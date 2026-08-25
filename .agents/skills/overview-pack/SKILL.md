---
name: overview-pack
description: >-
  End-to-end stakeholder pack for an H5/web game: store covers (3:4 + 16:9 +
  in-game hero), 21:9 UI/UX wireframe, manager-overview HTML, then one long JPG
  of every section. Use when the user wants the full overview from cover art
  through UIUX to manager view, a complete docs pack, or $overview-pack.
  Explicit invoke: $overview-pack. Emoji Cube Match 3D is the worked example.
---

# Overview pack (covers → UI/UX → manager JPG)

One skill for the **whole stakeholder chain**. Do not stop after covers or after
the 21:9 board.

Works the same in **Codex** (`$overview-pack` or implicit match) and **Cursor**.
Canonical path: `.agents/skills/overview-pack/`.

**This kit is generic.** Paths and titles come from `.agents/project.env`.
The committed env file is a **worked example** (Emoji Cube Match 3D) — see
[references/PROJECT.md](references/PROJECT.md). For another game, edit that env
first, then run this skill.

Handover zip: `npm run package:skills` → `overview-pack-kit.zip`
(see `.agents/HANDOFF.md`).

### Codex quick start

| Invoke | How |
| --- | --- |
| **Skill** | `$overview-pack` in Codex CLI, IDE, or ChatGPT desktop |
| **Subagent** | Spawn `.codex/agents/overview-pack.toml` |
| **Validate** | `bash .agents/skills/overview-pack/scripts/validate-overview-pack.sh` |

```
covers (3:4 · 16:9 · hero)
    → 21:9 UI/UX wireframe
    → manager-overview HTML
    → long JPG (all sections stacked) + PDF
```

Specialists (read when editing that layer):

| Layer | Skill |
| --- | --- |
| Game rules / content / difficulty | `$level-design-variant` |
| 21:9 screen-flow board | `$uiux-wireframe` |
| A4 HTML + section stitch | `$manager-overview` |

## Cover files (do this first)

| Ratio | Token in `project.env` | Role |
| --- | --- | --- |
| Hero / in-game | `COVER_HERO` | Welcome / background / manager hero |
| **3:4** portrait | `COVER_3X4` | Store tile · manager covers · 21:9 assets |
| **16:9** landscape | `COVER_16X9` | Catalog banner · same boards |

Never ship a pack with only the hero PNG. Title on art must match `GAME_TITLE`.

Check: `bash .agents/skills/overview-pack/scripts/check-covers.sh`  
Spec: [references/COVER-SPEC.md](references/COVER-SPEC.md)

## Pipeline (always this order)

```
1. Fill .agents/project.env     (example already filled for Emoji Cube Match 3D)
2. Covers in place              check-covers.sh
3. Facts from ENTRY             do not invent screens
4. Phone / shape shots          npm run capture   (if HUD or roster changed)
5. 21:9 UI/UX HTML              UX_HTML (+ locale twin)
6. Manager HTML                 MANAGER_HTML — every block is a .shot-block
7. Serve                        PORT=$SERVE_PORT npm run serve
8. Bake images                  PORT=$SERVE_PORT npm run docs
9. Validate                     bash .agents/skills/overview-pack/scripts/validate-overview-pack.sh
```

Checklist: [references/PIPELINE.md](references/PIPELINE.md)

## Worked example — Emoji Cube Match 3D

These are **example** paths from this repo’s `project.env`, not required names
for every game:

| What | Example path |
| --- | --- |
| Title | Emoji Cube Match 3D |
| Hero / 3:4 / 16:9 | `assets/cover.png`, `cover-3x4.webp`, `cover-16x9.webp` |
| 21:9 HTML | `docs/ux-wireframe.html` |
| 21:9 PNG | `docs/Emoji-Cube-Match-3D-UX-Wireframe-21x9.png` |
| Manager HTML | `docs/manager-overview.html` |
| Long JPG | `docs/Emoji-Cube-Match-3D-Manager-Overview-poster.jpg` |
| Serve | `PORT=5180 npm run serve` |

Example 21:9 journey (9 real screens): tutorial → spin → welcome → play HUD →
rotate → tray → match → overflow → cleared. Another game replaces this list
with **its** real screens.

## Handoff prompt

```
Use $overview-pack.

Read .agents/project.env (example values = Emoji Cube Match 3D; edit for this game).
Read .agents/skills/overview-pack/SKILL.md and references/PIPELINE.md.
Covers → 21:9 UI/UX → manager HTML → long JPG.
Theme / title: [...]
After HTML: PORT=$SERVE_PORT npm run serve && PORT=$SERVE_PORT npm run docs
Then: bash .agents/skills/overview-pack/scripts/validate-overview-pack.sh
```
