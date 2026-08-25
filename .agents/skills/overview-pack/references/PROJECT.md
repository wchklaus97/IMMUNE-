# Project map

The overview-pack kit is **game-agnostic**. Fill [`.agents/project.env`](../../project.env)
for the host repo. The committed file is a **worked example**: Emoji Cube Match 3D.

| Token | Meaning | Example (this repo) |
| --- | --- | --- |
| `GAME_TITLE` | Store / poster title | Emoji Cube Match 3D |
| `DOC_SLUG` | Filename prefix for baked PNG/JPG/PDF | `Emoji-Cube-Match-3D` |
| `SERVE_PORT` | Local demo port | `5180` |
| `ENTRY` | Playable source | `index.html` |
| `COVER_HERO` / `_3X4` / `_16X9` | Cover trio | `assets/cover.png` … |
| `UX_HTML` | 21:9 board | `docs/ux-wireframe.html` |
| `MANAGER_HTML` | A4 HTML | `docs/manager-overview.html` |
| `POSTER_JPG` | Long stitched JPG | `docs/<slug>-Manager-Overview-poster.jpg` |
| `SHOT_IDS` | `.shot-block` ids | hero … footer |
| `UX_MARKERS` | Must-have frames on the 21:9 board | overflow + cleared shots |

When installing the kit into another game:

1. Keep the skill folders as-is
2. Edit `.agents/project.env` (do not leave the example title)
3. Point HTML/covers at that game’s real files
4. Run `$overview-pack`
