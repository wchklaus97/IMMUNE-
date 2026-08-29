# IMMUNE demo handoff

Updated: 2026-08-29

## Current milestone

IMMUNE v0.4.0 is a playable six-mission vertical slice. The permanent 200-node
research network leads to a sequential mission desk, six playable base-cell
families, and a three-phase combat loop: Core Defense, Front-line Cleanse, and
Boss Total War. The local validation editor is Godot 4.6.1; the project and CI
target remain Godot 4.7.2 stable.

The latest tranche adds:

- MISSION-04 low-health enrage, MISSION-05 out-of-fire regeneration, and
  MISSION-06's combined systemic threat;
- T focused execution below 30% health and B antibody mark stacking;
- deterministic combat telemetry plus a real-scene balance matrix;
- Traditional Chinese / English mission and combat UI with a persisted runtime
  locale selector;
- a Meshy-7-aware, no-credit-by-default M-cell generation and GLB intake
  pipeline; and
- four-platform v0.4.0 release artifacts.

## Playable loop

1. Explore the permanent research network.
2. Press `C` or use the combat button to open the mission desk.
3. Select one of six missions and one of six cell families.
4. Complete Core Defense, Front-line Cleanse, and Boss Total War.
5. Receive antigen, biomass, protomass, discovery, and campaign rewards.
6. Unlock the next mission and return to the research network with versioned
   progress preserved.

## Architecture and ownership

- `godot/immune/autoload/` owns catalog, research/save state, persisted settings,
  audio, and shared VFX lookup.
- `godot/immune/resources/combat/` defines typed mission, difficulty, family,
  and pathogen data contracts.
- `godot/immune/scenes/combat_lane.gd` owns the three-phase mission FSM and
  composes core, player, enemies, HUD, telemetry, and pause/settings.
- `godot/immune/combat/` owns enemy traits, projectile signatures, the core, and
  local playtest telemetry.
- `godot/immune/ui/mission_select/` owns sequential campaign selection and family
  preview; `ui/research/` owns the permanent network.
- `godot/immune/characters/character_root.gd` is the shared procedural/imported
  hero-body adapter. Missing optional GLBs always retain the procedural fallback.
- `tools/meshy/` owns the reviewed paid-generation gate, no-network tests, task
  metadata, GLB validation, and explicit M-slot installation.
- `.github/workflows/ci.yml` owns Godot 4.7.2 import/smoke, bounded first/final
  mission balance, layout, exports, and three native launch checks.

## Balance candidate 1

All six missions passed one deterministic T run and one deterministic B run at
1× physics speed: 12/12 victories, a strictly increasing duration ladder for
each family, real projectile hits, both duty forms, regular core contact, and
one boss defeat per run. MISSION-06 finishes at 89.750 s for T and 81.283 s for
B, with both cores at 12/12. The full evidence table and tuning rationale live
in `docs/godot-prompter/specs/2026-08-28-immune-campaign-expansion-results.md`.

CI intentionally runs a smaller four-run sentinel: MISSION-01 and MISSION-06 for
T and B. The harness has both a 120-second simulated-game timeout and a
150-second wall timeout per run.

## Jelly and hero assets

`CHAR-BASE-B` remains an approved Meshy T2 hero replacement: 8,755 triangle
faces, untextured GLB, aligned procedural ink face, hidden procedural limbs, and
the `round_bubbles` wet-gel profile. T retains its imported authored membrane.

`CHAR-BASE-M` retains a rejected Meshy T2 candidate for provenance only. Task
`01a0478d-eb9c-7bb1-9d52-0b220cb002a8` produced an untextured 8,832-triangle
GLB. The downloaded file omitted vertex normals, so the workflow stopped before
installation, preserved the immutable download, and created a zero-credit Assimp
smooth-normal derivative. Geometry, bounds, and face count are unchanged.
The installed derivative SHA-256 is
`1eadda4a9c8dfccbd27c5471edf6e2079518d239832cc0dc64f3a46be95bcd4a`.
On 2026-08-29 the user explicitly rejected that candidate's texture and overall
quality, then accepted the zero-credit `fizzy` reference-match direction. The
shipping M scene now instantiates
`godot/immune/characters/base_m/reference_body.tscn`: a fused round authored body
with embedded eyes and mouth, medium bubbles, microbubbles, fine inclusions, and a
Compatibility-safe fresnel membrane. The adapter preserves those authored
materials and suppresses only M's conflicting procedural face, limbs, identity,
bubbles, and fixed kit; the existing mobile duty kit remains functional. New
shader paths default off for every other family. The rejected GLB remains in the
repository but is no longer the M runtime body and must not be used as the visual
baseline for N/A/D. N/A/D remain procedural and their paid tasks are paused.

Jelly performance was repeated on 2026-08-28 with ten B bodies, three synced
300-frame trials at 1920×1080 on Apple M4 Pro Compatibility/Metal. Median CPU /
wall means were 1.035 / 3.617 ms for StandardMaterial3D, 1.053 / 4.070 ms for gel
with bubbles off, and 1.035 / 3.892 ms for gel with bubbles on. The GPU timer
remained zero, so only “no measurable regression in this harness” is claimed.

The same three-trial harness was repeated with ten imported M bodies. Median CPU
/ wall means were 0.969 / 4.266 ms for StandardMaterial3D, 0.926 / 4.076 ms for
gel with bubbles off, and 0.963 / 4.306 ms for gel with bubbles on. The GPU timer
again remained zero; the supported conclusion is no measurable M bubble
regression, not that the gel path is faster.

## Meshy state and cost boundary

Official Meshy API docs and the 2026-08-28 changelog were reviewed. The latest
authenticated API response used server version `v2026.08.28.post1`. One approved
M-cell Image-to-3D task consumed exactly 5 credits, moving the balance from 1,500
to 1,495. No retry, second generation, texture, remesh, rig, or animation task was
submitted.

The selected M route is Image-to-3D Smart Topology, Meshy-7-compatible
`meshy-t2`, triangle topology, 8,000 target faces, untextured GLB, expected cost
5 credits. Dry-run remains the default. A future paid task still requires both
`--execute --approve-credits 5`. All paid POST failures, including HTTP 429/5xx,
stop without automatic retry; inspect Meshy's task list before another create
call. Do not rerun the completed M generation merely to recreate the installed
asset: both the immutable download and verified derivative are stored locally.

```sh
python3 -m unittest tools/meshy/test_workflow.py
python3 tools/meshy/run_m_cell_asset.py
python3 tools/meshy/run_m_cell_asset.py --balance-only
python3 tools/meshy/run_m_cell_asset.py --manifest tools/meshy/n_cell_request.json
python3 tools/meshy/run_m_cell_asset.py --manifest tools/meshy/a_cell_request.json
python3 tools/meshy/run_m_cell_asset.py --manifest tools/meshy/d_cell_request.json
python3 tools/meshy/validate_hero_glb.py \
  --project-dir meshy_output/20260828_164806_char-base-m_01a0478d
```

## Verification completed

- Godot 4.6.1: two import passes, six-mission smoke, bilingual translation
  contract, 1920×1080 overflow check, and the four-run CI balance sentinel pass.
- Campaign candidate: full six-mission × T/B 12-run matrix passes.
- Web research app: 53/53 Node tests pass and the production single-file build
  succeeds.
- Exports: Windows x86-64, Linux x86-64, macOS universal, and single-threaded Web
  rebuilt sequentially after M installation with v0.4.0 content. All four export
  logs contain no script, parse, compile, or engine errors.
- macOS: arm64+x86_64, strict code-signature verification, ad-hoc hardened
  runtime signature, bundle/version `com.wchklaus97.immune` / `0.4.0`, and native
  `RELEASE_SMOKE_OK platform=macOS nodes=200`.
- Exported Web: Chromium research → mission → M selection → M combat →
  Fixed/Mobile duty → pause/resume flow with real mouse and keyboard input;
  1600×900 and 1280×720 canvas fit, no document scroll, all eight requested
  resources returned 200, and the console reported 0 errors / 0 warnings.
- M integration balance: MISSION-01 M completed in 22.367 s with core 12/12;
  MISSION-06 M completed in 88.633 s with core 12/12 and 83 projectile hits.
- Meshy: dry-run, balance-only request, four no-network safety tests, B validation,
  one approved 5-credit M generation, smooth-normal geometry invariant, M GLB
  validation, six-angle visual review, M6 gameplay review, and installation pass.
- Visual correction pass (2026-08-29): reference/current gap review, six-angle
  `clear` and `fizzy` look-dev renders, two clean Godot imports, release smoke,
  1920x1080 overflow check, and six Meshy workflow safety tests. Ten-body M
  harness results were baseline CPU/wall 0.722/1.572 ms and opt-in three-layer
  core 0.623/1.354 ms in one 180-frame trial; GPU timing was unavailable (0 ms),
  so this supports only "no measurable regression in this run." The transparent
  screen-refraction experiment was rejected after Compatibility/Metal reported an
  unavailable texture and was replaced with the stable fresnel-alpha shell.
- Production M promotion (2026-08-29): accepted `fizzy` body wired into the real
  M scene; six-angle and fixed/mobile/boss captures; two import passes; expanded
  six-family smoke; 1920x1080 overflow; M1/M6 balance victories; 53/53 web tests;
  four release exports; and exported macOS native smoke all pass locally.
- CI macOS smoke logging no longer assumes Godot creates `--log-file`. The app's
  stdout/stderr is captured with `tee`, so the successful release marker visible
  in Actions is also guaranteed to exist in the file checked by `grep`.

Generated local artifacts (ignored by Git):

- `godot/immune/build/releases/IMMUNE-windows.exe`
- `godot/immune/build/releases/IMMUNE-linux.x86_64`
- `godot/immune/build/releases/IMMUNE-macOS.zip`
- `godot/immune/build/releases/web/index.html`
- `outputs/playtests/campaign-expansion-candidate-1-12run.json`

## Repeatable release commands

```sh
cd ui/immune-research-network
npm test
npm run build

cd ../../
godot --headless --path godot/immune --import
godot --headless --path godot/immune --import
godot --headless --path godot/immune --script res://tools/smoke.gd
godot --headless --path godot/immune --script res://tools/check_overflow.gd
godot --headless --path godot/immune --script res://tools/balance_matrix.gd -- \
  --out=outputs/playtests/campaign-expansion-candidate-1.json --trials=1
godot --headless --path godot/immune --export-release "Windows Desktop" build/releases/IMMUNE-windows.exe
godot --headless --path godot/immune --export-release "Linux/X11" build/releases/IMMUNE-linux.x86_64
godot --headless --path godot/immune --export-release "macOS" build/releases/IMMUNE-macOS.zip
godot --headless --path godot/immune --export-release "Web" build/releases/web/index.html
```

Run exports sequentially. Parallel Godot exporters race on the shared
`tmpproject.binary` file.

## Honest status and next development tranche

The six-mission vertical slice and local cross-platform release pipeline are
complete. It is not a content-complete commercial release. Remaining work is:

1. Replace N/A/D procedural hero bodies only after each reference and cost gate
   is approved; never batch paid retries after a failed task.
2. Expand English localization from the complete mission/combat flow into the
   200-node authored research catalog; that source content remains zh-HK-first.
3. Treat the checked-in CI on Godot 4.7.2 as the final remote gate. Local proof is
   on 4.6.1 because that is the installed editor.
4. Add a Developer ID Application identity, notarization credentials, privacy /
   storefront metadata, and store-specific packaging. The current macOS artifact
   is valid ad-hoc signed but cannot be publicly notarized with the credentials
   available on this machine.
5. Capture a non-zero GPU timing result on a backend that exposes it and perform
   longer human playtests across all six families, not only the deterministic T/B
   balance baseline.

These are explicit external/product gates, not hidden broken demo work. No release
upload, notarization, or storefront submission was performed.
