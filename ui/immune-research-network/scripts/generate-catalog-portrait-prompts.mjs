import { writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(__dirname, "..");
const OUT = join(ROOT, "assets", "catalog-portrait-prompts.json");

await import("../src/catalog/definitions.js");
await import("../src/catalog/character-identity.js");

const { characterIdentity } = globalThis.IMMUNE;

const STYLE =
  "cute stylized 3D immune-cell game portrait, honest wet gelatinous body, glossy jelly membrane, wet specular highlights, soft subsurface glow from inside, vinyl-toy volume, restrained organic detail";

const CAMERA =
  "front-facing catalog portrait camera, centered composition, character fills about 70 percent of frame, square icon crop";

const BACKGROUND = "flat solid chroma key green #00FF00 background, no floor, no pedestal, no terrain";

const FORBIDDEN =
  "NO chest Y glow, NO gold Y medallion, NO gatling gun face, NO golf-ball bump shader, NO tissue platform, NO text, NO watermark, NO letters, NO second body, NO split paint kits";

function catalogPrompt(id) {
  const brief = characterIdentity.artBrief(id, "catalog");
  return `${brief}\n${STYLE}. ${CAMERA}. ${BACKGROUND}. ${FORBIDDEN}.`;
}

const pilotIds = process.argv.slice(2);
const ids =
  pilotIds.length > 0 ? pilotIds : characterIdentity.listNeedingCatalogRedraw();

const allRedraw = characterIdentity.listNeedingCatalogRedraw();
const prompts = ids.map((id) => {
  const character = characterIdentity.CHARACTERS[id];
  if (!character) throw new Error(`unknown character id: ${id}`);
  return {
    fileName: `${id}.png`,
    characterId: id,
    name: character.name,
    catalogStatus: character.catalogStatus,
    prompt: catalogPrompt(id)
  };
});

const bundle = {
  version: "1.0.0",
  generatedAt: new Date().toISOString(),
  phase: "catalog-face-pilot",
  pilotIds: ids,
  remainingRedrawCount: allRedraw.length,
  remainingRedrawIds: allRedraw,
  prompts
};

await writeFile(OUT, JSON.stringify(bundle, null, 2), "utf8");
console.log(`wrote ${prompts.length} catalog portrait prompts -> ${OUT}`);
for (const p of prompts) console.log(`  ${p.characterId} ${p.name}`);
