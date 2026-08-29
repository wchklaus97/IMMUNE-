# Jelly Material V2

Updated: 2026-08-29

## Player-facing intent

The imported immune-cell bodies should read as soft, wet jelly at lineup,
research, combat, and face-close-up distances. B, M, N, A, and D show restrained
round air pockets under the membrane without looking diseased, cratered, or
covered in a tiled noise texture. T keeps its authored fine membrane pattern; M
is a lighter lavender than B so the two purple families remain distinguishable.

## Scope

In this milestone:

- keep the shared wrapped-light, spectral absorption, transmission, rim, broad
  sheen, and coat highlight paths;
- add a UV-free, object-space 3D round-bubble layer;
- centralize family profiles so preview, combat, and duty pieces agree;
- remove the Forward+-only screen-space SSS output from the Compatibility path;
- retain a zero-cost fallback by disabling the bubble layer;
- verify B, M, T, and the source-authored N/A/D bodies in isolation and in the
  playable demo;
- measure CPU and wall-frame cost when Compatibility/Metal returns no GPU timer.

Out of scope:

- another paid Meshy generation after the approved M task;
- changing B's topology, normals, silhouette, face, or duty-kit layout;
- alpha-blended refraction, screen-texture refraction, or Forward+-only SSS;
- changing the locked N/A/D silhouette after the reviewed authored-body pass.

## Visual pillars

1. **Soft volume:** colour deepens through thick areas and brightens at thin edges.
2. **Wet surface:** one broad coloured sheen and one tight neutral coat highlight.
3. **Round pockets:** sparse circular features remain round from front, side, and back.
4. **Readable face:** bubbles do not compete with the black eyes or mouth.
5. **Web-safe restraint:** no alpha sorting, extra geometry, UV requirement, or screen read.

## Technical design

`wet_gel.gdshader` samples eight bounded neighbouring lattice cells in object
space. Each active cell owns one jittered sphere. A mesh surface that intersects
that volume receives:

- a smooth spherical cap used for a shallow normal perturbation;
- a soft shell with a very small absorption shadow;
- a shorter fake optical path, so the pocket is slightly brighter and less saturated;
- a tiny interior glow, bounded by the existing hue-preserving energy ceiling.

Eight samples are sufficient because profile limits keep centre jitter at or
below 0.20 cell and radius at or below 0.48 cell. A more distant lattice cell
cannot touch the point being shaded. This avoids a 27-sample 3D Worley search.

Generic/imported family choices live in `characters/gel/gel_profiles.gd`; the
reviewed N/A/D production overrides live in `characters/authored_jelly_body.gd`:

| Family | Profile | Bubble layer | Legacy dimples |
|---|---|---:|---:|
| T | `authored_membrane` | Off | On |
| B | `round_bubbles` | On | Off |
| M | `macrophage_bubbles` | On | Off |
| N/A/D production bodies | `authored_fizzy_zero_credit` | On | Off |

Call-site overrides merge last, so diagnostics can disable or isolate one effect
without editing the production profile. N/A/D are intentionally authored-body
profiles in `characters/authored_jelly_body.gd`, not generic procedural-kit
profiles; their legacy fallbacks remain unchanged.

## Quality gates

### Gate 1 — contract

- B, M, N, A, and D production bodies expose and enable `bubble_enabled`.
- B, M, N, A, and D production bodies set `dimple_depth` to zero.
- T leaves `bubble_enabled` off and retains subtle legacy dimples.
- An explicit call-site override wins over the family profile.

### Gate 2 — shader health

- Godot import and headless smoke complete without shader or script errors.
- Compatibility screenshots no longer emit the Forward+-only SSS warning.
- Bubble-disabled material remains a valid fast fallback.

### Gate 3 — visual review

- B, M, N, A, and D bubbles are round at front, 3/4, side, and back angles.
- No triplanar seams, dark donut field, cracked-net pattern, or visible shimmer.
- At face distance, bubbles remain subordinate to eyes and mouth.
- T retains its authored membrane detail and colour identity.

### Gate 4 — gameplay and performance

- B, M, N, A, and D remain readable in lineup/research and live combat lighting.
- Ten-character stress measurements are repeated; median CPU and wall-frame
  values are reported. GPU results are reported only when the backend returns a
  non-zero timer.
- Web tests/build, Godot smoke, overflow, and sequential platform exports pass.

## Failure protocol

On any failed gate:

1. stop before the next stage;
2. preserve the last known-good baseline;
3. identify whether the defect is distribution, relief, colour/absorption,
   renderer support, instrumentation, or integration;
4. change the smallest parameter or layer that addresses that cause;
5. rerun the failed gate before broader regression work.

Do not submit a paid generation or compensate for a material defect by changing
the model until the shader path and profile have been isolated and reviewed.

### N/A/D authored production integration

On 2026-08-29, N/A/D were promoted from generic procedural blockouts to
source-authored high-resolution primitive bodies using the accepted Fizzy core
and clear membrane. N keeps the lime grounded silhouette and pill mouth; A keeps
the amber footless hover and relay-only duty; D keeps the deeper orange grounded
silhouette and five-lobe crown. Six angles and fixed/mobile/boss captures passed,
and expanded smoke now locks material layers, membrane shader, silhouette nodes,
duty visibility, and shadow settings. All three Meshy manifests were exercised
only in dry-run mode and reported zero network calls and zero credits.

## 2026-08-27 execution record

### Visual tuning

- Baseline B was a smooth purple wet-gel body without readable air pockets.
- Pass 1 used a strong shell shadow and negative relief. Multi-angle review
  rejected it because the bubbles read as dark donut craters.
- Pass 2 reduced density and shell shadow, changed the relief to a shallow
  positive lens, and increased the local thin-path cue. Front, 3/4, side, back,
  face, and face-3/4 views passed without seams or face competition.
- T's six review angles retained its authored membrane detail with bubbles off.

### Gameplay defect found by Web QA

Switching B to mobile duty initially revealed large triangular dark wedges over
the floor and lane. Camera transforms, mesh bounds, particles, and viewport
readback were isolated first. A controlled comparison that disabled only 3D
shadows restored the stage, proving that the newly visible procedural
`LocomotionKit` was the caster. Cosmetic mobile accessories now use
`SHADOW_CASTING_SETTING_OFF`; the character body and scene lights keep normal
shadows. A smoke assertion and both headed Godot and exported-Web screenshots
cover the regression.

### Performance

Compatibility/Metal on Apple M4 Pro returned a zero GPU timer, so no GPU number
is claimed. A 2026-08-28 repeat used three synced 300-frame trials at 1920×1080
with ten B bodies and produced these medians:

| Material path | CPU mean | Wall-frame mean |
|---|---:|---:|
| StandardMaterial3D | 1.035 ms | 3.617 ms |
| Wet gel, bubbles off | 1.053 ms | 4.070 ms |
| Wet gel, bubbles on | 1.035 ms | 3.892 ms |

The ordering is within run-to-run noise; the supported conclusion is that this
harness found no measurable regression from enabling bubbles. It does not prove
that the bubble path is faster, and a non-zero GPU capture remains a production
follow-up on another backend.

### M integration and performance

The approved M Image-to-3D task consumed 5 credits. Its geometry passed silhouette
and face-count checks but omitted normals, so the workflow preserved the original
download and generated smooth normals locally without changing its 8,832 triangles
or bounds. Visual pass 1 exposed flat shading and a duplicate procedural mouth;
pass 2 disabled the legacy triplanar dimple normal and used round bubbles; pass 3
added smooth normals; pass 4 separated M from B with a pale-lavender colour ramp.
Front, 3/4, side, back, face, MISSION-06 fixed, mobile, and boss views then passed.

Three synced 300-frame trials at 1920×1080 with ten M bodies produced:

| Material path | CPU median mean | Wall-frame median mean |
|---|---:|---:|
| StandardMaterial3D | 0.969 ms | 4.266 ms |
| Wet gel, bubbles off | 0.926 ms | 4.076 ms |
| Wet gel, bubbles on | 0.963 ms | 4.306 ms |

Compatibility/Metal again returned a zero GPU timer. The differences are within
run-to-run noise; this harness found no measurable bubble regression but does not
claim the bubble path is faster.
