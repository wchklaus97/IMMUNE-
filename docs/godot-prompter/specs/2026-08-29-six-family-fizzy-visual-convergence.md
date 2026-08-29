# IMMUNE six-family Fizzy visual convergence

Status: implemented and locally verified on 2026-08-29 with Godot 4.6.1.
The project and CI target remain Godot 4.7.2 stable.

## Goal

Resolve the remaining family-level visual mismatch after the user rejected the
earlier texture quality. The accepted target is a soft, poured, translucent
Fizzy jelly with readable interior bubbles, microbubbles, fine inclusions, and a
clear wet membrane. The change must preserve each family's silhouette, colour,
face, duty kit, and gameplay behaviour.

This tranche does not submit a Meshy generation, texture, remesh, or retry. It
uses the existing shared shader and local authored/imported bodies, so network
calls and Meshy credit consumption are both zero.

## Baseline review

Fresh six-angle close-ups were captured for T/B/M/N/A/D rather than judging the
material from code alone. M/N/A/D already matched the accepted Fizzy direction.
T still read as rough dimpled rubber, while B read as a largely solid saturated
purple body with weak secondary bubble structure. The mission desk also framed
the models too far away to act as a useful material preview.

Generated evidence is intentionally ignored by Git:

- `outputs/visual-qa-20260829/current-closeups-contact.png`
- `outputs/visual-qa-20260829/tb-before-after.png`
- `outputs/visual-qa-20260829/mission-desk-final3/`

## RED contracts

The smoke test was changed before the implementation and failed on the old B
runtime profile. The new contracts require:

- T and B profile materials to enable round bubbles, microbubbles, and fine
  inclusions;
- T to disable the old directional dimple layer;
- the realized T and B runtime bodies to retain all three Fizzy layers;
- the mission desk to expose a named `CellPreviewCamera` no wider than 30
  degrees and no farther than 3.8 world units; and
- CI to match a six-family `gel_fizzy=T+B+M+N+A+D` release marker.

The first RED invocation exited at the B microbubble/inclusion assertion. A
shell wrapper also attempted to assign zsh's read-only `status` variable; later
wrappers use `probe_exit`, so the harness now preserves the real Godot result.

## Implementation

`gel_profiles.gd` now owns one shared `FIZZY` layer for T and B. Family entries
only override colour-independent character cues such as bubble scale, density,
and deterministic seeds. The existing `wet_gel.gdshader` remains the only body
shader; there is no family shader fork.

T now uses a smooth clear surface with finer round bubbles and a dense, subtle
microbubble field instead of the legacy dimple normals. B keeps its purple
Meshy sculpt and ink face while gaining readable medium bubbles, microbubbles,
and inclusions.

The mission preview camera moved from 4.5 units / 36 degrees to 3.75 units /
29.5 degrees. The first close framing attempt was rejected because it cropped
M/N/A/D and their duty pieces. The second attempt showed that B remained clipped
even after scaling, identifying its different model origin as the cause. The
final configuration gives B its own vertical preview offset while leaving its
combat transform untouched. All six families are complete at both 1600x900 and
1280x720.

## Visual result

The final T body no longer reads as rough yellow rubber: the coarse directional
dimpling is gone, specular response is smoother, and three interior scales are
visible. B retains its family colour and silhouette while showing round pockets
and fine suspended material under the surface. M/N/A/D are unchanged apart from
the closer mission-desk presentation.

Automated captures prove deterministic rendering, full framing, and absence of
engine errors. They do not prove subjective taste; the final product-colour and
"jelly enough" decision remains a human review gate.

## Performance evidence

Compatibility/OpenGL-on-Metal, ten bodies, 1920x1080 project viewport, 180
post-warm-up frames:

| Family / material | CPU p95 | Wall p95 | Wall max |
|---|---:|---:|---:|
| T standard | 1.017 ms | 4.495 ms | 11.186 ms |
| T Fizzy | 1.055 ms | 4.149 ms | 5.024 ms |
| B standard | 0.789 ms | 3.736 ms | 4.289 ms |
| B Fizzy | 0.969 ms | 6.426 ms | 7.839 ms |

The Compatibility viewport GPU timer returned zero for every sample, so those
runs make no GPU claim. A fresh Xcode Metal System Trace on Apple M4 Pro,
Forward+/Metal, ten current B Fizzy bodies, dropped 60 warm-up frames and
analyzed 370 frames:

| Metric | Current B Fizzy | Previous matched standard | Delta |
|---|---:|---:|---:|
| Mean | 6.719 ms | 4.805 ms | +1.914 ms |
| p95 | 8.085 ms | 7.632 ms | +0.453 ms |
| Max | 13.117 ms | 12.039 ms | +1.078 ms |

All observed current spans remain below the 16.67 ms whole-frame budget. Metal
GPU span is only one component of frame time, and these Apple M4 Pro results are
not generalized to Web, other GPUs, or crowded production scenes.

## Reproduction

```bash
godot --headless --path godot/immune --import
godot --headless --path godot/immune --script res://tools/smoke.gd

godot --path godot/immune --resolution 1600x900 \
  res://tools/mission_select_shot.tscn -- \
  --out=/absolute/output/path --locale=en --tag=fizzy-final

godot --path godot/immune --resolution 1280x720 \
  res://tools/gel_perf.tscn -- \
  --family=B --count=10 --frames=180 --material=gel \
  --out=/absolute/output/path/B-gel.json
```

The complete Metal capture and analyzer method remains documented in
`2026-08-29-all-family-soak-and-metal-gpu.md`.

The first exported macOS smoke wrapper passed a relative `--log-file` path. The
app changed its working directory, no log was created, and a final diagnostic
`printf` masked the failed `rg` exit. The corrected wrapper uses an absolute log
path plus `set -e`; it produced the required
`RELEASE_SMOKE_OK platform=macOS nodes=200` marker and no engine error.

## Remaining gates

- Human side-by-side approval of T/B colour, translucency, and bubble density.
- Real lower-end Windows/Web GPU playtest; the measured local hardware is an
  Apple M4 Pro.
- Apple Developer ID signing/notarization and store metadata remain release
  operations outside this visual tranche.
