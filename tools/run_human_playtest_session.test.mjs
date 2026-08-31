import assert from "node:assert/strict";
import { chmod, mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  CAMPAIGN_ARTIFACT_PATHS,
  createHumanPlaytestCampaign,
} from "./create_human_playtest_campaign.mjs";
import {
  createHumanPlaytestSessionPlan,
  startHumanPlaytestStation,
} from "./run_human_playtest_session.mjs";

const BUILD_COMMIT = "81a3cbe1a5ba60227bbe0d8c873c55d07871b729";

async function createArtifactFixture(root) {
  await mkdir(join(root, "web"), { recursive: true });
  for (const relative of CAMPAIGN_ARTIFACT_PATHS) {
    const target = join(root, relative);
    let contents = Buffer.from(`fixture:${relative}\n`);
    if (relative === "web/index.html") {
      contents = Buffer.from(`<script src="index.js"></script>\n${" ".repeat(1_000)}`);
    }
    if (relative === "web/index.js") contents = Buffer.alloc(10_001, 1);
    if (["web/index.audio.worklet.js", "web/index.audio.position.worklet.js"].includes(relative)) {
      contents = Buffer.alloc(1_001, 3);
    }
    if (["web/index.png", "web/index.icon.png", "web/index.apple-touch-icon.png"].includes(relative)) {
      contents = Buffer.alloc(1_001, 4);
    }
    if ([
      "IMMUNE-windows.exe",
      "IMMUNE-windows.pck",
      "IMMUNE-linux.x86_64",
      "IMMUNE-linux.pck",
      "IMMUNE-macOS.zip",
      "web/index.pck",
      "web/index.wasm",
    ].includes(relative)) contents = Buffer.alloc(1_000_001, 2);
    await writeFile(target, contents);
  }
  await chmod(join(root, "IMMUNE-linux.x86_64"), 0o755);
}

async function campaignFixture(context) {
  const root = await mkdtemp(join(tmpdir(), "immune-playtest-session-"));
  context.after(() => rm(root, { recursive: true, force: true }));
  const artifactRoot = join(root, "source");
  const campaignRoot = join(root, "campaign");
  await createArtifactFixture(artifactRoot);
  await createHumanPlaytestCampaign({
    artifactRoot,
    outputRoot: campaignRoot,
    buildVersion: "0.4.0",
    buildCommit: BUILD_COMMIT,
    sourceRun: 33257048004,
    sourceArtifact: `immune-demo-${BUILD_COMMIT}`,
    generatedAt: "2026-08-29T15:00:00.000Z",
  });
  return { campaignRoot };
}

test("preflights exact participant and platform launch contracts", async (context) => {
  const { campaignRoot } = await campaignFixture(context);
  const expected = {
    web: ["web/index.html", "web/index.pck", "web/index.wasm"],
    windows: ["IMMUNE-windows.exe", "IMMUNE-windows.pck"],
    linux: ["IMMUNE-linux.x86_64", "IMMUNE-linux.pck"],
    macos: ["IMMUNE-macOS.zip"],
  };

  for (const [platform, requiredArtifacts] of Object.entries(expected)) {
    const plan = await createHumanPlaytestSessionPlan({
      campaignRoot,
      participantCode: "tester-01",
      platform,
    });
    assert.equal(plan.build.commit, BUILD_COMMIT);
    assert.equal(plan.participant.code, "tester-01");
    assert.deepEqual(plan.participant.familyOrder, ["T", "B", "M", "N", "A", "D"]);
    assert.equal(plan.platform, platform);
    for (const artifact of requiredArtifacts) assert.ok(plan.artifactPaths.includes(artifact));
    assert.equal(plan.launchPath, join(campaignRoot, "artifacts", requiredArtifacts[0]));
  }
});

test("rejects unknown participant, unknown platform, tampering, and a non-executable Linux build", async (context) => {
  const { campaignRoot } = await campaignFixture(context);
  await assert.rejects(
    createHumanPlaytestSessionPlan({ campaignRoot, participantCode: "tester-99", platform: "web" }),
    /participant.*tester-99/iu,
  );
  await assert.rejects(
    createHumanPlaytestSessionPlan({ campaignRoot, participantCode: "tester-01", platform: "android" }),
    /platform.*android/iu,
  );

  await writeFile(join(campaignRoot, "participants/tester-01/report.json"), "{}\n");
  await assert.rejects(
    createHumanPlaytestSessionPlan({ campaignRoot, participantCode: "tester-01", platform: "web" }),
    /VERIFY_FAILED|SHA-256|invalid kit/iu,
  );

  const second = await campaignFixture(context);
  await chmod(join(second.campaignRoot, "artifacts/IMMUNE-linux.x86_64"), 0o644);
  await assert.rejects(
    createHumanPlaytestSessionPlan({ campaignRoot: second.campaignRoot, participantCode: "tester-01", platform: "linux" }),
    /Linux executable.*not executable/iu,
  );
});

test("serves a loopback-only Web facilitator station, game, and assigned form", async (context) => {
  const { campaignRoot } = await campaignFixture(context);
  const station = await startHumanPlaytestStation({
    campaignRoot,
    participantCode: "tester-02",
    platform: "web",
    port: 0,
  });
  context.after(() => station.close());

  assert.match(station.url, /^http:\/\/127\.0\.0\.1:\d+\/$/u);
  assert.equal(station.gameUrl, `${station.url}game/`);
  assert.equal(station.formUrl, `${station.url}kit/`);

  const landing = await fetch(station.url);
  assert.equal(landing.status, 200);
  assert.equal(landing.headers.get("cache-control"), "no-store");
  assert.equal(landing.headers.get("cross-origin-opener-policy"), "same-origin");
  const landingHtml = await landing.text();
  assert.match(landingHtml, /tester-02/u);
  assert.match(landingHtml, new RegExp(BUILD_COMMIT, "u"));
  assert.match(landingHtml, /B.*M.*N.*A.*D.*T/su);
  assert.match(landingHtml, /Open Web game/u);
  assert.match(landingHtml, /<link rel="icon" href="data:image\/svg\+xml,/u);

  const [game, form, wasmHead, traversal, post] = await Promise.all([
    fetch(station.gameUrl),
    fetch(station.formUrl),
    fetch(`${station.url}game/index.wasm`, { method: "HEAD" }),
    fetch(`${station.url}game/%2e%2e/%2e%2e/etc/passwd`),
    fetch(station.url, { method: "POST" }),
  ]);
  assert.equal(game.status, 200);
  assert.match(await game.text(), /index\.js/u);
  assert.equal(form.status, 200);
  assert.match(await form.text(), /tester-02/u);
  assert.equal(wasmHead.status, 200);
  assert.equal(wasmHead.headers.get("content-type"), "application/wasm");
  assert.ok([403, 404].includes(traversal.status));
  assert.equal(post.status, 405);
});

test("native station exposes instructions and assigned form without serving executables", async (context) => {
  const { campaignRoot } = await campaignFixture(context);
  const station = await startHumanPlaytestStation({
    campaignRoot,
    participantCode: "tester-03",
    platform: "windows",
    port: 0,
  });
  context.after(() => station.close());

  assert.equal(station.gameUrl, null);
  const landingHtml = await fetch(station.url).then((response) => response.text());
  assert.match(landingHtml, /IMMUNE-windows\.exe/u);
  assert.match(landingHtml, /IMMUNE-windows\.pck/u);
  assert.equal((await fetch(`${station.url}game/`)).status, 404);
  assert.equal((await fetch(station.formUrl)).status, 200);
});
