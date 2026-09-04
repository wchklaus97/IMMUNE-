import assert from "node:assert/strict";
import { dirname } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import {
  parseV85ExportArgs,
  validateV85ExportContract,
  validateV85PckPaths,
} from "./validate_v8_5_export.mjs";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const BODY = "characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb";

test("parseV85ExportArgs accepts one optional PCK", () => {
  assert.deepEqual(parseV85ExportArgs([]), { pck: "" });
  assert.deepEqual(parseV85ExportArgs(["--pck=/tmp/candidate.pck"]), { pck: "/tmp/candidate.pck" });
  assert.throws(() => parseV85ExportArgs(["--pck="]), /non-empty/u);
  assert.throws(() => parseV85ExportArgs(["--wat"]), /unknown option/u);
  assert.throws(() => parseV85ExportArgs(["--pck=a", "--pck=b"]), /once/u);
});

test("validateV85PckPaths requires the raw body and imported scene without banned candidates", () => {
  const clean = [
    BODY,
    `${BODY}.import`,
    ".godot/imported/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb-a1b2c3.scn",
    "characters/base_t/character.tscn.remap",
  ];
  assert.deepEqual(validateV85PckPaths(clean), {
    bodyEntries: clean.slice(0, 3),
    resourceCount: clean.length,
  });
  assert.throws(() => validateV85PckPaths(clean.filter((path) => path !== BODY)), /raw V8.5 body/u);
  assert.throws(
    () => validateV85PckPaths([...clean, "characters/base_t/CHAR-BASE-T-v8-4-single-mass-r1.glb"]),
    /forbidden candidate/u,
  );
  assert.throws(
    () => validateV85PckPaths([...clean, "addons/v8_5_raw_export/plugin.cfg"]),
    /editor addon/u,
  );
  assert.throws(() => validateV85PckPaths([...clean, BODY]), /exactly three/u);
  assert.throws(
    () => validateV85PckPaths([...clean, "characters/concepts/rejected.png"]),
    /concept asset/u,
  );
});

test("repository V8.5 export contract remains isolated after V8.6 promotion", async () => {
  const result = await validateV85ExportContract({ root: ROOT });
  assert.equal(result.candidatePresetCount, 4);
  assert.equal(result.shippingPresetCount, 4);
  assert.equal(result.defaultLook, "v8_6");
  assert.equal(result.pck, "not-requested");
});
