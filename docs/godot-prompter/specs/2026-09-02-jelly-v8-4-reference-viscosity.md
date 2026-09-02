# Jelly V8.4 Reference Viscosity — Implemented Specification

Status: opt-in development candidate, verified 2026-09-02

Selected checkpoint: R24

Commercial default: V8.3

## Delivered outcome

V8.4 changes the six immune characters from a rigid-looking translated blob to
a bounded viscous presentation. Internal colour and roughness fields continue
moving at idle, locomotion increases their advection without restarting phase,
and start/stop clips transfer volume gradually instead of bouncing the whole
body as a solid ball. The render deformation is cosmetic; gameplay collision
remains stable.

The character contract is deliberately strict:

- one substantial connected body per character;
- one coincident, thin membrane pass rather than loose bubbles or cells;
- zero particle systems and zero detached decorative inclusions;
- face marks stay attached to the deforming surface and are gated out at the
  side/back instead of floating through the silhouette;
- bounded deformation prevents collapse or extreme squash;
- no screen-texture read or raymarch in the Compatibility/Web shader path.

## T single-mass geometry

Exact `v8_4` T loads
`characters/base_t/CHAR-BASE-T-v8-4-single-mass-r1.glb` at runtime. The local,
reproducible builder is `tools/meshy/build_t_single_mass_body.py`.

| Property | Audited value |
| --- | ---: |
| GLB SHA-256 | `169394df640604f6d5e1302f5ff82b444b088e924125b971441e713185b6f7bb` |
| Builder SHA-256 | `54d3a727fe6dea2347db3f1e82279ff12686d0d01752c20ba13353d1cfc67f4b` |
| Vertices | 2,253 |
| Triangles | 4,502 |
| Connected regions | 1 |
| Boundary edges | 0 |
| Non-manifold edges | 0 |
| GLB nodes / meshes / primitives | 1 / 1 / 1 |

The builder welds attribute seams, keeps the largest body surface, fills the
three former face-insert holes, triangulates, normalizes, and regenerates
normals. Rebuilding produced the same GLB hash.

Assimp writes the final conversion to a same-filesystem temporary candidate.
The builder validates its GLB 2.0 header and declared byte length before an
atomic promotion, so a failed conversion cannot leave a partial final file or
block a clean retry.

## Material and flow architecture

The V8.4 material profile adds broad, continuous laminar folds, an advected
slime/core field, mip-filtered wet micro-relief, a restrained transparent
membrane, and a shared low-frequency body-space wobble. `TIME` is never reset by
an animation transition; gameplay state only changes bounded speed, warp, and
direction overlays.

R24 is intentionally the final source state:

- body exposure scale `0.86`;
- transmission strength `1.28`, tint `0.38`;
- studio card broadening `0.72`, tail cut `0.32`;
- liquid-flow strength `0.82`, idle speed `0.28`, move boost `0.42`;
- laminar strength `0.78`; shared wobble amplitude `0.012`;
- authored caustic and fibre fields remain zero to avoid flecks/cell cues and
  unnecessary texture work.

R25–R29 were preserved but rejected. They increased saturation or widened rim
energy at the cost of brightness range, shape depth, or the broad wet-light-card
read. Their values are not present in the selected source.

## Animation contract

V8.4 retains exactly fourteen clips:

`idle`, `plant`, `uproot`, `move`, `hit`, `attack`, `relay_open`,
`relay_close`, `move_start`, `move_stop`, `relay_glide`, `skill_cast`,
`victory`, and `defeat`.

Idle is a 2.6-second loop. Start and stop use V8.4-only viscous channels, and the
move loop layers bounded lag/squash/turn/contact deformation over uninterrupted
shader circulation. Sampled motion showed no detached region or collapse:

| Review measure | Result |
| --- | ---: |
| Move silhouette width range | 3.1% |
| Move silhouette height range | 6.2% |
| Move silhouette area range | 3.9% |
| Start width / height range | 2.3% / 5.3% |
| Stop width / height range | 3.0% / 3.4% |
| Idle pose IoU | 98.55–98.94% |
| Idle internal luminance change | 0.83–1.07% |

## Visual checkpoint

The final evidence is retained outside the shipping package:

- `outputs/v8.4-reference-viscosity/reference-comparison-final/reference-vs-R24.png`
- `outputs/v8.4-reference-viscosity/review-r24/V8.4-T-R24-optics-yaw-contact.png`
- `outputs/v8.4-reference-viscosity/motion-r6/V8.4-T-move-R6-final-strip.png`
- `outputs/v8.4-reference-viscosity/flow-phase-r3/V8.4-T-idle-R3-final-strip.png`
- `outputs/v8.4-reference-viscosity/six-family-static-r4/V8.4-six-family-front-back-R24-final-contact.png`

R24 front-body luminance percentiles are p10 89.26, p50 131.51, and p90
170.04; saturation is 0.8505. It passes the directional shadow and highlight
bands, misses the median band by 1.51, and does not meet the 0.90 saturation
target. This is recorded as a known fidelity gap rather than hidden behind a
single favourable screenshot.

## Verification record

| Gate | Result |
| --- | --- |
| Default + V5–V8.4 Godot selector smoke | PASS |
| Exact fourteen clips and finite 72 Hz samples | PASS |
| Single-mass / zero detached-cell checks | PASS |
| Tool tests | 64/64 PASS |
| UI tests | 53/53 PASS |
| Steam-readiness tests | 7/7 PASS |
| Audio inventory | 9/9 PASS |
| Steam image inventory | 4/4 PASS |
| Warm Godot import | PASS, no error/warning markers |
| Ten-character CPU sample | V8.4 0.829 ms vs V8.3 0.839 ms |
| Release-safe Web PCK policy | PASS, 543 entries inspected |
| Web baseline | 60.003 mean FPS, 59.88 p05, no long frames |
| SwiftShader constrained profile | PASS as compatibility stress only |

Real Metal capture, Steam Deck capture, signing, store submission, pricing,
legal approval, and owner account actions remain external release gates.

## Running the development look

From `godot/immune`:

```sh
IMMUNE_GEL_LOOK=v8_4 godot --path .
```

Without that exact environment selector the project remains on V8.3. Every
release preset excludes the V8.4 derivative, and the PCK policy check fails if
the excluded filename appears in a package.

## Rights and next fidelity step

The V8.4 T geometry inherits the unresolved rights chain of its Tripo source.
It is suitable for local review only and must not ship until the owner supplies
the original receipt/task/input-rights evidence or replaces it with a
rights-cleared project-authored mesh.

The largest remaining concept gap is structural: the reference has a broader
lower body, more integrated arms/feet, deeper face sockets, and finer continuous
orange-peel normals. A future V8.5 should solve those in a rights-cleared sculpt
and baked normal field. Further whole-body colour/rim tuning on the current mesh
is unlikely to close that geometry gap without making the character flatter.
