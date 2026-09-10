import assert from "node:assert/strict";
import test from "node:test";

import {
  EXPECTED_ANIMATIONS,
  parseAnimationGateOutput,
  parseV86AnimationArgs,
  validateGodotVersion,
} from "./validate_v8_6_animations.mjs";

const VALID_REPORT = {
  schema: 2,
  selector: "v8_6",
  profile: "reference_convergence",
  sculpt_path: "res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb",
  sculpt_sha256: "3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3",
  sculpt_resource_name: "V8.6-AuthoredSculpt-T-r7-2",
  sculpt_aabb_position: [-0.82, 0, -0.5],
  sculpt_aabb_size: [1.64, 1.46, 1],
  fallback_nodes: 0,
  animation_count: 14,
  animations: EXPECTED_ANIMATIONS,
  sampled_clips: 14,
  sampled_poses: 154,
  min_scale: 0.82,
  max_scale: 1.14,
  move_scale_span: 0.07,
  idle_flow_speed: 0.28,
  idle_slime_strength: 0.82,
  moving_mix: 0.99,
  moving_lag: 0.05,
  moving_squash: 0.03,
  settling_lag: 0.02,
  settled_mix: 0.01,
  settled_lag: 0.004,
  settled_squash: 0.003,
  wet_materials: 1,
  shell_materials: 1,
  collision_unchanged: true,
  detached_meshes: 0,
};

test("parseV86AnimationArgs accepts one optional Godot binary", () => {
  assert.deepEqual(parseV86AnimationArgs([]), { godot: "" });
  assert.deepEqual(parseV86AnimationArgs(["--godot=/tmp/Godot"]), { godot: "/tmp/Godot" });
  assert.throws(() => parseV86AnimationArgs(["--godot="]), /non-empty/u);
  assert.throws(() => parseV86AnimationArgs(["--wat"]), /unknown option/u);
  assert.throws(
    () => parseV86AnimationArgs(["--godot=a", "--godot=b"]),
    /only once/u,
  );
});

test("validateGodotVersion accepts only the pinned 4.7.2 stable editor", () => {
  assert.equal(
    validateGodotVersion("4.7.2.stable.official.ed1daf0bf\n"),
    "4.7.2.stable.official.ed1daf0bf",
  );
  assert.throws(() => validateGodotVersion("4.6.1.stable.official.14d19694e"), /4\.7\.2/u);
  assert.throws(() => validateGodotVersion("4.7.2.dev.custom"), /official stable/u);
});

test("parseAnimationGateOutput accepts a complete deterministic report", () => {
  const output = `Godot Engine v4.7.2\nV8_6_ANIMATION_GATE_OK ${JSON.stringify(VALID_REPORT)}\n`;
  assert.deepEqual(parseAnimationGateOutput(output), VALID_REPORT);
});

test("parseAnimationGateOutput rejects incomplete or contradictory evidence", () => {
  assert.throws(() => parseAnimationGateOutput("no marker"), /success marker/u);
  assert.throws(
    () => parseAnimationGateOutput(
      `V8_6_ANIMATION_GATE_OK ${JSON.stringify({ ...VALID_REPORT, animation_count: 13 })}`,
    ),
    /animation_count/u,
  );
  assert.throws(
    () => parseAnimationGateOutput(
      `V8_6_ANIMATION_GATE_OK ${JSON.stringify({ ...VALID_REPORT, animations: [...EXPECTED_ANIMATIONS].reverse() })}`,
    ),
    /inventory drifted/u,
  );
  assert.throws(
    () => parseAnimationGateOutput(
      `V8_6_ANIMATION_GATE_OK ${JSON.stringify({ ...VALID_REPORT, idle_flow_speed: 0 })}`,
    ),
    /idle internal flow/u,
  );
  assert.throws(
    () => parseAnimationGateOutput(
      `V8_6_ANIMATION_GATE_OK ${JSON.stringify({ ...VALID_REPORT, moving_lag: 0 })}`,
    ),
    /viscous lag/u,
  );
  assert.throws(
    () => parseAnimationGateOutput(
      `V8_6_ANIMATION_GATE_OK ${JSON.stringify({ ...VALID_REPORT, move_scale_span: 0 })}`,
    ),
    /move clip/u,
  );
  assert.throws(
    () => parseAnimationGateOutput(
      `V8_6_ANIMATION_GATE_OK ${JSON.stringify({ ...VALID_REPORT, detached_meshes: 1 })}`,
    ),
    /detached meshes/u,
  );
});

test("parseAnimationGateOutput rejects any sculpt other than exact R7.2", () => {
  const rejectedIdentityEvidence = [
    [
      { sculpt_path: "res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r6.glb" },
      /sculpt_path/u,
    ],
    [
      { sculpt_sha256: "6fa587a26af3a248713986fd7614c028ae787a11cf22c310d89ac97d590dc770" },
      /sculpt_sha256/u,
    ],
    [{ sculpt_resource_name: "V8.6-AuthoredSculpt-T-r6" }, /sculpt_resource_name/u],
    [{ sculpt_aabb_position: [-0.75, 0, -0.5] }, /sculpt_aabb_position/u],
    [{ sculpt_aabb_size: [1.5, 1.46, 1] }, /sculpt_aabb_size/u],
    [{ fallback_nodes: 1 }, /fallback_nodes/u],
  ];

  for (const [overrides, expectedError] of rejectedIdentityEvidence) {
    assert.throws(
      () => parseAnimationGateOutput(
        `V8_6_ANIMATION_GATE_OK ${JSON.stringify({ ...VALID_REPORT, ...overrides })}`,
      ),
      expectedError,
    );
  }
});
