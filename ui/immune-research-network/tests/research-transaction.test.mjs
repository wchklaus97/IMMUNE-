import test from "node:test";
import assert from "node:assert/strict";

await import("../src/catalog/definitions.js");
await import("../src/catalog/build-catalog.js");
await import("../src/domain/unlock-engine.js");
await import("../src/domain/research-transaction.js");

const catalog = globalThis.IMMUNE.buildCatalog();

const player = {
  schemaVersion: 1,
  catalogVersion: "1.0.0",
  completedNodeIds: ["CORE-IMMUNE"],
  revealedNodeIds: ["CORE-IMMUNE", "CHAR-BASE-T"],
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

const readyPlayer = {
  ...player,
  completedNodeIds: [...player.completedNodeIds, "CHAR-BASE-T"],
  resources: { antigen: 100, biomass: 0, protomass: 10, fusionCore: 0 }
};

test("research purchase deducts once and cannot be double-purchased", () => {
  const funded = structuredClone(readyPlayer);
  const first = globalThis.IMMUNE.researchNode(catalog, funded, "BASE-T-01");
  const second = globalThis.IMMUNE.researchNode(catalog, first.state, "BASE-T-01");
  assert.equal(first.ok, true);
  assert.equal(second.ok, false);
  assert.equal(second.error, "already_completed");
  assert.equal(first.state.resources.antigen, readyPlayer.resources.antigen - 20);
  assert.equal(second.state.resources.antigen, first.state.resources.antigen);
});

test("failed purchase never mutates player resources", () => {
  const before = structuredClone(player);
  const result = globalThis.IMMUNE.researchNode(catalog, player, "BASE-T-01");
  assert.equal(result.ok, false);
  assert.deepEqual(player, before);
});

test("successful research reveals the 2-1 merge, not a linear next slot", () => {
  const funded = structuredClone(readyPlayer);
  const result = globalThis.IMMUNE.researchNode(catalog, funded, "BASE-T-01");
  assert.equal(result.ok, true);
  assert.ok(result.state.completedNodeIds.includes("BASE-T-01"));
  assert.ok(result.state.revealedNodeIds.includes("BASE-T-02"));
  assert.ok(result.state.revealedNodeIds.includes("BASE-T-03"));
  assert.equal(result.state.revealedNodeIds.includes("BASE-T-04"), false);
});

test("resource totals never go negative", () => {
  const poor = {
    ...readyPlayer,
    resources: { antigen: 20, biomass: 0, protomass: 1, fusionCore: 0 }
  };
  const result = globalThis.IMMUNE.researchNode(catalog, poor, "BASE-T-01");
  assert.equal(result.ok, true);
  assert.equal(result.state.resources.antigen, 0);
  assert.ok(result.state.resources.antigen >= 0);
});
