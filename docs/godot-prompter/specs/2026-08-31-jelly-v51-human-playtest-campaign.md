# IMMUNE Jelly V5.1 human-playtest campaign

Status: ready for private human distribution on 2026-08-31. No human result is
claimed or recorded here.

## Purpose and evidence boundary

This bundle turns the successful Godot 4.7.2 Jelly V5.1 artifact into one exact,
anonymous, six-person playtest campaign. It proves source provenance, complete
platform files, participant order, route availability, and tamper detection. It
cannot prove that players accept the jelly texture, that the game is fun or
accessible, or that it performs on lower-end hardware until real adults complete
the sessions on relevant devices.

No public release, tag, Developer ID signing, notarization, or storefront upload
was done. Raw reports and generated campaign files remain under ignored
`outputs/` paths.

## Source provenance

- Version: `0.4.0`
- Build commit: `2d011b167e79a1d583d368c98ed3c07a41209d3e`
- Successful GitHub Actions run: `33316071797`
- Actions URL: `https://github.com/wchklaus97/IMMUNE-/actions/runs/33316071797`
- Source artifact:
  `immune-demo-2d011b167e79a1d583d368c98ed3c07a41209d3e`
- Main artifact ZIP SHA-256:
  `4dae88f2db99716d538f8932d65a44efca6bf992e298c674410d0af4ed6f4af0`
- Hosted-Web QA ZIP SHA-256:
  `8d603d6b81bc60d5eca8cc7b0e6ed359ff030285cc92c3a7d79eada498302828`
- Campaign root:
  `outputs/human-playtest-campaigns/immune-v0.4.0-2d011b1-run-33316071797-jelly-v51-portable-v1/`
- Artifact-set SHA-256:
  `29c38e83a45a08d6bd7f89f59ee922fce3c89cd4553e78aea59955233045fc88`

The run's main validation/export job and the Linux, Windows, and macOS native
release-smoke jobs all passed. The downloaded ZIP hashes equal the digests
reported by Actions. The release contract accepts exactly 14 Windows, Linux,
macOS, and Web files. The schema-v2 campaign manifest records
`ready-for-human-distribution` and
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
- Real facilitator station: landing, selected Web build, and assigned offline
  form return HTTP 200 on loopback.
- Exact campaign Web artifact in real Chromium: research, mission selection,
  B combat, mobile duty, pause open, and pause close all pass with exact canvas
  fit and no effective resource, console, page, or request error.
- Local ANGLE/Metal: 119.970 mean / 101.010 p05 FPS.
- 4x-CPU SwiftShader: 13.787 mean / 12.180 p05 FPS.
- Eight browser screenshots were visually reviewed without blank output,
  scroll/HUD displacement, or broken hero rendering. The animated orange hero
  reaches the preview panel's top edge in one 1280x720 mission-select frame;
  real participants should be asked whether that close framing reads as lively
  or cramped.
- Hosted CI completed the same eight ordered lifecycle events in both profiles,
  with HTTP-200 required resources, exact canvas fit, and no effective resource,
  console, page, or request error.

Hosted CI used SwiftShader in both profiles and measured 1.875/1.250 and
2.126/1.304 mean/p05 FPS. Those values prove compatibility-path liveness only;
they are not a performance benchmark. The local constrained profile is also a
stress sentinel, not a real lower-end hardware result. Campaign verification is
distribution integrity, not a human result.

## Run the campaign

Start with one adult and the platform they will actually use:

```sh
cd outputs/human-playtest-campaigns/immune-v0.4.0-2d011b1-run-33316071797-jelly-v51-portable-v1
node facilitator/run_human_playtest_session.mjs \
  --campaign=. \
  --participant=tester-01 \
  --platform=web \
  --open
```

Collect completed reports under `outputs/playtests/human/raw/2d011b1/`.
Validate every report and require at least three complete adults before an
aggregate; six are recommended to finish the first counterbalanced rotation.

## Operational constraint

About 3.9 GiB of disk remained after the campaign and browser evidence were
created. The campaign itself is about 560 MiB. Avoid duplicating another full
artifact or campaign unless it is needed, and keep generated exports under
ignored paths.
