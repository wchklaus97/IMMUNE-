import { mkdir } from "node:fs/promises";
import { existsSync, readdirSync } from "node:fs";
import { createRequire } from "node:module";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(__dirname, "..");
const CHAR_DIR = join(ROOT, "assets/characters");
const PREVIEW_DIR = join(CHAR_DIR, "previews");
const require = createRequire(resolve(ROOT, "../../work/package.json"));

export function previewName(fileName) {
  return fileName.replace(/\.png$/i, ".jpg");
}

export async function generateDatasheetPreviews() {
  let sharp;
  try {
    sharp = require("sharp");
  } catch (error) {
    console.warn("sharp unavailable, skip jpg previews:", error.message);
    return { written: 0, dir: PREVIEW_DIR, skipped: true };
  }
  await mkdir(PREVIEW_DIR, { recursive: true });
  const sources = readdirSync(CHAR_DIR).filter((name) => /^CHAR-.*\.png$/i.test(name));
  let written = 0;
  for (const name of sources) {
    const src = join(CHAR_DIR, name);
    const dest = join(PREVIEW_DIR, previewName(name));
    await sharp(src)
      .resize({ width: 512, height: 512, fit: "cover", withoutEnlargement: true })
      .jpeg({ quality: 72, mozjpeg: true })
      .toFile(dest);
    written += 1;
  }
  return { written, dir: PREVIEW_DIR };
}

const invoked = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invoked) {
  const result = await generateDatasheetPreviews();
  console.log(`wrote ${result.written} datasheet previews -> ${result.dir}`);
}
