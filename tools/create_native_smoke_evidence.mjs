#!/usr/bin/env node

import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import { lstat, mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const PLATFORM_MARKERS = {
  Windows: "RELEASE_SMOKE_OK platform=Windows nodes=200",
  Linux: "RELEASE_SMOKE_OK platform=Linux nodes=200",
  macOS: "RELEASE_SMOKE_OK platform=macOS nodes=200",
};
const ENGINE_ERROR = /SCRIPT ERROR|Parse Error|Compile Error|ERROR:/u;

function sha256(buffer) {
  return createHash("sha256").update(buffer).digest("hex");
}

async function regularFile(path, label) {
  const info = await lstat(path);
  if (!info.isFile() || info.isSymbolicLink() || info.size < 1) {
    throw new Error(`${label} must be a non-empty regular file`);
  }
  return info;
}

function validateIdentity(platform, commit, version) {
  if (!Object.hasOwn(PLATFORM_MARKERS, platform)) {
    throw new Error(`platform must be one of ${Object.keys(PLATFORM_MARKERS).join(", ")}`);
  }
  if (!/^[0-9a-f]{40}$/u.test(commit)) throw new Error("commit must be a full 40-character Git SHA");
  if (!/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/u.test(version)) {
    throw new Error("version must be a semantic version");
  }
}

function runGit(root, args, label) {
  const result = spawnSync("git", ["-C", root, ...args], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.error || result.status !== 0) {
    const detail = result.error?.message ?? (result.stderr.trim() || `exit ${result.status}`);
    throw new Error(`${label} failed: ${detail}`);
  }
  return result.stdout.trim();
}

function verifyRepositoryIdentity(root, commit) {
  const head = runGit(root, ["rev-parse", "--verify", "HEAD"], "Git HEAD verification");
  if (head !== commit) {
    throw new Error(`commit does not match repository HEAD: expected ${head}, received ${commit}`);
  }
  const trackedChanges = runGit(
    root,
    ["status", "--porcelain=v1", "--untracked-files=no"],
    "Git tracked-tree verification",
  );
  if (trackedChanges) {
    throw new Error("repository tracked tree must be clean before native smoke evidence is created");
  }
  return head;
}

export async function createNativeSmokeEvidence({
  platform,
  log,
  artifact,
  pck = "",
  out,
  commit,
  version,
  generatedAt = new Date().toISOString(),
  repositoryRoot = ROOT,
  verifyRepository = true,
}) {
  validateIdentity(platform, commit, version);
  if (!out) throw new Error("out is required");
  if ((platform === "Windows" || platform === "Linux") && !pck) {
    throw new Error(`${platform} evidence requires a PCK sidecar`);
  }
  const verifiedHead = verifyRepository ? verifyRepositoryIdentity(resolve(repositoryRoot), commit) : null;
  const [logInfo, artifactInfo] = await Promise.all([
    regularFile(log, "runtime log"),
    regularFile(artifact, "release artifact"),
  ]);
  const logBuffer = await readFile(log);
  const logText = logBuffer.toString("utf8");
  const marker = PLATFORM_MARKERS[platform];
  if (!logText.includes(marker)) throw new Error(`runtime log is missing ${marker}`);
  if (ENGINE_ERROR.test(logText)) throw new Error("runtime log contains a Godot engine error");

  const artifacts = [{
    role: "executable_or_bundle",
    name: platform === "macOS" ? "IMMUNE-macOS.zip" : platform === "Windows" ? "IMMUNE-windows.exe" : "IMMUNE-linux.x86_64",
    bytes: artifactInfo.size,
    sha256: sha256(await readFile(artifact)),
  }];
  if (pck) {
    const pckInfo = await regularFile(pck, "PCK sidecar");
    artifacts.push({
      role: "pck",
      name: platform === "Windows" ? "IMMUNE-windows.pck" : "IMMUNE-linux.pck",
      bytes: pckInfo.size,
      sha256: sha256(await readFile(pck)),
    });
  }

  const report = {
    schema_version: 1,
    status: "pass",
    platform,
    build: { version, commit },
    source_repository: {
      head_verified: verifiedHead === commit,
      tracked_tree_clean: verifiedHead === commit,
    },
    runtime: {
      marker,
      nodes: 200,
      log_bytes: logInfo.size,
      log_sha256: sha256(logBuffer),
    },
    artifacts,
    runner: {
      node_platform: process.platform,
      node_arch: process.arch,
      ci: process.env.CI === "true",
    },
    generated_at: generatedAt,
  };
  await mkdir(dirname(resolve(out)), { recursive: true });
  await writeFile(resolve(out), `${JSON.stringify(report, null, 2)}\n`, { encoding: "utf8", flag: "wx" });
  return report;
}

export function nativeEvidenceArguments(argv) {
  const allowed = new Set([
    "platform", "log", "artifact", "pck", "out", "commit", "version", "generated-at",
  ]);
  const result = {};
  for (const argument of argv) {
    const match = /^--([^=]+)=(.*)$/u.exec(argument);
    if (!match || !allowed.has(match[1])) throw new Error(`Unknown native-evidence argument: ${argument}`);
    if (Object.hasOwn(result, match[1])) throw new Error(`Duplicate native-evidence argument: --${match[1]}`);
    if (!match[2]) throw new Error(`Native-evidence argument requires a value: --${match[1]}`);
    result[match[1]] = match[2];
  }
  return result;
}

async function main() {
  const args = nativeEvidenceArguments(process.argv.slice(2));
  for (const key of ["platform", "log", "artifact", "out", "commit", "version"]) {
    if (!args[key]) throw new Error(`Missing required argument --${key}=...`);
  }
  const report = await createNativeSmokeEvidence({
    platform: args.platform,
    log: args.log,
    artifact: args.artifact,
    pck: args.pck ?? "",
    out: args.out,
    commit: args.commit,
    version: args.version,
    generatedAt: args["generated-at"] ?? new Date().toISOString(),
  });
  console.log(`NATIVE_SMOKE_EVIDENCE_OK platform=${report.platform} commit=${report.build.commit} artifacts=${report.artifacts.length}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
