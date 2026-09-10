#!/usr/bin/env node

import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import {
  chmod,
  copyFile,
  lstat,
  mkdtemp,
  mkdir,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  writeFile,
} from "node:fs/promises";
import { basename, dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const PLATFORMS = ["windows", "linux", "macos"];
const PLATFORM_FILES = {
  windows: ["IMMUNE-windows.exe", "IMMUNE-windows.pck"],
  linux: ["IMMUNE-linux.x86_64", "IMMUNE-linux.pck"],
  macos: ["IMMUNE-macOS.zip"],
};
const DEFAULT_NOTICE_FILES = [
  { source: join(ROOT, "steam/THIRD_PARTY_NOTICES.txt"), target: "THIRD_PARTY_NOTICES.txt" },
  { source: join(ROOT, "steam/GODOT_COPYRIGHT.txt"), target: "GODOT_COPYRIGHT.txt" },
  { source: join(ROOT, "godot/immune/fonts/OFL.txt"), target: "NotoSansHK-OFL.txt" },
];

function expectPlainObject(value, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${label} must be an object`);
  }
}

function validateSteamId(value, label) {
  const text = String(value ?? "").trim();
  if (/placeholder|your[_ -]|app[_ -]?id|depot[_ -]?id/i.test(text)) {
    throw new Error(`${label} contains a placeholder`);
  }
  if (!/^[1-9]\d{3,11}$/u.test(text)) {
    throw new Error(`${label} must be a numeric Steam identifier`);
  }
  return text;
}

export function validateSteamConfig(config) {
  expectPlainObject(config, "Steam config");
  expectPlainObject(config.depots, "Steam depots");
  const appId = validateSteamId(config.appId, "Steam App ID");
  const depots = Object.fromEntries(PLATFORMS.map((platform) => [
    platform,
    validateSteamId(config.depots[platform], `Steam ${platform} depot ID`),
  ]));
  const identifiers = [appId, ...Object.values(depots)];
  if (new Set(identifiers).size !== identifiers.length) {
    throw new Error("Steam App ID and depot IDs must all be unique");
  }
  return { appId, depots };
}

export function requiredSteamAssets() {
  return {
    store: [
      { id: "header_capsule", width: 920, height: 430, required: true },
      { id: "small_capsule", width: 462, height: 174, required: true },
      { id: "main_capsule", width: 1232, height: 706, required: true },
      { id: "vertical_capsule", width: 748, height: 896, required: true },
      { id: "screenshots", width: 1920, height: 1080, minimum: 5, required: true },
    ],
    library: [
      { id: "library_capsule", width: 600, height: 900, required: true },
      { id: "library_hero", width: 3840, height: 1240, required: true },
      { id: "library_logo", width: 1280, height: 720, transparent: true, required: true },
      { id: "library_header", width: 920, height: 430, required: true },
    ],
    icons: [
      { id: "shortcut_icon", width: 256, height: 256, required: true },
      { id: "app_icon", width: 184, height: 184, required: true },
      { id: "mac_icon", format: "icns", required: true },
    ],
  };
}

function depotVdf(depotId, platform) {
  return `"DepotBuildConfig"
{
    "DepotID" "${depotId}"
    "ContentRoot" "../content/${platform}"
    "FileMapping"
    {
        "LocalPath" "*"
        "DepotPath" "."
        "recursive" "1"
    }
    "FileExclusion" "*.DS_Store"
    "FileExclusion" "*.log"
}
`;
}

export function renderSteamVdfs(config, platforms = PLATFORMS) {
  const normalized = validateSteamConfig(config);
  const selected = normalizedPlatforms(platforms);
  const depotLines = selected.map((platform) => (
    `        "${normalized.depots[platform]}" "depot_build_${normalized.depots[platform]}.vdf"`
  )).join("\n");
  const appBuild = `"appbuild"
{
    "appid" "${normalized.appId}"
    "desc" "IMMUNE validated release candidate"
    "buildoutput" "../build-output"
    "contentroot" "../content"
    "preview" "1"
    "depots"
    {
${depotLines}
    }
}
`;
  return {
    appBuild,
    depots: Object.fromEntries(selected.map((platform) => [
      platform,
      depotVdf(normalized.depots[platform], platform),
    ])),
  };
}

async function prepareFreshOutput(output) {
  const absolute = resolve(output);
  if (absolute === resolve(sep) || absolute === resolve(process.cwd())) {
    throw new Error(`Refusing unsafe Steam stage output: ${absolute}`);
  }
  try {
    await lstat(absolute);
    throw new Error(`Steam stage output already exists: ${absolute}`);
  } catch (error) {
    if (error?.code !== "ENOENT") throw error;
  }
  await mkdir(dirname(absolute), { recursive: true });
  return absolute;
}

async function validatedArtifact(path, label) {
  let info;
  try {
    info = await lstat(path);
  } catch {
    throw new Error(`Required Steam artifact is missing: ${label}`);
  }
  if (!info.isFile() || info.isSymbolicLink() || info.size < 1) {
    throw new Error(`Required Steam artifact is not a non-empty regular file: ${label}`);
  }
  return info;
}

async function copyPlatformFiles(artifacts, output, platform) {
  const destination = join(output, "content", platform);
  await mkdir(destination, { recursive: true });
  for (const file of PLATFORM_FILES[platform]) {
    const source = join(artifacts, file);
    await validatedArtifact(source, file);
    const target = join(destination, file);
    await copyFile(source, target);
    if (platform === "linux" && file.endsWith(".x86_64")) await chmod(target, 0o755);
  }
}

async function copyNoticeFiles(output, platform, noticeFiles) {
  const destination = join(output, "content", platform);
  await mkdir(destination, { recursive: true });
  const seen = new Set();
  for (const notice of noticeFiles) {
    if (!notice || typeof notice.source !== "string" || typeof notice.target !== "string") {
      throw new Error("Steam notice entries must contain source and target strings");
    }
    if (!/^[A-Za-z0-9][A-Za-z0-9._-]*$/u.test(notice.target) || seen.has(notice.target)) {
      throw new Error(`Invalid or duplicate Steam notice target: ${notice.target}`);
    }
    seen.add(notice.target);
    await validatedArtifact(notice.source, notice.target);
    await copyFile(notice.source, join(destination, notice.target));
  }
}

function validateZipEntries(entries) {
  for (const entry of entries) {
    if (!entry) continue;
    const normalized = entry.replaceAll("\\", "/");
    if (
      normalized.startsWith("/")
      || /^[A-Za-z]:\//u.test(normalized)
      || normalized.split("/").includes("..")
      || normalized.includes("\0")
    ) {
      throw new Error(`Unsafe macOS archive entry: ${entry}`);
    }
  }
}

async function rejectLinks(root) {
  for (const entry of await readdir(root, { withFileTypes: true })) {
    const target = join(root, entry.name);
    const info = await lstat(target);
    if (info.isSymbolicLink()) throw new Error(`Steam stage contains a symbolic link: ${target}`);
    if (info.isDirectory()) await rejectLinks(target);
  }
}

async function extractMacArtifact(artifacts, output) {
  const archive = join(artifacts, PLATFORM_FILES.macos[0]);
  await validatedArtifact(archive, PLATFORM_FILES.macos[0]);
  const list = spawnSync("unzip", ["-Z1", archive], { encoding: "utf8" });
  if (list.status !== 0) throw new Error(`Cannot inspect macOS export archive: ${list.stderr || list.stdout}`);
  validateZipEntries(list.stdout.split(/\r?\n/u));
  const destination = join(output, "content", "macos");
  await mkdir(destination, { recursive: true });
  const extract = spawnSync("unzip", ["-q", archive, "-d", destination], { encoding: "utf8" });
  if (extract.status !== 0) throw new Error(`Cannot extract macOS export archive: ${extract.stderr || extract.stdout}`);
  await rejectLinks(destination);
  await validatedArtifact(join(destination, "IMMUNE.app/Contents/MacOS/IMMUNE"), "IMMUNE.app executable");
  await chmod(join(destination, "IMMUNE.app/Contents/MacOS/IMMUNE"), 0o755);
}

async function collectFiles(root, directory = root) {
  const files = [];
  const entries = await readdir(directory, { withFileTypes: true });
  entries.sort((a, b) => a.name.localeCompare(b.name, "en"));
  for (const entry of entries) {
    const target = join(directory, entry.name);
    if (entry.isSymbolicLink()) throw new Error(`Steam stage contains a symbolic link: ${target}`);
    if (entry.isDirectory()) files.push(...await collectFiles(root, target));
    if (entry.isFile()) files.push(target);
  }
  return files;
}

async function fileDigest(path) {
  const buffer = await readFile(path);
  return createHash("sha256").update(buffer).digest("hex");
}

function normalizedPlatforms(platforms) {
  const values = [...new Set((platforms ?? PLATFORMS).map((value) => String(value).trim().toLowerCase()))];
  if (!values.length || values.some((value) => !PLATFORMS.includes(value))) {
    throw new Error(`Steam platforms must be selected from ${PLATFORMS.join(", ")}`);
  }
  return values.sort();
}

export async function stageSteamBuild({
  artifacts,
  output,
  config,
  platforms = PLATFORMS,
  noticeFiles = DEFAULT_NOTICE_FILES,
}) {
  const normalized = validateSteamConfig(config);
  const selected = normalizedPlatforms(platforms);
  const artifactRoot = resolve(artifacts);
  const outputRoot = await prepareFreshOutput(output);
  const stagingRoot = await mkdtemp(join(dirname(outputRoot), `.${basename(outputRoot)}.tmp-`));
  try {
    for (const platform of selected) {
      if (platform === "macos") await extractMacArtifact(artifactRoot, stagingRoot);
      else await copyPlatformFiles(artifactRoot, stagingRoot, platform);
      await copyNoticeFiles(stagingRoot, platform, noticeFiles);
    }
    const rendered = renderSteamVdfs(normalized, selected);
    const scripts = join(stagingRoot, "scripts");
    await mkdir(scripts, { recursive: true });
    await writeFile(join(scripts, `app_build_${normalized.appId}.vdf`), rendered.appBuild, "utf8");
    for (const platform of selected) {
      await writeFile(
        join(scripts, `depot_build_${normalized.depots[platform]}.vdf`),
        rendered.depots[platform],
        "utf8",
      );
    }
    const contentRoot = join(stagingRoot, "content");
    const stagedFiles = await collectFiles(contentRoot);
    const files = [];
    for (const path of stagedFiles) {
      const info = await stat(path);
      files.push({
        path: relative(stagingRoot, path).split(sep).join("/"),
        bytes: info.size,
        sha256: await fileDigest(path),
      });
    }
    const report = {
      schema_version: 2,
      app_id: normalized.appId,
      depots: Object.fromEntries(selected.map((platform) => [platform, normalized.depots[platform]])),
      platforms: selected,
      license_files: noticeFiles.map(({ target }) => target),
      files,
      upload_performed: false,
      upload_command: `steamcmd +login <STEAM_ACCOUNT> +run_app_build ${join("scripts", `app_build_${normalized.appId}.vdf`)} +quit`,
    };
    await writeFile(join(stagingRoot, "steam-stage-manifest.json"), `${JSON.stringify(report, null, 2)}\n`, "utf8");
    try {
      await lstat(outputRoot);
      throw new Error(`Steam stage output appeared during staging: ${outputRoot}`);
    } catch (error) {
      if (error?.code !== "ENOENT") throw error;
    }
    await rename(stagingRoot, outputRoot);
    return report;
  } catch (error) {
    await rm(stagingRoot, { recursive: true, force: true });
    throw error;
  }
}

export function stagingArguments(argv) {
  const allowed = new Set([
    "artifacts", "out", "app-id", "windows-depot", "linux-depot", "macos-depot", "platforms",
  ]);
  const result = {};
  for (const argument of argv) {
    const match = /^--([^=]+)=(.*)$/u.exec(argument);
    if (!match || !allowed.has(match[1])) throw new Error(`Unknown Steam staging argument: ${argument}`);
    if (Object.hasOwn(result, match[1])) throw new Error(`Duplicate Steam staging argument: --${match[1]}`);
    if (!match[2]) throw new Error(`Steam staging argument requires a value: --${match[1]}`);
    result[match[1]] = match[2];
  }
  return result;
}

async function main() {
  const args = stagingArguments(process.argv.slice(2));
  const required = ["artifacts", "out", "app-id", "windows-depot", "linux-depot", "macos-depot"];
  for (const name of required) {
    if (!args[name]) throw new Error(`Missing required argument --${name}=...`);
  }
  const report = await stageSteamBuild({
    artifacts: args.artifacts,
    output: args.out,
    config: {
      appId: args["app-id"],
      depots: {
        windows: args["windows-depot"],
        linux: args["linux-depot"],
        macos: args["macos-depot"],
      },
    },
    platforms: args.platforms ? args.platforms.split(",") : PLATFORMS,
  });
  console.log(`STEAM_STAGE_OK app=${report.app_id} platforms=${report.platforms.join(",")} files=${report.files.length} upload=false`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
