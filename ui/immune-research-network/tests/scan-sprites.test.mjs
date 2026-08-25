import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = fileURLToPath(new URL("..", import.meta.url));

await import("../src/assets/asset-loader.js");

function pngSize(buf) {
  return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) };
}

test("scan sprite sheets are 2x5 ten-frame grids", async () => {
  const names = [
    "SYM-FAMILY-T", "SYM-FAMILY-B", "SYM-FAMILY-M", "SYM-FAMILY-N", "SYM-FAMILY-A", "SYM-FAMILY-D", "SYM-CORE",
    "SYM-PAIR-TB", "SYM-PAIR-TM", "SYM-PAIR-TN", "SYM-PAIR-TA", "SYM-PAIR-TD",
    "SYM-PAIR-BM", "SYM-PAIR-BN", "SYM-PAIR-BA", "SYM-PAIR-BD",
    "SYM-PAIR-MN", "SYM-PAIR-MA", "SYM-PAIR-MD",
    "SYM-PAIR-NA", "SYM-PAIR-ND", "SYM-PAIR-AD",
    "SYM-TRIPLE-TBA", "SYM-TRIPLE-TND", "SYM-TRIPLE-MAD", "SYM-TRIPLE-BMD", "SYM-TRIPLE-BNA", "SYM-TRIPLE-TMN",
    "SYM-APEX-MEMORY", "SYM-APEX-STERILE", "SYM-APEX-SILENT", "SYM-PRIME",
    "SYM-BASE-01", "SYM-BASE-02", "SYM-BASE-03", "SYM-BASE-04",
    "SYM-BASE-05", "SYM-BASE-06", "SYM-BASE-07", "SYM-BASE-08",
    "SYM-UNI-DEF", "SYM-UNI-EXP", "SYM-UNI-WAR", "SYM-UNI-MOB", "SYM-UNI-FUS", "SYM-UNI-SUR",
    "SYM-STATUS-MARK", "SYM-STATUS-AB", "SYM-STATUS-COR", "SYM-STATUS-SLOW",
    "SYM-STATUS-INF", "SYM-STATUS-CHAIN", "SYM-STATUS-CRIT",
    "SYM-PAIR-S1", "SYM-PAIR-S2", "SYM-PAIR-S4",
    "SYM-TRIPLE-ROLE", "SYM-TRIPLE-RULE", "SYM-TRIPLE-APEX",
    "SYM-APEX-GATE", "SYM-APEX-PROTOCOL"
  ];
  for (const name of names) {
    const path = join(ROOT, "assets/symbols/sheets", `${name}-scan.png`);
    assert.ok(existsSync(path), `missing ${name}-scan.png`);
    const buf = await readFile(path);
    const { width, height } = pngSize(buf);
    assert.equal(width, (height * 5) / 2, `${name} should be 5:2 (2x5 cells)`);
  }
});

test("scan level maps 10 ladder statuses onto 10 frames", () => {
  const { scanLevel, scanFrameCell, SCAN_FRAMES } = globalThis.IMMUNE;
  assert.equal(SCAN_FRAMES, 10);
  assert.equal(scanLevel(0, 9), 0);
  assert.equal(scanLevel(1, 9), 1);
  assert.equal(scanLevel(4, 9), 4);
  assert.equal(scanLevel(8, 9), 8);
  assert.equal(scanLevel(9, 9), 9);
  assert.equal(scanLevel(0, 20), 0);
  assert.equal(scanLevel(10, 20), 5);
  assert.equal(scanLevel(20, 20), 9);
  assert.deepEqual(scanFrameCell(0), { col: 0, row: 0, cols: 5, rows: 2 });
  assert.deepEqual(scanFrameCell(4), { col: 4, row: 0, cols: 5, rows: 2 });
  assert.deepEqual(scanFrameCell(5), { col: 0, row: 1, cols: 5, rows: 2 });
  assert.deepEqual(scanFrameCell(9), { col: 4, row: 1, cols: 5, rows: 2 });
});

test("family ladder progress counts CHAR-BASE plus BASE-01..08", () => {
  const { familyLadderProgress } = globalThis.IMMUNE;
  const catalog = {
    nodes: [
      { id: "CHAR-BASE-T", familyIds: ["T"] },
      { id: "BASE-T-01", familyIds: ["T"] },
      { id: "BASE-T-02", familyIds: ["T"] },
      { id: "BASE-T-03", familyIds: ["T"] },
      { id: "BASE-T-04", familyIds: ["T"] },
      { id: "BASE-T-05", familyIds: ["T"] },
      { id: "BASE-T-06", familyIds: ["T"] },
      { id: "BASE-T-07", familyIds: ["T"] },
      { id: "BASE-T-08", familyIds: ["T"] },
      { id: "SKILL-T-99", familyIds: ["T"] }
    ]
  };
  const empty = familyLadderProgress(catalog, { completedNodeIds: [] }, "T");
  assert.deepEqual(empty, { done: 0, total: 9 });
  const mid = familyLadderProgress(catalog, { completedNodeIds: ["CHAR-BASE-T", "BASE-T-01", "BASE-T-02", "SKILL-T-99"] }, "T");
  assert.deepEqual(mid, { done: 3, total: 9 });
});

test("pair ladder progress counts CHAR-PAIR plus S1/S2/S4", () => {
  const { pairLadderProgress } = globalThis.IMMUNE;
  const catalog = {
    nodes: [
      { id: "CHAR-PAIR-TB" },
      { id: "PAIR-TB-S1" },
      { id: "PAIR-TB-S2" },
      { id: "PAIR-TB-S4" },
      { id: "CHAR-BASE-T" }
    ]
  };
  assert.deepEqual(pairLadderProgress(catalog, { completedNodeIds: [] }, "TB"), { done: 0, total: 4 });
  assert.deepEqual(pairLadderProgress(catalog, { completedNodeIds: ["CHAR-PAIR-TB", "PAIR-TB-S1"] }, "TB"), { done: 2, total: 4 });
});

test("triple ladder progress counts CHAR-TRIPLE plus ROLE/RULE/APEX", () => {
  const { tripleLadderProgress } = globalThis.IMMUNE;
  const catalog = {
    nodes: [
      { id: "CHAR-TRIPLE-TBA" },
      { id: "TRIPLE-TBA-ROLE" },
      { id: "TRIPLE-TBA-RULE" },
      { id: "TRIPLE-TBA-APEX" },
      { id: "CHAR-BASE-T" }
    ]
  };
  assert.deepEqual(tripleLadderProgress(catalog, { completedNodeIds: [] }, "TBA"), { done: 0, total: 4 });
  assert.deepEqual(tripleLadderProgress(catalog, { completedNodeIds: ["CHAR-TRIPLE-TBA", "TRIPLE-TBA-ROLE"] }, "TBA"), { done: 2, total: 4 });
});

test("apex ladder progress counts CHAR-APEX plus GATE/PROTOCOL", () => {
  const { apexLadderProgress } = globalThis.IMMUNE;
  const catalog = {
    nodes: [
      { id: "CHAR-APEX-MEMORY" },
      { id: "APEX-MEMORY-GATE" },
      { id: "APEX-MEMORY-PROTOCOL" },
      { id: "CHAR-PRIME" },
      { id: "APEX-PRIME-GATE" },
      { id: "APEX-PRIME-PROTOCOL" },
      { id: "CHAR-BASE-T" }
    ]
  };
  assert.deepEqual(apexLadderProgress(catalog, { completedNodeIds: [] }, "MEMORY"), { done: 0, total: 3 });
  assert.deepEqual(apexLadderProgress(catalog, { completedNodeIds: ["CHAR-APEX-MEMORY", "APEX-MEMORY-GATE"] }, "MEMORY"), { done: 2, total: 3 });
  assert.deepEqual(apexLadderProgress(catalog, { completedNodeIds: ["CHAR-PRIME"] }, "PRIME"), { done: 1, total: 3 });
});

test("base slot scan uses shared SYM-BASE sheets and eligibility frames", () => {
  const { scanSheetPath, scanLevelFromEligibility, SCAN_FRAMES } = globalThis.IMMUNE;
  assert.equal(scanSheetPath("BASE-T-04"), "assets/symbols/sheets/SYM-BASE-04-scan.png");
  assert.equal(scanSheetPath("BASE-A-01"), "assets/symbols/sheets/SYM-BASE-01-scan.png");
  assert.equal(scanLevelFromEligibility("hidden"), 0);
  assert.equal(scanLevelFromEligibility("missing_prerequisite"), 1);
  assert.equal(scanLevelFromEligibility("missing_condition"), 3);
  assert.equal(scanLevelFromEligibility("missing_resource"), 5);
  assert.equal(scanLevelFromEligibility("ready"), 7);
  assert.equal(scanLevelFromEligibility("completed"), SCAN_FRAMES - 1);
});

test("remaining research nodes use shared slot sheets and never steal character sheets", () => {
  const { scanSheetPath, researchSymbolPath } = globalThis.IMMUNE;
  assert.equal(scanSheetPath("UNI-DEF-01"), "assets/symbols/sheets/SYM-UNI-DEF-scan.png");
  assert.equal(scanSheetPath("UNI-SUR-07"), "assets/symbols/sheets/SYM-UNI-SUR-scan.png");
  assert.equal(scanSheetPath("STATUS-MARK"), "assets/symbols/sheets/SYM-STATUS-MARK-scan.png");
  assert.equal(scanSheetPath("STATUS-CRIT"), "assets/symbols/sheets/SYM-STATUS-CRIT-scan.png");
  assert.equal(scanSheetPath("PAIR-TB-S1"), "assets/symbols/sheets/SYM-PAIR-S1-scan.png");
  assert.equal(scanSheetPath("PAIR-AD-S4"), "assets/symbols/sheets/SYM-PAIR-S4-scan.png");
  assert.equal(scanSheetPath("TRIPLE-TBA-ROLE"), "assets/symbols/sheets/SYM-TRIPLE-ROLE-scan.png");
  assert.equal(scanSheetPath("TRIPLE-TMN-APEX"), "assets/symbols/sheets/SYM-TRIPLE-APEX-scan.png");
  assert.equal(scanSheetPath("APEX-MEMORY-GATE"), "assets/symbols/sheets/SYM-APEX-GATE-scan.png");
  assert.equal(scanSheetPath("APEX-PRIME-PROTOCOL"), "assets/symbols/sheets/SYM-APEX-PROTOCOL-scan.png");
  assert.equal(scanSheetPath("CHAR-PAIR-TB"), "assets/symbols/sheets/SYM-PAIR-TB-scan.png");
  assert.equal(scanSheetPath("CHAR-TRIPLE-TBA"), "assets/symbols/sheets/SYM-TRIPLE-TBA-scan.png");
  assert.equal(scanSheetPath("CHAR-APEX-MEMORY"), "assets/symbols/sheets/SYM-APEX-MEMORY-scan.png");
  assert.equal(researchSymbolPath("PAIR-TB-S1"), "assets/symbols/SYM-PAIR-S1.png");
  assert.notEqual(researchSymbolPath("PAIR-TB-S1"), researchSymbolPath("CHAR-PAIR-TB"));
  assert.notEqual(researchSymbolPath("TRIPLE-TBA-ROLE"), researchSymbolPath("CHAR-TRIPLE-TBA"));
  assert.notEqual(researchSymbolPath("APEX-MEMORY-GATE"), researchSymbolPath("CHAR-APEX-MEMORY"));
});

test("skill icons use five shared slot organs by ID suffix", async () => {
  const { skillSymbolPath, skillSlotFromId } = globalThis.IMMUNE;
  assert.equal(skillSlotFromId("SKILL-T-PASSIVE"), "PASSIVE");
  assert.equal(skillSymbolPath("SKILL-T-PASSIVE"), "assets/symbols/SYM-SKILL-PASSIVE.png");
  assert.equal(skillSymbolPath("SKILL-TB-P1"), "assets/symbols/SYM-SKILL-PASSIVE.png");
  assert.equal(skillSymbolPath("SKILL-TBA-ROLE"), "assets/symbols/SYM-SKILL-PASSIVE.png");
  assert.equal(skillSymbolPath("SKILL-MEMORY-GATE"), "assets/symbols/SYM-SKILL-PASSIVE.png");
  assert.equal(skillSymbolPath("SKILL-T-ACTIVE"), "assets/symbols/SYM-SKILL-ACTIVE.png");
  assert.equal(skillSymbolPath("SKILL-AD-P2"), "assets/symbols/SYM-SKILL-ACTIVE.png");
  assert.equal(skillSymbolPath("SKILL-TMN-RULE"), "assets/symbols/SYM-SKILL-ACTIVE.png");
  assert.equal(skillSymbolPath("SKILL-T-FIXED"), "assets/symbols/SYM-SKILL-FIXED.png");
  assert.equal(skillSymbolPath("SKILL-TB-FIXED"), "assets/symbols/SYM-SKILL-FIXED.png");
  assert.equal(skillSymbolPath("SKILL-PRIME-DEF"), "assets/symbols/SYM-SKILL-FIXED.png");
  assert.equal(skillSymbolPath("SKILL-TB-PROTO"), "assets/symbols/SYM-SKILL-PROTOCOL.png");
  assert.equal(skillSymbolPath("SKILL-MEMORY-PROTO"), "assets/symbols/SYM-SKILL-PROTOCOL.png");
  assert.equal(skillSymbolPath("SKILL-T-APEX"), "assets/symbols/SYM-SKILL-APEX.png");
  assert.equal(skillSymbolPath("SKILL-TBA-APEX"), "assets/symbols/SYM-SKILL-APEX.png");
  assert.equal(skillSymbolPath("SKILL-PRIME-ULT"), "assets/symbols/SYM-SKILL-APEX.png");
  assert.equal(skillSymbolPath("CHAR-BASE-T"), "");
  assert.equal(skillSymbolPath("APEX-MEMORY-GATE"), "");
  for (const slot of ["PASSIVE", "ACTIVE", "FIXED", "PROTOCOL", "APEX"]) {
    const path = join(ROOT, "assets/symbols", `SYM-SKILL-${slot}.png`);
    assert.ok(existsSync(path), `missing SYM-SKILL-${slot}.png`);
    const buf = await readFile(path);
    const { width, height } = pngSize(buf);
    assert.equal(width, 256, `${slot} width`);
    assert.equal(height, 256, `${slot} height`);
  }
});
