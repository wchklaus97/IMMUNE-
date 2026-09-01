# Steam graphical assets and provenance

All deliverables below are project assets. This record supports owner review and
the Steam content survey; it is not a legal opinion or a substitute for checking
the rights to every source/reference image.

## Source art

- `source/immune-key-art-landscape-v1.png` — 1536x1024 OpenAI-generated project
  key art, created 2026-09-01. Prompt intent: microscopic sci-fi environment,
  luminous central immune core, six distinct glossy jelly-cell heroes, branching
  biological network, readable exact title `IMMUNE`, no platform marks, no
  reviews, no pricing, and no promotional badges.
- `source/immune-key-art-portrait-v1.png` — 1024x1536 portrait companion from the
  same project-only direction, with exact single title and no third-party marks.
- `source/immune-wordmark.svg` — code-native transparent `IMMUNE` wordmark used
  to produce the library logo. It exists because two generated “transparent”
  attempts baked a checkerboard into RGB and were rejected from the repository.

## Store assets

| File | Size | Content rule |
| --- | ---: | --- |
| `store/header_capsule.png` | 920x430 | Artwork plus product name only |
| `store/small_capsule.png` | 462x174 | Artwork plus product name only |
| `store/main_capsule.png` | 1232x706 | Artwork plus product name only |
| `store/vertical_capsule.png` | 748x896 | Artwork plus product name only |

## Library and icon assets

| File | Size/format | Content rule |
| --- | ---: | --- |
| `library/library_capsule.png` | 600x900 | Artwork plus logo only |
| `library/library_hero.png` | 3840x1240 | Artwork only; no words |
| `library/library_logo.png` | 1280x720 RGBA | Wordmark on real transparency |
| `library/library_header.png` | 920x430 | Artwork plus product name only |
| `icons/shortcut_icon.png` | 256x256 PNG | Core symbol |
| `icons/app_icon.jpg` | 184x184 JPG | Core symbol |
| `icons/mac_icon.icns` | ICNS | Multi-size macOS shortcut icon |

## Screenshots

The six files under `screenshots/` are direct Godot 4.7.2 viewport captures from
the V8.1 authored-body combat scene at 1920x1080. The capture harness uses the
Compatibility renderer and `--store-framing=on` to place real player,
regular-enemy, and boss instances within the visible lane; it does not replace
gameplay renderers, draw concept art over the scene, or alter shipping
camera/balance data. Every capture passed selection identity, portrait
lifecycle, HUD overlap, safe-area, and nonblank image checks.

| File | V8.1 capture | SHA-256 |
| --- | --- | --- |
| `01-core-defense.png` | T / M01 / fixed combat | `31fb76f6eb2213e82f959d25fd0fb7f589dfbd5a4f5dedc16307f74c5829059e` |
| `02-boss-spore-queen.png` | B / M02 / boss combat | `92d73d60ccda49cd0dc015269f351dfacd43ba4b4c437acfba2b482983f58d3b` |
| `03-expedition-macrophage.png` | M / M03 / mobile combat | `0c6d4eef4e491574a27a735f376674ff54e1a266afa708a69e53f617a779c180` |
| `04-boss-mutation-hive.png` | N / M04 / boss combat | `7bbf4caa3f69c8ded93ec71d604a1d9b98a6d9a61729d529f8a4aeb2a18e22ee` |
| `05-relay-expedition.png` | A / M05 / mobile combat | `55834d3af0a7c2e8d1e8ea7ebfb72c55902e60d4a0732139d749bf8ed726ff1d` |
| `06-boss-systemic-devourer.png` | D / M06 / boss combat | `0317749bd60c23708ee1195faad9f66736ec9ed390d288ee42bfc8be55337a46` |

The generated Meshy/Tripo development models are excluded from release exports;
these screenshots show the same authored procedural jelly bodies included in
the shipping PCK.

## Automated check

```sh
npm run validate:steam-assets
```

The current accepted result is:

```text
STEAM_ASSETS_OK files=17 screenshots=6 logo_alpha=transparent
```

Official graphical rules:

- <https://partner.steamgames.com/doc/store/assets>
- <https://partner.steamgames.com/doc/store/assets/rules>
