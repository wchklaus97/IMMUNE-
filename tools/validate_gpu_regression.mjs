#!/usr/bin/env node

import fs from "node:fs";
import { createHash, randomBytes } from "node:crypto";
import path from "node:path";
import { fileURLToPath } from "node:url";

const DEFAULT_LIMITS = Object.freeze({
  meanPercent: 10,
  meanMs: 0.75,
  p95Percent: 10,
  p95Ms: 0.80,
  maxMs: 16.67,
  pairNoisePercent: 5,
  pairNoiseMs: 0.40,
});

const REPORT_CONTRACT = Object.freeze({
  schemaVersion: 1,
  process: "Godot",
  observedFrames: 360,
  dropFrames: 60,
  analyzedFrames: 300,
  captureHoldMs: 35_000,
  captureHoldMaxMs: 60_000,
  captureHoldClockToleranceMs: 1_000,
});

const EXPECTED_SEQUENCE = Object.freeze([
  { sequence: "A1", sequenceIndex: 1, look: "v8_5", group: "baseline", groupIndex: 0 },
  { sequence: "B1", sequenceIndex: 2, look: "v8_6", group: "candidate", groupIndex: 0 },
  { sequence: "B2", sequenceIndex: 3, look: "v8_6", group: "candidate", groupIndex: 1 },
  { sequence: "A2", sequenceIndex: 4, look: "v8_5", group: "baseline", groupIndex: 1 },
]);

const EXPECTED_WORKLOAD = Object.freeze({
  schema_version: 4,
  godot_version: "4.7.2-stable (official)",
  platform: "macOS",
  display_server: "macOS",
  rendering_method: "forward_plus",
  renderer: "metal",
  family: "T",
  source: "character",
  subject_scene: "res://characters/base_t/character.tscn",
  production_authored: true,
  legacy_diagnostic: false,
  material: "gel",
  count: 20,
  "viewport.width": 1920,
  "viewport.height": 1080,
  frames: 4000,
  warmup_frames: 60,
  sample_count: 4000,
  sync_mode: "none",
  capture_hold_ms: REPORT_CONTRACT.captureHoldMs,
  capture_window_always_on_top: true,
});

const EXPECTED_MATERIAL_STATS = Object.freeze({
  visible_mesh_instances: 140,
  wet_materials: 20,
  shell_materials: 20,
  eye_materials: 100,
  standard_replacements: 0,
});

const EXPECTED_ANIMATIONS = Object.freeze([
  "attack", "defeat", "hit", "idle", "move", "move_start", "move_stop",
  "plant", "relay_close", "relay_glide", "relay_open", "skill_cast", "uproot", "victory",
]);

const EXPECTED_ASSETS = Object.freeze({
  v8_5: Object.freeze({
    body_revision: "v8_5",
    asset_path: "res://characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb",
    asset_sha256: "8f14cfe59a508df413e4d53218f30bbf316e7e5d31e42154b2916a0bd5669294",
    asset_revision_label: "r4",
    asset_resource_name: "V8.5-AuthoredSculpt-T-r4",
    runtime_mesh_hash_schema: "godot-4.7.2-mesh-arrays-v1",
    runtime_mesh_sha256: "ce95be01d9b0b1272c74760f8c8e1d997baa0428e308a8cf50afb78cd77fbc4d",
    runtime_mesh_surface_count: 1,
    runtime_mesh_vertex_count: 6002,
    runtime_mesh_normal_count: 6002,
    runtime_mesh_index_count: 36000,
    runtime_mesh_surfaces: Object.freeze([Object.freeze({
      surface_index: 0,
      primitive: 3,
      format: 34896613383,
      name: "",
      vertex_count: 6002,
      normal_count: 6002,
      index_count: 36000,
    })]),
  }),
  v8_6: Object.freeze({
    body_revision: "v8_6",
    asset_path: "res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb",
    asset_sha256: "3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3",
    asset_revision_label: "r7-2",
    asset_resource_name: "V8.6-AuthoredSculpt-T-r7-2",
    runtime_mesh_hash_schema: "godot-4.7.2-mesh-arrays-v1",
    runtime_mesh_sha256: "d5efe6491bdc51aadafe4aaccb5c1c3321376e29f6949e123a458780bf57f1de",
    runtime_mesh_surface_count: 1,
    runtime_mesh_vertex_count: 6002,
    runtime_mesh_normal_count: 6002,
    runtime_mesh_index_count: 36000,
    runtime_mesh_surfaces: Object.freeze([Object.freeze({
      surface_index: 0,
      primitive: 3,
      format: 34896613383,
      name: "",
      vertex_count: 6002,
      normal_count: 6002,
      index_count: 36000,
    })]),
  }),
});

function statIdentityIfExists(file) {
  try {
    const realPath = fs.realpathSync(file);
    const stat = fs.statSync(realPath);
    return { realPath, stat };
  } catch (error) {
    if (error?.code === "ENOENT") return null;
    throw error;
  }
}

function sameFile(left, right) {
  return left.dev === right.dev && left.ino === right.ino;
}

function sameSnapshot(left, right) {
  return (
    sameFile(left, right)
    && left.size === right.size
    && left.mtimeMs === right.mtimeMs
    && left.ctimeMs === right.ctimeMs
  );
}

function prepareExclusiveOutput(outputPath, inputs) {
  const absolutePath = path.resolve(outputPath);
  fs.mkdirSync(path.dirname(absolutePath), { recursive: true });
  const realParent = fs.realpathSync(path.dirname(absolutePath));
  const publishPath = path.join(realParent, path.basename(absolutePath));
  let outputLstat = null;
  try {
    outputLstat = fs.lstatSync(absolutePath);
  } catch (error) {
    if (error?.code !== "ENOENT") throw error;
  }
  const outputIdentity = outputLstat ? statIdentityIfExists(absolutePath) : null;

  for (const entry of inputs) {
    const inputAbsolutePath = path.resolve(entry.file);
    const inputIdentity = statIdentityIfExists(inputAbsolutePath);
    if (
      absolutePath === inputAbsolutePath
      || (inputIdentity && publishPath === inputIdentity.realPath)
      || (outputIdentity && inputIdentity && sameFile(outputIdentity.stat, inputIdentity.stat))
    ) {
      throw new Error(`output path aliases ${entry.label}: ${absolutePath}`);
    }
  }
  if (outputLstat) throw new Error(`pre-existing output: ${absolutePath}`);
  return { absolutePath, publishPath, realParent };
}

function publishJsonExclusive(target, value) {
  const temporaryPath = path.join(
    target.realParent,
    `.${path.basename(target.publishPath)}.tmp-${process.pid}-${randomBytes(12).toString("hex")}`,
  );
  let descriptor;
  try {
    descriptor = fs.openSync(temporaryPath, "wx", 0o644);
    fs.writeFileSync(descriptor, `${JSON.stringify(value, null, 2)}\n`, "utf8");
    fs.fsyncSync(descriptor);
    fs.closeSync(descriptor);
    descriptor = undefined;
    try {
      fs.linkSync(temporaryPath, target.publishPath);
    } catch (error) {
      if (error?.code === "EEXIST") {
        throw new Error(`pre-existing output: ${target.absolutePath}`);
      }
      throw error;
    }
  } finally {
    if (descriptor !== undefined) fs.closeSync(descriptor);
    try {
      fs.unlinkSync(temporaryPath);
    } catch (error) {
      if (error?.code !== "ENOENT") throw error;
    }
  }
}

function fingerprintSourceArtifact(realPath) {
  const descriptor = fs.openSync(realPath, "r");
  try {
    const before = fs.fstatSync(descriptor);
    if (!before.isFile()) throw new Error("source artifact is not a regular file");
    const hash = createHash("sha256");
    const buffer = Buffer.allocUnsafe(1024 * 1024);
    let sizeBytes = 0;
    while (true) {
      const bytesRead = fs.readSync(descriptor, buffer, 0, buffer.length, null);
      if (bytesRead === 0) break;
      hash.update(buffer.subarray(0, bytesRead));
      sizeBytes += bytesRead;
    }
    const after = fs.fstatSync(descriptor);
    if (
      !sameSnapshot(before, after)
      || sizeBytes !== after.size
    ) {
      throw new Error("source artifact changed while hashing");
    }
    return {
      stat: after,
      sizeBytes,
      sha256: hash.digest("hex"),
    };
  } finally {
    fs.closeSync(descriptor);
  }
}

export function verifyGpuReportSourceArtifact(report, reportPath = "GPU report") {
  const binding = report?.source_artifact;
  if (binding == null || typeof binding !== "object" || Array.isArray(binding)) {
    throw new Error(`${reportPath}: source_artifact must be an object`);
  }
  if (
    typeof binding.absolute_path !== "string"
    || !path.isAbsolute(binding.absolute_path)
    || path.resolve(binding.absolute_path) !== binding.absolute_path
  ) {
    throw new Error(`${reportPath}: source_artifact.absolute_path must be absolute and normalized`);
  }
  if (
    typeof binding.real_path !== "string"
    || !path.isAbsolute(binding.real_path)
    || path.resolve(binding.real_path) !== binding.real_path
  ) {
    throw new Error(`${reportPath}: source_artifact.real_path must be absolute and normalized`);
  }
  if (!Number.isSafeInteger(binding.size_bytes) || binding.size_bytes < 0) {
    throw new Error(`${reportPath}: source_artifact.size_bytes must be a non-negative safe integer`);
  }
  if (typeof binding.sha256 !== "string" || !/^[a-f0-9]{64}$/u.test(binding.sha256)) {
    throw new Error(`${reportPath}: source_artifact.sha256 must be a lowercase SHA-256 digest`);
  }
  if (report?.source !== binding.absolute_path) {
    throw new Error(`${reportPath}: source must equal source_artifact.absolute_path`);
  }

  let actualRealPath;
  try {
    actualRealPath = fs.realpathSync(binding.absolute_path);
  } catch (error) {
    if (error?.code === "ENOENT") {
      throw new Error(`${reportPath}: source artifact does not exist: ${binding.absolute_path}`);
    }
    throw error;
  }
  if (actualRealPath !== binding.real_path) {
    throw new Error(
      `${reportPath}: source artifact realpath mismatch; declared ${binding.real_path}, got ${actualRealPath}`,
    );
  }

  const fingerprint = fingerprintSourceArtifact(actualRealPath);
  if (fingerprint.sizeBytes !== binding.size_bytes) {
    throw new Error(
      `${reportPath}: source artifact size mismatch; declared ${binding.size_bytes}, got ${fingerprint.sizeBytes}`,
    );
  }
  if (fingerprint.sha256 !== binding.sha256) {
    throw new Error(`${reportPath}: source artifact SHA-256 mismatch`);
  }
  const realPathAfter = fs.realpathSync(binding.absolute_path);
  const statAfter = fs.statSync(realPathAfter);
  if (realPathAfter !== actualRealPath || !sameSnapshot(fingerprint.stat, statAfter)) {
    throw new Error(`${reportPath}: source artifact changed while verifying`);
  }
  return {
    absolute_path: binding.absolute_path,
    real_path: actualRealPath,
    size_bytes: fingerprint.sizeBytes,
    sha256: fingerprint.sha256,
  };
}

function splitPaths(value, option) {
  const paths = String(value || "")
    .split(",")
    .map((entry) => entry.trim())
    .filter(Boolean);
  if (paths.length === 0) throw new Error(`${option}: expected at least one path`);
  return paths;
}

export function parseGpuRegressionArgs(argv) {
  const accepted = new Set([
    "baseline-reports",
    "candidate-reports",
    "baseline-runtimes",
    "candidate-runtimes",
    "out",
  ]);
  const values = {};
  for (const raw of argv) {
    if (!raw.startsWith("--") || !raw.includes("=")) throw new Error(`invalid option: ${raw}`);
    const [key, ...parts] = raw.slice(2).split("=");
    if (!accepted.has(key)) throw new Error(`unknown option: --${key}`);
    if (Object.hasOwn(values, key)) throw new Error(`duplicate option: --${key}`);
    values[key] = parts.join("=");
  }
  for (const required of [
    "baseline-reports",
    "candidate-reports",
    "baseline-runtimes",
    "candidate-runtimes",
  ]) {
    if (!Object.hasOwn(values, required)) throw new Error(`missing option: --${required}`);
  }
  return {
    baselineReports: splitPaths(values["baseline-reports"], "--baseline-reports"),
    candidateReports: splitPaths(values["candidate-reports"], "--candidate-reports"),
    baselineRuntimes: splitPaths(values["baseline-runtimes"], "--baseline-runtimes"),
    candidateRuntimes: splitPaths(values["candidate-runtimes"], "--candidate-runtimes"),
    out: String(values.out || ""),
  };
}

function valueAt(object, dottedPath) {
  return dottedPath.split(".").reduce((value, key) => value?.[key], object);
}

function sameValue(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

function finitePositive(value) {
  return typeof value === "number" && Number.isFinite(value) && value > 0;
}

function average(values) {
  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

function round(value, digits = 3) {
  return Number(value.toFixed(digits));
}

function summarize(reports) {
  return {
    run_count: reports.length,
    mean_ms: round(average(reports.map((report) => Number(report.gpu_frame_span_ms.mean)))),
    p95_ms: round(average(reports.map((report) => Number(report.gpu_frame_span_ms.p95)))),
    max_ms: round(Math.max(...reports.map((report) => Number(report.gpu_frame_span_ms.max)))),
    analyzed_frames_per_run: reports.map((report) => Number(report.analyzed_frame_count)),
  };
}

function regression(candidate, baseline) {
  const deltaMs = candidate - baseline;
  return {
    delta_ms: round(deltaMs),
    delta_percent: round((deltaMs / baseline) * 100, 2),
  };
}

function metricPairNoise(reports, metric, limits) {
  const values = reports.map((report) => Number(report.gpu_frame_span_ms[metric]));
  const spreadMs = Math.abs(values[1] - values[0]);
  const center = average(values);
  const spreadPercent = center > 0 ? (spreadMs / center) * 100 : Number.POSITIVE_INFINITY;
  return {
    values_ms: values.map((value) => round(value)),
    spread_ms: round(spreadMs),
    spread_percent: round(spreadPercent, 2),
    valid: (
      spreadMs <= limits.pairNoiseMs + Number.EPSILON * 16
      || spreadPercent <= limits.pairNoisePercent + Number.EPSILON * 16
    ),
  };
}

function pairNoise(reports, limits) {
  const mean = metricPairNoise(reports, "mean", limits);
  const p95 = metricPairNoise(reports, "p95", limits);
  return {
    mean,
    p95,
    // Preserve the original summary fields for older local evidence readers.
    mean_values_ms: mean.values_ms,
    spread_ms: mean.spread_ms,
    spread_percent: mean.spread_percent,
    mean_valid: mean.valid,
    p95_valid: p95.valid,
    valid: mean.valid && p95.valid,
  };
}

function validateGpuReport(report, runtime, expected, limits, errors) {
  const prefix = `${expected.group}[${expected.groupIndex}]`;
  if (report?.schema_version !== REPORT_CONTRACT.schemaVersion) {
    errors.push(`${prefix}: GPU report schema_version must equal 1`);
  }
  if (report?.process !== REPORT_CONTRACT.process) {
    errors.push(`${prefix}: process must equal Godot`);
  }
  if (!Number.isInteger(report?.pid) || report.pid <= 0) {
    errors.push(`${prefix}: report PID must be a positive integer`);
  } else if (report.pid !== runtime?.process_pid) {
    errors.push(`${prefix}: report PID does not match runtime process_pid`);
  }
  if (report?.run_id !== runtime?.run_id) {
    errors.push(`${prefix}: report run_id does not match its runtime report`);
  }
  if (report?.sequence !== expected.sequence || runtime?.sequence !== expected.sequence) {
    errors.push(`${prefix}: expected sequence ${expected.sequence} in report and runtime`);
  }
  if (
    report?.sequence_index !== expected.sequenceIndex
    || runtime?.sequence_index !== expected.sequenceIndex
  ) {
    errors.push(`${prefix}: sequence_index must equal ${expected.sequenceIndex}`);
  }
  if (typeof report?.source !== "string" || report.source.length === 0) {
    errors.push(`${prefix}: GPU report source must be a non-empty trace path`);
  }
  if (
    !Number.isInteger(report?.observed_frame_count)
    || report.observed_frame_count < REPORT_CONTRACT.observedFrames
  ) {
    errors.push(`${prefix}: observed_frame_count must be at least ${REPORT_CONTRACT.observedFrames}`);
  }
  if (report?.dropped_warmup_frames !== REPORT_CONTRACT.dropFrames) {
    errors.push(`${prefix}: dropped_warmup_frames must equal 60`);
  }
  if (report?.requested_max_frames !== REPORT_CONTRACT.analyzedFrames) {
    errors.push(`${prefix}: requested_max_frames must equal ${REPORT_CONTRACT.analyzedFrames}`);
  }
  if (report?.analyzed_frame_count !== REPORT_CONTRACT.analyzedFrames) {
    errors.push(`${prefix}: expected exactly ${REPORT_CONTRACT.analyzedFrames} analyzed frames`);
  }
  if (report?.analyzed_frames_contiguous !== true) {
    errors.push(`${prefix}: analyzed GPU frames must be contiguous`);
  }
  if (
    !Number.isInteger(report?.first_analyzed_frame)
    || !Number.isInteger(report?.last_analyzed_frame)
    || report.last_analyzed_frame - report.first_analyzed_frame !== REPORT_CONTRACT.analyzedFrames - 1
  ) {
    errors.push(`${prefix}: analyzed frame number span must contain exactly ${REPORT_CONTRACT.analyzedFrames} frames`);
  }
  if (report?.malformed_target_rows !== 0) {
    errors.push(`${prefix}: malformed_target_rows must be zero`);
  }
  if (!Number.isInteger(report?.nested_target_rows) || report.nested_target_rows < 0) {
    errors.push(`${prefix}: nested_target_rows must be a non-negative integer`);
  }
  if (!Number.isInteger(report?.unframed_target_rows) || report.unframed_target_rows < 0) {
    errors.push(`${prefix}: unframed_target_rows must be a non-negative integer`);
  }
  if (report?.unframed_target_rows_overlapping_analyzed_window !== 0) {
    errors.push(`${prefix}: unframed target rows must not overlap the analyzed window`);
  }
  if (!Number.isInteger(report?.target_event_count) || report.target_event_count <= 0) {
    errors.push(`${prefix}: target_event_count must be a positive integer`);
  }
  if (
    report?.channel_event_counts == null
    || typeof report.channel_event_counts !== "object"
    || Array.isArray(report.channel_event_counts)
    || Object.keys(report.channel_event_counts).length === 0
  ) {
    errors.push(`${prefix}: channel_event_counts must evidence at least one GPU channel`);
  } else if (
    Object.values(report.channel_event_counts).some(
      (value) => !Number.isInteger(value) || value <= 0,
    )
  ) {
    errors.push(`${prefix}: every channel_event_counts value must be a positive integer`);
  } else if (
    Number.isInteger(report?.target_event_count)
    && Number.isInteger(report?.nested_target_rows)
    && Number.isInteger(report?.unframed_target_rows)
    && Number.isInteger(report?.malformed_target_rows)
    && Object.values(report.channel_event_counts).reduce((sum, value) => sum + value, 0)
      + report.nested_target_rows
      + report.unframed_target_rows
      + report.malformed_target_rows !== report.target_event_count
  ) {
    errors.push(`${prefix}: target GPU row accounting mismatch`);
  }
  for (const metric of ["mean", "p50", "p95", "max"]) {
    if (!finitePositive(report?.gpu_frame_span_ms?.[metric])) {
      errors.push(`${prefix}: gpu_frame_span_ms.${metric} must be finite and positive`);
    }
  }
  const summary = report?.gpu_frame_span_ms;
  if (
    summary
    && finitePositive(summary.mean)
    && finitePositive(summary.p50)
    && finitePositive(summary.p95)
    && finitePositive(summary.max)
    && (Number(summary.p50) > Number(summary.p95)
      || Number(summary.mean) > Number(summary.max)
      || Number(summary.p95) > Number(summary.max))
  ) {
    errors.push(`${prefix}: GPU timing summary is internally inconsistent`);
  }
  if (finitePositive(summary?.max) && Number(summary.max) >= limits.maxMs) {
    errors.push(
      `${prefix}: max GPU frame must be below ${limits.maxMs} ms; got ${summary.max} ms`,
    );
  }
}

function validateRuntimeIdentity(runtime, expected, errors) {
  const prefix = `${expected.group}[${expected.groupIndex}]`;
  const identity = runtime?.runtime_identity;
  if (identity == null || typeof identity !== "object" || Array.isArray(identity)) {
    errors.push(`${prefix}: runtime_identity must be an object`);
    return;
  }
  const expectedAsset = EXPECTED_ASSETS[expected.look];
  for (const [field, wanted] of Object.entries(expectedAsset)) {
    if (!sameValue(identity[field], wanted)) {
      errors.push(`${prefix}: runtime_identity.${field} got ${JSON.stringify(identity[field])}; expected ${JSON.stringify(wanted)}`);
    }
  }
  for (const [field, wanted] of Object.entries({
    authored_sculpt: true,
    fallback_used: false,
    body_build_failed: false,
    shell_present: true,
    shell_visible: true,
    shell_shares_body_mesh: true,
    animation_count: 14,
    active_animation: "idle",
    animation_playing: true,
    animation_kind: "rest",
  })) {
    if (identity[field] !== wanted) {
      errors.push(`${prefix}: runtime_identity.${field} got ${JSON.stringify(identity[field])}; expected ${JSON.stringify(wanted)}`);
    }
  }
  if (identity.runtime_mesh_error !== "") {
    errors.push(`${prefix}: runtime_identity.runtime_mesh_error must be empty; got ${JSON.stringify(identity.runtime_mesh_error)}`);
  }
  if (!sameValue(identity.animation_catalog, EXPECTED_ANIMATIONS)) {
    errors.push(`${prefix}: runtime_identity.animation_catalog must equal the locked 14-animation list`);
  }
}

function validateRuntime(runtime, expected, errors) {
  const prefix = `${expected.group}[${expected.groupIndex}]`;
  for (const [field, wanted] of Object.entries(EXPECTED_WORKLOAD)) {
    const actual = valueAt(runtime, field);
    if (!sameValue(actual, wanted)) {
      errors.push(`${prefix}: ${field} got ${JSON.stringify(actual)}; expected ${JSON.stringify(wanted)}`);
    }
  }
  if (runtime?.gel_look !== expected.look) {
    errors.push(`${prefix}: gel_look must equal ${expected.look}; got ${JSON.stringify(runtime?.gel_look)}`);
  }
  if (!Number.isInteger(runtime?.process_pid) || runtime.process_pid <= 0) {
    errors.push(`${prefix}: process_pid must be a positive integer`);
  }
  if (
    typeof runtime?.run_id !== "string"
    || !/^[A-Za-z0-9][A-Za-z0-9._-]{7,127}$/u.test(runtime.run_id)
  ) {
    errors.push(`${prefix}: run_id must be an 8-128 character safe identifier`);
  }
  if (
    !Number.isInteger(runtime?.measurement_started_unix_ms)
    || !Number.isInteger(runtime?.measurement_finished_unix_ms)
    || runtime.measurement_started_unix_ms <= 0
    || runtime.measurement_finished_unix_ms < runtime.measurement_started_unix_ms
  ) {
    errors.push(`${prefix}: measurement timestamps are invalid`);
  }
  if (runtime?.capture_hold_status !== "complete") {
    errors.push(`${prefix}: capture_hold_status must equal complete`);
  }
  if (
    !Number.isInteger(runtime?.capture_hold_started_unix_ms)
    || !Number.isInteger(runtime?.capture_hold_finished_unix_ms)
    || runtime.capture_hold_started_unix_ms < runtime.measurement_finished_unix_ms
    || runtime.capture_hold_finished_unix_ms < runtime.capture_hold_started_unix_ms
  ) {
    errors.push(`${prefix}: capture hold timestamps are invalid or precede measurement completion`);
  }
  if (
    !Number.isInteger(runtime?.capture_hold_actual_ms)
    || runtime.capture_hold_actual_ms < REPORT_CONTRACT.captureHoldMs
    || runtime.capture_hold_actual_ms > REPORT_CONTRACT.captureHoldMaxMs
  ) {
    errors.push(
      `${prefix}: capture_hold_actual_ms must be between ${REPORT_CONTRACT.captureHoldMs} and ${REPORT_CONTRACT.captureHoldMaxMs}`,
    );
  }
  if (
    !Number.isInteger(runtime?.capture_hold_rendered_frames)
    || runtime.capture_hold_rendered_frames <= 0
  ) {
    errors.push(`${prefix}: capture_hold_rendered_frames must be a positive integer`);
  }
  if (
    Number.isInteger(runtime?.capture_hold_started_unix_ms)
    && Number.isInteger(runtime?.capture_hold_finished_unix_ms)
    && Number.isInteger(runtime?.capture_hold_actual_ms)
  ) {
    const holdWallClockMs = (
      runtime.capture_hold_finished_unix_ms - runtime.capture_hold_started_unix_ms
    );
    if (
      holdWallClockMs < REPORT_CONTRACT.captureHoldMs
      || holdWallClockMs > REPORT_CONTRACT.captureHoldMaxMs
      || Math.abs(holdWallClockMs - runtime.capture_hold_actual_ms)
        > REPORT_CONTRACT.captureHoldClockToleranceMs
    ) {
      errors.push(
        `${prefix}: capture hold wall-clock span must be ${REPORT_CONTRACT.captureHoldMs}-${REPORT_CONTRACT.captureHoldMaxMs} ms and agree with capture_hold_actual_ms within ${REPORT_CONTRACT.captureHoldClockToleranceMs} ms`,
      );
    }
  }
  if (
    runtime?.options == null
    || typeof runtime.options !== "object"
    || Array.isArray(runtime.options)
    || Object.keys(runtime.options).length !== 0
  ) {
    errors.push(`${prefix}: options must be empty for selector-level comparison`);
  }
  for (const [key, wanted] of Object.entries(EXPECTED_MATERIAL_STATS)) {
    if (runtime?.material_stats?.[key] !== wanted) {
      errors.push(`${prefix}: material_stats.${key} got ${runtime?.material_stats?.[key]}; expected ${wanted}`);
    }
  }
  validateRuntimeIdentity(runtime, expected, errors);
}

function orderedRuns(input) {
  return EXPECTED_SEQUENCE.map((expected) => ({
    expected,
    report: input[`${expected.group}Reports`][expected.groupIndex],
    runtime: input[`${expected.group}Runtimes`][expected.groupIndex],
  }));
}

export function validateGpuRegression({
  baselineReports,
  candidateReports,
  baselineRuntimes,
  candidateRuntimes,
  limits = DEFAULT_LIMITS,
}) {
  if (
    baselineReports?.length !== 2
    || candidateReports?.length !== 2
    || baselineRuntimes?.length !== 2
    || candidateRuntimes?.length !== 2
  ) {
    throw new Error("expected exactly two baseline and two candidate runs with matching runtimes");
  }

  const input = { baselineReports, candidateReports, baselineRuntimes, candidateRuntimes };
  const contractErrors = [];
  const performanceErrors = [];
  const noiseErrors = [];
  const runs = orderedRuns(input);

  for (const { report, runtime, expected } of runs) {
    validateRuntime(runtime, expected, contractErrors);
    validateGpuReport(report, runtime, expected, limits, contractErrors);
  }

  const runId = baselineRuntimes[0]?.run_id;
  for (const { runtime, expected } of runs) {
    if (runtime?.run_id !== runId) {
      contractErrors.push(`${expected.sequence}: all four runtime reports must share one run_id`);
    }
  }
  const traceSources = runs.map(({ report }) => report?.source);
  if (new Set(traceSources).size !== runs.length) {
    contractErrors.push("A1, B1, B2, and A2 must reference four distinct trace sources");
  }
  for (let index = 1; index < runs.length; index += 1) {
    const previous = runs[index - 1].runtime;
    const current = runs[index].runtime;
    if (
      !Number.isInteger(previous?.capture_hold_finished_unix_ms)
      || !Number.isInteger(current?.measurement_started_unix_ms)
      || current.measurement_started_unix_ms <= previous.capture_hold_finished_unix_ms
    ) {
      contractErrors.push(
        `measurement chronology must respect capture hold chronology A1 then B1 then B2 then A2; ${runs[index].expected.sequence} did not start after ${runs[index - 1].expected.sequence} completed its capture hold`,
      );
    }
  }

  const baseline = summarize(baselineReports);
  const candidate = summarize(candidateReports);
  const rawBaseline = {
    mean: average(baselineReports.map((report) => Number(report.gpu_frame_span_ms.mean))),
    p95: average(baselineReports.map((report) => Number(report.gpu_frame_span_ms.p95))),
  };
  const rawCandidate = {
    mean: average(candidateReports.map((report) => Number(report.gpu_frame_span_ms.mean))),
    p95: average(candidateReports.map((report) => Number(report.gpu_frame_span_ms.p95))),
  };
  const comparison = {
    mean: regression(candidate.mean_ms, baseline.mean_ms),
    p95: regression(candidate.p95_ms, baseline.p95_ms),
  };

  const rawMeanDelta = rawCandidate.mean - rawBaseline.mean;
  const rawMeanPercent = (rawMeanDelta / rawBaseline.mean) * 100;
  const rawP95Delta = rawCandidate.p95 - rawBaseline.p95;
  const rawP95Percent = (rawP95Delta / rawBaseline.p95) * 100;

  if (
    rawMeanDelta > limits.meanMs
    || rawMeanPercent > limits.meanPercent
  ) {
    performanceErrors.push(
      `mean regression ${comparison.mean.delta_ms} ms / ${comparison.mean.delta_percent}% exceeds either ${limits.meanMs} ms or ${limits.meanPercent}% ceiling`,
    );
  }
  if (
    rawP95Delta > limits.p95Ms
    || rawP95Percent > limits.p95Percent
  ) {
    performanceErrors.push(
      `p95 regression ${comparison.p95.delta_ms} ms / ${comparison.p95.delta_percent}% exceeds either ${limits.p95Ms} ms or ${limits.p95Percent}% ceiling`,
    );
  }

  const noise = {
    baseline: pairNoise(baselineReports, limits),
    candidate: pairNoise(candidateReports, limits),
  };
  for (const selector of ["baseline", "candidate"]) {
    const evidence = noise[selector];
    if (!evidence.mean_valid) {
      noiseErrors.push(
        `${selector} mean spread ${evidence.mean.spread_ms} ms / ${evidence.mean.spread_percent}% exceeds both ${limits.pairNoiseMs} ms and ${limits.pairNoisePercent}% noise ceiling`,
      );
    }
    if (!evidence.p95_valid) {
      noiseErrors.push(
        `${selector} p95 spread ${evidence.p95.spread_ms} ms / ${evidence.p95.spread_percent}% exceeds both ${limits.pairNoiseMs} ms and ${limits.pairNoisePercent}% noise ceiling`,
      );
    }
  }

  const errors = [...contractErrors, ...performanceErrors, ...noiseErrors];
  const verdict = (
    errors.length === 0
      ? "PASS"
      : (contractErrors.length === 0 && performanceErrors.length === 0 ? "INCONCLUSIVE" : "FAIL")
  );
  return {
    schema_version: 2,
    ok: verdict === "PASS",
    verdict,
    run_id: runId || null,
    sequence: EXPECTED_SEQUENCE.map((entry) => entry.sequence),
    limits: { ...limits },
    report_contract: { ...REPORT_CONTRACT },
    baseline,
    candidate,
    selectors: { baseline: "v8_5", candidate: "v8_6" },
    comparison,
    noise,
    errors,
  };
}

function loadReports(paths) {
  return paths.map((file) => JSON.parse(fs.readFileSync(file, "utf8")));
}

function loadBoundGpuReports(paths, option) {
  return paths.map((file, index) => {
    const absolutePath = path.resolve(file);
    const report = JSON.parse(fs.readFileSync(absolutePath, "utf8"));
    verifyGpuReportSourceArtifact(report, `${option}[${index}] ${absolutePath}`);
    return report;
  });
}

function runCli() {
  let args;
  try {
    args = parseGpuRegressionArgs(process.argv.slice(2));
    const inputPaths = [
      ...args.baselineReports.map((file, index) => ({
        file,
        label: `input --baseline-reports[${index}]`,
      })),
      ...args.candidateReports.map((file, index) => ({
        file,
        label: `input --candidate-reports[${index}]`,
      })),
      ...args.baselineRuntimes.map((file, index) => ({
        file,
        label: `input --baseline-runtimes[${index}]`,
      })),
      ...args.candidateRuntimes.map((file, index) => ({
        file,
        label: `input --candidate-runtimes[${index}]`,
      })),
    ];
    const outputTarget = args.out
      ? prepareExclusiveOutput(args.out, inputPaths)
      : null;
    const result = validateGpuRegression({
      baselineReports: loadBoundGpuReports(args.baselineReports, "--baseline-reports"),
      candidateReports: loadBoundGpuReports(args.candidateReports, "--candidate-reports"),
      baselineRuntimes: loadReports(args.baselineRuntimes),
      candidateRuntimes: loadReports(args.candidateRuntimes),
    });
    if (outputTarget) publishJsonExclusive(outputTarget, result);
    const prefix = `GPU_REGRESSION_GATE_${result.verdict}`;
    console.log(
      `${prefix} runs=${result.candidate.run_count} mean_ms=${result.candidate.mean_ms.toFixed(3)} p95_ms=${result.candidate.p95_ms.toFixed(3)} max_ms=${result.candidate.max_ms.toFixed(3)}`,
    );
    for (const error of result.errors) console.error(`- ${error}`);
    if (!result.ok) process.exitCode = 1;
  } catch (error) {
    console.error(`GPU_REGRESSION_GATE_FAILED ${error.message}`);
    process.exitCode = 2;
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  runCli();
}
