# Jelly V8 living-slime motion

Date: 2026-09-01  
Source checkpoint: `884198eaf28a6370363e74af8c155122d828da40`
(`feat: add V8 living slime motion`)  
Status: additive local visual version; not pushed, tagged, signed, notarized, or
published

## Outcome

V8 changes the six playable cells from a rigid-looking moving sphere into a
stable gameplay body with a separate living-slime presentation layer.

- Internal gel continues to circulate while the character is idle.
- Walking adds direction and speed to that same uninterrupted flow instead of
  restarting it.
- The visible wet core and clear membrane lag, compress, spread, and settle as
  one viscous mass.
- The V8 move loop is a slow travelling compression wave rather than the older
  gather/jump/land lope.
- `CollisionShape3D` is never deformed. Navigation and collision retain the
  stable sphere used by the existing combat game.

This is a stylized visual simulation, not a soft-body solver or volumetric fluid
simulation. That separation is deliberate: it improves the slime read without
making control, collision, or Web performance depend on unstable soft-body
physics.

## Preserved versions

V8 is selected by `immune/visual/gel_look="v8"` or
`IMMUNE_GEL_LOOK=v8`. The earlier selectors remain runnable and tested.

| Look | Preserved source | Runtime selector |
|---|---|---|
| V5.1 | `2d011b167e79a1d583d368c98ed3c07a41209d3e` | `IMMUNE_GEL_LOOK=v5` |
| V6 | `c45c3eb07e8a944c9205dcf14d13ca4b3260c0df` | `IMMUNE_GEL_LOOK=v6` |
| V7 | `f9cb6609ec00f483cb33fda2223fe6d52ea1f379` | `IMMUNE_GEL_LOOK=v7` |
| V8 | `884198eaf28a6370363e74af8c155122d828da40` | project default or `IMMUNE_GEL_LOOK=v8` |

Every V8-only shader uniform has an inert default. V5/V6/V7 smoke explicitly
requires the flow, cohesive-slime, body-lag, and body-squash controls to stay at
zero. V8 reuses the V7 gummy-glass optical and geometry foundation and then
applies its own motion/detail profile. It does not rewrite V7 values.

The previous r1/r2 captures and the earlier Web builds remain intact. V8 uses
new output locations:

- `outputs/v8-liquid-motion/idle-b/`: preserved first-pass flow evidence;
- `outputs/v8-liquid-motion/slime-r2/`: preserved cohesive-slime prototype;
- `outputs/v8-liquid-motion/slime-r3/`: current verified idle/move motion evidence;
- `outputs/v8-liquid-motion/gameplay-b/`: real combat and portrait captures;
- `outputs/v8-liquid-motion/perf/`: order-varied V7/V8 performance reports;
- `outputs/v8-liquid-motion/web-qa/`: exported-Web lifecycle report;
- `godot/immune/build/history/web-v8/`: separate ignored V8 Web export.

No previous capture, generated model, source checkpoint, or release directory
was removed or overwritten. No Meshy generation was submitted and no paid
generation credit was consumed.

## Motion architecture

### Continuous internal mass

`wet_gel.gdshader` uses Godot's uninterrupted `TIME` clock to advect only the
object-space coordinates used by internal inclusions and fibers. The authored
outer micro-height remains attached to the membrane, preventing the skin from
looking as if it slides across the character.

A low-frequency analytic field combines three broad sine/cosine lobes into a
cohesive volume and narrow folding ridge. This makes the dominant internal cue
look like one moving slime mass rather than many independent flecks. V8 reduces
the inherited granular fleck/fiber energy only in its own profile so those small
details remain subordinate.

### Movement overlay

`character_root.gd` converts world velocity into local speed and direction. It
eases acceleration, deceleration, and direction independently, then sends only
changed runtime values to per-instance wet-gel and shell materials. Stopping or
turning does not reset shader time.

A damped visual spring targets a small displacement opposite travel direction.
Acceleration adds a bounded vertical squash with lateral volume compensation.
The same lag and squash uniforms are applied to the wet core and every clear
membrane pass so the shell cannot detach from the body.

The locomotion state uses start/stop hysteresis. Mobile duty remains in `idle`
while stationary, enters `move` only above the movement threshold, and returns
to idle after stopping. One-shot attack/hit/duty animations are not interrupted.

### V8 move loop

`gel_anim.gd` keeps the exact 0.92-second V5/V6/V7 move animation and gives V8 a
separate 1.12-second loop. V8 limits vertical root travel to a small grounded
range and transfers volume through two slow squash/stretch waves with delayed
limb spread and mass lag.

The shader spring and animation solve different parts of the read:

1. The animation provides the large, readable compression wave.
2. The spring supplies direction-aware drag and acceleration response.
3. The fragment field keeps the internal slime circulating through both states.
4. The unchanged collision sphere owns gameplay contact.

## Automated contracts

The Godot smoke suite now verifies all six families:

- V8 move length and bounded vertical travel;
- non-zero idle-flow/slime profile values and deterministic per-family phase;
- shader use of uninterrupted time, internal coordinate advection, cohesive
  slime volume, and direction-aware vertex lag;
- per-instance wet-core and clear-shell material discovery;
- movement blend, local direction, negative mass lag, and acceleration squash;
- two-second decay back to a settled idle state without residual wobble;
- identical core/shell deformation state;
- unchanged collision transform and shape while visual viscosity runs;
- inert V8 controls and exact historical move length under V5/V6/V7.

`shot.gd` adds a non-destructive real-time capture mode:
`--flow-seconds` records actual elapsed shader time, while optional
`--flow-velocity` exercises the production velocity overlay without moving the
camera-framed subject.

## Visual evidence

The current B-family r3 verification strips contain four real-time samples at 0.25, 1.0,
1.75, and 2.5 seconds.

- Idle frame 0 versus frame 3 has whole-frame mean absolute luma difference
  `0.018591`; the broad internal bright mass visibly changes position without
  input.
- A diagnostic 6%-luma silhouette measurement over the cropped old r2 move
  samples ranged only 399-407 px in height. The new r3 samples range 372-439 px,
  showing the intended compression/re-expansion cycle. This diagnostic supports
  visual review; it is not a human quality score.
- All eight source PNGs pass size, reopen, visibility, colour-range, and luma
  variance checks. The derived idle and move strips are stored beside them.

The real 1920x1080 B / MISSION-01 gameplay harness also passes fixed, mobile,
boss, pause, portrait lifecycle, duty identity, stable live-player scale,
collision-layer, camera, safe-area, and no-HUD-overlap contracts. At gameplay
distance the silhouette motion is the primary cue; the internal flow is most
legible in the combat portrait and close review shots.

## Local performance sentinel

Ten B bodies were rendered at 1920x1080 after warm-up. The second pair reversed
run order. Values are local CPU/wall measurements only.

| Pair | Look | Frames | CPU mean / p95 | Wall mean / p95 |
|---|---|---:|---:|---:|
| 1 | V7 | 600 | 1.102 / 1.596 ms | 3.021 / 4.579 ms |
| 1 | V8 | 600 | 0.870 / 0.993 ms | 2.625 / 3.403 ms |
| 2 | V8 | 1,200 | 0.891 / 1.052 ms | 2.555 / 3.320 ms |
| 2 | V7 | 1,200 | 0.960 / 1.209 ms | 2.600 / 3.498 ms |

V8 shows no measured regression in either order-varied pair. The Compatibility
Metal viewport GPU timer returned zero for every run, so this is not GPU parity
or minimum-spec hardware evidence.

## Exported-Web validation

The first export attempt failed before writing because Godot does not create a
new target directory. The workflow stopped, diagnosed the exact error, created
only `build/history/web-v8/`, and reran the same export successfully. Future
new-version exports should pre-create their target directory.

The exported V8 Web build completes all eight ordered events from engine ready
through research, B selection, combat, mobile duty, pause open, and pause close.

| Profile | Renderer | Mean / p05 FPS | Result |
|---|---|---:|---|
| Baseline | ANGLE Metal, Apple M4 Pro | 60.003 / 59.88 | pass |
| Compatibility stress | 4x CPU + SwiftShader | 12.593 / 11.99 | pass |

The stress profile is compatibility evidence, not a physical low-end-device
benchmark. Both profiles pass resource, canvas-fit, event-order, console, and
two-second frame-watchdog contracts.

## Validation summary

All of the following pass locally with official Godot
`4.6.1.stable.official.14d19694e`:

- clean import and `git diff --check`;
- default V8 content smoke;
- explicit V5, V6, and V7 rollback smoke;
- 58/58 root tool tests;
- anonymous playtest-template validation;
- bilingual research/HUD overflow contract;
- r3 idle and moving real-time capture content checks;
- fixed/mobile/boss/pause gameplay presentation contract;
- two order-varied V7/V8 performance pairs;
- separate Web export and two-profile browser lifecycle QA.

The repository's previously documented release baseline used Godot 4.7.2.
Therefore this V8 checkpoint still requires a clean 4.7.2 revalidation before it
can replace any exact release candidate. Human motion/texture preference,
minimum-spec Windows/Deck/phone testing, native Windows/Linux smoke,
signing/notarization, Steamworks review, and owner-authorized publication remain
open. V8 is a tested local development checkpoint, not a public release.

## Reproduction

```sh
godot --headless --path godot/immune --import
godot --headless --path godot/immune --script res://tools/smoke.gd
IMMUNE_GEL_LOOK=v5 godot --headless --path godot/immune --script res://tools/smoke.gd
IMMUNE_GEL_LOOK=v6 godot --headless --path godot/immune --script res://tools/smoke.gd
IMMUNE_GEL_LOOK=v7 godot --headless --path godot/immune --script res://tools/smoke.gd

godot --path godot/immune --resolution 1024x1024 res://tools/shot.tscn -- \
  --scene=res://tools/anim_preview.tscn \
  --out=<absolute-new-output-directory> --tag=b-v8-slime-r3-move \
  --anim=move --flow-seconds=0.25,1.0,1.75,2.5 \
  --flow-velocity=3,0,0 --family=B --body=blockout --ground=0

mkdir -p godot/immune/build/history/web-v8
godot --headless --path godot/immune --export-release Web \
  build/history/web-v8/index.html
npm run test:web-release -- \
  --artifacts=godot/immune/build/history/web-v8 \
  --out=outputs/v8-liquid-motion/web-qa \
  --duration-ms=4000 --gate-mode=compatibility-only
```
