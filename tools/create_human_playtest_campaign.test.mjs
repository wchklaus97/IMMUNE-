import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { chmod, mkdtemp, readFile, rename, rm, stat, symlink, unlink, writeFile, mkdir } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import test from "node:test";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

import {
  CAMPAIGN_ARTIFACT_PATHS,
  createHumanPlaytestCampaign,
  verifyHumanPlaytestCampaign,
} from "./create_human_playtest_campaign.mjs";

const BUILD_COMMIT = "81a3cbe1a5ba60227bbe0d8c873c55d07871b729";
const SOURCE_ARTIFACT = `immune-demo-${BUILD_COMMIT}`;
const execFileAsync = promisify(execFile);

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
  const root = await mkdtemp(join(tmpdir(), "immune-playtest-campaign-"));
  context.after(() => rm(root, { recursive: true, force: true }));
  const artifactRoot = join(root, "artifacts-source");
  const outputRoot = join(root, "campaign-output");
  await createArtifactFixture(artifactRoot);
  return { root, artifactRoot, outputRoot };
}

function options(artifactRoot, outputRoot) {
  return {
    artifactRoot,
    outputRoot,
    buildVersion: "0.5.0-rc.1",
    buildCommit: BUILD_COMMIT,
    participantCount: 6,
    sourceRun: 33257048004,
    sourceArtifact: SOURCE_ARTIFACT,
    generatedAt: "2026-08-29T15:00:00.000Z",
  };
}

test("creates an atomic portable six-participant campaign with checksummed complete artifacts", async (context) => {
  const { root, artifactRoot, outputRoot } = await campaignFixture(context);
  const result = await createHumanPlaytestCampaign(options(artifactRoot, outputRoot));

  assert.equal(result.manifest.schema_version, 2);
  assert.equal(result.manifest.status, "ready-for-human-distribution");
  assert.equal(result.manifest.build.commit, BUILD_COMMIT);
  assert.equal(result.manifest.source.actions_run, 33257048004);
  assert.equal(result.manifest.participants.length, 6);
  assert.equal(new Set(result.manifest.participants.map((entry) => entry.family_order[0])).size, 6);
  assert.deepEqual(result.manifest.artifacts.map((entry) => entry.path), CAMPAIGN_ARTIFACT_PATHS);
  assert.ok(result.manifest.artifacts.every((entry) => /^[0-9a-f]{64}$/u.test(entry.sha256)));
  assert.equal(result.manifest.facilitator.entry_path, "facilitator/run_human_playtest_session.mjs");
  assert.equal(result.manifest.facilitator.files.length, 5);
  assert.ok(result.manifest.facilitator.files.every((entry) => /^[0-9a-f]{64}$/u.test(entry.sha256)));

  const saved = JSON.parse(await readFile(join(outputRoot, "campaign-manifest.json"), "utf8"));
  assert.deepEqual(saved, result.manifest);
  const readme = await readFile(join(outputRoot, "README.md"), "utf8");
  assert.match(readme, /node facilitator\/run_human_playtest_session\.mjs/u);
  assert.match(readme, /--participant=tester-01/u);
  const sums = await readFile(join(outputRoot, "SHA256SUMS"), "utf8");
  for (const artifact of result.manifest.artifacts) {
    assert.match(sums, new RegExp(`${artifact.sha256}  artifacts/${artifact.path.replaceAll(".", "\\.")}\\n`, "u"));
  }
  for (const facilitator of result.manifest.facilitator.files) {
    assert.match(sums, new RegExp(`${facilitator.sha256}  ${facilitator.path.replaceAll(".", "\\.")}\\n`, "u"));
  }

  for (const participant of result.manifest.participants) {
    const kitRoot = join(outputRoot, participant.kit_path);
    const kitManifest = JSON.parse(await readFile(join(kitRoot, "manifest.json"), "utf8"));
    assert.equal(kitManifest.participant_code, participant.participant_code);
    assert.equal(kitManifest.build.commit, BUILD_COMMIT);
    assert.deepEqual(kitManifest.family_order, participant.family_order);
  }

  const sourceMode = (await stat(join(artifactRoot, "IMMUNE-linux.x86_64"))).mode & 0o777;
  const copiedMode = (await stat(join(outputRoot, "artifacts/IMMUNE-linux.x86_64"))).mode & 0o777;
  assert.equal(copiedMode, sourceMode);
  const verification = await verifyHumanPlaytestCampaign(outputRoot);
  assert.equal(verification.participants, 6);
  assert.equal(verification.artifacts, CAMPAIGN_ARTIFACT_PATHS.length);
  const portableVerification = await execFileAsync(process.execPath, [
    join(outputRoot, "facilitator/create_human_playtest_campaign.mjs"),
    "--verify=.",
  ], { cwd: outputRoot });
  assert.match(portableVerification.stdout, /HUMAN_PLAYTEST_CAMPAIGN_VERIFY_OK participants=6 artifacts=14/u);
  const portable = await execFileAsync(process.execPath, [
    join(outputRoot, "facilitator/run_human_playtest_session.mjs"),
    `--campaign=${outputRoot}`,
    "--participant=tester-01",
    "--platform=web",
    "--preflight-only",
  ], { cwd: root });
  assert.match(portable.stdout, /HUMAN_PLAYTEST_SESSION_PREFLIGHT_OK participant=tester-01 platform=web/u);
  assert.match(portable.stdout, new RegExp(`build=${BUILD_COMMIT}`, "u"));
  await assert.rejects(createHumanPlaytestCampaign(options(artifactRoot, outputRoot)), /refusing to overwrite/u);
});

test("rejects a missing runtime sidecar without leaving a partial campaign", async (context) => {
  const { artifactRoot, outputRoot } = await campaignFixture(context);
  await unlink(join(artifactRoot, "IMMUNE-windows.pck"));

  await assert.rejects(createHumanPlaytestCampaign(options(artifactRoot, outputRoot)), /IMMUNE-windows\.pck/u);
  await assert.rejects(stat(outputRoot), (error) => error.code === "ENOENT");
});

test("rejects unexpected artifact files that could leak unrelated data", async (context) => {
  const { artifactRoot, outputRoot } = await campaignFixture(context);
  await writeFile(join(artifactRoot, ".env"), "SECRET=do-not-package\n");

  await assert.rejects(createHumanPlaytestCampaign(options(artifactRoot, outputRoot)), /unexpected artifact.*\.env/iu);
  await assert.rejects(stat(outputRoot), (error) => error.code === "ENOENT");
});

test("verifier rejects manifest, checksum-list, and participant-path tampering", async (context) => {
  const { artifactRoot, outputRoot } = await campaignFixture(context);
  await createHumanPlaytestCampaign(options(artifactRoot, outputRoot));
  const manifestPath = join(outputRoot, "campaign-manifest.json");
  const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
  manifest.artifact_set_sha256 = "0".repeat(64);
  manifest.participants[0].kit_path = "../../outside";
  await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  await writeFile(join(outputRoot, "SHA256SUMS"), "tampered\n");

  await assert.rejects(
    verifyHumanPlaytestCampaign(outputRoot),
    /artifact_set_sha256|kit path|SHA256SUMS/iu,
  );
});

test("verifier rejects unchecksummed files added to a completed distribution", async (context) => {
  const { artifactRoot, outputRoot } = await campaignFixture(context);
  await createHumanPlaytestCampaign(options(artifactRoot, outputRoot));
  await writeFile(join(outputRoot, "debug.log"), "must not ship\n");
  await writeFile(join(outputRoot, "participants/tester-01/private-notes.txt"), "must not ship\n");

  await assert.rejects(
    verifyHumanPlaytestCampaign(outputRoot),
    /unexpected campaign entry.*debug\.log|unexpected participant file.*private-notes/iu,
  );
});

test("verifier keeps legacy schema-v1 campaign evidence readable", async (context) => {
  const { artifactRoot, outputRoot } = await campaignFixture(context);
  await createHumanPlaytestCampaign(options(artifactRoot, outputRoot));
  const manifestPath = join(outputRoot, "campaign-manifest.json");
  const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
  manifest.schema_version = 1;
  delete manifest.facilitator;
  await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  await rm(join(outputRoot, "facilitator"), { recursive: true, force: true });
  const sumsPath = join(outputRoot, "SHA256SUMS");
  const sums = await readFile(sumsPath, "utf8");
  const legacySums = sums
    .split("\n")
    .filter((line) => line && !line.includes("  facilitator/"))
    .map((line) => `${line}\n`)
    .join("");
  await writeFile(sumsPath, legacySums);

  const result = await verifyHumanPlaytestCampaign(outputRoot);
  assert.equal(result.manifest.schema_version, 1);
});

test("verifier rejects portable facilitator tampering and unexpected files", async (context) => {
  const { artifactRoot, outputRoot } = await campaignFixture(context);
  await createHumanPlaytestCampaign(options(artifactRoot, outputRoot));
  const bundledRunner = join(outputRoot, "facilitator/run_human_playtest_session.mjs");
  await unlink(bundledRunner);
  await symlink(fileURLToPath(new URL("./run_human_playtest_session.mjs", import.meta.url)), bundledRunner);
  await writeFile(join(outputRoot, "facilitator/private-token.txt"), "must not ship\n");

  const externalReadme = join(dirname(outputRoot), "external-readme.md");
  await rename(join(outputRoot, "README.md"), externalReadme);
  await symlink(externalReadme, join(outputRoot, "README.md"));

  const participantRoot = join(outputRoot, "participants/tester-01");
  const externalParticipant = join(dirname(outputRoot), "external-tester-01");
  await rename(participantRoot, externalParticipant);
  await symlink(externalParticipant, participantRoot, "dir");

  await assert.rejects(
    verifyHumanPlaytestCampaign(outputRoot),
    (error) => {
      assert.match(error.message, /campaign entry symbolic links are forbidden: README\.md/iu);
      assert.match(error.message, /tester-01: invalid kit.*participant directory symbolic links are forbidden/iu);
      assert.match(error.message, /facilitator\/run_human_playtest_session\.mjs.*symbolic links are forbidden/iu);
      assert.match(error.message, /facilitator: unexpected file.*private-token/iu);
      return true;
    },
  );
});
