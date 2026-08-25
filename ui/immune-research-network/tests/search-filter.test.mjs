import test from "node:test";
import assert from "node:assert/strict";

await import("../src/catalog/definitions.js");
await import("../src/catalog/build-catalog.js");
await import("../src/domain/unlock-engine.js");
await import("../src/domain/search-filter.js");
await import("../src/layout/radial-layout.js");

const catalog = globalThis.IMMUNE.buildCatalog();

const demoPlayer = {
  schemaVersion: 1,
  catalogVersion: catalog.version,
  completedNodeIds: ["CORE-IMMUNE", "CHAR-BASE-T", "BASE-T-01", "BASE-T-02", "BASE-T-03"],
  revealedNodeIds: [
    "CORE-IMMUNE",
    "CHAR-BASE-T",
    "BASE-T-01",
    "BASE-T-02",
    "BASE-T-03",
    "BASE-T-04"
  ],
  trackedNodeIds: [],
  equippedProtocolIds: [],
  protocolBandwidth: 6,
  resources: { antigen: 10, biomass: 0, protomass: 0, fusionCore: 0 },
  characterCards: {},
  items: {},
  discoveryFlags: [],
  inBattle: false,
  view: { x: 1500, y: 1500, zoom: 0.55 }
};

test("search returns T mobility uniquely and hides undiscovered names", () => {
  const visible = globalThis.IMMUNE.searchCatalog(catalog, demoPlayer, "T 細胞移動資格");
  assert.deepEqual(
    visible.map((node) => node.id),
    ["BASE-T-04"]
  );
  const hiddenName = catalog.nodes.find((node) => node.id === "CHAR-APEX-MEMORY").name;
  assert.deepEqual(globalThis.IMMUNE.searchCatalog(catalog, demoPlayer, hiddenName), []);
});

test("filtering changes emphasis but not layout", () => {
  const before = globalThis.IMMUNE.layoutCatalog(catalog);
  globalThis.IMMUNE.applyFilters(catalog, demoPlayer, { familyIds: ["T"] });
  const after = globalThis.IMMUNE.layoutCatalog(catalog);
  assert.deepEqual([...after.entries()], [...before.entries()]);
});

test("applyFilters down-weights non-matching family nodes", () => {
  const { emphasis } = globalThis.IMMUNE.applyFilters(catalog, demoPlayer, { familyIds: ["T"] });
  assert.equal(emphasis.get("BASE-T-04"), 1);
  assert.equal(emphasis.get("BASE-B-01"), 0.15);
});

test("empty search query returns no results", () => {
  assert.deepEqual(globalThis.IMMUNE.searchCatalog(catalog, demoPlayer, ""), []);
  assert.deepEqual(globalThis.IMMUNE.searchCatalog(catalog, demoPlayer, "   "), []);
});
