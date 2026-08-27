import { mkdir, writeFile, readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(__dirname, "..");
const ASSETS = join(ROOT, "assets");

let previousManifest = {};
try {
  previousManifest = JSON.parse(await readFile(join(ASSETS, "manifest.json"), "utf8"));
} catch {
  previousManifest = {};
}

function carryMedia(bucket, id, target) {
  const previous = previousManifest?.[bucket]?.[id];
  if (!previous) return target;
  if (previous.png && existsSync(resolve(ROOT, previous.png))) target.png = previous.png;
  if (previous.forms) {
    const forms = Object.fromEntries(
      Object.entries(previous.forms).filter(([, path]) => path && existsSync(resolve(ROOT, path)))
    );
    if (Object.keys(forms).length) target.forms = forms;
  }
  return target;
}

await import("../src/catalog/definitions.js");
await import("../src/catalog/build-catalog.js");
await import("../src/catalog/validate-catalog.js");
await import("../src/assets/game-assets.js");

const catalog = globalThis.IMMUNE.buildCatalog();
const { characters, defenseTargets } = globalThis.IMMUNE.gameAssets;
const families = globalThis.IMMUNE.definitions.families;

const familyColor = Object.fromEntries(families.map(([id, , color]) => [id, color]));

const KIND_SHAPES = {
  core: "hex",
  character_anchor: "circle",
  base_character_research: "rounded",
  pair_research: "diamond",
  triple_research: "triangle",
  apex_research: "star",
  universal: "pentagon",
  status: "octagon"
};

function glyphFor(name, kind) {
  if (kind === "core") return "核";
  const trimmed = (name || "").replace(/｜.*$/, "").trim();
  return trimmed.slice(0, 2) || "研";
}

function shapePath(shape, r) {
  switch (shape) {
    case "hex": {
      const pts = [];
      for (let i = 0; i < 6; i += 1) {
        const a = (Math.PI / 3) * i - Math.PI / 6;
        pts.push(`${Math.cos(a) * r},${Math.sin(a) * r}`);
      }
      return `<polygon points="${pts.join(" ")}" />`;
    }
    case "diamond":
      return `<polygon points="0,${-r} ${r},0 0,${r} ${-r},0" />`;
    case "triangle":
      return `<polygon points="0,${-r} ${r * 0.95},${r * 0.8} ${-r * 0.95},${r * 0.8}" />`;
    case "star": {
      const pts = [];
      for (let i = 0; i < 10; i += 1) {
        const rad = i % 2 === 0 ? r : r * 0.45;
        const a = (Math.PI / 5) * i - Math.PI / 2;
        pts.push(`${Math.cos(a) * rad},${Math.sin(a) * rad}`);
      }
      return `<polygon points="${pts.join(" ")}" />`;
    }
    case "pentagon": {
      const pts = [];
      for (let i = 0; i < 5; i += 1) {
        const a = ((Math.PI * 2) / 5) * i - Math.PI / 2;
        pts.push(`${Math.cos(a) * r},${Math.sin(a) * r}`);
      }
      return `<polygon points="${pts.join(" ")}" />`;
    }
    case "octagon": {
      const pts = [];
      for (let i = 0; i < 8; i += 1) {
        const a = ((Math.PI * 2) / 8) * i - Math.PI / 8;
        pts.push(`${Math.cos(a) * r},${Math.sin(a) * r}`);
      }
      return `<polygon points="${pts.join(" ")}" />`;
    }
    case "rounded":
      return `<rect x="${-r}" y="${-r}" width="${r * 2}" height="${r * 2}" rx="${r * 0.35}" />`;
    default:
      return `<circle cx="0" cy="0" r="${r}" />`;
  }
}

function blendColors(colors) {
  if (!colors.length) return "#7ec8ff";
  if (colors.length === 1) return colors[0];
  const toRgb = (hex) => {
    const h = hex.replace("#", "");
    return [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)];
  };
  const rgb = colors.map(toRgb).reduce(
    (acc, cur) => [acc[0] + cur[0], acc[1] + cur[1], acc[2] + cur[2]],
    [0, 0, 0]
  );
  const n = colors.length;
  const clamp = (v) => Math.max(0, Math.min(255, Math.round(v / n)));
  return `#${clamp(rgb[0]).toString(16).padStart(2, "0")}${clamp(rgb[1]).toString(16).padStart(2, "0")}${clamp(rgb[2]).toString(16).padStart(2, "0")}`;
}

function nodeSvg(node) {
  const shape = KIND_SHAPES[node.kind] || "circle";
  const colors = (node.familyIds || []).map((f) => familyColor[f]).filter(Boolean);
  const fill = blendColors(colors.length ? colors : ["#45bdf2"]);
  const stroke = node.kind === "character_anchor" || node.kind === "core" ? "#ffffff" : "#0b1520";
  const r = node.kind === "core" ? 44 : node.kind === "character_anchor" ? 36 : 28;
  const glyph = glyphFor(node.name, node.kind);
  const fontSize = glyph.length > 1 ? 14 : 18;
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-48 -48 96 96" width="96" height="96">
  <defs>
    <radialGradient id="g" cx="35%" cy="30%" r="70%">
      <stop offset="0%" stop-color="${fill}" stop-opacity="1"/>
      <stop offset="100%" stop-color="#0a1420" stop-opacity="0.95"/>
    </radialGradient>
  </defs>
  <g fill="url(#g)" stroke="${stroke}" stroke-width="2.5">
    ${shapePath(shape, r)}
  </g>
  <text x="0" y="6" text-anchor="middle" font-family="Segoe UI, Microsoft JhengHei, sans-serif" font-size="${fontSize}" font-weight="700" fill="#f5fbff">${glyph}</text>
</svg>`;
}

function skillSvg(skill, character) {
  const colors = (character.families || []).map((f) => familyColor[f]).filter(Boolean);
  const fill = blendColors(colors.length ? colors : ["#a878ff"]);
  const slotIcon = { passive: "被", active: "技", fixed: "固", protocol: "協", apex: "極" }[skill.slot] || "技";
  const label = skill.name.replace(/｜.*$/, "").slice(0, 2);
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-40 -40 80 80" width="80" height="80">
  <circle cx="0" cy="0" r="34" fill="${fill}" stroke="#ffffff" stroke-width="2"/>
  <circle cx="0" cy="0" r="24" fill="none" stroke="#ffffff" stroke-opacity="0.35" stroke-width="1.5" stroke-dasharray="4 3"/>
  <text x="0" y="-4" text-anchor="middle" font-size="16" font-weight="800" fill="#fff">${slotIcon}</text>
  <text x="0" y="16" text-anchor="middle" font-size="11" font-weight="600" fill="#eef6ff">${label}</text>
</svg>`;
}

function defenseSvg(target) {
  const palette = {
    core: "#ff6b6b",
    structure: "#5de4ff",
    pathogen: "#f2b84b",
    hazard: "#d28cff",
    boss: "#ff4757"
  };
  const fill = palette[target.category] || "#91aec1";
  const iconById = {
    "ENEMY-FUNGUS": "真",
    "ENEMY-TOXIN": "毒"
  };
  const icon = iconById[target.id] || { core: "核", structure: "塔", pathogen: "菌", hazard: "染", boss: "王" }[target.category] || "敵";
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-40 -40 80 80" width="80" height="80">
  <rect x="-32" y="-32" width="64" height="64" rx="14" fill="${fill}" stroke="#fff" stroke-width="2"/>
  <path d="M-18,-8 L0,-22 L18,-8 L12,18 L-12,18 Z" fill="#0b1520" fill-opacity="0.35"/>
  <text x="0" y="8" text-anchor="middle" font-size="20" font-weight="800" fill="#fff">${icon}</text>
</svg>`;
}

function characterSvg(character) {
  const colors = (character.families || []).map((f) => familyColor[f]).filter(Boolean);
  const fill = blendColors(colors.length ? colors : ["#45bdf2"]);
  const initial = character.name.slice(0, 1);
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-64 -64 128 128" width="128" height="128">
  <circle cx="0" cy="0" r="58" fill="${fill}" stroke="#fff" stroke-width="3"/>
  <ellipse cx="0" cy="8" rx="34" ry="28" fill="#ffffff" fill-opacity="0.22"/>
  <circle cx="-14" cy="-6" r="6" fill="#fff"/>
  <circle cx="14" cy="-6" r="6" fill="#fff"/>
  <circle cx="-14" cy="-6" r="3" fill="#0b1520"/>
  <circle cx="14" cy="-6" r="3" fill="#0b1520"/>
  <path d="M-16,18 Q0,30 16,18" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round"/>
  <text x="0" y="46" text-anchor="middle" font-size="14" font-weight="700" fill="#fff">${initial}</text>
</svg>`;
}

async function writeSvg(subdir, name, svg) {
  const folder = join(ASSETS, subdir);
  await mkdir(folder, { recursive: true });
  await writeFile(join(folder, name), svg, "utf8");
  return `assets/${subdir}/${name}`;
}

const manifest = {
  version: "1.0.0",
  generatedAt: new Date().toISOString(),
  nodes: {},
  skills: {},
  characters: {},
  defense: {}
};

for (const node of catalog.nodes) {
  const rel = await writeSvg("nodes", `${node.id}.svg`, nodeSvg(node));
  manifest.nodes[node.id] = carryMedia("nodes", node.id, { path: rel, name: node.name, kind: node.kind });
}

for (const [charId, character] of Object.entries(characters)) {
  const rel = await writeSvg("characters", `${charId}.svg`, characterSvg(character));
  manifest.characters[charId] = carryMedia("characters", charId, { path: rel, name: character.name, png: null });
  for (const skill of character.skills) {
    const skillRel = await writeSvg("skills", `${skill.id}.svg`, skillSvg(skill, character));
    manifest.skills[skill.id] = { path: skillRel, name: skill.name, characterId: charId, slot: skill.slot };
  }
}

for (const target of defenseTargets) {
  const rel = await writeSvg("defense", `${target.id}.svg`, defenseSvg(target));
  manifest.defense[target.id] = carryMedia("defense", target.id, {
    path: rel,
    name: target.name,
    category: target.category
  });
}

await writeFile(join(ASSETS, "manifest.json"), JSON.stringify(manifest, null, 2), "utf8");

console.log(
  [
    `nodes: ${Object.keys(manifest.nodes).length}`,
    `characters: ${Object.keys(manifest.characters).length}`,
    `skills: ${Object.keys(manifest.skills).length}`,
    `defense: ${Object.keys(manifest.defense).length}`,
    `manifest: assets/manifest.json`
  ].join(" / ")
);
