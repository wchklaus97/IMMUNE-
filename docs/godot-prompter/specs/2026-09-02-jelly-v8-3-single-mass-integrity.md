# Jelly V8.3 single-mass integrity result

Date: 2026-09-02

Foundation: V8.2 clean checkpoint `400c4f5`

Plan checkpoint: `2be7295`

Branch: `feature/v8-3-single-mass-integrity`

Status: implemented local candidate; not pushed, tagged, exported, signed,
notarized, uploaded to Steam, or published

## Outcome

V8.3 replaces the production character's intersecting body, arm, foot, and
crown primitives with one continuous watertight surface per family. The wet
core and thin clear membrane share that exact mesh, so animation cannot open a
seam between parts. Family cues are sculpted into the connected surface instead
of attached as independent blobs.

The clean-volume profile removes every detail that could read as a small cell or
fragment: macro bubbles, microbubbles, inclusions, flecks, duty wheels, the A
relay dish, and duty-switch particles. Eyes and mouth remain as thin, inset face
marks. Idle flow, locomotion flow, lag, squash, contact response, turn shear,
combat animation, collision, and all fourteen V8.2 clips remain available.

The project and CI default are now:

```text
immune/visual/gel_look="v8_3"
```

Every prior look remains an explicit runtime rollback:

```text
IMMUNE_GEL_LOOK=v5
IMMUNE_GEL_LOOK=v6
IMMUNE_GEL_LOOK=v7
IMMUNE_GEL_LOOK=v8
IMMUNE_GEL_LOOK=v8_1
IMMUNE_GEL_LOOK=v8_2
```

No prior source checkpoint, selector, generated model, screenshot directory, or
release artifact was deleted or overwritten.

## Root causes addressed

1. The former authored body was several intersecting spheres. Large squash,
   pitch, or turn samples could expose their intersections and make an arm,
   foot, or D crown lobe read as a detached cell.
2. The V8.2 macro-bubble field deliberately drew cell-like interior circles,
   which conflicted with the requested clean single-character read.
3. `LocomotionKit` built four independent wheel meshes and A built a separate
   `RelayDish`. At gameplay distance these read as small cells below or beside
   the character.
4. The duty burst placeholder was logically harmless but remained a future path
   for loose dot geometry.
5. Protruding spherical eyes could cross the silhouette at three-quarter attack
   angles and resemble a floating black pellet.

## Geometry contract

`single_mass_blob_mesh.gd` builds a deterministic indexed `ArrayMesh` for each
family:

- 96 radial segments and 48 rings;
- one shared top vertex, 47 shared intermediate rings, and one shared bottom
  vertex;
- 4,514 vertices, 27,072 indices, and 9,024 triangles;
- one surface with generated normals;
- every undirected edge is used exactly twice;
- Euler characteristic is 2;
- resource identity is `V8.3-SingleMass-<family>`.

The smoke gate verifies index validity, non-degenerate triangles, closed
two-manifold edge use, and the sphere-topology Euler characteristic. `Body` and
`BodyShell` must reference the same mesh resource; the shell is only a 1.006
scale envelope. The authored visual tree contains exactly five mesh instances:
wet body, membrane, two inset eyes, and one inset mouth. It rejects any extra
`Arm*`, `Foot*`, `Crown*`, `Bubble*`, duty-kit mesh, or visible/emitting swap
particle.

T, B, M, N, A, and D use separate bounded profile values for body radius,
connected side lobes, lower lobes, skirt, and top shaping. D's top identity is
part of the same surface instead of five crown spheres. A remains a hover family
without allocating a relay attachment.

## Material and face contract

The V8.3 profile inherits the accepted V8.2 core flow and membrane response but
sets all bubble, microbubble, inclusion, and authored fleck budgets to zero.
Restrained caustic and fibre response keeps the interior alive without drawing
discrete particles. Runtime body-deformation strength is 0.64; core and shell
receive the same lag, squash, turn, and contact values.

Eyes use a 0.040 depth scale and remain within 0.18 body-space X. The mouth is
flatter, darker, and inset; V8.3 does not allocate eye or mouth rim geometry.
Smoke enforces the eye bounds and the exact total mesh-instance count so later
look-dev cannot silently reintroduce floating pellets.

## Motion and non-collapse contract

V8.3 retains these fourteen clips:

```text
idle, plant, uproot, move, hit, attack, relay_open, relay_close,
move_start, move_stop, relay_glide, skill_cast, victory, defeat
```

Every clip is sampled at 72 Hz in smoke. Every `CoreMesh` scale component must
stay in 0.80–1.22 and sampled volume must stay in 0.95–1.04. Runtime lag is
limited to 0.13, runtime squash to 0.09, and shader deformation to 0.64. The
V8.3 defeat pose keeps at least 0.86 height with restrained 8-degree pitch and
6-degree roll, so failure reads as a supported viscous settle rather than a
collapsed or torn body. Gameplay collision shape and transform remain fixed.

## Gameplay cadence regression and correction

The release matrix exposed a pre-existing V8.2 problem that static visual smoke
could not detect. MISSION-06/T deterministically failed at 63.283 seconds with
core 0/12, 90 hits, only 10 enemies defeated, and no expedition/duty phase. An
explicit V8.2 control reproduced the exact same numbers, proving the new mesh
was not the cause. Historical pre-motion reports completed the same scenario
with 139–141 shots.

The cause was presentation ownership: T's 0.55-second fixed cadence could be
paused by active, hit, or duty recovery animations. V8.3 now lets only T release
a due basic token through the existing `combat_action_released` boundary while
a stronger pose remains on screen. Active wind-up retains ownership until its
own 0.48-second hit has committed; the overlay is limited to T so B's slower
one-second cadence and multi-target active selection remain unchanged. Damage,
cooldowns, enemy profiles, mission data, projectile resolution, and V5–V8.2
arbitration were not modified.

The final focused MISSION-06/T run passed at 97.083 seconds with 151/151 hits and
core 6/12. The final CI-equivalent four-run matrix passed MISSION-01 and
MISSION-06 for T and B with `BALANCE_MATRIX_OK runs=4`.

## Visual evidence

Every iteration remains available:

- `outputs/v8.3-single-mass/review-r1/`: rejected first connected silhouette;
- `review-r2/`: softer integrated lobe pass;
- `review-r3/`: embedded face pass; rejected after move capture exposed wheels;
- `review-r4/`: duty geometry removed and terminal stress captured;
- `review-r5/`: softer side/lower kernels and safer defeat pose;
- `review-r6/`: accepted inset-eye static, move, and attack evidence.

Accepted comparison files include:

- `outputs/v8.3-single-mass/review-r6/all-six-front-r6.png`;
- `outputs/v8.3-single-mass/review-r6/all-six-attack-strips-r6.png`;
- `outputs/v8.3-single-mass/review-r6/T-move-strip-r6.png`;
- `outputs/v8.3-single-mass/review-r6/r5-r6-eye-comparison.png`.

The first real-game A capture is preserved below the Godot project at
`godot/immune/outputs/v8.3-single-mass/gameplay-r1/`. Fixed, relay/mobile, and
boss screenshots plus the reopened presentation report all passed. Relay duty
kept its gameplay/HUD state but drew no dish or loose character geometry.
The accepted absolute-path rerun is
`outputs/v8.3-single-mass/gameplay-release/`; it preserves the same three stages
and a five-sample verified presentation report without replacing the first run.

An attempted headless `shot.tscn` capture stalled at `frame_post_draw`. The
three owned test processes were stopped without touching other sessions. The
workflow was corrected to use headed Godot for render captures; all subsequent
R1–R6 and gameplay captures completed normally.

## Performance evidence

The headed 1920×1080 Compatibility/OpenGL-on-Metal harness measured ten T
characters for 240 frames after a 60-frame warm-up:

| Candidate | Visible meshes | CPU mean | Wall mean | Wall p95 |
|---|---:|---:|---:|---:|
| V8.2 gel control | 100 | 0.766 ms | 2.642 ms | 3.742 ms |
| V8.3 gel | 50 | 0.664 ms | 1.921 ms | 3.586 ms |
| V8.3 standard sentinel | 50 | 0.817 ms | 2.175 ms | 3.699 ms |

Reports are preserved in `outputs/v8.3-single-mass/perf/`. This backend returned
zero for every viewport GPU timing sample, so these results are CPU/wall and
geometry evidence only; they are not presented as measured GPU time.

## Verification completed

Verified locally with official Godot
`4.6.1.stable.official.14d19694e`:

- warm import with no script, parse, compile, or engine error;
- default V8.3 six-family smoke;
- explicit V5, V6, V7, V8, V8.1, and V8.2 rollback smokes;
- exact topology, clean-detail, inset-face, collision, material, fourteen-clip,
  terminal-pose, release-marker, and T cadence-overlay contracts;
- headed R1–R6 visual captures and manual review;
- real-game A fixed, relay/mobile, boss, portrait, HUD, and presentation report;
- ten-character V8.2/V8.3/standard performance probes;
- CI-equivalent four-run balance matrix, including deterministic MISSION-06/T;
- six-family MISSION-01 gameplay matrix;
- screenshot/provenance contract and 1920×1080 bilingual overflow contract;
- 64 repository release/tool tests and playtest-template validation;
- 53 research-network UI tests and successful single-file UI build;
- translation CSV, 200-node catalog localization, nine release-audio assets,
  and seventeen Steam graphical assets;
- `git diff --check` and Godot editor parse/import validation.

## Honest remaining gates

This source candidate fixes the reported character-integrity issue, but it is
not evidence that the game is already published or 100% Steam-ready:

- local Godot is 4.6.1; the repository's required official 4.7.2 CI run remains
  remote/open;
- local free disk is about 2.6 GiB, below the retained-output safety threshold
  for a new four-platform export;
- the local backend exposes no usable GPU timer, and no lower-end Windows,
  Steam Deck, or physical mobile run was performed here;
- signing, notarization, native smoke, store upload, owner review, and owner
  publication authorization remain external release gates;
- V8.3 resolves fragmentation and loose-cell cues, but the procedural art is
  still a stylized interpretation rather than a pixel-identical reconstruction
  of the reference banner.

Passing source, visual, balance, and performance gates is implementation
evidence. It does not grant publishing authority.
