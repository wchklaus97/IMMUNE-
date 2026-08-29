# IMMUNE Jelly V3 human-playtest campaign

Status: ready for private human distribution on 2026-08-30. No human result is
claimed or recorded by this document.

## Purpose and evidence boundary

This campaign moves the CI-verified Jelly V3 build into a repeatable,
anonymous six-person playtest without weakening build provenance. It can prove
that every tester receives the same verified binaries, assigned family order,
and report form. It cannot prove that the art is accepted, the game is fun or
accessible, or that it performs on lower-end hardware until real adults complete
the sessions on the relevant machines.

Raw reports and generated campaign files remain under ignored `outputs/`
directories. No participant result was fabricated during campaign preparation.
No public release, upload, tag, signing, or notarization was performed.

## Source provenance

- Version: `0.4.0`
- Build commit: `2b077c57c82881cca2d33cb6c07abed4b944776a`
- Successful GitHub Actions run: `33262958960`
- Source artifact:
  `immune-demo-2b077c57c82881cca2d33cb6c07abed4b944776a`
- Downloaded release root: `outputs/release-ci-33262958960-jelly-v3/`
- Campaign root:
  `outputs/human-playtest-campaigns/immune-v0.4.0-2b077c5-run-33262958960-jelly-v3-portable-v1/`
- Artifact-set SHA-256:
  `82b37917f97bcdbd58675561026958e5d97874af411a413457a9665e3e80a05d`

The release contract accepted exactly 14 allowlisted Windows, Linux, macOS, and
Web files. The campaign manifest identifies the evidence class as
`playtest-distribution-provenance-not-human-results` and the status as
`ready-for-human-distribution`.

## Portable bundle contract

The atomic generator created six cyclically counterbalanced kits for
`tester-01` through `tester-06`, 14 shared release artifacts, and five portable
facilitator files. `SHA256SUMS` covers all 43 artifact, participant-kit, and
facilitator files. The copied bundle requires Node.js but no repository checkout
or npm installation.

Both the repository verifier and the verifier copied inside the campaign pass
with `participants=6 artifacts=14`. Platform preflight passes for Web, Windows,
Linux, and macOS, including the Linux execute-bit contract. The runner binds to
loopback, exposes only the selected kit and Web build, and never serves a native
executable over HTTP.

## Facilitator and exported-Web verification

A real loopback station was started for `tester-01`. The landing page displayed
the exact build commit and its assigned `T -> B -> M -> N -> A -> D` order.
The station, kit, Web entry point, JavaScript, PCK, WASM, and both audio worklets
returned HTTP 200 with the expected MIME and cross-origin-isolation headers.
Unallowlisted native-executable access returned 404 and POST returned 405.

Chromium at 1280x720 then completed the actual exported flow from the research
screen through mission selection, family selection, combat, duty change, and
pause. The canvas fit without page scroll and `crossOriginIsolated` was true.
The ordered application events were:

1. `engine_ready`
2. `research_ready`
3. `mission_select_ready`
4. `family_selected`
5. `combat_ready`
6. `duty_changed`
7. `pause_changed`

The browser reported `ERR_ABORTED` for PCK and WASM requests only after those
exact required resources had already returned HTTP 200. The first ad-hoc check
incorrectly treated those successful preload cancellations as fatal. It was
stopped, diagnosed against the checked-in `web_release_qa.mjs` classifier, and
rerun with the established response-status rule; no failed browser run was
promoted as evidence. The reviewed screenshot is
`outputs/jelly-v3-playtest-campaign-qa/station-web-flow.png`.

## Run the actual campaign

Start with one participant and the platform they will really use:

```sh
cd outputs/human-playtest-campaigns/immune-v0.4.0-2b077c5-run-33262958960-jelly-v3-portable-v1
node facilitator/run_human_playtest_session.mjs \
  --campaign=. \
  --participant=tester-01 \
  --platform=web \
  --open
```

Collect completed adult reports under `outputs/playtests/human/raw/2b077c5/`,
validate each report independently, and require at least three complete
participants before producing an aggregate. Six participants are recommended
to complete the initial cyclic rotation. Human Jelly V3 side-by-side approval
and a real agreed lower-end Windows/Web machine remain required.

## Operational constraint

Approximately 1.6 GiB of free disk remained after creating this 558 MiB portable
campaign. Historical evidence was not deleted. Do not duplicate another full
campaign or CI download without checking disk space first; reuse this verified
bundle for the current test round.
