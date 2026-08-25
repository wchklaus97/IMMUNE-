import { readFile, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const OUT = join(__dirname, "../staging/catalog-pilot/preview.html");

await import("../src/catalog/definitions.js");
await import("../src/catalog/build-catalog.js");
await import("../src/catalog/character-identity.js");

const { CHARACTERS } = globalThis.IMMUNE.characterIdentity;
const catalog = globalThis.IMMUNE.buildCatalog();
const anchors = catalog.nodes
  .filter((n) => n.kind === "character_anchor")
  .map((n) => ({ id: n.id, name: n.name, families: CHARACTERS[n.id]?.families?.join("+") || "" }));

const cards = anchors
  .map(
    (a) => `
    <article class="card">
      <header>
        <h2>${a.name}</h2>
        <div class="id">${a.id} · ${a.families} · ${CHARACTERS[a.id]?.catalogStatus || ""}</div>
      </header>
      <div class="thumb"><img src="${a.id}.png" alt="${a.name}" loading="lazy"></div>
    </article>`
  )
  .join("");

const html = `<!doctype html>
<html lang="zh-Hant">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>IMMUNE｜31 目錄臉全集</title>
  <style>
    :root {
      --bg: #06111d; --panel: #0c1c2c; --border: #27506a;
      --text: #e9f6ff; --muted: #91aec1; --cyan: #5de4ff;
      --font: "Segoe UI", "Microsoft JhengHei", sans-serif;
    }
    * { box-sizing: border-box; }
    body { margin: 0; font-family: var(--font); background: var(--bg); color: var(--text); padding: 24px; }
    h1 { margin: 0 0 8px; font-size: 22px; }
    p { color: var(--muted); margin: 0 0 24px; line-height: 1.5; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; }
    .card { background: var(--panel); border: 1px solid var(--border); border-radius: 12px; overflow: hidden; }
    .card header { padding: 10px 12px 8px; border-bottom: 1px solid var(--border); }
    .card h2 { margin: 0; font-size: 15px; }
    .card .id { color: var(--cyan); font-size: 11px; margin-top: 4px; line-height: 1.3; }
    .thumb { background: #00ff00; padding: 8px; }
    .thumb img { width: 100%; height: auto; display: block; border-radius: 6px; }
  </style>
</head>
<body>
  <h1>IMMUNE 31 目錄臉</h1>
  <p>identity workflow 批次完成 · ${anchors.length} anchors · 更新 ${new Date().toISOString().slice(0, 10)}</p>
  <div class="grid">${cards}</div>
</body>
</html>`;

await writeFile(OUT, html, "utf8");
console.log(`wrote preview with ${anchors.length} cards -> ${OUT}`);
