# V8.2 jelly motion lab implementation plan

Date: 2026-09-01

Base: V8.1 exact local candidate at `c136ed9`

Branch: `feature/v8-2-jelly-motion`

## Objective

Move the six authored base cells closer to the glossy translucent reference art
without replacing their stable gameplay collision or deleting any prior visual
version. V8.2 must read as one viscous living mass: a distinct clear membrane,
cohesive moving core, advected suspended inclusions, direction-aware motion,
and complete terminal presentation.

## Preservation boundary

- `IMMUNE_GEL_LOOK=v5`, `v6`, `v7`, `v8`, and `v8_1` remain exact rollback
  selectors.
- V8.1 source, the exact 14-file release set, candidate record, and historical
  archives remain untouched.
- V8.2 uses new output paths and a new candidate record. It must never overwrite
  V8.1 evidence or artifacts.
- Generated Meshy/Tripo experiments remain excluded from shipping PCKs and from
  the default preview/performance path.

## Architecture

### Rendering

- Keep one opaque wet core and the existing one transparent `BodyShell`.
- Add zero-default wet-core uniforms for moving density colour, moving
  roughness, and shared-body-space macro-bubble advection.
- Keep the authored surface relief attached to the membrane; only interior
  fields move.
- Add no raymarch, screen-texture refraction, nested transparent volume, or
  extra full-silhouette pass. Compatibility/Web must remain supported.
- Introduce V8.2 profile values additively after the preserved V8.1 values.
  Tune T/B first, then extend the accepted bounded profile to M/N/A/D.

### Motion and animation

- Retain the existing resolved-motion bridge, start/move/stop controller,
  procedural arbitrary-angle turn shear, contact response, stable collision,
  action priority arbiter, and release-marker timing.
- Retain the exact V8.1 12-clip library.
- V8.2 adds `victory` and `defeat`, producing a 14-clip library.
- Wire core-shock feedback to the existing `hit` clip.
- Route mission completion into the correct terminal clip. Terminal
  presentation owns the animation lane and holds its final pose.

### Tooling

- Default animation/material/performance previews to production authored scenes.
- Keep legacy generated GLBs behind an explicit diagnostic option only.
- Extend smoke coverage for selectors, shader controls, 14 clips, terminal
  priority, production preview identity, collision isolation, and six families.

## Execution sequence

1. Add the V8.2 selector while keeping an explicit V8.1-or-later hardening
   predicate for runtime behavior.
2. Implement the zero-default shader controls and T/B profiles.
3. Add/wire victory, defeat, and production hit presentation.
4. Repair preview/performance tooling so captures exercise authored bodies.
5. Run import and source smoke for V8.2 plus every V5-V8.1 rollback.
6. Capture T/B idle, start, move, stop, turn, attack, skill, hit, victory, and
   defeat evidence. Compare against V8.1 and tune.
7. Extend the accepted V8.2 profile to M/N/A/D; repeat smoke and representative
   visual/performance checks including D and A Relay.
8. Run repository tools, Web/native QA, code review, and release-policy checks.
9. Preserve V8.1 artifacts, then create a separate V8.2 artifact/evidence set
   only when storage gates permit.

## Acceptance gates

- Interior core/bubble centroid visibly moves during idle and movement while
  surface relief remains attached.
- Start, stop, and 180-degree reversal do not reset or pop the flow phase.
- One clear membrane only; no limb sorting seams or added transparent volume.
- V8.1 remains exactly 12 clips; V8.2 is exactly 14. Release markers and their
  callback ordering remain unchanged.
- Victory/defeat hold terminal poses; terminal state rejects lower-priority
  action and duty requests.
- `CollisionShape3D` transform and shape never change, and character root scale
  stays `Vector3.ONE` across every presentation state.
- Six families instantiate the V8.2 profile; A retains Relay movement.
- Hero draw-call delta is at most two and geometry delta at most five percent;
  no new transparent pass. Candidate frame/GPU regressions must remain within
  ten percent or one millisecond of a same-machine V8.1 baseline.
- Official Godot 4.7.2 import/smoke, root tool tests, Web lifecycle, and macOS
  native smoke pass before any V8.2 release-candidate claim.

## Storage hard stop

The source volume began this task with roughly 0.5 GiB free. Compact source
work and screenshots may proceed, but profiling requires at least 2 GiB free
and a four-platform export requires at least 8 GiB free while retaining 5 GiB
afterward. No historical output may be removed or relocated without hash-bound
preservation evidence.
