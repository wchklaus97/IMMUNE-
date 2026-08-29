# Offline six-family human playtest campaign kit

Date: 2026-08-29

## Outcome and evidence boundary

The remaining subjective gate now has a repeatable collection workflow rather
than only a blank JSON template. A facilitator can create one provenance-locked,
anonymous, offline kit per participant, collect all six MISSION-01 family
sessions, validate each report, and produce a numeric-only campaign aggregate.

This work does not claim that a human playtest has happened. Browser-filled
reports used during development are synthetic form-smoke fixtures. They remain
under ignored `outputs/` paths and must never be counted as participant evidence.
At least three real complete participants are required for an initial comparable
sample; six are recommended. Fun, accessibility, visual clarity, control feel,
and lower-end hardware performance still require facilitator review and real
target hardware.

## Workflow and ownership

```text
exact exported build commit
          |
          v
create_human_playtest_kit.mjs
          |
          +-- manifest + assigned cyclic family order
          +-- bilingual offline form + blank report
          |
          v
real participant exports completed JSON
          |
          v
validate_human_playtest.mjs
          |
          v
aggregate_human_playtests.mjs
          |
          +-- numeric counts, ratings, outcomes, votes
          +-- no participant codes, device/GPU text, or free text
```

- `docs/playtesting/campaign-plan.json` is the machine-readable campaign
  contract: MISSION-01, six families, within-subject design, minimum 3,
  recommended 6, and coverage targets.
- `tools/create_human_playtest_kit.mjs` requires an explicit anonymous
  `tester-` code and the exact commit that produced the artifact. Numeric codes
  `tester-01` through `tester-06` use the six cyclic starting families once
  each. The generator refuses to overwrite an existing kit.
- `tools/validate_human_playtest.mjs` rejects incomplete sessions,
  placeholders, malformed provenance, identifying field names, and email
  addresses hidden in any text value.
- `tools/aggregate_human_playtests.mjs` validates every input, rejects duplicate
  participants and mixed builds, and emits a numeric-only aggregate. With
  `--require-minimum`, a valid under-sized campaign writes an
  `insufficient-sample` report and exits 2.

## Offline form design

The form is native HTML, CSS, and JavaScript with no runtime dependencies. It
uses a restrained cold-biotech palette, one cyan accent, automatic light/dark
color schemes, responsive single-column mobile layout, visible focus rings,
and minimum 44 px interactive controls. The English and Traditional Chinese
copy is intentionally direct for nontechnical testers.

Privacy is part of the interface rather than hidden policy text: the form says
that it makes no network requests, does not upload or track, does not auto-save,
and must not contain names or contact details. Draft and completed exports are
downloaded locally. A draft is never accepted by the completed-report
validator.

Design calibration: `DESIGN_VARIANCE=3`, `MOTION_INTENSITY=2`, and
`VISUAL_DENSITY=5`. No animation, decorative gradients, external fonts, or
unnecessary dashboard chrome were introduced.

## Diagnosed failures and corrections

Three failures were treated as workflow findings rather than bypassed:

1. The first browser smoke had one console error. Network inspection isolated
   it to Chrome's implicit missing favicon request, not form behavior. An empty
   data-URL favicon was added and a fresh kit was generated rather than
   overwriting participant data.
2. The first complete-form automation timed out because later family controls
   live inside closed native `details` panels. The test was corrected to open
   each panel before filling it. The product kept native disclosure behavior.
3. The first aggregator CLI run failed with `paths[2] must be string, got
   Array`. Passing `resolve` directly to `map` leaked the array index and source
   array into Node's variadic path API. Explicit arrow functions fixed the call,
   and a spawned CLI integration test now covers positional input and the
   minimum-sample exit code.

## Local verification

- Root tool suite: 25/25 tests pass, including generator determinism,
  counterbalancing, overwrite refusal, PII rejection, aggregate privacy,
  mixed-build/duplicate rejection, and real CLI invocation.
- The checked-in blank template validates in incomplete mode.
- A generated `tester-01` kit uses version `0.4.0`, build commit
  `5021665c73862f9aa8a2e7adf514c86841f4c4e5`, and order T, B, M, N, A, D.
- Desktop dark, desktop light, and 390x844 mobile renders were visually
  inspected. The mobile audit found one H1, no horizontal overflow, no
  unlabeled fields, no undersized ordinary controls, no external requests, and
  no console errors.
- Empty completed export is blocked. Synthetic draft and complete downloads
  match the schema; only the completed fixture passes strict validation.
- A synthetic one-report aggregate is explicitly
  `status=insufficient-sample`, `participants=1`, `remaining=2`, with no
  participant code or raw text leak. It is not human evidence.
- The unchanged exported Godot Web artifact also passed the strict local
  browser sentinel after this tranche: Metal baseline 120.006 mean / 101.010
  p05 FPS; 4x CPU plus SwiftShader 15.093 / 13.387, with the full interaction
  flow intact.

Generated kits, downloads, screenshots, raw reports, and aggregates remain
ignored under `outputs/`.

The follow-on distribution tranche packages the exact successful CI binaries,
all six kits, and SHA-256 inventory into one atomic verified campaign. See
`docs/godot-prompter/specs/2026-08-29-playtest-distribution-bundle.md`.

## Remote verification

GitHub Actions run `33257048004` verifies commit `81a3cbe` on Godot 4.7.2.
The 11m39s `validate-and-export` job passed the 25-test tool suite, playtest
template, 53-test research UI, localization/release contracts, Godot import and
smoke, bounded T/B campaign balance, all-six-family MISSION-01 regression, HUD
layout, four exports, hosted Web compatibility flow, and both artifact uploads.
Native artifact launch then passed on Linux in 9s, Windows in 21s, and macOS in
45s.

The downloaded schema-v2 Web report is explicitly `compatibility-only`; both
profiles used hosted ANGLE Vulkan SwiftShader. Baseline measured 1.158 mean /
1.111 p05 FPS with a 900 ms maximum frame, and the 4x-CPU profile measured
1.324 / 1.304 with a 766.8 ms maximum. Each profile recorded all eight expected
events, four HTTP 200 release resources, and zero console, page, or effective
request errors. All eight uploaded research, mission-select, combat, and pause
screenshots were visually reviewed without blank canvases, clipping, or state
mismatches. These figures prove compatibility and liveness only, not hardware
performance.

## Repeatable commands

```sh
npm run create:playtest-campaign -- \
  --artifacts=outputs/release-ci-33257048004 \
  --build-commit=81a3cbe1a5ba60227bbe0d8c873c55d07871b729 \
  --source-run=33257048004 \
  --source-artifact=immune-demo-81a3cbe1a5ba60227bbe0d8c873c55d07871b729 \
  --out=outputs/human-playtest-campaigns/immune-v0.4.0-81a3cbe-run-33257048004

npm run create:playtest-kit -- \
  --participant=tester-01 \
  --build-commit=81a3cbe1a5ba60227bbe0d8c873c55d07871b729 \
  --out=outputs/human-playtest-kits/tester-01-build-81a3cbe

node tools/validate_human_playtest.mjs \
  outputs/playtests/human/raw/81a3cbe/tester-01-six-family-playtest-complete.json

npm run aggregate:playtests -- \
  --dir=outputs/playtests/human/raw/81a3cbe \
  --out=outputs/playtests/human/aggregate-81a3cbe.json \
  --minimum-participants=3 \
  --require-minimum
```

## Next safe work

Assign `tester-01` through `tester-06` to real adult participants, keep every
raw report local, validate each file, and aggregate only reports from the exact
same artifact commit. Ensure both locales are exercised and include at least one
real Windows integrated-GPU session. A public release, tag, upload, or hardware
performance claim remains a separate owner-approved action.
