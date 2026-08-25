# Phase 5 — Evidence, gallery & integration

## Goal

Collect all artifacts under `build/`, host a review gallery, and run a smoothing
pass that wires mesh + gel + animation into one Godot scene.

## Evidence layout

```
build/
├── shots/
│   ├── t-raw/          # Tripo baseline (Blender)
│   ├── t-godot/        # Plastic baseline (Godot)
│   ├── t-fix/          # Geometry fix (Blender)
│   ├── t-gel-r3..r5/   # Material rounds
│   ├── t-gel-r5-hi/    # Matched-density r5
│   ├── t-anim/         # Animation strips + SHEET + FACE
│   ├── r5fam-sheet.png # Six families
│   └── critic*/        # Independent critic renders
├── r5/                 # Comparison strips, crops, sim-{400,250,160}
├── r4/                 # Prior round strips
├── ref-crops/          # Geometry pixel overlays
├── inspect/            # GLB copies for Blender hand-check
├── fix-report.json     # Mesh fix log
└── gallery/            # Hosted review site
```

## Host gallery

```powershell
npm run serve
# Open http://127.0.0.1:5180/build/gallery/
```

Gallery source: `build/gallery/index.html` + `gallery.css`

Update gallery when a new material round or geometry pass completes.

## Gauntlet workbench

During gauntlet runs, maintain `gauntlet-workbench.md` at repo root:

```markdown
## Bar (one sentence)
...

## Pieces
| # | Piece | Builder | Output | Status |

## Log
- round N: ...
```

Do not commit unless user asks.

## Smoothing pass (P4) checklist

```
- [ ] character.tscn loads CHAR-*-fix.glb (or latest approved GLB)
- [ ] apply_gel() wired from family_look on mesh instances
- [ ] rebuild_gel_anims() runs on ready
- [ ] Game scenes use ACES tonemapping (material calibration dependency)
- [ ] kit_lock_preview and combat_lane render clean
- [ ] Fresh whole-product critic vs concept 3/4 + face + idle FACE strip
- [ ] build/gallery/ updated with final comparison strip
```

## Comparison strip convention

Save side-by-side strips to `build/rN/strip-front.png`:
**reference | latest round | prior round | plastic baseline**

Also save:
- `crop-crown.png`, `crop-limb.png` — microstructure
- `sim-400.png`, `sim-250.png`, `sim-160.png` — gameplay scale

## Critic dispatch template

Builder gets: piece scope, bar sentence, output paths, commands.
Critic gets: bar, artifact paths, measurement commands, reference image path.
**Critic must not receive builder transcript.**

Use `gauntlet-loop` iron laws: no self-grading, no round cap, real pixels only.

## Re-run full evidence chain

1. `bl_shots.py` on current GLB → `build/shots/t-fix/`
2. `shot.gd` gel_preview → `build/shots/t-gel-rN/`
3. `gel_compare.py --zones --detail` → paste numbers in workbench
4. `shot.gd` anim_preview per clip → `build/shots/t-anim/`
5. Refresh `build/gallery/index.html` if new sections needed
