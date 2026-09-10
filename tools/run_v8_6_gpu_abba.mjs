#!/usr/bin/env node

/**
 * Run the formal V8.6 GPU comparison as one, fail-closed macOS campaign.
 *
 * This runner intentionally owns no tuning knobs.  The four captures are always
 * A1=v8_5, B1=v8_6, B2=v8_6, A2=v8_5 and each launch is bound to a fresh runtime
 * report, exact Godot PID, and a separately saved Metal System Trace.
 *
 * It is also usable as a library.  The exported command-plan, path, status,
 * watchdog, and TOC helpers are pure or dependency-injectable so unit tests can
 * exercise the safety boundary without starting Godot or Instruments.
 */

import { spawn, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import fsp from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_PATH = fileURLToPath(import.meta.url);
const TOOLS_DIR = path.dirname(SCRIPT_PATH);
const REPO_ROOT = path.resolve(TOOLS_DIR, "..");
const PROJECT_ROOT = path.join(REPO_ROOT, "godot", "immune");

export const GODOT_VERSION = "4.7.2.stable.official.ed1daf0bf";
export const GODOT_SHA256 = "c7cccbf8fb143e34e02fd6521e09be2c2b974f0d5db080b19071c9c570718ccf";
export const DEFAULT_GODOT_PATH = path.resolve(
  REPO_ROOT,
  "..",
  "work",
  "godot-4.7.2",
  "Godot.app",
  "Contents",
  "MacOS",
  "Godot",
);
export const DEFAULT_XCRUN_PATH = "/usr/bin/xcrun";
export const DEFAULT_XCTRACE_PATH = "/Applications/Xcode.app/Contents/Developer/usr/bin/xctrace";
export const METAL_TEMPLATE = "Metal System Trace";
export const CAPTURE_HOLD_MS = 35_000;
export const TRACE_TIME_LIMIT_SECONDS = 8;
export const TRACE_TIME_LIMIT = `${TRACE_TIME_LIMIT_SECONDS}s`;
// `--time-limit 8s` is the exact requested measurement contract. Pinned
// xctrace 17F113 consistently includes bounded recorder stop latency in its
// authoritative TOC envelope (for example, 9.745658 s for an 8 s request and
// roughly 13.4-13.86 s for historical 12 s requests). Keep that envelope
// separate from the fixed 300-frame analysis window and reject both truncated
// and anomalously long recordings.
export const TRACE_RECORDED_MIN_SECONDS = 7.95;
export const TRACE_RECORDED_MAX_SECONDS = 12.0;
export const TRACE_END_REASON = "Time limit reached";
// Xcode 26 produced roughly 8.4 GiB of retained trace data plus comparable
// staging for one 30-second/20-character capture on the qualification host.
// Eight seconds preserves a 300-frame post-warmup sample while keeping four
// ABBA traces bounded; 24 GiB covers retained bundles plus one active staging
// copy and leaves meaningful host headroom.
export const INITIAL_MIN_FREE_BYTES = 24 * 1024 ** 3;
export const PER_CAPTURE_MIN_FREE_BYTES = 14 * 1024 ** 3;
export const PRE_ANALYSIS_MIN_FREE_BYTES = 6 * 1024 ** 3;
export const MIN_FREE_BYTES = INITIAL_MIN_FREE_BYTES;
const DEFAULT_EXEC_MAX_BUFFER_BYTES = 1024 ** 2;
// Git's binary patch encoding can be larger than the changed assets. Keep the
// normal subprocess bound tight, but give the two exact diff fingerprints a
// separate finite ceiling so legitimate GLB/LFS worktrees do not fail at the
// default 1 MiB spawnSync limit.
export const GIT_DIFF_MAX_BUFFER_BYTES = 16 * 1024 ** 2;
export const DROP_FRAMES = 60;
export const MAX_ANALYZED_FRAMES = 300;
export const TERMINATION_GRACE_MS = 5_000;
export const TERMINATION_KILL_WAIT_MS = 5_000;

export const TIMEOUTS_MS = Object.freeze({
  startup: 15_000,
  // A headed Metal window can be compositor-throttled to roughly 30 fps while
  // it is backgrounded. The exact 60-warmup + 4,000-frame workload then needs
  // a little over two minutes before it can publish the capture-ready record.
  ready: 5 * 60_000,
  godotCompletion: 120_000,
  xctraceStartup: 15_000,
  // Instruments may spend several minutes finalising a Metal trace on a
  // busy/deferred Xcode host. Keep a hard upper bound, but do not make the
  // normal save path fail at the old 90-second/60-second limits.
  xctraceSave: 15 * 60_000,
  export: 5 * 60_000,
  analyze: 30_000,
  gate: 30_000,
});

export const ABBA_SEQUENCE = Object.freeze([
  Object.freeze({ sequence: "A1", sequenceIndex: 1, look: "v8_5", group: "baseline", groupIndex: 0 }),
  Object.freeze({ sequence: "B1", sequenceIndex: 2, look: "v8_6", group: "candidate", groupIndex: 0 }),
  Object.freeze({ sequence: "B2", sequenceIndex: 3, look: "v8_6", group: "candidate", groupIndex: 1 }),
  Object.freeze({ sequence: "A2", sequenceIndex: 4, look: "v8_5", group: "baseline", groupIndex: 1 }),
]);

export function buildCampaignContract() {
  return Object.freeze({
    sequence: ABBA_SEQUENCE.map((entry) => `${entry.sequence}=${entry.look}`),
    resolution: "1920x1080",
    rendering_method: "forward_plus",
    renderer: "metal",
    family: "T",
    source: "character",
    material: "gel",
    count: 20,
    frames: 4000,
    sync: false,
    capture_hold_ms: CAPTURE_HOLD_MS,
    trace_time_limit: TRACE_TIME_LIMIT,
    trace_recorded_min_seconds: TRACE_RECORDED_MIN_SECONDS,
    trace_recorded_max_seconds: TRACE_RECORDED_MAX_SECONDS,
    trace_end_reason: TRACE_END_REASON,
    drop_frames: DROP_FRAMES,
    analyzed_frames: MAX_ANALYZED_FRAMES,
    initial_min_free_bytes: INITIAL_MIN_FREE_BYTES,
    per_capture_min_free_bytes: PER_CAPTURE_MIN_FREE_BYTES,
    pre_analysis_min_free_bytes: PRE_ANALYSIS_MIN_FREE_BYTES,
  });
}

export const SOURCE_PATHS = Object.freeze([
  "tools/run_v8_6_gpu_abba.mjs",
  "tools/analyze_metal_gpu_trace.mjs",
  "tools/validate_gpu_regression.mjs",
  "godot/immune/project.godot",
  "godot/immune/tools/gel_perf.gd",
  "godot/immune/characters/family_look.gd",
  "godot/immune/characters/gel_anim.gd",
  "godot/immune/characters/gel/gel_look.gd",
  "godot/immune/characters/gel/gel_profiles.gd",
  "godot/immune/characters/gel/wet_gel.gdshader",
  "godot/immune/characters/gel/jelly_shell.gdshader",
  "godot/immune/characters/gel/gel_eye.gdshader",
  "godot/immune/characters/authored_jelly_body.gd",
  "godot/immune/characters/character_root.gd",
  "godot/immune/characters/base_t/character.tscn",
  "godot/immune/characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb",
  "godot/immune/characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb",
]);

const SAFE_ID_RE = /^[A-Za-z0-9][A-Za-z0-9._-]{7,127}$/u;
const UINT_RE = /^\d+$/u;
const JSON_INDENT = 2;

function fail(message) {
  throw new Error(message);
}

function isPositiveInteger(value) {
  return Number.isInteger(value) && value > 0;
}

export function isSafeRunId(value) {
  return typeof value === "string" && SAFE_ID_RE.test(value);
}

function normalizeAbsolute(value, label) {
  if (typeof value !== "string" || value.trim().length === 0) {
    fail(`${label} must be a non-empty path`);
  }
  const resolved = path.resolve(value);
  if (!path.isAbsolute(resolved)) fail(`${label} must be absolute`);
  return resolved;
}

export function assertNewEvidenceRoot(value, {
  fsApi = fs,
  repoRoot = REPO_ROOT,
  projectRoot = path.join(repoRoot, "godot", "immune"),
  cwd = process.cwd(),
  temporaryRoot = os.tmpdir(),
} = {}) {
  const root = normalizeAbsolute(value, "evidence root");
  const repository = normalizeAbsolute(repoRoot, "repository");
  const project = normalizeAbsolute(projectRoot, "Godot project");
  const temporaryDirectory = normalizeAbsolute(temporaryRoot, "OS temporary directory");
  const forbidden = new Set([
    path.parse(root).root,
    repository,
    project,
    path.resolve(cwd),
  ]);
  if (forbidden.has(root)) fail("evidence root is too broad or names the workspace");
  if (fsApi.existsSync(root)) fail(`evidence root must not already exist: ${root}`);
  if (!pathInside(root, temporaryDirectory) || root === temporaryDirectory) {
    fail(`formal evidence root must be a new leaf below the OS-reported temporary directory: ${temporaryDirectory}`);
  }
  const parent = path.dirname(root);
  if (!fsApi.existsSync(parent)) fail(`evidence root parent must already exist: ${parent}`);
  const parentStat = fsApi.lstatSync(parent);
  if (parentStat.isSymbolicLink()) fail(`evidence root parent must not be a symbolic link: ${parent}`);
  if (!parentStat.isDirectory()) fail(`evidence root parent is not a directory: ${parent}`);
  const realParent = fsApi.realpathSync(parent);
  const canonicalRoot = path.join(realParent, path.basename(root));
  const realTemporaryRoot = fsApi.realpathSync(temporaryDirectory);
  const expectedCanonicalRoot = path.join(
    realTemporaryRoot,
    path.relative(temporaryDirectory, root),
  );
  if (canonicalRoot !== expectedCanonicalRoot) {
    fail(`evidence root must not traverse a symbolic-link or aliased ancestor: ${root}`);
  }
  const realRepository = fsApi.realpathSync(repository);
  const realProject = fsApi.realpathSync(project);
  if (!pathInside(canonicalRoot, realTemporaryRoot) || canonicalRoot === realTemporaryRoot) {
    fail(`formal evidence root escaped the canonical OS temporary directory: ${realTemporaryRoot}`);
  }
  if (pathInside(canonicalRoot, realProject)) {
    fail(`evidence root must be outside the measured Godot project: ${canonicalRoot}`);
  }
  if (pathInside(canonicalRoot, realRepository)) {
    fail(`formal evidence root must be outside the source repository: ${canonicalRoot}`);
  }
  return root;
}

export function reserveEvidenceRoot(value, options = {}) {
  const root = assertNewEvidenceRoot(value, options);
  try {
    fs.mkdirSync(root, { recursive: false });
  } catch (error) {
    if (error?.code === "EEXIST") fail(`evidence root was created concurrently: ${root}`);
    throw error;
  }
  const temporaryDirectory = normalizeAbsolute(options.temporaryRoot || os.tmpdir(), "OS temporary directory");
  const expectedCanonicalRoot = path.join(
    fs.realpathSync(temporaryDirectory),
    path.relative(temporaryDirectory, root),
  );
  const actualCanonicalRoot = fs.realpathSync(root);
  if (actualCanonicalRoot !== expectedCanonicalRoot) {
    fail(`reserved evidence root resolved outside its expected canonical target: ${root}`);
  }
  return root;
}

function parseOption(raw, accepted, values) {
  if (!raw.startsWith("--") || !raw.includes("=")) fail(`invalid option: ${raw}`);
  const [key, ...parts] = raw.slice(2).split("=");
  if (!accepted.has(key)) fail(`unknown option: --${key}`);
  if (Object.hasOwn(values, key)) fail(`duplicate option: --${key}`);
  const value = parts.join("=");
  if (value.length === 0) fail(`--${key} requires a non-empty value`);
  values[key] = value;
}

function parseTimeout(value, name) {
  if (!UINT_RE.test(value)) fail(`--${name} must be a positive integer`);
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed) || parsed <= 0) fail(`--${name} must be a positive integer`);
  return parsed;
}

export function parseRunnerArgs(argv) {
  const accepted = new Set([
    "godot",
    "evidence-root",
    "run-id",
    "project",
    "repo",
    "startup-timeout-ms",
    "ready-timeout-ms",
    "godot-timeout-ms",
    "xctrace-startup-timeout-ms",
    "xctrace-save-timeout-ms",
    "export-timeout-ms",
    "analyze-timeout-ms",
    "gate-timeout-ms",
    "plan-only",
  ]);
  const values = {};
  for (const raw of argv) {
    if (raw === "--plan-only") {
      if (Object.hasOwn(values, "plan-only")) fail("duplicate option: --plan-only");
      values["plan-only"] = "true";
      continue;
    }
    parseOption(raw, accepted, values);
  }
  for (const required of ["godot", "evidence-root", "run-id"]) {
    if (!Object.hasOwn(values, required)) fail(`missing option: --${required}`);
  }
  if (!isSafeRunId(values["run-id"])) {
    fail("--run-id must use 8-128 safe identifier characters");
  }
  const timeout = (key, fallback) => (
    Object.hasOwn(values, key) ? parseTimeout(values[key], key) : fallback
  );
  return {
    godot: normalizeAbsolute(values.godot, "--godot"),
    evidenceRoot: normalizeAbsolute(values["evidence-root"], "--evidence-root"),
    runId: values["run-id"],
    repo: normalizeAbsolute(values.repo || REPO_ROOT, "--repo"),
    project: normalizeAbsolute(values.project || PROJECT_ROOT, "--project"),
    timeouts: Object.freeze({
      startup: timeout("startup-timeout-ms", TIMEOUTS_MS.startup),
      ready: timeout("ready-timeout-ms", TIMEOUTS_MS.ready),
      godotCompletion: timeout("godot-timeout-ms", TIMEOUTS_MS.godotCompletion),
      xctraceStartup: timeout("xctrace-startup-timeout-ms", TIMEOUTS_MS.xctraceStartup),
      xctraceSave: timeout("xctrace-save-timeout-ms", TIMEOUTS_MS.xctraceSave),
      export: timeout("export-timeout-ms", TIMEOUTS_MS.export),
      analyze: timeout("analyze-timeout-ms", TIMEOUTS_MS.analyze),
      gate: timeout("gate-timeout-ms", TIMEOUTS_MS.gate),
    }),
    planOnly: values["plan-only"] === "true",
  };
}

function requireAbsolutePath(value, label) {
  const resolved = normalizeAbsolute(value, label);
  if (resolved !== value) fail(`${label} must be normalized and absolute: ${value}`);
  return resolved;
}

export function expectedRun(sequence) {
  const run = ABBA_SEQUENCE.find((entry) => entry.sequence === sequence);
  if (!run) fail(`unknown ABBA sequence: ${sequence}`);
  return run;
}

export function assertAbbaOrder(sequenceEntries) {
  if (!Array.isArray(sequenceEntries) || sequenceEntries.length !== ABBA_SEQUENCE.length) {
    fail("formal campaign must contain exactly A1, B1, B2, A2");
  }
  const actual = sequenceEntries.map((entry) => (
    typeof entry === "string" ? entry : entry?.sequence
  ));
  const expected = ABBA_SEQUENCE.map((entry) => entry.sequence);
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    fail(`formal campaign order must be ${expected.join(" -> ")}; got ${actual.join(" -> ")}`);
  }
  return true;
}

export function assertAbbaPrefix(sequenceEntries) {
  if (!Array.isArray(sequenceEntries) || sequenceEntries.length === 0 || sequenceEntries.length > ABBA_SEQUENCE.length) {
    fail("formal campaign prefix must contain one through four ordered entries");
  }
  const actual = sequenceEntries.map((entry) => (
    typeof entry === "string" ? entry : entry?.sequence
  ));
  const expected = ABBA_SEQUENCE.slice(0, actual.length).map((entry) => entry.sequence);
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    fail(`formal campaign prefix must follow ${expected.join(" -> ")}; got ${actual.join(" -> ")}`);
  }
  return true;
}

function pathInside(child, parent) {
  const relative = path.relative(parent, child);
  return relative === "" || (relative !== ".." && !relative.startsWith(`..${path.sep}`) && !path.isAbsolute(relative));
}

export function assertTaskPath(candidate, root, label = "path") {
  const absoluteCandidate = requireAbsolutePath(candidate, label);
  const absoluteRoot = requireAbsolutePath(root, "evidence root");
  if (!pathInside(absoluteCandidate, absoluteRoot)) {
    fail(`${label} must be below the evidence root`);
  }
  if (absoluteCandidate === absoluteRoot) fail(`${label} must not equal the evidence root`);
  return absoluteCandidate;
}

function runDirectoryPaths(root, run) {
  const runRoot = assertTaskPath(path.join(root, run.sequence), root, `${run.sequence} directory`);
  return Object.freeze({
    runRoot,
    tmp: path.join(runRoot, "tmp"),
    qaSave: path.join(runRoot, "tmp", "qa-save.json"),
    runtime: path.join(runRoot, "runtime.json"),
    trace: path.join(runRoot, "metal.trace"),
    traceToc: path.join(runRoot, "metal-toc.xml"),
    intervals: path.join(runRoot, "metal-gpu-intervals.xml"),
    report: path.join(runRoot, "gpu-report.json"),
    godotLog: path.join(runRoot, "godot.log"),
    xctraceLog: path.join(runRoot, "xctrace.log"),
    tocLog: path.join(runRoot, "xctrace-toc.log"),
    intervalsLog: path.join(runRoot, "xctrace-intervals.log"),
    analyzeLog: path.join(runRoot, "analyze.log"),
  });
}

// Instruments records the target process environment in its TOC.  Never pass
// the full shell environment into a captured Godot process: developer tokens,
// cloud credentials, and provider keys would become part of retained evidence.
export const CAPTURE_ENV_ALLOWLIST = Object.freeze([
  "HOME",
  "USER",
  "LOGNAME",
  "PATH",
  "LANG",
  "LC_ALL",
  "LC_CTYPE",
  "TERM",
  "COMMAND_MODE",
  "SYSTEM_VERSION_COMPAT",
  "MallocNanoZone",
]);
export const CAPTURE_ENV_DENY_RE = /(?:TOKEN|SECRET|KEY|PASSWORD|CREDENTIAL|AWS|MESHY|ANTHROPIC|OPENAI|API)/iu;

export function isDeniedEnvironmentName(name) {
  return CAPTURE_ENV_DENY_RE.test(String(name));
}

export function buildCaptureEnv({ look, tmpDir, baseEnv = process.env, includeLook = true } = {}) {
  if (!/^v8_[56]$/u.test(String(look))) fail(`capture selector must be v8_5 or v8_6: ${look}`);
  const tempPath = normalizeAbsolute(tmpDir, "per-run TMPDIR");
  const result = {};
  for (const name of CAPTURE_ENV_ALLOWLIST) {
    if (isDeniedEnvironmentName(name)) continue;
    if (typeof baseEnv?.[name] === "string" && baseEnv[name].length > 0) result[name] = baseEnv[name];
  }
  result.TMPDIR = tempPath;
  result.TMP = tempPath;
  result.TEMP = tempPath;
  if (includeLook) result.IMMUNE_GEL_LOOK = String(look);
  return Object.freeze(result);
}

export function buildGodotCommand({ godot, project, runRoot, tmpDir, qaSave, runtime, runId, sequence, look }) {
  const run = expectedRun(sequence);
  if (run.look !== look) fail(`${sequence} is locked to ${run.look}, not ${look}`);
  const command = requireAbsolutePath(godot, "Godot executable");
  const projectPath = requireAbsolutePath(project, "Godot project");
  const tempPath = requireAbsolutePath(tmpDir, "per-run TMPDIR");
  const savePath = requireAbsolutePath(qaSave, "QA save path");
  const runtimePath = requireAbsolutePath(runtime, "runtime report");
  const runPath = requireAbsolutePath(runRoot, "run root");
  if (!pathInside(savePath, tempPath)) fail("QA save path must be inside the per-run TMPDIR");
  if (!pathInside(runtimePath, runPath)) fail("runtime report must be inside the sequence directory");
  return Object.freeze({
    command,
    args: Object.freeze([
      "--path", projectPath,
      "--resolution", "1920x1080",
      "--rendering-method", "forward_plus",
      "--rendering-driver", "metal",
      "res://tools/gel_perf.tscn",
      "--",
      "--family=T",
      "--source=character",
      "--count=20",
      "--frames=4000",
      "--material=gel",
      "--sync=false",
      `--out=${runtimePath}`,
      `--save-path=${savePath}`,
      `--run-id=${runId}`,
      `--sequence=${sequence}`,
      `--capture-hold-ms=${CAPTURE_HOLD_MS}`,
    ]),
    env: buildCaptureEnv({ look, tmpDir: tempPath }),
  });
}

export function buildXctraceAttachCommand({ xctrace = DEFAULT_XCTRACE_PATH, trace, pid }) {
  const command = requireAbsolutePath(xctrace, "xctrace executable");
  const output = requireAbsolutePath(trace, "Metal trace output");
  if (!isPositiveInteger(pid)) fail("xctrace attach PID must be a positive integer");
  return Object.freeze({
    command,
    args: Object.freeze([
      "record",
      "--template", METAL_TEMPLATE,
      "--time-limit", TRACE_TIME_LIMIT,
      "--no-prompt",
      "--output", output,
      "--attach", String(pid),
    ]),
  });
}

export function buildXctraceExportCommand({ xctrace = DEFAULT_XCTRACE_PATH, trace, output, mode }) {
  const command = requireAbsolutePath(xctrace, "xctrace executable");
  const input = requireAbsolutePath(trace, "Metal trace input");
  const destination = requireAbsolutePath(output, "xctrace export output");
  if (mode === "toc") {
    return Object.freeze({
      command,
      args: Object.freeze(["export", "--input", input, "--toc", "--output", destination]),
    });
  }
  if (mode === "intervals") {
    return Object.freeze({
      command,
      args: Object.freeze([
        "export", "--input", input,
        "--xpath", "/trace-toc/run[@number=\"1\"]/data/table[@schema=\"metal-gpu-intervals\"]",
        "--output", destination,
      ]),
    });
  }
  fail(`unknown xctrace export mode: ${mode}`);
}

export function buildAnalyzerCommand({ node = process.execPath, analyzer, input, pid, runId, sequence, output }) {
  if (!isPositiveInteger(pid)) fail("analyzer PID must be a positive integer");
  const run = expectedRun(sequence);
  if (!isSafeRunId(runId)) fail("analyzer run ID is unsafe");
  const command = requireAbsolutePath(node, "Node executable");
  const script = requireAbsolutePath(analyzer, "Metal analyzer");
  return Object.freeze({
    command,
    args: Object.freeze([
      script,
      `--input=${requireAbsolutePath(input, "interval input")}`,
      "--process=Godot",
      `--pid=${pid}`,
      `--run-id=${runId}`,
      `--sequence=${run.sequence}`,
      `--drop-frames=${DROP_FRAMES}`,
      `--max-frames=${MAX_ANALYZED_FRAMES}`,
      `--out=${requireAbsolutePath(output, "GPU report")}`,
    ]),
  });
}

export function buildGateCommand({ node = process.execPath, validator, root, output }) {
  const command = requireAbsolutePath(node, "Node executable");
  const script = requireAbsolutePath(validator, "GPU regression validator");
  const evidenceRoot = requireAbsolutePath(root, "evidence root");
  const destination = assertTaskPath(output, evidenceRoot, "gate report");
  const baselineReports = ["A1", "A2"].map((sequence) => path.join(evidenceRoot, sequence, "gpu-report.json"));
  const candidateReports = ["B1", "B2"].map((sequence) => path.join(evidenceRoot, sequence, "gpu-report.json"));
  const baselineRuntimes = ["A1", "A2"].map((sequence) => path.join(evidenceRoot, sequence, "runtime.json"));
  const candidateRuntimes = ["B1", "B2"].map((sequence) => path.join(evidenceRoot, sequence, "runtime.json"));
  return Object.freeze({
    command,
    args: Object.freeze([
      script,
      `--baseline-reports=${baselineReports.join(",")}`,
      `--candidate-reports=${candidateReports.join(",")}`,
      `--baseline-runtimes=${baselineRuntimes.join(",")}`,
      `--candidate-runtimes=${candidateRuntimes.join(",")}`,
      `--out=${destination}`,
    ]),
  });
}

export function buildCampaignPlan({ godot, project, root, runId, xctrace = DEFAULT_XCTRACE_PATH, node = process.execPath } = {}) {
  const evidenceRoot = requireAbsolutePath(root, "evidence root");
  if (!isSafeRunId(runId)) fail("run ID is unsafe");
  const runs = ABBA_SEQUENCE.map((run) => {
    const paths = runDirectoryPaths(evidenceRoot, run);
    const godotCommand = buildGodotCommand({
      godot, project, runRoot: paths.runRoot, tmpDir: paths.tmp,
      qaSave: paths.qaSave, runtime: paths.runtime, runId,
      sequence: run.sequence, look: run.look,
    });
    return Object.freeze({
      ...run,
      paths,
      godot: godotCommand,
      xctrace: Object.freeze({
        attach: (pid) => buildXctraceAttachCommand({ xctrace, trace: paths.trace, pid }),
        toc: buildXctraceExportCommand({ xctrace, trace: paths.trace, output: paths.traceToc, mode: "toc" }),
        intervals: buildXctraceExportCommand({ xctrace, trace: paths.trace, output: paths.intervals, mode: "intervals" }),
      }),
      analyze: (pid) => buildAnalyzerCommand({
        node, analyzer: path.join(TOOLS_DIR, "analyze_metal_gpu_trace.mjs"),
        input: paths.intervals, pid, runId, sequence: run.sequence, output: paths.report,
      }),
    });
  });
  assertAbbaOrder(runs);
  return Object.freeze({
    runs: Object.freeze(runs),
    gate: buildGateCommand({ node, validator: path.join(TOOLS_DIR, "validate_gpu_regression.mjs"), root: evidenceRoot, output: path.join(evidenceRoot, "gpu-regression-gate.json") }),
  });
}

function commandText(command, args) {
  return [command, ...args].map((part) => (
    /[^A-Za-z0-9_./:=+-]/u.test(part) ? JSON.stringify(part) : part
  )).join(" ");
}

function realpathIfExists(candidate) {
  try {
    return fs.realpathSync(candidate);
  } catch {
    return null;
  }
}

export function verifyFormalWorkspaceIdentity({
  repo,
  project,
  expectedRepo = REPO_ROOT,
  realpath = fs.realpathSync,
} = {}) {
  const requestedRepo = normalizeAbsolute(repo, "repository");
  const requestedProject = normalizeAbsolute(project, "Godot project");
  let repoRealpath;
  let projectRealpath;
  let expectedRepoRealpath;
  let expectedProjectRealpath;
  try {
    repoRealpath = realpath(requestedRepo);
    projectRealpath = realpath(requestedProject);
    expectedRepoRealpath = realpath(normalizeAbsolute(expectedRepo, "runner repository"));
    expectedProjectRealpath = realpath(path.join(expectedRepoRealpath, "godot", "immune"));
  } catch (error) {
    fail(`formal workspace realpath verification failed: ${error?.message || String(error)}`);
  }
  if (repoRealpath !== expectedRepoRealpath) {
    fail(`formal repository must be the runner repository: ${expectedRepoRealpath}`);
  }
  if (projectRealpath !== expectedProjectRealpath) {
    fail(`formal Godot project must be ${expectedProjectRealpath}`);
  }
  const repoProjectRealpath = realpath(path.join(repoRealpath, "godot", "immune"));
  if (projectRealpath !== repoProjectRealpath) {
    fail("formal Godot project is not bound to the fingerprinted repository");
  }
  return Object.freeze({
    repo: Object.freeze({ requested_path: requestedRepo, realpath: repoRealpath }),
    project: Object.freeze({ requested_path: requestedProject, realpath: projectRealpath }),
  });
}

export function sha256File(filePath) {
  const hash = createHash("sha256");
  const fd = fs.openSync(filePath, "r");
  const buffer = Buffer.allocUnsafe(1024 * 1024);
  try {
    let bytes;
    do {
      bytes = fs.readSync(fd, buffer, 0, buffer.length, null);
      if (bytes > 0) hash.update(buffer.subarray(0, bytes));
    } while (bytes > 0);
  } finally {
    fs.closeSync(fd);
  }
  return hash.digest("hex");
}

function hashPathEntry(root, entry, hash) {
  const absolute = path.join(root, entry);
  const stat = fs.lstatSync(absolute);
  hash.update(`${entry}\0${stat.mode}\0${stat.size}\0${stat.isDirectory() ? "d" : stat.isSymbolicLink() ? "l" : "f"}\0`);
  if (stat.isSymbolicLink()) {
    hash.update(fs.readlinkSync(absolute));
    return stat.size;
  }
  if (stat.isDirectory()) {
    let total = 0;
    for (const child of fs.readdirSync(absolute).sort()) {
      total += hashPathEntry(absolute, child, hash);
    }
    return total;
  }
  const fd = fs.openSync(absolute, "r");
  const buffer = Buffer.allocUnsafe(1024 * 1024);
  try {
    let bytes;
    do {
      bytes = fs.readSync(fd, buffer, 0, buffer.length, null);
      if (bytes > 0) hash.update(buffer.subarray(0, bytes));
    } while (bytes > 0);
  } finally {
    fs.closeSync(fd);
  }
  return stat.size;
}

export function hashPath(candidate) {
  const absolute = path.resolve(candidate);
  const stat = fs.lstatSync(absolute);
  const hash = createHash("sha256");
  const size = stat.isDirectory()
    ? hashPathEntry(path.dirname(absolute), path.basename(absolute), hash)
    : hashPathEntry(path.dirname(absolute), path.basename(absolute), hash);
  return { path: absolute, realpath: fs.realpathSync(absolute), sizeBytes: size, sha256: hash.digest("hex") };
}

export function artifactFingerprint(candidate, root) {
  const absolute = assertTaskPath(candidate, root, "artifact");
  const fingerprint = hashPath(absolute);
  return {
    path: absolute,
    realpath: fingerprint.realpath,
    size_bytes: fingerprint.sizeBytes,
    sha256: fingerprint.sha256,
  };
}

export function assertArtifactFingerprintUnchanged(expected, actual, label = "artifact") {
  for (const field of ["realpath", "size_bytes", "sha256"]) {
    if (expected?.[field] !== actual?.[field]) {
      fail(`${label} changed after its initial fingerprint (${field})`);
    }
  }
  return actual;
}

function statfsFreeBytes(candidate) {
  const statfs = fs.statfsSync(candidate);
  return Number(statfs.bavail) * Number(statfs.bsize);
}

export function nearestExistingDirectory(candidate) {
  let cursor = path.resolve(candidate);
  while (!fs.existsSync(cursor)) {
    const parent = path.dirname(cursor);
    if (parent === cursor) fail(`no existing parent for path: ${candidate}`);
    cursor = parent;
  }
  const stat = fs.statSync(cursor);
  if (!stat.isDirectory()) fail(`free-space probe target is not a directory: ${cursor}`);
  return cursor;
}

export function assertDiskHeadroom(candidate, minimumBytes = MIN_FREE_BYTES, statfs = statfsFreeBytes) {
  if (!Number.isSafeInteger(minimumBytes) || minimumBytes <= 0) fail("minimum free-space threshold must be positive");
  const probe = nearestExistingDirectory(candidate);
  const availableBytes = statfs(probe);
  if (!Number.isFinite(availableBytes) || availableBytes < minimumBytes) {
    fail(`insufficient disk headroom: ${availableBytes} bytes available; need at least ${minimumBytes}`);
  }
  return { path: probe, availableBytes, minimumBytes };
}

function execFile(command, args, options = {}) {
  const maxBuffer = options.maxBuffer ?? DEFAULT_EXEC_MAX_BUFFER_BYTES;
  if (!Number.isSafeInteger(maxBuffer) || maxBuffer <= 0) {
    fail("subprocess output safety limit must be a positive safe integer");
  }
  const result = spawnSync(command, args, {
    cwd: options.cwd,
    env: options.env,
    encoding: "utf8",
    maxBuffer,
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.error?.code === "ENOBUFS") {
    fail(`${command} output exceeded the ${maxBuffer}-byte safety limit`);
  }
  if (result.error) throw result.error;
  if (result.status !== 0) {
    fail(`${command} ${args.join(" ")} failed with exit code ${result.status}: ${String(result.stderr || "").trim()}`);
  }
  return String(result.stdout || "");
}

export function gitSnapshot({ cwd = REPO_ROOT, excludePath = "" } = {}) {
  const repo = path.resolve(cwd);
  const root = String(execFile("git", ["rev-parse", "--show-toplevel"], { cwd: repo })).trim();
  const head = String(execFile("git", ["rev-parse", "HEAD"], { cwd: repo })).trim();
  const statusRaw = String(execFile("git", ["status", "--porcelain=v1", "--untracked-files=all"], { cwd: repo }));
  const exclude = excludePath ? path.relative(root, path.resolve(excludePath)).replaceAll(path.sep, "/") : "";
  const status = statusRaw.split("\n").filter((line) => {
    if (!exclude || line.length < 4) return line.length > 0;
    const payload = line.slice(3).trim().replace(/^"|"$/gu, "");
    return payload !== exclude && !payload.startsWith(`${exclude}/`);
  }).join("\n");
  const untrackedRaw = String(execFile("git", ["ls-files", "--others", "--exclude-standard", "-z"], { cwd: repo }));
  const untracked = untrackedRaw.split("\0").filter(Boolean).filter((relativePath) => {
    if (!exclude) return true;
    return relativePath !== exclude && !relativePath.startsWith(`${exclude}/`);
  }).sort().map((relativePath) => {
    const absolutePath = path.resolve(root, relativePath);
    if (!fs.existsSync(absolutePath)) fail(`untracked source disappeared during Git fingerprint: ${relativePath}`);
    const stat = fs.statSync(absolutePath);
    return {
      path: relativePath,
      realpath: fs.realpathSync(absolutePath),
      size_bytes: stat.size,
      sha256: stat.isFile() ? sha256File(absolutePath) : hashPath(absolutePath).sha256,
    };
  });
  const unstaged = String(execFile("git", ["diff", "--no-ext-diff", "--binary"], {
    cwd: repo,
    maxBuffer: GIT_DIFF_MAX_BUFFER_BYTES,
  }));
  const staged = String(execFile("git", ["diff", "--cached", "--no-ext-diff", "--binary"], {
    cwd: repo,
    maxBuffer: GIT_DIFF_MAX_BUFFER_BYTES,
  }));
  const payload = {
    repo: root,
    head,
    status,
    unstaged_sha256: createHash("sha256").update(unstaged).digest("hex"),
    staged_sha256: createHash("sha256").update(staged).digest("hex"),
    untracked,
  };
  return {
    ...payload,
    fingerprint: createHash("sha256").update(JSON.stringify(payload)).digest("hex"),
  };
}

export function sourceFingerprints(repo = REPO_ROOT) {
  const root = path.resolve(repo);
  return SOURCE_PATHS.map((relativePath) => {
    const absolute = path.join(root, relativePath);
    if (!fs.existsSync(absolute)) fail(`source fingerprint target is missing: ${relativePath}`);
    const stat = fs.statSync(absolute);
    return {
      path: relativePath,
      realpath: fs.realpathSync(absolute),
      size_bytes: stat.size,
      sha256: sha256File(absolute),
    };
  });
}

function sourceFingerprintDigest(entries) {
  return createHash("sha256").update(JSON.stringify(entries)).digest("hex");
}

export function assertSourceFingerprintsUnchanged(expected, repo = REPO_ROOT, label = "source") {
  const actual = sourceFingerprints(repo);
  if (sourceFingerprintDigest(expected) !== sourceFingerprintDigest(actual)) {
    fail(`${label} fingerprints changed during the frozen campaign`);
  }
  return actual;
}

export function verifyGodotIdentity({ godot, versionOutput, expectedPath = DEFAULT_GODOT_PATH, expectedSha256 = GODOT_SHA256, hash = sha256File, realpath = realpathIfExists } = {}) {
  const requested = normalizeAbsolute(godot, "Godot executable");
  const actualRealpath = realpath(requested);
  if (!actualRealpath) fail(`Godot executable does not exist: ${requested}`);
  const expectedRealpath = path.resolve(expectedPath);
  if (actualRealpath !== expectedRealpath) {
    fail(`Godot executable realpath is not the pinned 4.7.2 binary: ${actualRealpath}`);
  }
  const version = String(versionOutput ?? execFile(actualRealpath, ["--version"])).trim();
  if (version !== GODOT_VERSION) fail(`Godot version must be ${GODOT_VERSION}; got ${version}`);
  const sha256 = hash(actualRealpath);
  if (sha256 !== expectedSha256) fail(`Godot executable SHA-256 drifted: ${sha256}`);
  return { requested_path: requested, realpath: actualRealpath, version, sha256 };
}

export function assertGodotIdentityUnchanged(expected, options = {}) {
  if (expected == null || typeof expected !== "object") fail("initial Godot identity is unavailable");
  const actual = verifyGodotIdentity({
    godot: expected.requested_path,
    expectedPath: expected.realpath,
    expectedSha256: expected.sha256,
    ...options,
  });
  if (identityDigest(actual) !== identityDigest(expected)) {
    fail("Godot executable identity changed during the frozen campaign");
  }
  return actual;
}

function processIsAlive(pid) {
  if (!isPositiveInteger(pid)) return false;
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function defaultReadJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

export function validateRuntimeReady(runtime, { runId, sequence, look, pid } = {}) {
  if (runtime == null || typeof runtime !== "object" || Array.isArray(runtime)) fail("runtime report is not an object");
  if (runtime.run_id !== runId) fail(`runtime run_id mismatch: ${runtime.run_id}`);
  if (runtime.sequence !== sequence) fail(`runtime sequence mismatch: ${runtime.sequence}`);
  if (runtime.gel_look !== look) fail(`runtime look mismatch: ${runtime.gel_look}`);
  if (runtime.capture_hold_status !== "ready") fail(`runtime is not capture-ready: ${runtime.capture_hold_status}`);
  if (runtime.process_pid !== pid) fail(`runtime PID ${runtime.process_pid} does not match spawned PID ${pid}`);
  if (!isPositiveInteger(runtime.process_pid)) fail("runtime process_pid must be a positive integer");
  return runtime;
}

export function validateRuntimeComplete(runtime, { runId, sequence, look, pid } = {}) {
  validateRuntimeReady({ ...runtime, capture_hold_status: runtime?.capture_hold_status === "complete" ? "ready" : runtime?.capture_hold_status }, { runId, sequence, look, pid });
  if (runtime.capture_hold_status !== "complete") fail(`runtime capture hold did not complete: ${runtime.capture_hold_status}`);
  if (!Number.isInteger(runtime.capture_hold_actual_ms) || runtime.capture_hold_actual_ms < CAPTURE_HOLD_MS) fail("runtime capture hold duration is incomplete");
  if (!Number.isInteger(runtime.capture_hold_rendered_frames) || runtime.capture_hold_rendered_frames <= 0) fail("runtime capture hold rendered frame count is invalid");
  return runtime;
}

export function validateAnalyzedReport(report, { runId, sequence, pid, source } = {}) {
  if (report == null || typeof report !== "object" || Array.isArray(report)) fail("analyzed report is not an object");
  const expected = expectedRun(sequence);
  if (report.schema_version !== 1 || report.process !== "Godot") fail(`${sequence} analyzed report schema/process mismatch`);
  if (report.pid !== pid || report.sequence !== sequence || report.run_id !== runId) fail(`${sequence} analyzed report identity mismatch`);
  if (report.sequence_index !== expected.sequenceIndex) fail(`${sequence} analyzed report sequence_index mismatch`);
  if (typeof report.source !== "string" || path.resolve(report.source) !== path.resolve(source)) {
    fail(`${sequence} analyzed report is not bound to its exported interval source`);
  }
  const observedMinimum = DROP_FRAMES + MAX_ANALYZED_FRAMES;
  if (!Number.isInteger(report.observed_frame_count) || report.observed_frame_count < observedMinimum) {
    fail(`${sequence} analyzed report requires at least ${observedMinimum} observed frames`);
  }
  if (report.dropped_warmup_frames !== DROP_FRAMES) fail(`${sequence} analyzed report must drop exactly ${DROP_FRAMES} warmup frames`);
  if (report.requested_max_frames !== MAX_ANALYZED_FRAMES || report.analyzed_frame_count !== MAX_ANALYZED_FRAMES) {
    fail(`${sequence} analyzed report must contain exactly ${MAX_ANALYZED_FRAMES} analyzed frames`);
  }
  if (report.analyzed_frames_contiguous !== true) fail(`${sequence} analyzed report frames are not contiguous`);
  if (
    !Number.isInteger(report.first_analyzed_frame)
    || !Number.isInteger(report.last_analyzed_frame)
    || report.last_analyzed_frame - report.first_analyzed_frame !== MAX_ANALYZED_FRAMES - 1
  ) {
    fail(`${sequence} analyzed report frame span must contain exactly ${MAX_ANALYZED_FRAMES} frames`);
  }
  if (report.malformed_target_rows !== 0) fail(`${sequence} analyzed report contains malformed target rows`);
  if (!Number.isInteger(report.target_event_count) || report.target_event_count <= 0) fail(`${sequence} analyzed report target events are missing`);
  if (!Number.isInteger(report.nested_target_rows) || report.nested_target_rows < 0) fail(`${sequence} analyzed report nested row count is invalid`);
  if (!Number.isInteger(report.unframed_target_rows) || report.unframed_target_rows < 0) {
    fail(`${sequence} analyzed report unframed row count is invalid`);
  }
  if (report.unframed_target_rows_overlapping_analyzed_window !== 0) {
    fail(`${sequence} analyzed report has unframed rows overlapping the analyzed window`);
  }
  if (
    report.channel_event_counts == null
    || typeof report.channel_event_counts !== "object"
    || Array.isArray(report.channel_event_counts)
    || Object.keys(report.channel_event_counts).length === 0
    || Object.values(report.channel_event_counts).some(
      (value) => !Number.isInteger(value) || value <= 0,
    )
  ) {
    fail(`${sequence} analyzed report GPU channel counts are invalid`);
  }
  const classifiedTargetRows = Object.values(report.channel_event_counts)
    .reduce((sum, value) => sum + value, 0)
    + report.nested_target_rows
    + report.unframed_target_rows
    + report.malformed_target_rows;
  if (classifiedTargetRows !== report.target_event_count) {
    fail(`${sequence} analyzed report target row accounting mismatch`);
  }
  const summary = report.gpu_frame_span_ms;
  for (const metric of ["mean", "p50", "p95", "max"]) {
    if (typeof summary?.[metric] !== "number" || !Number.isFinite(summary[metric]) || summary[metric] <= 0) {
      fail(`${sequence} analyzed report ${metric} is not a positive finite duration`);
    }
  }
  if (summary.p50 > summary.p95 || summary.p95 > summary.max || summary.mean > summary.max) {
    fail(`${sequence} analyzed report GPU duration ordering is invalid`);
  }
  return report;
}

export function assertTraceFitsCaptureHold(runtime, traceTiming) {
  const traceStart = Number(traceTiming?.startUnixMs);
  const traceFinish = Number(traceTiming?.endUnixMs);
  if (!Number.isInteger(traceStart) || traceStart <= 0) fail("authoritative trace start timestamp is invalid");
  if (!Number.isInteger(traceFinish) || traceFinish <= traceStart) fail("authoritative trace end timestamp is invalid");
  const holdStart = Number(runtime?.capture_hold_started_unix_ms);
  const holdFinish = Number(runtime?.capture_hold_finished_unix_ms);
  if (!Number.isInteger(holdStart) || !Number.isInteger(holdFinish) || holdFinish < holdStart) {
    fail("capture hold timestamps are unavailable for trace containment verification");
  }
  if (traceStart < holdStart || traceFinish > holdFinish) {
    fail(
      `authoritative trace window does not fit inside the final capture hold `
      + `(${holdStart}-${holdFinish}); trace=${traceStart}-${traceFinish}`,
    );
  }
  return {
    hold_started_unix_ms: holdStart,
    hold_finished_unix_ms: holdFinish,
    trace_started_unix_ms: traceStart,
    trace_finished_unix_ms: traceFinish,
    trace_wall_duration_ms: traceFinish - traceStart,
    fits: true,
  };
}

function sleepMs(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

export async function waitForRuntimeReady({ file, runId, sequence, look, pid, timeoutMs = TIMEOUTS_MS.ready, pollMs = 100, readJson = defaultReadJson, isAlive = () => processIsAlive(pid), now = () => Date.now(), sleep = sleepMs } = {}) {
  const started = now();
  let lastError = "runtime report not published";
  while (now() - started <= timeoutMs) {
    try {
      const runtime = readJson(file);
      return validateRuntimeReady(runtime, { runId, sequence, look, pid });
    } catch (error) {
      lastError = error?.message || String(error);
      if (lastError.includes("run_id mismatch") || lastError.includes("sequence mismatch") || lastError.includes("look mismatch") || lastError.includes("does not match spawned PID")) throw error;
    }
    if (!isAlive()) fail(`Godot exited before capture-ready runtime report (${sequence}); last state: ${lastError}`);
    await sleep(pollMs);
  }
  fail(`runtime-ready watchdog expired for ${sequence} after ${timeoutMs} ms: ${lastError}`);
}

export async function withWatchdog(promise, { timeoutMs, label, onTimeout = () => {}, setTimer = setTimeout, clearTimer = clearTimeout } = {}) {
  if (!Number.isFinite(timeoutMs) || timeoutMs <= 0) fail(`${label || "watchdog"} timeout must be positive`);
  let timer;
  const timeoutToken = Object.freeze({ timeout: true });
  const timeout = new Promise((resolve) => {
    timer = setTimer(() => resolve(timeoutToken), timeoutMs);
  });
  try {
    const result = await Promise.race([promise, timeout]);
    if (result !== timeoutToken) return result;
    const timeoutError = new Error(`${label || "operation"} watchdog expired after ${timeoutMs} ms`);
    try {
      await onTimeout();
    } catch (error) {
      timeoutError.cause = error;
    }
    throw timeoutError;
  } finally {
    if (timer !== undefined) clearTimer(timer);
  }
}

function signalOwnedChild(child, label, signal) {
  const pid = Number(child?.pid);
  if (!isPositiveInteger(pid)) fail(`${label} has no safe child PID to terminate`);
  if (signal !== "SIGTERM" && signal !== "SIGKILL") fail(`unsupported child signal: ${signal}`);
  try {
    const sent = child.kill(signal);
    if (!sent && processIsAlive(pid)) fail(`${label} PID ${pid} refused ${signal}`);
  } catch (error) {
    if (error?.code !== "ESRCH") throw error;
  }
}

async function waitForTrackedClose(handle, timeoutMs) {
  if (handle.isDone()) return { completed: true, result: await handle.completion };
  let timer;
  const timeoutToken = Object.freeze({ timeout: true });
  try {
    const result = await Promise.race([
      handle.completion,
      new Promise((resolve) => { timer = setTimeout(() => resolve(timeoutToken), timeoutMs); }),
    ]);
    return result === timeoutToken
      ? { completed: false, result: null }
      : { completed: true, result };
  } finally {
    if (timer !== undefined) clearTimeout(timer);
  }
}

export async function terminateTrackedChild(handle, {
  label = "owned child",
  graceMs = TERMINATION_GRACE_MS,
  killWaitMs = TERMINATION_KILL_WAIT_MS,
} = {}) {
  if (!handle) fail(`${label} is not a tracked child`);
  if (!Number.isInteger(graceMs) || graceMs <= 0) fail("termination grace must be positive");
  if (!Number.isInteger(killWaitMs) || killWaitMs <= 0) fail("kill wait must be positive");
  if (handle.isDone()) {
    return { phase: "already_closed", result: await handle.completion };
  }
  if (!isPositiveInteger(Number(handle.pid))) {
    const pidless = await waitForTrackedClose(handle, killWaitMs);
    if (!pidless.completed) fail(`${label} has no safe PID and did not emit close`);
    return { phase: "closed_without_pid", result: pidless.result };
  }
  handle.terminate("SIGTERM");
  const graceful = await waitForTrackedClose(handle, graceMs);
  if (graceful.completed) return { phase: "sigterm", result: graceful.result };
  if (!handle.isDone()) handle.terminate("SIGKILL");
  const killed = await waitForTrackedClose(handle, killWaitMs);
  if (!killed.completed) fail(`${label} PID ${handle.pid} did not close after SIGKILL`);
  return { phase: "sigkill", result: killed.result };
}

function appendOutput(logFile, chunk, appendFileFn = fs.appendFileSync) {
  if (!chunk) return;
  appendFileFn(logFile, Buffer.isBuffer(chunk) ? chunk : String(chunk));
}

export function spawnTrackedCommand({
  command,
  args = [],
  cwd,
  env,
  log,
  spawnFn = spawn,
  appendFileFn = fs.appendFileSync,
} = {}) {
  const logPath = requireAbsolutePath(log, "command log");
  if (typeof appendFileFn !== "function") fail("command log writer must be a function");
  fs.mkdirSync(path.dirname(logPath), { recursive: true });
  const handle = fs.openSync(logPath, "wx");
  fs.closeSync(handle);
  let child;
  try {
    child = spawnFn(command, args, { cwd, env, shell: false, stdio: ["ignore", "pipe", "pipe"] });
  } catch (error) {
    throw error;
  }
  const pid = isPositiveInteger(Number(child?.pid)) ? Number(child.pid) : null;
  let closed = false;
  let spawnError = null;
  let logWriteError = null;
  let logTerminationError = null;
  let trackedHandle = null;
  let startupSettled = false;
  let resolveStartup;
  let rejectStartup;
  const startup = new Promise((resolve, reject) => {
    resolveStartup = resolve;
    rejectStartup = reject;
  });
  let result;
  let resolveCompletion;
  const completion = new Promise((resolve) => { resolveCompletion = resolve; });
  const settle = (status, signal) => {
    if (closed) return;
    closed = true;
    result = {
      pid,
      status,
      signal: signal || null,
      command,
      args,
      log: logPath,
      spawn_error: spawnError?.message || null,
      log_write_error: logWriteError?.message || null,
      log_write_error_code: logWriteError?.code || null,
      log_termination_error: logTerminationError?.message || null,
    };
    resolveCompletion(result);
  };
  const markStarted = () => {
    if (!isPositiveInteger(pid)) {
      startupSettled = true;
      rejectStartup(new Error(`spawned ${command} without a positive PID`));
      return;
    }
    startupSettled = true;
    resolveStartup({ pid, command, args });
  };
  const recordLogWriteFailure = (error) => {
    if (logWriteError) return;
    logWriteError = error instanceof Error ? error : new Error(String(error));
    if (!startupSettled) {
      startupSettled = true;
      rejectStartup(logWriteError);
    }
    // Never throw from a stream data callback. Route the failure through the
    // tracked result and terminate only this owned PID; the surrounding
    // campaign catch can then settle every other owned child and publish its
    // failure manifest. terminateTrackedChild also escalates TERM to KILL.
    queueMicrotask(() => {
      if (!trackedHandle || trackedHandle.isDone()) return;
      terminateTrackedChild(trackedHandle, { label: `${command} log-write failure` })
        .catch((terminationError) => {
          logTerminationError = terminationError instanceof Error
            ? terminationError
            : new Error(String(terminationError));
        });
    });
  };
  const writeChunk = (chunk) => {
    if (logWriteError) return;
    try {
      appendOutput(logPath, chunk, appendFileFn);
    } catch (error) {
      recordLogWriteFailure(error);
    }
  };
  child.stdout?.on("data", writeChunk);
  child.stderr?.on("data", writeChunk);
  child.once?.("spawn", markStarted);
  child.once?.("error", (error) => {
    spawnError = error;
    if (!startupSettled) {
      startupSettled = true;
      rejectStartup(error);
    }
  });
  child.once?.("close", settle);
  trackedHandle = Object.freeze({
    child,
    pid,
    startup,
    completion,
    isDone: () => closed,
    isAlive: () => !closed && isPositiveInteger(pid) && processIsAlive(pid),
    result: () => result,
    terminate: (signal = "SIGTERM") => signalOwnedChild(child, command, signal),
  });
  return trackedHandle;
}

async function awaitTracked(handle, timeoutMs, label) {
  return withWatchdog(handle.completion, {
    timeoutMs,
    label,
    onTimeout: () => terminateTrackedChild(handle, { label }),
  });
}

function assertExitZero(result, label) {
  if (!result || result.status !== 0 || result.signal || result.spawn_error || result.log_write_error) {
    fail(
      `${label} failed: status=${result?.status ?? "unknown"}`
      + ` signal=${result?.signal ?? "none"}`
      + ` spawn_error=${result?.spawn_error ?? "none"}`
      + ` log_write_error=${result?.log_write_error ?? "none"}`,
    );
  }
  return result;
}

export function inspectTraceToc(xml, { pid, processName = "Godot" } = {}) {
  if (typeof xml !== "string" || xml.trim().length === 0) fail("trace TOC is empty");
  if (!isPositiveInteger(pid)) fail("TOC verification PID must be positive");
  const processes = [];
  for (const match of xml.matchAll(/<process\b([^>]*)\/?\s*>/gu)) {
    const attrs = match[1] || "";
    const name = attrs.match(/\bname="([^"]*)"/u)?.[1] || "";
    const processPid = Number(attrs.match(/\bpid="(\d+)"/u)?.[1] || 0);
    if (name || processPid) processes.push({ name, pid: processPid });
  }
  const exact = processes.filter((entry) => entry.name === processName && entry.pid === pid);
  const hasMetalSchema = /<table\b[^>]*\bschema="metal-gpu-intervals"/u.test(xml);
  const summaries = [...xml.matchAll(/<summary\b[^>]*>([\s\S]*?)<\/summary>/gu)];
  if (summaries.length !== 1) fail("trace TOC must contain exactly one recording summary");
  const summary = summaries[0][1];
  const uniqueSummaryText = (name) => {
    const expression = new RegExp(`<${name}>\\s*([^<]+?)\\s*</${name}>`, "gu");
    const matches = [...summary.matchAll(expression)];
    if (matches.length !== 1) fail(`trace TOC summary must contain exactly one ${name}`);
    return matches[0][1].trim();
  };
  const startDate = uniqueSummaryText("start-date");
  const endDate = uniqueSummaryText("end-date");
  const isoWithZone = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/u;
  if (!isoWithZone.test(startDate) || !isoWithZone.test(endDate)) {
    fail("trace TOC start-date/end-date must be timezone-qualified ISO-8601 timestamps");
  }
  const startUnixMs = Date.parse(startDate);
  const endUnixMs = Date.parse(endDate);
  if (!Number.isFinite(startUnixMs) || !Number.isFinite(endUnixMs) || endUnixMs <= startUnixMs) {
    fail("trace TOC recording timestamps are invalid");
  }
  const durationText = uniqueSummaryText("duration");
  const durationSeconds = Number(durationText);
  const timeLimitText = uniqueSummaryText("time-limit");
  const timeLimitSeconds = Number(timeLimitText.match(/^([0-9]+(?:\.[0-9]+)?)\s+seconds?$/u)?.[1] || 0);
  const endReason = uniqueSummaryText("end-reason");
  const wallDurationMs = endUnixMs - startUnixMs;
  if (
    !Number.isFinite(durationSeconds)
    || durationSeconds <= 0
    || Math.abs(wallDurationMs - durationSeconds * 1000) > 5
  ) {
    fail("trace TOC duration does not agree with its authoritative start/end timestamps");
  }
  const environmentKeys = [...xml.matchAll(/<item\b([^>]*)\/?\s*>/gu)]
    .map((match) => match[1]?.match(/\bkey="([^"]*)"/u)?.[1] || "")
    .filter(Boolean);
  const forbiddenEnvironmentKeys = environmentKeys.filter((key) => isDeniedEnvironmentName(key));
  const devices = [...xml.matchAll(/<device\b([^>]*)\/?\s*>/gu)].map((match) => {
    const attrs = match[1] || "";
    return {
      platform: attrs.match(/\bplatform="([^"]*)"/u)?.[1] || "",
      model: attrs.match(/\bmodel="([^"]*)"/u)?.[1] || "",
      osVersion: attrs.match(/\bos-version="([^"]*)"/u)?.[1] || "",
    };
  }).filter((entry) => entry.platform || entry.model || entry.osVersion);
  const requestedTimeLimit = timeLimitSeconds === TRACE_TIME_LIMIT_SECONDS
    && endReason === TRACE_END_REASON;
  const boundedRecordingEnvelope = durationSeconds >= TRACE_RECORDED_MIN_SECONDS
    && durationSeconds <= TRACE_RECORDED_MAX_SECONDS;
  const timeLimitDeltaSeconds = durationSeconds - timeLimitSeconds;
  const result = {
    processName,
    pid,
    processes,
    exactProcessCount: exact.length,
    hasMetalSchema,
    durationSeconds,
    startDate,
    endDate,
    startUnixMs,
    endUnixMs,
    wallDurationMs,
    timeLimitSeconds,
    timeLimitDeltaSeconds,
    endReason,
    environmentKeys,
    forbiddenEnvironmentKeys,
    devices,
    requestedTimeLimit,
    boundedRecordingEnvelope,
    ok: exact.length >= 1 && hasMetalSchema,
  };
  result.ok = result.ok
    && result.requestedTimeLimit
    && result.boundedRecordingEnvelope
    && result.forbiddenEnvironmentKeys.length === 0;
  if (!result.ok) {
    fail(
      `trace TOC must contain ${processName} PID ${pid}, metal-gpu-intervals schema, `
      + `an exact requested ${TRACE_TIME_LIMIT_SECONDS}-second limit with ${TRACE_END_REASON}, `
      + `a ${TRACE_RECORDED_MIN_SECONDS}-${TRACE_RECORDED_MAX_SECONDS}-second authoritative `
      + "recording envelope, and no forbidden environment keys",
    );
  }
  return result;
}

// A successful process exit is not sufficient evidence that the captured
// scene rendered correctly.  Godot can emit a script/shader/engine diagnostic
// and still return status 0, which would otherwise let a cheaper failed frame
// set enter the ABBA aggregate.  Keep this matcher in lock-step with the
// repository's checked Godot command and fail closed on every occurrence.
export const GODOT_DIAGNOSTIC_RE = /(?:SCRIPT ERROR|Parse Error|Compile Error|ERROR:)/u;

export function inspectGodotLog(logText) {
  if (typeof logText !== "string") fail("Godot log is not text");
  const match = GODOT_DIAGNOSTIC_RE.exec(logText);
  const result = {
    ok: !match,
    diagnostic: match?.[0] || null,
  };
  if (!result.ok) fail(`Godot log contains a failure diagnostic: ${result.diagnostic}`);
  return result;
}

function readText(filePath) {
  return fs.readFileSync(filePath, "utf8");
}

function assertNewOutput(filePath, root, label) {
  const absolute = assertTaskPath(filePath, root, label);
  if (fs.existsSync(absolute)) fail(`${label} must not already exist: ${absolute}`);
  return absolute;
}

function makePerRunTempDir(_runRoot, runId, sequence, role = "raw") {
  const prefix = `${runId}-${sequence}-${role}-tmp-`;
  // ResearchState accepts explicit QA saves only below the operating-system
  // temporary root. Keep this directory outside the evidence tree so that the
  // same path is accepted by Godot's QA save guard.
  let tmp = "";
  try {
    tmp = fs.mkdtempSync(path.join(os.tmpdir(), prefix));
    const marker = path.join(tmp, ".runner-owned");
    fs.writeFileSync(marker, `${JSON.stringify({ runId, sequence, role, created_utc: new Date().toISOString() })}\n`, { flag: "wx" });
    return tmp;
  } catch (error) {
    if (tmp && fs.existsSync(tmp) && path.basename(tmp).startsWith(prefix)) {
      fs.rmSync(tmp, { recursive: true, force: false });
    }
    throw error;
  }
}

function removeOwnedTempDir(tmpDir, runId, sequence, role = "raw") {
  const absolute = path.resolve(tmpDir);
  const safeTempRoot = path.resolve(os.tmpdir());
  if (!pathInside(absolute, safeTempRoot) || absolute === safeTempRoot) {
    fail(`refusing to remove temporary directory outside the OS temp root: ${absolute}`);
  }
  const marker = path.join(absolute, ".runner-owned");
  if (!fs.existsSync(marker)) fail(`refusing to remove unmarked temporary directory: ${absolute}`);
  const markerData = JSON.parse(fs.readFileSync(marker, "utf8"));
  if (markerData.runId !== runId || markerData.sequence !== sequence || markerData.role !== role) fail(`temporary directory ownership mismatch: ${absolute}`);
  if (!path.basename(absolute).startsWith(`${runId}-${sequence}-${role}-tmp-`)) fail(`temporary directory name is not runner-owned: ${absolute}`);
  fs.rmSync(absolute, { recursive: true, force: false });
  return true;
}

export function cleanupOwnedTempDirOnFailure(tmpDir, runId, sequence, role) {
  const record = { path: path.resolve(tmpDir), role, removed: false, already_absent: false };
  if (!fs.existsSync(tmpDir)) {
    record.removed = true;
    record.already_absent = true;
    return record;
  }
  try {
    removeOwnedTempDir(tmpDir, runId, sequence, role);
    record.removed = true;
  } catch (error) {
    record.error = error?.message || String(error);
  }
  return record;
}

function appendFailureDetail(error, key, values) {
  if (error == null || typeof error !== "object") return;
  const current = Array.isArray(error[key]) ? error[key] : [];
  error[key] = [...current, ...values];
}

async function settleOwnedChildren(children) {
  const records = [];
  for (const entry of [...children].reverse()) {
    const { handle, label } = entry;
    try {
      const settled = await terminateTrackedChild(handle, { label });
      records.push({
        label,
        pid: handle.pid,
        phase: settled.phase,
        status: settled.result?.status ?? null,
        signal: settled.result?.signal ?? null,
        log_write_error: settled.result?.log_write_error ?? null,
        log_write_error_code: settled.result?.log_write_error_code ?? null,
        log_termination_error: settled.result?.log_termination_error ?? null,
      });
    } catch (error) {
      records.push({ label, pid: handle?.pid ?? null, phase: "failed", error: error?.message || String(error) });
    }
  }
  return records;
}

function writeExclusiveJson(filePath, value) {
  const parent = path.dirname(filePath);
  const temporary = path.join(
    parent,
    `.${path.basename(filePath)}.tmp-${process.pid}-${Date.now()}`,
  );
  const encoded = `${JSON.stringify(value, null, JSON_INDENT)}\n`;
  let temporaryCreated = false;
  try {
    const handle = fs.openSync(temporary, "wx", 0o600);
    temporaryCreated = true;
    try {
      fs.writeFileSync(handle, encoded, { encoding: "utf8" });
      fs.fsyncSync(handle);
    } finally {
      fs.closeSync(handle);
    }
    // A same-directory hard link publishes the fully synced inode atomically
    // and fails closed with EEXIST instead of replacing prior evidence.
    fs.linkSync(temporary, filePath);
  } finally {
    if (temporaryCreated && fs.existsSync(temporary)) fs.unlinkSync(temporary);
  }
}

export function readHostInfo({
  run = execFile,
  platform = process.platform,
  arch = process.arch,
  release = os.release,
} = {}) {
  const osVersion = (() => {
    try { return run("/usr/bin/sw_vers", ["-productVersion"]).trim(); } catch { return release(); }
  })();
  const osBuild = (() => {
    try { return run("/usr/bin/sw_vers", ["-buildVersion"]).trim(); } catch { return "unknown"; }
  })();
  let gpu = "unknown";
  try {
    const raw = run("/usr/sbin/system_profiler", ["SPDisplaysDataType", "-json"]);
    const parsed = JSON.parse(raw);
    const entries = parsed?.SPDisplaysDataType || [];
    gpu = [...new Set(entries.flatMap((entry) => [entry._name, entry.sppci_model]).filter(Boolean))].join(" | ") || "unknown";
  } catch {
    // A formal run cannot make a hardware claim without a concrete GPU name.
  }
  const result = {
    platform,
    arch,
    os_product_version: osVersion,
    os_build: osBuild,
    gpu,
  };
  for (const [field, value] of Object.entries(result)) {
    if (typeof value !== "string" || value.trim().length === 0 || /^unknown$/iu.test(value.trim())) {
      fail(`formal host identity ${field} is unavailable`);
    }
  }
  return result;
}

function identityDigest(value) {
  return createHash("sha256").update(JSON.stringify(value)).digest("hex");
}

export function assertHostInfoUnchanged(expected, options = {}) {
  const actual = readHostInfo(options);
  if (identityDigest(actual) !== identityDigest(expected)) {
    fail("host/GPU identity changed during the frozen campaign");
  }
  return actual;
}

function ensureExecutable(realpath, label) {
  if (!realpath || !fs.existsSync(realpath)) fail(`${label} is missing: ${realpath}`);
  const stat = fs.statSync(realpath);
  if (!stat.isFile()) fail(`${label} is not a file: ${realpath}`);
  fs.accessSync(realpath, fs.constants.X_OK);
}

export function verifyXcodeToolchainIdentity({
  xcrun = DEFAULT_XCRUN_PATH,
  run = execFile,
  realpath = fs.realpathSync,
  hash = sha256File,
} = {}) {
  const requestedXcrun = normalizeAbsolute(xcrun, "xcrun executable");
  let xcrunRealpath;
  let developerDir;
  let xctraceRequested;
  let xctraceRealpath;
  let xcodebuildRequested;
  let xcodebuildRealpath;
  try {
    xcrunRealpath = realpath(requestedXcrun);
    developerDir = realpath(String(run("/usr/bin/xcode-select", ["-p"])).trim());
    xctraceRequested = normalizeAbsolute(
      String(run(xcrunRealpath, ["--find", "xctrace"])).trim(),
      "resolved xctrace executable",
    );
    xctraceRealpath = realpath(xctraceRequested);
    xcodebuildRequested = normalizeAbsolute(
      String(run(xcrunRealpath, ["--find", "xcodebuild"])).trim(),
      "resolved xcodebuild executable",
    );
    xcodebuildRealpath = realpath(xcodebuildRequested);
  } catch (error) {
    fail(`Xcode toolchain resolution failed: ${error?.message || String(error)}`);
  }
  ensureExecutable(xcrunRealpath, "xcrun executable");
  ensureExecutable(xctraceRealpath, "resolved xctrace executable");
  ensureExecutable(xcodebuildRealpath, "resolved xcodebuild executable");
  if (!pathInside(xctraceRealpath, developerDir) || !pathInside(xcodebuildRealpath, developerDir)) {
    fail("resolved Xcode tools are outside the selected developer directory");
  }
  const xctraceVersion = String(run(xctraceRealpath, ["version"])).trim();
  const xcodeVersion = String(run(xcodebuildRealpath, ["-version"])).trim();
  const traceBuild = xctraceVersion.match(/\(([A-Za-z0-9.]+)\)\s*$/u)?.[1] || "";
  const xcodeBuild = xcodeVersion.match(/(?:^|\n)Build version\s+([^\s]+)\s*$/u)?.[1] || "";
  if (!/^xctrace version\s+\S+/u.test(xctraceVersion) || !traceBuild) {
    fail(`resolved xctrace returned an invalid version: ${xctraceVersion}`);
  }
  if (!/^Xcode\s+\S+/u.test(xcodeVersion) || !xcodeBuild) {
    fail(`resolved xcodebuild returned an invalid version: ${xcodeVersion}`);
  }
  if (traceBuild !== xcodeBuild) {
    fail(`xctrace/Xcode build mismatch: ${traceBuild} != ${xcodeBuild}`);
  }
  return Object.freeze({
    developer_dir: developerDir,
    xcrun: Object.freeze({
      requested_path: requestedXcrun,
      realpath: xcrunRealpath,
      sha256: hash(xcrunRealpath),
    }),
    xctrace: Object.freeze({
      requested_path: xctraceRequested,
      realpath: xctraceRealpath,
      version: xctraceVersion,
      build: traceBuild,
      sha256: hash(xctraceRealpath),
    }),
    xcodebuild: Object.freeze({
      requested_path: xcodebuildRequested,
      realpath: xcodebuildRealpath,
      version: xcodeVersion,
      build: xcodeBuild,
      sha256: hash(xcodebuildRealpath),
    }),
  });
}

export function assertXcodeToolchainUnchanged(expected, options = {}) {
  const actual = verifyXcodeToolchainIdentity(options);
  if (identityDigest(actual) !== identityDigest(expected)) {
    fail("selected Xcode/xctrace toolchain changed during the frozen campaign");
  }
  return actual;
}

function readRuntimeForRun(run, options) {
  const runtime = defaultReadJson(run.paths.runtime);
  return runtime;
}

async function captureRun({ plan, run, options, frozenGit, attempt }) {
  const captureStartedUtc = new Date().toISOString();
  fs.mkdirSync(run.paths.runRoot, { recursive: false });
  const tmpDir = makePerRunTempDir(run.paths.runRoot, options.runId, run.sequence);
  const ownedChildren = [];
  let godot;
  try {
    Object.assign(attempt, { status: "capture-launching", stage: "godot-startup", raw_temp_path: tmpDir });
    const paths = { ...run.paths, tmp: tmpDir, qaSave: path.join(tmpDir, "qa-save.json") };
    for (const output of [paths.runtime, paths.trace, paths.traceToc, paths.intervals, paths.report]) {
      assertNewOutput(output, options.evidenceRoot, `${run.sequence} output`);
    }
    const command = buildGodotCommand({
      godot: options.godotIdentity.realpath,
      project: options.project,
      runRoot: paths.runRoot,
      tmpDir,
      qaSave: paths.qaSave,
      runtime: paths.runtime,
      runId: options.runId,
      sequence: run.sequence,
      look: run.look,
    });
    // `command.env` is already a strict allowlist. Do not merge any caller or
    // shell environment: xctrace serialises the target environment into the
    // retained TOC, including credential-like names if they leak through.
    godot = spawnTrackedCommand({ command: command.command, args: command.args, cwd: options.project, env: command.env, log: paths.godotLog });
    ownedChildren.push({ handle: godot, label: `${run.sequence} Godot` });
    Object.assign(attempt, { pid: godot.pid, status: "capture-running" });
    await withWatchdog(godot.startup, {
      timeoutMs: options.timeouts.startup,
      label: `${run.sequence} Godot startup`,
      onTimeout: () => terminateTrackedChild(godot, { label: `${run.sequence} Godot startup` }),
    });
    const ready = await waitForRuntimeReady({
      file: paths.runtime,
      runId: options.runId,
      sequence: run.sequence,
      look: run.look,
      pid: godot.pid,
      timeoutMs: options.timeouts.ready,
      isAlive: godot.isAlive,
    });
    if (ready.process_pid !== godot.pid) fail(`${run.sequence} ready PID race`);
    attempt.stage = "xctrace-record";
    const traceCommand = buildXctraceAttachCommand({ xctrace: options.xctrace, trace: paths.trace, pid: godot.pid });
    const toolEnv = buildCaptureEnv({ look: run.look, tmpDir });
    let xctraceProcessSpawnedUtc = "";
    const xctrace = spawnTrackedCommand({ command: traceCommand.command, args: traceCommand.args, cwd: options.repo, env: toolEnv, log: paths.xctraceLog });
    ownedChildren.push({ handle: xctrace, label: `${run.sequence} xctrace` });
    let traceResult;
    let godotResult;
    let xctraceFinishedUtc = "";
    let godotFinishedUtc = "";
    try {
      await withWatchdog(xctrace.startup, {
        timeoutMs: options.timeouts.xctraceStartup,
        label: `${run.sequence} xctrace startup`,
        onTimeout: () => terminateTrackedChild(xctrace, { label: `${run.sequence} xctrace startup` }),
      });
      // This is process-launch diagnostics only. Authoritative recording
      // containment is established from TOC start-date/end-date after export.
      xctraceProcessSpawnedUtc = new Date().toISOString();
      [traceResult, godotResult] = await Promise.all([
        awaitTracked(xctrace, options.timeouts.xctraceSave, `${run.sequence} xctrace save`).then((result) => {
          xctraceFinishedUtc = new Date().toISOString();
          return result;
        }),
        awaitTracked(godot, options.timeouts.godotCompletion, `${run.sequence} Godot completion`).then((result) => {
          godotFinishedUtc = new Date().toISOString();
          return result;
        }),
      ]);
    } catch (error) {
      throw error;
    }
    const godotLogVerification = inspectGodotLog(readText(paths.godotLog));
    assertExitZero(traceResult, `${run.sequence} xctrace`);
    assertExitZero(godotResult, `${run.sequence} Godot`);
    const runtime = readRuntimeForRun(run, options);
    validateRuntimeComplete(runtime, { runId: options.runId, sequence: run.sequence, look: run.look, pid: godot.pid });
    const runtimeFingerprint = artifactFingerprint(paths.runtime, options.evidenceRoot);
    if (!fs.existsSync(paths.trace) || !fs.statSync(paths.trace).isDirectory()) fail(`${run.sequence} xctrace did not save a trace bundle`);
    const traceFingerprint = artifactFingerprint(paths.trace, options.evidenceRoot);
    const rawTempFingerprint = hashPath(tmpDir);
    // The raw per-run TMPDIR can contain hundreds of megabytes of Instruments
    // working data. It is removed only after both children exited and the
    // retained trace was hashed. A fresh marked temp directory is used for the
    // small xctrace export/analyzer tools below.
    removeOwnedTempDir(tmpDir, options.runId, run.sequence, "raw");
    Object.assign(attempt, { status: "capture-complete", stage: "captured", raw_temp_removed: true });
    const exportTmpDir = makePerRunTempDir(run.paths.runRoot, options.runId, run.sequence, "export");
    const exportPaths = { ...paths, tmp: exportTmpDir };
    return {
      ...run,
      paths: exportPaths,
      pid: godot.pid,
      runtime,
      runtimeFingerprint,
      traceFingerprint,
      rawTempFingerprint,
      raw_temp_removed: true,
      frozenGit,
      capture_started_utc: captureStartedUtc,
      xctrace_process_spawned_utc: xctraceProcessSpawnedUtc,
      xctrace_finished_utc: xctraceFinishedUtc,
      godot_finished_utc: godotFinishedUtc,
      capture_finished_utc: new Date().toISOString(),
      godot_log_verification: godotLogVerification,
    };
  } catch (error) {
    const termination = await settleOwnedChildren(ownedChildren);
    const cleanup = cleanupOwnedTempDirOnFailure(
      tmpDir,
      options.runId,
      run.sequence,
      "raw",
    );
    appendFailureDetail(error, "child_termination", termination);
    appendFailureDetail(error, "failure_cleanup", [cleanup]);
    Object.assign(attempt, {
      status: "failed",
      failed_stage: attempt.stage,
      raw_temp_removed: cleanup.removed,
      error: error?.message || String(error),
    });
    throw error;
  }
}

async function exportAndAnalyzeRun({ run, options, attempt }) {
  const ownedChildren = [];
  try {
  for (const output of [run.paths.traceToc, run.paths.intervals, run.paths.report]) {
    assertNewOutput(output, options.evidenceRoot, `${run.sequence} post-capture output`);
  }
  Object.assign(attempt, { status: "analysis-running", stage: "toc-export", export_temp_path: run.paths.tmp });
  const tocCommand = buildXctraceExportCommand({ xctrace: options.xctrace, trace: run.paths.trace, output: run.paths.traceToc, mode: "toc" });
  const toolEnv = buildCaptureEnv({ look: run.look, tmpDir: run.paths.tmp });
  const tocProcess = spawnTrackedCommand({ command: tocCommand.command, args: tocCommand.args, cwd: options.repo, env: toolEnv, log: run.paths.tocLog });
  ownedChildren.push({ handle: tocProcess, label: `${run.sequence} xctrace TOC export` });
  assertExitZero(await awaitTracked(tocProcess, options.timeouts.export, `${run.sequence} xctrace TOC export`), `${run.sequence} xctrace TOC export`);
  const tocXml = readText(run.paths.traceToc);
  const tocVerification = inspectTraceToc(tocXml, { pid: run.pid });
  const traceWindow = assertTraceFitsCaptureHold(run.runtime, tocVerification);
  attempt.stage = "interval-export";
  const intervalsCommand = buildXctraceExportCommand({ xctrace: options.xctrace, trace: run.paths.trace, output: run.paths.intervals, mode: "intervals" });
  const intervalsProcess = spawnTrackedCommand({ command: intervalsCommand.command, args: intervalsCommand.args, cwd: options.repo, env: toolEnv, log: run.paths.intervalsLog });
  ownedChildren.push({ handle: intervalsProcess, label: `${run.sequence} xctrace intervals export` });
  assertExitZero(await awaitTracked(intervalsProcess, options.timeouts.export, `${run.sequence} xctrace intervals export`), `${run.sequence} xctrace intervals export`);
  if (fs.statSync(run.paths.intervals).size <= 0) fail(`${run.sequence} exported intervals are empty`);
  attempt.stage = "metal-analysis";
  const analyzeCommand = buildAnalyzerCommand({
    node: process.execPath,
    analyzer: path.join(TOOLS_DIR, "analyze_metal_gpu_trace.mjs"),
    input: run.paths.intervals,
    pid: run.pid,
    runId: options.runId,
    sequence: run.sequence,
    output: run.paths.report,
  });
  const analyzeProcess = spawnTrackedCommand({ command: analyzeCommand.command, args: analyzeCommand.args, cwd: options.repo, env: toolEnv, log: run.paths.analyzeLog });
  ownedChildren.push({ handle: analyzeProcess, label: `${run.sequence} Metal analysis` });
  assertExitZero(await awaitTracked(analyzeProcess, options.timeouts.analyze, `${run.sequence} Metal analysis`), `${run.sequence} Metal analysis`);
  const report = defaultReadJson(run.paths.report);
  attempt.stage = "report-contract";
  validateAnalyzedReport(report, {
    runId: options.runId,
    sequence: run.sequence,
    pid: run.pid,
    source: run.paths.intervals,
  });
  const traceFingerprintAfterAnalysis = artifactFingerprint(run.paths.trace, options.evidenceRoot);
  assertArtifactFingerprintUnchanged(
    run.traceFingerprint,
    traceFingerprintAfterAnalysis,
    `${run.sequence} retained Metal trace`,
  );
  removeOwnedTempDir(run.paths.tmp, options.runId, run.sequence, "export");
  Object.assign(attempt, { status: "analysis-complete", stage: "complete", export_temp_removed: true });
  return {
    ...run,
    traceFingerprint: traceFingerprintAfterAnalysis,
    trace_unchanged_after_analysis: true,
    toc: artifactFingerprint(run.paths.traceToc, options.evidenceRoot),
    intervals: artifactFingerprint(run.paths.intervals, options.evidenceRoot),
    report: artifactFingerprint(run.paths.report, options.evidenceRoot),
    toc_verification: {
      pid: run.pid,
      metal_schema: tocVerification.hasMetalSchema,
      duration_seconds: tocVerification.durationSeconds,
      start_date: tocVerification.startDate,
      end_date: tocVerification.endDate,
      start_unix_ms: tocVerification.startUnixMs,
      end_unix_ms: tocVerification.endUnixMs,
      wall_duration_ms: tocVerification.wallDurationMs,
      time_limit_seconds: tocVerification.timeLimitSeconds,
      time_limit_delta_seconds: tocVerification.timeLimitDeltaSeconds,
      end_reason: tocVerification.endReason,
      requested_time_limit_verified: tocVerification.requestedTimeLimit,
      bounded_recording_envelope_verified: tocVerification.boundedRecordingEnvelope,
      environment_key_count: tocVerification.environmentKeys.length,
      safe_environment_keys: tocVerification.environmentKeys,
      devices: tocVerification.devices,
    },
    trace_window: traceWindow,
    raw_temp_removed: true,
    analysis_finished_utc: new Date().toISOString(),
  };
  } catch (error) {
    const termination = await settleOwnedChildren(ownedChildren);
    const cleanup = cleanupOwnedTempDirOnFailure(
      run.paths.tmp,
      options.runId,
      run.sequence,
      "export",
    );
    appendFailureDetail(error, "child_termination", termination);
    appendFailureDetail(error, "failure_cleanup", [cleanup]);
    Object.assign(attempt, {
      status: "failed",
      failed_stage: attempt.stage,
      export_temp_removed: cleanup.removed,
      error: error?.message || String(error),
    });
    throw error;
  }
}

function manifestArtifact(pathValue, root) {
  return artifactFingerprint(pathValue, root);
}

function finalizeRunArtifacts(run, root) {
  const runtime = manifestArtifact(run.paths.runtime, root);
  const trace = manifestArtifact(run.paths.trace, root);
  const toc = manifestArtifact(run.paths.traceToc, root);
  const intervals = manifestArtifact(run.paths.intervals, root);
  const report = manifestArtifact(run.paths.report, root);
  assertArtifactFingerprintUnchanged(run.runtimeFingerprint, runtime, `${run.sequence} runtime report`);
  assertArtifactFingerprintUnchanged(run.traceFingerprint, trace, `${run.sequence} Metal trace`);
  assertArtifactFingerprintUnchanged(run.toc, toc, `${run.sequence} trace TOC`);
  assertArtifactFingerprintUnchanged(run.intervals, intervals, `${run.sequence} interval export`);
  assertArtifactFingerprintUnchanged(run.report, report, `${run.sequence} GPU report`);
  return { runtime, trace, toc, intervals, report };
}

async function runCampaign(options) {
  if (process.platform !== "darwin") fail("formal V8.6 GPU ABBA requires macOS");
  const workspace = verifyFormalWorkspaceIdentity({
    repo: options.repo,
    project: options.project,
  });
  options.repo = workspace.repo.realpath;
  options.project = workspace.project.realpath;
  // Complete all read-only preflight checks before reserving a fresh evidence
  // leaf. Once exclusive mkdir succeeds, every subsequent failure is covered
  // by provenance.failed.json.
  options.evidenceRoot = assertNewEvidenceRoot(options.evidenceRoot, {
    repoRoot: options.repo,
    projectRoot: options.project,
    cwd: process.cwd(),
  });
  const disk = assertDiskHeadroom(options.evidenceRoot);
  const godotPath = path.resolve(options.godot);
  ensureExecutable(godotPath, "Godot executable");
  const godotIdentity = verifyGodotIdentity({ godot: godotPath });
  const requestedXcrun = normalizeAbsolute(options.xcrun || DEFAULT_XCRUN_PATH, "xcrun executable");
  const toolchain = verifyXcodeToolchainIdentity({ xcrun: requestedXcrun });
  options.godotIdentity = godotIdentity;
  options.xcrun = requestedXcrun;
  options.xctrace = toolchain.xctrace.realpath;
  const host = readHostInfo();
  const source = sourceFingerprints(options.repo);
  const gitBefore = gitSnapshot({ cwd: options.repo, excludePath: options.evidenceRoot });
  const plan = buildCampaignPlan({
    godot: godotIdentity.realpath,
    project: options.project,
    root: options.evidenceRoot,
    runId: options.runId,
    xctrace: toolchain.xctrace.realpath,
  });
  const frozenGit = gitBefore.fingerprint;
  const completedRuns = [];
  const attempts = [];
  let campaignStage = "reserve-evidence-root";
  options.evidenceRoot = reserveEvidenceRoot(options.evidenceRoot, {
    repoRoot: options.repo,
    projectRoot: options.project,
    cwd: process.cwd(),
  });
  try {
    campaignStage = "post-reservation-preflight";
    assertDiskHeadroom(options.evidenceRoot);
    for (const run of plan.runs) {
      campaignStage = `${run.sequence}-capture-analysis`;
      const captureDisk = assertDiskHeadroom(options.evidenceRoot, PER_CAPTURE_MIN_FREE_BYTES);
      assertAbbaPrefix([...completedRuns, run]);
      assertHostInfoUnchanged(host);
      assertXcodeToolchainUnchanged(toolchain, { xcrun: options.xcrun });
      assertGodotIdentityUnchanged(godotIdentity);
      assertSourceFingerprintsUnchanged(source, options.repo, `before ${run.sequence}`);
      const current = gitSnapshot({ cwd: options.repo, excludePath: options.evidenceRoot });
      if (current.fingerprint !== frozenGit) fail(`git/source state changed before ${run.sequence}`);
      const attempt = {
        sequence: run.sequence,
        sequence_index: run.sequenceIndex,
        look: run.look,
        status: "starting",
        stage: "pre-capture",
        pid: null,
        started_utc: new Date().toISOString(),
        disk_headroom_before_capture: captureDisk,
      };
      attempts.push(attempt);
      const captured = await captureRun({ plan, run, options, frozenGit, attempt });
      const afterCapture = gitSnapshot({ cwd: options.repo, excludePath: options.evidenceRoot });
      if (afterCapture.fingerprint !== frozenGit) fail(`git/source state changed after ${run.sequence}`);
      assertSourceFingerprintsUnchanged(source, options.repo, `after ${run.sequence} capture`);
      assertXcodeToolchainUnchanged(toolchain, { xcrun: options.xcrun });
      Object.assign(attempt, { status: "post-capture-preflight", stage: "pre-analysis-disk" });
      attempt.disk_headroom_before_analysis = assertDiskHeadroom(
        options.evidenceRoot,
        PRE_ANALYSIS_MIN_FREE_BYTES,
      );
      const analyzed = await exportAndAnalyzeRun({ run: captured, options, attempt });
      completedRuns.push(analyzed);
      attempt.finished_utc = new Date().toISOString();
      const afterRun = gitSnapshot({ cwd: options.repo, excludePath: options.evidenceRoot });
      if (afterRun.fingerprint !== frozenGit) fail(`git/source state changed after ${run.sequence} analysis`);
      assertSourceFingerprintsUnchanged(source, options.repo, `after ${run.sequence} analysis`);
    }
    assertAbbaOrder(completedRuns);
    campaignStage = "cross-run-identity";
    const tocDevices = completedRuns.map((run) => run.toc_verification.devices);
    if (tocDevices.some((devices) => !Array.isArray(devices) || devices.length === 0)) {
      fail("every trace TOC must identify the capture device");
    }
    if (new Set(tocDevices.map((devices) => identityDigest(devices))).size !== 1) {
      fail("trace TOC device identity changed across the ABBA campaign");
    }
    assertHostInfoUnchanged(host);
    assertXcodeToolchainUnchanged(toolchain, { xcrun: options.xcrun });
    campaignStage = "gpu-regression-gate";
    const gateTmpDir = makePerRunTempDir(options.evidenceRoot, options.runId, "GATE", "gate");
    const gateEnv = buildCaptureEnv({ look: "v8_6", tmpDir: gateTmpDir, includeLook: false });
    let gateProcess;
    let gateResult;
    try {
      gateProcess = spawnTrackedCommand({ command: plan.gate.command, args: plan.gate.args, cwd: options.repo, env: gateEnv, log: path.join(options.evidenceRoot, "gpu-regression-gate.log") });
      gateResult = assertExitZero(await awaitTracked(gateProcess, options.timeouts.gate, "GPU regression gate"), "GPU regression gate");
    } catch (error) {
      const termination = gateProcess
        ? await settleOwnedChildren([{ handle: gateProcess, label: "GPU regression gate" }])
        : [];
      const cleanup = cleanupOwnedTempDirOnFailure(gateTmpDir, options.runId, "GATE", "gate");
      appendFailureDetail(error, "child_termination", termination);
      appendFailureDetail(error, "failure_cleanup", [cleanup]);
      throw error;
    }
    const gateCleanup = cleanupOwnedTempDirOnFailure(gateTmpDir, options.runId, "GATE", "gate");
    if (!gateCleanup.removed) {
      const cleanupError = new Error(`GPU regression gate temp cleanup failed: ${gateCleanup.error}`);
      appendFailureDetail(cleanupError, "failure_cleanup", [gateCleanup]);
      throw cleanupError;
    }
    const gatePath = path.join(options.evidenceRoot, "gpu-regression-gate.json");
    const gateLogPath = path.join(options.evidenceRoot, "gpu-regression-gate.log");
    const gate = defaultReadJson(gatePath);
    if (gate.verdict !== "PASS" || gate.ok !== true) fail(`GPU regression gate did not PASS: ${gate.verdict}`);
    const gitAfter = gitSnapshot({ cwd: options.repo, excludePath: options.evidenceRoot });
    if (gitAfter.fingerprint !== frozenGit) fail("git/source state changed after GPU regression gate");
    const sourceAfter = assertSourceFingerprintsUnchanged(source, options.repo, "after GPU regression gate");
    const hostAfter = assertHostInfoUnchanged(host);
    const toolchainAfter = assertXcodeToolchainUnchanged(toolchain, { xcrun: options.xcrun });
    const godotAfter = assertGodotIdentityUnchanged(godotIdentity);
    const finalizedArtifacts = new Map(
      completedRuns.map((run) => [run.sequence, finalizeRunArtifacts(run, options.evidenceRoot)]),
    );
    const manifest = {
      schema_version: 1,
      status: "PASS",
      run_id: options.runId,
      created_utc: new Date().toISOString(),
      contract: buildCampaignContract(),
      host,
      host_after: hostAfter,
      host_unchanged: identityDigest(host) === identityDigest(hostAfter),
      workspace,
      disk_headroom: disk,
      godot: godotIdentity,
      godot_after: godotAfter,
      godot_unchanged: identityDigest(godotIdentity) === identityDigest(godotAfter),
      xcode_toolchain: toolchain,
      xcode_toolchain_after: toolchainAfter,
      xcode_toolchain_unchanged: identityDigest(toolchain) === identityDigest(toolchainAfter),
      git: { before: gitBefore, after: gitAfter, unchanged: gitBefore.fingerprint === gitAfter.fingerprint },
      source_fingerprints: source,
      source_fingerprints_after: sourceAfter,
      source_unchanged: sourceFingerprintDigest(source) === sourceFingerprintDigest(sourceAfter),
      attempts,
      runs: completedRuns.map((run) => ({
        sequence: run.sequence,
        sequence_index: run.sequenceIndex,
        look: run.look,
        pid: run.pid,
        capture_started_utc: run.capture_started_utc,
        xctrace_process_spawned_utc: run.xctrace_process_spawned_utc,
        xctrace_finished_utc: run.xctrace_finished_utc,
        godot_finished_utc: run.godot_finished_utc,
        capture_finished_utc: run.capture_finished_utc,
        trace_window: run.trace_window,
        runtime: finalizedArtifacts.get(run.sequence).runtime,
        trace: finalizedArtifacts.get(run.sequence).trace,
        trace_unchanged_after_analysis: run.trace_unchanged_after_analysis,
        trace_toc: finalizedArtifacts.get(run.sequence).toc,
        intervals: finalizedArtifacts.get(run.sequence).intervals,
        report: finalizedArtifacts.get(run.sequence).report,
        logs: {
          godot: manifestArtifact(run.paths.godotLog, options.evidenceRoot),
          xctrace_attach: manifestArtifact(run.paths.xctraceLog, options.evidenceRoot),
          xctrace_toc: manifestArtifact(run.paths.tocLog, options.evidenceRoot),
          xctrace_intervals: manifestArtifact(run.paths.intervalsLog, options.evidenceRoot),
          analyzer: manifestArtifact(run.paths.analyzeLog, options.evidenceRoot),
        },
        godot_log_verification: run.godot_log_verification,
        toc_verification: run.toc_verification,
        raw_temp: { ...run.rawTempFingerprint, removed: run.raw_temp_removed },
      })),
      gate: {
        ...manifestArtifact(gatePath, options.evidenceRoot),
        log: manifestArtifact(gateLogPath, options.evidenceRoot),
        verdict: gate.verdict,
        validator_status: gateResult.status,
      },
    };
    const manifestPath = path.join(options.evidenceRoot, "provenance.json");
    campaignStage = "publish-success-provenance";
    writeExclusiveJson(manifestPath, manifest);
    return manifest;
  } catch (error) {
    const failedManifestPath = path.join(options.evidenceRoot, "provenance.failed.json");
    if (!fs.existsSync(failedManifestPath)) {
      const failure = {
        schema_version: 1,
        status: "FAIL",
        run_id: options.runId,
        created_utc: new Date().toISOString(),
        error: error?.message || String(error),
        stage: attempts.at(-1)?.status === "failed"
          ? (attempts.at(-1)?.failed_stage || attempts.at(-1)?.stage || campaignStage)
          : campaignStage,
        evidence_root_reserved: true,
        host,
        workspace,
        godot: godotIdentity,
        xcode_toolchain: toolchain,
        git_before: gitBefore,
        attempts,
        child_termination: Array.isArray(error?.child_termination) ? error.child_termination : [],
        failure_cleanup: Array.isArray(error?.failure_cleanup) ? error.failure_cleanup : [],
        preserved_evidence_root: options.evidenceRoot,
      };
      try { writeExclusiveJson(failedManifestPath, failure); } catch { /* Preserve the original failure. */ }
    }
    throw error;
  }
}

export async function runGpuAbba(options) {
  const parsed = options?.timeouts ? options : { ...options, timeouts: TIMEOUTS_MS };
  return runCampaign({
    ...parsed,
    xcrun: parsed.xcrun || DEFAULT_XCRUN_PATH,
    repo: parsed.repo || REPO_ROOT,
    project: parsed.project || PROJECT_ROOT,
  });
}

function printPlan(options) {
  const workspace = verifyFormalWorkspaceIdentity({ repo: options.repo, project: options.project });
  const evidenceRoot = assertNewEvidenceRoot(options.evidenceRoot, {
    repoRoot: workspace.repo.realpath,
    projectRoot: workspace.project.realpath,
    cwd: process.cwd(),
  });
  const disk = assertDiskHeadroom(evidenceRoot);
  const godot = verifyGodotIdentity({ godot: options.godot });
  const toolchain = verifyXcodeToolchainIdentity({ xcrun: DEFAULT_XCRUN_PATH });
  const host = readHostInfo();
  sourceFingerprints(workspace.repo.realpath);
  gitSnapshot({ cwd: workspace.repo.realpath, excludePath: evidenceRoot });
  const plan = buildCampaignPlan({
    godot: godot.realpath,
    project: workspace.project.realpath,
    root: evidenceRoot,
    runId: options.runId,
    xctrace: toolchain.xctrace.realpath,
  });
  console.log(`GPU_ABBA_PLAN run_id=${options.runId} root=${evidenceRoot}`);
  console.log(`  host=${host.gpu} macOS=${host.os_product_version} free_bytes=${disk.availableBytes}`);
  console.log(`  xctrace=${toolchain.xctrace.realpath} ${toolchain.xctrace.version}`);
  for (const run of plan.runs) {
    console.log(`${run.sequence}=${run.look} PID_BIND=runtime:${run.paths.runtime}`);
    const displayArgs = run.godot.args.map((argument) => (
      argument.startsWith("--save-path=")
        ? "--save-path=<runner-owned-os-temp>/qa-save.json"
        : argument
    ));
    console.log(`  ${commandText(run.godot.command, displayArgs)}`);
    console.log(`  xctrace attach waits for PID and writes ${run.paths.trace}`);
  }
  console.log(`  gate ${commandText(plan.gate.command, plan.gate.args)}`);
}

async function main() {
  let options;
  try {
    options = parseRunnerArgs(process.argv.slice(2));
    if (options.planOnly) {
      printPlan(options);
      return;
    }
    const manifest = await runGpuAbba(options);
    console.log(`GPU_ABBA_PASS run_id=${manifest.run_id} manifest=${path.join(options.evidenceRoot, "provenance.json")}`);
  } catch (error) {
    console.error(`GPU_ABBA_FAILED ${error?.message || String(error)}`);
    process.exitCode = 1;
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === SCRIPT_PATH) {
  main();
}
