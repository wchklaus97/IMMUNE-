#!/usr/bin/env node

import fs from "node:fs";
import { createHash, randomBytes } from "node:crypto";
import path from "node:path";
import readline from "node:readline";

const ACCEPTED_ARGS = new Set([
  "input", "process", "pid", "run-id", "sequence", "drop-frames", "max-frames", "out",
  "baseline",
]);

function failUsage(message) {
  console.error(`METAL_GPU_ANALYSIS_USAGE_ERROR ${message}`);
  console.error(
    "Usage: node tools/analyze_metal_gpu_trace.mjs --input=<metal-gpu-intervals.xml> "
      + "--process=Godot --pid=<positive-pid> --run-id=<capture-id> "
      + "--sequence=<A1|B1|B2|A2> [--drop-frames=60] [--max-frames=1000] "
      + "[--out=<report.json>]",
  );
  process.exit(2);
}

function failSafety(message) {
  console.error(`METAL_GPU_ANALYSIS_SAFETY_ERROR ${message}`);
  process.exit(2);
}

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

const args = {};
for (const raw of process.argv.slice(2)) {
  if (!raw.startsWith("--") || !raw.includes("=")) failUsage(`invalid option ${raw}`);
  const [key, ...rest] = raw.slice(2).split("=");
  if (!ACCEPTED_ARGS.has(key)) failUsage(`unknown option --${key}`);
  if (Object.hasOwn(args, key)) failUsage(`duplicate option --${key}`);
  args[key] = rest.join("=");
}

const input = args.input;
const processName = String(args.process || "Godot");
const processId = Number(args.pid || 0);
const runId = String(args["run-id"] || "");
const sequence = String(args.sequence || "");
const sequenceIndex = Object.freeze({ A1: 1, B1: 2, B2: 3, A2: 4 })[sequence];
const dropFrames = Number(args["drop-frames"] ?? 60);
const maxFrames = Number(args["max-frames"] ?? 1000);
const output = String(args.out || "");
const baselinePath = String(args.baseline || "");

if (!input || !Number.isInteger(processId) || processId <= 0 || !runId || !sequence) {
  failUsage("--input, --pid, --run-id, and --sequence are required");
}
if (!/^[A-Za-z0-9][A-Za-z0-9._-]{7,127}$/u.test(runId)) {
  failUsage("--run-id must be 8-128 safe identifier characters");
}
if (processName !== "Godot") failUsage("--process must be the exact name Godot");
if (sequenceIndex === undefined) failUsage("--sequence must be A1, B1, B2, or A2");
if (!Number.isInteger(dropFrames) || dropFrames < 0) {
  failUsage("--drop-frames must be a non-negative integer");
}
if (!Number.isInteger(maxFrames) || maxFrames <= 0) {
  failUsage("--max-frames must be a positive integer");
}

let outputTarget = null;
if (output) {
  try {
    outputTarget = prepareExclusiveOutput(output, [
      { file: input, label: "input" },
      ...(baselinePath ? [{ file: baselinePath, label: "baseline" }] : []),
    ]);
  } catch (error) {
    failSafety(error.message);
  }
}

const inputAbsolutePath = path.resolve(input);
let inputRealPath;
let inputStatBefore;
try {
  inputRealPath = fs.realpathSync(inputAbsolutePath);
  inputStatBefore = fs.statSync(inputRealPath);
  if (!inputStatBefore.isFile()) throw new Error("input trace is not a regular file");
} catch (error) {
  console.error(`METAL_GPU_ANALYSIS_FAILED input=${inputAbsolutePath} error=${error.message}`);
  process.exit(1);
}

const scalarMaps = {
  "start-time": new Map(),
  duration: new Map(),
  "gpu-frame-number": new Map(),
  "gpu-channel-name": new Map(),
  "metal-nesting-level": new Map(),
};
const processMap = new Map();
const frames = new Map();
const channelEventCounts = new Map();
const relevantElementIds = new Set();
let targetEventCount = 0;
let malformedTargetRows = 0;
let nestedTargetRows = 0;
let unframedTargetRows = 0;
let unresolvedProcessRows = 0;
const unframedTargetIntervals = [];

function hasAttr(attrs, name) {
  return new RegExp(`(?:^|\\s)${name}="[^"]*"(?=\\s|/|$)`, "u").test(attrs);
}

function attr(attrs, name) {
  const matches = [...attrs.matchAll(
    new RegExp(`(?:^|\\s)${name}="([^"]*)"(?=\\s|/|$)`, "gu"),
  )];
  if (matches.length > 1) {
    console.error(`METAL_GPU_ANALYSIS_FAILED duplicate XML attribute: ${name}`);
    process.exit(1);
  }
  return matches.length === 1 ? matches[0][1] : "";
}

function numericScalar(text) {
  const normalized = String(text).trim();
  if (normalized.length === 0) return undefined;
  const value = Number(normalized);
  return Number.isFinite(value) ? value : undefined;
}

function reserveRelevantElementId(id, tag) {
  if (!id) return;
  if (relevantElementIds.has(id)) {
    console.error(`METAL_GPU_ANALYSIS_FAILED duplicate XML id: ${id} (${tag})`);
    process.exit(1);
  }
  relevantElementIds.add(id);
}

function scalarValues(line, tag, parse) {
  const values = [];
  const map = scalarMaps[tag];
  const pattern = new RegExp(
    `<${tag}\\b([^>]*)>([^<]*)<\\/${tag}>|<${tag}\\b([^>]*)\\/>`,
    "g",
  );
  for (const match of line.matchAll(pattern)) {
    const attrs = match[1] || match[3] || "";
    const hasInlineBody = match[2] !== undefined;
    const hasId = hasAttr(attrs, "id");
    const hasRef = hasAttr(attrs, "ref");
    const hasFmt = hasAttr(attrs, "fmt");
    const id = attr(attrs, "id");
    const ref = attr(attrs, "ref");
    const fmt = attr(attrs, "fmt");
    if (hasId && id.length > 0) reserveRelevantElementId(id, tag);
    let value;
    const scalarFormValid = (!hasId || id.length > 0)
      && (!hasRef || ref.length > 0)
      && !(hasRef && (hasId || hasFmt || hasInlineBody));
    if (!scalarFormValid) {
      value = undefined;
    } else if (ref) {
      value = map.get(ref);
    } else {
      value = match[2] === undefined ? undefined : parse(match[2], attrs);
      if (id && value !== undefined) map.set(id, value);
    }
    // Keep one slot per XML scalar. An unresolved first duration must not make
    // the following CPU-to-GPU latency duration look like event duration.
    values.push(value);
  }
  return values;
}

function scalarElementPattern(tag) {
  return `<${tag}\\b[^>]*(?:\\/>|>[^<]*<\\/${tag}>)`;
}

const START_TIME_ELEMENT = scalarElementPattern("start-time");
const DURATION_ELEMENT = scalarElementPattern("duration");
const CHANNEL_ELEMENT = scalarElementPattern("gpu-channel-name");
const FRAME_ELEMENT = scalarElementPattern("gpu-frame-number");
const DEPTH_ELEMENT = scalarElementPattern("metal-nesting-level");
const SENTINEL_ELEMENT = "<sentinel\\s*\\/>";
const EVENT_PREFIX_PATTERN = new RegExp(
  `^\\s*${START_TIME_ELEMENT}${DURATION_ELEMENT}${CHANNEL_ELEMENT}`
    + `(?<frame>${FRAME_ELEMENT}|${SENTINEL_ELEMENT})`
    + `(?<latency>${DURATION_ELEMENT}|${SENTINEL_ELEMENT})`
    + `${DEPTH_ELEMENT}\\s*$`,
  "u",
);

function eventPrefixShape(line) {
  const rowStart = line.match(/<row\b[^>]*>/u);
  if (!rowStart || rowStart.index === undefined) return null;
  const prefixStart = rowStart.index + rowStart[0].length;
  const labelStart = line.indexOf("<formatted-label", prefixStart);
  if (labelStart < 0) return null;
  const match = EVENT_PREFIX_PATTERN.exec(line.slice(prefixStart, labelStart));
  if (!match?.groups) return null;
  return {
    frameKind: /^\s*<sentinel\b/u.test(match.groups.frame) ? "unframed" : "framed",
    latencyKind: /^\s*<sentinel\b/u.test(match.groups.latency) ? "sentinel" : "duration",
  };
}

function processValues(line) {
  const values = [];
  for (const match of line.matchAll(/<process\b([^>]*)>/g)) {
    const attrs = match[1] || "";
    const hasInlineBody = !match[0].endsWith("/>");
    const hasId = hasAttr(attrs, "id");
    const hasRef = hasAttr(attrs, "ref");
    const hasFmt = hasAttr(attrs, "fmt");
    const id = attr(attrs, "id");
    const ref = attr(attrs, "ref");
    const fmt = attr(attrs, "fmt");
    if (hasId && id.length > 0) reserveRelevantElementId(id, "process");
    let value;
    const processFormValid = (!hasId || id.length > 0)
      && (!hasRef || ref.length > 0)
      && !(hasRef && (hasId || hasFmt || hasInlineBody));
    if (!processFormValid) {
      value = undefined;
    } else if (ref) {
      value = processMap.get(ref);
    } else {
      const pidMatch = fmt.match(/\((\d+)\)$/u);
      value = fmt.length === 0 || !pidMatch ? undefined : {
        label: fmt,
        name: fmt.replace(/\s+\(\d+\)$/u, ""),
        pid: pidMatch ? Number(pidMatch[1]) : 0,
      };
      if (id) processMap.set(id, value);
    }
    values.push(value);
  }
  return values;
}

function percentile(sortedValues, percentileValue) {
  if (sortedValues.length === 0) return 0;
  const index = Math.min(
    Math.floor((sortedValues.length - 1) * percentileValue),
    sortedValues.length - 1,
  );
  return sortedValues[index];
}

const sourceHash = createHash("sha256");
let sourceBytes = 0;
const stream = fs.createReadStream(inputRealPath);
stream.on("data", (chunk) => {
  sourceHash.update(chunk);
  sourceBytes += chunk.length;
});
const lines = readline.createInterface({ input: stream, crlfDelay: Infinity });

let sourceLineNumber = 0;
for await (const line of lines) {
  sourceLineNumber += 1;
  const rowOpenCount = [...line.matchAll(/<row\b[^>]*>/gu)].length;
  const rowCloseCount = [...line.matchAll(/<\/row>/gu)].length;
  if (rowOpenCount === 0 && rowCloseCount === 0) continue;
  const rowOpenIndex = line.search(/<row\b[^>]*>/u);
  const rowCloseIndex = line.indexOf("</row>");
  if (
    rowOpenCount !== 1
    || rowCloseCount !== 1
    || rowOpenIndex < 0
    || rowCloseIndex < rowOpenIndex
  ) {
    console.error(
      `METAL_GPU_ANALYSIS_FAILED unsupported XML row layout at line ${sourceLineNumber}`,
    );
    process.exit(1);
  }
  const rowXml = line.slice(rowOpenIndex, rowCloseIndex + "</row>".length);
  const prefixShape = eventPrefixShape(rowXml);
  const starts = scalarValues(rowXml, "start-time", numericScalar);
  const durations = scalarValues(rowXml, "duration", numericScalar);
  const frameNumbers = scalarValues(rowXml, "gpu-frame-number", (text, attrs) => {
    const fmt = attr(attrs, "fmt");
    const match = fmt.match(/Frame\s+(\d+)/u);
    return match ? Number(match[1]) : numericScalar(text);
  });
  const channels = scalarValues(rowXml, "gpu-channel-name", (text, attrs) =>
    attr(attrs, "fmt") || text,
  );
  const depths = scalarValues(rowXml, "metal-nesting-level", numericScalar);
  const processes = processValues(rowXml);

  const resolvedProcesses = processes.filter((entry) => entry !== undefined);
  const mentionsTarget = resolvedProcesses.some(
    (entry) =>
      entry.name === processName && (processId === 0 || entry.pid === processId),
  );
  const processIdentityConsistent = resolvedProcesses.length > 0
    && resolvedProcesses.length === processes.length
    && resolvedProcesses.every(
      (entry) => entry.name === resolvedProcesses[0].name && entry.pid === resolvedProcesses[0].pid,
    );
  if (!processIdentityConsistent) {
    if (mentionsTarget) {
      targetEventCount += 1;
      malformedTargetRows += 1;
    } else if (processes.some((entry) => entry === undefined)) {
      unresolvedProcessRows += 1;
    }
    continue;
  }
  const matchesTarget = mentionsTarget;
  if (!matchesTarget) continue;
  targetEventCount += 1;

  const start = starts[0];
  const duration = durations[0];
  const frameNumber = frameNumbers[0];
  const channel = channels[0];
  const depth = depths[0];
  const latencyValueValid = prefixShape?.latencyKind === "sentinel"
    || (Number.isFinite(durations[1]) && durations[1] >= 0);
  const scalarShapeValid = prefixShape !== null
    && starts.length === 1
    && durations.length === (prefixShape.latencyKind === "duration" ? 2 : 1)
    && channels.length === 1
    && depths.length === 1
    && frameNumbers.length === (prefixShape.frameKind === "framed" ? 1 : 0)
    && latencyValueValid;
  const commonFieldsValid = scalarShapeValid
    && Number.isFinite(start)
    && start >= 0
    && Number.isFinite(duration)
    && duration > 0
    && typeof channel === "string"
    && channel.trim().length > 0
    && Number.isInteger(depth)
    && depth >= 0;
  if (!commonFieldsValid) {
    malformedTargetRows += 1;
    continue;
  }
  if (!Number.isInteger(frameNumber) || frameNumber <= 0) {
    if (frameNumber === undefined && prefixShape.frameKind === "unframed") {
      unframedTargetRows += 1;
      unframedTargetIntervals.push({ start, end: start + duration });
    } else {
      malformedTargetRows += 1;
    }
    continue;
  }
  if (depth !== 0) {
    nestedTargetRows += 1;
    continue;
  }

  const end = start + duration;
  const existing = frames.get(frameNumber) || {
    start,
    end,
    eventCount: 0,
  };
  existing.start = Math.min(existing.start, start);
  existing.end = Math.max(existing.end, end);
  existing.eventCount += 1;
  frames.set(frameNumber, existing);

  channelEventCounts.set(channel, (channelEventCounts.get(channel) || 0) + 1);
}

if (unresolvedProcessRows > 0) {
  console.error(
    `METAL_GPU_ANALYSIS_FAILED unresolved process identity rows=${unresolvedProcessRows}`,
  );
  process.exit(1);
}

let inputStatAfter;
let inputRealPathAfter;
try {
  inputRealPathAfter = fs.realpathSync(inputAbsolutePath);
  inputStatAfter = fs.statSync(inputRealPathAfter);
} catch (error) {
  console.error(`METAL_GPU_ANALYSIS_FAILED source changed while reading: ${error.message}`);
  process.exit(1);
}
if (
  inputRealPathAfter !== inputRealPath
  || !sameFile(inputStatBefore, inputStatAfter)
  || inputStatBefore.size !== inputStatAfter.size
  || inputStatBefore.mtimeMs !== inputStatAfter.mtimeMs
  || inputStatBefore.ctimeMs !== inputStatAfter.ctimeMs
  || sourceBytes !== inputStatAfter.size
) {
  console.error("METAL_GPU_ANALYSIS_FAILED source changed while reading");
  process.exit(1);
}
const sourceArtifact = {
  absolute_path: inputAbsolutePath,
  real_path: inputRealPath,
  size_bytes: sourceBytes,
  sha256: sourceHash.digest("hex"),
};

const orderedFrames = [...frames.entries()].sort((a, b) => a[0] - b[0]);
const afterWarmup = orderedFrames.slice(dropFrames);
const analyzedFrames = afterWarmup.slice(0, maxFrames);
const analyzedWindowStart = analyzedFrames.length > 0
  ? Math.min(...analyzedFrames.map(([, frame]) => frame.start))
  : null;
const analyzedWindowEnd = analyzedFrames.length > 0
  ? Math.max(...analyzedFrames.map(([, frame]) => frame.end))
  : null;
const unframedTargetRowsOverlappingAnalyzedWindow = (
  analyzedWindowStart === null || analyzedWindowEnd === null
    ? unframedTargetRows
    : unframedTargetIntervals.filter(
      (interval) => interval.start < analyzedWindowEnd && interval.end > analyzedWindowStart,
    ).length
);
const analyzedFramesContiguous = analyzedFrames.every(
  ([frameNumber], index) => index === 0 || frameNumber === analyzedFrames[index - 1][0] + 1,
);
const durationsMs = analyzedFrames
  .map(([, frame]) => (frame.end - frame.start) / 1_000_000)
  .filter((value) => Number.isFinite(value) && value > 0)
  .sort((a, b) => a - b);

if (durationsMs.length === 0) {
  console.error(
    `METAL_GPU_ANALYSIS_FAILED process=${processName} pid=${processId || "any"} ` +
      `events=${targetEventCount} frames=${orderedFrames.length}`,
  );
  process.exit(1);
}

const totalMs = durationsMs.reduce((sum, value) => sum + value, 0);
const report = {
  schema_version: 1,
  source: inputAbsolutePath,
  source_artifact: sourceArtifact,
  process: processName,
  pid: processId,
  run_id: runId,
  sequence,
  sequence_index: sequenceIndex,
  target_event_count: targetEventCount,
  malformed_target_rows: malformedTargetRows,
  nested_target_rows: nestedTargetRows,
  unframed_target_rows: unframedTargetRows,
  unframed_target_rows_overlapping_analyzed_window:
    unframedTargetRowsOverlappingAnalyzedWindow,
  observed_frame_count: orderedFrames.length,
  dropped_warmup_frames: Math.min(dropFrames, orderedFrames.length),
  requested_max_frames: maxFrames,
  analyzed_frame_count: durationsMs.length,
  analyzed_frames_contiguous: analyzedFramesContiguous,
  first_analyzed_frame: analyzedFrames[0]?.[0] ?? null,
  last_analyzed_frame: analyzedFrames.at(-1)?.[0] ?? null,
  gpu_frame_span_ms: {
    mean: Number((totalMs / durationsMs.length).toFixed(3)),
    p50: Number(percentile(durationsMs, 0.5).toFixed(3)),
    p95: Number(percentile(durationsMs, 0.95).toFixed(3)),
    max: Number(durationsMs.at(-1).toFixed(3)),
  },
  channel_event_counts: Object.fromEntries(
    [...channelEventCounts.entries()].sort((a, b) => a[0].localeCompare(b[0])),
  ),
  interpretation:
    "Frame span is max(GPU event end) - min(GPU event start) for top-level Metal events " +
    "assigned to each target-process frame; overlapping events are not double-counted. " +
    "Rows with an explicit nullable Frame sentinel are excluded and counted separately.",
};

if (baselinePath) {
  const baseline = JSON.parse(fs.readFileSync(baselinePath, "utf8"));
  const baselineSummary = baseline.gpu_frame_span_ms || {};
  report.baseline = baselinePath;
  report.comparison_to_baseline = Object.fromEntries(
    ["mean", "p50", "p95", "max"].map((metric) => {
      const current = Number(report.gpu_frame_span_ms[metric] || 0);
      const baselineValue = Number(baselineSummary[metric] || 0);
      const delta = current - baselineValue;
      return [
        metric,
        {
          delta_ms: Number(delta.toFixed(3)),
          delta_percent:
            baselineValue > 0 ? Number(((delta / baselineValue) * 100).toFixed(1)) : null,
        },
      ];
    }),
  );
}

if (outputTarget) {
  try {
    publishJsonExclusive(outputTarget, report);
  } catch (error) {
    failSafety(error.message);
  }
}

const summary = report.gpu_frame_span_ms;
console.log(
  `METAL_GPU_ANALYSIS_OK process=${processName} pid=${processId} run_id=${runId} ` +
    `sequence=${sequence} frames=${report.analyzed_frame_count} mean_ms=${summary.mean.toFixed(3)} ` +
    `p95_ms=${summary.p95.toFixed(3)} max_ms=${summary.max.toFixed(3)}`,
);
if (report.comparison_to_baseline) {
  const comparison = report.comparison_to_baseline;
  console.log(
    `METAL_GPU_COMPARISON mean_delta_ms=${comparison.mean.delta_ms.toFixed(3)} ` +
      `mean_delta_percent=${comparison.mean.delta_percent?.toFixed(1) ?? "n/a"} ` +
      `p95_delta_ms=${comparison.p95.delta_ms.toFixed(3)} ` +
      `p95_delta_percent=${comparison.p95.delta_percent?.toFixed(1) ?? "n/a"}`,
  );
}
if (output) console.log(`METAL_GPU_REPORT ${output}`);
