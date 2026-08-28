# Jelly Material V2

Updated: 2026-08-27

## Player-facing intent

The imported immune-cell bodies should read as soft, wet jelly at lineup,
research, combat, and face-close-up distances. B should show a restrained layer
of round air pockets under its membrane without looking diseased, cratered, or
covered in a tiled noise texture. T keeps its authored fine membrane pattern.

## Scope

In this milestone:

- keep the shared wrapped-light, spectral absorption, transmission, rim, broad
  sheen, and coat highlight paths;
- add a UV-free, object-space 3D round-bubble layer;
- centralize family profiles so preview, combat, and duty pieces agree;
- remove the Forward+-only screen-space SSS output from the Compatibility path;
- retain a zero-cost fallback by disabling the bubble layer;
- verify B and T in isolation and in the playable demo;
- measure CPU and wall-frame cost when Compatibility/Metal returns no GPU timer.

Out of scope:

- another paid Meshy generation;
- changing B's topology, normals, silhouette, face, or duty-kit layout;
- alpha-blended refraction, screen-texture refraction, or Forward+-only SSS;
- enabling unreviewed bubble profiles on M, N, A, or D.

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

Family choices live in `characters/gel/gel_profiles.gd`:

| Family | Profile | Bubble layer | Legacy dimples |
|---|---|---:|---:|
| T | `authored_membrane` | Off | On |
| B | `round_bubbles` | On | Off |
| M/N/A/D | `base_gel` | Off | Existing defaults |

Call-site overrides merge last, so diagnostics can disable or isolate one effect
without editing the production profile.

## Quality gates

### Gate 1 — contract

- B material exposes and enables `bubble_enabled`.
- B sets `dimple_depth` to zero.
- T leaves `bubble_enabled` off and retains subtle legacy dimples.
- An explicit call-site override wins over the family profile.

### Gate 2 — shader health

- Godot import and headless smoke complete without shader or script errors.
- Compatibility screenshots no longer emit the Forward+-only SSS warning.
- Bubble-disabled material remains a valid fast fallback.

### Gate 3 — visual review

- B bubbles are round at front, 3/4, side, and back angles.
- No triplanar seams, dark donut field, cracked-net pattern, or visible shimmer.
- At face distance, bubbles remain subordinate to eyes and mouth.
- T retains its authored membrane detail and colour identity.

### Gate 4 — gameplay and performance

- B remains readable in lineup/research and live combat lighting.
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
is claimed. Three 300-frame trials at 1920×1080 with ten B bodies and an explicit
render sync produced these medians:

| Material path | CPU mean | Wall-frame mean |
|---|---:|---:|
| StandardMaterial3D | 0.912 ms | 5.030 ms |
| Wet gel, bubbles off | 0.846 ms | 4.487 ms |
| Wet gel, bubbles on | 0.842 ms | 4.217 ms |

The ordering is within run-to-run noise; the supported conclusion is that this
harness found no measurable regression from enabling bubbles. It does not prove
that the bubble path is faster, and a non-zero GPU capture remains a production
follow-up on another backend.

No Meshy request was submitted and no generation credits were consumed.
