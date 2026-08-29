import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";

import { parseConfig, validateReleaseContract } from "./validate_release_contract.mjs";

test("parses Godot config sections and typed scalar values", () => {
  const parsed = parseConfig('[application]\nconfig/name="IMMUNE"\nenabled=true\ncount=4\n');
  assert.deepEqual(parsed.get("application"), { "config/name": "IMMUNE", enabled: true, count: 4 });
});

test("keeps the live four-platform release identity coherent", async () => {
  const report = await validateReleaseContract({ root: path.resolve(".") });
  assert.equal(report.version, "0.4.0");
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
