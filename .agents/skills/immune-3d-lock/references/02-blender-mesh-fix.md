# Phase 2 — Blender mesh fix

## Goal

Fix head marks and silhouette geometry on the Tripo GLB without destroying UVs.
Output `CHAR-*-fix.glb` with before/after crops for critic review.

## Critical insight (Tripo shells)

Tripo remesh often has **separate mesh shells** for pore and eyes with baked
texture. Fixes must use **vertex displacement** on those shells, not destructive
remesh/boolean. Body is a third shell (~2500 verts).

Probe shells first:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe" `
  --background --factory-startup --python build/bl_fix_t_probe.py
# → build/probe-t.json
```

## Fix targets (priority order)

| Issue | Target | Method |
| ----- | ------ | ------ |
| Forehead pore | Raised torus → flush dish + dark hole | Push pore shell inward along pore axis |
| Nose bump | Remove | Displace mouth-region verts down |
| Eyes | Symmetrize almond shape | Mirror/displace lens shell |
| Mouth | Clean small frown slit | Pinch squiggle verts |
| Silhouette | Bell + wavy skirt + hooked arms | Broader sculpt pass (P1b) |

## Run fix pipeline

```powershell
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe" `
  --background --factory-startup --python build/bl_fix_t.py
```

Outputs:
- `godot/immune/characters/base_t/CHAR-BASE-T-fix.glb`
- `build/fix-report.json` — refine steps, shell counts, pore axis

Re-render evidence:

```powershell
# Same bl_shots.py call with --glb CHAR-BASE-T-fix.glb --out build/shots/t-fix --tag t-fix
```

## Analysis crops

Scripts `build/an_*.py` generate pixel overlays in `build/ref-crops/`:
- `pore-cmp.png`, `eye-compare.png`, `mouth-cmp.png`
- `sil-overlay.png`, `outline-overlay.png`

Use these in critic prompts — not builder rationale.

## Budget

CHAR-BASE-T fix landed at **7522 tris** (up from 5044). Acceptable if head
marks pass; do not chase original 5k if quality regresses.

## Pitfalls

| Pitfall | Symptom | Fix |
| ------- | ------- | --- |
| Boolean/remesh on face | Holes in eyes, torn pore | Revert; displace shells only |
| Bounding-box silhouette | "Taller" but outline unchanged | Judge **rendered outline**, not AABB |
| Open eye hole in mesh data | Reported by critic | Inherited from Tripo; invisible in shaded render |
| Editing fix.glb while P1b runs | Race on same file | Copy to `build/inspect/` for hand review |

## GUI hand-check

```powershell
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe" `
  --python build/bl_open_compare.py
# Left = tripo-5k, Right = fix
```

## Critic bar (geometry only)

Pass when 3/4 and face close-up match concept on pore dish, eye symmetry, no
nose, clean mouth. Silhouette skirt/arms may be a **separate piece (P1b)** —
do not fail material critic on mesh, or vice versa.

## Next

→ [03-wet-gel-material.md](03-wet-gel-material.md)
