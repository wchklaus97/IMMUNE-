# IMMUNE demo handoff

Updated: 2026-08-27

## Current milestone

The requested playable demo milestone is implemented. The permanent research network leads into a mission selector, three authored missions, six playable immune-cell families, and a complete three-phase combat loop. The current local Jelly Material V2 release gate uses Godot 4.6.1 because that is the installed editor; the project target and CI baseline remain Godot 4.7.2 stable.

`CHAR-BASE-B` is now the first Meshy T2 hero replacement after T: an 8,755-triangle, untextured smart-topology GLB generated from the locked B-cell reference for 5 credits. The shared wet-gel shader, aligned procedural ink face, runtime duty-kit swaps, regenerated smooth normals, and a local rear-normal repair produce the approved demo look without another paid generation.

Jelly Material V2 adds a centralized `round_bubbles` B profile with sparse UV-free object-space air pockets while T keeps its `authored_membrane` profile. Bubble defaults remain off for unreviewed families and caller overrides provide a zero-cost fallback. The Forward+-only screen-space SSS write was removed from the Compatibility shader path. No Meshy request or credit was used for this material milestone.

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
- Reproducible B-cell asset provenance plus `tools/smooth_meshy_b_normals.cpp`, which repairs missing Meshy normals and the single-view rear shading seam without moving vertices or changing topology.
- Jelly Material V2 family profiles, object-space round B bubbles, safe-off defaults, and regression coverage on the actual imported surface override.
- Cosmetic mobile duty accessories opt out of shadow casting after Web QA proved their custom-gel shadow pass caused screen-sized floor wedges; character bodies still cast normal shadows.
- Headed gameplay and material capture harnesses plus CPU/GPU/wall-frame instrumentation for Compatibility backends.

## Verification commands

```sh
cd ui/immune-research-network
npm test
npm run build

cd ../../
mkdir -p godot/immune/build/releases/web
godot --headless --path godot/immune --import
godot --headless --path godot/immune --import
godot --headless --path godot/immune --script res://tools/smoke.gd
godot --headless --path godot/immune --script res://tools/check_overflow.gd
godot --headless --path godot/immune --export-release "Windows Desktop" build/releases/IMMUNE-windows.exe
godot --headless --path godot/immune --export-release "Linux/X11" build/releases/IMMUNE-linux.x86_64
godot --headless --path godot/immune --export-release "macOS" build/releases/IMMUNE-macOS.zip
godot --headless --path godot/immune --export-release "Web" build/releases/web/index.html
```

Jelly-specific visual and performance checks:

```sh
godot --path godot/immune --resolution 1920x1080 res://tools/gameplay_shot.tscn -- \
  --out=/absolute/output/path --family=B --mission=MISSION-01 --tag=B-v2
godot --path godot/immune --resolution 1920x1080 res://tools/gel_perf.tscn -- \
  --family=B --material=gel --count=10 --frames=300 --sync=true
```

## Verified release state

- Godot 4.7.2 import, expanded smoke test, and 1920×1080 HUD overflow check pass without script errors.
- Web research-network suite passes 53/53 tests and its production build succeeds.
- Windows x86-64, Linux x86-64, macOS universal, and Web release exports complete without export warnings or errors.
- The exported macOS `.app` is arm64/x86-64 universal, ad-hoc hardened-runtime signed, passes strict code-signature verification, and launches natively with `RELEASE_SMOKE_OK platform=macOS nodes=200`.
- The exported Web build was exercised in Chromium through research → mission select → onboarding → live combat → pause/settings.
- Exported Web console: 0 errors, 0 warnings; canvas fits a 1036×690 viewport without document scroll.
- GitHub Actions run [33072178177](https://github.com/wchklaus97/IMMUNE-/actions/runs/33072178177) completed successfully for commit `ee70f3c`: Web validation, Godot import/smoke/overflow, four-platform export, artifact upload, and native launch markers on Ubuntu, Windows, and macOS all passed.
- A fresh checkout intentionally runs Godot import twice: the first pass builds the ignored `.godot` cache, and the second pass is the clean error gate. This avoids treating the project theme font's first-start cache miss as a source error.
- The 2026-08-27 B-cell replacement was locally rechecked with Godot 4.6.1: two import passes, expanded smoke, 1920×1080 overflow, all four exports, strict macOS signature validation, universal-binary inspection, and headless launch passed. The Web research-network suite remains 53/53 green and its production build succeeds.
- Meshy task `01a043a9-4884-7a6f-bd72-1a716f663403` consumed exactly 5 credits (balance 1505 → 1500). The integrated GLB retains 4,380 vertices / 8,755 faces; front, side, back, 3/4, and face screenshots passed visual review after normal repair.
- Run the four Godot exports sequentially. Parallel exporter processes race on the shared system file `tmpproject.binary`; a sequential rerun produced 0 errors / 0 warnings in all four logs.
- Jelly V2 followed two RED→GREEN cycles: B/T profile contracts first, then the mobile-accessory shadow regression. Six-angle B/T captures passed; B pass 1 was rejected for crater-like donut rings and pass 2 replaced them with restrained round pockets.
- On Apple M4 Pro Compatibility/Metal, three synced 300-frame trials with ten B bodies found median CPU/wall means of 0.912/5.030 ms for StandardMaterial3D, 0.846/4.487 ms for wet gel with bubbles off, and 0.842/4.217 ms with bubbles on. The GPU timer stayed at zero; only “no measurable regression in this harness” is claimed.
- Exported Web QA at 1600×900 and 1036×690 exercised research → B selection → onboarding → live combat → pause → mobile duty. Canvas fit both viewports with no page scroll and the browser console reported 0 errors / 0 warnings. The mobile shadow wedge found during this pass was fixed and rechecked before final export.

## Honest production status

The demo/vertical slice is complete and its local cross-platform release pipeline is green. It is not yet a content-complete commercial game: M/N/A/D still use polished procedural family bodies rather than final approved imported hero meshes, and the campaign still has only three missions. The next safest task is a full three-mission B/T playtest and balance pass using the final exports; after that, prepare a no-credit M-cell reference/prompt/multi-view plan and quality gate. Do not submit another paid Meshy task without explicit approval. The GL Compatibility renderer cannot use Godot's Forward+ subsurface-scattering output, so the current Web-safe gel look relies on coat, wrapped diffuse, transmission, rim, and the bounded bubble layer. A non-zero GPU capture on another backend, more enemy/mission content, accessibility/localization depth, Developer ID notarization, storefront packaging, and CI action-version maintenance remain production work.
