#!/usr/bin/env node

import { createHash } from "node:crypto";
import { createReadStream } from "node:fs";
import {
  copyFile,
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  writeFile,
} from "node:fs/promises";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { createHumanPlaytestKit } from "./create_human_playtest_kit.mjs";
import { validateHumanPlaytest } from "./validate_human_playtest.mjs";
import { validateReleaseContract } from "./validate_release_contract.mjs";

const ROOT = resolve(fileURLToPath(new URL(".", import.meta.url)), "..");
const PARTICIPANT_COUNT = 6;
const KIT_FILES = ["README.md", "index.html", "manifest.json", "report.json"];
const CAMPAIGN_ROOT_ENTRIES = ["README.md", "SHA256SUMS", "artifacts", "campaign-manifest.json", "participants"];

export const CAMPAIGN_ARTIFACT_PATHS = [
  "IMMUNE-linux.pck",
  "IMMUNE-linux.x86_64",
  "IMMUNE-macOS.zip",
  "IMMUNE-windows.exe",
  "IMMUNE-windows.pck",
  "web/index.apple-touch-icon.png",
  "web/index.audio.position.worklet.js",
  "web/index.audio.worklet.js",
  "web/index.html",
  "web/index.icon.png",
  "web/index.js",
  "web/index.pck",
  "web/index.png",
  "web/index.wasm",
];

function argument(name, fallback = "") {
  const prefix = `--${name}=`;
  const match = process.argv.slice(2).find((entry) => entry.startsWith(prefix));
  return match ? match.slice(prefix.length) : fallback;
}

async function exists(path) {
  try {
    await stat(path);
    return true;
  } catch (error) {
    if (error?.code === "ENOENT") return false;
    throw error;
  }
}

function assertOptions({ buildVersion, buildCommit, participantCount, sourceRun, sourceArtifact }) {
  if (typeof buildVersion !== "string" || !/^\d+\.\d+\.\d+$/u.test(buildVersion)) {
    throw new Error("build version: expected numeric SemVer");
  }
  if (typeof buildCommit !== "string" || !/^[0-9a-f]{40}$/u.test(buildCommit)) {
    throw new Error("build commit: expected the exact full 40-character lowercase commit used by CI");
  }
  if (participantCount !== PARTICIPANT_COUNT) {
    throw new Error(`participant count: expected ${PARTICIPANT_COUNT} for one complete family-order rotation`);
  }
  if (!Number.isSafeInteger(sourceRun) || sourceRun < 1) {
    throw new Error("source run: expected a positive GitHub Actions run ID");
  }
  if (typeof sourceArtifact !== "string" || !/^[A-Za-z0-9._-]+$/u.test(sourceArtifact) || !sourceArtifact.includes(buildCommit)) {
    throw new Error("source artifact: expected a safe artifact name containing the full build commit");
  }
}

async function projectVersion() {
  const source = await readFile(resolve(ROOT, "godot/immune/project.godot"), "utf8");
  const match = source.match(/^config\/version="([^"]+)"$/mu);
  if (!match) throw new Error("project.godot config/version is missing");
  return match[1];
}

async function sha256(path) {
  const hash = createHash("sha256");
  for await (const chunk of createReadStream(path)) hash.update(chunk);
  return hash.digest("hex");
}

async function scanFiles(root, current = root) {
  const entries = await readdir(current, { withFileTypes: true });
  const paths = [];
  for (const entry of entries) {
    const absolute = join(current, entry.name);
    const rel = relative(root, absolute).replaceAll("\\", "/");
    if (/[\r\n\\]/u.test(rel)) throw new Error(`unsafe artifact path: ${JSON.stringify(rel)}`);
    if (entry.isSymbolicLink()) throw new Error(`artifact symlink is forbidden: ${rel}`);
    if (entry.isDirectory()) {
      paths.push(...await scanFiles(root, absolute));
    } else if (entry.isFile()) {
      paths.push(rel);
    } else {
      throw new Error(`unsupported artifact entry: ${rel}`);
    }
  }
  return paths.sort();
}

async function validateExactArtifactInventory(artifactRoot) {
  const actual = await scanFiles(artifactRoot);
  const expected = [...CAMPAIGN_ARTIFACT_PATHS].sort();
  const missing = expected.filter((path) => !actual.includes(path));
  const unexpected = actual.filter((path) => !expected.includes(path));
  if (missing.length || unexpected.length) {
    const details = [
      ...missing.map((path) => `missing artifact: ${path}`),
      ...unexpected.map((path) => `unexpected artifact: ${path}`),
    ];
    throw new Error(`HUMAN_PLAYTEST_CAMPAIGN_FAILED\n- ${details.join("\n- ")}`);
  }
  return expected;
}

async function inventory(root, paths, prefix = "") {
  return Promise.all(paths.map(async (path) => {
    const absolute = join(root, path);
    const info = await stat(absolute);
    return {
      path: prefix ? `${prefix}/${path}` : path,
      size_bytes: info.size,
      sha256: await sha256(absolute),
    };
  }));
}

function checksumLines(entries) {
  return entries.map((entry) => `${entry.sha256}  ${entry.path}\n`).join("");
}

function renderCampaignReadme(manifest) {
  return `# IMMUNE six-family human playtest campaign

This is an anonymous local-only distribution bundle. It contains no human results.

## Exact source

- Version: \`${manifest.build.version}\`
- Build commit: \`${manifest.build.commit}\`
- GitHub Actions run: \`${manifest.source.actions_run}\`
- Actions artifact: \`${manifest.source.artifact}\`
- Mission: \`${manifest.mission}\`

Do not replace, rename, or mix the files under \`artifacts/\`. Verify the bundle
before distribution:

\`\`\`sh
node tools/create_human_playtest_campaign.mjs --verify=/absolute/path/to/this-campaign
\`\`\`

## Distribution

1. Assign one folder under \`participants/\` to each adult participant.
2. Give every participant the same exact platform build from \`artifacts/\`.
3. Keep the Windows \`.exe\` beside \`IMMUNE-windows.pck\` and the Linux binary
   beside \`IMMUNE-linux.pck\`.
4. Serve the complete \`artifacts/web/\` directory over local HTTP for Web tests.
5. Ask participants not to enter names or contact details.
6. Collect only the completed JSON download and store it under an ignored local
   \`outputs/playtests/human/raw/${manifest.build.commit.slice(0, 7)}/\` folder.

The six kits rotate the starting family once each. Three valid reports are the
minimum initial sample; all six are recommended. Synthetic fixtures are not
human evidence.
`;
}

async function writeKit(root, kit) {
  await mkdir(root, { recursive: true });
  await Promise.all([
    writeFile(join(root, "README.md"), kit.readme),
    writeFile(join(root, "index.html"), kit.html),
    writeFile(join(root, "manifest.json"), `${JSON.stringify(kit.manifest, null, 2)}\n`),
    writeFile(join(root, "report.json"), `${JSON.stringify(kit.report, null, 2)}\n`),
  ]);
}

async function verifyEntry(root, entry, errors) {
  const target = join(root, entry.path);
  try {
    const info = await stat(target);
    if (!info.isFile()) {
      errors.push(`${entry.path}: expected a file`);
      return;
    }
    if (info.size !== entry.size_bytes) errors.push(`${entry.path}: expected ${entry.size_bytes} bytes, got ${info.size}`);
    const digest = await sha256(target);
    if (digest !== entry.sha256) errors.push(`${entry.path}: SHA-256 mismatch`);
  } catch {
    errors.push(`${entry.path}: missing`);
  }
}

export async function verifyHumanPlaytestCampaign(campaignRoot) {
  const absoluteRoot = resolve(campaignRoot);
  const manifest = JSON.parse(await readFile(join(absoluteRoot, "campaign-manifest.json"), "utf8"));
  const errors = [];
  try {
    const rootDirents = await readdir(absoluteRoot, { withFileTypes: true });
    const rootEntries = rootDirents.map((entry) => entry.name).sort();
    for (const entry of rootEntries.filter((entry) => !CAMPAIGN_ROOT_ENTRIES.includes(entry))) {
      errors.push(`unexpected campaign entry: ${entry}`);
    }
    for (const entry of CAMPAIGN_ROOT_ENTRIES.filter((entry) => !rootEntries.includes(entry))) {
      errors.push(`missing campaign entry: ${entry}`);
    }
    const expectedDirectories = new Set(["artifacts", "participants"]);
    for (const entry of rootDirents.filter((entry) => CAMPAIGN_ROOT_ENTRIES.includes(entry.name))) {
      const shouldBeDirectory = expectedDirectories.has(entry.name);
      if (shouldBeDirectory !== entry.isDirectory()) errors.push(`campaign entry type mismatch: ${entry.name}`);
    }
  } catch (error) {
    errors.push(`campaign root: cannot scan (${error instanceof Error ? error.message : String(error)})`);
  }
  if (manifest.schema_version !== 1) errors.push("schema_version: expected 1");
  if (manifest.kind !== "human-playtest-campaign-bundle") errors.push("kind: unexpected campaign kind");
  if (manifest.status !== "ready-for-human-distribution") errors.push("status: campaign is not ready for distribution");
  if (typeof manifest.build?.version !== "string" || !/^\d+\.\d+\.\d+$/u.test(manifest.build.version)) {
    errors.push("build.version: expected numeric SemVer");
  }
  if (typeof manifest.build?.commit !== "string" || !/^[0-9a-f]{40}$/u.test(manifest.build.commit)) {
    errors.push("build.commit: expected a full lowercase commit");
  }
  if (!Number.isSafeInteger(manifest.source?.actions_run) || manifest.source.actions_run < 1) {
    errors.push("source.actions_run: expected a positive run ID");
  }
  if (typeof manifest.source?.artifact !== "string" || !/^[A-Za-z0-9._-]+$/u.test(manifest.source.artifact) || !manifest.source.artifact.includes(manifest.build?.commit ?? "missing")) {
    errors.push("source.artifact: must contain the full build commit");
  }
  if (!Array.isArray(manifest.artifacts) || manifest.artifacts.length !== CAMPAIGN_ARTIFACT_PATHS.length) {
    errors.push(`artifacts: expected ${CAMPAIGN_ARTIFACT_PATHS.length} entries`);
  } else {
    const artifactPaths = manifest.artifacts.map((entry) => entry.path);
    const pathsMatch = JSON.stringify(artifactPaths) === JSON.stringify(CAMPAIGN_ARTIFACT_PATHS);
    if (!pathsMatch) {
      errors.push("artifacts: path contract mismatch");
    } else {
      await Promise.all(manifest.artifacts.map((entry) => verifyEntry(join(absoluteRoot, "artifacts"), entry, errors)));
      const artifactSetSha256 = createHash("sha256").update(checksumLines(manifest.artifacts)).digest("hex");
      if (artifactSetSha256 !== manifest.artifact_set_sha256) errors.push("artifact_set_sha256: manifest mismatch");
      try {
        const copiedPaths = await scanFiles(join(absoluteRoot, "artifacts"));
        if (JSON.stringify(copiedPaths) !== JSON.stringify(CAMPAIGN_ARTIFACT_PATHS)) {
          errors.push("artifacts: copied directory contains missing or unexpected files");
        }
      } catch (error) {
        errors.push(`artifacts: cannot scan copied directory (${error instanceof Error ? error.message : String(error)})`);
      }
    }
  }
  if (!Array.isArray(manifest.participants) || manifest.participants.length !== PARTICIPANT_COUNT) {
    errors.push(`participants: expected ${PARTICIPANT_COUNT}`);
  } else {
    const starts = new Set();
    for (const [index, participant] of manifest.participants.entries()) {
      const expectedCode = `tester-${String(index + 1).padStart(2, "0")}`;
      const expectedKitPath = `participants/${expectedCode}`;
      if (participant.participant_code !== expectedCode) errors.push(`participants[${index}]: expected ${expectedCode}`);
      starts.add(participant.family_order?.[0]);
      if (participant.kit_path !== expectedKitPath) errors.push(`${expectedCode}: kit path mismatch`);
      const kitRoot = join(absoluteRoot, expectedKitPath);
      try {
        const actualKitFiles = (await readdir(kitRoot)).sort();
        const expectedKitFiles = [...KIT_FILES].sort();
        for (const file of actualKitFiles.filter((file) => !expectedKitFiles.includes(file))) {
          errors.push(`${expectedCode}: unexpected participant file ${file}`);
        }
        for (const file of expectedKitFiles.filter((file) => !actualKitFiles.includes(file))) {
          errors.push(`${expectedCode}: missing participant file ${file}`);
        }
        const [kitManifest, report] = await Promise.all([
          readFile(join(kitRoot, "manifest.json"), "utf8").then(JSON.parse),
          readFile(join(kitRoot, "report.json"), "utf8").then(JSON.parse),
        ]);
        validateHumanPlaytest(report, { allowIncomplete: true });
        if (kitManifest.participant_code !== expectedCode || report.tester.participant_code !== expectedCode) {
          errors.push(`${expectedCode}: participant identity mismatch`);
        }
        if (kitManifest.build?.commit !== manifest.build?.commit || report.build?.commit !== manifest.build?.commit) {
          errors.push(`${expectedCode}: build commit mismatch`);
        }
        if (JSON.stringify(kitManifest.family_order) !== JSON.stringify(participant.family_order)) {
          errors.push(`${expectedCode}: family order mismatch`);
        }
        if (JSON.stringify(report.sessions.map((session) => session.family)) !== JSON.stringify(participant.family_order)) {
          errors.push(`${expectedCode}: report family order mismatch`);
        }
        if (!Array.isArray(participant.files) || participant.files.length !== KIT_FILES.length) {
          errors.push(`${expectedCode}: kit file inventory mismatch`);
        } else {
          const expectedFiles = KIT_FILES.map((name) => `${expectedKitPath}/${name}`);
          const actualFiles = participant.files.map((entry) => entry.path);
          if (JSON.stringify(actualFiles) !== JSON.stringify(expectedFiles)) {
            errors.push(`${expectedCode}: kit file path contract mismatch`);
          } else {
            await Promise.all(participant.files.map((entry) => verifyEntry(absoluteRoot, entry, errors)));
          }
        }
      } catch (error) {
        errors.push(`${expectedCode}: invalid kit (${error instanceof Error ? error.message : String(error)})`);
      }
    }
    if (starts.size !== PARTICIPANT_COUNT) errors.push("participants: starting-family rotation is not counterbalanced");
  }
  if (Array.isArray(manifest.artifacts) && Array.isArray(manifest.participants)) {
    const checksumEntries = [
      ...manifest.artifacts.map((entry) => ({ ...entry, path: `artifacts/${entry.path}` })),
      ...manifest.participants.flatMap((participant) => Array.isArray(participant.files) ? participant.files : []),
    ];
    try {
      const savedChecksums = await readFile(join(absoluteRoot, "SHA256SUMS"), "utf8");
      if (savedChecksums !== checksumLines(checksumEntries)) errors.push("SHA256SUMS: content mismatch");
    } catch {
      errors.push("SHA256SUMS: missing");
    }
  }
  if (errors.length) throw new Error(`HUMAN_PLAYTEST_CAMPAIGN_VERIFY_FAILED\n- ${errors.join("\n- ")}`);
  return { manifest, participants: manifest.participants.length, artifacts: manifest.artifacts.length };
}

export async function createHumanPlaytestCampaign({
  artifactRoot,
  outputRoot,
  buildVersion,
  buildCommit,
  participantCount = PARTICIPANT_COUNT,
  sourceRun,
  sourceArtifact,
  generatedAt = new Date().toISOString(),
}) {
  assertOptions({ buildVersion, buildCommit, participantCount, sourceRun, sourceArtifact });
  const absoluteArtifacts = resolve(artifactRoot);
  const absoluteOutput = resolve(outputRoot);
  if (await exists(absoluteOutput)) throw new Error(`Output already exists; refusing to overwrite campaign data: ${absoluteOutput}`);
  const release = await validateReleaseContract({ artifacts: absoluteArtifacts });
  if (release.version !== buildVersion) throw new Error(`build version: expected project ${release.version}, got ${buildVersion}`);
  const sourcePaths = await validateExactArtifactInventory(absoluteArtifacts);
  const artifactInventory = await inventory(absoluteArtifacts, sourcePaths);
  const parent = dirname(absoluteOutput);
  await mkdir(parent, { recursive: true });
  const staging = await mkdtemp(join(parent, ".immune-playtest-campaign-"));
  let renamed = false;
  try {
    for (const path of sourcePaths) {
      const destination = join(staging, "artifacts", path);
      await mkdir(dirname(destination), { recursive: true });
      await copyFile(join(absoluteArtifacts, path), destination);
    }

    const participants = [];
    for (let index = 1; index <= participantCount; index += 1) {
      const participantCode = `tester-${String(index).padStart(2, "0")}`;
      const kit = createHumanPlaytestKit({ participantCode, buildVersion, buildCommit, generatedAt });
      const kitPath = `participants/${participantCode}`;
      const kitRoot = join(staging, kitPath);
      await writeKit(kitRoot, kit);
      const files = await inventory(kitRoot, KIT_FILES, kitPath);
      participants.push({
        participant_code: participantCode,
        kit_path: kitPath,
        family_order: kit.manifest.family_order,
        files,
      });
    }

    const artifactSetSha256 = createHash("sha256").update(checksumLines(artifactInventory)).digest("hex");
    const manifest = {
      schema_version: 1,
      kind: "human-playtest-campaign-bundle",
      status: "ready-for-human-distribution",
      evidence_class: "playtest-distribution-provenance-not-human-results",
      privacy: "anonymous-kits-no-human-results",
      generated_at: generatedAt,
      build: { version: buildVersion, commit: buildCommit },
      source: { actions_run: sourceRun, artifact: sourceArtifact },
      mission: "MISSION-01",
      sample: { minimum_participants: 3, recommended_participants: PARTICIPANT_COUNT },
      artifact_set_sha256: artifactSetSha256,
      artifacts: artifactInventory,
      participants,
      claim_boundary: "Distribution integrity only. This bundle contains no human results and does not prove fun, accessibility, visual quality, control feel, or hardware performance.",
    };
    const allChecksums = [
      ...artifactInventory.map((entry) => ({ ...entry, path: `artifacts/${entry.path}` })),
      ...participants.flatMap((participant) => participant.files),
    ];
    await Promise.all([
      writeFile(join(staging, "campaign-manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`),
      writeFile(join(staging, "README.md"), renderCampaignReadme(manifest)),
      writeFile(join(staging, "SHA256SUMS"), checksumLines(allChecksums)),
    ]);
    await verifyHumanPlaytestCampaign(staging);
    if (await exists(absoluteOutput)) throw new Error(`Output appeared during generation; refusing to overwrite: ${absoluteOutput}`);
    await rename(staging, absoluteOutput);
    renamed = true;
    return { manifest, outputRoot: absoluteOutput };
  } finally {
    if (!renamed) await rm(staging, { recursive: true, force: true });
  }
}

async function main() {
  const verify = argument("verify");
  if (verify) {
    const result = await verifyHumanPlaytestCampaign(verify);
    console.log(`HUMAN_PLAYTEST_CAMPAIGN_VERIFY_OK participants=${result.participants} artifacts=${result.artifacts} root=${resolve(verify)}`);
    return;
  }
  const buildVersion = argument("build-version", await projectVersion());
  const artifactRoot = argument("artifacts");
  const buildCommit = argument("build-commit");
  const sourceRunText = argument("source-run");
  const sourceRun = /^\d+$/u.test(sourceRunText) ? Number(sourceRunText) : Number.NaN;
  const sourceArtifact = argument("source-artifact");
  const outputRoot = argument("out");
  if (!artifactRoot || !outputRoot) {
    throw new Error("Usage: node tools/create_human_playtest_campaign.mjs --artifacts=release-root --build-commit=<40-hex> --source-run=<id> --source-artifact=<name> --out=campaign-root");
  }
  const result = await createHumanPlaytestCampaign({
    artifactRoot,
    outputRoot,
    buildVersion,
    buildCommit,
    sourceRun,
    sourceArtifact,
  });
  console.log(`HUMAN_PLAYTEST_CAMPAIGN_OK participants=${result.manifest.participants.length} artifacts=${result.manifest.artifacts.length} artifact_set_sha256=${result.manifest.artifact_set_sha256} out=${result.outputRoot}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
