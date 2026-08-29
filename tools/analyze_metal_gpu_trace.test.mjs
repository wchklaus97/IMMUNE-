import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

test("groups overlapping top-level Metal events into target-process frame spans", async (t) => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "immune-metal-trace-"));
  t.after(() => fs.rmSync(tempDir, { recursive: true, force: true }));
  const input = path.join(tempDir, "intervals.xml");
  const output = path.join(tempDir, "report.json");
  fs.writeFileSync(
    input,
    `<?xml version="1.0"?>
<trace-query-result>
<row><start-time id="s1">0</start-time><duration id="d1">2000000</duration><gpu-channel-name id="c1" fmt="Vertex">Vertex</gpu-channel-name><gpu-frame-number id="f1" fmt="Frame 1">1</gpu-frame-number><metal-nesting-level id="depth0">0</metal-nesting-level><process id="p1" fmt="godot (42)"></process></row>
<row><start-time id="s2">1000000</start-time><duration id="d2">3000000</duration><gpu-channel-name id="c2" fmt="Fragment">Fragment</gpu-channel-name><gpu-frame-number ref="f1"/><metal-nesting-level ref="depth0"/><process ref="p1"/></row>
<row><start-time id="s3">10000000</start-time><duration id="d3">5000000</duration><gpu-channel-name ref="c1"/><gpu-frame-number id="f2" fmt="Frame 2">2</gpu-frame-number><metal-nesting-level ref="depth0"/><process ref="p1"/></row>
<row><start-time id="s4">12000000</start-time><duration id="d4">6000000</duration><gpu-channel-name ref="c2"/><gpu-frame-number ref="f2"/><metal-nesting-level ref="depth0"/><process ref="p1"/></row>
</trace-query-result>
`,
  );

  const { stdout } = await execFileAsync(process.execPath, [
    path.resolve("tools/analyze_metal_gpu_trace.mjs"),
    `--input=${input}`,
    "--process=godot",
    "--pid=42",
    "--drop-frames=1",
    `--out=${output}`,
  ]);

  assert.match(stdout, /METAL_GPU_ANALYSIS_OK/);
  const report = JSON.parse(fs.readFileSync(output, "utf8"));
  assert.equal(report.observed_frame_count, 2);
  assert.equal(report.analyzed_frame_count, 1);
  assert.equal(report.gpu_frame_span_ms.mean, 8);
  assert.deepEqual(report.channel_event_counts, { Fragment: 2, Vertex: 2 });
});
