# IMMUNE demo handoff

Updated: 2026-08-30

## V5.1 current handoff — supersedes the V4 status below

V5.1 was developed from `d40b23a63e6553025238acf0e34573eac6160878`.
Use `git rev-parse HEAD` after the local handoff commit as its exact committed
source identity. The working editor and every final runtime/capture/export check in this
tranche use Godot `4.7.2.stable.official.ed1daf0bf` with Compatibility rendering.

### What changed

- The shipping six-family `fizzy` surface now uses a deterministic 512x512 RGB
  CC0 orange-peel micro-height map in object-space triplanar projection with
  mipmaps. Production scale/depth are `0.45`/`0.004`; rejected procedural rings,
  connected wrinkles, quilt rows, microbubble relief, and inclusion relief are
  disabled rather than stacked underneath it.
- `wet_gel.gdshader` carries the body colour outside engine `ALBEDO`, bounds each
  direct-light contribution independently, and uses the height signal for shallow
  grazing relief plus coherent wet-coat breakup. `jelly_shell.gdshader` is an
  energy-bounded dielectric clear pass.
- `ImmuneGelLightContract` accepts `DirectionalLight3D` only. Debug scene audits
  and headed QA probes enforce no more than three directional lights and one
  shadow-casting directional light per viewport, reporting rejected Omni/Spot
  lights by class and node path. Shipping scenes statically own the accepted one
  shadowed key plus up to two unshadowed fills topology; this is not described as
  a release-build runtime rejection layer.
- Combat now has a 336x252 own-world hero portrait without changing the live
  player scale, camera, or collision. It synchronizes duty, disables rendering
  and frees the character when hidden, and recreates it after a valid resize.
- M/N/A/D live and portrait characters reuse constructed-once cached sphere,
  capsule, and torus meshes which their callers treat as read-only. The body and
  membrane retain independent materials but no longer duplicate the same 96x48
  vertex buffers.
- Aspect `<= 0.8` gets a 2.25x tall-HUD theme/spacing pass. The locked target is
  720x1280; 360/390 px narrow phones and safe-area insets remain future work.
- `ResearchState` resolves debug `--save-path=` before initial load/seed. Every
  `res://tools/*.gd` or `.tscn` QA entry automatically reserves a unique
  process/run-specific temporary save unless it receives a valid explicit debug
  override. Malformed existing saves are preserved byte-for-byte; QA exits `74`
  instead of overwriting them, while normal gameplay falls back to an in-memory
  demo seed.
- `gameplay_shot.gd`, `crit4_probe.gd`, `gel_perf.gd`, and `shot.gd` validate
  their supported arguments and fail closed on invalid selections, non-finite
  values, directory/write/reopen failures, or inapplicable height overrides.

### Source and license lock

- Generator: `build/generate_jelly_height.py`
- Asset: `godot/immune/characters/gel/jelly_micro_height.png`
- License/provenance: `godot/immune/characters/gel/jelly_micro_height.LICENSE.md`
- ProcTexture CC0 pack SHA-256:
  `a95fa0d0acfe71054d8f2ea8993887e39ce4be7190fb9bf1d354088cac6815c0`
- Source height SHA-256:
  `c1b1a860dec8e404588d9aaba1417140148218553b8af9a90fb09293f5f4ae87`
- Checked-in PNG SHA-256:
  `25ba40fcb8a6d800fc1ffe4747a4dadad95593fc8d8f3299aed5eef7888fc9a6`
- V5.1 submitted no Meshy task, made no paid API retry, and consumed zero credits.

### Final local evidence

- Both explicit-save and no-argument smoke pass. The real save stayed identical
  by SHA-256, size, mtime, and ctime; evidence is in
  `outputs/v5.1-final-validation-472/real-save.before.txt` and `.after.txt`.
- The progressive headed light probe reports median luma `0.0509`, `0.1574`,
  `0.2331`, `0.2703` for zero through three production-matched directional
  lights, with `0.52%` dominant clipping at the accepted three-light topology.
  It proves Omni, Spot, and a second shadow-casting directional light are all
  rejected before rendering.
- Six views for each of T/B/M/N/A/D (36 PNGs) and a five-frame T yaw sequence
  pass automated visual-critic review under `outputs/v5.1-final-validation-472/family-shots/` and
  `yaw/`.
- Landscape T/B/M/N/A/D and tall T gameplay produce 21 correctly sized PNGs.
  All landscape reports pass 5/5 lifecycle states, tall passes 3/3, every sample
  has no HUD overlap, and portrait visibility/free/recreate contracts pass. The
  hash-bound aggregate is `gameplay/final-source-locked-audit.json`.
- Six zh_HK mission-select captures pass exact family/mission identity, nonblank,
  write, and reopen checks; the accepted combined log is
  `logs/final-source-locked-mission-select.log`.
- An uncontended ten-B-body, 300-frame, 1920x1080 sentinel measures V5.1 gel at
  `1.140/1.496 ms` CPU mean/p95 and `2.788/4.596 ms` wall mean/p95 versus
  StandardMaterial3D at `1.036/1.358 ms` and `2.817/4.587 ms`. Gel-minus-control
  is `+10.04%` CPU mean and `-1.03%` wall mean. The viewport GPU timer is
  unavailable, the small wall difference is scheduler-sensitive, this is one
  local CPU/wall run, and StandardMaterial3D is not called V4.
- A real-scene MISSION-01 autopilot regression passes T/B/M/N/A/D 6/6 with a
  surviving `12/12` core, real projectile hits, and each mobile/relay duty path.
- The freshly exported Godot 4.7.2 Web build passes the complete browser flow.
  Baseline Metal is `119.841/103.093` mean/p05 FPS; 4x CPU + SwiftShader is
  `11.284/7.937`. Both have exact canvas fit, no scroll, no effective resource
  failure, and no console/page error. Expected SwiftShader ReadPixels warnings
  and superseded aborted preloads remain classified separately in the report.
- The final source-locked rerun passes root tools 36/36, Web UI tests 53/53 and
  production build, deterministic texture-byte lock, Godot import, both smoke
  modes, research-HUD overflow, light probe, 36 family views, five yaw frames,
  six mission captures, all gameplay reports/captures, six-family balance, perf,
  fresh Web export, and browser QA. The import retains longstanding non-fatal
  Unicode/NUL warnings but has no script/parse/compile/error failure. Playtest
  template, translation (595 rows), catalog (200 nodes/406 rows), release
  identity, and `git diff --check` also pass.

Evidence workspace root: `outputs/v5.1-final-validation-472/`.
`accepted-manifest.json` enumerates the source-locked accepted files and hashes;
unlisted intermediate, partial, source-aligned, rerun, and negative artifacts are
diagnostic only. The final Web build lives under ignored
`godot/immune/build/releases/v5.1-final-validation-472/web/`; generated exports
must never be committed.

Save/report publication uses validated temporary files, backup-backed
replacement, exact-byte/schema/current-identity verification, and schema-aware
orphan recovery. It is recoverable for ordinary same-filesystem failures; it is
not a power-loss durability or hostile same-user TOCTOU guarantee.

### Honest external gates

- No V5.1 Windows, Linux, or macOS native artifact exists locally because only
  the exact Godot 4.7.2 Web template could be installed within available disk.
- No V5.1 four-platform portable campaign exists. The latest campaign below is
  V4 and must not be used to collect or label V5.1 results.
- The exact matched V4 performance launch was denied by two permission-review
  timeouts. No matched V4 delta is claimed.
- Six-family human art/readability/control testing and a real agreed lower-end
  machine remain required. Browser automation and SwiftShader do not prove them.
- Push, remote CI, tag, GitHub Release, notarization, and storefront publication
  require separate owner approval and have not been performed.

## Current milestone

IMMUNE v0.4.0 is a playable six-mission vertical slice. The permanent 200-node
research network leads to a sequential mission desk, six playable base-cell
families, and a three-phase combat loop: Core Defense, Front-line Cleanse, and
Boss Total War. The local validation editor, project, and CI target are Godot
4.7.2 stable.

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
- six-family Fizzy visual convergence: T drops its rubber-like directional
  dimples, T/B gain the accepted bubble/microbubble/inclusion hierarchy, and the
  mission desk now presents complete close hero views at 1600x900 and 1280x720;
- Jelly V3 membrane convergence: T/B gain Compatibility-safe expanded next-pass
  membranes, all six bodies gain quiet overlapping rounded wet-skin cells and
  shallow smooth 3D microvariation, bright concentric interior rings are capped,
  T is ACES-corrected back to a saturated orange core, and the mission hero key
  is near-neutral so it no longer shifts warm families red. The final convergence
  also removes B's sparse emissive membrane-cell override and aligns M's
  production wet-coat roughness with the shared 0.030 contract;
- Jelly V4 organic membrane convergence: all six Fizzy bodies replace the V3
  isolated highlight spots with continuous, bounded rounded cells at gameplay
  distance, and the shared shader rotates the object-space sampling frame to
  remove horizontal quilting for only three dot products and no extra noise,
  texture, or bubble sample;
- a balance-neutral biological combat arena, phase-readable cleanse zone,
  styled mission/vitals/action HUD, and a Compatibility-safe A RelayDish; and
- a fail-fast 36-run headed campaign soak with telemetry v2 plus a reproducible
  Instruments Metal-trace analyzer; and
- four-platform v0.4.0 release artifacts; and
- a release identity/artifact contract with a canonical jelly-core icon,
  Windows PE metadata, macOS bundle verification, safe tag/version matching,
  generated-output import isolation, and native CI evidence; and
- a real exported-Web research-to-combat browser gate with host-default and
  4x-CPU/SwiftShader profiles, explicit local-performance versus hosted-CI
  compatibility gate modes, failure diagnostics, eight screenshots, and an
  anonymous six-family human-playtest intake contract; and
- a provenance-locked, counterbalanced offline human-playtest kit with a
  bilingual accessible form, strict PII validation, and a numeric-only campaign
  aggregator that cannot silently mix builds or duplicate participants; and
- an atomic six-participant distribution bundle sourced from the successful CI
  release artifact, with complete runtime sidecars, per-file SHA-256, exact
  allowlists, tamper verification, and no-overwrite protection; and
- a checksum-gated facilitator station that locks one participant and platform,
  checks native entry/sidecar contracts and Linux permissions, serves Web and
  the assigned form only on loopback, cannot expose native executables over
  HTTP, and travels inside the schema-v2 campaign with all five facilitator
  sources separately checksummed; and
- a historical portable Jelly V3 campaign sourced from successful Godot 4.7.2
  run `33262958960`, locking all six tester kits to code commit `2b077c5` with
  43 checksums and a verified exported-Web research-to-pause rehearsal. Current
  V4 source supersedes it, so it must not be used for new V4 reports.
- a current portable Jelly V4 campaign sourced from successful Godot 4.7.2 run
  `33264998027`, locking six tester kits to code commit `23f5bdc`, 14 artifacts,
  43 checksums, four platform preflights, and a verified exported-Web
  research-to-pause rehearsal.

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
- `godot/immune/characters/primitive_mesh_cache.gd` owns constructed-once shared
  high-density primitive meshes; authored live and portrait callers treat them
  as read-only.
- `godot/immune/characters/gel/gel_look.gd`, `gel_profiles.gd`,
  `wet_gel.gdshader`, and `jelly_shell.gdshader` own the shared opaque-core,
  Compatibility-safe membrane, spectral thickness, legacy optional bubbles,
  CC0 triplanar micro-height, and rounded wet-skin response. T/B use a next
  pass; M/N/A/D keep authored shell geometry. `light_contract.gd` owns the
  per-viewport direct/shadowed-light caps.
- `build/generate_jelly_height.py` owns the checksum-pinned, deterministic
  conversion from the licensed source height channel to the packed RGB runtime
  data texture. It must fail before writing if provenance or metrics drift.
- `tools/meshy/` owns the reviewed paid-generation gate, no-network tests, task
  metadata, GLB validation, and explicit M-slot installation.
- `tools/generate_catalog_localization.mjs` owns the deterministic 406-row
  research translation artifact and its CI drift contract.
- `tools/validate_translation_csv.mjs` owns the shared game/research CSV shape,
  duplicate, blank, placeholder-parity, and English-script checks.
- `tools/validate_release_contract.mjs` owns project/preset identity, tag/version
  coherence, credential-path rejection, and complete four-platform artifact
  structure, including Windows/Linux PCK sidecars and Web audio worklets.
- `tools/web_release_qa.mjs` owns exported-Web HTTP serving, real keyboard flow,
  ordered opt-in QA events, canvas/resource/console contracts, baseline and
  constrained-software cadence evidence, renderer-aware warning classification,
  explicit gate modes, screenshots, and failure diagnostics.
- `tools/create_human_playtest_kit.mjs` owns exact-build participant-kit
  generation, deterministic six-family order rotation, offline bilingual form,
  and overwrite refusal.
- `tools/create_human_playtest_campaign.mjs` owns successful-CI source
  provenance, exact 14-file release allowlisting, atomic artifact copying, six
  counterbalanced kits, SHA-256 inventory, distribution verification, and
  rejection of unchecksummed or path-traversing additions.
- `tools/run_human_playtest_session.mjs` owns per-session campaign revalidation,
  assigned participant/family order, exact platform entry and companions,
  Linux executable permission, and the no-store loopback facilitator station.
  It serves only the selected kit and verified Web allowlist; native
  executables are never HTTP routes.
- `tools/validate_human_playtest.mjs` owns the anonymous six-family report shape
  and PII rejection; `docs/playtesting/six-family-playtest-template.json` is its
  blank local-only contract and contains no fabricated participant results.
- `tools/aggregate_human_playtests.mjs` owns same-build/unique-participant
  enforcement and numeric-only campaign summaries. `docs/playtesting/` owns the
  facilitator instructions and machine-readable campaign plan.
- `godot/immune/build/.gdignore` prevents generated release/capture output from
  re-entering Godot's source import pipeline.
- `.github/workflows/ci.yml` owns Godot 4.7.2 import/smoke, catalog translation
  drift, release identity/tag validation, bounded T/B first/final mission
  balance, all-family MISSION-01 balance, bilingual layout, exports, artifact
  validation, exported-Web compatibility stress/evidence upload, and three
  native launch/metadata checks.

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
the `round_bubbles` wet-gel profile. T keeps its imported authored body and face
texture.
Both now share the accepted Fizzy clear-surface response and three interior
scales (round bubbles, microbubbles, and fine inclusions); T no longer uses the
directional dimple normal field that made it read as rough rubber. This local
material pass submitted no Meshy task and consumed no credit.

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

After the T/B Fizzy convergence, a fresh Compatibility pass at ten bodies and
180 frames measured T gel at 1.055 ms CPU p95 / 4.149 ms wall p95 and B gel at
0.969 ms CPU p95 / 6.426 ms wall p95. A new Forward+/Metal trace of the current B
profile measured 6.719 ms mean / 8.085 ms p95 / 13.117 ms max across 370
post-warm-up frames. Against the existing matched StandardMaterial3D baseline,
the p95 delta is +0.453 ms. Full visual, failure-analysis, and performance
evidence lives in
`docs/godot-prompter/specs/2026-08-29-six-family-fizzy-visual-convergence.md`.

Jelly V3 was remeasured with three 300-frame trials per case, ten bodies, and the
actual 1920x1080 Compatibility/OpenGL-on-Metal viewport. Median T CPU/wall p95
moved from 0.622/2.437 ms at the fresh baseline to 0.786/2.885 ms; B's main V3
pass, before the final constant-only parameter convergence, moved from
0.663/2.579 ms to 0.696/2.827 ms. A matched T membrane-off ablation measured
0.742/2.594 ms, attributing 0.291 ms wall p95 to the clear second pass. The pass
is retained for its visibly cleaner, less-washed boundary; this is a measured
quality/cost decision, not a no-regression claim. The Compatibility GPU timer
again returned zero, so no GPU number is inferred. Final B constants were then
checked in an interleaved same-window A/B and measured 4.297 ms wall p95 versus
4.688 ms for the former overrides; cross-window absolute cadence is not compared.
Full failures, visual probes, RED/GREEN contracts, and evidence are in
`docs/godot-prompter/specs/2026-08-30-jelly-membrane-v3.md`.

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

- Jelly V4 local release gate (2026-08-30): reference/V3 audit, three stopped
  probe rounds, a witnessed RED smoke contract, and GREEN six-family production
  profiles. Six six-angle close-up sets, six mission cards, and 18 gameplay
  frames were regenerated; contact-sheet review found continuous wet cells with
  no horizontal quilt, moire, broken face, colour shift, or distant readability
  regression. A three-trial ten-body interleaved V3/V4 comparison measured V4
  at 1.021 ms CPU mean / 1.225 ms CPU p95 and 2.270 ms wall mean / 4.477 ms wall
  p95: +4.3%/+4.2% CPU and +0.7%/+1.7% wall versus the old constants. Root tools
  pass 36/36, Web UI 53/53 plus build, Meshy 6/6, translation/catalog checks,
  two imports, smoke, overflow, all-family M1 6/6, T/B first/final 4/4, four
  sequential exports, artifact contract, universal macOS native smoke, and
  exported-Web compatibility QA all pass locally. Full rationale and claim
  boundaries are in
  `docs/godot-prompter/specs/2026-08-30-jelly-membrane-v4.md`.
- Jelly V4 remote and campaign gate (2026-08-30): GitHub Actions run
  `33264998027` verifies commit
  `23f5bdc82c7f9eae0311d6959e532ed06da0b167`; main Godot 4.7.2
  validation/export passed in 10m34s and Windows/macOS/Ubuntu native artifacts
  passed in 18s/21s/17s. The exact artifact was packaged as
  `immune-v0.4.0-23f5bdc-run-33264998027-jelly-v4-portable-v1`. Repository and
  bundled verifiers, all 43 independent checksums, and four platform preflights
  pass. The copied Web build completed the full browser flow at 120.003/109.890
  mean/p05 FPS on Metal and 13.165/11.962 on 4x-CPU SwiftShader; eight screenshots
  passed visual review. This is distribution evidence, not a human result. Full
  provenance is in
  `docs/godot-prompter/specs/2026-08-30-jelly-v4-human-playtest-campaign.md`.

- Verified facilitator station (2026-08-29): four new tests cover exact
  Web/Windows/Linux/macOS entry contracts, unknown participant/platform,
  checksum tampering, lost Linux execute permissions, path traversal, loopback
  Web serving, assigned-form isolation, and the native no-executable HTTP
  boundary. Three more campaign tests cover portable spawned CLI execution,
  legacy schema-v1 readability, and bundled-runner tampering/symlinks; the full root
  suite passes 36/36. The schema-v2 portable `81a3cbe` campaign contains 14
  artifacts, 24 kit files, and 5 facilitator files; its bundled verifier and
  independent `shasum` both pass all 43 entries. The bundle's own runner passed
  all four `--preflight-only` modes. A real tester-01 Web station served the
  assigned form and 39,514,754-byte WASM with HTTP 200 and the correct
  MIME/security headers; Chrome at 1280x720 proved full provenance, zero
  station/game console or page errors, an unclipped no-scroll canvas, and
  ordered `engine_ready` / `research_ready`. Visual review passed for both the
  station and research screen. Two rehearsal findings became regressions: Web
  `launch=` now points to `index.html` rather than the apple-touch icon, and an
  inline station favicon prevents Chrome's implicit 404. A portability audit
  also found `/var` versus `/private/var` could silently skip CLI `main()`;
  realpath-aware detection and explicit bundled-command stdout assertions now
  cover it. The copied campaign needs Node.js but no repo checkout or npm
  install. This remains session integrity evidence, not a human result. Full
  evidence is in
  `docs/godot-prompter/specs/2026-08-29-verified-facilitator-station.md`.
  Functional commit `ebf5b9c` passed GitHub Actions run `33259930365`: main
  validation/export in 11m22s and native Linux/Windows/macOS artifact launch in
  11s/15s/49s. The downloaded schema-v2 hosted-Web report completed eight
  ordered events and four HTTP-200 resources per profile with exact canvas fit,
  no scroll, and zero console/page/effective-request errors. All eight
  screenshots were visually reviewed without blank output, clipping, or state
  displacement. Hosted SwiftShader reported 1.220/1.200 mean/p05 FPS and an
  833.4 ms maximum frame at baseline, then 1.395/1.364 and 733.3 ms under 4x CPU
  throttling. This remains compatibility-only liveness evidence, not a real
  low-end hardware benchmark. The downloaded report SHA-256 is
  `350172f65421c7e5836d4e9b0cb0109682994888dc79e6b57108d103490181ba`.
- Provenance-locked playtest distribution (2026-08-29): the successful
  `81a3cbe` artifact from run `33257048004` was downloaded and passed the
  strengthened release contract with exactly 14 allowlisted files. An atomic
  six-participant campaign was generated with 38 valid `SHA256SUMS` entries and
  artifact-set digest
  `9ce6eac3db3da6dc4ffd81c23eb1af59d59906dab2860560df1a5de419da9f8c`;
  Linux executable permissions survived the copy and an intentional second
  create exited 1 without overwrite. Campaign/tamper tests pass 5/5 and the full
  root suite passes 30/30. The real tester-01 form passed a 390x844 Chrome audit
  with the full commit, TBMNAD order, no overflow/unlabelled fields, one
  same-origin request, and no console errors. The copied Web artifact passed the
  complete local flow at 119.753 / 103.093 mean/p05 FPS on Metal and 15.219 /
  13.624 under 4x CPU plus SwiftShader. A QA-output contamination found during
  review was moved outside the bundle; exact-root tests now reject any future
  unchecksummed debug/private file. Full evidence is in
  `docs/godot-prompter/specs/2026-08-29-playtest-distribution-bundle.md`.
  Functional commit `dd8a960` then passed GitHub Actions run `33258313619`:
  main validation/export in 11m35s and Linux/Windows/macOS native smoke in
  14s/19s/22s. Its downloaded hosted-Web report is schema v2 and explicitly
  compatibility-only; SwiftShader baseline measured 1.210/1.132 mean/p05 FPS
  with 883.3ms maximum frame, while the 4x-CPU profile measured 1.385/1.333 with
  750ms maximum. Both profiles completed eight ordered events and four required
  HTTP-200 resources with zero console/page/effective-request errors. All eight
  screenshots were visually reviewed and retained the expected research,
  mission-selection jelly preview, combat, and pause states without clipping or
  blank output. These figures are not a real low-end hardware benchmark.
- Offline human-playtest campaign kit (2026-08-29): 25/25 root tool tests pass,
  including deterministic/counterbalanced kit generation, overwrite refusal,
  free-text email and identity-field rejection, aggregate privacy, mixed-build
  and duplicate-participant failure, plus spawned CLI coverage. The blank
  template validates; a real generated kit was inspected in desktop dark,
  desktop light, and 390x844 mobile. Mobile programmatic audit found one H1,
  zero horizontal overflow, zero unlabeled fields, zero undersized ordinary
  controls, zero external requests, and zero console errors. Empty completed
  export was blocked; synthetic draft/complete downloads and a one-report
  insufficient-sample aggregate were validated without treating them as human
  evidence. The unchanged exported Godot Web artifact then passed the strict
  local flow at 120.006 / 101.010 mean/p05 FPS on Metal and 15.093 / 13.387
  under 4x CPU plus SwiftShader.
  GitHub Actions run `33257048004` verifies commit `81a3cbe`: the 11m39s main
  job and Linux 9s, Windows 21s, and macOS 45s native artifact launches all
  pass. Its downloaded compatibility-only report records hosted SwiftShader at
  1.158 / 1.324 mean FPS, 900 / 766.8 ms maximum frames, all eight events and
  four resource 200s per profile, no effective errors, and eight visually
  reviewed screenshots. This remains liveness evidence, not a hardware
  benchmark. Full workflow, privacy boundary, and failure corrections are in
  `docs/godot-prompter/specs/2026-08-29-human-playtest-campaign-kit.md`.
- Exported-Web compatibility stress and playtest intake (2026-08-29): 15/15
  local tool tests, anonymous six-family template validation, fresh Web export,
  and real Chrome research → mission desk → B/MISSION-01 → mobile duty → pause
  flow pass at 1600x900 baseline and 1280x720 4x-CPU/SwiftShader. Baseline
  measured 120.000 mean / 111.111 p05 FPS; constrained software measured 14.460
  mean / 13.210 p05 FPS with zero frames above 250 ms. Both produced all eight
  ordered events, exact canvas fit, four resource 200s, no effective request,
  page, or console errors, and four visually reviewed screenshots. The raw
  constrained 50 ms long-frame ratio remains reported at 100%; the evidence is
  explicitly compatibility stress, not a lower-end hardware benchmark. Failure
  phase logs, JSON/PNG snapshots, benign superseded preload cancellation
  classification, and a consistent 250 ms constrained-stall gate were added
  after two diagnosed RED runs. Full evidence and claim boundary are in
  `docs/godot-prompter/specs/2026-08-29-constrained-web-and-human-playtest.md`.
- Renderer-aware Web gate correction (2026-08-29): remote run `33254857282`
  proved that GitHub Ubuntu supplied SwiftShader for both the unforced baseline
  and forced-software profiles. The complete browser loop, resources, fit, and
  eight screenshots passed, but 1.220 / 1.385 mean FPS correctly could not meet
  the local hardware-backed sentinel. Report schema v2 now makes the contract
  explicit: local runs retain the original strict FPS/long-frame gates, while
  CI uses `compatibility-only` with all functional/error contracts and a
  two-second maximum-frame watchdog. The uploaded report passes the latter and
  still fails the former; frames above one second are no longer filtered out.
  Fresh local strict and CI-mode browser runs pass at 119.998 / 14.751 and
  120.051 / 14.706 mean FPS respectively. GitHub Actions run `33255697919`
  verifies commit `5021665`: `validate-and-export` and Linux, Windows, and macOS
  native release-smoke jobs all pass. Its downloaded schema-v2 report records
  `compatibility-only`, all eight ordered events, four resource 200s, exact fit,
  no effective errors, and eight visually reviewed screenshots. Hosted
  SwiftShader measured 1.154 / 1.319 mean FPS with 916.6 / 783.4 ms maximum
  frames, safely below the explicit two-second liveness watchdog; all raw slow
  cadence ratios remain reported and no hardware-performance claim is made.
- Release identity hardening (2026-08-29): contract tests went RED on the absent
  icon/Windows metadata and GREEN after the project/preset update; actionlint,
  four fresh exports, and the complete artifact contract pass. Windows PE
  inspection proves six icon resources plus matching product/company/description
  and 0.4.0 version data. macOS strict deep signature, bundle/version/icon,
  arm64+x86_64, and exported 200-node smoke pass. Web generates 1024 and 180 px
  alpha icons, and `.gdignore` leaves no release `.import` sidecars. Full evidence
  is in `docs/godot-prompter/specs/2026-08-29-release-identity-hardening.md`.
  GitHub Actions run `33253080682` verifies commit `a7db3bd` on Godot 4.7.2:
  `validate-and-export` plus Linux, Windows, and macOS native artifact jobs all
  pass, including the new Windows VersionInfo and macOS bundle/icon checks.
- Six-family Fizzy convergence (2026-08-29): fresh six-angle baseline review,
  RED-to-GREEN profile/runtime contracts, final complete mission-desk framing at
  1600x900 and 1280x720, T/B Compatibility comparisons, and a current B
  Forward+/Metal trace pass. The two rejected framing attempts are preserved as
  generated evidence; no Meshy request or credit was used.
- Current Fizzy release gate (2026-08-29): 53/53 Web tests and build, translation
  2 files / 595 rows, Meshy 6/6 no-network tests, two Godot imports, smoke,
  bilingual overflow, T/B first/final four-run balance, six-family MISSION-01,
  four platform exports, strict ad-hoc hardened-runtime macOS signature, and the
  exported universal macOS release smoke all pass locally.
- Jelly V3 release gate (2026-08-30): fresh six-family baseline, four rejected
  visual candidates plus controlled colour/texture/membrane sweeps, RED/GREEN
  material and neutral-preview-light contracts, six final close-up sets, both
  locales at 1280x720 mission selection, and 36 bilingual combat frames pass
  visual inspection. Capture teardown reproduced an intermittent three-resource
  exit warning, added a bounded render drain, then passed two mission plus two
  A-combat replay batches with no leak/error. Root tools pass 36/36; Web UI
  53/53 plus build; Meshy 6/6; two imports, smoke, bilingual overflow, T/B 4/4,
  all-family 6/6, four sequential exports, artifact validation, universal macOS
  native smoke, and exported-Web Metal/SwiftShader QA all pass locally.
- Jelly V3 final-parameter evidence (2026-08-30): B/M six-angle close-ups,
  1600x900 English and bilingual 1280x720 mission desks, and both B/M combat
  locales were regenerated after removing B's sparse emissive override and
  aligning M's coat. An interleaved three-trial ten-body B comparison found the
  final constants no slower than the former overrides (median wall p95 4.297 ms
  versus 4.688 ms in the same noisy host window); cross-window absolute cadence
  is not treated as an optimization claim.
- Jelly V3 remote gate (2026-08-30): GitHub Actions run `33262958960` verified
  code commit `2b077c57c82881cca2d33cb6c07abed4b944776a` on Godot 4.7.2. The main
  validation/export job and independent Linux, Windows, and macOS native artifact
  jobs all completed successfully. The follow-up handoff-only commit uses
  `[skip ci]` to record that terminal result without recursively launching the
  same full pipeline.
- Jelly V3 human-playtest campaign (2026-08-30): the exact successful artifact
  from run `33262958960` passed the 14-file release contract and was packaged as
  `immune-v0.4.0-2b077c5-run-33262958960-jelly-v3-portable-v1`. Its artifact-set
  SHA-256 is
  `82b37917f97bcdbd58675561026958e5d97874af411a413457a9665e3e80a05d`;
  both repository and bundled verifiers pass six participants / 14 artifacts,
  all 43 checksums are covered, and Web/Windows/Linux/macOS preflights pass. A
  real loopback Chromium rehearsal at 1280x720 completed the exported research,
  mission selection, family selection, combat, duty-change, and pause sequence
  with exact canvas fit, isolation, required HTTP-200 resources, and no effective
  request failure. The initial checker incorrectly rejected known PCK/WASM
  cancellations after successful 200 responses; it was stopped, diagnosed, and
  rerun with the checked-in strict classifier. This is campaign-integrity
  evidence only: no participant report or human-quality claim was created. Full
  evidence is in
  `docs/godot-prompter/specs/2026-08-30-jelly-v3-human-playtest-campaign.md`.
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
- `outputs/release-hardening-20260829/`
- `outputs/web-release-qa-final-20260829/`
- `outputs/human-playtest-kits/`
- `outputs/human-playtest-campaigns/immune-v0.4.0-81a3cbe-run-33257048004/`
- `outputs/human-playtest-campaigns/immune-v0.4.0-81a3cbe-run-33257048004-portable-v4/`
- `outputs/release-ci-33257048004/`
- `outputs/playtest-campaign-web-qa-81a3cbe/`
- `outputs/ci-web-release-qa-downloaded-33258313619/`
- `outputs/playtest-session-station-qa/`
- `outputs/web-release-qa-ci-run-33259930365/`
- `outputs/jelly-v3-lookdev/`
- `outputs/jelly-v4-lookdev/`
- `outputs/human-playtest-campaigns/immune-v0.4.0-23f5bdc-run-33264998027-jelly-v4-portable-v1/`
- `outputs/jelly-v4-playtest-campaign-qa/`
- `outputs/release-ci-33262958960-jelly-v3/`
- `outputs/human-playtest-campaigns/immune-v0.4.0-2b077c5-run-33262958960-jelly-v3-portable-v1/`
- `outputs/jelly-v3-playtest-campaign-qa/`
- `outputs/playtests/human/`

## Repeatable release commands

```sh
cd ui/immune-research-network
npm test
npm run build

cd ../../
npm ci --ignore-scripts
npm run test:tools
npm run validate:playtest-template
gh run download 33264998027 \
  -n immune-demo-23f5bdc82c7f9eae0311d6959e532ed06da0b167 \
  -D outputs/release-ci-33264998027-jelly-v4
npm run create:playtest-campaign -- \
  --artifacts=outputs/release-ci-33264998027-jelly-v4 \
  --build-commit=23f5bdc82c7f9eae0311d6959e532ed06da0b167 \
  --source-run=33264998027 \
  --source-artifact=immune-demo-23f5bdc82c7f9eae0311d6959e532ed06da0b167 \
  --out=outputs/human-playtest-campaigns/immune-v0.4.0-23f5bdc-run-33264998027-jelly-v4-portable-v1
npm run create:playtest-campaign -- \
  --verify=outputs/human-playtest-campaigns/immune-v0.4.0-23f5bdc-run-33264998027-jelly-v4-portable-v1
cd outputs/human-playtest-campaigns/immune-v0.4.0-23f5bdc-run-33264998027-jelly-v4-portable-v1
node facilitator/run_human_playtest_session.mjs --campaign=. \
  --participant=tester-01 --platform=web --open
cd ../../..
npm run aggregate:playtests -- \
  --dir=outputs/playtests/human/raw/23f5bdc \
  --out=outputs/playtests/human/aggregate-23f5bdc.json \
  --minimum-participants=3 --require-minimum
node tools/validate_release_contract.mjs
node tools/generate_catalog_localization.mjs --check
node tools/validate_translation_csv.mjs
godot --headless --path godot/immune --import
godot --headless --path godot/immune --import
smoke_dir="$(mktemp -d)"
godot --headless --path godot/immune --script res://tools/smoke.gd -- \
  --save-path="$smoke_dir/state.json"
godot --headless --path godot/immune --script res://tools/check_overflow.gd
godot --headless --path godot/immune --script res://tools/balance_matrix.gd -- \
  --out=user://six-family-mission-01.json --missions=MISSION-01 \
  --families=T,B,M,N,A,D --trials=1
godot --headless --path godot/immune --script res://tools/balance_matrix.gd -- \
  --out=outputs/playtests/campaign-expansion-candidate-1.json --trials=1
godot --path godot/immune --rendering-method gl_compatibility \
  --script res://tools/balance_matrix.gd -- \
  --soak --out=outputs/playtests/all-family-campaign-soak.json
godot --headless --path godot/immune --export-release "Windows Desktop" build/releases/IMMUNE-windows.exe
godot --headless --path godot/immune --export-release "Linux/X11" build/releases/IMMUNE-linux.x86_64
godot --headless --path godot/immune --export-release "macOS" build/releases/IMMUNE-macOS.zip
godot --headless --path godot/immune --export-release "Web" build/releases/web/index.html
node tools/validate_release_contract.mjs --artifacts=godot/immune/build/releases
npm run test:web-release -- \
  --artifacts=godot/immune/build/releases/web \
  --out=outputs/web-release-qa --duration-ms=6000
npm run test:web-release -- \
  --artifacts=godot/immune/build/releases/web \
  --out=outputs/ci-web-release-qa --duration-ms=4000 \
  --gate-mode=compatibility-only
```

Run exports sequentially. Parallel Godot exporters race on the shared
`tmpproject.binary` file.

## Honest status and next development tranche

The six-mission vertical slice, all six base-cell playable bodies, V5.1 jelly
surface, portrait lifecycle, 720x1280 HUD target, local smoke/capture gates, and
fresh exported-Web browser gate are complete. It is not a content-complete
commercial release. Remaining work is:

1. Keep the N/A/D Meshy manifests as optional comparisons only. Any paid task
   still needs a separate exact 5-credit approval; never batch paid retries after
   a failed task. V5.1 made no Meshy call and the playable demo does not depend on
   further generation.
2. Push the owner-approved V5.1 commit and let checked-in Godot 4.7.2 CI produce
   Windows, Linux, macOS, and Web artifacts. Local V5.1 has only the exact 4.7.2
   Web template, so the older V4 native artifacts cannot be relabelled or mixed.
3. Only after that remote artifact is green, create a new checksum-locked V5.1
   portable campaign. The existing `23f5bdc` campaign is V4 historical evidence,
   not a V5.1 distribution.
4. Run real six-family human playtesting for the final material direction,
   fun/readability/accessibility/control feel, then repeat on an agreed lower-end
   Windows/Web machine. SwiftShader and deterministic capture evidence do not
   prove either human judgement or real-hardware performance.
5. If exact V4/V5 cost comparison is required, approve launching the
   checksum-identified V4 worktree and run the same 10-body/300-frame harness.
   The current standard-material sentinel is green but is not a historical V4
   measurement.
6. Add a stacked 360/390 px phone layout and display safe-area insets before
   claiming narrow-phone/notch support. The current portrait and HUD lock covers
   landscape plus 720x1280.
7. Add a Developer ID Application identity, notarization credentials, privacy /
   storefront metadata, and store-specific packaging before public distribution.
8. A future push/tag/release remains an explicit owner-approved publishing
   action. Run `node tools/validate_release_contract.mjs --tag=v0.4.0` first; no
   push, tag, GitHub Release, upload, notarization, or storefront submission was
   performed in the V5.1 local tranche.

These are explicit external/product gates, not hidden broken demo work.
