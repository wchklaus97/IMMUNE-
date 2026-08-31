# IMMUNE Jelly V5.2 human-playtest campaign

Status: ready for private human distribution on 2026-08-31. No human result is
claimed or recorded here.

## Purpose and evidence boundary

This bundle turns the successful Godot 4.7.2 Jelly V5.2 artifact into one exact,
anonymous, six-person playtest campaign. It proves source provenance, complete
platform files, participant order, route availability, and tamper detection. It
cannot prove that players accept the jelly texture, that the game is fun or
accessible, that the narrow-phone layout works on physical notches, or that it
performs on lower-end hardware until real adults complete the sessions on
relevant devices.

No public release, tag, Developer ID signing, notarization, or storefront upload
was done. Raw reports and generated campaign files remain under ignored
`outputs/` paths.

## Source provenance

- Version: `0.4.0`
- Build commit: `32a04cd544afd196b454386a4d252828d33badf2`
- Successful GitHub Actions run: `33361771002`
- Actions URL: `https://github.com/wchklaus97/IMMUNE-/actions/runs/33361771002`
- Source artifact:
  `immune-demo-32a04cd544afd196b454386a4d252828d33badf2`
- Actions release-archive SHA-256:
  `f7a6131a399c54993ffb9e57bff5ed0849b3a87bdfeb167d4ac345f617b76908`
- Actions hosted-Web-QA archive SHA-256:
  `d61e6468efe9d5c28bf72c4ccece8a240454a5822856b63889c9962f5aa3ea1d`
- Campaign root:
  `outputs/human-playtest-campaigns/immune-v0.4.0-32a04cd-run-33361771002-jelly-v52-portable-v1/`
- Campaign generated at: `2026-08-31T08:39:48.670Z`
- Artifact-set SHA-256:
  `11041aa0447929cf1b75b02574ee630f8a080a564ffde52402ceb76873f29bc6`

The run's main validation/export job and the Linux, Windows, and macOS native
release-smoke jobs all passed. The exact named release artifact was downloaded
while unexpired and accepted by the release contract as exactly 14 Windows,
Linux, macOS, and Web files. The schema-v2 campaign manifest records
`ready-for-human-distribution` and
`playtest-distribution-provenance-not-human-results`.

## Verification

The atomic generator created six cyclic orders beginning with T, B, M, N, A,
and D. It copied 14 release artifacts, 24 participant-kit files, and five
portable facilitator files. All 43 entries are covered by `SHA256SUMS`.

- Repository verifier: 6 participants / 14 artifacts, pass.
- Verifier copied inside the bundle: pass.
- Independent `shasum -a 256 -c SHA256SUMS`: 43/43 pass.
- All six participant assignments pass Web preflight. Web, Windows, Linux, and
  macOS preflight pass for `tester-01`, including the Linux executable bit.
- Real facilitator station: landing, assigned form, selected Web build, and
  WebAssembly resource return HTTP 200 on loopback. The station supplies
  `no-store`, COOP/COEP, same-origin resource policy, and the correct
  `application/wasm` MIME type.
- Exact campaign Web artifact in Chromium: research, mission selection, B
  combat, mobile duty, pause open, and pause close pass with exact canvas fit
  and no effective resource, console, page, or request error.
- Local ANGLE/Metal: 119.996 mean / 104.167 p05 FPS.
- 4x-CPU SwiftShader: 13.207 mean / 10.823 p05 FPS.
- Eight browser screenshots were visually reviewed without blank output, HUD
  displacement, or broken rendering. The animated T hero reaches beyond the
  preview's top edge in the 1280x720 constrained mission frame; participants
  should judge whether that reads as lively or cramped.

SwiftShader is a compatibility stress sentinel, not a real lower-end hardware
benchmark. Campaign verification is distribution integrity, not a human result.

## Failure handling

The first GitHub artifact-metadata query was blocked by the restricted network
sandbox. It was rerun with explicit GitHub API permission and proved the exact
artifact name, source commit, run, size, digest, and unexpired state before any
download began.

The first local browser rehearsal failed before serving the game with
`listen EPERM` because the sandbox denied a `127.0.0.1` listener. The empty
tool-created evidence directory was removed, and the exact command passed after
granting loopback-server permission; no gate was weakened. Four concurrent
header requests passed, while two concurrent content requests briefly missed
the station across isolated command sandboxes. The station process remained
healthy and both content contracts passed when retried sequentially. The final
36-test tool suite reproduced the same sandbox restriction only in its two
listener tests, then passed 36/36 unchanged with loopback permission.

Storage was also treated as a hard gate. With no external volume and 3.3 GiB
initially free, the 433,014,678-byte archive was downloaded into a unique system
temporary directory, validated, used as the campaign source, and retained until
all campaign and browser checks passed. Only that 560 MiB tool-created temporary
copy was then deleted. No earlier evidence or user file was removed, the final
campaign remains about 560 MiB, and about 2.7 GiB remained afterward.

## Run the campaign

Start with one adult and the platform they will actually use:

```sh
cd outputs/human-playtest-campaigns/immune-v0.4.0-32a04cd-run-33361771002-jelly-v52-portable-v1
node facilitator/run_human_playtest_session.mjs \
  --campaign=. \
  --participant=tester-01 \
  --platform=web \
  --open
```

Collect completed reports under `outputs/playtests/human/raw/32a04cd/`.
Validate every report and require at least three complete adults before an
aggregate; six are recommended to finish the first counterbalanced rotation.

## Operational constraint

About 2.7 GiB of disk remained after temporary cleanup. Avoid duplicating the
artifact or campaign, and do not delete earlier ignored evidence without owner
approval. The generated campaign is ready for private sessions but is not a
publicly signed or notarized release.
