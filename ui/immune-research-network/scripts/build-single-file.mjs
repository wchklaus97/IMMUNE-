import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(__dirname, "..");
const OUTPUT = resolve(ROOT, "../../outputs/immune_research_network_v1.html");

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

async function inlineLocalAssets(html, root) {
  for (const href of [...html.matchAll(/<link[^>]+href="([^"]+\.css)"[^>]*>/g)].map((m) => m[1])) {
    const css = await readFile(resolve(root, href), "utf8");
    html = html.replace(
      new RegExp(`<link[^>]+href="${escapeRegExp(href)}"[^>]*>`),
      `<style>\n${css}\n</style>`
    );
  }
  for (const src of [...html.matchAll(/<script[^>]+src="([^"]+\.js)"[^>]*><\/script>/g)].map((m) => m[1])) {
    const js = (await readFile(resolve(root, src), "utf8")).replace(/<\/script/gi, "<\\/script");
    html = html.replace(
      new RegExp(`<script[^>]+src="${escapeRegExp(src)}"[^>]*><\\/script>`),
      `<script>\n${js}\n<\/script>`
    );
  }
  return html;
}

async function main() {
  await import("../src/catalog/definitions.js");
  await import("../src/catalog/build-catalog.js");
  await import("../src/catalog/validate-catalog.js");

  const catalog = globalThis.IMMUNE.buildCatalog();
  const validation = globalThis.IMMUNE.validateCatalog(catalog);
  const anchors = catalog.nodes.filter((node) => node.kind === "character_anchor").length;

  let html = await readFile(resolve(ROOT, "index.html"), "utf8");
  html = await inlineLocalAssets(html, ROOT);

  const forbidden = [/src="/, /href="src\//, /fetch\(/, /import\(/];
  for (const pattern of forbidden) {
    if (pattern.test(html)) {
      throw new Error(`Build output contains forbidden pattern: ${pattern}`);
    }
  }

  await mkdir(dirname(OUTPUT), { recursive: true });
  await writeFile(OUTPUT, html, "utf8");

  console.log(
    [
      `${catalog.nodes.length} nodes`,
      `${anchors} anchors`,
      validation.valid ? "valid DAG" : `invalid: ${validation.errors.join(", ")}`,
      "no external runtime assets",
      `written ${OUTPUT}`
    ].join(" / ")
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
