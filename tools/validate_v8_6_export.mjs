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
const PACKAGE_RELATIVE = "package.json";
const CI_RELATIVE = ".github/workflows/ci.yml";
const PROFILE_RELATIVE = "godot/immune/characters/gel/gel_profiles.gd";
const AUTHORED_BODY_RELATIVE = "godot/immune/characters/authored_jelly_body.gd";
const PROBE_RELATIVE = "tools/godot/v8_6_candidate_probe.gd";
const ROLLBACK_PROBE_RELATIVE = "tools/godot/v8_3_rollback_probe.gd";
const BODY_RELATIVE = "godot/immune/characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb";
const BODY_RESOURCE = "res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb";
const BODY_SHA256 = "3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3";
const V86_BODY_PREFIX = "CHAR-BASE-T-v8-6-authored-sculpt-";
const PRESERVED_BODIES = [
  {
    label: "R5",
    relative: "godot/immune/characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r5.glb",
    resource: "res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r5.glb",
    sha256: "473fcb356a166eb113bc3532d471e2bc51c6dea85dbf7146e417d293e103197f",
  },
  {
    label: "R6",
    relative: "godot/immune/characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r6.glb",
    resource: "res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r6.glb",
    sha256: "6fa587a26af3a248713986fd7614c028ae787a11cf22c310d89ac97d590dc770",
  },
  {
    label: "R7",
    relative: "godot/immune/characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7.glb",
    resource: "res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7.glb",
    sha256: "2ee384882c8c41c6a1454a457b5ed17ce2e934999ecc24337e27b9948299d587",
  },
  {
    label: "R7.1",
    relative: "godot/immune/characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-1.glb",
    resource: "res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-1.glb",
    sha256: "8af1663976140b6769ae638217efe46873e9a71a57e0294005c49361a7bf40a0",
  },
];
const FEATURE = "v8_6_candidate";
const SHIPPING_FEATURE = "v8_6_shipping";
const ADDON_RESOURCE = "res://addons/v8_6_raw_export/plugin.cfg";
const ADDON_FILES = [
  "godot/immune/addons/v8_6_raw_export/plugin.cfg",
  "godot/immune/addons/v8_6_raw_export/v8_6_raw_export.gd",
  "godot/immune/addons/v8_6_raw_export/v8_6_raw_export_plugin.gd",
];
const V85_IMMUTABLE_FILES = new Map([
  ["godot/immune/addons/v8_5_raw_export/plugin.cfg", "8de8354ea8d8f020ace38f41afd9a0194a5a0546b808cdc46c826447242f4d6a"],
  ["godot/immune/addons/v8_5_raw_export/v8_5_raw_export.gd", "767c6aef92b5e6a628cdd7dbebbe7cbf20ceacd86c894ff46db3065d8caa22b0"],
  ["godot/immune/addons/v8_5_raw_export/v8_5_raw_export_plugin.gd", "ecf71bd7cc2daad8dd8bea6f549668bb580f25bf11a20163aa64ab3b7795845c"],
  ["tools/validate_v8_5_export.mjs", "3578c1fe9e3fce3dd7052a6dc2b3e0aeda1841c94be26b70061f82548fcbe4d5"],
  ["tools/validate_v8_5_export.test.mjs", "8f138b434e61c80fa6ce121f1719a83dae44124f84a7059d4c7a8076ef06e724"],
  ["tools/godot/v8_5_candidate_probe.gd", "ff83781b3c8fb6ad5b56870ebf30acd7fc2a1c0b2c30aba450cc352805f82328"],
]);
const SHIPPING_NAMES = ["Windows Desktop", "Linux/X11", "Web", "macOS"];
const V85_CANDIDATE_NAMES = [
  "Windows Desktop V8.5 Candidate",
  "Linux/X11 V8.5 Candidate",
  "Web V8.5 Candidate",
  "macOS V8.5 Candidate",
];
const CANDIDATE_SPECS = [
  {
    name: "Windows Desktop V8.6 Candidate",
    platform: "Windows Desktop",
    path: "build/v8-6-candidate/IMMUNE-windows.exe",
    options: {
      "binary_format/embed_pck": false,
      "binary_format/architecture": "x86_64",
      "application/file_version": "0.5.0.1",
      "application/product_version": "0.5.0-rc.1",
      "codesign/enable": false,
    },
  },
  {
    name: "Linux/X11 V8.6 Candidate",
    platform: "Linux",
    path: "build/v8-6-candidate/IMMUNE-linux.x86_64",
    options: {
      "binary_format/embed_pck": false,
      "binary_format/architecture": "x86_64",
    },
  },
  {
    name: "Web V8.6 Candidate",
    platform: "Web",
    path: "build/v8-6-candidate/web/index.html",
    options: {
      "variant/thread_support": false,
      "variant/extensions_support": false,
    },
  },
  {
    name: "macOS V8.6 Candidate",
    platform: "macOS",
    path: "build/v8-6-candidate/IMMUNE-macOS.zip",
    options: {
      "binary_format/architecture": "universal",
      "application/bundle_identifier": "com.wchklaus97.immune.v86candidate",
      "application/short_version": "0.5.0",
      "application/version": "1",
    },
  },
];
const FORBIDDEN_CANDIDATE_MARKERS = [
  "CHAR-BASE-B-meshy-t2",
  "CHAR-BASE-M-meshy-t2",
  "CHAR-BASE-T-tripo-5k",
  "CHAR-BASE-T-fix",
  "CHAR-BASE-T-v8-4-single-mass-r1",
  "CHAR-BASE-T-v8-5-authored-sculpt-r4",
  ...PRESERVED_BODIES.map(({ resource }) => resource.split("/").at(-1)),
];
const PROBE_ANIMATIONS = [
  "idle",
  "plant",
  "uproot",
  "move",
  "hit",
  "attack",
  "relay_open",
  "relay_close",
  "move_start",
  "move_stop",
  "relay_glide",
  "skill_cast",
  "victory",
  "defeat",
];

function presetByName(sections, name) {
  for (const [section, values] of sections) {
    if (/^preset\.\d+$/u.test(section) && values.name === name) {
      return { base: values, options: sections.get(`${section}.options`) ?? {} };
    }
  }
  return null;
}

function allPresets(sections) {
  const result = [];
  for (const [section, values] of sections) {
    if (/^preset\.\d+$/u.test(section)) {
      result.push({ section, base: values, options: sections.get(`${section}.options`) ?? {} });
    }
  }
  return result;
}

function presetExcludesResource(preset, resource) {
  const relative = resource.slice("res://".length);
  return String(preset.base.export_files ?? "").includes(resource)
    || String(preset.base.exclude_filter ?? "").split(",").map((value) => value.trim()).includes(relative);
}

function requireCondition(errors, condition, message) {
  if (!condition) errors.push(message);
}

function normalizedPckPath(path) {
  return String(path).replace(/^res:\/\//u, "");
}

async function readRequired(root, relative, errors, label, encoding = null) {
  try {
    return await readFile(join(root, relative), encoding ?? undefined);
  } catch (error) {
    if (error?.code === "ENOENT") {
      errors.push(`${label} is missing: ${relative}`);
      return encoding ? "" : Buffer.alloc(0);
    }
    throw error;
  }
}

export function validateV86PckPaths(paths) {
  const normalized = paths.map(normalizedPckPath);
  const body = BODY_RESOURCE.slice("res://".length);
  const bodyEntries = normalized.filter((path) => (
    path === body
    || path === `${body}.import`
    || /^\.godot\/imported\/CHAR-BASE-T-v8-6-authored-sculpt-r7-2\.glb-[0-9a-f]+\.scn$/u.test(path)
  ));
  if (!normalized.includes(body)) throw new Error("V8_6_PCK_FAILED: raw V8.6 body is missing");
  if (!normalized.includes(`${body}.import`)) throw new Error("V8_6_PCK_FAILED: V8.6 import metadata is missing");
  if (!bodyEntries.some((path) => path.startsWith(".godot/imported/") && path.endsWith(".scn"))) {
    throw new Error("V8_6_PCK_FAILED: imported V8.6 scene is missing");
  }
  if (bodyEntries.length !== 3) {
    throw new Error(`V8_6_PCK_FAILED: expected exactly three V8.6 body entries, got ${bodyEntries.length}`);
  }
  for (const marker of FORBIDDEN_CANDIDATE_MARKERS) {
    if (normalized.some((path) => path.includes(marker))) {
      throw new Error(`V8_6_PCK_FAILED: forbidden candidate leaked into PCK: ${marker}`);
    }
  }
  if (normalized.some((path) => path.includes(V86_BODY_PREFIX) && !bodyEntries.includes(path))) {
    throw new Error("V8_6_PCK_FAILED: unexpected V8.6 body revision leaked into PCK");
  }
  if (normalized.some((path) => path.startsWith("addons/"))) {
    throw new Error("V8_6_PCK_FAILED: editor addon leaked into PCK");
  }
  if (normalized.some((path) => path.startsWith("characters/concepts/"))) {
    throw new Error("V8_6_PCK_FAILED: concept asset leaked into PCK");
  }
  return { bodyEntries, resourceCount: normalized.length };
}

export function parseV86ExportArgs(argv) {
  let pck = "";
  for (const raw of argv) {
    if (!raw.startsWith("--pck=")) throw new Error(`unknown option: ${raw}`);
    if (pck) throw new Error("--pck may be provided only once");
    pck = raw.slice("--pck=".length);
    if (!pck) throw new Error("--pck requires a non-empty path");
  }
  return { pck };
}

export async function validateV86ExportContract({ root = ROOT, pck = "" } = {}) {
  const errors = [];
  const [projectSource, presetsSource, packageSource, ciSource, profileSource, authoredBodySource, probeSource, rollbackProbeSource] = await Promise.all([
    readRequired(root, PROJECT_RELATIVE, errors, "Godot project", "utf8"),
    readRequired(root, PRESETS_RELATIVE, errors, "export presets", "utf8"),
    readRequired(root, PACKAGE_RELATIVE, errors, "package manifest", "utf8"),
    readRequired(root, CI_RELATIVE, errors, "CI workflow", "utf8"),
    readRequired(root, PROFILE_RELATIVE, errors, "gel profile", "utf8"),
    readRequired(root, AUTHORED_BODY_RELATIVE, errors, "authored body", "utf8"),
    readRequired(root, PROBE_RELATIVE, errors, "candidate probe", "utf8"),
    readRequired(root, ROLLBACK_PROBE_RELATIVE, errors, "rollback probe", "utf8"),
  ]);
  const [bodyBuffer, ...preservedAndAddonSources] = await Promise.all([
    readRequired(root, BODY_RELATIVE, errors, "raw V8.6 body"),
    ...PRESERVED_BODIES.map(({ label, relative }) => (
      readRequired(root, relative, errors, `preserved V8.6 ${label} body`)
    )),
    ...ADDON_FILES.map((path) => readRequired(root, path, errors, "V8.6 export addon", "utf8")),
  ]);
  const preservedBodyBuffers = preservedAndAddonSources.slice(0, PRESERVED_BODIES.length);
  const addonSources = preservedAndAddonSources.slice(PRESERVED_BODIES.length);
  const legacySources = await Promise.all(
    [...V85_IMMUTABLE_FILES.keys()].map((path) => readRequired(root, path, errors, "preserved V8.5 contract")),
  );

  const project = parseConfig(projectSource, PROJECT_RELATIVE);
  const presets = parseConfig(presetsSource, PRESETS_RELATIVE);
  let packageJson = {};
  try {
    packageJson = JSON.parse(packageSource);
  } catch {
    errors.push(`${PACKAGE_RELATIVE}: invalid JSON`);
  }

  const defaultLook = project.get("immune")?.["visual/gel_look"];
  requireCondition(errors, defaultLook === "v8_6", `shipping default must be v8_6, got ${JSON.stringify(defaultLook)}`);
  const enabledPlugins = String(project.get("editor_plugins")?.enabled ?? "");
  requireCondition(errors, enabledPlugins.includes("res://addons/v8_5_raw_export/plugin.cfg"), "V8.5 export plugin must remain enabled");
  requireCondition(errors, enabledPlugins.includes(ADDON_RESOURCE), `editor plugin is not enabled: ${ADDON_RESOURCE}`);
  requireCondition(
    errors,
    packageJson.scripts?.["validate:v8-6-export"] === "node tools/validate_v8_6_export.mjs",
    "package script validate:v8-6-export is missing or drifted",
  );
  const ciChecks = [
    [ciSource.includes("v8-6-native-smoke:"), "CI is missing the V8.6 native-smoke job"],
    [ciSource.includes("os: [ubuntu-latest, windows-latest, macos-latest]"), "CI is missing the three-OS V8.6 matrix"],
    [ciSource.includes("immune-v8-6-candidate-${{ github.sha }}"), "CI candidate artifact is not commit-bound"],
    [ciSource.includes("Windows Desktop V8.6 Candidate"), "CI does not export the Windows V8.6 candidate"],
    [ciSource.includes("Linux/X11 V8.6 Candidate"), "CI does not export the Linux V8.6 candidate"],
    [ciSource.includes("macOS V8.6 Candidate"), "CI does not export the macOS V8.6 candidate"],
    [ciSource.includes("Web V8.6 Candidate"), "CI does not export the Web V8.6 candidate"],
    [ciSource.includes("create_native_smoke_evidence.mjs"), "CI does not seal native smoke evidence"],
    [ciSource.includes("IMMUNE V8.6 visual candidate"), "CI does not validate Windows candidate metadata"],
    [ciSource.includes('V8_6_EXPORT_PROBE_OK'), "CI does not probe the promoted V8.6 export"],
    [ciSource.includes('V8_3_ROLLBACK_PROBE_OK'), "CI does not probe V8.3 rollback from the promoted PCK"],
    [ciSource.includes('--version=0.5.0-rc.1'), "CI evidence is not bound to release identity 0.5.0-rc.1"],
  ];
  for (const [condition, message] of ciChecks) requireCondition(errors, condition, message);

  requireCondition(errors, profileSource.includes(`if OS.has_feature("${FEATURE}"):`), "gel selector does not honor the V8.6 export feature");
  requireCondition(errors, profileSource.includes(`if OS.has_feature("${SHIPPING_FEATURE}"):`), "gel selector does not honor the V8.6 shipping feature");
  requireCondition(errors, profileSource.includes("static func v8_6_enabled() -> bool:"), "exact V8.6 selector helper is missing");
  requireCondition(errors, profileSource.includes('return selected_look() == "v8_6"'), "exact V8.6 selector helper is not fail-closed");
  requireCondition(errors, profileSource.includes('return &"reference_convergence"'), "exact V8.6 profile name is missing");
  requireCondition(errors, authoredBodySource.includes(BODY_RESOURCE), "authored body does not pin the V8.6 source path");
  requireCondition(errors, authoredBodySource.includes(BODY_SHA256), "authored body does not pin the V8.6 source SHA-256");

  const bodySha = createHash("sha256").update(bodyBuffer).digest("hex");
  const preservedBodySha256 = {};
  requireCondition(errors, /^[0-9a-f]{64}$/u.test(BODY_SHA256), "V8.6 expected SHA-256 has not been finalized");
  requireCondition(errors, bodySha === BODY_SHA256, `V8.6 body SHA-256 mismatch: ${bodySha}`);
  for (const [index, preserved] of PRESERVED_BODIES.entries()) {
    const actualSha = createHash("sha256").update(preservedBodyBuffers[index]).digest("hex");
    preservedBodySha256[preserved.resource.slice("res://".length)] = actualSha;
    requireCondition(
      errors,
      actualSha === preserved.sha256,
      `preserved V8.6 ${preserved.label} body SHA-256 mismatch: ${actualSha}`,
    );
  }
  for (const [index, source] of addonSources.entries()) {
    requireCondition(errors, source.trim().length > 0, `addon file is empty: ${ADDON_FILES[index]}`);
  }
  const addonSource = addonSources.join("\n");
  requireCondition(errors, addonSource.includes(BODY_RESOURCE), "export addon does not pin the V8.6 body path");
  requireCondition(errors, addonSource.includes(BODY_SHA256), "export addon does not pin the V8.6 body SHA-256");
  requireCondition(errors, addonSource.includes(SHIPPING_FEATURE), "export addon does not honor the V8.6 shipping feature");
  requireCondition(errors, addonSource.includes("V8_6_RAW_EXPORT_ADDED"), "export addon is missing its success marker");
  requireCondition(errors, addonSource.includes("V8_6_RAW_EXPORT_FAILED"), "export addon is missing its fail-closed marker");
  const digestGuardIndex = addonSource.indexOf("if digest != _EXPECTED_SHA256:");
  const addFileIndex = addonSource.indexOf("add_file(_SOURCE_PATH, bytes, false)");
  requireCondition(
    errors,
    digestGuardIndex >= 0 && addFileIndex > digestGuardIndex,
    "export addon must verify SHA-256 before injecting the raw body",
  );

  for (const [index, [path, expectedSha]] of [...V85_IMMUTABLE_FILES.entries()].entries()) {
    const actualSha = createHash("sha256").update(legacySources[index]).digest("hex");
    requireCondition(errors, actualSha === expectedSha, `preserved V8.5 file drifted: ${path}`);
  }

  for (const name of SHIPPING_NAMES) {
    const preset = presetByName(presets, name);
    requireCondition(errors, Boolean(preset), `shipping preset is missing: ${name}`);
    if (!preset) continue;
    requireCondition(errors, preset.base.custom_features === SHIPPING_FEATURE, `${name}: expected shipping feature ${SHIPPING_FEATURE}`);
    requireCondition(errors, !presetExcludesResource(preset, BODY_RESOURCE), `${name}: active V8.6 R7.2 body must be available to the export plugin`);
    for (const preserved of PRESERVED_BODIES) {
      requireCondition(
        errors,
        presetExcludesResource(preset, preserved.resource),
        `${name}: preserved V8.6 ${preserved.label} body must remain excluded`,
      );
    }
    requireCondition(errors, String(preset.base.exclude_filter ?? "").includes("addons/*"), `${name}: editor addons must be excluded`);
  }

  for (const name of V85_CANDIDATE_NAMES) {
    const preset = presetByName(presets, name);
    requireCondition(errors, Boolean(preset), `preserved V8.5 preset is missing: ${name}`);
    if (!preset) continue;
    requireCondition(errors, preset.base.custom_features === "v8_5_candidate", `${name}: V8.5 feature drifted`);
    requireCondition(errors, presetExcludesResource(preset, BODY_RESOURCE), `${name}: active V8.6 R7.2 body must not leak into V8.5`);
    for (const preserved of PRESERVED_BODIES) {
      requireCondition(
        errors,
        presetExcludesResource(preset, preserved.resource),
        `${name}: preserved V8.6 ${preserved.label} body must not leak into V8.5`,
      );
    }
  }

  const featurePresets = allPresets(presets).filter(({ base }) => String(base.custom_features ?? "").split(",").includes(FEATURE));
  requireCondition(
    errors,
    featurePresets.length === CANDIDATE_SPECS.length,
    `expected exactly ${CANDIDATE_SPECS.length} isolated V8.6 candidate presets, got ${featurePresets.length}`,
  );
  for (const spec of CANDIDATE_SPECS) {
    const candidate = presetByName(presets, spec.name);
    requireCondition(errors, Boolean(candidate), `candidate preset is missing: ${spec.name}`);
    if (!candidate) continue;
    requireCondition(errors, candidate.base.platform === spec.platform, `${spec.name}: expected ${spec.platform} platform`);
    requireCondition(errors, candidate.base.export_path === spec.path, `${spec.name}: expected export path ${spec.path}`);
    requireCondition(errors, candidate.base.runnable === false, `${spec.name}: candidate must not be runnable by default`);
    requireCondition(errors, candidate.base.custom_features === FEATURE, `${spec.name}: expected custom feature ${FEATURE}`);
    requireCondition(errors, candidate.base.export_filter === "exclude", `${spec.name}: expected exclude resource policy`);
    const excluded = String(candidate.base.export_files ?? "");
    requireCondition(errors, !presetExcludesResource(candidate, BODY_RESOURCE), `${spec.name}: V8.6 body must be available to the export plugin`);
    for (const preserved of PRESERVED_BODIES) {
      requireCondition(
        errors,
        presetExcludesResource(candidate, preserved.resource),
        `${spec.name}: preserved V8.6 ${preserved.label} body must remain excluded`,
      );
    }
    for (const marker of FORBIDDEN_CANDIDATE_MARKERS) {
      requireCondition(errors, excluded.includes(marker), `${spec.name}: missing exclusion for ${marker}`);
    }
    requireCondition(errors, String(candidate.base.exclude_filter ?? "").includes("addons/*"), `${spec.name}: editor addons must be excluded`);
    for (const [option, expected] of Object.entries(spec.options)) {
      requireCondition(errors, candidate.options[option] === expected, `${spec.name}: expected ${option}=${expected}`);
    }
  }

  const probeChecks = [
    [probeSource.includes(`OS.has_feature("${FEATURE}")`), "probe does not require the V8.6 feature"],
    [probeSource.includes(`OS.has_feature("${SHIPPING_FEATURE}")`), "probe does not accept the V8.6 shipping feature"],
    [probeSource.includes(BODY_RESOURCE), "probe does not pin the V8.6 body path"],
    [probeSource.includes(BODY_SHA256), "probe does not pin the V8.6 body SHA-256"],
    [probeSource.includes("liquid_material_count"), "probe does not inspect wet-material inventory"],
    [probeSource.includes("liquid_shell_material_count"), "probe does not inspect shell-material inventory"],
    [probeSource.includes("EXPECTED_ANIMATIONS"), "probe does not inspect the 14-animation inventory"],
    [probeSource.includes("marked_bodies.size() != 1"), "probe does not require exactly one authored body"],
    [probeSource.includes("marked_shells.size() != 1"), "probe does not require exactly one authored shell"],
    [probeSource.includes("wet_materials != 1"), "probe does not require exactly one wet material"],
    [probeSource.includes("shell_materials != 1"), "probe does not require exactly one shell material"],
    [probeSource.includes("authored_body_build_failed"), "probe does not reject failed authored-body construction"],
    [probeSource.includes("FORBIDDEN_FALLBACK_MARKERS"), "probe does not reject older fallback bodies"],
    [probeSource.includes("KitSwapBurst"), "probe does not inspect the loose-burst node"],
    [probeSource.includes("not loose_burst_hidden"), "probe does not require the loose burst to stay hidden"],
    [probeSource.includes("V8_6_EXPORT_PROBE_OK"), "probe success marker is missing"],
  ];
  for (const [condition, message] of probeChecks) requireCondition(errors, condition, message);
  for (const animation of PROBE_ANIMATIONS) {
    requireCondition(errors, probeSource.includes(`\"${animation}\"`), `probe is missing animation ${animation}`);
  }
  const rollbackChecks = [
    [rollbackProbeSource.includes('IMMUNE_GEL_LOOK'), "rollback probe does not require an explicit selector"],
    [rollbackProbeSource.includes('v8_3_single_mass'), "rollback probe does not inspect the V8.3 body"],
    [rollbackProbeSource.includes('v8_6_authored_sculpt'), "rollback probe does not reject the V8.6 body"],
    [rollbackProbeSource.includes('v8_6_single_mass_shell'), "rollback probe does not reject the V8.6 shell"],
    [rollbackProbeSource.includes('V8_3_ROLLBACK_PROBE_OK'), "rollback probe success marker is missing"],
  ];
  for (const [condition, message] of rollbackChecks) requireCondition(errors, condition, message);

  let pckResult = null;
  if (pck) {
    const pckPath = isAbsolute(pck) ? pck : resolve(root, pck);
    try {
      const info = await stat(pckPath);
      requireCondition(errors, info.isFile() && info.size > 0, `candidate PCK is empty: ${pckPath}`);
      if (info.isFile() && info.size > 0) {
        pckResult = validateV86PckPaths(parsePckResourcePaths(await readFile(pckPath)));
      }
    } catch (error) {
      if (error?.code === "ENOENT") errors.push(`candidate PCK is missing: ${pckPath}`);
      else throw error;
    }
  }

  if (errors.length) throw new Error(`V8_6_EXPORT_CONTRACT_FAILED\n- ${errors.join("\n- ")}`);
  return {
    candidatePresetCount: CANDIDATE_SPECS.length,
    shippingPresetCount: SHIPPING_NAMES.length,
    defaultLook,
    bodySha256: bodySha,
    preservedBodySha256,
    pck: pckResult ? "verified" : "not-requested",
    pckFiles: pckResult?.resourceCount ?? 0,
  };
}

async function main() {
  const args = parseV86ExportArgs(process.argv.slice(2));
  const report = await validateV86ExportContract(args);
  console.log(`V8_6_EXPORT_CONTRACT_OK candidate_presets=${report.candidatePresetCount} shipping_presets=${report.shippingPresetCount} default=${report.defaultLook} asset_sha=${report.bodySha256} pck=${report.pck} pck_files=${report.pckFiles}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
