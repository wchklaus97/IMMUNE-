# Exported-Web compatibility stress and six-family human playtest contract

Date: 2026-08-29

## Scope and claim boundary

This tranche closes the repeatable exported-Web compatibility gap without
pretending that one development Mac is representative lower-end hardware. The
browser evidence is deliberately labelled
`compatibility-stress-not-hardware-benchmark`. It proves that the shipped HTML,
JavaScript, PCK, and WASM load; a real browser can drive the playable loop; and
the loop retains a bounded frame heartbeat under an artificial stress profile.

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

- `baseline`: 1600x900, native renderer, no CPU throttling;
- `constrained-software`: 1280x720, 4x DevTools CPU throttling, forced
  SwiftShader with renderer proof.

The baseline gate uses 50 ms long frames. The constrained profile is a
compatibility heartbeat, not a smoothness claim: it records the same 50 ms
metric but gates on frames above 250 ms (`compatibility_stall_ratio`) so its
5 FPS floor and stall definition are internally consistent.

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

## Local evidence

The final six-second run produced eight visually reviewed screenshots and this
result:

| Profile | Renderer | Mean FPS | p05 FPS | p95 frame | >250 ms stalls |
| --- | --- | ---: | ---: | ---: | ---: |
| baseline | ANGLE Metal / Apple M4 Pro | 120.000 | 111.111 | 9.0 ms | 0/720 |
| constrained-software | ANGLE Vulkan / SwiftShader, 4x CPU | 14.460 | 13.210 | 75.7 ms | 0/87 |

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
```

## Next safe work

Run the six-family template with real players, then validate each completed JSON
without `--allow-incomplete`. Separately repeat the exported-Web flow on an
agreed low-end Windows/Web target and attach its browser/hardware identity to a
new hardware report. Neither step requires a Meshy generation or release upload.
