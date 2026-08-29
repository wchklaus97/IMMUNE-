#!/usr/bin/env node

import { createReadStream, realpathSync } from "node:fs";
import { stat } from "node:fs/promises";
import { createServer } from "node:http";
import { extname, isAbsolute, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawn } from "node:child_process";
import { pipeline } from "node:stream/promises";

import { verifyHumanPlaytestCampaign } from "./create_human_playtest_campaign.mjs";

const HOST = "127.0.0.1";
const KIT_FILES = new Set(["README.md", "index.html", "manifest.json", "report.json"]);
const PLATFORM_ARTIFACTS = Object.freeze({
  web: [
    "web/index.html",
    "web/index.js",
    "web/index.pck",
    "web/index.wasm",
    "web/index.apple-touch-icon.png",
    "web/index.audio.position.worklet.js",
    "web/index.audio.worklet.js",
    "web/index.icon.png",
    "web/index.png",
  ],
  windows: ["IMMUNE-windows.exe", "IMMUNE-windows.pck"],
  linux: ["IMMUNE-linux.x86_64", "IMMUNE-linux.pck"],
  macos: ["IMMUNE-macOS.zip"],
});

const MIME = Object.freeze({
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".md": "text/markdown; charset=utf-8",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".wasm": "application/wasm",
});

export const HUMAN_PLAYTEST_PLATFORMS = Object.freeze(Object.keys(PLATFORM_ARTIFACTS));

function argument(name, fallback = "") {
  const prefix = `--${name}=`;
  const match = process.argv.slice(2).find((entry) => entry.startsWith(prefix));
  return match ? match.slice(prefix.length) : fallback;
}

function hasFlag(name) {
  return process.argv.slice(2).includes(`--${name}`);
}

function isMainModule(url) {
  if (!process.argv[1]) return false;
  try {
    return realpathSync(fileURLToPath(url)) === realpathSync(process.argv[1]);
  } catch {
    return fileURLToPath(url) === resolve(process.argv[1]);
  }
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function assertInput(participantCode, platform) {
  if (typeof participantCode !== "string" || !/^tester-\d{2}$/u.test(participantCode)) {
    throw new Error(`participant: expected tester-NN, got ${JSON.stringify(participantCode)}`);
  }
  if (!HUMAN_PLAYTEST_PLATFORMS.includes(platform)) {
    throw new Error(`platform: expected ${HUMAN_PLAYTEST_PLATFORMS.join(", ")}, got ${JSON.stringify(platform)}`);
  }
}

function launchInstructions(platform, artifactPaths) {
  if (platform === "web") {
    return "Open the Web game from this loopback station. Do not open index.html with file:// and do not separate any Web files.";
  }
  if (platform === "windows") {
    return `Keep ${artifactPaths[0]} beside ${artifactPaths[1]}, then launch ${artifactPaths[0]}.`;
  }
  if (platform === "linux") {
    return `Keep ${artifactPaths[0]} beside ${artifactPaths[1]}, then launch the executable ${artifactPaths[0]}.`;
  }
  return `Extract ${artifactPaths[0]}, then open the contained IMMUNE application. Keep the original ZIP unchanged for provenance.`;
}

export async function createHumanPlaytestSessionPlan({ campaignRoot, participantCode, platform }) {
  const normalizedPlatform = typeof platform === "string" ? platform.toLowerCase() : platform;
  assertInput(participantCode, normalizedPlatform);
  const absoluteCampaignRoot = resolve(campaignRoot);
  const { manifest } = await verifyHumanPlaytestCampaign(absoluteCampaignRoot);
  const participant = manifest.participants.find((entry) => entry.participant_code === participantCode);
  if (!participant) throw new Error(`participant: ${participantCode} is not assigned by this campaign`);

  const artifactPaths = [...PLATFORM_ARTIFACTS[normalizedPlatform]];
  const inventoryPaths = new Set(manifest.artifacts.map((entry) => entry.path));
  const missing = artifactPaths.filter((path) => !inventoryPaths.has(path));
  if (missing.length) throw new Error(`platform ${normalizedPlatform}: campaign is missing ${missing.join(", ")}`);

  if (normalizedPlatform === "linux") {
    const executable = join(absoluteCampaignRoot, "artifacts", artifactPaths[0]);
    const info = await stat(executable);
    if ((info.mode & 0o111) === 0) {
      throw new Error(`Linux executable is not executable: ${executable}`);
    }
  }

  const kitRoot = join(absoluteCampaignRoot, participant.kit_path);
  return {
    schemaVersion: 1,
    evidenceClass: "verified-facilitator-session-not-human-result",
    verifiedAt: new Date().toISOString(),
    campaignRoot: absoluteCampaignRoot,
    build: { ...manifest.build },
    source: { ...manifest.source },
    mission: manifest.mission,
    participant: {
      code: participant.participant_code,
      familyOrder: [...participant.family_order],
      kitRoot,
      formPath: join(kitRoot, "index.html"),
    },
    platform: normalizedPlatform,
    artifactRoot: join(absoluteCampaignRoot, "artifacts"),
    artifactPaths,
    launchPath: join(absoluteCampaignRoot, "artifacts", artifactPaths[0]),
    companionPaths: artifactPaths.slice(1).map((path) => join(absoluteCampaignRoot, "artifacts", path)),
    instructions: launchInstructions(normalizedPlatform, artifactPaths),
    claimBoundary: "This preflight proves campaign integrity and session assignment only. It does not create or imply human playtest evidence.",
  };
}

function stationHtml(plan) {
  const familyOrder = plan.participant.familyOrder.map(escapeHtml).join(" → ");
  const artifactList = plan.artifactPaths
    .map((path) => `<li><code>${escapeHtml(path)}</code></li>`)
    .join("");
  const gameButton = plan.platform === "web"
    ? '<a class="primary" href="/game/" target="_blank" rel="noopener">Open Web game</a>'
    : "";
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Ccircle cx='32' cy='32' r='28' fill='%230e7180'/%3E%3Ccircle cx='23' cy='27' r='4' fill='%23dffbff'/%3E%3Ccircle cx='41' cy='27' r='4' fill='%23dffbff'/%3E%3Cpath d='M20 40Q32 50 44 40' fill='none' stroke='%23dffbff' stroke-width='4'/%3E%3C/svg%3E">
  <title>IMMUNE verified playtest session</title>
  <style>
    :root{color-scheme:dark;font-family:Inter,system-ui,sans-serif;background:#061019;color:#e6f8ff}
    body{margin:0;min-height:100vh;display:grid;place-items:center;padding:24px;box-sizing:border-box}
    main{width:min(760px,100%);border:1px solid #2cc8df66;border-radius:20px;background:#0a1824;padding:clamp(22px,5vw,42px);box-sizing:border-box;box-shadow:0 22px 80px #0008}
    h1{font-weight:500;letter-spacing:.04em;margin-top:0}h2{font-size:1rem;color:#76dcea;margin-top:28px}
    .status{display:inline-block;border:1px solid #55e1a0;border-radius:999px;color:#86f5bd;padding:6px 10px;font-size:.82rem}
    dl{display:grid;grid-template-columns:max-content 1fr;gap:10px 18px}dt{color:#86a9b7}dd{margin:0;overflow-wrap:anywhere}
    code{color:#b7eaf2}.order{font-size:1.35rem;letter-spacing:.08em;color:#ffca65}
    .actions{display:flex;flex-wrap:wrap;gap:12px;margin:28px 0}.actions a{border:1px solid #46cadd;border-radius:10px;padding:12px 16px;color:#dffbff;text-decoration:none}.actions .primary{background:#0e7180}
    .warning{border-left:3px solid #ffbd52;padding:10px 14px;background:#17170f;color:#ffe2a5}li{margin:7px 0}
  </style>
</head>
<body><main>
  <span class="status">Campaign integrity verified</span>
  <h1>IMMUNE facilitator station</h1>
  <dl>
    <dt>Participant</dt><dd><strong>${escapeHtml(plan.participant.code)}</strong></dd>
    <dt>Platform</dt><dd>${escapeHtml(plan.platform)}</dd>
    <dt>Mission</dt><dd>${escapeHtml(plan.mission)}</dd>
    <dt>Version</dt><dd>${escapeHtml(plan.build.version)}</dd>
    <dt>Build commit</dt><dd><code>${escapeHtml(plan.build.commit)}</code></dd>
    <dt>Actions run</dt><dd>${escapeHtml(plan.source.actions_run)}</dd>
  </dl>
  <h2>Required family order</h2>
  <p class="order">${familyOrder}</p>
  <h2>Platform files</h2><ul>${artifactList}</ul>
  <p>${escapeHtml(plan.instructions)}</p>
  <div class="actions">${gameButton}<a href="/kit/" target="_blank" rel="noopener">Open assigned form</a></div>
  <p class="warning">Use only this participant code and order. Do not enter names, email addresses, contact details, or account names.</p>
  <p>${escapeHtml(plan.claimBoundary)}</p>
</main></body></html>`;
}

function insideRoot(root, target) {
  const rel = relative(root, target);
  return rel === "" || (!rel.startsWith("..") && !isAbsolute(rel));
}

function safeTarget(root, path) {
  const target = resolve(root, path);
  return insideRoot(root, target) ? target : null;
}

function responseHeaders(contentType, size) {
  return {
    "Cache-Control": "no-store",
    "Content-Length": size,
    "Content-Type": contentType,
    "Cross-Origin-Embedder-Policy": "require-corp",
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Resource-Policy": "same-origin",
    "Permissions-Policy": "camera=(), geolocation=(), microphone=()",
    "Referrer-Policy": "no-referrer",
    "X-Content-Type-Options": "nosniff",
  };
}

function decodePath(requestUrl) {
  try {
    return decodeURIComponent(new URL(requestUrl, `http://${HOST}`).pathname);
  } catch {
    return null;
  }
}

async function serveFile(request, response, root, relativePath, allowlist) {
  if (!allowlist.has(relativePath)) {
    response.writeHead(404, responseHeaders("text/plain; charset=utf-8", 9)).end("Not Found");
    return;
  }
  const target = safeTarget(root, relativePath);
  if (!target) {
    response.writeHead(403, responseHeaders("text/plain; charset=utf-8", 9)).end("Forbidden");
    return;
  }
  try {
    const info = await stat(target);
    if (!info.isFile()) throw new Error("not a file");
    response.writeHead(200, responseHeaders(MIME[extname(target).toLowerCase()] ?? "application/octet-stream", info.size));
    if (request.method === "HEAD") {
      response.end();
      return;
    }
    await pipeline(createReadStream(target), response);
  } catch {
    if (!response.headersSent) response.writeHead(404, responseHeaders("text/plain; charset=utf-8", 9));
    response.end("Not Found");
  }
}

export async function startHumanPlaytestStation({ campaignRoot, participantCode, platform, port = 0 }) {
  if (!Number.isSafeInteger(port) || port < 0 || port > 65_535) {
    throw new Error(`port: expected an integer from 0 through 65535, got ${JSON.stringify(port)}`);
  }
  const plan = await createHumanPlaytestSessionPlan({ campaignRoot, participantCode, platform });
  const kitAllowlist = new Set(KIT_FILES);
  const webAllowlist = new Set(plan.platform === "web" ? plan.artifactPaths.map((path) => path.slice("web/".length)) : []);
  const landing = Buffer.from(stationHtml(plan));
  const server = createServer(async (request, response) => {
    if (!new Set(["GET", "HEAD"]).has(request.method ?? "")) {
      response.writeHead(405, { ...responseHeaders("text/plain; charset=utf-8", 18), Allow: "GET, HEAD" }).end("Method Not Allowed");
      return;
    }
    const pathname = decodePath(request.url ?? "/");
    if (pathname === null) {
      response.writeHead(400, responseHeaders("text/plain; charset=utf-8", 11)).end("Bad Request");
      return;
    }
    if (pathname === "/") {
      response.writeHead(200, responseHeaders("text/html; charset=utf-8", landing.length));
      response.end(request.method === "HEAD" ? undefined : landing);
      return;
    }
    if (pathname === "/kit") {
      response.writeHead(308, { Location: "/kit/", "Cache-Control": "no-store" }).end();
      return;
    }
    if (pathname.startsWith("/kit/")) {
      const relativePath = pathname.slice("/kit/".length) || "index.html";
      await serveFile(request, response, plan.participant.kitRoot, relativePath, kitAllowlist);
      return;
    }
    if (plan.platform === "web" && pathname === "/game") {
      response.writeHead(308, { Location: "/game/", "Cache-Control": "no-store" }).end();
      return;
    }
    if (plan.platform === "web" && pathname.startsWith("/game/")) {
      const relativePath = pathname.slice("/game/".length) || "index.html";
      await serveFile(request, response, join(plan.artifactRoot, "web"), relativePath, webAllowlist);
      return;
    }
    response.writeHead(404, responseHeaders("text/plain; charset=utf-8", 9)).end("Not Found");
  });

  await new Promise((resolveListen, reject) => {
    const onError = (error) => reject(error);
    server.once("error", onError);
    server.listen(port, HOST, () => {
      server.off("error", onError);
      resolveListen();
    });
  });
  const address = server.address();
  if (!address || typeof address === "string") {
    server.close();
    throw new Error("Unable to resolve facilitator station port");
  }
  const url = `http://${HOST}:${address.port}/`;
  let closed = false;
  return {
    plan,
    url,
    formUrl: `${url}kit/`,
    gameUrl: plan.platform === "web" ? `${url}game/` : null,
    close: () => {
      if (closed) return Promise.resolve();
      closed = true;
      return new Promise((resolveClose, reject) => {
        server.close((error) => error ? reject(error) : resolveClose());
      });
    },
  };
}

function openBrowser(url) {
  let command;
  let args;
  if (process.platform === "darwin") {
    command = "open";
    args = [url];
  } else if (process.platform === "win32") {
    command = "cmd";
    args = ["/c", "start", "", url];
  } else {
    command = "xdg-open";
    args = [url];
  }
  const child = spawn(command, args, { detached: true, stdio: "ignore" });
  child.once("error", (error) => {
    console.warn(`Unable to open the facilitator station automatically: ${error.message}`);
  });
  child.unref();
}

async function main() {
  const campaignRoot = argument("campaign");
  const participantCode = argument("participant");
  const platform = argument("platform").toLowerCase();
  if (!campaignRoot || !participantCode || !platform) {
    throw new Error(`Usage: node tools/run_human_playtest_session.mjs --campaign=<campaign-root> --participant=tester-01 --platform=<${HUMAN_PLAYTEST_PLATFORMS.join("|")}> [--preflight-only] [--port=4173] [--open]`);
  }
  if (hasFlag("preflight-only")) {
    const plan = await createHumanPlaytestSessionPlan({ campaignRoot, participantCode, platform });
    console.log(`HUMAN_PLAYTEST_SESSION_PREFLIGHT_OK participant=${plan.participant.code} platform=${plan.platform} build=${plan.build.commit} launch=${plan.launchPath}`);
    return;
  }
  const portText = argument("port", "0");
  const port = /^\d+$/u.test(portText) ? Number(portText) : Number.NaN;
  const station = await startHumanPlaytestStation({ campaignRoot, participantCode, platform, port });
  console.log(`HUMAN_PLAYTEST_SESSION_READY participant=${station.plan.participant.code} platform=${station.plan.platform} build=${station.plan.build.commit}`);
  console.log(`Facilitator station: ${station.url}`);
  if (station.gameUrl) console.log(`Web game: ${station.gameUrl}`);
  console.log(`Assigned form: ${station.formUrl}`);
  if (station.plan.platform !== "web") console.log(`Native launch file: ${station.plan.launchPath}`);
  console.log("Press Ctrl+C to stop the loopback station.");
  if (hasFlag("open")) openBrowser(station.url);
  await new Promise((resolveStop) => {
    process.once("SIGINT", resolveStop);
    process.once("SIGTERM", resolveStop);
  });
  await station.close();
}

if (isMainModule(import.meta.url)) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
