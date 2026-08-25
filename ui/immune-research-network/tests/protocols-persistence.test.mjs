import test from "node:test";
import assert from "node:assert/strict";

await import("../src/catalog/definitions.js");
await import("../src/catalog/build-catalog.js");
await import("../src/domain/unlock-engine.js");
await import("../src/domain/research-transaction.js");
await import("../src/domain/protocols.js");
await import("../src/state/persistence.js");

const catalog = globalThis.IMMUNE.buildCatalog();

function buildProtocolPlayer() {
  const completed = new Set(["CORE-IMMUNE"]);
  for (const node of catalog.nodes) {
    if (node.id.endsWith("-PROTOCOL")) completed.add(node.id);
    if (node.id.startsWith("APEX-") && node.id.endsWith("-GATE")) completed.add(node.id);
    if (node.id.startsWith("CHAR-APEX-")) completed.add(node.id);
    if (node.id.startsWith("PAIR-") && node.id.endsWith("-S4")) completed.add(node.id);
    if (node.id.startsWith("CHAR-PAIR-")) completed.add(node.id);
  }
  return {
    schemaVersion: 1,
    catalogVersion: catalog.version,
    completedNodeIds: [...completed],
    revealedNodeIds: [...completed],
    trackedNodeIds: [],
    equippedProtocolIds: [],
    protocolBandwidth: 6,
    resources: { antigen: 999, biomass: 0, protomass: 999, fusionCore: 999 },
    characterCards: {},
    items: {},
    discoveryFlags: ["apex_memory_found", "apex_sterile_found", "apex_silent_found"],
    inBattle: false,
    view: { x: 1500, y: 1500, zoom: 0.55 }
  };
}

test("protocol loadout enforces bandwidth and one Apex", () => {
  let state = { ...buildProtocolPlayer(), protocolBandwidth: 6, equippedProtocolIds: [] };
  const first = globalThis.IMMUNE.equipProtocol(catalog, state, "APEX-MEMORY-PROTOCOL");
  assert.equal(first.ok, true);
  state = first.state;
  const secondApex = globalThis.IMMUNE.equipProtocol(catalog, state, "APEX-STERILE-PROTOCOL");
  assert.equal(secondApex.ok, false);
  assert.equal(secondApex.error, "apex_limit");
});

test("battle lock prevents equip and unequip", () => {
  const player = { ...buildProtocolPlayer(), inBattle: true };
  const equip = globalThis.IMMUNE.equipProtocol(catalog, player, "APEX-MEMORY-PROTOCOL");
  assert.equal(equip.ok, false);
  assert.equal(equip.error, "loadout_locked_in_battle");

  const loaded = {
    ...buildProtocolPlayer(),
    equippedProtocolIds: ["APEX-MEMORY-PROTOCOL"],
    inBattle: true
  };
  const unequip = globalThis.IMMUNE.unequipProtocol(loaded, "APEX-MEMORY-PROTOCOL");
  assert.equal(unequip.ok, false);
  assert.equal(unequip.error, "loadout_locked_in_battle");
});

test("tracking accepts at most three nodes", () => {
  const base = {
    schemaVersion: 1,
    catalogVersion: catalog.version,
    completedNodeIds: ["CORE-IMMUNE", "CHAR-BASE-T", "CHAR-BASE-B"],
    revealedNodeIds: ["CORE-IMMUNE", "CHAR-BASE-T", "CHAR-BASE-B", "BASE-T-01", "BASE-B-01"],
    trackedNodeIds: [],
    equippedProtocolIds: [],
    protocolBandwidth: 6,
    resources: { antigen: 0, biomass: 0, protomass: 0, fusionCore: 0 },
    characterCards: {},
    items: {},
    discoveryFlags: [],
    inBattle: false,
    view: { x: 1500, y: 1500, zoom: 0.55 }
  };
  let state = base;
  for (const id of ["BASE-T-01", "BASE-B-01", "CHAR-BASE-T"]) {
    const result = globalThis.IMMUNE.trackNode(catalog, state, id, true);
    assert.equal(result.ok, true);
    state = result.state;
  }
  const fourth = globalThis.IMMUNE.trackNode(catalog, state, "CHAR-BASE-B", true);
  assert.equal(fourth.ok, false);
  assert.equal(fourth.error, "track_limit");
});

test("serialize and restore keep valid progress only", () => {
  const player = buildProtocolPlayer();
  player.trackedNodeIds = ["BASE-T-01", "REMOVED-NODE"];
  player.completedNodeIds.push("REMOVED-NODE");
  const raw = globalThis.IMMUNE.serializePlayer(player);
  assert.equal(globalThis.IMMUNE.STORAGE_KEY, "immune.research-network.v1");

  const restored = globalThis.IMMUNE.restorePlayer(raw, catalog, {
    completedNodeIds: ["CORE-IMMUNE"],
    revealedNodeIds: ["CORE-IMMUNE"]
  });
  assert.ok(restored.completedNodeIds.includes("CORE-IMMUNE"));
  assert.ok(!restored.completedNodeIds.includes("REMOVED-NODE"));
  assert.ok(!restored.trackedNodeIds.includes("REMOVED-NODE"));
  assert.equal(restored.inBattle, false);
  assert.equal(restored.unlockedCampaignLevel, "L01");
});

test("restore keeps a valid unlocked campaign level", () => {
  const raw = {
    schemaVersion: 1,
    catalogVersion: catalog.version,
    completedNodeIds: ["CORE-IMMUNE"],
    revealedNodeIds: ["CORE-IMMUNE"],
    unlockedCampaignLevel: "L03"
  };
  const restored = globalThis.IMMUNE.restorePlayer(raw, catalog);
  assert.equal(restored.unlockedCampaignLevel, "L03");
});

test("restore clamps tracked list to max three", () => {
  const raw = {
    schemaVersion: 1,
    catalogVersion: catalog.version,
    completedNodeIds: ["CORE-IMMUNE"],
    revealedNodeIds: ["CORE-IMMUNE", "CHAR-BASE-T", "CHAR-BASE-B", "CHAR-BASE-M"],
    trackedNodeIds: ["CHAR-BASE-T", "CHAR-BASE-B", "CHAR-BASE-M", "CHAR-BASE-N"],
    equippedProtocolIds: [],
    protocolBandwidth: 6,
    resources: { antigen: 0, biomass: 0, protomass: 0, fusionCore: 0 }
  };
  const restored = globalThis.IMMUNE.restorePlayer(raw, catalog);
  assert.equal(restored.trackedNodeIds.length, 3);
});
