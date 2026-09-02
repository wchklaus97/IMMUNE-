#!/usr/bin/env node

import { createHash } from "node:crypto";
import { readFile, stat } from "node:fs/promises";
import { dirname, isAbsolute, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { parseConfig } from "./validate_release_contract.mjs";
import { parsePckResourcePaths } from "./validate_steam_readiness.mjs";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const PROJECT_RELATIVE = "godot/immune/project.godot";
const PRESETS_RELATIVE = "godot/immune/export_presets.cfg";
const PROFILE_RELATIVE = "godot/immune/characters/gel/gel_profiles.gd";
const BODY_RELATIVE = "godot/immune/characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb";
const BODY_RESOURCE = "res://characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb";
const BODY_SHA256 = "8f14cfe59a508df413e4d53218f30bbf316e7e5d31e42154b2916a0bd5669294";
const FEATURE = "v8_5_candidate";
const ADDON_RESOURCE = "res://addons/v8_5_raw_export/plugin.cfg";
const ADDON_FILES = [
  "godot/immune/addons/v8_5_raw_export/plugin.cfg",
  "godot/immune/addons/v8_5_raw_export/v8_5_raw_export.gd",
  "godot/immune/addons/v8_5_raw_export/v8_5_raw_export_plugin.gd",
];
const SHIPPING_NAMES = ["Windows Desktop", "Linux/X11", "Web", "macOS"];
const CANDIDATE_PRESETS = [
  ["Windows Desktop V8.5 Candidate", "Windows Desktop", "build/v8-5-candidate/IMMUNE-windows.exe"],
  ["Linux/X11 V8.5 Candidate", "Linux", "build/v8-5-candidate/IMMUNE-linux.x86_64"],
  ["Web V8.5 Candidate", "Web", "build/v8-5-candidate/web/index.html"],
  ["macOS V8.5 Candidate", "macOS", "build/v8-5-candidate/IMMUNE-macOS.zip"],
];
const FORBIDDEN_CANDIDATE_MARKERS = [
  "CHAR-BASE-B-meshy-t2",
  "CHAR-BASE-M-meshy-t2",
  "CHAR-BASE-T-tripo-5k",
  "CHAR-BASE-T-fix",
  "CHAR-BASE-T-v8-4-single-mass-r1",
];

function presetByName(sections, name) {
  for (const [section, values] of sections) {
    if (/^preset\.\d+$/u.test(section) && values.name === name) {
      return { base: values, options: sections.get(`${section}.options`) ?? {} };
    }
  }
  return null;
}

function requireCondition(errors, condition, message) {
  if (!condition) errors.push(message);
}

function normalizedPckPath(path) {
  return String(path).replace(/^res:\/\//u, "");
}

export function validateV85PckPaths(paths) {
  const normalized = paths.map(normalizedPckPath);
  const body = BODY_RESOURCE.slice("res://".length);
  const bodyEntries = normalized.filter((path) => (
    path === body
    || path === `${body}.import`
    || /^\.godot\/imported\/CHAR-BASE-T-v8-5-authored-sculpt-r4\.glb-[0-9a-f]+\.scn$/u.test(path)
  ));
  if (!normalized.includes(body)) throw new Error("V8_5_PCK_FAILED: raw V8.5 body is missing");
  if (!normalized.includes(`${body}.import`)) throw new Error("V8_5_PCK_FAILED: V8.5 import metadata is missing");
  if (!bodyEntries.some((path) => path.startsWith(".godot/imported/") && path.endsWith(".scn"))) {
    throw new Error("V8_5_PCK_FAILED: imported V8.5 scene is missing");
  }
  if (bodyEntries.length !== 3) {
    throw new Error(`V8_5_PCK_FAILED: expected exactly three V8.5 body entries, got ${bodyEntries.length}`);
  }
  for (const marker of FORBIDDEN_CANDIDATE_MARKERS) {
    if (normalized.some((path) => path.includes(marker))) {
      throw new Error(`V8_5_PCK_FAILED: forbidden candidate leaked into PCK: ${marker}`);
    }
  }
  if (normalized.some((path) => path.startsWith("addons/"))) {
    throw new Error("V8_5_PCK_FAILED: editor addon leaked into PCK");
  }
  if (normalized.some((path) => path.startsWith("characters/concepts/"))) {
    throw new Error("V8_5_PCK_FAILED: concept asset leaked into PCK");
  }
  return { bodyEntries, resourceCount: normalized.length };
}

export function parseV85ExportArgs(argv) {
  let pck = "";
  for (const raw of argv) {
    if (!raw.startsWith("--pck=")) throw new Error(`unknown option: ${raw}`);
    if (pck) throw new Error("--pck may be provided only once");
    pck = raw.slice("--pck=".length);
    if (!pck) throw new Error("--pck requires a non-empty path");
  }
  return { pck };
}

export async function validateV85ExportContract({ root = ROOT, pck = "" } = {}) {
  const [projectSource, presetsSource, profileSource, bodyBuffer, ...addonSources] = await Promise.all([
    readFile(join(root, PROJECT_RELATIVE), "utf8"),
    readFile(join(root, PRESETS_RELATIVE), "utf8"),
    readFile(join(root, PROFILE_RELATIVE), "utf8"),
    readFile(join(root, BODY_RELATIVE)),
    ...ADDON_FILES.map((path) => readFile(join(root, path), "utf8")),
  ]);
  const project = parseConfig(projectSource, PROJECT_RELATIVE);
  const presets = parseConfig(presetsSource, PRESETS_RELATIVE);
  const errors = [];
  const defaultLook = project.get("immune")?.["visual/gel_look"];
  requireCondition(errors, defaultLook === "v8_3", `shipping default must remain v8_3, got ${JSON.stringify(defaultLook)}`);
  requireCondition(
    errors,
    String(project.get("editor_plugins")?.enabled ?? "").includes(ADDON_RESOURCE),
    `editor plugin is not enabled: ${ADDON_RESOURCE}`,
  );
  requireCondition(errors, profileSource.includes(`OS.has_feature("${FEATURE}")`), "gel profile does not honor the V8.5 export feature");

  const bodySha = createHash("sha256").update(bodyBuffer).digest("hex");
  requireCondition(errors, bodySha === BODY_SHA256, `V8.5 body SHA-256 mismatch: ${bodySha}`);
  for (const [index, source] of addonSources.entries()) {
    requireCondition(errors, source.trim().length > 0, `addon file is empty: ${ADDON_FILES[index]}`);
  }
  requireCondition(errors, addonSources.join("\n").includes(BODY_SHA256), "export addon does not pin the V8.5 body SHA-256");
  requireCondition(errors, addonSources.join("\n").includes("V8_5_RAW_EXPORT_ADDED"), "export addon is missing its success marker");

  for (const name of SHIPPING_NAMES) {
    const preset = presetByName(presets, name);
    requireCondition(errors, Boolean(preset), `shipping preset is missing: ${name}`);
    if (!preset) continue;
    requireCondition(errors, preset.base.custom_features === "", `${name}: shipping custom_features must remain empty`);
    requireCondition(errors, String(preset.base.export_files ?? "").includes(BODY_RESOURCE), `${name}: V8.5 body must remain excluded`);
    requireCondition(errors, String(preset.base.exclude_filter ?? "").includes("addons/*"), `${name}: editor addons must be excluded`);
  }

  for (const [name, platform, exportPath] of CANDIDATE_PRESETS) {
    const preset = presetByName(presets, name);
    requireCondition(errors, Boolean(preset), `candidate preset is missing: ${name}`);
    if (!preset) continue;
    requireCondition(errors, preset.base.platform === platform, `${name}: expected platform ${platform}`);
    requireCondition(errors, preset.base.export_path === exportPath, `${name}: expected export path ${exportPath}`);
    requireCondition(errors, preset.base.runnable === false, `${name}: candidate preset must not be runnable by default`);
    requireCondition(errors, preset.base.custom_features === FEATURE, `${name}: expected custom feature ${FEATURE}`);
    requireCondition(errors, preset.base.export_filter === "exclude", `${name}: expected exclude resource policy`);
    const excluded = String(preset.base.export_files ?? "");
    requireCondition(errors, !excluded.includes(BODY_RESOURCE), `${name}: V8.5 body must be available to the export plugin`);
    for (const marker of FORBIDDEN_CANDIDATE_MARKERS) {
      requireCondition(errors, excluded.includes(marker), `${name}: missing exclusion for ${marker}`);
    }
    requireCondition(errors, String(preset.base.exclude_filter ?? "").includes("addons/*"), `${name}: editor addons must be excluded`);
    if (platform === "Windows Desktop" || platform === "Linux") {
      requireCondition(errors, preset.options["binary_format/architecture"] === "x86_64", `${name}: expected x86_64 architecture`);
    } else if (platform === "Web") {
      requireCondition(errors, preset.options["variant/thread_support"] === false, `${name}: thread support must remain disabled`);
      requireCondition(errors, preset.options["variant/extensions_support"] === false, `${name}: extension support must remain disabled`);
    } else if (platform === "macOS") {
      requireCondition(errors, preset.options["binary_format/architecture"] === "universal", `${name}: expected universal architecture`);
    }
  }

  let pckResult = null;
  if (pck) {
    const pckPath = isAbsolute(pck) ? pck : resolve(root, pck);
    const info = await stat(pckPath);
    requireCondition(errors, info.isFile() && info.size > 0, `candidate PCK is empty: ${pckPath}`);
    if (info.isFile() && info.size > 0) pckResult = validateV85PckPaths(parsePckResourcePaths(await readFile(pckPath)));
  }
  if (errors.length) throw new Error(`V8_5_EXPORT_CONTRACT_FAILED\n- ${errors.join("\n- ")}`);
  return {
    candidatePresetCount: CANDIDATE_PRESETS.length,
    shippingPresetCount: SHIPPING_NAMES.length,
    defaultLook,
    bodySha256: bodySha,
    pck: pckResult ? "verified" : "not-requested",
    pckFiles: pckResult?.resourceCount ?? 0,
  };
}

async function main() {
  const args = parseV85ExportArgs(process.argv.slice(2));
  const report = await validateV85ExportContract(args);
  console.log(`V8_5_EXPORT_CONTRACT_OK candidate_presets=${report.candidatePresetCount} shipping_presets=${report.shippingPresetCount} default=${report.defaultLook} asset_sha=${report.bodySha256} pck=${report.pck} pck_files=${report.pckFiles}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
