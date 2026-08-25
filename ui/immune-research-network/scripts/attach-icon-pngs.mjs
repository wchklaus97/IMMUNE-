import { copyFile, readFile, writeFile, mkdir, readdir } from "node:fs/promises";
import { join, resolve, extname } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(__dirname, "..");
const MANIFEST = join(ROOT, "assets/manifest.json");
const STAGING = process.argv[2]
  ? resolve(process.argv[2])
  : "C:/Users/wchkl/.cursor/projects/c-Users-wchkl-Documents-Codex-2026-08-12-https-chatgpt-com-share-6a7b9aee-e840-2/assets";

const manifest = JSON.parse(await readFile(MANIFEST, "utf8"));

async function findPng(id) {
  const names = [`${id}.png`];
  const folders = [STAGING, join(STAGING, "skills"), join(STAGING, "nodes")];
  for (const folder of folders) {
    for (const name of names) {
      const src = join(folder, name);
      if (existsSync(src)) return src;
    }
  }
  return null;
}

async function attach(id, bucket, entry) {
  const src = await findPng(id);
  if (!src) return false;
  const rel = `assets/${bucket}/${id}.png`;
  await mkdir(join(ROOT, `assets/${bucket}`), { recursive: true });
  await copyFile(src, join(ROOT, rel));
  entry.png = rel;
  if (!entry.path) entry.path = rel.replace(".png", ".svg");
  return true;
}

let attached = 0;
for (const [id, entry] of Object.entries(manifest.skills || {})) {
  if (await attach(id, "skills", entry)) attached += 1;
}
for (const [id, entry] of Object.entries(manifest.nodes || {})) {
  if (await attach(id, "nodes", entry)) attached += 1;
}

await writeFile(MANIFEST, JSON.stringify(manifest, null, 2), "utf8");
console.log(`attached ${attached} skill/node pngs from ${STAGING}`);
