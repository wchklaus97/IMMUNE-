# Phase 3 — Wet-gel material (Godot)

## Goal

Replace plastic GLB material with `wet_gel.gdshader` driven by `gel_look.gd`
and `family_look.gd` palettes. Beat the concept render on colour **and**
surface microstructure.

## Files

| File | Role |
| ---- | ---- |
| `godot/immune/characters/gel/wet_gel.gdshader` | Beer–Lambert absorption, peak limiter, Voronoi dimples |
| `godot/immune/characters/gel/gel_look.gd` | Per-family uniforms from `JELLY` palette |
| `godot/immune/characters/family_look.gd` | `gel_material()`, `apply_gel()` |
| `godot/immune/tools/gel_preview.tscn` | Preview scene for shot harness |
| `godot/immune/tools/gel_perf.tscn` | Shader cost benchmark |

**Default mesh in preview:** `CHAR-BASE-T-tripo-5k.glb` (not a broken fix.glb).

## Render evidence

```powershell
Get-Process -Name godot* -ErrorAction SilentlyContinue | Stop-Process -Force
& "$env:LOCALAPPDATA\Microsoft\WinGet\Links\godot_console.exe" `
  --path godot/immune --resolution 1024x1024 --position 60,60 `
  res://tools/shot.tscn -- `
  --scene=res://tools/gel_preview.tscn `
  --out=build/shots/t-gel-r5 --tag=t-gel-r5
```

## Measurement (do not trust colour alone)

```powershell
# Zone gradient (core → ribbon spectral drop)
python build/gel_compare.py --zones `
  godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png `
  build/shots/t-gel-r5/t-gel-r5-front.png

# Microstructure (required since round 4)
python build/gel_compare.py --detail `
  godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png `
  build/shots/t-gel-r5/t-gel-r5-front.png

# Blurred-reference control — metrics must collapse on blur
python build/gel_compare.py --detail blur=4 `
  godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png `
  godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png

# Eyes only — erode mask; do not conflate with gel crevices
python build/gel_compare.py --ink `
  godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png `
  build/shots/t-gel-r5/t-gel-r5-face.png
```

## Round history (CHAR-BASE-T) — what failed and why

| Round | Failure | Fix direction |
| ----- | ------- | ------------- |
| 1 | Warm families clip to flat red plateau | Per-channel Beer–Lambert |
| 2 | Fixed clip but thin parts stopped glowing | Restore `transmit_color` |
| 3 | Spectral OK but ~40 CV too dark → vinyl | `albedo_gain` + `body_budget` ceiling |
| 4 | Colour landed; no microstructure | Turn on dimples |
| 5 | F2−F1 Voronoi = cracked net at face range | `dimple_round` blend toward F1 dome |

## Round 5 landed parameters (starting point)

- `dimple_depth` 0.05, `dimple_scale` 110, `crease` 0.16, `dimple_round` 0.45
- Microcontrast ~0.066 vs ref ~0.061; speckle ~1.74 vs ref ~2.07
- Cost: ~+0.81 ms mean per 10 characters vs StandardMaterial3D

## Resolution trap

Reference frames subject ~900px tall; default harness ~373px. Normalising both
to 700px **upscales** the render. Also check:
- `build/shots/t-gel-r5-hi/` — matched density
- `build/r5/sim-{400,250,160}.png` — gameplay size survival

Dimples are a **close-range cue**. Surviving at 160px needs distance-driven
`dimple_scale` (LOD), not a single constant.

## Six families

Render sheet: `build/shots/r5fam-sheet.png`. B is known-dark and accepted.
T/D are 0.2° apart in palette — that is palette, not shader bug.

## Critic bar (material only)

Ignore mesh silhouette defects (route to P1/P1b). Judge:
translucent wet gel vs plastic/vinyl; spectral core→ribbon; microcontrast +
speckle with blurred control; eyes flat glossy black; no R≥254 plateau >~3%;
gameplay-scale readability at 200–400px.

## Next

→ [04-gel-animation.md](04-gel-animation.md)
