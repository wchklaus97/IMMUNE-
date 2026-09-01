# IMMUNE Steam release candidate

This directory contains the repository-controlled material for a Steam
submission candidate. It does not contain the Steamworks SDK, credentials,
App/depot identifiers, signing identities, or an uploaded build.

## Contents

- `store-page.en.md` and `store-page.zh_HK.md`: reviewed store-copy drafts;
- `content-survey-draft.md`: owner-review draft for Steam's content survey,
  including known pre-generated AI content;
- `asset-rights-register.md`: fail-closed provenance register for every major
  shipping asset class;
- `privacy-notice-draft.md`: draft for the offline demo's public privacy page;
- `steamworks-setup.md`: exact separate-Demo-App launch/depot handoff;
- `publisher-inputs.example.json`: deliberately incomplete schema for the
  account owner's IDs, evidence records, and attestations;
- `THIRD_PARTY_NOTICES.txt` and `GODOT_COPYRIGHT.txt`: redistribution notices
  copied into every native depot together with the Noto Sans HK OFL;
- `build-candidate-v0.4.0.md`: preserved historical V5.4 artifact record; the
  current V8.1 record is created only after a clean source commit and rebuild;
- `assets/`: exact-dimension store/library art, icons, six real 1920x1080
  gameplay screenshots, source art, and provenance notes;
- `release-checklist.md`: automated gates and the remaining account, human,
  legal, platform, review, and timing gates.

## Validate the submission assets

```sh
npm run validate:steam-assets
npm run test:tools
npm run validate:steam-readiness -- \
  --artifacts=godot/immune/build/releases
```

The asset validator reads PNG, JPEG, and ICNS headers directly, checks every
required size, proves that the library logo contains transparent pixels, and
requires at least five 16:9 gameplay screenshots at 1920x1080 or larger. The
readiness gate also validates the strict 14-file release inventory, licence and
handoff files, offline runtime surface, and shipping/excluded T/M model policy
inside the PCK.

## Stage native depots without uploading

First build and validate the Windows, Linux, and macOS artifacts. Then replace
the bracketed values below with the identifiers issued by Steamworks:

```sh
npm run prepare:steam -- \
  --artifacts=godot/immune/build/releases \
  --out=outputs/steam-stage-v0.4.0 \
  --app-id=<APP_ID> \
  --windows-depot=<WINDOWS_DEPOT_ID> \
  --linux-depot=<LINUX_DEPOT_ID> \
  --macos-depot=<MACOS_DEPOT_ID>
```

`prepare:steam` rejects placeholders, duplicate/non-numeric IDs, missing or
empty artifacts, symlinks, unsafe macOS ZIP entries, and an existing output
directory. It emits checksummed content, the three required licence records,
and VDF files with `preview=1`; it never invokes `steamcmd`, logs in, or uploads
anything. Staging is transactional: a failed run removes its private temporary
directory and never leaves the requested output looking complete. Keep the
Steamworks SDK, account name, password, guard code, signing
credentials, and completed publisher-input file outside this repo.

After the owner has resolved every external gate, copy
`publisher-inputs.example.json` outside the repository, fill it with real IDs,
the exact candidate commit, absolute paths to archived evidence files, and the
SHA-256 of every evidence file, then run:

```sh
npm run validate:steam-readiness -- \
  --artifacts=godot/immune/build/releases \
  --publisher-inputs=/absolute/private/path/publisher-inputs.json
```

The checked-in example is intentionally rejected. The validator opens every
evidence path, rejects symlinks and empty files, verifies every SHA-256, checks
that the three native-smoke records bind the same clean commit/version, and—if
artifacts are supplied—cross-checks their bytes and hashes. Public release
remains a separate owner decision.

## Submission boundary

This handoff targets a **separate Steam Demo App** associated with a future base
game App. The next owner-controlled actions are to complete onboarding and the
content survey, resolve every blocked/conditional asset-rights row, enter real
base/demo/depot IDs, sign and notarize macOS, run native Windows/Linux evidence,
preview SteamPipe, upload to a private branch, install through the Steam client,
and submit the demo page and build to Valve. See `steamworks-setup.md` and
`release-checklist.md` before treating a staged depot as publishable.

Current official references:

- <https://partner.steamgames.com/doc/store/assets>
- <https://partner.steamgames.com/doc/store/assets/rules>
- <https://partner.steamgames.com/doc/gettingstarted/contentsurvey?language=english>
- <https://partner.steamgames.com/doc/sdk/uploading>
- <https://partner.steamgames.com/doc/store/Review_Process>
- <https://partner.steamgames.com/doc/store/coming_soon?language=english>
