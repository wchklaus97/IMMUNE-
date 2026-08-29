# IMMUNE Jelly V4 human-playtest campaign

Status: ready for private human distribution on 2026-08-30. No human result is
claimed or recorded here.

## Purpose and evidence boundary

This bundle turns the successful Godot 4.7.2 Jelly V4 artifact into one exact,
anonymous, six-person playtest campaign. It proves build provenance, complete
platform files, participant order, and tamper detection. It cannot prove that
the art is accepted, the game is fun or accessible, or that it performs on
lower-end hardware until real adults complete the sessions on relevant devices.

No public release, tag, upload, Developer ID signing, or notarization was done.
Raw reports and generated campaign files remain under ignored `outputs/` paths.

## Source provenance

- Version: `0.4.0`
- Build commit: `23f5bdc82c7f9eae0311d6959e532ed06da0b167`
- Successful GitHub Actions run: `33264998027`
- Source artifact:
  `immune-demo-23f5bdc82c7f9eae0311d6959e532ed06da0b167`
- Campaign root:
  `outputs/human-playtest-campaigns/immune-v0.4.0-23f5bdc-run-33264998027-jelly-v4-portable-v1/`
- Artifact-set SHA-256:
  `6d4e94f6b9c0d3f416e3653181b533c3f0403c029da49a31c565c75ba0f7fc24`

The release contract accepts exactly 14 Windows, Linux, macOS, and Web files.
The schema-v2 manifest records `ready-for-human-distribution` and
`playtest-distribution-provenance-not-human-results`.

## Verification

The atomic generator created six cyclic orders beginning with T, B, M, N, A,
and D. It copied 14 release artifacts, 24 participant-kit files, and five
portable facilitator files. All 43 entries are covered by `SHA256SUMS`.

- Repository verifier: 6 participants / 14 artifacts, pass.
- Verifier copied inside the bundle: pass.
- Independent `shasum -a 256 -c SHA256SUMS`: 43/43 pass.
- Web, Windows, Linux, and macOS facilitator preflight: pass, including the
  Linux executable bit.
- Exact campaign Web artifact in real Chromium: research, mission selection,
  B combat, mobile duty, pause open, and pause close all pass with exact canvas
  fit and no effective resource, console, or page errors.
- Local ANGLE/Metal: 120.003 mean / 109.890 p05 FPS.
- 4x-CPU SwiftShader: 13.165 mean / 11.962 p05 FPS.
- Eight browser screenshots were visually reviewed without blank output,
  scroll, clipping, or UI displacement.

SwiftShader remains compatibility stress, not a real low-end hardware result.
Campaign verification is distribution integrity, not a human result.

## Run the campaign

Start with one adult and the platform they will actually use:

```sh
cd outputs/human-playtest-campaigns/immune-v0.4.0-23f5bdc-run-33264998027-jelly-v4-portable-v1
node facilitator/run_human_playtest_session.mjs \
  --campaign=. \
  --participant=tester-01 \
  --platform=web \
  --open
```

Collect completed reports under `outputs/playtests/human/raw/23f5bdc/`.
Validate every report and require at least three complete adults before an
aggregate; six are recommended to finish the first counterbalanced rotation.

## Operational constraint

Only about 834 MiB of disk remained after the campaign and browser evidence were
created. The exact CI artifact replaced the rebuildable local release files in
`godot/immune/build/releases`; the historical V3 campaign was preserved. Do not
create another full campaign or duplicate the artifact without freeing space.
