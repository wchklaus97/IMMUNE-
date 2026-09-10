import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { promisify } from "node:util";

import {
  parseGpuRegressionArgs,
  validateGpuRegression,
} from "./validate_gpu_regression.mjs";

const execFileAsync = promisify(execFile);
const VALIDATOR = path.resolve("tools/validate_gpu_regression.mjs");

const RUN_ID = "v86-metal-gate-20260904";
const SEQUENCE_INDEX = Object.freeze({ A1: 1, B1: 2, B2: 3, A2: 4 });
const ASSET_IDENTITY = Object.freeze({
  v8_5: {
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
    runtime_mesh_surfaces: [{
      surface_index: 0,
      primitive: 3,
      format: 34896613383,
      name: "",
      vertex_count: 6002,
      normal_count: 6002,
      index_count: 36000,
    }],
  },
  v8_6: {
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
    runtime_mesh_surfaces: [{
      surface_index: 0,
      primitive: 3,
      format: 34896613383,
      name: "",
      vertex_count: 6002,
      normal_count: 6002,
      index_count: 36000,
    }],
  },
});
const ANIMATIONS = Object.freeze([
  "attack", "defeat", "hit", "idle", "move", "move_start", "move_stop",
  "plant", "relay_close", "relay_glide", "relay_open", "skill_cast", "uproot", "victory",
]);

function gpuReport(mean, p95, max, sequence, pid = 1234, frames = 300) {
  return {
    schema_version: 1,
    source: `/tmp/${sequence}.trace/metal-gpu-intervals.xml`,
    process: "Godot",
    pid,
    run_id: RUN_ID,
    sequence,
    sequence_index: SEQUENCE_INDEX[sequence],
    target_event_count: frames * 3,
    malformed_target_rows: 0,
    nested_target_rows: frames,
    unframed_target_rows: 0,
    unframed_target_rows_overlapping_analyzed_window: 0,
    observed_frame_count: frames + 60,
    dropped_warmup_frames: 60,
    requested_max_frames: 300,
    analyzed_frame_count: frames,
    analyzed_frames_contiguous: true,
    first_analyzed_frame: 61,
    last_analyzed_frame: frames + 60,
    gpu_frame_span_ms: { mean, p50: mean - 0.2, p95, max },
    channel_event_counts: { Fragment: frames, Vertex: frames },
  };
}

function runtime(look, sequence, startMs, pid = 1234) {
  const identity = ASSET_IDENTITY[look];
  const measurementFinishedMs = startMs + 900;
  const captureHoldStartedMs = measurementFinishedMs + 1;
  return {
    schema_version: 4,
    run_id: RUN_ID,
    sequence,
    sequence_index: SEQUENCE_INDEX[sequence],
    process_pid: pid,
    measurement_started_unix_ms: startMs,
    measurement_finished_unix_ms: measurementFinishedMs,
    capture_hold_ms: 35_000,
    capture_hold_status: "complete",
    capture_hold_started_unix_ms: captureHoldStartedMs,
    capture_hold_finished_unix_ms: captureHoldStartedMs + 35_000,
    capture_hold_actual_ms: 35_000,
    capture_hold_rendered_frames: 2_100,
    capture_window_always_on_top: true,
    gel_look: look,
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
    viewport: { width: 1920, height: 1080 },
    frames: 4000,
    warmup_frames: 60,
    sample_count: 4000,
    sync_mode: "none",
    material_stats: {
      visible_mesh_instances: 140,
      wet_materials: 20,
      shell_materials: 20,
      eye_materials: 100,
      standard_replacements: 0,
    },
    runtime_identity: {
      ...structuredClone(identity),
      runtime_mesh_error: "",
      authored_sculpt: true,
      fallback_used: false,
      body_build_failed: false,
      shell_present: true,
      shell_visible: true,
      shell_shares_body_mesh: true,
      animation_catalog: [...ANIMATIONS],
      animation_count: 14,
      active_animation: "idle",
      animation_playing: true,
      animation_kind: "rest",
    },
    options: {},
  };
}

function validGateInput() {
  return {
    baselineReports: [
      gpuReport(7.20, 8.00, 12.70, "A1"),
      gpuReport(7.24, 7.96, 12.80, "A2"),
    ],
    candidateReports: [
      gpuReport(7.70, 8.40, 14.10, "B1"),
      gpuReport(7.74, 8.44, 14.30, "B2"),
    ],
    baselineRuntimes: [runtime("v8_5", "A1", 1_000), runtime("v8_5", "A2", 121_000)],
    candidateRuntimes: [runtime("v8_6", "B1", 41_000), runtime("v8_6", "B2", 81_000)],
  };
}

function sourceArtifact(file) {
  const bytes = fs.readFileSync(file);
  return {
    absolute_path: path.resolve(file),
    real_path: fs.realpathSync(file),
    size_bytes: bytes.length,
    sha256: createHash("sha256").update(bytes).digest("hex"),
  };
}

function writeCliFixture(tempDir, { bindSources = true } = {}) {
  const input = validGateInput();
  const reportGroups = [
    ["baselineReports", input.baselineReports],
    ["candidateReports", input.candidateReports],
  ];
  const runtimeGroups = [
    ["baselineRuntimes", input.baselineRuntimes],
    ["candidateRuntimes", input.candidateRuntimes],
  ];
  const paths = {
    baselineReports: [],
    candidateReports: [],
    baselineRuntimes: [],
    candidateRuntimes: [],
    sources: {},
  };

  for (const [key, reports] of reportGroups) {
    for (const report of reports) {
      if (bindSources) {
        const source = path.join(tempDir, `${report.sequence}-intervals.xml`);
        fs.writeFileSync(source, `trace artifact ${report.sequence}\n`);
        report.source = path.resolve(source);
        report.source_artifact = sourceArtifact(source);
        paths.sources[report.sequence] = source;
      }
      const reportPath = path.join(tempDir, `${report.sequence}-gpu-report.json`);
      fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
      paths[key].push(reportPath);
    }
  }
  for (const [key, runtimes] of runtimeGroups) {
    for (const runtimeReport of runtimes) {
      const runtimePath = path.join(tempDir, `${runtimeReport.sequence}-runtime.json`);
      fs.writeFileSync(runtimePath, `${JSON.stringify(runtimeReport, null, 2)}\n`);
      paths[key].push(runtimePath);
    }
  }

  paths.args = [
    `--baseline-reports=${paths.baselineReports.join(",")}`,
    `--candidate-reports=${paths.candidateReports.join(",")}`,
    `--baseline-runtimes=${paths.baselineRuntimes.join(",")}`,
    `--candidate-runtimes=${paths.candidateRuntimes.join(",")}`,
  ];
  return paths;
}

test("parses paired AB/BA report and runtime paths", () => {
  assert.deepEqual(
    parseGpuRegressionArgs([
      "--baseline-reports=a.json,b.json",
      "--candidate-reports=c.json,d.json",
      "--baseline-runtimes=ar.json,br.json",
      "--candidate-runtimes=cr.json,dr.json",
      "--out=gate.json",
    ]),
    {
      baselineReports: ["a.json", "b.json"],
      candidateReports: ["c.json", "d.json"],
      baselineRuntimes: ["ar.json", "br.json"],
      candidateRuntimes: ["cr.json", "dr.json"],
      out: "gate.json",
    },
  );
});

test("accepts the exact A1 B1 B2 A2 V8.5/V8.6 evidence contract", () => {
  const result = validateGpuRegression(validGateInput());

  assert.equal(result.ok, true);
  assert.equal(result.verdict, "PASS");
  assert.deepEqual(result.sequence, ["A1", "B1", "B2", "A2"]);
  assert.equal(result.baseline.run_count, 2);
  assert.equal(result.candidate.run_count, 2);
  assert.equal(result.candidate.mean_ms, 7.72);
  assert.equal(result.candidate.p95_ms, 8.42);
  assert.equal(result.candidate.max_ms, 14.3);
  assert.equal(result.noise.baseline.valid, true);
  assert.equal(result.noise.candidate.valid, true);
});

test("accepts only accounted unframed rows outside the analyzed window", () => {
  const accepted = validGateInput();
  accepted.candidateReports[0].unframed_target_rows = 7;
  accepted.candidateReports[0].target_event_count += 7;
  assert.equal(validateGpuRegression(accepted).ok, true);

  const overlapping = validGateInput();
  overlapping.candidateReports[0].unframed_target_rows = 1;
  overlapping.candidateReports[0].unframed_target_rows_overlapping_analyzed_window = 1;
  overlapping.candidateReports[0].target_event_count += 1;
  const overlapResult = validateGpuRegression(overlapping);
  assert.equal(overlapResult.ok, false);
  assert.match(overlapResult.errors.join("\n"), /must not overlap/u);

  const miscounted = validGateInput();
  miscounted.candidateReports[0].target_event_count += 1;
  const miscountedResult = validateGpuRegression(miscounted);
  assert.equal(miscountedResult.ok, false);
  assert.match(miscountedResult.errors.join("\n"), /row accounting mismatch/u);

  const missing = validGateInput();
  delete missing.candidateReports[0].unframed_target_rows;
  const missingResult = validateGpuRegression(missing);
  assert.equal(missingResult.ok, false);
  assert.match(missingResult.errors.join("\n"), /unframed_target_rows.*non-negative/u);
});

test("fails closed unless workload is exact Forward+/Metal T character gel 20 at 1080p/4000", () => {
  const input = validGateInput();
  const run = input.candidateRuntimes[0];
  run.rendering_method = "mobile";
  run.count = 19;
  run.viewport.width = 1280;
  run.frames = 3999;
  run.sample_count = 3999;
  run.capture_window_always_on_top = false;
  run.options = { studio_reflection_strength: 0.1 };

  const result = validateGpuRegression(input);
  const errors = result.errors.join("\n");
  assert.equal(result.ok, false);
  assert.match(errors, /rendering_method.*forward_plus/u);
  assert.match(errors, /count.*20/u);
  assert.match(errors, /viewport.width.*1920/u);
  assert.match(errors, /frames.*4000/u);
  assert.match(errors, /capture_window_always_on_top.*true/u);
  assert.match(errors, /options must be empty/u);
});

test("requires a completed rendered 35000 ms post-measure capture hold", () => {
  const missing = validGateInput();
  delete missing.candidateRuntimes[0].capture_hold_ms;
  const missingResult = validateGpuRegression(missing);
  assert.equal(missingResult.ok, false);
  assert.match(missingResult.errors.join("\n"), /capture_hold_ms.*35000/u);

  const incomplete = validGateInput();
  const run = incomplete.candidateRuntimes[0];
  run.capture_hold_ms = 30_000;
  run.capture_hold_status = "ready";
  run.capture_hold_actual_ms = 34_999;
  run.capture_hold_rendered_frames = 0;
  run.capture_hold_started_unix_ms = run.measurement_finished_unix_ms - 1;
  const incompleteResult = validateGpuRegression(incomplete);
  const errors = incompleteResult.errors.join("\n");
  assert.equal(incompleteResult.ok, false);
  assert.match(errors, /capture_hold_ms.*35000/u);
  assert.match(errors, /capture_hold_status.*complete/u);
  assert.match(errors, /capture hold timestamps/u);
  assert.match(errors, /capture_hold_actual_ms.*35000/u);
  assert.match(errors, /capture_hold_rendered_frames.*positive/u);

  const overlap = validGateInput();
  overlap.candidateRuntimes[0].measurement_started_unix_ms = 10_000;
  overlap.candidateRuntimes[0].measurement_finished_unix_ms = 10_900;
  overlap.candidateRuntimes[0].capture_hold_started_unix_ms = 10_901;
  overlap.candidateRuntimes[0].capture_hold_finished_unix_ms = 45_901;
  const overlapResult = validateGpuRegression(overlap);
  assert.equal(overlapResult.ok, false);
  assert.match(overlapResult.errors.join("\n"), /capture hold chronology/u);

  const contradictory = validGateInput();
  const contradictoryRun = contradictory.candidateRuntimes[1];
  contradictoryRun.capture_hold_finished_unix_ms = (
    contradictoryRun.capture_hold_started_unix_ms + 1_000
  );
  const contradictoryResult = validateGpuRegression(contradictory);
  assert.equal(contradictoryResult.ok, false);
  assert.match(contradictoryResult.errors.join("\n"), /capture hold wall-clock span/u);
});

test("requires exactly two baselines, two candidates, and A1 B1 B2 A2 chronology", () => {
  const missing = validGateInput();
  missing.baselineReports.pop();
  missing.baselineRuntimes.pop();
  assert.throws(() => validateGpuRegression(missing), /exactly two baseline and two candidate runs/u);

  const reordered = validGateInput();
  reordered.candidateReports[0].sequence = "B2";
  reordered.candidateRuntimes[0].sequence = "B2";
  const result = validateGpuRegression(reordered);
  assert.equal(result.ok, false);
  assert.match(result.errors.join("\n"), /expected sequence B1/u);

  const badChronology = validGateInput();
  badChronology.candidateRuntimes[0].measurement_started_unix_ms = 500;
  badChronology.candidateRuntimes[0].measurement_finished_unix_ms = 900;
  const chronologicalResult = validateGpuRegression(badChronology);
  assert.equal(chronologicalResult.ok, false);
  assert.match(chronologicalResult.errors.join("\n"), /measurement chronology/u);

  const reusedTrace = validGateInput();
  reusedTrace.candidateReports[0].source = reusedTrace.baselineReports[0].source;
  const reusedTraceResult = validateGpuRegression(reusedTrace);
  assert.equal(reusedTraceResult.ok, false);
  assert.match(reusedTraceResult.errors.join("\n"), /four distinct trace sources/u);
});

test("binds every trace to the same run ID, exact runtime PID, sequence and frame window", () => {
  const input = validGateInput();
  const report = input.candidateReports[1];
  report.schema_version = 2;
  report.process = "godot";
  report.run_id = "wrong-run";
  report.pid = 9999;
  report.observed_frame_count = 359;
  report.dropped_warmup_frames = 59;
  report.requested_max_frames = 299;
  report.analyzed_frame_count = 299;
  report.analyzed_frames_contiguous = false;
  report.malformed_target_rows = 1;

  const result = validateGpuRegression(input);
  const errors = result.errors.join("\n");
  assert.equal(result.ok, false);
  assert.match(errors, /GPU report schema_version must equal 1/u);
  assert.match(errors, /process must equal Godot/u);
  assert.match(errors, /run_id does not match/u);
  assert.match(errors, /PID does not match/u);
  assert.match(errors, /observed_frame_count.*360/u);
  assert.match(errors, /dropped_warmup_frames.*60/u);
  assert.match(errors, /requested_max_frames.*300/u);
  assert.match(errors, /exactly 300 analyzed frames/u);
  assert.match(errors, /contiguous/u);
  assert.match(errors, /malformed_target_rows.*zero/u);
});

test("binds actual body asset, no-fallback shell, and all 14 idle animation facts", () => {
  const input = validGateInput();
  const identity = input.candidateRuntimes[0].runtime_identity;
  identity.asset_sha256 = "0".repeat(64);
  identity.asset_revision_label = "r6";
  identity.asset_resource_name = "V8.6-AuthoredSculpt-T-r6";
  identity.fallback_used = true;
  identity.shell_shares_body_mesh = false;
  identity.animation_catalog.pop();
  identity.animation_count = 13;
  identity.active_animation = "move";

  const result = validateGpuRegression(input);
  const errors = result.errors.join("\n");
  assert.equal(result.ok, false);
  assert.match(errors, /asset_sha256/u);
  assert.match(errors, /asset_revision_label/u);
  assert.match(errors, /asset_resource_name/u);
  assert.match(errors, /fallback_used.*false/u);
  assert.match(errors, /shell_shares_body_mesh.*true/u);
  assert.match(errors, /animation_catalog/u);
  assert.match(errors, /animation_count.*14/u);
  assert.match(errors, /active_animation.*idle/u);
});

test("binds evidence to the exact imported runtime mesh arrays and topology", async (t) => {
  const cases = [
    {
      name: "stale imported vertex data digest",
      mutate: (identity) => { identity.runtime_mesh_sha256 = "0".repeat(64); },
      error: /runtime_mesh_sha256/u,
    },
    {
      name: "changed imported vertex count",
      mutate: (identity) => { identity.runtime_mesh_vertex_count = 6001; },
      error: /runtime_mesh_vertex_count/u,
    },
    {
      name: "changed imported surface metadata",
      mutate: (identity) => { identity.runtime_mesh_surfaces[0].format = 0; },
      error: /runtime_mesh_surfaces/u,
    },
    {
      name: "runtime fingerprint failure",
      mutate: (identity) => { identity.runtime_mesh_error = "surface arrays unavailable"; },
      error: /runtime_mesh_error.*must be empty/u,
    },
  ];
  for (const testCase of cases) {
    await t.test(testCase.name, () => {
      const input = validGateInput();
      testCase.mutate(input.candidateRuntimes[0].runtime_identity);
      const result = validateGpuRegression(input);
      assert.equal(result.ok, false);
      assert.match(result.errors.join("\n"), testCase.error);
    });
  }
});

test("applies the 16.67 ms max ceiling to all A and B runs", () => {
  const input = validGateInput();
  input.baselineReports[1].gpu_frame_span_ms.max = 16.67;
  const result = validateGpuRegression(input);

  assert.equal(result.ok, false);
  assert.match(result.errors.join("\n"), /baseline\[1\].*below 16.67 ms/u);
});

test("marks noisy selector evidence inconclusive only beyond both 5% and 0.40 ms", () => {
  const withinAbsolute = validGateInput();
  withinAbsolute.baselineReports[0].gpu_frame_span_ms.mean = 7.0;
  withinAbsolute.baselineReports[1].gpu_frame_span_ms.mean = 7.4; // >5%, exactly 0.40 ms
  const accepted = validateGpuRegression(withinAbsolute);
  assert.equal(accepted.noise.baseline.valid, true);

  const noisy = validGateInput();
  noisy.candidateReports[0].gpu_frame_span_ms.mean = 7.0;
  noisy.candidateReports[1].gpu_frame_span_ms.mean = 7.6;
  const result = validateGpuRegression(noisy);
  assert.equal(result.ok, false);
  assert.equal(result.verdict, "INCONCLUSIVE");
  assert.match(result.errors.join("\n"), /candidate mean spread.*noise ceiling/u);

  const noisyP95 = validGateInput();
  noisyP95.candidateReports[0].gpu_frame_span_ms.p95 = 8.0;
  noisyP95.candidateReports[1].gpu_frame_span_ms.p95 = 8.6;
  const p95Result = validateGpuRegression(noisyP95);
  assert.equal(p95Result.ok, false);
  assert.equal(p95Result.verdict, "INCONCLUSIVE");
  assert.equal(p95Result.noise.candidate.mean_valid, true);
  assert.equal(p95Result.noise.candidate.p95_valid, false);
  assert.match(p95Result.errors.join("\n"), /candidate p95 spread.*noise ceiling/u);
});

test("fails when either aggregate relative or absolute mean and p95 ceiling is exceeded", () => {
  const input = validGateInput();
  for (const report of input.candidateReports) {
    report.gpu_frame_span_ms.mean = 8.0;
    report.gpu_frame_span_ms.p95 = 8.9;
  }
  const result = validateGpuRegression(input);

  assert.equal(result.ok, false);
  assert.equal(result.verdict, "FAIL");
  assert.match(result.errors.join("\n"), /mean regression .*10%/u);
  assert.match(result.errors.join("\n"), /p95 regression .*10%/u);
});

test("rejects missing pairs and unknown CLI options", () => {
  const missing = validGateInput();
  missing.candidateReports = [];
  missing.candidateRuntimes = [];
  assert.throws(() => validateGpuRegression(missing), /exactly two baseline and two candidate runs/u);
  assert.throws(
    () => parseGpuRegressionArgs(["--baseline-reports=a.json", "--wat=no"]),
    /unknown option/u,
  );
});

test("CLI accepts reports bound to unchanged real source artifacts", async (t) => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-gpu-gate-bound-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  const fixture = writeCliFixture(tempDir);
  const output = path.join(tempDir, "gpu-regression-gate.json");

  const { stdout } = await execFileAsync(process.execPath, [
    VALIDATOR,
    ...fixture.args,
    `--out=${output}`,
  ]);

  assert.match(stdout, /GPU_REGRESSION_GATE_PASS/u);
  assert.equal(JSON.parse(fs.readFileSync(output, "utf8")).verdict, "PASS");
});

test("CLI rejects synthetic reports without source-artifact binding", async (t) => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-gpu-gate-unbound-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  const fixture = writeCliFixture(tempDir, { bindSources: false });

  await assert.rejects(
    execFileAsync(process.execPath, [VALIDATOR, ...fixture.args]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /source_artifact/u);
      return true;
    },
  );
});

test("CLI verifies every source artifact realpath, size, hash, and existence", async (t) => {
  const realPathDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-gpu-gate-realpath-"));
  const sizeDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-gpu-gate-size-"));
  const changedDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-gpu-gate-changed-"));
  const missingDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-gpu-gate-missing-"));
  t.after(() => fs.rmSync(realPathDir, { recursive: true, force: true }));
  t.after(() => fs.rmSync(sizeDir, { recursive: true, force: true }));
  t.after(() => fs.rmSync(changedDir, { recursive: true, force: true }));
  t.after(() => fs.rmSync(missingDir, { recursive: true, force: true }));

  const wrongRealPath = writeCliFixture(realPathDir);
  const wrongRealPathReport = JSON.parse(
    fs.readFileSync(wrongRealPath.baselineReports[0], "utf8"),
  );
  wrongRealPathReport.source_artifact.real_path = path.join(realPathDir, "wrong-source.xml");
  fs.writeFileSync(
    wrongRealPath.baselineReports[0],
    `${JSON.stringify(wrongRealPathReport, null, 2)}\n`,
  );
  await assert.rejects(
    execFileAsync(process.execPath, [VALIDATOR, ...wrongRealPath.args]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /source artifact realpath mismatch/u);
      return true;
    },
  );

  const wrongSize = writeCliFixture(sizeDir);
  const wrongSizeReport = JSON.parse(fs.readFileSync(wrongSize.candidateReports[0], "utf8"));
  wrongSizeReport.source_artifact.size_bytes += 1;
  fs.writeFileSync(
    wrongSize.candidateReports[0],
    `${JSON.stringify(wrongSizeReport, null, 2)}\n`,
  );
  await assert.rejects(
    execFileAsync(process.execPath, [VALIDATOR, ...wrongSize.args]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /source artifact size mismatch/u);
      return true;
    },
  );

  const changed = writeCliFixture(changedDir);
  const bytes = fs.readFileSync(changed.sources.A1);
  bytes[0] ^= 0xff;
  fs.writeFileSync(changed.sources.A1, bytes);
  await assert.rejects(
    execFileAsync(process.execPath, [VALIDATOR, ...changed.args]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /source artifact SHA-256 mismatch/u);
      return true;
    },
  );

  const missing = writeCliFixture(missingDir);
  fs.unlinkSync(missing.sources.B2);
  await assert.rejects(
    execFileAsync(process.execPath, [VALIDATOR, ...missing.args]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /source artifact does not exist/u);
      return true;
    },
  );
});

test("CLI rejects output aliasing an input and refuses a pre-existing output", async (t) => {
  const aliasDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-gpu-gate-alias-"));
  const existingDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-gpu-gate-existing-"));
  t.after(() => fs.rmSync(aliasDir, { recursive: true, force: true }));
  t.after(() => fs.rmSync(existingDir, { recursive: true, force: true }));

  const aliasFixture = writeCliFixture(aliasDir);
  const aliasedInput = aliasFixture.baselineReports[0];
  const originalInput = fs.readFileSync(aliasedInput, "utf8");
  await assert.rejects(
    execFileAsync(process.execPath, [
      VALIDATOR,
      ...aliasFixture.args,
      `--out=${aliasedInput}`,
    ]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /output.*aliases.*input/u);
      return true;
    },
  );
  assert.equal(fs.readFileSync(aliasedInput, "utf8"), originalInput);

  const hardLinkAlias = path.join(aliasDir, "hard-linked-gate-output.json");
  fs.linkSync(aliasedInput, hardLinkAlias);
  await assert.rejects(
    execFileAsync(process.execPath, [
      VALIDATOR,
      ...aliasFixture.args,
      `--out=${hardLinkAlias}`,
    ]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /output.*aliases.*input/u);
      return true;
    },
  );
  assert.equal(fs.readFileSync(aliasedInput, "utf8"), originalInput);

  const existingFixture = writeCliFixture(existingDir);
  const output = path.join(existingDir, "gpu-regression-gate.json");
  fs.writeFileSync(output, "sentinel\n");
  await assert.rejects(
    execFileAsync(process.execPath, [
      VALIDATOR,
      ...existingFixture.args,
      `--out=${output}`,
    ]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /pre-existing output/u);
      return true;
    },
  );
  assert.equal(fs.readFileSync(output, "utf8"), "sentinel\n");
});
