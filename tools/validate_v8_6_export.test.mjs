import assert from "node:assert/strict";
import { dirname } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import {
  parseV86ExportArgs,
  validateV86ExportContract,
  validateV86PckPaths,
} from "./validate_v8_6_export.mjs";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const BODY = "characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb";
const PRESERVED_BODIES = [
  ["characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r5.glb", "473fcb356a166eb113bc3532d471e2bc51c6dea85dbf7146e417d293e103197f"],
  ["characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r6.glb", "6fa587a26af3a248713986fd7614c028ae787a11cf22c310d89ac97d590dc770"],
  ["characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7.glb", "2ee384882c8c41c6a1454a457b5ed17ce2e934999ecc24337e27b9948299d587"],
  ["characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-1.glb", "8af1663976140b6769ae638217efe46873e9a71a57e0294005c49361a7bf40a0"],
];

test("parseV86ExportArgs accepts one optional PCK", () => {
  assert.deepEqual(parseV86ExportArgs([]), { pck: "" });
  assert.deepEqual(parseV86ExportArgs(["--pck=/tmp/candidate.pck"]), { pck: "/tmp/candidate.pck" });
  assert.throws(() => parseV86ExportArgs(["--pck="]), /non-empty/u);
  assert.throws(() => parseV86ExportArgs(["--wat"]), /unknown option/u);
  assert.throws(() => parseV86ExportArgs(["--pck=a", "--pck=b"]), /once/u);
});

test("validateV86PckPaths requires only the exact active R7.2 body inventory", () => {
  const clean = [
    BODY,
    `${BODY}.import`,
    ".godot/imported/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb-a1b2c3.scn",
    "characters/base_t/character.tscn.remap",
  ];
  assert.deepEqual(validateV86PckPaths(clean), {
    bodyEntries: clean.slice(0, 3),
    resourceCount: clean.length,
  });
  assert.throws(() => validateV86PckPaths(clean.filter((path) => path !== BODY)), /raw V8.6 body/u);
  assert.throws(
    () => validateV86PckPaths([...clean, "characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb"]),
    /forbidden candidate/u,
  );
  for (const [preservedBody] of PRESERVED_BODIES) {
    assert.throws(() => validateV86PckPaths([...clean, preservedBody]), /forbidden candidate/u);
  }
  assert.throws(
    () => validateV86PckPaths([...clean, "characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r8.glb"]),
    /unexpected V8.6 body revision/u,
  );
  assert.throws(
    () => validateV86PckPaths([...clean, "addons/v8_6_raw_export/plugin.cfg"]),
    /editor addon/u,
  );
  assert.throws(() => validateV86PckPaths([...clean, BODY]), /exactly three/u);
  assert.throws(
    () => validateV86PckPaths([...clean, "characters/concepts/rejected.png"]),
    /concept asset/u,
  );
});

test("repository V8.6 export contract promotes R7.2 and preserves V8.3 rollback", async () => {
  const result = await validateV86ExportContract({ root: ROOT });
  assert.equal(result.candidatePresetCount, 4);
  assert.equal(result.shippingPresetCount, 4);
  assert.equal(result.defaultLook, "v8_6");
  assert.equal(result.bodySha256, "3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3");
  assert.deepEqual(result.preservedBodySha256, Object.fromEntries(PRESERVED_BODIES));
  assert.equal(result.pck, "not-requested");
});
