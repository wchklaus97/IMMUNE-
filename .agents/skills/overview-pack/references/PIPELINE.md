# Overview pack checklist

Generic. Fill `.agents/project.env` first (example host: Emoji Cube Match 3D).

## Covers
- [ ] `COVER_HERO` (in-game hero)
- [ ] `COVER_3X4` (store 3:4)
- [ ] `COVER_16X9` (catalog 16:9)
- [ ] Title on art matches `GAME_TITLE`
- [ ] `bash .agents/skills/overview-pack/scripts/check-covers.sh`

## UI/UX 21:9 (`$uiux-wireframe`)
- [ ] Journey frames are **this game’s** real screens (do not copy another title’s list)
- [ ] Loop, IA, interactions match `ENTRY`
- [ ] Assets row shows 3:4 **and** 16:9
- [ ] Locale twins updated together when the host has them

## Manager view (`$manager-overview`)
- [ ] Hero uses `COVER_HERO`
- [ ] UX phones + desktop match current shots
- [ ] Content galleries match live data (example: `SHAPE_ORDER` play order)
- [ ] Store covers show 3:4 + 16:9
- [ ] Every section is a `.shot-block` (`SHOT_IDS`)
- [ ] Locale twins updated together when the host has them

## Bake
- [ ] `PORT=$SERVE_PORT npm run serve` is up
- [ ] HUD/roster changed → `PORT=$SERVE_PORT npm run docs`
- [ ] Copy/covers only → `PORT=$SERVE_PORT npm run docs:posters`
- [ ] `bash .agents/skills/overview-pack/scripts/validate-overview-pack.sh`
- [ ] Open `UX_HTML` and `MANAGER_HTML`
- [ ] Open `POSTER_JPG`

## Example (this repo)

Emoji Cube Match 3D uses 9 journey frames (tutorial → overflow → cleared),
25 shapes, tray 7→6→5, and filenames prefixed `Emoji-Cube-Match-3D-`.
Another game should not keep those facts — only the pipeline.
