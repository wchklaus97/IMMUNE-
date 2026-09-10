# Steamworks setup handoff — IMMUNE demo

This repository is prepared for a **separate Steam Demo App**, associated with a
base game App in Steamworks. Steam demos use their own App ID, depots, build,
store configuration, and release checklist. The account owner may choose a
different commercial track, but must update all records consistently before
staging.

## Launch options

| Operating system | Executable | Arguments | Architecture |
| --- | --- | --- | --- |
| Windows | `IMMUNE-windows.exe` | none | x86-64 |
| Linux / SteamOS | `IMMUNE-linux.x86_64` | none | x86-64 |
| macOS | `IMMUNE.app` | none | universal arm64 + x86-64 |

Use one unique depot per platform. The staging tool preserves the Linux execute
bit, expands the macOS ZIP into the depot, places licence notices beside the
application, rejects symbolic links, records SHA-256 checksums, and generates
SteamPipe VDFs with `preview=1`. It never logs in or uploads.

## Account-owner sequence

1. Create/identify the base game and associated Demo App, then record the real
   Demo App ID and three unique depot IDs in a private publisher-input file.
2. Configure the three launch options above, supported operating systems,
   English and Traditional Chinese store languages, depots, packages, and demo
   association.
3. Resolve every blocked/conditional row in `asset-rights-register.md`; sign the
   content-survey draft and publish the final privacy/support URLs.
4. Developer-ID sign and notarize the macOS app. It already requests the two
   Steam overlay entitlements and excludes App Sandbox. Mark Steamworks' 64-bit
   and notarized checkboxes only after inspecting the final signed app.
5. Run `npm run prepare:steam -- ...` with real IDs into a new empty directory.
   Inspect `steam-stage-manifest.json`, every content directory, and every VDF.
6. Run SteamCMD's app build in preview mode first. Only an authorized owner may
   remove/override preview mode and upload.
7. Assign the uploaded build to a password-protected beta branch and grant the
   correct testing package. Install through the Steam client on Windows, Linux,
   and macOS.
8. Verify launch, overlay, controller, offline start, save persistence, update,
   uninstall/reinstall, permissions, and clean-machine dependencies. Perform a
   real 1280x800 Steam Deck session; only Valve can grant Deck Verified status.
9. Submit the Demo store page and build for Valve review. Public release remains
   an explicit account-owner action.

Official references:

- <https://partner.steamgames.com/doc/store/application/demos>
- <https://partner.steamgames.com/doc/store/application/platforms>
- <https://partner.steamgames.com/doc/sdk/uploading>
- <https://partner.steamgames.com/doc/store/Review_Process>
