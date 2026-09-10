import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

function minimalTrace(pid = 42) {
  return `<?xml version="1.0"?>
<trace-query-result>
<row><start-time id="s1">0</start-time><duration id="d1">2000000</duration><gpu-channel-name id="c1" fmt="Vertex">Vertex</gpu-channel-name><gpu-frame-number id="f1" fmt="Frame 1">1</gpu-frame-number><sentinel/><metal-nesting-level id="depth0">0</metal-nesting-level><formatted-label/><process id="p1" fmt="Godot (${pid})"></process></row>
</trace-query-result>
`;
}

test("groups overlapping top-level Metal events into target-process frame spans", async (t) => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-metal-trace-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  const input = path.join(tempDir, "intervals.xml");
  const output = path.join(tempDir, "report.json");
  fs.writeFileSync(
    input,
    `<?xml version="1.0"?>
<trace-query-result>
<row><start-time id="s1">0</start-time><duration id="d1">2000000</duration><gpu-channel-name id="c1" fmt="Vertex">Vertex</gpu-channel-name><gpu-frame-number id="f1" fmt="Frame 1">1</gpu-frame-number><sentinel/><metal-nesting-level id="depth0">0</metal-nesting-level><formatted-label/><process id="p1" fmt="Godot (42)"></process></row>
<row><start-time id="s2">1000000</start-time><duration id="d2">3000000</duration><gpu-channel-name id="c2" fmt="Fragment">Fragment</gpu-channel-name><gpu-frame-number ref="f1"/><sentinel/><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="s3">10000000</start-time><duration id="d3">5000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number id="f2" fmt="Frame 2">2</gpu-frame-number><sentinel/><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="s4">12000000</start-time><duration id="d4">6000000</duration><gpu-channel-name ref="c2"/><gpu-frame-number ref="f2"/><sentinel/><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
</trace-query-result>
`,
  );

  const { stdout } = await execFileAsync(process.execPath, [
    path.resolve("tools/analyze_metal_gpu_trace.mjs"),
    `--input=${input}`,
    "--process=Godot",
    "--pid=42",
    "--run-id=v86-metal-test",
    "--sequence=A1",
    "--drop-frames=1",
    "--max-frames=1",
    `--out=${output}`,
  ]);

  assert.match(stdout, /METAL_GPU_ANALYSIS_OK/);
  const report = JSON.parse(fs.readFileSync(output, "utf8"));
  assert.equal(report.observed_frame_count, 2);
  assert.equal(report.analyzed_frame_count, 1);
  assert.equal(report.run_id, "v86-metal-test");
  assert.equal(report.sequence, "A1");
  assert.equal(report.sequence_index, 1);
  assert.equal(report.pid, 42);
  assert.equal(report.malformed_target_rows, 0);
  assert.equal(report.nested_target_rows, 0);
  assert.equal(report.unframed_target_rows, 0);
  assert.equal(report.unframed_target_rows_overlapping_analyzed_window, 0);
  assert.equal(report.analyzed_frames_contiguous, true);
  assert.equal(report.gpu_frame_span_ms.mean, 8);
  assert.deepEqual(report.channel_event_counts, { Fragment: 2, Vertex: 2 });
  const inputBytes = fs.readFileSync(input);
  assert.equal(report.source, path.resolve(input));
  assert.deepEqual(report.source_artifact, {
    absolute_path: path.resolve(input),
    real_path: fs.realpathSync(input),
    size_bytes: inputBytes.length,
    sha256: createHash("sha256").update(inputBytes).digest("hex"),
  });
});

test("classifies an exact nullable Frame sentinel and reports analyzed-window overlap", async (t) => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-metal-trace-unframed-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  const input = path.join(tempDir, "intervals.xml");
  const output = path.join(tempDir, "report.json");
  const overlappingInput = path.join(tempDir, "intervals-overlap.xml");
  const overlappingOutput = path.join(tempDir, "report-overlap.json");
  const trace = `<?xml version="1.0"?>
<trace-query-result>
<row><start-time id="s1">0</start-time><duration id="d1">2000000</duration><gpu-channel-name id="c1" fmt="Vertex">Vertex</gpu-channel-name><gpu-frame-number id="f1" fmt="Frame 1">1</gpu-frame-number><duration id="lat1">100</duration><metal-nesting-level id="depth0">0</metal-nesting-level><formatted-label/><process id="p1" fmt="Godot (42)"></process></row>
<row><start-time id="s2">4000000</start-time><duration id="d2">2000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number id="f2" fmt="Frame 2">2</gpu-frame-number><duration id="lat2">100</duration><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="s3">10000000</start-time><duration id="d3">1000000</duration><gpu-channel-name ref="c1"/><sentinel/><duration id="lat3">100</duration><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
</trace-query-result>
`;
  fs.writeFileSync(input, trace);
  const command = (source, target) => [
    path.resolve("tools/analyze_metal_gpu_trace.mjs"),
    `--input=${source}`,
    "--process=Godot",
    "--pid=42",
    "--run-id=v86-metal-unframed",
    "--sequence=A1",
    "--drop-frames=0",
    "--max-frames=1",
    `--out=${target}`,
  ];

  await execFileAsync(process.execPath, command(input, output));
  const report = JSON.parse(fs.readFileSync(output, "utf8"));
  assert.equal(report.target_event_count, 3);
  assert.equal(report.malformed_target_rows, 0);
  assert.equal(report.nested_target_rows, 0);
  assert.equal(report.unframed_target_rows, 1);
  assert.equal(report.unframed_target_rows_overlapping_analyzed_window, 0);
  assert.equal(report.analyzed_frame_count, 1);
  assert.deepEqual(report.channel_event_counts, { Vertex: 2 });

  fs.writeFileSync(
    overlappingInput,
    trace.replace('<start-time id="s3">10000000</start-time>', '<start-time id="s3">1000000</start-time>'),
  );
  await execFileAsync(process.execPath, command(overlappingInput, overlappingOutput));
  const overlapping = JSON.parse(fs.readFileSync(overlappingOutput, "utf8"));
  assert.equal(overlapping.unframed_target_rows, 1);
  assert.equal(overlapping.unframed_target_rows_overlapping_analyzed_window, 1);
});

test("rejects an output that aliases its trace input or comparison baseline", async (t) => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-metal-trace-alias-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  const input = path.join(tempDir, "intervals.xml");
  const inputContents = minimalTrace();
  fs.writeFileSync(input, inputContents);

  await assert.rejects(
    execFileAsync(process.execPath, [
      path.resolve("tools/analyze_metal_gpu_trace.mjs"),
      `--input=${input}`,
      "--process=Godot",
      "--pid=42",
      "--run-id=v86-metal-alias",
      "--sequence=A1",
      "--drop-frames=0",
      "--max-frames=1",
      `--out=${input}`,
    ]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /output.*aliases.*input/u);
      return true;
    },
  );
  assert.equal(fs.readFileSync(input, "utf8"), inputContents);

  const hardLinkAlias = path.join(tempDir, "input-hard-link.xml");
  fs.linkSync(input, hardLinkAlias);
  await assert.rejects(
    execFileAsync(process.execPath, [
      path.resolve("tools/analyze_metal_gpu_trace.mjs"),
      `--input=${input}`,
      "--process=Godot",
      "--pid=42",
      "--run-id=v86-metal-alias",
      "--sequence=A1",
      "--drop-frames=0",
      "--max-frames=1",
      `--out=${hardLinkAlias}`,
    ]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /output.*aliases.*input/u);
      return true;
    },
  );
  assert.equal(fs.readFileSync(input, "utf8"), inputContents);

  const baseline = path.join(tempDir, "baseline.json");
  const baselineContents = `${JSON.stringify({ gpu_frame_span_ms: { mean: 2, p50: 2, p95: 2, max: 2 } })}\n`;
  fs.writeFileSync(baseline, baselineContents);
  await assert.rejects(
    execFileAsync(process.execPath, [
      path.resolve("tools/analyze_metal_gpu_trace.mjs"),
      `--input=${input}`,
      "--process=Godot",
      "--pid=42",
      "--run-id=v86-metal-alias",
      "--sequence=A1",
      "--drop-frames=0",
      "--max-frames=1",
      `--baseline=${baseline}`,
      `--out=${baseline}`,
    ]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /output.*aliases.*baseline/u);
      return true;
    },
  );
  assert.equal(fs.readFileSync(baseline, "utf8"), baselineContents);
});

test("rejects a pre-existing output without changing it", async (t) => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-metal-trace-existing-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  const input = path.join(tempDir, "intervals.xml");
  const output = path.join(tempDir, "report.json");
  fs.writeFileSync(input, minimalTrace());
  fs.writeFileSync(output, "sentinel\n");

  await assert.rejects(
    execFileAsync(process.execPath, [
      path.resolve("tools/analyze_metal_gpu_trace.mjs"),
      `--input=${input}`,
      "--process=Godot",
      "--pid=42",
      "--run-id=v86-metal-existing",
      "--sequence=B1",
      "--drop-frames=0",
      "--max-frames=1",
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

test("publishes concurrently to one output exactly once without temporary residue", async (t) => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-metal-trace-exclusive-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  const input = path.join(tempDir, "intervals.xml");
  const output = path.join(tempDir, "report.json");
  fs.writeFileSync(input, minimalTrace());
  const command = [
    path.resolve("tools/analyze_metal_gpu_trace.mjs"),
    `--input=${input}`,
    "--process=Godot",
    "--pid=42",
    "--run-id=v86-metal-exclusive",
    "--sequence=A2",
    "--drop-frames=0",
    "--max-frames=1",
    `--out=${output}`,
  ];

  const attempts = await Promise.allSettled([
    execFileAsync(process.execPath, command),
    execFileAsync(process.execPath, command),
  ]);
  assert.equal(attempts.filter((entry) => entry.status === "fulfilled").length, 1);
  const rejection = attempts.find((entry) => entry.status === "rejected");
  assert.equal(rejection.reason.code, 2);
  assert.match(rejection.reason.stderr, /pre-existing output/u);
  assert.equal(JSON.parse(fs.readFileSync(output, "utf8")).sequence, "A2");
  assert.deepEqual(
    fs.readdirSync(tempDir).filter((entry) => entry.includes(".tmp-")),
    [],
  );
});

test("requires exact PID, run ID, and ABBA sequence identity", async (t) => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-metal-trace-invalid-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  const input = path.join(tempDir, "intervals.xml");
  fs.writeFileSync(input, "<?xml version=\"1.0\"?><trace-query-result></trace-query-result>\n");

  await assert.rejects(
    execFileAsync(process.execPath, [
      path.resolve("tools/analyze_metal_gpu_trace.mjs"),
      `--input=${input}`,
      "--process=Godot",
    ]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /--pid.*--run-id.*--sequence/u);
      return true;
    },
  );

  await assert.rejects(
    execFileAsync(process.execPath, [
      path.resolve("tools/analyze_metal_gpu_trace.mjs"),
      `--input=${input}`,
      "--process=Godot",
      "--pid=42",
      "--run-id=v86-metal-test",
      "--sequence=C1",
    ]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /A1, B1, B2, or A2/u);
      return true;
    },
  );

  await assert.rejects(
    execFileAsync(process.execPath, [
      path.resolve("tools/analyze_metal_gpu_trace.mjs"),
      `--input=${input}`,
      "--process=godot",
      "--pid=42",
      "--run-id=v86-metal-test",
      "--sequence=A1",
    ]),
    (error) => {
      assert.equal(error.code, 2);
      assert.match(error.stderr, /exact name Godot/u);
      return true;
    },
  );
});

test("separates nested from malformed rows and exposes non-contiguous frame evidence", async (t) => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-metal-trace-integrity-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  const input = path.join(tempDir, "intervals.xml");
  const output = path.join(tempDir, "report.json");
  fs.writeFileSync(
    input,
    `<?xml version="1.0"?>
<trace-query-result>
<row><start-time id="s1">0</start-time><duration id="d1">2000000</duration><gpu-channel-name id="c1" fmt="Vertex">Vertex</gpu-channel-name><gpu-frame-number id="f1" fmt="Frame 1">1</gpu-frame-number><sentinel/><metal-nesting-level id="depth0">0</metal-nesting-level><formatted-label/><process id="p1" fmt="Godot (42)"></process></row>
<row><start-time id="s2">4000000</start-time><duration id="d2">2000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number id="f3" fmt="Frame 3">3</gpu-frame-number><sentinel/><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="s3">7000000</start-time><duration id="d3">1000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number id="f4" fmt="Frame 4">4</gpu-frame-number><sentinel/><metal-nesting-level id="depth1">1</metal-nesting-level><formatted-label/><process ref="p1"/></row>
<row><start-time id="s4">9000000</start-time><gpu-channel-name ref="c1"/><gpu-frame-number id="f5" fmt="Frame 5">5</gpu-frame-number><sentinel/><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="s5">11000000</start-time><duration id="d5">1000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number id="f2" fmt="Frame 2">2</gpu-frame-number><sentinel/><metal-nesting-level ref="depth0"/><formatted-label/><process id="p2" fmt="Godot (99)"></process></row>
<row><start-time id="s6">13000000</start-time><duration id="d6">1000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number ref="missing-frame"/><duration id="lat6">100</duration><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="s7">15000000</start-time><sentinel/><gpu-channel-name ref="c1"/><gpu-frame-number id="f6" fmt="Frame 6">6</gpu-frame-number><duration id="lat7">100</duration><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="s8">17000000</start-time><sentinel/><gpu-channel-name ref="c1"/><sentinel/><duration id="lat8">100</duration><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="s9">19000000</start-time><duration id="d9">1000000</duration><gpu-channel-name ref="c1"/><sentinel/><gpu-frame-number ref="missing-frame"/><duration id="lat9">100</duration><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="s10">21000000</start-time><duration id="d10">1000000</duration><gpu-channel-name ref="c1"/><sentinel/><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="s11">23000000</start-time><duration id="d11">1000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number id="f11" fmt="Frame 11">11</gpu-frame-number><duration ref="missing-latency"/><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="s12">25000000</start-time><duration id="d12">1000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number id="f12" fmt="Frame 12">12</gpu-frame-number><sentinel/><metal-nesting-level ref="depth0"/><formatted-label><process ref="p1"/></formatted-label><process id="p-other" fmt="Other (99)"></process></row>
<row><start-time id="s13">27000000</start-time><duration id="d13">1000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number id="f13" fmt="Frame 13">13</gpu-frame-number><sentinel/><metal-nesting-level ref="depth0"/><formatted-label><process ref="p1"/></formatted-label><process xref="p1"/></row>
<row><start-time id="s14">29000000</start-time><duration id="d14">1000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number id="f14" fmt="Frame 14">14</gpu-frame-number><sentinel/><metal-nesting-level/><formatted-label/><process ref="p1"/></row>
<row><start-time/><duration id="d15">1000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number id="f15" fmt="Frame 15">15</gpu-frame-number><sentinel/><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="illegal-alias" ref="s1"/><duration id="d16">1000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number id="f16" fmt="Frame 16">16</gpu-frame-number><sentinel/><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
<row><start-time id="s17">33000000</start-time><duration id="d17">1000000</duration><gpu-channel-name ref="c1">Contradictory</gpu-channel-name><gpu-frame-number id="f17" fmt="Frame 17">17</gpu-frame-number><sentinel/><metal-nesting-level ref="depth0"/><formatted-label/><process ref="p1"/></row>
</trace-query-result>
`,
  );

  await execFileAsync(process.execPath, [
    path.resolve("tools/analyze_metal_gpu_trace.mjs"),
    `--input=${input}`,
    "--process=Godot",
    "--pid=42",
    "--run-id=v86-metal-integrity",
    "--sequence=B2",
    "--drop-frames=0",
    "--max-frames=2",
    `--out=${output}`,
  ]);

  const report = JSON.parse(fs.readFileSync(output, "utf8"));
  assert.equal(report.sequence_index, 3);
  assert.equal(report.observed_frame_count, 2);
  assert.equal(report.analyzed_frame_count, 2);
  assert.equal(report.analyzed_frames_contiguous, false);
  assert.equal(report.nested_target_rows, 1);
  assert.equal(report.unframed_target_rows, 0);
  assert.equal(report.unframed_target_rows_overlapping_analyzed_window, 0);
  assert.equal(report.malformed_target_rows, 13);
  assert.equal(report.target_event_count, 16);
});

test("fails closed on merged row elements or duplicate XML attributes", async (t) => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-metal-trace-row-layout-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  const input = path.join(tempDir, "intervals.xml");
  const duplicateInput = path.join(tempDir, "duplicate-attribute.xml");
  const duplicateProcessIdInput = path.join(tempDir, "duplicate-process-id.xml");
  const unresolvedProcessInput = path.join(tempDir, "unresolved-process.xml");
  const row = '<row><start-time>0</start-time><duration>1</duration><gpu-channel-name fmt="Vertex">Vertex</gpu-channel-name><gpu-frame-number fmt="Frame 1">1</gpu-frame-number><sentinel/><metal-nesting-level>0</metal-nesting-level><formatted-label/><process fmt="Godot (42)"></process></row>';
  fs.writeFileSync(input, `<?xml version="1.0"?><trace-query-result>${row}${row}</trace-query-result>\n`);
  const command = (source) => [
    path.resolve("tools/analyze_metal_gpu_trace.mjs"),
    `--input=${source}`,
    "--process=Godot",
    "--pid=42",
    "--run-id=v86-row-layout",
    "--sequence=A1",
    "--drop-frames=0",
    "--max-frames=1",
  ];

  await assert.rejects(
    execFileAsync(process.execPath, command(input)),
    (error) => {
      assert.equal(error.code, 1);
      assert.match(error.stderr, /unsupported XML row layout/u);
      return true;
    },
  );

  fs.writeFileSync(
    duplicateInput,
    `<?xml version="1.0"?><trace-query-result>${row.replace('fmt="Frame 1"', 'fmt="Frame 1" fmt="Frame 2"')}</trace-query-result>\n`,
  );
  await assert.rejects(
    execFileAsync(process.execPath, command(duplicateInput)),
    (error) => {
      assert.equal(error.code, 1);
      assert.match(error.stderr, /duplicate XML attribute: fmt/u);
      return true;
    },
  );

  fs.writeFileSync(
    duplicateProcessIdInput,
    `<?xml version="1.0"?><trace-query-result>
${row.replace('<process fmt="Godot (42)"></process>', '<process id="p" fmt="Godot (42)"></process>')}
${row
    .replace('<start-time>0</start-time>', '<start-time>2</start-time>')
    .replace('<gpu-frame-number fmt="Frame 1">1</gpu-frame-number>', '<gpu-frame-number fmt="Frame 2">2</gpu-frame-number>')
    .replace('<process fmt="Godot (42)"></process>', '<process id="p" fmt="Other (99)"></process>')}
${row
    .replace('<start-time>0</start-time>', '<start-time>4</start-time>')
    .replace('<gpu-frame-number fmt="Frame 1">1</gpu-frame-number>', '<gpu-frame-number fmt="Frame 3">3</gpu-frame-number>')
    .replace('<process fmt="Godot (42)"></process>', '<process ref="p"/>')}
</trace-query-result>\n`,
  );
  await assert.rejects(
    execFileAsync(process.execPath, command(duplicateProcessIdInput)),
    (error) => {
      assert.equal(error.code, 1);
      assert.match(error.stderr, /duplicate XML id: p \(process\)/u);
      return true;
    },
  );

  fs.writeFileSync(
    unresolvedProcessInput,
    `<?xml version="1.0"?><trace-query-result>${row.replace(
      '<process fmt="Godot (42)"></process>',
      '<process ref="missing-process"/>',
    )}</trace-query-result>\n`,
  );
  await assert.rejects(
    execFileAsync(process.execPath, command(unresolvedProcessInput)),
    (error) => {
      assert.equal(error.code, 1);
      assert.match(error.stderr, /unresolved process identity rows=1/u);
      return true;
    },
  );
});
