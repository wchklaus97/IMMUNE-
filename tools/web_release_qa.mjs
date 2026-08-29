#!/usr/bin/env node

import { createReadStream } from "node:fs";
import { mkdir, readFile, stat, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { extname, isAbsolute, relative, resolve } from "node:path";
import { pipeline } from "node:stream/promises";
import { fileURLToPath } from "node:url";

const ROOT = resolve(fileURLToPath(new URL(".", import.meta.url)), "..");
const DEFAULT_ARTIFACT_ROOT = resolve(ROOT, "godot/immune/build/releases/web");
const DEFAULT_OUTPUT_ROOT = resolve(ROOT, "outputs/web-release-qa");
const EVIDENCE_CLASS = "compatibility-stress-not-hardware-benchmark";
const REQUIRED_RESOURCES = ["index.html", "index.js", "index.pck", "index.wasm"];
const PROFILE_DEFINITIONS = {
  baseline: {
    id: "baseline",
    viewport: { width: 1600, height: 900 },
    cpuThrottleRate: 1,
    forceSoftwareRenderer: false,
  },
  "constrained-software": {
    id: "constrained-software",
    viewport: { width: 1280, height: 720 },
    cpuThrottleRate: 4,
    forceSoftwareRenderer: true,
  },
};
const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".wasm": "application/wasm",
};

function rounded(value, digits = 3) {
  const scale = 10 ** digits;
  return Math.round(value * scale) / scale;
}

function nearestRank(values, percentile) {
  if (!values.length) return 0;
  const sorted = [...values].sort((left, right) => left - right);
  const index = Math.max(0, Math.ceil(percentile * sorted.length) - 1);
  return sorted[Math.min(index, sorted.length - 1)];
}

export function summarizeFrameIntervals(rawIntervals) {
  const intervals = rawIntervals.filter((value) => Number.isFinite(value) && value > 0 && value <= 1_000);
  const duration = intervals.reduce((sum, value) => sum + value, 0);
  const fps = intervals.map((value) => 1_000 / value);
  const longFrameCount = intervals.filter((value) => value > 50).length;
  const stallFrameCount = intervals.filter((value) => value > 250).length;
  return {
    sample_count: intervals.length,
    duration_ms: rounded(duration),
    mean_fps: duration > 0 ? rounded(intervals.length * 1_000 / duration) : 0,
    p05_fps: rounded(nearestRank(fps, 0.05)),
    p95_frame_ms: rounded(nearestRank(intervals, 0.95)),
    max_frame_ms: rounded(Math.max(0, ...intervals)),
    long_frame_count: longFrameCount,
    long_frame_ratio: intervals.length ? rounded(longFrameCount / intervals.length) : 0,
    compatibility_stall_count: stallFrameCount,
    compatibility_stall_ratio: intervals.length ? rounded(stallFrameCount / intervals.length) : 0,
  };
}

export function classifyRequestFailures(rawFailures, resourceStatus) {
  const failures = [];
  const cancellations = [];
  for (const entry of rawFailures) {
    const pathname = new URL(entry.url).pathname;
    const name = pathname.split("/").pop() ?? "";
    const description = `${entry.url}: ${entry.error}`;
    const wasSupersededBySuccess = entry.error === "net::ERR_ABORTED"
      && REQUIRED_RESOURCES.includes(name)
      && resourceStatus.get(name) === 200;
    (wasSupersededBySuccess ? cancellations : failures).push(description);
  }
  return { failures, cancellations };
}

function expect(errors, condition, label) {
  if (!condition) errors.push(label);
}

function eventIndex(events, name, predicate = () => true) {
  return events.findIndex((event) => event?.event === name && predicate(event));
}

export function validateWebQaReport(report, { expectedProfileIds = ["baseline", "constrained-software"] } = {}) {
  const errors = [];
  expect(errors, report?.schema_version === 1, "schema_version: expected 1");
  expect(errors, report?.evidence_class === EVIDENCE_CLASS, `evidence_class: expected ${EVIDENCE_CLASS}`);
  expect(errors, /^\d+\.\d+\.\d+$/u.test(report?.build?.version ?? ""), "build.version: expected numeric SemVer");
  expect(errors, Array.isArray(report?.profiles), "profiles: expected an array");
  const profiles = Array.isArray(report?.profiles) ? report.profiles : [];
  expect(errors, profiles.length === expectedProfileIds.length, `profiles: expected ${expectedProfileIds.length}`);

  for (const id of expectedProfileIds) {
    const profile = profiles.find((entry) => entry?.id === id);
    if (!profile) {
      errors.push(`profile ${id}: missing`);
      continue;
    }
    const events = Array.isArray(profile.events) ? profile.events : [];
    const engine = eventIndex(events, "engine_ready");
    const research = eventIndex(events, "research_ready");
    const mission = eventIndex(events, "mission_select_ready");
    const combat = eventIndex(events, "combat_ready", (event) => event.family === "B" && event.mission === "MISSION-01");
    const duty = eventIndex(events, "duty_changed", (event) => event.duty === "mobile");
    const pauseOpen = eventIndex(events, "pause_changed", (event) => event.open === true);
    const pauseClosed = eventIndex(events, "pause_changed", (event) => event.open === false);
    expect(errors, engine >= 0, `${id}: engine_ready missing`);
    expect(errors, research > engine, `${id}: research_ready missing or out of order`);
    expect(errors, mission > research, `${id}: mission_select_ready missing or out of order`);
    expect(errors, combat > mission, `${id}: combat_ready B/MISSION-01 missing or out of order`);
    expect(errors, duty > combat, `${id}: duty_changed mobile missing or out of order`);
    expect(errors, pauseOpen > duty, `${id}: pause_changed open missing or out of order`);
    expect(errors, pauseClosed > pauseOpen, `${id}: pause_changed close missing or out of order`);

    const requiredResources = Array.isArray(profile.resources?.required) ? profile.resources.required : [];
    const exactRequiredResources = requiredResources.length === REQUIRED_RESOURCES.length
      && new Set(requiredResources).size === REQUIRED_RESOURCES.length
      && REQUIRED_RESOURCES.every((name) => requiredResources.includes(name));
    expect(errors, exactRequiredResources, `${id}: required resources must be the exact release set`);
    expect(errors, Array.isArray(profile.resources?.failures) && profile.resources.failures.length === 0, `${id}: resource failures present`);
    expect(errors, profile.fit?.can_scroll_x === false && profile.fit?.can_scroll_y === false, `${id}: document scroll detected`);
    expect(errors, profile.fit?.canvas_inside_viewport === true, `${id}: canvas is clipped outside viewport`);
    expect(errors, Array.isArray(profile.console?.errors) && profile.console.errors.length === 0, `${id}: console errors present`);
    expect(errors, Array.isArray(profile.console?.page_errors) && profile.console.page_errors.length === 0, `${id}: page errors present`);
    expect(errors, Array.isArray(profile.console?.request_failures) && profile.console.request_failures.length === 0, `${id}: request failures present`);
    if (id === "baseline") {
      expect(errors, Array.isArray(profile.console?.warnings) && profile.console.warnings.length === 0, `${id}: browser warnings present`);
    }
    expect(errors, Array.isArray(profile.screenshots) && profile.screenshots.length >= 4, `${id}: expected four visual states`);
    expect(errors, profile.renderer?.webgl_version?.includes("WebGL"), `${id}: WebGL context unavailable`);
    expect(errors, profile.frames?.sample_count >= (id === "constrained-software" ? 30 : 60), `${id}: insufficient frame samples`);
    expect(errors, profile.frames?.mean_fps >= (id === "constrained-software" ? 5 : 20), `${id}: frame heartbeat below compatibility floor`);
    expect(errors, profile.frames?.p05_fps >= (id === "constrained-software" ? 2 : 10), `${id}: p05 frame heartbeat below compatibility floor`);
    if (id === "baseline") {
      expect(errors, profile.frames?.long_frame_ratio <= 0.25, `${id}: excessive long-frame ratio`);
    } else {
      expect(errors, profile.frames?.compatibility_stall_ratio <= 0.1, `${id}: excessive compatibility-stall ratio`);
    }
    if (id === "constrained-software") {
      expect(errors, profile.cpu_throttle_rate === 4, `${id}: expected 4x CPU throttling`);
      expect(errors, profile.renderer?.software === true, `${id}: SwiftShader/software renderer not proven`);
    }
  }

  if (errors.length) throw new Error(`WEB_RELEASE_QA_FAILED\n- ${errors.join("\n- ")}`);
  return { profiles: profiles.length, evidenceClass: EVIDENCE_CLASS };
}

function argument(name, fallback = "") {
  const prefix = `--${name}=`;
  const match = process.argv.slice(2).find((value) => value.startsWith(prefix));
  return match ? match.slice(prefix.length) : fallback;
}

async function ensureArtifactSet(artifactRoot) {
  for (const name of REQUIRED_RESOURCES) {
    const info = await stat(resolve(artifactRoot, name));
    if (!info.isFile() || info.size < (name === "index.html" ? 1_000 : 10_000)) {
      throw new Error(`Web artifact ${name} is missing or unexpectedly small`);
    }
  }
}

function safeArtifactPath(artifactRoot, requestUrl) {
  const pathname = decodeURIComponent(new URL(requestUrl, "http://127.0.0.1").pathname);
  const relativePath = pathname === "/" ? "index.html" : pathname.replace(/^\/+/, "");
  const target = resolve(artifactRoot, relativePath);
  const rel = relative(artifactRoot, target);
  if (rel.startsWith("..") || isAbsolute(rel)) return null;
  return target;
}

async function startArtifactServer(artifactRoot) {
  const server = createServer(async (request, response) => {
    try {
      const target = safeArtifactPath(artifactRoot, request.url ?? "/");
      if (!target) {
        response.writeHead(403).end("Forbidden");
        return;
      }
      const info = await stat(target);
      response.writeHead(200, {
        "Cache-Control": "no-store",
        "Content-Length": info.size,
        "Content-Type": MIME[extname(target).toLowerCase()] ?? "application/octet-stream",
      });
      if (request.method === "HEAD") {
        response.end();
        return;
      }
      await pipeline(createReadStream(target), response);
    } catch {
      if (!response.headersSent) response.writeHead(404);
      response.end("Not Found");
    }
  });
  await new Promise((resolveListen, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolveListen);
  });
  const address = server.address();
  if (!address || typeof address === "string") throw new Error("Unable to resolve Web QA server port");
  return {
    url: `http://127.0.0.1:${address.port}/?web_qa=1`,
    close: () => new Promise((resolveClose, reject) => server.close((error) => error ? reject(error) : resolveClose())),
  };
}

async function launchBrowser(chromium, profile) {
  const channels = [process.env.PW_CHANNEL, "chrome", "msedge"].filter(Boolean);
  const args = ["--autoplay-policy=no-user-gesture-required", "--ignore-gpu-blocklist"];
  if (profile.forceSoftwareRenderer) {
    args.push("--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader");
  }
  let lastError;
  for (const channel of channels) {
    try {
      return await chromium.launch({ channel, headless: true, args });
    } catch (error) {
      lastError = error;
    }
  }
  if (process.env.CHROME_PATH) {
    return chromium.launch({ executablePath: process.env.CHROME_PATH, headless: true, args });
  }
  throw new Error(`Unable to launch Chrome for ${profile.id}: ${lastError instanceof Error ? lastError.message : String(lastError)}`);
}

async function waitForQaEvent(page, event, fields = {}) {
  await page.waitForFunction(
    ({ event, fields }) => globalThis.__immuneWebQa?.events?.some((entry) => (
      entry.event === event && Object.entries(fields).every(([key, value]) => entry[key] === value)
    )),
    { event, fields },
    { timeout: 120_000 },
  );
}

async function inspectRenderer(page) {
  return page.locator("canvas").first().evaluate((canvas) => {
    const gl = canvas.getContext("webgl2") || canvas.getContext("webgl");
    if (!gl) return { webgl_version: "", unmasked_renderer: "", software: false };
    const extension = gl.getExtension("WEBGL_debug_renderer_info");
    const renderer = extension
      ? String(gl.getParameter(extension.UNMASKED_RENDERER_WEBGL))
      : String(gl.getParameter(gl.RENDERER));
    return {
      webgl_version: String(gl.getParameter(gl.VERSION)),
      unmasked_renderer: renderer,
      software: /swiftshader|software|llvmpipe/iu.test(renderer),
    };
  });
}

async function inspectFit(page) {
  return page.evaluate(() => {
    const canvas = document.querySelector("canvas");
    const rect = canvas?.getBoundingClientRect();
    const documentElement = document.documentElement;
    return {
      viewport_width: window.innerWidth,
      viewport_height: window.innerHeight,
      can_scroll_x: documentElement.scrollWidth > documentElement.clientWidth,
      can_scroll_y: documentElement.scrollHeight > documentElement.clientHeight,
      canvas_width: Math.round(rect?.width ?? 0),
      canvas_height: Math.round(rect?.height ?? 0),
      canvas_inside_viewport: Boolean(rect) && rect.left >= -0.5 && rect.top >= -0.5
        && rect.right <= window.innerWidth + 0.5 && rect.bottom <= window.innerHeight + 0.5,
    };
  });
}

async function sampleFrameIntervals(page, durationMs) {
  return page.evaluate((duration) => new Promise((resolveSample) => {
    const intervals = [];
    const started = performance.now();
    let previous = 0;
    function frame(timestamp) {
      if (previous > 0) intervals.push(timestamp - previous);
      previous = timestamp;
      if (timestamp - started >= duration) {
        resolveSample(intervals);
        return;
      }
      requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
  }), durationMs);
}

async function capture(page, outputRoot, profileId, state) {
  const directory = resolve(outputRoot, "screenshots", profileId);
  await mkdir(directory, { recursive: true });
  const target = resolve(directory, `${state}.png`);
  await page.screenshot({ path: target, type: "png", scale: "css" });
  return relative(ROOT, target);
}

async function runProfile({ chromium, profile, url, outputRoot, durationMs }) {
  const browser = await launchBrowser(chromium, profile);
  const errors = [];
  const warnings = [];
  const messages = [];
  const pageErrors = [];
  const requestFailures = [];
  const resourceStatus = new Map();
  let context;
  let page;
  let phase = "browser-launched";
  const markPhase = (nextPhase) => {
    phase = nextPhase;
    console.log(`WEB_QA_PHASE id=${profile.id} phase=${phase}`);
  };
  try {
    markPhase("context-create");
    context = await browser.newContext({ viewport: profile.viewport, deviceScaleFactor: 1 });
    page = await context.newPage();
    page.on("console", (message) => {
      messages.push({ type: message.type(), text: message.text() });
      if (message.type() === "error") errors.push(message.text());
      if (message.type() === "warning") warnings.push(message.text());
      if (["error", "warning"].includes(message.type())) {
        console.log(`WEB_QA_BROWSER id=${profile.id} type=${message.type()} text=${JSON.stringify(message.text())}`);
      }
    });
    page.on("pageerror", (error) => pageErrors.push(error.message));
    page.on("requestfailed", (request) => requestFailures.push({
      url: request.url(),
      error: request.failure()?.errorText ?? "failed",
    }));
    page.on("response", (response) => {
      const pathname = new URL(response.url()).pathname;
      const name = pathname === "/" ? "index.html" : pathname.split("/").pop();
      if (REQUIRED_RESOURCES.includes(name)) resourceStatus.set(name, response.status());
    });
    const cdp = await context.newCDPSession(page);
    await cdp.send("Emulation.setCPUThrottlingRate", { rate: profile.cpuThrottleRate });
    markPhase("navigate");
    await page.goto(url, { waitUntil: "domcontentloaded", timeout: 120_000 });
    markPhase("canvas-visible");
    await page.locator("canvas").first().waitFor({ state: "visible", timeout: 120_000 });
    markPhase("engine-ready");
    await waitForQaEvent(page, "engine_ready");
    markPhase("research-ready");
    await waitForQaEvent(page, "research_ready");
    const screenshots = [await capture(page, outputRoot, profile.id, "01-research")];
    const canvas = page.locator("canvas").first();
    const box = await canvas.boundingBox();
    if (!box) throw new Error(`${profile.id}: canvas has no bounding box`);
    await canvas.click({ position: { x: box.width / 2, y: box.height / 2 } });
    markPhase("mission-select-ready");
    await page.keyboard.press("c");
    await waitForQaEvent(page, "mission_select_ready");
    screenshots.push(await capture(page, outputRoot, profile.id, "02-mission-select"));
    markPhase("family-selected-b");
    await page.keyboard.press("e");
    await waitForQaEvent(page, "family_selected", { family: "B" });
    markPhase("combat-ready");
    await page.keyboard.press("Enter");
    await waitForQaEvent(page, "combat_ready", { family: "B", mission: "MISSION-01" });
    await page.keyboard.press("Enter");
    await page.waitForTimeout(350);
    screenshots.push(await capture(page, outputRoot, profile.id, "03-combat"));
    markPhase("duty-mobile");
    await page.keyboard.press("Space");
    await waitForQaEvent(page, "duty_changed", { duty: "mobile" });
    await page.keyboard.down("w");
    await page.keyboard.down("d");
    markPhase("frame-sample");
    const intervals = await sampleFrameIntervals(page, durationMs);
    await page.keyboard.up("d");
    await page.keyboard.up("w");
    markPhase("pause-open");
    await page.keyboard.press("Escape");
    await waitForQaEvent(page, "pause_changed", { open: true });
    screenshots.push(await capture(page, outputRoot, profile.id, "04-pause"));
    markPhase("pause-close");
    await page.keyboard.press("Escape");
    await waitForQaEvent(page, "pause_changed", { open: false });

    const resources = REQUIRED_RESOURCES.map((name) => ({ name, status: resourceStatus.get(name) ?? 0 }));
    const resourceFailures = resources.filter((entry) => entry.status !== 200);
    const classifiedRequests = classifyRequestFailures(requestFailures, resourceStatus);
    return {
      id: profile.id,
      viewport: profile.viewport,
      cpu_throttle_rate: profile.cpuThrottleRate,
      renderer: await inspectRenderer(page),
      resources: { required: [...REQUIRED_RESOURCES], observed: resources, failures: resourceFailures },
      events: await page.evaluate(() => globalThis.__immuneWebQa?.events ?? []),
      frames: summarizeFrameIntervals(intervals),
      fit: await inspectFit(page),
      console: {
        errors,
        warnings,
        messages,
        page_errors: pageErrors,
        request_failures: classifiedRequests.failures,
        request_cancellations: classifiedRequests.cancellations,
      },
      screenshots,
    };
  } catch (error) {
    const failureDirectory = resolve(outputRoot, "failures");
    await mkdir(failureDirectory, { recursive: true });
    const failureScreenshot = resolve(failureDirectory, `${profile.id}-${phase}.png`);
    const diagnosticPath = resolve(failureDirectory, `${profile.id}-${phase}.json`);
    let browserState = {};
    if (page && !page.isClosed()) {
      await page.screenshot({ path: failureScreenshot, type: "png", scale: "css" }).catch(() => {});
      browserState = await page.evaluate(() => {
        const canvas = document.querySelector("canvas");
        const rect = canvas?.getBoundingClientRect();
        return {
          url: globalThis.location.href,
          title: document.title,
          ready_state: document.readyState,
          body_text: document.body?.innerText?.slice(0, 4_000) ?? "",
          canvas_count: document.querySelectorAll("canvas").length,
          canvas_rect: rect ? { x: rect.x, y: rect.y, width: rect.width, height: rect.height } : null,
          bridge: globalThis.__immuneWebQa ?? null,
        };
      }).catch((evaluationError) => ({ evaluation_error: String(evaluationError) }));
    }
    const diagnostic = {
      schema_version: 1,
      profile: profile.id,
      phase,
      error: error instanceof Error ? error.stack ?? error.message : String(error),
      browser_state: browserState,
      resources: Object.fromEntries(resourceStatus),
      console: {
        errors,
        warnings,
        messages,
        page_errors: pageErrors,
        request_failures: requestFailures.map((entry) => `${entry.url}: ${entry.error}`),
      },
      screenshot: relative(ROOT, failureScreenshot),
    };
    await writeFile(diagnosticPath, `${JSON.stringify(diagnostic, null, 2)}\n`);
    throw new Error(`${profile.id}: Web QA failed in phase ${phase}; diagnostics=${diagnosticPath}`, { cause: error });
  } finally {
    await context?.close().catch(() => {});
    await browser.close().catch(() => {});
  }
}

async function projectVersion() {
  const source = await readFile(resolve(ROOT, "godot/immune/project.godot"), "utf8");
  const match = source.match(/^config\/version="([^"]+)"$/mu);
  if (!match) throw new Error("project.godot config/version is missing");
  return match[1];
}

export async function runWebReleaseQa({ artifactRoot, outputRoot, profileIds, durationMs }) {
  await ensureArtifactSet(artifactRoot);
  await mkdir(outputRoot, { recursive: true });
  const { chromium } = await import("playwright-core");
  const server = await startArtifactServer(artifactRoot);
  const report = {
    schema_version: 1,
    evidence_class: EVIDENCE_CLASS,
    generated_at: new Date().toISOString(),
    build: { version: await projectVersion(), artifact_root: relative(ROOT, artifactRoot) },
    profiles: [],
  };
  try {
    for (const id of profileIds) {
      const profile = PROFILE_DEFINITIONS[id];
      if (!profile) throw new Error(`Unknown Web QA profile: ${id}`);
      const result = await runProfile({ chromium, profile, url: server.url, outputRoot, durationMs });
      report.profiles.push(result);
      await writeFile(resolve(outputRoot, "report.partial.json"), `${JSON.stringify(report, null, 2)}\n`);
      console.log(`WEB_QA_PROFILE_OK id=${id} renderer=${JSON.stringify(result.renderer.unmasked_renderer)} mean_fps=${result.frames.mean_fps} p05_fps=${result.frames.p05_fps}`);
    }
  } finally {
    await server.close();
  }
  try {
    validateWebQaReport(report, { expectedProfileIds: profileIds });
  } catch (error) {
    const failedReport = {
      ...report,
      validation_error: error instanceof Error ? error.message : String(error),
    };
    await writeFile(resolve(outputRoot, "report.failed.json"), `${JSON.stringify(failedReport, null, 2)}\n`);
    throw error;
  }
  const reportPath = resolve(outputRoot, "report.json");
  await writeFile(reportPath, `${JSON.stringify(report, null, 2)}\n`);
  return { report, reportPath };
}

async function main() {
  const artifactRoot = resolve(argument("artifacts", DEFAULT_ARTIFACT_ROOT));
  const outputRoot = resolve(argument("out", DEFAULT_OUTPUT_ROOT));
  const profileIds = argument("profiles", "baseline,constrained-software").split(",").filter(Boolean);
  const durationMs = Math.max(2_000, Number(argument("duration-ms", "6000")) || 6_000);
  const { report, reportPath } = await runWebReleaseQa({ artifactRoot, outputRoot, profileIds, durationMs });
  console.log(`WEB_RELEASE_QA_OK profiles=${report.profiles.length} evidence=${report.evidence_class} report=${reportPath}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.stack ?? error.message : String(error));
    process.exitCode = 1;
  });
}
