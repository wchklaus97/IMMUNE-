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
- complete Traditional Chinese / English coverage for all 200 research nodes,
  six campaign names, and the mission/combat UI with a persisted runtime locale
  selector;
- a player-facing mission desk with a confined, independently scaled six-family
  3D jelly preview, visible selection states, readable badges, and responsive
  1600x900 / 1280x720 layouts;
- a completed English catalog editorial pass plus a two-table structural CSV
  validator that runs before localization drift detection in CI;
- a real-time MISSION-01 regression across all six families, including the
  corrected A-family hover-projectile trajectory and relay duty cycle;
- a Meshy-7-aware, no-credit-by-default M-cell generation and GLB intake
  pipeline;
- zero-credit source-authored Fizzy production bodies for N, A, and D, with
  fixed/mobile/relay integration;
- a balance-neutral biological combat arena, phase-readable cleanse zone,
  styled mission/vitals/action HUD, and a Compatibility-safe A RelayDish; and
- a fail-fast 36-run headed campaign soak with telemetry v2 plus a reproducible
  Instruments Metal-trace analyzer; and
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
  composes core, player, enemies, presentation-only arena meshes, HUD, telemetry,
  and pause/settings.
- `godot/immune/combat/` owns enemy traits, projectile signatures, the core, and
  local playtest telemetry.
- `godot/immune/ui/mission_select/` owns sequential campaign selection and family
  preview; `ui/research/` owns the permanent network.
- `godot/immune/characters/character_root.gd` is the shared procedural/imported
  hero-body adapter. Missing optional GLBs always retain the procedural fallback.
- `godot/immune/characters/authored_jelly_body.gd` owns the reusable N/A/D
  production silhouette, family material profiles, face, membrane, and D crown.
- `tools/meshy/` owns the reviewed paid-generation gate, no-network tests, task
  metadata, GLB validation, and explicit M-slot installation.
- `tools/generate_catalog_localization.mjs` owns the deterministic 406-row
  research translation artifact and its CI drift contract.
- `tools/validate_translation_csv.mjs` owns the shared game/research CSV shape,
  duplicate, blank, placeholder-parity, and English-script checks.
- `.github/workflows/ci.yml` owns Godot 4.7.2 import/smoke, catalog translation
  drift, bounded T/B first/final mission balance, all-family MISSION-01 balance,
  bilingual layout, exports, and three native launch checks.

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

The matrix now has a second real-time CI sentinel for MISSION-01 across T, B, M,
N, A, and D. All six pass with real projectile hits and 12/12 Core health; the
durations are 21.833, 20.033, 20.833, 20.533, 22.400, and 20.200 seconds
respectively. This expansion found an A-only defect: the hovering WeaponSocket's
projectile vector had been flattened, so all shots passed above enemy collision
centres. Range/facing remains horizontal while projectile velocity now uses the
full 3D target vector. The playtest autopilot and matrix also treat A's expedition
duty as `relay`, not `mobile`.

After the trajectory fix, A initially missed the final MISSION-06 health margin.
Matching its fixed cooldown to the existing 0.58-second relay cooldown produced
clean victories at 22.400 seconds for MISSION-01 and 95.467 seconds for
MISSION-06, both with 12/12 Core health. N and D MISSION-06 also pass at 87.150
and 87.767 seconds. An attempted 8x simulation was rejected because accelerated
physics distorted collisions and autopilot timing; balance evidence remains 1x.

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
bubbles, and fixed kit; the existing mobile duty kit remains functional. The
rejected GLB remains in the repository but is no longer the M runtime body.

`CHAR-BASE-N`, `CHAR-BASE-A`, and `CHAR-BASE-D` are now source-authored Fizzy
production bodies, not generic runtime blockouts. One reusable builder keeps
family-specific colours and random seeds while matching the locked silhouette:
N is lime, grounded, and has a short pill mouth; A is amber, footless, hovering,
and relay-only; D is deep orange, grounded, and has five crown lobes. Their
adapters preserve the authored bubble/microbubble/inclusion core and clear
membrane, suppress conflicting procedural pieces, and retain N/D locomotion or A
RelayDish as appropriate. The pass used no Meshy POST and consumed no credit.
Six-angle and gameplay evidence is checked in under
`godot/immune/build/shots/nad-production*`. Full implementation evidence lives
in `docs/godot-prompter/specs/2026-08-29-nad-authored-jelly.md`.

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

The built-in viewport GPU timer was also zero on Forward Mobile and Forward+
Metal. A 2026-08-29 Xcode `Metal System Trace` pass finally provided real GPU
frame spans for ten B bodies on Apple M4 Pro Forward+. Across matched 370-frame
post-warm-up samples, StandardMaterial3D measured 4.805 ms mean / 7.632 ms p95;
wet gel measured 5.645 ms mean / 7.986 ms p95. The gel delta is +0.840 ms mean
(17.5%) and +0.354 ms p95 (4.6%). The longer 1,164-frame gel sample measured
6.464 ms mean / 8.093 ms p95 / 13.087 ms max. The Standard capture target hit
the 12-second Instruments limit after 430 observed frames, so only its 370
complete post-warm-up frames are used and the comparison is not generalized to
Compatibility/Web/other GPUs. Full methodology is in
`docs/godot-prompter/specs/2026-08-29-all-family-soak-and-metal-gpu.md`.

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
- Research localization (2026-08-29): deterministic 406-row generator check;
  all 400 node name/description fields plus six campaign names resolve in
  English; Traditional Chinese fallback and a live locale switch pass; the
  1920×1080 research HUD passes in `zh_HK` and `en`.
- Player-facing mission desk QA (2026-08-29): the preview is confined to an
  owned SubViewport; six family scales, both locales, 1600x900 and 1280x720,
  selection/locked states, 18 fixed/mobile-or-relay/boss gameplay frames, and
  clean render-resource shutdown pass. Full English family names and player-copy
  replace raw codes and internal pipeline language. The shared CSV validator
  passes 2 files / 595 rows. Evidence and rationale live in
  `docs/godot-prompter/specs/2026-08-29-player-facing-mission-desk-qa.md`.
- Combat presentation and Web renderer pass (2026-08-29): 58-degree combat
  camera, 20 collision-free biological arena meshes, two cleanse rings plus
  eight signal markers, styled top HUD, and three 220x52 action controls. The
  A RelayDish uses shadow-free, fully opaque accent geometry; its thin torus no
  longer submits the wet-gel/transparent path that produced screen-sized black
  triangles on Compatibility/Web. Six families × two resolutions × three states
  produced 36/36 headed captures with zero leaks. Real Chromium Fixed-to-Relay
  input passes at 1600x900 and 1280x720 with exact canvas fit, no scroll, and
  zero console errors/warnings. Details live in
  `docs/godot-prompter/specs/2026-08-29-combat-presentation-polish.md`.
- All-family headed soak (2026-08-29): 36/36 real-time Compatibility runs across
  all six missions and T/B/M/N/A/D pass with 2,048.902 simulated seconds,
  2,043.823 wall seconds, maximum 1.007 wall/game ratio, minimum Core 6/12,
  99.1% mean projectile accuracy, minimum steady p05 111 FPS, maximum 348 draw
  calls, and zero timeouts/failures. Every family preserves the strict
  M1<M2<M3<M4<M5<M6 duration ladder. Reports checkpoint after every run and soak
  mode stops on the first run-level contract failure. Mission/family filters are
  validated before loading, so a typo cannot silently fall back to MISSION-01.
- Metal GPU evidence (2026-08-29): `gel_perf.gd` no longer calls `force_sync()`
  from a `frame_post_draw` continuation (which stalled Forward+), explicitly
  reports unavailable zero-only built-in timers, and writes JSON. A checked-in
  streaming analyzer resolves Instruments refs, filters exact Godot PID, avoids
  double-counting overlapping GPU events, and passes its Node overlap test.
- Six-family runtime regression (2026-08-29): MISSION-01 passes for T/B/M/N/A/D
  at real 1x simulation speed with real hits, both applicable duties, and 12/12
  Core health. Focused N/D/A MISSION-06 runs and the unchanged T/B first/final
  sentinel also pass after the A trajectory and relay corrections.
- Campaign candidate: full six-mission × T/B 12-run matrix passes.
- Web research app: 53/53 Node tests pass and the production single-file build
  succeeds.
- Exports: Windows x86-64, Linux x86-64, macOS universal, and single-threaded Web
  rebuilt sequentially after the combat presentation pass with v0.4.0 content.
  All four export logs contain no script, parse, compile, or engine errors.
- macOS: arm64+x86_64, strict code-signature verification, ad-hoc hardened
  runtime signature, bundle/version `com.wchklaus97.immune` / `0.4.0`, and native
  `RELEASE_SMOKE_OK platform=macOS nodes=200`.
- Exported Web: Chromium research → mission → A selection → A combat →
  Fixed/Relay duty → pause flow with real keyboard input;
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
- N/A/D authored production pass (2026-08-29): three locked silhouettes wired
  into their real scenes with family Fizzy cores and clear membranes; 18
  multi-angle and 9 gameplay captures; expanded body/duty/shadow smoke; 53/53
  Web tests; 6/6 Meshy workflow tests; three manifest dry-runs with
  `network_calls=0 credits=0`; HUD overflow; four-run T/B balance sentinel; four
  release exports; exported macOS native smoke; and Web HTML/WASM/PCK HTTP checks
  all pass locally.

Generated local artifacts (ignored by Git):

- `godot/immune/build/releases/IMMUNE-windows.exe`
- `godot/immune/build/releases/IMMUNE-linux.x86_64`
- `godot/immune/build/releases/IMMUNE-macOS.zip`
- `godot/immune/build/releases/web/index.html`
- `outputs/playtests/campaign-expansion-candidate-1-12run.json`
- `outputs/playtests/all-family-campaign-soak-20260829.json`
- `outputs/playtests/metal-traces/`
- `outputs/player-qa-20260829/`
- `outputs/combat-polish-20260829/`

## Repeatable release commands

```sh
cd ui/immune-research-network
npm test
npm run build

cd ../../
node --test tools/analyze_metal_gpu_trace.test.mjs
node tools/generate_catalog_localization.mjs --check
node tools/validate_translation_csv.mjs
godot --headless --path godot/immune --import
godot --headless --path godot/immune --import
godot --headless --path godot/immune --script res://tools/smoke.gd
godot --headless --path godot/immune --script res://tools/check_overflow.gd
godot --headless --path godot/immune --script res://tools/balance_matrix.gd -- \
  --out=user://six-family-mission-01.json --missions=MISSION-01 \
  --families=T,B,M,N,A,D --trials=1
godot --headless --path godot/immune --script res://tools/balance_matrix.gd -- \
  --out=outputs/playtests/campaign-expansion-candidate-1.json --trials=1
godot --path godot/immune --rendering-method gl_compatibility \
  --script res://tools/balance_matrix.gd -- \
  --soak --out=/absolute/path/all-family-campaign-soak.json
godot --headless --path godot/immune --export-release "Windows Desktop" build/releases/IMMUNE-windows.exe
godot --headless --path godot/immune --export-release "Linux/X11" build/releases/IMMUNE-linux.x86_64
godot --headless --path godot/immune --export-release "macOS" build/releases/IMMUNE-macOS.zip
godot --headless --path godot/immune --export-release "Web" build/releases/web/index.html
```

Run exports sequentially. Parallel Godot exporters race on the shared
`tmpproject.binary` file.

## Honest status and next development tranche

The six-mission vertical slice, all six base-cell playable bodies, and local
cross-platform release pipeline are complete. It is not a content-complete
commercial release. Remaining work is:

1. Keep the N/A/D Meshy manifests as optional comparisons only. Any paid task
   still needs a separate exact 5-credit approval; never batch paid retries after
   a failed task. The playable demo no longer depends on these generations.
2. Treat the checked-in CI on Godot 4.7.2 as the final remote gate. Local proof is
   on 4.6.1 because that is the installed editor.
3. Add a Developer ID Application identity, notarization credentials, privacy /
   storefront metadata, and store-specific packaging. The current macOS artifact
   is valid ad-hoc signed but cannot be publicly notarized with the credentials
   available on this machine.
4. Non-zero GPU timing and a 34-minute automated all-family campaign soak are now
   complete. The remaining product-risk gate is longer human playtesting across
   all six families for fun, readability, accessibility, and control feel; the
   deterministic autopilot cannot honestly prove those qualities.

These are explicit external/product gates, not hidden broken demo work. No release
upload, notarization, or storefront submission was performed.
