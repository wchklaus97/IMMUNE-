# IMMUNE demo handoff

Updated: 2026-08-27

## Current milestone

The requested playable demo milestone is implemented and release-checked in Godot 4.7.2 stable. The permanent research network now leads into a mission selector, three authored missions, six playable immune-cell families, and a complete three-phase combat loop.

## Playable loop

1. Explore the 200-node permanent research network.
2. Press `C` or use the combat button to open the immune mission console.
3. Select one of three missions, one of six families, and a difficulty.
4. Complete Core Defense, Forward Cleanse, and Boss Total War.
5. Receive antigen, biomass, protomass, discovery, and campaign rewards.
6. Return to the research network with versioned progress preserved.

## Implemented systems

- Three data-driven mission resources and scenes with escalating enemy/difficulty profiles.
- T/B/M/N/A/D playable family profiles, shared wet-gel shader treatment, duty forms, animations, and active-skill VFX entries.
- Health bars, damage numbers, hit flash, camera shake, haptics, onboarding, pause/settings, audio buses, original music/SFX, keyboard, and gamepad input.
- Version 2 JSON save data with version 1 migration, mission selection, completion records, settings persistence, and safe catalog validation.
- Traditional Chinese Web-safe Noto Sans HK variable font with its OFL license.
- Windows, Linux, macOS universal, and single-threaded Web release presets, GitHub Actions validation/export/native-smoke matrix, and Git LFS rules for authored media.

## Verification commands

```sh
cd ui/immune-research-network
npm test
npm run build

cd ../../
godot --headless --path godot/immune --import
godot --headless --path godot/immune --script res://tools/smoke.gd
godot --headless --path godot/immune --script res://tools/check_overflow.gd
godot --headless --path godot/immune --export-release "Windows Desktop" build/releases/IMMUNE-windows.exe
godot --headless --path godot/immune --export-release "Linux/X11" build/releases/IMMUNE-linux.x86_64
godot --headless --path godot/immune --export-release "macOS" build/releases/IMMUNE-macOS.zip
godot --headless --path godot/immune --export-release "Web" build/releases/web/index.html
```

## Verified release state

- Godot 4.7.2 import, expanded smoke test, and 1920×1080 HUD overflow check pass without script errors.
- Web research-network suite passes 53/53 tests and its production build succeeds.
- Windows x86-64, Linux x86-64, macOS universal, and Web release exports complete without export warnings or errors.
- The exported macOS `.app` is arm64/x86-64 universal, ad-hoc hardened-runtime signed, passes strict code-signature verification, and launches natively with `RELEASE_SMOKE_OK platform=macOS nodes=200`.
- The exported Web build was exercised in Chromium through research → mission select → onboarding → live combat → pause/settings.
- Exported Web console: 0 errors, 0 warnings; canvas fits a 1036×690 viewport without document scroll.
- Windows and Linux exports passed binary-format and archive-integrity checks. CI now downloads and launches those exact release artifacts on native Ubuntu/Windows runners; that remote matrix remains unexecuted until the uncommitted branch is pushed.

## Honest production status

The demo/vertical slice is complete. It is not yet a content-complete commercial game: B/M/N/A/D currently use polished procedural family bodies rather than final approved imported hero meshes, and the campaign still has only three missions. The next production milestone should first execute the remote native-smoke matrix, then focus on final character asset replacement, more enemy/mission content, balance/playtesting, accessibility/localization depth, Developer ID notarization, and storefront packaging.
