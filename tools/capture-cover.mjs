import { mkdir, copyFile } from "node:fs/promises";
import { createRequire } from "node:module";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const { chromium } = require("../work/node_modules/playwright-core/index.js");
const sharp = require("../work/node_modules/sharp");

const ROOT = resolve(fileURLToPath(new URL(".", import.meta.url)), "..");
const PORT = Number(process.env.PORT || 5180);
const GAME_URL = `http://127.0.0.1:${PORT}/ui/immune-research-network/?cover=1`;
const COVER = { width: 1536, height: 1024, deviceScaleFactor: 1 };
const PNG_OUT = resolve(ROOT, "assets", "cover-16x9-from-ui.png");
const WEBP_OUT = resolve(ROOT, "assets", "cover-16x9.webp");
const AI_BACKUP = resolve(ROOT, "assets", "cover-16x9-ai.webp");

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

async function main() {
  await mkdir(resolve(ROOT, "assets"), { recursive: true });
  if (existsSync(WEBP_OUT) && !existsSync(AI_BACKUP)) {
    await copyFile(WEBP_OUT, AI_BACKUP);
  }

  const browser = await launchBrowser();
  try {
    const context = await browser.newContext({
      viewport: { width: COVER.width, height: COVER.height },
      deviceScaleFactor: COVER.deviceScaleFactor
    });
    const page = await context.newPage();
    await page.addInitScript(() => {
      try {
        localStorage.removeItem("immune.research-network.v1");
      } catch {
        /* ignore */
      }
    });
    await page.goto(GAME_URL, { waitUntil: "domcontentloaded" });
    await page.waitForFunction(
      () =>
        Boolean(window.IMMUNE?.isCoverMode) &&
        document.documentElement.classList.contains("is-cover") &&
        document.querySelectorAll(".cover-portrait").length >= 6,
      { timeout: 30000 }
    );
    await page.waitForTimeout(1200);
    await page.screenshot({ path: PNG_OUT, type: "png" });
    await context.close();
  } finally {
    await browser.close();
  }

  await sharp(PNG_OUT)
    .resize(COVER.width, COVER.height)
    .webp({ quality: 86 })
    .toFile(WEBP_OUT);
  console.log("OK  16:9 cover from live UI →", WEBP_OUT);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
