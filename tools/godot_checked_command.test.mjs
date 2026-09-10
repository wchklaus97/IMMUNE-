import assert from "node:assert/strict";
import { mkdtemp, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  parseGodotCheckedCommandArgs,
  runCheckedCommand,
  validateGodotResult,
} from "./godot_checked_command.mjs";

test("parseGodotCheckedCommandArgs accepts repeated markers and a command", () => {
  assert.deepEqual(parseGodotCheckedCommandArgs([
    "--log=/tmp/godot.log",
    "--expect=FIRST",
    "--expect=SECOND",
    "--",
    "godot",
    "--headless",
  ]), {
    log: "/tmp/godot.log",
    expectedMarkers: ["FIRST", "SECOND"],
    command: "godot",
    args: ["--headless"],
  });
});

test("parseGodotCheckedCommandArgs rejects incomplete or ambiguous options", () => {
  assert.throws(() => parseGodotCheckedCommandArgs(["--", "godot"]), /--log/u);
  assert.throws(() => parseGodotCheckedCommandArgs(["--log=", "--", "godot"]), /non-empty/u);
  assert.throws(() => parseGodotCheckedCommandArgs(["--log=a", "--log=b", "--", "godot"]), /once/u);
  assert.throws(() => parseGodotCheckedCommandArgs(["--log=a", "--wat", "--", "godot"]), /unknown option/u);
  assert.throws(() => parseGodotCheckedCommandArgs(["--log=a"]), /command/u);
});

test("validateGodotResult rejects Godot diagnostics even with exit code zero", () => {
  for (const diagnostic of ["ERROR: failed", "SCRIPT ERROR: bad", "Parse Error: bad", "Compile Error: bad"]) {
    assert.throws(
      () => validateGodotResult({ status: 0, signal: null, logText: diagnostic, expectedMarkers: [] }),
      /diagnostic/u,
    );
  }
});

test("validateGodotResult requires every marker and a clean process exit", () => {
  assert.doesNotThrow(() => validateGodotResult({
    status: 0,
    signal: null,
    logText: "FIRST\nSECOND\n",
    expectedMarkers: ["FIRST", "SECOND"],
  }));
  assert.throws(
    () => validateGodotResult({ status: 0, signal: null, logText: "FIRST", expectedMarkers: ["SECOND"] }),
    /missing expected marker/u,
  );
  assert.throws(
    () => validateGodotResult({ status: 7, signal: null, logText: "", expectedMarkers: [] }),
    /exit code 7/u,
  );
  assert.throws(
    () => validateGodotResult({ status: null, signal: "SIGTERM", logText: "", expectedMarkers: [] }),
    /SIGTERM/u,
  );
});

test("runCheckedCommand captures a unique log and applies fail-closed validation", async () => {
  const directory = await mkdtemp(join(tmpdir(), "immune-godot-checked-"));
  const successLog = join(directory, "success.log");
  await runCheckedCommand({
    command: process.execPath,
    args: ["-e", "console.log('READY')"],
    log: successLog,
    expectedMarkers: ["READY"],
    echo: false,
  });
  assert.match(await readFile(successLog, "utf8"), /READY/u);
  await assert.rejects(
    runCheckedCommand({
      command: process.execPath,
      args: ["-e", "console.error('ERROR: hidden Godot failure')"],
      log: join(directory, "failure.log"),
      expectedMarkers: [],
      echo: false,
    }),
    /diagnostic/u,
  );
  await assert.rejects(
    runCheckedCommand({
      command: process.execPath,
      args: ["-e", "console.log('READY')"],
      log: successLog,
      expectedMarkers: ["READY"],
      echo: false,
    }),
    /already exists/u,
  );
});
