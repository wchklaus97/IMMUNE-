# IMMUNE V5.3 gameplay, jelly, and Steam-readiness plan

Date: 2026-09-01
Status: repository implementation complete; owner/Steamworks/Valve gates pending

Skills applied: Godot brainstorming, shader basics, input handling, Godot UI,
responsive UI, component system, resource pattern, state machine, HUD system,
Godot testing, and export pipeline.

## Outcome

Turn the current six-mission vertical slice into a stronger publish candidate by
closing the repository-controlled gaps the latest audit found:

1. give the player one deliberate, cooldown-based active ability per family;
2. make missions produce authored encounter events instead of differing only by
   enemy stats and traits;
3. keep all four combat actions usable at desktop, gamepad, and narrow-phone
   sizes, with a compact two-by-two phone tray and touch movement controls;
4. make the six cell bodies read as brighter, soft-volume wet jelly while
   retaining the bounded Compatibility shader and three-directional-light
   contract;
5. correct stale mission copy and localize every new player-facing string;
6. produce deterministic four-platform release artifacts plus a Steam staging
   manifest, upload-script templates, store-copy draft, asset inventory, and a
   fail-closed readiness report.

The deliverable is **Steam ready-to-submit**, not a false claim that Valve has
approved or released the game. Steamworks credentials, App ID/depot IDs,
Developer ID signing/notarization credentials, public Coming Soon timing,
Valve review, and real human/device evidence remain owner/external gates.

## Architecture

### Player agency

- `FamilyActiveSkillProfile` is a read-only typed Resource referenced by each
  `FamilyCombatProfile`.
- `ActiveSkillController` is a focused Node component that owns cooldown state
  and emits activation/cooldown signals. It does not query scene siblings.
- `CombatLane` resolves the signalled profile against enemies owned by that
  mission and drives the existing hit/VFX/telemetry paths.
- The six skills share one data-driven resolver but differ by targeting,
  radius, damage, mark/execute behavior, target cap, and optional core repair.

### Mission identity

- `ImmuneMissionData` owns neutral-default encounter pattern, interval,
  strength, and player-facing event copy.
- `EncounterDirector` is a focused Node component that advances a deterministic
  timer only during live combat phases and emits authored events.
- Runtime patterns are `steady`, `surge`, `cytokine`, `adaptive`, `biofilm`, and
  `systemic`. Existing pathogen traits stay intact; the director layers visible
  pacing events over them without adding mission-specific scene scripts.

### Touch and responsive HUD

- Desktop/tall HUD becomes four actions: Ability, Duty, Intel, Mission Desk.
- Narrow phone becomes a two-column/two-row action tray rather than a tall
  one-column stack. Every action remains at least 44 physical pixels high.
- `CombatTouchControls` is a reusable Control component with four directional
  buttons. It emits a normalized movement vector and never writes to InputMap.
  It is shown for narrow-phone layouts or a real touchscreen and is ignored in
  fixed duty.
- Keyboard/gamepad continue to use InputMap. `demo_active_skill` gets keyboard
  and gamepad bindings and appears in prompt text through `SettingsState`.

### Jelly V5.3

- Keep the existing opaque-core wet-gel shader, shell shader, authored meshes,
  light-class restriction, and clipping probe.
- Tune only bounded surface/profile values: body exposure, thin-volume
  contrast, transmission, coat response, shell alpha, and authored-height
  depth. Add at most one unshadowed directional fill so the production rig
  remains one shadowed key plus two unshadowed fills.
- Accept parameters only after the zero/one/three-light probe, runtime smoke,
  deterministic screenshot comparison, and exported-Web visual check pass.

### Steam packaging

- Preserve Steamworks SDK and credentials outside the public repository.
- Generate platform staging directories and placeholder-based VDF templates;
  a preflight tool must reject placeholders, missing artifacts, unexpected
  files, and secret-bearing values before any upload command can be printed.
- Store metadata and graphical-asset inventory follow current Steamworks rules:
  base capsules contain only artwork/logo, screenshots are real gameplay, and
  the required current dimensions are recorded in the readiness report.
- No upload, branch promotion, pricing change, tag, or public release occurs
  without explicit owner credentials and authorization.

## Test-first sequence

1. Add RED smoke contracts for the active-skill Resource/component, six family
   profiles, input binding, encounter data/director, four-action HUD, two-column
   phone contract, touch controls, telemetry, and corrected M03 copy.
2. Add RED Node tests for Steam staging/preflight using temporary fixture
   artifacts and placeholder rejection.
3. Implement the new Resources/components and wire CombatLane.
4. Tune six mission and six family resources; update translations and copy.
5. Tune V5.3 profile/lighting within the existing energy and light-count gates.
6. Run two imports, isolated smoke, overflow/responsive matrix, tool tests,
   research UI tests/build, translation checks, balance matrix, jelly probe,
   four exports, artifact validation, native launch smoke where available, and
   exported-Web baseline/constrained QA.
7. Inspect desktop and phone captures. If the jelly or controls regress, stop,
   diagnose the failed metric/capture, change the smallest responsible layer,
   and rerun from its nearest RED gate.

## Completion gates

Repository-controlled completion requires all of the following:

- six active abilities trigger, cool down, damage valid targets, and expose
  accessible localized HUD feedback;
- all six missions declare a valid encounter pattern and every non-tutorial
  mission produces a distinct event in deterministic smoke coverage;
- desktop action tray is four columns, narrow phone is two columns, touch
  movement is present, critical controls stay inside safe area, and minimum
  physical target/copy sizes pass;
- V5.3 probe has no hot-pixel/clip regression and visual captures remain
  readable in zh_HK and English;
- campaign balance finishes without timeout or invariant failure;
- release artifacts and Steam staging preflight pass with no credentials;
- documentation reports external gates as pending instead of converting them
  into unsupported success claims.

## Completion evidence

- Six family skills and six encounter patterns pass the Godot 4.7.2 smoke
  contract. The balance harness now rejects every non-1x `--time-scale`
  request because accelerated Godot physics changed projectile and autopilot
  outcomes during the first attempted matrix.
- The corrected real-time matrix passes 36/36 mission/family runs. Every run
  wins, defeats one boss, fires and hits real projectiles, uses and hits with an
  active skill, completes its mobile/relay duty round trip, leaves the core
  alive, and preserves a strictly increasing six-mission duration ladder.
- M06 systemic reinforcements are tracked separately from objective kills, so
  encounter waves add pressure without shortening the objective. Final M06
  runs take 79.817–91.950 seconds and leave 8–12/12 core HP.
- 390x844 and 360x800 safe-area combat, mission, research, and Pause evidence
  passes in English and Traditional Chinese. Four combat actions remain inside
  the safe rectangle; touch and action targets remain at least 44 physical px.
- Jelly V5.3 zero/one/two/three-light evidence stays bounded. The accepted
  three-light candidate has 0.309 median luminance and 1.17% clipped pixels;
  the 10-character 1920x1080 gel CPU mean is 0.910 ms, equal to the standard
  material control in the same harness. Godot's compatibility Metal GPU timer
  is unavailable, so no unsupported GPU number is claimed.
- Root release/tool tests pass 45/45, Web research tests pass 53/53, Meshy
  workflow tests pass 6/6, catalog localization passes 200 nodes/406 rows,
  translation validation passes 623 rows, and all 17 Steam graphical assets
  pass exact-size/format/transparency validation.
- Official Godot 4.7.2 (`ed1daf0bf`) completes two imports, isolated smoke, and
  all four release exports. The artifact contract, local universal macOS
  release smoke, exported-Web baseline/constrained browser flow, and a
  no-upload three-depot Steam staging rehearsal all pass. Exact checksums and
  platform limitations are recorded in `steam/build-candidate-v0.4.0.md`.
