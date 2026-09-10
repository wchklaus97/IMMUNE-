import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import {
  parseConfig,
  nativeVersionIdentity,
  releaseArguments,
  validateArtifactInventory,
  validateReleaseContract,
} from "./validate_release_contract.mjs";

const RELEASE_FILES = [
  "IMMUNE-windows.exe",
  "IMMUNE-windows.pck",
  "IMMUNE-linux.x86_64",
  "IMMUNE-linux.pck",
  "IMMUNE-macOS.zip",
  "web/index.html",
  "web/index.js",
  "web/index.pck",
  "web/index.wasm",
  "web/index.audio.worklet.js",
  "web/index.audio.position.worklet.js",
  "web/index.png",
  "web/index.icon.png",
  "web/index.apple-touch-icon.png",
];

test("release-contract CLI rejects unknown, empty, and duplicate inputs", () => {
  assert.throws(() => releaseArguments(["--token=secret"]), /Unknown/u);
  assert.throws(() => releaseArguments(["--tag="]), /requires a value/u);
  assert.throws(() => releaseArguments(["--tag=v0.5.0-rc.1", "--tag=v0.5.0-rc.2"]), /Duplicate/u);
});

test("maps RC identity to platform-safe native versions", () => {
  assert.deepEqual(nativeVersionIdentity("0.5.0-rc.1"), {
    source: "0.5.0-rc.1",
    windowsFile: "0.5.0.1",
    windowsProduct: "0.5.0-rc.1",
    macShort: "0.5.0",
    macBuild: "1",
  });
  assert.equal(nativeVersionIdentity("0.5-rc.1"), null);
});

test("parses Godot config sections and typed scalar values", () => {
  const parsed = parseConfig('[application]\nconfig/name="IMMUNE"\nenabled=true\ncount=4\n');
  assert.deepEqual(parsed.get("application"), { "config/name": "IMMUNE", enabled: true, count: 4 });
});

test("keeps the live four-platform release identity coherent", async () => {
  const report = await validateReleaseContract({ root: path.resolve(".") });
  assert.equal(report.version, "0.5.0-rc.1");
  assert.equal(report.presetCount, 4);
  assert.equal(report.webMode, "single-threaded");
  assert.equal(report.macSigning, "adhoc");
});

test("rejects a release tag that disagrees with the project version", async () => {
  await assert.rejects(
    validateReleaseContract({ root: path.resolve("."), tag: "v9.9.9" }),
    /release tag/u,
  );
});

test("release artifact inventory rejects stale or extra files", async () => {
  const root = await mkdtemp(path.join(tmpdir(), "immune-release-inventory-"));
  for (const file of RELEASE_FILES) {
    const target = path.join(root, file);
    await mkdir(path.dirname(target), { recursive: true });
    await writeFile(target, "fixture");
  }
  assert.deepEqual((await validateArtifactInventory(root)).errors, []);
  await writeFile(path.join(root, "web/old-candidate.pck"), "stale");
  assert.match((await validateArtifactInventory(root)).errors.join("\n"), /unexpected artifact/u);
});
