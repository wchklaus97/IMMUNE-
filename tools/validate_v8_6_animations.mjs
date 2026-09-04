#!/usr/bin/env node

import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const PROJECT = resolve(ROOT, "godot/immune");
const GATE_SCRIPT = resolve(ROOT, "tools/godot/v8_6_animation_gate.gd");
const PINNED_LOCAL_GODOT = resolve(
  ROOT,
  "../work/godot-4.7.2/Godot.app/Contents/MacOS/Godot",
);
const SUCCESS_MARKER = "V8_6_ANIMATION_GATE_OK ";
const PINNED_VERSION = /^4\.7\.2\.stable\.official\.[0-9a-f]+$/u;

export const EXPECTED_SCULPT_PATH =
  "res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb";
export const EXPECTED_SCULPT_SHA256 =
  "3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3";
export const EXPECTED_SCULPT_RESOURCE_NAME = "V8.6-AuthoredSculpt-T-r7-2";
export const EXPECTED_SCULPT_AABB_POSITION = Object.freeze([-0.82, 0, -0.5]);
export const EXPECTED_SCULPT_AABB_SIZE = Object.freeze([1.64, 1.46, 1]);

export const EXPECTED_ANIMATIONS = Object.freeze([
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
]);

function requireCondition(condition, message) {
  if (!condition) throw new Error(`V8_6_ANIMATION_GATE_FAILED: ${message}`);
}

function requireFinite(report, key) {
  requireCondition(
    typeof report[key] === "number" && Number.isFinite(report[key]),
    `${key} must be a finite number`,
  );
  return report[key];
}

function requireVector3Match(report, key, expected) {
  const actual = report[key];
  requireCondition(
    Array.isArray(actual) && actual.length === 3,
    `${key} must be a three-component array, got ${JSON.stringify(actual)}`,
  );
  requireCondition(
    actual.every((component) => typeof component === "number" && Number.isFinite(component)),
    `${key} must contain only finite numbers, got ${JSON.stringify(actual)}`,
  );
  requireCondition(
    actual.every((component, index) => Math.abs(component - expected[index]) <= 1e-6),
    `${key} must match ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
  );
  return actual;
}

export function parseV86AnimationArgs(argv) {
  let godot = "";
  for (const raw of argv) {
    if (!raw.startsWith("--godot=")) throw new Error(`unknown option: ${raw}`);
    if (godot) throw new Error("--godot may be provided only once");
    godot = raw.slice("--godot=".length);
    if (!godot) throw new Error("--godot requires a non-empty path");
  }
  return { godot };
}

export function validateGodotVersion(output) {
  const version = String(output).trim().split(/\r?\n/u).at(-1) ?? "";
  requireCondition(PINNED_VERSION.test(version), `expected official stable Godot 4.7.2, got ${JSON.stringify(version)}`);
  return version;
}

export function validateAnimationGateReport(report) {
  requireCondition(report && typeof report === "object" && !Array.isArray(report), "report must be an object");
  requireCondition(report.schema === 2, `schema must be 2, got ${JSON.stringify(report.schema)}`);
  requireCondition(report.selector === "v8_6", `selector must be v8_6, got ${JSON.stringify(report.selector)}`);
  requireCondition(
    report.profile === "reference_convergence",
    `profile must be reference_convergence, got ${JSON.stringify(report.profile)}`,
  );
  requireCondition(
    report.sculpt_path === EXPECTED_SCULPT_PATH,
    `sculpt_path must bind exact R7.2 source ${EXPECTED_SCULPT_PATH}, got ${JSON.stringify(report.sculpt_path)}`,
  );
  requireCondition(
    report.sculpt_sha256 === EXPECTED_SCULPT_SHA256,
    `sculpt_sha256 must bind exact R7.2 bytes, got ${JSON.stringify(report.sculpt_sha256)}`,
  );
  requireCondition(
    report.sculpt_resource_name === EXPECTED_SCULPT_RESOURCE_NAME,
    `sculpt_resource_name must bind exact R7.2 runtime mesh, got ${JSON.stringify(report.sculpt_resource_name)}`,
  );
  requireVector3Match(report, "sculpt_aabb_position", EXPECTED_SCULPT_AABB_POSITION);
  requireVector3Match(report, "sculpt_aabb_size", EXPECTED_SCULPT_AABB_SIZE);
  requireCondition(report.fallback_nodes === 0, `fallback_nodes must be zero, got ${JSON.stringify(report.fallback_nodes)}`);
  requireCondition(report.animation_count === 14, `animation_count must be 14, got ${JSON.stringify(report.animation_count)}`);
  requireCondition(
    JSON.stringify(report.animations) === JSON.stringify(EXPECTED_ANIMATIONS),
    `animation inventory drifted: ${JSON.stringify(report.animations)}`,
  );
  requireCondition(report.sampled_clips === 14, `sampled_clips must be 14, got ${JSON.stringify(report.sampled_clips)}`);
  requireCondition(report.sampled_poses === 154, `sampled_poses must be 154, got ${JSON.stringify(report.sampled_poses)}`);

  const minScale = requireFinite(report, "min_scale");
  const maxScale = requireFinite(report, "max_scale");
  const moveScaleSpan = requireFinite(report, "move_scale_span");
  requireCondition(minScale >= 0.70, `sampled animation collapsed below scale floor: ${minScale}`);
  requireCondition(maxScale <= 1.30, `sampled animation exceeded scale ceiling: ${maxScale}`);
  requireCondition(minScale <= maxScale, `scale range is contradictory: ${minScale}..${maxScale}`);
  requireCondition(moveScaleSpan >= 0.03, `move clip lost its viscous squash span: ${moveScaleSpan}`);

  const idleFlowSpeed = requireFinite(report, "idle_flow_speed");
  const idleSlimeStrength = requireFinite(report, "idle_slime_strength");
  requireCondition(idleFlowSpeed > 0.001, `idle internal flow is disabled: ${idleFlowSpeed}`);
  requireCondition(idleSlimeStrength > 0.001, `cohesive slime field is disabled: ${idleSlimeStrength}`);

  const movingMix = requireFinite(report, "moving_mix");
  const movingLag = requireFinite(report, "moving_lag");
  const movingSquash = requireFinite(report, "moving_squash");
  const settlingLag = requireFinite(report, "settling_lag");
  const settledMix = requireFinite(report, "settled_mix");
  const settledLag = requireFinite(report, "settled_lag");
  const settledSquash = requireFinite(report, "settled_squash");
  requireCondition(movingMix >= 0.72 && movingMix <= 1.0, `movement overlay is outside acceptance range: ${movingMix}`);
  requireCondition(movingLag > 0.003 && movingLag <= 0.14, `viscous lag is outside acceptance range: ${movingLag}`);
  requireCondition(movingSquash > 0.004 && movingSquash <= 0.12, `movement squash is outside acceptance range: ${movingSquash}`);
  requireCondition(settlingLag > 0.003, `viscous drag did not persist after movement stopped: ${settlingLag}`);
  requireCondition(settledMix >= 0.0 && settledMix < 0.12, `movement overlay did not settle: ${settledMix}`);
  requireCondition(settledLag >= 0.0 && settledLag < 0.012, `viscous lag did not settle: ${settledLag}`);
  requireCondition(settledSquash >= 0.0 && settledSquash < 0.008, `viscous squash did not settle: ${settledSquash}`);

  requireCondition(report.wet_materials === 1, `expected one coherent wet material, got ${JSON.stringify(report.wet_materials)}`);
  requireCondition(report.shell_materials === 1, `expected one coherent shell material, got ${JSON.stringify(report.shell_materials)}`);
  requireCondition(report.collision_unchanged === true, "visual liquid motion changed gameplay collision");
  requireCondition(report.detached_meshes === 0, `detached meshes must be zero, got ${JSON.stringify(report.detached_meshes)}`);
  return report;
}

export function parseAnimationGateOutput(output) {
  const lines = String(output).split(/\r?\n/u);
  const marked = lines.filter((line) => line.startsWith(SUCCESS_MARKER));
  requireCondition(marked.length === 1, `expected one success marker, got ${marked.length}`);
  let report;
  try {
    report = JSON.parse(marked[0].slice(SUCCESS_MARKER.length));
  } catch (error) {
    throw new Error(`V8_6_ANIMATION_GATE_FAILED: malformed report JSON (${error.message})`);
  }
  return validateAnimationGateReport(report);
}

function chooseGodot(explicitPath) {
  if (explicitPath) return explicitPath;
  if (process.env.IMMUNE_GODOT_BIN) return process.env.IMMUNE_GODOT_BIN;
  if (existsSync(PINNED_LOCAL_GODOT)) return PINNED_LOCAL_GODOT;
  return "godot";
}

export function runV86AnimationGate({ godot = "" } = {}) {
  const binary = chooseGodot(godot);
  const versionResult = spawnSync(binary, ["--version"], { encoding: "utf8" });
  requireCondition(versionResult.error == null, `could not launch Godot at ${binary}: ${versionResult.error?.message ?? "unknown error"}`);
  requireCondition(versionResult.status === 0, `Godot --version exited ${versionResult.status}: ${versionResult.stderr}`);
  const version = validateGodotVersion(versionResult.stdout);

  const result = spawnSync(
    binary,
    [
      "--headless",
      "--audio-driver",
      "Dummy",
      "--path",
      PROJECT,
      "--script",
      GATE_SCRIPT,
    ],
    {
      encoding: "utf8",
      env: { ...process.env, IMMUNE_GEL_LOOK: "v8_6" },
      maxBuffer: 16 * 1024 * 1024,
    },
  );
  requireCondition(result.error == null, `Godot animation gate could not run: ${result.error?.message ?? "unknown error"}`);
  requireCondition(
    result.status === 0,
    `Godot animation gate exited ${result.status}\n${result.stdout}\n${result.stderr}`,
  );
  let report;
  try {
    report = parseAnimationGateOutput(`${result.stdout}\n${result.stderr}`);
  } catch (error) {
    throw new Error(`${error.message}\nGodot stdout:\n${result.stdout}\nGodot stderr:\n${result.stderr}`);
  }
  return { binary, version, report };
}

async function main() {
  const args = parseV86AnimationArgs(process.argv.slice(2));
  const result = runV86AnimationGate(args);
  console.log(
    `V8_6_ANIMATION_VALIDATION_OK godot=${result.version} animations=${result.report.animation_count} sampled_poses=${result.report.sampled_poses} detached=${result.report.detached_meshes}`,
  );
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
