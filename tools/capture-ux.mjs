import { mkdir } from "node:fs/promises";
import { createRequire } from "node:module";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { pathToFileURL } from "node:url";

const require = createRequire(import.meta.url);
const { chromium } = require("../work/node_modules/playwright-core/index.js");

const ROOT = resolve(fileURLToPath(new URL(".", import.meta.url)), "..");
const OUT = resolve(ROOT, "tools", "screenshots");
const PORT = Number(process.env.PORT || 5180);
const GAME_URL = `http://127.0.0.1:${PORT}/ui/immune-research-network/`;

const DECK = { width: 1280, height: 800, deviceScaleFactor: 1 };
const DESKTOP = { width: 1920, height: 1080, deviceScaleFactor: 1 };
const LANDSCAPE = { width: 1280, height: 720, deviceScaleFactor: 1 };

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

async function waitForApp(page) {
  await page.waitForFunction(
    () =>
      Boolean(window.IMMUNE?._app?.store) &&
      document.querySelector(".brand-title")?.textContent === "IMMUNE",
    { timeout: 30000 }
  );
  await page.waitForTimeout(900);
}

async function resetDemo(page) {
  await page.addInitScript(() => {
    try {
      localStorage.removeItem("immune.research-network.v1");
    } catch {
      /* ignore */
    }
  });
}

async function selectNode(page, nodeId, zoom = 1.1) {
  await page.evaluate(
    ({ nodeId, zoom }) => {
      const app = window.IMMUNE._app;
      app.store.dispatch({ type: "SELECT_NODE", nodeId });
      app.store.dispatch({ type: "SET_ROUTE_FOCUS", nodeId });
      const point = app.layout.get(nodeId);
      if (point) app.panZoom.focusPoint(point, zoom);
    },
    { nodeId, zoom }
  );
  await page.waitForTimeout(500);
}

async function setViewMode(page, mode) {
  await page.evaluate((mode) => {
    window.IMMUNE._app.store.dispatch({ type: "SET_VIEW_MODE", mode });
  }, mode);
  await page.waitForTimeout(350);
}

async function clickToolbar(page, action) {
  await page.click(`[data-action="${action}"]`);
  await page.waitForTimeout(500);
}

async function shot(page, name) {
  const file = resolve(OUT, name);
  await page.screenshot({ path: file, type: "png" });
  console.log("shot", name);
}

async function capturePhoneJourney(page) {
  await page.setViewportSize({ width: DECK.width, height: DECK.height });
  await page.goto(GAME_URL, { waitUntil: "domcontentloaded" });
  await waitForApp(page);

  await clickToolbar(page, "fit-all");
  await shot(page, "ux-01-fit-all.png");

  await clickToolbar(page, "home");
  await shot(page, "ux-02-core.png");

  await selectNode(page, "BASE-T-03", 1.15);
  await shot(page, "ux-03-play-hud.png");

  await selectNode(page, "CHAR-BASE-T", 1.05);
  await page.evaluate(() => {
    const app = window.IMMUNE._app;
    const point = app.layout.get("CHAR-BASE-T");
    if (point) app.panZoom.focusPoint(point, 1.05);
  });
  await page.waitForTimeout(400);
  await shot(page, "ux-04-t-focus.png");

  await selectNode(page, "BASE-T-03", 1.2);
  await shot(page, "ux-05-detail-ready.png");

  await selectNode(page, "BASE-T-04", 1.2);
  await page.locator(".detail-btn.secondary").evaluate((el) => el.click());
  await page.waitForTimeout(400);
  await shot(page, "ux-06-tracked.png");

  await setViewMode(page, "list");
  await shot(page, "ux-07-list.png");

  await setViewMode(page, "map");
  await selectNode(page, "CHAR-PAIR-TB", 1.15);
  await shot(page, "ux-08-locked.png");

  await selectNode(page, "BASE-T-03", 1.2);
  await page.locator("#research-button").evaluate((el) => el.click());
  await page.waitForFunction(
    () => document.querySelector("#toast-region")?.textContent?.includes("研究完成"),
    { timeout: 8000 }
  );
  await page.waitForTimeout(250);
  await shot(page, "ux-09-researched.png");
}

async function captureDesktop(browser) {
  const context = await browser.newContext({
    viewport: DESKTOP,
    deviceScaleFactor: DESKTOP.deviceScaleFactor
  });
  const page = await context.newPage();
  await resetDemo(page);
  await page.goto(GAME_URL, { waitUntil: "domcontentloaded" });
  await waitForApp(page);
  await selectNode(page, "BASE-T-03", 0.95);
  await shot(page, "ux-10-desktop.png");

  await page.hover("#protocol-dock");
  await page.waitForTimeout(300);
  await shot(page, "ux-11-protocol.png");
  await context.close();

  const land = await browser.newContext({
    viewport: LANDSCAPE,
    deviceScaleFactor: LANDSCAPE.deviceScaleFactor
  });
  const landPage = await land.newPage();
  await resetDemo(landPage);
  await landPage.goto(GAME_URL, { waitUntil: "domcontentloaded" });
  await waitForApp(landPage);
  await selectNode(landPage, "CHAR-BASE-T", 0.7);
  await landPage.click('[data-action="fit-all"]');
  await landPage.waitForTimeout(400);
  await shot(landPage, "ux-12-landscape.png");
  await land.close();
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const browser = await launchBrowser();
  try {
    const phone = await browser.newContext({
      viewport: { width: DECK.width, height: DECK.height },
      deviceScaleFactor: DECK.deviceScaleFactor
    });
    const page = await phone.newPage();
    await resetDemo(page);
    await capturePhoneJourney(page);
    await phone.close();
    await captureDesktop(browser);
  } finally {
    await browser.close();
  }
  console.log("OK  UX screenshots →", pathToFileURL(OUT).href);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
