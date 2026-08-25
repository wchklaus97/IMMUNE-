# Phase 4 — Gel animation (no rig)

## Goal

Animate gel blobs with **node transforms only** — no armature, no shape keys.
Keep forehead pore and eyes readable through every clip.

## Files

| File | Role |
| ---- | ---- |
| `godot/immune/characters/gel_anim.gd` | Builds clips at runtime |
| `godot/immune/characters/character_root.gd` | `rebuild_gel_anims()`, `play_hit/attack/rest` |
| `godot/immune/tools/anim_preview.tscn` | Preview scene for harness |

## Clips (CHAR-BASE-T)

| Clip | Purpose |
| ---- | ------- |
| idle | Breathing squash/stretch |
| plant | Root into ground |
| uproot | Pull out of ground |
| move | Locomotion wobble |
| hit | Impact squash |
| attack | Lunge stretch |
| relay_open / relay_close | A-family relay duty |

Motion language: squash, stretch, jiggle, settle, overshoot — liquid body, not skeletal.

## Render animation evidence

```powershell
Get-Process -Name godot* -ErrorAction SilentlyContinue | Stop-Process -Force
& "$env:LOCALAPPDATA\Microsoft\WinGet\Links\godot_console.exe" `
  --path godot/immune --resolution 1024x1024 --position 60,60 `
  res://tools/shot.tscn -- `
  --scene=res://tools/anim_preview.tscn `
  --out=build/shots/t-anim --tag=t-anim `
  --anim=idle --frames=12
```

Repeat for each `--anim=` value. Outputs per clip:
- `t-anim-<clip>-00..11.png` — frame strip
- `t-anim-<clip>-SHEET.png` — contact sheet
- `t-anim-<clip>-FACE.png` — face readability strip

Or batch: `build/render_anims.ps1`

## Critic bar (animation only)

- Pore remains a readable dish through full arc (check FACE strips)
- Eyes stay symmetric and ink-black, not stretched into slits
- Motion reads as gel, not rigid transform
- Integrates with duty contract (`character_root.gd`) without errors

## Pitfalls

| Pitfall | Fix |
| ------- | --- |
| Scaling root collapses face marks | Animate body child, not face shell |
| Shader wobble + dimple shimmer | Keep dimple amplitude stable during anim until LOD exists |
| Missing clip in duty map | Add to `rebuild_gel_anims()` and test in `kit_lock_preview` |

## Next

→ [05-evidence-gallery.md](05-evidence-gallery.md) for integration pass (P4).
