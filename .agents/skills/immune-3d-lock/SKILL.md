---
name: immune-3d-lock
description: >-
  End-to-end workflow to lock an IMMUNE gel character from AI-generated GLB to
  Godot-ready mesh, wet-gel shader, and animations. Use when importing Tripo or
  Meshy GLB, fixing forehead pore/eyes/silhouette in Blender, developing the
  wet-gel material, building gel animations, or running gauntlet evidence for
  CHAR-BASE-* characters. Pairs with gauntlet-loop for critic-driven iteration.
---

# IMMUNE 3D character lock

Lock a translucent wet-gel blob character against a 2D concept render. This
skill is the **orchestrator**; each phase has a reference file with commands,
bars, and pitfalls.

**Announce at start:** "I'm using the immune-3d-lock skill."

## When to use

- User drops a Tripo/Meshy GLB and wants it game-ready in Godot
- Forehead pore reads as a third eye, material looks like plastic, or silhouette is wrong
- User asks to continue CHAR-BASE-T (or any family) 3D lock work
- User wants the build evidence gallery or render harness re-run

**Pair with:** `gauntlet-loop` whenever quality must beat a reference image, not
"look okay."

## Pipeline (five phases)

```
AI GLB intake → Blender mesh fix → Godot wet-gel shader → Gel animation → Integration
     │                │                    │                  │              │
  Phase 1          Phase 2              Phase 3            Phase 4        Phase 5
```

| Phase | Reference | Output |
| ----- | --------- | ------ |
| 1 Intake & baseline | [01-intake-baseline.md](references/01-intake-baseline.md) | `CHAR-*-tripo-5k.glb`, `build/shots/t-raw/`, mesh JSON |
| 2 Blender mesh fix | [02-blender-mesh-fix.md](references/02-blender-mesh-fix.md) | `CHAR-*-fix.glb`, `build/shots/t-fix/`, `build/ref-crops/` |
| 3 Wet-gel material | [03-wet-gel-material.md](references/03-wet-gel-material.md) | `wet_gel.gdshader`, `gel_look.gd`, `build/shots/t-gel-r*/` |
| 4 Gel animation | [04-gel-animation.md](references/04-gel-animation.md) | `gel_anim.gd`, `build/shots/t-anim/` |
| 5 Evidence & gallery | [05-evidence-gallery.md](references/05-evidence-gallery.md) | `build/gallery/`, `gauntlet-workbench.md` |

Toolchain paths and Windows quirks: [toolchain.md](references/toolchain.md).

## One-sentence bar (CHAR-BASE-T example)

A fresh critic comparing 3/4 and face close-up renders against
`godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png` must call ours a match
or better on: **flush round forehead pore**, **symmetric almond eyes + small
frown, no nose bump**, **bell silhouette with four droopy limbs**, **translucent
wet-gel with rim glow**, and **pore readable through the full animation arc**.

## Gauntlet split (do not merge owners)

| Piece | Owns | Does not touch |
| ----- | ---- | -------------- |
| P1 geometry | `build/bl_fix_t*.py`, `characters/base_t/*.glb` | shader, anim harness |
| P2 material | `characters/gel/*`, `tools/gel_preview.tscn` | mesh GLB, `shot.gd` |
| P3 animation | `characters/gel_anim.gd`, `tools/anim_preview.tscn` | shader tuning |
| Shared harness | `tools/shot.gd`, `build/bl_shots.py` | **nobody edits without explicit ask** |

## Face budgets (Tripo remesh target)

| Tier | Characters | Target tris |
| ---- | ---------- | ------------- |
| Base | CHAR-BASE-* | ~5k |
| Pair fusion | CHAR-* pair locks | ~6–8k |
| Triple / apex | CHAR-PRIME, apex | ~8–12k |

UV: Tripo remesh ships with UV + basecolor; keep UVs. Wet-gel look is shader-driven
in Godot — do not bake plastic PBR as final look.

## Quick commands

```powershell
# Baseline (Blender)
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe" `
  --background --factory-startup `
  --python build/bl_shots.py -- `
  --glb godot/immune/characters/base_t/CHAR-BASE-T-tripo-5k.glb `
  --out build/shots/t-raw --tag t-raw

# Godot render (needs real window)
Get-Process -Name godot* -ErrorAction SilentlyContinue | Stop-Process -Force
& "$env:LOCALAPPDATA\Microsoft\WinGet\Links\godot_console.exe" `
  --path godot/immune --resolution 1024x1024 --position 60,60 `
  res://tools/shot.tscn -- `
  --scene=res://tools/gel_preview.tscn `
  --out=build/shots/t-gel-r5 --tag=t-gel-r5

# Material metrics
python build/gel_compare.py --zones --detail `
  godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png `
  build/shots/t-gel-r5/t-gel-r5-front.png

# Evidence gallery
npm run serve
# → http://127.0.0.1:5180/build/gallery/
```

## Stop conditions

- Each piece wins an independent critic against the bar
- Smoothing pass (P4): one scene with mesh + gel + anims, then whole-product critic
- Do not self-grade. Maintain `gauntlet-workbench.md` at repo root during gauntlet runs

## Worked example

CHAR-BASE-T full evidence index: `build/gallery/` (hosted) and `gauntlet-workbench.md`.
