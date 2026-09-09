# Model quality audit — visual acceptance remains open

Reference: `godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png`.
Current source: V8.6 R7.2, mesh SHA-256
`3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3`.

On 2026-09-06, three new six-angle capture sets completed successfully on
Godot 4.7.2 / Compatibility / Apple M4 Pro. Evidence is preserved in
`outputs/v8.6-quality-audit-20260906/`:

- `baseline`: current production reference scene, no overrides.
- `no-authored-relief`: identical scene with `authored_height_depth:0` and
  `orange_peel_micro_depth:0`. Large cheek, arm and foot patches remain.
- `clay`: same production body with StandardMaterial3D, roughness 0.85,
  specular zero; other meshes hidden and wet vertex shader removed.
  Shoulder bulges, eye sockets and limb transitions remain readable in clay.

The fine height texture is therefore not a sufficient explanation or fix for
the broad visual defects. Clay separates the actual shoulder/limb shape from
the wet appearance, but disabling its vertex shader also changes deformation;
it does not isolate individual lighting, normal or motion contributions.
Do not claim the optical root cause is fully isolated yet.

Visual gaps: overly distinct shoulders, narrow central mass, insufficiently
integrated eye/pore treatment, thick yellow edge, large wax-like optical
patches instead of the reference's fine wet surface and depth. Static images
cannot establish continuous internal circulation or viscosity during motion.

Next experiment: keep geometry and motion fixed while separately disabling
studio reflection cards, thickness/glow and procedural normal contributions.
Then create an additive geometry revision with broader upper body, smoother
shoulder connections and integrated facial cavities. Review under both neutral
and production light before accepting material changes. Preserve all revisions.

RC1 build/animation-contract success is technical evidence, not visual approval.
The previous claim of 100% development/visual completion is withdrawn. Reference
matching, motion appearance and human visual acceptance remain open.

## Optical isolation follow-up

Three further six-angle GPU sets succeeded with the same engine and rig:

- `no-body-cards-r2`: only `studio_reflection_strength:0` on the wet body.
  Broad pale cheek/arm/foot patches substantially disappear. Shell reflections
  remain enabled. Body studio cards are a major contributor to the apparent
  folds; this corrects any inference that those patches are all mesh defects.
- `no-thickness-glow`: `thin_curvature:0,thin_fresnel:0,thin_glow:0,rim_energy:0`.
  The thick yellow border disappears while broad reflection patches remain.
  This isolates the border to this group, not to one individual uniform.
- `optical-candidate-a`: `studio_reflection_strength:0.12,studio_streak_strength:0.12,thin_power:5,glow_power:5,thin_curvature:0.15`.
  Broad patches and border are reduced, but the result reads too solid/plastic
  and loses the reference's luminous gel depth. Rejected for promotion.

The first `no-cards` attempt failed closed because
`membrane_studio_reflection_strength` is not an exposed preview alias. It
produced no images. R2 deliberately isolates body cards only using the existing
supported control; it is not evidence that both body and shell were disabled.

Next material work must replace the broad artificial reflection appearance
with finer, coherent wet highlights while retaining depth and a narrow luminous
boundary. Simply disabling the effects is a diagnostic, not the finished look.
No shipping defaults or historical material profiles were changed.

## Preserved optical candidates B and C

Both completed six-angle GPU capture on the same 4.7.2 Compatibility rig.
`optical-candidate-b` keeps more luminous boundary than A while reducing broad
front-facing reflection patches: strength 0.8, edge share 0.9, broadening 0,
tail cut 0.05, streak 0.25, thin/glow powers 2. A reusable scene is
`res://tools/gel_optical_candidate_b.tscn`; it applies preview-only uniforms.
This is a working comparison baseline, not final visual acceptance.

`optical-candidate-c` uses strength 0.45, edge share 0.65, and B's other
settings plus orange-peel micro depth 0.003 and scale 24. It does not produce
the reference's fine wet highlight structure at the full-body capture scale.
Neither experiment fixes shoulder silhouette, integrated face cavities, or
proves dynamic internal flow. Increasing micro depth alone is not sufficient.

## Shape D: upper-body proportion experiment

`gel_shape_candidate_d.tscn` uses optical B and an invertible preview-only
horizontal map, with width rising smoothly from 1 at y=0.60 to 1.16 at y=1.15.
It updates seven mesh instances, including attached face and shell geometry,
with inverse-transpose normals and forward-transformed tangents. Source GLB,
indices, historical files and shipping selection are unchanged. This is a
proportion study, not a new production asset or completed topology revision.

The initial `shape-candidate-d` run has a script error on SphereMesh and is
invalid evidence despite the shot harness returning zero. The call was fixed
to use triangle primitives for PrimitiveMesh, retaining ArrayMesh's primitive
type. `shape-candidate-d-r2` then completed with the seven-mesh marker and six
captures, with no script errors in the observed output.

Front inspection shows a broader crown, but shoulder protrusions remain and
the forehead ring becomes horizontally stretched. Do not promote D unchanged.
The next authored revision should broaden the torso before subtracting facial
cavities, then seat facial elements separately; it should not distort a round
pore to obtain the body proportion. Dynamic deformation and neutral-clay D
comparison remain untested. The positive analytic map determinant alone does
not prove rendered pose or facial quality.

## Shape E: authored torso and shoulder revision

`tools/meshy/build_t_shape_e.py` changes only the numeric torso radius
(0.620 to 0.700) and two upper shoulder primitives (centre y 0.800 to 0.750,
radii 0.235/0.290/0.290 to 0.220/0.245/0.290), before the existing cavities
are subtracted. It retains R7.2's gates and immutable writer. Its inherited
R7 log prefixes name the helper routines, not the new asset version; the final
`SHAPE_E_OK` marker identifies this experiment.

New GLB: `outputs/v8.6-quality-audit-20260906/shape-e/shape-e.glb`, SHA-256
`a7a0d06b8e686d504f46449c3d5266eff0ee1538e78c254ebc5f80294b0b3444`.
Build passes: 6,002 vertices, 12,000 triangles, one closed region, zero boundary,
nonmanifold, winding or degenerate errors, Euler 2, volume 1.037772. Both eye
openings pass the inherited intersection tests; sampled outboard extent is
0.060355 and minor span 0.261616. This is structural evidence, not final face fit.

`gel_shape_candidate_e.tscn` verifies that exact GLB hash and substitutes only
the body and shell in a local optical-B preview. It retains the unscaled face
elements. Six GPU captures completed with `SHAPE_E_PREVIEW_OK replaced=2` under
`shape-e/gpu/`; four neutral builder previews are under `shape-e/neutral/`.
Front inspection shows smoother crown-to-shoulder transitions than D, and the
forehead ring stays round. The surface still lacks the reference's wet detail,
eyes/pore still read as attachments, and runtime animation compatibility remains
unverified. Shape E is retained for further development, not shipping promotion.

## Face F/G: cavity reflection and seating

Face F hides the separate pore torus, recesses the pore 0.008 and eyes 0.005,
and enlarges eye x/y scales by 1.12/1.08. Production body-space wobble bindings
are refreshed after changing face transforms. Its six GPU captures completed,
but the pore became a grey dot rather than a dark opening.

Inspection found `gel_eye.gdshader` hard-coded `SPECULAR = 1.0`. It now exposes
`surface_specular` with default 1.0, retaining previous material behavior.
Face G changes only the candidate pore's value to zero. Six further GPU
captures completed under `face-g/`, with the F and G setup markers. Front
inspection confirms the grey reflection disappears and eye highlights remain.
The pore still lacks the reference's smoothly integrated wet lip; removing
the torus alone is not a complete facial solution. F/G remain opt-in preview
scenes and all earlier material/geometry outputs are retained. Dynamic facial
registration is not yet established by these stills.

## H: integrated forehead cavity — rejected pending alignment

`build_t_shape_h.py` extends E, changing forehead cavity radii from
0.064/0.064/0.034 to 0.095/0.095/0.062 before meshing. Output
`shape-h/shape-h.glb` has SHA-256
`c1a9e388e4fe9bfbb20b834f686317775e23fa86474b24a8801a915249442da8`.
It passes inherited topology/eye-opening gates with 6,002 vertices, 12,000
triangles, one closed region and zero final degenerate/nonmanifold faces.

The hash-bound H scene uses G's facial elements and optical B; six GPU images
completed under `shape-h/gpu/`. Its face34 image reveals two unacceptable
defects: visible polygonal cavity edges and spatial separation between the
recess and black pore marker. This disproves full facial alignment despite
the eye-opening checks. H is not accepted or promoted.

Next: derive pore placement from the actual post-normalization cavity surface,
not the old runtime coordinate, and increase local cavity mesh quality before
judging reflection details. Eye gates must not be treated as pore-fit gates.
E/G and all failed H evidence remain available unchanged.

## I/J: measured pore seating

I samples 61 vertical centreline locations against the actual H triangles,
selecting the frontmost ray intersection then the interior cavity minimum.
The measured floor is `(0, 1.056, 0.286961)`, far behind the inherited mark
at z=0.430. Its six captures show that merely placing the shallow ellipsoid
at the floor hides it under the curved surface; I is not accepted.

J replaces that ellipsoid with a 129-vertex, four-ring surface patch of radius
0.030, projected individually onto the same body triangles with a 0.001 forward
offset. It refreshes the body-space wobble bindings and leaves all previous
versions intact. Six GPU captures in `face-j/` complete with `FACE_J_PATCH_OK`.
The inspected face34 image places the visible dark patch inside the recess
rather than floating outside its rim as in H. This is improved static seating,
not final acceptance: the recess still has polygonal edges and optical patches,
and interpolation/deformation may cause dynamic surface intersection. No
animation or gameplay quality claim is made for J yet.

## K: smooth-surface comparison and elapsed-time capture

`build_t_shape_k.py` applies one Loop subdivision pass to H's decimated mesh
before normalization and the inherited validation. The new immutable output
has 24,002 vertices / 48,000 triangles, one closed region, no final boundary,
nonmanifold, winding or degenerate errors, and volume 1.038619. SHA-256:
`ebdaf5858e3abeaa559bb7790eba777c86baaa6742e483647bc940743a967ce6`.
This globally increases geometry fourfold; it is a high-detail comparison,
not a measured production performance improvement or local-only refinement.

Six captures in `shape-k/gpu/` show a smoother cavity boundary, although some
angular detail and an oversized recess remain. The fitted floor moves to
`(0, 1.066, 0.288378)` and J's patch is reprojected onto this new surface.

`gel_idle_surface_audit.tscn` then captures eight near-face frames with live
shader time, waiting 0.5 seconds before each sample. All images save successfully
under `shape-k/idle/`. This uses a static reference subject, not CharacterRoot
locomotion or an AnimationPlayer clip; it is only an elapsed shader-time check.
The inspected initial, middle and final samples retain a visible pore patch.
Continuous video review, all-pose intersection tests and actual movement are
still needed; these sparse images do not prove complete dynamic registration.

## K in the real CharacterRoot animation preview

`gel_candidate_k_animation.tscn` now instantiates the production T character,
substitutes the local K body at `CoreMesh/RealMesh` with the original transform,
rebuilds its material cache and animation rig, and preserves duty selection.
It reports one wet material, one shell and five attachment materials (including
the hidden preserved torus); these counts are not five separate characters.

Eight sampled `idle` clip images completed in `shape-k/animation-idle/`.
Six live `move` frames completed in `shape-k/animation-reversal/` at requested
times 0.5 through 3 seconds, with velocities +3,+3,-3,-3,0,0 along X. This
exercises the production velocity overlay while the character stays in the
preview, not traversal/collision in a playable level. Frame 03 was visually
inspected in each set: a coherent body and visible face remain, but the eyes
still read raised, the pore is oversized, and wet surface reference parity is
not achieved. Sparse sampled frames cannot establish all-pose intersection or
subjective animation quality. No full fourteen-animation or performance pass
has been performed for K, and no shipping selector was changed.

## L: measured eye depth

L ray-samples the K body's frontmost surface at each eye centre. Left floor
z=0.299528 and right floor z=0.299649 contrast with inherited eye z=0.431.
It places the lenses at the sampled floor plus 0.009 and refreshes material
deformation bindings. Six captures complete in `face-l/` with both measured
placement markers. Front and face34 inspection still show a hard black lens
boundary. Centre-depth correction alone does not establish perimeter contact,
reference fidelity or movement safety; L remains an unaccepted experiment.

## M: perimeter-conforming lenses

M samples the body beneath all 2,210 vertices of each existing eye sphere,
using XY-filtered source triangles. Before fitting, the near-equator gap is
0.002314–0.036907 on the left and 0.002251–0.036924 on the right, confirming
that centre seating did not establish perimeter contact.

The new mesh maps its equator to skin plus 0.001 and retains front/back lens
thickness; normals are regenerated. Six GPU captures complete in `face-m/`.
Front inspection shows substantially weaker eye catchlights after the normal
change. M is therefore a contact experiment, not an approved eye appearance.
Vertex clearance is not an all-triangle or animated collision guarantee.
Next work must retain a convincing convex wet lens response while following
the cavity boundary; previous sphere geometry, L and M all remain preserved.

## N: convex eye crown and production-animation preview

N retains M's sampled perimeter and adds a 0.020 body-space crown to the
front lens only. M defaults to zero, preserving its earlier result. The crown
vanishes at the equator; this is not a claim of derivative continuity there.
The six preserved static captures are in `face-n/`. Front and face34 inspection
confirms restored wet eye highlights, but the oversized forehead cavity and
waxy skin remain unacceptable relative to the reference.

The existing K animation wrapper now accepts an exported candidate scene,
defaulting to K. A separate N scene uses the same production AnimationPlayer
and refreshed material bindings without changing the shipping selector.
Godot 4.7.2 on Apple M4 Pro completed six velocity-overlay samples (+3,+3,
-3,-3,0,0 X) in `face-n/animation-reversal/`, with exit zero, no reported script
errors, the N scene marker, both 0.020 crown markers and six PNG content gates.
Frame 003 was visually inspected: eyes remain visible with a highlight, but
still have a hard boundary. This is a preview overlay, not gameplay collision
testing, continuous motion acceptance, a full fourteen-clip pass or profiling.
No candidate is promoted. Prior models and evidence remain preserved.

## O: smaller cavity rejected by placement gate

An independent K-derived builder replaces cavity radii 0.095/0.095/0.062
with 0.075/0.075/0.045. Output SHA-256 is
`b38f359e0621918adfa39fad5d80a21eb114d59fb0c2d5e8f095d5a50d1c4c92`.
Its final mesh has 24,002 vertices, 48,000 triangles, one closed component,
Euler 2 and zero boundary, nonmanifold, degenerate or winding errors.
Inherited H log describes the intermediate wrapper; O's final marker describes
the actual override. These topology results do not establish visual quality.

GPU preview exits 2: the existing pore-placement scan cannot find an interior
minimum in its fixed Y interval. No valid O captures or acceptance are claimed.
The shallower cavity and absolute-depth scan need investigation together;
removing the guard or presenting the rejected asset would conceal the issue.
The failure also exposed J/L/M continuing after the parent's `_fail` cleared
materials. They now return immediately when that array is empty. A targeted
failure-path rerun exits 2 without the previous secondary array-index errors.
Previous candidates and shipping assets remain preserved. O is rejected pending
geometric/placement diagnosis, not a new approved character version.

### O placement diagnosis and visual rejection

A 61-sample centreline diagnostic proves the global-depth assumption wrong:
the cavity has a local minimum `(0, 1.060, 0.305247)` and rises to z=0.307436
at y=1.100, but the forehead then falls to z=0.302717 at y=1.120. The global
minimum therefore selected the scan boundary rather than the actual cavity.
O now opts into a local-minimum locator requiring exactly one minimum and a
rise greater than 0.0001 on both sides at five-sample spacing. Previous scenes
retain the original locator; no guard is bypassed.

The corrected run in `shape-o/gpu-local-fit/` exits zero, reports the measured
local minimum and saves all six PNGs without script errors. Front and face34
inspection show a new visual tradeoff: the obvious cup-like depression is
reduced, but its wet lip is too weak and the mark looks like a black dot.
Thus placement is repaired while O still fails reference-match appearance.
The next geometry/material decision must preserve a legible rounded wet lip,
not merely minimize cavity depth. No dynamic or performance acceptance for O.

## P: shaded cavity patch, not a complete wet lip

P retains O's GLB and local locator. It gives the 129-vertex patch planar UVs
and regenerated geometric normals instead of uniform +Z normals, and opts into
a radial near-black-to-warm-brown edge in `gel_eye.gdshader`. The new uniform
defaults to zero so existing face materials do not opt in. Only P sets cavity
roughness 0.35 and specular 0.12; body material and mesh remain O's.

Godot 4.7.2 / Apple M4 Pro exits zero, emits FACE_P_OK and saves six content-
checked views under `face-p/`, with no reported script or shader errors.
Inspected face34 shows a softer dark edge, but the patch still reads offset
inside an uneven recess and the wet lip is not reference-matched. This is a
minor material improvement, not geometric acceptance or animated verification.
The full-body waxy appearance remains unresolved. No production promotion.

## Q: direct-light wet coat and resolved surface relief

Q keeps P's geometry, face and optical-card baseline, changing four surface
controls: spec_energy 0.10 -> 0.65, coat_roughness 0.058 -> 0.10,
authored_height_depth 0.00090 -> 0.0025, authored_height_lod_bias 0.84 -> 0.20.
This tests stronger direct-light highlights with less filtered height detail,
not real transparency or a new volumetric renderer.

The six-view Apple M4 Pro / Godot 4.7.2 run exits zero with all overrides
reported and no script/shader errors. Evidence is in `surface-q/`.
Front inspection shows more legible wet highlights and fine relief than P,
but also a stronger pebbled/rind appearance. Sampled PNG peak luma reaches
1.0 in front and face34, so highlight clipping requires measurement before
approval. Neither complete reference fidelity nor animation stability is
established. Q remains an isolated candidate; prior versions stay preserved.

## R: measured highlight/relief compromise

R retains Q except spec_energy=0.35, authored_height_depth=0.0016 and
authored_height_lod_bias=0.45. Six GPU views complete without reported errors
under `surface-r/`. Front inspection shows less pebbled relief while retaining
stronger highlights than P, but does not establish translucency or fidelity.

Read-only PIL/NumPy analysis counts pixels with all RGB channels >=250 in the
1024-square PNGs: P front 22; Q front 498 and face34 3458; R front 260 and
face34 1949. R reduces this near-white footprint about 48% and 44% respectively.
These are whole-frame near-white counts, not an HDR clipping measurement,
subject-normalized metric or acceptance threshold. Shader time was not frozen
between captures, so the comparison is indicative rather than pixel-exact.
R is not promoted: subdued hotspots alone do not deliver the reference's
translucent interior, wet rounded facial rims or motion quality.

### R production-animation overlay

`gel_candidate_r_animation.tscn` connects R to the existing production-character
wrapper and refreshes its material/animation bindings. Twelve move-clip samples
at 0.25-second intervals complete under `surface-r/animation-reversal/`, using
four +3 X velocities, four -3 X velocities and four zero velocities. The run
exits zero with the R candidate marker and twelve PNG content gates, with no
reported script/shader errors. The subject stays in the preview; this is not
actual level traversal or collision coverage.

Frames 005 and 011 were inspected: a single coherent body remains visible,
but the side-on eye still reads like a raised lens and the skin reads waxy.
The sparse captures cannot prove continuous fluid motion, absence of shimmer,
all-pose face contact, or a fourteen-animation pass. R is therefore not approved
for reference fidelity; the animation evidence exposes remaining visual work
rather than closing the quality gate.

## S: lower eye crown and projected pore alignment

S retains R's body/materials but reduces eye crown from 0.020 to 0.012 and
offsets the conforming pore patch -0.025 Y before ray-projecting every vertex.
The patch centre is y=1.035. J's new offset defaults to zero, preserving all
earlier scenes. This is an artistic placement offset, not a new measured floor.

Six views in `face-s/` complete on Godot 4.7.2 / Apple M4 Pro without reported
script/shader errors. Face34 inspection puts the black patch lower in the
recess but reveals a grey specular spot on its right side; the pore still
does not read as a natural opening. Eye highlights survive the reduced crown,
but this close-up cannot establish dynamic or all-angle perimeter contact.
S is an unapproved comparison, not a shipping update. All previous versions
and captured failures are retained.

## T: keep direct specular out of the pore centre

T inherits S and enables a radial specular mask on the pore only. The centre
receives zero direct specular; the outer 30% of UV radius smoothly restores
it. The shader uniform and P-script export default to zero, retaining previous
materials/scenes. This changes shading, not geometry or actual cavity occlusion.

Six GPU views in `face-t/` complete with exit zero, the edge-only marker=1,
and no reported script/shader errors. Face34 inspection confirms removal of
S's grey central spot while a narrow highlight remains at the right boundary.
The recess still lacks the reference's rounded wet lip and the wider surface
remains too waxy. This is a targeted shading repair, not full visual acceptance
or motion verification. No shipping selector or historical model is replaced.

## U: isolate the direct-light ceiling

U inherits T and changes only the wet material's direct_light_budget_share
from 0.10 to 0.40 (read-back marker verifies both). Six views complete without
reported errors under `light-u/`. Front inspection shows a much brighter,
paler orange body, not the reference's deep translucent interior. The
whole-frame sampled luma variance rises from roughly 0.030 to 0.070, largely
because the subject is brighter against its dark background; this is not
proof of better internal contrast or material quality.

This experiment does not support simply lifting the exposure safety ceiling
as the waxiness fix. The shader comments document its three-light additive
Compatibility safety purpose, and U has not passed those light-count gates.
Keep U diagnostic-only and retain production defaults. Future material work
must address light transport/reflection structure, not merely brightness.

## Mesh-derived thickness diagnostic

The wet shader explicitly uses view-Fresnel/curvature thinness, not measured
mesh thickness (`local_thickness` around line 1292). This limits what parameter
tuning alone can establish. `tools/meshy/bake_surface_thickness.py` now reads
the independent O GLB and casts inward normal rays through a VTK OBB tree,
recording the first hit farther than 0.002 from each vertex. Output is immutable
and bound to the exact source SHA. A missing exit rejects consumption while
preserving the diagnostic.

The first run completes with 24,002/24,002 exit distances, zero misses:
min 0.0597816, median 0.8748572, max 1.6398464 in authored model units.
Evidence: `shape-o/thickness-normal.json`. This is normal-direction rest-pose
thickness, NOT camera/light-path thickness, volume rendering or animated
thickness. It is not yet used by the shader. Before consumption, imported
vertex order must be verified and the field visually inspected; mere zero
misses cannot prove physically correct light transport or reference fidelity.

### Thickness correspondence and field inspection

R2 adds a hash of ordered source POSITION floats. The debug scene correctly
rejects byte-exact matching after Godot import (exit 2, no valid captures).
First-position comparisons suggest quantization, so R3 preserves full source
positions and checks every same-index point with a 0.00005 distance limit.
All 24,002 pass, max error 0.000035883; this is tolerance-verified correspondence,
not byte identity. Source SHA, count, finite positive values and zero misses
are checked before assigning thickness to COLOR.r (normalized by 1.64).

Six unshaded debug views complete in `thickness-debug-r3/` without reported
errors. Blue denotes short normal exit distance, red long. Front inspection
shows broadly thin hands/feet and thicker core but abrupt transitions near
the foot/body junction and shoulder. Normal rays can switch their opposite
surface suddenly; zero ray misses does not remove that directional artifact.
Do not feed this field uncritically into production absorption. Investigate
multi-direction thickness or edge-preserving regularization before adoption.
No actual wet material consumes the bake yet; failed R2 and all bakes remain.

### Five-ray cone thickness

The baker now accepts an opt-in 30-degree cone: one normal plus four tangent-
offset rays, averaging first-exit distances only if all five succeed. Default
zero retains the prior single ray. `shape-o/thickness-cone30.json` completes
120,010 rays over 24,002 vertices with zero misses (min 0.194525, median
0.835672, max 1.268522). Geometry and previous bakes remain unchanged.

Across all 72,000 unique mesh edges, absolute thickness-jump p99 falls from
0.556815 to 0.237202; max from 1.359987 to 0.594127; edges above 0.2 from
2478 to 1251. This measures field continuity, not physical accuracy: averaging
also raises the thinnest value and can blur genuine thin regions.

Six debug captures in `thickness-cone-debug/` pass correspondence and render
checks. Front inspection shows reduced abrupt patches but visible foot/torso
bands remain. This field remains a rest-pose, direction-averaged proxy and has
not yet been tested as actual absorption or animated thickness.

## V: first absorption test using measured thickness

The wet shader adds `baked_thickness_mix`, default zero. V opts into 0.65,
mixing the old optical thickness with cone-mean vertex red * 1.64, clamped
to the existing throughput function's 0..1 range. The debug loader can now
retain normal face/shell visibility and the wet material instead of false
colour. It verifies source, correspondence and samples before assignment.

Six captures complete under `thickness-v/`, exit zero, mix read-back=0.65,
with no reported shader/script errors. Front inspection shows changed colour
depth but notably weaker luminous forehead edges; it still looks solid/waxy.
This is expected evidence of a limitation: rest-pose normal thickness does
not shorten with a grazing camera path. Mixing it directly into the old
view-dependent field is not a complete optical model. V is not promoted.
View-path correction, animation and multiple-light evaluation remain open;
no real transparency/refraction has been implemented by this experiment.

## W: convex view-chord approximation

W inherits V and sets baked_thickness_view_mix=1. The measured normal/cone
distance is multiplied by abs(dot(macro normal, view)) before the existing
0.65 blend. Micro-bump normals are deliberately excluded from this path.
The default zero preserves V and earlier materials. This convex chord proxy
is not accurate for arbitrary concavities, refracted rays or moving thickness.

Six GPU views in `thickness-w/` complete without reported errors, confirming
both mix values and source correspondence. Front inspection restores much of
the forehead edge brightness lost in V while retaining the measured-field
colour variation. However, the character still looks solid/waxy compared to
the reference; neither thin-edge recovery nor successful rendering establishes
reference parity. No animation/multi-light validation or shipping promotion.

## X: front-facing card redistribution rejected

X inherits W and changes only studio_reflection_edge_share 0.90 -> 0.35,
verified after material setup. All six views in `reflection-x/` complete
without reported errors. Front inspection visibly brings back broad pale
patches on forehead, shoulders and feet resembling false folds. This is not
the reference's structured wet reflection and is rejected.

The existing studio term uses view-space Gaussian cards followed by peak_limit;
its soft-knee exponential approaches a fixed budget. Both the card distribution
and its compressed upper range merit isolation rather than another wholesale
brightness increase. X does not establish which factor dominates the patches.
W, X, all earlier assets and shipping selectors remain preserved.

## Y: isolate studio-response compression

Y inherits X but opts into rational studio compression `c * budget /
(budget + peak(c))`. A new studio-only uniform defaults to zero; body, rim and
interior retain their existing peak limiter. Six views in `reflection-y/`
complete with the read-back marker=1 and no reported shader/script errors.
Front inspection reduces X's conspicuous flat forehead/foot patches but also
reduces their brightness. This supports compression contributing to the
artifact; it does not isolate response shape from total reflected energy.
Waxy appearance and reference mismatch remain. No promotion or motion pass.

## Z: reflection budget and palette sanity check

Read-only body-patch samples give reference median RGB 216/57/1 (box
480,620–560,700) versus Y 215/67/8 (480,600–560,650). These manually chosen
patches are not registered geometry or global colour metrics, but do not
support a wholesale warmer/brighter palette change as the first fix.

Z keeps Y and raises only studio_reflection_budget to 0.60. Six views in
`reflection-z/` complete without reported errors and verify the new budget.
Front inspection strengthens pale forehead/foot reflections but still fails
to reproduce the reference's structured wet highlights. Merely raising this
budget is not sufficient. Z remains diagnostic-only; no final visual acceptance.

## AA: strip-card shape isolation

AA inherits Y and replaces Gaussian key/cool lobes with two smooth-edged
vertical strips in reflected view direction; warm/streak lobes are suppressed
only when this opt-in shape mix is one. Defaults preserve the previous shader.
Six views in `reflection-aa/` complete without reported errors. Front inspection
shows obvious rectangular forehead bands and broken marks around the face
rather than natural reference-like reflections. AA is rejected: replacing
Gaussian shapes with strips alone does not solve the appearance. Temporal
stability and light/world-space anchoring are also unverified. No promotion.

## Renderer-path comparison: W on native Forward+/Metal

Using the same W scene with command-line overrides `--rendering-method
forward_plus --rendering-driver metal` confirms Metal 4.0 / Forward+ on Apple
M4 Pro. All six views in `w-forward-metal/` complete without reported errors.
Project settings stay `gl_compatibility`; no renderer migration was performed.

Front inspection differs substantially: the body becomes deep red, broad pale
patches reappear, and bloom is visible. The shot environment already requests
ACES and glow, so this comparison includes differing backend responses to those
same settings; it is not a tone-map-normalized material comparison. It does not
support switching renderer as a one-step quality fix. A native path would need
its own colour/lighting/material calibration and performance/feature testing.
This is new backend evidence, not a reference-match or release acceptance.

### Post-process-normalized backend probe

`gel_neutral_backend_shot.tscn` inherits the shot rig, retains its lights and
camera, and overrides the environment to linear tonemapping, exposure=1,
no glow/SSAO/SSIL/adjustments/fog and a fixed dark background. Separate six-view
Compatibility and Forward+/Metal runs complete without reported errors under
`backend-neutral-compat/` and `backend-neutral-forward/`.

Both front images were inspected. The Forward+ version is still redder with
broad pale surface marks while Compatibility is orange with smaller highlights.
Thus ACES/bloom alone do not explain the mismatch; further investigation must
include colour-space handling, material paths and lighting accumulation. This
probe does not isolate those remaining causes or freeze shader time. Neither
renderer result is reference accepted; project settings remain unchanged.

### Colour-space isolation: confirmed nonlinear material-math mismatch

`tools/gel_color_space_probe.gd` renders three unshaded quads into a 384x128
SubViewport with linear tonemapping, no lights, no glow and no time dependency.
Native Godot 4.7.2 runs on Apple M4 Pro exited zero without reported errors:

| RGB8 centre sample | Compatibility | Forward+/Metal |
| --- | --- | --- |
| source_color passthrough | 255,184,84 | 255,184,84 |
| unmanaged absorption | 239,205,100 | 248,196,119 |
| linear absorption + output conversion | 248,196,120 | 248,196,119 |

The diagnostic uses the same normalized-tint/power/exponential structure as
wet_gel.gdshader::gel_throughput, with explicit test coefficients, not the
complete character material. Explicit linearization before that calculation
and sRGB encoding of its final unshaded output reduce this isolated difference
to one 8-bit channel step. Plain source_color passthrough already matches;
removing source_color hints or applying unconditional gamma correction would
not be justified.

This establishes a reproducible colour-space sensitivity in the nonlinear
absorption calculation; it does NOT establish that this is the sole cause of
the complete character mismatch or fix the reference fidelity. Production
materials remain untouched by this probe. A single conversion inside
gel_throughput is not a complete fix: its return value participates in further
mixing, budgets, direct lighting and emission. Those operations need a coherent
working-space contract and isolated candidate before production adoption.

Next bounded work: keep Compatibility as the shipping baseline; create one
linear-light material candidate with explicit input/output boundaries, test
body-only and full-face renders against the same neutral rig, then check the
reference and continuous movement. Do not add another reflection-shape variant
until this colour contract is established. Genuine optical depth and integrated
facial features remain separate unresolved visual gates.

Official reference: https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html
documents OUTPUT_IS_SRGB as true for Compatibility and false for Forward+/Mobile.

### AB: explicit extinction coefficients in a native linear pipeline

`gel_linear_optics_candidate.gd/.tscn` inherits W and requires Forward+ before
loading the candidate. It creates an in-memory copy of the body shader,
preserves all 186 effective parameters, and substitutes only gel_throughput.
The old UI-tint-derived coefficient calibration is computed explicitly on CPU
and bound as numerical vec3 data, not source_color. Actual sigma is
(0.095, 1.121941, 7.103553). Forward+ supplies the linear material/light pipeline
and final display encoding; the candidate does not gamma-encode individual
light contributions. It does not implement linear accumulation on Compatibility.
No production shader/profile or renderer setting was changed for AB.

All six neutral-rig images in `linear-optics-ab/` completed on native Metal
without reported errors. Front and face34 inspected against the reference:
the dark red body, broad waxy reflections, tiny mouth and lens-like eye edges
remain visibly far from the bright orange, wet, embedded-feature reference.
Closeup also exposes blocky highlight detail. AB is NOT visually accepted.
This materially narrows the diagnosis: separating absorption coefficient data
from display tint is useful, but plainly insufficient for the full mismatch.
There is no measured full-image improvement or animation acceptance claim.

The remaining optical design must address the combined lighting/energy budget,
surface reflection structure and apparent interior depth, not repeatedly tune
absorption alone. Preserve the existing deformation code, but use a coherent
body-lighting candidate with fewer independent emissive ceilings before adding
more decorative reflections. Eye embedding and mouth silhouette need a separate
geometry pass. Do not promote AB or migrate the shipping renderer.

### AC / AD: replace capped/card lighting with a single linear radiance path

`gel_coherent_light_candidate.gd/.tscn` inherits AB, retains vertex deformation
and fragment normal/thickness calculations, and replaces the light function
using `gel_coherent_light.gdshaderinc`. It zeros body EMISSION and hides the
secondary reflective shell in this candidate only. Wrapped scatter and
thickness-attenuated backlight now accumulate without per-light peak ceilings;
one GGX-style specular lobe replaces the previous two art-directed lobes.
This is an art-directed translucency approximation, not a physically validated
BSDF, ray-traced refraction, or simulated interior fluid. The fragment flow
coordinates remain but their former emissive contribution is intentionally
removed; their visible motion needs new verification, not an assumed pass.

AC uses scatter=0.65, transmission=0.75, absorption_mix=0.48. Six native Metal
neutral-rig captures complete without reported errors in `coherent-light-ac/`.
Front inspection removes broad pale wax patches but becomes overly yellow and
flat. AC is rejected. Its defaults and captures remain preserved.

`gel_coherent_light_ad.tscn` changes only these three explicit parameters to
0.42 / 0.25 / 1.0. Six captures in `coherent-light-ad/` also complete without
reported errors. Front inspection recovers an orange body without the prior
broad white reflection bands, but still resembles opaque glossy plastic:
insufficient luminous edge/interior depth, dull grey-green arm creases, small
pore/mouth and detached-looking eyes. No reference acceptance or promotion.

This experiment supports replacing the previous capped/card lighting as a
cleaner foundation, but it does not solve jelly fidelity. The next material
step needs an explicit internal-depth cue and controlled reflected environment,
not another global brightness change. Facial geometry and continuous-motion
acceptance remain outstanding. No shipping material, GLB or renderer changed.

### AE / AF: internal optical-depth sampling

`gel_internal_depth_candidate.gd/.tscn` inherits AD and inserts eight midpoint
samples along a refracted view ray (IOR=1.36), using the baked chord estimate.
The density field is a continuous curling ribbon; its integrated optical depth
replaces v_through. No new mesh, bubble object or satellite cell is created.
The local/view transforms use the documented Godot 4.7 MODEL_MATRIX and
INV_VIEW_MATRIX. This is still an estimated-chord effect: samples are not
clipped against the actual concave mesh, and skinning/deformation does not
recompute true exits. It is not a physically simulated volume or real scene
refraction. These limitations matter especially around arms and feet.

AE six-angle native Metal captures in `internal-depth-ae/` completed without
reported errors. Front inspection reveals large marbled bands and pale foot
patches, unlike the reference. AE's contrast=1 is rejected and preserved.

AF (`gel_internal_depth_af.tscn`) uses contrast=0.25. A new neutral idle rig
captures eight samples at 0.5-second intervals in `internal-depth-af-idle/`.
All eight pass content checks with no reported engine errors; first and last
images were inspected. Marbling is subdued, but depth/motion is too subtle to
claim convincing liquid from these sparse samples. Surface wobble also changes
over time, so differences cannot be attributed exclusively to the new density
field. No continuous-animation, movement-transition, GPU timing or full
reference acceptance is claimed. Strong blocky point highlights and detached
eye edges remain visible in closeup.

Next evidence needed is controlled density-only time comparison plus a moving
camera/continuous clip, and a reflected environment that produces wet surface
structure rather than isolated point hotspots. Do not promote AF on the basis
of passing screenshot generation. All old candidate defaults remain intact.

### AF isolated depth clock: repeatability confirmed

`gel_depth_isolation_shot.gd/.tscn` freezes every material TIME token to 2.0
and advances only candidate_depth_time through 0,1,2,3,0. AF's default remains
-1 (ordinary elapsed time); production is unaffected. Native Metal five-frame
run `depth-isolation-af/` completed without reported errors. Compared with t=0:

| Internal time | Max channel delta (RGB8) | Pixels with delta > 1 |
| --- | --- | --- |
| 1 | 15 | 163319 |
| 2 | 20 | 214698 |
| 3 | 21 | 214361 |
| 0 repeated | 0 | 0 |

This isolates genuine density-field response and exact repeatability, not a
surface-wobble false positive. It is not a perceptual liquid-quality gate or
a continuous-animation/locomotion pass. The complete image is compared; metrics
are not a reference similarity score.

### AG reflected-environment probe: unresolved body response

`gel_softbox_sky.gdshader` supplies two static world-oriented softboxes to the
engine sky radiance map. `gel_environment_shot` enables sky reflections, disables
directional specular, and locally copies the AF shader with point specular zero,
SPECULAR=0.5 and ROUGHNESS=0.17. Initial run had a wrong enum spelling and was
stopped; corrected to documented Environment.REFLECTION_SOURCE_SKY before retry.

Six-view runs `environment-ag-r2/` through `environment-ag-r5/` all completed
without reported errors. Their front images were inspected. R2 retains the body
ambient_light_disabled flag; eye reflections appear but the body is matte. R3
removes that flag and disables ambient source; R4 uses colour ambient with zero
energy; R5 uses black ambient colour with energy=1. All still lack the intended
body reflections. The latter variants also lose the conspicuous eye reflections.
These are failed probes, not visual improvements. All configurations/captures
are retained through separate scenes and default-off exported options.

Do not infer a Godot bug or keep increasing sky intensity. Next isolate the
engine reflection response using a minimal standard material/control sphere
and this same sky, then compare the custom material's output boundaries. The
current evidence does not establish why the expected radiance is absent.
No candidate was promoted; the goal remains visibly incomplete.

### Reflection control and AG6–AG8: restore body environment response

`gel_reflection_control.gd` renders three identical dielectric spheres with
standard material, minimal spatial material and custom-light material. On this
native 4.7.2 Metal run, black colour ambient plus sky reflection source yields
all-black spheres. Merely switching the background to sky shows the background
but the spheres stay black. Switching ambient source to SKY restores matching
softbox reflections in all three (peak RGB8 200/255). Images are preserved as
`reflection-control*.png`. These isolate configuration sensitivity without
claiming a general Godot bug or universal renderer rule.

An additional control changes only the third shader's IRRADIANCE to black with
alpha=1. It becomes entirely black while the other two retain reflections.
Thus that proposed diffuse-only suppression is unsuitable in this tested path.
AG6 reproduces the unresolved matte body while its eyes reflect the environment.

AG7 avoids IRRADIANCE writes and instead uses engine ALBEDO=0. This restores
body reflections but removes its custom diffuse colour as well (black glossy
body). AG8 uses ALBEDO=0.001 and compensates custom DIFFUSE_LIGHT by 1000,
preserving the direct radiance after the engine albedo multiplication while
keeping the ambient floor small. Both are separate opt-in scenes. All six-view
runs AG6/7/8 completed without reported errors; front images were inspected.

AG8 (`gel_environment_ag8.tscn` with AF subject) finally shows world-sky
reflections on the orange body. This fixes the missing environment response in
this candidate. It is still not reference accepted: broad bands remain too
regular, the body too opaque, grey arm creases persist, and eyes/mouth need
geometry work. The 1000x intermediate diffuse factor also needs precision/HDR
stress validation before adoption; this is not a production-ready solution.
No promotion or renderer migration. Captures: `environment-ag-r6/`, `-r7/`, `-r8/`.

Next use AG8 as an explicit working reflection baseline, validate the albedo
compensation against a direct-light-only control, then refine the actual surface
normal structure and facial embedding instead of reverting to view-locked cards.

### AH: conforming frown mouth

The reference has a small readable frown, while the previous mouth is an almost
invisible straight slit. `gel_mouth_candidate_ah.gd/.tscn` inherits AF and replaces
only the existing MouthCavity mesh with a 99-vertex curved ribbon, width=0.105,
arch=0.014. Every vertex ray-fits the body surface with a 0.001 forward offset;
all 99 rays hit. It retains the existing mouth node/material deformation
bindings, regenerates normals, and disables cavity catchlights/specular that
previously made the slit look like a silver mark. No extra mesh node was added.

Six AG8-lighting captures in `mouth-ah/` complete without reported errors.
Front inspection shows a readable frown, a local improvement toward the
reference expression. Back inspection shows no face marks. The standard face34
crop excludes the mouth, so it is not evidence of mouth closeup quality.
This is a surface-fitted dark mark, NOT a carved mouth cavity or complete lip
integration. Animated contact, closeup edge quality and all 14 animations remain
unverified. The broader material/eye fidelity gaps are unchanged. Shipping GLB
SHA remains 3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3.

### AH mouth-specific closeup gate

`gel_mouth_detail_shot.gd/.tscn` inherits the AG8 rig, records its standard six
views, then targets the actual MouthCavity mesh bounds at camera azimuths
0/35/70 degrees and eight idle samples spaced by 0.5 seconds. All 17 captures
in `mouth-ah-detail/` completed without reported errors and passed PNG content
checks. Front, 70-degree and first/last idle closeups were visually inspected.

Those inspected samples show a continuous dark frown attached to the surface,
without an obvious air gap or detached segment. This is not proof of flicker-free
continuous playback, movement/combat contact, or all animation states. Closeup
quality FAILS: the mouth is a flat black decal with abrupt terminal edges, not a
recess with a wet lip. Body highlight patches also visibly break into blocky
surface detail at this scale. These are concrete outstanding defects, not
acceptable completion masked by a good distant silhouette.

Next geometry work must establish an actual shallow mouth recess and rounded
lip transition (preserving the readable AH frown), with the same closeup rig.
Separately isolate the authored bump sampling that produces blocky highlights.
Do not promote AH merely because the front expression is now legible.

### AI: cubic height reconstruction reduces blocky closeup highlights

Source inspection finds jelly_micro_height.png is 512x512 RGB8, lossless import
compress/mode=0, mipmaps enabled; VRAM block compression is not supported as the
cause. The existing three triplanar textureGrad samples use bilinear height
reconstruction, whose derivative changes across magnified texels. This suggested
a reconstruction test rather than reducing authored_height_depth to zero.

`gel_cubic_height_candidate.gd/.tscn` inherits AH, replacing only the three sample
sites with cubic B-spline reconstruction (`gel_cubic_height.gdshaderinc`). Four
bilinear taps per mip and two interpolated mip levels give eight taps per site.
The original texture, bump depth and mesh are unchanged. The filter smooths
texel-scale detail; it is not an exactly interpolating reconstruction and does
not preserve all high-frequency height contrast. It also replaces anisotropic
textureGrad behavior with explicit isotropic LOD selection: oblique/minified
quality and increased sample cost need measurement before promotion.

All 17 images in `cubic-height-ai/` completed on native Metal without reported
errors, including six views, three mouth closeups and eight sparse idle samples.
Front and mouth-00 were inspected against the prior AH images. Mouth closeup
shows a substantial reduction of the large rectangular highlight blocks;
full-character view retains visible relief. This is a genuine local quality
improvement, not complete reference fidelity. The runs are not time-registered
pixel comparisons. GPU timing and continuous motion remain unverified.

AI is retained as a candidate only. Surface reflection layout, true mouth/lip
recess, eye embedding and jelly optical depth remain unfinished. Next measure
the cubic path's GPU/LOD behavior and continue the actual facial geometry work;
do not claim the entire character quality gate passed.

### AI performance measurement: internal GPU timer unavailable

`gel_cubic_benchmark.gd/.tscn` compares the same material and mesh with only the
three cubic call sites switched back to textureGrad for the baseline. Body TIME
is fixed at 2.0. Each full/close camera runs bilinear/cubic/cubic/bilinear with
90 warmup and 240 measured frames per batch. Native 4.7.2 Metal initial run
completes all eight batches but every viewport GPU sample is zero. The report
correctly records valid_gpu_samples=false and the rig exits failure (5).
CPU render submission medians near 0.09–0.10 ms are NOT GPU costs or frame-time
acceptance. Data: `cubic-benchmark-ai/cubic-benchmark.json`.

A target-launched Xcode Metal System Trace was started as an alternative,
limited to 45 seconds. Target benchmark completed all batches and exited;
its report is in `cubic-benchmark-native/`, still with zero internal GPU times.
At the latest check the xctrace process is actively finalizing the recording
(PID 61310, exec session 44800, approximately four minutes elapsed and ~100%
CPU). `cubic-native-metal.trace` is about 7.3 GB; free disk is about 17 GiB.
Do NOT start a duplicate recording or delete old versions. Resume waiting on
the same session until terminal before exporting the trace TOC and target GPU
events. Native GPU results are pending, not an achieved performance gate.
Later benchmark reports also include engine version/executable for provenance;
the first reports predate that addition, so trace metadata must verify the
native recording's executable/version before drawing comparisons.

### Native trace follow-up: analysis activity is not a valid timing result

The same recorder (PID 61310, session 44800) is still non-terminal after
approximately 11 minutes, using about one CPU core. A one-second process sample
at `/tmp/xctrace_2026-09-06_145051_xBlv.sample.txt` shows workers inside
`DVTInstrumentsAnalysisCore`; it does not establish successful finalization or
rule out a pathological analysis loop. The trace remains about 7.3 GB and free
disk is about 15 GiB. No duplicate recording was started and no versions were
deleted. GPU acceptance remains pending; CPU samples and recorder activity must
not be presented as a GPU performance pass. Export only after the recorder
exits, and verify target executable provenance before interpreting its events.

### Native trace terminal result: provenance gate not satisfied

Recorder session 44800 ultimately saved `cubic-native-metal.trace` and exited
54. TOC export (session 7847) then completed successfully. Its target PID is
61334, benchmark arguments match the requested rig, target exit status is 5,
duration 33.213231 seconds, and end reason is target exit. However the process
path is `/Applications/Godot.app`, not the pinned workspace engine. A direct
`/Applications/Godot.app/Contents/MacOS/Godot --version` returns
4.6.1.stable.official.14d19694e. The narrow dyld export
`cubic-native-dyld.xml` contains schema only, no rows, so it cannot resolve the
provenance discrepancy. Do not use this recording to claim pinned-4.7.2 GPU
acceptance. Both recorder and export are terminal; do not keep polling them.
No second recording was started. Free disk recovered to about 16 GiB after
finalization. Any future trace should attach to an already verified exact PID
and use a smaller capture; do not repeat the ambiguous bundle launch.

### AJ / AK integrated mouth recess: geometry progress, not visual lock

`gel_mouth_recess_aj.gd/.tscn` inherits AI, refines shared body edges locally
with conforming incident-face splits, adds a 0.010-unit depression and
0.0022-unit lip in the existing body, and moves the existing mouth inset down
with the same deformation. No new nodes or imported-asset edits. Thickness
colors are interpolated, not re-baked, so physical thickness validation remains
pending. Source material uses triplanar mapping and has no UV array.

Initial `mouth-recess-aj/` run incorrectly assumed UV data, raised a Nil
duplicate error, and the generic shot rig still emitted screenshots and exit
0. Those images are INVALID candidate evidence. Fixed optional UV handling and
added `gel_mouth_recess_shot.gd/.tscn` to require `_aj_ready` before any capture.
A negative test with the AI scene exits 5 as intended, refusing baseline
screenshots. Artifacts and old candidates remain preserved.

AJ corrected run (`mouth-recess-aj-r2/`) completes 17 captures on explicit
4.7.2 Metal and verifies every undirected body edge has exactly two incident
faces: 98,681 vertices / 197,358 triangles. Closeups reveal severe triangular
highlight artifacts after regenerating normals on unevenly refined geometry;
AJ is rejected as a visual result, despite topology checks passing.

AK (`gel_mouth_recess_ak.tscn`) keeps AJ defaults reproducible, but selects
three refinement iterations and interpolates original smooth normals, then
transforms them by the inverse-transpose Jacobian of the analytic depth field.
It completes all 17 captures (`mouth-recess-ak/`) without script errors, with
45,291 vertices / 90,578 triangles and closed-edge checks. Viewed frontal and
70-degree mouth crops show a real recessed surround and substantially smoother
reflections versus AJ. Corners still show small bright irregularities, inset
ends remain too sharp, and cavity shading has an undesirable dull/greenish
band. This is a local improvement over AI's flat mouth but NOT reference-match
acceptance. No full-animation or multi-character performance claim is made.

Shipping R7.2 GLB SHA-256 remains
`3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3`;
`git diff --check` passes. Next geometry work should round the inset corners,
reduce lip artifacts, and embed the eyes; optics, internal flow, continuous
animation, fresh thickness and performance verification remain unfinished.

### AL rounded mouth and AM integrated eye surround

AL (`gel_mouth_recess_al.gd/.tscn`) preserves AJ/AK, removes the clamped
parabolic arch's derivative kink, reduces mouth depression to 0.006 and lip
peak to 0.0014, and replaces the existing dark mouth mesh with a fitted
257-vertex curved elliptical disk. No extra nodes. Initial and diagnostic
runs exit 2 before capture: the engine segment/triangle routine misses the
center at (0, 0.639) on the densely refined patch. A projected barycentric
intersection resolves all 257 positions; the audit counts 257 containing
triangles missed by the engine routine, minimum projected area
0.000000349905, barycentric tolerance 0.00001. This supports a small-triangle
intersection tolerance issue, not evidence of a hole in the body.

`mouth-recess-al-r2/` completes 17 captures on explicit Godot 4.7.2 Metal,
exit 0, no script errors. Frontal/70-degree crops show softer inset ends and
less abrupt lip transitions than AK. Some bright pinpricks and a dull cavity
band remain; no final mouth acceptance. Its body retains 45,291 vertices /
90,578 triangles; thickness re-bake and full motion remain pending.

AM (`gel_eye_socket_am.gd/.tscn`) adds a smooth 0.005-unit annular displacement
to the existing body around the measured lens half-axes (0.1148, 0.07344),
centers (+/-0.238, 0.855), rotations +/-38 degrees. It overrides the refinement
predicate to include the eye surrounds. AJ/AK/AL retain the old predicate and
their original default behavior. No eye mesh replacement or extra ring nodes.
AM verifies closed edge incidence with 83,006 vertices / 166,008 triangles.
`eye-socket-am/` completes 17 captures; `gel_eye_socket_shot.gd/.tscn` adds a
construction-ready gate and full left-eye crops at 0/40/70 degrees, completing
nine captures in `eye-socket-am-detail/`. Both runs use explicit 4.7.2 Metal,
exit 0, no script errors.

Visual judgment: the integrated surround is visible but too subtle to meet
the reference's embedded wet eye. The lens still reads as a convex black
insert with large white rectangular highlights. Do not promote AM merely
because geometry/runtime checks pass. The largest remaining mismatch is
opaque/waxy body optics and excessive lens reflections, not missing mouth
detail. Prioritize coherent jelly transmission/depth and eye lighting next;
retain the new geometry for further comparisons. GPU cost, thickness after
sculpting, both-eye continuous animation and all 14 animations remain open.

### AN actual opaque-background transmission and AO eye reflection cleanup

Inspection confirms the existing internal-depth field only modulated absorption
inside an opaque material. AN (`gel_transmission_an.gd/.tscn` and shader include)
adds screen-colour/depth inputs, a refracted estimated chord endpoint (IOR 1.36),
reverse-Z foreground rejection, coloured Beer attenuation and Fresnel-weighted
background radiance. ALPHA=1 routes to transparency while radiance composition
is explicit, with depth_draw_always. It retains geometry and lights/exposure,
but reduces the candidate surface scatter energy from 0.42 to 0.32. This is
screen-space, opaque-background-only refraction, NOT ray-traced mesh-bounded
transport. Off-screen/foreground-rejected rays currently fall back to black.
Transparent-object overlap/sorting and foreground-edge artifacts remain open.
Primary API references:
https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html
and https://godotengine.org/article/introducing-reverse-z/ .

AN native 4.7.2 Metal run completes nine full/eye captures (`transmission-an/`)
without script errors. On the black studio background the body still looks
opaque/waxy: a working feature does not prove reference fidelity.
`gel_transmission_probe.gd/.tscn` adds an explicitly diagnostic opaque checker
behind the subject and captures transmission weights 0/0.8/0 at fixed body
TIME=2. Initial `transmission-an-probe/` visibly demonstrates refracted coloured
background response, but freezing only the body made the independently moving
mouth disappear in that diagnostic. This is not a validated production motion
defect; the subsequent probe freezes all face shader TIME as well.

AO (`gel_eye_optics_ao.gd/.tscn`) preserves AN and duplicates only the two eye
materials, disables view-space and local catchlight additions, sets specular
0.29 and roughness 0.12, leaving the scene sky/lights unchanged. All nine captures
in `eye-optics-ao/` pass runtime checks. Viewed eye and full-body images show
the broad grey eye wash/overexposed reflection reduced, but the remaining
rectangular reflection is somewhat dull and the body still misses the luminous
orange reference. Retain as an experiment, not a final optical lock.

The corrected fixed-time probe with AO completes nine captures and exits 0.
`transmission-ao-probe/transmission-probe.json` measures the interior-body ROI
(340,580,340,120): all 40,800 pixels change >1/255 between off/on, peak channel
delta 0.34117648, mean maximum-channel delta 0.13407786. Repeated off capture
has zero changed ROI pixels and peak delta 0. These measurements prove a
repeatable background-transmission response only. They do NOT validate
foreground occlusion, multi-character composition, realistic scattering,
dynamic thickness, GPU cost, or visual acceptance. The probe now rejects wrong
capture dimensions/missing images before attempting fixed-ROI measurement.

Next priorities: screen-refraction foreground/overlap tests, diffuse/volume
lighting balance for the bright orange interior and thin luminous edge, and
motion validation. Do not mistake the conspicuous checkerboard response for a
finished jelly character. No release promotion or deletion occurred.

### AP / AQ single internal-reflection experiment

AP (`gel_internal_reflection_ap.gd/.tscn` plus include) adds one internal
reflection using a local convex-sphere normal construction, two traversals of
the current absorption estimate, and Schlick interface weights. It derives
the environment sample helper from the exact `gel_softbox_sky.gdshader` used
by the comparison rig. Lights, exposure, front-surface reflection, geometry,
screen-transmission weight and AO eye materials are unchanged. This is NOT
actual mesh-bounded transport, an exact dielectric Fresnel solution, or a
general runtime environment integration: it is tied to this studio sky and
does not account for arbitrary sky rotation/energy overrides.

All nine AP captures in `internal-reflection-ap/` complete on explicit 4.7.2
Metal, exit 0, without script errors. Viewed front shows orange internal light
but recognisable hard-edged softbox patches on the torso/limbs. Reject AP as a
final visual result; additional radiance alone did not produce soft jelly.

AQ (`gel_internal_reflection_aq.gd/.tscn`) retains AP and averages the internal
sky over a 0.22 angular footprint, nine samples with weights summing to one,
without raising gain. All nine `internal-reflection-aq/` captures complete,
exit 0, no script errors. Frontal comparison shows softened internal patches
and a warmer/brighter right torso than AO. Still visibly waxy, with broad
front highlights and dull/greenish limb creases; not reference-match acceptance.
The nine-sample filter has added shader cost which has NOT been GPU-profiled.
No promotion, imported mesh edits or prior-version deletion occurred.

Keep this as evidence about an internal-light contribution, not a claim that
the full optical problem is solved. Geometry-aware path lengths, front-surface
roughness/reflection balance, lighting contributions to the dull creases,
foreground/overlap tests, continuous flow/movement and valid GPU measurements
remain open. `git diff --check` passes after these candidate additions.

### Optical decomposition: dull limb contribution localized

`gel_optical_components_shot.gd/.tscn` freezes all body/face shader TIME=2,
keeps camera/exposure/light energies fixed, and separately disables surface
reflection, internal reflection, or neutralizes directional light colors.
Initial `optical-components-aq/` completes 12 captures; extended
`optical-components-aq-r2/` completes 13, adding direct-transmission-off. All
run with explicit 4.7.2 Metal, exit 0, no script errors. Baseline is restored
at the end (no numerical repeat-image comparison yet).

Viewed no-surface, neutral-light and neutral/no-surface images retain dull
inner-arm regions. Thus neither surface reflection nor blue light color alone
explains the defect. The direct-transmission-off diagnostic replaces the
greyish regions with darker amber/orange, localizing a significant contribution
to the direct transmitted-light term. Disabling this term is NOT an accepted
fix: that would remove desired jelly light transport.

AR (`gel_chord_control_ar.gd/.tscn`) isolates the view-angle thickness factor,
using the normal-direction bake without cosine multiplication. Nine captures
in `chord-control-ar/` complete successfully. It reddens/darkens the silhouette
but does not remove dull limb regions. Reject as a full correction.

AS (`gel_light_path_as.gd/.tscn`) preserves AQ and changes only direct-light
attenuation: the exponent is half of (1 + abs(NdotL)/max(abs(NdotV),0.025)),
an incident/outgoing local-convex chord approximation, without disabling or
reducing transmission energy. Nine `light-path-as/` captures complete, exit 0,
no shader/script errors. Viewed front still has dull limb regions: this
approximation is insufficient; do not promote it as a solved defect.

Source also confirms body.cast_shadow is OFF in authored_jelly_body.gd, while
the shot key light enables shadows. The newer transparent body additionally
cannot serve as an ordinary opaque shadow caster. Missing mesh-aware incoming
light path / torso occlusion is a concrete next hypothesis, not yet a proven
root cause. Measure that contribution against actual geometry before adding
more cosmetic hue/brightness changes. Do not simply turn off all transmission
or add an opaque proxy and claim physically correct translucent shadows.
All older candidates remain; release assets are untouched.

### Actual incident-path probe: coordinate repair and first measurements

`gel_incident_path_probe.gd/.tscn` now converts Camera3D logical viewport
coordinates to capture pixels before selecting triangle centers. The failed
initial, diagnostic and r2 runs remain preserved; waiting eight frames did NOT
fix their selection failure. r3 reports logical viewport 1920x1920 versus
1024x1024 image readback, establishing the coordinate mismatch.

`incident-path-probe-aq-r3/incident-paths.json` records six rest-mesh samples,
18 directional-light paths and two intersection scales (50 and 100). Native
4.7.2 / Metal / M4 Pro run exits 0; every path has consistent crossing parity
and agrees across scales. Selection errors are 0.59–3.47 capture pixels.
No material or release geometry was changed by this diagnostic.

Measured rim-light material lengths at the four arm samples are 0.533, 0.342,
0.417 and 0.315 scene units, versus the existing camera-chord estimates 0.312,
0.144, 0.344 and 0.157. These are different directional quantities: they must
not be substituted universally or called equivalent optical depths. The lower
right sample additionally crosses a separate body interval of length 0.494
toward the fill light despite its surface facing that light (NdotL 0.999).
This supports the missing incoming-path / self-occlusion hypothesis at that
sample, but does not prove it explains the full visible grey defect.

Scope limits: undeformed triangle centers, no refraction in the intersection
ray, no dynamic deformation, and no full visible-surface occlusion test for
sample selection. Scale agreement is numerical consistency, not independent
ground truth. Next experiment should apply a mesh-aware incoming attenuation
in an isolated fixed-light candidate, compare against AQ at identical time,
then validate moving geometry before considering production use. Keep the
transmission effect; do not hide the defect by disabling it.

### Whole-mesh incoming bake and fixed-front comparison harness (in progress)

The probe now exports numeric positions/normals/indices/directions into
`incident-path-probe-aq-r5/rest-mesh.json`. r5 completes natively, exit 0.
r4 encountered a GDScript inferred-type parse error; its process was stopped,
the local variable explicitly typed, and check-only passed before r5.

`tools/meshy/bake_incident_paths.py` uses VTK OBB intersections from just inside
each vertex, sums material intervals while excluding air gaps, and rejects
even crossing parity. It writes a new report only, preserves prior artifacts,
and includes a source hash. This full bake was launched as exec session 91557,
PID 77610, and is still running at this note (50,000 / 83,006 vertices,
zero parity failures so far). Revalidate that SAME session before any restart;
partial progress is not a completed valid bake. The first running version uses
the now-deprecated VTK SetCells API, which emitted a warning, not a failure.

`tools/meshy/test_incident_paths.py` passes three analytic controls: single-body
exit, separated-body material sum excluding the air gap, and rejecting an
outside-origin even-crossing case. Its accumulator was extracted after launch;
the running bake already holds the mathematically identical inline version.

`gel_mesh_light_path_shot.gd/.tscn` is prepared and GDScript check-only passes.
It requires a valid bake, matching source hash and per-vertex positions; uses
a float lookup texture without modifying geometry or existing UVs; compares
baseline, incoming attenuation, incoming plus surface attenuation, repeat
baseline at fixed front orientation/time. Runtime shader compilation, visual
comparison, and repeat-frame checks remain NOT RUN. This is a unit-density,
straight-ray diagnostic, not an animated production solution. No new visual
improvement is claimed yet. Shipping GLB hash remains unchanged.

### AT fixed-front mesh-path results: completed, not a visual fix

Session 91557 is TERMINAL, exit 0: all 83,006 vertices / 249,018 light rays
completed with zero parity failures. The report is
`incident-path-probe-aq-r5/incident-bake.json`. No need to restart that bake.
The fixed-front harness additionally checks actual scene light directions and
pivot orientation before applying the data.

Native session 19426 is TERMINAL, exit 0. `mesh-light-path-at/` contains 17
captures, including four mesh-path comparisons after the AQ decomposition.
The existing baseline and patched-but-disabled baseline differ by at most one
8-bit channel level. Disabled repeat is pixel-identical (max difference 0).
Combined incoming/occlusion changes 251,002 pixels, max channel delta 75/255.
These establish that the new light path is active and the comparison repeats;
they do not establish visual improvement or physically accurate scattering.

Viewed baseline and combined images: some foot/edge coloration changes, but
dull grey/olive inner-arm regions remain and the material is still waxy with
broad white reflection bands. Therefore actual straight-ray incoming material
length alone does not resolve the defect. Do NOT promote AT as a quality fix.
The reference still has much stronger luminous orange body, yellow thin rims,
irregular wet highlights and better integrated eye/pore/mouth details.

Next: re-evaluate absorption/scattering calibration against those reference
relationships, using the completed geometry evidence rather than further
unverified chord approximations. Fixed-light rest baking is not suitable for
shipping movement; dynamic lighting/deformation validation remains required.
All old candidates and release geometry remain unchanged.

### AU absorption/scattering calibration: reject simple saturation fix

`gel_absorption_calibration_shot.gd/.tscn` runs fixed-time AQ controls without
changing lights, exposure, geometry, or the production shader. Native sessions
59705 and 29662 both completed, exit 0, under pinned 4.7.2 / Metal.
`absorption-au/` preserves the initial seven calibration frames plus the parent
controls; `absorption-au-r2/` contains 23 total captures including ten calibration
frames. Baseline versus restored baseline is pixel-identical (max delta 0).

Tested sigma (.095,2.8,12) and (.095,4.5,16), baseline scatter .32 and increased
scatter .64. Viewed combined cases become excessively red/saturated and retain
plastic-looking reflection bands: NOT an accepted correction. Moderate sigma
(.095,1.8,12), scatter .42, and absorption coupling 1/.5/0 further isolate the
surface-tint coupling. Viewed .5 and 0 cases brighten toward orange/yellow but
remain waxy, with olive/dull underarms; do not claim reference match.

This rules out promoting a simple global saturation/brightness adjustment.
Next investigate surface highlight structure with the now-cubic height filter:
the reference's irregular wet relief versus current broad smooth studio bands.
That filter was introduced after earlier high-relief failures, so its useful
relief range needs a controlled visual test. Maintain color controls and do
not conflate those changes with fluid motion, which remains unvalidated here.
All candidates and shipping geometry remain preserved.

### AV cubic relief / gloss controls: coarse relief is cleaner, still not matched

`gel_relief_calibration_shot.gd/.tscn` isolates authored height depth, texture
scale, and body roughness on fixed-time AQ. Pinned native sessions 19724 and
85741 completed, exit 0. `relief-av/` preserves the first sweep;
`relief-av-r2/` has 23 captures and baseline-repeat max pixel delta 0.

Actual runtime baseline height scale is 0.36 (not the shader default 0.75),
depth .0016 and body roughness .17. Tested depths .004/.008, roughness .17/.07,
then scales .30/.20 with roughness .10. Lighting, absorption, geometry, and
face materials remain unchanged. The shader skill guided independent material
parameter controls and retaining a repeat baseline.

Viewed medium/strong gloss cases break up the broad highlights but introduce
coarse jagged bright patches; do not promote them. The .20-scale/.004-depth/.10
roughness image has larger, less granular relief, but broad white bands, waxy
body and dull inner arms remain. No complete reference-match improvement is
claimed. Finer texture strength alone is not a solution.

Source inspection confirms bump_normal still derives height slopes using
screen-space dFdx/dFdy. Cubic reconstruction smooths sampled height, but does
not itself replace the screen-quad derivative operator. Whether that operator
contributes to jagged strong-relief highlights needs an isolated gradient
comparison before adopting more expensive filtering or stronger bump values.
Keep the coarser relief image as a comparison, not a shipping promotion.

### AW spatial height gradient: visible edge-smoothing, not full material acceptance

`gel_gradient_probe.gdshaderinc` evaluates six centered object-space filtered
height samples, then maps their slopes through the existing view-space surface
basis. It replaces only the authored-height bump call. Triplanar blend normal
is held constant for spatial samples; this is not an exact derivative of all
varying normal/blend terms. It still uses derivatives for surface coordinates
and mip selection, so do not describe it as entirely derivative-free.

`gel_gradient_probe_shot.gd/.tscn` uses AQ, fixed time 2, scale .20, depth .004,
roughness .10, unchanged lights/color/geometry. Native session 45142 completed
exit 0 (`gradient-aw/`, 17 captures). Screen-gradient repeat is pixel-identical.
Spatial steps .0005 versus .001 have mean channel difference .02335/255 and
max 16/255 across the image; their closeness is not proof of analytic accuracy.
Spatial versus screen changes 138,369 pixels. Viewed spatial frame has smoother
highlight boundaries than the visibly stair-stepped screen-gradient control.

Session 58875 also completed exit 0 (`gradient-aw-r2/`, 23 captures), adding
screen/spatial pairs at yaw 0, .5 and 1 degree. Viewed 1-degree spatial image
retains smoother boundaries. These are discrete stills, not a passed temporal
shimmer, fluid-animation or GPU-performance test. The six extra triplanar
samples are expensive (up to 144 additional texture taps before compiler
optimization); do not ship this diagnostic without cost/quality evaluation.

The result supports a real gradient-related contribution to highlight jaggies.
Broad white studio bands, waxy core, dull arms and reference silhouette/facial
differences remain. Preserve this as a useful diagnostic improvement, not an
accepted whole-character solution. Next separate environment highlight shape
from material relief, while retaining this smooth-gradient comparison.

### AX environment shape isolation

`gel_environment_shape_shot.gd/.tscn` inherits AW's smooth spatial-gradient
control, resets front orientation, and changes the engine sky and the embedded
internal-reflection sky together. Anchor-count checks reject mismatched source
updates. Five controls: baseline, narrower softboxes, side-oriented softboxes,
side+narrow, restored baseline. Peak radiance stays constant; narrower boxes
reduce integrated environment energy, so this is NOT an equal-energy test.
Directional lighting, exposure, body material values and geometry stay fixed.

Native session 54672 completed exit 0 under pinned 4.7.2 / Metal; 28 captures
are preserved in `environment-ax/`. Baseline repeat max pixel delta is 0.
Viewed narrow and side frames confirm large white reflection bands follow
environment width/location, not only height relief. Narrow reduces band width;
side relocates highlights toward the contour but leaves face/eye reflections
too dark. Waxy/dull body regions persist. Neither is accepted as a full fix.

Next balance face readability against contour highlights using a deliberately
structured environment, and verify across actual gameplay lighting before
adopting a studio look. This work changes diagnostic rigs only; no shipping
model, saved older candidate or production sky was overwritten.

### AY small frontal reflectors with side/narrow environment

`gel_face_fill_shot.gd/.tscn` tests side/narrow AX plus two small warm-neutral
world-space softboxes centered at (+/-.45,.45,.80), size (.12,.16). Intensities
0/2/6/12/0 affect both the real sky and the internal-reflection approximation.
Eye shaders are unchanged: any new eye highlights are environment reflections,
not painted emissive dots. This adds illumination energy, not an equal-energy
material comparison. Parent controls and older outputs are retained.

Native session 60710 completed exit 0, pinned 4.7.2 / Metal. `face-fill-ay/`
has 33 captures. Zero-intensity restored repeat is identical (max delta 0).
Intensity 12 changes 217,439 pixels versus zero. Viewed 12 image restores
small eye catchlights without the original broad frontal reflection stripes,
but also creates visibly paired forehead/cheek patches. Waxy body, grey/olive
arm regions and the full reference mismatch remain. Keep as a look-development
candidate; do not claim accepted model quality or game-lighting robustness.

Next inspect this candidate from side/three-quarter views before further
fine-tuning. Current evidence is fixed-front/time only; avoid optimizing a
single still at the expense of gameplay appearance. No shipping resources,
old candidate or release GLB were replaced.

### AY multi-angle inspection

The face-fill rig now captures yaw -35/35/90/180 for zero and intensity-12
fill, restoring the front orientation between controls. Native session 24257
completed exit 0. `face-fill-ay-r2/` contains 41 captures; zero-repeat remains
pixel-identical (max delta 0). No live bake/render sessions from this run remain.

Viewed intensity-12 at 35, 90 and 180 degrees. These stills show no obvious
catastrophic collapse or detached satellite particles, but this does NOT pass
the animation/no-collapse requirement. The side view exposes a thick solid/
waxy body appearance and dull greenish arm borders; three-quarter has thin
bright facial borders and still-unresolved model/reference proportions.
Reflector changes improve catchlights but do not deliver internal liquid feel.

Next stop micro-tuning the fill rig and examine the volume-scattering term.
The current direct-light surface term is a tinted wrapped diffuse response
multiplied by camera throughput, rather than accumulated scattering along a
volume path. Test an integrated scattering alternative independently, retaining
AY lighting and AW gradient controls. Any approximation must be labeled and
validated rather than called a physical fluid simulation. Shipping unchanged.

### AZ uniform-incident volume integral: rendered, rejected as cloudy

`gel_volume_integral_shot.gd/.tscn` isolates a single-scattering integral:
sigma_s/(sigma_a+sigma_s) * (1-exp(-(sigma_a+sigma_s)*density_depth)). It uses
the existing eight-sample estimated optical depth, includes scattering loss
in transmission, and replaces wrapped surface tint with the integral. It
retains wrapped angular weighting and assumes uniform incident radiance;
therefore it is NOT a physically complete incident/outgoing transport model.
Inherited AY ends at zero frontal fill, so these comparisons use the fixed
side/narrow environment without the intensity-12 eye fill.

Native session 73258 completed exit 0, pinned 4.7.2 / Metal. `volume-az/`
contains 46 captures, including baseline, integral, stronger absorption,
stronger absorption/unit gain, restored baseline. Repeat max delta 0.
A numerical trapezoid control at depth .8, sigma_a (.095,2.8,12), sigma_s 1
agrees with the closed form to 6.94e-11 (CPU mathematical formula only, not
proof of full GPU scattering correctness).

Viewed integral/amber and unit-gain images become dull brown or milky/pastel,
not luminous orange jelly. Reject as a visual fix; do not promote. Increasing
gain only brightens the wrong material appearance. One explicit limitation is
the uniform unattenuated incident field: incoming absorption to each scattering
location is absent. Next couple incoming attenuation to scattering locations
using actual geometry evidence where possible, instead of another gain sweep.
All shipping resources and older artifacts remain preserved.

### BA sparse interior incoming/outgoing path integration

`tools/meshy/probe_scattering_paths.py` reconstructs the six sampled triangle
centers from the preserved rest mesh and uses the recorded front camera
(0,1.898,4.453). Straight view rays stop at the first actual mesh exit. For
8/16/32 interior midpoint samples, each directional-light ray accumulates
actual material intervals to the exterior, excluding intervening air gaps.
Any invalid crossing parity aborts. No full vertex bake was restarted.

Session 30091 completed exit 0. The new immutable report is
`incident-path-probe-aq-r5/scattering-paths-ba.json`, containing 18 sample/light
combinations with unit density, sigma_a (.095,2.8,12), sigma_s 1. Incoming and
outgoing attenuation are both evaluated at each location. Maximum absolute
16-to-32-sample integral difference is .002997; convergence is not an exact
solution or proof for arbitrary geometry. Scope excludes refraction, phase,
Fresnel, light energy/color, animated shape and the procedural fluid density.

For right-lower-arm sample (740,605), fill-light index 1, the coupled/uniform
incident RGB ratios are (.433694,.066441,.000397689). This supports a strong
chromatic error from omitting incoming attenuation in AZ, not a universal
correction ratio to apply over the whole character. Other samples differ.
These are transport-factor measurements, not rendered pixel colors.

Next produce mesh-aware interior incoming-distance data usable by the shader
(for example a bounded volume lookup), validate it against these sparse paths,
then render a coupled integration comparison. Do not paint six measured ratios
onto the character or claim reference quality based only on these numbers.
No new visual candidate or shipping change was made in this diagnostic.

### BB incoming volume lookup: two resolutions fail boundary accuracy gate

`tools/meshy/build_incoming_volume.py` voxelizes the preserved actual mesh,
integrates occupancy along the three fixed light directions, and exports
RGBA32F (RGB incoming material lengths; A occupancy). Bounds include .05
padding; samples at grid endpoints correspond to texel centers. Payload order
is z/y/x/RGBA, x fastest. Source and payload hashes are recorded. No existing
output directory may be overwritten. This is a rest-mesh unit-density lookup,
not animated lighting or a physically complete scattering solution.

48-cubed output `incoming-volume-bb48/`: session 71300 TERMINAL exit 5,
576 interior validation rays, mean absolute length error .008077, max .129130.
64-cubed `incoming-volume-bb64/`: session 91544 TERMINAL exit 5,
mean .006029, max .125901. Both fail the unchanged sparse length gate
(mean < .01 AND max < .04). Their manifests valid=false; do not load them as
validated shader inputs. Original failed evidence is preserved.

Added worst-sample recording before the 64 run. Largest error is left lower
arm target (290,605), layer 9, key-light direction: exact .050430 versus lookup
.176331. Nearby layer 11 jumps to exact .286589. This supports an unresolved
shadow-boundary / trilinear smoothing problem, not simply a uniform scaling
error. Mean improvement alone is insufficient; blind global resolution growth
is not accepted as a fix. The volume data has NOT been connected to a shader.

Next evaluate local refinement around this boundary and the resulting coupled
scattering error, retaining exact ray comparisons. Keep boundary cases in the
gate, rather than dropping troublesome samples or relaxing thresholds to pass.
No rendering improvement or shipping change is claimed this turn.

## BC exact boundary convergence

Added `tools/meshy/probe_incoming_boundary.py`; evidence is preserved in
`outputs/v8.6-quality-audit-20260906/incoming-boundary-bc/report.json`.
513 exact full-mesh rays along a 0.06-unit line through BB64's worst point
completed with valid odd crossing parity. Source hash is checked against BB64.
The measured path rises from .05056 at offset .000117 to .17188 at .001523;
crossing counts vary from 1 to 9 as the ray encounters additional material
intervals. This establishes a very sharp geometric transport feature, not a
constant calibration offset. Multiple ray intervals do not by themselves prove
disconnected geometry or visible fragments.

One-dimensional exact-distance interpolation convergence:
- spacing .015: maximum error .10103;
- spacing .00375: maximum error .05965;
- spacing .001875: maximum error .02606;
- spacing .00046875: maximum error .01037.

These are nested samples on one line only, not validation of a refined 3D
volume. Error is not strictly monotonic at every resolution. A uniform 64-cube
grid has spacing .01746–.02762, far coarser than this measured feature; merely
increasing it a little is unlikely to resolve this boundary. Next evaluate a
light-aligned interval representation or genuinely local refinement, with all
576 existing validation paths plus independent boundary samples retained.
No shader integration, animation acceptance, GPU-performance acceptance, or
shipping visual improvement is claimed. Existing versions remain untouched.

## BD sparse exact-corner refinement feasibility

`tools/meshy/probe_local_incoming.py` evaluates trilinear interpolation of exact
full-mesh ray distances at surrounding grid corners, retaining all 576 BB
interior light-path queries. Outside corners use even crossing parity with the
far endpoint outside the mesh; this is a different approximation from BB's
integrated voxel occupancy. Evidence:
`outputs/v8.6-quality-audit-20260906/local-incoming-bd-r2/report.json`.

- .004 spacing: mean .00022824, max .07391836, fails original distance gate.
- .002 spacing: mean .00013470, max .05988098, fails original distance gate.
- .001 spacing: mean .00004480, max .02036016, passes original distance gate.

This establishes sparse feasibility of exact-corner local sampling; it is NOT
a baked full 3D texture, an adaptive refinement algorithm, an independent
holdout test, animated-light support, or rendered acceptance. Before shader
integration, select/refine cells without consulting validation answers and
test additional boundary locations. Avoid a uniformly .001-spaced full volume.

First run terminated with a NumPy boolean JSON serialization error at the
passing third row. Explicit Python bool conversion fixed it; rerun completed
exit 0 and persisted all three rows. No shipping material/model changes.

## BE held-out spatial sampling

Extended `probe_local_incoming.py --holdout` with seed 20260907 fixed before
execution. The .001 spacing was selected from BD, not retuned on these points.
Added 128 uniformly sampled interior points plus 128 points within .015 units
per axis of the known difficult boundary, each with all three fixed lights.
Retained all original 576 queries, giving 1,344 total and 768 held-out paths.
Evidence: `outputs/v8.6-quality-audit-20260906/local-incoming-be-holdout/report.json`.

Exact-corner interpolation passes the unchanged distance gate: combined mean
.00014499, max .02201981; holdout mean .00022012, max .02201981. Total 10,683
unique corner rays. The worst point is a held-out key-light boundary sample,
not removed. Three existing incident-path unit controls also pass.

This strengthens fixed-light rest-mesh interpolation feasibility only. The
boundary subset is deliberately targeted, not a random whole-character
quality guarantee. No adaptive cell selection/storage, complete volume, shader
integration, deformation support, or rendered reference match is established.
The next implementation must make this precision practical without allocating
a uniform millimetre-scale full-character 3D grid. Shipping assets unchanged.

## BF complete key-light interval tree, validation fails

Added `build_light_intervals.py`: light-aligned 2D quadtree stores exact paired
mesh crossings instead of a dense 3D distance field. Bilinear interpolation is
applied to remaining material length, not to potentially mismatched interval
endpoints. Refinement tests center and four edge midpoints at the union of all
piecewise-linear depth breakpoints, with minimum depth 5, maximum 10, error
target .01; selection never consults BD/BE validation values.

Preserved `outputs/v8.6-quality-audit-20260906/light-intervals-bf-key/`:
- 112,437 rays, 33,749 nodes, 25,312 leaves, at most 8 crossings per ray;
- full JSON payload 8,052,711 bytes, SHA256
  `fb4f9aa7596157ebe61824b71ce1e4e268c02ae8c3a703682e3a4ad53753882d`;
- 4,335 terminal cells still exceed the internal .01 refinement target;
  worst internal residual .05856. Successful build exit 0 is NOT acceptance.
- independent reader verifies mesh/payload hashes and tests all 448 key-light
  original plus held-out paths: mean .00110881, max .04947116, fails unchanged
  .04 maximum gate, validation exit 5. Worst remains original left-arm point.

Three new unit tests cover empty rays, air exclusion, and exact interval
endpoints; all pass. No GPU integration or rendered improvement yet. Next
refine unresolved leaves from this preserved tree instead of rebuilding all
coarse rays, then revalidate before creating fill/rim data. Existing versions
and shipping materials remain unchanged.

## BG resumed key-tree refinement

Builder now supports `--resume` and `--max-depth`, verifies source/payload/light
and basis/bounds, rescales integer coordinates, and refines only unresolved
leaves. Preserved BF remains untouched. BG adds 79,470 rays to 112,437 saved
rays; 51,089 nodes, 38,317 leaves, max depth 11, max 10 crossings. JSON payload
12,930,148 bytes, SHA256
`c288a3f6896af8420d6808169cfb5c9b95237ad9480729ea64c852c90cddac8a`.
Evidence: `outputs/v8.6-quality-audit-20260906/light-intervals-bg-key/`.

All 448 original/held-out key-light paths pass the unchanged distance gate:
mean .00078731, max .02533631 (previous max .04947116). Four interval tests
pass, including coordinate rescaling and bilinear lookup. Build and validation
both exit 0. However, 3,829 terminal cells still exceed the internal .01 target,
worst .05543: the sparse validation result is NOT full-domain certification.

Next pack this key-light tree for an explicitly diagnostic rendered comparison,
keeping unresolved-cell limitations visible, before spending on additional
light bakes. A key-only A/B can test whether coupled incoming scattering moves
the actual image toward the reference; it cannot be promoted as a complete
material. Still no visual, animation, performance, or publishing acceptance.

## BH actual GPU interval-transport comparison: visually rejected

Added `pack_light_intervals.py`, `gel_interval_transport.gdshaderinc`, and
`gel_interval_transport_shot.gd/.tscn`. BG tree packed into nearest RGBA32F
node/ray textures totaling 4,800,512 bytes, no source-color conversion. Runtime
verifies payload hashes. CPU tree packing is diagnostic; GPU numeric readback
is not yet checked. World light-plane traversal and paired intervals feed a
16-sample unit-density, straight-view-ray scattering integral on KEY light
only. Fill/rim and other reflection/transmission layers remain unchanged. The
existing estimated view chord is still used, not a true mesh-bounded chord.

Pinned Godot 4.7.2 Forward+ Metal Apple M4 Pro run completed exit 0; 17 captures
in `outputs/v8.6-quality-audit-20260906/interval-render-bh/`, including baseline,
uniform incident field, coupled incoming attenuation, baseline repeat.
Headless script parse also passes. Baseline/coupled/reference images inspected.
Coupled output is dull mustard/brown with pronounced olive-grey hands/feet,
still broad white reflection streaks and waxy body. It does NOT match the
luminous saturated orange reference and is rejected for promotion. This
demonstrates numeric light-path accuracy alone does not deliver the desired
look; sigma calibration and mixing with existing lighting remain unresolved.

Do not spend on fill/rim bakes before this actual rendering failure is
understood. Next isolate scattering color versus retained layers, with matched
lighting controls and image comparisons. All prior models/materials preserved.

## BI key-scattering color versus retained layers

Added `gel_scatter_isolation_shot.gd/.tscn`, inheriting BH. Separate `bi_sigma`
changes ONLY key-light scattering extinction, leaving absorption used by other
layers untouched. Cases compare original, amber (0.095,2.8,12), stronger
(0.095,4.5,16), uniform amber, amber without direct transmission, and amber
without body environment/internal reflections, then original repeat.

Pinned 4.7.2 Forward+ Metal run and headless parse exit 0. Preserved 24 PNGs:
`outputs/v8.6-quality-audit-20260906/scatter-isolation-bi/`. Inspected amber,
no-direct-transmission, and no-reflections images. Amber alone remains brown
and olive-grey; removing reflections retains the grey hands/feet. Removing
direct transmission visibly reduces grey in hands but makes the body darker
brown. This implicates the retained approximate direct-transmission layer in
the undesirable color, without proving it is the only source. Merely disabling
that layer is not a fix: desired luminous translucency is still absent.

Next revise the transmission model consistently with scattering, rather than
calibrating only the key scattering term or compensating with saturation.
No visual candidate accepted; no shipping edits or version removal.

## BJ shared extinction and brightness control: still rejected

Added `gel_shared_extinction_shot.gd/.tscn`. Shared amber sigma drives both
key scattering and retained absorption, with optional +1 scattering loss in
`v_through`. Existing density-based approximate depth and directional formulas
remain; this is coefficient consistency, NOT a complete transport solution.
Scatter gain .32 versus 1 is explicitly varied, not silently compensated.

Pinned 4.7.2 Forward+ Metal and headless parse exit 0. Thirty PNGs preserved in
`outputs/v8.6-quality-audit-20260906/shared-extinction-bj/`; original repeat has
zero pixel delta. Shared-total, shared-total-gain, and absorption-gain images
inspected: low gain dark orange-brown; gain 1 restores brightness but produces
creamy pastel/plastic appearance. Grey/olive bands on hands/feet remain. None
is accepted as reference match. No shipping changes or deletion.

Next prioritize numeric GPU-versus-CPU lookup parity and estimated view-depth /
angular transport diagnostics before further color sweeps. The offline tree
validation does not yet prove actual GPU samples equal offline values; do not
treat successful shader compilation and changed pixels as that proof.

## BK actual GPU helper readback parity passes

Added `prepare_interval_gpu_check.py` and `gel_interval_gpu_check.gd`. Uses
unchanged BH lookup helper in an unshaded, blend-disabled canvas pass, identical
packed textures and verified hashes. Reads back 24-bit encoded material length
from a 64x16 SubViewport, with four encoding controls followed by 512 broad-box
and 508 boundary-neighborhood float32 query positions (seed 20260908).
CPU reference evaluates the preserved BG tree at those same float32 positions.

Evidence: `outputs/v8.6-quality-audit-20260906/interval-gpu-bk/`, including query
payload, expected values, and complete GPU readback/error arrays. Native pinned
4.7.2 Forward+ Metal Apple M4 Pro exits 0, as does headless syntax check.
1,024 values: maximum absolute difference .00001377778713, encoding-control
maximum .00000005960465. Passes declared .001 lookup / .000001 control limits.

This verifies packing/upload/traversal/helper evaluation at supplied positions,
NOT the spatial material's generation of those positions, correctness of the
estimated view chord, full-domain exact mesh accuracy, or reference appearance.
Next inspect estimated view depth and spatial coordinate generation at the
problematic rendered samples; color sweeps are not justified by this result.
No shipping assets changed and all previous evidence retained.

## BL actual fragment depth diagnostic

Added `gel_spatial_depth_probe.gd/.tscn` and `compare_spatial_depth.py`. Encodes
actual fragment world position, estimated depth, baked chord, and abs(NdotV).
First parse found `_out` typo (fixed to `_out_dir`). First native run produced
black controls because the diagnostic used EMISSION with unshaded mode; no
values from that failed run are accepted. Changing diagnostic output to ALBEDO
with inverse sRGB conversion yields valid .125 and 1.5 controls at all six
sample pixels. Failed `spatial-depth-bl` and successful `spatial-depth-bl-r2`
remain preserved. Successful native pinned Metal run exits 0.

Compared six decoded fragment points against camera [0,1.898,4.453] rays through
rest mesh. Estimated/first-chord ratios for targets (278,570), (290,605),
(752,570), (740,605), (510,610), (510,350): .859, .722, .962, .650, .875, 1.070.
In particular lower-arm estimated lengths .14669/.16700 versus static camera
chords .20329/.25702 suggest appreciable underestimation, consistent with too
little attenuation. However decoded surface versus mesh entry differs by
.00096–.00549 world units. This may include deformation, sampling/encoding, or
camera mismatch; exact spatial correspondence is NOT yet established. Do not
claim these ratios prove the sole cause of the visual problem.

Evidence: `spatial-depth-bl-r2/spatial-depth.json` and `comparison.json` under
the audit output directory. Next resolve surface correspondence and replace
the normal-scaled baked chord with a mesh-bounded view-path diagnostic, not
six hand-tuned per-pixel multipliers. No shipping material changes.

## BM rest-pose correspondence isolates deformation mismatch

Added `probe_rest_pose` option and `gel_spatial_rest_probe.tscn`. Diagnostic
restores the original VERTEX/NORMAL at the end of the body vertex function;
shipping liquid animation is untouched. Actual viewport metadata reports
MSAA=0, screen-space AA=0, TAA=false, so AA mixing is not the explanation in
this run. All encoding controls pass. Pinned native Metal run exits 0.

Evidence: `outputs/v8.6-quality-audit-20260906/spatial-rest-bm/`.
With deformation bypassed, surface-to-rest-mesh camera-ray entry errors shrink
from BL's .00096–.00549 to 1.17e-7–5.57e-7. This strongly identifies vertex
deformation as the BL correspondence difference. Estimated/true straight-view
chord ratios remain .871, .713, .948, .638, .875, 1.071 at the six targets.
Lower-arm depth estimates .14487/.16397 versus true .20329/.25701 are therefore
genuine rest-pose approximation errors, not a framebuffer coordinate offset.

Next implement a separate first-backface camera-depth diagnostic to replace
the normal-scaled chord in a controlled A/B, with actual deformed geometry in
both front/back passes and all previous poses preserved. This could support
motion; it still needs concavity/coverage and numeric checks before acceptance.
No claim of refracted-path correctness or reference-match completion.

## BN first-backface depth implemented; concavity artifact blocks acceptance

Added `gel_backface_depth_shot.gd/.tscn`. Independent 1024-square SubViewport
renders the same body mesh/transform with front culling and matching camera,
encoding camera distance. Decoded RF texture replaces normal-scaled depth with
back distance minus front-fragment distance. Both body passes use rest pose;
other face parts are not restored, so rest-pose feature fit is not acceptance
evidence. This is a fixed snapshot/readback diagnostic, not live animation.

Pinned native Metal and headless parse exit 0. Evidence preserved in
`outputs/v8.6-quality-audit-20260906/backface-depth-bn/` (20 PNGs plus depth JSON).
Six backface-derived depths match independent mesh chords to max 2.97e-6 units.
Estimated/repeat image pixel delta is zero. Inspected actual estimated and
backface renders: backface reduces some hand greyness but adds a conspicuous
arch-shaped pale band above the gap between the feet; still wax/plastic overall.
No visual promotion. Six-point correctness does not validate concave coverage.

Next inspect front/back pairing and thickness discontinuities in that concavity,
including coverage/incomplete-path handling in the old transmission model.
Do not blur or hand-mask the band merely to hide it. Animated geometry and
all face parts must share the same pose before a motion comparison is valid.
Shipping assets and all previous versions remain untouched.

## BO concavity-grid validation and transmission isolation

Extended BN export with 1,147 camera rays over x=420..600,y=630..780 at 5-pixel
spacing, using the offscreen camera's pixel-center directions. Extended
`compare_spatial_depth.py --backface-grid` to compare GPU back distance with
exact second mesh crossing, retaining misses and multi-interval rays.
`outputs/v8.6-quality-audit-20260906/backface-grid-bo/comparison.json` records
max error .00005434, mean .000003912; 9 rays have multiple material intervals.
Center x=510 has one material interval and continuously decreases from depth
.8332 at y630 to .0135 at y745, then misses from y750 onward. This argues against
a spurious first-backface pairing jump as the cause of the central arch.

Added backface/no-direct-transmission image control; preserved rerun in
`backface-grid-bo-r2/` (21 PNGs). Native runs exit 0. Inspected no-transmission
image: grey/white intensity diminishes, but the arch-shaped tonal boundary
remains. Thus direct transmission amplifies the issue but is not its sole
source; remaining depth-dependent surface/internal response also matters.
Do not claim disabling transmission fixes the artifact or that the grid proves
whole-image correctness. Next isolate remaining depth-dependent terms before
replacing the response; no hand mask, blur, shipping edits, or asset deletion.

## BP actual spatial shader sampling parity

Added `gel_backface_sampling_probe.gd/.tscn`; evidence in
`outputs/v8.6-quality-audit-20260906/backface-sampling-bp/`. Encoded readback
from the main spatial shader covers 1,027 body pixels in the tested concavity
region. Maximum sampled back-distance error versus the depth texture is
3.0741e-7; control error is 8.9407e-8. Actual shader depth versus independent
mesh chord has maximum error 5.5644e-5. This excludes a texture-orientation or
front-subtraction error at those tested locations, not across all animation.

## BQ depth-response decomposition identifies surface-tint contribution

Added `gel_depth_response_shot.gd/.tscn`; evidence in
`outputs/v8.6-quality-audit-20260906/depth-response-bq/` (26 PNGs).
All five response controls use backface depth with direct transmission off.
Internal reflection and depth-dependent surface absorption are independently
disabled. The control/repeat maximum pixel difference is zero.

The arch remains without internal reflection, but disappears or is strongly
reduced when surface absorption is disabled. Visual reinspection of control
and no-surface-absorption confirms this difference. Thus multiplying surface
orange by whole camera-path transmittance is the principal remaining source
of this tonal arch under these conditions. The no-absorption control is flatter
and still looks like plastic; it is not an accepted jelly material or a final
fix. Broad white highlights and feature fit remain unresolved.

Next separate surface reflection from volume transport in an isolated candidate
instead of applying whole-object attenuation to the surface tint. Retain depth
for volume response and validate both appearance and motion before promotion.
No shipping material is promoted and all previous versions remain preserved.

## BR separated key-volume source: implemented, visually rejected

Added `gel_separate_volume_shot.gd/.tscn`, inheriting verified static backface
depth and key-light interval transport. Candidate surface tint is constant;
the key's single-scattering integral contributes independently with isotropic
1/(4 PI) weighting, not the visible surface's wrapped cosine. This is only a
key-light experiment, not complete multi-light or multiple-scattering transport.
Preserved evidence: `outputs/v8.6-quality-audit-20260906/separate-volume-br/`.
Pinned native Metal run completed exit 0. Control/repeat and three candidate
cases rendered successfully. Inspected separate and triple-volume-gain images:
both are dark brown with broad white highlights, materially unlike luminous
orange jelly. Increasing volume gain has only a small visible effect. No
promotion. Next isolate/read back the key source and light-selection predicate
to distinguish a weak physical source from light-routing/scale errors before
further appearance tuning. Existing shipping assets and older versions retained.

## BS corrects BR's missing engine-albedo compensation

Code inspection found a concrete integration defect in BR: environment-shot
rewrites existing DIFFUSE_LIGHT additions with reciprocal engine_albedo_floor
before BR inserts its new volume addition. The new term therefore lacked the
1000 multiplier compensating ALBEDO=.001. BR's weak gain response must not be
interpreted as evidence that the physical source itself is negligible.

Added `gel_volume_scale_shot.gd/.tscn`, preserving BR and validating the actual
shader ALBEDO declaration against the exported floor before compensating only
the new source. Native Metal completed exit 0; evidence in
`outputs/v8.6-quality-audit-20260906/volume-scale-bs/`. Uncorrected/repeat delta
is zero. Corrected gain 1 versus 3 changes 265,565 pixels, maximum channel delta
75 and full RGBA image mean absolute delta 11.256 (versus BR maximum 1).
The selected key-light branch clearly contributes; blanket light-routing
failure no longer explains the observed gain issue.

Visually inspected corrected/gain images and the original concept. Corrected
transport is yellow/olive wax, not saturated luminous orange jelly. A dark arch
now appears in the volume response as thickness tends to zero; surface-only
fixes do not establish full material correctness. No visual acceptance or
shipping promotion. Further work must address the combined volume/refraction
response and missing illumination directions, rather than merely increasing
gain; facial proportions and excessive broad highlights also remain open.

## BT missing-light data build in progress; budget failure handled

Started full light-plane trees for fill (light 1) and rim (light 2), matching
the same rest-mesh source used by the key. Four interval unit tests passed;
available disk approximately 26 GiB. These are static diagnostic data, not
animated or visually accepted assets.

Direct rim depth-11 build terminated exit 1 at the explicit 150,000-new-ray
budget (44,794 nodes reported). No tree was saved; do not treat that attempt
as valid data. Rather than raising the safety budget, started a separate
depth-10 coarse rim build at `light-intervals-bt-rim-coarse`, intended for
existing residual-only resume refinement after independent validation.
Fill depth-11 build remains live and is not restarted. Next recheck the live
process handles, validate completed trees with original and holdout paths,
and only pack/use data that meets the defined gate. No shipping changes.

## BU rim tree built and independently sampled; fill still running

Coarse rim process completed exit 0 with 116,643 rays, 35,669 nodes and 26,752
leaves. Payload SHA256:
`909c13754357d8188fbf80bccb791e3a0ce3fd07b9f3144c58821babcf07aa60`.
Original plus holdout validation completed exit 0: 448 paths, mean error
.000970306, maximum .020248118, passing the pre-existing .01 mean/.04 maximum
distance gates. This is sampled accuracy only: 5,000 refinement leaves still
exceed the .01 local probe target (worst .051553127). No full-domain claim.

Packed separately at `light-intervals-bu-rim-packed` for the next GPU parity
check; raw/coarse evidence remains preserved. Fill process remains live,
last observed 90,000 rays and 26,738 nodes; do not restart on elapsed time alone.
No new visual acceptance or shipping change. Next check packed rim GPU parity,
then validate/pack fill when its current process reaches a terminal state.

## BV rim GPU parity and independent two-light render

Refactored GPU checker directory selection into overridable methods, preserving
BK defaults. `gel_rim_gpu_check.gd` uses separate rim evidence directories.
Native Metal parity exit 0: 1,024 values, maximum error .00000284080845,
encoding controls .00000005960465. Evidence: `interval-gpu-bv-rim/`.

Added `gel_rim_volume_shot.gd/.tscn`: separately loaded/hash-checked rim tree,
16-point incoming/outgoing integral and independently selected rim contribution,
with BS engine-albedo compensation. Static key, key+rim, rim and key-repeat
controls preserved in `rim-volume-bv/`; native exit 0. Repeat maximum pixel
difference zero; adding rim changes channels by up to 30 levels. Inspected
key+rim render: still yellow/olive wax with a dark foot arch and broad white
streaks. Adding this missing direction alone does not provide reference-match
appearance. No promotion or motion-validation claim. Final fill poll terminated
exit 1 at the same explicit 150,000-ray budget, reporting 44,524 nodes; no
completed fill tree exists. All current processes are terminal. Next use the
coarse-first/residual-refinement strategy that successfully produced rim data,
not a blind depth-11 retry or raised budget. Fill GPU integration remains open.

## BW coarse fill underway; restart semantics inspected

Started light-1 depth-10 build in a new `light-intervals-bw-fill-coarse`
directory. Live process observed producing 15,000 rays / 4,486 nodes. This is
not a completed dataset; poll the existing process rather than duplicate it.

Inspected generator failure/resume semantics: the ray budget throws before
output creation, so failed direct builds do not retain a usable tree. Existing
`--resume` only accepts completed, hash-matched trees, checks the source/light/
basis/bounds, rescales coordinates and refines unresolved leaves. Therefore the
coarse-first workflow must save a complete tree before refinement; an arbitrary
failure output must not be passed to resume. No claim that interrupted-build
checkpoint recovery has been implemented. The current build is unchanged and
the 150,000-new-ray limit remains intact. Validate coarse fill independently
on completion before deciding whether residual refinement is needed.

## BX fill coarse tree complete and sampled validation passes

Existing BW process completed exit 0 without restart: 140,451 rays, 42,509
nodes, 31,882 leaves; 11,294,136-byte payload SHA256
`d5a0ef5949122ff2777ea3cd2eaf61002f99ae613c28f0f17ed6deedefa1363d`.
Independent original+holdout validation completed exit 0: 448 paths, maximum
error .0103764191 and mean .0005606236, passing existing .04/.01 gates.
This does not certify every cell: 5,459 terminal cells exceed the .01 local
refinement target, worst .0486547667. Raw tree/validation preserved under
`light-intervals-bw-fill-coarse`.

Packed data at `light-intervals-bx-fill-packed`; prepared 1,024 deterministic
GPU parity queries at `interval-gpu-bx-fill`. GPU execution and three-light
spatial integration remain next. All build/validation processes are terminal.
No visual improvement or shipping readiness claimed from these numeric gates.

## BY three-direction transport integrated; missing fill is not the main gap

`gel_fill_gpu_check.gd` completed native Metal parity exit 0 with 1,024 values:
maximum error .00000146713722, encoding controls .00000005960465. Evidence in
`interval-gpu-bx-fill/`.

Added `gel_fill_volume_shot.gd/.tscn`, extending BV with a separately loaded,
hash-checked fill tree, 16-point integral and BS scale compensation. Native
render completed exit 0; preserved `fill-volume-by/` includes key+rim,
three-lights, rim+fill and key+rim-repeat controls. Repeat maximum pixel delta
zero; fill changes channels by at most 14 levels. Inspected three-light render:
still olive/yellow wax, broad white streaks and a dark arch above feet. Thus
the missing fill alone does not explain the material/reference mismatch.

All three existing directional sources now have static sampled path accuracy
and GPU helper parity evidence. This is not full environment/multiple-scattering
transport, motion support, or real-time performance acceptance. Stop expanding
directional data as the next action: use this complete three-direction control
to address spectral absorption and the overly broad surface reflection response.
No visual promotion, shipping edits or deletion; all processes are terminal.

## BZ three-light absorption/emitter-width factorial control

Added `gel_three_light_appearance_shot.gd/.tscn`. All three directional volume
sources enabled; test shared absorption (.095,2.8,12) versus baseline, and
narrower reflected emitter widths independently and combined. Body internal
environment and world sky edits are synchronized and guarded by anchor counts.
Emitter peak radiance is fixed, integrated energy is not; this is an appearance
control, not equal-energy illumination comparison.

Native Metal completed exit 0; evidence `three-light-appearance-bz/`.
Baseline/repeat maximum pixel difference zero. Inspected amber and amber/narrow:
body shifts from olive toward brown/orange; narrower emitters reduce white-band
width but also weaken eye glints and peripheral reflection. Neither resembles
the reference's saturated luminous jelly. Dark foot arch and coarse/jagged
highlight edges remain. No visual promotion. Next isolate consistent surface
gradient/roughness on this three-light control (the smoother AW gradient is not
yet present here), then calibrate volume brightness with all three source gains
together. Do not interpret this as completed motion or reference matching.

## CA gradient/gain candidate implemented; native capture still live

Added `gel_three_light_gradient_shot.gd/.tscn`: matched relief .004, scale .20,
roughness .10 and amber absorption across screen/spatial derivative controls;
all three volume gains jointly tested at 1 and 3. Intended output is
`three-light-gradient-ca/`. This candidate has not yet reached its own cases.

Native process PID 9403 / exec session 34613 remains live, but output stopped
after parent baseline side image (three PNGs). Process sample at
`/tmp/Godot_2026-09-06_173638_C3h1.sample.txt` shows the main loop mostly sleeping,
not evidence of an expensive shader compiler. CUA inspection sees the side-view
IMMUNE debug window; raising/activating it did not immediately resume output.
No duplicate process was started and no completion or gradient improvement is
claimed. Re-poll this exact session and diagnose frame-wait/window-render state
before restarting. Unrelated suspended system-Godot PID 61332 was not touched.

## CB capture instrumentation completes CA controls; no hang root-cause claim

Re-polled CA, inspected shot.gd: image save awaits two frame_post_draw signals
without timeout. Main loop sample remained mostly sleeping; no render/error
output progressed. Stopped only owned CA PID 9403 with TERM, confirmed session
exit 143, preserving its three PNGs. Added `gel_capture_watchdog_shot.gd/.tscn`
with per-save begin/end diagnostics, process/drawn frame counters every 3 sec,
and at most three deferred force_draw recovery attempts if drawn frames stall.
API basis: https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#class-renderingserver-method-force-draw

New CB native Metal run completed exit 0, including all five CA gradient/gain
controls, at `capture-watchdog-cb/`. Observed counters advanced; the original
hang did not recur. This does not establish the original root cause or prove
the recovery branch fixes it. Screen/repeat maximum pixel delta zero.

Inspected spatial gain 1 and 3 images: spatial gradient produces smoother
highlight boundaries, but large white patches remain. Gain 3 brightens orange
yet still reads as solid wax with a conspicuous dark arch above the feet.
No reference-match acceptance or motion/performance approval. Both CA and CB
processes now terminal; all prior versions preserved. Next address the remaining
thin-region optical response rather than assuming smooth highlights plus gain
is sufficient to produce transparent jelly.

## CC exit-environment candidate pending; draw-stall reproduced

Added `gel_exit_environment_shot.gd/.tscn`: intended rest-mesh back-normal
capture and zero-bounce filtered environment transmission with two-interface
Fresnel and total extinction. Same-screen-pixel back normal remains a deliberate
approximation, not a traced refracted exit. It requires normal/path validation;
no appearance claim is supported yet.

Native `exit-environment-cc/` run terminated exit 5 through the CB watchdog,
before CC's own cases. Process frames advanced 290→725 while drawn frames
stayed 92; forced draw attempt 1 let the neutral-light PNG complete. Later
process frames advanced 1144→2449 while drawn frames stayed 98, and the three
recovery-attempt cap stopped execution. This is evidence that the draw wait can
stall independently of process updates, and that requesting drawing can advance
capture; it does not identify why automatic window rendering stopped.

The current watchdog is insufficient: parents wait for multiple draw signals
between saves, while only one recovery is requested per 3-second timeout and
the engine counter may not reflect manual draws. Next track frame_post_draw
events directly and provide a bounded main-thread draw pump after a verified
stall, retaining a hard overall timeout. Do not increase optical complexity or
interpret partial captures as a failed/successful exit-environment material.
All current diagnostic processes are terminal; prior outputs remain intact.

## CD bounded draw-pump regression succeeds; CC visual control completed

Added `gel_bounded_capture_shot.gd/.tscn`, preserving the previous watchdog.
Counts frame_post_draw signals directly; after a verified 3-second draw stall,
uses a deferred main-thread pump with at most one outstanding request. A
120-second wall-clock bound covers the complete inherited and exit tests.
Parent heartbeat does not issue competing recovery draws. No shipping changes.

Pinned native Metal regression deliberately used `--disable-render-loop` (flag
verified in the pinned binary help), not a headless dummy renderer. Exit 0;
`bounded-capture-cd/capture-result.json` records 510 draw signals, 487 forced
draws, manual mode true, success true, elapsed 14,707 ms. This verifies recovery
when automatic drawing is unavailable, not the OS cause of previous stalls.

All CC controls and back-normal capture now exist. Inspected exit-environment
render: remains orange wax with large white highlights and dark foot arch.
The added zero-bounce environment path has little visible impact; do not promote
it or infer physical correctness from successful rendering. Same-pixel exit
normal/path approximation still needs independent validation. Next inspect
exit directions/TIR and sampled environment radiance to distinguish weak source
illumination from a refraction-path approximation problem. All processes terminal.

## CE exit-path readback separates dark environment from TIR approximation

Added `gel_exit_probe_shot.gd/.tscn`; native Metal/manual-loop run exit 0.
Four numeric maps in `exit-probe-ce/`: coverage/valid exit flags, world exit
direction, RGB24 encoded maximum sky radiance over 0..32, and 1.5 encoding
control. Control maximum error 8.94069725e-8 over the flagged body mask.

265,567 covered pixels: 143,144 valid exits and 122,423 classified as TIR by
the current same-pixel back-normal approximation. Every valid exit samples
only sky floor .006000519 (encoded): world direction z spans -1..-.47451,
whereas the two studio emitters are in positive-z directions. Thus the tiny
CC effect is consistent with genuinely dark sampled environment, not another
missing diffuse-albedo scale compensation (this path writes EMISSION).

Arch targets x510,y650/700/730/740 all classify as TIR; lower arm (290,605)
also TIR, (278,570) exits with sky floor. These classifications are not yet
physically validated: front refracted rays and straight-camera back normals
need not refer to the same surface intersection. Next compare actual refracted
mesh intersections/normals at these targets before adopting any TIR response
or adding back-environment illumination. No visual promotion; process terminal.

## CF actual GPU entry rays distinguish false arm TIR from genuine arch TIR

Added `gel_refracted_ray_probe.gd/.tscn`: RGB24 readback of actual world entry
position and shader-perturbed refracted direction at ten targets. Native Metal
exit 0, encoding control maximum error 8.94069725e-8. Evidence preserved in
`refracted-rays-cf/refracted-rays.json`. Added `trace_refracted_exits.py` and
ran against the rest mesh; exit 0, `exits.json` contains both 1e-5 and 3e-5
origin offsets, which produced the same reported intersections/classifications.
Uses actual triangle intersections and barycentrically interpolated exit normals,
not back-surface micro-normal or multiple reflections.

Lower arms (290,605) and (740,605) change from same-pixel TIR to valid exits:
Snell discriminants .6694/.8876, path lengths .29336/.3132. The four arch targets
(510,650/700/730/740) remain TIR, discriminants -.8014/-.6338/-.4564/-.4450,
actual first lengths .8000/.2880/.09001/.04251. Thus wrong back sampling does
affect arm classifications, but does not alone explain the arch's missing light.

Next follow actual internal reflection after the arch's TIR to its subsequent
surface hit; do not force a nonphysical direct exit or mask/blur the dark arch.
Keep the erroneous same-pixel branch out of any accepted material until replaced
and validated. No new appearance accepted, no shipping changes; processes terminal.

## CG actual internal continuation: arch rays exit after one reflection

Extended `trace_refracted_exits.py` with optional bounded TIR continuation
(`--tir-bounces 8`). Preserved results in `refracted-rays-cf/tir-paths-cg.json`.
Readback validation: all 20 paths (ten targets at two origin offsets) terminate
at transmissive exits; paired offsets produce identical total lengths and exit
directions. Maximum exit-direction unit-length error is 3.33e-16.

All six non-arch targets exit without TIR. Four arch targets each reflect once:

| Pixel | First segment | Complete internal path | Exit world z |
| --- | ---: | ---: | ---: |
| 510,650 | .8000 | .873169 | -.95841 |
| 510,700 | .288001 | .993034 | -.85117 |
| 510,730 | .090010 | 1.132360 | -.62515 |
| 510,740 | .042507 | 1.161522 | -.61244 |

Thus a thin first segment at the foot arch does not imply a short complete
optical path. These exits still point into negative-z environment directions;
the current studio emitters are on positive z. This supports testing actual
reflected-path transport and controlled rear illumination separately, not
forcing transmission, reducing thickness arbitrarily, or masking the arch.
It does not demonstrate an appearance improvement or fully explain rendered
brightness: this numeric diagnostic excludes Fresnel branch splitting,
scattering integration, exit micro-normals, and animation. No shipping material
changed and no visual acceptance granted. Previous versions remain preserved.

## CH rear environment control is not a visual fix

Added `gel_rear_environment_shot.gd/.tscn`, extending bounded capture. Synchronized
a broad neutral rear softbox in engine sky and internal sky helper, centered
at normalize(0,.35,-1), size (1,1), radiance 0/1/4. Kept the existing approximate
exit transport unchanged. Radiance-4 with exit contribution disabled separates
that contribution from other environment effects. All previous files preserved.

Pinned 4.7.2 native Forward+ Metal run completed exit 0 (session 15230), five
new controls in `rear-environment-ch/`; headless parse check had no errors.
Inspected radiance-1 and radiance-4 alongside the original reference. Rear light
brightens the body/arms but retains hard patch boundaries, olive-dark arch,
oversized white highlights, and wax-like opacity. Strong rear light clips bright
arm regions rather than reproducing reference detail. Do not promote this control.

This rules out simply increasing rear studio illumination as a sufficient fix
under the current approximate transport. Next replace the same-pixel exit branch
with validated actual path data for a static comparison before any live shader
integration. Current face proportions/forehead fit and surface detail also remain
visually unlike the reference; this illumination test does not address them.

## CI full-field ray acquisition and bounded pilot

Added `gel_full_ray_capture.gd/.tscn`: saves seven RGB24 component maps from
the unchanged CF numeric shader, without changing existing captures. Pinned
native Metal run session 4591 exited 0; parse check clean. `decode_full_rays.py`
validated 265,567 covered body rays in `full-rays-ci/world-rays.npz`.
Encoding control maximum error 8.940697249e-8; direction unit-length maximum
error 4.112323335e-7; all original ten probe values agree within 1e-6.

Added bounded `trace_ray_batch.py`, preserving and stopping at the first invalid
path rather than hiding failures. Deterministic seed 20260906 pilot selected
256 full-field rays; completed all 256 with zero exceptions in 7.409 seconds,
terminal exit 0. Results: `full-rays-ci/pilot-256.json`. This is a pilot, not
full-field optical validation or a visual improvement. Full-field tracing should
be checkpointed in bounded batches given the observed runtime; no monolithic
unobserved job launched. Next build complete exit/path textures with explicit
unresolved-ray masks before comparing against the approximate CC branch.

## CJ profiler-driven acceleration exposes a grazing reflection failure

Added optional `NearestExitLocator` using installed VTK's closest-hit overload.
256 pilot paths exactly matched OBB intersections, lengths and exit directions.
Initial speed remained poor. cProfile then identified repeated NPZ decompression
as the dominant cost: 193 archive reads in the 64-ray test, ~1.718 seconds.
Cached decoded arrays once per run. Same 256 paths stayed exactly equal while
measured tracing time decreased from 7.409 seconds to .014016 seconds (not a
game/GPU performance benchmark). All old evidence remains untouched.

Expanded deterministic pilot to 4,096 targets and stopped on first failure,
at selected target 1,858, index 223375, pixel (431,695). Both closest-hit and
original OBB methods fail at the same third continuation: no exit. Evidence
`full-rays-ci/pilot-4096-cj.json`, `pilot-4096-obb-cj.json`, and detailed
`pilot-4096-detail-cj.json`; these runs correctly exit 1, not successful full maps.

Added previous-segment and geometric-normal diagnostics to the tracer. At the
problem surface, reflected direction leaves the geometric interior despite
reflection against the interpolated smooth normal. Triangle winding is opposite
the supplied outward normals, so the geometric hemisphere is oriented to agree
with the incident outward crossing. This explains why a later intersection is
missing; changing acceleration or silently filling pixels would not fix it.
Next explicitly handle shading-normal/geometric-normal consistency at grazing
internal reflections, validate that handling, then resume full-field acquisition.
No full-field texture produced, no visual fix claimed, no shipping changes.

## CK geometric-normal control and thin-path offset sensitivity

Added explicit geometric exit-normal mode; original smooth mode stays default.
Orient triangle normals to the supplied outward normals, never the incident ray.
4,096-target geometric pilot completed without exceptions in .296 seconds.
This is a faceted-geometry optical control, not an accepted smooth visual model.

Added `trace_full_field.py` with input hashes, 4,096-ray NPZ checkpoints,
32-bounce limit, explicit unresolved states and failure evidence. Native Python
run session 88185 stopped with exit 1 at index 207695, pixel (579,662).
50 checkpoints / 204,800 rays are preserved under `full-paths-ck`; one earlier
ray hit the bounce limit. No complete texture claimed or silent fill performed.

The new failure is offset-sensitive: epsilon 1e-5 misses the next boundary;
epsilon 1e-6 reveals a following segment only 5.694989e-6 units long and proceeds
to the pilot's eight-bounce limit (not a successful exit). Epsilon 3e-7 instead
hits an entry-facing surface. Evidence preserved in `full-rays-ci/geometric-
failure-*-ck.json`. An attempted direct comparison correctly failed because
the latter result has no completed path; do not treat process exit 0 from the
1e-6 diagnostic as proof of a resolved ray. Pilot reporting now explicitly
counts bounce-limit outcomes and reports one requested target for index mode.

Next address precision/offset handling against this thin boundary and check
mesh topology locally; merely choosing the one epsilon that avoids exceptions
is not validation. All shipping assets and previous versions unchanged.

## CL double-precision secondary intersections complete full-field traversal

Preserved legacy single-precision/fixed-offset mode; added optional double vtkPoints,
separate secondary epsilon and nearest-query tolerance 1e-12. Failed CK target
207695 now exits after ten segments at total length 2.3486450520536417. Secondary
offsets 1e-8 and 1e-9 give identical total length and exit direction. First GPU
entry still uses 1e-5 to accommodate its separately measured readback precision.

Independent edge-incidence audit: 249,012 unique edges, zero boundary edges,
zero edges with more than two incident triangles. This does not test self-
intersection or establish complete mesh correctness.

`full-paths-cl` contains all 265,567 geometric-normal paths in 65 checkpoints;
run session 25189 exited 0 after 18.321 seconds with no invalid intersections.
265,547 transmissive exits and 20 explicit 32-bounce-limit results. Manifest
"complete" means all input rays processed, not all rays resolved or visual
quality accepted. Unresolved records retain NaN exit directions and valid_exit=0;
they must not silently become valid sampled exits in a rendering test.

Next load these validated geometric transport controls into a static render
comparison, while treating remaining high-bounce rays explicitly. The geometric
normal control can introduce facets; it is not a substitute for the desired
smooth, flowing jelly surface. No shipping shader or previous asset removed.

## CM actual exit-path static render: dark regions improve, artifacts remain

Added `pack_exit_paths.py`: numeric RGBA32F direction/validity and path-length/
exit-cosine/TIR-count/coverage buffers, total 33,554,432 bytes, nearest sampling,
no color-space conversion. Readback: 265,567 covered, 265,547 valid exits,
20 unresolved masks; invalid directions zero, float32 unit error <=5.96e-8.

Added `gel_traced_exit_shot.gd/.tscn` comparing old CC+AP approximations against
geometric traced environment exit transport, under dark and rear-1 environments.
Traced branch disables CC and AP to avoid counting their environment paths twice.
Uses total traced length for unscattered Beer attenuation and entry/exit Schlick
transmission; excludes non-TIR reflected branch splitting and still leaves the
existing straight-view scattering integral unchanged. Unresolved exits contribute
zero only in this diagnostic and remain explicitly masked in source buffers.
This is camera/rest-pose specific, not animation-ready or a shipping shader.

Pinned native Metal session 90274 exited 0; parse check clean; outputs in
`traced-exit-cm/`. Inspected approximate-rear and traced-rear: foot arch and
inner-arm dark blocks improve, but fine speckling/contour bands appear around
feet/underarms; broad white highlights, flat orange/wax character remain far
from the reference. No promotion. Next independently verify GPU path sampling
then isolate geometric-normal discontinuities versus remaining straight-view
scattering approximation; do not simply blur the artifacts or claim visual lock.

## CN full-body GPU path sampling parity passes

Added `gel_path_readback_shot.gd/.tscn`, which retains CM's exact texture reads
and outputs path length, three world direction components, exit cosine, validity,
and a constant 1.5 as RGB24 numeric maps. Pinned Metal run session 61448 exited
0; parse check clean. Added `check_path_readback.py`; `path-readback-cn/parity.json`
passes all seven fields at all 265,567 covered pixels with tolerance 4e-6.

Maximum errors: length/direction/cosine <=9.536736e-7 (RGB24 quantization),
validity 5.960465e-8, constant control 8.940697e-8. Zero out-of-tolerance values.
Thus CM's fine artifacts cannot be attributed to wrong UV orientation, invalid
buffer layout or color-space conversion in these sampled fields. This does not
validate optical completeness or animation behavior. Next isolate discontinuities
in traced transport itself (geometric normals/TIR transitions) and its interaction
with the remaining straight-view scattering term. No quality promotion.

## CO discontinuity correlation and exact exit Fresnel control

Added `analyze_exit_discontinuities.py`. Among 465,268 valid neighbor pairs with
baseline max RGB difference <5/255, 5,287 develop jumps >20/255 under CM;
4,523 of those also change TIR count. This is correlation, not causal proof.
Largest pair (297,597)/(298,597) jumps 165/255, with path length .38905 vs
2.57185 and one vs seven TIR events. Evidence: CM `discontinuities-co.json`.

Found an independent exit weighting defect: Schlick using internal incident
cosine does not approach reflectance 1 at critical angle. For IOR 1.36,
critical cosine .6777481542; at cosine .68848127, exact dielectric Fresnel is
.37516745 versus current .02613547. Formula verified against PBRT:
https://www.pbr-book.org/3ed-2018/Reflection_Models/Specular_Reflection_and_Transmission

Added `gel_exact_fresnel_shot.gd/.tscn`: exact unpolarized Rs/Rp exit weighting
versus preserved Schlick control, identical paths/light. Native Metal session
82864 exited 0, parse clean, repeat max difference zero. Exact change max91,
mean .05215 RGB levels across image. Inspected exact result: wax character,
speckles and bands remain; largest selected neighbor jump only changes 165 to164.
Thus correcting this weighting alone is insufficient. It remains an appropriate
formula correction, not a complete transport or quality fix: the reflected
portion at non-TIR exits is still omitted. Next test continuation of that branch
at problematic neighboring paths before proposing any spatial smoothing.

## CP omitted reflected branches and central exit visibility

Added `probe_reflected_branches.py`: deterministic geometric-interface splitting
at every hit, exact dielectric Fresnel, same rear1 studio and nine angular sky
samples as AQ/CH. Internal weight includes sigma=(.095,2.8,12)+1 attenuation.
Stops below remaining max channel weight 1e-7 or 128 interactions. Asserts
escaped+absorbed+remaining=1 within 1e-10, before entry Fresnel/lighting.

31 unique pixels from CO's strongest pairs all complete within 20 interactions,
max remaining 9.8524114e-8. Added branches can contribute materially (maximum
extra linear RGB 2.58386,.39443,.0006945), but worst pair remains discontinuous:
(297,597) red first2.800820/total2.801097; (298,597) first.00034874/total.00035531.
Thus omitted internal branches are real missing energy, not sufficient explanation
for this worst jump. Evidence: CM `reflected-branches-cp.json`.

Added central outgoing-ray visibility check: only 2/31 first exits intersect
the body again, and neither pixel in that worst pair is blocked. This excludes
central self-occlusion for that pair, not all angular samples/external transport.
`reflected-visibility-cp.json` preserves next-hit locations; no visibility mask
or unverified physical fix applied. Both diagnostic runs exit0.

Next isolate pixel-scale entry-normal variation and sampling across these path
transitions; a single geometric ray can select very different emitter/path
histories on neighboring pixels. Use actual ray-footprint comparisons rather
than post-blurring the beauty render. No animation/visual acceptance granted.

## CQ unperturbed entry control reveals strong path sensitivity

Extended the bounded CP numeric probe with `--unperturbed-entry`. Uses recorded
camera position, intersects the camera ray with the actual rest mesh, interpolates
authored entry normals, and refracts without shader micro-normal perturbation.
Exit geometry, exact Fresnel branches, attenuation and studio illumination remain
unchanged. Surface position matches GPU entries within 1.1927522e-6 (31 targets).
Direction changes span .0475093 to4.8891393 degrees. Run session52412 exit0;
max16 interactions, remaining energy <=9.31281e-8. Evidence: CM
`unperturbed-entry-cq.json`; original CP output retained.

For the worst pair, linear red radiance becomes 2.808644 and .862403 versus
CP's 2.801097 and .00035531. The latter change follows only .0475093 degrees of
entry direction change. Across the preselected 20 strong neighbor pairs, mean
maximum-channel radiance difference drops from2.656017 to2.075616, but remains
large. This selected-pair measure is not a full-image quality score; no beauty
render or animation improvement demonstrated here. Removing micro-normal detail
alone is insufficient and would compromise the desired wet surface detail.

Next test actual subpixel camera-ray footprints through smooth entry normals,
then compare convergence before adding rough-entry angular sampling. Preserve
reference detail; do not use post-blur as a substitute for sampling optical paths.

## CR true pixel-footprint sampling does not remove the worst discontinuity

Added `probe_pixel_footprint.py`: reconstructs the recorded front camera and
verifies directions against the native backface grid before using actual
stratified subpixel rays. Each ray independently intersects/refracts at interpolated
smooth entry normals then follows CP geometric-exit Fresnel branches. No beauty
image blur or interpolation of saved exit paths. Native probe session41247 exit0.
Evidence: CM `pixel-footprint-cr.json`; all traced residual weights <1e-7.

Worst pair (297,597)/(298,597) red radiance at 1/4/16/64/256 samples:
- First pixel: 2.80889,3.04002,2.25482,2.40620,2.41340.
- Second pixel: .86267,1.09403,.57011,.53700,.56287.

The 64-to256 change is small for the first pixel but still ~4.8% for the second;
do not claim complete convergence. Nevertheless the pair difference remains
1.86920 at64 samples and1.85053 at256: ordinary subpixel averaging does not
eliminate this large transport boundary. This two-pixel diagnostic excludes
shader entry micro-detail, entry Fresnel and volume-source integration, so is not
a full-image reference match or live-performance result.

Next evaluate consistency of the geometric exit surface with the desired smooth
surface (including normals and angular roughness), rather than assume more samples
alone resolve it. No accepted asset/material changed or previous version removed.

## CS normal consistency is mostly good; no evidence for blanket normal repair

Added `audit_surface_normals.py` over all83,006 vertices/166,008 triangles.
Outward geometric-vs-interpolated-authored face-normal angular percentiles:
median .73254deg,90th2.09326,95th3.39609,99th10.10164,max70.58858.
Zero opposite-hemisphere faces. Only .0207666% of surface area exceeds15deg.
Authored vs regenerated area-weighted vertex normals: median .52189deg,
95th1.93596,99th4.00572,max34.87137. Largest outliers are small facial triangles;
no geometry or normals regenerated in the model. Evidence: CM `normal-audit-cs.json`.

Added authored-normal reporting at actual branch intersections and reran31 CO
targets, session41887 exit0, evidence `path-normals-cs.json`. Worst neighboring
pair's encountered discrepancies stay below2.692deg and2.533deg respectively;
maximum across all31 paths is5.98864deg. Therefore a grossly reversed/stale normal
at the inspected intersections is not the explanation. Small angular differences
can still matter near critical reflection; blanket normal repair is not justified.

Next use a controlled curved-surface/refinement comparison at the affected
paths, with reprojected entry rays and measured silhouette displacement. Preserve
the existing character and facial shape rather than globally remesh on speculation.
No full-image improvement or animation acceptance claimed this turn.

## CT local curvature refinement does not improve selected path transitions

Added `build_local_curvature_control.py`: independent linear and locally blended
Loop subdivision controls, equal topology332,018 vertices/664,032 triangles.
Only outer arms/feet receive curvature changes; central facial-region vertex
displacement exactly zero. 261,613 vertices unchanged, max displacement .00571134,
99th percentile .00123818. Preserved both diagnostic meshes and report under
`curvature-ct`; no game asset replaced. Disk check before generation:25Gi available.

31-target CP probes reproject camera rays onto each mesh with measured entry
movement and unchanged interpolated entry-normal data between controls. Both
processes terminal exit0; max entry difference vs GPU .000001193(linear),
.000609566(local-curved), below explicitly configured .01 diagnostic limit.
Mean selected-pair max-channel radiance difference1.873567(linear) versus
1.917886(curved). Worst pair red2.808612/.861917(linear) becomes2.470294/.000425909
(curved). This does not support curvature refinement as a fix; do not promote.

Linear subdivision is a numerical/control mesh, not asserted bitwise equivalent
to the original floating-point triangle intersection history. These selected
paths are sensitive and no full-image improvement or silhouette acceptance is
claimed. Next examine angular roughness in transport: current environment blur
does not itself distribute the internal paths across rough surface directions.
Keep the desired detailed surface, and test a transport model consistent with
its roughness before further speculative geometric changes.

## CU entry angular-distribution sensitivity is not a sufficient fix

Extended `probe_pixel_footprint.py` with explicit `--angular-alpha` sensitivity
mode. Fixed center camera ray; stratified slope radius alpha*sqrt(u/(1-u)) and
azimuth perturb the smooth entry normal before tracing each actual internal path.
This is deliberately NOT a full rough dielectric estimator: no VNDF/PDF weights,
masking-shadowing, entry Fresnel factor, or rough exits. Do not equate alpha with
an accepted Godot material setting or promote the result as physically complete.

Both alpha .01 and .03 ran64/256/1024 paths per target without failures;
sessions30573 and26203 terminal exit0. Evidence: CM `angular-cu-001.json` and
`angular-cu-003.json`. At1024 samples, red values at (297,597)/(298,597):
- alpha .01: 2.735510/.198037 (difference2.537473).
- alpha .03: 2.254188/.281309 (difference1.972879).

Direction dispersion alone does not remove the neighboring bright/dark transition.
No full-image improvement or convergence claim made. Future rough-transport work
must include consistent interface weighting and exit behavior, not progressively
widen this unweighted cone until an arbitrary desired blur appears. Existing
beauty controls, shipping assets, and prior versions are unchanged.

## CV tested rough-dielectric interface replaces unweighted-cone foundation

Reviewed PBRT rough dielectric BSDF and visible GGX microfacet sampling:
https://www.pbr-book.org/4ed/Reflection_Models/Rough_Dielectric_BSDF
https://www.pbr-book.org/4ed/Reflection_Models/Roughness_Using_Microfacet_Theory
Added `rough_dielectric.py` with local incident-facing frame, visible normal
sampling, exact Fresnel branch selection, correlated Smith masking, macro-
hemisphere rejection, and radiance-mode eta-squared transmission correction.
Independent directional BSDF/PDF evaluation is separate from sample weighting.
This is a single-scatter interface model, not microfacet multiple scattering,
volume transport, or a shipping character material.

`test_rough_dielectric.py` passes9,000 attempts over both IOR directions,
three slope widths and three incident cosines. 8,776 valid samples,224 legitimate
macro-hemisphere rejections; max independent f*cos/pdf vs sample weight error
1.110223e-15. Unit direction, normal-incidence Fresnel and internal TIR checks pass.
Independent hemispherical VNDF quadrature at alpha.3/cosines.1,.7,1 integrates
to1 within3.331e-6; 4,096-sample mean-normal comparisons differ by <=.006428.
This does not prove all roughness/angle regimes, convergence or visual fidelity.

Next integrate the tested interface at both entry and exit of the measured
problem rays, explicitly preserving geometry-consistent hemispheres, external
reentry and path termination. No full-image quality claim or shipping edit.

## CW rough interfaces integrated with medium state and external reentry

Added `probe_rough_transport.py`, using CV sample weights at actual geometric
interfaces, explicit inside/outside state, eta-squared radiance transport,
external reentry, macro-hemisphere rejection and extinction. Raw CH rear1 sky,
not AQ's angular sky blur. No volume source or microfacet multiple scattering.
Geometry-consistent entry normals intentionally differ from CP/CQ's smooth
entry normals, so numerical results are not a causal like-for-like comparison
against those earlier values.

Four matched cases: two pixels, entry-only alpha.03 (later interfaces1e-5) versus
all interfaces alpha.03. 1,024 and8,192 paths/case runs terminal exit0; evidence
CM `rough-transport-cw.json` and `rough-transport-cw-8192.json`. No inside-missing-
exit, medium-state disagreement or128-bounce-limit outcomes. At8,192 paths:
- Entry-only red .0314972 +/- .0037637 SE and .0278798 +/- .0040635 SE.
- All-interface red .0495922 +/- .0052926 SE and .0518397 +/- .0056672 SE.
- External reentry counts323/257(entry-only),375/362(all-interface).

Adjacent means are close within sampling uncertainty in BOTH controls. Thus do
not credit rough exits alone with resolving the previous discontinuity. Standard
errors remain material, and the1,024-to8,192 means reveal rare bright paths.
Next isolate the entry-normal convention against a consistent reference before
full-image integration, and address sampling variance rather than presenting a
two-pixel result as character-quality completion. No native beauty or live shader
changed; every old version and failed/diagnostic artifact remains preserved.

## CX matched first-entry normal convention strongly changes the problematic pair

Added `--smooth-entry` to CW probe. Only initial local scattering frame changes
to barycentrically interpolated authored normals; geometry, IOR, random seed,
roughness, medium state, raw sky and all later geometric interfaces unchanged.
Reject geometric/shading hemisphere disagreement explicitly. This is a sensitivity
control without a shading-normal radiance correction, not a final physical BSDF.

8,192 samples/case, session22629 terminal exit0; CM `smooth-entry-cx-8192.json`.
Entry-only red means .768552(SE .024557) and .080183(SE .006529), versus CW
geometric .031497/.027880. All-interface red1.291046(SE .034070) and
.103872(SE .008187), versus CW geometric .049592/.051840. Exactly one initial
shading/geometric hemisphere rejection across these four cases. No invalid
intersection, inside/outside disagreement or bounce-limit termination.

The large contrast reappears when only the first-entry normal convention changes,
well beyond reported standard errors. This identifies an important sensitivity,
not proof that replacing all smooth shading with faceted shading solves quality.
Next make a preserved static visual control separating detailed surface reflection
from geometry-consistent refraction entry; inspect full-image artifacts and
reference fidelity before any shipping change. No beauty or animation accepted.

## CY full-field geometric-entry static visual control

Added `build_geometric_entry_rays.py`: all265,567 GPU coverage rays reprojected
to exact geometric entry intersections/normals; max position displacement
.000215029,99th percentile1.789991e-6. New `geometric-entry-cy.npz` preserved.
Full trace with entry/secondary offsets1e-8 completes exit0,18.212 seconds,
12 explicitly unresolved32-bounce paths; all other paths valid. Packed into
separate `exit-paths-packed-cy` buffers, no existing data replaced.

Added `gel_geometric_entry_shot.gd/.tscn`: swaps only path buffers after CO exact
exit Fresnel setup; reflection detail, lights, entry Fresnel factor and remaining
scattering terms stay fixed. Not the stochastic CW rough transport—still the
static first-transmissive-exit model. Pinned native Metal session64287 exit0;
parse check clean, repeated original image max difference0.

Inspected CY geometric render: the previously selected strongest adjacent jump
at(297,597)/(298,597) falls164 to8 RGB levels. Full-image max change176,mean.15618.
This verifies a local improvement, but distributed feet/underarm speckles,
contours, broad highlights and wax-like opacity remain; no reference match or
promotion. Next evaluate remaining artifact regions and scattering contributions
in full-image comparisons, not optimize only this now-improved pixel pair.
All original geometry, shipping materials and earlier versions preserved.

## CZ native component isolation and full-image countercheck

CY's local improvement is not an overall improvement: covered horizontal/vertical
adjacent pairs with baseline maximum RGB jump <5 and candidate jump >20 increase
from 4,856 (perturbed entry) to 5,116 (geometric entry). Baseline is CM approximate
rear render; coverage is CY info alpha. This metric is diagnostic, not a perceptual
quality score.

Added `gel_component_isolation_shot.gd/.tscn`, retaining geometric CY path buffers,
exact CO exit Fresnel, unchanged surface reflection and rear illumination. Switch
only all three volume gains (3/0) and traced environment gain (1/0). Native pinned
4.7.2 Metal session35238 exits0; parse check clean. Five new captures preserved in
`outputs/v8.6-quality-audit-20260906/components-cz`. Full/repeat max RGB difference0.

Same jump metric: full5,116; no-volume12,408; no-exit-env0; neither19. Visual
inspection confirms foot contour bands and red arm/foot speckles persist without
volume and disappear when traced environment is disabled. Thus this static traced
environment term is responsible for these artifacts under the tested setup;
volume masks some contrast rather than causing it. This does not establish the
precise failing path approximation or justify simply disabling transparency.

Broad white reflection streaks remain in every control, including neither.
Volume-only appearance is opaque/waxy; removing volume darkens the character.
At least two distinct issues remain: discontinuous transmitted environment and
surface highlight design, plus the still-unaccepted shape/face/reference match.
Next isolate the transmission approximation's unresolved/first-exit and roughness
handling, keeping surface reflections separate. No production material, shipping
geometry or previous version changed; no visual lock, animation or release claim.

## DA classify residual geometric-entry discontinuities

Extended the existing discontinuity analyzer with explicit before/after filenames
and optional coverage including unresolved paths; legacy defaults retained.
Reproduced CZ's 5,116 jumps across 465,326 eligible pairs. Of those, 3,992
(78.03%) cross a TIR-count change, 1,124 have equal counts, and only2 touch an
unresolved path. Correlation is not proof of a particular tracing defect; the
12 unresolved rays cannot explain this widespread pattern.

Extended reflected-branch probe with an optional entry epsilon, keeping the
legacy1e-5 default. On CY geometric rays, explicit1e-8 matches the full-field
offset. Recomputed the current top20 pairs (35 unique pixels), not the old
already-improved pair. Exit0; maximum21 steps, residual weight <1e-7.
Mean maximum-channel linear radiance gap changes3.289385 to3.163778 when later
internal branches are included. The strongest image pair(297,600)/(298,600)
has first red radiance .002496/3.491247 and full-branch .006615/3.770297:
the contrast remains. Two of35 first exits are centrally occluded. This probe
does not integrate external reentry, entry Fresnel, volume sources or roughness;
it is not a complete physical solution or a native visual improvement.

Evidence preserved as `components-cz/discontinuities-da.json` and
`components-cz/branches-da.json`. Next test spatially representative rough
transport, including current foot/arm discontinuities, rather than increasing
the bounce limit or hiding contrast with volume brightness. Old artifacts and
shipping assets remain untouched. Reference fidelity remains unaccepted.

## DB rough transport across four residual artifact regions

Extended `probe_rough_transport.py` with repeatable `--pixel x y` arguments,
input validation and preserved legacy default pixels. Selected strongest eligible
horizontal jump in each foot/right-arm rectangle plus DA's strongest left-arm
pair: (297,600)/(298,600), (276,745)/(277,745), (746,751)/(747,751),
(717,602)/(718,602). Selection uses CZ full vs approximate baseline, not a
post-treatment selection of improved pixels. This remains four pairs, not a
full-image or animation test.

1024 and8192 samples/case runs both exit0, geometric entry/exit normals,
alpha .03, comparing rough entry only against roughness at all interfaces.
8192 result, absolute red linear radiance pair gaps (entry-only -> all):
left-arm1.120012 -> .166748; left-foot .030921 -> .002353;
right-foot .487837 -> .122538; right-arm .621149 -> .297417.
Individual all-interface red standard errors respectively range .03814-.03829,
.00214-.00220, .00362-.00570, .00448-.00908. Common RNG seeds mean covariance
is not assumed zero. Residual right-arm/right-foot differences remain substantial.
No invalid medium-state assertion, missing inside exit or128-bounce exhaustion;
explicit macro-hemisphere rejection and low-weight terminations are retained.
Re-ran independent GGX tests:9,000 attempts,weight identity error1.11e-15,
sampler distribution checks pass. This verifies sampling implementation checks,
not full physical correctness or game readiness.

Artifacts `components-cz/rough-regions-db.json` and `rough-regions-db-8192.json`.
Evidence supports testing all-interface roughness further; it does not show that
roughness alone removes artifacts. Solver still lacks volume source integration
and microfacet multiple scattering, uses geometric rather than authored shading
normals, and its raw sky/entry factors differ from the native static model.
No beauty image synthesized or changed, no native material promotion. Reference
review again confirms tall plump silhouette, saturated orange luminous interior,
thin golden edges, fine irregular highlights and properly embedded face remain
the actual visual target. Next obtain a matched native transmission control from
this model with explicit sampling uncertainty, rather than claim this numerical
reduction as visual acceptance. All prior versions remain preserved.

## DC first-transmission partition and masked native control

Added optional first-interface component selection to rough `trace`, preserving
default all transport and random consumption. 256 deterministic path replays
verify all = transmission + reflection exactly (max error0). This prevents adding
the solver's initial surface reflection to Godot's existing surface reflection.
Added `bake_rough_regions.py`: four fixed16x16 regions, independent per-pixel
seeds,64 samples/pixel, entry-only/all-interface roughness. Stores numeric linear
RGBA float means, masks and standard errors, no beauty-image manipulation.
Bake session37747 exit0; each case1,024 pixels/65,536 samples; no invalid path
assertion or bounce-limit termination. Means finite/nonnegative, unmeasured area0.
Red mean standard error .053907/.060982;95th percentile .214052/.238769;
maximum error .646679/.612861. Therefore this is visibly under-sampled evidence,
not a converged beauty bake. Inputs/hash/settings and termination counts preserved
in `rough-regions-dc/manifest.json`.

Added `gel_rough_regions_shot.gd/.tscn`, guided by shader-basics uniform/data-texture
handling. Explicitly restores CY geometric buffers and replaces only CM emission
inside numeric masks, adding already-weighted transmission once. Existing volume,
screen transmission, face and surface terms unchanged; no claim that their complete
combination is physically consistent. Four static native captures in
`native-regions-dc`; pinned4.7.2 Metal session36816 exit0, parse clean. Repeated
control max difference0. Outside-mask pixel change exactly0 for both variants;
799/853 pixels change within mask, maximum157/156 RGB levels.

Selected pair jumps control -> entry-only -> all-interface:
left-arm160 ->81 ->6; left-foot87 ->21 ->2; right-foot99 ->63 ->18;
right-arm147 ->136 ->78. Crucial region-wide countercheck over all1,920 adjacent
pairs wholly inside the masks: jumps>20 are488 ->513 ->488, mean maximum-channel
jump23.1094 ->20.9932 ->20.4547. Selected pairs improve but regional jump count
does NOT improve at64 samples. Native inspection still shows waxy pale opacity,
broad white streaks, foot contours and arm speckle. No visual acceptance.

Next reduce estimator uncertainty with better sampling or a convergence check on
these fixed regions before extending to a whole-image bake. Preserve the raw
noise/error evidence; do not hide it with arbitrary image blur or promote a
selected-pixel result. All production materials and previous artifacts untouched.

## DD equal-budget sampler comparison before adopting a new bake method

Added `probe_transport_sampling.py`: fixed eight DB artifact pixels, all-interface
rough transmission, ordinary MC versus independently scrambled Sobol,16 replicates
of64 paths per case. Exactly384 dimensions (three per128 possible interfaces),
no point skipping/thinning, powers-of-two batches. Adapter test verifies128
nonoverlapping dimension groups and exhaustion guard. SciPy primary reference:
https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.qmc.Sobol.random_base2.html
and https://docs.scipy.org/doc/scipy-1.13.0/reference/generated/scipy.stats.qmc.Sobol.html
describe balanced powers-of-two sampling and independent scrambled replicates.
Reported uncertainty uses variation between replicate means, not an invalid
independent-sample error estimate within one Sobol set.

Session37107 exit0;16 cases complete, equal16,384 traced paths across each
method's8 pixels. Raw replicate means preserved in `rough-regions-dc/sampling-dd.json`.
Red variance ratios Sobol/MC in pixel order:
(297,600).3120; (298,600).3098; (276,745)3.3307; (277,745)2.1791;
(746,751)1.4388; (747,751)1.0242; (717,602).5604; (718,602).8440.
Thus observed gains in arm samples do not generalize to feet.16 replicates give
an exploratory variance estimate, not a universal sampler ranking or proof of
convergence. Do not adopt Sobol wholesale or claim visual improvement.

Next preserve MC and increase its sample count on the fixed DC regions, measuring
both estimator uncertainty and whole-region native jump statistics; do not choose
a method per pixel after seeing favorable outcomes. No native rerender this turn,
no shipping changes, no previous version removed, quality goal remains unmet.

## DE higher-sample fixed-region native convergence check

Added optional single-case selection to the numeric region baker; legacy both-case
default unchanged. Re-ran all-interface MC with256 samples/pixel on the exact same
four16-square masks, seeds and transport (nested64 sample prefixes). New
`rough-regions-de` preserved independently. Bake session88273 exit0;262,144 paths,
258,322 sky,3,815 explicit macro-hemisphere rejection,7 low-weight, no exhaustion
or invalid medium assertion; partition test max error0.

Added `gel_rough_convergence_shot.gd/.tscn`, using the existing masked shader and
swapping only64/256 buffers, plus repeated64 control. Main agent read shader-basics
for the native uniform/data-texture workflow. Pinned4.7.2 Metal session26462 exit0;
parse check clean. `check_rough_convergence.py` writes a new report with assertions
for identical masks, repeated render and unchanged outside pixels. Repeated64
max difference0, outside-mask64/256 difference0. Raw images and report preserved
under `native-regions-de`, no image filtering or editing.

Across all1,920 internal adjacent pairs, jumps>20 decrease488 to376 (22.95%);
mean max-channel jump20.4547 to17.8609. Mean red standard error .060982 to.032521,
95th percentile .238769 to.120542,maximum .612861 to.305980. Region RGB mean
changes4.1003/1.0208/1.4557/3.5299,maximum57/12/22/60. Thus sample noise accounts
for part of the regional defects, but remaining uncertainty is still material;
neither these nested estimates nor two sample counts prove convergence.

Inspected native256 image: whole-body pale wax-like opacity, broad white streaks,
foot contours and untested areas remain visibly wrong relative to reference.
This local numerical reduction is NOT an overall quality improvement or final
material. More brute-force sampling alone cannot deliver the required live
animated character; next separate stable residual optical structure from remaining
noise before choosing a realtime approximation, while retaining the distinct
shape/face/highlight/reference acceptance work. Shipping GLB SHA remains
3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3.
No production edits or previous-version deletion.

## DF independent-run separation of stable structure and sampling noise

Added nonnegative `--seed-offset` to baker with legacy0 default, recorded in new
manifests. Re-ran256 samples per pixel on fixed four regions with offset100,000,000
(disjoint seeds), new `rough-regions-df`. Session87866 exit0;262,144 paths,
258,365 sky,3,774 explicit rejection,5 low-weight, no invalid state/bounce limit.
Maximum estimated error .307583, partition error0. No beauty image edited or
new native capture claimed this turn.

Added `check_transport_repeatability.py`: asserts matching mesh/sample/optical
settings and masks, different seeds, finite nonnegative buffers. Compares signed
red edge differences and their independent-pixel standard errors. Exploratory
screen requires same sign and |difference|>3SE separately in both runs; it is not
a multiple-comparison-corrected significance claim or a physical validity test.
1,920 pairs:1,253 same sign;288 pass the repeated3SE screen;172 of376 DE native
jumps>20 intersect those edges. Remaining204 are not thereby proven noise.
Mean red run change .034937,max .697783;0 pixels exceed3 combined run SE.
Raw report `rough-regions-df/repeatability.json` preserves strongest edges.

Reprojected the six strongest repeated edges to exact mesh entry triangles.
Geometric entry-normal angular differences7.4113,14.9091,7.4113,5.0926,7.1010,
7.1143 degrees. Strongest pair(293,594)/(293,595), triangles27278/26668,
has repeated red differences4.3755/4.3219 withSE .3114/.3219. This links a stable
high-contrast region to appreciable per-triangle entry-normal changes, but is
not alone causal proof or a reason to smooth the entire character.

Next test geometric versus consistently handled smooth optical interface normals
on these current stable edges, with explicit geometric hemisphere validation;
the earlier CX uncorrected first-entry sensitivity probe is not a final normal
solution. Stop treating this residual solely as a sample-count problem. Preserve
all earlier fields and native renders. Whole-body reference fidelity and live
animation quality remain unaccepted; shipping material/geometry unchanged.

## DG actual local-curvature control at stable rough-transport edges

Extended rough probe CLI with component and interface-case selection, retaining
legacy all-components/both-cases defaults. Reused preserved CT linear subdivision
and local Loop-curved geometry, not a new production model or an uncorrected
shading-normal frame. All optical normals are geometric at every interface;
same alpha .03, first-transmission component,2048 samples/pixel, fixed seed,
ten predetermined pixels: two strongest DF pairs and the existing feet/right-arm
pairs. CT preserves the central face but changes both entry and later geometry;
this does not isolate entry normals alone. CT664,032 triangles is diagnostic,
not a justified realtime asset budget.

Linear session3200 and curved45950 both exit0. Linear -> curved absolute red
pair contrast: strongest DF3.932823 ->2.876236; second3.768468 ->2.541073;
left foot .000820 ->.007508; right foot .122391 ->.059639;
right arm .306799 ->.170859. Strongest two reductions26.87%/32.57%, but their
residual contrast remains large. Left-foot estimates are near their sampling
errors; no consistent improvement asserted there. These are selected diagnostic
pixels, not proof of region-wide or native visual improvement.

Original un-subdivided mesh control session61106 also exits0. Original versus
linear max mean RGB difference .011599, largest red difference divided by sum
of individual SE .231383. Common-seed runs are not independent, and individual
paths are not bitwise invariant under subdivision; no exact path-equivalence
claim. All three runs have no bounce-limit or invalid medium-state failure.
Raw results preserved in `curvature-ct/rough-{original,linear,local-curved}-dg.json`.

Conclusion: locally more continuous actual geometry improves several stable
edges under this model, but does not solve them. Next evaluate the same geometry
control across the fixed regions before any model replacement, keeping face and
silhouette differences explicit. No blanket smoothing, paid regeneration, shipping
edit, old-version deletion or reference-match acceptance.

## DH complete-region countercheck rejects the CT curvature adoption

Reused the existing baker unchanged for CT local-curved mesh at256 samples,
same four16-square regions and seeds as DE. New `rough-regions-dh` preserved;
session20194 exit0,262,144 paths,258,404 sky,3,735 explicit rejection,5 low-weight,
no invalid state/bounce-limit failure. Maximum SE .310952,partition error0.
Curved input SHA73d455013955918c976c44e0b41378c69f559bdb5077fdff30f460c22d4ae12d.

Added `compare_curvature_regions.py` for all480 adjacent pairs per region, not
DG's favorable selected pairs. It validates matching optical settings/sample
count/masks/seeds and reports linear red variation, brightness and uncertainty.
Baseline -> curved mean adjacent red jump:
left arm .267313 ->.306075 (14.50% worse);
left foot .023470 ->.022225 (5.30% lower);
right foot .039860 ->.038388 (3.69% lower);
right arm .135484 ->.128151 (5.41% lower).
Aggregate .116532 ->.123710,6.16% worse. Mean red brightness respectively
.419759 ->.456526, .068579 ->.068365, .179240 ->.187132,
.373267 ->.367603; changes are not a uniform darkening. Standard-error levels
are similar between each region's controls, though residual noise remains and
this is not a formal perceptual score or simultaneous significance test.

`rough-regions-dh/comparison.json` preserves full metrics. Region-wide evidence
does not support promoting CT curved geometry despite DG's selected-pair gains.
Stop this particular geometry-smoothing adoption path. No native appearance
capture was produced for changed geometry, and swapping its transmission into
an unchanged body would not establish correct model/material integration.

Next return to whole-character appearance priorities: the already-isolated broad
surface reflection and wax-like volume response, with native controls and direct
reference comparison. Retain the optical investigations as constraints; do not
continue optimizing selected pixels or claim the unresolved transmission solved.
No production asset/material changes, prior-version deletion, reference lock or
animation acceptance. The full requested visual target remains unmet.

## DI whole-body environment reflection versus volume balance

Added `gel_reflection_balance_shot.gd/.tscn` after CZ full control. Main agent used
shader-basics and verified Godot4.7 RADIANCE override semantics against:
https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html
Override blends environment radiance toward black with alpha1-gain; regex guard
rejects an existing RADIANCE assignment. Custom transmitted environment and other
terms stay unchanged. Cases reflection1/0/.25 with volume3, reflection1/.25 with
volume1, repeated original. Parse clean; native4.7.2 Metal session94090 exit0.
Original gain1 image exactly matches pre-injection CZ parent and repeat (max0).
All six captures preserved in `reflection-balance-di`.

Visual inspection: disabling reflected radiance removes the white slabs but
leaves matte wax-like body and transmitted foot/arm artifacts. Quarter gain
dims the same slab shapes rather than recreating fine wet highlights; reducing
volume darkens the body without resolving artifacts or matching luminous orange
reference. Reject scalar dimming as the appearance solution. This is attribution,
not a complete energy-balanced material or a final visual version.

## DJ move reflection emitters toward the sides

Added `gel_side_reflection_shot.gd/.tscn`, preserving DI original full gains.
Synchronously change sky and body analytic sky emitters from directions
(-.65,.40,.70)/(.75,.22,.62) to(-.95,.40,.15)/(.95,.22,.15), normalized in shader.
Compare original, side placement, side plus narrower widths(.10/.07 versus
.24/.16), repeated original. Peak emitter radiance fixed; narrowing lowers
integrated energy. Rear source and directional volume lights unchanged. No
screen-space highlight mask or image manipulation.

Parse clean, native pinned Metal session60829 exit0, repeated original max0.
Four new captures in `side-reflection-dj`. Inspected both side variants: central
white slabs move toward edges; narrow-side yields thinner edge streaks, a useful
composition direction. But body remains pale/opaque, flat in the centre, with
visible foot bands/arm speckles and insufficient fine reference texture. Shape
and face fit still not accepted. No whole-character reference lock or promotion.

Next address the body colour/volume response while retaining an explicit original
and side-emitter control; do not confuse removing central glare with achieving
jelly depth. All old diagnostic versions and production assets preserved.

## DK shared spectral absorption at fixed side-narrow reflection

Added `gel_spectral_absorption_shot.gd/.tscn`; main agent read shader-basics and
confirmed key/rim/fill integrals all use candidate_extinction_sigma. Restores DJ
side-narrow emitters consistently in surface and analytic transmitted sky after
the parent restores original lighting. Changes only shared absorption sigma:
(.095,2.8,12) control, (.095,6,24), (.095,10,40), repeated control. Geometry,
volume gains, surface response and red absorption unchanged. No image tinting.

Pinned4.7.2 Metal session55143 exit0; parse clean. New captures preserved under
`spectral-absorption-dk`. Repeated control max difference0 and matches DJ side-
narrow parent image exactly. Red channel unchanged across both absorption cases
(full-image maximum red difference0). At fixed torso pixel(510,550), RGB changes
[255,139,63] ->[255,98,38] ->[255,80,20]. Colour becomes more saturated but
strongest version tends red; central form remains flat, highlights thin rather
than reference's fine facets, and foot/arm artifacts remain. Absorption alone
does not recover jelly depth; no visual acceptance or promotion.

Of265,567 covered pixels,151,436 (57.02%) display red255 in all three cases.
Coverage includes the projected body footprint, not a semantic material mask.
Important next issue: displayed torso red already reaches255 in the control,
so merely suppressing green/blue cannot restore its red-channel tonal detail.
Next test radiance headroom/source balance separately from hue, retaining the
side-emitter control and checking whole-body form. Also inspect whether current
volume source actually carries the intended internal density variation rather
than assuming the existing flow controls affect this diagnostic integral.
No production edits or deletion; all prior versions retained.

## DL existing internal-density wiring and radiance headroom

Graph search returned project not indexed; inspected known shader sources.
Legacy internal-depth code integrates a flowing density into optical_depth and
v_through. BH/BV/BY primary scattering instead integrates homogeneous extinction
over geometric depth_length, without that density. CM static transmitted sky also
uses geometric path length. AN screen transmission can still consume v_through,
so do not claim density has literally no consumer or that shipping material is
identical to this diagnostic stack.

Added `gel_density_wiring_shot.gd/.tscn`, main agent using shader-basics. Fixed
geometry/side-narrow lights, all three volume gains1.5 rather than3. Contrast0/1
and fixed depth-time0/5, repeated flow0. Pinned Metal session61658 exit0, parse
clean, outputs `density-wiring-dl`. Uniform0/5 images identical; contrast0 versus1
max RGB difference1,mean .002212; flow0 versus5 max1,mean .003558 across10,835
pixels. Repeat exact0. Covered red255 ratio falls57.02% to1.026% at gain1.5.
Existing flow makes negligible displayed difference in this specific stack.

## DM connect continuous density to primary volume scattering

Added separate `gel_density_coupling_shot.gd/.tscn`, preserving exact legacy
integral branch when disabled. Reuses the continuous curl/ribbon field in object
space (no bubbles, nodes or fragments); normalizes density's symmetric mean by
1.15,50% strength. At each of16 midpoint samples per light, weight the scattering
source by density and accumulate outgoing optical density. Incoming optical depth
uses local-density times known incoming material length: an explicitly locally
homogeneous approximation, NOT complete heterogeneous ray integration. Existing
CM exit attenuation remains homogeneous and static. Full physical consistency,
deformation support and performance remain unverified.

Native pinned Metal session33213 exit0, parse clean. New `density-coupling-dm`
captures control, flow0/2.5/5, flow0 repeat and control repeat. Disabled result
differs from pre-injection legacy by at most1 RGB level, not bitwise identical;
both repeated captures themselves match exactly. Enabled versus disabled at0:
max18,mean .53635 across264,091 changed pixels. Flow0 versus5: max23,mean .69966,
259,444 changed pixels, compared with legacy max1. Thus density now influences
the primary body shading, not merely an effectively hidden transmission term.

Inspected flow0/5 images: subtle broad internal variation now exists, but body
still reads plastic/waxy with dark foot contours and mismatched face/reference.
Discrete timestamps are not a continuous idle/walk animation test or viscosity
validation. Next inspect a continuous fixed-camera flow sequence and bound its
temporal changes before tuning visibility, while retaining headroom and all
known optical limitations. No final material promotion, production changes or
previous-version deletion. Requested reference fidelity is still not achieved.

## DN continuous density sequence validation

Added separate `gel_density_sequence_shot.gd/.tscn` and
`tools/meshy/check_density_sequence.py`. Main agent used godot-testing and its
async testing reference: validate schedule and artifact integrity, not visual
acceptance with arbitrary pixel thresholds. Pinned native Metal session33712
completed exit0. Captured151 lossless1024x1024 frames, manually stepping shader
time0..5 seconds at1/30 intervals with fixed rest geometry and camera.

Checker passed: contiguous indices, unique files, scheduled times and dimensions.
Repeated first frame has max RGB delta0; endpoints differ by max23. Largest
adjacent per-channel delta2; largest adjacent full-image mean delta .01777204.
These are diagnostic observations, not a flicker/viscosity quality certificate.
Midpoint frame inspected: broad subtle internal variation, but flat dark eyes,
foot bands and waxy appearance remain; reference fidelity is not achieved.

Preserved all PNGs in `density-sequence-dn`; encoded an additional unfiltered
H.264 CRF15 preview, `density-flow-preview.mp4`, without overwriting anything.
ffprobe confirms151 frames,1024x1024,30fps,5.033333 seconds. This offline sequence
does not measure realtime GPU performance, walking deformation or14 animations.
No production promotion or previous-version removal. Next prioritize visible
reference mismatches (foot transmission contours, eye depth, coherent jelly
surface) before extending the experimental flow into locomotion.

## DO eye reflection response isolation

Previous DN was progress: new continuous artifacts and temporal observations.
Graph discovery returned project not indexed; inspected known shader files and
used literal-search fallback. shader-basics skill guided separate material
instances without modifying production shaders. AO explicitly disables both
artificial eye catchlights and view-card emission, sets specular .29/roughness
.12. Environment diagnostic disables direct-light specular. Thus the eyes depend
on environment reflections; this is a diagnostic-stack fact, not a shipping bug
diagnosis. Reference has appreciable glossy eye curvature and bright highlights.

New `gel_eye_response_shot.gd/.tscn` duplicates only the two eye materials after
DM controls. Tests specular .29/.5/1 at roughness .12, then .5 at roughness .30,
and original repeat. Pinned Metal session2198 exited0; parse check passed.
Artifacts: `eye-response-do`. Against control, maximum channel changes68/170/50,
changed pixels7934/8341/8229, all within x328..698,y423..529. Original repeat exact0.
Inspected specular1 and broad images: specular1 restores distinct small highlights
on outer upper eye edges; broad merely softens/dims reflection, not reference-like
depth. This proves visible eye shading responds, not that geometry/occlusion is
correct. Do not promote specular1 as a material fix without an optical rationale.
Next test light placement relative to eye curvature with a restrained dielectric
response, and inspect crown/socket geometry. Foot contours, pore clipping and
body material mismatch remain. Old versions and production files untouched.

## DP eye crown geometry comparison

Previous DO was progress: isolated material response. Using 3d-essentials,
created only `gel_eye_crown_dp.tscn`, inheriting AQ with lens_crown_height .035
instead of .012. Existing fitting code adds front-half crown displacement that
vanishes at the equator, preserves the back half, and regenerates normals.
Pinned native session54707 exited0; both eye construction logs confirm .035.
Reused DO material controls with identical body and lighting settings.

Artifacts `eye-crown-dp`: inspected specular .5/roughness .12 image. Taller crown
moves narrow bright reflections inward and makes the eyes read as rounded lenses
without requiring specular1 or painted catchlights. This is a useful visual
direction, not final reference approval: reference eyes have richer broad/faceted
reflections and embedded socket rims. Fixed front view cannot validate side
protrusion, socket attachment during deformation or back-face visibility.
Matched material comparisons against DO have max RGB changes234/232/238/227
for control/.5/1/broad respectively, so not merely a no-op parameter change.
The initial control comparison also includes a few pixels outside the eye region;
do not claim exact whole-body pixel isolation or use these deltas as a quality
score. Retain this as an independent candidate, with no production promotion.
Next verify side seating and animation attachment before adopting the crown.

## DQ opaque side-seating audit of DP crown

Previous DP was progress: crown changed the reflection footprint at restrained
specular. Using 3d-essentials, added `gel_eye_seating_shot.gd/.tscn`: after DO,
replace visible meshes with opaque StandardMaterial3D, grey body and dark face,
so neither transmission nor a face-visibility shader gate can hide defects.
Rest mesh only; no vertex deformation, unchanged authored node transforms.
Capture left-eye closeups at0,-40,-70,-90 degrees, distance .60. Pinned Metal
session63413 exited0 and script parse check passed. All four native PNGs saved
and reopened successfully under `eye-seating-dq`.

Inspected40/70/90: no obvious open gap along the visible lens perimeter at these
angles, but .035 crown produces an appreciably projecting button-like profile
at90. Far eye also projects past the facial silhouette at70. Thus the front
reflection improvement alone is insufficient for promotion; current crown is
not accepted as the embedded reference eye. Opaque rest tests cannot prove
translucent back-face visibility or animation attachment. Next reduce crown
and evaluate a rim/socket transition rather than accepting a bulbous lens just
because it catches the light. Body optical defects remain a separate open task.
All previous candidates retained; no production mesh/material edits this turn.

## DR reduced crown: retain as provisional, not visual lock

Previous DQ was progress: exposed excessive side projection despite better front
reflection. With 3d-essentials, added independent `gel_eye_crown_dr.tscn`, crown
.022 (DP .035, original .012). Reused exact DO front-response and DQ opaque
rest-seating procedures. Pinned Metal session77352 exited0; all captures saved
and reopened. Artifacts `eye-crown-dr` retain earlier controls and four closeups.

Inspected front specular .5/roughness .12 and90-degree seating. Reflection is
still visible; side lens appears less bulbous than DP but remains distinctly
separate in profile. No obvious visible perimeter gap in that rest view. Crown
alone does not create the continuous orange socket rim visible in the reference.
The closeup camera target follows each lens AABB center, so these are qualitative
comparisons, not equal-camera pixel measurements of projection. Do not infer
whole-model visual acceptance or animation safety. Keep .022 provisional for
subsequent socket work rather than continuing blind scalar sweeps. Next inspect
socket geometry and derive its transition from the existing body surface; do
not add detached rings merely to disguise the interface. Body foot transmission
bands, pore clipping, reference silhouette and final liquid motion remain open.
Old versions and production assets unchanged.

## DS aperture coverage isolation before socket reconstruction

Previous DR was progress: retained front reflection with less crown projection.
Graph lookup again reports project not indexed; read known fitting files and
searched builder literals. R7.1 constructs eye sockets by smooth subtraction
(eye softness .014), R7.2 radii .285/.190/.060. Runtime F then enlarges lens width
1.12 and height1.08 before L/M seating and perimeter fitting. Existing builder lip
contracts alone cannot establish visible runtime lip coverage after that change.

Using 3d-essentials, exposed those two F multipliers with their exact existing
defaults; prior scenes retain their settings. Added independent
`gel_eye_aperture_ds.tscn` inheriting DR crown .022, multipliers1/1. No extra
ring/mesh and no body rebuild. Pinned Metal session91258 exited0, all front
response and opaque seating captures saved/reopened under `eye-aperture-ds`.
Inspected front .5 specular: a thin amber/dark perimeter is now visible around
the smaller black lenses, supporting coverage as one contributor. Inspected40
degree opaque closeup: still no strong rounded socket transition; this does not
solve reference fidelity. Eye-size reduction changes expression/proportions and
is not automatically an improvement. Keep as diagnostic, not promotion.
Next derive the visible socket rim and lens outline together from reference;
do not continue shrinking eyes merely to expose more border. Original versions
retained, production assets unchanged. Full model/animation acceptance open.

## DT reference-proportion evidence changes the next geometry action

Previous DS was progress: exposed coverage contribution but risked smaller eyes.
Added numeric-only `measure_reference_proportions.py` and produced
`reference-proportions-dt.json` with input hashes, explicit eye ROIs, connected
foreground bounds and threshold20/35/50 sensitivity. No image editing. These are
projection measurements, not intrinsic 3D dimensions: reference pose/camera,
asymmetry and glow differ. Largest foreground component excludes black background;
dark-eye component excludes highlights and is only a proxy for the lens outline.

At threshold35, reference body width/height1.011; DR/DS1.053. Reference eye widths
over body width .151/.133, DR .128/.130, DS .117/.119. Reference eye center heights
from head top .459/.451; DR/DS .453/.453. Reference inter-eye center separation
336/908=.370, DR197.5/632=.3125, DS198.5/632=.3141. Body threshold sweep changes
reference aspect .997..1.012, candidates constant1.053; it does not reverse the
finding that DS eyes are undersized in these images. Do not apply ratios directly
as world-space scale/position factors without matched-camera validation.

Decision: reject DS as the forward visual direction despite its exposed border.
Keep DR-sized lens provisional; next adjust socket/lens placement together and
rim transition, with a whole-body reference projection check. Vertical eye
placement is not the primary measured mismatch. This avoids further shrinking
eyes to solve a local border problem at the expense of expression and likeness.
Whole-body optics and deformation still open; no promotion or asset deletion.

## DU coherent face-spacing candidate

Previous DT was progress: reference proportions rejected further lens shrinkage.
Using 3d-essentials, added independent `gel_face_spacing_shot.gd/.tscn`. Starting
with DR, DQ first switches to opaque rest materials. Apply the same continuous
subject-space x displacement to every visible mesh (body and face parts):
dx=.15*x*exp(-((y-.855)/.24)^4-(x/.55)^8)*smoothstep(.10,.25,z).
Preserve vertex/index topology, regenerate normals, no additional components.
Changed meshes remain runtime-only; production files and older candidates kept.
Static optical fields are deliberately not reused after modifying geometry.

Pinned native session90339 exit0; parse check passed. Five visible meshes warped,
maximum sampled displacement .0549277, minimum sampled x-Jacobian .751913.
Positive sampled Jacobian is a local check, not proof of no triangle inversion
or global self-intersection. New captures `face-spacing-du`: equal-camera before
and after whole-body clay plus left-eye90-degree closeup. Inspected after/side:
spacing looks closer to reference; no obvious perimeter separation in this rest
view, but side projection persists and fine surface lines need further inspection.

Using DT numeric helper with expanded explicit eye ROIs: before eye widths/body
.1266 each, after .1456 each (reference .133/.151). Center separation/body grows
198/632=.3133 to228/632=.3608 (reference .370). Body bbox stays196,200..828,800;
vertical eye positions remain .4533. Different clay/optical highlight response
limits dark-mask comparison, not a reference acceptance score. This candidate
advances projected proportions without independently translating a lens away
from its socket. Next validate mesh integrity and preserve/export the coherent
geometry for material re-evaluation; final gel quality and animations remain open.

## DV archive roundtrip succeeds; eye topology needs cleanup

Previous DU was progress: coherent proportion correction with captured evidence.
Using assets-pipeline, added `gel_face_archive_shot.gd/.tscn` to preserve the five
visible rest meshes as binary .res resources plus a standalone clay .tscn and
numeric subject-space geometry manifest, outside production. Pinned Metal
session97829 exited0; parse check passed. Each mesh reloaded with cache ignored
and all surface arrays compared exactly. Archive in `face-archive-dv`.
This saves geometry and transforms, not a working animation or final material.

Added `check_face_archive.py`; numeric report identifies a real quality issue:
Body83006 vertices/166008 triangles: min area2.6168e-7, no area<1e-12 triangles,
zero boundary or nonmanifold edges after1e-7 positional weld. Each eye2210/4224:
128 zero-area triangles,130 edges with multiplicity>2 after weld. Do not certify
the entire asset clean. Pole/UV seam degeneracy is a hypothesis, not yet verified
against pre-warp eye geometry; next compare source and remove only demonstrably
redundant faces in a new candidate. Forehead and mouth patches have32/64 boundary
edges, consistent with their open-patch construction, not evidence of body holes.
No global self-intersection, inverted-face or animated attachment proof yet.
Keep goal and visual acceptance open; originals preserved, no promotion.

## DW duplicate-face cleanup and rebuild precision investigation

Previous DV was progress: archived geometry and identified eye degeneracy.
Numeric inspection confirms all128 zero-area faces per eye have exactly
coincident vertex pairs. Removing these faces in memory yields4096 triangles
per eye and zero boundary/nonmanifold edges after1e-7 positional weld. This
establishes redundancy, not when the duplicate faces originally arose.

Using assets-pipeline, added standalone `clean_face_archive.gd`. Initial attempt
failed an overly broad input-array versus saved-array equality assertion;
session96271 was explicitly stopped(exit130), partial `face-clean-dw` preserved.
Investigated rebuild separately from persistence, not a blind retry. New output
`face-clean-dw-r2` succeeds(exit0): only duplicate-face indices removed; positions
and retained indices exact, saved/reloaded arrays match rebuilt arrays exactly.
Rebuilding itself changes normals (left max vector delta .000095504, right
.000128320) and right tangent array. Therefore do NOT claim all original
attributes preserved exactly; tangent difference still needs quantification and
render comparison. No normals were intentionally regenerated in this cleanup.

Numeric `topology-report.json`: both eyes4096 triangles, no area<1e-12 faces,
zero welded boundary/nonmanifold edges. Body remains unchanged. Open pore/mouth
patch boundaries remain intentional diagnostic geometry. Cleaned .res eyes and
scene saved separately; reference original body/patch resources retained.
Next verify rebuilt tangent/normal effects visually before adopting; this is
geometry cleanup, not proof of final reference fidelity or animation readiness.

## DX bounded cleanup shading comparison

Previous DW was progress: removed redundant faces, exposed rebuild quantization.
Using godot-testing and async reference, added standalone30-second-bounded
`gel_cleanup_compare.gd/.tscn`, loading archived scenes directly without the long
optical diagnostic chain. Initial scene parse failed due to mistyped reflection
enum; session43469 stopped, no images produced. Corrected against existing
working environment setup, parse check passed; native session90279 exited0.

`cleanup-compare-dx`: fixed sky/direct light and glossy StandardMaterial3D eye,
roughness .12/specular .5, no normal map or anisotropy. Capture before/after/repeat
at0/40/90 degrees. Tangent max component delta left0/right .0000985861, zero
handedness changes. Exact repeated-before frames at all angles. Before/after
max RGB changes7/1/2 over546/153/84 pixels; whole-image mean differences
.00024605/.00005563/.00003338. These are diagnostic observations, not universal
acceptance thresholds. Inspected original/cleaned frontal images: highlight
placement and eye contour remain visually consistent at this resolution.
Body facial surface faceting remains visible and unrelated to cleanup.

Retain cleaned DW-r2 as the provisional geometry base: redundant eye faces gone,
small quantized shading changes bounded in these conditions. This does not test
normal-mapped/anisotropic materials, temporal animation or final jelly optics.
Next work should address body surface/optical appearance with the archived
coherent geometry; no production promotion or previous-version deletion.

## DY area-weighted normal isolation does not remove facial faceting

Previous DX was progress: bounded cleanup shading effects. Using assets-pipeline,
added `gel_normal_weight_compare.gd/.tscn`; DX harness now has opt-in paths/output
and subject-preparation hook, original defaults unchanged. Both comparison scenes
start from cleaned DW-r2. Only second body gets area-weighted vertex normals from
clockwise triangle winding; vertex positions and indices verified exactly equal.
No intentional geometry, eye or material changes. Existing tangents are not
recomputed; diagnostic clay has no normal map/anisotropy, so not a final normal-
mapped asset. Parse check passed; pinned Metal session95243 exited0.

Normal minimum alignment .954633, mean angular change .141619 degrees; no
orientation reversal. `normal-weight-dy` before/after/repeat at0/40/90: repeated
controls exactly equal; candidate max RGB28/25/5, full-image mean .09664/.10420/
.07448. Inspected frontal result: local face triangulation and under-eye crease
pattern persist. Area weighting alone does not solve the visible defect; do not
promote simply because normals changed or silhouette stayed fixed. Next inspect
local surface curvature/triangle quality around sockets and mouth, keeping prior
whole-mesh smoothing rejection in mind. Optical foot artifacts remain separate.
All versions preserved, no production changes or full visual acceptance.

## DZ local curvature identifies pre-existing face-region irregularity

Previous DY was progress: ruled out area-weighted normals alone. Added numeric
`compare_face_curvature.py`, comparing verified original rest body to DU/DV body.
Initial direct-index assertion failed: SurfaceTool reordered indexing. Established
an83006-vertex bijection using the known DU field, max error3.164e-8; canonical
triangle connectivity matches exactly after mapping. No silent nearest-neighbor
substitution: bijection and full triangle set equality are required.

`face-curvature-dz.json`: original face region121635 triangles has median shape
quality .3555 (equilateral=1), fifth percentile .1057; forehead control median
.9275/p5 .7562. Original face edges p95 dihedral6.91 degrees, max118.63;3315
exceed15 degrees. Forehead max3.13, none exceed15. Mouth region similarly has
median quality .4374 and max dihedral111.81. Thus narrow triangles and large
local folds predate DU; not solely caused by face spreading. Some large angles
may be intentional cavity edges, so these measurements do not classify each
edge as defective or establish causality for every visible crease.

After DU, comparable region stats remain irregular (face median .3604, max112.16).
Regions are coordinate masks recomputed per mesh and have slightly different
membership; do not interpret count reductions as matched-edge improvement.
Next inspect the original face-region surface-generation/refinement stage and
target the irregular transitions while preserving pore/socket/mouth boundaries.
No reason to accept global smoothing or another normal-only fix. All previous
assets retained; optical appearance and animation acceptance remain incomplete.

## EA source split rule has reproducible shape degradation

Previous DZ was progress: localized pre-existing poor triangle quality. Graph
search unavailable for this project; followed known runtime files. Thickness
stage retains24002 vertices; AJ mouth refinement and AM eye-surround predicate
produce83006 vertices. AJ marks shared edges, inserts their midpoints, then uses
a new face centroid fan for every partially/fully split triangle, up to5 passes.
Closed-edge checks prove incidence, not triangle aspect quality. AM expands
this refinement into eye surrounds; DU only later warps the existing topology.

Added numerical `probe_refinement_quality.py`, output `refinement-quality-ea.json`.
Controlled planar equilateral input, all edges marked5 times: centroid fan yields
7776 triangles, quality median .345293/min .037477; midpoint four-split yields
1024, quality1 throughout. Both preserve signed area to1e-12, no inverted faces.
This isolates a genuine degradation mechanism in the split rule, not proof that
every observed model crease has that cause: actual regional predicates and
subsequent displacement differ from this planar control.

Next implement opt-in shared-edge midpoint red/green triangulation (one/two/three
marked-edge cases), test all patterns and shared-edge incidence, then compare
the actual candidate under unchanged displacement/materials. Preserve old fan
defaults and all existing artifacts until replacement is validated. Do not
equate lower triangle count or better planar quality with final visual success.

## EB opt-in midpoint refinement implemented and construction tested

Previous EA was progress: reproduced centroid-fan shape degradation. Using
godot-testing, added actual GDScript `gel_quality_split.gd` and standalone
`test_quality_split.gd` (no new framework dependency). Zero/one/two/three marked
edges produce1/2/3/4 triangles; two-edge case uses shorter quadrilateral diagonal.
Caller continues to allocate globally shared midpoints, so adjacent faces share
boundary indices. AJ now exposes use_quality_refinement=false by default;
`gel_quality_refinement_eb.tscn` opts in with DR-sized eyes/crown .022.

Native headless helper tests exit0:16 triangle cases (all8 masks on equilateral
and slender triangles) check signed area/winding and split boundary coverage;
64 tetrahedron global-edge masks check closed edge incidence. These tests cover
actual helper, not a separate Python rewrite. They do not prove repeated adaptive
quality or final surface appearance. Initial actual-scene headless run exit2
because Forward+ was not selected; no geometry failure inferred. Explicit pinned
Metal Forward+ session13431 completes construction exit0. Body42726 vertices/
85448 triangles versus old83006/166008; shared-edge closure passes and all257
mouth-patch fit samples complete. No new nodes, unchanged displacement functions.

This is construction evidence only, not rendered visual improvement. Existing
thickness colors were interpolated and are not a fresh bake for displaced body.
Next archive actual new topology, compare local triangle quality and same-camera
clay visuals before redoing optics. Preserve old fan behavior/artifacts and keep
production unchanged; full reference/animation fidelity remains unverified.

### EC — archive and actual-render verification of quality refinement

Created standalone `face-refinement-ec` using `archive_quality_ec.gd`: same DU
subject-space warp, regenerated normals, identical clay material, and removal of
coincident eye triangles. Saved/reloaded mesh arrays agree exactly. Native pinned
4.7.2 Forward+ archive and three-angle comparison both exit 0. Existing assets
and production model remain unchanged. Disk check: 23 GiB available.

Body has 42,726 vertices / 85,448 triangles versus 83,006 / 166,008. Numeric
checks find no degenerate triangles or boundary/nonmanifold edges on body/eyes.
Forehead/mouth remain intentional open patches. Independent face-region triangle
quality median improves from 0.3604 to 0.8555 (1 is equilateral); maximum regional
dihedral drops from 112.16 to 43.14 degrees. Different topology means these are
distribution comparisons, not matched-edge measurements or appearance scores.

Viewed actual 0-degree before/after and 40-degree after captures: face silhouette
is retained, but visible eye/mouth faceting remains. No final visual acceptance.
Repeat maximum RGB delta is 7 at front and 0 at 40/90 degrees; front capture is
not bitwise deterministic, so small pixel differences cannot prove improvement.
Initial analysis failed because JSON indices loaded as floats; validated integral
values and explicitly converted to int64 before rerunning successfully.

Artifacts: `face-refinement-ec/{mesh-archive,topology-report,quality-comparison}.json`
and `refinement-compare-ec/`. Next address residual cavity surface continuity,
then rebake optics for the new geometry and validate jelly/animation appearance.
Old static optical fields are not valid for this changed rest mesh.

### ED / EE — reject adjacency smoothing; fit a spatially weighted face surface

ED attempted 8 local positive/negative smoothing pairs. Native orientation guard
stopped it before saving: independent numeric reproduction found one triangle
near (0.1408, 0.9213, 0.3199) flipped starting at pair 5. Constraining ED-r2 to
depth only prevented flips (minimum normal alignment 0.7591, maximum movement
0.00361), but actual front/40-degree renders showed worse ringing/faceting.
Reject ED-r2 despite passing topology checks. Its artifacts remain untouched.

EE replaces connectivity averaging with area-weighted quadratic fitting over
physical XY neighborhoods, preserving XY and the zero-weight region exactly.
Initial support was rank-deficient at sparse vertices; bounded support expansion
to at most 0.07 solves all fits (8 expanded vertices, default radius 0.035).
Body-only EE visibly smoothed the face but buried the mouth; reject that assembly.
EE-r2 transports all four face parts by barycentric interpolation of the same
body depth displacement, preserving sampled original front-surface offsets.
All part vertices found supporting triangles. This is not a full intersection
proof or a motion-validity claim.

The EE-r2 render helper hit an index mismatch: SurfaceTool rebuilt eye buffers
with a different vertex count. Stopped its live process; updated comparator to
skip indexwise tangent comparisons when topology/buffer sizes differ (null, not
zero error). EE-r3 then completed native Forward+ captures at 0/40/90 degrees,
exit 0. Viewed 0/40-degree images: visibly smoother eyes/mouth, restored frown,
no obvious new silhouette issue in those views. Material remains diagnostic clay.

EE body maximum displacement 0.0032993, minimum old/new triangle normal alignment
0.6277; no changes outside mask. Numeric input archive retains 85,448 body faces.
Body/eyes have no degenerate/boundary/nonmanifold edges; intentional pore/mouth
patch boundaries remain. Face-region maximum dihedral 43.14 -> 16.27 degrees;
mouth maximum 43.14 -> 3.23. Edges above 15 degrees: face 192 -> 2, mouth 189 -> 0.
These support the local smoothness diagnosis, not full reference acceptance.

Sources: `tools/meshy/fit_local_surface.py`, `gel_local_fit_ee.gd`, and
`gel_local_fit_ee_r3.tscn`. Artifacts: `local-fit-ee-r2.json`,
`local-fit-ee-r3/{00,40,90}-{before,after,repeat}.png`, saved mesh resources and
`topology-report.json`. All prior candidates preserved; production unchanged.
Next archive the coherent assembly with saved-resource verification, inspect
attachment closeups, and regenerate optical data for this geometry. Reference
translucency, viscous locomotion, internal flow, and animation acceptance remain
open; the active goal is not complete.

### EF — independent coherent assembly and attachment closeups

`archive_face_fit_ef.gd` saved all five EE-r3 mesh resources into `face-fit-ef`,
retained EC node transforms and clay materials, and saved `face-fit-rest.tscn`.
Mesh arrays agree exactly after resource reload; transforms and mesh arrays agree
after packed-scene reload. Headless archive exits 0. This is a standalone rest
assembly without the preceding mutation or optical-baking chain.

Checks on the actual saved-resource manifest (not just Python input) find body
42,726 vertices / 85,448 triangles; eyes 2,208 / 4,096 each. SurfaceTool merged two
eye vertices per eye during rebuilding. No degenerate, boundary, or nonmanifold
edges on body/eyes; intentional pore/mouth patch boundaries remain. Bidirectional
nearest-position comparison to intended EE-r2 positions has maximum error below
1.38e-7 across all parts. This does not independently prove triangle correspondence
or global absence of self-intersections.

Added optional capture target/distance/height/settle settings to DX, leaving
existing defaults unchanged. Native Forward+ `gel_eye_closeup_ef.tscn` and
`gel_mouth_closeup_ef.tscn` both finish 0/40/90-degree captures, exit 0. Eight
settling frames produce bitwise-identical before/repeat images in all six cases.
Viewed eye front/side and mouth front/40/90: eye surroundings are smoother with
no obvious detached gap in those views; mouth remains visible but its local
recess/lip relief is noticeably flattened by fitting. The side mouth view is
occluded and cannot certify attachment. Keep this as a provisional geometry
candidate, not final visual/reference approval.

Artifacts: `face-fit-ef/{face-fit-rest.tscn,mesh-archive.json,topology-report.json}`,
`eye-closeup-ef/`, `mouth-closeup-ef/`. Existing candidates and production model
remain untouched. Next retain the smooth surface while restoring a controlled
mouth recess (transporting its inset consistently), then rebake and evaluate the
orange translucent material on this geometry. Full jelly and motion scope remains
open; no production promotion or completion claim.

### EG — restore controlled mouth relief on the smooth assembly

`gel_mouth_relief_eg.gd` applies a compact smooth depth field around the existing
frown: Gaussian depression amplitude 0.0025, small rim amplitude 0.0006, continuous
arch and smooth support cutoff. Body and mouth receive the same spatial field;
eyes and forehead have exactly zero displacement. This avoids restoring the old
poorly tessellated relief or moving the mouth independently of its host surface.

Actual maximum depth shift: body 0.002499397, mouth 0.002499999. Minimum old/new
triangle-normal alignment: body 0.965605, mouth 0.981575 (no reversal). Saved mesh
arrays agree exactly after reload. `mouth-relief-eg/mouth-relief-rest.tscn` is a
preserved complete candidate scene. Manifest topology checks show no degenerate
triangles; body/eyes closed and manifold under the existing positional weld test.
Mouth/pore retain their intentional open patch boundaries.

Pinned native Forward+ closeup and independent full-body scene reload/capture
both exit 0 at 0/40/90 degrees. Viewed front/40 mouth closeups and full-body front:
subtle depression/shading restored while keeping the surrounding surface smooth;
no obvious new defect in inspected views. This is a provisional rest-geometry
result, not animation or final reference approval. Closeup before/repeat RGB
delta is 0 at every angle; full-body front delta is 4, remaining angles 0, so do
not infer fine pixel-level change from full-body front alone.

Artifacts: `mouth-relief-eg/` (scene, all five mesh resources, mesh manifest,
topology report, captures), `full-body-eg/`. Every earlier candidate remains.
Next move from clay to the orange translucent material on this actual mesh,
regenerating required optical data rather than reusing obsolete topology-dependent
fields. Existing inward-normal thickness baker is GLB-only and explicitly not
view thickness; do not substitute that scalar for refracted view/light paths.
Internal flow, viscous locomotion, all-animation and reference fidelity remain
unverified. Production model unchanged; active goal incomplete.

### EH — new mesh-bounded volumetric material prototype

Built `body-distance-eh` directly from EG's actual saved body using
`tools/meshy/bake_body_distance.py`: 64^3 signed-distance samples, float32, padded
subject-space bounds, clockwise-to-CCW conversion, positive signed volume 1.044845,
inside/outside sign probes. Manifest and payload hashes are checked on loading.
VTK distance semantics: https://github.com/Kitware/VTK/blob/master/Filters/Core/vtkImplicitPolyDataDistance.h
Texture API: https://docs.godotengine.org/en/stable/classes/class_imagetexture3d.html

New isolated `gel_volume_eh.gdshader` refracts the entry direction and samples
continuous internal density through the mesh-specific SDF. Single-scatter optical
integration uses two analytic studio lights and spectral extinction, combined
with native dielectric reflections. It does not reuse earlier static lookup fields
or deform geometry. It is explicitly a coarse rest prototype: no transmitted
scene background, exit refraction, multiple scattering, motion-updated SDF, or
validated integration convergence/performance. Flow time is frozen at zero.

First attempt rejected: docs' CLEARCOAT_GLOSS is unsupported by pinned binary;
binary symbols and generated material code show CLEARCOAT_ROUGHNESS. Corrected
and added empty-uniform-list compile rejection. R2 compiled/rendered but was
yellow/overbright and had fixed-step contour bands. R3 added adaptive view steps,
fractional boundary occupancy, lower source energy and stronger green/blue
extinction; viewed front render is orange and bands reduced, but it still reads
too solid/plastic and lacks the reference's golden thin-edge transmission.

R2 quit reported renderer resource leaks. Explicit subject cleanup removed those
but exposed an archived internal `@Node3D@5` name collision. Assigning distinct
plain names before parenting fixes the comparison lifecycle; R4 native Forward+
capture exits 0 without the preceding reported errors. Earlier attempts and all
old geometry remain preserved. Successful process exit is not visual acceptance.

Artifacts: `body-distance-eh/{distance.f32,volume.json}` and
`volume-eh{,-r2,-r3,-r4}/`. Next validate SDF sampling and ray exit coverage, then
add the missing transmitted environment/exit-interface contribution rather than
compensating for it with more emission. Reference micro-surface, golden edges,
internal-flow visibility and viscous animation remain incomplete. Production
unchanged; no promotion, no completion claim.

### EI — exit interface and shared environment, with GPU exit diagnostics

Added opt-in exit contribution to EH: bracket/bisect SDF boundary, central-field
gradient normal, refraction at gel-to-air interface and attenuated environment
radiance. A shared shader include drives both EI's reflected sky and transmitted
environment (the original EH sky remains unchanged). EI includes a rear studio
panel; before/after both use this same environment and calibrated EH material,
with only the exit environment contribution enabled on the after variant.

GPU diagnostic distinguishes successful exits (green), total internal reflection
(blue), exhausted view-step budget (red), and start-outside (yellow). At 128 steps,
saturated red pixels numbered 180/1/16 for 0/40/90 degrees. Most foot regions are
TIR, not failed exit intersections. R2 uses 256 steps and exact unpolarized exit
Fresnel rather than Schlick near the critical angle. Saturated diagnostic red and
yellow pixels are now 0 in all three views; green counts 207055/162166/126613 and
blue counts 57011/85002/63611. Counts exclude antialias boundaries and are not an
all-rays, all-cameras or light-path-convergence proof.

Both native diagnostic and appearance runs exit 0 without reported errors.
Viewed EI/R2 front: transmission contributes bright yellow arm regions, but a
strong foot-region boundary and excessive bright patches remain. Exact Fresnel
alone does not resolve this. Missing reflected continuation at TIR remains a
major known omission: that energy currently has no environment contribution.
Do not promote this material or describe reference quality as achieved.

Artifacts: `exit-diagnostic-ei{,-r2}/`, `exit-environment-ei{,-r2}/`, including R2
`pixel-classification.json`. All earlier output and default EH behavior preserved.
Next continue bounded internal reflected paths, recording residual trapped/budget
states, then evaluate the actual reference appearance. Coarse SDF fidelity,
micro-surface relief, visible internal flow, dynamic body deformation and GPU
performance are still open. Production untouched; goal incomplete.

### EJ — bounded internal reflected continuation and residual diagnostics

Added opt-in reflected branches after the first exit interface. Both partial
Fresnel reflection and TIR continue inside the same SDF; each segment integrates
extinction and single scattering, then splits transmitted environment from the
remaining reflected throughput at the next interface. Limits: 256 steps/segment,
4 or 16 reflections, low-throughput stop 1e-4. Default internal_bounces=0 keeps
older EH/EI behavior. This is not multiple diffuse scattering or dynamic geometry.

EJ four-reflection and EJ16 sixteen-reflection appearance/residual runs all finish
native Forward+ at 0/40/90 degrees, exit 0 with no reported errors. Residual mode
uses grayscale remaining maximum-channel throughput and magenta for exhausted
secondary step budget. No saturated magenta diagnostic pixels detected in those
views. Four-reflection changed diagnostic pixels: 35907/56154/47775, maximum RGB
186/170/182. At sixteen: 143/182/64 pixels, maximum RGB 39/42/43. Display RGB is
not linear energy; values include quantization/antialias limitations and do not
prove zero residual or convergence for other cameras/light paths.

Viewed front appearance: formerly dark foot core gains radiance, but strong
color boundaries and yellow patches persist. Four-to-sixteen appearance max RGB
delta 24/34/59, full RGBA mean delta 0.000381/0.001113/0.003716. Do not use these
small averages as a reference-match score: geometry occupies only part of frame,
and the remaining defects remain obvious. Higher bounce count alone is not the
solution. Need to evaluate ideal refractive interfaces against the rough glossy
surface, finite studio-light mapping, and SDF/light-path fidelity next.

Artifacts: `internal-reflection-ej{,16}/`, `reflection-residual-ej{,16}/`, and
EJ16 `comparison-analysis.json`. All old candidate assets preserved. Production
unchanged; no visual/animation acceptance or GPU performance certification.

### EK — environment filtering, micro-relief and exposure isolation

Preserved EG rest geometry and all previous candidates. Added opt-in nine-tap
environment-direction filtering (0.20 footprint) and reused the existing jelly
height texture for entry/surface normal relief. This only filters environment
radiance; it is not a complete rough dielectric BSDF. SDF exit normals remain
unperturbed. Fine scale 0.75/depth 0.0013 reads as pitting; R2 scale 0.18/depth
0.0048 gives larger variation but does not achieve the reference finish.

R3 isolates exposure at 0.25, retaining the R2 material and lighting. Its complete
nine-image set and comparison.json exist; the old process handle is no longer
available, so a terminal exit code is not independently recovered here. Front
and 40-degree images were visually inspected. All three before/repeat pairs are
pixel-identical (maximum channel delta 0).

Read-only PNG measurement: orange mask is R > 1.2*G and R > 50. Fraction of that
mask with R >= 254, for front/40/90 degrees respectively:

- EJ16: 94.4133% / 91.8235% / 77.9931%.
- EK R2: 97.6176% / 94.9334% / 79.0166%.
- EK R3 exposure 0.25: 0.0278% / 0.1061% / 0.3160%.

The mask changes with exposure; these are display-channel saturation diagnostics,
not fixed-pixel HDR energy measurements or reference-match scores. Lower exposure
visibly recovers orange tonal variation, but hard foot boundaries, yellow arm
patches, coarse highlights and a hard-plastic/glassy impression remain. Exposure
is a confirmed contributing issue, not a complete material fix. Do not promote.

Artifacts: environment-filter-ek/, micro-surface-ek/, micro-surface-ek-r2/ and
micro-surface-ek-r3/ under the audit output root. Next isolate internal transport
versus surface reflection at this non-saturating exposure before more detail
tuning. Visible internal flow, viscous movement, reference acceptance and actual
game GPU performance are still unverified. No production asset replacement.

### EL — isolate surface shading from internal transport

Added standalone component shader variants at EK R3 exposure 0.25, unchanged EG
geometry, camera, microrelief and 16 internal reflections. Combined material is
the before control; surface-only removes traced EMISSION; transport-only uses an
unshaded shader with traced radiance routed through ALBEDO. Shader parameters are
explicitly preserved when replacing the shader resource.

Initial script had a joined comment/extends parse error; stopped that exact
process and fixed the newline. Initial and R2 transport captures were black:
preserving uniforms alone did not resolve this. Those captures are invalid as
transport evidence and retained. Routing the computed radiance through unshaded
ALBEDO instead of EMISSION produces the expected visible transport in R3.

Surface R2 and transport R3 both complete 0/40/90-degree nine-image runs, native
Metal Forward+, exit 0. Inspected front component images: orange foot boundaries
and yellow arm regions remain clearly visible in transport-only; surface-only
contains broad uneven highlights but not those colored bands. This localizes
the bands to the traced transport contribution, not merely engine surface
reflection. It does not yet identify whether direct scattering, refracted
environment, coarse SDF normals or their interaction causes the discontinuity.
Next isolate those transport terms at the same exposure. Surface microstructure
also remains unlike the fine irregular reference texture; goal incomplete.

Artifacts: surface-isolation-el-r2/ and transport-isolation-el-r3/. Earlier EL
outputs retained as diagnostic failures. No production change or performance
acceptance; successful captures do not validate dynamic flow or animation.

### EM — separate scattering, environment and reflected continuation

Added environment_gain (default 1) to both direct and internally reflected
environment contributions; source_gain already gates both scattering terms.
Both comparison variants use the verified EL unshaded transport route. After
isolates scattering (environment_gain 0) or environment (source_gain 0), retaining
extinction, density, Fresnel, microrelief, exposure 0.25 and rest geometry.
Third run repeats the scattering isolation with reflection_count 0.

All three native Forward+ runs finish exit 0, producing front/40/90 degree
before/after/repeat images. Viewed front results: scattering with 16 reflections
has strong foot bands; environment-only has complementary dark foot regions and
yellow arm patches. Without reflected continuation the scattering foot bands
largely disappear, while a central crotch shading patch remains. This identifies
reflected-path scattering as a contributor to those bands; it does not prove
all bands are numerical bugs rather than ideal-interface transport behavior.
Removing reflection is diagnostic only, not an acceptable final-quality fix.

Next investigate exit-normal/path continuity and rough-interface treatment at
the same non-saturating exposure. The earlier environment lookup filter alone
cannot soften the interface's TIR/reflection path distribution. Fine irregular
surface relief, luminous reference finish and animated viscous flow still need
acceptance. All prior versions preserved, production untouched.

Artifacts: scattering-isolation-em/, environment-isolation-em/ and
direct-scattering-em/. These are component diagnostics, not beauty candidates
or proof of GPU performance.

### EN / EO — normal-footprint and optical-depth controls

EN adds exit_normal_radius, default 0.5 voxel preserving prior behavior. After
uses 2 voxels for the central-difference gradient, affecting exit refraction and
internal reflected directions without changing the SDF zero surface. Native
three-angle comparison exits 0. Front still has obvious foot bands and yellow
arms: larger gradient footprint alone is insufficient. Before versus EK R3 after
maximum channel differences front/40/90 are 1/0/0; before/repeat all exactly 0.
This is a footprint sensitivity test, not a higher-resolution SDF validation or
a rough dielectric treatment.

EO separately scales extinction and scattering coefficients together by 4,
preserving their channel-wise ratio, with baseline exit normals and all 16
reflections enabled. Native three-angle run exits 0. Inspected front: foot band
contrast and yellow arm patches are reduced, but the whole body becomes darker,
redder and less translucent than the orange luminous reference. Reject as a
final material; hiding bands by excessive optical density is not success.

This exposes a second material constraint: current calibrated scattering to
extinction ratios are approximately (0.7222, 0.0711, 0.00444), strongly suppressing
green/blue diffuse transport. Density alone cannot yield the reference's orange
diffuse core. Next test spectral scattering balance independently from density,
and retain the need for rough-interface transport and fine irregular surface
detail. Do not claim reference fidelity, flow, animation or performance passed.

Artifacts exit-smoothing-en/ and optical-density-eo/ retained alongside all old
versions. Changes are diagnostic tools only; production model not replaced.

### EP — spectral scattering balance with fixed optical thickness

Both variants inherit EO optical scale 4; after changes only scattering/extinction
ratio to (0.7222222, 0.55, 0.12), preserving red response, extinction, surface,
lighting and exposure 0.25. Native 0/40/90 comparison exits 0. Viewed front is
warmer but muddy ochre, not the luminous orange reference; not accepted.

R2 uses ratio (0.7222222, 0.3, 0.025) with exposure 0.65 for both controls. This
changes two parameters relative to EP, so do not attribute its entire improvement
to spectral balance alone. Front appears vivid orange rather than dark red or
ochre; however it remains too opaque, with broad patchy highlights and a visible
foot transition. Fine irregular relief and translucent edge structure still do
not match the reference. R2 native three-angle run exits 0; both runs have exact
before/repeat equality at every angle.

Orange-mask display saturation (R>1.2G and R>50, fraction R>=254): EP front/40/90
0.00267%/0.000813%/0.05238%; R2 17.2648%/13.3612%/6.9240%. R2 therefore reintroduces
meaningful red-channel saturation despite improved apparent hue. Next lower
exposure without changing spectral ratios before surface work; do not certify
R2 as final quality or promote it. Density and rough-interface transport remain
open, along with animation and visible internal flow.

Artifacts spectral-balance-ep/ and spectral-balance-ep-r2/ retained. Production
and all previous versions unchanged; shader skill used for isolated uniform
controls and native verification, not a production material replacement.

### EQ — reduced exposure and procedural irregular microrelief

Exposure 0.45 on both EP R2 spectral controls reduces orange-mask R>=254 from
17.2648% to 3.11468% front (40/90: 0.89757%/0.88700%). This is not zero clipping.
Added opt-in 3D nearest-seed squared-distance relief at scale 35, jitter 0.6,
depth 0.0015; default cellular_surface false preserves older texture behavior.
No vertices or silhouette changed, no additional mesh particles. This is only
surface/entry-normal relief, not a change to internal exit-interface roughness.

EQ first front has visible grid-like highlight structure. R2 raises jitter to
0.95 and depth to 0.006; relief is more visible but produces noisy/pixelated
sparkles rather than the reference's smooth fine facets. Both three-angle native
Metal runs exit 0. R2 orange-mask saturation front/40/90: 3.15372%/0.76249%/0.74005%.
Neither candidate is accepted. Raising relief alone is not sufficient.

Next inspect the screen-derivative normal construction: cell-boundary slopes
combined with fragment-quad derivatives can produce blocky highlight changes.
Analytic subject-space relief gradients are a testable alternative; they still
need antialiasing and temporal/gameplay-scale validation. Reference transparency,
fine surface, viscous motion and internal flow remain incomplete. Production
not replaced; all old candidates and both cellular-surface-eq{,-r2}/ retained.

### ER — analytic cellular surface gradients

Cell evaluation now returns height and its subject-space gradient. The opt-in
analytic_cell_normal path transforms the gradient as a covector, projects it
onto the surface tangent plane and perturbs the normal directly. Default false
preserves the screen-derivative path. No mesh or silhouette edits. ER compares
EQ R2 derivative normals against analytic normals at identical material settings.

Native front/40/90 nine-image run exits 0. Front inspection shows coherent small
curved cells rather than the previous blocky pixel highlights, but a scale-like
surface remains too pronounced and the core too opaque versus reference. This
is a normal-construction improvement, not final art acceptance. No animation,
temporal aliasing or GPU-performance validation is implied.

Read-only CPU finite differences of the same scalar relief at 200 seeded random
positions (epsilon 1e-7) agree with analytic gradients: maximum absolute error
1.32064e-8. This checks the derivative formula away from cell boundaries, not GPU
hash equivalence or continuity at nearest-seed changes. Cell-edge smoothing and
footprint filtering still require work; surface depth should be tuned only after
that continuity control. Existing reference/flow/viscosity requirements remain.

Artifact analytic-cells-er/ retained. All earlier candidates preserved; production
unchanged. Do not promote this scale-like finish as the requested jelly texture.

### ES — polynomial cell-boundary blending and lower relief

Opt-in cell_blend_width 0.15 blends squared-distance minima and their analytic
gradients; default 0 retains ER. Both comparison variants use analytic normals,
identical color/exposure and geometry. The sequential smooth minimum is order
dependent; this is not a proof of global continuity for every neighborhood.

Added reproducible tools/meshy/test_cell_relief.py. Two CPU tests pass: 200 seeded
finite differences maximum gradient error 2.74056e-8; 300 lattice crossings show
maximum height/gradient differences 1.07643e-7 / 5.94498e-5 at offsets +/-1e-9.
These sampled tests do not validate GPU hash precision, cell-edge antialiasing,
temporal stability or full-material physical accuracy.

ES depth 0.006 and R2 depth 0.003 native three-angle runs both exit 0. First front
still reads as orange peel despite softer junctions. R2 reduces relief strength
without changing color or optical thickness; retained as a gentler surface
candidate, not accepted reference match. Core opacity, foot-region transition,
eye/forehead integration and luminous transparent rim remain unresolved.

Artifacts soft-cells-es/ and soft-cells-es-r2/ retained with earlier versions.
No production replacement. Continue full reference assessment, including actual
visible flow and viscous movement; static surface tests do not satisfy them.

### ET / EU — clearer outer density and visible-flow check

ET adds opt-in density falloff from 0.2 at the SDF boundary to 1 at depth 0.08,
using smoothstep. Default skin_density 1 preserves previous behavior. The same
density function drives view extinction/scattering and light attenuation; no
new shell mesh, opacity compositing or outline glow. Both variants retain ES R2
surface and core coefficients. Native three-angle run exits 0. Viewed front has
slightly more golden edge transmission, but still an opaque-looking center and
foot-region transitions; not accepted as reference fidelity.

EU keeps both copies at ET settings, changing only flow_time from 0 to 6. Native
three-angle run exits 0; before/repeat pixels are identical in all views. Over
the orange mask (R>1.2G and R>50), maximum-channel absolute change mean front/40/90
is 3.55288/2.89034/2.90396 on 0-255 RGB; p95 8/6/6; fractions above 8 are
4.8588%/1.8873%/1.7012%. Changes are real but modest and mostly tonal. Static
endpoints do not prove recognizable liquid movement, smooth animation, runtime
frame rate or coupling to locomotion. Do not call flow accepted.

Next evaluate a continuous sequence and a more readable internal density pattern,
without adding satellite cells or sacrificing the coherent silhouette. Core
opacity and reference surface fidelity still require work. Artifacts clear-skin-et/
and flow-visibility-eu/ retained; old versions and production model unchanged.

### EV — continuous fixed-time flow capture

Added opt-in flow_capture_frames/fps and configurable bounded timeout to the
existing capture harness. Defaults retain prior static runs. EV produces 72
front-view frames at 12 samples/sec, times 0 through 71/12, encoded as six-second
flow-preview.mp4. Only flow_time changes; rest mesh, camera, surface and lighting
stay fixed. Native run exits 0; verified all 72 contiguous 1024x1024 PNG files.
FFmpeg encoding exits 0. This is offline playback, not measured real-time FPS.

Adjacent-frame orange-mask maximum-channel mean differences range 0.10166 to
0.11189 on 0-255 RGB; every adjacent pair has maximum change only 1. These are
visibility diagnostics, not a visual acceptance threshold. The flow remains
extremely subtle and does not establish recognizable slime-like internal motion.
Do not describe the goal as achieved or motion quality as validated by export.

Next make the internal pattern spatially readable (coherent moving density
streaks with retained clear outer layer), then rerun the same sequence. Do not
replace this with surface shimmer, brightness pulsing or extra particle cells.
Viscous locomotion, reference translucency and final surface fidelity remain open.
Artifact flow-sequence-ev/ includes source frames, comparison.json and MP4.
All prior assets retained; production unchanged. Testing skill guided bounded
capture and scope-limited technical validation rather than pixel-based acceptance.

### EW — spatially readable flowing density streaks

Added opt-in flowing_streaks density field: a height-dependent rotating XZ domain
and smoothly warped moving phase, with density bounded 0.12–1.77 before the clear
skin multiplier. Default false preserves EV. Same density affects extinction,
single scattering and light attenuation. This is procedural visual flow, not a
mass-conserving fluid simulation. Mesh, surface relief and lighting stay fixed;
no satellite cells, particle meshes or global brightness animation were added.

Native three-angle plus 72-frame run exits 0. Verified contiguous 1024x1024 PNGs;
FFmpeg six-second 12fps MP4 encoding exits 0. Adjacent-frame orange-mask mean
maximum-channel differences now range 1.47693–2.11824 versus EV 0.10166–0.11189;
per-pair maximum differences range 17–32 versus EV 1. This proves stronger temporal
image response, not successful slime-motion aesthetics or real-time performance.

Inspected time 0 and 3s frames: spatial bright streaks move through the body, but
they read too much as luminous bands, with over-yellow arms and occasional olive
areas. Not accepted or promoted. Next constrain modulation to deeper interior
and retain steadier clear boundary density, then re-evaluate whether the flow
looks like internal liquid rather than light sweeping across a solid surface.
Reference surface/shape, translucency and viscous locomotion still incomplete.

Artifacts flow-streaks-ew/ (frames, comparison.json, flow-preview.mp4) retained.
All previous candidates and production unchanged.

### EX — confine stronger flow to the interior

Opt-in interior_flow_only blends the streak field against steady density 0.9,
using SDF depth smoothstep 0.04–0.14; clear skin multiplication remains shared by
extinction, scattering and incident attenuation. Default false preserves EW.
Both comparison variants use streak flow; only the interior mask changes.

Native three-angle plus 72-frame sequence exits 0. Verified all contiguous
1024x1024 frames; six-second 12fps MP4 encoding exits 0. Adjacent-frame orange-mask
mean maximum-channel change ranges 0.78559–0.91968; maximum changes 5–11, compared
with EW 17–32. The reduced amplitude is not itself a quality score. Inspected front
shows reduced large yellow arm patches while interior bands remain visible.
Core still reads too opaque and the bands remain stylized; no full motion or
reference acceptance. This is a procedural field, not conserved fluid dynamics.

Next assess the more stable interior motion against the complete reference,
including shape/face integration and translucent rim; further shader-only
micro-tuning cannot stand in for full-character acceptance or viscous locomotion.
Artifact interior-flow-ex/ contains frames, comparison.json and flow-preview.mp4.
All prior candidates retained; production unchanged.

### EY — full-character reassessment and clay cavity-material correction

The archived pore and mouth still used diagnostic gray StandardMaterial3D:
albedo (0.025,0.025,0.025), roughness 0.65. EY overrides only those two materials
with dark warm albedo (0.0015,0.0003,0.0001), roughness 0.9, specular 0. Geometry,
eyes and EX body stay unchanged. Native three-angle run exits 0; inspected front
has darker, clearer openings. This does not create missing recess geometry.

Re-inspected the original CHAR-BASE-T-3d-alt.png against EY: reference has a rounded
raised/recessed pore rim, integrated eye sockets, thin mouth opening, luminous
golden edges and soft fine facets. EY still lacks pore-rim depth, eye integration,
natural internal optical depth and the reference's finish. Dark material alone
does not fix those omissions. Actual locomotion/deformation remains unverified.

Read-only projection measurements via measure_reference_proportions.measure:
reference threshold-swept width/height 0.99671–1.01228, EY 1.05333. Eye center height
relative to body: reference 0.44408–0.45880, EY 0.45333; eye height/body height
reference 0.13158–0.13393, EY 0.12. These are projection/glow/camera-dependent, not
intrinsic 3D resize factors. Do not blindly stretch geometry from these numbers.
Prioritize restoring integrated pore/eye relief on a separately validated mesh
before further cosmetic shader tuning. Re-bake the body SDF if geometry changes.

Graph discovery reports IMMUNE- unindexed; known local sources read as fallback.
Artifact face-material-ey/ retained. All earlier assets and production unchanged;
3d-essentials used for isolated material instancing and native comparison.

### EZ / FA — coherent pore relief and matching optical volume

EZ applies one compact Z-depth field to the EG body and pore patch around
(0,1.035): radius-0.052 rim, amplitude 0.009, width 0.014; central recess -0.008,
radius 0.035; compact support ending at 0.1. Eyes and mouth positions unchanged.
Saved separate meshes plus pore-relief-rest.tscn; mesh save/load equality passes.
Native front/40/90 clay closeups exit 0. Viewed front has rim/recess but remaining
coarse facets, so this is not a final smooth facial surface.

Topology unchanged. Body maximum shift 0.008149, minimum triangle normal dot
0.86161; pore 0.00799999 / 0.959523. Zero degenerate triangles or >2-use edges
across all five parts. Body index-boundary edges 0; eye index seams 318 each,
pore 32 and mouth 64 are unchanged (index edges must not be confused with welded
geometric boundaries). No claim of global self-intersection/animation validation.

Re-baked 64^3 SDF from the EZ manifest, not the old EG shape. Source SHA
c717f7219fc0e75e2edbdba6b163a3ac7e32540e25fae40f6828ed23d32afa39,
payload SHA 0cfdddba843aa3743d002de3f810aa73317aa1b19749487e1c6fa213426e6af8.
Loader now allows explicit volume-folder/source-manifest selection with prior
defaults preserved and source/payload verification retained. FA pairs each mesh
with its matching SDF; both copies have EY dark cavities and EX material.
Native full-body three-angle FA exits 0. Viewed front shows a more integrated
highlighted pore rim. Remaining pore faceting, eye integration, core opacity and
reference fidelity still unresolved; no production promotion.

Artifacts pore-relief-ez/, body-distance-ez/, pore-optics-fa/. All older versions
preserved. Asset skill guided separate resource archives and matched optical
rebaking; no imported cache edits. Next improve local pore tessellation/normal
smoothness and validate full-face integration rather than inflate the ring.

### FB — locally refine the pore before applying relief

Reused midpoint red/green splitter, with shared edge midpoint IDs, three local
passes and 0.006 edge-length threshold inside radius 0.13 around the pore on the
front surface. Refinement starts from EG, then reapplies exactly the EZ depth
field (not an additional bump on the already deformed EZ mesh). Before is EZ.
UVs and vertex colors interpolate; normals/tangents rebuild. Unsupported rest
attributes fail explicitly rather than silently discard data.

Initial run correctly stopped at unsupported vertex-color attribute, exit 2.
Added color interpolation and reran to a new directory. FB R2 native closeup
three-angle run exits 0, archive mesh round-trip equality passes. Body vertices
42726 -> 47124; triangles 85448 -> 94244. Minimum deformation normal dot 0.843378;
body has zero index boundary edges, nonmanifold edges or degenerate triangles.
Other meshes retain prior counts, pore/mouth patch boundaries and eye seams.
No global self-intersection or animation validation is implied.

Viewed front: ring is more continuous but some waviness remains from the base
surface. Do not call full reference match. New archive pore-refine-fb-r2/
pore-refined-rest.tscn is separate; its matching optical volume has NOT yet been
baked, so do not use it with EZ/EG SDF. Next verify smooth base interpolation near
the ring and bake its matching volume before full-material evaluation. Current
production, earlier versions and the initial failed FB output remain untouched.

### FC — full-material comparison of refined pore

Completed the previously pending FB matched 64^3 optical bake. Source manifest
SHA 7e4f767f94997ff6a2c3d1af7d3fdc2ad568d07d0ffedd617be9c884fd61a5ea;
payload SHA d66dd80183565bd37a5d26faa41327be79023fe22062a1fc24b4bd7d7fa452f0.
Both hashes verified independently and by the native loader. FC pairs EZ with
body-distance-ez and FB R2 with body-distance-fb, applying identical EY/EX
material, lighting and camera settings. No production or imported-cache edits.

Pinned Godot 4.7.2 Metal Forward+ on Apple M4 Pro completed front/40/90 captures
with exit 0. Eye tangent comparison remains identical. Viewed front before/after:
the refined ring reflection is more continuous, but this is a small local change;
the body still looks orange-peel/plastic-like, with opaque patches and poorly
integrated eyes. This is NOT reference-match, animation or performance acceptance.
Keep FB as an experimental candidate only, not a production replacement.

Artifacts: body-distance-fb/ and pore-optics-fc/ under the existing audit output
root. Asset-pipeline discipline kept separate mesh/volume pairs and all prior
versions. Production GLB SHA remains
3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3.
Next priority is full-character material/readability rather than further tiny
pore changes: reduce faceted surface response and resolve internal opaque bands,
then reassess against the reference before any animated integration.

### FD / FE — separate surface and optical-density controls

Both variants use FB R2 and its verified body-distance-fb volume. FD changes only
the surface profile: cellular scale 35 -> 55, depth 0.003 -> 0.0008. FE uses that
refined profile on both sides and scales extinction and scattering together by
0.625 on the after side (effective optical_scale 2.5 instead of 4). No exposure,
lighting, geometry, cavity or camera changes. Shader skill guided separate
material uniforms rather than destructive edits to prior candidates.

Both pinned Metal Forward+ runs completed front/40/90 before/after/repeat captures
with exit 0; source/payload hash verification and unchanged eye tangent checks
passed. Viewed both front results against CHAR-BASE-T-3d-alt.png. FD reduces coarse
sparkle but loses surface character and still reads as smooth plastic. FE makes
arms yellower and body brighter without eliminating flat opaque-looking bands.
Neither is accepted as a closer overall reference match or promoted. These
controls rule out these particular parameter changes as sufficient fixes, not
all surface/density approaches. Motion and performance remain unverified.

Preserved outputs material-balance-fd/ and material-balance-fe/. Next examine the
spatial lighting/transport response behind persistent flat bands; simply lowering
surface relief or extinction is insufficient. Reference also requires richer
golden rim transmission and integrated eye sockets, not just higher brightness.

### FF — incoming-light integration convergence

Inspected light_depth: a fixed 24-step march could return before leaving the
body, with step lengths 0.008..0.10. Added optional uniforms retaining exactly
those legacy defaults; FF after uses 512-step cap and 0.002..0.03 step lengths.
Both sides use FB geometry/SDF and the FC material, not the rejected FD/FE
surface/density adjustments. Production shader files were not edited this turn.

New read-only CPU probe check_light_depth_budget.py samples 4154 interior points
from a 25^3 lattice, both fixed shader light directions, EX density at time zero,
and trilinear SDF sampling. Against a finer numerical march (4096 cap,
0.00025..0.001 steps), legacy has 5 / 10 unfinished rays; refined has 0 / 0.
Mean absolute optical-depth errors: 0.004978 / 0.004547 legacy versus
0.000371 / 0.000361 refined. Maximum errors 0.076899 / 0.233512 versus
0.001458 / 0.001209. This is sampled CPU convergence evidence, not analytic
ground truth, exhaustive GPU validation, or reference-image similarity.

Native pinned Metal Forward+ front/40/90 captures exit 0. Viewed front retains
the opaque-looking bands and coarse surface despite improved light integration.
Foreground (before max RGB >20) mean maximum-channel change is 1.15009/255;
global maximum channel change 37/255. Thus the tested light-step limitation is
real but its correction is insufficient to explain/fix the broad visual mismatch.
Preserve light-convergence-ff/ as an accuracy control; do not promote or claim
performance suitability. Prior versions remain selectable through default values.
Next focus on directional internal-reflection/environment structure and the
reference's broad luminous rim rather than treating numerical accuracy alone as
art-direction acceptance.

### FG / FH — broad incident fill and failure-driven workflow change

FG adds six axis directions of attenuated incident fill (average, gain 3) to
both primary and reflected scattering paths. This is an art-directed extra light
source, NOT multiple scattering or a physical environment integral. Default gain
zero preserves earlier material settings. Direct nested GPU marching triggered
repeated Metal fence timeouts; stopped the exact process (60989, exit 143).
Do not run FG as a production or accepted diagnostic profile.

Changed workflow to a CPU-generated 32^3 RGBA float32 rest-fill texture, using
the same six rays, extinction (3.6,18,72), EX density time zero, FF light stepping.
All bake rays completed. Payload SHA
e99c9aa7a5f27da5010ae86c91a7638e0395cb5b5aaa6b7d11deda77abfcbd75.
Saved separately in rest-fill-fh/ with model/SDF hashes, bounds and settings.
FH loader checks source/SDF/payload hashes, byte count, extinction and static
time/no-flow-capture constraint. Changing density implementation or shape requires
rebaking; this is not valid animated illumination. Interpolation error at 32^3
has not been quantified. Asset skill guided isolated baked data; shader skill
guided optional uniforms rather than replacing earlier materials.

Initial FH stopped after a null shader-override value was passed to float().
Handled unset override as its explicit shader default zero, then reran to unique
rest-fill-optics-fh-r2/. Pinned native Metal Forward+ completed all three angles,
exit 0 with no fence timeout in this run. This is completion evidence, not FPS
profiling. Viewed front: brighter, less prominent foot bands, but core remains
opaque-looking and relief still reads too faceted; no reference-match acceptance.
The broad-fill direction warrants comparison at matched brightness before deciding
whether it improves material character rather than merely adding light.
Production and all earlier/failed outputs retained; no promotion.

### FI — brightness-controlled fill comparison and decision

Added optional two-value comparison_exposures to the rest capture harness; empty
retains old behavior. Values apply before settle frames for each before/after/
repeat and are recorded in comparison.json. Invalid nonpositive/length settings
or simultaneous flow capture reject. Testing skill guided bounded native capture
and diagnostic scope; this is not a GUT/gdUnit4 pixel-golden unit test.

Measured FH front decoded-sRGB mean luminance 0.259783 before / 0.328665 after.
FI exposure 0.45 / 0.35568875 reduced the difference to +2.052%; FI R2 exposure
0.45 / 0.34854 gives 0.259783 / 0.259976, difference +0.0743% on the fixed
before foreground mask (max RGB >20/255). Thus front average display brightness
is approximately matched, not the whole histogram or scene radiance. Side means
remain +2.200% and +3.458%; do not claim those views brightness-matched.

At front, luminance std/mean drops 0.28912 -> 0.25829; red >=254/255 fraction
drops 5.919% -> 3.920%. Neither statistic is a material-quality score. Both native
runs completed all three angles, exit 0; R2 before/repeat maximum channel delta
0 / 1 / 0 at 0/40/90 degrees. Read-only measure_capture_luminance.py reproduces
the metrics. No image editing/post-processing was used for comparison.

Viewed R2 front: fill genuinely redistributes brightness, but body still reads
opaque and faceted, with shallow-looking facial features. Keep as a lighting
option only, not a accepted reference-matched character. Stop treating further
global brightness tweaks as the main next step: the missing integrated orange
eye rims and eye seating are a separate conspicuous reference mismatch and should
be addressed geometrically before another material polish pass. Preserve
fill-exposure-fi/ and fill-exposure-fi-r2/ plus all prior versions; no promotion.

### FJ — integrated eye-rim rest geometry

Measured FB eyes in subject XY: centers +/-0.27339514, y=0.85500012; principal
half extents 0.12205179 / 0.08318894, mirrored major axis (0.98172638,0.19029798).
FJ uses these as an approximate elliptical rim guide, not a silhouette-exact fit.
Body-only local midpoint refinement (three passes, edge threshold 0.006 inside
eye radius 1.85) precedes a shared body/eye Z field: rim +0.008 at normalized
radius 1.13 with width 0.22, center recess -0.003 exp(-2*r*r), compact fade
1.55..1.8, front z>=0.23. No separate rim object, satellite or extra character.

Initial run and diagnostic probe stopped with exit 2 at EyeL orientation gate.
Probe revealed local-coordinate normal dot -0.620870; eye depth scale is 0.014
versus much larger XY scales. Independent subject-space CPU evaluation instead
gave minimum dot ~0.93975 / 0.93640 for eyes. FJ R2 bakes eye transforms into
vertices, rebuilds normals/tangents, sets identity transforms, then applies the
same relief and unchanged positive normal-dot criterion. It does not lower the
gate. This changes tangent basis and is not a normal-map equivalence claim.

R2 pinned native clay front/40/90 exits 0; exact resource save/load passes.
Body vertices 47124 -> 56118, triangles 94244 -> 112232, minimum normal dot
0.928411. Body index boundary/nonmanifold/degenerate counts all zero. Eyes retain
2208 vertices/4096 triangles and 318 index seams each; minimum normal dots
0.939752/0.936401. Pore/mouth counts and intentional boundaries unchanged.
All five meshes have zero degenerate triangles or >2-use index edges. These are
not global self-intersection or animation tests. Eye tangent report shows 176/171
handedness differences and component delta 2 after transform bake/regeneration;
do not treat old tangent-equality assertions as passed.

Viewed front clay closeup shows connected raised eye rims, with some broad/wavy
edges; full orange material fit remains unverified. New archive eye-rim-fj-r2/
eye-rim-rest.tscn needs its own SDF before optical comparison; never reuse FB SDF
or FH fill on it. Asset skill guided baked transforms and separate archives.
All prior/failed outputs and production preserved. Next validate the matched
full-material appearance and eye/body intersections before any promotion.

### FK — matched eye-rim optics, full body and closeup

Baked 64^3 SDF from FJ R2, source SHA
e0ff2d99ee84c720127fa7b3ebc51cf7d0896593fb66f9535e1fec9e0db764b8,
payload SHA 4d3f393c6bcd63de997513adae4c8fb00c6315482927061c8b4b2b1ef6046943.
Signed body volume 1.04524138098, range -0.41267914..0.75012749. Native loader
verifies hashes on both FB-before and FJ-after. FK uses identical EY/EX material,
FF light stepping, shared 0.45 exposure; no obsolete FH fill on the new shape.

Full-body and face-closeup front/40/90 native pinned Metal runs both exit 0.
Viewed full front/40 and face front: rim highlights now appear around eyes,
but remain narrow/patchy and are visually overwhelmed by coarse cellular relief.
This is limited local evidence, not overall reference fidelity. The core is still
too flat/opaque-looking and eye seating/intersections have not been quantitatively
validated. Tangent report retains FJ transform-bake changes; not an equality pass.

Ran existing check_face_archive.py on FJ, saved welded-topology-check.json:
body and eyes zero boundaries after 1e-7 weld, all five parts zero nonmanifold
edges or triangles below area 1e-12; pore/mouth intentional boundaries 32/64.
This checks each mesh separately, not eye/body intersections or global self-
intersection. Asset-pipeline skill enforced matching geometry-specific volumes
and separate outputs body-distance-fj/, eye-optics-fk/, eye-optics-fk-close/.
No production promotion or deletion. Next isolate cellular normal relief near
the facial rims (preserving body detail) to expose the modeled smooth rim, then
reassess its contour rather than enlarge geometry blindly.

### FL — localized facial normal-strength control

Added optional smooth_facial_rims, default false. On the analytic cellular-normal
path only, a smooth rest-space band around the measured FJ eye ellipse and pore
reduces normal perturbation strength to 0.08 at the rim, returning to 1 outside.
Front depth fade 0.18..0.28 prevents affecting the back. This is art-directed
normal strength, not the exact gradient of a displaced height field. Geometry,
SDF, eye materials, body detail parameters, lighting and exposure are identical
between both FJ variants. Prior variants retain default behavior.

CPU formula probe (10,000 seed-0 points) confirms finite strength within 0.08..1,
exact mirror symmetry, and strength 1 behind the front-depth gate. This does not
prove GPU equivalence or visual acceptance. Initial inline probe accidentally
placed assertions after a function return; its empty exit-0 result was NOT counted.
Corrected indentation and explicitly observed the printed assertion results.

Pinned native full-body and closeup front/40/90 runs both exit 0. Viewed front
closeup and full-body: rim reflections are more continuous and readable, but can
still look like flat outlines; coarse body facets and opaque-looking core remain.
This is a limited facial finish candidate, not the requested overall jelly match.
Eye tangent comparison is equal here because both variants use the same FJ mesh;
it does not resolve the earlier FB-to-FJ basis change. No animation/intersection
or GPU performance acceptance. Shader skill kept the control local and optional.

Preserved facial-finish-fl/ and facial-finish-fl-close/ and all previous versions.
No promotion. Next test whether 64^3 SDF resolution is suppressing the thin facial
geometry in optical transport (eye rim amplitude 0.008 versus roughly 0.02–0.03
grid spacing), before introducing further geometry or brightness changes.

### FM — 128^3 SDF fidelity control

Baked body-distance-fm-128 from the same FJ manifest. Source SHA remains
e0ff2d99ee84c720127fa7b3ebc51cf7d0896593fb66f9535e1fec9e0db764b8;
payload SHA 368068e26b358788c8746e46bd236db6982d0c5b71df93c4cab793f967d0d17a.
Payload increases 1 MiB -> 8 MiB. New read-only measure_sdf_surface_error.py
verifies both hashes and samples trilinear SDF residual at 56118 body vertices.
All-vertex mean absolute residual 0.000521765 -> 0.000171562; max
0.0118291 -> 0.00322425. On 26339 front-face vertices, mean 0.000521390 ->
0.000155451, p95 0.00181023 -> 0.000534505, max 0.00512651 -> 0.00182624.
These are vertex zero-level residuals, not continuous-surface Hausdorff error.

Native FM uses identical FJ geometry, FL face smoothing, FF light stepping,
material/lighting/exposure. Exit normals retain half-voxel gradient radius, so
physical normal-estimation support also shrinks with resolution. Full front/40/90
run exits 0 with source/payload verification; eye tangents identical. Viewed front
and 40-degree after: no decisive overall visual improvement; opaque patches,
coarse body facets and outline-like eye rims persist. Better geometric sampling
is therefore insufficient to solve the art-direction gap, and 128 is not promoted
solely because its numerical error is smaller. Runtime FPS cost remains untested.

Asset skill preserved both data versions and source linkage. Outputs in
body-distance-fm-128/ and volume-resolution-fm/. No deletions or production edits.
Next return to the material's overly hard surface response and flat internal
color structure; do not keep escalating volume resolution as a proxy for quality.

### FN — reference-directed scattering palette, rejected clipping tradeoff

Re-measured the actual reference rather than assume it permits more clipping.
New read-only measure_orange_palette.py selects orange pixels independently
(R>0.2, R>1.15G, G>1.1B in 0..1 sRGB). This heuristic excludes some highlights
and dark areas and is not a similarity score or aligned pixel comparison.
Reference median RGB is (0.97255,0.38824,0.01176), versus FM
(0.82745,0.41961,0.09804); selected-pixel red>=254/255 fraction reference 2.657%
versus FM 5.858%. Reference green p10..p90 0.21176..0.63529 is much wider than
FM 0.36863..0.50196. Thus simply raising global brightness is not supported.

FN keeps both FJ/128 SDF variants, FL masking, FF light integration, exposure and
lights unchanged; after changes scattering/extinction ratios from
(0.722222,0.3,0.025) to (0.98,0.23,0.003), all within 0..1. Pinned native three-
angle run exits 0 with matching hashes and identical eye tangents. Viewed front
has less grey/brown and a stronger red-orange hue. Median RGB improves toward
reference to (0.93333,0.37255,0.01961), but red-near-clip fraction rises to 24.358%.
Green p10..p90 remains narrow (0.32549..0.45490); flat patches and coarse surface
are still evident. Do not promote this tradeoff as the desired final quality.

Preserve reference-spectrum-fn/ as a palette direction only. Shader skill guided
material coefficient changes without editing images or overwriting old profiles.
Next test highlight rolloff/tone response while preserving the improved midtone
hue, rather than increasing red scattering further. The target includes spatial
translucency and surface character, not just matching median color statistics.

### FO — highlight rolloff with palette/exposure calibration

Added default-no-op per-capture configuration hook to the bounded harness; FO
records actual tone mode/exposure/white values in comparison.json. Both copies
use FN geometry and spectrum; initial FO compares linear vs filmic at exposure
0.45, white 6. Filmic removes selected orange-pixel red clipping but darkens median
RGB to (0.80784,0.39216,0.01569), so it is not sufficient by itself.

FO R2 retains FN linear before and calibrates filmic after with exposure 1.2,
scattering/extinction ratio (0.98,0.09,0.001), white 6. This is a combined art-
direction profile, not a tone-mapper-only causal test. Both pinned native runs
complete all three angles, exit 0, hashes verified and equal eye tangents.
Testing skill guided bounded capture, controlled baselines and recording actual
settings; these are visual diagnostics, not a GUT/gdUnit4 acceptance suite.

Viewed R2 front is brighter red-orange with more retained highlight range.
Orange-mask median RGB (0.93725,0.40784,0.01961), mean decoded-linear display
luminance 0.300008 (reference 0.307110), red>=254/255 fraction 0.00542% instead
of FN 24.358%. Reference median remains (0.97255,0.38824,0.01176). Green p10..p90
widens to 0.35294..0.55686 but is still narrower than reference 0.21176..0.63529.
Independent orange masks exclude some highlights; statistics are not proof of
full material/reference match. No image edits were used.

Preserve highlight-rolloff-fo/ and highlight-rolloff-fo-r2/. R2 is a more useful
palette/highlight candidate, but coarse faceted surface, flat internal regions,
eye integration, dynamic behavior and performance remain unaccepted. No production
promotion or deletion. Next improve surface reflection character without losing
this highlight range; do not treat close average luminance as a completed goal.

### FP — surface roughness isolation and interrupted-run handling

Exposed surface_roughness and coat_roughness with previous defaults 0.12/0.15.
FP compares FO R2 on both sides, changing only these engine reflection parameters
to 0.24/0.22 after. Cellular normals, internal transport and filmic profile remain
identical. Shader skill keeps earlier defaults and isolated material variants.

Initial FP emitted repeated Metal fence timeouts; explicitly stopped PID 66803,
confirmed exit 143. Disk ~21 GiB free; memory_pressure -Q reported 44% system-wide
free, and an unrelated /Applications/Godot process was left alone. Root cause is
NOT established; do not infer the new roughness values caused resource exhaustion.
R2 reduces static settle frames 8 -> 2 without changing 1024 resolution, geometry
or material. It completes all three angles, exit 0 with no observed fence timeout.
Before/repeat maximum channel delta is 0 at every angle. This supports stability
of that baseline in this run, not a definitive timeout fix or FPS benchmark.

Viewed R2 front: highlights broaden, but rounded cellular bumps become more
obvious; it does not resolve the hard/scaly material impression. Foreground mean
luminance increases ~1.27%/1.21%/1.81% at front/40/90; no quality score is implied.
Keep as a control, not a promoted improvement. A smoother outer reflection layer
over finer internal/body detail may better fit the reference than increasing the
roughness of a single shared bumpy normal field; this remains a hypothesis to test.
Preserved surface-reflection-fp/ failed artifacts and surface-reflection-fp-r2/,
all previous versions and production assets.

### FQ — decoupled outer reflection normals

Added reflection_normal_detail with default 1 (previous behavior). FQ holds
FO R2 palette, filmic exposure 1.2, FJ rest geometry, 128 SDF and original
roughness fixed; after uses 0.15 normal detail for engine surface reflection.
The normal is blended back toward the original mesh normal only after optical
transport and entry Fresnel were evaluated. Internal ray detail stays unchanged.
This shader-skill-guided isolation is an art-directed approximation, not a
reciprocal two-interface dielectric or a physical liquid simulation.

Pinned native run completed all three angles and exit 0 without observed errors.
Before/repeat maximum channel delta is zero at all angles. Foreground mean
decoded display luminance changes -0.50%, -0.29%, -0.45% at 0/40/90 degrees;
these are stability/brightness diagnostics, not acceptance scores.

Viewed front before/after and 40-degree after alongside the reference. FQ reduces
fragmented cellular highlights, but broad smooth white reflections now read more
like glossy plastic. The interior remains visually flat and a strong lower-body
bright band remains at 40 degrees. Reference fine irregular texture, translucent
golden edge depth and substantial embedded eye/pore rims are still not matched.
Keep smooth-skin-fq/ as a control, not a production promotion or visual lock.
All previous versions remain preserved. No animation or performance acceptance
is implied. Next separate interior-band diagnosis from fine-scale surface design;
do not keep smoothing the entire reflection field as a presumed solution.

### FR / FS — isolate lower-body transmitted bright band

FR holds FQ on both copies and sets environment_gain to zero only after. Source
inspection confirms this removes environment exit radiance on direct and internal
reflection paths, while retaining scattering along those paths and engine outer
reflection. Native 0/40/90 captures complete, exit 0; before/repeat deltas all zero.
Viewed 40-degree after: yellow foot band and hand transmission weaken markedly,
but some lower-body structure remains. Disabling transmission is not a quality fix.

FS adds default-false diagnostic_uniform_environment to filtered_environment;
after substitutes constant linear RGB (1,1,1), keeping outer reflection lighting
unchanged. This is not energy-matched to the studio. Viewed 40-degree result still
has the localized foot band: directional studio structure alone is insufficient
to explain it. Transmission/path length/interface behavior needs further isolation;
this does not yet distinguish expected thin-region transport from a numerical bug.

Initial FS exits 0 but front before/repeat max delta is 16/255; reject a blanket
determinism claim. Preserve it and run FS R2 with settle frames 2 -> 4, unchanged
resolution/material. R2 exits 0, all three before/repeat deltas zero. This supports
that run's comparison stability, not a universal warm-up fix. Mean display luma
changes -1.86%, +0.19%, +4.21%; no reference-quality score implied.

Preserve exit-isolation-fr/, uniform-exit-fs/, uniform-exit-fs-r2/ and prior
versions. Shader skill guided default-preserving diagnostic controls. No production
promotion. Next isolate entry-normal perturbation under constant environment,
then inspect path-length/interface behavior if the band persists.

### FT / FU — entry-ray and flowing-density isolation

FT keeps FS R2 constant exit environment on both sides and changes only entry
ray direction to use the original mesh normal after. Outer reflections and entry
Fresnel retain previous normals. Default-false diagnostic_smooth_entry_ray avoids
changing earlier profiles; this deliberately inconsistent diagnostic is not a
production dielectric. Native three-angle run exits 0, repeat deltas all zero.
Viewed 40-degree after: jagged band becomes smooth but remains sharply localized.
Entry bump detail therefore explains band edge texture, not its existence.

FU keeps FT smooth-ray configuration on both sides and replaces interior density
with constant 0.9 after, retaining the clear-skin density layer. Default-false
diagnostic_uniform_density changes both view and light attenuation consistently.
Native run exits 0, repeat deltas zero at all angles. Viewed 40-degree after: the
thin lower bright stripe largely disappears; a broader foot/hand transition
remains. Mean luminance changes -0.95/-0.86/-1.53 percent at 0/40/90 degrees.
This implicates the high-contrast streak density field in the thin stripe under
these controlled conditions; it does not prove all transport is numerically sound.

The uniform-density render remains plastic-looking and removes requested internal
motion cues, so it is a control, not a fix or reference match. Next redesign the
flow density as softer volumetric variation rather than sharp broad sine sheets,
then restore studio environment/detailed entry rays and validate motion as well
as stills. Preserve entry-ray-ft/, density-isolation-fu/ and all previous versions.
Shader skill guided isolated, default-preserving controls; no production promotion.

### FV — softer volumetric flow candidate and failed continuous capture

Added default-false soft_volume_flow. Within the existing rotated coordinate field,
use three intersecting sine factors with smooth coordinate warp, density 0.9 +/-
0.45 instead of thresholded sheets spanning 0.12..1.77. Existing interior mask and
clear-skin layer remain. This changes spatial structure and contrast together;
it is art-directed animated density, not mass-conserving liquid simulation.
FV inherits FQ directly, restoring studio environment and detailed entry rays;
none of FR/FS/FT/FU diagnostic switches are enabled.

Static native run completes three angles, exit 0, before/repeat deltas all zero.
Viewed 40-degree after: thin lower stripe is reduced while hand/foot transmission
remains. Broader lower-body transition and plastic-like surface/core remain.
Mean foreground display luminance changes -1.18/-0.75/-0.36 percent. Candidate
addresses one artifact, not full reference fidelity. Preserve soft-flow-fv/.

Attempted 48-frame, 12 fps offline rest sequence in soft-flow-fv-motion/. After
frame 36 progress, repeated Metal fence timeouts appear at force_draw and image
readback. On inspection PID 72213 was already gone; session confirmed terminal
exit 0 despite errors and a completed comparison.json. Reject this motion run:
exit status and frame count do NOT establish render validity. No video promoted,
no automatic retry. Disk ~21 GiB free, system memory_pressure reports 45% free;
these snapshots do not establish the timeout cause. Preserve failed artifacts.

Next add external stderr-error gating to capture runs so GPU errors cannot be
reported as success, then isolate frame/readback load in bounded captures before
another full motion attempt. Do not solve this by disabling requested motion or
claiming the static candidate passes animation/performance acceptance. Shader skill
guided separate material controls; production assets and earlier versions unchanged.

### Capture guard / FV short — fail closed and assess visible change

Added tools/meshy/capture_guard.py: starts only its own child, merges stdout and
stderr into an exclusive new log directory, stops that child on detected ERROR /
fence timeout, bounds elapsed runtime, and requires the harness completion marker.
Its clean_process status explicitly excludes frame integrity and visual acceptance.
Seven subprocess tests cover clean completion, zero-exit GPU error, live stderr
error termination, timeout, nonzero exit, missing marker and existing-output refusal.
Tests first failed for the absent module, then all passed after implementation.
Godot testing skill guided bounded async/error-path testing; this Python supervisor
suite is not a GUT/gdUnit4 scene suite or pixel golden test. Graph discovery was
unavailable for IMMUNE-, so local file discovery was used.

FV short keeps resolution 1024, all material settings and 12 fps; reduces requested
continuous sequence from 48 to 12 frames to isolate sustained capture exposure.
Guarded run completes in 39.23 seconds, no detected error, all 12 PNGs decode at
1024x1024. This does not resolve the longer-run Metal timeout or measure game FPS.
Adjacent whole-image mean absolute channel change is only 0.00517..0.00560 /255;
first/last maximum channel delta is 5/255. Viewed last frame remains plastic-like.
Pixel change proves a non-static output, not adequately visible slime circulation.

Preserve soft-flow-fv-short/ and soft-flow-fv-short-guard/. No production promotion.
Next improve internal optical contrast/depth so softer motion is perceptible without
returning to high-contrast sheets; retain guard for subsequent native capture runs.
Longer continuous capture stability remains an independent unresolved requirement.

### FW — lower optical depth blocked by native render error

FW holds FV soft flow on both copies, halves extinction and scattering together
after, preserving scattering/extinction ratio, geometry, studio and exposure.
The purpose is increased interior visibility without replacing flow with uniform
density. Shader skill guided coefficient pairing and isolated material instances.

Guarded native attempt stopped at the first Metal fence timeout in force_draw,
14.81 seconds, child exit -15, completion marker absent. Guard correctly reports
render_error rather than success. Preserve optical-depth-fw/ partial artifacts
and optical-depth-fw-guard/ process.log/result.json. Do not use partial images for
quality judgment. No retry made. Disk ~21 GiB free, memory_pressure 38% free.

Source inspection: reflected paths allow 16 bounces, each 256 view steps; each
view sample performs two light_depth marches capped at 512 steps. The primary
path has another 256 view steps. Thus the loop-cap upper bound alone permits
17*256*2*512 = 4,456,448 light-march iterations per fragment, before additional
distance/density work. This is a theoretical bound, not measured GPU work.
Remaining throughput below 0.0001 stops later bounces; lower extinction may keep
more bounces alive. It is a plausible workload risk, NOT established timeout
causality: current log does not identify which capture variant was drawing.

This evidence argues for reducing nested transport cost with measured error bounds
before pursuing more transparent profiles, not simply lowering output resolution
or accepting fewer physical effects. A cached directional optical-depth approach
would need current-time density updates and comparison to direct integration;
the previous static fill cache is neither that solution nor motion-compatible.
FW remains unaccepted, no production promotion, all prior assets preserved.

### Directional-cache feasibility — error before GPU integration

Added check_directional_cache.py, a CPU FV soft-density experiment at t=0 and 2,
both analytic light directions, FJ 128 SDF. Evaluates 2,000 seeded held-out interior
points against the existing 512/.002/.03 direct march. Records source/payload hashes,
depth error and transmission error for current and FW half-extinction spectra.
No GPU cache or production change made. Optimization skill guided measured tradeoffs;
CPU timings and loop bounds are not substitutes for a native GPU profile.

32-cubed current-time cache depth MAE ~0.0075..0.0114; 64-cubed improves to
~0.00284..0.00489 but maximum remains 0.320..0.421. Naive interpolation is rejected:
small averages conceal severe local errors, including near geometric discontinuities.
Using t=0 cache at t=2 increases 64-cubed MAE to ~0.0217/0.0295; a static cache is
not an acceptable replacement for requested flowing density.

Hybrid experiment uses cache only when all eight corner nodes are inside and their
optical-depth spread <=0.03; otherwise uses direct reference as hypothetical fallback.
Current-time max error falls to 0.00239..0.00541, MAE ~0.000090..0.000130, but only
21.35..26.25 percent of sampled points use cache. Stale hybrid maximum remains
0.121..0.133. This is a heuristic experiment, not a proven bound or actual speedup;
most sampled points still require expensive direct work. Do not integrate as a
claimed timeout fix. Consider a direction-aligned representation and boundary-aware
sampling, with current-time updates and error validation, before GPU implementation.

Reports directional-cache-32.json, directional-cache-64.json and
directional-cache-64-hybrid.json are preserved. All numerical runs complete with
no unfinished rays. No native rerun, visual lock, animation acceptance or production
promotion this turn. Character fidelity remains the final goal, not cache accuracy.

### Direction-aligned cache — reject same-count rotated grid

Extended CPU feasibility tool with opt-in --aligned. Cache z aligns with each
light ray; an orthonormal basis transforms the original SDF bounding-box corners
to cache bounds. Distance and density evaluations remain in subject coordinates.
Records physical spacing; same 64-cubed node count does not mean same spacing.

All rays complete. Current-time naive maximum depth errors remain 0.305..0.629.
The existing conservative all-inside/corner-spread hybrid accepts only 0.8..1.25%
of held-out points, versus 21..26% for axis-aligned cache. Rotated bounding volume
has coarser physical spacing; corner-spread also includes legitimate directional
depth gradients. These confounds mean this test rejects this concrete same-count
configuration, not every possible direction-aligned representation. Tiny hybrid
average error primarily reflects >98% direct fallback, not an effective speedup.

Default-grid regression rerun exactly matches all six previous result groups for
depth errors, transmission errors and hybrid statistics. Preserve aligned and
regression JSON reports. No GPU run or image-quality promotion. Optimization skill
guided error/coverage accounting instead of treating averages as sufficient proof.

Stop extending this uniform-grid cache branch without a stronger cost/accuracy
case. Next obtain per-capture workload attribution and a bounded native profile
of the established baseline; current timeout logs lack variant attribution, so
further cache development alone risks optimizing an unverified cause. Model
translucency, visible flow and reference surface fidelity remain unresolved.

### FX stage attribution / FW instrumented failure

Added opt-in capture_stage_timing to the shared harness. Logs angle/variant before
settle, readback and save/validation, and records wall durations per completed image.
Default is false. These synchronization-inclusive timings are NOT isolated GPU
timestamps or gameplay FPS. Optimization skill guided attribution before more changes.

FX inherits FV baseline unchanged, guarded run clean in 23.61 seconds. Nine captures
record settle 1.399..2.266 seconds (four post-draw waits), readback 0.454..0.745
seconds and save/decode-validation 0.044..0.062 seconds. Saving is a small share
of this observed capture path; waiting/render synchronization dominates wall time.

FW instrumented rerun is justified by new attribution, not an unchanged blind retry.
Same half-coefficient profile and 1024 resolution, unique output. Guard stops at
14.96 seconds on Metal timeout, child -15. Log completes front before/after/repeat
and 40-before; last marker is angle=40 variant=1 phase=settle. Error occurs in
force_draw before that image's readback/save. Front after readback was 0.918s,
settle 2.760s. This localizes failure to rendering/waiting for the lower-extinction
40-degree view, not its PNG write. It does not prove which shader loop or driver
condition causes it, and front partial artifacts are not a passed visual run.

Preserve capture-profile-fx/, its guard log, optical-depth-fw-profile/ partial
artifacts and guard log. No further retry. Next isolate internal-bounce workload
at this specific view with clearly labeled diagnostics and residual-energy checks;
do not turn off bounces permanently as a presumed quality fix. Production and
all earlier versions remain unchanged, reference fidelity still unaccepted.

### FY — bounded internal-reflection diagnosis at failing view

Added default-preserving capture_angles export ([0,40,90]); FY selects only 40.
Both subjects use FW half coefficients with FV flow, comparing bounce caps 2 and 4.
Separate residual scene enables existing debug_residual on both. Shader skill
guided isolated controls and residual inspection rather than accepting truncation.
Guarded beauty and residual runs both complete cleanly (~9.00/8.23 seconds).

Beauty before/repeat delta zero; 2->4 foreground mean absolute channel difference
0.215/255 but maximum 52/255. Four-bounce settle/readback wall time 2.489/0.809s
versus two-bounce 1.557/0.518s (repeat 1.402/0.452s), including synchronization,
not isolated GPU duration. Reduced-cap completion supports bounce-work sensitivity,
not proof of the full-cap timeout's root cause or acceptable quality.

Viewed four-bounce residual: visible gray remaining throughput at limbs/silhouette.
Tone-mapped display and unchanged eyes prevent treating raw pixel values as numeric
energy bounds. No blanket residual acceptance. Viewed beauty retains plastic-like
core and renewed lower bright band despite soft flow. Lower extinction alone is
not the reference-match solution. Preserve bounce-budget-fy/ and residual outputs,
their guard logs, all versions. Do not promote 2/4 caps as a production fix.

Next optimize per-path lighting evaluation while retaining reflected transport;
validate spatially localized error rather than only whole-image averages. Also
revisit the surface/core balance: greater transmission has not restored the
reference's fine texture and volumetric depth. Overall goal remains unachieved.

### FZ / GA — local reflected-light reuse, full-cap failure

Default-false reuse_reflected_lighting reuses key/back incident lighting for at
most one adjacent reflected-ray sample, distance <=0.02 and current SDF <=-0.005.
Cache resets every bounce. Density, attenuation, path stepping, Fresnel and exit
transport remain per-sample. This is a lighting approximation, not an exact bound.
Shader skill guided separate controls and image-error comparison.

FZ uses FW half coefficients, 40 degrees, cap four on both copies. Guarded run
clean in 12.11s. Foreground mean absolute channel delta 0.00375/255, max 1/255,
p99 zero; before/repeat delta zero. Viewed after retains plastic core and bright
band, so this is not a quality improvement in itself. Warm baseline repeat settle/
readback 2.232/0.736s versus reuse 2.026/0.658s; first baseline settle 4.066s.
Timing variation/warmup prevents asserting a proven speedup from this single run.

GA keeps reuse on both sides and compares caps 4/16 at the same view, restoring
the full existing reflection budget after. Guard stops on Metal fence timeout,
6.44s, child -15, marker absent. No retry or partial-image acceptance. The small
local reuse optimization is insufficient to establish full-cap viability; it must
not be sold as the timeout fix. Preserve FZ complete outputs and GA failed artifacts
and guard logs. Production unchanged; full-reference and motion acceptance pending.

### GB — fine surface profile, reference comparison rejects visual lock

Returns to FV's original optical coefficients and full reflection budget, not the
failed lower-extinction branch. GB doubles cell scale 35->70, halves height depth
0.003->0.0015, and increases outer normal detail 0.15->0.6. This is a combined
surface art-direction profile, not a single-variable causal test. Soft FV density,
geometry, studio, tone response and facial masks remain. Shader skill guided
separate material settings rather than editing existing production assets.

Guarded three-angle run completes cleanly in 25.83 seconds. Viewed front alongside
the original CHAR-BASE-T-3d-alt reference. Smaller highlight cells are visible, but
surface reads as orange peel and four vertical white reflection patches remain
dominant. Reference has richer interior shading, substantial eye/pore integration
and golden peripheral transmission. Finer noise alone does not close that gap;
GB is not promoted. This independent surface work does not abandon the unresolved
low-extinction rendering/motion problem.

Read current studio include: two front softboxes at intensities 16 and 8, narrow
widths 0.24/0.16 and tall extents 0.60/0.55, plus back source 4. Next test a broader,
less dominant front reflection profile with consistent reflected/transmitted
environment, while evaluating body depth rather than only noise size. Preserve
fine-skin-gb/ and guard evidence, all earlier versions and production assets.

### GC — broaden studio, reject unstable sky comparison

GC compares GB on both sides with broad front softboxes after: intensity 5/2.5
and widths 0.50/0.40, versus 16/8 and 0.24/0.16. Back environment unchanged.
Both sky reflection and custom transmitted environment use the same profile;
fixed analytic volume lights remain unchanged. This is not energy-matched lighting.

First guarded run clean in 29.48s but before/repeat channel deltas 0/84/19 at
0/40/90 degrees. Reject visual conclusions despite process success. Official Sky
documentation confirms custom uniforms make automatic sky processing incremental:
https://docs.godotengine.org/en/stable/classes/class_sky.html
R2 forces quality mode for this static comparison, but guard stops on Metal fence
timeout in first front-before settle, 1.95s, child -15. No further native retry.

Initial shared include uniform would also change legacy sky auto-mode selection.
Corrected isolation: shared function now takes explicit profile bool; legacy
ei_studio wrapper passes false without uniforms. Only volume shader and separate
gel_studio_gc sky declare the new uniform; GC selects that test sky. This final
isolation edit has NOT yet been native-render validated. Prior captures reflect
the pre-isolation implementation; don't conflate them with current source output.

Preserve GC failed-comparison artifacts, R2 timeout artifacts and logs. Shader skill
guided consistent environment inputs and default-profile isolation. Next prebuild
separate sky resources per profile before measured capture rather than repeatedly
rebuilding radiance mid-comparison; verify repeats and legacy output. No production
promotion, reference match or motion acceptance. Broader-light hypothesis unproven.

### GD — independent skies and hidden-subject sky preparation

GD holds separate static Sky resources for legacy/broad profiles, uses explicit
incremental processing, records roughness_layers, and avoids mutating sky materials
between captures. First run with ten visible settle frames hits Metal timeout at
40-before settle after completed front triplet; guard stops at 27.69s, child -15.
This happens on legacy profile too. Disk ~20 GiB, memory_pressure 42% free. Preserve
failed artifacts; do not claim the new studio alone causes the fault.

R2 changes workflow: optional sky_preparation_frames (default zero) hides both
subjects for ten post-draw waits after sky selection, then restores intended subject
and waits four visible frames. Sky preparation no longer repeatedly renders the
expensive body. Material, resolution, full reflection budget and light integration
are unchanged. Guarded run clean in 27.45s; before/repeat pixel deltas zero for all
three angles. This validates this bounded comparison, not general timeout resolution
or long-animation performance. Shader skill guided independent material/resources.

Viewed broad-profile front: highlights are broader/less white but orange-peel texture
and flat/plastic core remain. Foreground mean display luminance -0.89/-1.55/-0.38%
at front/40/90, std/mean decreases; not a reference-quality score. No visual lock.
Keep separate-studios-gd-r2/ as a stable lighting control. Shared profile-function
and isolated sky code now have native coverage; no assertion of complete legacy
pixel equivalence across all previous scenes. Production assets remain unchanged.

Next address body scattering/depth and light placement (not merely broader boxes),
using this stable comparison workflow; full lower-extinction transport and visible
motion remain unresolved. All previous versions and failed outputs preserved.

### GE — internal key/back balance

Exposed volume_key_gain/back_gain with original defaults 4/3.5, used consistently
in primary and reflected scattering. GE keeps GD broad sky on both sides and all
geometry, optical coefficients and FV flow unchanged; after changes gains to 1/6.
This changes analytic incident lights, not the reflected studio radiance. It is
an art-directed lighting balance, not a single physically unified studio solution.

Guarded run clean in 28.81s, all before/repeat deltas zero. Viewed front: stronger
red center versus orange perimeter, but too dark/red and still plastic-like.
Mean display luminance changes -22.77/-17.04/+2.88 percent at 0/40/90. Reject
claim that darkening alone delivers reference depth. Shader skill guided consistent
coefficient controls while retaining prior profiles.

Prepared milder GE R2 (2.5/5) with exported candidate controls, but guarded attempt
hits Metal timeout, 1.98s, child -15, no completion marker. No retry or beauty
acceptance; investigate the earliest logged stage before another attempt. Preserve
GE complete and R2 failed outputs plus logs. Production unchanged, all versions kept.
Remaining surface/core and stable-render problems are not resolved by this test.

### GF — renderer isolation, not a stability fix

Godot debugging systematic-method skill guided evidence collection before another
material change. Existing benchmark PID 61332 is stopped (state T), CPU 0.0%,
elapsed 08:43:39 at inspection. It was not killed, resumed or modified. Its presence
does not establish GPU contention. Disk remains approximately 20 GiB available.

Added independent gel_backend_isolation_gf.tscn inheriting GE R2 with only a new
output directory. Ran pinned 4.7.2 with explicit Vulkan, Forward+, 1024x1024 and
the same full material/capture settings. Actual startup reports Vulkan 1.2.334,
Apple M4 Pro. Guard clean_process in 48.732s, child zero, completion marker seen.
Three-angle before/repeat maximum channel differences all zero. Outputs and guard
logs live under backend-isolation-gf-vulkan/ and its -guard sibling.

This is one successful alternate-backend run after an intermittent Metal failure,
not proof of a Metal engine defect or a reliable production workaround. Startup,
compilation, capture and synchronization are included in elapsed time: no FPS or
GPU frame-time claim. Production renderer settings remain untouched.

Viewed front after: intact orange character but broad pale reflections, fine
orange-peel relief and flat/plastic body remain; no reference acceptance. Candidate
foreground display luminance versus control changes -10.69/-7.37/+3.56 percent at
0/40/90; these are diagnostic measurements, not quality scores. No motion test.

Next: bounded matched-backend profiling with logged GPU tasks to separate expensive
volume transport from backend behavior, then design a real-time body-depth/flow
solution against the reference. Do not expand beauty variants or promote this
offline shader based on one completed capture. All previous versions preserved.

### GG — measured GPU cost and Vulkan hang invalidate backend workaround

Previous GF turn classified as progress: alternate-backend evidence, not a fix.
Optimization skill directs profiling before optimization. Added independent GG
scene inheriting GF unchanged except fresh output directory. Pinned 4.7.2 CLI
help confirms --gpu-profile; ran same Vulkan Forward+ 1024x1024 capture with this
flag under capture_guard. No production settings changed.

Guard stopped at 13.305s, render_error, child -15, no completion marker. At
40-before readback MoltenVK reports VK_TIMEOUT and MTLCommandBuffer GPU Hang,
followed by lost VkDevice and fence wait failure. No retry. Partial outputs and
logs preserved in gpu-profile-gg-vulkan/ and gpu-profile-gg-vulkan-guard/.
This establishes that failure is not exclusive to native Metal. Vulkan on this
machine also uses Metal underneath; it is not independent hardware validation.

Pre-failure CLI GPU profile includes a total of 630.041ms and opaque pass
629.212ms. Other profile blocks mix hidden-subject sky preparation and visible
capture intervals, so do not treat them as an unbiased steady-state FPS sample
or average all blocks. Even the observed heavy opaque sample is far outside an
entire 60Hz frame budget (16.667ms). Exact per-shader attribution still requires
a body-material ablation; this is pass-level evidence, not proof of hardware
failure or the exact cause of device loss. Do not call this run accepted.

Re-viewed original reference: golden transmitting edges, interior orange/red
depth, substantial integrated eye/pore rims and irregular wet facets remain the
target. GF still looks flat/plastic. Expensive transport has not bought reference
fidelity; switching backends or lowering frame count is not a solution.

Next controlled diagnostic: same geometry/camera/sky with body material isolated
to confirm opaque cost. Then replace nested per-pixel light marches with a
bounded real-time representation, validating dynamic density and transmission
against reference and full transport controls. Do not promote truncated-bounce
or stale-light-cache approximations previously rejected. One-character and
multi-character GPU budgets, visible idle/movement flow, integrity and reference
acceptance all remain open. Preserve all versions.

### GH — body-material ablation localizes dominant cost

Previous GG turn is progress: observed GPU pass cost and alternate-backend hang
changed the next action. Optimization skill guides an ablation before redesign.
GH inherits GF/GE R2 geometry, cameras, broad sky, lighting and resolution. After
normal preparation it replaces only Part00 material on both subjects with opaque
StandardMaterial3D (orange, roughness .12, specular .3, clearcoat .25/.15). Other
parts remain unchanged. Static settle count increased from 4 to 120 for profile
sampling; this is not an identical timing workload or a beauty candidate.

Pinned Vulkan Forward+ --gpu-profile run clean in 3.955s. Three-angle before/after
display measurements identical and before/repeat pixel deltas zero. GPU CLI block
reports total .464ms, opaque .325431ms. Visible warm 120-frame settle intervals
~55–63ms, readbacks ~.8–1.3ms; those latter numbers are wall time, not GPU timings.
Prior GG opaque samples were hundreds of milliseconds. Sampling windows differ,
so do not claim an exact speedup ratio or steady gameplay FPS. Nonetheless this
strongly localizes dominant diagnostic cost to the custom body material rather
than this geometry/sky alone. It does not isolate which shader loop dominates,
prove the precise GPU-hang mechanism, or validate the actual production gameplay.

Viewed front confirms intentionally opaque/plastic control, not desired jelly.
Do not promote GH or equate cheap standard shading with reference fidelity.
Artifacts: body-ablation-gh-vulkan/ and body-ablation-gh-vulkan-guard/. Independent
GH script/scene added; production models/settings and all prior versions kept.

Next: replace nested light integration in an independent candidate while keeping
body depth, moving interior structure, golden transmission and irregular wet skin
as explicit visual requirements. Validate approximation against full transport
controls and reference, not just against this cheap ablation. Avoid mesh reduction
as the primary response to the measured material bottleneck.

### GI — live quadrature feasibility rejects a misleading loop-budget shortcut

GH was progress: body material ablation localized dominant cost. Shader skill
informs separating geometric first exit from current-time density integration;
no GPU shader or production asset modified this turn. Added independent CPU
check_light_quadrature_gi.py. It verifies SDF payload hash, tests 2,000 seeded
interior points, two lights and times 0/2/5. Sphere tracing with .7 safety, .00005
minimum and .15 maximum is checked against .002 maximum tracing, then both get
12 bisections. Gauss-Legendre 8/16/32/64 integrates live FV density on the chord.
Reference compares 256/512 orders on fine-traced chords. No stale-time cache.

Reports light-quadrature-gi.json and -gi-r2.json preserved. R2 adds actual legacy
march counts; initial report does not contain those fields. First-exit difference
<=1.197e-8 on sampled points, reference order difference <=3.871e-6 depth.
Order 8/16/32/64 maximum RGB transmission differences across these cases are
.006757/.001170/.000186/.000069. These are finite sampled checks, not global bounds,
final radiance errors, deformed geometry validation or GPU timings.

Critical result: original 512-budget marcher actually averages 14.368/15.698
density evaluations for these two ray sets (14–16, not 512). It averages about
29.736/32.395 SDF fetches. New exit+quadrature costs ~36–38 SDF fetches even at
order 8; order 16 costs ~44–46 and does not reduce density evaluations on average.
The 12-step bisection overhead is included. GPU branch/cache/trigonometric costs
remain unmeasured, but there is no evidence for the needed large speedup.
Reject immediate GPU integration as an optimization; no native render retry.

Next investigate sharing current-time light integration across view samples or
pixels rather than another per-fragment integral substitution. Prior naive/stale
directional caches failed near boundaries, so a shared representation must resolve
first-exit boundaries and current moving density and demonstrate lower cost plus
bounded observed transmission error before adoption. Reference wetness/depth,
visible flow, viscous movement and production GPU stability remain unaccepted.

### GJ — re-anchor development to visible reference discrepancies

GI is progress: actual sample counts rejected an unjustified optimization path.
This checkpoint reopens the original CHAR-BASE-T-3d-alt.png and GF 00-after.png,
not the opaque GH control. These are a concept and an unpromoted diagnostic,
NOT a new live-game comparison. Current shipping GLB hash was rechecked as
3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3.
Updated top-level handoff beyond its older W checkpoint without removing history.

| Requirement | Current visual evidence | Acceptance work, not a pass claim |
| --- | --- | --- |
| Wet irregular surface | GF has small orange-peel cells and four broad pale front patches; reference has broken lateral highlights | Match light placement and facet scale together; inspect front and 40-degree without sacrificing depth |
| Jelly interior | GF center comparatively flat, thin edges insufficiently golden; reference has orange/red interior and luminous golden periphery | Validate body-depth representation plus lighting, not just brightness or an opaque tint |
| Integrated facial cavities | GF eye borders are thin; reference has substantial wet orange rims and a thicker pore lip | Inspect normalized face close-ups and geometric cross-sections; avoid detached lenses or a painted ring |
| Silhouette/stance | Reference reads taller with broader flowing feet; images have different framing and uncertain camera equivalence | Match framing before estimating geometry changes; do not arbitrarily stretch all parts from unregistered images |
| Visible internal movement | A still cannot verify this; earlier short FV sequence had extremely subtle differences | Continuous idle and movement clips, same appearance and readable internal motion, no detached particles |
| Runtime stability | Full diagnostic material has GPU hangs; cheap ablation is fast but visually wrong | New liquid solution must satisfy appearance AND measured native budgets; no backend-only promotion |

Priority: stop treating CPU quadrature experiments as visual progress. First
establish a matched-framing review baseline and shape/face discrepancies while
designing shared live lighting; then test appearance and cost together in an
independent candidate. The static concept does not specify side/back anatomy or
animation and must not be presented as evidence for those. Full goal stays open;
no reference lock, 14-animation reacceptance, shipping replacement or release claim.

### GK — scale-normalized silhouette evidence

GJ changed the authoritative handoff and priorities but did not improve the model.
GK adds measure_reference_silhouette_gk.py, a read-only numeric image measurement,
not image editing. It hashes original reference/GF inputs and writes exclusive
reference-silhouette-gk.json. Orange foreground bounding boxes normalize row
positions and widths by subject height; five neighboring rows reduce single-row
noise. Three red thresholds (20/40/60) probe mask sensitivity. This removes
uniform image scale ONLY; perspective, pose, lens and lighting are not registered.

At thresholds 40/60, candidate width/height 1.062 versus reference 1.012. Near
10% height widths agree within ~0.5%; at 40% candidate is ~6.7–6.8% wider, at
55% ~10.8–10.9% wider, and at 85% ~11.5–11.7% narrower. These mid-body signs
remain at threshold 20. The 95% band is grossly threshold-sensitive because
the reference's faint orange lower extent changes the normalized row. Reject
that band for shape decisions. Color masks also exclude some white highlights.

This supports testing localized shoulder/arm contour reduction and broader
foot spread rather than uniformly stretching/squeezing the entire model. It does
not establish exact deformation factors: camera/pose control is still required.
No source PNG, production model or shader was changed. Next use the existing cheap
clay/material control to inspect camera/pose and local silhouettes before spending
another full optical render. Reference facial depth, liquid material, continuous
movement and stable native rendering remain open alongside this shape work.

### GL — perspective control does not remove contour mismatch

Camera skill guided an independent cheap-material camera control, preserving
geometry/pose and viewing direction. Compare FOV32 against FOV16 with distance
scaled by tan(16deg)/tan(8deg); same target-plane framing, not reference-camera
reconstruction. Production camera unchanged. First GL run completed but repeat
pixel delta 254 exposed a test bug: harness resets position per angle, not per
variant. Rejected that comparison; diagnosed accumulated distance and rebuilt
offset from fixed capture_distance/height and horizontal direction. No blind retry.

GL R2 completes cleanly in 2.050s. Repeat max deltas 0/1/0 at 0/40/90; the tiny
40-degree difference remains (normalized direction arithmetic is not bit-exact).
Do not report exact repeat equality. At threshold40, front silhouette width/height
changes 1.0642 -> 1.0790 with longer lens. At normalized height .55 width/height
changes 1.0169 -> 1.0275; at .85 .8057 -> .8024. Reference corresponding values
are ~.9119/.9119. This particular reduction in perspective slightly worsens rather
than resolves middle width and lower-foot spread. It does not exclude all camera
elevations/poses, but rejects 'just use a longer lens' as the fix.

Keep camera-control-gl/ failed-comparison outputs, -gl-r2/ and both guards.
No mesh, optical settings or shipping version changed. Next localized contour
candidate should preserve head and facial positions, reduce middle shoulder/arm
width and spread the lower feet, then verify intact geometry before optical work.

### GM — first localized contour candidate, not promoted

Assets skill guided separate generated .res meshes and JSON archive, leaving GLB
and old resources untouched. GM extends cheap GH control, changes only variant1
by x'=x*s(y), s in [.92,1.14], smooth middle reduction and lower-foot expansion.
All parts use the same continuous map; y/z and indices preserved. Normals use
inverse-transpose Jacobian, tangents forward Jacobian (slope numerical derivative).
This is rest geometry only; existing SDF is invalid for the altered body and was
NOT used to shade the new mesh. No rig/animation integration.

GM clean2.207s; viewed front has broader feet and reduced middle, but lower arms
look pointed/pinched. Reject final visual lock. GM R2 clean2.037s adds early skip
for y>=.72 to avoid renormalizing unchanged upper attributes. Despite this,
recreated ArrayMesh eye tangent deltas remain ~5.6–5.8e-5 versus control, no
handedness changes. Therefore do NOT claim bit-identical upper attributes; mesh
repacking is a hypothesis, not established here. Upper positions stay unchanged.

Both archives pass existing numerical checker: body56118 vertices/112232 triangles,
zero degenerate triangles below1e-12, zero welded boundary/nonmanifold edges.
Eyes also closed; pore32/mouth64 boundary edges remain intentional. This does not
prove no self-intersections or deformation safety through animations.

R2 front normalized width at .55 height is .9662 (control1.0169, reference~.9119),
at .85 height .8986 (control.8057, reference~.9119). Feet-band match improves,
middle remains too broad, top unchanged. Overall width/height .9983 versus
reference~1.012, but scalar match cannot outweigh pinched arm contour. Source,
captures, per-part resources, guard logs and geometry reports preserved under
contour-gm/ and contour-gm-r2/. Next refine arm-local falloff independently from
feet and preserve wholly unchanged mesh resources instead of repacking them.

### GN — smoother lower arms and exact eye-resource preservation

GM was progress: independent contour candidate and integrity evidence, not final
acceptance. Assets skill guided reuse of unchanged resources. New GN overrides
the y scale with .92 below the upper transition and a .22 foot contribution
below .28, retaining maximum foot scale1.14. This removes GM's lower-arm outward
flare while leaving y>=.72 untouched. Shared GM exporter gains opt-in
preserve_unchanged_meshes (default false preserves earlier behavior); GN enables
it. Parts01/02/03 retain their original Mesh resources; only body/mouth rebuilt.

First attempt stopped on GDScript 'Cannot infer type of unchanged', before any
capture. Erroneously dispatched follow-on artifact reads found missing files;
no validation resulted. Diagnosed parse error, explicitly typed bool, then ran
with a new -parsefix-guard directory. Clean2.211s, all angles captured. Downstream
checks were run only after confirmed terminal success on this corrected attempt.
Eye tangent delta exactly0 for both eyes, handedness changes0. Numerical archive
checks: body/eyes closed after weld, no degenerates/nonmanifold edges, intentional
pore/mouth boundaries unchanged. Not a global self-intersection or animation test.

Viewed front: lower arms rounded again compared with GM pointed tips; expanded
feet retained. Shoulder transition still reads blocky/solid under opaque control,
and no liquid shading or motion acceptance. GN is an additive rest-shape candidate,
not shipping replacement. Preserve arm-transition-gn/ meshes, archive, captures,
geometry report and both failed/corrected guard logs. Existing old-body SDF cannot
be applied to this altered shape. Next inspect side/40-degree contours and facial
integration before rebuilding mesh-dependent optical assets or rigging changes.

### GO — multi-angle GN review and direct preservation checks

GN was progress: revised arms and unchanged eye resources. Opened its existing
40/90-after captures this turn; no native rerun. Oblique/side views reveal thick
arm depth and hard shoulder transitions despite improved front tips/feet. Do not
call three captured angles three accepted angles. Reference supplies no true side
view, so side criticism is continuity/art direction, not an exact reference match.

Added check_contour_preservation.py with explicit source-to-candidate part mapping,
finite/topology/YZ/upper-region/protected-face checks and original-versus-new face
normal direction checks. Run against FJ R2 -> GN saved preservation-check.json.
Source hash e0ff2d99ee84c720127fa7b3ebc51cf7d0896593fb66f9535e1fec9e0db764b8;
candidate hash 6f1f003e9eac65679e99008c5d17306c9a18104120a2e621c0fdc4bbd552601a.
32,005 upper body vertices unchanged. Both eyes and pore all positions unchanged;
all parts' YZ/index arrays unchanged. Maximum body displacement .088093, mouth
.001443. Minimum corresponding body face-normal cosine .775394; no >=90-degree
turn in sampled triangles. This is NOT self-intersection, tangent, rig or motion
acceptance, and does not validate the altered geometry's liquid optics.

Next contour change should address arm depth/shoulder blending locally, preserve
eyes/pore and broadened feet, and inspect oblique view before optics. Do not keep
tuning only front width or claim body-integrity checks imply visual approval.
All previous assets retained; production unchanged. Full goal remains open.

### GP — local arm-depth candidate

GO provided multi-angle evidence and preservation checks. Assets skill guided
independent GP script/scene/resources. GN width/feet retained; GP scales z by
1-.20*lateral*arm, lateral smoothstep(.42,.66,abs(x)), vertical support .26–.72.
Default shared depth hook returns1 for earlier profiles. Normals use inverse
transpose of combined x/y-dependent warp; tangents use its forward Jacobian.
Old GLB, resources and SDF unchanged; altered body is still opaque diagnostic only.

Guard clean2.436s, three angles captured. Compared GN to GP archives directly:
XY exactly unchanged all parts, upper/foot/central protected positions unchanged
(48,364 body vertices in checked protected union); maximum body Z change .050922.
Eyes/pore/mouth positions unchanged versus GN. Existing rest checker again finds
closed body/eyes, no degenerate or nonmanifold triangles; intentional facial
aperture boundaries remain. This does not prove self-intersection or rig safety.

Viewed 40-degree after: arm is thinner but hard shoulder/upper-arm transition still
visible. Side is inspected separately; depth reduction alone is not reference
acceptance. Keep arm-depth-gp/ capture/archive/resources/geometry report and guard.
No liquid render, motion validation or promotion. Next must soften attachment
shape without creating a narrow neck or losing the single connected body; do not
mistake lower arm thickness for a complete anatomy or material solution.

### GQ — localized shoulder smoothing crosses obsolete height-only lock

GP was progress but thickness alone left hard attachment. Read GP vertex bands:
outer shoulder remains above y=.72 (max|x| .651 at .85, .574 at .95), so blanket
upper lock prevented editing relevant shoulder geometry. New localized mask uses
|x| .44–.60, lower fade y .40–.62, upper fade .88–1.06. Central facial region,
feet and other parts remain pinned; this intentionally supersedes the arbitrary
all-y>=.72 restriction, not user-required face preservation.

Assets skill guided separate shoulder-smooth-gq/ archive. Numeric script applies
100 weighted Laplacian steps .35 on unique graph adjacency. 48,503 body vertices
pinned, max displacement .030060, minimum corresponding face cosine .948936.
Not volume preserving. Existing checker finds no degenerate triangles, no welded
body boundary/nonmanifold edges; eyes/pore/mouth unchanged from GP. Not a global
self-intersection or animation test.

Independent renderer uses GP resources for control, GQ positions for after body,
recomputes changed-vertex area-weighted normals and reprojects tangents. Eyes and
other parts retain GP resources. Guard clean2.573s with all angles captured.
Viewed 40-after: shoulder highlight transition is more continuous and protruding
hard region reduced. This is a plausible local improvement, not final reference
acceptance. Front/side and motion still require review. Original optical SDF is
invalid for new shape; no optical rendering or shipping promotion occurred.
Preserve numeric archive/report, shoulder-smooth-gq-render/ and guard plus all
previous variants. Next check volume loss and full silhouettes before selecting
this shape for liquid material redevelopment.

### GR — GQ volume and remaining views

GQ was progress: actual localized mesh smoothing and oblique improvement. This
turn opens existing GQ front and side after captures; no new render. Front retains
expanded feet and face placement, side attachment looks smoother than GP, but
opaque red control still cannot establish jelly depth, surface or moving anatomy.

Direct body tetrahedral sums (absolute values, consistent archived winding):
FJ R2 1.045241381, GP 1.020348137, GQ 1.015547911. GQ smoothing loses ~0.47045%
relative to GP; combined shape changes lose ~2.84083% relative to FJ. GP area
6.453875183 -> GQ6.415384214. These are rest-mesh measurements, not simulated
liquid mass conservation or a guarantee that local thickness is preserved.

Extended existing check_face_archive.py with surface_area and signed volume for
edge-closed meshes; open pore/mouth volume is null. Negative volume here reflects
triangle winding, not negative physical volume. Scope explicitly warns edge closure
alone does not establish consistent winding or no self-intersections. Saved new
GQ geometry-volume-check.json; earlier reports preserved unchanged.

GQ can remain a local rest-shape candidate, with measured modest smoothing shrinkage,
not an accepted final character. Next test deformation compatibility on this shape
and develop matching low-cost liquid shading; do not reuse the original SDF blindly
or keep refining isolated shape numbers instead of the reference appearance.
No production asset replacement, new optical render or animation pass this turn.

### GS — existing animation generator compatibility, narrow scope

GR was progress: rest volume evidence and reusable reporting. Animation skill
guided reuse of existing animation generation instead of inventing a separate rig.
Graph search again reports project unindexed; scoped source inspection confirms
gel_anim.gd is skeleton-free node-transform animation, and CharacterRoot drives
wet/shell/eye shader body-space lag/squash/turn/contact/wobble uniforms. Runtime
material discovery recognizes specific shader resource suffixes; our diagnostic
materials are not automatically connected. New static archives have not been
promoted into that pipeline.

Added gel_rest_motion_gs.gd. Headless pinned4.7.2 with IMMUNE_GEL_LOOK=v8_6 loads
GQ body and retained GP facial parts under identity-host CoreMesh. Existing
GelAnim.build_library generates all14 names. It samples only the three CoreMesh
value tracks at37 times per clip (518 samples), skips method events, checks finite
transforms/positive determinant, and saves rest-motion-gs.json. Run exit0 with
no script errors; minimum sampled determinant ~.97763. This proves neither
shader deformation nor final animation appearance, hit events, attachments,
collision, full CharacterRoot initialization or shipping compatibility.

Identity-host pivot clamps to .15. Transformed aggregate AABBs include negative
Y (idle~-.0157, skill_cast~-.2237). Rotated AABBs are conservative and test lacks
production placement; do NOT declare actual ground penetration from these bounds.
Next measure actual transformed vertices under correct production placement,
then test the same shader-driven material/attachment deformation. No rig binding
is required by this architecture, but correct shared body-space materials are.
No game model replacement or 14-animation acceptance claim. Old assets preserved.

### GT — actual vertex contact, old-shape control

GS was progress: existing animation generator coverage exposed possible contact
issues. Read character.tscn and CharacterRoot defaults: CoreMesh and imported
model have zero offset/unit scale. The scene's y=.51 belongs to CollisionShape3D,
not the visual model. Added optional actual-vertex measurement and per-part paths
to GS plus GT and GT-control scripts; preserved earlier outputs. Pinned headless
v8_6 runs finish exit0, no script errors, 14 clips x37 samples each.

Actual rest vertices transformed by node tracks reach below visual-origin Y0:
GQ idle-.011775, move-.016150, skill_cast-.128221. Old FJ control also reaches
idle-.011501, move-.015393, skill_cast-.122491. Largest candidate-control worsening
among clip minima is hit~-.007482; start/stop identical. Thus most of this effect
exists in the node animation applied to either shape, not solely the new feet.
Not a completed gameplay ground-collision diagnosis: shader displacement, root
world placement and actual stage floor remain outside this test.

Saved vertex-ground-gt.json and -gt-control.json. The latter's inherited scope text
says GQ but its body_resource explicitly identifies FJ mesh-00.res; corrected
future source wording to 'selected rest mesh'. Existing reports remain preserved.
Next integrate full CharacterRoot/body-space deformation into the contact check
and use dynamic support correction if actual rendered penetration persists, not
a permanent whole-character height offset. No production changes or animation
acceptance. All old versions retained.

### GU — real CharacterRoot candidate adapter and uniform coherence

GT was progress: actual vertex contact and old-shape control. Animation skill
guides reuse of CharacterRoot.rebuild_gel_anims/update_liquid_flow. Added independent
gel_runtime_candidate_gu.gd adapter: instantiate actual T scene, replace only its
test-instance Body/BodyShell and four facial meshes with GQ/GP resources, reset
baked facial transforms to identity, retain existing wet/shell/eye materials,
remove redundant test-instance ForeheadPoreRim, and recache body-space materials.
BodyShell keeps1.006 scale. Removed exact shipping-sculpt marker on altered body;
marked candidate. No production selection or original asset changes.

First headless run assertion compared sent shader lag with exact runtime lag and
left test process alive. Inspected line69 and existing CharacterRoot coalescing
threshold (.000002 squared lag distance), terminated own confirmed PID88933, then
corrected test: all six materials must share body sent lag, and internal-to-sent
delta must remain within documented threshold. Corrected run exit0, no script
errors. Delta .00004454, all body/shell/eyes/pore/mouth lag(-.124039,0,0), motion
mix .9988213, shared body-space enabled1. Material inventory1 wet/1 shell/4 face;
rebuilt inventory14 named animations. Saved runtime-candidate-gu.json.

This is real CharacterRoot initialization/wiring with120 manually supplied velocity
updates, NOT real physics movement, GPU deformation, rendered material quality,
contact, gameplay events or 14-animation acceptance. Existing shipping materials
are a compatibility baseline, not the desired new jelly finish. The headless
test currently relies on assertions for some setup checks; future automated native
driver must guard errors/timeouts rather than leave assertion-stopped processes.
Next render this isolated adapter with existing material/animation path, inspect
face/body synchronization and contact before claiming integration complete.

### GV — native runtime motion capture, render scheduling isolation

Added isolated gel_runtime_motion_gv scene using GU's real CharacterRoot adapter,
unchanged shipping materials, automatic AnimationPlayer and 240 fixed60Hz velocity
updates. Mobile duty is assigned on this test instance; root remains stationary.
Visual floor Y0, two directional lights and ambient-color diagnostic environment.
This is an input treadmill, not physical translation, collision or gameplay QA.

Initial normal render-loop run stopped producing images after frame-030.png and
timed out at120.05s; guard terminated its own process (-15). No engine error in
log. Sampled process was CPU-active, not enough symbol information to establish
an engine root cause. Preserved partial outputs; no successful-run claim.

Hypothesis: capture waiting on render scheduling. Added stage logs and explicit
deferred force_draw, following existing cleanup harness, with --disable-render-loop.
Separate GV R2 completes in6.514s exit0, no logged errors, 48 PNG frames and JSON.
This isolates a working offline capture path, not proof of the original hang's
exact cause or real-time performance. Encoded4-second12fps motion.mp4 using ffmpeg.
Animation samples show idle -> move_start -> move -> move_stop -> idle. Motion mix
reaches .992 then decays to .093 by final capture; not fully settled at clip end.

Viewed initial-run moving frame020 and R2 final frame047: severe broad pale front
reflection remains, chrome-like eyes and forehead pore, red opaque/plastic feeling
rather than bright translucent reference jelly. These diagnostic lighting captures
do NOT establish material-only causality. No reference lock or visual improvement
claim. Full sequence visual review, ground contact, side views and remaining10
animations still pending. All prior versions preserved, no production promotion.
Next isolate body/shell reflection under matched reference lighting before tuning
the finish; do not confuse the now working motion-capture pipeline with art approval.

### GW — isolate pale reflection to body's analytic studio cards

Previous GV turn was progress: completed native motion capture and exposed visible
material mismatch. Shader skill guided uniform-level ablation, no shader source
or production defaults changed. Graph again reports IMMUNE- unindexed; inspected
known shader files directly. Added GV candidate hook/frame_count (defaults retain
GV behavior) and isolated GW scene, selected with IMMUNE_GW_VARIANT.

Five native Vulkan runs use identical GV camera, geometry, lighting and first20
idle updates. Outputs layer-isolation-gw-{baseline,no_shell,no_cards,no_direct_spec,
bounded_cards}, four frames each. All guard clean exit0 in1.45–3.11seconds. Separate
runs' shader TIME is not explicitly frozen, so these are qualitative ablations,
not pixel-exact optical contribution subtraction or motion acceptance.

Viewed frame003 of all three removal variants: hiding BodyShell leaves the broad
pale facial/body patch; setting body spec_energy0 also leaves it, removing sharp
direct highlights instead. Setting body studio_reflection_strength0 removes the
broad pale patch. This identifies the body's analytic studio reflection as its
dominant cause in this diagnostic scene, not the transparent shell.

Bounded-cards candidate retains shell/direct specular and sets body card strength
.32,budget.08,edge_share.94,strip_shape_mix1. Native capture clean2.11s. Viewed
against original CHAR-BASE-T-3d-alt.png: narrower pale strips replace broad wash,
but remain artificial; body still much too dark/red, lacks golden transmitting
edges and reference's irregular wet facets. Chrome-like eyes/pore unchanged.
Keep this as a bounded reflection control, NOT an accepted finish or promotion.
No old outputs or assets removed. Next diagnose body/interior color and energy
budgets with the analytic-card control; do not restore broad wash to fake brightness.

### GX — separate palette and direct-light ceiling, combined orange candidate

GW was progress: isolated analytic-card wash. Shader skill used for test-instance
uniform changes. Added gel_color_energy_gx scene with four variants and preserved
parameter reports. Actual initialized body_color(1,.185,0),deep_color(.8,.052,0),
body_absorb1,extinction_density3.8,spread2,body_budget1.36,direct share.1,
exposure.88. These are much redder than shader declaration defaults; use initialized
values, not declarations, when diagnosing current render.

All variants retain GW bounded cards. Energy-only raises direct share to.45 and
exposure1; palette-only uses body(1,.60,.018),deep(1,.32,.008),transmit(1,.84,.16),
body_absorb.35. Combined applies both. No lamp, camera, mesh or production selector
change. Four Vulkan guard runs clean exit0,1.39–2.25s, four PNG frames each.
Viewed frame003 of energy/palette/combined: energy alone produces bright red;
palette alone dark amber; combined yields orange body and yellow/golden edge.
This supports both hue and per-light ceiling contributing to the dark-red baseline.

Combined is a useful color-direction candidate, NOT finished reference jelly:
core is too uniform/flat, edge has an artificial glow-like appearance, strip
reflections remain synthetic and eyes/pore chrome-like. Thinness/transmission
remain shader proxies, not verified physical internal transport. No full motion,
multi-angle, clipping or three-light regression acceptance for the raised ceiling.
Reports parameters.json preserve before/overrides. All previous versions retained.
Next restore depth/detail without broad white wash and separately correct facial
reflection. Do not promote this single-angle color control as a finished asset.

### GY — facial reflection isolation on GX combined candidate

GX was progress: color/ceiling separation. Read eye shader completely using shader
skill; added isolated GY scene extending GX with preserved default output prefix.
No production shader change; retains shared deformation shader and uniforms.
Actual eyes initialize studio_strength.46,budget.56,main_card_shape(4.5,7),
catchlight_strength.48,specular1,roughness.042. Pore/mouth already studio0 and
catchlight0, but specular1/roughness.18: their bright glint has a different source.

Two guarded Vulkan captures clean exit0 (2.29s,1.45s), four frames each. no_cards
sets all face studio/catchlight0: eyes lose broad silver wash, pore glint persists.
small_cards sets eyes studio.28/budget.20,main shape(90,100),pin(150,150),specular.45;
cavities specular.12/roughness.30. Viewed frame003: dark eyes with small edge glints
and less bead-like pore. Eye surfaces now too flat/dark to call final reference
match; need shaped localized reflections, not reintroduction of a broad white wash.
Body remains flat GX orange proxy. Reports face-before.json preserve initialized
values; overrides explicit in GY script. All prior assets/captures retained.
No motion/multi-angle/reference acceptance or production replacement. Next couple
localized reflection shape to irregular wet surface detail and inspect face closeup
under reference-like lighting; keep body interior-depth problem explicitly open.

### GZ — authored bump scale/depth test, no finish acceptance

GY was progress: facial source isolation. Shader skill used to inspect existing
triplanar sampling and derivative bump. Added isolated GZ harness inheriting GX
combined/GY small_cards material overrides. It validates both inherited variant
environments to avoid accidental baseline mismatch. Actual body authored height
enabledtrue,scale.36,depth.0009,membrane grazing floor.44/power1.45,microdepth.0006.

Three guarded native captures (baseline,broad,broad_soft) clean exit0,1.43–2.08s.
Broad sets scale.25,depth.008,microdepth0; broad_soft same except depth.003.
Sampling multiplies position by scale, so lower scale enlarges texture features;
bump strength also divides by scale, recorded explicitly rather than interpreted
as a pure frequency-only test. No geometry displacement or topology changes.
Viewed both frame003 images: broad exposes dense dimple/pockmark-like highlights,
not reference's smooth irregular wet facets. Broad_soft is gentler but remains
flat in core, with synthetic strips. Neither accepted as finished material.
Four frames per run, not motion or anti-aliasing acceptance. Parameters preserved
in surface-parameters.json and all old files retained. Next inspect/replace the
height-field morphology itself in an isolated candidate rather than escalating
depth on an unsuitable pattern. Interior depth remains independently unresolved.

### HA — smooth periodic height morphology control, reject regular ripples

GZ was progress: exposed unsuitable dimple morphology. Shader skill guided new
isolated numerical RGBF height texture (256 square, mipmaps, six integer-frequency
sine modes per decorrelated channel). This is generated shader data, not a edited
beauty image or changed mesh. Saved height.res independently in each HA output.
Uses GX combined/GY small_cards, scale1, microdepth0, depth.008 gentle/.018 strong.
The same texture feeds authored inclusion/fiber paths too; this is NOT a pure
surface-only ablation. Shared shader and runtime deformation remain unchanged.

Both native Vulkan guards clean exit0,2.66/1.78s, four PNG frames each. Viewed
frame003: smoother continuous highlights than GZ dimples, but regular interference
ripples remain obvious around shoulders/feet; strong version accentuates them.
Neither adopted. Core remains strikingly uniform despite changing normals.
Next test whether GX's per-light ceiling is flattening interior differences before
another morphology iteration; this is a hypothesis, not a verified cause yet.
No multi-angle/motion/reference approval. Every original asset/version preserved.

### HB — native per-light ceiling probe and gain controls

HA was progress: rejected periodic morphology and identified ceiling hypothesis.
Shader skill used for isolated runtime shader instrumentation. Validates exact
insertion anchors, saves probe.gdshader in output; original shader file unchanged.
Probe removes body emission/specular and hides shell. Each of two lights adds
(.5,0,0) if raw body-light peak>=its budget, otherwise(0,.5,0). Thus red=both
above, yellow=one above, green=neither above. This probes the budget threshold,
NOT the earlier soft-knee onset, hardware clipping or exact lost contrast.

Actual albedo_gain1.84. Baseline probe shows almost all visible core yellow with
red edges; gain.2 changes core to green, retaining some yellow/red edge. Supports
per-light compression affecting core; not proof it explains all flatness. Two
Vulkan runs clean exit0,3.81/1.30s. Probe shader assigned after initialization so
existing material references retain motion updates; no rebuild/production use.

Beauty controls keep original shader/shell and only change gain(.2/.6). Both
clean exit0,2.20/1.39s. Viewed frame003: .2 restores broader dark-to-light shading
but darkens amber core too much; .6 stays brighter/flatter. Neither achieves
reference's bright rich interior. All four runs four frames, fixed diagnostic
camera/lights, not full motion/multi-angle acceptance. Saved all outputs, no
promotion. Next separate light contributions/soft limiting from the missing
interior optical-density variation; do not simply lower gain and call it jelly.

### HC — existing cohesive-density color path, three rendered sequences

HB was progress: direct-budget evidence. Shader skill used to inspect existing
surface-sampled analytic slime field and color mixing. Added HC on GX combined/GY
small_cards; real CharacterRoot input treadmill unchanged, 240 updates,48 images.
Baseline actual flow_strength.82,idle_speed.28,slime_strength.82,scale.78,
softness.18,threshold.48,core_mix.32,laminar_color_mix.22. Density candidate sets
slime/core strength1,softness.25,laminar color0,deep_color(1,.08,.002). Second
density_scale candidate additionally sets slime scale3. Neither changes mesh or
adds particles, shader loops, or a second geometry mass.

All three Vulkan guard runs clean exit0,5.69/5.08/5.61s,48 frames each. Viewed
density frames003/020/047 and density_scale003/047: orange-red broad shading shifts,
but interior still reads as a surface color gradient with synthetic reflections,
not convincing transparent-shell depth. These selected frames are not a complete
motion acceptance; underlying clock uses existing TIME and simulated input.
Encoded density_scale/motion.mp4 at12fps, verified48 report samples. All versions
and parameter reports retained. No production adoption or reference lock.
Next needs view-dependent interior depth/parallax, not merely stronger existing
surface-color blend. Earlier full-volume EH performance failures remain relevant;
any new depth representation must be bounded and independently profiled.

### HD — current GQ rest-shape distance volume, verified surface residual

HC was progress: exposed surface-density proxy limits. Shader skill guides mesh-
bounded interior representation; reused existing VTK bake script on actual GQ
archive, not old FJ geometry. Disk18GiB available before bake. New output
body-distance-hd-128 contains128^3 float32 values (8MiB) and source/payload hashes.
Source SHA fbd161a50eb520c43e91dcaf805d2197db2d47e6dfa091402a94557532376f4f;
payload SHA 2a993a9793d1985c9b217682e6835188b7c06a2c455942730ff04319ebab9301.
Bake exits0, signed volume1.015547911, finite signed distances, known inside/outside
probes pass. Original geometry and old distance volumes retained.

Added check_rest_distance_hd.py: verifies hashes/byte count/finiteness and samples
trilinear field at56118 rest vertices plus20000 deterministic triangle-index-uniform
barycentric surface samples (not area-weighted). Vertex absolute residual mean
.0001641,p95.0005284,max.0046283; sampled triangles mean.0001297,p95.0004577,
max.0043408. Voxel spacing(.0131353,.0127559,.00913386). Saved surface-check.json.
These are measured errors, not an optical acceptance threshold; thin facial rims
and near-boundary rays still require safeguards. Rest SDF cannot be sampled at
deformed positions without inverse deformation or another consistent mapping.
Next bounded rest-pose ray-depth prototype and explicit sample budget before any
dynamic integration. No new beauty-render improvement claimed this turn.

### HE — bounded native rest-depth rays; edge failures remain explicit

HD was progress: current-shape SDF. Added independent unshaded rest-depth shader
and native harness loading hash-checked HD volume/GQ body, no CharacterRoot,
deformation, face attachments or lighting. Vertex inverse MODELVIEW supplies local
camera; texture coordinates map sampled bounds to texel centers. Straight camera
ray (no refraction) uses12 entry probes .002 apart, accepts distance<-.001, then
at most96 interior samples with step clamp(-d*.7,.001,.06). Max108 SDF calls/pixel,
no nested lighting loop. Grayscale travel/1.6; yellow=no inside seed,
magenta=no exit before budget. Normalized depth may clip above1.6.

Guard clean exit0,2.992s for00/40/90 captures, not GPU FPS. Viewed all angles:
body depth varies, but silhouette/grazing failure marks remain. Hypothesis: waiting
for positive distance wastes near-exit steps. Add opt-in exit tolerance.0005 (less
than seed margin.001), preserve zero default and separate R2 scene/output. R2
clean exit0,2.641s. Threshold-count magenta pixels at00/40/90 fall269/391/1022 to
202/289/609; yellow unchanged1153/1111/1326. Counts from RGB>180/<100 masks,
not exact coverage percentages or a depth-accuracy proof.

Tolerance helps but does NOT solve ray convergence/entry safety. Keep prototype
diagnostic-only; do not shade failures as valid depth. Next compare failing rays
to exact mesh intersections and establish bounded fallback/entry handling before
using this depth for appearance. No optical/motion/reference acceptance, original
assets and both result sets retained.

### HF — exact mesh-ray comparison of HE failure pixels

HE was progress: bounded path with exposed failures. Debugging skill/systematic
method used for causal trace before another threshold edit. Added CPU comparator
check_depth_edges_hf.py: recreates pixel-center rays for actual HE00/40/90 camera,
uses existing VTK closest-hit adapter for mesh entry/next exit (1e-5 inward offset),
verifies archive/SDF hashes and emulates R2 trilinear12+96-step algorithm. Selects
150 yellow and150 magenta pixels per angle, seeded RNG. No beauty-image edits.

900 sampled rays all hit mesh;895 CPU classifications match GPU. Yellow matches
148/150,150/150,150/150; magenta150/150,150/150,147/150. Remaining5 differ near
thresholds; not asserted exact floating-point parity. Saved depth-edges-hf.json
with individual rays and summaries. All yellow medians of first-segment midpoint
SDF are only -.00050/-.00037/-.00044, shallower than seed criterion-.001; some
midpoints are positive from interpolation error. Their mesh first-depth medians
.0352/.0280/.0363 show that missing seed is not simply zero material thickness.

Magenta first-exit medians .607/.601/.665; median traveled/true-depth .920/.872/.917.
They usually have real interior and an exit beyond progress reached, not a missing
mesh exit. Distinct problems: near-surface seed/grid precision vs bounded grazing
convergence. Do not solve both by relaxing one threshold. Next evaluate bounded
fallback for already-entered rays against these exact exits, while retaining an
explicit unresolved-seed status. No render/optical acceptance or production change.

### HG — bounded fallback accuracy audit, reject success-count-only fix

HF was progress: separated seed and exit failure. Debugging skill guided CPU
experiment before GPU integration. Added opt-in --fallback to HF comparator,
preserving default behavior and writing new depth-fallback-hg.json. After original
CPU-magenta exhaustion: one current-distance check, at most16 fixed steps, then6
bisections on first detected threshold crossing (max23 extra SDF calls). Four
step sizes tested on same447 CPU-magenta rays, against exact mesh first exit.

Steps .005/.01/.02/.04 resolve274/346/386/444 of447. Absolute error medians
.00321/.00294/.00263/.00216 andp95 .01225/.01196/.01133/.01091 hide severe tails:
max .11477/.11481/.11489/1.17997; errors>.02 count6/6/6/8. Thus largest-step
success count is unsafe, not a near-complete solution. All candidates rejected
for promotion. No shader changes or GPU cost claims from these CPU results.

At90deg pixel[377,523], exact first exit.077927 but original march already reached
.188600 before fallback, proving at least one failure predates fallback. Several
40deg rays resolve too early by.0245–.0461. This also implicates SDF/grazing
representation and threshold crossings, not merely an insufficient step cap.
Next needs near-boundary exactness/representation handling, with these rays retained
as regression data; do not silently replace their depths with later intersections.
Every previous output/asset retained; reference and dynamic optical goal still open.

### HH — cell-wise cubic reference proves coarse-grid gap loss

HG was progress: rejected unsafe fixed fallback. Debugging skill guides separation
of numerical traversal and representation error. Added trilinear_exit_hh.py CPU
reference: partitions ray at voxel planes and solves each trilinear cell's cubic
for first outward zero after existing inside seed. Two analytic tests pass: plane
exit and three crossings within one cell (first exit selected). No GPU adoption.
HF --cell-roots writes new reports depth-cell-roots-hh.json and-r2.json.

447/447 sampled CPU-magenta rays resolve. Median absolute mesh-exit error.0003785,
p95.0045413, but three side-view outliers>.02, max1.180929. This is not an accepted
depth solution despite complete root finding. Additional exact-mesh next-entry
checks confirm actual empty gaps that the grid marks inside at midpoint:
[382,430] gap.017257,SDF-.0000650; [500,664] gap.009115,SDF-.0020392;
[377,523] gap.011509,SDF-.0012517. Coarse trilinear field has lost those gaps,
so changing traversal alone cannot recover first true exit.

Next must preserve near-boundary geometry information (e.g. exact mesh/depth-pass
boundary for camera rays), rather than promote more iterations on the same field.
SDF can still assist interior sampling away from boundaries. Original artifacts
and all comparisons retained; no beauty improvement or dynamic optical acceptance.

## HI — actual mesh front/back depth recovers the sampled gaps

Added isolated `gel_mesh_depth_hi.gd/.tscn` and numerical comparator
`tools/meshy/check_mesh_depth_hi.py`. Renders GQ body at identity, camera angles
0/40/90, 1024 square, no AA, unshaded RGB24 camera-distance encoding with inverse
sRGB transfer and linear tonemapping. Separate front/back culling passes use
nearest depth testing; no SDF, animation, lighting or production material changes.

Native Vulkan guard completed cleanly in 3.193 seconds (process wall time, NOT GPU
frame performance). All 900 previously sampled HF failure pixels have front/back
coverage. Against independent closest-triangle first-exit thickness, absolute
error median 0.0000139694, p95 0.0001145554, maximum 0.0008229744; zero above 0.02.
The three HH gap failures now have errors 0.0000931127, 0.0000016273 and
0.0000393399 respectively. This validates recovered first-exit depth for this
sample, not universal precision, all silhouette pixels or arbitrary geometry.

Evidence: `outputs/v8.6-quality-audit-20260906/mesh-depth-hi/comparison.json` and
six encoded PNGs (numerical data, not beauty images), plus `mesh-depth-hi-guard`.
Reproduce comparator with Python script and the audit output base as argument.
Next: bounded straight-ray interior-density candidate using these validated mesh
boundaries. Refracted rays require their own boundary handling; camera-depth must
not be silently treated as refracted path length. Deformed pose synchronization,
visual acceptance and actual GPU profiling remain open. All versions preserved.

## HJ — bounded depth-driven absorption candidate, visually insufficient

Added `gel_depth_density_hj.gd/.tscn`, independent static GQ character capture with
GX combined/GY small-card parameters, no shell, no AnimationPlayer, identity
CoreMesh and body vertex deformation disabled. HI front/back angle-0 RGB24 data
decoded to RF thickness; same 1024 square/FOV32 camera. Body absorption now can
use 24 midpoint density samples along the straight rest-space camera ray. No
SDF marching, nested light rays, paid assets or production modifications.

Output `depth-density-hj` has baseline/density at explicit density phases
0/1.5/3 plus candidate shader; guard clean in 3.494 seconds, not GPU timing.
Viewed density 0/3 and baseline 0: bright orange flat core and glow-like edges
remain, interior structure not convincing. RGB absolute difference on red>100
pixels averages 3.308/255 between density phases, 4.268/255 against baseline.
These are image differences, NOT verified fluid motion: other existing shader
TIME effects are still live, so phase comparison is not fully isolated.

Do not promote. `gel_throughput` clamps thickness to [0,1], and final light path
retains multiple emission/highlight terms plus soft-knee diffuse limiting; these
are next isolation targets, not yet a proven unique cause. Capture configuration
also raises body_absorb to 1 and disables old core/laminar color proxies in both
variants. Geometry remains intact in inspected front images, but no dynamic,
multi-angle or all-animation acceptance follows. Cached depth MUST NOT be reused
on moving geometry. Next isolate absorption-only output and competing emission
with controlled clocks before adding synchronized moving depth passes.

## HK — controlled body-clock layer isolation

Added optional identity `_transform_shader` hook to HJ (default unchanged), and
`gel_layer_probe_hk.gd/.tscn`. Five separate preserved modes: full, no_emission,
through, body, no_limit. All body shader TIME tokens frozen at zero; only the
explicit HJ density phase changes. Face shaders are not clock-frozen, so numerical
comparison uses a face-free forehead rectangle x450:570/y270:350. Static/cached
depth restriction remains. Five native guards clean (2.185–3.117 seconds wall),
six images per mode, no production edits or optical acceptance.

Viewed density phase0 in all four isolation modes. No-emission removes reflection
cards but retains flat orange bulk. Raw throughput is yellow with white thin
areas; raw body is almost flat orange. Removing diffuse soft-knee produces an
overbright yellow character, not a reference-match improvement. Thus disabling
emission alone is insufficient; removing the limiter is not an acceptable fix.

Forehead phase0→3 mean absolute RGB change on 0–255 scale:
full 0.54934; no_emission 0.56302; through 6.83177; body 2.31882;
no_limit 3.32156. Raw-body output red is 255 throughout this rectangle (green
mean160.535, std4.992; blue0); raw-through mean RGB248.143/233.717/26.179.
These are display-space diagnostic measurements, not linear radiance or GPU
precision. Raw outputs bypass illumination via EMISSION and disable custom light.
They show density variation exists upstream but is substantially reduced in the
final output; attenuation versus color multiplication/light limiting still needs
calibration. `gel_throughput` uses transmit-color-derived spectral extinction and
clamps thickness to1; no claim yet that a single parameter is the sole cause.

Next: calibrate absorption spectral contrast and input energy together using this
fixed-clock, fixed-camera comparison, retain a bright orange/red interior with
golden thin regions, and then restore restrained wet highlights. Do not simply
increase density or bypass the limiter. All outputs under `layer-probe-hk-*`.

## HL — absorption/energy calibration, orange-red direction but rejected seams

Added `gel_absorption_hl.gd/.tscn` inheriting HK fixed-body-clock full mode.
Four variants: unchanged baseline, albedo gain0.65 (from1.84), empirical RGB
extinction sigma(0.12,2.3,6), and combined. The spectral branch also removes the
old thickness upper clamp; thus this is a grouped optical calibration, not a
single-variable extinction experiment. No physically measured coefficients claimed.
HJ first-segment depth, 24 samples and frozen geometry/camera constraints retained.

Initial baseline guard stopped on Variant-inferred `before` variable warning
treated as parse error. Explicit float annotation fixes the script; failed log
retained. All four r2 guards completed cleanly (1.529–2.741 seconds wall, not GPU
frame time), six images each under `absorption-hl-*`, plus settings and shader.

Reopened the actual `CHAR-BASE-T-3d-alt.png` reference and viewed energy, spectral,
combined density phase0. Spectral/combined make the bulk orange-red rather than
yellow-orange, but still have flat core, synthetic reflection strips, flat black
eyes and a conspicuous lower-body color boundary. Gain-only is visually weak.
Do not promote: a closer hue is not the wet, irregular, deep translucent reference.
The boundary may relate to first-segment-only thickness where camera rays traverse
multiple body intervals; must inspect exact intersections before asserting cause.
Next check this seam against true mesh intervals, then account for separated
material segments without absorbing through air. All prior assets remain intact.

## HM — lower-body seam traced to changing mesh intervals, not depth corruption

Added `tools/meshy/check_seam_hm.py`; output `seam-hm.json`. Checks source SHA,
traces repeated nearest triangle intersections with 1e-5 offsets (cap16, rejects
odd counts) for 783 pixel-center rays: x360..620 at y680/700/720, same angle0
camera. Compares encoded HI depth and HL combined RGB across adjacent pixels.
All traces finished; max GPU first-thickness error 0.0000816587 model units.

Six >0.05 first-depth jumps coincide with 2↔4 mesh intersections: the second
body segment behind an air gap is omitted by HJ. Example y720 x432→433:
first depth0.637766→0.447069, second segment0→0.0814234. Total material thickness
still changes0.637766→0.528492. Other total jumps0.06614..0.11289 remain even
after including the second segment, vs first-only jumps0.09223..0.19141.
Therefore first-segment-only absorption contributes to the seam, but adding
segments alone cannot establish a smooth result. This is not RGB decode failure.

Next: preserve each occupied interval and integrate density at its true spatial
position (do not concatenate lengths into a fictitious continuous ray or absorb
through air), plus inspect rear concavity/edge sampling where total thickness
still changes sharply. Need rendered A/B and silhouette/geometry regression before
claiming a fix. No production or prior candidate mesh changes; no visual acceptance.

## HN — full occupied-interval bake and rendered comparison

Added `bake_intervals_hn.py`; numerical data only, no beauty image manipulation.
273045 GPU-covered angle0 pixels traced against GQ mesh, zero odd/missing/over-cap
records. Interval counts: 272682 one,361 two,1 three,1 four. Stores up to four
entry/exit pairs relative to first entry in two RGBA32F files (32MiB total),
manifest with source/payload hashes. Regression against all783 HM rays:
maxfloat32 error2.97995e-8. Scope is this camera/rest mesh/coverage only; repeated
closest-hit method uses1e-5 offset, not sub-offset feature proof.

Added default no-op material finalization hook in HJ and `gel_intervals_hn` scene.
Candidate inherits HL combined, integrates24 midpoint density samples per occupied
segment at true positions, skips air. Max96 analytic samples/pixel (vast majority
24), no nested light rays. Validates source/payload hashes/byte lengths and empty
issue list. Captures three explicit density phases plus inherited baseline.
Native guard clean3.476s wall, not GPU performance evidence.

Viewed `interval-render-hn/density-0.0.png`: lower-body broad color boundaries
persist, no material visual improvement sufficient for promotion. Only363 pixels
have multiple segments; adding them does not resolve the dominant artifact. This
narrows next work to actual rear geometry/thickness transition and mapping,
rather than more optical complexity. Keep every candidate and numerical artifact.
No reference lock, animated synchronization or release acceptance claimed.

## HO — clay underside identifies hard-edged foot tunnel

Added `gel_rear_clay_ho.gd/.tscn`, standalone GQ ArrayMesh with rough gray
StandardMaterial3D, no liquid/face/shell shader. Four native views rear, rear_low,
side_low, bottom under `rear-clay-ho`; guard clean1.719s wall. Viewed rear_low and
bottom: the foot arch is an extruded-looking channel with abrupt lateral ridges,
not a smoothly blended soft underside. This is a geometry issue visible without
any optical material, consistent with HM's thickness seam.

HM y720 ray reconstruction locates the transition precisely. Pixel432 entry
(-.191432,.272333,.441105), exit(-.219609,.033054,-.149400).
Adjacent433 entry(-.189018,.272390,.441245), first exit
(-.208522,.104653,.027295), then second segment through
(-.213269,.063827,-.073457) to(-.216821,.033277,-.148849).
Atx440 the ray exits once at(-.185727,.144310,.125163), and atx500 at
(-.028608,.218502,.308258). The internal foot arch, rather than a failed texture
read, explains the sharply changing thickness. Optical adjustments cannot remove
the hard geometry transition itself.

Next make a separately versioned, locally rounded underside/arch candidate,
pinning face, upper body, front outline and foot extremities. Recompute normals,
verify closed topology and volume/bounds change, recapture clay and re-bake depth
for that mesh; never reuse GQ cached intervals on the modified candidate. No
production mesh changes made this turn; all previous versions retained.

## HP — first local underside smoothing candidate, insufficient visual rounding

Extended numerical smoother with optional `--region underside` (default shoulder
behavior unchanged). Applied100 weighted Laplacian steps0.35 to GQ, new archive
`underside-hp`. Mask limits absx<.38,y<.32,z(-.45,.36), pins y<=.005 and front
z>=.36. 53564 vertices pinned exactly, maximum displacement0.0596279; minimum
old/new face-normal cosine0.56890, no reversed/degenerate face detected by this
test; zero non-two-use edges. Bounds unchanged; volume1.015547911→1.016986840
(+0.14169%). This is not self-intersection or projected-silhouette proof.

HO now has default-preserving output/mesh hooks. New `gel_underside_hp` rebuilds
ArrayMesh and affected-face vertex normals/tangent projections, preserving other
arrays; saves separate `underside-hp-render/body.res`, four clay views. Guard
clean1.556s wall. Viewed bottom: some transition softening but channel is still
too straight/hard and small endpoint puckers appear. Do not promote or claim seam
fixed. The support mask pins the floor/front/rear transitions too tightly for
simple local Laplacian smoothing to erase this shape. Next revise the geometric
rounding profile and transition support, checking silhouette explicitly, rather
than blindly increasing iteration count. GQ and all prior assets remain intact;
HP has no compatible optical cache yet.

## HQ — widened underside support control, still insufficient

Added optional `underside_wide` smoother mask: absx support .28..48, y.22..38,
front z.22..40, no hard floor/rear pin. Same100 steps0.35 from GQ, not from HP.
New `underside-hq` archive:51747 vertices pinned, max displacement0.075748,
minimum face cosine0.463379, zero non-two-use edges. Volume1.013772042
vs1.015547911 source (-0.17487%); ymin rises0→0.00185146, other bounds unchanged.
This does NOT establish all-pose grounding or self-intersection safety.

HP mesh builder now has default-preserving archive folder export. HQ candidate
and GQ control each captured five gray views including new front view, separate
`underside-hq-render`/`underside-hq-control`. Guards clean0.984/1.526s wall.
Viewed candidate front/bottom: front gross form retained, underside still has
straight trench walls and endpoint pinching despite wider support. Thus the
earlier hypothesis that tight support alone caused the defect is insufficient.
No promotion; do not keep increasing Laplacian iterations. Next replace the
channel cross-section with a deliberately rounded profile, with an explicit
transition to the feet/front/back, then verify geometric and optical seams.
All candidate archives/resources retained; no production change.

## HR — direct vertical arch warp rejected by face-direction guard

Added `round_arch_hr.py`: first vertical underside hit at each vertex x/z,
Gaussian targetheight .22*exp(-(x/.23)^2), boundedshift±.10 with local x/z/y
falloff. Initial short vertical support failed face-direction check (mincos
-0.99810); no mesh archive emitted. Widened vertical decay .25→.50 and upper
support .30..50→.30..80 still failed. Both reports retained under underside-hr
and underside-hr-r2; no GPU scene run, no failed mesh promoted.

Added diagnose-only path, writes report without candidate mesh. HR diagnostic
finds77 faces with nonpositive old/new normal dot, worstface13803. Its two
nearby original points(-.209925,.069820,-.163401) and
(-.209583,.079399,-.162211) move to y.116874 and.095898 respectively. This
nearby differential shift reverses the original local vertical ordering; using
the first underside hit as a height field is unstable across this overhanging
region. Widening y falloff alone does not address the root issue. Normal-dot
failure is a conservative rejection, not a complete intersection diagnosis.

Stop this height-field warp route. Next use a local surface reconstruction or
3D constrained deformation that handles overhangs, preserves patch boundaries
and checks topology/self-intersections, instead of further parameter retries.
Added HR scene remains unrun and cannot load a valid archive yet. All earlier
GQ/HP/HQ versions unchanged; production untouched. No visual improvement claimed.

## HS — 3D implicit projection improves the measured arch transition

Added `round_arch_hs.py`: hash-verified GQ/HD, Gaussian smooth signed field with
worldsigma.04,12 bounded projection steps max.006, local x/y/z blended support.
This is sculpting toward a smoothed 3D implicit surface, not reusing coarse SDF as
an exact optical boundary. Existing mesh connectivity retained.52007 vertices
pinned; max displacement.0288569; minfacecos.622939, zero nonpositive faces;
volume1.015547911→1.014964620 (-.05744%), ymin.000366337. No full intersection
or animation safety claimed.

New HS scene reuses HP resource builder; five clay captures and body.res in
underside-hs-render. Guard clean1.584s wall. Viewed bottom: ridge endpoints less
pinched and transition rounder than prior candidates, though a channel remains.
Reused HM exact-ray comparator with optional candidate source/output arguments;
source SHA189b895b7f982dc844bafc072d1b9510ff4de9f85b197d1fe9084b363eee4338.
All783 rays traced; six prior >.05 adjacent first-depth jumps are now absent.
The report's max_first_error compares to OLD GQ GPU depth and is a shape delta,
NOT current candidate GPU error. GPU/RGB controls remain GQ and explicitly labeled.

This is useful geometric evidence, not optical seam acceptance. Next re-bake
HS-specific camera intervals and render matched absorption A/B before deciding
whether to retain HS. Do not use GQ HI/HN caches on HS. Production and all older
versions remain intact.

## HT — HS-specific optical cache and matched beauty capture

Added default-preserving source/output exports to HI; `gel_mesh_depth_ht.tscn`
captures HS body.res, six front/back angle0/40/90 encoded images. Guard clean1.823s.
HN numerical baker now accepts source/depth/output/reference options; source hash
must match chosen exact-ray reference. New `intervals-ht` from HS depth/mesh:
273042 covered pixels,273034 one interval,7 two,1 four, no unresolved pixels.
All783 HS regression rays match packed intervals within2.97897e-8. No GQ depth
used as active occupied intervals on the modified mesh.

HN loader now has default-preserving source/interval-folder exports; HT subclass
replaces Body only with HS (shell stays hidden), preserves HLcombined materials,
frozen body clock, angle0 camera and lights. New `interval-render-ht`, six frames,
guard clean2.100s wall. Existing HJ legacy first-depth sampler is still allocated
but overridden by each HN occupied pair before integration; it does not define
the active path. Could remove that redundant allocation in a future refactor.

Viewed density0: lower-body color transition is less abrupt than HN, but broad
lighter arch remains. Still flat orange/red bulk, synthetic long studio strips,
flat black eyes: not reference acceptance. Keep HS/HT as a geometric improvement
candidate, not production promotion. Next return to dominant visible deficits:
wet irregular surface/reflection shaping and facial depth, with this improved
boundary baseline. Dynamic cache synchronization and all-animation QA remain open.

## HU — irregular reflection-normal candidates

Added `gel_wet_facets_hu.gd/.tscn` on HS/HT baseline. Static object-space3D
jittered-cell search (27 neighbor sites, two hashes/site) picks two nearest
random tangent slopes and blends near borders; perturbs fragment normal only,
not vertices or occupied intervals. This is authored-looking normal variation,
not fluid simulation or a proven continuous physical height field. It also
changes Fresnel/direct lighting, so not a specular-only ablation.

Five preserved variants under wet-facets-hu-* with six captures each. Baseline;
facets scale18/strength.12/border.15; strongstrength.24; cards uses facets plus
Gaussian studio cards instead of strips, budget.16/edge share.6; fine scale32,
strength.10/border.35. Guards all clean1.654–3.044s wall, no GPU performance proof.

Viewed facets/strong/cards/fine density0. Coarse variants look mosaic-like; strong
exaggerates hard cell patches, cards adds pale wash. Reject those looks. Fine is
less blocky and breaks long reflection bands into smaller irregular patches,
but still lacks convincing wet depth; eyes remain flat black. Keep fine only as
an unapproved study. No geometry changes, original shader files untouched by this
turn. Need reflection shaping without patchy diffuse color and proper glossy eye
depth next; dynamic shimmer/UV tangent seam behavior untested.

## HV — eye reflection sizing and coordinate diagnostic

Added `gel_eye_depth_hv.gd/.tscn`, keeps HUfine/HS/HT body unchanged. Five eye
variants: baseline, medium cards(shape24/40,pin70/90,strength.42,budget.3), added
local-normal catchlight.25, normal visualization, and crisp catchlight.
All guards clean1.540–3.207s wall; six images per variant, parameters in eyes.json.
Viewed medium/catchlight/normals/crisp phase0. Eye normals vary smoothly, so the
black look is not explained by constant normals. Medium gives tiny soft glints;
catchlight adds excessive fuzzy gray; crisp maps Gaussian catchlight through
smoothstep(.40,.65),strength.55,budget.5 and retains mostly black eyes.

Crisp has a round left highlight but a sliver on the right. It improves visibility
but is not accepted as reference-matched glossy eyes. The local-normal catchlight
is not view-dependent physical reflection, and baked eye meshes use differing
normal distributions; this hack must not be promoted without orientation/motion
checks. Next use camera/light-dependent reflection with fitted card placement
and verify both eyes, not merely increase local emissive catchlight. Pore/mouth,
meshes and production shader files unchanged. Face shaders are not clock-frozen;
all evidence is static diagnostic, not animation QA.

## HW — world-direction eye card, static verification only

Added `gel_world_eye_hw.gd/.tscn` on HUfine/HS/HT. Retains eye vertex deformation
and visibility gate, replaces fragment studio/local catchlight with rectangular
environment-card approximation: reflect view vector around actual view normal,
transform direction via INV_VIEW_MATRIX, project against fixed world direction
normalize(-.45,.7,1). Halfwidth.25/.40, height1.4x, derivative-smoothed edges;
Schlick-like Fresnel*.12e2 capped.7, black albedo, roughness.06,specular.5.
This is a world-anchored analytic environment reflection, not an actual scene
area light/shadow/path-traced reflection. It does not follow DirectionalLight nodes.

Two variants under world-eye-hw-small/large, six captures each, eye shaders saved.
Guards clean3.832/1.567s wall. Viewed phase0: black eyes and crisp reflections,
but angular left patch/right sliver differ and a thin right-eye diagonal highlight
is visible. Not accepted. No camera-motion test yet; world-coordinate formula is
not proof of stable rendered motion. Next isolated eye closeup/orbit and normal
continuity test before tuning or adopting the reflection. Body, pore, mouth and
production resources remain unchanged; all older candidates preserved.

## HX — isolated eye orbit and test-harness visibility correction

The initial `eye-orbit-hx-full` and `eye-orbit-hx-reflection_only`
captures are blank despite clean process guards (2.047s and 1.320s).
Diagnosis: CoreMesh is a MeshInstance3D ancestor of both eyes; the isolation
loop hid that ancestor along with non-eye geometry. These captures are invalid
visual evidence and are preserved. The test-only correction clears the ancestor's
mesh, restores its visibility, and asserts each eye is visible in the tree.
Outputs use new `eye-orbit-hx-r2-*` directories, without overwriting originals.

Both corrected native runs completed cleanly (2.662s full, 1.304s reflection-only).
The frontal closeups now show both eyes. With both directional lights hidden,
the thin curved diagonal line in the right eye remains, as do thin bright edge
traces. Thus direct directional-light specular alone is not the cause. The main
card highlight survives as intended. Reflection shader boundary/antialiasing
and mesh-normal continuity remain hypotheses, not established root causes.
The diagnostic also captures -15/0/+15 degree camera yaw and exports numerical
eye meshes for follow-up normal analysis. Three static angles are not continuous
motion or GPU performance acceptance. No production material/model is promoted;
all versions are preserved. Disk currently has approximately 16 GiB available.

## HY / HZ — reflection-boundary artifact removed in candidate

Hypothesis from HW code: dividing the reflected direction by
max(forward, 0.001) before fwidth creates excessively wide filter footprints
near the reflection horizon. HY substitutes rectangle half-space distances
abs(projected direction) - size * forward, computes derivatives without that
division, and rejects forward <= 0.05. This is a grouped boundary-formulation
change; the individual contribution of the rejection threshold is not isolated.
The eye meshes and normals are unchanged.

`eye-boundary-hy-angular` and `eye-boundary-hy-dark` completed cleanly
(3.265s, 2.336s). Viewed angular captures at -15/0/+15 degrees: the spurious
thin diagonal line and bright outline traces seen in HX are no longer visible,
while the main rectangular reflections remain. The dark control with emission
zero also has no traces. This supports the reflection-boundary implementation,
not a geometry crack, as the cause of this particular rendered artifact; it
does not prove general normal continuity or all-angle stability.

HZ reuses HY's fix_boundary function on the complete HW/HU/HT candidate,
without eye-isolation changes. `eye-integrated-hz` completed cleanly (2.259s)
and the frontal density-0.0 capture was compared directly with
CHAR-BASE-T-3d-alt.png. The eye-line artifact is absent at this view, but the
eyes remain too flat, the forehead pore is still mostly orange rather than an
open dark circle, surface patches are too mosaic-like, and the limb rims are
milky instead of golden. This is one concrete defect fixed in an unpromoted
candidate, not reference-match completion. Next priority is the forehead pore
occlusion and richer eye curvature/reflections, followed by the body material.
No production assets changed; all prior captures/candidates remain preserved.

## IA / IB — forehead-pore discrepancy traced to mixed rest/deformed test state

IA uses HZ's complete candidate with three isolated changes: `solid` replaces
only the pore material with unshaded magenta StandardMaterial3D (no deformation),
`isolated` additionally hides Body, and `frozen` retains the original pore shader
but sets liquid_body_deform_strength and liquid_wobble_strength to zero.
All three native guards completed cleanly (2.852s, 1.314s, 1.629s).
Viewed density-0.0 in each: solid and isolated both show a complete magenta
circle; frozen shows the complete dark circle with the body still visible.

This contradicts the earlier assumption that the rest candidate pore geometry
must be occluded or require enlargement. HJ freezes body vertex deformation for
cached optical intervals but previously left face deformation enabled. The
resulting mismatched pose hides most of the dark pore in HZ. The evidence
supports a diagnostic-harness pose mismatch, not a proven production mesh defect.
No pore vertices, body geometry or depth testing were altered to conceal it.

IB synchronizes all four face attachments to the rest body using the same two
zero-strength controls, with assertions. `rest-alignment-ib` completed cleanly
(1.770s); inspected frontal density-0.0 shows the full dark pore and a more
complete frown. This is explicitly a static reference-comparison correction,
not an acceptable way to remove liquid animation from the game. Dynamic
body/face synchronization still requires its own rendered test with matching
geometry-aware optical data. The body mosaic reflections, milky limb rims and
flat eyes remain below reference quality. All candidates and diagnostic outputs
are preserved; no production resources were replaced.

## IC / ID — isolate and reduce milky transmission rims

IC starts from aligned IB. Three controls disable body emission, spec_energy,
or both thin_glow/transmit_strength respectively. Native guards clean:
3.278s, 1.573s, 1.518s. Viewed each frontal density-0.0: milky limb rims persist
without emission and without specular, but disappear without transmission.
The no-transmission control loses useful luminous thin-limb appearance and is
not a proposed final material. Emission removal additionally reduces the visible
front-body mosaic patches, suggesting a separate studio/emission investigation.

ID changes only transmit_tint from the recorded runtime value 0.38 to 1.0,
retaining both transmission terms and the existing transmit color. Guard clean
1.842s. Viewed density-0.0: previously creamy-white hand and foot margins become
golden yellow, closer in hue to the reference. The central body remains flat,
the broad yellow edging can still read as glow, and mosaic patches remain.
This empirical tint candidate is not a physically calibrated absorption model,
nor reference/motion/performance acceptance. Next isolate studio emission patches
and rebuild wet specular detail without losing golden transmission. All tests
are new preserved output directories; no production shader or asset promoted.

## IE / IF — isolate patch interaction; reject hard-card body candidate

IE compares ID against no_studio (HU fine normals retained), no_facets (studio
retained), and neither. Guards clean 2.245s/1.541s/1.526s. All three frontal
density-0.0 images inspected: no_studio removes the front pink mosaic but keeps
some facet-lit surface detail; no_facets changes the mosaic into broad pink
vertical strips; neither is smooth and plastic-like. Thus the conspicuous
patches are the interaction of analytic strip emission and HU normal changes,
not a fragmented mesh. Neither removal-only control meets the reference.

IF substitutes a world-direction rectangular reflection using the HY half-space
boundary method, retains fine normals, scales reflection by Schlick Fresnel * 8,
and raises the studio ceiling to 0.5. Guard clean 3.251s. Viewed frontal capture
has conspicuous pale-pink hard-edged islands on forehead, belly and foot. It is
rejected, not promoted. A sharper reflection shape alone does not solve material
quality: the reflection has insufficient smooth energy/roughness variation and
the saturated body plus emission needs HDR/output-response investigation before
further intensity increases. Clipping is a hypothesis here, not numerically
verified. Preserve IF as failure evidence; do not repeat simply with higher gain.
Next inspect actual linear radiance/tonemapping and roughness-filtered reflection
with no_studio as the clean control. Production and all older versions unchanged.

## IG / IH — output response does not explain away the hard patches

IG holds IF's geometry/material/lights fixed: quarter exposure on the original
linear mapper versus Filmic at exposure 1. Guards clean 2.240s/1.619s. Both
frontal density-0.0 images inspected: quarter exposure is dark but retains hard
patch shapes; Filmic is brighter/yellower and also retains them. Neither is a
visual fix. At pixel (460,320), IF RGB [255,167,149] becomes [141,88,78]
at quarter exposure. Inverse-sRGB and division by 0.25 estimates pre-output
linear RGB [1.0654,0.3903,0.3047], supporting red clipping at that pixel.
Forehead ROI x375:510/y280:430 has 6512 red-255 pixels in IF; quarter-exposure
reconstruction has 6408 pixels estimated red >1.01. This is a quantized PNG
exposure estimate, not a direct HDR buffer read; it cannot recover still-clipped
pixels. Clipping contributes, but the persistent shapes reject it as sole cause.

IH changes only rectangular reflection transition width from 0.012 to 0.08,
retaining original exposure. Guard clean 3.327s. Viewed frontal output shows
slightly softer boundaries but still conspicuous pink islands: not accepted.
Next work should address the actual normal-field/reflection energy distribution,
not repeatedly change output exposure or blur width. Keep IE no_studio as the
clean control. All captures preserved, production remains unchanged.

## II — continuous scalar-field normal candidate

II replaces HU's nearest-cell slope assignment with the analytic gradient of
eight-corner quintic-interpolated scalar value noise at scale 32, strength 0.10.
It projects the view-transformed gradient onto the surface tangent plane and
retains IF's reflection/energy settings for comparison. The new perturbation
does not use mesh UV tangent axes; existing underlying material relief remains.
No vertices are moved, so the rest optical intervals are still applicable.

Initial run failed compilation because MODELVIEW_MATRIX is unavailable in the
fragment stage. Guard stopped the child (1.626s); failure outputs preserved.
Correction passes the matrix from vertex stage via a varying, then reruns in
new continuous-normal-ii-r2 directories. Guard clean 3.580s.

Viewed density-0.0: square/flat facet patches become rounded rippled glints and
the limb surface appears more continuously wet, but the large pale-pink reflection
regions and flat center remain. This is a useful normal-field comparison, not
reference acceptance. The visible texture is also too regularly dimpled in places.
The shader formula derives from one smooth scalar field; no claim is made yet
for a numerical continuity test, non-uniform-scale handling, animated stability
or GPU performance. Next address the reflection energy plateau separately while
retaining both HU and II controls. No production resources changed.

## IJ / IK — reject limiter hypothesis in forehead ROI; graded source study

IJ isolates only the body analytic reflection (body direct lighting and all other
emission removed), comparing existing limited expression against raw studio.
Guards clean 2.926s/2.185s. Viewed both frontal outputs. In ROI x375:510/y280:430,
7676 pixels with raw red >50 have mean/max RGB difference exactly 0 between
limited and raw PNGs. Red percentiles 5/50/95 are [72,153,153] for both.
Thus this region's reflection plateau is already present before the limiter;
removing the limiter is not justified as a fix for that region. This narrow
comparison does not establish equivalence elsewhere or in HDR.

IK retains II's normal field and full body, but replaces uniform rectangular
source radiance with an elliptical angular Gaussian (x variance parameter .04,
y .09), same peak gain 8 and Fresnel. Guard clean 3.065s. Viewed density-0.0:
hard islands become graded wet ripples, but forehead/belly still look too
dimpled and pink, not reference-like fine irregular facets. This is an empirical
source-distribution candidate, not measured lighting or physical area integration.
No promotion. Next prioritize scalar-field spatial structure and body/reflective
color balance, retaining IK and earlier controls rather than escalating gain.
All old assets and captures preserved; production unchanged.

## IL — spatial scale versus slope strength comparison

IL holds IK lighting/reflection/color fixed and tests shallow (scale32,
strength.035), fine (scale64,strength.10), and fine_shallow (scale64,strength.035).
Native guards clean 3.318s/2.595s/2.534s; all frontal density-0.0 images viewed.
Fine alone produces denser orange-peel dimples, not the reference's irregular
wet facets. Shallow reduces relief but broad soft pink lobes dominate. Combined
fine_shallow preserves smaller subtle glints yet remains plastic-like with flat
central orange. No variant passes reference match; none is promoted.

This comparison separates texture frequency from slope magnitude: simply
increasing frequency is counterproductive, while lower slope is useful only as
a restrained detail layer. The next material work should prioritize the missing
body depth/light contrast and eye surface/environment response, not keep tuning
this noise toward a target it does not represent. All versions remain preserved.
Static cached-depth renders do not demonstrate animated liquid or performance.

## IM / IN — absorption depth contrast calibration

IM holds IL fine_shallow fixed and changes red extinction from .12 to .8
(medium) or 1.4 (strong), green/blue unchanged at 2.3/6.0. Guards clean
3.380s/2.631s; both frontal images inspected. The thick center gains contrast,
but strong drifts brown/yellow. In belly ROI x535:600/y580:680, phase0 red
5th/95th percentiles change from [218,222] in IL to [200,216] medium and
[178,206] strong. Phase0-to3 mean absolute RGB changes are 3.713, 5.358,
8.241 respectively (8-bit PNG units). This is stronger static density-phase
visibility, not character movement or demonstrated convincing liquid animation.

IN instead adds neutral extinction .68 to all three original channels, giving
[.8,2.98,6.68]. It preserves the original spectral coefficient differences rather
than preferentially suppressing red. IN guard clean 3.226s; inspected frontal
density-0.0 retains a more orange-red center than IM strong with golden limbs,
but the pink surface highlights and flat eye response persist. Not accepted.
All variants remain empirical optical
studies with fixed rest-camera intervals, not calibrated material properties.
No production asset or shader is replaced; prior versions preserved.

## IO / IP — dim environment response gives eyes some curvature

IO starts from IN and adds a dim world-Y environment gradient to the two eye
reflections, weighted by their existing Schlick Fresnel. It retains black albedo,
zero metallic and the HY-corrected key card. This is an analytic environment
approximation, not a captured environment map or extra geometry. Guard clean
3.446s. Inspected full frontal output: subtle gray-to-black curvature appears,
without making the eyes broadly silver, but improvement at game scale is small.

IP isolates the two eyes (explicitly retaining visible ancestors) and captures
-15/0/+15 degree camera yaw. Body is hidden so its fixed-camera optical cache
is not used on visible moving-camera geometry. Guard clean 1.988s; all three
closeups inspected: gradient and key-card position respond to view, and the old
interior diagonal line is not visible. Fine dotted silhouette highlights remain
in these lit closeups; this is not an all-artifact acceptance. Eyes still lack
the reference's richer irregular reflection structure. Three static angles do
not prove continuous motion stability or performance. Keep IO/IP as candidates,
with all older versions and production assets unchanged.

## IQ — remaining eye silhouette speckle isolation

IQ extends IP, comparing no_direct (both directional lights hidden, environment
reflection unchanged) against msaa4 (lights retained, viewport MSAA changed from
0 to enum2 / 4x). Guards clean 2.325s/1.739s. Both frontal density-1.5 closeups
inspected. Removing direct lights removes the strongest white glints but faint
dotted edge traces remain. MSAA4 alters coverage but does not visibly eliminate
all traces. Neither control establishes a complete fix; do not disable production
lights or globally enable MSAA on this evidence. Next inspect eye mesh normals
and very-grazing reflection response, with numeric geometry/edge evidence before
further material changes. These are isolated diagnostic views, not game-quality
or GPU-cost acceptance. All older candidates remain, production unchanged.

## IR — numerical rest-eye mesh audit

Added tools/meshy/check_eye_normals_ir.py; output eye-normals-ir.json records
source SHA256 86c14020e8ab0afaf8ae4b7967b157455fbf9649b43b283850bf0ca20f6ddebb
for HX-r2's actual exported eye arrays. Both parts have 2208 vertices and 4096
triangles. Normal lengths are within approximately 1.1e-7 of unit length; zero
triangles have double area <1e-12. Each has 4064 near-coincident vertex pairs
within 1e-7, with maximum normal disagreement only 1.48e-6 degrees. This does
not support a mismatched duplicated-vertex normal seam.

Indexed topology has 318 boundary edges per part and no edges used >2 times;
these counts are before positional welding and must not be called physical holes.
Adjacent vertex-normal median/p95/max angles are 3.29/28.53/56.69 degrees left,
2.96/28.37/59.05 right. Worst left edge length is roughly 0.00077, located near
(-.3787,.9227,.2821), indicating rapid normal variation on a narrow rim region.
Rapid variation can be legitimate curvature; it is not itself proof of defective
normals or the rendered speckle cause. The next bounded test should compare
rim tessellation/normal interpolation on that region, not globally weld or
smooth the character. This read-only numerical audit excludes self-intersection,
deformation, screen coverage and reference acceptance. No production changes.

## IS — local rim normal smoothing does not solve silhouette speckle

Candidate-only smooth_eye_rim_is.py groups positions rounded to 1e-6 for shading
adjacency, selects endpoints of edges with normal disagreement >25 degrees, and
performs three 50%-weighted neighbor-average normal steps. Vertex positions and
indices are not edited. Selected counts 354 left/367 right; maximum normal change
10.804/10.899 degrees. Output eye-rim-is/mesh.json preserves numerical arrays.
The Godot test uses the same IP scene/material/camera, substitutes only candidate
normals and drops unused stale tangent arrays. New eye resources are saved under
eye-rim-is-render, not over original resources.

Guard clean 2.673s; frontal density-1.5 viewed. Fine bright silhouette traces
still remain. This rejects this local-normal-smoothing proposal as a fix and
does not justify altering the production eye mesh. No reference/motion acceptance.
Retain original IO/IP eye geometry. The unresolved subpixel edge issue should
not displace the larger remaining body/reference and full-game motion checks.
All older versions preserved, production untouched.

## IT — return to deformable full-character evidence

The graph still reports IMMUNE unindexed, so inspected the existing GV harness
directly. New IT reuses GV with HS Body/BodyShell geometry, original deformable
materials and face geometry, no static depth/interval shader. Native guard clean
5.889s; 240 input steps yield 48 saved images and motion.json. Sampled states:
frame0 idle, frame90 move/moving (lag x=-.072239, motion_mix .82738), frame150
moving (lag -.120924), frame180 move_stop/stopping, frame210 idle with decaying
lag -.014256. Automatic animation time and shader TIME remain real process time,
while velocity updates use 1/60; this is not deterministic four-second playback.

Viewed captures 000/018/030: visible shape change and a retained single character
in those samples, but severe broad pale reflections and metallic-looking eyes.
This is HS geometry under the existing deformable material in diagnostic lighting,
not proof of the live game's exact look. More importantly, the recent static
optical candidates are NOT yet integrated into a working deformable material.
Do not present static visual progress as ready game progress. Next port only
motion-safe material/eye corrections and verify shared body/face deformation;
geometry-aware optical intervals require a separate dynamic solution.
Root is stationary, plane has no collision, so no real locomotion/collision,
all-animation, liquid-flow quality or GPU performance acceptance. All versions
preserved, production untouched.

## IU — first motion-safe appearance port, still not reference quality

IU retains IT's HS geometry and deformable body shader. It applies restrained
body energy/palette parameters, disables analytic body studio reflection and
hides the extra shell in this test instance. It ports only IO's eye fragment
section onto each original shader prefix, preserving vertex code and deformation
uniforms (strength .7, wobble .012, body space1). Pore/mouth direct specular is
reduced. No HJ/HN camera cache, frozen vertex program or rest-only optical shader
is introduced. This is a grouped appearance candidate, not causal isolation.

First run clean 4.658s. Viewed captures 000/018/036: broad pale patches and
metallic eye response are substantially reduced, with body and face moving in
the sampled images. Body still reads as smooth solid orange, lacking the
reference's wet facets and convincing interior depth. This is not completion.

Added a default-no-op GV after-motion hook and IU per-step checks comparing all
four face lag uniforms against Body. Fresh IU-r2 output preserves first run.
240 checked steps have maximum lag-uniform error 0. This verifies parameter
delivery, not matching GPU-deformed positions/normals, complete animation or
collision behavior. Both runs retain the treadmill/time limitations recorded
under IT. All production resources and previous versions remain unchanged.

## IV — motion-safe density absorption improves palette, not interior depth

Added isolated gel_motion_density_iv extending IU. Original body shader prefix
through vertex processing is preserved (SHA256
393705223d1d7c07cf13c9bb9d83209c84a7f462e9a37dcc460475508acf328e).
Only throughput becomes exp(-(.45,2.5,6)*local_thickness*density), with density
.4+1.2*clamp(.7*existing slime volume+.3*existing laminar mask,0,1).
Body absorption is 1; competing core/laminar color lerps are disabled. This is
an empirical surface optical-density proxy, not physical volumetric transport.
No static camera cache or additional geometry is introduced. Existing flow is
active: strength .82, idle speed .28, slime strength .82/scale .78, laminar .78.
Baked thickness mix is zero, so thickness still comes from the old heuristic.

Native guard clean 6.363s, 48 captures, 240 body/face lag checks with zero error.
Viewed IV frames000/018 against IU-r2 frame018: center is deeper orange-red and
edges golden, but body remains visually uniform and insufficiently liquid.
Do not accept this as an interior-flow or reference-match fix. Between-run
timing is not deterministic; images do not isolate temporal fluid behavior.
All IT treadmill limitations and outstanding GPU/full-animation checks remain.
Next isolate field contrast and phase at a fixed pose before adding further
optical complexity; then validate any successful change in motion. Preserved
all previous versions and production assets; this candidate is not promoted.

## IW — fixed-pose isolation exposes weak spatial density and optical response

New gel_flow_isolation_iw uses IV setup without treadmill/floor, disables the
AnimationPlayer, freezes all five visible part shader TIME values at zero, and
steps only the body liquid phase through 0/1.5/3. Three outputs per phase:
normal full shading, grayscale density, and unlit v_surface_color. Diagnostic
passes explicitly zero direct diffuse/specular. Native guard clean 6.877s.
These are fixed-pose diagnostic samples, not a runtime material or fluid proof.

At abdominal ROI x450:570/y580:680, phase0 density red p5/p95 is 229/230;
phase0-to3 mean absolute RGB delta is 13.638 density, 1.049 surface, and .602
full (8-bit PNG units). The field changes, but starts almost uniform locally;
the resulting appearance variation is weak. Values are display encoded and
must not be interpreted as linear radiometric attenuation ratios.

A separate preserved run changes only slime scale .78 to3 via IMMUNE_IW_SCALE=3.
Guard clean1.593s. Viewed density/full phase0: clearly broader spatial variation
in grayscale, but full rendering still resembles smooth solid orange. Scale
alone is insufficient. Next investigate attenuation of the surface-color signal
by the custom lighting budget before adding stronger visual layers. No production
promotion, geometry changes, reference acceptance or removal of prior versions.

## IX — lighting ablations reject a single-switch fix

Added default identity hooks to IW and isolated gel_light_isolation_ix. All
three runs retain IW scale3 fixed pose/phases. no_limit bypasses only the direct
body peak_limit; no_emission zeros fragment emission; surface_only replaces
lighting with Lambert v_surface_color and zeros emission (grouped isolation,
not a proposed final material). Native guards clean3.466/4.827/2.618s respectively.

Viewed full-phase0 for all: no_limit brightens the yellow edge but remains flat;
no_emission darkens the body but does not reveal convincing layers; surface_only
loses wet highlights/transmitting edge and exposes dark arm creases. None is
accepted. At abdominal x450:570/y580:680, phase0-to3 mean absolute RGB change:
IW-scale3 .538, no_limit .626, no_emission .965, surface_only1.187 PNG units.
Red phase0 p5/p95:206/213,210/224,185/193,180/203 respectively. These are
display-encoded observations, not radiometric ratios or full-body metrics.

This does not support blaming only the direct limiter or only emission. The
underlying surface-density response is already weak. Next develop a stronger
coherent optical-density response (with fixed-pose phase evidence first), keeping
the wet surface cues; do not adopt the diagnostic Lambert material. No production
changes, prior outputs removed, runtime performance or reference acceptance.

## IY — stronger neutral-density response reveals broad moving dark masses

Re-viewed CHAR-BASE-T-3d-alt.png: reference requires substantially richer wet
surface reflections and golden transmitting thin regions, not just darker color.
New isolated gel_density_response_iy retains IW-scale3 poses/phases and lighting.
Throughput becomes exp(-(vec3(.12,2.17,5.67)+2*smoothstep(.65,1.25,iv_density))
*local_thickness). Coefficients remain nonnegative; this is an empirical density
mapping on a surface thickness heuristic, not physical volume transport.

Guard clean5.794s. Viewed full-phase0/3: broad dark orange masses visibly shift
across abdomen/forehead while bright thin regions and wet highlights remain.
However these masses still resemble broad surface shading, and the darker body
does not match the reference's luminous interior and irregular wet facets.
Useful evidence that the existing field can affect visible appearance; not a
finished material, fluid simulation, motion acceptance or release candidate.
Next retain this diagnostic visibility while testing genuine depth cues rather
than escalating contrast alone. All previous versions and production preserved.

## IZ — straight-ray layered approximation remains insufficient

Added gel_layered_flow_iz extending IY. Eight midpoint samples of the existing
analytic slime field along a straight camera-to-body ray replace its surface
sample in density. Sample length=.60*local_thickness (heuristic), with the same
surface advection offset at every depth and the existing laminar term. Camera
is transformed into shared body coordinates using actual part metadata and
embedded per diagnostic run. No static screen cache or extra geometry. This
is NOT mesh-bounded ray marching, refraction, correct volumetric advection, or
a runtime camera implementation; samples are not proven to remain inside mesh.

Front and25-degree yaw runs each capture three phases and three diagnostic modes.
Native guards clean5.773/5.188s. Viewed full-phase0 from both angles: smooth dark
orange masses remain surface-like; side also exposes uneven broad highlights.
No convincing reference-depth improvement. Camera rotation changes silhouette,
lighting and samples together; these images do not isolate parallax correctness.
Do not promote or call this true liquid depth. A geometry-bounded optical path
and reflection treatment remain necessary investigations; escalating the number
of heuristic layers without stronger evidence is not justified. All previous
versions and production resources preserved; no motion/performance acceptance.

## JA — rest-mesh bounds reject any tested universal layer length

Added check_layer_bounds_ja.py, reading the preserved HS mesh archive and tracing
nearest triangle intersections on a16-pixel grid at0/25-degree yaw. Exclusive
layer-bounds-ja.json records source hash and all occupied intervals. 1070/1033
rays hit the character, with1/16 multi-interval rays. First occupied segment
min/median/max lengths: .006184/.587431/.886643 front,
.001492/.587245/.917712 side. Fixed lengths .12/.3/.6 exceed first segment on
37/196/551 front rays and32/193/525 side rays respectively.

This is a numerical rest-mesh bound audit, not a readback of IZ's actual
per-pixel .6*local_thickness, nor its GPU-deformed geometry. Therefore these
counts MUST NOT be described as actual IZ leakage percentages. They show even
a small fixed layer depth cannot be universally safe, and side views need to
distinguish disjoint occupied intervals. No odd intersection counts or cap
failures in the sampled grid. Grazing pixels between grid samples remain untested.

Next obtain entry/exit bounds for the same deformed geometry and camera used by
the appearance shader; do not substitute a rest cache or merely shorten every
ray. Existing HN/HT rest-interval work is useful as a numerical control, not a
dynamic solution. No production resources or previous versions modified/removed.

## JB — paired depth captures now use the actual deformation vertex program

Added gel_deformed_depth_jb extending IT. It builds HS Body in an AA-disabled
SubViewport and uses the original wet shader prefix (hash
393705223d1d7c07cf13c9bb9d83209c84a7f462e9a37dcc460475508acf328e), replacing
TIME with a controlled uniform and render mode with unshaded front/back culling.
Original vertex operations otherwise remain. RGB24 encodes radial view distance
over0..8, following HI encoding. Non-body instance meshes are cleared only in
this isolated test. Shipping files remain untouched.

Frozen AnimationPlayer,181 controller steps at1/60, velocity4x during30..119.
Paired sequential captures atframes0/90/180, shader time0/1.5/3; lag x is
0/-.110534/-.014256. Global Body transform remains identity. Both draws in each
pair use identical controlled time/lag. Native guard clean3.834s.
Decoded common coverage273227/279099/274411 pixels, zero front/back mask mismatch
and zero negative differences in all three pairs. Median depth
.586978/.589037/.587822; maxima .884267/.889335/.890306. Thus these captures
are deformation-dependent, not a reused rest cache.

This is not yet per-frame viewport texture integration, animation-track/physics
coverage, exact triangle-ground-truth validation, refraction or multi-interval
peeling. Nearest back-facing depth alone must not be assumed sufficient for
every disjoint/self-overlapping ray. Next validate/use paired bounds in the
same controlled appearance snapshot before attempting full runtime integration.
No beauty/reference acceptance or production promotion; all versions preserved.

## JC — matched deformed depth is wired into controlled appearance snapshots

JB gains default no-op post-pair hook and output-name hook. New JC uses IU's
motion-safe palette/eyes, IV absorption formula and slime scale3. It restores
four face meshes only for appearance, freezes body/face time to the same value
as each depth pair, and compares heuristic versus measured local_thickness at
frames0/90/180. Same materials, pose, camera and two lights in each comparison.
RGB24 PNG depth pairs are uploaded as nearest-filtered data textures; measured
thickness is used only when entry/exit are ordered, nonzero and entry agrees
with current fragment radial distance within .001. Invalid samples fall back
to the old heuristic; the valid/fallback fraction has NOT yet been read back.

Native guard clean6.939s. Viewed control/measured090: golden transmitting regions
on arms/feet change substantially, central body stays saturated orange-red.
Surface remains smooth and internal depth insufficient. This proves a visible
effect from matched snapshot bounds, not reference acceptance. Nearest backface
is still not complete multi-interval transport or refraction. Sequential disk
capture/upload is diagnostic only, not a viable per-frame game implementation.
Next quantify entry-alignment/fallback coverage before trusting thin-edge pixels,
then evaluate bounded density integration and richer wet reflection. Production
and all prior versions preserved; no runtime/performance/animation acceptance.

## JD — GPU entry-alignment coverage passes, shifted control fails as expected

New gel_depth_alignment_jd reuses JC and replaces only body output with green
for jc_valid or red for invalid. Face restoration is disabled to classify every
Body pixel, including otherwise occluded facial regions. Direct light outputs
are zero. A second preserved run offsets both depth texture UVs by .01x (10.24
pixels at1024 resolution). Native guards clean3.681/2.871s.

Compared RGB labels against each corresponding encoded front-depth mask.
Aligned frames0/90/180 valid counts273227/279099/274411, invalid0, unclassified0,
labels outside mask0. Shifted valid17268/17810/17193, invalid255959/261289/257218;
again no unclassified or outside labels. Thus all tested aligned fragments pass
the actual shader .001 entry-distance tolerance and ordered/nonzero depths;
the deliberately misaligned control is rejected on over93% of covered pixels.
This is not a test of all possible stale/misaligned buffers: near-equal depths
can still pass the tolerance. It does establish that JC's matched snapshots
are not silently falling back across the body.

No claim of backface accuracy against deformed triangle ground truth, disjoint
interval handling, live per-frame synchronization, GPU performance or reference
quality. Next can use these validated snapshot bounds for bounded flow samples
without attributing remaining flatness to widespread entry misalignment.
Production and all previous versions preserved.

## JE — depth-bounded flow integration has only a small appearance effect

New gel_bounded_flow_je extends JC. At valid measured fragments it evaluates
eight midpoint samples between the measured front/back bounds, recalculating
the analytic circulation/advection and slime/laminar fields at each location.
The averaged density drives the same spectral absorption as JC. It asserts
identity global/part transforms because radial world lengths are used directly;
the camera remains the known JB fixed camera. Soft threshold uses .008 instead
of screen derivatives inside the loop. Original body/face vertex code and
controlled time are unchanged. This is not a general runtime camera solution.

Native guard clean3.992s. Viewed measured090: saturated orange center and golden
limbs remain, still smooth and solid-looking. Compared to JC measured captures,
whole-image RGB mean/max absolute differences at0/90/180 are .285/15,
.256/15,.354/16 PNG units. Background is included, so means are not body-only
quality scores. The change is visible but small; no reference acceptance.
The bounds inherit JB's nearest-backface/multiple-interval caveats. This is
straight-ray density integration, not refraction or full scattering transport.

Keep as an isolated more coherent sampling baseline, not a promoted material.
Increasing layer count alone is not supported as the next quality fix. The
reference's richer wet-surface reflection is still a major visible deficit;
return to motion-safe surface reflection/normal treatment while retaining
these bounded-depth controls. All production and previous versions preserved.

## JF — graded world reflection exposes smooth polished-plastic response

Added gel_wet_reflection_jf extending JE. Replaces the disabled studio term
with two smooth angular Gaussian environment sources, world-space directions
(-.6,.7,1)/(.7,.4,.8), widths(.20,.50)/(.14,.45), strengths8/4, Schlick .04
Fresnel and existing peak limiter with budget .55. No vertex/normal geometry
changes, so matched depth and bounded integration remain. These are empirical
environment lobes, not physical area-light integration.

Native guard clean4.127s, three controlled depth/appearance states saved. Viewed
measured090: considerably stronger wet reflection, but broad pink-white ribbons
across forehead, eye rims, body and feet look like polished plastic. Existing
micro-normal detail is visible but not the reference's irregular wet facets.
Reject direct promotion; stronger reflection alone is not the quality fix.
Next test a restrained continuous irregular normal field with this reflection
control, preserving deformation and bounds, rather than further increasing
light energy. No all-frame, runtime performance or reference acceptance.
All production resources and previous candidates remain unchanged/preserved.

## JG — continuous lattice relief still reads as a regular surface pattern

Added gel_wet_relief_jg extending JF. A quintic-interpolated scalar random field
at scale32 drives the existing derivative-based bump_normal, strengths .0015
and .004 in separate preserved runs. Screen-footprint fade .35..85 is included
but not tested across distances. No vertex displacement, silhouette or depth
program changes; derivatives use the actual view positions. This differs from
II's explicit object-gradient basis transformation.

Guards clean4.126/3.415s. Viewed measured090 for both: broad reflection ribbons
break up, but repeated rectangular/orange-peel structure becomes visible, much
stronger at .004. Neither meets the reference's irregular wet facets. Continuity
alone does not eliminate lattice appearance. Reject promotion of both variants;
increasing strength is not supported. Next investigate non-lattice/domain-warped
surface structure with controlled reflection, not more bump amplitude. The
screenshots do not prove temporal stability or close/game-distance quality.
All previous candidates and production resources preserved.

## JH — non-lattice waves reduce squares but not the overall plastic appearance

Added gel_spectral_relief_jh extending shallow JG. Replaces spatial lattice
height with16 fixed-index hashed directions/phases, summed sine waves at
frequencies3.5..6.5 in scale32 coordinates. No spatial floor/fract is used by
the new height field. Other original material fields can still have their own
structure. Strength .0015 and JF reflection/bounded-depth setup retained.

Guard clean4.279s. Viewed measured090: the overt rectangular pattern is reduced,
but broad pink-white reflective bands remain and feet show repeated fine wave
structure. Removing lattice interpolation alone is not enough for reference
quality. Finite directional waves are not guaranteed isotropic or non-repeating;
the inherited footprint fade is not calibrated to this new frequency band.
No claim of anti-aliasing, temporal stability, performance or visual acceptance.
Further work must address highlight distribution and frequency/footprint response,
not treat a different noise function as a finished material. All prior versions
and production resources preserved; no promotion.

## JI — narrower highlights help concentration, not reference distribution

Added gel_highlight_filter_ji with two preserved variants. Both narrow JF source
widths to(.10,.38)/(.10,.35), strengths24/12 and reflection budget1.2. This is
a grouped highlight-shape/energy candidate, not individual parameter isolation.
The filtered variant additionally attenuates each JH wave by
exp(-(phase_dx^2+phase_dy^2)/24), a Gaussian footprint approximation. It does
not provide full nonlinear specular antialiasing; inherited fade is retained.

Native guards clean4.068/3.467s. Viewed filtered measured090: highlights more
concentrated and white, less broad pink wash, but still arranged in ribbons and
the feet retain repetitive detail. Not reference quality. Filtered-versus-only-
highlights whole-image RGB mean/max difference at090 is .00877/46 PNG units;
small average does not imply no local effect or temporal stability. Different
distances, moving camera and performance remain untested. Do not call this an
aliasing fix or promote the candidate. Next needs distribution/temporal evidence,
not another unconstrained increase in specular strength. All versions preserved.

## JJ — farther-camera filtering does not resolve the visible pattern

New gel_distance_filter_jj extends JI at1.5x camera-target distance with matching
new depth captures and corrected JE ray-origin literal. Camera metadata saved;
unit body-coordinate assertions retained. Unfiltered/filtered runs clean
3.882/3.149s. At frames0/90/180 covered depth pixels119977/122570/120501 and
max back-depth7.475884/7.475636/7.476711, below RGB24 encoding limit8 (no far
depth saturation). This is an additional diagnostic distance, not a verified
shipping gameplay camera or repeated JD alignment audit.

Viewed filtered measured090: bands and repeated foot detail remain visible at
smaller projected size. Filtered/unfiltered body-mask mean/max RGB differences
.07794/74,.08101/60,.07681/75 PNG units. Sparse strong differences mean whole-
body average alone is inadequate for judging filtering; continuous subpixel
motion is still untested. Neither result proves aliasing or temporal stability
solved. Further quality work must alter the visible reflection/relief pattern,
not rely on distance or this filter to hide it. All production and previous
versions remain preserved; no promotion or reference acceptance.

## JK — normal-stack isolation separates fine-pattern and broad-highlight issues

New gel_normal_stack_jk extends filtered JI, resets n to base_n before JH relief,
bypassing earlier shader normal perturbations while preserving earlier color,
thinness and roughness fields. Second geometry variant also resets n after the
new relief, so final shading uses interpolated/deformed geometric normals only.
Neither changes vertices or matched depth snapshots. Guards clean4.231/3.401s.

Viewed measured090: old-normal bypass still shows the repeated foot detail and
broken-up highlights. Geometric-normal variant removes those fine patterns and
produces smooth foot highlights, but broad ribbons remain. This supports the
new wave relief as the source of the conspicuous fine pattern in this control,
not a need to resculpt the foot mesh. Broad ribbons persist independently of
that relief and need reflection-source/layout treatment. The geometric variant
is an isolation control, not an acceptable featureless final surface.
No temporal, GPU-performance or reference acceptance. All old versions and
production resources preserved. Next address broad reflection distribution
separately from redesigning the fine surface field.

## JL — compact source shape shortens broad reflection ribbons

Added gel_compact_sources_jl on JK geometric-normal control. Only source widths
change from(.10,.38)/(.10,.35) to(.20,.20)/(.16,.16); positions, peak strengths,
budget, depths and absorption remain. Shape changes also alter integrated source
energy, so this is not equal-energy calibration. Requires geometric-control env.

Guard clean4.247s. Viewed measured090: forehead and body ribbons become shorter
localized highlights; some foot streaks persist due to local curvature. This
supports source aspect ratio as a contributor to elongated reflections. The
surface still looks smooth/plastic and lacks reference facets; do not adopt
featureless geometry as the final solution. Body and eye reflection sources
are not yet unified, another remaining consistency limitation. Preserve as a
source-shape control while designing irregular relief without repeated waves.
No temporal/performance/reference acceptance or production changes; old versions
preserved.

## JM — compact radial relief remains visually unsuitable

Added isolated gel_compact_relief_jm extending JL. Final normals use a scalar
height field of jittered, signed compact radial kernels, 27 neighboring cells,
radius .45–.75, cubic positive-part support, body-space scale24 and strength.002.
Derivative-based footprint fade is heuristic, not validated specular AA.
Vertices, depth pass, reflection layout and prior versions are unchanged.

Native Vulkan guard clean, child0 and completion marker, elapsed4.507s. Viewed
measured090 against JL: localized highlights now break into conspicuous little
dimples/bumps, especially forehead; this is not the intended wet irregular
faceting. Reject promotion. Avoid treating removal of obvious wave patterns as
reference acceptance. Three snapshots do not establish motion continuity,
14-animation quality or GPU frame-time performance. The 27-cell evaluation
also requires profiling before any production consideration.

Next should establish the desired surface-detail scale and highlight breakup
against the actual reference before further parameter variants; this candidate
does not resolve the underlying smooth-plastic/material-depth mismatch.

## JN — reference framing audit corrects the next intervention

Reopened original CHAR-BASE-T-3d-alt.png and JL measured090 directly. Measured
largest connected orange mask (R>threshold, R>1.5B), thresholds60/100/140,
using PIL/numpy/scipy label. Reference bounding box at threshold100 is
(53,53,907,896); JL000=(222,200,581,600), JL090=(195,206,604,595),
JL180=(216,200,584,600). Width/height reference1.0123 vs candidate
.9683/1.0151/.9733. Threshold variation changes reference width at most1px,
candidate bounds unchanged. These are image-space extents, not proof of
matching mesh proportions, camera intrinsics or pose.

The two largest enclosed dark components in the face region correspond to
eyes on visual inspection. At threshold100, reference areas11166+9589 give
2.554% of bbox area; JL0004691+4707 give2.696%, JL0904775+4836 give2.674%.
Highlights split/alter masks, so these are dark-region proxies, not anatomical
eye surface areas. Do not include all enclosed holes: the threshold also
captures mouth/pore and non-eye material regions.

This evidence contradicts treating smaller on-screen eyes or apparently shorter
body in these differently framed images as sufficient reason to enlarge eyes
or stretch the mesh. Reference fills896px height vs600px candidate; small
surface features are not directly comparable in pixels. Next capture candidate
at matched occupied height, with newly regenerated depth and corrected ray
origin, before assessing surface-detail scale. Do not stretch screenshots or
geometry to compensate for framing. Then prioritize connected irregular wet
facets (not isolated round dimples), edge transmission and layered reflections.
Reference light setup/camera are unknown; matching framing is necessary but
does not isolate material from illumination. No production changes or acceptance.

## JO — matched occupied-height native control

Added gel_reference_framing_jo extending JL, changing only camera FOV using
2*atan(tan(original_fov/2)*600/896). Position and orientation remain unchanged,
so JE's camera-origin literal remains valid. Fresh front/back and beauty passes
are captured at all three shader snapshots; no image resizing or mesh edits.
Camera settings stored in output camera.json. Guard clean3.208s.

Measured threshold100 orange-component boxes: idle(80,46,867,896), moving
(39,55,901,888), settling(70,46,872,896). Reference(53,53,907,896).
Thus idle height target896 is reached without clipping. All three front/back
coverage mismatches0 and negative back-minus-front counts0. This does not
replace the JD shader-validity test, exact multi-interval geometry verification
or continuous-motion evaluation.

Viewed idle: at matched occupied height the smooth plastic look remains obvious;
flat black eyes with a single hard reflection, broad blurred body highlights,
and nearly featureless feet remain unlike reference. Shape differences remain
(notably arm attachment/negative spaces), but reference pose/camera are unknown.
This control is suitable for detail-scale comparisons, not visual acceptance.
Next material changes should use this matched framing, preserving JL/JO as
controls. No production promotion, shader-performance claim or animation signoff.

## JP/JQ — facet orientation field and distribution isolation

JP extends matched-frame JO. Replaces final geometric normal with a tangential
random orientation field, scale48, amplitude.14, Gaussian weights exp(-24*d2)
over27 cells with feature positions restricted to .35–.65 of each cell.
VIEW_MATRIX rotates field under JE's asserted identity body transform. This is
an art-directed normal field, not an integrable displaced physical surface.
Footprint fade heuristic remains; no validated temporal/specular AA.

JP guard clean4.931s. Viewed idle: clear checker/mosaic structure; reject this
distribution. JQ keeps scale/amplitude/blend sharpness but expands feature jitter
to full cell and neighborhood to125 samples to avoid omitting nearby features.
JQ guard clean4.255s. Viewed idle: square alignment is reduced, but high-contrast
polygon patches look like a mosaic/crystal coating rather than the reference's
subtle wet surface. Not accepted; next isolate orientation amplitude/transition
softness before adding more fields. Both saved separately, original vertices/depth unchanged.
Full-cell jitter addresses the regular placement hypothesis, not all material
defects. Do not infer performance from these capture wall times:125 exponential
weights per shaded fragment needs profiling and likely a cheaper representation
before integration. No live-motion or release acceptance.

## JR — orientation strength dominates excessive facet contrast

gel_facet_balance_jr extends JQ with three explicit env-selected variants:
amplitude only .14->.045; softness only Gaussian exponent24->8; combined both.
All other material/depth/camera settings retained. Guards clean4.874/4.230/4.332s
respectively, not GPU timings. Viewed all three idle captures at matched height.
Amplitude reduction visibly reduces mosaic contrast more than softness alone;
softness mainly rounds cell transitions while strong patch contrast persists.
Combined is less crystalline but still reads as textured plastic, not accepted.

This bounds the benefit of more facet tweaking: broad pink-white front highlights
and flat black eye reflections remain independent defects, while the reference
places substantial wet reflection around outer contours. Preserve combined as a
subdued-detail candidate and next isolate reflection placement using the same
field; do not claim softening facets solves transparency or body depth. The
125-cell field remains costly/unprofiled and deformed-coordinate sampling has
unverified temporal behavior. No production resources changed or versions removed.

## JS — contour reflection placement improves distribution, not interior depth

gel_contour_sources_js extends JR combined, asserts that variant. Only two
Gaussian environment-source directions change: (-.60,.70,1)->(-1,.45,-.65),
(.70,.40,.80)->(1,.35,-.65). Widths, source radiance, budgets, direct lights,
facets and geometry remain unchanged. Native guard clean4.739s. All six depth
PNG hashes (front/back at000/090/180) identical to JR combined.

Viewed000 and090: large front pink-white patches move toward lateral head/body
contours and feet, closer to reference reflection distribution. Preserve JS as
the next placement baseline, not production promotion. Interior remains flat
orange/red, eyes still black cutout-like surfaces with an unrelated hard card,
and some isolated gold front glints remain from other lighting terms. Changing
body sources alone does not unify eye illumination or create optical depth.
Next inspect/align eye environment reflections with JS and retain dark eye body
while introducing readable curvature. Continuous motion, silhouette integrity
over all14 animations and actual GPU performance remain unverified.

## JT — shared lateral eye sources alone worsen readability

gel_shared_eye_sources_jt extends JS. Copies jf_source helper from current body
beauty shader. Replaces eye-only front rectangular card with the body's two
Gaussian directions, widths, colors and radiances; applies Fresnel and peak1.2
cap. Retains dim legacy eye sky gradient, standard eye direct-light response,
visibility discard and complete prefix before hw_size (including vertex and
controlled jb_time). Saved EyeL/R shaders and eye-port.json prefix hashes.
This unifies only these two reflection sources, not every lighting term.

Guard clean4.866s. Viewed000: previous white card disappears, almost all eye
area is dark with only faint grazing highlight. Readability worsens; reject
promotion. Shared source consistency by itself is not visual acceptance.
This supports testing an additional shared front soft source for both body and
eyes; do not restore an unrelated eye-only painted catchlight. Eye curvature,
normal distribution and rim geometry remain possible contributors and are not
proven correct by this lighting-only test. Production and older versions unchanged.
Continuous motion and deformation-uniform synchronization not revalidated here.

## JU — shared frontal soft source reveals curvature but washes body

gel_shared_front_ju extends JT. Adds one identical incoming Gaussian source
expression to body studio and both eye reflected terms before their existing
budget operators: direction(-.45,.70,1), widths(.32,.40), radiance4, warm white.
Each evaluates its actual reflected direction and Fresnel. Vertex programs,
visibility gates, mesh and existing three-state harness unchanged. Saved final
eye shaders overwrite only this new run's inherited intermediate eye snapshots.

Guard clean5.810s. Viewed000: eyes gain a broad dark-grey gradient and are more
readable than JT, but body now has broad pink-white wash on forehead/front and
feet. Not accepted. This confirms the shared-source tradeoff at this tested
shape/intensity; it does not prove separate light rigs are necessary. Next
adjust source angular extent/edge profile, keeping shared radiance, to produce
more localized eye reflection without broad front wash. Do not only increase
intensity. Source response is not fully unified: eye cap and body soft budget
operator differ, eye dim sky persists. Interior depth, actual animation/motion
quality and GPU frame time remain unresolved. No production or old-version edits.

## JV — narrower shared front source reduces wash but loses eye readability

gel_narrow_front_jv extends JU, changes only front source widths(.32,.40) to
(.12,.16) in body and both eyes. Peak radiance4 unchanged, integrated angular
energy decreases; not an equal-energy comparison. Saved final eye shaders.
Native guard clean5.776s. Viewed000: body front wash contracts to smaller
patches, but eye reflection becomes a small dim spot. Still lacks reference
glass-like eye depth; reject promotion. Disk remains about15GiB available.

The JU/JV pair brackets a source-size/readability tradeoff without resolving it.
Next inspect eye normal/reflection-direction distribution before another source
size/intensity variant. Geometry curvature, imported normals and source overlap
are distinct possible causes; current snapshots do not identify which dominates.
Do not infer mesh failure solely from the small specular spot. Preserve all
versions. Production unchanged; dynamic integrity/GPU/reference gates remain open.

## JW — eye-facing and narrow-source coverage diagnostic

gel_eye_diagnostic_jw extends JV, preserves eye vertex prefix and visibility
gate, outputs data through emission (inverse sRGB then linear viewport output):
R=clamped NdotV, G=unit narrow-front source response before radiance/Fresnel,
B=1 eye marker. ALBEDO0/SPECULAR0/METALLIC0. Saved diagnostic eye shaders.
Guard clean4.733s. Viewed000 marker coverage corresponds to visible eyes.

Measured two largest B>250 connected components. Idle10478/10511pixels,
centers(339.7,452.5)/(679.2,451.4); NdotV p05/median/p95 left
.702/.949/.996, right .710/.949/.996. Source response>0.1 covers
.61%/3.69%; >0.5 covers.19%/1.29%. At090 source>0.1 covers1.81%/4.55%;
at1801.28%/3.95% (ordered image-left/right). Quantized8-bit diagnostic,
not photometric irradiance or curvature reconstruction. An initial R<250 mask
was discarded because it excluded near-facing normals and biased coverage.

Evidence: visible shading normals are not uniform, but tested narrow source
overlap is sparse. This does not validate mesh curvature/imported normals;
NdotV includes viewing-direction variation. Next measure full reflected-vector
distribution and place shared source from that evidence before resculpting eyes.
No production geometry changed; no temporal/performance/reference acceptance.

## JX/JY — reflected-vector measurement and data-selected source direction

JX extends JW, encodes world reflected vector r*.5+.5 via inverse-sRGB emission.
Uses JW's two largest blue-marker components as pixel masks at each matching
frame. Decoded vector length p01/p99 approximately .995/1.004, consistent with
8-bit quantization; normalized before CPU source evaluation. Mean vectors idle
left(-.197,-.159,.753), right(.193,-.149,.757). Recomputed original narrow
source coverage>0.1=.63%/3.71%, close to JW .61%/3.69%, a useful decode check.
JX guard clean4.675s. No geometry or camera change.

Bounded CPU grid search directions(x,y,1), x=-.4..+.4 step.1, y=.1..+.9 step.1,
maximized minimum coverage across both eyes at000/090/180. Best grid direction
(0,.3,1), six coverages6.63/6.56/7.16/6.49/6.79/6.57%. This is a placement
heuristic, not a visual quality metric, global optimum or observed JY GPU coverage.

JY extends JV changing only shared front direction(-.45,.7,1)->(0,.3,1) on body
and eyes. Guard clean5.430s. Viewed000: two eye glints now more balanced and
readable, but body gains central pink patches around pore/mouth. No reference
acceptance; this illustrates why maximizing eye coverage alone is insufficient.
Preserve measurement and render. Next needs joint body/eye appearance judgment,
not more eye-only coverage optimization. All versions and production preserved;
continuous motion/performance and interior fluid-depth requirements remain open.

## JZ — absorption hue adjustment improves local median, not depth variation

Compared bbox-normalized central belly ROI x.35–.65,y.62–.75 in original
reference and JY idle (boxes from JN/JO). RGB p25/50/75 reference
(206,49,0)/(217,58,1)/(232,69,1); JY(208,44,1)/(212,46,1)/(214,50,8).
Not registered anatomical points or intrinsic material measurements: illumination,
pose and reference processing remain unknown. ROI exposes both hue and variation
differences, not a universal material target.

gel_absorption_balance_jz extends JY, only extinction green coefficient2.5->2.1
in measured-path Beer throughput. Red.45/blue6 and flow density unchanged.
Guard clean5.037s; viewed000 color moves toward orange but remains visually flat.
JZ same ROI(208,51,1)/(212,54,1)/(214,58,8): green median closer to58 reference,
but red IQR still6 vs26 reference, green IQR7 vs20. No claim of accurate liquid
optics from matching an ROI median. Existing pink reflections remain. Preserve
as hue candidate, not promotion. Next inspect spatial density/illumination
variation and internal depth rather than extending the light-placement-only loop.
All production/older versions preserved; continuous fluid motion and GPU gates open.

## KA — local density variation is small despite global variation

gel_density_diagnostic_ka extends JZ, replaces fragment final output with
R=local_thickness/2, G=jc_density/2, B=jc_valid, inverse-sRGB data emission.
Replaces light function with zero accumulators. Retains actual8-sample flow,
depth matching and face occlusion. Guard clean4.518s; viewed000 diagnostic.

Decoded valid(B>250) body pixels, 8-bit step2/255. Thickness/density p05/50/95:
000(.149,.612)/(.573,1.255)/(.855,1.341);
090(.149,.620)/(.573,1.239)/(.855,1.341);
180(.149,.627)/(.573,1.176)/(.855,1.333).
Idle central belly ROI from JZ p25/50/75:
(.824,1.278)/(.847,1.286)/(.871,1.294).
Thus global density varies, while this specific belly region has very little
variation (IQR about.016, only two data-code steps). Not evidence that all flow
is absent or that density alone explains reference appearance. Quantization
limits precision; depth is nearest backface interval, not full ray peeling.

Next inspect threshold saturation and raw versus mapped slime/laminar fields
before increasing density contrast. Preserve single connected character; do
not introduce detached cells as a substitute for continuous internal variation.
No production changes, physics-fluid claim, animation acceptance or GPU profiling.

## KB/KC — saturation exists, but shifting threshold does not restore variation

KB extends KA; RGB diagnostic outputs ray-mean raw slime signal, normalized
mapped slime, and fraction of8 samples above upper smoothstep edge. Uses KA
valid mask for whole-body statistics. Parameters saved: threshold.48, softness.18,
strength.82, scale3, laminar strength.78/scale1.55, flow strength.82.
KB guard clean4.786s. Idle belly p25/50/75 raw .804/.827/.843, mapped
.953/.965/.976, saturation .749/.749/.875 (8-bit approximation of6/8 or7/8).
Whole-body raw medians000/090/180=.627/.635/.596, mapped.933/.902/.831.
Saturation is real locally, not uniform throughout the body.

KC extends JZ beauty, shifts only JE ray-sample smoothstep threshold+.20
(.48->.68, upper edge.668->.868); leaves surface fields/material uniforms alone.
Guard clean4.321s. Viewed000 remains flat; body hue slightly brighter/oranger.
Same belly RGB p25/50/75=(210,56,1)/(214,58,1)/(215,61,8). Median green now
matches reference58, but IQR5 vs reference20, red IQR5 vs26. Thus threshold
shift is not a demonstrated detail/depth fix. Saturation diagnosis alone did
not justify expecting recovered spatial variation in the final light response.
Next separate the mapped-density variation from the final lighting/budget
compression before more threshold tuning. No production promotion; preserve all
tests and versions. Snapshot tests do not prove fluid motion or GPU suitability.

## KD — direct-light budget demonstrably compresses local red variation

gel_light_budget_kd extends KC. Final body EMISSION0/ALBEDO1, specular accumulator
zero; light function encodes summed raw scaled_body_light.r in R and summed
peak-limited red in G, both*.125. Read PNG sRGB back to linear then*8. Face
shaders unchanged; use KA visible valid-body mask. Guard clean4.772s.

Idle belly ROI raw/capped p25/50/75=(.5629,.5184)/(.6095,.5330)/(.6418,.5478).
IQR .0789->.0294, about63% reduction. This is direct red contribution only,
not final image contrast or whole optical response. Quantized8-bit data limits
precision. No clipped ROI channels. Whole valid-mask diagnostics have20/44/26
clipped channels at000/090/180, so global maxima cannot be inferred from these
captures; rerender lower diagnostic gain for tail analysis. Whole idle medians
raw/capped .8369/.5937. Do not treat clipping in diagnostic as beauty clipping.

This supports testing a less compressive direct-light response, with exposure
and highlight safety checked, before adding more density texture. It does not
prove removing all budgets will match reference or be stable. Current physical
path, refraction omissions, density and reflection issues remain. All production
and prior versions preserved; no visual/animation/performance acceptance.

## KE — later direct soft knee brightens without recovering belly contrast

gel_direct_knee_ke extends KC. Adds independent direct-light limiter using same
exponential rolloff and same budget but knee fraction.15 versus original.35;
only direct DIFFUSE_LIGHT calls new helper. Other limits/highlights unchanged.
curve.json records actual old setting. Guard clean4.665s. Viewed000 remains flat.

Belly RGB p25/50/75 shifts KC(210,56,1)/(214,58,1)/(215,61,8) to
KE(216,58,1)/(220,60,1)/(221,63,8). Red/green IQR still5/5. Valid-body pixel
fraction with any channel255 rises00021.40->22.23%,09021.93->22.74%,
18021.57->22.36%. All-channels255 stays approximately.31/.33/.39% respectively.
These are encoded endpoint counts, not HDR clipping magnitude or a complete
exposure metric. No improvement in selected local contrast; reject promotion.

KD compression evidence does not imply changing knee alone restores reference
detail. Next revisit incident illumination/path distribution and contributing
light components rather than continuing knee/threshold tuning. Reference includes
surface detail and unknown illumination; its ROI variance is not exclusively
fluid density. Preserve all candidates, production untouched. Full goal remains
unmet: wet reference appearance, internal motion/depth, all-animation integrity
and actual GPU/runtime integration are not established by these snapshots.

## KF — light decomposition locates central transmission deficit

gel_light_components_kf extends KC, env selects body/transmission/remainder.
Body=body_lit (includes wrapped/deep contribution), transmission=glow+xmit.
Both retain original full-sum peak-limit scale per light, not independently
rebudgeted; EMISSION and specular zeroed. Remainder zeros direct diffuse but
keeps all original EMISSION/specular (not solely reflection). Faces unchanged.
Guards clean4.398/3.897/3.651s. Viewed body/transmission idle: transmission is
concentrated at edges; body term carries the opaque-looking central color.

Linear decoded three-component sum vs KC idle on KA body mask and baseline
channels<.98: mean absolute error.001062,max.010293, consistent with approximate
8-bit decomposition, not exact HDR additivity proof. Unchanged faces excluded.
Central belly mean linear RGB: body(.52609,.03235,0), transmission
(.001352,.000177,0), remainder(.14168,.01816,.009899). Transmission supplies
about.20% of summed red in this ROI; body about78.6%. This is a selected region
under this rig, not whole-character/global energy accounting.

Next inspect thin-part gating (v_hot) and incident-path assumptions in glow/xmit.
Reference-like interior lighting cannot be inferred from bright rim alone.
Do not blindly brighten transmission or assert physically correct scattering:
current paths remain camera-oriented nearest-backface bounds. All versions and
production unchanged; live fluid motion, geometry/animation and GPU gates open.

## KG — removing transmission thin gate only overbrightens the core

Inspected hot: powered glow_band built from thin_floor/Fresnel/curvature, times
optional feature AO gate. This is not measured light-path thickness. Both glow
and xmit multiply it; local exposure also uses it. gel_transmission_gate_kg
extends KC removing v_hot only from xmit; preserves thin glow, angular t,
view-path absorption, budgets/exposure and all geometry. Guard clean4.779s.

Viewed000: substantially brighter yellow/orange body but still flat, not accepted.
Belly RGB p25/50/75 KC(210,56,1)/(214,58,1)/(215,61,8) ->
KG(241,75,1)/(243,78,1)/(246,81,8). IQR remains small5/6. Thus gate strongly
affects central transmission amount, but bypass does not create internal depth.
Retain as an ablation; no production promotion or all-poses safety claim.

Next establish incident/light-direction path bounds. Existing attenuation follows
camera front/back and t=pow(dot(VIEW,-normalize(LIGHT+NORMAL*distort)),power),
not a measured path from light to scattering points. Do not label gate removal
as real fluid optics. A light-space thickness study is needed before integrating
an internal-light model. Old versions preserved; live runtime/performance and
reference quality remain unresolved.

## KH — directional-light front/back depth snapshots established

Added identity _depth_shader_code hook to JB; default returns original code so
existing harness behavior is retained. KH overrides only length(VERTEX) depth
metric with -VERTEX.z. Orthographic camera uses JC second directional light
Euler(-25,150,0), target(0,.6716,0)+basis.z*4, size2.5, near.05/far8. Captures
same controlled deformation snapshots and body mesh via JB/IT; face meshes are
excluded as in original depth study. Stores light-camera.json basis/position.
RGB24 encoding range0..8 retained. Native guard clean3.590s.

Frame000/090/180 coverage259217/265230/260655; front/back mismatches0, negative
thickness0. Occupied bounds safely inside1024 canvas (overallx203..821,y212..815).
Depth range approximately3.346..4.842, inside clip/encoding range. Thickness
p05/median/p95 respectively(.1496,.6695,1.1108),(.1474,.6714,1.1077),
(.1494,.6691,1.1069). These are light-projection populations, not registered
comparisons to camera-space thickness values. No exact mesh intersection check
or multi-interval guarantee; nearest backface pair can miss air gaps.

Next project internal sample positions into this light basis and validate entry
depth before computing incident attenuation. Entry-to-sample distance is not
the whole front/back thickness. This turn establishes data only; does not change
beauty or runtime integration, and does not prove correct scattering/refraction.
Production and all prior artifacts preserved; reference/motion/GPU gates open.

## KI — camera-to-light interval containment audit

Added tools/meshy/check_incident_paths_ki.py. Reconstructs JO perspective rays
at a stride8 pixel-centre lattice, takes eight midpoints per front/back interval,
and projects them into KH's orthographic basis. Verifies matching original shader
prefix hash, frame/time/lag/transform metadata, and orthonormal light basis.
Records source depth SHA256 hashes in incident-paths-ki.json; exclusive output
creation preserves earlier reports. Python run completed successfully.

Frames000/090/180: 76144/77816/76456 samples, none outside the light map,
7/5/0 missing light-depth pairs. Strict interval containment is
96.1901%/95.8402%/96.0879%. With .005 world-unit tolerance (about two light-map
pixels), containment is96.3333%/95.9983%/96.2318%; after-exit counts remain
2784/3105/2874, before-entry counts1/4/7. Thus relaxing raster tolerance does
not remove the discrepancy. Median valid entry-to-sample distances are about
.341/.344/.340, not the whole KH interval thickness.

This exposes a failed prerequisite, not accepted fluid optics. Nearest backface
intervals, occlusion/multiple surfaces, camera interval occupancy and reconstruction
error remain possible causes; matching metadata does not prove exact geometry
correspondence. Investigate failed sample regions and independent intersections
before adding incident attenuation to beauty. No production material changed,
no image improvement claimed, all versions retained. Visual, motion, GPU and
release acceptance remain open.

## KJ — failed light intervals localize to lower appendage region

KI script now has optional --localize mode producing a separate exclusive
incident-regions-kj.json, retaining KI output and default behavior. Same counts
reproduced. At tolerance.005, after-exit excess p05/median/p95 is approximately
(.104,.325,.525),(.100,.321,.525),(.101,.323,.520) for frames000/090/180.
These are substantial distances, not just depth quantization. Median distance
from the light silhouette is59.4/59.8/60.5 pixels. Even taking the maximum exit
over a5x5 neighborhood leaves2284/2599/2368 failed points; this operation is
diagnostic only and must not become an artificial thickness correction.

Camera-grid failures cluster in lower lateral/foot regions (mostly y640..1023);
world-space y p05/median/p95 is roughly .05/.175/.375. Directly inspected KC
measured-000 and reference: these correspond broadly to appendage/lower-body
regions, but no exact anatomical segmentation is claimed. Pattern supports
investigating multiple ray intervals/occlusion before increasing map resolution.
It does not yet distinguish real air gaps from missing later occupied intervals.

Fresh visual comparison still shows a flat orange central mass, disconnected
pale polygonal highlights, weak eye reflections/rims and different foot/arm
silhouette versus the reference's continuous wet facets and stronger optical
depth. A correct light interval representation alone will not solve all these
differences. Next independent intersection/depth-peeling check must distinguish
later occupied segments from air; do not merely accept farthest-back thickness.
No production promotion, material edit, or visual acceptance this turn.

## KK — second light interval explains most after-exit samples

Added no-op _configure_depth_material hook to JB, called after shader/time
assignment. New isolated gel_light_peel_kk harness extends KH and rejects
fragments at or before the corresponding first-exit depth+.0001. Samples
the preserved KH RGB24 depth with nearest filtering, no source_color transform.
Original deformed vertex prefix and three snapshot states retained. Native
Vulkan guard completed cleanly in4.134s (not a GPU timing measurement).

Second front/back coverage:13714/13714,14960/14960,14042/14043. Mask mismatch
0/0/1; reversed pairs0 throughout. CPU --peel analysis produces separate
incident-peel-kk.json: of2784/3105/2874 former after-exit failures,2781/3099/2866
fall within the second interval at.005 tolerance (99.89%/99.81%/99.72%).
Gap counts1/1/3, beyond-second0/5/1, no-second-pair2/0/4. This strongly identifies
missing later occupied intervals as the dominant cause, not a global coordinate
offset. Residual edge/interval cases remain unresolved; not independent exact
triangle-intersection proof or exhaustive interval coverage.

Next incident attenuation should sum occupied segment lengths up to each
sample, excluding the air gap between intervals. Do not use first-entry to
last-exit distance as material thickness. Additional intervals must be checked
before claiming a complete representation. This shader-skill-guided diagnostic
does not change production beauty; reference matching, liquid motion, geometry
quality and GPU acceptance remain open. All existing versions preserved.

## KL — occupied-segment distance implemented and unit-tested

Added occupied_distance CPU reference implementation to KI tool and --segments
mode with separate incident-segments-kl.json. Sum clamped distance within each
ordered non-overlapping interval; missing/reversed/overlapping second intervals
are not accumulated. Invalid cases are not silently accepted as optical evidence.
Five unittest cases pass: air-gap plateau, absent second interval, invalid first,
overlap prevention, reversed second. Tested via unittest discover in tools/meshy.

Strict sample containment in either interval is76008/76144,77667/77816,
76312/76456; unresolved136/149/144 are excluded from metrics, not repaired.
Median occupied light distance is.3502/.3543/.3496. For samples strictly in
the second interval, subtracting the air gap removes median.11235/.10809/.11172
world units compared with first-entry-to-sample distance (p95~.30). This confirms
that simply extending to the farthest backface would materially overcount
absorbing material. Assertions check nonnegative lengths and no excess over
naive distance on accepted samples. All source depth hashes, including second
interval maps, are recorded for the new report.

This is a geometric CPU reference, not density-integrated optical depth or a
rendered improvement. Shader integration must match this segmented calculation,
retain an explicit unresolved-sample policy, and evaluate the flowing density
along the incident segments; two intervals are not proved exhaustive. Existing
versions and production materials unchanged; full reference acceptance remains
unmet.

## KM — first segmented-incident scattering render, not visually accepted

New isolated gel_incident_scatter_km extends KC. Binds KH/KK frozen depth maps
per snapshot with nearest/no-source-color sampling; projects the undeformed-by-
advection world sample into the recorded light basis. Strictly rejects samples
outside either ordered interval, sums occupied distance without the air gap.
Eight view samples retain KC advected density and accumulate midpoint view
optical depth. Prototype incident extinction assumes density1 along the incident
segments; sigma(.45,2.1,6), isotropic source3.5/(4PI), scalar scattering
coefficient1. Adds this result to EMISSION without replacing existing surface
terms. Thus it is deliberately not energy-conserving full transport and is not
a completed flowing incident-density model. Frozen maps, no runtime integration.

Native Vulkan guard clean5.634s; saved control/measured frames000/090/180.
Inspected measured000 directly: mainly brighter, still plastic/flat, with pale
patches and weak eye treatment. Against KC idle whole-image mean absolute RGB
code delta6.286, max43. Fixed pixel ROI y650:750,x400:600 meanRGB changes
(215.03,64.94,10.09) to(235.33,79.25,11.05); this is brightness evidence, not
reference matching. Control mode lacks measured-flow integration as inherited
from JC; KC measured is the proper frozen appearance baseline for this addition.

Do not promote. Next needs incident density integration and surface/volume
energy allocation rather than adding more light. Shader skill guided separate
sampler/material handling. Production assets and earlier versions unchanged;
reference, motion, GPU and full geometry gates remain unmet.

## KN — shared flowing density integrated along incident segments

New isolated gel_incident_density_kn extends KM. Extracts the exact KC advected
density block into kn_density helper, passes phase/motion/axes explicitly, and
integrates four midpoint samples per occupied incident segment. Reconstructs
positions toward the light from sample z; excludes the air interval. View-side
eight-sample density integration unchanged. All source intensity, surface terms
and additive volume allocation remain KM's for a one-variable comparison.
No physical energy-conservation claim; scalar scattering1 still exceeds red
extinction. Sampling convergence, full interval coverage and runtime cost open.

Native Vulkan process clean5.384s. Directly inspected measured000: still flat
plastic-orange with isolated pale facets; not a reference-quality improvement.
Compared with KM idle, whole-image mean absolute RGB code delta1.156, max12;
central ROI y650:750,x400:600 mean changes(235.327,79.245,11.047) to
(235.248,79.081,10.956). Thus a more coherent incident-density calculation does
not by itself fix the dominant appearance mismatch. Avoid further density-only
tweaks as a presumed solution; surface/volume allocation, continuous wet normal
structure and eye geometry/reflections remain visible problems.

Shader skill guided shared field and sampler separation. Saved three controlled
snapshot pairs, not animation acceptance. Existing production and versions
unchanged. Do not promote KN; next address energy allocation explicitly and
check incident integration convergence before expensive runtime adoption.

## KO — surface/volume allocation ablation remains visually insufficient

New gel_energy_split_ko extends KN. Halves body_lit before the existing direct
budget (including wrapped deep-color contribution), leaves glow/xmit/reflection
terms unchanged. Changes scalar scattering coefficient1 to.35, below all
extinction channels(.45,2.1,6), removing negative implied absorption from the
isolated volume term. This does not make the entire legacy material globally
energy-conserving. Two coordinated allocation changes, not separate attribution.

Native Vulkan guard clean5.264s and three controlled snapshot pairs saved.
Direct visual inspection of idle shows predominantly a darker central mass,
with the same disconnected pale facets and weak eyes. No reference-quality
gain sufficient for promotion. This refutes treating brightness redistribution
alone as the remaining solution. Continuous wet surface structure and reflection
shape now deserve priority over more density/intensity parameter sweeps.
Shader skill used for isolated material changes; production and all earlier
versions retained. Motion, optical integration convergence and GPU cost remain
unverified, as do overall reference/geometry acceptance gates.

## KP/KQ — scalar-height gradients replace independent random normal field

KP branches from KC, not the rejected brightness/scattering experiments.
Replaces jp_field with negative analytic gradient of normalized Gaussian-weighted
scalar random heights. Quotient derivative includes both weight and weighted-
height derivatives. Retains125 neighboring centers, scale48, tangent projection,
normal amplitude.045 and derivative fade from JRcombined. Geometry is unchanged.
Native guard clean5.310s; direct idle inspection shows more connected microrelief
on forehead and feet, but overly hard scale-like ridges. Not accepted.

KQ widens the height kernel exponent8 to3 and consistently changes derivative
coefficient16 to6, preserving all other settings. Guard clean4.563s; independent
three-state depth/beauty captures preserved. Finite neighborhood truncation means
global mathematical continuity is not guaranteed, especially with broader tails;
boundary continuity and temporal shimmer require checks. These are normal-only
surface experiments, not physical mesh smoothing or refraction. Shader skill
guided scalar-field implementation. No production promotion or deletion.

## KR/KS — shared elongated source and radiance comparison

KR extends KP's height gradient. Replaces only third reflected source direction
(0,.30,1) with(-.60,.50,.60), Gaussian widths(.12,.16) with(.22,.50), keeping
peak radiance4. Body and both eyes use identical input source; old contour
sources retained. Angular integrated power changes with source size. Native
guard clean5.853s. Inspected idle: source becomes a connected left-side ribbon,
but pale pink response and hard relief remain; eyes still dim. Not accepted.

KS changes only that source peak4 to40, identically in body and eyes, preserving
legacy response caps. Guard clean6.108s, controlled three-state captures saved.
This is a radiance-response diagnostic, not physically calibrated illumination
or a release candidate. No global exposure change. Body rational limiting and
eye peak cap differ, so identical source does not imply identical response.
Shader skill guided shared-source changes. Existing versions retained and no
production promotion. Full reference and animation/performance gates stay open.

## KT — lower normal amplitude reduces harsh ridges, not full visual acceptance

New gel_shallow_relief_kt extends KS and changes only final normal amplitude
.045 to.015. Same scalar field/kernel, frequency48, fade, source radiance40,
body/eye settings, mesh and frozen flow snapshots. Native guard clean5.081s.
Directly inspected idle and frame090: hard scale edges are reduced and the
left reflection is smoother, but a broad pale ribbon still dominates, central
body remains optically flat, and eye reflections are simple streaks rather than
the reference's layered glass reflections. Not accepted or promoted.

This supports excessive normal amplitude as a contributor to hard relief, not
as the sole mismatch. Three isolated snapshots do not verify shimmer during
movement. Next needs temporal inspection and reflection-source extent control;
do not report the visual lock or fourteen-animation gate passed. Shader skill
guided the isolated normal change. All prior versions/production preserved.

## KU — consecutive start-transient capture and sequence artifact

JB gets a _depth_capture_frames hook defaulting to original[0,90,180]. KU
extends KT and captures every simulated frame25..55. Preserves fixed actor root,
frozen AnimationPlayer and existing update_liquid_flow input step at frame30.
31 paired depth/control/beauty frames saved. Native guard clean18.488s; offline
render duration is not FPS. check_temporal_ku verifies exact frame sequence and
frame/60 timestamps; all31 depth masks match, negative pairs0. Largest adjacent
common-mask mean absolute RGB code change8.764 occurs at frame31, p99=120.
Not motion-compensated; this cannot distinguish deformation from shimmer.

Encoded original measured frames at60fps to temporal-ku/start-60fps.mp4 using
ffmpeg, no interpolation or retouching. Duration31/60s. PNGs are authoritative;
H264 is a review convenience. Actual root locomotion, all14 animations, stop/idle
cycles, frame-rate performance and temporal visual acceptance remain open.
Testing skill kept data assertions distinct from visual acceptance. Next inspect
start transition with motion/normal controls before claiming stable reflection.
All prior versions and production preserved; goal remains incomplete.

## KV — no-relief temporal control retains the dominant start transient

New gel_temporal_control_kv extends KU, replacing only final perturbed normal
with base_n. Same31-frame schedule, lights, density, deformation and eye shaders.
Native guard clean18.892s. compare_temporal_kv verifies all62 front/back PNG
hashes match KU exactly, and frame metadata matches. Paired temporal analysis
uses common body projection mask (includes face pixels), not material tracking.

Both candidate and no-relief control peak at frame31: mean absolute RGB code
changes8.7641 vs8.6288. Difference of signed temporal changes has mean absolute
1.6514 at that transition, averaged over all30 transitions.8237. These numbers
are not additive attribution percentages. Dominant global start change remains
without new normal detail; do not label it solely microrelief shimmer. Residual
includes intended moving details as well as possible artifacts. Localized shimmer
has not been excluded. Next examine step-input/deformation response around30/31
and track material points before adopting temporal smoothing as a fix.

Shader skill guided the isolated ablation. All outputs retained; production
untouched, full visual/motion acceptance open.

## KW/KX — start test was also a ninety-degree turn

Graph lookup unavailable for IMMUNE; read character_root.gd locally. Runtime
flow already uses exponential motion mix and a damped lag spring. KW traces
uniforms over frames25..35 in the same setup, saving runtime-trace.json.
Before30 flow direction(0,0,-1), velocity0. At30 requested velocity becomes(4,0,0),
direction starts steering, turn shear.00882 then.02781 at31; squash.00716 then
.01647, lag only-.000469 then-.001347. Contact remains0. Native guard4.686s.
Thus KU's start transient mixes start and a turn relative to initialized flow
direction; it is not a pure straight-start test. This is test interpretation,
not sufficient evidence of a production movement bug.

KX extends KU but seeds flow directionRIGHT in isolated setup and force-sends
uniforms before simulation, retaining actual speed step and response code.
Native guard18.839s,31 consecutive frames saved. Sequence checker now accepts
explicit --folder aligned-start-kx while preserving KU default. Masks/negative
depth pairs0. Largest common-mask mean absolute code change is1.3394 at30,
p99=15, compared with KU8.7641 at31,p99=120. Large transient is strongly
associated with initial direction/turn response; do not suppress relief as its
presumed cause. Not motion-compensated temporal acceptance, real locomotion,
or full fourteen-animation testing. Follow-up should separate turn/start/stop
scenarios and inspect their visual continuity rather than smooth everything.
Debugging skill enforced trace before changes; production unchanged, all
versions preserved, overall appearance still short of reference.

## KY/KZ — separated stop and constant-speed turn captures

JB adds _depth_velocity(frame), default preserving original speed schedule.
KY extends aligned KX, captures115..145 around speed4-to0 at120. KZ extends
KX, captures85..115 around right-to-forward90degree velocity change at90,
constant speed4. Actor root/camera remain fixed, AnimationPlayer frozen. These
are shader response tests, not navigation or complete walking animations.
Existing default harness behavior retained; new exclusive output directories.

Native guards KY18.756s, KZ18.039s clean. Sequence checker extended with explicit
scenario/frame ranges. Both31-frame sets have0 mask mismatches/negative depth
pairs. KY largest common-mask mean absolute RGB code change1.1703 at135,p99=16.
KZ largest5.7020 at100,p99=76. Aligned start KX was1.3394. Different trajectories
and phase times mean these are diagnostic populations, not calibrated quality
scores. Inspected KY125/KZ095: intact silhouette in those views, broad pale
reflection still dominant. No continuous-motion visual acceptance claimed.

Turn response deserves separate inspection from start/stop; do not globally
blur/suppress wet detail based on the mixed KU input. Testing skill guided
deterministic separated scenarios and data/visual distinction. Disk approx13GiB
before capture; no previous assets removed. Reference appearance, real gameplay
motion, all14 animations and GPU acceptance remain unresolved.

## LA — compact source reduces ribbon but reintroduces isolated patches

New gel_compact_reflection_la extends KT, changes third-source widths(.22,.50)
to(.22,.22) identically for body and eyes. Direction and peak40 unchanged;
angular integrated power decreases. Geometry, relief, base color/exposure held.
Native guard clean6.206s; saved three controlled snapshot pairs. Direct idle
inspection: broad ribbon reduced, but separate forehead/mouth/foot glints recur,
eyes dimmer. Not a sufficient reference improvement and not promoted.

This bounds the source-width tradeoff: broader source produces a dominating
ribbon, compact source exposes isolated curvature-driven lobes. More width-only
sweeps are not justified as the full solution. Revisit local surface curvature
and eye/rim geometry versus reference, while preserving established material
controls. Shader skill guided shared-source isolation. Existing versions and
production unchanged; overall visual, motion, GPU gates remain open.

## LB — projected face landmarks expose proportion mismatch

Freshly viewed reference and LA idle. Added compare_face_landmarks_lb.py:
fixed interior ROIs, largest dark connected component, fill internal holes,
centroid/bbox/PCA, max-channel thresholds40/60/90 for sensitivity. Output
face-landmarks-lb.json includes source hashes. This measures projected dark
features, not3D curvature or exact silhouettes; reflections can bias masks.
No exact camera/pose registration, but body image heights are approximately
matched. Production GLB hash still3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3.

Threshold60: reference eye centers(358.43,467.33)/(705.08,460.94), candidate
(341.90,455.12)/(681.41,452.80). Reference mouth center(538.69,549.91), candidate
(510.78,591.55). Eye-midpoint-to-mouth vertical distance85.78 vs137.59px;
threshold sweep85.62..85.93 vs136.74..138.65, so not just mask threshold.
Mouth dark width38..43px reference vs65 candidate. Eye principal image-axis
angles at60 reference+36.97/-43.93deg, candidate+26.37/-33.18deg; exact angle
varies with highlight masking, but reference eyes remain more steeply inclined.
Global horizontal framing shift must not be mistaken for asymmetric geometry.

This provides a concrete higher-priority geometry target: mouth placement/size
and eye inclination before further lighting sweeps. Any correction must move
body cavity/rim and matching attachment consistently, not float the mouth mesh
away from its sculpted socket. Independent side-view evidence still needed for
depth/curvature claims. No geometry edited this turn; all versions retained.
Overall appearance, motion and release gates remain incomplete.

## LC — coherent local mouth warp improves projected proportion, provisional

Added gel_mouth_proportion_lc extending LA. First run stopped at identity-mouth-
transform assertion(line27); failure log preserved in mouth-proportion-lc-guard.
Investigated before retry: attachment transform is nonidentity. r2 computes one
world-space warp then transforms back per mesh; normal transform uses local
Jacobian inverse transpose, tangents reprojected. Body/BodyShell/MouthCavity get
new ArrayMeshes saved only under mouth-proportion-lc-r2; faces cache updated so
JC restores the corrected mouth, not original. Topology/UV retained; no blends
allowed. Shader-deformation coordinate anchoring after rest warp still needs
verification; no claim of globally collision-free animated geometry.

Warp center(0,.634704,.354426), upward.080, core Xscale.60, radial smoothstep
support(.20,.22,.18), plateau to normalized radius.35. Samples have minimum local
Jacobian determinants Body.1417,Shell.1340,Mouth.6000; affected vertices
8464/8345/257. Positive sampled determinants exclude local inversions at sampled
vertices only; substantial compression, between-vertex folds/intersections and
surface triangulation still need checks. Native retry guard clean3.629s.

Fresh idle inspection and LB landmark checker: mouth dark width38px vs LA65
and reference39; eye-midpoint-to-mouth distance89.20 vs LA137.59/reference85.78.
Mouth center(508.95,543.16), dark height12 vs reference8; eye masks unchanged.
Mouth aspect/curvature not yet matched. Warp creates stronger adjacent reflection;
side view and animated attachment coherence remain unverified. This is concrete
projected geometry progress, not full visual acceptance. 3D skill guided shared
coordinate treatment. All original assets/versions preserved, no promotion.

## LD/LE — oblique view exposes shared pre-existing large planar artifacts

LD extends corrected LC, rotates camera45deg around target(0,.6716,0), retains
distance/FOV, and replaces JE's ray origin with the new camera position. Fresh
depth pairs ensure camera/depth correspondence. Camera skill guided matched
coordinate update. Native guard5.131s clean; viewed idle and frame090.
Mouth is smaller/higher, but major diagonal planar color boundaries cross the
lower torso and unnatural overlapping-looking arm contours appear. Side-view
acceptance fails; normal determinant checks were not enough.

Created LE with identical view/ray-origin change, extending unwarped LA.
Guard3.033s clean; viewed idle shows the same large lower-torso planar boundary
and arm appearance. Therefore these artifacts are not newly caused solely by
LC mouth warp. Root cause remains open: geometry versus shader/interpolation/
surface handling must be isolated with a neutral material retaining deformation.
No claim of true duplicate geometry or intersections yet. Existing reference
image is frontal, so this is artifact detection, not side-reference matching.
All original assets and candidates retained; production untouched. Prior frontal
improvements remain provisional, full visual/motion/GPU gates incomplete.

## LF — neutral material separates shading defect from shape defect

Added gel_side_clay_lf extending LE; body shader retains original deformed vertex
prefix/time uniform and uses standard lit grey fragment(.35 albedo,.85 roughness,
.2 specular), no custom light/gel fragment. Same cull_back as LE, same mesh,
camera, lights and snapshots. Eyes/face attachments retain existing materials.
Native guard4.536s clean. Direct idle inspection: broad diagonal planar color
boundary is absent on grey body, but layered/extra-lobed arm profile and underside
shape persist. Thus distinguish custom-material shading artifact from actual
shape mismatch; do not describe both as one geometry failure or fix with lighting.

Shader skill guided preservation of deformation while isolating fragment/light.
This grey render does not prove watertightness, no intersections or acceptable
anatomy. Existing versions preserved and no production edits. Next narrow gel
fragment/light pathway using preserved controls and separately audit side mesh
lobes. Overall reference and release readiness remain incomplete.

## LG — measured optical branch implicated, validity switching not visible cause

Viewed preserved LE control-000: large diagonal torso color boundary is absent
when jc_measured is false, unlike LE measured-000. This narrows the artifact to
measured thickness/density and their downstream shading, not generic gel lighting.
Added isolated gel_depth_validity_lg: same LE camera, vertex deformation and fresh
depth pairs; unshaded body green for the exact jc_valid condition, red otherwise.
Native guard clean4.404s; idle image is green across torso with no corresponding
diagonal validity boundary. Face attachments remain original materials. Therefore
the large beauty boundary is not explained by visible validity/fallback switching
in this snapshot. Validity only checks depth ordering/front agreement; it does not
prove the back surface or optical path is physically correct. Next inspect back
depth/path continuity and separate density integration from thickness-dependent
shading. No production changes, no visual acceptance, all versions retained.

## LH — constant density retains seam; back depth has large discontinuities

Added gel_constant_density_lh extending LE, replacing jc_density with 1.0 just
before throughput evaluation, leaving measured thickness, geometry, camera,
lights and downstream shading unchanged. Shader skill guided one-variable
isolation. Guard clean5.119s, three snapshots saved; directly inspected idle:
large diagonal torso boundary persists. Integrated animated density variation is
therefore not necessary for the defect. This is diagnostic, not a proposed
replacement for internal liquid flow.

Decoded preserved LE RGB24 radial depth on CPU. At row750 between x469/470,
front depth delta=-.00046, back delta=-.41282, thickness jump=.41236. At row800
x349/350, front delta=-.00203, back delta=-.50814, thickness jump=.50612.
These are interior points near the observed diagonal, not a global silhouette
edge. Back-surface selection/geometry now needs inspection, including additional
surface intervals; this does not yet distinguish erroneous internal faces from
legitimate multi-interval visibility. Do not blur the map or label depth validity
as physical correctness. All versions preserved; production untouched, reference
match and full motion acceptance remain incomplete.

## LI — oblique second interval confirms omitted occupied path

Added gel_side_peel_li extending LE, retaining camera/deformation and discarding
fragments at radial distance <= preserved LE first exit+.0001. Captures second
front/back only; deliberately skips beauty because second maps cannot replace
first maps directly. Shader skill guided isolated depth-pass changes. Native
guard clean4.197s. Ordered second interval pixels:34044/36773/34947 at0/90/180;
front/back mask mismatch0/3/1, negative paired interval0 throughout.

Idle at(x469,y750), first path=.935919 with no second interval. Adjacent x470
has depths4.289781,4.813336,4.855684,5.225237: first path=.523555 but summed
occupied length=.893107. Thus the previous .41236 jump becomes .04281 when
including the second occupied segment, excluding its air gap. At y800 x349/350
the original .50612 jump becomes .03464 (totals .732390/.697748).
This provides concrete evidence that a single interval omits material behind
the first exit near the observed seam. It does not yet prove topology correct,
eliminate all discontinuities, or demonstrate the visual fix. Next integrate
density independently over both occupied segments (not through the intervening
air) and verify beauty, residual seams and further intervals. No production
asset edits or promotion; all versions retained; overall quality goal incomplete.

## LJ — two-segment absorption removes inspected broad diagonal seam

Added gel_segmented_view_lj extending LE. Binds frozen LI second depth pairs for
matching frame/camera. Valid second interval must start beyond first exit and end
after its entry. Samples eight density midpoints per occupied segment, offsets
second samples from first entry to second entry (skipping air), and computes
length-weighted density. Total occupied length feeds absorption and downstream
macro-thickness shading. Original surface, reflection and vertex code preserved.
Shader skill guided isolated optical-path changes. Guard clean5.751s. All six
first-depth PNG hashes match LE exactly; control090/180 hashes also match, but
control000 differs and requires follow-up rather than claiming exact full control
equivalence.

Direct inspection of measured000 and090: the former broad diagonal torso color
boundary and associated arm color cut are absent. This is a visual improvement,
not just a numerical one. Material still reads too plastic/scaly, arm/foot shape
remains unsatisfactory, and tiny/residual discontinuities are not ruled out.
This uses frozen external depth maps, not a realtime game integration. Third
interval coverage, animated time continuity, sample convergence, front-view
regression and GPU cost remain unverified. Existing versions preserved, no
production promotion, overall reference-quality and motion gates incomplete.

## LK — repeat reproduces seam improvement, exposes first-frame variation

Added gel_segmented_repeat_lk, exact LJ inheritance with output-name-only change.
Guard clean3.597s. All six depth images and control/measured090/180 are pixel
identical to LJ. Idle control differs at2708 pixels(max channel18), measured at
1944(max16). Crucially LK control000 exactly matches original LE control000.
Thus the previously noted idle control difference can arise between identical
algorithm runs; it is not demonstrated to be caused by segmented absorption.
Root cause of first-frame variation remains open (do not assert shader warmup).

Direct LK measured000 inspection reproduces disappearance of broad diagonal
torso seam. Testing skill guided separating diagnostic repeatability from visual
acceptance: pixel comparisons are not a reference-quality test. Need stable
capture initialization before small photometric claims, plus further interval,
continuous-motion and runtime validation. No production change; all versions
retained, plastic surface/shape mismatch and overall goal remain unresolved.

## LL — third intervals sparse but not absent

Added gel_third_interval_ll extending LI with previous-exit map switched to LI
second back depth. Same camera and deformation; shader skill guided unchanged
depth-pass semantics. Guard clean2.288s. Added check_third_interval_ll.py with
source hashes and exclusive interval-audit.json output. At0/90/180 there are
9/7/15 ordered third-interval pixels, zero front/back mask mismatches and zero
negative paired lengths. Median lengths .01035/.10056/.05855, maxima
.40061/.61986/.65613 model units. Small screen coverage does not imply small
local error. No claim that two intervals are universally sufficient or that
these samples prove valid watertight topology; depth peeling epsilon/raster
edges still need investigation. Two intervals explain the broad seam, but
remaining sparse samples must be handled or bounded before runtime acceptance.
All candidates retained, production unchanged, reference/motion goal incomplete.

## LM — all observed third intervals lie on second-mask boundary

Extended check_third_interval_ll.py with --localize, preserving original report
and writing exclusive interval-localization.json with source hashes and every
sample coordinate, gap, length and Euclidean distance to absent second-front
pixels. Across all31 third-interval samples(9/7/15), this distance is exactly1px.
This localizes residuals to the second-surface mask boundary, rather than a broad
interior missing region. Gaps vary from .00027 to .28391; do not dismiss long
third segments as negligible solely because coverage is sparse. Debugging skill
guided explicit boundary hypothesis and tracing before changing behavior.
Raster/depth interpolation versus genuine tiny third geometry remains unproven;
supersampled or independent ray/triangle checks are appropriate next evidence.
Do not simply discard the third intervals. No render/asset modifications this
turn; all versions and previous audit outputs preserved, goal incomplete.

## LN — independent idle rays confirm genuine third mesh intervals

Added gel_ray_source_ln: exports actual runtime mesh vertices/indices, pixel-center
camera rays and idle deformation uniforms after update. Asserts identity body,
single surface, zero squash/motion/shear/contact/lag. Wobble remains enabled at
strength.012, scale2.4, phase.31. Guard clean2.341s. Added check_idle_rays_ln.py:
applies shader idle wobble formula to exported vertices, then double-precision
two-sided Moller-Trumbore intersections against all triangles, independently of
depth maps. Stores source hash, triangle IDs, ordered distances and orientation.

All9 inspected idle rays have exactly6 alternating oriented intersections,
confirming3 actual mesh intervals. Their distances closely track all6 raster
depths (largest observed discrepancy about .000237 model units). Therefore the
LM boundary localization does not justify classifying these as raster artifacts;
two intervals genuinely omit occupied mesh at these rays. This does not establish
watertightness/global topology or validate moving frames. Next support third
interval absorption or change geometry with independent verification; do not
discard boundary samples. Debugging skill guided coordinate/deformation checks
before independent comparison. All versions preserved, production untouched,
overall reference quality and motion goal remains incomplete.

## LO — third occupied segment included in candidate absorption

Added gel_three_segments_lo extending LJ. Binds matching frozen LL third pairs,
requires valid ordered first/second/third intervals, sums occupied lengths, and
uses eight density samples in each segment with its own entry offset. Air gaps
remain excluded. Shader skill guided isolated extension; previous versions and
production assets unchanged. Native guard clean5.644s.

Compared with LK, measured0/90/180 differ at5/5/10 pixels(max channel52/51/53).
Control090/180 identical; idle control retains known2708-pixel run variation, so
do not assert exact idle attribution. Direct measured090 inspection retains the
broad-seam improvement, but plastic/scaly surface and unsatisfactory appendage
shape remain. This is frozen-map diagnostic integration, not runtime acceptance.
Three is not proven a universal bound; further interval coverage, continuous
motion, convergence and performance remain open. Overall quality goal incomplete.

## LP — fresh per-frame three-layer start sequence, residual invalid pairs

Added gel_segmented_motion_lp extending LO; frames25..55 inclusive,60Hz simulated
step, direction initialized RIGHT to separate straight start from turning. Each
frame captures first pair then peels second/third pairs with same frozen time and
lag, before beauty. LJ/LO gained backward-compatible source-path hooks with old
defaults unchanged. Shader skill guided matching per-frame optical inputs.
Guard clean23.733s;31 complete frames, no realtime FPS claim. Added
check_segmented_motion_lp.py and exclusive sequence-audit.json. Common-mask
frame difference peaks at30: mean1.32234,p99=18 (not motion compensated).
There are3 negative paired-depth pixels across the sequence; do not call depth
validation clean. Shader validity rejects invalid ordering, but temporal effect
needs investigation. Direct frame031 inspection retains broad-seam improvement;
not a full animation visual acceptance. Still no root locomotion, full14-animation
coverage, realtime depth pipeline or GPU profiling. All versions retained,
production untouched, reference/motion quality goal incomplete.

## LQ investigation — independently peeled exit can precede next entry

Read preserved LP depth triples at the3 negative layer2 pixels. At frame43
(778,683), layers are [4.106885,4.446007],[4.451214,4.448777],
[4.451214,4.836091]. Layer3 repeats layer2 entry because layer2 exit is before
it. LO's valid3 depends on valid2, so both segments are rejected despite a
later exit. Same repeated-entry pattern occurs at frame38(222,400) and
frame39(241,697). This identifies a concrete capture-pairing weakness: front
and back independently discard only through previous exit, rather than matching
the back to the newly found front. Next candidate should seek exit beyond the
current entry, while documenting any skipped orphan exits/epsilon limitations;
do not merely clamp negative lengths or claim topology repaired.

At fixed pixel(778,683), RGB42/43/44=[197,64,0]/[208,89,1]/[196,64,0].
This is a local transient consistent with lost absorption, not motion-compensated
proof. Frame38 point emerges from background, so its black-to-orange transition
must not be described as pure shading flicker. Reference re-inspected: major
remaining artistic gaps are fine wet facet reflections versus scale-like relief,
layered glassy eyes, translucent golden contours and appendage proportions.
Depth cleanup is necessary but does not establish those visual qualities.
All artifacts preserved; no production changes or acceptance this turn.

## LR — paired exit search fixes targeted transient, broader acceptance fails

LP gained backward-compatible threshold-path hook; LR overrides back pass to
use current layer front instead of previous layer exit. Same .0001 discard
epsilon; does not reconstruct any skipped thin intervals or repair topology.
31-frame repeat guard clean23.856s. Extended sequence checker folder choice and
added compare_paired_exit_lr.py with exclusive regression-points.json.
Negative pairs3->0, though ordering is constrained by construction and alone
cannot prove correctness. At original frame43(778,683), corrected second exit
4.836091 follows entry4.451214; local RGB42/43/44 changes from
[197,64,0]/[208,89,1]/[196,64,0] to [197,64,0]/[196,64,0]/[196,64,0].
Thus the targeted brightness excursion is removed, not merely its error count.

Direct measured043 inspection still shows a diagonal tonal boundary on lower
torso, so prior snapshot seam improvement must NOT be generalized to all motion.
Investigate remaining path/density branch behavior; full continuous visual gate
fails. Plastic/scaly surface and shape mismatch persist. Shader skill guided
paired surface search rather than clamping negative lengths. All versions kept,
production unchanged; no runtime/GPU/reference acceptance claimed.

## LS — raising density quadrature does not remove residual tonal seam

Viewed LR control043: residual measured diagonal is not comparably evident in
control. CPU summed three ordered occupied paths has much smaller boundary
jumps than original single interval: row730 x530 .02603, row750 x469 .04580,
row770 x416 .02999 model units. Added gel_density_convergence_ls extending LR,
frame43 only,64 midpoint samples per occupied segment versus8 (192 iterations
maximum vs24), all offsets/weight denominators adjusted. Shader skill guided
one-variable precision comparison. Guard clean4.705s. Direct image inspection
retains diagonal boundary. LR-to-LS maximum channel difference1, image mean
.004441, torsoROI[300:650,650:820] mean.007272 on0..255 scale. This sampled
comparison strongly argues against coarse density quadrature as the visible
cause, not universal convergence proof. Do not ship higher sample count as a
quality fix. Next isolate downstream heuristic thickness darkening from actual
absorption/geometry-gap effects. All versions preserved, production unchanged,
reference and motion acceptance remain incomplete.

## LT — removing heuristic thickness darkening does not solve tonal seam

Added gel_no_macro_darkening_lt extending LR, frame43 only. Removed only the
body *=1-clamp(thickness_contrast)*macro_thickness expression; retained segmented
absorption, density advection, surface normals and lighting. Shader skill guided
single-contribution isolation. Guard clean4.725s. Direct measured043 retains
diagonal lower-torso boundary despite brighter body. LR-to-LT image mean absolute
difference1.4400, max23, torsoROI mean4.1593 on0..255 scale. Thus extra heuristic
darkening affects brightness but is not necessary for the residual seam; do not
promote this as a fix. Next inspect density/sample coordinate mapping and actual
optical-path discontinuity rather than raising samples or changing brightness.
All originals/candidates preserved; production untouched; quality goal incomplete.

## LU investigation — view throughput also tints surface diffuse

Traced current LR generated shader. liquid_field_position selects deformed
v_liquid_body_pos; surface advection writes a distinct liquid_sample_position,
not liquid_field_position. JE/LJ/LO integration starts from liquid_field_position
and advects each midpoint once. No evidence here of double-advection of the ray
origin. This relies on existing identity-body/part setup, not arbitrary transforms.

The computed through=exp(-sigma*occupied_length*mean_density) multiplies body
albedo at1442, then v_surface_color at1474 feeds custom diffuse lighting. The
same through also becomes v_through at1683 and xmit_col in light at1711.
Thus camera-path discontinuities modulate an apparent surface-color term as
well as transmission. This is an approximation, not separate physically based
surface reflection and volume scattering. It is a specific next isolation target:
remove view absorption from surface albedo ONLY in a diagnostic, retain it in
transmission, and compare the residual seam. Do not claim root cause proven or
promote an unattenuated/plastic body as the desired jelly result. Debugging skill
guided dataflow tracing; no production changes, all versions retained.

## LV — surface-albedo absorption isolation removes inspected diagonal

Added gel_surface_absorption_lv extending LR, frame43 only. Replaces body color
expression with body_color*albedo_gain, removing only view-throughput tint from
surface albedo. Retains thickness heuristic darkening, v_through transmission,
all density/flow, lights, reflections, mesh and depth pairing. Shader skill guided
isolated contribution test. Native guard clean4.757s. Direct measured043 inspection
shows the pronounced lower-torso diagonal boundary absent, while body becomes
yellow-orange and still plastic. This implicates view-path tinting of surface
diffuse in the inspected residual, but is not a physically complete material fix.
Do not promote this loss of orange/red volume depth as reference acceptance.
Next develop separated surface reflection and interior scattering/absorption,
preserving spectral depth without camera-path cuts printed onto diffuse albedo.
Full temporal/angle validation remains needed. All prior versions retained,
production untouched, overall reference-quality goal incomplete.

## LW — uniform-incident scattering prototype rejected visually

Added gel_separated_scatter_lw extending LV. Uses analytic uniform-isotropic
incident-radiance source1.5 with sigma_s=.35 and sigma_t(.45,2.1,6): volume
term1.5*(sigma_s/sigma_t)*(1-through), carried via EMISSION. Ratio is bounded
per channel but this does not establish whole-material energy conservation.
Replaces old direct body+glow+xmit sum with10% surface diffuse; preserves existing
reflection/other emission terms. No actual incident attenuation/shadow solution,
refraction or multiple scattering. Shader skill guided explicit source separation.
Guard clean4.453s. Direct frame043 inspection rejects result: brown/milky body,
large tonal cut across lower body and arm re-emerges strongly, wrong reference
palette and translucency. Do not claim scattering generally failed; this uniform
incident approximation and current optical representation are insufficient.
Next use actual incident paths and diagnose remaining volume discontinuities;
do not recolor this failed model and call it reference quality. All versions kept,
production unchanged, full quality goal remains incomplete.

## LX — moving-frame first-depth fallback is not the broad boundary

Added gel_moving_validity_lx extending LR at frame43, original vertex prefix,
same fresh paired depths, unshaded green for exact first-depth jc_valid condition
and red otherwise. Shader skill guided diagnostic replacement rather than more
lighting changes. Guard clean3.943s. Direct measured043 inspection is green
across lower torso and arm; no broad red/green boundary matches the beauty cut.
This tests the actual moving problem frame, unlike prior LG idle-only evidence.
Thus broad first-depth fallback switching is not supported as the cause here.
Does not test density continuity, later interval validity, physical light paths,
or complete animation quality. Further lighting work must preserve this distinction.
All versions retained; production untouched; overall goal incomplete.

## LY / LZ — optical field readback, diagnostic failure preserved

LY used unshaded EMISSION with zero ALBEDO. Despite a clean process, the body
rendered black; those zero samples are invalid evidence for thickness/density.
LZ preserves LY and instead outputs the diagnostic through unshaded ALBEDO:
R=local_thickness/2, G=jc_density/2, B=second-interval validity. First LZ launch
failed because the scene root was Node rather than the inherited Node3D; fixed
the scene type and retained the failure log. Retry guard clean in 3.154s.
Shader-basics guided an isolated diagnostic material, not production changes.

Inverse-sRGB decoded 8-bit LZ measured043 samples (row, column; left/right):
- (730,530): thickness .935568/.912822; density 1.129423/1.129423.
- (750,469): thickness .935568/.890402; density 1.129423/1.129423.
- (770,416): thickness .890402/.868307; density 1.116681/1.116681.

All three second-interval flags change 0 to 1. Blue diagnostic regions are this
explicit flag, not beauty defects. Thickness changes agree approximately with
prior packed-depth measurements; this color readback is quantized and not a
high-precision buffer. No density jump is resolved at these three points, not
proof of global density continuity. This supports focusing the next controlled
transport comparison on occupied-interval boundaries rather than increasing
density quadrature again. Still no reference-match, motion or release acceptance.
All prior versions retained; no production asset or material changed this step.

## MA — constant density with corrected three-interval pairing

Added gel_paired_constant_ma extending LR, frame43, fresh three paired depth
layers, forcing jc_density=1 immediately before spectral through calculation.
Unlike LH this tests the corrected multi-interval moving-frame representation.
Guard clean4.528s; directly inspected measured043. The diagonal tonal boundary
across the lower torso remains with uniform absorption density. Therefore the
varying integrated density is not necessary for this residual boundary. This
does not disable every surface flow term, nor prove incident lighting correct.
Combined with LS convergence and LZ readback, stop increasing density sampling
or smoothing interior flow as the proposed cure for this particular boundary.
The image still has excessive scale-like relief, broad clipped-looking highlights,
opaque/plastic impression and awkward underside silhouette. No visual promotion.
Next transport work must separate camera-path absorption from surface response
and test occupied-interval transitions with matched incident-light information.
Shader-basics used for the isolated material change; all versions preserved.

## MB — matched moving-frame incident intervals captured

Added gel_matched_light_mb extending LR at frame43, reusing exact aligned-start
deformation and paired exit search. Camera matches JC second directional light
Euler(-25,150,0), orthographic size2.5 at target+source_axis*4. Depth encoding and
peel comparisons both use positive view-z, not radial distance. Added default-
preserving LP hooks for peel metric and skipping beauty; existing LR defaults
remain radial with beauty enabled. No production changes.

Guard clean2.661s. MB original vertex-prefix SHA and frame43 sample record
(time, lag, body transform) exactly match LR. Decoded valid occupied intervals:
262076 first, 14040 second, 9 third. Each layer has zero negative pairs and zero
front/back mask mismatch; subsequent entries have zero overlap with prior exit.
These are ordering/coverage checks, not proof of complete geometric transport.
The nine third intervals must not silently be dropped by a two-layer consumer.
Camera axes/position and depth metric saved in matched-light-mb/light-camera.json.

This replaces stale 0/90/180 incident data for the actual problem frame and is
ready for a matched transport comparison. No beauty was rendered by MB; it does
not establish improved appearance, temporal stability, refraction, incident density
integration, first-light coverage or runtime performance. Overall goal incomplete.

## MC / MD — matched incident scattering wired, visual candidate rejected

MC extends LV, consumes all three MB light intervals at frame43. Integrates
24 view samples (8 per occupied segment), exact inherited varying view density,
unit incident density, sigma_t(.45,2.1,6), sigma_s.35, isotropic phase1/(4pi),
second-light source3.5. Air gaps are excluded from cumulative view optical depth.
Appends scattering via EMISSION; replaces old body/glow/xmit direct term with
10% surface diffuse as in LW. Other pre-existing reflection/emission terms remain.
This is not full energy-conserving transport, refraction or complete lighting.
The strict light-volume membership uses nearest depth and has no coverage repair.

Guard MC clean4.918s. Direct measured043 inspection: brown/plastic, scale-like
relief and broad white highlights remain; does not match reference orange-red
gel depth. Do not promote. MD disables only the new scattering contribution;
guard clean3.790s. All six view-depth files byte-identical MC/MD. Measured043
differs at519728 pixels, maximum channel44, whole-image mean absolute RGB4.34877
(8-bit units), confirming a nonzero contribution, not proving physical correctness.

Shader-basics guided isolated source separation and ablation. Next distinguish
insufficient incident lighting/transport approximation from the independently
incorrect surface relief and silhouette; avoid claiming this failed palette is
reference progress. Both candidate and control preserved, production untouched.
Overall visual/motion/release acceptance remains incomplete.

## ME — lower relief alone is not the reference surface

Re-opened CHAR-BASE-T-3d-alt.png: reference includes visible irregular wet facets,
especially on limbs/contour, rather than uniformly smooth plastic. ME extends LR
at frame43 and changes only normal-offset amplitude .015 to .003 (80% reduction).
Guard clean4.346s. Direct measured043 inspection shows substantially weaker scale
edges but broad smooth white reflections and plastic appearance remain; the
diagonal absorption boundary is more exposed. Do not promote this as a texture fix.
This bounds the next change: change the spatial character/distribution of relief
and reflection footprint rather than merely reducing its amplitude everywhere.
Reference has nonuniform facet sizes and coherent irregular glints; current field
still reads as a repeated small-cell pattern. Shape and transport remain separate
unresolved issues. Shader-basics guided one-variable isolation. All versions kept,
production untouched; no motion/reference acceptance claimed.

## MF / MG — irregular support and blended planes do not yet fix scale read

MF extends LR frame43: each Gaussian center now has deterministic diagonal
anisotropic exponent coefficients in[4,14], with matching derivative -2*w*k*delta.
Keeps normalized weighted-height quotient and amplitude.015. Guard clean3.954s.
Direct image still reads as cellular raised edges; random support size alone is
insufficient. MG extends MF with local linear height planes, random slope +/- .5,
center-height amplitude.1, correct w*slope addition to height derivative, and
normal amplitude.08. Guard clean4.581s. Direct image has stronger hammered/scaly
appearance and excessive glint fragmentation, not reference acceptance.

Both isolated candidates preserved, production unchanged. MG changes both field
form and output strength, so cannot attribute its regression to plane blending
alone. Before more visual parameter sweeps, compare slopes at matched RMS and
check continuity of the finite-support normalized field; mathematical local
derivatives do not establish global continuity at moving cell-neighborhood bounds.
No actual geometry, flow, or transport correction in these variants. Shader-basics
guided separate test materials; whole model quality goal remains incomplete.

## MH — field derivative and strength calibration

Added check_facet_fields_mh.py, deterministic NumPy float64 transcription of
the actual shader hash and LR/MF/MG normalized fields. 4096 points seed20260907,
64 derivative checks, 96 integer-boundary probes across all axes. Raw-gradient
RMS LR1.981155, MF2.038491, MG.748142. At their rendered amplitudes, RMS values
are .0297173/.0305774/.0598514: MG was about2.014 times LR, so prior image was
not a matched-strength field-shape comparison. MG calibrated raw-RMS amplitude
is .0397215097 rather than .08. This is not yet tangent-projected, surface-area
weighted or screen-footprint-filtered RMS; do not claim exact visible match.

Maximum central-difference derivative errors are1.74e-8/1.03e-8/3.95e-9.
Boundary gradient differences decrease roughly100x per100x epsilon reduction,
ending at7.14e-6/8.57e-6/5.38e-6 for epsilon1e-7. These probes do not support a
large neighborhood discontinuity as the dominant scale-pattern cause. They do
not prove global continuity or GPU float32 behavior, which can differ in hash.
Results saved exclusively to facet-fields-mh.json. No appearance correction or
production modification this step. Next render matched-strength MG before
rejecting/accepting the field shape itself. All versions retained; goal incomplete.

## MI — raw-RMS calibrated plane field remains insufficient

Added gel_calibrated_planes_mi extending MG, normal amplitude .0397215097 from
MH calibration; all other material, geometry, light and frame43 settings unchanged.
Guard clean4.700s. Direct measured043 inspection has less excessive fragmentation
than MG, but still a raised-cell/scale impression, large pale highlight patches,
plastic body and existing diagonal tonal boundary. Not a reference-quality result.
The comparison removes the known raw-volume RMS mismatch, not all projected/GPU
normal variance differences. Do not conclude all plane-field approaches fail.
At this stage changing height-field coefficients alone is not sufficient; next
isolate the broad reflection footprint and its clipping/rolloff before another
texture-parameter sweep. Shader-basics guided isolated candidate; all historical
versions preserved, production unchanged. Overall objective remains incomplete.

## MJ / MK — broad pale highlights isolated to analytic studio reflection

Both extend MI at frame43. MJ disables only directional SPECULAR_LIGHT addition;
guard clean4.084s. Direct inspection retains the large white/pale patches on the
head, face and feet while small directional glints disappear. MK disables only
the analytic studio term in EMISSION; guard clean3.762s. Direct inspection removes
those broad pale patches while leaving small bright directional glints. Body now
looks flat and insufficiently wet, so complete studio removal is not a solution.

This isolates the next correction to analytic reflection footprint/radiance/rolloff
rather than another relief-strength reduction. It does not establish clipping as
the cause, nor that every white pixel is erroneous. Reference needs coherent wet
reflections, not their deletion. Existing diagonal transport boundary and shape
issues remain. Shader-basics guided single-source ablations. All candidates kept,
production unchanged; whole reference-quality objective remains incomplete.

## ML — third-source radiance reduced consistently across body and eyes

ML extends MI; third analytic source radiance40 to8, unchanged direction and
angular width(.22,.22), updated identically in body/EyeL/EyeR test materials.
Other two analytic sources and directional lighting unchanged. Guard clean5.293s.
Direct measured043 inspection reduces white centers on forehead, mouth region and
feet; these become pale orange/pink reflections. Right-side patches remain,
showing that the third source is not their sole contributor. Eye reflections
become dimmer, and the whole character remains plastic/scaly with the transport
boundary intact. This is a localized highlight reduction, not reference acceptance.
Further reducing all source power would lose the reference's wet glints; next
compare source footprint/location against reference rather than more global gain
changes. Shader-basics guided matched body/eye source edit, no production mutation.
All previous candidates retained; full objective still incomplete.

## MM — frontal idle review exposes unresolved whole-character mismatch

Added gel_front_review_mm extending ML, frame0, camera(0,1.898,4.453) looking at
(0,.6716,0), inherited FOV. Updates shader view-ray origin consistently and captures
fresh paired depth layers. camera-system guided controlled view setup. This is
frontal azimuth at existing review elevation, not an exact reference-camera solve.
Guard clean4.798s. Direct measured000 inspection: one intact character, but flat/dim
black eyes without reference rim/reflection depth, mouth too low, thick hanging
arms, pale broad surface patches and opaque/plastic body remain. Reference has a
smaller higher mouth, fuller glassy eye treatment, slimmer liquid extremities and
strong orange-red depth with thin golden edges. Camera differences limit exact
proportion claims, not these visibly unresolved quality concerns.

No full animation inspection or reference acceptance. Crucially, material-only
iterations did not close face/shape debt: latest chain still excludes earlier LC
face-fit experiment. Next reconcile that known candidate with current front view
and eye appearance before calling this a coherent new character version. All
versions preserved, production unchanged, overall goal remains incomplete.

## MN — earlier mouth fit integrated with current material candidate

Extracted LC's existing geometry operation into _apply_mouth_warp(actor, output),
leaving its original setup calling the same operation. MN extends MM and invokes
only that helper on the current test meshes, sharing the face restoration cache;
does not execute the LC capture pipeline. Body, shell and mouth receive coherent
world-space warp and inverse-transpose normal updates, not a moved black decal.
3d-essentials guided mesh/coordinate consistency. Guard clean3.175s.

Direct measured000 shows mouth smaller and higher, closer to reference layout,
but a prominent pale reflection/contour beside it is visible. Eyes remain flat/dim,
arms thick and overall body plastic. Sampled minimum Jacobians Body.141716,
Shell.133958, Mouth.600016, all positive and matching LC values; this is not global
nonintersection or animation proof. Affected vertices8464/8345/257. Fresh paired
depths and meshes saved in integrated-face-mn. No promotion or production edits.
Next inspect mouth-adjacent contour under neutral material and side view before
accepting this integration; retain face-layout gain without declaring whole quality
achieved. All prior outputs preserved, goal still incomplete.

## MO / MP — neutral-material mouth-warp comparison reveals shape side effect

MO extends MN (warped), MP extends MM (unwarped), frame0 and same frontal camera.
Reuses LF's neutral body material with original vertex prefix, albedo.35,
roughness.85, specular.2; face materials preserved. Guards clean2.807s/2.009s.
Direct inspection: MO has a small pinched/creased contour between the lower eye
regions above the raised mouth that MP does not show. Thus mouth-layout gain
has a geometric/normal-field side effect; the beauty pale patch cannot simply
be dismissed as lighting. No visible open tear in these frames, not a topology
or animation proof. Existing arm/underside lumps remain in both controls.

Next refine the local warp transition or surface reprojection while preserving
the higher/smaller mouth, then repeat neutral and beauty comparison. Do not accept
the LC/MN positive sampled Jacobian as an aesthetic surface-quality guarantee.
3d-essentials guided neutral material isolation; all versions preserved and no
production modifications. Reference-quality objective remains incomplete.

## MQ / MR — localize horizontal mouth compression

MN now has a default-preserving helper-script hook. MQ overrides LC warp to
keep vertical support(.20,.22,.18), shift.08, but narrows horizontal compression
support to(.10,.11,.18); same smoothstep(.35,1) and center width scale.60. MR
uses this through MO's neutral material capture. Guard clean2.816s. Minimum
sampled Jacobians Body.171042, Shell.173129, Mouth.600016, improved versus MO
without proving global validity. In frontal clay the upper cheek pinch is less
localized, but a broad mouth-surround contour remains. Mouth still higher/smaller.
Do not call the transition fully repaired based on this single neutral view.

The inherited mesh-warp.json records shift/center scale but not distinct support
radii; the actual MQ source and this section document the changed support. Next
side-view and beauty comparison must verify no new bulge or mouth detachment.
3d-essentials guided coherent mesh/normal warp. All versions retained; no production
changes or reference/animation acceptance. Overall goal incomplete.

## MS — localized mouth warp in side idle and moving beauty

Added gel_side_width_ms, current ML/MI material with MQ localized compression,
45-degree camera and consistent shader ray origin. Fresh paired layers at0/43.
Final camera recorded in side-camera.json, explicitly superseding inherited
front-camera.json. Guard clean3.747s. Direct inspection of both measured frames
shows mouth remains seated on the face without an obvious detached black patch,
but a raised/puckered lip surround and pale patch persist. This is not smooth
reference geometry acceptance. The broad torso transport boundary and thick
arm/underside silhouette remain unrelated unresolved issues.

These are two controlled deformation snapshots with frozen AnimationPlayer,
not a continuous motion test or all-animation validation. Next local shape work
must address the vertical warp/surface transition, not further compress width
alone. camera-system guided consistent capture. About12GiB free before run.
All versions retained; no production changes; whole quality goal incomplete.

## MT / MU — tangent-plane mouth translation remains insufficient

MT extends MQ and estimates a local surface normal from969 front-facing body
vertices in mouth-centered XY annulus(.12,.18), abs(deltaZ)<.10. Normal is
(.00183038,.13613044,.99068922). Adds dz=-(nx*dx+ny*dy)/nz to the existing warp,
removing normal displacement relative to that fitted plane while preserving XY
placement. This is vertex-weighted plane approximation, not curved reprojection.
MU uses MS side camera/frames0,43 and same material. Guard clean3.971s.
Sampled Jacobians remain positive: Body.152687, Shell.156542, Mouth.600016.

Direct measured043 inspection still shows a puckered pale mouth surround; simple
tangent translation did not resolve the aesthetic side effect. Do not promote or
keep tuning only the plane tilt. Next shape correction needs the actual curved
surface or a better relocation field, with neutral comparison, rather than assuming
a local plane preserves a curved face. Frame0 rendered but not directly inspected
this step. 3d-essentials guided coordinate/normal handling. All versions retained,
production unchanged; full quality objective incomplete.

## MV — quadratic face fit measured, not applied due large residuals

Added fit_mouth_surface_mv.py against archived unwarped LN/HS rest vertices,
verified source SHA f18e5820e529bf53fb32a91c3bdab66bb82d59e60a4df7bf3e0d191a617400ed.
Mouth-centered XY annulus(.10,.22), abs(dz)<.10, deterministic2513 train/629
holdout vertices. Quadratic z(dx,dy) holdout RMSE.004925 vs plane.011914;
maximum residual.035538 and condition number139.57. Predicted center shift for
dy=.08 is dz=-.017562. Maximum residual exceeds this correction magnitude, so
do not use these coefficients as a verified surface-reprojection fix yet.

Random vertex holdout can share neighboring triangles and is weaker than spatial
holdout; excluded cavity/target interior is not validated. The archive also needs
runtime source equivalence verification before geometry application. Next localize
residuals and distinguish facial rims/cavity samples from smooth carrier surface,
then evaluate spatial holdout. No new render or geometry change this step.
3d-essentials informed coordinate-space isolation; evidence saved in
mouth-surface-mv.json. All versions retained; overall quality objective incomplete.

## MW — residual localization contradicts eye-rim contamination hypothesis

Added check_mouth_fit_mw.py, preserving MV coefficients and data selection.
All3142 annulus vertices evaluated:26 exceed abs error.015; all26 lie below
the mouth, only4 have abs(dx)>.10. Worst vertex54697 at(-.005905,.419788,.414092),
dy=-.214916, error.036993. Thus do not attribute dominant residuals to upper eye
rims without contrary evidence. Eight angular holdouts give RMSE.00428..01960,
maximum error up to.04454, worse than random holdout. Sector counts45..840 reveal
strong vertex-density imbalance. Center-shift predictions stay approximately
-.01632..-.01823, but stable central prediction does not validate the whole warp.

Next evaluate triangle-area or spatially balanced sampling and lower-face curvature,
not residual-based deletion of inconvenient vertices. Record mouth-fit-mw.json
includes exact indices/coordinates and all sector folds. No mesh mutation or new
render; this changes the next geometric inference, not visual acceptance. All
versions retained, production untouched, overall objective incomplete.

## MX — area weighting reduces imbalance but quadratic carrier still inadequate

Added check_area_fit_mx.py: lump each source triangle's area equally onto its
three vertices, then fit the same3142-vertex annulus. Weights vary511.59x;
sector area fractions are12.08..13.09%, despite prior vertex counts45..840.
This confirms tessellation-density imbalance, not missing lower-region area.
Area-weighted fit training area-RMSE.006250 vs uniform.009326, max training
residual.014373 vs.035855. Worst spatial-fold max error drops.044541 to.018968.
However upper-sector holdout errors increase in places; worst area-RMSE.011060
and residual magnitudes remain comparable to center dz prediction-.017057.

Do not call weighted fitting validated geometry. A single quadratic patch trades
errors across different curvature regions. Next use a spatially varying carrier
with area-aware validation, preserving local detail residuals; no arbitrary outlier
deletion. Lumped areas include adjacent triangles across annulus selection edges,
so not exact clipped-annulus surface integration. Results mouth-area-fit-mx.json.
No mesh edits or new render this step; all versions preserved, objective incomplete.

## MY — local area-weighted carrier improves every spatial fold

Added check_local_surface_my.py: moving quadratic least squares with Gaussian
sigma.10, query-centered/scaled coordinates, same area weights and eight excluded
angular sectors as MX. No regularization or outlier removal. Every fold improves
area-RMSE versus global area-weighted MX. Worst area-RMSE.006114 vs.011060;
worst absolute error.013806 vs.018968. Lower-sector maxima.00328..00456 versus
MX.01176..01897. Normal-matrix conditions293..418 (float64); not a GPU solver.
Predicted center dz across folds ranges-.019606..-.022064, differing from the
global quadratic prediction. This is useful carrier-fit evidence, not a completed
mouth correction: excluded central cavity and target point remain unvalidated.

Next verify source equivalence and build an isolated residual-preserving geometry
candidate with normals recomputed consistently, then inspect neutral/beauty views.
Do not claim ring fit proves central geometry or animation safety. Results saved
mouth-local-fit-my.json. No mesh edits this step; all versions retained and full
reference-quality objective remains incomplete.

## MZ–ND — source verification, curved relocation and neutral-material check

MZ verified the current unwarped test Body against the LN analysis archive:
56,118 vertices, 336,696 indices, zero vertex delta and identical indices.
Body transform is identity; mouth center is (0, .634704, .354426).
This does not establish shell/cavity identity or surface-fit accuracy.

NA builds a 45-term degree-eight polynomial surrogate of MY moving least
squares. On 1,024 seeded validation samples, height error versus MLS has
maximum .000411511 and RMSE .000106443. These measure approximation of MLS,
not error against the unknown central carrier; derivatives remain unvalidated.
NB applies the same XY relocation as MQ and adds carrier(newXY)-carrier(oldXY)
to Z, preserving the original offset from the fitted carrier. Body, shell and
mouth receive the same mapping with Jacobian-based normal/tangent updates.

NC isolated beauty capture completed cleanly in 6.427 seconds on Apple M4 Pro
Vulkan Forward+. Both side frames 0/43 were inspected. No obvious open tear
was visible, but pale/puckered mouth surroundings, scaly surface, flat eyes
and thick limbs remain. Minimum sampled Jacobians: Body .171490,
BodyShell .171605, MouthCavity .600016. Positive sampled determinants are
not exhaustive intersection checks or animation acceptance.

ND adds a front neutral-material capture using the same NB warp, frames 0/43.
Clean process in 6.082 seconds. Both images inspected: a shallow raised band
between the eyes above the mouth persists without orange surface shading.
Therefore the mouth-region issue is not solely a specular-material effect.
Arm/torso creases and broad lower-body lobes remain visible. No clear open
tear in these two views; do not infer watertightness from screenshots.

Decision: retain NC/ND as experimental evidence, do not promote. Next isolate
the residual raised band against the unwarped neutral baseline before changing
the geometry again; surface pattern and optical quality remain separate work.
These are controlled snapshots, not all 14 animations, gameplay GPU profiling
or release validation. All older candidates retained; production untouched.
Outputs: source-match-mz, mouth-carrier-na.json, carrier-side-nc and
carrier-clay-nd under outputs/v8.6-quality-audit-20260906.

## NE–NG — travelling deformation field softens the induced facial band

Previous turn classification: progress (NC/ND capture and interpretation).
Re-inspected unwarped MP frame 0: the sharp transverse band visible in ND is
not prominent in MP, supporting deformation-induced compression as a working
hypothesis. This comparison does not isolate all possible normal errors.

NE replaces the one-shot MQ XY displacement with 16 explicit-midpoint steps
of a travelling compact velocity field. Core targets remain .08 lift and .6
horizontal scale (log(.6) contraction rate); NB carrier-height compensation
and LC normal/tangent Jacobians remain. This is offline rest-mesh construction,
not runtime fluid simulation. Finite integration is not a diffeomorphism proof.

NF neutral front frames 0/43 completed cleanly in 7.961 seconds and were both
inspected. The sharp raised band is visibly softer than ND, although a broad
shallow facial contour remains. Sampled minimum Jacobians rise from NB Body
.171490 / shell .171605 to .453127 / .449680; cavity .600048. Affected vertices
increase to 10,234 Body / 10,074 shell / 257 cavity. Thus spatial support differs;
do not attribute improvement solely to higher determinant values.

NG side beauty frames 0/43 completed cleanly in 7.637 seconds. Frame 43 was
inspected: mouth remains seated, but overall scaly/plastic appearance and pale
highlights persist. Frame 0 exists but was not visually inspected this turn.
Keep NE as a promising geometry candidate, not a promoted or accepted character.
Remaining checks include integration convergence, more viewpoints/motion,
central carrier accuracy, and the separate surface/optical reference mismatch.
All previous assets retained; no production files modified this turn.

## NH–NI — step refinement supports retaining the 16-step mouth candidate

Previous turn classification: progress (NE implementation and NF/NG evidence).
NE now exposes a default-preserving integration-step hook; NH overrides it to
32. NI renders the same neutral setup and compares all generated mesh vertices
and normals with saved 16-step NF resources, asserting identical index arrays.
No production mesh or shader changed. Clean native process in 9.322 seconds.

Body (56,118 vertices): maximum world-position difference .0000167795,
RMS .000000900646, maximum local normal-angle difference .090368 degrees.
Shell (56,118): maximum .0000165368, RMS .000000878977, angle .114249 degrees.
Cavity (257): maximum .00000141285, RMS .000000784731, angle .018111 degrees.
Results in flow-convergence-ni/convergence.json. Frame 43 visually inspected;
softened band remains consistent with NF. Frame 0 captured, not inspected here.

This is agreement under one step refinement, not a demonstrated convergence
order or an exact-solution error bound. Normal differences include finite-
difference Jacobian and float32 effects. It does not test mesh intersections,
14 animation clips, renderer performance, or reference-quality acceptance.
Evidence supports moving attention back to the prominent surface/optical
mismatch rather than increasing integration steps to address the remaining
plastic/scaly appearance. Preserve both candidates; overall objective active.

## NJ — continuous surface removes cells but is not the reference finish

Previous turn classification: progress (NH/NI step-refinement evidence).
Re-inspected CHAR-BASE-T-3d-alt.png: reference has irregular wet facets, thin
golden margins, rich orange core and strongly reflected black eyes. Merely
removing all surface texture is not reference matching.

NJ replaces jp_field only with an analytic scalar-height gradient composed of
12 deterministic directional sinusoids (wavevector magnitudes .65..1.7).
Normalize by sqrt(sum(.5*|k|^2)); theoretical independent-phase RMS is one,
not measured surface/GPU RMS. Normal strength .029717 targets prior volume
RMS scale approximately. Geometry, mouth warp, lighting and absorption retained.

First run failed: replacing from jp_field through fragment accidentally removed
intervening depth sampler declarations (unknown lj_front2). Guard stopped the
process. After reading the log, fixed replacement to balanced-brace function
extent only. Failed outputs preserved; fresh continuous-surface-nj-r2 output.
Retry completed cleanly in 9.272 seconds. Frame 43 directly inspected; frame 0
captured but not inspected. Cellular/scaly pattern is largely gone, but the
result is excessively smooth/plastic, with broad pale highlights and the
diagonal torso tonal boundary more exposed. Not an accepted visual upgrade.

Keep this diagnostic: removing cellular gradient does not solve material optics.
Next work must retain irregular wet detail without returning to cell outlines,
and address broad reflection/volume-light balance rather than claiming smooth
orange plastic is jelly. No production promotion; all versions preserved.

## NK–NL — compact sources and stronger continuous relief remain insufficient

Previous turn classification: progress (NJ diagnostic and compile-failure fix).
NK changes only Body analytic source widths relative to NJ: (.20,.20) to
(.07,.07), (.16,.16) to (.06,.06), (.22,.22) to (.08,.08). Peak radiances
unchanged, so integrated angular energy is reduced; this is not energy-matched
source-size comparison. Eye sources, geometry and absorption unchanged.
Clean capture 9.791 seconds; frame 43 inspected: broad pale patches shrink,
but much of the surface becomes flat orange plastic. Not a reference match.

NL retains NK and increases continuous-field normal amplitude .029717 to .12.
Clean capture 9.042 seconds; frame 43 inspected. Reflections split into curved
wet-looking streaks, but large dent-like shading and a wavy arm appearance
replace the previous smooth look. These are shader normals, not changed mesh
positions. The scale of relief still differs from the fine irregular reference
facets, and the diagonal torso tone boundary persists. Frame 0 captured for
both candidates but not inspected this turn. Neither candidate promoted.

Evidence: lowering source width alone trades pale patches for flatness; raising
continuous relief amplitude alone creates overlarge distortions. Next address
spatial frequency/distribution separately, retaining current tests as controls,
while keeping optical-depth discontinuity as an unresolved separate issue.
All previous versions retained; no production changes or acceptance claims.

## NM–NN — finer continuous relief exposes spectrum regularity

Previous turn classification: progress (NK/NL optical and relief diagnostics).
NM retains NL strength .12 and compact sources, increases object-space field
frequency 48 to 144 and scales the footprint estimate identically. Captured
cleanly in 9.742 seconds. Frame 43 inspected: large apparent dents become
smaller, but directional repeating wave/interference patterns are conspicuous.
Because footprint fade changes with frequency, this is not equal visible RMS.

NN changes only the deterministic wave count 12 to 64, retaining normalization
by summed wavevector energy. Clean capture in 9.272 seconds. Frame 43 inspected:
obvious regular interference is reduced and the surface is more irregular, but
relief remains too strong/uniformly distributed. It still reads orange-peel or
hammered plastic rather than the reference's translucent wet facets. The broad
diagonal torso boundary and weak black-eye reflections remain. Frame 0 exists
for both, not visually inspected this turn. No motion/shimmer acceptance.

Keep NN as a spectrum diagnostic, not a promoted quality result. Next evaluate
surface detail strength/distribution without conflating it with the unresolved
volume-optics boundary; further wave-count increases are not justified by this
evidence. Native process timings are not GPU frame-performance measurements.
All candidate and older outputs preserved; no production change.

## NO–NP — fine coat normals were also modulating interior shading

Previous turn classification: progress (NM/NN spectrum evidence).
NO retains NN detailed NORMAL for specular/studio reflections, but passes
base_n via fragment-to-light varying for wrapped diffuse and transmission
distortion. Initial launch used an incorrect executable path and failed before
Godot started (FileNotFoundError); corrected to pinned 4.7.2 with a fresh guard
directory. Actual capture clean in 10.181 seconds. Frame 43 inspected: direct
body contrast reduced, but widespread ripples still visible.

NP additionally changes the fragment heuristic fres input from n to base_n;
studio jf_fresnel and reflection normals remain detailed. Clean capture in
9.076 seconds. Frame 43 inspected: most widespread orange-peel shading disappears
while fragmented wet highlights remain. This isolates an important coupling:
fine normal variation was driving interior/rim heuristic masks, not only coat
reflections. NO/NP are diagnostic layered-normal splits, not physically complete
layered BSDFs or transport corrections. Frame 0 captured but not inspected here.

NP is visually smoother away from highlights, but still too flat, with small
isolated reflection clusters, weak eyes and the persistent diagonal body tone
boundary. No reference-quality or motion acceptance. Next retain normal-path
separation as a candidate while revisiting reflection coverage and interior
optics; do not simply lower all surface detail to hide the coupling.
All older outputs preserved. No production files modified or promotion.

## NQ — restored source coverage preserves the normal split but brings pale patches

Previous turn classification: progress (NO/NP isolated interior-normal coupling).
NQ restores the pre-NK Body source widths .20/.16/.22 while retaining all NP
normal separation and NN spectrum parameters. Peak radiance unchanged, so
integrated angular source energy increases relative to NP. No eye or geometry
changes. Clean native capture 10.256 seconds. Frame 43 directly inspected:
wet reflection coverage increases, and the widespread off-highlight dents do
not return; however large pale textured patches reappear on forehead, cheek,
arm and feet. Thus normal separation is useful but broad source coverage alone
does not achieve the reference. Frame 0 captured but not inspected this turn.

The persistent diagonal torso boundary is unchanged and dominates broad body
color. Prior LV evidence already implicated view-path absorption in diffuse;
do not repeat that ablation as a novel discovery. Next revisit transport/color
allocation with the existing LV/MC evidence before further light-size tuning.
NQ preserved as a control, not promoted. Full visual/motion/performance objective
remains incomplete; no production modifications.

## NR — intrinsic orange color avoids the strongest view-path diffuse seam

Previous turn classification: progress (NQ coverage test). Re-read LV and MC:
LV removed diffuse throughput but became yellow; MC used matched single-scatter
lighting but was visually inadequate. NR does not claim to rediscover LV.
It combines the current normal-separated candidate with an art-directed linear
orange substrate (1,.22,.004)*albedo_gain instead of multiplying body color by
view-path throughput. Existing transmission still uses through. Macro-thickness
and liquid color controls remain; this is not an exact volume transport model.

Clean native capture 10.002 seconds. Frame 43 inspected: the strong diagonal
lower-torso color discontinuity seen in NQ is much less apparent, while the
body now shades more continuously. Orange hue retained rather than LV's yellow
base. Pale textured highlights, flat dark eyes and overall opaque/plastic
impression persist; no claim of reference match or full seam elimination from
one image. Frame 0 captured but not inspected this turn.

Keep NR as an art-directed color-separation candidate for multi-view comparison,
not a replacement for proper interior lighting. Preserve all versions and
production state. Reference-quality, motion and runtime-performance gates remain
open; next inspect the candidate frontally against reference before promotion.

## NS — frontal comparison rejects the current material as reference-ready

Previous turn classification: progress (NR color-separation candidate).
NS renders NR from frontal azimuth (0,1.898,4.453), target (0,.6716,0), retaining
inherited FOV and frames 0/43. View-ray literal updated with camera. Final camera
metadata explicitly supersedes inherited side/front files. Not an exact recovered
reference camera. Clean capture 9.750 seconds. Frame 0 and original reference
CHAR-BASE-T-3d-alt.png inspected together; frame 43 captured but not inspected.

Mouth is smaller/higher, but the current frontal surface is flat opaque orange,
with overlarge pale reflection patches, weak golden transparent margins, thick
limbs and black eyes that read as flat patches. Reference has layered dark eye
reflections/rims, a deeper orange interior and fine wet faceting. NR side-view
seam improvement is not enough to accept this character.

Read actual exported EyeL shader: reflection code is present (not simply absent
catchlights); it uses three analytic world-direction sources, Fresnel and a
low-strength hemispheric term. Two strong sources point toward negative Z;
the third points (-.60,.50,.60). Candidate diagnosis: eye cap normals/reflected
directions may not cover bright source lobes. This is an inference, not yet
measured. Next inspect actual eye reflection-direction coverage before adding
arbitrary painted highlights or changing eye energy. Preserve geometry and all
candidate versions; production untouched, overall objective incomplete.

## NT–NU — eye-source coverage measured; shared front source improves glints

Previous turn classification: progress (NS frontal evidence and shader inspection).
NT retains body depth but renders it black, encoding key/fill/third eye source
lobes in RGB before Fresnel/radiance, with .05 pedestal and .9 gain. Quantized
RGB8 is decoded to linear; two conservative eye boxes exclude pore/mouth.
Clean process 9.629 seconds, diagnostic image inspected. Visible eye pixels
10,476 and 10,511. Key/fill both decode to zero (below quantization, not proof
of exact mathematical zero). Third source means .008631/.012736; only166/363
pixels exceed .1 response, approximately1.58%/3.45%. Third maxima .987429/.867522.
Thus existing analytic illumination poorly covers frontal eye reflections.

NU adds the same front analytic source to Body and both eyes: direction
(-.35,.55,1), widths(.18,.25), peak12, warm-white color, each material's Fresnel.
No painted eye texture or geometry edits. Clean capture10.283 seconds. Frame0
inspected: eyes gain clear soft glints, confirming source coverage matters;
however body pale patches worsen and eye glints remain soft rather than the
reference's layered sharp reflections. Frame43 captured but not inspected.

Do not promote NU as a final look. Next refine source shape/coverage consistently
across materials and validate side/motion appearance; eye-cap geometry and rim
still require review. These raster probes are not animation/performance or
reference acceptance. All historical candidates retained, production untouched.

## NV — shaped shared source sharpens eyes but over-sharpens body reflections

Previous turn classification: progress (NT coverage measurement and NU candidate).
NV changes only the additional NU source from Gaussian to a rectangular angular
card, same direction/width/peak12 across Body and both eyes. Edge smoothing uses
max(.04,fwidth(edge)); this is raster edge AA, not a material-roughness convolution.
Other three sources unchanged. Card profile has different integrated energy;
do not interpret this as equal-energy source comparison.

Clean capture11.046 seconds; both frontal frames0/43 inspected. Eyes now show
distinct shaped reflections rather than soft dots, closer in kind to reference
glass highlights. However body reflections become harsh flat pale islands on
forehead, chest and feet, worsening the overall look. No mesh breakup inferred:
these are reflection boundaries on unchanged geometry. Reject overall promotion.

Next distinguish shared source shape from each material's reflected-source blur:
the environment should remain shared, but body/eye roughness responses need not
be identical. A pixel-edge AA term alone is not a roughness model. Keep NV and
all earlier candidates; production untouched and quality objective incomplete.

## NW — filtered body card retains sharp eyes but pale coverage remains excessive

Previous turn classification: progress (NV shaped-source result).
NW retains the shared rectangular source direction, dimensions and radiance.
Body response uses a separable Gaussian convolution of the planar card via erf
approximation, sigma .07 plus diagonal pixel-footprint variance /12. Eye response
remains NV. This is a planar filter approximation, not GGX, not a full spherical
energy-conserving material model; discarded footprint covariance is a limitation.

Clean native capture10.158 seconds. Frame0 inspected: harsh pale island edges
soften, and eyes retain shaped sharp glints. EyeL shader SHA256 matches NV
exactly (7f0bd480bf0644eb91f9f850ee83a6f0f80630acd1fc951bcd4b99bf8fd6c6e0).
Body still has excessive pale reflection coverage and flat orange interior;
overall reference quality remains insufficient. Frame43 captured but not
visually inspected this turn. No motion aliasing or runtime performance proof.

Keep material-specific filtering as an experimental direction, but do not call
it an accepted jelly surface. Next work needs broader material balance and
interior depth cues rather than further tiny source-edge adjustments alone.
All candidate versions retained; no production promotion or changes.

## NX — restore liquid color proxy on current material; flow still not legible

Previous turn classification: progress (NW material-specific source filtering).
Current inherited JC deliberately disables liquid_core_color_mix and laminar
color mix for optical isolation. Read HC precedent: surface-color proxy tests
already existed, so this is integration with the new material, not novel volume
transport. NX records actual before values (core mix0, deep(1,.32,.008)), sets
core mix.85 and deep(1,.07,.002), retains other fields and all NW optics. Deep
color also affects wrapped diffuse, so this is not a core-mix-only ablation.

NX uses zero velocity at all frames and captures0/90/180 with existing wobble
and flow clocks. Clean process9.219 seconds. Frames0/180 inspected: color richer
red-orange, but no clearly readable internal fluid motion from these snapshots;
minor shape/highlight changes cannot establish flowing interior acceptance.
Frame90 captured but not inspected. Broad white patches remain dominant.

Do not claim re-enabling a parameter solved the idle-fluid requirement. Next
measure the actual liquid mask and phase over time separately from body wobble
and coat highlights to determine whether it varies meaningfully or is saturated.
All old versions retained; no production changes or promotion.

## NY–NZ — central liquid mask plateau explains weak idle readability

Previous turn classification: progress (NX restored-proxy integration).
NY directly renders core mask/slime volume/1 in RGB with unshaded Body, no
emission, preserving deformation and face occlusion. Central belly ROI
x420..599,y580..749 (30,600 pixels) is entirely Body, blue validity asserted.
Clean capture10.294 seconds. At frames0/90/180, decoded red min=max=mean
.6866853. std~5.8e-7 is numerical cancellation, not real variation. jb_time
advances0/1.5/3; idle speed.28, motion mix0, scale3, softness.18, strength.82,
threshold.48. Mask plateau near .84*.82=.6888 is strength-scaled saturation;
the generic >.95 statistic is therefore NOT a useful saturation detector here.

Read actual shader: surface mask threshold.48 differs from integrated density
threshold+.20, inherited from KC. NZ adds the same .20 only inside surface
slime/ridge block, leaving density unchanged. Clean capture9.298 seconds.
Frame0 ROI remains plateau; frame180 mean.677976,min.577580,max.686685,std.019590.
NZ frame180 diagnostic inspected: broad mask transition crosses the face/body,
but central region remains largely plateaued. Matching thresholds alone does
not produce sufficient idle-flow readability. No successful beauty integration
or flowing-volume claim. NY frame180 also inspected; other diagnostic images
captured, not all visually reviewed. Uniform changes are logged per frame.

Next evaluate field range/transition width and material-point evolution before
further color gain; stronger color on a plateau cannot reveal motion. Keep all
versions, production untouched, overall objective incomplete.

## OA–OB — softer transition improves mask variation, not yet visible fluid quality

Previous turn classification: progress (NY plateau diagnosis and NZ threshold test).
OA retains NZ aligned surface threshold and changes shared liquid_slime_softness
.18 to .32. Clean capture9.001 seconds. Central ROI frame0 mean.674901,
min.603827,max.686685,std.013424; frame180 mean.629916,min.564712,max.672443,
std.029599. Mean change~.045 vs NZ~.00871. This is screen-space variation with
wobble, not material-point flow verification; the >.95 counter remains unsuitable.

Extracted NZ threshold edit into a default-preserving static helper. OB uses it
on NX beauty and the same .32 softness, preserving raw diagnostics separately.
Shared softness also alters integrated density; final settings file records
this instead of silently relying on inherited metadata. Clean capture10.601
seconds. Frames0/180 directly inspected: a modest body-color shift is present,
but fluid movement is still not clearly legible and the character retains a flat
orange/plastic impression under dominant pale reflection patches. Frame90
captured, not inspected. No claim that numerical mask changes meet idle UX.

Next quantify actual beauty color sensitivity to the mask and distinguish it
from coat/wobble changes before increasing density or speed. Keep all versions;
production untouched and full reference-quality goal remains active.

## OC–OD — color proxy works, but temporal signal is small relative to static tint

Previous turn classification: progress (OA mask evidence and OB beauty integration).
OC changes only OB liquid_core_color_mix .85 to0, retaining deep color, density,
flow and wobble. Clean capture9.312 seconds. OD image-data analysis asserts
byte-identical hashes for all18 depth images (three frames, three layers, two
sides), then compares the same30,600-pixel central belly ROI. No image editing.

Enabled-minus-disabled mean RGB8 effect: frame0 (1.177,-22.844,-2.604), frame90
(1.195,-22.292,-2.606), frame180 (1.222,-21.373,-2.490); maximum absolute28.
Temporal change of this isolated effect, frame180 minus0, mean absolute RGB8
(.4135,2.30085,.5055), max14; signed green mean1.4713. Thus the proxy has a
substantial static tint but much smaller temporal signal, consistent with weak
visible interior motion. These sRGB8 statistics are not perceptual thresholds.

Same-time ablation isolates color-mix contribution, but temporal differences
remain screen-space and include wobble/shading/quantization coupling. No visual
acceptance claimed from numbers; OC images not visually inspected this turn.
Next improve field evolution/distribution rather than merely amplifying static
tint. Results core-sensitivity-od.json; preserve all versions and production.

## OE — higher spatial frequency does not resolve interior readability

Isolated OB extension changes liquid_slime_scale from3 to6, retaining idle
speed and softness. Shared scale affects both surface color proxy and integrated
density, not just one layer. No geometry or particles added. Native Forward+
capture0/90/180 completed cleanly in9.351 seconds. Inspected0/180 against OB180:
body tint changes, but dominant pale patterned reflections and opaque orange
appearance remain; these snapshots do not establish convincing internal flow.
No visual acceptance or promotion. Frame90 captured, not visually inspected.

First metadata used the wrong idle-speed key and recorded null. Corrected to
liquid_flow_idle_speed and added non-null assertions for every recorded uniform;
reran into a separate oe-r2 output, retaining the original. Clean process8.335
seconds. This correction changes metadata only, not material settings.

Next work should prioritize a readable translucent interior and reduce dominant
coat reflection coverage, then validate continuous idle/movement playback, not
keep increasing field frequency or count snapshot color changes as fluid UX.
All historical versions and production changes preserved. Disk about11GiB free;
no cleanup performed. Overall reference-quality and release acceptance remain
incomplete.

## OF–OG — reflection attenuation is not an interior-depth solution

Previous turn classification: progress (OE distribution test and metadata fix).
Re-read reference directly this turn: layered glossy eyes/rims, translucent
golden limbs and perimeter, red-orange depth and more distributed wet detail
remain missing from the candidate. OF scales only the final bounded body studio
reflection to .35, leaving eyes and direct specular unchanged. Native capture
0/90/180 clean10.977 seconds. Frame0 inspected: pale regions soften but remain
obvious; body still opaque and flat. This is art-directed attenuation, not an
energy-conserving material model.

OG additionally zeros Body direct SPECULAR_LIGHT only. Clean9.683 seconds.
Frame0 inspected: small bright glints disappear, but forehead/chest patterned
patches persist. This contradicts the tentative hypothesis that direct specular
was the principal cause of those broad patches. The remaining indirect source
response and underlying orange substrate still dominate. Neither test makes
the interior convincingly transparent; do not promote either or solve this by
turning off all gloss (reference explicitly needs wet gloss).

Frames90/180 captured but not visually inspected. No continuous animation,
performance or reference acceptance established. Shader-basics guided isolated
body-material edits while preserving the eye shader. All versions retained;
production untouched. Next address the flat substrate/interior depth model and
reflection spatial structure, not another scalar brightness sweep.

## OH–OI — connected interior depth cue, still not translucent reference quality

Previous turn classification: progress (OF/OG reflection ablations ruled out
scalar attenuation as an interior solution). OH returns to OE lighting and
integrates a continuous compact core over the existing three occupied intervals,
eight midpoint samples each. Center(0,.70,0), radii(.34,.54,.28), density
max(1-r_squared,0)^2. Accumulated mass drives 1-exp(-8*mass) between golden
(1,.48,.012) and red-orange(1,.055,.001) substrate colors. Existing surface
core tint disabled explicitly and recorded separately from inherited metadata.
No extra meshes/particles; core static in body coordinates before advection.
This remains art-directed diffuse color from volume depth, NOT actual background
transmission, refraction, multiple scattering, or validated liquid animation.

OH native capture clean10.855 seconds; frame0 inspected. Central orange-red
and golden exterior separation is visible, but exterior looks too solid/yellow
and patterned reflections remain. Not reference acceptance. OI recaptures all
depth layers at45-degree camera(3.14875,1.898,3.14875), updates integration ray
and final-camera metadata. Clean10.217 seconds; frame0 inspected. Core color
region changes with angle rather than a fixed screen decal. Nevertheless side
view shows abrupt arm/body shading boundaries and opaque toy-like material;
this is not a validated general-view solution. Frames90/180 in both captures
not visually inspected. Integration convergence and motion not tested here.

Preserve OH/OI only as evidence for layer separation; do not promote. Further
work needs actual transmitted/scattered-light contribution instead of relying
on a color-mapped diffuse substrate, plus side-boundary diagnosis. All historical
versions and production files retained. Overall goal remains incomplete.

## OJ–OL — separate side-view substrate artifacts from lighting

Previous turn classification: progress (OH connected-core integration and OI
side-view evidence). OJ renders OI Body unshaded with ALBEDO=body and zero
emission; faces retain their shaders. Clean10.051 seconds. Frame0 inspected:
strong arm-adjacent lighting boundary disappears, but a faint diagonal belly
color boundary remains. OK bypasses all legacy post-substrate modifiers and
outputs only the OH core color equation unshaded. Clean9.067 seconds. Frame0
shows smooth core transition with no visually apparent diagonal belly boundary.
This separates the core cue from inherited substrate modifiers at this view,
not a global smoothness or animation proof.

OL returns to lit OI and removes only legacy macro-thickness diffuse darkening.
Clean9.839 seconds. Frame0 inspected: belly transition less conspicuous, but
arm/body lighting discontinuity persists and material remains opaque yellow
plastic. Removing one old modifier is not a full side-view repair. Do not
promote. Three frames0/90/180 captured per test; only0 visually inspected.

These isolated shader-basics tests preserve all geometry, eyes and historical
versions. No production changes. Next isolate direct-light body response versus
transmitted-light response around the arm boundary; retain the connected core
as a depth cue only, not proof of translucent or flowing liquid quality.

## OM–OO — wrapped diffuse creates red creases; removing hue switch is partial

Previous turn classification: progress (OJ/OK substrate isolation, OL integration).
OM retains OL but removes glow+xmit from scaled_body_light; ON removes body_lit
instead. Both retain all reflection/emission, so neither is a pure isolated
lighting buffer and their images cannot simply be summed (peak limiter remains).
Native captures clean10.476 and9.354 seconds. Frame0 inspected in each. OM
retains pronounced red arm/foot creases; ON is dark brown with gold edges and
additional broad shade regions. Transmission removal does not remove the red
crease, and transmission alone is not a reference-quality replacement.

OO returns to full OL and changes wrapped diffuse from front surface color plus
deep-red bleed to v_surface_color*wrapped. Clean10.017 seconds. Frame0 inspected:
red creases become less conspicuous brown/gold shadow, but broad shoulder/arm
boundary persists and body remains solid yellow/plastic. This is an artistic
wrap adjustment, not physical SSS, energy conservation, or complete seam repair.
It removes the unrelated red hue switch, not all geometric lighting contrast.

All tests captured0/90/180; only0 visually inspected. No animation/performance
acceptance. Shader-basics guided isolated Body changes; eyes, geometry, earlier
versions and production preserved. Further improvement must address remaining
normal/light-response boundary and genuine interior transport; no promotion.

## OP–OQ — no visible macro-normal split; rolloff does not remove shoulder band

Previous turn classification: progress (OM/ON separation and OO hue continuity).
OP displays base_n*.5+.5 unshaded with zero emission on Body, retaining faces.
Native capture clean10.283 seconds; frame0 inspected. Macro-normal colors vary
smoothly through the shoulder region where beauty has a hard-looking shade
boundary. This visual evidence does not justify a mesh-normal rewrite; it is
not a numerical mesh continuity proof or all-frame verification.

Read prior KE direct-knee test before proceeding. OQ instead tests full-range
rational direct-light rolloff c*budget/(budget+max(c)), replacing only the final
DIFFUSE_LIGHT limiter on OO. Clean9.521 seconds. Frame0 inspected: overall
direct contribution darkens, but shoulder band remains visible. Thus this
rolloff change does not solve the boundary; do not promote it or compensate
brightness until the actual source is isolated. Reflection paths unchanged.

Both captured0/90/180; only0 inspected. No reference, animation, or performance
acceptance. All versions and production preserved. Next inspect thickness-driven
v_hot/local_exposure_scale and transmission coupling; don't repeat mesh smoothing
or scalar brightness tuning without new evidence. Goal remains incomplete.

## OR–OS — exposure mask and transmission hue do not explain shoulder boundary

Previous turn classification: progress (OP normal evidence, OQ limiter test).
OR extends OO, replacing only mix(1,thin_budget_scale,v_hot) with1 in local
exposure. Clean9.779 seconds; frame0 inspected, shoulder band persists. Read
actual hot expression: Fresnel/curvature band and optional feature AO, NOT
directly measured ray thickness. Correct the earlier shorthand hypothesis
that this was a direct thickness-to-exposure path.

OS extends OR and replaces only xmit_col with constant(1,.45,.01), preserving
directional transmission weights, hot, substrate and reflection. Clean9.495
seconds. Frame0 inspected: transmitted hue changes but shoulder band persists.
Thus path-dependent transmission hue is not sufficient to explain that band.
Neither diagnostic is a physical fix or a reference-quality improvement.

Both captured0/90/180, only0 visually inspected. Production and all versions
preserved. Next stop broad scalar sweeps: obtain separate raw light/normal-dot
buffers around the boundary, including remaining emission, to identify the
specific contribution before more beauty edits. Genuine translucency, flow,
reference fidelity and animation acceptance remain unproven.

## OT–OU — separated emission and diffuse both contain broad bands

Previous turn classification: progress (OR/OS ruled out two sufficient causes).
OT initially used unshaded ALBEDO=0 while retaining EMISSION: clean process
9.958 seconds but Body black. Invalid emission diagnostic; do not infer emission
is absent. Corrected to ALBEDO=EMISSION then EMISSION=0 in a fresh ot-r2 output,
preserving the first output. Clean9.092 seconds; frame0 inspected. Studio
patterns and broad red/orange bands are visible in emission alone.

OU retains lit OO and zeros Body EMISSION and custom SPECULAR_LIGHT. Clean
9.705 seconds; frame0 inspected. Shoulder band clearly remains in diffuse plus
transmission without white reflection patterns. Thus there are contributions
in both groups, not a single reflection-only problem. Face shaders unchanged.
These are displayed diagnostic buffers, not linear HDR compositing evidence;
do not sum sRGB images or assume matching tonemapping.

All captured0/90/180; only0 inspected. Native light creation inspected: no
explicit shadow enable in JC. Don't claim shadow settings verified at runtime.
Next inspect shared color/filter inputs and separate raw diffuse dot-light
response. No production changes, no promotion, all versions retained. Goal
remains incomplete; visual/flow quality is not established by process health.

## OV — raw Lambert baseline distinguishes shape shading from material bands

Previous turn classification: progress (OT corrected emission buffer, OU diffuse
buffer). Read absorb_filter: uniform body hue normalized and mixed by uniform
absorption, not a spatial band generator itself. Read peak_limit: exponential
soft knee, not a discontinuous hard clamp. OQ already showed that replacing
direct limiter alone does not solve the shoulder band; do not repeat that claim.

OV extends OU, replaces last light() with equal-weight .25*max(NdotL,0) for
each light, ignores color/attenuation/wrap/limiter/transmission, retains zero
Body emission and specular. Guard asserts function replacement boundary.
Clean capture10.092 seconds. Frame0 inspected: shoulder has broad geometric
shading variation but not the flat golden material band appearance. This is
evidence of material amplification, not proof of perfect mesh smoothness.
Faces retain their original shaders and should be excluded from interpretation.

Frames90/180 captured, not inspected. No production edits or promotion; all
versions retained. Use OV as a geometric-light baseline for rebuilding the
material response without conflating genuine form shading with a tear. Overall
reference fidelity, translucent interior and liquid movement remain incomplete.

## OW — stripped layer candidate reduces flat-band contrast but loses gel cues

Previous turn classification: progress (OV geometric-light baseline).
OW extends OO, keeps only analytic studio reflection in emission, replaces
light() with .4*v_surface_color*clamp((NdotL+.25)/1.25,0,1)*LIGHT_COLOR*
ATTENUATION/PI. Removes old local exposure/limiter/glow/xmit and direct specular;
retains core-depth substrate, geometry and eye materials. This is a multi-change
material rebuild candidate, NOT a one-variable cause isolation or physical gel.

Clean native capture10.713 seconds. Frame0 inspected: broad shade transitions
less conspicuous than OO, but still visible around shoulder, with darker arm/foot
undersides. Body remains opaque yellow and studio patterns remain overly broad.
Removing the old stack does not achieve reference translucency and loses the
golden transmitted edge cues. Do not promote as an improvement in full fidelity.
Frames90/180 captured, not inspected; no animation or performance acceptance.

All versions and production preserved. Keep OW as a simpler material baseline
for adding genuine transport, not as an acceptable final replacement. Goal
remains full reference-quality character with continuous liquid motion.

## OX — current-geometry light intervals for renewed transport work

Previous turn classification: progress (OW stripped candidate, not accepted).
Inspected actual MB matched-light and MC scattering code; earlier guessed MB
filename did not exist. MB captures old LR geometry/frame43, so those textures
must not be reused for current OW geometry/idle. OX ports MB orthographic depth
capture hooks onto OW, with no beauty render, frames0/90/180. Second directional
source camera(-25,150,0), size2.5, positive view-Z RGB24 range0..8. Final camera
metadata explicitly supersedes inherited side-view metadata.

Clean native capture8.059 seconds. Body.res byte hashes differ from OW; direct
Godot resource verification then compared ALL surface arrays exactly for Body,
BodyShell and MouthCavity, all matched. File hash alone is not mesh equivalence.
Verifier: tools/verify_light_geometry_ox.gd (headless success).

RGB24 numerical checks: paired pixels per layer at0:259217/13714/9;
90:259273/13788/11;180:259468/13866/11. No reversed paired intervals; subsequent
paired fronts strictly beyond previous backs. Unpaired counts zero except
frame180 layer2 has5 pixels. Therefore not a completely clean occupancy map:
consumer must validate pairs; investigate edge pixels before broad acceptance.
No visual beauty, scattering integration, flow or performance acceptance here.

All prior outputs preserved, production unchanged. Next use current valid light
intervals to evaluate transport on OW rather than resurrect old misaligned maps.
Goal remains reference-quality translucent flowing character, not depth capture.

## OY — current light-map single-scatter contribution integrated; first-frame anomaly

Previous turn classification: progress (OX maps and exact geometry-array check).
OY extends OW, samples frame-matched OX second-light intervals, rejects any
unpaired column, integrates homogeneous unit-density single scattering over
24 view samples. Sigma(.45,2.1,6), scalar scatter coefficient.35, source3.5,
isotropic phase1/(4PI). Unlike older MC, incident and outgoing paths use the
same unit density. Adds contribution to OW emission. Still lacks refractive
boundary transport, multiple scattering, first-light scattering and consistent
volume-driven appearance throughout; not a full physical gel or moving density.

Clean native capture10.866 seconds. Frame0 inspected: subtle lightening, still
opaque yellow/plastic with broad patterned highlights. All18 camera depth maps
hash-identical to OW. Compared to OW, changed pixels at0/90/180:
523120/522773/522851; max positive RGB8 delta57 each. Minimum delta at90/180 is0,
but frame0 has negative deltas down to-36, inconsistent with a purely additive
effect. Needs investigation before attributing all frame0 change to scattering.
These are quantized image differences, not perceptual quality or HDR verification.
Frames90/180 not visually inspected. Consumer rejection does not repair OX's5
unpaired pixels. No production promotion; all prior versions preserved.

## OZ — same-run scatter ablation stable after additional render settling

Previous turn classification: progress (OY integration exposed frame0 anomaly).
OZ adds gain uniform and frozen on-a/off/on-b captures in the same scene/light
setup after parent capture. Three redraws initially: clean11.944 seconds but
frame0 repeats differ at2565 pixels, delta range-24..36; on-b minus off has461
negative pixels. Frames90/180 repeat exactly and are nonnegative. This is an
actual failed repeatability test, not evidence of negative physical scattering.

Retained output; changed settle count3 to12 and reran to oz-r2. Clean10.047
seconds. All three frames enabled repeats exactly equal; on-minus-off entirely
nonnegative. Changed pixels523076/522773/522851, max RGB8 delta57 each. Supports
render/resource settling hypothesis, not a proven underlying driver cause or
universal12-frame guarantee. New check_scatter_repeat_oz.py preserves exact
repeat, nonnegative contribution and nonzero effect gates for these captures.

No new visual-quality claim: this validates measurement stability, not reference
fidelity, physical completeness or continuous liquid animation. All versions
preserved and production unchanged. Use settled comparisons for further optical
work; avoid cross-run first-frame attribution without this check.

## PA–PB — both directional sources integrated; warmup gate revisited

Previous turn classification: progress (OZ same-run verification).
OX gained a default-preserving source-rotation hook; PA uses(-35,-30,0) for
the first light, current OW geometry, frames0/90/180. Clean7.997 seconds. PB
reads actual PA camera axes and duplicates the validated interval lookup with
separate samplers. Adds source2.5 single scattering alongside existing3.5 source,
same homogeneous density/sigma and rejection rules. Both contributions use
the same gain for on/off/on tests. PA occupancy not independently audited yet.

First PB clean11.503 seconds but frame0 repeat assertion failed despite12 draws.
First on-a frame0 viewed: still opaque yellow, no reference acceptance. Retained
all outputs. Added optional first-frame wall-clock warmup to OZ (default0 keeps
old behavior); PB-r2 uses2000ms of active redraw before existing12-draw captures.
Native rerun clean11.956 seconds. Repeat verifier passed all three frames:
exact enabled repeats, zero negative on-minus-off channels, changed pixels
525221/524780/524852, max RGB8 deltas73/73/72. R2 images not visually inspected.
This addresses warmup robustness, not a proven
driver diagnosis. Do not equate either clean process with successful visuals.
Further transport completeness and liquid motion remain unfinished; production
unchanged and every historical version retained.

## PC — volume without opaque substrate remains too dark; PA validity audited

Previous turn classification: progress (PA/PB integration and repeat checks).
PB-r2 on-a0 directly inspected this turn: still opaque yellow. PC zeros only
the OW diffuse contribution, retaining two-source homogeneous single scatter
and analytic studio reflection. Clean13.564 seconds. Settled on/off/on verifier
passes all0/90/180, changed pixels525401/524973/525011, max RGB8 delta95 each.
Frame0 on-a inspected: dark brown with some thickness separation, not reference
orange jelly. This reproduces the insufficient-radiance appearance seen in
older scattering work, now with aligned geometry/two lights/stable captures.
Do not promote or call this visual success merely because numerical gates pass.

PA RGB24 interval audit: paired counts0:289500/8648/4;
90:289752/8600/12;180:289309/8640/7. No reversed pairs and paired subsequent
fronts beyond previous backs. Two unpaired layer2 pixels at180; other counts0.
Existing OY/PB lookup rejects incomplete columns; this is not repaired geometry.

Only frame0 visually inspected. No reference/animation/performance acceptance.
Next assess incident radiance/scattering versus absorption and missing boundary
transport; don't restore a dominating opaque substrate as a substitute for gel.
All versions retained; no production changes.

## PD–PF — light-unit calibration corrected; visual target still unmet

PD isolates LIGHT_COLOR/(32*PI), while PE substitutes vec3(3/32) per
directional source (two lights, energies2.5 and3.5). Native captures clean
9.970/9.077 seconds. All three frame images are pixel-identical between PD
and PE, consistent with Godot's documented LIGHT_COLOR energy-times-PI
convention: https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html
This checks this renderer/rig's convention, not absolute physical calibration.

PF extends PC and only changes the two scattering source factors from
energy/(4*PI) to energy/4, incorporating that convention. Clean12.538 seconds.
Read-only settled on/off/on verification passes at0/90/180: exact enabled
repeats, nonnegative contribution, changed pixels525434/525015/525052,
maximum RGB8 delta162 each. No production material promotion.

PF frame0 directly inspected: brighter orange-brown body, but broad rippled
white reflection patches, dark/gray extremities, flat oval eyes and conspicuous
arm/body tonal boundaries remain. It does not yet resemble the requested clear
orange jelly. Frames90/180 verified numerically, not visually accepted. These
homogeneous scattering tests do not establish moving internal liquid or viscous
animation quality. All historical versions preserved.

Next work should resolve reference-visible appearance: isolate the broad coat
reflection from transmission, verify against the same reference/view, and only
then integrate animated density. Do not mistake light-unit consistency or a
clean capture for reference, animation, gameplay-GPU or release acceptance.

## PG–PH — coat-normal ablation and frontal reference comparison

Previous turn: progress (PF unit consistency verified, visual failure recorded).
PG changes only analytic studio reflection direction/Fresnel to base_n; it
preserves PF transport, geometry, eyes and lighting. Clean13.597 seconds.
Repeat verifier passes0/90/180; changed pixels525598/525169/525206, max delta162.
Frame0 inspected: rippled patches become smooth broad reflections but the body
remains brown/plastic. Removing coat detail alone is not the reference solution;
reference itself has fine wet relief. Keep PG diagnostic, not a promoted look.

PH extends PF (not PG), restores frontal camera(0,1.898,4.453) and matched
view-ray origin, recaptures all view depth intervals. Light maps stay source-
matched to unchanged geometry. New reference-camera.json explicitly overrides
inherited side-camera metadata. Reference camera unknown; approximate framing,
not calibrated image registration. Clean13.735 seconds. Repeat checks pass
0/90/180, changed585374/585503/585159, max deltas150/150/151.

Reference and PH frame0 directly inspected. Slanted eyes are present frontally,
so the earlier side-view oval-eye observation should not imply absent slant.
However eyes lack reference's substantial orange rims/layered depth. Arms are
thicker, the golden translucent edge is absent, and the whole body is dull
brown rather than luminous orange/red. Wet relief is concentrated in fragmented
white patches instead of the reference's distributed fine facets. Pore rim is
also too weak. These are material AND shape shortcomings, not fixed by the
successful numerical checks. No visible extra cell in this still; not evidence
for all14 animations. Frames90/180 not visually accepted.

Next prioritize actual transmitted illumination/boundary treatment and frontal
reference color/edge depth, retaining fine coat detail rather than deleting it.
Then address eye/pore rims and limb proportions with corresponding shape tests.
All earlier versions retained; production unchanged; no release acceptance.

## PI–PJ — straight-ray transmitted background diagnostic, not shipping refraction

Previous turn: progress (PG coat isolation and PH frontal comparison).
PI extends PH and adds white radiance2 multiplied by exp(-sigma*distance),
sigma(.45,2.1,6), using all three valid occupied view intervals and rejecting
incomplete/out-of-order columns. Formula basis: homogeneous beam transmittance,
https://pbr-book.org/4ed/Volume_Scattering/Transmittance . This deliberately
overrides background visibility only for body transport while keeping primary
background black. It is a diagnostic, not a real scene emitter, scene occlusion,
refractive boundary, energy-consistent dielectric or production gel material.
No Fresnel boundary losses/refraction/multiple scattering are implemented here.

PI on/off/on now toggles ONLY this background term; existing two-source scatter
stays on. Clean13.635 seconds; exact repeats/nonnegative deltas all0/90/180,
changed pixels585035/585133/584712, max RGB8 delta255. Frame0 viewed: grossly
overexposed yellow/white limbs, failed visual result. Preserved intact.

PJ changes only diagnostic background radiance2 to.65. Clean12.986 seconds.
Repeat checks pass same changed counts, max delta211 each. Frame0 viewed:
less overexposed, orange center and paler limbs, but pale/gray edges and flat
interior still do not match saturated translucent orange reference. Broad coat
patches and missing facial rims persist. Merely adding uniform transmitted
illumination is insufficient; do not promote PJ as reference-matched jelly.
Frames90/180 not visually accepted. No dynamic-density/animation acceptance.

This isolates a missing illumination contribution without proving the reference
lighting setup. Next needs actual boundary/refraction and scene illumination
treatment, not another unexplained global brightness multiplier. All versions
retained and production unchanged.

## PK–PL — entry-refracted path prototype and identity-IOR control

Previous turn: progress (PI/PJ transmitted background isolation).
PK extends PJ, changes the background attenuation distance to an entry-refracted
ray (IOR1.33, macro normal). Marches current frame's three view-space peeled
occupancy intervals in.025 increments up to2.402, refines the first exit with
8 binary steps. Initial probe.002; incomplete/unordered/offscreen/missed paths
return no new background contribution, not invented exits. Refraction basis:
https://www.pbr-book.org/4ed/Reflection_Models/Specular_Reflection_and_Transmission .
This is still first-exit screen-space geometry, NOT complete dielectric transport:
no exit normal/refraction/TIR/re-entry, boundary Fresnel or consistent refracted
single scattering. Existing scattering remains unrefracted, background override
remains diagnostic. No production promotion.

PK clean14.427 seconds, repeated on/off/on checks pass0/90/180, changed pixels
585032/585127/584710, max RGB8 delta206/207/207. Frame0 viewed: less pale outer
rim but distinct inner-foot tonal regions and orange flat interior remain.
Not accepted. No proof that every band is a bug; first-exit limitations need
further analysis rather than color changes to mask them.

PL changes only entry IOR to1.0 as straight-ray control. Clean13.611 seconds;
repeat verifier passes, changed584993/585084/584666, max211/211/210.
Compared PL on-a to PJ on-a where PJ has background contribution and no second
interval, eroded2px: masks574472/574294/573677 pixels. Mean absolute RGB8
error.002891/.003262/.002274, p99=0 each; pixels with any error>2:3/4/1,
max210/210/134. Off images exactly equal each frame. Thus most single-interval
paths agree with the analytic straight-ray control, but severe sparse misses
remain. Does not validate refracted first-exit completeness or all geometry.
PL not visually inspected. All historical versions retained, no animation or
real-gameplay performance/reference acceptance. Next inspect rejected paths
and exit/re-entry geometry before treating this prototype as real gel optics.

## PM–PN — thin entry probe failure located and bounded correction tested

Previous turn: progress (PK entry refraction and PL identity control).
Located all8 PL-vs-PJ single-interval errors>2: near-mouth pixels with measured
thickness1.19e-5..5.48e-5, much smaller than the fixed.002 initial probe.
PL returned its off value there. PM anchors ray start to quantized jc_entry
and sets initial distance=min(.002,first_interval_length*.25); retains all
subsequent rejection rules. PN is its identity-IOR control. Old versions intact.

PN clean14.372 seconds, repeated on/off/on passes0/90/180. Against PJ using
the same two-pixel-eroded single-interval masks574472/574294/573677, max RGB8
error now1 each, no errors>2, mean.001983/.001955/.002048. Off images exactly
equal. This fixes the observed sparse failure in this control, not every thin
feature/refracted ray or underlying mesh issue. Very thin near-mouth intervals
may themselves deserve geometry audit; matching them does not prove topology.

PM native capture clean13.755 seconds. Repeats pass0/90/180, changed pixels
585035/585132/584712, max delta206/207/207. Frame0 inspected: inner-foot bands,
flat orange fill and broad white patches remain; no reference acceptance.
First-exit/refraction limitations of PK
remain: no exit boundary, TIR/re-entry, and scattering still follows the original
view ray. No production promotion or full-reference/animation/GPU acceptance.
All earlier versions retained.

## PO–PP — exit boundary attenuation exposes missing reflected paths

Previous turn: progress (PM/PN adaptive entry validated in identity control).
PO estimates exit normals via central differences(h=.003) of signed radial
interval field, applies exact unpolarized entry/exit Fresnel for IOR1.33 to
the diagnostic background term. Unsupported field neighborhoods rejected.
Total internal reflection removes direct background, but reflected rays are
NOT traced; neither re-entry nor scene-dependent outgoing illumination exists.
Scattering/reflection layers remain otherwise unchanged, so this is not a
complete energy-consistent dielectric. Field is not a Euclidean SDF.

CPU algebra sanity check: normal incidence F=.020059312199524774 both
directions, cosine.5 exiting gives TIR, values bounded0..1 for1001 cosine
samples both ratios. This checks formula only, not GPU normal accuracy.
PO clean14.363 seconds; repeats pass0/90/180, changed441221/442556/443078,
max deltas173/173/161. Frame0 inspected: severe dense edge contour noise,
dark feet and brown bottom band; rejected visual result.

PP changes only normal-field depth sampling to decode RGB24 first, then
bilinearly interpolate four valid neighboring depths. Mixed absent/present
footprints rejected; no interpolation of packed RGB values. Exit marching
still nearest. Clean13.930 seconds; repeats pass0/90/180, changed pixels
444566/445740/445924, max deltas173/173/161. Frame0 inspected: dense contour
noise substantially reduced, but hard dark regions on head/limbs/feet persist.
This supports depth-derivative discretization as a noise contributor, not a
proof of correct exit normals. Dark regions may include TIR AND invalid normal
neighborhoods; these require separate classification before attribution.

No visual/reference acceptance; frames90/180 numerically checked only. Next
separate rejection from TIR and account for reflected paths rather than remove
boundary attenuation merely to brighten the image. Production unchanged and
all old versions retained. Animation/real gameplay GPU work still incomplete.

## PQ–PR — dark-region classification and one internal bounce

Previous turn: progress (PO/PP boundary prototype and normal filtering).
PQ emits unshaded RGB labels from PP's actual branches. Clean13.625 seconds;
all on-a/off/on-b images exactly equal for each frame. Frame0 directly viewed.
Counts0/90/180: input-invalid0/0/0, path-miss0/1/0, invalid-normal13/35/22,
non-outward39/55/22, computed-TIR140561/139452/138920,
direct446240/447482/447789. The large head/feet regions classify as TIR, not
missing data. These are algorithm classifications, not independent validation
of exit normals or physical correctness. Other pixels are face/background.

PR extends PP and adds one internally reflected segment, attenuated by total
traveled distance and entry-transmission * first-exit-reflection * second-exit-
transmission. Uses reflected direction and the existing first-exit marcher,
offset inward.001 plus initial probe.0005. These new fixed offsets are not
independently validated for thin geometry. No further bounces or re-entry;
unrefracted scattering and diagnostic uniform background remain limitations.

PR clean17.259 seconds; on/off/on passes0/90/180, changed531476/532300/531777,
max RGB8 delta174/174/164. Frame0 inspected: some previously dark areas regain
orange contribution, but strong foot striping, hard patches and head seams
remain. Reject visual promotion. More paths alone do not solve discrete
occupancy/exit accuracy; isolate reflected-ray stepping/normal stability before
adding more bounces. No reference match, animation or gameplay GPU acceptance.
Production unchanged; all prior versions retained.

## PS–PT — consistent occupancy sampling reduces stripes; convergence incomplete

Previous turn: progress (PQ classifications and PR reflected contribution).
PS extends PR, moves existing pp_depth helper before occupancy, and uses its
decoded bilinear depths for pk_inside as well as po_field. Retains strict mixed-
footprint rejection and all other transport parameters. Clean20.393 seconds.
On/off/on passes0/90/180, changed537016/537805/537239, max174/174/164.
Frame0 inspected: dense central-foot stripes markedly reduced compared with PR,
but hard foot patches, head seams, dark hand tips and flat interior remain.
This supports mismatched nearest occupancy versus filtered normals as a stripe
contributor, not complete ray/normal accuracy or reference acceptance.

PT halves marching step.025 to.0125 and doubles limit96 to192, preserving
extent/bounce count and8 binary refinements. Clean22.445 seconds; repeats pass,
changed537054/537788/537260, max174/174/164. PS/PT off images exactly equal.
Across PS nonblack pixels609294/609524/609249, mean absolute RGB8 differences
.019332/.022623/.019702, p99=0, but max137/142/144 and pixels with any
channel difference>2:1038/1099/1191. Therefore a small but materially unstable
subset remains; low mean error is NOT a convergence pass. PT not visually
inspected. Localize those discontinuities before using increased sampling as a
quality claim. Capture wall times are not gameplay GPU frame measurements.

No production promotion. All historical versions retained. Actual reference
fidelity, liquid animation, gameplay GPU and release gates remain incomplete.

## PU–PV — finer exit refinement does not resolve path discontinuities

Previous turn: progress (PS sampling consistency; PT non-convergence exposed).
Localized PS/PT errors>2: bbox spans roughlyx96..924,y58..935 across frames;
only249/238/221 affected pixels belowy700. Maxima near(x495,y858)/(494,859),
where RGB drops from about(166,72,18) to(29,20,16). Not just subtle color drift.

PU changes only PS binary exit refinement8 to12. PV additionally halves main
step and doubles its count, matching PT extent. Clean21.291/23.164 seconds.
Both repeated on/off/on pass0/90/180. PU changed537013/537807/537225;
PV537055/537789/537266; max additive deltas174/174/164 both. Off images equal.
PU/PV nonblack-mask mean RGB8 error.017262/.020226/.017598, p99=0, maxima
137/142/144. Pixels>2 now924/1000/1103 versus1038/1099/1191 previously.
Minor improvement, but maximum failures unchanged: exit refinement precision is
not the main cause. Do not continue increasing binary iterations as the fix.

PV frame0 viewed: strong hard foot/head patches and flat interior persist,
not reference jelly. PU not visually inspected. Next examine traversal branch
rejection/skipped intervals at the identified worst pixels; strict mixed-depth
footprint rejection and fixed reflected-origin offsets remain unvalidated.
All versions preserved, production unchanged, no reference/animation/GPU gate
passed by these diagnostic comparisons.

## PW–PY — major discontinuity traced to reflected interpolation rejection

Previous turn: progress (PU/PV rejects precision-only explanation).
PW instruments PU marcher stage failures and final reflected-path state;
PX uses half step as PV. Unshaded grayscale status/64, decoded through inverse
sRGB. Clean19.257/21.142 seconds. For each frame all on-a/off/on-b exactly
equal. This is branch telemetry, not a beauty improvement.

Worst pixels(x495,y858) at0 and(494,859) at90/180 change from status33
(reflected transmission) to22(reflected coarse march invalid). Among PU/PV
error>2 pixels,22->33 counts517/546/574;33->22 counts105/151/279.
Other cases include same33 with differing radiance, second-exit TIR and normal
rejection. Thus the largest jump is not the primary entry or binary precision.

PY further distinguishes half-step reflected march errors: projection41,
invalid interpolation footprint42, unpaired43, ordering44. Clean22.229 seconds;
all on-a/off/on-b exactly equal each frame. All three worst pixels are42.
Of pixels decoded22 in PX,13325/13785/14256 decode42 in PY;16/16/13 remain22.
These counts lack a face-exclusion mask, so the small residual cannot be
interpreted as branch behavior (unchanged facial grayscale can decode as22).
The known body worst-pixel result directly supports invalid interpolation
footprint rejection. pp_depth's invalid footprint includes mixed presence and
image-border support; further discrimination may be useful before generalizing.

Next repair traversal around unsupported depth footprints rather than silently
treating unknown geometry as empty, disabling Fresnel or raising brightness.
Preserve rejection telemetry for regression. No visual, physical path, animation
or gameplay GPU acceptance. Old versions and production remain untouched.

## PZ–QA — search before invalid footprint helps locally, worst jump remains

Previous turn: progress (PW/PX stage instrumentation and PY footprint diagnosis).
PZ extends PU: on a coarse invalid sample, bisects toward the last known inside
sample up to12 times searching for a VALID outside point. Unknown never counts
as outside; if none found, still reject. Existing exit refinement also retains
invalid rejection. QA is half-step control. All earlier outputs retained.

Clean21.201/23.205 seconds. Both on/off/on checks pass0/90/180. PZ changed
537164/537962/537386; QA537144/537890/537366; maxima174/174/164 both.
Off images equal. PZ/QA nonblack mean RGB8 error.013879/.017551/.014144;
pixels>2:784/880/935, down from924/1000/1103. However maxima137/142/144
and all three previous worst-pixel values remain unchanged. Thus bounded
backsearch recovers some paths but is NOT the major discontinuity fix.

QA frame0 inspected: flat orange body, hard limb/head patches and poor reference
match persist. PZ not visually inspected. No promotion or quality acceptance.
Crucially the bright coarse result is not ground truth: it may skip unsupported
footprints that the finer ray encounters. Do not force the fine result to match
it by treating unknown as air. Next use independent mesh intersection or
explicit footprint traversal evidence for worst rays, to distinguish false
coarse acceptance from false fine rejection. Repeatedly changing brightness or
binary precision cannot answer this geometric question.

All old versions/production preserved; animation and gameplay GPU remain untested
for these prototypes. No full-reference or release acceptance.

## QB — measured reflected-ray replay identifies mixed second-layer footprint

Previous turn: progress (PZ/QA limited backsearch, worst failures unchanged).
QB captures reflected origin/direction in view space, each component RGB24
over[-8,8], two repeats per component/frame. Clean24.483 seconds; all18
component pairs exactly equal. Direction lengths within2.1e-7 of1. Native
camera projection logged; CPU replay flips Y to image-row convention and
asserts each measured reflected seed is inside. Encoding resolution~9.54e-7.
This is measured GPU-ray/depth replay, NOT independent mesh intersection.

New read-only tools/meshy/trace_telemetry_qb.py reproduces the crucial branch
difference using the same measured ray with both step sizes. At0 coarse.025
finds outside at distance1.1005; fine.0125 fails at.638 on layer2 front mixed
presence, footprint base(441,558). At90: coarse outside1.0755, fine invalid.663,
base(442,555). At180: coarse outside1.0755, fine invalid.688, base(450,548).
Each offending2x2 layer2-front footprint contains one positive depth and three
zeros, near the mouth. Short-range samples show inside up to the unsupported
footprint; it is not a valid exit missed by PZ's backward search.

The issue involves depth-layer correspondence across neighboring columns, not
simply insufficient binary precision. Next evaluate the union of valid intervals
per pixel before interpolation, rather than interpolating ordinal layer slots
whose presence changes across a tiny feature. Validate corner intervals and
the same worst rays; do not invent absent geometry. Existing rejection/debug
versions retained. No beauty improvement claimed this turn; no model/reference,
animation or gameplay GPU acceptance. Production unchanged.

## QC–QD — union-before-interpolation fixes the three traced failures

Previous turn: progress (QB measured-ray replay located slot correspondence).
QC evaluates signed radial union of valid intervals independently at each of
four neighboring pixels, THEN interpolates the scalar field. Both occupancy
and normal estimation use it. Invalid/empty corner columns remain unsupported;
no fabricated depths. This is a sampled implicit field, not exact mesh geometry
or Euclidean distance. QD halves step at same trace extent. Retains PZ backsearch.

Clean22.615/25.711 seconds. Both same-run repeat/additive checks pass0/90/180.
QC changed537448/538227/537698; QD537422/538193/537678. Off images equal.
All three previously traced worst pixels now EXACTLY match between step sizes:
frame0(495,858) RGB166,72,18;90(494,859)167,73,16;180167,74,15.
check_layer_correspondence_qc.py adds that specifically scoped regression.

Full-image nonblack mean differences.004678/.007377/.004126; pixels>2 now
196/222/187 versus784/880/935 in PZ/QA. HOWEVER remaining maxima174/174/128
are still severe (some exceed prior maxima). Full convergence NOT passed.
QD frame0 inspected: major reference mismatch persists—flat orange fill,
hard foot/head patches, pale arms, broad white coat patches and weak eye rims.
QC not visually inspected. This fixes a real diagnosed layer-slot bug, not the
complete aesthetic/optical model. Next inspect remaining severe paths and
missing higher-bounce illumination; don't promote based on this narrow test.
All old versions preserved; production, animation and gameplay GPU gates unchanged.

## QE–QF — four/eight internal segments recover light but remain visually inadequate

Previous turn: progress (QC/QD fixes traced layer correspondence failures).
QE replaces separate first/second paths with a four-segment deterministic loop:
attenuate throughput per segment, add transmitted diagnostic background at each
valid exit, retain Fresnel-reflected throughput and continue. QF permits8.
Cutoff max-throughput<.0001; existing inward.001/seed.0005 offsets retained.
Still no external re-entry, directional environment or refracted volume-scatter
integration. Union-field representation/unsupported silhouettes remain limitations.

QE clean47.733 seconds; QF clean63.077 (guard120 seconds, prior60 unchanged).
Both on/off/on pass all0/90/180. QE changed557515/558039/557444;
QF569116/569545/568950, max deltas163/166/165 both. Off images exactly equal.
QF minus QE entirely nonnegative. Nonblack-mask mean RGB8 differences
.306713/.304885/.304455; maxima124/123/120; pixels>2:16760/16262/15998.
Thus4 versus8 paths NOT converged; zero negative deltas verifies additive
behavior only. These wall times include capture/depth/render scheduling and are
NOT gameplay GPU frame timings, but this is clearly a heavyweight diagnostic.

Both frame0 images inspected: some dark regions gain orange, yet foot bands,
head patches and flat orange/pale-arm appearance remain far from reference.
No visual promotion. More segments alone is not a sufficient quality strategy;
geometry/normal validity, actual environment transport and reference-facing
shape/material work still needed. Do not call this release-ready or fluid motion.
All versions preserved and production unchanged. No reference/animation/GPU gate
completed by these captures.

### QG — static eye underlay: rejected, not promoted

Shifted from optical bounce experiments to reference-facing eye geometry.
`tools/inspect_eye_geometry_qg.gd` confirmed both eye meshes are independent
2208-vertex, single-surface geometry, approximately 0.2314 × 0.1826 × 0.0499.
`gel_eye_rim_qg.gd/.tscn` extends the frontal PH baseline, captures frame 0 only,
and creates two isolated StandardMaterial3D orange underlays by scaling eye XY
1.14 around each AABB center and moving Z back 0.004. Normals are inverse-scale
corrected and stale tangents removed. Underlays are excluded from body depth
capture and do not modify source meshes or production materials.

Native Vulkan capture completed cleanly in 11.039 seconds (process/log health
only). Output: `outputs/v8.6-quality-audit-20260906/eye-rim-qg/`, with baseline,
rim-a, rim-b and scope metadata. Only frame 0 was captured; inherited camera
metadata listing 0/90/180 is not an animation test result. qg-scope.json records
the actual scope.

Visual inspection against CHAR-BASE-T-3d-alt.png rejects this approach: the
orange duplicates occlude substantial black eye regions and create broad flat
orange patches rather than narrow integrated eye rims. Enlarging a complete
curved eye mesh is not a hollow rim and does not preserve a reliable clearance
to the differently deformed eye surface. Do not promote or blindly increase
offset/scale. Next bounded experiment should construct an actual annular rim
from the eye silhouette with an empty center, then validate clearance and shared
deformation in front/side and motion views. Body translucency and wet highlight
quality remain substantially short of reference. All previous versions retained;
no animation, real-time performance, release or reference-match gate passed.

### QH–QI — hollow eye silhouette tube, static prototype only

QH replaces QG's complete underlay with a closed tube around the XY convex hull
of each original eye mesh. Radius 0.006, outward radial offset 0.008, 12 tube
sides; boundary Z comes from the nearest original projected vertex. No central
cap or filled eye surface is generated. Double-sided StandardMaterial3D is used
for this diagnostic; not a production topology/winding acceptance. All original
versions remain unchanged. Only frame 0; no deformation integration is claimed.

QH native capture exited cleanly in 13.181 seconds. Visual inspection shows black
eye faces are preserved rather than broadly occluded as in QG. However, the rim
looks like a thin separate orange wire, not the reference's integrated soft rim.
The brown opaque body and coarse high-contrast highlights remain unresolved.
QH repetition failed: 961 pixels differed, maximum channel delta 76, entirely
within eye-region bounds x262–761/y389–515. Baseline-to-rim changed 5041 pixels.

QI preserves QH geometry and adds 2 seconds of visible rendering before the
baseline/rim capture sequence, to test newly created material pipeline settling.
QI exited cleanly in 13.339 seconds; rim-a and rim-b are bit-identical (zero
changed pixels). This supports resource/pipeline settling as the discrepancy's
cause, but is not a general determinism or performance guarantee. Outputs:
`outputs/v8.6-quality-audit-20260906/eye-rim-qh/` and `eye-rim-qi/`.

Next: replace the wire-like profile with an integrated eyelid transition and
match its deformation to the black eye and body; validate side and motion views.
No production promotion, reference match, animation or release gate passed.

### QJ–QK — broader annular lip and verified winding correction

QJ replaces QI's thin tube with an open annular profile, width 0.03, 16 radial
bands, height 0.012*sin(PI*u)-0.025*u*u. Center remains empty and outer edge is
sunk, not welded to body. Approximate radial normals and StandardMaterial3D
remain diagnostic. QJ clean capture: 13.064 s; repeated rim images identical.
Visual result was broader but had conspicuous black upper edges.

QK reverses QJ triangle winding only. A runtime geometric assertion verifies
every original triangle cross-product aligns positively with its averaged
outward vertex normals (counterclockwise); indices are reversed for Godot's
clockwise front faces. QK completed cleanly in 11.960 s with assertions passing;
rim-a and rim-b identical. Visual inspection shows upper black bands removed,
supporting reversed-face lighting as their cause. This is a mesh defect fix,
not a justification to increase lighting or hide the artifact.

The corrected rim still looks like a separate orange accessory on a brown body,
not translucent skin smoothly surrounding an inset eye. Narrow dark lower edges
and the lack of shared deformation remain unaccepted. Do not promote. Next
integration work must address actual attachment/body surface clearance and
consistent material response, not keep scaling the rim. All tests are frame 0;
no side/motion, 14-animation, real-time GPU or reference-match acceptance.
QK inherits QJ profile metadata; QI tube metadata is superseded by qj-scope.json.
All previous versions and production files preserved.

Reproduction: run the existing `tools/shot.tscn` with
`--scene=res://tools/gel_preview.tscn --family=T` for baseline, adding
`--set=authored_height_depth:0,orange_peel_micro_depth:0` for relief isolation.
For clay use `--scene=res://tools/gel_geometry_audit.tscn`. Supply a new absolute
`--out` directory and unique `--tag` for every run. Use the preserved 4.7.2
binary at `../work/godot-4.7.2/Godot.app/Contents/MacOS/Godot`, project path
`godot/immune`, and resolution `1024x1024`.
