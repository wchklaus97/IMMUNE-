import test from "node:test";
import assert from "node:assert/strict";

if (!Object.groupBy) {
  Object.groupBy = (items, keyFn) =>
    items.reduce((acc, item) => {
      const key = keyFn(item);
      (acc[key] ||= []).push(item);
      return acc;
    }, {});
}

await import("../src/catalog/definitions.js");
await import("../src/catalog/build-catalog.js");
await import("../src/catalog/validate-catalog.js");
await import("../src/catalog/character-identity.js");

test("catalog contains the approved 200-node allocation", () => {
  const catalog = globalThis.IMMUNE.buildCatalog();
  const counts = Object.groupBy(catalog.nodes, (node) => node.kind);
  const size = (key) => (counts[key] || []).length;
  assert.equal(catalog.nodes.length, 200);
  assert.deepEqual(
    [
      size("core"),
      size("character_anchor"),
      size("base_character_research"),
      size("pair_research"),
      size("triple_research"),
      size("apex_research"),
      size("universal"),
      size("status")
    ],
    [1, 31, 48, 45, 18, 8, 42, 7]
  );
});

test("all stable ids and references are valid", () => {
  const result = globalThis.IMMUNE.validateCatalog(globalThis.IMMUNE.buildCatalog());
  assert.deepEqual(result.errors, []);
  assert.equal(result.valid, true);
});

test("BASE-T-04 uses the approved mobility name", () => {
  const catalog = globalThis.IMMUNE.buildCatalog();
  const node = catalog.nodes.find((entry) => entry.id === "BASE-T-04");
  assert.ok(node);
  assert.equal(node.name, "T 細胞移動資格");
});

test("antibody base node 4 is fixed relay qualification", () => {
  const catalog = globalThis.IMMUNE.buildCatalog();
  const node = catalog.nodes.find((entry) => entry.id === "BASE-A-04");
  assert.ok(node);
  assert.equal(node.name, "抗體固定中繼資格");
});

test("family, universal, and status trees use 2-1 then 3-1 routes with level links", () => {
  const catalog = globalThis.IMMUNE.buildCatalog();
  const byId = Object.fromEntries(catalog.nodes.map((node) => [node.id, node]));
  const ids = (node) => node.prerequisiteGroups[0].nodeIds;

  assert.deepEqual(ids(byId["BASE-T-01"]), ["CHAR-BASE-T"]);
  assert.deepEqual(ids(byId["BASE-T-02"]), ["CHAR-BASE-T"]);
  assert.deepEqual(ids(byId["BASE-T-03"]), ["BASE-T-01", "BASE-T-02"]);
  assert.deepEqual(ids(byId["BASE-T-04"]), ["BASE-T-03"]);
  assert.deepEqual(ids(byId["BASE-T-05"]), ["BASE-T-03"]);
  assert.deepEqual(ids(byId["BASE-T-06"]), ["BASE-T-03"]);
  assert.deepEqual(ids(byId["BASE-T-07"]), ["BASE-T-04", "BASE-T-05", "BASE-T-06"]);
  assert.deepEqual(ids(byId["BASE-T-08"]), ["BASE-T-07"]);
  assert.equal(byId["BASE-T-03"].route, "2-1");
  assert.equal(byId["BASE-T-03"].levelLink, "L02");
  assert.equal(byId["BASE-T-07"].route, "3-1");
  assert.equal(byId["BASE-T-07"].levelLink, "L04");
  assert.equal(byId["BASE-T-08"].levelLink, "L05");
  assert.equal(byId["BASE-T-04"].revealRule.type, "completed");

  assert.deepEqual(ids(byId["UNI-DEF-01"]), ["CORE-IMMUNE"]);
  assert.deepEqual(ids(byId["UNI-DEF-02"]), ["CORE-IMMUNE"]);
  assert.deepEqual(ids(byId["UNI-DEF-03"]), ["UNI-DEF-01", "UNI-DEF-02"]);
  assert.deepEqual(ids(byId["UNI-DEF-07"]), ["UNI-DEF-04", "UNI-DEF-05", "UNI-DEF-06"]);

  assert.deepEqual(ids(byId["STATUS-MARK"]), ["CORE-IMMUNE"]);
  assert.deepEqual(ids(byId["STATUS-AB"]), ["CORE-IMMUNE"]);
  assert.deepEqual(ids(byId["STATUS-COR"]), ["STATUS-MARK", "STATUS-AB"]);
  assert.deepEqual(ids(byId["STATUS-CRIT"]), ["STATUS-SLOW", "STATUS-INF", "STATUS-CHAIN"]);

  assert.deepEqual(ids(byId["PAIR-TB-S1"]), ["BASE-T-01", "BASE-B-01"]);
  assert.deepEqual(ids(byId["PAIR-TB-S2"]), ["BASE-T-02", "BASE-B-02"]);
  assert.deepEqual(byId["CHAR-PAIR-TB"].prerequisiteGroups[0].nodeIds, ["PAIR-TB-S1", "PAIR-TB-S2"]);
});

test("core universal layers grant global combat stats without new node ids", () => {
  const catalog = globalThis.IMMUNE.buildCatalog();
  const byId = Object.fromEntries(catalog.nodes.map((node) => [node.id, node]));
  assert.equal(byId["UNI-WAR-01"].name, "全體攻擊節奏");
  assert.equal(byId["UNI-MOB-01"].name, "全體移動節奏");
  const warSpeed = byId["UNI-WAR-01"].effectOps.find((op) => op.stat === "attackSpeed");
  assert.equal(warSpeed.op, "grant_global_stat");
  assert.equal(warSpeed.amount, 0.05);
  assert.equal(
    byId["UNI-MOB-05"].effectOps.some((op) => op.stat === "attackSpeed"),
    false
  );
  const warAll = byId["UNI-WAR-01"].effectOps
    .concat(byId["UNI-WAR-03"].effectOps, byId["UNI-WAR-07"].effectOps)
    .filter((op) => op.stat === "attackSpeed" && !op.duty)
    .reduce((sum, op) => sum + op.amount, 0);
  assert.ok(warAll <= 0.14);
  assert.ok(byId["UNI-WAR-01"].tags.includes("core_layer"));
  assert.ok(byId["STATUS-CRIT"].effectOps.some((op) => op.stat === "critChance"));
});

test("base skills follow 2-1 then capstone with campaign level links", async () => {
  await import("../src/assets/game-assets.js");
  const t = globalThis.IMMUNE.gameAssets.characters["CHAR-BASE-T"].skills;
  const bySlot = Object.fromEntries(t.map((skill) => [skill.slot, skill]));
  assert.equal(bySlot.active.unlockNodeId, "BASE-T-01");
  assert.equal(bySlot.passive.unlockNodeId, "BASE-T-02");
  assert.equal(bySlot.fixed.unlockNodeId, "BASE-T-03");
  assert.deepEqual(bySlot.fixed.requires, ["SKILL-T-PASSIVE", "SKILL-T-ACTIVE"]);
  assert.equal(bySlot.apex.unlockNodeId, "BASE-T-08");
  assert.equal(bySlot.active.levelLink, "L01");
  assert.equal(bySlot.fixed.levelLink, "L02");
  assert.equal(bySlot.apex.levelLink, "L05");
  assert.equal(bySlot.fixed.route, "2-1");
});

function campaignMin(node) {
  return (node.conditions || []).find((condition) => condition.type === "campaign_level")?.min || null;
}

test("selective campaign locks skip early 2-1 and pair research", () => {
  const catalog = globalThis.IMMUNE.buildCatalog();
  const byId = Object.fromEntries(catalog.nodes.map((node) => [node.id, node]));

  assert.equal(campaignMin(byId["BASE-T-01"]), null);
  assert.equal(campaignMin(byId["BASE-T-03"]), null);
  assert.equal(campaignMin(byId["UNI-WAR-01"]), null);
  assert.equal(campaignMin(byId["UNI-WAR-03"]), null);
  assert.equal(campaignMin(byId["STATUS-MARK"]), null);
  assert.equal(campaignMin(byId["STATUS-COR"]), null);
  assert.equal(campaignMin(byId["PAIR-TB-S1"]), null);
  assert.equal(campaignMin(byId["PAIR-TB-S2"]), null);

  assert.equal(campaignMin(byId["BASE-T-04"]), "L02");
  assert.equal(campaignMin(byId["BASE-A-04"]), "L02");
  assert.equal(campaignMin(byId["BASE-T-05"]), "L03");
  assert.equal(campaignMin(byId["BASE-T-07"]), "L03");
  assert.equal(campaignMin(byId["BASE-T-08"]), "L05");
  assert.equal(campaignMin(byId["UNI-WAR-04"]), "L03");
  assert.equal(campaignMin(byId["UNI-WAR-07"]), "L03");
  assert.equal(campaignMin(byId["STATUS-SLOW"]), "L03");
  assert.equal(campaignMin(byId["STATUS-CRIT"]), "L03");
  assert.equal(campaignMin(byId["CHAR-PAIR-TB"]), "L03");
  assert.equal(campaignMin(byId["CHAR-TRIPLE-TBA"]), "L04");
  assert.equal(campaignMin(byId["TRIPLE-TBA-APEX"]), "L05");
  assert.equal(campaignMin(byId["CHAR-APEX-MEMORY"]), "L05");
  assert.equal(campaignMin(byId["CHAR-PRIME"]), "L06");
  assert.equal(catalog.nodes.length, 200);
});

test("character identity model covers all 31 anchors and never invents ids", () => {
  const catalog = globalThis.IMMUNE.buildCatalog();
  const anchors = catalog.nodes.filter((n) => n.kind === "character_anchor").map((n) => n.id);
  const model = globalThis.IMMUNE.characterIdentity.CHARACTERS;
  assert.equal(Object.keys(model).length, 31);
  for (const id of anchors) {
    assert.ok(model[id], `missing identity for ${id}`);
    assert.equal(model[id].name, catalog.nodes.find((n) => n.id === id).name);
  }
  assert.equal(globalThis.IMMUNE.characterIdentity.listNeedingCatalogRedraw().includes("CHAR-BASE-T"), false);
  assert.equal(globalThis.IMMUNE.characterIdentity.CHARACTERS["CHAR-PAIR-TB"].catalogStatus, "keep_catalog");
  assert.ok(globalThis.IMMUNE.characterIdentity.artBrief("CHAR-PAIR-TM", "catalog").includes("吞噬突擊"));
});
