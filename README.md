# IMMUNE-

Godot + web UI for the IMMUNE permanent research network / six-mission tower-defense demo.

## Repo layout

| Path | What |
|------|------|
| `godot/immune/` | Godot 4.7 game project (v0.4.0) |
| `ui/immune-research-network/` | Research network web UI + character assets |
| `tools/meshy/` | Cost-gated Meshy generation, smoothing, validation, and hero intake |
| `steam/` | Steam store copy, graphical assets, disclosure draft, and release checklist |
| `build/gallery/` | 3D lock evidence gallery (`npm run serve` → `/build/gallery/`) |
| `.agents/HANDOFF.md` | Codex handoff for CHAR-BASE-T 3D work |
| `gauntlet-workbench.md` | Gauntlet iteration log |

## Quick start

```powershell
npm run serve
# http://127.0.0.1:5180/ui/immune-research-network/
# http://127.0.0.1:5180/build/gallery/
```

Godot project: open `godot/immune/project.godot` in Godot 4.7+.

## Handoff

See `CODEX_HANDOFF.md` for the current six-mission progress, verified release state,
Meshy cost gate, known external blockers, and the next development tranche. The
older `.agents/HANDOFF.md` / `.agents/HANDOFF-ZH.md` files retain CHAR-BASE-T history.
