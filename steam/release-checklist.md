# Steam release checklist

Updated: 2026-09-01. “Repository complete” means the source tree can produce and
validate a submission candidate. It does not mean Valve has approved the page or
build, nor that the product is publicly released.

## Repository-controlled gates

- [x] Six playable families, six missions, three combat phases, and permanent
  research progression are present.
- [x] Six cooldown-based active skills and six authored encounter patterns are
  covered by the Godot smoke contract.
- [x] Keyboard/gamepad actions, four-action desktop HUD, two-by-two narrow HUD,
  touch movement, safe-area, pause, and bilingual UI contracts exist.
- [x] V5.3 jelly lighting/material candidate passes the bounded light probe and
  automated runtime smoke.
- [x] Current Steam store/library/icon dimensions are represented by checked-in
  assets and a fail-closed validator.
- [x] Six 1920x1080, 16:9, actual-gameplay screenshots are checked in.
- [x] English and Traditional Chinese store-copy drafts exist.
- [x] Known pre-generated AI content has a content-survey disclosure draft and
  local provenance references.
- [x] Depot staging rejects placeholders, unsafe inputs, missing files, and
  credentials; generated VDFs remain in preview mode and do not upload.
- [x] Final all-tool, translation, UI, import, smoke, balance, responsive,
  performance, and release-artifact regression is green for the exact candidate
  commit.
- [x] Windows, Linux, macOS, and Web artifacts are rebuilt from that exact
  candidate and checksum-recorded.
- [x] Native macOS release smoke is green for the exact local candidate:
  ad-hoc signature, bundle/version/icon, arm64+x86_64, and the 200-node runtime
  marker all pass.
- [ ] Native Windows and Linux release smoke is green for the exact candidate
  on those operating systems. Local headers/artifacts pass, but the current
  V5.2 remote run is historical evidence only; V5.3 has not been pushed or
  uploaded.

## Steamworks/account gates

- [ ] Complete Steamworks partner onboarding, bank/tax/identity checks, and pay
  the Steam Direct fee.
- [ ] Decide whether this is the full product App or a separate Steam demo App.
- [ ] Obtain the real App ID and unique Windows/Linux/macOS depot IDs.
- [ ] Enter supported operating systems, launch options, install folders, and
  branch/package access in Steamworks.
- [ ] Verify ownership/licensing for every game and marketing asset.
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
- [ ] Run real minimum-spec Windows/Linux/macOS tests and at least one 1280x800
  Steam Deck session. Do not claim Steam Deck Verified before Valve grants it.
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
