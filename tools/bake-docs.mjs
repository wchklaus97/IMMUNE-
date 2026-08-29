import { mkdir, writeFile } from "node:fs/promises";
import { createRequire } from "node:module";
import { basename, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const { chromium } = require("../node_modules/playwright-core/index.js");
const sharp = require("../work/node_modules/sharp");
const { PDFDocument } = require("../work/node_modules/pdf-lib/dist/pdf-lib.js");

const ROOT = resolve(fileURLToPath(new URL(".", import.meta.url)), "..");
const PORT = Number(process.env.PORT || 5180);
const BASE = `http://127.0.0.1:${PORT}`;

const SHOT_IDS = "hero,summary,loop,ux,mechanics,catalog,progression,covers,footer".split(",");

async function launchBrowser() {
  const channels = [process.env.PW_CHANNEL, "msedge", "chrome", "chromium"].filter(Boolean);
  let lastError;
  for (const channel of channels) {
    try {
      return await chromium.launch({
        channel: channel === "chromium" ? undefined : channel,
        headless: true
      });
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError || new Error("Unable to launch a Chromium-based browser");
}

async function waitForImages(page) {
  await page.evaluate(async () => {
    const imgs = [...document.images];
    await Promise.all(
      imgs.map(
        (img) =>
          img.complete
            ? Promise.resolve()
            : new Promise((resolve) => {
                img.addEventListener("load", resolve, { once: true });
                img.addEventListener("error", resolve, { once: true });
              })
      )
    );
  });
  await page.waitForTimeout(200);
}

async function bakeUx(browser, htmlPath, pngPath) {
  const context = await browser.newContext({
    viewport: { width: 3360, height: 1440 },
    deviceScaleFactor: 1
  });
  const page = await context.newPage();
  await page.goto(`${BASE}/${htmlPath.replace(/\\/g, "/")}`, { waitUntil: "networkidle" });
  await page.waitForSelector("#board");
  await waitForImages(page);
  const board = page.locator("#board");
  await board.screenshot({ path: resolve(ROOT, pngPath), type: "png" });
  await context.close();
  console.log("baked", pngPath);
}

async function bakeManager(browser, htmlPath, jpgPath, pdfPath) {
  const context = await browser.newContext({
    viewport: { width: 1600, height: 1200 },
    deviceScaleFactor: 1
  });
  const page = await context.newPage();
  await page.goto(`${BASE}/${htmlPath.replace(/\\/g, "/")}`, { waitUntil: "networkidle" });
  await waitForImages(page);

  const buffers = [];
  for (const id of SHOT_IDS) {
    const block = page.locator(`[data-shot="${id}"]`);
    const count = await block.count();
    if (!count) throw new Error(`Missing .shot-block data-shot="${id}" in ${htmlPath}`);
    const buf = await block.first().screenshot({ type: "png" });
    buffers.push(buf);
    console.log("section", id);
  }
  await context.close();

  const images = await Promise.all(
    buffers.map((buf) => sharp(buf).resize({ width: 1600, withoutEnlargement: true }).png().toBuffer())
  );
  const metas = await Promise.all(images.map((buf) => sharp(buf).metadata()));
  const width = 1600;
  const height = metas.reduce((sum, meta) => sum + (meta.height || 0), 0);
  const canvas = sharp({
    create: {
      width,
      height,
      channels: 3,
      background: { r: 6, g: 17, b: 29 }
    }
  });

  let top = 0;
  const composites = [];
  for (let i = 0; i < images.length; i += 1) {
    composites.push({ input: images[i], top, left: 0 });
    top += metas[i].height || 0;
  }

  const jpgFull = resolve(ROOT, jpgPath);
  await canvas.composite(composites).jpeg({ quality: 86, mozjpeg: true }).toFile(jpgFull);
  console.log("baked", jpgPath);

  const pdf = await PDFDocument.create();
  const jpgBytes = await sharp(jpgFull).jpeg({ quality: 84 }).toBuffer();
  const embedded = await pdf.embedJpg(jpgBytes);
  const pageWidth = 595.28;
  const scale = pageWidth / embedded.width;
  const pageHeight = embedded.height * scale;
  const pdfPage = pdf.addPage([pageWidth, pageHeight]);
  pdfPage.drawImage(embedded, { x: 0, y: 0, width: pageWidth, height: pageHeight });
  await mkdir(resolve(ROOT, "docs"), { recursive: true });
  await writeFile(resolve(ROOT, pdfPath), await pdf.save());
  console.log("baked", pdfPath);
}

async function main() {
  const browser = await launchBrowser();
  try {
    await bakeUx(
      browser,
      "docs/ux-wireframe.html",
      "docs/IMMUNE-Permanent-Research-Network-UX-Wireframe-21x9.png"
    );
    await bakeUx(
      browser,
      "docs/ux-wireframe-zh.html",
      "docs/IMMUNE-Permanent-Research-Network-UX-Wireframe-21x9-zh.png"
    );
    await bakeManager(
      browser,
      "docs/manager-overview.html",
      "docs/IMMUNE-Permanent-Research-Network-Manager-Overview-poster.jpg",
      "docs/IMMUNE-Permanent-Research-Network-Manager-Overview.pdf"
    );
    await bakeManager(
      browser,
      "docs/manager-overview-zh.html",
      "docs/IMMUNE-Permanent-Research-Network-Manager-Overview-zh-poster.jpg",
      "docs/IMMUNE-Permanent-Research-Network-Manager-Overview-zh.pdf"
    );
  } finally {
    await browser.close();
  }
  console.log("OK  posters baked");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
