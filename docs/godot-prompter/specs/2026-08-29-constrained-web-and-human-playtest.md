# Exported-Web compatibility stress and six-family human playtest contract

Date: 2026-08-29

## Scope and claim boundary

This tranche closes the repeatable exported-Web compatibility gap without
pretending that one development Mac is representative lower-end hardware. The
browser evidence is deliberately labelled
`compatibility-stress-not-hardware-benchmark`. It proves that the shipped HTML,
JavaScript, PCK, and WASM load; a real browser can drive the playable loop; and
the loop retains a bounded frame heartbeat under an artificial stress profile.
The host-default profile does not imply a hardware GPU: hosted CI may choose
SwiftShader even when the runner does not explicitly force a software renderer.

It does not prove subjective fun, readability, accessibility, control feel, or
performance on a particular Windows laptop, integrated GPU, mobile browser, or
assistive-input setup. Those remain human/hardware gates.

## Automated browser contract

`tools/web_release_qa.mjs` serves the already-exported release artifact and uses
Playwright against installed Chrome. The runner performs real canvas focus and
keyboard input through this sequence:

1. research network ready;
2. `C` opens mission selection;
3. `E` selects B;
4. `Enter` starts B / MISSION-01 and confirms onboarding;
5. `Space` changes fixed duty to mobile;
6. `W+D` remains held during the frame sample;
7. `Escape` opens and closes pause/settings.

An opt-in Web-only autoload publishes ordered, JSON-safe state events when the
URL includes `?web_qa=1`. The bridge is inert in native builds and ordinary Web
play. The runner also requires HTTP 200 for the four release resources, a WebGL
context, exact canvas fit without document scroll, no console/page/effective
request errors, four screenshots per profile, and the expected eight events.

Profiles:

- `baseline`: 1600x900, host-default renderer, no CPU throttling;
- `constrained-software`: 1280x720, 4x DevTools CPU throttling, forced
  SwiftShader with renderer proof.

Report schema v2 records one of two explicit gate modes:

- `local-performance-sentinel` is the default. Baseline requires at least 60
  samples, 20 mean / 10 p05 FPS, and no more than 25% frames above 50 ms.
  Constrained software requires at least 30 samples, 5 mean / 2 p05 FPS, and no
  more than 10% frames above 250 ms.
- `compatibility-only` is used by hosted CI because its host-default renderer is
  not guaranteed to expose a hardware GPU. It still requires all resources,
  events, screenshots, WebGL, fit, and error contracts, plus at least three
  samples spanning two seconds, 0.5 mean / 0.4 p05 FPS, and no individual frame
  above the two-second watchdog. It makes no smoothness or hardware-performance
  claim.

Both modes preserve all measured 50 ms and 250 ms counts and ratios. Frame
intervals above one second are no longer discarded. The only permitted browser
warning is Chromium's exact `GPU stall due to ReadPixels` diagnostic when the
reported renderer is independently identified as software; any other warning
fails both modes.

## Failure analysis and workflow corrections

The first browser run displayed the complete research network but timed out
waiting for `engine_ready`. Failure JSON and a screenshot proved that all four
resources returned 200 and the canvas rendered while the bridge was `null`.
The opt-in check was therefore moved from an `eval()` return conversion to the
official `JavaScriptBridge.get_interface("window")` path and direct query
parsing.

The runner now prints each phase and, on failure, preserves the active URL,
document state, canvas geometry, bridge snapshot, browser messages, resource
statuses, stack, and screenshot. This turns future timeouts into bounded,
actionable evidence.

Godot/Chromium may cancel an initial PCK or WASM preload after a later request
has succeeded. The raw `net::ERR_ABORTED` record is retained as a cancellation,
but is not classified as an effective failure when the same required resource
has a final HTTP 200. A unit test locks that distinction.

The first constrained run then exposed a contradictory contract: a 5 FPS floor
allowed 200 ms frames while a 50 ms long-frame ratio still failed them. The
contract was corrected to retain/report long frames and gate constrained stalls
above 250 ms. No measured data is suppressed.

The first remote run (`33254857282`) exposed a second environment/claim defect.
GitHub's Ubuntu host-default profile and the explicitly constrained profile both
reported ANGLE Vulkan SwiftShader. They completed the entire interaction flow,
returned all required resources with HTTP 200, fit both canvases, and produced
all eight valid screenshots, but the four-second samples ran at only 1.220 and
1.385 mean FPS. Applying the hardware-backed local thresholds to that
virtualized software renderer incorrectly failed otherwise complete
compatibility evidence.

The workflow was stopped and the uploaded failure artifact was inspected before
changing code. The correction is an explicit CLI gate mode, not automatic
environment detection or silently lowered thresholds. The downloaded report
passes `compatibility-only` and still fails `local-performance-sentinel`; RED
tests lock both outcomes. The 0.87-second worst remote frame remains visible in
the report and below the two-second liveness watchdog.

## Local evidence

The final renderer-aware six-second local sentinel produced eight visually
reviewed screenshots and this result:

| Profile | Renderer | Mean FPS | p05 FPS | p95 frame | >250 ms stalls |
| --- | --- | ---: | ---: | ---: | ---: |
| baseline | ANGLE Metal / Apple M4 Pro | 119.998 | 103.093 | 9.7 ms | 0/720 |
| constrained-software | ANGLE Vulkan / SwiftShader, 4x CPU | 14.751 | 13.123 | 76.2 ms | 0/89 |

Both profiles recorded all eight ordered events, exact viewport/canvas fit, no
document scroll, four required resources at HTTP 200, no console errors, no page
errors, and no effective request failures. SwiftShader emitted four expected
`ReadPixels` performance warnings; they are preserved in the report.

Generated local evidence is under
`outputs/web-release-qa-final-20260829/` and remains ignored. CI regenerates and
uploads `outputs/ci-web-release-qa` for every run, including partial/failure
evidence via `if: always()`.

## Anonymous human playtest contract

`docs/playtesting/six-family-playtest-template.json` contains one MISSION-01
session for each of T, B, M, N, A, and D. It records completion, duty switching,
five 1-5 ratings, concise notes, anonymous device/input/locale facts, defects,
and cross-family summary rankings. It explicitly forbids personally identifying
fields and external telemetry.

`tools/validate_human_playtest.mjs` supports two modes:

- `--allow-incomplete` validates the checked-in template in CI;
- complete mode rejects placeholders, missing families, malformed build data,
  incomplete ratings/notes, and common PII keys.

This creates a trustworthy intake format but does not fabricate six human
sessions. Actual participants and actual target hardware are still required.

## Repeatable commands

```sh
npm ci --ignore-scripts
npm run test:tools
npm run validate:playtest-template
godot --headless --path godot/immune --export-release "Web" build/releases/web/index.html
npm run test:web-release -- \
  --artifacts=godot/immune/build/releases/web \
  --out=outputs/web-release-qa \
  --duration-ms=6000

# Hosted software-rendered CI compatibility evidence; not a performance claim.
npm run test:web-release -- \
  --artifacts=godot/immune/build/releases/web \
  --out=outputs/ci-web-release-qa \
  --duration-ms=4000 \
  --gate-mode=compatibility-only
```

## Next safe work

Run the six-family template with real players, then validate each completed JSON
without `--allow-incomplete`. Separately repeat the exported-Web flow on an
agreed low-end Windows/Web target and attach its browser/hardware identity to a
new hardware report. Neither step requires a Meshy generation or release upload.
