import test from "node:test";
import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = fileURLToPath(new URL("..", import.meta.url));

await import("../src/catalog/definitions.js");
await import("../src/catalog/build-catalog.js");
await import("../src/assets/game-assets.js");

test("asset manifest covers every catalog node and character skill", async () => {
  const manifest = JSON.parse(await readFile(join(ROOT, "assets/manifest.json"), "utf8"));
  const catalog = globalThis.IMMUNE.buildCatalog();
  assert.equal(Object.keys(manifest.nodes).length, 200);
  for (const node of catalog.nodes) {
    assert.ok(manifest.nodes[node.id], `missing node icon for ${node.id}`);
  }
  const chars = globalThis.IMMUNE.gameAssets.characters;
  assert.equal(Object.keys(manifest.characters).length, 31);
  for (const [id, character] of Object.entries(chars)) {
    assert.ok(manifest.characters[id], `missing character asset for ${id}`);
    for (const skill of character.skills) {
      assert.ok(manifest.skills[skill.id], `missing skill icon for ${skill.id}`);
    }
  }
  assert.equal(Object.keys(manifest.defense).length, 14);
  for (const [id, entry] of Object.entries(manifest.defense)) {
    assert.ok(existsSync(join(ROOT, entry.path)), `missing defense svg ${id}`);
  }
});

test("embedded asset bundle stays small and lists node paths", async () => {
  const manifest = JSON.parse(await readFile(join(ROOT, "assets/manifest.json"), "utf8"));
  const bundleSrc = await readFile(join(ROOT, "src/assets/asset-bundle.js"), "utf8");
  assert.ok(bundleSrc.length < 2_000_000, `bundle too large: ${bundleSrc.length}`);
  assert.equal(false, bundleSrc.includes("data:image/png"));
  for (const id of ["CORE-IMMUNE", "CHAR-BASE-T", "CHAR-PAIR-TB"]) {
    assert.match(bundleSrc, new RegExp(manifest.nodes[id].path.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
  }
});
