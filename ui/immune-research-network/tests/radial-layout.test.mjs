import test from "node:test";
import assert from "node:assert/strict";

await import("../src/catalog/definitions.js");
await import("../src/catalog/build-catalog.js");
await import("../src/layout/pair-slots.js");
await import("../src/layout/lod.js");
await import("../src/layout/radial-layout.js");
await import("../src/layout/edge-routing.js");

const catalog = globalThis.IMMUNE.buildCatalog();

test("layout is finite, stable and within the approved world", () => {
  const a = globalThis.IMMUNE.layoutCatalog(catalog);
  const b = globalThis.IMMUNE.layoutCatalog(catalog);
  assert.equal(a.size, 200);
  for (const [id, point] of a) {
    assert.deepEqual(point, b.get(id));
    assert.ok(Number.isFinite(point.x) && Number.isFinite(point.y));
    assert.ok(point.x >= 0 && point.x <= 3000 && point.y >= 0 && point.y <= 3000);
  }
});

test("LOD uses all four approved zoom bands", () => {
  assert.equal(globalThis.IMMUNE.getLod(0.35), "overview");
  assert.equal(globalThis.IMMUNE.getLod(0.8), "structure");
  assert.equal(globalThis.IMMUNE.getLod(1.2), "detail");
  assert.equal(globalThis.IMMUNE.getLod(1.8), "inspect");
  assert.equal(globalThis.IMMUNE.getLod(8), "inspect");
});

test("31 character anchors expose anchor flag", () => {
  const layout = globalThis.IMMUNE.layoutCatalog(catalog);
  const anchors = catalog.nodes.filter((node) => node.kind === "character_anchor");
  assert.equal(anchors.length, 31);
  for (const node of anchors) {
    const point = layout.get(node.id);
    assert.ok(point, `missing layout for ${node.id}`);
    assert.equal(point.anchor, true, `${node.id} should be an anchor`);
  }
});

test("buildEdges references existing layout points", () => {
  const layout = globalThis.IMMUNE.layoutCatalog(catalog);
  const edges = globalThis.IMMUNE.buildEdges(catalog);
  assert.ok(edges.length > 0);
  const kinds = new Set(edges.map((edge) => edge.kind));
  for (const kind of ["required", "dual_source", "optional", "affinity"]) {
    assert.ok(kinds.has(kind), `missing edge kind ${kind}`);
  }
  for (const edge of edges) {
    assert.ok(layout.has(edge.from), `missing from layout ${edge.from}`);
    assert.ok(layout.has(edge.to), `missing to layout ${edge.to}`);
    assert.ok(edge.path.startsWith("M "));
  }
});

test("pair slots match approved fixed table", () => {
  assert.deepEqual(globalThis.IMMUNE.pairLayoutSlots.TB, [300, 980]);
  assert.deepEqual(globalThis.IMMUNE.pairLayoutSlots.MD, [120, 1150]);
  assert.equal(Object.keys(globalThis.IMMUNE.pairLayoutSlots).length, 15);
});
