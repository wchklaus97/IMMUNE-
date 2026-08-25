# Phase 1 — GLB intake & baseline

## Goal

Accept an AI-generated GLB, copy it into the Godot project, measure facts, and
render round-0 evidence before any fixes.

## Checklist

```
- [ ] Copy GLB to godot/immune/characters/<family>/
- [ ] Run Godot --import
- [ ] Run bl_shots.py → build/shots/<tag>-raw/
- [ ] Run shot.gd on plastic/default material → build/shots/<tag>-godot/
- [ ] Record tris, verts, UV layers, bounds in gauntlet-workbench.md
- [ ] List gaps vs concept image (pore, nose, eyes, mouth, silhouette, material)
```

## Tripo vs Meshy

| | Tripo remesh ~5k | Meshy generate |
| - | ---------------- | -------------- |
| UV | Usually present | Often needs manual UV |
| Silhouette | Good volume | Can be smoother/blobbier |
| Face detail | Separate shells (pore, eyes) | Varies |
| Final look | Needs Godot gel shader | Needs Godot gel shader |

**Decision for T:** Tripo remesh at ~5k won. Do not regenerate unless silhouette is unsalvageable.

## Baseline command

```powershell
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe" `
  --background --factory-startup --python build/bl_shots.py -- `
  --glb godot/immune/characters/base_t/CHAR-BASE-T-tripo-5k.glb `
  --out build/shots/t-raw --tag t-raw --res 768 --samples 48
```

Read `build/shots/t-raw/t-raw-report.json`:
- `total_tris`, `total_verts`, `uv_layers`, `materials`, `raw_bounds_*`

## Known Tripo baseline faults (CHAR-BASE-T)

1. Forehead pore = raised torus (volcano boss), not flush dish
2. Opaque plastic/clay material in engine
3. Nose bump above mouth
4. Asymmetric eyes (screen-left pinched)
5. Scratchy mouth squiggle
6. Squat silhouette (wider than tall); concept is bell, taller than wide
7. No animations

## Output paths

- `godot/immune/characters/base_t/CHAR-BASE-T-tripo-5k.glb`
- `build/shots/t-raw/` — Blender renders + JSON
- `build/shots/t-godot/` — Godot plastic baseline

## Next

→ [02-blender-mesh-fix.md](02-blender-mesh-fix.md) for geometry.
Material and animation can start in parallel on the **baseline** mesh only if
evidence paths are tagged clearly (`t-gel-tripo-*` vs `t-gel-r*`).
