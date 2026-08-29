# Verified human-playtest facilitator station

Date: 2026-08-29

## Outcome and claim boundary

The six-person campaign can now be opened through a checksum-gated facilitator
station instead of manually pairing a tester folder, platform entry point,
runtime sidecars, and an ad hoc Web server. The station is a local operational
aid. It verifies distribution integrity and assignment only; it does not create
a report, count as a human participant, or prove fun, accessibility, jelly
visual quality, control feel, or target-hardware performance.

## Session contract

The self-contained `facilitator/run_human_playtest_session.mjs` accepts one
existing verified campaign, one assigned participant, and one explicit
platform:

```sh
cd outputs/human-playtest-campaigns/immune-v0.4.0-81a3cbe-run-33257048004-portable-v4
node facilitator/run_human_playtest_session.mjs \
  --campaign=. \
  --participant=tester-01 \
  --platform=web \
  --open
```

Before it starts, the tool:

1. re-runs the complete campaign verifier, including all 43 hashed artifact,
   kit, and facilitator files plus the exact-root allowlists;
2. requires the participant to exist in the campaign manifest and preserves
   that participant's six-family cyclic order;
3. chooses the exact Web, Windows, Linux, or macOS entry and companion files;
4. rejects a Linux binary whose executable permission was lost even when its
   content hash is unchanged; and
5. reports an explicit `verified-facilitator-session-not-human-result` evidence
   class and claim boundary; and
6. runs from the copied campaign with only Node.js: the runner and its four
   validation dependencies are in the manifest and `SHA256SUMS`, so no
   repository checkout or npm installation is required.

`--preflight-only` prints the exact launch path and exits. Without it, the
station binds to `127.0.0.1` on a caller-selected or ephemeral port. The landing
page displays the full build commit, Actions run, participant, mission, family
order, and platform inventory. It uses `no-store`, same-origin isolation,
referrer, permissions, and MIME hardening headers.

The selected participant's four allowlisted kit files are available under
`/kit/`. Web sessions also expose only the nine verified Web artifacts under
`/game/`, including `application/wasm` for the engine binary. Native stations
show the exact filesystem launch path but return 404 for `/game/`; executables
are never distributed over HTTP.

## RED/GREEN findings

The initial module-missing RED established four independent tests: all-platform
mapping, invalid/tampered input, a loopback Web station, and a native station
that cannot serve executables. The fixture implementation passed those tests,
but the real campaign rehearsal exposed two omissions that were corrected with
new regression assertions:

1. The first Web preflight reported the apple-touch icon as `launch=` because
   artifact inventory order had been reused as entry-point order. A new exact
   launch-path assertion failed, then Web ordering was changed to put
   `web/index.html` first.
2. The first real Chrome station smoke loaded the game and canvas but reported
   one 404. Response and console-location tracing proved it was Chrome's implicit
   `/favicon.ico` request, not a Godot artifact failure. A data-URL station icon
   and HTML regression assertion removed the network request rather than
   suppressing browser errors.

The next smoke initially looked for a nonexistent console prefix and therefore
recorded zero QA events. Inspection of the checked-in `WebQaBridge` contract
showed that events live in `globalThis.__immuneWebQa`. The final rehearsal used
the same state contract as `tools/web_release_qa.mjs` and waited explicitly for
`engine_ready` followed by `research_ready`.

A final facilitator-device audit found that the repo-local command was not
portable when only the campaign directory was copied. Schema v2 now includes
the runner and four dependencies as five separately hashed files. The first
spawned portable test then exited 0 with no output because macOS can present the
same temporary path as `/var/...` and `/private/var/...`; string-based
main-module detection failed across that alias. Both portable CLI entries now
compare realpaths, and the regression requires explicit success output from the
bundled `--verify=.` and `--preflight-only` commands. Schema-v1 evidence remains
readable. The final verifier review also replaced root metadata, a complete
participant directory, and the bundled runner with content-preserving external
symlinks; all three levels now fail explicitly instead of following paths out of
the campaign.

## Verification evidence

- Session-specific tests: 4/4; campaign portability, legacy, tamper, and symlink
  coverage: 7/7.
- Full root tool suite after integration: 36/36.
- Node syntax and `git diff --check`: pass.
- The real schema-v2 portable campaign at
  `outputs/human-playtest-campaigns/immune-v0.4.0-81a3cbe-run-33257048004-portable-v4/`
  has 14 artifacts, 24 kit files, and 5 facilitator files. Its bundled verifier
  and an independent `shasum` pass both proved all 43 entries. The unchanged
  artifact-set SHA-256 is
  `9ce6eac3db3da6dc4ffd81c23eb1af59d59906dab2860560df1a5de419da9f8c`.
- The portable bundle's own runner passed Web, Windows, Linux, and macOS
  `--preflight-only`; each reported the intended platform entry, and the Linux
  executable permission check passed.
- A real bundled `tester-01` Web station ran on `127.0.0.1:41976`. Its landing
  page and assigned form returned 200; the 39,514,754-byte WASM returned 200 with
  `application/wasm`; all checked responses used `no-store` and isolation
  headers.
- Headless Chrome at 1280x720 confirmed the full commit and tester assignment,
  zero station/game console or page errors, a 1280x720 unclipped canvas with no
  document scroll, and ordered `engine_ready` / `research_ready` events.
- The station and research-network screenshots were visually reviewed and
  showed the expected provenance, family order, controls, and complete game
  canvas. Evidence remains ignored under
  `outputs/playtest-session-station-qa/`.

## Next safe work

Run one station per real adult participant, starting with `tester-01` and the
agreed platform. Collect at least three complete reports, preferably all six,
exercise both locales, and include at least one real Windows integrated-GPU
session. Validate each downloaded JSON before aggregation. A public tag,
notarization, upload, or storefront submission remains a separate owner- and
credential-gated publishing action.
