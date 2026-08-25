import { readFile, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const IDENTITY = join(__dirname, "../src/catalog/character-identity.js");

await import("../src/catalog/definitions.js");
await import("./../src/catalog/character-identity.js");

const ids = process.argv.slice(2);
const targets =
  ids.length > 0
    ? ids
    : globalThis.IMMUNE.characterIdentity.listNeedingCatalogRedraw();

let source = await readFile(IDENTITY, "utf8");
let changed = 0;

for (const id of targets) {
  const needle = `"${id}": entry({`;
  const withStatus = `"${id}": entry({\n      catalogStatus: "pilot_catalog",`;
  if (!source.includes(needle)) {
    console.warn(`skip missing block: ${id}`);
    continue;
  }
  if (source.includes(`"${id}": entry({\n      catalogStatus: "pilot_catalog"`)) {
    console.log(`already marked: ${id}`);
    continue;
  }
  source = source.replace(needle, withStatus);
  changed += 1;
  console.log(`marked: ${id}`);
}

await writeFile(IDENTITY, source, "utf8");
console.log(`updated ${changed} characters -> pilot_catalog`);
