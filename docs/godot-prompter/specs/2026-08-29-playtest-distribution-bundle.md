# Provenance-locked human playtest distribution bundle

Date: 2026-08-29

## Outcome and claim boundary

The six-family playtest is now packaged as one distribution-ready local bundle
rather than six forms that a facilitator must manually pair with binaries. The
bundle contains the exact successful GitHub Actions release artifact once, six
counterbalanced participant kits, a source manifest, and checksums for every
distributed artifact and kit file.

`ready-for-human-distribution` means the local file set is complete and passes
the integrity contract. It does not mean any participant has played it. The
bundle contains no human results and cannot prove fun, accessibility, visual
quality, control feel, or real lower-end hardware performance.

## Distribution contract

`tools/create_human_playtest_campaign.mjs` requires:

- the exact full 40-character commit used by CI;
- a positive Actions run ID and artifact name containing that commit;
- version parity with `project.godot`;
- exactly 14 allowlisted release files, including the Windows and Linux `.pck`
  sidecars and both Web audio worklets;
- six participant kits, with T, B, M, N, A, and D each used once as the first
  family;
- SHA-256 and byte size for each release and kit file; and
- a destination that does not already exist.

Generation occurs in a temporary sibling directory. The complete staging tree
is verified before one final rename, so a failed hash, copy, kit, or manifest
check cannot leave a distribution that looks complete. Existing campaigns are
never overwritten.

The same executable supports `--verify`. Verification rejects:

- missing, additional, symlinked, or renamed artifacts;
- modified sizes or SHA-256 values;
- a changed aggregate artifact-set digest;
- participant-code, build-commit, family-order, or kit-path mismatch;
- path traversal in manifest-controlled paths;
- a modified or missing `SHA256SUMS`; and
- any unchecksummed file added to the campaign root or a participant kit.

The general release contract was also tightened so Windows/Linux sidecars and
Web audio worklets are mandatory for all artifact validation, not only campaign
packaging.

## Diagnosed workflow correction

The first real bundle passed every source/destination checksum and its copied
Web artifact passed the browser flow. The browser evidence was initially written
inside the campaign root. Although harmless, that made the distribution contain
an unchecksummed debug directory.

Work stopped before handoff. The evidence was moved to the separate ignored
`outputs/playtest-campaign-web-qa-81a3cbe/` path, the verifier gained an exact
top-level and participant-file allowlist, and a RED/GREEN regression now proves
that `debug.log` and private-note additions fail verification. The final bundle
contains only the five declared root entries.

## Real generated campaign

Source:

- version: `0.4.0`
- commit: `81a3cbe1a5ba60227bbe0d8c873c55d07871b729`
- GitHub Actions run: `33257048004`
- artifact: `immune-demo-81a3cbe1a5ba60227bbe0d8c873c55d07871b729`
- artifact count: 14
- participant kits: 6, or 24 kit files
- artifact-set SHA-256:
  `9ce6eac3db3da6dc4ffd81c23eb1af59d59906dab2860560df1a5de419da9f8c`

Generated ignored output:

`outputs/human-playtest-campaigns/immune-v0.4.0-81a3cbe-run-33257048004/`

All 38 `SHA256SUMS` entries passed independently with macOS `shasum`. The Linux
binary retained executable permissions. A second create invocation exited 1
with explicit overwrite refusal. The verifier passed after the separate QA
evidence directory was removed from the distribution.

The real `tester-01` form was opened at 390x844 in Chrome. It displayed the full
commit and T/B/M/N/A/D order with zero horizontal overflow, zero unlabeled
fields, one same-origin document request, no external requests, and no console
errors.

The copied release artifact passed the strengthened four-platform structure
contract. Its Web copy then completed the real browser flow from research to
mission selection, B/MISSION-01 combat, mobile duty, and pause:

| Profile | Renderer | Mean FPS | p05 FPS |
| --- | --- | ---: | ---: |
| baseline | ANGLE Metal / Apple M4 Pro | 119.753 | 103.093 |
| constrained | 4x CPU / SwiftShader | 15.219 | 13.624 |

This remains a local compatibility sentinel, not a lower-end hardware result.

## Automated evidence

- Campaign-specific tests: 5/5.
- Full root tool suite: 30/30 after adding the distribution contracts.
- Meshy no-network tests: 6/6.
- Release artifact, translation, catalog-localization, and workflow contracts:
  pass.
- Raw release download, generated campaigns, participant data, and browser
  evidence remain ignored under `outputs/`.

Remote verification for functional commit `dd8a960` completed in GitHub Actions
run `33258313619`: the main validation/export job passed in 11m35s, followed by
Linux, Windows, and macOS native release smoke jobs in 14s, 19s, and 22s.

The downloaded schema-v2 hosted-Web report is explicitly
`compatibility-stress-not-hardware-benchmark` with a `compatibility-only` gate.
Both profiles used ANGLE Vulkan SwiftShader. Baseline recorded 1.210 mean / 1.132
p05 FPS and an 883.3ms maximum frame; the 4x-CPU profile recorded 1.385 mean /
1.333 p05 FPS and a 750ms maximum frame. Each profile emitted all eight ordered
readiness/interaction events, loaded all four required resources with HTTP 200,
and had zero console errors, page errors, or effective request failures. All
eight research, mission-selection, combat, and pause screenshots were visually
reviewed: the expected state was present, the canvas fit the viewport, no UI was
clipped, and the highlighted jelly character remained visible in both profiles.

The distribution is now consumed through the checksum-gated facilitator station
documented in
`docs/godot-prompter/specs/2026-08-29-verified-facilitator-station.md`. It
re-verifies the campaign before every session, locks the participant order and
platform entry, provides a loopback-only Web server with the correct WASM MIME,
and never serves native executables over HTTP. This reduces facilitator setup
errors but remains operational evidence rather than human evidence.

The recommended copied bundle is now schema v2. It adds five separately hashed
files under `facilitator/`—the runner and four validation dependencies—to the 14
artifacts and 24 kit files, for 43 `SHA256SUMS` entries. The bundle therefore
needs Node.js but no repository checkout or npm install. Schema-v1 evidence
remains verifiable. Manifest entries are checked with `lstat`, so a symlink to
matching content outside the campaign is rejected rather than accepted by hash;
the same prohibition applies to root metadata entries and participant kit
directories.

## Next safe work

Start the verified station for the assigned participant and platform, then give
`tester-01` through `tester-06` to real adults. Collect a minimum of three valid
reports and preferably all six, with both locales and at least one real Windows
integrated-GPU session. Keep raw JSON local and aggregate only reports from
commit `81a3cbe`.
