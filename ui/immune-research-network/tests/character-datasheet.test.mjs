import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildSheetPayload, renderDatasheet } from "../scripts/build-character-datasheet.mjs";

const ROOT = fileURLToPath(new URL("..", import.meta.url));

test("datasheet payload covers 31 characters and both form portraits", async () => {
  const manifest = JSON.parse(await readFile(join(ROOT, "assets/manifest.json"), "utf8"));
  const payload = buildSheetPayload(manifest);
  assert.equal(payload.characters.length, 31);
  const macrophage = payload.characters.find((c) => c.id === "CHAR-BASE-M");
  assert.equal(macrophage.name, "巨噬細胞");
  assert.equal(macrophage.forms.catalog.src, "characters/CHAR-BASE-M.png");
  assert.equal(macrophage.forms.fixed.src, "characters/CHAR-BASE-M-fixed.png");
  assert.equal(macrophage.forms.mobile.src, "characters/CHAR-BASE-M-mobile.png");
  assert.equal(macrophage.forms.fixed.preview, "characters/previews/CHAR-BASE-M-fixed.jpg");
  const antibody = payload.characters.find((c) => c.id === "CHAR-BASE-A");
  assert.equal(antibody.forms.mobile.kind, "relay");
  assert.equal(antibody.forms.mobile.src, "characters/CHAR-BASE-A-relay.png");
  for (const character of payload.characters) {
    for (const form of Object.values(character.forms)) {
      assert.ok(existsSync(join(ROOT, "assets", form.src)), `missing ${form.src}`);
    }
  }
});

test("datasheet html inlines every character id and form file", async () => {
  const manifest = JSON.parse(await readFile(join(ROOT, "assets/manifest.json"), "utf8"));
  const template = await readFile(join(ROOT, "scripts/datasheet-page.html"), "utf8");
  const html = renderDatasheet(template, buildSheetPayload(manifest), "assets/");
  assert.match(html, /CHAR-BASE-M\.png/);
  assert.match(html, /CHAR-BASE-M-fixed\.png/);
  assert.match(html, /CHAR-BASE-A-relay\.png/);
  assert.match(html, /CHAR-PRIME-mobile\.png/);
  assert.equal((html.match(/CHAR-(BASE|PAIR|TRIPLE|APEX|PRIME)/g) || []).length > 31, true);
});
