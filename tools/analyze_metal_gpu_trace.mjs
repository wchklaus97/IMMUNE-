#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import readline from "node:readline";

const args = Object.fromEntries(
  process.argv.slice(2).map((arg) => {
    const [key, ...rest] = arg.replace(/^--/, "").split("=");
    return [key, rest.join("=") || "true"];
  }),
);

const input = args.input;
const processName = String(args.process || "godot");
const processId = Number(args.pid || 0);
const dropFrames = Math.max(Number(args["drop-frames"] || 60), 0);
const maxFrames = Math.max(Number(args["max-frames"] || 0), 0);
const output = String(args.out || "");
const baselinePath = String(args.baseline || "");

if (!input) {
  console.error(
    "Usage: node tools/analyze_metal_gpu_trace.mjs --input=<metal-gpu-intervals.xml> " +
      "[--process=godot] [--pid=<pid>] [--drop-frames=60] [--out=<report.json>]",
  );
  process.exit(2);
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
let targetEventCount = 0;
let malformedTargetRows = 0;

function attr(attrs, name) {
  const match = attrs.match(new RegExp(`${name}="([^"]*)"`));
  return match ? match[1] : "";
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
    const id = attr(attrs, "id");
    const ref = attr(attrs, "ref");
    let value;
    if (ref) {
      value = map.get(ref);
    } else {
      value = parse(match[2] || "", attrs);
      if (id && value !== undefined) map.set(id, value);
    }
    if (value !== undefined) values.push(value);
  }
  return values;
}

function processValues(line) {
  const values = [];
  for (const match of line.matchAll(/<process\b([^>]*)>/g)) {
    const attrs = match[1] || "";
    const id = attr(attrs, "id");
    const ref = attr(attrs, "ref");
    let value;
    if (ref) {
      value = processMap.get(ref);
    } else {
      const fmt = attr(attrs, "fmt");
      const pidMatch = fmt.match(/\((\d+)\)$/);
      value = {
        label: fmt,
        name: fmt.replace(/\s+\(\d+\)$/, ""),
        pid: pidMatch ? Number(pidMatch[1]) : 0,
      };
      if (id) processMap.set(id, value);
    }
    if (value) values.push(value);
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

const stream = fs.createReadStream(input, { encoding: "utf8" });
const lines = readline.createInterface({ input: stream, crlfDelay: Infinity });

for await (const line of lines) {
  if (!line.includes("<row>")) continue;
  const starts = scalarValues(line, "start-time", (text) => Number(text));
  const durations = scalarValues(line, "duration", (text) => Number(text));
  const frameNumbers = scalarValues(line, "gpu-frame-number", (text, attrs) => {
    const fmt = attr(attrs, "fmt");
    const match = fmt.match(/Frame\s+(\d+)/);
    return match ? Number(match[1]) : Number(text);
  });
  const channels = scalarValues(line, "gpu-channel-name", (text, attrs) =>
    attr(attrs, "fmt") || text,
  );
  const depths = scalarValues(line, "metal-nesting-level", (text) => Number(text));
  const processes = processValues(line);

  const matchesTarget = processes.some(
    (entry) =>
      entry.name === processName && (processId === 0 || entry.pid === processId),
  );
  if (!matchesTarget) continue;
  targetEventCount += 1;

  const start = starts[0];
  const duration = durations[0];
  const frameNumber = frameNumbers[0];
  const depth = depths[0] ?? 0;
  if (
    !Number.isFinite(start) ||
    !Number.isFinite(duration) ||
    !Number.isFinite(frameNumber) ||
    depth !== 0
  ) {
    malformedTargetRows += 1;
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

  const channel = String(channels[0] || "unknown");
  channelEventCounts.set(channel, (channelEventCounts.get(channel) || 0) + 1);
}

const orderedFrames = [...frames.entries()].sort((a, b) => a[0] - b[0]);
const afterWarmup = orderedFrames.slice(dropFrames);
const analyzedFrames = maxFrames > 0 ? afterWarmup.slice(0, maxFrames) : afterWarmup;
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
  source: input,
  process: processName,
  pid: processId || null,
  target_event_count: targetEventCount,
  malformed_or_nested_target_rows: malformedTargetRows,
  observed_frame_count: orderedFrames.length,
  dropped_warmup_frames: Math.min(dropFrames, orderedFrames.length),
  requested_max_frames: maxFrames || null,
  analyzed_frame_count: durationsMs.length,
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
    "assigned to each target-process frame; overlapping events are not double-counted.",
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

if (output) {
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, `${JSON.stringify(report, null, 2)}\n`);
}

const summary = report.gpu_frame_span_ms;
console.log(
  `METAL_GPU_ANALYSIS_OK process=${processName} pid=${processId || "any"} ` +
    `frames=${report.analyzed_frame_count} mean_ms=${summary.mean.toFixed(3)} ` +
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
