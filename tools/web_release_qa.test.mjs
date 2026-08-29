import assert from "node:assert/strict";
import test from "node:test";

import {
  classifyRequestFailures,
  summarizeFrameIntervals,
  validateWebQaReport,
} from "./web_release_qa.mjs";

function profile(id, overrides = {}) {
  return {
    id,
    viewport: { width: 1280, height: 720 },
    cpu_throttle_rate: id === "constrained-software" ? 4 : 1,
    renderer: {
      webgl_version: "WebGL 2.0",
      unmasked_renderer: id === "constrained-software" ? "ANGLE SwiftShader" : "ANGLE Metal",
      software: id === "constrained-software",
    },
    resources: {
      required: ["index.html", "index.js", "index.pck", "index.wasm"],
      failures: [],
    },
    events: [
      { event: "engine_ready" },
      { event: "research_ready" },
      { event: "mission_select_ready" },
      { event: "combat_ready", family: "B", mission: "MISSION-01" },
      { event: "duty_changed", duty: "mobile" },
      { event: "pause_changed", open: true },
      { event: "pause_changed", open: false },
    ],
    frames: {
      sample_count: 180,
      duration_ms: 3_000,
      mean_fps: id === "constrained-software" ? 18 : 58,
      p05_fps: id === "constrained-software" ? 9 : 48,
      p95_frame_ms: id === "constrained-software" ? 111 : 21,
      max_frame_ms: id === "constrained-software" ? 111 : 21,
      long_frame_ratio: id === "constrained-software" ? 0.08 : 0.01,
      compatibility_stall_ratio: 0,
    },
    fit: {
      can_scroll_x: false,
      can_scroll_y: false,
      canvas_inside_viewport: true,
      canvas_width: 1280,
      canvas_height: 720,
    },
    console: { errors: [], warnings: [], page_errors: [], request_failures: [] },
    screenshots: ["research.png", "mission.png", "combat.png", "pause.png"],
    ...overrides,
  };
}

test("summarizes frame cadence without hiding long frames", () => {
  const summary = summarizeFrameIntervals([16, 17, 16, 18, 100, 1_600]);
  assert.equal(summary.sample_count, 6);
  assert.equal(summary.duration_ms, 1_767);
  assert.equal(summary.p95_frame_ms, 1_600);
  assert.equal(summary.max_frame_ms, 1_600);
  assert.equal(summary.long_frame_count, 2);
  assert.equal(summary.long_frame_ratio, 0.333);
  assert.equal(summary.compatibility_stall_count, 1);
  assert.equal(summary.compatibility_stall_ratio, 0.167);
  assert.ok(summary.mean_fps > 3 && summary.mean_fps < 4);
  assert.equal(summary.p05_fps, 0.625);
});

test("does not treat an aborted Godot preload as a failure after a successful response", () => {
  const result = classifyRequestFailures([
    { url: "http://127.0.0.1/index.wasm", error: "net::ERR_ABORTED" },
    { url: "http://127.0.0.1/missing.png", error: "net::ERR_FAILED" },
  ], new Map([["index.wasm", 200]]));
  assert.deepEqual(result.cancellations, ["http://127.0.0.1/index.wasm: net::ERR_ABORTED"]);
  assert.deepEqual(result.failures, ["http://127.0.0.1/missing.png: net::ERR_FAILED"]);
});

test("accepts complete baseline and constrained-software evidence", () => {
  const report = {
    schema_version: 2,
    evidence_class: "compatibility-stress-not-hardware-benchmark",
    gate_mode: "local-performance-sentinel",
    build: { version: "0.4.0", artifact_root: "godot/immune/build/releases/web" },
    profiles: [profile("baseline"), profile("constrained-software")],
  };
  assert.doesNotThrow(() => validateWebQaReport(report));
});

test("rejects a report that never proves duty and pause transitions", () => {
  const incomplete = profile("baseline", {
    events: [
      { event: "engine_ready" },
      { event: "research_ready" },
      { event: "mission_select_ready" },
      { event: "combat_ready", family: "B", mission: "MISSION-01" },
    ],
  });
  assert.throws(
    () => validateWebQaReport({
      schema_version: 2,
      evidence_class: "compatibility-stress-not-hardware-benchmark",
      gate_mode: "local-performance-sentinel",
      build: { version: "0.4.0", artifact_root: "godot/immune/build/releases/web" },
      profiles: [incomplete, profile("constrained-software")],
    }),
    /duty_changed|pause_changed/u,
  );
});

test("rejects duplicate required resources and unexpected browser warnings", () => {
  const invalidBaseline = profile("baseline", {
    resources: {
      required: ["index.html", "index.html", "index.pck", "index.wasm"],
      failures: [],
    },
    console: { errors: [], warnings: ["unexpected warning"], page_errors: [], request_failures: [] },
  });
  assert.throws(
    () => validateWebQaReport({
      schema_version: 2,
      evidence_class: "compatibility-stress-not-hardware-benchmark",
      gate_mode: "local-performance-sentinel",
      build: { version: "0.4.0" },
      profiles: [invalidBaseline, profile("constrained-software")],
    }),
    /required resources|warning/u,
  );
});

test("accepts complete software-rendered hosted CI evidence only in compatibility mode", () => {
  const expectedSoftwareWarning = "[.WebGL-0x123]GL Driver Message (OpenGL, Performance, GL_CLOSE_PATH_NV, High): GPU stall due to ReadPixels";
  const softwareBaseline = profile("baseline", {
    renderer: {
      webgl_version: "WebGL 2.0",
      unmasked_renderer: "ANGLE Vulkan SwiftShader Device (Subzero)",
      software: true,
    },
    frames: {
      sample_count: 5,
      duration_ms: 4_099.9,
      mean_fps: 1.22,
      p05_fps: 1.154,
      p95_frame_ms: 866.7,
      max_frame_ms: 866.7,
      long_frame_ratio: 1,
      compatibility_stall_ratio: 1,
    },
    console: { errors: [], warnings: [expectedSoftwareWarning], page_errors: [], request_failures: [] },
  });
  const softwareConstrained = profile("constrained-software", {
    frames: {
      sample_count: 6,
      duration_ms: 4_333.1,
      mean_fps: 1.385,
      p05_fps: 1.364,
      p95_frame_ms: 733.3,
      max_frame_ms: 733.3,
      long_frame_ratio: 1,
      compatibility_stall_ratio: 1,
    },
  });
  const report = {
    schema_version: 2,
    evidence_class: "compatibility-stress-not-hardware-benchmark",
    gate_mode: "compatibility-only",
    build: { version: "0.4.0" },
    profiles: [softwareBaseline, softwareConstrained],
  };

  assert.doesNotThrow(() => validateWebQaReport(report));
  assert.throws(
    () => validateWebQaReport({ ...report, gate_mode: "local-performance-sentinel" }),
    /insufficient frame samples|heartbeat|long-frame/u,
  );
});

test("compatibility mode rejects unexpected warnings and a frame watchdog breach", () => {
  const invalidBaseline = profile("baseline", {
    renderer: {
      webgl_version: "WebGL 2.0",
      unmasked_renderer: "ANGLE SwiftShader",
      software: true,
    },
    frames: {
      sample_count: 4,
      duration_ms: 4_300,
      mean_fps: 0.93,
      p05_fps: 0.45,
      p95_frame_ms: 2_100,
      max_frame_ms: 2_100,
      long_frame_ratio: 1,
      compatibility_stall_ratio: 1,
    },
    console: { errors: [], warnings: ["WebGL context lost"], page_errors: [], request_failures: [] },
  });
  assert.throws(
    () => validateWebQaReport({
      schema_version: 2,
      evidence_class: "compatibility-stress-not-hardware-benchmark",
      gate_mode: "compatibility-only",
      build: { version: "0.4.0" },
      profiles: [invalidBaseline, profile("constrained-software")],
    }),
    /unexpected browser warnings|frame watchdog/u,
  );
});
