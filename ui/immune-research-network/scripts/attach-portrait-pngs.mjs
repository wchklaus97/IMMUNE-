import { copyFile, readFile, writeFile, mkdir } from "node:fs/promises";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(__dirname, "..");
const MANIFEST = join(ROOT, "assets/manifest.json");
const stagingArg = process.argv[2] || process.env.IMMUNE_ASSET_STAGING || "";
const STAGING = stagingArg ? resolve(stagingArg) : null;

const manifest = JSON.parse(await readFile(MANIFEST, "utf8"));

async function copyAsset(fileName, bucket) {
  if (!STAGING) return null;
  const src = join(STAGING, fileName);
  if (!existsSync(src)) return null;
  const rel = `assets/${bucket}/${fileName}`;
  const dest = join(ROOT, rel);
  await mkdir(join(ROOT, `assets/${bucket}`), { recursive: true });
  await copyFile(src, dest);
  return rel;
}

let attached = 0;
for (const id of Object.keys(manifest.characters || {})) {
  const entry = manifest.characters[id];
  if (!entry.forms) entry.forms = {};

  const legacy = await copyAsset(`${id}.png`, "characters");
  if (legacy) {
    entry.png = legacy;
    if (!entry.forms.fixed) entry.forms.fixed = legacy;
    attached += 1;
  }

  for (const [formKey, suffix] of [
    ["fixed", "fixed"],
    ["mobile", "mobile"],
    ["mobile", "relay"]
  ]) {
    const rel = await copyAsset(`${id}-${suffix}.png`, "characters");
    if (!rel) continue;
    entry.forms[formKey] = rel;
    attached += 1;
  }
}

for (const id of Object.keys(manifest.defense || {})) {
  const rel = await copyAsset(`${id}.png`, "defense");
  if (rel) {
    manifest.defense[id].png = rel;
    attached += 1;
  }
}

await writeFile(MANIFEST, JSON.stringify(manifest, null, 2), "utf8");
console.log(
  STAGING
    ? `attached ${attached} png assets from ${STAGING}`
    : "no portrait staging supplied; generated SVG fallbacks remain active"
);
