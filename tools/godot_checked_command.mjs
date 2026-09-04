#!/usr/bin/env node

import { spawn } from "node:child_process";
import { mkdir, open } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const GODOT_ERROR_PATTERN = /(?:SCRIPT ERROR|Parse Error|Compile Error|ERROR:)/u;

export function parseGodotCheckedCommandArgs(argv) {
  let log = "";
  const expectedMarkers = [];
  const separator = argv.indexOf("--");
  const options = separator < 0 ? argv : argv.slice(0, separator);
  const commandParts = separator < 0 ? [] : argv.slice(separator + 1);
  for (const raw of options) {
    if (raw.startsWith("--log=")) {
      if (log) throw new Error("--log may be provided only once");
      log = raw.slice("--log=".length);
      if (!log) throw new Error("--log requires a non-empty path");
    } else if (raw.startsWith("--expect=")) {
      const marker = raw.slice("--expect=".length);
      if (!marker) throw new Error("--expect requires a non-empty marker");
      expectedMarkers.push(marker);
    } else {
      throw new Error(`unknown option: ${raw}`);
    }
  }
  if (!log) throw new Error("--log is required");
  if (!commandParts.length || !commandParts[0]) throw new Error("a command is required after --");
  return {
    log,
    expectedMarkers,
    command: commandParts[0],
    args: commandParts.slice(1),
  };
}

export function validateGodotResult({ status, signal, logText, expectedMarkers = [] }) {
  if (signal) throw new Error(`Godot command terminated by signal ${signal}`);
  if (status !== 0) throw new Error(`Godot command failed with exit code ${status}`);
  const diagnostic = GODOT_ERROR_PATTERN.exec(logText);
  if (diagnostic) throw new Error(`Godot command emitted a failure diagnostic: ${diagnostic[0]}`);
  for (const marker of expectedMarkers) {
    if (!logText.includes(marker)) throw new Error(`Godot command missing expected marker: ${marker}`);
  }
  return { status, markers: expectedMarkers.length };
}

export async function runCheckedCommand({ command, args = [], log, expectedMarkers = [], echo = true }) {
  if (!command) throw new Error("command is required");
  if (!log) throw new Error("log path is required");
  await mkdir(dirname(log), { recursive: true });
  let handle;
  try {
    handle = await open(log, "wx");
  } catch (error) {
    if (error?.code === "EEXIST") throw new Error(`log already exists: ${log}`);
    throw error;
  }

  let logText = "";
  let writeChain = Promise.resolve();
  try {
    const result = await new Promise((accept, reject) => {
      const child = spawn(command, args, { shell: false, stdio: ["ignore", "pipe", "pipe"] });
      const capture = (stream, destination) => {
        stream.on("data", (chunk) => {
          const text = chunk.toString("utf8");
          logText += text;
          writeChain = writeChain.then(() => handle.write(text));
          if (echo) destination.write(text);
        });
      };
      capture(child.stdout, process.stdout);
      capture(child.stderr, process.stderr);
      child.once("error", reject);
      child.once("close", (status, signal) => accept({ status, signal }));
    });
    await writeChain;
    await handle.sync();
    validateGodotResult({ ...result, logText, expectedMarkers });
    return { ...result, log, logText, markers: expectedMarkers.length };
  } finally {
    await handle.close();
  }
}

async function main() {
  const options = parseGodotCheckedCommandArgs(process.argv.slice(2));
  const result = await runCheckedCommand(options);
  console.log(`GODOT_CHECKED_COMMAND_OK command=${options.command} log=${options.log} markers=${result.markers}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
