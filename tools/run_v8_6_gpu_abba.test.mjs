import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import {
  ABBA_SEQUENCE,
  CAPTURE_HOLD_MS,
  CAPTURE_ENV_ALLOWLIST,
  DEFAULT_XCTRACE_PATH,
  DROP_FRAMES,
  GODOT_SHA256,
  GODOT_VERSION,
  GIT_DIFF_MAX_BUFFER_BYTES,
  INITIAL_MIN_FREE_BYTES,
  MAX_ANALYZED_FRAMES,
  PER_CAPTURE_MIN_FREE_BYTES,
  PRE_ANALYSIS_MIN_FREE_BYTES,
  TRACE_END_REASON,
  TRACE_RECORDED_MAX_SECONDS,
  TRACE_RECORDED_MIN_SECONDS,
  TRACE_TIME_LIMIT,
  assertAbbaOrder,
  assertAbbaPrefix,
  assertArtifactFingerprintUnchanged,
  assertTraceFitsCaptureHold,
  assertDiskHeadroom,
  assertGodotIdentityUnchanged,
  assertNewEvidenceRoot,
  buildAnalyzerCommand,
  buildCaptureEnv,
  buildCampaignContract,
  buildCampaignPlan,
  buildGodotCommand,
  buildGateCommand,
  buildXctraceAttachCommand,
  buildXctraceExportCommand,
  cleanupOwnedTempDirOnFailure,
  inspectGodotLog,
  inspectTraceToc,
  isDeniedEnvironmentName,
  isSafeRunId,
  gitSnapshot,
  parseRunnerArgs,
  readHostInfo,
  reserveEvidenceRoot,
  spawnTrackedCommand,
  terminateTrackedChild,
  validateAnalyzedReport,
  validateRuntimeComplete,
  validateRuntimeReady,
  verifyGodotIdentity,
  verifyFormalWorkspaceIdentity,
  verifyXcodeToolchainIdentity,
  waitForRuntimeReady,
  withWatchdog,
} from "./run_v8_6_gpu_abba.mjs";

const RUN_ID = "v86-test-run-20260904";
const ROOT = "/tmp/immune-v86-gpu-test-root";
const GODOT = "/Users/klaus_mac/Documents/Codex/work/godot-4.7.2/Godot.app/Contents/MacOS/Godot";
const PROJECT = "/repo/godot/immune";

async function waitForLog(file, pattern, timeoutMs = 2_000) {
  const started = Date.now();
  while (Date.now() - started <= timeoutMs) {
    if (fs.existsSync(file) && pattern.test(fs.readFileSync(file, "utf8"))) return;
    await new Promise((resolve) => setTimeout(resolve, 10));
  }
  throw new Error(`timed out waiting for ${pattern} in ${file}`);
}

test("locks the formal campaign to A1=v8_5, B1=v8_6, B2=v8_6, A2=v8_5", () => {
  assert.deepEqual(ABBA_SEQUENCE.map((entry) => `${entry.sequence}=${entry.look}`), [
    "A1=v8_5", "B1=v8_6", "B2=v8_6", "A2=v8_5",
  ]);
  assert.doesNotThrow(() => assertAbbaOrder(ABBA_SEQUENCE));
  assert.doesNotThrow(() => assertAbbaPrefix(ABBA_SEQUENCE.slice(0, 2)));
  assert.throws(() => assertAbbaPrefix(["A1", "B2"]), /prefix/u);
  assert.throws(() => assertAbbaOrder(["A1", "B1", "A2", "B2"]), /order/u);
});

test("locks the bounded trace, sample, hold, and staged disk contract", () => {
  const contract = buildCampaignContract();
  assert.equal(contract.frames, 4000);
  assert.equal(contract.capture_hold_ms, 35_000);
  assert.equal(TRACE_TIME_LIMIT, "8s");
  assert.equal(contract.trace_time_limit, "8s");
  assert.equal(contract.trace_recorded_min_seconds, 7.95);
  assert.equal(contract.trace_recorded_max_seconds, 12.0);
  assert.equal(contract.trace_end_reason, "Time limit reached");
  assert.equal(TRACE_RECORDED_MIN_SECONDS, 7.95);
  assert.equal(TRACE_RECORDED_MAX_SECONDS, 12.0);
  assert.equal(TRACE_END_REASON, "Time limit reached");
  assert.equal(contract.drop_frames, 60);
  assert.equal(contract.analyzed_frames, 300);
  assert.equal(contract.initial_min_free_bytes, 24 * 1024 ** 3);
  assert.equal(contract.per_capture_min_free_bytes, 14 * 1024 ** 3);
  assert.equal(contract.pre_analysis_min_free_bytes, 6 * 1024 ** 3);
  assert.equal(GIT_DIFF_MAX_BUFFER_BYTES, 16 * 1024 ** 2);
});

test("Git snapshot fingerprints a real diff larger than the default subprocess buffer", () => {
  const parent = fs.mkdtempSync(path.join(os.tmpdir(), "immune-v86-git-snapshot-"));
  const repo = path.join(parent, "repo");
  const hooks = path.join(parent, "empty-hooks");
  const globalAttributes = path.join(parent, "empty-global-attributes");

  const runGit = (args, maxBuffer = 1024 ** 2) => {
    const result = spawnSync("git", args, {
      cwd: repo,
      encoding: "utf8",
      maxBuffer,
      stdio: ["ignore", "pipe", "pipe"],
    });
    if (result.error) throw result.error;
    assert.equal(result.status, 0, String(result.stderr || ""));
    return String(result.stdout || "");
  };

  try {
    fs.mkdirSync(repo);
    fs.mkdirSync(hooks);
    fs.writeFileSync(globalAttributes, "");
    runGit(["init", "--quiet"]);
    runGit(["config", "user.name", "IMMUNE GPU Test"]);
    runGit(["config", "user.email", "gpu-test@example.invalid"]);
    runGit(["config", "commit.gpgSign", "false"]);
    runGit(["config", "core.hooksPath", hooks]);
    runGit(["config", "core.attributesFile", globalAttributes]);
    runGit(["config", "core.autocrlf", "false"]);

    fs.writeFileSync(path.join(repo, ".gitattributes"), "large-diff.txt -filter diff text eol=lf\n");
    const lines = Array.from({ length: 40_000 }, (_, index) => String(index).padStart(6, "0"));
    fs.writeFileSync(
      path.join(repo, "large-diff.txt"),
      `${lines.map((index) => `before-${index}-payload`).join("\n")}\n`,
    );
    runGit(["add", ".gitattributes", "large-diff.txt"]);
    runGit(["commit", "--quiet", "-m", "large diff fixture"]);
    fs.writeFileSync(
      path.join(repo, "large-diff.txt"),
      `${lines.map((index) => `after-${index}-payload`).join("\n")}\n`,
    );

    const patch = runGit(["diff", "--no-ext-diff", "--binary"], 32 * 1024 ** 2);
    assert.ok(Buffer.byteLength(patch, "utf8") > 1024 ** 2);
    const snapshot = gitSnapshot({ cwd: repo });
    assert.equal(snapshot.unstaged_sha256, createHash("sha256").update(patch).digest("hex"));
    assert.equal(snapshot.staged_sha256, createHash("sha256").update("").digest("hex"));
    assert.match(snapshot.status, /^ M large-diff\.txt$/mu);
    assert.match(snapshot.fingerprint, /^[a-f0-9]{64}$/u);
  } finally {
    fs.rmSync(parent, { recursive: true, force: false });
  }
});

test("parses required explicit paths and rejects unsafe run IDs", () => {
  const parsed = parseRunnerArgs([
    `--godot=${GODOT}`,
    `--evidence-root=${ROOT}`,
    `--run-id=${RUN_ID}`,
    "--ready-timeout-ms=1234",
    "--plan-only",
  ]);
  assert.equal(parsed.godot, GODOT);
  assert.equal(parsed.evidenceRoot, ROOT);
  assert.equal(parsed.timeouts.ready, 1234);
  assert.equal(parsed.planOnly, true);
  assert.equal(isSafeRunId(RUN_ID), true);
  assert.equal(isSafeRunId("../overwrite"), false);
  assert.throws(() => parseRunnerArgs([`--evidence-root=${ROOT}`, `--run-id=${RUN_ID}`]), /--godot/u);
  assert.throws(() => parseRunnerArgs([`--godot=${GODOT}`, `--evidence-root=${ROOT}`, "--run-id=short"]), /safe/u);
});

test("evidence-root guard permits only an OS-temp leaf with a verified canonical target", () => {
  const parent = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "immune-v86-path-")));
  const allowed = path.join(parent, "allowed");
  const outsideAllowed = path.join(parent, "outside-allowed");
  fs.mkdirSync(allowed);
  fs.mkdirSync(outsideAllowed);
  const fresh = path.join(allowed, "new-run");
  const repo = path.join(parent, "repo");
  const project = path.join(repo, "godot", "immune");
  fs.mkdirSync(project, { recursive: true });
  const guardOptions = { repoRoot: repo, projectRoot: project, cwd: "/", temporaryRoot: allowed };
  assert.equal(assertNewEvidenceRoot(fresh, guardOptions), fresh);
  assert.throws(
    () => assertNewEvidenceRoot(path.join(outsideAllowed, "formal"), guardOptions),
    /OS-reported temporary directory/u,
  );
  fs.mkdirSync(path.join(parent, "existing"));
  assert.throws(() => assertNewEvidenceRoot(path.join(parent, "existing"), guardOptions), /already exist/u);
  fs.mkdirSync(path.join(repo, "outputs"), { recursive: true });
  assert.throws(() => assertNewEvidenceRoot(path.join(repo, "outputs", "formal"), { ...guardOptions, temporaryRoot: parent }), /outside the source repository/u);
  fs.mkdirSync(path.join(project, "evidence"), { recursive: true });
  assert.throws(() => assertNewEvidenceRoot(path.join(project, "evidence", "formal"), { ...guardOptions, temporaryRoot: parent }), /outside the measured Godot project/u);
  const realParent = path.join(parent, "real-parent");
  const linkedParent = path.join(parent, "linked-parent");
  fs.mkdirSync(realParent);
  fs.symlinkSync(realParent, linkedParent);
  assert.throws(() => assertNewEvidenceRoot(path.join(linkedParent, "formal"), { ...guardOptions, temporaryRoot: parent }), /symbolic link|aliased ancestor/u);
  fs.mkdirSync(path.join(realParent, "nested"));
  assert.throws(() => assertNewEvidenceRoot(path.join(linkedParent, "nested", "formal"), { ...guardOptions, temporaryRoot: parent }), /aliased ancestor/u);
  fs.rmSync(parent, { recursive: true, force: false });
});

test("evidence-root reservation accepts only the OS-provided temp alias canonical target", () => {
  const parent = fs.mkdtempSync(path.join(os.tmpdir(), "immune-v86-reserve-"));
  const repo = path.join(parent, "repo");
  const project = path.join(repo, "godot", "immune");
  fs.mkdirSync(project, { recursive: true });
  const fresh = path.join(parent, "formal-run");
  assert.equal(reserveEvidenceRoot(fresh, { repoRoot: repo, projectRoot: project, cwd: "/" }), fresh);
  assert.equal(fs.statSync(fresh).isDirectory(), true);
  assert.equal(
    fs.realpathSync(fresh),
    path.join(fs.realpathSync(os.tmpdir()), path.relative(os.tmpdir(), fresh)),
  );
  fs.rmSync(parent, { recursive: true, force: false });
});

test("capture environment is allowlisted and strips credential-like names", () => {
  const env = buildCaptureEnv({
    look: "v8_6",
    tmpDir: "/tmp/immune-v86-isolated",
    baseEnv: {
      HOME: "/Users/test",
      PATH: "/usr/bin",
      LANG: "C.UTF-8",
      MESHY_API_KEY: "must-not-escape",
      AWS_SECRET_ACCESS_KEY: "must-not-escape",
      ANTHROPIC_AUTH_TOKEN: "must-not-escape",
      USER: "test",
    },
  });
  assert.equal(env.IMMUNE_GEL_LOOK, "v8_6");
  assert.equal(env.TMPDIR, "/tmp/immune-v86-isolated");
  assert.equal(env.MESHY_API_KEY, undefined);
  assert.equal(env.AWS_SECRET_ACCESS_KEY, undefined);
  assert.equal(env.ANTHROPIC_AUTH_TOKEN, undefined);
  for (const key of Object.keys(env)) {
    assert.equal(CAPTURE_ENV_ALLOWLIST.includes(key) || ["TMPDIR", "TMP", "TEMP", "IMMUNE_GEL_LOOK"].includes(key), true);
    assert.equal(isDeniedEnvironmentName(key), false);
  }
});

test("builds the exact headed Godot and xctrace command plans", () => {
  const command = buildGodotCommand({
    godot: GODOT,
    project: PROJECT,
    runRoot: `${ROOT}/A1`,
    tmpDir: "/tmp/immune-v86-isolated",
    qaSave: "/tmp/immune-v86-isolated/qa-save.json",
    runtime: `${ROOT}/A1/runtime.json`,
    runId: RUN_ID,
    sequence: "A1",
    look: "v8_5",
  });
  assert.equal(command.args.includes("--headless"), false);
  assert.deepEqual(command.args.slice(0, 10), [
    "--path", PROJECT,
    "--resolution", "1920x1080",
    "--rendering-method", "forward_plus",
    "--rendering-driver", "metal",
    "res://tools/gel_perf.tscn", "--",
  ]);
  assert.deepEqual(command.args.slice(-6), [
    "--sync=false",
    `--out=${ROOT}/A1/runtime.json`,
    "--save-path=/tmp/immune-v86-isolated/qa-save.json",
    `--run-id=${RUN_ID}`,
    "--sequence=A1",
    `--capture-hold-ms=${CAPTURE_HOLD_MS}`,
  ]);
  assert.equal(command.args.includes("--source=character"), true);
  assert.equal(command.env.TMPDIR, "/tmp/immune-v86-isolated");
  assert.equal(command.env.IMMUNE_GEL_LOOK, "v8_5");

  const trace = buildXctraceAttachCommand({ xctrace: DEFAULT_XCTRACE_PATH, trace: `${ROOT}/A1/metal.trace`, pid: 1234 });
  assert.deepEqual(trace.args, [
    "record", "--template", "Metal System Trace", "--time-limit", "8s",
    "--no-prompt", "--output", `${ROOT}/A1/metal.trace`, "--attach", "1234",
  ]);
  const toc = buildXctraceExportCommand({ xctrace: DEFAULT_XCTRACE_PATH, trace: `${ROOT}/A1/metal.trace`, output: `${ROOT}/A1/metal-toc.xml`, mode: "toc" });
  assert.deepEqual(toc.args.slice(0, 4), ["export", "--input", `${ROOT}/A1/metal.trace`, "--toc"]);
  const intervals = buildXctraceExportCommand({ xctrace: DEFAULT_XCTRACE_PATH, trace: `${ROOT}/A1/metal.trace`, output: `${ROOT}/A1/intervals.xml`, mode: "intervals" });
  assert.match(intervals.args.join(" "), /metal-gpu-intervals/u);
});

test("campaign plan and aggregate command preserve grouped validator order", () => {
  const plan = buildCampaignPlan({ godot: GODOT, project: PROJECT, root: ROOT, runId: RUN_ID });
  assert.deepEqual(plan.runs.map((entry) => entry.sequence), ["A1", "B1", "B2", "A2"]);
  assert.deepEqual(plan.gate.args.slice(1, 5).map((arg) => arg.split("=")[0]), [
    "--baseline-reports", "--candidate-reports", "--baseline-runtimes", "--candidate-runtimes",
  ]);
  assert.match(plan.gate.args[1], /A1\/gpu-report\.json,[^ ]*A2\/gpu-report\.json/u);
  assert.match(plan.gate.args[2], /B1\/gpu-report\.json,[^ ]*B2\/gpu-report\.json/u);
  assert.equal(plan.gate.args.at(-1), `--out=${ROOT}/gpu-regression-gate.json`);
  const analyzer = buildAnalyzerCommand({ node: "/usr/local/bin/node", analyzer: "/repo/tools/analyze_metal_gpu_trace.mjs", input: `${ROOT}/A1/intervals.xml`, pid: 1234, runId: RUN_ID, sequence: "A1", output: `${ROOT}/A1/report.json` });
  assert.equal(analyzer.args.includes(`--pid=1234`), true);
  assert.equal(analyzer.args.includes(`--drop-frames=${DROP_FRAMES}`), true);
  assert.equal(analyzer.args.includes(`--max-frames=${MAX_ANALYZED_FRAMES}`), true);
  const gate = buildGateCommand({ node: "/usr/local/bin/node", validator: "/repo/tools/validate_gpu_regression.mjs", root: ROOT, output: `${ROOT}/gate.json` });
  assert.match(gate.args.join(" "), /baseline-reports=.*A1.*A2/u);
});

test("Godot identity requires the pinned realpath, official version, and SHA", () => {
  const expected = verifyGodotIdentity({
    godot: GODOT,
    expectedPath: GODOT,
    versionOutput: GODOT_VERSION,
    expectedSha256: GODOT_SHA256,
    realpath: () => GODOT,
    hash: () => GODOT_SHA256,
  });
  assert.deepEqual(expected, {
    requested_path: GODOT,
    realpath: GODOT,
    version: GODOT_VERSION,
    sha256: GODOT_SHA256,
  });
  assert.deepEqual(assertGodotIdentityUnchanged(expected, {
    versionOutput: GODOT_VERSION,
    realpath: () => GODOT,
    hash: () => GODOT_SHA256,
  }), expected);
  assert.throws(() => assertGodotIdentityUnchanged(expected, {
    versionOutput: GODOT_VERSION,
    realpath: () => GODOT,
    hash: () => "0".repeat(64),
  }), /SHA-256 drifted|identity changed/u);
  assert.throws(() => verifyGodotIdentity({ godot: GODOT, expectedPath: "/wrong/Godot", versionOutput: GODOT_VERSION, expectedSha256: GODOT_SHA256, realpath: () => GODOT, hash: () => GODOT_SHA256 }), /pinned/u);
  assert.throws(() => verifyGodotIdentity({ godot: GODOT, expectedPath: GODOT, versionOutput: "4.6.1", expectedSha256: GODOT_SHA256, realpath: () => GODOT, hash: () => GODOT_SHA256 }), /version/u);
});

test("formal workspace binds the measured project to this runner repository", () => {
  const parent = fs.mkdtempSync(path.join(os.tmpdir(), "immune-v86-workspace-"));
  const expectedRepo = path.join(parent, "repo");
  const expectedProject = path.join(expectedRepo, "godot", "immune");
  const alternateRepo = path.join(parent, "alternate-repo");
  const alternateProject = path.join(alternateRepo, "godot", "immune");
  fs.mkdirSync(expectedProject, { recursive: true });
  fs.mkdirSync(alternateProject, { recursive: true });
  const identity = verifyFormalWorkspaceIdentity({
    repo: expectedRepo,
    project: expectedProject,
    expectedRepo,
  });
  assert.equal(identity.repo.realpath, fs.realpathSync(expectedRepo));
  assert.equal(identity.project.realpath, fs.realpathSync(expectedProject));
  assert.throws(() => verifyFormalWorkspaceIdentity({
    repo: alternateRepo,
    project: alternateProject,
    expectedRepo,
  }), /runner repository/u);
  assert.throws(() => verifyFormalWorkspaceIdentity({
    repo: expectedRepo,
    project: alternateProject,
    expectedRepo,
  }), /Godot project/u);
  fs.rmSync(parent, { recursive: true, force: false });
});

test("runtime PID, selector, and completion status fail closed", () => {
  const ready = { run_id: RUN_ID, sequence: "B1", gel_look: "v8_6", capture_hold_status: "ready", process_pid: 1234 };
  assert.doesNotThrow(() => validateRuntimeReady(ready, { runId: RUN_ID, sequence: "B1", look: "v8_6", pid: 1234 }));
  assert.throws(() => validateRuntimeReady({ ...ready, process_pid: 9999 }, { runId: RUN_ID, sequence: "B1", look: "v8_6", pid: 1234 }), /PID/u);
  assert.throws(() => validateRuntimeReady({ ...ready, gel_look: "v8_5" }, { runId: RUN_ID, sequence: "B1", look: "v8_6", pid: 1234 }), /look/u);
  assert.throws(() => validateRuntimeComplete(ready, { runId: RUN_ID, sequence: "B1", look: "v8_6", pid: 1234 }), /complete/u);
  assert.doesNotThrow(() => validateRuntimeComplete({ ...ready, capture_hold_status: "complete", capture_hold_actual_ms: CAPTURE_HOLD_MS, capture_hold_rendered_frames: 100 }, { runId: RUN_ID, sequence: "B1", look: "v8_6", pid: 1234 }));
});

test("each analyzed run fails immediately unless its exact 300-frame window is complete", () => {
  const source = `${ROOT}/A1/metal-gpu-intervals.xml`;
  const valid = {
    schema_version: 1,
    source,
    process: "Godot",
    pid: 1234,
    run_id: RUN_ID,
    sequence: "A1",
    sequence_index: 1,
    target_event_count: 600,
    malformed_target_rows: 0,
    nested_target_rows: 300,
    unframed_target_rows: 0,
    unframed_target_rows_overlapping_analyzed_window: 0,
    observed_frame_count: 360,
    dropped_warmup_frames: 60,
    requested_max_frames: 300,
    analyzed_frame_count: 300,
    analyzed_frames_contiguous: true,
    first_analyzed_frame: 61,
    last_analyzed_frame: 360,
    gpu_frame_span_ms: { mean: 7.1, p50: 7.0, p95: 8.2, max: 11.0 },
    channel_event_counts: { Fragment: 300 },
  };
  const options = { runId: RUN_ID, sequence: "A1", pid: 1234, source };
  assert.equal(validateAnalyzedReport(valid, options), valid);
  assert.throws(() => validateAnalyzedReport({ ...valid, observed_frame_count: 359 }, options), /at least 360/u);
  assert.throws(() => validateAnalyzedReport({ ...valid, analyzed_frame_count: 299 }, options), /exactly 300/u);
  assert.throws(() => validateAnalyzedReport({ ...valid, analyzed_frames_contiguous: false }, options), /not contiguous/u);
  assert.throws(() => validateAnalyzedReport({ ...valid, last_analyzed_frame: 361 }, options), /span.*300/u);
  assert.throws(() => validateAnalyzedReport({ ...valid, malformed_target_rows: 1 }, options), /malformed/u);
  assert.equal(validateAnalyzedReport({
    ...valid,
    target_event_count: 607,
    unframed_target_rows: 7,
  }, options).unframed_target_rows, 7);
  assert.throws(() => validateAnalyzedReport({
    ...valid,
    target_event_count: 607,
    unframed_target_rows: 7,
    unframed_target_rows_overlapping_analyzed_window: 1,
  }, options), /overlapping/u);
  assert.throws(() => validateAnalyzedReport({
    ...valid,
    target_event_count: 601,
  }, options), /accounting/u);
});

test("authoritative TOC recording window must fit inside the final Godot hold", () => {
  const runtime = {
    capture_hold_started_unix_ms: 1_000,
    capture_hold_finished_unix_ms: 36_100,
  };
  assert.deepEqual(assertTraceFitsCaptureHold(runtime, { startUnixMs: 2_000, endUnixMs: 11_746 }), {
    hold_started_unix_ms: 1_000,
    hold_finished_unix_ms: 36_100,
    trace_started_unix_ms: 2_000,
    trace_finished_unix_ms: 11_746,
    trace_wall_duration_ms: 9_746,
    fits: true,
  });
  assert.throws(() => assertTraceFitsCaptureHold(runtime, { startUnixMs: 900, endUnixMs: 10_646 }), /does not fit/u);
  // Regression: the xctrace process can spawn inside the hold while the
  // authoritative recording starts later and finishes outside it.
  const processSpawnUnixMs = 2_000;
  assert.equal(processSpawnUnixMs >= runtime.capture_hold_started_unix_ms, true);
  assert.throws(() => assertTraceFitsCaptureHold(runtime, { startUnixMs: 27_000, endUnixMs: 36_746 }), /does not fit/u);
});

function traceTocFixture({
  endTime = "03:00:09.745658",
  duration = "9.745658",
  endReason = TRACE_END_REASON,
  timeLimitMarkup = "<time-limit>8 seconds</time-limit>",
  pid = 1234,
  schema = "metal-gpu-intervals",
  environmentKey = "TMPDIR",
} = {}) {
  return `<?xml version="1.0"?><trace-toc><run number="1"><info><target><process type="attached" name="Godot" pid="${pid}"/><environment><item key="HOME" value="/Users/test"/><item key="${environmentKey}" value="/tmp/isolated"/></environment></target><summary><start-date>2026-09-04T03:00:00.000000+08:00</start-date><end-date>2026-09-04T${endTime}+08:00</end-date><duration>${duration}</duration><end-reason>${endReason}</end-reason>${timeLimitMarkup}</summary></info><data><table schema="${schema}" target-pid="SINGLE"/></data></run></trace-toc>`;
}

test("TOC accepts the observed recorder envelope while preserving authoritative timing", () => {
  const valid = traceTocFixture();
  const inspection = inspectTraceToc(valid, { pid: 1234 });
  assert.equal(inspection.ok, true);
  assert.equal(inspection.durationSeconds, 9.745658);
  assert.equal(inspection.endUnixMs - inspection.startUnixMs, 9_745);
  assert.equal(Math.abs(inspection.wallDurationMs - inspection.durationSeconds * 1000) <= 5, true);
  assert.equal(inspection.requestedTimeLimit, true);
  assert.equal(inspection.boundedRecordingEnvelope, true);
  assert.deepEqual(inspection.environmentKeys, ["HOME", "TMPDIR"]);
  assert.equal(inspection.forbiddenEnvironmentKeys.length, 0);
});

test("TOC accepts duplicate exact process rows emitted for the attached Godot PID", () => {
  const duplicatedProcess = traceTocFixture().replace(
    '<process type="attached" name="Godot" pid="1234"/>',
    '<process type="attached" name="Godot" pid="1234"/><process name="Godot" pid="1234"/>',
  );
  const inspection = inspectTraceToc(duplicatedProcess, { pid: 1234 });
  assert.equal(inspection.ok, true);
  assert.equal(inspection.exactProcessCount, 2);
});

test("TOC recorder envelope accepts inclusive boundaries and rejects values just outside", () => {
  assert.equal(inspectTraceToc(traceTocFixture({
    endTime: "03:00:07.950000",
    duration: "7.95",
  }), { pid: 1234 }).boundedRecordingEnvelope, true);
  assert.equal(inspectTraceToc(traceTocFixture({
    endTime: "03:00:12.000000",
    duration: "12.0",
  }), { pid: 1234 }).boundedRecordingEnvelope, true);
  assert.throws(() => inspectTraceToc(traceTocFixture({
    endTime: "03:00:07.949000",
    duration: "7.949",
  }), { pid: 1234 }), /recording envelope/u);
  assert.throws(() => inspectTraceToc(traceTocFixture({
    endTime: "03:00:12.001000",
    duration: "12.001",
  }), { pid: 1234 }), /recording envelope/u);
});

test("TOC requires exactly one exact eight-second requested time limit", () => {
  assert.throws(() => inspectTraceToc(traceTocFixture({
    timeLimitMarkup: "<time-limit>7 seconds</time-limit>",
  }), { pid: 1234 }), /exact requested 8-second limit/u);
  assert.throws(() => inspectTraceToc(traceTocFixture({
    timeLimitMarkup: "",
  }), { pid: 1234 }), /exactly one time-limit/u);
  assert.throws(() => inspectTraceToc(traceTocFixture({
    timeLimitMarkup: "<time-limit>8 seconds</time-limit><time-limit>8 seconds</time-limit>",
  }), { pid: 1234 }), /exactly one time-limit/u);
});

test("TOC requires the exact time-limit end reason", () => {
  for (const endReason of [
    "time limit reached",
    "Time limit reached.",
    "Time limit reached after delay",
    "Target app exited",
    "User stopped recording",
  ]) {
    assert.throws(() => inspectTraceToc(traceTocFixture({ endReason }), { pid: 1234 }), /Time limit reached/u);
  }
});

test("TOC still rejects timing disagreement, the wrong PID or schema, and unsafe environment", () => {
  const valid = traceTocFixture();
  assert.throws(() => inspectTraceToc(valid.replace("<start-date>", "<start-date>bad</start-date><start-date>"), { pid: 1234 }), /exactly one start-date/u);
  assert.throws(() => inspectTraceToc(valid.replace("+08:00</start-date>", "</start-date>"), { pid: 1234 }), /timezone-qualified/u);
  assert.throws(() => inspectTraceToc(valid.replace("03:00:09.745658", "03:00:07.000000"), { pid: 1234 }), /does not agree/u);
  assert.throws(() => inspectTraceToc(valid.replace("03:00:09.745658", "03:00:00.000000"), { pid: 1234 }), /timestamps are invalid/u);
  assert.throws(() => inspectTraceToc(valid.replace(/<start-date>[^<]+<\/start-date>/u, ""), { pid: 1234 }), /exactly one start-date/u);
  assert.throws(() => inspectTraceToc(valid.replace("<duration>9.745658", "<duration>3.041"), { pid: 1234 }), /does not agree/u);
  assert.throws(() => inspectTraceToc(traceTocFixture({ environmentKey: "MESHY_API_KEY" }), { pid: 1234 }), /forbidden environment/u);
  assert.throws(() => inspectTraceToc(traceTocFixture({ pid: 9999 }), { pid: 1234 }), /PID 1234/u);
  assert.throws(() => inspectTraceToc(traceTocFixture({ schema: "other-schema" }), { pid: 1234 }), /metal-gpu-intervals schema/u);
});

test("formal host identity requires a concrete GPU", () => {
  const run = (command, args) => {
    if (command.endsWith("sw_vers") && args[0] === "-productVersion") return "26.6.2\n";
    if (command.endsWith("sw_vers") && args[0] === "-buildVersion") return "25G83\n";
    if (command.endsWith("system_profiler")) {
      return JSON.stringify({ SPDisplaysDataType: [{ _name: "Apple M4 Pro", sppci_model: "Apple M4 Pro" }] });
    }
    throw new Error("unexpected command");
  };
  assert.equal(readHostInfo({ run, platform: "darwin", arch: "arm64" }).gpu, "Apple M4 Pro");
  assert.throws(() => readHostInfo({
    run: (command, args) => command.endsWith("sw_vers")
      ? (args[0] === "-productVersion" ? "26.6.2" : "25G83")
      : JSON.stringify({ SPDisplaysDataType: [] }),
    platform: "darwin",
    arch: "arm64",
  }), /host identity gpu is unavailable/u);
});

test("Xcode provenance pins selected developer dir, xctrace binary, hashes, and build", () => {
  const parent = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "immune-v86-xcode-")));
  const developer = path.join(parent, "Xcode.app", "Contents", "Developer");
  const xcrun = path.join(parent, "xcrun");
  const xctrace = path.join(developer, "usr", "bin", "xctrace");
  const xcodebuild = path.join(developer, "usr", "bin", "xcodebuild");
  fs.mkdirSync(path.dirname(xctrace), { recursive: true });
  for (const executable of [xcrun, xctrace, xcodebuild]) {
    fs.writeFileSync(executable, "fixture");
    fs.chmodSync(executable, 0o755);
  }
  const run = (command, args) => {
    if (command === "/usr/bin/xcode-select") return `${developer}\n`;
    if (command === xcrun && args.join(" ") === "--find xctrace") return `${xctrace}\n`;
    if (command === xcrun && args.join(" ") === "--find xcodebuild") return `${xcodebuild}\n`;
    if (command === xctrace) return "xctrace version 16.0 (17F113)\n";
    if (command === xcodebuild) return "Xcode 26.6\nBuild version 17F113\n";
    throw new Error(`unexpected command: ${command} ${args.join(" ")}`);
  };
  const identity = verifyXcodeToolchainIdentity({ xcrun, run, hash: (file) => `sha256:${path.basename(file)}` });
  assert.equal(identity.developer_dir, developer);
  assert.equal(identity.xctrace.realpath, xctrace);
  assert.equal(identity.xctrace.build, "17F113");
  assert.equal(identity.xcodebuild.build, "17F113");
  assert.match(identity.xctrace.sha256, /^sha256:/u);
  assert.throws(() => verifyXcodeToolchainIdentity({
    xcrun,
    run: (command, args) => command === xcodebuild
      ? "Xcode 26.6\nBuild version DIFFERENT\n"
      : run(command, args),
    hash: () => "sha",
  }), /build mismatch/u);
  fs.rmSync(parent, { recursive: true, force: false });
});

test("Godot diagnostics fail closed even when the process exits successfully", () => {
  assert.deepEqual(inspectGodotLog("Godot Engine v4.7.2\nFRAME_READY\n"), {
    ok: true,
    diagnostic: null,
  });
  for (const diagnostic of ["SCRIPT ERROR: bad shader", "Parse Error: bad scene", "Compile Error: bad shader", "ERROR: renderer failure"]) {
    assert.throws(() => inspectGodotLog(`status=0\n${diagnostic}\n`), /failure diagnostic/u);
  }
});

test("runtime-ready polling and watchdogs are bounded without real capture", async () => {
  let reads = 0;
  const runtime = await waitForRuntimeReady({
    file: "/unused/runtime.json",
    runId: RUN_ID,
    sequence: "A1",
    look: "v8_5",
    pid: 4321,
    timeoutMs: 100,
    pollMs: 1,
    isAlive: () => true,
    readJson: () => {
      reads += 1;
      if (reads < 2) throw new Error("not ready");
      return { run_id: RUN_ID, sequence: "A1", gel_look: "v8_5", capture_hold_status: "ready", process_pid: 4321 };
    },
  });
  assert.equal(runtime.process_pid, 4321);
  let timeoutCleanupFinished = false;
  await assert.rejects(withWatchdog(new Promise(() => {}), {
    timeoutMs: 5,
    label: "mock operation",
    onTimeout: async () => {
      await new Promise((resolve) => setTimeout(resolve, 5));
      timeoutCleanupFinished = true;
    },
  }), /watchdog expired/u);
  assert.equal(timeoutCleanupFinished, true);
});

test("owned child termination awaits TERM and escalates an uncooperative child to KILL", async () => {
  const parent = fs.mkdtempSync(path.join(os.tmpdir(), "immune-v86-termination-"));
  const cooperativeLog = path.join(parent, "cooperative.log");
  const stubbornLog = path.join(parent, "stubborn.log");
  const cooperative = spawnTrackedCommand({
    command: process.execPath,
    args: ["-e", "console.log('READY'); setInterval(() => {}, 1000)"],
    cwd: parent,
    env: process.env,
    log: cooperativeLog,
  });
  const stubborn = spawnTrackedCommand({
    command: process.execPath,
    args: ["-e", "process.on('SIGTERM', () => {}); console.log('READY'); setInterval(() => {}, 1000)"],
    cwd: parent,
    env: process.env,
    log: stubbornLog,
  });
  try {
    await Promise.all([cooperative.startup, stubborn.startup]);
    await Promise.all([
      waitForLog(cooperativeLog, /READY/u),
      waitForLog(stubbornLog, /READY/u),
    ]);
    const cooperativeResult = await terminateTrackedChild(cooperative, {
      label: "cooperative fixture",
      graceMs: 1_000,
      killWaitMs: 1_000,
    });
    assert.equal(cooperativeResult.phase, "sigterm");
    assert.equal(cooperative.isDone(), true);
    assert.equal(cooperativeResult.result.signal, "SIGTERM");

    const stubbornResult = await terminateTrackedChild(stubborn, {
      label: "stubborn fixture",
      graceMs: 30,
      killWaitMs: 1_000,
    });
    assert.equal(stubbornResult.phase, "sigkill");
    assert.equal(stubborn.isDone(), true);
    assert.equal(stubbornResult.result.signal, "SIGKILL");
  } finally {
    for (const fixture of [cooperative, stubborn]) {
      if (!fixture.isDone()) {
        fixture.terminate("SIGKILL");
        await fixture.completion.catch(() => {});
      }
    }
    fs.rmSync(parent, { recursive: true, force: false });
  }
});

test("a real child log-write failure is tracked and terminates the exact owned process", async () => {
  const parent = fs.mkdtempSync(path.join(os.tmpdir(), "immune-v86-log-failure-"));
  const log = path.join(parent, "child.log");
  let writeAttempts = 0;
  const injectedError = new Error("injected command log ENOSPC");
  injectedError.code = "ENOSPC";
  const handle = spawnTrackedCommand({
    command: process.execPath,
    args: ["-e", "console.log('TRIGGER_LOG_WRITE'); setInterval(() => {}, 1000)"],
    cwd: parent,
    env: process.env,
    log,
    appendFileFn: () => {
      writeAttempts += 1;
      throw injectedError;
    },
  });
  try {
    await handle.startup;
    const closed = await withWatchdog(handle.completion, {
      timeoutMs: 3_000,
      label: "injected log-write failure child",
      onTimeout: () => terminateTrackedChild(handle, {
        label: "injected log-write failure child",
        graceMs: 250,
        killWaitMs: 1_000,
      }),
    });
    assert.equal(writeAttempts, 1);
    assert.equal(handle.isDone(), true);
    assert.equal(handle.isAlive(), false);
    assert.equal(closed.pid, handle.pid);
    assert.equal(closed.status, null);
    assert.equal(closed.signal, "SIGTERM");
    assert.equal(closed.log_write_error, injectedError.message);
    assert.equal(closed.log_write_error_code, "ENOSPC");
    assert.equal(closed.log_termination_error, null);
  } finally {
    if (!handle.isDone()) {
      handle.terminate("SIGKILL");
      await handle.completion.catch(() => {});
    }
    fs.rmSync(parent, { recursive: true, force: false });
  }
});

test("spawn errors are observed but completion waits for the child close event", async () => {
  const parent = fs.mkdtempSync(path.join(os.tmpdir(), "immune-v86-spawn-error-"));
  const handle = spawnTrackedCommand({
    command: path.join(parent, "does-not-exist"),
    args: [],
    cwd: parent,
    env: process.env,
    log: path.join(parent, "spawn-error.log"),
  });
  await assert.rejects(handle.startup, /ENOENT|spawn/u);
  const closed = await withWatchdog(handle.completion, {
    timeoutMs: 2_000,
    label: "spawn-error close",
  });
  assert.equal(handle.isDone(), true);
  assert.equal(handle.pid, null);
  assert.match(closed.spawn_error, /ENOENT|spawn/u);
  fs.rmSync(parent, { recursive: true, force: false });
});

test("failure cleanup removes only a correctly marked runner-owned temp directory", () => {
  const owned = fs.mkdtempSync(path.join(os.tmpdir(), `${RUN_ID}-A1-raw-tmp-`));
  fs.writeFileSync(path.join(owned, ".runner-owned"), `${JSON.stringify({
    runId: RUN_ID,
    sequence: "A1",
    role: "raw",
  })}\n`);
  fs.writeFileSync(path.join(owned, "working-data"), "fixture");
  const removed = cleanupOwnedTempDirOnFailure(owned, RUN_ID, "A1", "raw");
  assert.equal(removed.removed, true);
  assert.equal(fs.existsSync(owned), false);

  const foreign = fs.mkdtempSync(path.join(os.tmpdir(), `${RUN_ID}-A1-raw-tmp-`));
  fs.writeFileSync(path.join(foreign, ".runner-owned"), `${JSON.stringify({
    runId: "different-run-id",
    sequence: "A1",
    role: "raw",
  })}\n`);
  const refused = cleanupOwnedTempDirOnFailure(foreign, RUN_ID, "A1", "raw");
  assert.equal(refused.removed, false);
  assert.match(refused.error, /ownership mismatch/u);
  assert.equal(fs.existsSync(foreign), true);
  fs.rmSync(foreign, { recursive: true, force: false });
});

test("disk headroom guard uses the injected statfs result", () => {
  const parent = fs.mkdtempSync(path.join(os.tmpdir(), "immune-v86-disk-"));
  const target = path.join(parent, "future");
  assert.equal(INITIAL_MIN_FREE_BYTES, 24 * 1024 ** 3);
  assert.equal(PER_CAPTURE_MIN_FREE_BYTES, 14 * 1024 ** 3);
  assert.equal(PRE_ANALYSIS_MIN_FREE_BYTES, 6 * 1024 ** 3);
  assert.equal(
    assertDiskHeadroom(target, undefined, () => INITIAL_MIN_FREE_BYTES).availableBytes,
    INITIAL_MIN_FREE_BYTES,
  );
  assert.throws(
    () => assertDiskHeadroom(target, undefined, () => INITIAL_MIN_FREE_BYTES - 1),
    /insufficient disk/u,
  );
  assert.equal(
    assertDiskHeadroom(target, PER_CAPTURE_MIN_FREE_BYTES, () => PER_CAPTURE_MIN_FREE_BYTES).availableBytes,
    PER_CAPTURE_MIN_FREE_BYTES,
  );
  assert.throws(
    () => assertDiskHeadroom(target, PER_CAPTURE_MIN_FREE_BYTES, () => PER_CAPTURE_MIN_FREE_BYTES - 1),
    /insufficient disk/u,
  );
  assert.equal(assertDiskHeadroom(target, 20, () => 21).availableBytes, 21);
  assert.throws(() => assertDiskHeadroom(target, 20, () => 19), /insufficient disk/u);
  fs.rmSync(parent, { recursive: true, force: false });
});

test("retained Metal trace fingerprint must remain unchanged through export and analysis", () => {
  const fingerprint = {
    realpath: "/evidence/A1/metal.trace",
    size_bytes: 123456,
    sha256: "a".repeat(64),
  };
  assert.equal(assertArtifactFingerprintUnchanged(fingerprint, { ...fingerprint }, "trace").sha256, fingerprint.sha256);
  assert.throws(() => assertArtifactFingerprintUnchanged(
    fingerprint,
    { ...fingerprint, size_bytes: fingerprint.size_bytes + 1 },
    "trace",
  ), /changed after its initial fingerprint/u);
  assert.throws(() => assertArtifactFingerprintUnchanged(
    fingerprint,
    { ...fingerprint, sha256: "b".repeat(64) },
    "trace",
  ), /changed after its initial fingerprint/u);
});
