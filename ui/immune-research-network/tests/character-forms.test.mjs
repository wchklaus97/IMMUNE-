import test from "node:test";
import assert from "node:assert/strict";

await import("../src/catalog/definitions.js");
await import("../src/assets/game-assets.js");

const { characters, isFormUnlocked } = globalThis.IMMUNE.gameAssets;

test("each character defines fixed and mobile forms", () => {
  assert.equal(Object.keys(characters).length, 31);
  for (const character of Object.values(characters)) {
    assert.ok(character.forms?.fixed, `${character.id} missing fixed form`);
    assert.ok(character.forms?.mobile, `${character.id} missing mobile form`);
  }
});

test("macrophage mobile unlock requires BASE-M-04", () => {
  const m = characters["CHAR-BASE-M"];
  const locked = { completedNodeIds: ["BASE-M-03"], revealedNodeIds: ["CHAR-BASE-M"] };
  const unlocked = { completedNodeIds: ["BASE-M-03", "BASE-M-04"], revealedNodeIds: ["CHAR-BASE-M"] };
  assert.equal(isFormUnlocked(locked, m, "fixed"), true);
  assert.equal(isFormUnlocked(locked, m, "mobile"), false);
  assert.equal(isFormUnlocked(unlocked, m, "mobile"), true);
});

test("antibody construct uses relay qualification instead of mobility", () => {
  const a = characters["CHAR-BASE-A"];
  assert.equal(a.forms.mobile.label, "固定中繼");
  assert.equal(a.forms.mobile.kind, "relay");
  assert.equal(a.forms.mobile.unlockNodeId, "BASE-A-04");
});

test("pair fusion mobile requires both source mobility researches", () => {
  const tb = characters["CHAR-PAIR-TB"];
  assert.deepEqual(tb.forms.mobile.unlockNodeIds, ["BASE-T-04", "BASE-B-04"]);
  const partial = { completedNodeIds: ["BASE-T-04"], revealedNodeIds: ["CHAR-PAIR-TB"] };
  const full = { completedNodeIds: ["BASE-T-04", "BASE-B-04"], revealedNodeIds: ["CHAR-PAIR-TB"] };
  assert.equal(isFormUnlocked(partial, tb, "mobile"), false);
  assert.equal(isFormUnlocked(full, tb, "mobile"), true);
});
