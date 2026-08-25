import { existsSync, statSync } from "node:fs";
import { readFile, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(__dirname, "..");
const ASSETS = join(ROOT, "assets");
const OUT = join(ROOT, "src/assets/asset-bundle.js");
const MAX_EMBED_BYTES = 24 * 1024;

const manifest = JSON.parse(await readFile(join(ASSETS, "manifest.json"), "utf8"));
const dataUrls = {};
let skipped = 0;

function shouldEmbed(relativePath) {
  if (!relativePath) return false;
  if (relativePath.startsWith("assets/characters/")) return false;
  if (!relativePath.toLowerCase().endsWith(".svg")) return false;
  return true;
}

async function embedPath(relativePath) {
  if (!shouldEmbed(relativePath)) {
    skipped += 1;
    return;
  }
  const abs = join(ROOT, relativePath.replace(/\//g, "\\"));
  if (!existsSync(abs)) {
    skipped += 1;
    return;
  }
  if (statSync(abs).size > MAX_EMBED_BYTES) {
    skipped += 1;
    return;
  }
  const body = await readFile(abs);
  dataUrls[relativePath] = `data:image/svg+xml;base64,${body.toString("base64")}`;
}

for (const bucket of ["nodes", "skills", "characters", "defense"]) {
  for (const entry of Object.values(manifest[bucket] || {})) {
    if (entry.path) await embedPath(entry.path);
    if (entry.png) skipped += 1;
    if (entry.forms) {
      skipped += Object.keys(entry.forms).length;
    }
  }
}

const bundle = {
  version: manifest.version,
  manifest,
  dataUrls
};

const js = `(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});
  IMMUNE.assets = IMMUNE.assets || {};
  IMMUNE.assets.setEmbeddedBundle(${JSON.stringify(bundle)});
})(globalThis);
`;

await writeFile(OUT, js, "utf8");
console.log(
  `embedded ${Object.keys(dataUrls).length} svg icons, skipped ${skipped} portraits/pngs -> src/assets/asset-bundle.js (${js.length} bytes)`
);
