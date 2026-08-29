# IMMUNE six-family human playtest

This campaign collects real, anonymous, local-only player evidence for the six
base-cell families. Automation already proves that the demo loads and that the
combat loop can complete. This campaign asks the questions automation cannot:
Are the families distinct, are controls and combat readable, does the jelly art
communicate clearly, and would a player choose to replay?

## Evidence boundary

- Raw reports stay under ignored local `outputs/` folders.
- The offline form makes no network requests and does not auto-save answers.
- Reports use anonymous `tester-` codes and require adult confirmation.
- Names, email addresses, phone numbers, account names, and contact details are
  forbidden.
- The aggregate removes participant codes, device text, GPU text, and all
  free-text answers. It contains numeric counts and ratings only.
- A minimum sample does not prove accessibility, fun, or low-end hardware
  performance. A facilitator must review local notes and hardware coverage.

## Campaign contract

- Shared mission: `MISSION-01`
- Families: T, B, M, N, A, D
- Minimum initial sample: 3 complete participants
- Recommended sample: 6 complete participants
- Design: each participant plays all six families
- Order control: deterministic cyclic rotation from the anonymous participant
  code
- Exact provenance: every participant must use the same version and build
  commit

The six numeric tester codes `tester-01` through `tester-06` start on a
different family. Continue with `tester-07` only after the first rotation is
assigned.

## Prepare the verified six-person campaign

The following Jelly V3 path is retained as a historical reproducibility record.
Current source contains Jelly V4 and therefore must not collect or label new V4
human results with this older artifact. Wait for a successful V4 CI artifact
and a new provenance-locked campaign before starting the next participant set.

The historical V3 path packages the exact successful CI artifact once, plus six
counterbalanced participant kits. For commit `2b077c5` from Actions run
`33262958960`:

```sh
gh run download 33262958960 \
  -n immune-demo-2b077c57c82881cca2d33cb6c07abed4b944776a \
  -D outputs/release-ci-33262958960-jelly-v3

npm run create:playtest-campaign -- \
  --artifacts=outputs/release-ci-33262958960-jelly-v3 \
  --build-commit=2b077c57c82881cca2d33cb6c07abed4b944776a \
  --source-run=33262958960 \
  --source-artifact=immune-demo-2b077c57c82881cca2d33cb6c07abed4b944776a \
  --out=outputs/human-playtest-campaigns/immune-v0.4.0-2b077c5-run-33262958960-jelly-v3-portable-v1

npm run create:playtest-campaign -- \
  --verify=outputs/human-playtest-campaigns/immune-v0.4.0-2b077c5-run-33262958960-jelly-v3-portable-v1
```

The generated bundle contains:

- `artifacts/`: the exact Windows, Linux, macOS, and complete Web builds;
- `participants/tester-01` through `tester-06`: one assigned offline kit each;
- `facilitator/`: the portable session runner plus its four validation
  dependencies, so the copied campaign needs Node.js but no repository checkout
  or npm install;
- `campaign-manifest.json`: CI source, full commit, 14-file artifact inventory,
  participant order, portable runner inventory, sizes, and SHA-256 values;
- `SHA256SUMS`: all 14 artifact, 24 participant-kit, and 5 facilitator-file
  checksums; and
- `README.md`: facilitator distribution instructions.

The generator requires the Windows and Linux `.pck` sidecars and both Web audio
worklets, rejects unexpected files, verifies the completed copy, writes through
a temporary sibling directory, and refuses to overwrite an existing campaign.
The verifier also rejects altered manifests, path traversal, checksum drift,
and any unchecksummed debug/private file added later.

## Start a verified facilitator session

Use the station instead of manually matching a participant folder, executable,
sidecar, and Web server:

```sh
cd outputs/human-playtest-campaigns/immune-v0.4.0-2b077c5-run-33262958960-jelly-v3-portable-v1
node facilitator/run_human_playtest_session.mjs \
  --campaign=. \
  --participant=tester-01 \
  --platform=web \
  --open
```

Choose exactly one of `web`, `windows`, `linux`, or `macos`. The portable runner
and validators are themselves checksummed campaign files. Before opening the
station, the runner revalidates the complete campaign, checks that the assigned
participant and cyclic family order match the manifest, selects only the
platform's allowlisted entry and companion files, and verifies the Linux execute
bit when relevant. Use `--preflight-only` to print the exact native launch path
and exit without starting a server.

The station binds only to `127.0.0.1`, uses `no-store` and same-origin isolation
headers, shows the full build commit and assigned family order, and serves only
the selected kit. For Web it serves the complete verified export with the
correct WASM MIME type. For native platforms it shows the exact launch
instructions but never serves an executable over HTTP. Closing the terminal or
pressing Ctrl+C stops the station.

This preflight is distribution-integrity evidence only. It creates no report,
does not count as a participant, and cannot establish fun, accessibility,
visual quality, control feel, or real-hardware performance.

## Prepare one kit only

Use this fallback only when a complete campaign bundle is not needed. Always use
the commit that produced the artifact, not the current documentation HEAD:

```sh
npm run create:playtest-kit -- \
  --participant=tester-01 \
  --build-commit=2b077c57c82881cca2d33cb6c07abed4b944776a \
  --out=outputs/human-playtest-kits/tester-01-build-2b077c5
```

The output contains:

- `index.html`: bilingual offline form
- `report.json`: prefilled blank report
- `manifest.json`: exact build and assigned family order
- `README.md`: tester and facilitator instructions

The generator refuses to overwrite an existing kit so participant drafts are
not destroyed accidentally.

## Run one session

1. Start the verified station for the assigned participant and platform.
2. Confirm the station displays the expected full commit and family order.
3. For native sessions, launch only the file shown by the station and keep its
   required companion files together.
4. For Web sessions, use the station's **Open Web game** button rather than
   opening `index.html` with `file://`.
5. Ask the participant not to enter names or contact details.
6. Let the participant play each family in the assigned order.
7. Explain only the normal controls. Avoid coaching family strategy after play
   begins.
8. Ask the participant to try the duty switch where available.
9. Use Download draft before any break.
10. Use Export completed report after all six sessions.
11. Store the downloaded JSON under
   `outputs/playtests/human/raw/<build-commit>/`.

## Validate reports

Validate every completed file separately:

```sh
node tools/validate_human_playtest.mjs \
  outputs/playtests/human/raw/2b077c5/tester-01-six-family-playtest-complete.json
```

The validator rejects incomplete sessions, placeholders, unknown families,
mixed missions, malformed build provenance, PII keys, and email addresses
hidden in free text.

## Aggregate a campaign

```sh
npm run aggregate:playtests -- \
  --dir=outputs/playtests/human/raw/2b077c5 \
  --out=outputs/playtests/human/aggregate-2b077c5.json \
  --minimum-participants=3 \
  --require-minimum
```

`--require-minimum` exits non-zero when fewer than three valid participants are
present, but still writes an `insufficient-sample` aggregate for inspection.
Duplicate participant codes or mixed builds fail without producing a combined
claim.

## Facilitator review

Before making a product decision, inspect the local raw reports for:

- repeated confusion about the same control, duty, phase, or HUD element;
- any family with repeated role or jelly-visual ratings below 3;
- defects reproduced by more than one participant;
- whether both Traditional Chinese and English were exercised;
- at least one real Windows integrated-GPU result;
- at least one controller result if controller support is a release claim; and
- motion, contrast, text-size, or input-access needs that the current form does
  not represent.

Do not commit raw reports. If a decision summary is needed in the repository,
write it from the anonymous numeric aggregate and remove any copied free text.
