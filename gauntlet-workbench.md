# Gauntlet workbench — CHAR-BASE-T 3D lock

## Bar (one sentence)

A fresh reviewer, comparing renders of the T model at a matched 3/4 angle and a
face close-up against `godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png`,
must call ours a match or better on all four: **flush round forehead pore** (a
shallow dish with a small dark hole, not a raised boss and not a third eye),
**symmetric almond eyes with a small frown and no nose bump**, **bell silhouette
with four droopy limbs**, and **translucent wet-gel material with rim glow** —
and the animations must keep the pore readable through the whole motion arc.

Reference image is the bar. Not "looks good".

## Toolchain (verified this session)

Blender 5.2 is a Microsoft Store install. The exe cannot be launched directly
(Access denied). Use the launcher, which **detaches**, so always write results to
a file and poll for it rather than reading stdout:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe" `
  --background --factory-startup --python <script.py> -- <args>
```

Godot 4.7.1:

```powershell
& "C:\Users\wchkl\AppData\Local\Microsoft\WinGet\Links\godot_console.exe" `
  --path <proj> --headless --import          # after adding assets

& "C:\Users\wchkl\AppData\Local\Microsoft\WinGet\Links\godot_console.exe" `
  --path <proj> --resolution 1024x1024 --position 60,60 res://tools/shot.tscn -- `
  --scene=res://... --out=<abs dir> --tag=<name> [--anim=<name> --frames=12]
```

Godot needs a real window to render; `--headless` gives no pixels. Kill strays
with `Get-Process godot* | Stop-Process -Force`.

Review renderers:

- `build/bl_shots.py` — Blender Cycles CPU. Imports a GLB, writes a mesh-facts
  JSON, renders 34 / front / side / back / face / face34 / facehigh.
- `godot/immune/tools/shot.gd` + `shot.tscn` — in-engine renders, same angles,
  plus animation frame strips. **Shared harness: do not edit it.**

## Baseline measured (round 0)

`godot/immune/characters/base_t/CHAR-BASE-T-tripo-5k.glb` — Tripo remesh.

- 5,044 tris, 3,277 verts, 1 UV layer, 1 material, basecolor JPG. Budget for T
  is 5k, so the mesh is on target. No armature, no shape keys, no actions.
- Raw bounds 0.999 W x 0.811 D x 0.882 H — wider than tall. Concept is taller
  than wide.
- Evidence: `build/shots/t-raw/` (Blender), `build/shots/t-godot/` (Godot).

Gaps found against the reference:

1. Forehead is a **raised protruding torus** (volcano boss). Concept is a flush
   shallow dish with a small hole. This is the user's named blocker.
2. Material is opaque clay/plastic. Concept is translucent wet gel.
3. There is a **nose bump** above the mouth. Concept has no nose.
4. Eyes are asymmetric; the screen-left eye is pinched and clipped by the brow.
5. Mouth is a scratchy squiggle, not a clean small frown.
6. Silhouette is squat. Concept is a bell, taller than wide.
7. No animations at all.

## Pieces

| # | Piece | Builder | Output | Status |
| - | ----- | ------- | ------ | ------ |
| P1 | Head marks + silhouette geometry (Blender) | `dd9f5b38` | `characters/base_t/CHAR-BASE-T-fix.glb`, `build/shots/t-fix/` | **WINS** (critic `9be95701`) |
| P2 | Wet-gel material in Godot | `89f4a8ab` | `characters/gel/wet_gel.gdshader` + `gel_look.gd`, `tools/gel_preview.tscn`, `build/shots/t-gel-r5/` (+ `t-gel-r5-hi/`), evidence in `build/r5/` | **LOSES** r1 (`c636703a`), r2 (`cc505a7c`), r3 (`d518496e`), r4 (`c0985859`); r5 with critic `e9fc77f8` |
| P1b | Silhouette — flared wavy skirt, hooked tapered arms | `dd9f5b38` | same GLB | building |
| P3 | Animation set | `390d8431` | `characters/gel_anim.gd`, `tools/anim_preview.tscn`, `build/shots/{t-anim,t-blockout,a-blockout}/` | **WINS** (critic `e711c749`) |
| P4 | Smoothing pass — one scene, one look | — | — | pending |

File ownership, to keep the three out of each other's way:

- P1 owns `build/bl_fix_t*.py` and `characters/base_t/*.glb`.
- P2 owns the `.gdshader` files and `tools/gel_preview.tscn`.
- P3 owns the animation scripts and `tools/anim_preview.tscn`.
- Nobody edits `tools/shot.gd`, `tools/shot.tscn`, or `build/bl_shots.py`.

## Log

- round 0: baseline measured, bar installed, three builders dispatched.
- round 1, P3: eight clips built at runtime by `gel_anim.gd` (idle, plant, uproot,
  move, hit, attack, relay_open, relay_close), driven through the existing duty
  contract in `character_root.gd`. Frame strips and contact sheets rendered for
  the sculpt, the primitive blockout and family A. Builder's own stated weakness:
  every clip is one global ellipsoid scale on a rigid mesh, so limbs scale
  instead of lagging — no true surface jiggle. Critic `e711c749` dispatched.
- P1 has landed `characters/base_t/CHAR-BASE-T-fix.glb` and `build/shots/t-fix/`;
  P2 has landed `characters/gel/` and `build/shots/{t-gel,t-gel-iter}/`. Both
  builders still running, so those are mid-flight, not final.
- round 1, P3 verdict: **WINS**. Critic reproduced six clips independently and
  measured silhouettes rather than eyeballing them: height and width move in
  opposite directions at every extreme (`hit` h/w 1.30 → 0.74, `move` 1.33 →
  0.89), landings hold a flattened splat with the lobes thrown outward, and each
  beat overshoots then settles in decaying wobbles. Identity marks survive the
  hardest squash — verified in a 2x zoom board at
  `build/shots/critic-anim/CRITIC-COMPARE.png`. Smoke test exit 0.
  Residuals accepted, not blocking: `move` frame 07 foreshortens the near eye
  into a shallow lens as the head pitches back on landing; `hit`'s ~35 ms
  rebound stretch is too short to reliably land on a sampled frame.

- round 1, P2: `wet_gel.gdshader` + `gel_look.gd`, four family uniforms
  (`body_color`, `deep_color`, `transmit_color`, `rim_color`) all derived from
  the single `JELLY[family]` entry, so a new family is one `Color`. Eyes held
  dark by a luminance window on the baked JPG producing an `ink` mask that zeroes
  emission, SSS, wrapped diffuse and transmission — but deliberately keeps the
  tight coat specular, so they read as wet black rather than as holes. Measured
  against the reference on subject pixels: hue 20.5° vs 22.9°, saturation 0.855
  vs 0.918, median luminance 0.498 vs 0.487. Old baseline was hue 38.6°,
  saturation 0.636, median luminance 0.766 — i.e. washed-out and pale, which is
  exactly the "plastic shell" read. Cost +0.8 ms mean for ten on screen.
  Builder's own remaining gaps: saturation ~0.06 short, a bloom halo instead of
  the reference's crisp rim line, and limb-tip glow weaker than the reference
  because thinness is faked from fresnel and curvature with no baked thickness
  map. Critic `c636703a` dispatched.

- round 1, P2 verdict: **LOSES**, on one bounded gap. Passes accepted: eyes are
  flat glossy black under 4x zoom, all six families land within 12° of palette
  hue, `kit_lock_preview.tscn` still renders clean, and the critic ran the perf
  harness itself — 2.34 ms mean / 3.28 ms p95 for ten at 1920x1080 on a GTX 1650
  SUPER. It also confirmed the plastic read is gone.
  **The gap:** on warm families the thin parts clip to a flat plateau instead of
  a thick-to-thin gradient. Red pinned at 255 across 41% of T's eroded body core
  versus 3% in the reference (D 40.2%, A 22.5%, M 11.4%, B 6.8%, N 2.4%). A foot
  scanline shows R welded to 1.000 for 23 of 57 limb pixels with only green
  ramping, where the reference has both channels modulating — so the reference
  limb reads as gel getting thinner and ours reads as an emissive stripe painted
  on the outline. The same shader already does it right on N green, which is why
  this is a bounded exposure fix and not a redesign.
  Evidence: `build/shots/critic-gel/zoom/clip-tripo.png`, `limb-{ref,tripo}.png`,
  `SBS-matched.png`. Round 2 dispatched to the same builder.
- Not blocked on: M and B measure the same hue (282°), separated only by
  saturation 0.66 vs 0.93.
- round 2, P2: the cause was architectural, not three numbers. The thin-part
  terms **added** energy, and on a warm hue red is already near 1.0 from albedo,
  so any addition pinned it — after which red can only brighten, never deepen.
  Replaced with per-channel **Beer–Lambert absorption**, where thickness removes
  light, plus a hue-preserving peak limiter that scales by `budget/peak` so
  channel ratios survive (independent per-channel clipping is what flattens a
  gradient and drags hue toward white). Also dropped `light_wrap` 0.60 → 0.10 and
  `sss_amount` 1.2 → 0.4, because a heavily wrapped terminator left nothing dark
  on the body for red to fall toward.
  Dominant-channel clip on eroded core, before → after, reference 3.02%:
  T 44.2 → 2.66, D 44.1 → 2.93, A 26.5 → 2.09, M 14.4 → 1.65, B 10.1 → 1.81,
  N 2.6 → 1.63. Limb scanline: pinned red pixels 132/315 → 0/282, R now modulates
  0.800 → 0.988 against the reference's 0.78 → 0.98.
  The corrections live in the palette derivation — a warmth-weighted hue shift, a
  dominant-channel exposure normalisation, and a saturation term that declines to
  buy saturation a hue cannot afford in luminance — so a seventh family needs no
  new constants. Evidence: `build/shots/t-gel/EV4-clipmap.png`.
  Builder-declared trades for the next critic to weigh: median luminance 0.425 vs
  the reference's 0.487 and lum90 0.599 vs 0.693, i.e. ~13% darker; blown-white
  pixels roughly doubled (0.50% vs 0.20%) buying gloss back through the coat
  lobe; B is unavoidably dark because blue carries 0.072 of perceived luminance
  against green's 0.715; and B/M hue stays nearly collapsed because the authored
  palette entries are only 7.5° apart, which no derivation can widen.

- round 2, P2 verdict: **LOSES**. A second critic independently confirmed the
  round-1 clip gap is closed (eroded core 1.55–3.11% against the reference's
  3.02%, and on a foot scanline it now clips *less* than the reference does: 3 of
  120 pinned versus the reference's 15 of 128). Saturation survived at 0.92–0.93
  against the reference's 0.915, versus 0.640 for the old plastic. Eyes, dimples,
  `kit_lock_preview.tscn` and cost all passed.
  **The gap:** the clip was removed by killing transmitted light rather than
  shaping it, so the thin parts no longer glow from within. In a ribbon 1.2% of
  subject height in from the silhouette: median luminance 0.477 vs 0.596, p90
  0.598 vs 0.818, blue p90 0.125 vs 0.412, and pixels above luminance 0.75 across
  the 0–5% shell at 1.36% vs 11.66%. The spectral test settles it — the reference
  desaturates 0.156 from thin edge to deep core because short-path light keeps
  green and blue and emerges yellow-white; ours changes by 0.001, so nothing
  spectral happens at the edge.
  Crucially **not** global dimming: the deep-core band matches the reference at
  0.399 vs 0.396 median, so the whole 13% luminance deficit sits precisely in the
  band that is meant to be hot. Mechanism is `gel_look.gd` `DEFAULTS` overriding
  the shader — `interior_budget` 0.12 vs 0.85, `transmit_strength` 0.35 vs 2.6,
  `rim_budget` 0.10 vs 0.55 — leaving subtractive absorption as the only carrier,
  and absorption can deepen a thick shoulder but never make a thin edge
  incandescent. Evidence: `build/shots/critic2-analysis/pair-foot.png`.
  Round 3 dispatched with numeric targets: ribbon ~0.60 median / ~0.80 p90, blue
  past 0.4, ribbon saturation down toward 0.81, core clip still under 3%.
- Tooling defect found by the round-2 critic and routed to P2: `MESH_CANDIDATES`
  in `tools/gel_preview.gd` and `tools/gel_perf.gd` lists the damaged
  `CHAR-BASE-T-fix.glb` **first**, so the default preview and the published perf
  number were both running on a mesh with holes through the eyes. P2's own
  evidence was quietly contaminated by this.
- Watch item: family B renders at median luminance 0.120 / p90 0.193 against T's
  0.425 — borderline unreadable at gameplay scale. Deliberate, from the
  `luma_gain` headroom cap. May resolve once transmission works again.

- round 3, P2: the round-2 fix had the transmitted light multiplied by a saturated
  `transmit_color` whose blue is 0.034, so no thickness could ever desaturate — the
  edge was structurally locked to the family hue and could only get brighter. Round 3
  makes throughput itself carry the colour: transmitted light starts at the lamp's
  own colour and is tinted only by what absorption removed, so a short path emerges
  yellow-white with live blue and a long one emerges deep orange. Four supporting
  changes: absorption depth and hot-band width were decoupled (`glow_power`), since
  `thin_power` drove both and widening the ribbon kept un-darkening the core; the band
  is over-driven into a clamped plateau (`glow_gain`) because the reference is hot
  uniformly across its outer 5% rather than spiking at the outline; curvature became
  signed convexity so concave folds stay dark; and its weight dropped to 0.10 because
  screen-space normal derivatives are piecewise-constant per triangle and a strong
  weight drew the tessellation as jagged pale rings around the eyes and pore. Facial
  features are additionally kept out of the glow by a blurred-mip read of the bake.
  Verified: `build/shots/t-gel-r3/`, `build/shots/r3-review/`, `build/shots/r3-fam/`.
  Ribbon metric added to `build/gel_compare.py --ribbon`, reproducing the round-2
  critic's numbers to within 0.05pp on shell hot% and 0.000 on shell blue p90.
- round 3, P2 measured (front / reference): ribbon median 0.525 / 0.576, ribbon p90
  0.765 / 0.774, ribbon blue p90 0.431 / 0.455, ribbon saturation 0.752 / 0.822,
  ribbon hot% 12.18 / 12.39, core-to-ribbon saturation drop **+0.151 / +0.140**
  (round 2 was -0.044), eroded-core clip 1.46% / 3.02%. Cost 2.335 ms mean and
  3.300 ms p95 for ten characters at 1080p, against 1.777 / 2.043 for
  `StandardMaterial3D` on the same scene. `scenes/kit_lock_preview.tscn` still loads
  clean. `MESH_CANDIDATES` reordered in both tools, so the clean tripo mesh is now
  the default everywhere.
- round 3, P2 residual gaps, stated rather than hidden: the outer shell is still
  colder than the reference (median 0.452 against 0.582, hot% 5.77 against 11.61) —
  the hot zone is genuinely narrower, and only 4 points of the 30.2%/33.5% shell-area
  difference is silhouette shape, so this is the material, not the mesh. Core
  saturation 0.903 against 0.962, so the body reads a shade muted beside the
  reference. And the incandescence is a band inside the silhouette rather than light
  filling a limb's whole width, because a screen-space fresnel-and-curvature proxy has
  no access to real thickness on a closed opaque mesh. The identified fix is a baked
  thickness map, which is asset work outside this piece.
- round 3, P2 on family B: now a palette limit, with the arithmetic. Exposing each
  authored hue until its dominant channel just reaches 1.0 caps B's luminance at
  0.408, against T 0.567, A 0.681, M 0.665 and N 0.859 — B's dominant channel is blue,
  which carries 0.072 of Rec.709 luminance. B cannot match T's brightness without
  either clipping blue (the defect this round exists to prevent) or desaturating
  toward lavender, which is already M's identity. Transmission did lift it: B's
  core-to-ribbon saturation drop is +0.155, matching T's +0.151, and its ribbon
  median is 2.2x its core. At gameplay scale in `r3-review/fam-all.png` B reads
  clearly, carried by its rim. Recommend accepting B as a darker family or revisiting
  the palette entry — not a material change.

- round 1, P1: re-export at 22:41 recovers from the damaged intermediates the
  other agents were seeing. 7,890 tris / 4,821 verts, UVMap and baked basecolor
  intact, Godot headless import clean. Vertex displacement only.
  The structural insight that unblocked it: the remesh models the pore, and each
  eye, as **separate closed shells welded onto the skull**, and only those shells
  carry the dark paint in the basecolor. So the pore shell was reshaped into a
  dish and sunk below the skull, making the visible rim the smooth intersection
  of two analytic surfaces instead of the shell's own ragged boundary. Boss went
  from +0.040 proud to −0.005 recessed, floor −0.043. Eyes were mirrored shell to
  shell rather than self-mirrored. The mouth is not a crease at all but a
  crescent pocket whose *interior* is painted dark, so filling it drags purple
  paint onto the skin — it was squeezed shut into a slit instead.
  Silhouette was judged on rendered outline rather than bounding box: reference
  1.012 wide/tall, raw remesh 0.979, fix 0.971. Squashing the box to square took
  the render 12% narrower than the concept, so the box stays at 1.100.
  Builder-declared residuals: eyes still sit in raised sockets with a brow ridge
  where the reference has them flush; mouth narrower than the reference's wide
  frown; faint concentric ripples in the pore dish plus a nick at 7 o'clock;
  7,890 of 8,000 tris leaves almost no headroom, and T's nominal budget is 5k.

- round 1, P1 verdict: **WINS**, against both the reference and the baseline.
  The decisive evidence is a sign flip on the defect the piece exists to solve,
  measured on matched horizontal cross-sections: at the pore's own height the
  baseline pushes **0.037–0.040 units forward** of the surrounding forehead
  (3.7–4.0% of the 0.88 model height) over a mound ~11% of height wide; the fix
  pushes forward **nowhere**, and instead recesses a bore 3.8% of height inside a
  dish that blends out to flush, largest rim deviation 0.0012. From above, the
  baseline mound breaks the crown silhouette and the fix does not. Pore centre is
  on the midline at x −0.0037 and sits 0.14 of model height above the eye line.
  Verified independently: 7,890 tris (own audit agreed with the report), `UVMap`
  and the 4096² basecolor survived, and dark texels still cluster on the right
  features — the pore's dark texels grew from 5 triangles to 71 as its patch was
  subdivided 192 → 1,718 faces, which is UVs interpolating correctly rather than
  tearing. Godot's import cache `source_md5` matches the current file. Zero
  non-manifold edges, zero loose vertices.
  Of the three carried findings: the low pore is gone; the torn screen-left eye
  is gone, and a mirrored ray-grid puts the fix's eye symmetry at 0.0019 mean
  deviation against the baseline's 0.00966, about 5x better. **The open-hole
  finding was real but inherited** — exactly one genuine boundary, 32 edges at
  the screen-right eye socket rim, and the baseline has the identical defect
  (32 edges, same centre within 0.008, same radius within 0.0004). With a green
  emissive wall behind the head, no green shows through on the face in any frame.
  No faceted star around the pore. The 1,654 raw boundary edges are glTF UV-seam
  splits, not holes.
  Residuals accepted: the dish is modest at ~0.19 of head width against roughly
  0.26 in the reference; the rim is slightly polygonal with a notch at 7 o'clock
  and faint concentric terracing; a small lumpy blob sits inside the bore; and
  the inherited socket aperture should be welded shut on principle some day.

- round 3, P2: the real mechanism was one line upstream of the choked budgets.
  Transmitted light was `transmit_color * throughput`, and T's `transmit_color`
  has blue at **0.034** — so that multiply capped blue at the palette's blue at
  *every* thickness, and a thin edge could only become a brighter orange, never
  desaturate toward yellow-white. No amount of budget-raising could have fixed
  it. Throughput now carries the colour itself: transmitted light starts at the
  lamp's colour and is tinted only by what absorption removed.
  Front view against the reference — ribbon p90 luminance 0.765 vs 0.774, ribbon
  blue p90 0.431 vs 0.455, hot% 12.18 vs 12.39, eroded-core clip 1.46% vs 3.02%,
  and the spectral test that killed round 2 now reads **+0.151** core-to-ribbon
  saturation drop against the reference's +0.140, where round 2 was −0.044.
  The builder rebuilt the ribbon metric before changing any shading and
  reproduced the round-2 critic's independent numbers to three decimals, so both
  sides are measuring the same thing.
  Both side tasks done: `MESH_CANDIDATES` reordered so the clean mesh is the
  default, and family B shown to be a palette limit with arithmetic — exposing
  each authored hue until its dominant channel reaches 1.0 caps B at luminance
  0.408 against T's 0.567, because B's dominant channel is blue at 0.072 of
  Rec.709 luminance. B cannot match T without either clipping blue or
  desaturating into M's identity.
  Builder-declared remaining diffs: outer shell still colder than the reference
  (median 0.452 vs 0.582, hot% 5.77 vs 11.61, and only ~4 points of that is
  silhouette geometry); core saturation 0.903 vs 0.962; and the incandescence is
  a band inside the silhouette rather than light filling a limb's full width,
  which it attributes to having no real thickness data on a closed opaque mesh
  and says needs a baked thickness map — i.e. asset work, not shader work.
  **Lead's own read, not a verdict:** in `build/shots/r3-review/pair-whole.png`
  the round-3 render looks flatter and more matte to the eye than the round-1
  renders in `build/shots/t-gel/EV1-vs-reference.png` did, despite the better
  numbers. The critic was explicitly instructed to trust its eye over the metrics
  if they disagree. Watch whether it does.

- round 3, P2 verdict: **LOSES**, but the critic said the ribbon targets are met
  or near-met and it would have passed on those alone. The spectral mechanism is
  genuinely working now. It named the pattern instead: *round 2 killed
  transmitted light instead of shaping it; round 3 killed dominant-channel
  exposure instead of ceilinging it.* Same error, one level up.
  **The gap:** the body's dominant channel is ~40 code values too low
  everywhere. The reference holds **red at 250/255 continuously across the outer
  12%** of the body, sagging only to 0.92 at the deepest core, while green falls
  0.58 → 0.28 and blue 0.106 → 0.004 — the thickness gradient is carried entirely
  by green and blue and red barely moves. Reference core is R ≥ 250 across
  46.72% with only 3.02% at R ≥ 254. Ours: red median 0.85 → 0.816, only 2.60%
  reaching 250. So the render is darker *and* less saturated at once, which is
  what a matte opaque surface measures like.
  Owner: `extinction_base` 1.0 of `extinction_density` 2.5 costs red exp(−2.5) =
  0.082 at full thickness, with `body_absorb` 0.65 putting 40% of that on albedo.
  The critic pre-tested both naive relaxations and **both fail harder than round
  1** — `extinction_base:0.15` pins R ≥ 254 across 72.65%, `body_absorb:0.0`
  across 67.56%, both pale peach. The reference threads a needle at 250–253.
  Named fix: take neutral extinction off the dominant channel *and* apply the
  already-existing `peak_limit` to `ALBEDO × DIFFUSE_LIGHT`, where it is
  currently applied only to `EMISSION`.
  **Methodological finding worth keeping:** the ribbon aggregate was measuring a
  one-to-two-pixel bright rim. At 0.4% depth the render matches the reference;
  the deficit opens from 0.8% inward. "The reference has a lit volume; the render
  has a rim on a solid." Round 4 was told to measure in depth zones, not one
  band, so it cannot hide the same way.
- round 4, P2: took the named fix literally, both halves of it.
  *Spectral extinction.* `gel_throughput` now applies `extinction_base` as a small
  neutral sag only (1.0 → 0.025) and puts the real absorption in a spectral term
  weighted by how far each channel sits below the dominant one, shaped by a new
  `extinction_shape` (3.5). The dominant channel is now nearly transparent while
  the non-dominant channels absorb hard, which is the reference's actual
  behaviour: red flat, green and blue carrying the whole gradient. This is a
  property of the palette-derived transmit colour, not a per-family constant.
  *A ceiling on the body, not just on emission.* `peak_limit` was applied only to
  `EMISSION`. It is now applied once to the summed `DIFFUSE_LIGHT + body + glow +
  transmission` under a single `body_budget`, so every energy path shares one
  hue-preserving ceiling. `albedo_gain` is deliberately over-driven into that
  ceiling — driving past it *is* the mechanism: red pins to the plateau while
  green and blue keep whatever the absorption left them. A soft knee
  (`peak_knee`) makes red roll off at 250–253 instead of slamming into 254.
  `luma_gain`/`PEAK_CEILING` were deleted: with a real ceiling a second exposure
  normaliser can only fight it, and because it divided by albedo luminance it
  dimmed hardest exactly the families the hue and saturation work had brightened.
- round 4, P2 measured in depth zones as instructed (`gel_compare.py --zones`,
  reference values in brackets). Red median by depth: 0.969 / 0.969 / 0.965 /
  0.973 / 0.976 / 0.984 / 0.984 / 0.976 against [0.902 / 0.969 / 0.984 / 0.984 /
  0.984 / 0.976 / 0.969 / 0.933] — red is now held flat across the whole body
  instead of sagging. Eroded core **R ≥ 250 at 46.42% [46.72]** with **R ≥ 254 at
  0.42% [3.02]**, so the needle is threaded from the safe side. Plateau did not
  return on the warm families: D 46.00 / 0.43, A 0.47 / 0.31.
  Round-3 gains held, not undone: green 0.624 → 0.318 [0.475 → 0.294] and blue
  0.145 → 0.082 [0.106 → 0.004] still fall away while red does not.
  Eyes survived the exposure rise and improved: ink median (0.176, 0.035, 0.004)
  against the reference's own (0.180, 0.043, 0.004), p90 luminance 0.090 [0.094]
  where round 3 was 0.145. Added `--ink` to `gel_compare.py` so this
  non-regression is reproducible rather than asserted — the body statistics
  deliberately exclude ink pixels, so nothing else could have caught it.
- round 4, P2 candid residual, with the cause bounded by measurement: **core
  saturation 0.890 against the reference's 0.961, slightly worse than round 3's
  0.903.** It is one thing — a blue floor of 0.082 in the deep core where the
  reference reaches 0.004. It is not the albedo: T's palette saturation pushes to
  exactly 1.0, so the body albedo carries zero blue. Probing the additive terms
  one at a time was inconclusive, so they were zeroed *together*
  (`rim_budget`, `interior_budget`, `core_glow`, `spec_energy`, `env_specular`,
  `transmit_strength`, `transmit_tint`, `thin_glow`, `sss_amount`, `light_wrap`
  all 0): core blue fell only 0.082 → 0.063. So ~0.02 is the gel cues and
  **~0.063 is irreducible under this harness's ACES tonemap plus glow** and no
  uniform reaches it. The reference is a concept render that never went through
  this pipeline. Stated, not worked around.
- round 4, P2 cost, attributed rather than quoted absolute. At twelve characters
  filling 1080p: gel **3.682 ms mean / 4.565 p95**, the same meshes with the old
  `StandardMaterial3D` 2.795 / 3.680, and the imported GLB material 2.922 / 3.818.
  So the gel material itself is **+0.89 ms for twelve**, ~0.074 ms each, and the
  remaining ~2.8 ms is scene and post-process baseline. Round 3's published
  2.459 ms is not comparable — this session's *standard-material* baseline alone
  is above it, so the machine moved between sessions and only the within-session
  delta means anything.
- round 4, P2 rejected optimisation, recorded so it is not retried: replacing the
  soft knee's `exp()` with the cheaper rational `t/(1+t)` saved nothing measurable
  (3.765 vs 3.820 ms, inside run-to-run noise) and **collapsed core R ≥ 250 from
  46.4% to 3.0%**, because the rational form approaches the budget far too slowly
  to hold the dominant channel at 250–253. Reverted, with the reason in a comment
  at the call site.
- round 4, P2: both halves of the named fix taken. Extinction is now spectral —
  the neutral term drops 1.0 → 0.025 and absorption moves onto the non-dominant
  channels, weighted by how far each sits below the dominant one, so red is
  nearly transparent and green and blue carry the gradient, which is the
  reference's actual mechanism. And `peak_limit` now wraps the summed
  `DIFFUSE_LIGHT + body + glow + transmission` under one `body_budget` with a
  soft knee, with `albedo_gain` deliberately over-driven into it — driving past
  the ceiling *is* the mechanism. `luma_gain`/`PEAK_CEILING` were deleted: with a
  real ceiling a second exposure normaliser can only fight it, and because it
  divided by albedo luminance it dimmed hardest exactly the families the hue work
  had just brightened.
  Red median by depth zone is now 0.969 / 0.969 / 0.965 / 0.973 / 0.976 / 0.984 /
  0.984 / 0.976 against the reference's 0.902 / 0.969 / 0.984 / 0.984 / 0.984 /
  0.976 / 0.969 / 0.933 — held flat instead of sagging. Eroded core R ≥ 250 at
  46.42% (reference 46.72) with R ≥ 254 at 0.42% (reference 3.02), threading the
  needle from the safe side. Warm families clean: D 46.00/0.43, A 0.47/0.31.
  Round 3's spectral gains held. Eyes came through the exposure rise *better*
  than round 3 — ink median (0.176, 0.035, 0.004) vs the reference's (0.180,
  0.043, 0.004), bright-outlier p90 luminance 0.090 vs 0.094, where round 3 was
  0.145.
  Cost measured within-session: +0.89 ms for twelve at 1080p, ~0.074 ms each.
  A cheaper rational soft knee was tried and reverted — no measurable saving and
  it collapsed core R ≥ 250 from 46.4% to 3.0%; the reason is now a comment at
  the call site.
  **Load-bearing claim the next critic was told to test rather than accept:** the
  remaining core-saturation residual (0.890 vs the reference's 0.961) is
  attributed mostly to the harness. Zeroing all ten additive terms together only
  moved the core blue floor from 0.082 to 0.063, so ~0.063 is claimed irreducible
  under the harness's ACES tonemap plus glow, on the grounds that the reference
  is a concept render that never went through this pipeline. If that holds it
  means the bar and the measuring instrument are in conflict, which the project
  needs to know.
  New honest observation: family B's green is **exactly 0.000 at every depth**, so
  B's gradient is carried by red alone and its gel read is structurally weaker
  than a warm family's.
- round 4, P2 verdict: **LOSES**, but every colour axis now lands on the
  reference — red plateau 47% vs 45%, R ≥ 254 at 0.44% vs 2.21%, eyes an
  essentially exact ink match. The critic said it would ship without embarrassing
  anyone, and still failed it.
  **The gap:** no surface microstructure. At a common 700px subject height,
  microcontrast is 0.0377 against the reference's 0.0596, and distinct small
  sharp highlights are 9.48 per thousand interior pixels against 27.37 — **below
  the old opaque plastic baseline's 11.42** on that cue. Cause: `gel_look.gd` has
  `dimple_depth: 0.009` at `dimple_scale: 160.0`, i.e. the feature is switched
  off; the shader's Voronoi bump is fine. The critic swept it and found no trade
  at all — at depth 0.09 / scale 60 microcontrast hits 0.0904 and speckle 48.63
  while every colour metric holds or improves. Landing value is around depth
  0.04–0.05 at scale 80–120.

- round 5, P2: microcontrast **0.0662** against the reference's 0.0614 and
  distinct highlights **1.74** against 2.07, up from round 4's 0.0410 / 0.40 —
  clear of the plastic baseline on both cues now. Colour untouched as predicted:
  hue 18.3° unchanged, core R ≥ 250 **46.59%** against the reference's 46.72,
  which is *closer* than round 4's 46.42; R ≥ 254 at 0.43%. Eyes measure closer
  than round 4. Cost unchanged at +0.81 ms for ten, because the Voronoi was
  always being evaluated and only its amplitude was invisible.
  Simply raising the amplitude as instructed produced a **bright cracked net**,
  and the cause is the field's shape rather than its gain: F2−F1 Voronoi is flat
  across a cell interior and drops only at the wall, so every highlight it can
  make sits on a cell *border*. The reference has each cell catching its own
  highlight, which needs curvature *inside* the cell. A `dimple_round` blend
  toward an F1 dome fixes it and is also what makes a cell register as one
  distinct highlight instead of feeding a continuous ridge. Landed at depth 0.05,
  scale 110, crease 0.16, round 0.45 over eight sweeps and ~50 renders.
  It also validated the new metrics against the round-4 critic's blurred-reference
  control before trusting them, and kept `--detail blur=N` runnable so no future
  round can pass on colour statistics alone.
  **It corrected one of its own instruments rather than the shader**: the `--ink`
  check appeared to show the eyes regressing, two shader fixes moved the number
  by exactly nothing, and the clue was that `--ink` selected every dark subject
  pixel, conflating eye ink with the gel's own dark crevices where added sparkle
  is correct. Both speculative shader changes were reverted.
  **Finding the next round should not rediscover:** this cue is
  resolution-limited. Rendered at matched density (873 px) the material measures
  microcontrast 0.0718 and speckle 6.33, above the reference on both — the
  1024-shot figures understate it because the reference is framed 901 px tall and
  a default harness shot is 373 px. Simulated on-screen size: 400 px → 0.0538 /
  2.28, 250 px → 0.0413 / 0.83, 160 px → 0.0320 / 0.32. So it is a close-range cue
  that is gone by gameplay size, and making it survive at 200 px needs larger
  cells at the cost of the face-range look — a distance-driven `dimple_scale`,
  i.e. an LOD job, not a constant. Scale was deliberately held at 110 rather than
  the 160 that reaches exact metric parity, because at 160 the cells are ~3 px in
  a harness shot and ~1 px in gameplay, which a still-image metric cannot see and
  an animating character would shimmer with.
  **Integration recommendation:** game scenes should adopt ACES tonemapping
  rather than the material being recalibrated for linear. The ceiling
  architecture depends on a tonemapper that compresses above 1.0, since the whole
  mechanism is driving the dominant channel past 1.0 and catching it underneath;
  all four rounds of colour calibration are fitted through ACES; and one
  `tonemap_mode` line per scene is far smaller than refitting the palette
  derivation. ACES-dependent uniforms in order of fragility: `BODY_HUE_SHIFT`,
  then `albedo_gain` and `body_budget`, then `extinction_density`.

### The instrument was blind, and it was proven, not argued

The round-4 critic blurred the reference by 4 pixels and re-measured it:
R50 0.973 → 0.973, hue 22.7° → 23.1°, saturation 0.929 → 0.926, R ≥ 250
45.30% → 44.86%. **Every number four rounds of review optimised is unchanged, and
the blurred reference no longer looks like gel.** Its detail metrics caught it at
once: microcontrast 0.0596 → 0.0155, speckle 27.37 → 1.32.

So the review instrument could not tell "has the reference's colour statistics"
from "looks like the reference". Microcontrast and speckle count are now
first-class metrics for this piece. Note this is the **third** time tonight an
aggregate hid a spatial fact — the ribbon band in P2 round 3, the outline
width-over-height ratio in P1, and now the colour statistics. Treat any aggregate
that passes while the eye disagrees as a suspect instrument.

### The harness claim was tested and upheld, with a correction

The round-4 critic built its own stage and isolated each term. Deep-core blue:
shipped 0.086, glow off 0.075, **linear 0.000**. It is ~all ACES — removing the
blue lamps actually *raised* blue, and ambient contributes none. Confirmed
analytically against Godot's ACES fit: a pure red at the drive needed to land
R ≈ 0.90 outputs sRGB blue 0.079, manufacturing almost exactly the measured floor
out of nothing. No shader can emit negative blue, and lowering the drive is the
round-3 dimming trap. So the residual is genuinely unreachable — but the
blurred-reference control shows ±0.08 of core blue is not what separates gel from
vinyl, so it is not worth further effort.

Also a harness property, not a shader one: the reference's long crisp specular
*sheets* rather than blobs. Three directional lamps can only make three point
highlights.

### Integration hazard for P4 — found by the round-4 critic

`apply_gel` is called only from `tools/gel_preview.gd` and `tools/gel_perf.gd`.
**No game scene uses this material yet.** And `scenes/combat_lane.gd` and
`scenes/kit_lock_preview.gd` set no `tonemap_mode`, so they run linear, while all
four rounds of tuning were done under `tools/shot.tscn`'s ACES environment.
`BODY_HUE_SHIFT = 0.1048` is an explicit ACES pre-compensation fitted there.
Under linear the hue survives (18.1° ACES vs 18.6° linear) but **the red plateau
collapses from 47% to 10% at ≥ 250 and mean luminance drops 0.471 → 0.402** —
which is round 3's failure mode. So P4 must either move game scenes to ACES or
recalibrate the material for linear. This is not optional; the look will not
survive the move unchanged. Also note `kit_lock_preview.tscn` uses
`StandardMaterial3D` blockouts, so the "no regression" check on it has been
vacuous for this material all along.

- round 4, P2 verdict: **LOSES**, but every colour axis passed — red plateau 47% vs
  45%, R ≥ 254 0.44% vs 2.21%, eyes an essentially exact ink match, spectral
  saturation correct — and the critic said it would not embarrass anyone if it
  shipped. **It failed on something the instrument could not see.**
  **The gap:** the surface has no microstructure, and that, not colour, is what
  reads as vinyl. At matched pixel density the reference's skirt and limb are
  covered in dense cellular dimpling, each cell catching its own micro-highlight.
  Microcontrast 0.0596 vs 0.0377; distinct small sharp highlights per 1000
  interior px 27.37 vs 9.48 — **below the opaque plastic baseline's 11.42.**
  Cause: the feature was switched off. `dimple_depth` 0.009 at `dimple_scale`
  160 is below visibility at any range the character is seen at.
  **The methodological lesson, which is the durable part.** The critic blurred the
  reference by 4px and re-measured: R50 0.973 → 0.973, hue 22.7 → 23.1,
  saturation 0.929 → 0.926, R ≥ 250 45.30% → 44.86%. *Every number four rounds of
  review optimised is unchanged, and the blurred reference no longer looks
  remotely like gel.* Colour statistics cannot distinguish "has the reference's
  colour statistics" from "looks like the reference".
- round 5, P2: adopted microcontrast and speckle count as first-class metrics
  (`gel_compare.py --detail`) and **validated the instrument against the critic's
  own control before trusting it** — it reproduces the critic's readings (ref
  0.0614 vs its 0.0596, round 4 0.0410 vs its 0.0377), reproduces the humiliating
  ordering (old plastic 0.56 beats round 4's 0.40 on speckle), and collapses on a
  4px-blurred copy (0.0614 → 0.0241, 2.07 → 0.01). `--detail blur=N` keeps that
  control permanently runnable.
- round 5, P2 fixed the cue, and one thing the critic's sweep did not reach.
  Turning the dimples on as instructed produced a **bright cracked net** at face
  range, and the reason is the field's SHAPE, not its amplitude: F2−F1 Voronoi is
  flat across a cell interior and drops only at the wall, so all of its gradient —
  every highlight it can make — sits on cell BORDERS. The reference shows each
  cell catching its own highlight, which needs curvature *inside* the cell. Added
  a `dimple_round` blend toward an F1 dome (0 reproduces the old field exactly),
  which puts the highlight mid-cell and is also what makes a cell count as one
  distinct small highlight instead of feeding a continuous ridge.
  Landed at `dimple_depth` 0.05, `dimple_scale` 110, `dimple_crease` 0.16,
  `dimple_round` 0.45 — found by measurement over eight sweeps, ~50 renders.
- round 5, P2 measured. Microcontrast **0.0662** [ref 0.0614], speckle **1.74**
  [2.07], against round 4's 0.0410 / 0.40 and the plastic baseline's 0.0498 /
  0.56 — comfortably clear of plastic on both cues now.
  It was never a trade, as the critic predicted: hue 18.3° unchanged, saturation
  0.885 → 0.889, core **R ≥ 250 46.59% [46.72]** — closer than round 4's 46.42 —
  R ≥ 254 0.43% [3.02], red still flat 0.965–0.984 across the body. Eyes: with the
  corrected metric below, ink median (0.176, 0.039, 0.004) vs the reference's
  (0.184, 0.043, 0.000), *closer* than round 4's (0.173, 0.035, 0.004). All six
  families hold and separate. `kit_lock_preview` clean. Cost unchanged, because
  the Voronoi was always being evaluated — only its amplitude was invisible: for
  ten, gel 3.548 ms mean / 4.478 p95 against the standard material's 2.738 /
  3.586, i.e. **+0.81 mean**, consistent with the critic's +0.65.
- round 5, P2 corrected one of its own instruments rather than the shader. The
  `--ink` check added in round 4 appeared to show the eyes regressing (p90
  luminance 0.090 → 0.134). Two shader fixes aimed at the eye mask changed the
  number by nothing, which was the clue: `--ink` selected *every* dark subject
  pixel, so it was conflating eye ink with the gel's dark crevices, where added
  sparkle is correct. Eroding the ink mask separates them, and the eyes then
  measure better than round 4. **A metric that moves for the wrong reason is
  worse than no metric**, and it nearly bought a shader change to fix a
  measurement artefact.
- round 5, P2 finding the next round should not have to rediscover: **this cue is
  resolution-dependent, and the published number is resolution-limited.** The
  reference frames its subject 901px tall; a default harness shot frames it 373px,
  so `--detail` normalising both to 700 measures the render *upscaled*. Rendered
  at matched density (873px) the same material measures microcontrast **0.0718**
  and speckle **6.33**, i.e. above the reference on both — the microstructure is
  abundantly there and the 1024-shot figures understate it. Simulating on-screen
  size: 400px → 0.0538 / 2.28, 250px → 0.0413 / 0.83, 160px → 0.0320 / 0.32. So
  it is a close-range cue that is gone by gameplay size. Making it survive at
  200px needs larger cells, which costs the face-range look — that is a
  distance-driven `dimple_scale`, i.e. an LOD job, not a constant to hand-tune.
- round 5, P2 also confirmed the round-4 concession was legitimate and is now
  closed: the critic isolated deep-core blue independently at shipped 0.086, glow
  off 0.075, **linear 0.000**, and showed analytically that Godot's ACES fit
  manufactures sRGB blue 0.079 from a perfectly pure red at the drive needed to
  land R ≈ 0.90. It is ACES, not glow and not the lamps, and
  `ambient_light_disabled` is working. The blurred-reference control also shows
  ±0.08 of core blue is not what separates gel from vinyl, so it is closed rather
  than merely conceded.
- **INTEGRATION BLOCKER carried out of P2, for whoever wires this into gameplay.**
  `apply_gel` is called only from `tools/gel_preview.gd` and `tools/gel_perf.gd` —
  **no game scene uses this material yet** — and `scenes/combat_lane.gd` and
  `scenes/kit_lock_preview.gd` set no `tonemap_mode`, so they run linear. The
  material's exposure calibration is ACES-specific and will not survive the move
  unchanged: under linear the red plateau collapses from 47% to 10% at ≥ 250 and
  mean luminance drops 0.471 → 0.402, which is round 3's failure mode.
  ACES-dependent uniforms are `BODY_HUE_SHIFT` (an explicit pre-rotation fitted
  under `tools/shot.tscn`), `albedo_gain` and `body_budget` (the drive/ceiling
  pair), and secondarily `extinction_density`. **Recommendation: game scenes
  adopt ACES tonemapping** rather than recalibrating the material for linear —
  the ceiling architecture depends on a tonemapper that compresses above 1.0, the
  four rounds of colour calibration are all fitted through ACES, and one
  `tonemap_mode` line per scene is a far smaller change with far less risk than
  refitting the palette derivation. If a linear pipeline is required instead, it
  is a recalibration of those four uniforms plus a re-fit of `BODY_HUE_SHIFT` to
  ~0, and it must be re-measured with `--zones` and `--detail`, not eyeballed.
- **New piece P1b, opened on two independent reports.** The P2 round-3 critic and
  the P2 builder both described the silhouette as wrong in the same terms: the
  reference is a squat broad bell with a **wide wavy flared skirt of four broad
  lobes and two upraised tapered arms with hooked tips**, while both meshes are a
  tall egg with stubby side nubs and stubby feet. P1's own silhouette check
  passed because it measured overall outline width-over-height (1.012 ref, 0.971
  fix) — an aggregate that cannot distinguish a flared wavy hem from a stubby one
  of the same width. **This is the identical failure mode the material critic
  just diagnosed in the ribbon metric**, in a different piece, found the same
  night. P1b was told to measure width as a function of height and hem waviness,
  not extent, and to not regress the locked head marks.

### Carried to P1 — THREE independent reports, from agents who never spoke

The P2 builder, working only on material and with no knowledge of the P3 critic's
finding, reported the same class of problem on `CHAR-BASE-T-fix.glb` and proved
it is the mesh by rendering the identical material on both meshes:
`build/shots/t-gel/EV3-mesh-compare.png` — fix mesh left, tripo baseline right.
On the fix mesh the pore is ringed by a **faceted star of creases** and the
screen-left eye is **torn and ragged**; on the untouched tripo mesh the same
material renders a clean circular pore and clean almonds. Widening the ink mask
window did not change the tear, so it is geometry, not the texture window.

The P2 critic, a third agent with no contact with either, then found worse: on
`CHAR-BASE-T-fix.glb` there are **literal holes where both eyes should be** — you
see through the head to the background in `build/shots/critic-gel/critgel-front.png`
and `critgel-34.png`. No eye geometry, no backing, so the material's ink path has
nothing to shade. It also calls the pore a "crumpled chaotic crater". The tripo
mesh is clean in every one of these respects.

Combined with the P3 critic's finding below, the current state is that **P1's fix
mesh is worse than the baseline it started from** on the very marks it was
supposed to repair. P1 is still iterating, so this may be an intermediate export.
Its critic must be given all three findings and must compare against
`CHAR-BASE-T-tripo-5k.glb`, not only against the reference. If P1 cannot beat the
baseline, the fallback is to fix only the protruding forehead ring on the tripo
mesh and leave the rest of that mesh untouched.

Two mesh notes that are NOT about the fix mesh, from the P2 critic: the tripo
mouth reads as a crumpled crease rather than a clean curved line, and on both
meshes the skirt and feet are shorter and stubbier than the reference's long
draping skirt, with arms attaching lower and hugging the body instead of flaring.

### Also carried to P1 — found by the P3 critic, independently

On `CHAR-BASE-T-fix.glb` the **forehead pore sits down at brow level, tucked
against the near eye, instead of high on the midline** as in the reference. The
offset is identical at rest and at every animation extreme, so it is the mesh,
not the motion. P1's critic must check pore *placement*, not only whether the
pore is flush.
## Codex handoff continuation — 2026-08-18

Bar: a fresh critic comparing rendered CHAR-BASE-T 3/4 and gameplay-scale material against `godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png` must prefer ours on face marks, bell silhouette, wet-gel material, and readable pore through animation.

Current pieces:

- P1 head marks: WINS (prior critic evidence retained).
- P2 material: r5 LOSES; fresh r6 critic also LOSES because highlights are overdriven/glittery and cells read as embossed plastic. Next builder is working on r7.
- P1b silhouette: current fix LOSES; fresh critic sees downward arms and two flat feet instead of raised hooks and four skirt lobes. Next builder is working on p1b2.
- P3 animation: WINS (prior critic evidence retained).
- P4 integration: builder in progress; `character.tscn` was still a sphere placeholder at start, and gameplay scenes lacked gel application and ACES.

Evidence:

- P2 r6: `build/shots/t-gel-r6/final/`; front microcontrast 0.085 vs ref 0.0614, speckle 3.22/1k vs 2.07; critic still saw blown hotspots and yellow halos.
- P1b: `build/shots/t-fix-p1b/`; `build/fix-report-p1b.json`; report says 7,522 triangles and 110 hook-region vertices, but rendered outline remains unreadable.

What is running now: independent P2 r7 builder, P1b2 geometry builder, and P4 integration builder. Each has disjoint file ownership; fresh critics must inspect their real artifacts before any win claim.

Latest critic verdicts:

- P2 r7: **LOSE**. Glitter dropped, but at 200–400px the low-frequency translucent/cellular volume cue collapses into an opaque shell with isolated hotspots. Next gap: restore broad volume structure without restoring r6 sparkle.
- P1b2: **INSUFFICIENT/LOSE**. Export/report exists, but the fresh render directory contains no PNGs; the available simulation still shows arms too low. Next gap: produce a visible raised-hook silhouette and complete render evidence.
- P4 integration: **WIN**. Fresh smoke/parse checks exited 0; real GLB, gel application, animation rebuild, and ACES are present in game scenes. Evidence: `build/shots/integration/`.

What is running now: independent P2 r8 material builder and P1b3 geometry builder. P4 is awaiting whole-product smoothing after P2/P1b settle.

Latest critic verdicts:

- P2 r8: **LOSE**. Detail/ink remain controlled, but core green/blue remain too high (`0.329/0.078` vs reference `0.294/0.004`); the deep-core-to-thin-shell gradient is still too flat and reads plastic at 200–400px. Next gap: stronger body absorption/throughput without disturbing current rim/detail.
- P1b3: **LOSE**. Front arms are broad horizontal blobs; side view still hangs vertically; hem reads as two flat feet. Next gap: narrow tapered arms rising above attachment and curling inward, then a continuous four-lobed scalloped skirt.

P4 remains independently **WIN** and is integrated against the current fix GLB. Whole-product smoothing is blocked on P2/P1b passing their own bars.
