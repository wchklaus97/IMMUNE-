# IMMUNE Steam release candidate

This directory contains the repository-controlled material for a Steam
submission candidate. It does not contain the Steamworks SDK, credentials,
App/depot identifiers, signing identities, or an uploaded build.

## Contents

- `store-page.en.md` and `store-page.zh_HK.md`: reviewed store-copy drafts;
- `content-survey-draft.md`: owner-review draft for Steam's content survey,
  including known pre-generated AI content;
- `build-candidate-v0.4.0.md`: exact local artifact hashes, validation evidence,
  and the remaining native-platform/signing boundary;
- `assets/`: exact-dimension store/library art, icons, six real 1920x1080
  gameplay screenshots, source art, and provenance notes;
- `release-checklist.md`: automated gates and the remaining account, human,
  legal, platform, review, and timing gates.

## Validate the submission assets

```sh
npm run validate:steam-assets
npm run test:tools
```

The asset validator reads PNG, JPEG, and ICNS headers directly, checks every
required size, proves that the library logo contains transparent pixels, and
requires at least five 16:9 gameplay screenshots at 1920x1080 or larger.

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
directory. It emits checksummed content plus VDF files with `preview=1`; it
never invokes `steamcmd`, logs in, or uploads anything. Keep the Steamworks SDK,
account name, password, guard code, and signing credentials outside this repo.

## Submission boundary

The next owner-controlled actions are to complete onboarding and the content
survey, choose whether this App ID represents the full product or a separate
demo, enter real IDs, sign/notarize where required, upload to a private branch,
test through the Steam client, and submit both store page and build to Valve.
See `release-checklist.md` before treating a staged depot as publishable.

Current official references:

- <https://partner.steamgames.com/doc/store/assets>
- <https://partner.steamgames.com/doc/store/assets/rules>
- <https://partner.steamgames.com/doc/gettingstarted/contentsurvey?language=english>
- <https://partner.steamgames.com/doc/sdk/uploading>
- <https://partner.steamgames.com/doc/store/Review_Process>
- <https://partner.steamgames.com/doc/store/coming_soon?language=english>
