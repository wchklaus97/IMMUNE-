# IMMUNE Jelly V4 organic membrane cells

Status: implemented and locally verified on 2026-08-30 with Godot 4.6.1.
The project and CI target remain Godot 4.7.2 stable.

## Why V4 exists

The user rejected Jelly V3 as still too smooth and plastic. A direct comparison
against `characters/concepts/CHAR-BASE-T-3d-alt.png` showed that V3 had the right
family colours, silhouette, wet edge, and quieter inclusions, but its small
rounded cells appeared only in isolated highlights. The reference instead has a
continuous, low-amplitude, irregular wet membrane texture.

This pass changes only the shared zero-credit Godot material profile and its
runtime contracts. It submits no Meshy request, consumes no credit, and does not
replace authored geometry.

## Failure analysis and stopped probes

The V3 field used scale 70, radius 0.50-0.72, jitter 0.12, and depth 0.005. On a
gameplay-sized body the spheres were too small and shallow to maintain a visible
normal field. Several controlled probes were stopped and rejected before source
values changed:

- scale 48 with depth 0.010-0.012: broader coverage, still visually smooth;
- scale 44 with depth 0.025-0.040: visible, but the object axes exposed a regular
  horizontal quilt;
- larger cells without a sampling-frame rotation: good close-up contrast, but
  the rows still read as a grid on round heads and limbs.

The accepted probe keeps a bounded eight-corner 3D field, uses scale 48, radius
0.72-0.80, jitter 0.14, softness 0.10, and depth 0.035, then samples it through a
fixed orthonormal frame. That rotation removes the character-axis alignment for
three dot products; it adds no hash, texture lookup, bubble-volume sample, or
screen-space dependency. Smooth inclusion depth is reduced to 0.005 so it does
not compete with the new membrane structure.

## RED/GREEN contract

`tools/smoke.gd` was tightened before changing production profiles. The first
run went RED with:

`CHAR-BASE-M rounded membrane cells must remain visible at gameplay distance`

The final contract requires every Fizzy body to keep:

- scale 44-52 and density at least 0.999;
- depth 0.028-0.042;
- minimum/maximum radii at least 0.70/0.78;
- jitter 0.10-0.16;
- `radius_min - jitter >= 0.56` to avoid visible gaps; and
- `radius_max + jitter < 0.96` to retain the eight-sample lattice safety bound.

The existing zero-thickness, zero-shadow, zero-emission limits remain. The
cells shape wet highlights; they do not become painted rings or glowing spots.
The final smoke is GREEN for T, B, M, N, A, and D.

## Visual evidence

Generated evidence is ignored by Git under `outputs/jelly-v4-lookdev/`:

- `probes/reference-organic-probes.png`: reference and rejected/accepted probes;
- `probes/rotation-before-after.png`: object-axis field versus rotated field;
- `final/closeups/`: six families by six views;
- `final/closeups-face34-contact.png`: final six-family three-quarter close-up;
- `final/mission-1280x720-en/` and `final/mission-contact-sheet.png`;
- `final/combat-1280x720-en/`: six families in fixed, mobile/relay, and boss
  states; and
- `final/combat-fixed-contact.png` plus `final/combat-boss-contact.png`.

All contact sheets were visually inspected. The final field is continuous in
close wet highlights without the rejected horizontal quilting. At mission-card
and combat distances it converges into a restrained wet response rather than
moire. Family colour, ink face, silhouette, transparent boundary, UI framing,
and combat readability remain intact. This is repeatable visual evidence, not a
substitute for the user's final art-direction decision.

## Performance evidence

Compatibility/OpenGL-on-Metal on Apple M4 Pro, ten T bodies at the actual
1920x1080 viewport, 60 warm-up and 300 measured frames, three interleaved trials
per profile. The old V3 constants were supplied as runtime overrides; both cases
therefore include the inexpensive sampling-frame rotation. Values are medians.

| Profile | CPU mean | CPU p95 | Wall mean | Wall p95 | Wall max |
|---|---:|---:|---:|---:|---:|
| V3 constants | 0.979 ms | 1.176 ms | 2.254 ms | 4.401 ms | 6.896 ms |
| V4 constants | 1.021 ms | 1.225 ms | 2.270 ms | 4.477 ms | 7.650 ms |

V4 changes CPU mean/p95 by +4.3%/+4.2% and wall mean/p95 by +0.7%/+1.7% in
this window. Absolute ten-body wall p95 remains below 5 ms. The Compatibility
GPU timer returned zero, so no GPU-time claim is made. This test isolates the
profile change, not the three-dot sampling-frame cost.

The freshly exported whole Web application also passed the compatibility-only
browser gate. Baseline ANGLE/Metal measured 119.744 mean / 99.010 p05 FPS;
4x-CPU SwiftShader measured 12.722 / 10.020 FPS. SwiftShader is a compatibility
stress profile, not a real lower-end hardware benchmark.

## Verification

- Root tool tests: 36/36; playtest template: pass.
- Web research UI: 53/53 and production build: pass.
- Meshy no-network tests: 6/6; no paid request was made.
- Translation CSV: 2 files / 595 rows; catalog localization: 200 nodes / 406
  rows.
- Two Godot imports, six-family smoke, and bilingual overflow: pass.
- T/B/M/N/A/D MISSION-01: 6/6 victories, core 12/12.
- T/B MISSION-01 plus MISSION-06: 4/4 victories, core 12/12.
- Sequential Windows, Linux, macOS, and Web exports plus 14-file artifact
  contract: pass.
- Exported macOS: strict ad-hoc signature, arm64+x86_64, bundle/version/icon,
  and `RELEASE_SMOKE_OK platform=macOS nodes=200`: pass.
- Exported Web baseline plus constrained-software research-to-pause flow: pass.
- GitHub Actions run `33264998027` verifies code commit
  `23f5bdc82c7f9eae0311d6959e532ed06da0b167` on Godot 4.7.2. The main
  validation/export job passed in 10m34s; native Windows, macOS, and Ubuntu
  artifact jobs passed in 18s, 21s, and 17s.
- The exact CI artifact was packaged into a schema-v2 six-person Jelly V4
  campaign with 14 artifacts, 43 checksums, four platform preflights, and a real
  exported-Web rehearsal. Its artifact-set SHA-256 is
  `6d4e94f6b9c0d3f416e3653181b533c3f0403c029da49a31c565c75ba0f7fc24`.

The first macOS staging command was rejected before execution because its
cleanup trap contained `rm -rf`. The workflow stopped, identified the safety
rejection, reused an explicit existing ignored smoke directory, and then passed
all binary checks. No failed generation or partial binary was promoted.

## Remaining gates

- Human side-by-side approval of all six final bodies.
- At least three complete adult reports from the provenance-locked V4 campaign;
  six remain recommended. No synthetic or facilitator rehearsal counts.
- A real agreed lower-end Windows/Web hardware pass.
- Developer ID signing, notarization, storefront metadata, public tag/release,
  and upload require explicit owner authorization and were not performed.
