import { readFile, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(__dirname, "..");
const OUT = join(ROOT, "assets", "form-portrait-prompts.json");

await import("../src/catalog/definitions.js");
await import("../src/assets/game-assets.js");
await import("../src/catalog/character-identity.js");

const { characters } = globalThis.IMMUNE.gameAssets;
const { characterIdentity } = globalThis.IMMUNE;
const prompts = [];

for (const character of Object.values(characters)) {
  if (!character.forms) continue;
  const identity = characterIdentity.CHARACTERS[character.id];
  for (const [formKey, form] of Object.entries(character.forms)) {
    const brief = identity ? characterIdentity.artBrief(character.id, formKey) : "";
    const posture =
      formKey === "fixed"
        ? "FIXED duty pose from identity silhouette.fixed"
        : form.kind === "relay"
          ? "RELAY hover duty from identity silhouette.mobile"
          : "MOBILE duty pose from identity silhouette.mobile";
    prompts.push({
      fileName: `${character.id}-${form.assetSuffix}.png`,
      characterId: character.id,
      formKey,
      prompt: [
        brief || `IMMUNE game character ${character.name}`,
        posture,
        "Cute stylized 3D immune cell game portrait, honest wet jelly material, square icon, flat #00ff00 chroma key, no text, no watermark."
      ].join("\n")
    });
  }
}

await writeFile(OUT, JSON.stringify(prompts, null, 2), "utf8");
console.log(`wrote ${prompts.length} form portrait prompts -> assets/form-portrait-prompts.json`);
