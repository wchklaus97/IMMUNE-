import test from "node:test";
import assert from "node:assert/strict";

await import("../src/catalog/definitions.js");
await import("../src/catalog/build-catalog.js");
await import("../src/domain/unlock-engine.js");

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

test("a revealed node distinguishes missing prerequisite from missing resource", () => {
  const state = globalThis.IMMUNE.deriveNodeState(catalog, player, "BASE-T-01");
  assert.equal(state.visibility, "revealed");
  assert.equal(state.completion, "incomplete");
  assert.equal(state.eligibility, "missing_prerequisite");
});

test("runtime state keeps visibility completion eligibility selected tracked separate", () => {
  const selectedPlayer = {
    ...player,
    selectedNodeId: "BASE-T-01",
    trackedNodeIds: ["BASE-T-01"],
    resources: { ...player.resources, antigen: 100, protomass: 10 }
  };
  const ready = {
    ...selectedPlayer,
    completedNodeIds: [...player.completedNodeIds, "CHAR-BASE-T"]
  };
  const state = globalThis.IMMUNE.deriveNodeState(catalog, ready, "BASE-T-01");
  assert.equal(state.visibility, "revealed");
  assert.equal(state.completion, "incomplete");
  assert.equal(state.eligibility, "ready");
  assert.equal(state.selected, true);
  assert.equal(state.tracked, true);
  assert.notEqual(state.visibility, state.eligibility);
});

test("hidden apex stays hidden without discovery flag", () => {
  const state = globalThis.IMMUNE.deriveNodeState(catalog, player, "CHAR-APEX-MEMORY");
  assert.equal(state.visibility, "hidden");
  assert.equal(state.eligibility, "hidden");
});

test("completed node reports completed eligibility", () => {
  const done = { ...player, completedNodeIds: [...player.completedNodeIds, "CORE-IMMUNE"] };
  const state = globalThis.IMMUNE.deriveNodeState(catalog, done, "CORE-IMMUNE");
  assert.equal(state.completion, "complete");
  assert.equal(state.eligibility, "completed");
});

test("missing resources are reported separately from prerequisites", () => {
  const fundedPrereq = {
    ...player,
    completedNodeIds: [...player.completedNodeIds, "CHAR-BASE-T"],
    resources: { antigen: 0, biomass: 0, protomass: 0, fusionCore: 0 }
  };
  const state = globalThis.IMMUNE.deriveNodeState(catalog, fundedPrereq, "BASE-T-01");
  assert.equal(state.eligibility, "missing_resource");
  assert.ok(state.missingResources.antigen >= 20);
});

test("family mobility waits for L02 while early 2-1 stays open", () => {
  const fundedT03 = {
    ...player,
    unlockedCampaignLevel: "L01",
    completedNodeIds: [...player.completedNodeIds, "CHAR-BASE-T", "BASE-T-01", "BASE-T-02", "BASE-T-03"],
    revealedNodeIds: [...player.revealedNodeIds, "BASE-T-01", "BASE-T-02", "BASE-T-03", "BASE-T-04"],
    resources: { antigen: 200, biomass: 0, protomass: 10, fusionCore: 0 }
  };
  const locked = globalThis.IMMUNE.deriveNodeState(catalog, fundedT03, "BASE-T-04");
  assert.equal(locked.eligibility, "missing_condition");
  assert.equal(locked.missingConditions[0].min, "L02");

  const opened = globalThis.IMMUNE.deriveNodeState(
    catalog,
    { ...fundedT03, unlockedCampaignLevel: "L02" },
    "BASE-T-04"
  );
  assert.equal(opened.eligibility, "ready");

  const early = globalThis.IMMUNE.deriveNodeState(
    catalog,
    {
      ...player,
      unlockedCampaignLevel: "L01",
      completedNodeIds: [...player.completedNodeIds, "CHAR-BASE-T"],
      resources: { antigen: 200, biomass: 0, protomass: 10, fusionCore: 0 }
    },
    "BASE-T-01"
  );
  assert.equal(early.eligibility, "ready");
});

test("named pair body waits for L03 while pair research does not", () => {
  const pairReady = {
    ...player,
    unlockedCampaignLevel: "L02",
    completedNodeIds: [
      ...player.completedNodeIds,
      "CHAR-BASE-T",
      "CHAR-BASE-B",
      "BASE-T-01",
      "BASE-B-01",
      "PAIR-TB-S1",
      "BASE-T-02",
      "BASE-B-02",
      "PAIR-TB-S2"
    ],
    revealedNodeIds: [...player.revealedNodeIds, "CHAR-PAIR-TB", "PAIR-TB-S1", "PAIR-TB-S2"],
    resources: { antigen: 200, biomass: 0, protomass: 10, fusionCore: 2 }
  };
  const body = globalThis.IMMUNE.deriveNodeState(catalog, pairReady, "CHAR-PAIR-TB");
  assert.equal(body.eligibility, "missing_condition");
  assert.equal(body.missingConditions[0].min, "L03");

  const unlocked = globalThis.IMMUNE.deriveNodeState(
    catalog,
    { ...pairReady, unlockedCampaignLevel: "L03" },
    "CHAR-PAIR-TB"
  );
  assert.equal(unlocked.eligibility, "ready");

  const s1 = globalThis.IMMUNE.deriveNodeState(
    catalog,
    {
      ...player,
      unlockedCampaignLevel: "L01",
      completedNodeIds: [...player.completedNodeIds, "CHAR-BASE-T", "CHAR-BASE-B", "BASE-T-01", "BASE-B-01"],
      revealedNodeIds: [...player.revealedNodeIds, "PAIR-TB-S1"],
      resources: { antigen: 200, biomass: 0, protomass: 10, fusionCore: 0 }
    },
    "PAIR-TB-S1"
  );
  assert.equal(s1.eligibility, "ready");
});
