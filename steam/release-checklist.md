# Steam release checklist

Updated: 2026-09-04. “Repository complete” means the source tree can produce and
validate a submission candidate. It does not mean Valve has approved the page or
build, nor that the product is publicly released.

## Repository-controlled gates

- [x] Six playable families, six missions, three combat phases, and permanent
  research progression are present.
- [x] Six cooldown-based active skills and six authored encounter patterns are
  covered by the Godot smoke contract.
- [x] Keyboard/gamepad actions, four-action desktop HUD, two-by-two narrow HUD,
  touch movement, safe-area, pause, and bilingual UI contracts exist.
- [x] V8.1 living-slime material, idle circulation, viscous locomotion, and
  authored six-family body contracts pass automated runtime smoke.
- [x] All Meshy/Tripo hero experiments and the damaged faceted T variant are
  excluded from shipping PCKs; all six runtime families use authored jelly
  bodies while source/history evidence remains preserved.
- [x] Current Steam store/library/icon dimensions are represented by checked-in
  assets and a fail-closed validator.
- [x] Six current V8.1 1920x1080, 16:9, actual-gameplay screenshots cover all
  six families and six missions.
- [x] All nine shipping audio files have deterministic project source,
  provenance, exact checksum locks, and a CI drift gate.
- [x] English and Traditional Chinese store-copy drafts exist.
- [x] Known pre-generated AI content has a content-survey disclosure draft and
  local provenance references.
- [x] Godot/Noto/CC0 notices and the exact Godot 4.7.2 copyright inventory are
  checked in and copied into all three staged native depots.
- [x] The repository readiness gate scans the runtime for network APIs, checks
  the shipping/excluded PCK resource policy, verifies rights-bound files, and
  requires every publisher evidence file to exist with a matching SHA-256.
- [x] Native-smoke evidence creation refuses a caller-supplied SHA unless it is
  the current clean tracked Git HEAD; publisher validation cross-checks all
  three native records against one candidate commit/version and final artifacts.
- [x] Depot staging rejects placeholders, unsafe inputs, missing files, and
  credentials; generated VDFs remain in preview mode and do not upload.
- [x] Rebuilt and recorded the final V8.1 Windows, Linux, macOS, and Web
  artifacts from clean source commit
  `52e05f2562470bc6cbe6db505f8df7ded3f53bf0` in
  `build-candidate-v0.4.0-v8.1.md`. The older
  `build-candidate-v0.4.0.md` remains the preserved V5.4 historical record.
- [x] Fresh native macOS release smoke binds that exact V8.1 commit and ZIP,
  including strict ad-hoc signature, universal architecture, bundle metadata,
  entitlements, artifact/log hashes, and the runtime success marker. Developer
  ID signing and notarization remain separate unchecked gates below.
- [x] The opt-in V8.5 T candidate has a hash-bound project-authored mesh,
  five-group visual lock, all-14-animation review, real Apple M4 Pro GPU
  evidence, and a complete owner-signing template. It remains separate from
  the release/default selector and excluded pending the unchecked gates below.
- [x] The opt-in V8.6 R7.2 T candidate has completed its final multi-angle and
  all-14-animation strips, exact official 4.7.2 four-platform candidate export,
  mounted-PCK probe, local universal macOS release smoke, baseline/SwiftShader
  Web QA, 138/138 full regression suite, and independent code review. The
  official Forward+/Metal A1/B1/B2/A2 R7 campaign now passes on Apple M4 Pro:
  V8.6 aggregate mean/p95 is 7.721/8.066 ms versus V8.5 7.799/8.135 ms
  (-1.00%/-0.85%), with all repeatability and 16.67 ms maximum gates green.
  The immutable provenance and an independent byte-identical gate rerun are
  recorded in the convergence specification. An initial 24 GiB
  preflight failed without creating a root; after macOS reclaimed space, A1
  captured successfully but its 9.745658-second authoritative TOC envelope was
  rejected by the old exact-duration tolerance before B1. That immutable root
  is harness-validation-inconclusive and supplies no GPU verdict; at that point
  all four sequences had to restart under the bounded-envelope contract. A
  later R6 A1 also completed but stopped before B1 when seven legal nullable Frame
  sentinels were misclassified as malformed. That root remains immutable;
  read-only reanalysis proves zero overlap with its 300-frame window and exact
  row accounting, and the parser/gates now have fail-closed regressions. Those
  failed attempts remain historical and do not replace the successful R7 root.
  The hash-bound owner-signing template is prepared but remains unsigned under
  the separate account/rights gate below.
- [ ] Native Windows and Linux release smoke is green for the exact candidate
  on those operating systems. The new PE/ELF artifacts and byte-identical PCK
  are prepared for transfer. An offline Ubuntu amd64 container smoke passes
  under Apple-Silicon emulation, but that and cross-exporting on macOS are not
  native/minimum-spec target evidence. An exact commit-bound three-OS CI matrix
  is prepared but has not been pushed or run. Historical remote runs do not
  prove this candidate.

## Steamworks/account gates

- [ ] Complete Steamworks partner onboarding, bank/tax/identity checks, and pay
  the Steam Direct fee.
- [x] Repository release track is selected as a separate Steam Demo App
  associated with a base game App.
- [ ] Obtain the real App ID and unique Windows/Linux/macOS depot IDs.
- [ ] Enter supported operating systems, launch options, install folders, and
  branch/package access in Steamworks.
- [ ] Complete and owner-sign
  `asset-rights-attestation-v8.6-template.md` for R7.2 (or the preserved V8.5
  template if that older candidate is selected), then archive the signed record
  with an exact SHA-256. Project-authored audio now
  has deterministic source and exact hashes, while generated Meshy/Tripo
  development models are non-shipping; Steam key-art inputs and contributor
  authority still require owner confirmation in `asset-rights-register.md`.
- [ ] Complete and owner-sign the content survey, including the pre-generated AI
  disclosure in `content-survey-draft.md`.
- [ ] Choose pricing, supported territories, release date/time, support email,
  developer/publisher names, privacy policy, and any required EULA.
- [ ] Upload store copy and graphical assets, then preview every language and
  crop in Steamworks.

## Build/distribution gates

- [ ] Sign the Windows build if the owner adopts a code-signing certificate.
- [ ] Sign and notarize the 64-bit universal macOS app with the owner's Apple
  Developer ID; tick Steamworks notarization metadata only after verification.
- [ ] Stage depots with the real IDs, inspect `steam-stage-manifest.json`, then
  run SteamPipe in preview mode before any live upload.
- [ ] Upload to a private beta branch and install each platform through the
  Steam client—not directly from the export directory.
- [ ] Confirm clean install, update, uninstall, save persistence, offline start,
  controller prompts, overlay compatibility, and executable permissions.
- [ ] Run real minimum-spec Windows/Linux/macOS tests and at least one physical
  1280x800 Steam Deck session. Automated 1280x720 minimum-display and 1280x800
  desktop layout regressions are useful evidence but are not hardware or Deck
  results. Do not claim Steam Deck Verified before Valve grants it.
- [ ] Complete six-family human play sessions for readability, controls,
  difficulty, photosensitivity, and jelly appearance; automation cannot replace
  this gate.

## Valve/timing gates

- [ ] Publish the Coming Soon page for at least the current required minimum
  period (Steam currently documents two weeks for new products).
- [ ] Account for any Steam Direct first-title waiting period (currently 30 days
  after fee payment where applicable).
- [ ] Submit both store presence and build for review at least seven business
  days before the intended release; resolve every Valve request.
- [ ] After approval, perform a final private-branch launch rehearsal and verify
  the public release controls, packages, price, date, and localized page.
- [ ] Owner explicitly authorizes pressing Steamworks “Release App”.

Official references:

- <https://partner.steamgames.com/steamdirect?l=english>
- <https://partner.steamgames.com/doc/gettingstarted/onboarding>
- <https://partner.steamgames.com/doc/store/coming_soon?language=english>
- <https://partner.steamgames.com/doc/store/Review_Process>
- <https://partner.steamgames.com/doc/sdk/uploading>
