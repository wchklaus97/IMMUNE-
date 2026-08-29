# IMMUNE Jelly V3 membrane convergence

Status: implemented and locally verified on 2026-08-30 with Godot 4.6.1.
The project and CI target remain Godot 4.7.2 stable.

## Goal and boundary

This tranche responds to the rejected solid/plastic texture by moving all six
playable bodies toward the supplied `CHAR-BASE-T-3d-alt.png` reference: a deep
saturated core, light-through edges, a clear wet membrane, and small irregular
highlights rather than painted bubble rings or cracked rubber cells.

It changes local Godot materials, look profiles, preview lighting, QA contracts,
and capture tooling only. No Meshy request, retry, texture, remesh, rig, or paid
POST was submitted; the credit cost is zero.

## Fresh baseline and rejected probes

A fresh six-family baseline was captured from the then-current `HEAD` at
1600x900 and 1024x1024. T was pale orange rubber, B was dark plastic, and the
large bright rings on M/N/A/D read as surface polka dots. Simply reducing those
rings improved depth but left a smooth airbrushed/plastic surface.

The following probes were deliberately rejected before source values were
accepted:

- increasing the shared smooth noise alone to its 0.04 shader limit; it remained
  too broad and sparse;
- reviving the retired triplanar Voronoi dimples; this would reintroduce the
  cracked-net/rubber failure the user rejected;
- sparse microbubble normals; they looked like isolated water droplets; and
- red T shader inputs (`#ff2600` through `#ff4d00`), which became red under ACES.

The accepted probe uses dense, overlapping 3D rounded cells only to perturb the
normal. Their emission, shell emission, optical thinness, and shadow are zero,
so they appear only where a wet highlight catches them rather than as texture
paint. T also hides its separate large-bubble surface response. Its final amber
shader input is calibrated so the shot stage lands orange after ACES.

Generated evidence is intentionally ignored by Git under:

- `outputs/jelly-v3-lookdev/baseline/`
- `outputs/jelly-v3-lookdev/candidate-1/` through `candidate-4/`
- `outputs/jelly-v3-lookdev/t-*-sweep*/`
- `outputs/jelly-v3-lookdev/final/`

## RED/GREEN contracts

Smoke contracts were added before each implementation seam and observed RED:

- T/B initially failed because they had no Compatibility-safe membrane next
  pass;
- M initially failed because its bright bubble rings exceeded the quiet interior
  limit;
- all Fizzy bodies then failed because smooth 3D wet-skin depth was zero; and
- the mission desk failed until its named key light became near-neutral.

The final contracts require:

- T/B to attach `jelly_shell.gdshader`, expand it beyond the core, and keep the
  face alpha below 0.03;
- all six bodies to keep shallow smooth 3D microvariation at or below 0.02;
- overlapping rounded membrane cells with bounded depth, radius, jitter, and no
  thickness spots;
- large/micro bubble ring emission and inclusion emission below their quiet
  interior caps; and
- a named `CellPreviewKey` whose green/blue channels are high enough to preserve
  family colours.

## Implementation

`gel_look.gd` now builds an optional transparent next pass while filtering its
builder-only options out of the core shader uniforms. T/B opt into that pass;
M/N/A/D retain their authored shell meshes, so there is no double shell.
`jelly_shell.gdshader` adds a zero-default normal-space expansion; zero preserves
the separately scaled authored shell meshes.

`wet_gel.gdshader` reuses its existing smooth 3D inclusion sample for shallow
normal variation, avoiding a second inclusion-noise fetch. The dense microbubble
field now also supports overlapping rounded membrane cells. Its maximum radius
and scale hints were widened while keeping `radius + jitter < 1.0`, which
preserves the eight-corner lattice bound.

The shared T/B and authored M/N/A/D Fizzy profiles now use:

- stronger thickness extinction and quieter interior bubble emission;
- dense overlapping membrane cells at scale 70, depth 0.005, with no emission,
  shell emission, optical thinness, or shadow;
- smooth 3D microvariation at scale 72 and depth 0.010;
- a tighter 0.030 wet coat; and
- calmer explicit/next-pass membrane rims.

T additionally removes large-bubble surface response and applies the final amber
ACES pre-compensation. B deliberately inherits the same dense, non-emissive
membrane-cell field instead of its former sparse, emissive family override, and
M's production `fizzy` variant uses the same 0.030 wet coat as the other authored
bodies. The mission preview key changed from strongly amber
`(1.0, 0.78, 0.58)` to near-neutral `(1.0, 0.95, 0.88)` so the selection screen
does not recolour the assets.

Two QA-tool defects found during the work were fixed rather than worked around:

- `gel_preview.gd` now parses Boolean `--set` values like `gel_perf.gd`, so
  feature ablations cannot pass invalid strings into shader options; and
- mission/gameplay capture teardown now combines deferred frames, a bounded
  0.1-second real-time drain, render sync, and one final frame. The previously
  intermittent three-resource exit warning did not recur in two mission plus two
  A-combat replay batches.

## Visual evidence

Final evidence contains:

- six families at 1600x900 mission selection;
- six families in both English and Traditional Chinese at 1280x720 mission
  selection;
- six 1024x1024 six-angle character sets;
- six families times three combat phases in both locales (36 frames); and
- membrane on/off T comparisons.

The result has materially deeper family gradients, quiet interiors without
concentric polka-dot rings, and small rounded wet highlights. T now has the
reference-like orange core and luminous boundary instead of a pale yellow clay
read. Automated captures establish repeatability, framing, and absence of engine
errors; final subjective art-direction acceptance remains a human gate.

## Performance evidence

Compatibility/OpenGL-on-Metal, Apple M4 Pro, ten bodies, the project's actual
1920x1080 viewport, 60 warm-up frames plus 300 measured frames, three trials per
case. Values below are medians across the three JSON reports.

| Case | CPU mean | CPU p95 | Wall mean | Wall p95 |
|---|---:|---:|---:|---:|
| T baseline | 0.552 ms | 0.622 ms | 1.185 ms | 2.437 ms |
| T Jelly V3 | 0.631 ms | 0.786 ms | 1.323 ms | 2.885 ms |
| T V3, membrane off | 0.614 ms | 0.742 ms | 1.200 ms | 2.594 ms |
| B baseline | 0.593 ms | 0.663 ms | 1.372 ms | 2.579 ms |
| B V3 before final parameter convergence | 0.615 ms | 0.696 ms | 1.505 ms | 2.827 ms |

T's complete wall p95 rises by 0.448 ms (+18.4%) and B's by 0.248 ms (+9.6%).
The T membrane accounts for 0.291 ms of the final wall-p95 result in the matched
ablation. It is retained because the visual comparison shows the clearer,
less-washed boundary and the absolute ten-body result remains 2.885 ms. This is
an explicit quality/cost decision, not a claim of zero regression.

Final B convergence removed three constant-only overrides; it did not add a
shader branch, texture lookup, or noise sample. A later unpaired run nevertheless
showed substantially higher wall cadence for both settings, so that run cannot
honestly be compared with the earlier baseline. A same-window, interleaved
three-trial A/B instead compared the final inherited field against the former
scale/density/emission overrides:

| B paired case | CPU mean | CPU p95 | Wall mean | Wall p95 |
|---|---:|---:|---:|---:|
| Final inherited cells | 0.882 ms | 1.060 ms | 2.506 ms | 4.297 ms |
| Former B overrides | 0.903 ms | 1.082 ms | 2.661 ms | 4.688 ms |

The final constants were 2.3% lower in CPU mean and 8.3% lower in wall p95 in
that paired window. These measurements establish no added cost from the final B
look; the different absolute cadence between windows remains host-load noise and
is not presented as an optimization claim.

The Compatibility viewport GPU timer returned zero for every sample, so no GPU
number is inferred. Exported Web QA provides separate whole-application cadence:
the final export's six-second local sentinel measured 120.002 mean FPS / 104.167
p05 on ANGLE/Metal and 12.262 mean / 10.834 p05 on 4x-CPU SwiftShader. A separate
four-second compatibility-only replay also passed both profiles. SwiftShader
is compatibility stress, not a hardware benchmark.

## Verification

- Root tool tests: 36/36.
- Web research UI: 53/53 plus production build.
- Meshy no-network safety: 6/6.
- Translation CSV: 2 files / 595 rows; catalog localization: 200 nodes / 406
  generated rows.
- Two Godot imports, release smoke, and bilingual 1920x1080 overflow: pass.
- T/B MISSION-01 + MISSION-06 balance: 4/4 victories, core 12/12.
- T/B/M/N/A/D MISSION-01: 6/6 victories, core 12/12.
- Sequential Windows, Linux, macOS, and Web exports plus artifact contract: pass.
- Exported macOS: ad-hoc signature, arm64+x86_64, bundle/version/icon, and
  `RELEASE_SMOKE_OK platform=macOS nodes=200`: pass.
- Exported Web baseline plus constrained software flow: pass.
- GitHub Actions run `33262958960` on code commit
  `2b077c57c82881cca2d33cb6c07abed4b944776a`: main Godot 4.7.2
  validation/export plus Linux, Windows, and macOS native artifact jobs all pass.
- The exact successful artifact was downloaded and repackaged as the portable
  six-person Jelly V3 campaign. The release contract accepts exactly 14 files;
  both campaign verifiers pass 6 participants / 14 artifacts and all 43
  checksums. Web/Windows/Linux/macOS preflight and a real 1280x720 exported-Web
  research-to-pause browser flow pass. This is distribution-integrity evidence,
  not a human result. Full evidence is in
  `2026-08-30-jelly-v3-human-playtest-campaign.md`.

## Failure handling recorded

Three tooling failures were diagnosed before retrying:

1. Godot 4.6.1 crashed in `RotatedFileLogger::rotate_file()` before project load
   when given a relative path whose directory did not exist after `--path`.
   Validation now uses absolute Godot log paths or shell capture.
2. ImageMagick `montage` required a missing default font. Contact sheets use
   font-free `+append/-append` composition.
3. The invalid Boolean ablation described above was discarded and regenerated
   only after the parser fix.

No failed render or invalid screenshot was promoted as evidence.

## Remaining gates

- Human side-by-side approval of final T/B/M/N/A/D texture and translucency.
- A real agreed lower-end Windows/Web GPU pass; the measured local hardware is
  an Apple M4 Pro and SwiftShader is not a substitute.
- At least three complete adult reports from the provenance-locked Jelly V3
  campaign; six are recommended for the first counterbalanced rotation.
- Developer ID signing, notarization, store metadata, public tag/release, and
  upload remain explicit owner-authorized release operations and were not done.
