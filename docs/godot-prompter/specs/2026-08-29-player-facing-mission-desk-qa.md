# Player-facing mission desk and localization QA

Date: 2026-08-29

## Outcome

The exported demo now presents the six cell families inside a dedicated 3D
preview frame on the mission desk. The preview can no longer overlap mission
copy or action controls, and each family has an independently reviewed scale so
the complete jelly silhouette remains visible at both 1600x900 and 1280x720.

The same review completed the English editorial pass for the 200-node research
catalog and added a structural CSV validator to CI. Both translation tables now
fail early on malformed column counts, duplicate or blank keys, placeholder
mismatches, or Han text in the English column.

## Defects found and corrected

The first exported-Web review exposed four player-facing defects:

1. The mission preview was rendered in the root 3D world and could overlap the
   mission title, briefing, family text, and buttons.
2. Locked-mission emoji rendered as missing-glyph boxes on the bundled font.
3. The mission subtitle described the internal wet-gel and duty-animation
   pipeline instead of helping the player choose a team.
4. One unquoted English comma split the subtitle into four CSV columns and
   truncated it to `Choose a mission` at runtime.

The preview now uses an owned `SubViewport` with its own world, environment,
lights, and camera inside a styled `PanelContainer`. Mission/family controls use
visible pressed states and higher-contrast theme overrides. Localized text badges
replace emoji, the subtitle is player-facing, and the new CSV validator prevents
the comma regression from returning.

The first headed screenshot retry also reported `ObjectDB instances leaked` and
two resources still active on exit. Generation stopped at that point. The cause
was quitting one frame after freeing a live, always-updating `SubViewport`.
Cleanup now disables viewport updates, releases the preview, waits through the
render queue, and forces synchronization before exit. Both locale runs now exit
without script, engine, ObjectDB, or resource-leak errors. QA images are emitted
under the repository-level ignored `outputs/` directory so they no longer enter
Godot's asset-import scan.

## English catalog editorial pass

All 406 generated research rows were regenerated from the canonical 200-node
catalog. Shared prose was rewritten to remove internal or awkward language:

- raw family codes in fusion descriptions now use full family names;
- three-family lists use readable English conjunctions;
- `physical fusion` is now `fusion form for deployment`;
- `family's ultimate permanent research` is now a player-facing research-line
  completion description;
- `Antibody-free Awakening` is now `Antibody-independent Awakening`; and
- base research descriptions no longer expose `combat AI behavior` terminology.

The generator contains rejection guards for retired raw-code and internal
phrasing in addition to the existing 200-node, 406-row, non-empty, duplicate,
and Han-character contracts.

## Visual and interaction evidence

Headed Godot capture covered both locales and all families:

- 12 mission-desk images at 1600x900;
- six English mission-desk images at 1280x720;
- 18 English gameplay images covering fixed, mobile/relay, and boss states;
- no family accessory residue during rapid family replacement; and
- complete silhouettes with the accepted Fizzy jelly material visible in the
  preview frame.

The final Web export was then exercised in Chromium using real keyboard events:

1. research network;
2. `C` to open the mission desk;
3. `E` to cycle through families and select Antibody Construct;
4. `Enter` to start MISSION-01;
5. `Space` to change fixed duty to Relay duty; and
6. `Escape` to open Pause / Settings.

The canvas fit 1600x900 and 1280x720. The browser console reported zero errors
and zero warnings. Local ignored evidence is under
`outputs/player-qa-20260829/`.

## Regression results

- translation validator: 2 files / 595 rows;
- research generator: 200 nodes / 406 rows, write and drift-check modes;
- Godot smoke: six missions, six families, bilingual catalog and mission desk;
- research overflow: `zh_HK` and `en` at 1920x1080;
- Web tests: 53/53, followed by a production build;
- MISSION-01 real-time matrix: 6/6 family victories, every Core 12/12;
- T/B MISSION-01 + MISSION-06 sentinel: 4/4 victories, every Core 12/12;
- headed mission/gameplay generation: clean exit and no engine errors; and
- Web release export and Chromium flow: clean console.

The accepted balance timings remain unchanged: MISSION-01 T/B/M/N/A/D complete
in 21.833/20.033/20.833/20.533/22.400/20.200 seconds. MISSION-06 T and B
complete in 89.750 and 81.283 seconds.

## Remaining product gates

This pass does not claim store readiness. Developer ID signing/notarization,
storefront metadata, non-zero GPU timing on a backend that exposes it, and
longer unscripted human sessions remain external or product-validation gates.
Optional N/A/D Meshy comparisons remain separate five-credit approval-gated
tasks; the playable demo does not depend on them.
