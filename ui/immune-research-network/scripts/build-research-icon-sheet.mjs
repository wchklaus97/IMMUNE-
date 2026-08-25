/**
 * Composites category research icons (no characters) into a fixed-cell sprite sheet.
 */
import { mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { createRequire } from "node:module";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const UI = resolve(__dirname, "..");
const REPO = resolve(UI, "../..");
const STAGING =
  "C:/Users/wchkl/.cursor/projects/c-Users-wchkl-Documents-Codex-2026-08-12-https-chatgpt-com-share-6a7b9aee-e840-2/assets";
const require = createRequire(resolve(REPO, "work/package.json"));
const sharp = require("sharp");

const CELL = 256;
const LABEL_H = 36;
const COLS = 8;
const BG = { r: 6, g: 17, b: 29, alpha: 255 };

const ROWS = [
  { label: "CORE", files: ["SHEET-CORE.png"] },
  {
    label: "BASE 01–08",
    files: [
      "SHEET-BASE-01.png",
      "SHEET-BASE-02.png",
      "SHEET-BASE-03.png",
      "SHEET-BASE-04.png",
      "SHEET-BASE-05.png",
      "SHEET-BASE-06.png",
      "SHEET-BASE-07.png",
      "SHEET-BASE-08.png"
    ]
  },
  { label: "PAIR S1 S2 S4", files: ["SHEET-PAIR-S1.png", "SHEET-PAIR-S2.png", "SHEET-PAIR-S4.png"] },
  { label: "TRIPLE", files: ["SHEET-TRIPLE-ROLE.png", "SHEET-TRIPLE-RULE.png", "SHEET-TRIPLE-APEX.png"] },
  { label: "APEX", files: ["SHEET-APEX-GATE.png", "SHEET-APEX-PROTO.png"] },
  {
    label: "UNI DEF EXP WAR MOB FUS SUR",
    files: [
      "SHEET-UNI-DEF.png",
      "SHEET-UNI-EXP.png",
      "SHEET-UNI-WAR.png",
      "SHEET-UNI-MOB.png",
      "SHEET-UNI-FUS.png",
      "SHEET-UNI-SUR.png"
    ]
  },
  {
    label: "STATUS MARK AB COR SLOW INF CHAIN CRIT",
    files: [
      "SHEET-STATUS-MARK.png",
      "SHEET-STATUS-AB.png",
      "SHEET-STATUS-COR.png",
      "SHEET-STATUS-SLOW.png",
      "SHEET-STATUS-INF.png",
      "SHEET-STATUS-CHAIN.png",
      "SHEET-STATUS-CRIT.png"
    ]
  }
];

function findSrc(name) {
  const a = join(STAGING, name);
  const b = join(UI, "assets/nodes", name);
  if (existsSync(a)) return a;
  if (existsSync(b)) return b;
  return null;
}

const width = COLS * CELL;
const height = ROWS.length * (CELL + LABEL_H);
const composites = [];

for (let r = 0; r < ROWS.length; r += 1) {
  const top = r * (CELL + LABEL_H);
  const svg = Buffer.from(
    `<svg width="${width}" height="${LABEL_H}" xmlns="http://www.w3.org/2000/svg">
      <rect width="100%" height="100%" fill="#0c1c2c"/>
      <text x="12" y="24" fill="#5de4ff" font-size="16" font-family="Segoe UI, Microsoft JhengHei, sans-serif">${ROWS[r].label}</text>
    </svg>`
  );
  composites.push({ input: svg, top, left: 0 });
  for (let c = 0; c < ROWS[r].files.length && c < COLS; c += 1) {
    const src = findSrc(ROWS[r].files[c]);
    if (!src) continue;
    const cell = await sharp(src)
      .resize(CELL, CELL, { fit: "cover" })
      .png()
      .toBuffer();
    composites.push({ input: cell, top: top + LABEL_H, left: c * CELL });
  }
}

const outDir = join(REPO, "outputs");
await mkdir(outDir, { recursive: true });
const out = join(outDir, "immune_research_icon_sheet.png");
await sharp({
  create: { width, height, channels: 4, background: BG }
})
  .composite(composites)
  .png()
  .toFile(out);

const uiOut = join(UI, "assets/nodes/research-icon-sheet.png");
await sharp(out).toFile(uiOut);
console.log(`sprite sheet ${COLS}x${ROWS.length} cells of ${CELL}px -> ${out}`);
