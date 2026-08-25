# Cover spec

Three files. A reskin replaces **all three**. Paths come from `.agents/project.env`.

| File token | Aspect | Typical size | Role |
| --- | --- | --- | --- |
| `COVER_HERO` | flexible (≈ square or 4:3) | large PNG | In-game background + welcome hero |
| `COVER_3X4` | **3:4** | 1024×1536 | Store / catalog portrait |
| `COVER_16X9` | **16:9** | 1536×1024 | Desktop / banner |

## Must show

- Game title matching `GAME_TITLE` / `<title>` / welcome
- One readable gameplay cluster (not a flat icon sheet)
- Tone that matches the HUD

## Must not

- Crop title off the 3:4 safe area (keep title in the upper third)
- Theme that contradicts in-game characters / content sets
- Skip 16:9 because “the PNG is enough”

## After replacing covers

1. `bash .agents/skills/overview-pack/scripts/check-covers.sh`
2. Manager HTML store-cover section points at `COVER_3X4` / `COVER_16X9`
3. 21:9 board assets row uses the same two files
4. `PORT=$SERVE_PORT npm run docs:posters`

## Example — Emoji Cube Match 3D

| Token | Example |
| --- | --- |
| `COVER_HERO` | `assets/cover.png` |
| `COVER_3X4` | `assets/cover-3x4.webp` |
| `COVER_16X9` | `assets/cover-16x9.webp` |
| Title on art | EMOJI CUBE MATCH 3D · orbit / tap / match three |
| HUD tone | indigo / pink / emoji cubes |
| Release aliases | `cover-3-4.webp`, `cover-16-9.webp` (from `npm run package:release`) |
