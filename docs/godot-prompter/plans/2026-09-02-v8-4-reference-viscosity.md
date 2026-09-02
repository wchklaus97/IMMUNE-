# V8.4 Reference Fidelity and Viscous Motion Plan

## Outcome

V8.4 is a rollback-safe successor to V8.3. It keeps the accepted single,
watertight character mass while moving the production look closer to the orange
gel reference: saturated optical depth, restrained coloured membrane, stable
orange-peel micro-relief, continuous internal circulation, and visible viscous
inertia during locomotion. V5 through V8.3 remain selectable and unchanged.

## Evidence from the V8.3 baseline

The reproducible T-family comparison against
`characters/concepts/CHAR-BASE-T-3d-alt.png` found:

- reference core red-at-or-above-250 coverage: 46.72%; V8.3: 0.16%;
- reference interior microcontrast: 0.0614; V8.3: 0.0260;
- reference compact highlights per 1,000 interior pixels: 2.07; V8.3: 0.15;
- V8.3 has a broad white membrane and a dark amber/brown core rather than the
  reference's saturated orange body and family-coloured transmitted edge.

These are directional look-development measures, not a promise of pixel-perfect
matching: the procedural character silhouette and the concept illustration are
not registered pixel for pixel.

## Non-negotiable contract

- One connected indexed body surface and one coincident membrane surface.
- No floating bubbles, microcells, inclusions, detached limbs, duty geometry, or
  loose particles.
- Eyes and mouth remain shallow, attached marks; they must share body-space
  deformation with the core and membrane.
- Internal flow continues through idle, move, turn, action, hit, recovery, and
  duty transitions. Animation changes may alter speed and direction but may not
  reset the phase.
- Locomotion collision remains stable. Visible lag, squash, shear, and surface
  wobble are render deformation only and remain bounded against collapse.
- All fourteen accepted clips stay present and finite at sampled 72 Hz playback.
- Compatibility/Web remains free of screen-texture reads and raymarching.
- V8.4-specific shader uniforms default to zero so V5 through V8.3 retain their
  historical paths.

## Implementation slices

1. Add the exact `v8_4` selector, inherited capability helpers, and failing smoke
   assertions before production code is enabled.
2. Add a V8.4 material profile with clean continuous laminar flow, stronger but
   mip-filtered wet-skin relief, saturated optical depth, and a coloured low-alpha
   membrane.
3. Add a low-frequency body-space wobble shared by wet core, shell, eyes, and
   mouth. Runtime continues to own eased lag/squash/turn/contact values.
4. Refine the same watertight radial surface for taller reference proportions and
   broader integrated side/lower lobes without adding another mesh piece.
5. Extend topology, animation, cadence, material, rollback, and Compatibility
   smoke checks to V8.4.
6. Capture static, idle, move, turn, action, defeat, and six-family evidence;
   compare it to both the reference and the preserved V8.3 checkpoint.
7. Run balance, UI, save, web-route, smoke, import, and 10-character performance
   probes before considering V8.4 the project default.

## Acceptance gates

- `IMMUNE_GEL_LOOK=v8_4` six-family smoke passes with the exact V8.4 marker.
- V5, V6, V7, V8, V8.1, V8.2, and V8.3 rollback smoke all pass.
- Mesh resource identity and metadata prove the V8.4 single-mass path; detached
  geometry and particle counts remain zero after duty swaps.
- Static captures show no collapse, fragments, white shell takeover, or face
  detachment at front and three-quarter views.
- Motion strips show coherent shape continuity and readable residual motion after
  acceleration, turning, and stopping.
- The continuous flow field changes at idle and remains phase-continuous through
  move/action overlays.
- Ten-character V8.4 CPU/frame probes do not regress materially from V8.3; any
  measured regression must be documented before default promotion.
- No export, signing, upload, store submission, or public release occurs in this
  slice without separate authorization.

## Execution result — 2026-09-02

The V8.4 development slice is complete and remains opt-in. R24 is the selected
look-development checkpoint. R25 through R29 are retained under
`outputs/v8.4-reference-viscosity/` as rejected experiments; none of their
parameter changes remain in production source.

- T uses `CHAR-BASE-T-v8-4-single-mass-r1.glb` only under exact selector
  `v8_4`. Its reproducible audit reports one node, one mesh, one primitive,
  2,253 vertices, 4,502 triangles, one connected component, zero boundary
  edges, and zero non-manifold edges.
- B, M, N, A, and D retain one coherent procedural mass each. No V8.4 family
  creates a detached cell, bubble, particle system, or loose face component.
- The shader clock continues across locomotion/action overlays. The body,
  membrane, eyes, and mouth share bounded low-frequency body-space wobble.
- The exact fourteen-clip contract passes: `idle`, `plant`, `uproot`, `move`,
  `hit`, `attack`, `relay_open`, `relay_close`, `move_start`, `move_stop`,
  `relay_glide`, `skill_cast`, `victory`, and `defeat`.
- Motion review found one substantial connected orange component in every
  sampled frame. Move width varied 3.1%, height 6.2%, and area 3.9%; idle pose
  IoU stayed between 98.55% and 98.94% while interior luminance still changed.
- Ten-character CPU sampling measured about 0.829 ms for V8.4 versus 0.839 ms
  for V8.3. This shows no sampled CPU regression; it does not replace a Metal,
  Steam Deck, or representative low-end GPU capture.
- R24 front-body percentiles were p10 89.26, p50 131.51, and p90 170.04, with
  saturation 0.8505. The lower and upper luminance gates pass; median misses the
  target band by 1.51 and saturation remains below the 0.90 directional target.
  R24 was selected because later attempts improved a single scalar while losing
  the broad wet-light-card and dimensional gel read.

## Verification completed

- Godot selector smoke: default plus V5, V6, V7, V8, V8.1, V8.2, V8.3, and
  V8.4 all return `SMOKE_OK` from the final source tree.
- Tool tests: 64/64; UI tests: 53/53; Steam-readiness tests: 7/7; generated
  audio inventory: 9/9; Steam image inventory: 4/4.
- A warm Godot import completed without error/warning markers and without
  changing tracked files.
- Release-safe Web export completed, and its PCK resource-policy scan inspected
  543 entries without finding the development-only V8.4 derivative.
- Web release QA completed baseline and constrained-software profiles. Baseline
  measured 60.003 mean FPS and 59.88 p05 FPS with no long frames.

## Promotion boundary

The configured/default and release-safe look stays `v8_3`. The V8.4 T mesh is a
derivative of a Tripo source whose commercial receipt and input-rights evidence
are missing, so all export presets exclude it and the PCK validator fails closed
if it leaks. V8.4 must not become the commercial default until that evidence is
resolved or the mesh is replaced by a rights-cleared project-authored sculpt.

The remaining visual fidelity gap is principally silhouette/sculpt and face
integration, not another global colour adjustment. A future V8.5 should rebuild
the rights-cleared hero topology around the concept proportions, then fit a
small-scale surface-normal field and face sockets on that geometry. R24 is the
stable foundation for that work, not a claim of pixel-perfect concept parity.
