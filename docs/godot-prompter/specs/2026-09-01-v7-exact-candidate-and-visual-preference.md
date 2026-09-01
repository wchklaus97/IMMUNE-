# V7 exact candidate and visual-preference handoff

Date: 2026-09-01
Status: exact local four-platform candidate verified; blinded human study ready;
publisher and real-human gates remain open

## Outcome

The additive V7 game source remains preserved at
`f9cb6609ec00f483cb33fda2223fe6d52ea1f379`. A later documentation-only
checkpoint, `5747a52c5c0466a12b5ff3fdd5e9c2fc92bab906`, was checked out cleanly and
used to export a new, non-overwriting four-platform candidate with official
Godot `4.7.2.stable.official.ed1daf0bf` and matching templates.

The exact artifact root is:

`godot/immune/build/releases/v7-exact-5747a52/`

The older `build/releases/web/`, `build/releases/web-v7/`, V5/V6 outputs,
generated models, look selectors, and ignored evidence remain intact. No push,
tag, GitHub Release, notarization, Steam upload, or public distribution was
performed.

Current `main` later received the documentation-only V6 provenance correction
at `b97888119a4d1512830a55aaf8b555f9f016a21a`. That correction does not change
the game bytes and is not used to relabel the artifacts: the candidate remains
bound to exact commit `5747a52c5c0466a12b5ff3fdd5e9c2fc92bab906`.

## Exact artifact inventory

The release contract accepts exactly 14 files, version `0.4.0`, four export
presets, a single-threaded Web build, ad-hoc macOS signing, and an unpublished
tag state.

| File | SHA-256 |
|---|---|
| `IMMUNE-windows.exe` | `198e8e41c131937abf58676e18de522a6612a96885309512609036ec994c2832` |
| `IMMUNE-windows.pck` | `4836feecdafbd28aa811a6ad1200a4d289d3dc659f6a76ac8a22bcb746190646` |
| `IMMUNE-linux.x86_64` | `d9f79ab89b5ae369aeed11c6052d402e8218cd503bf85b4a235f9c30c46a7c63` |
| `IMMUNE-linux.pck` | `4836feecdafbd28aa811a6ad1200a4d289d3dc659f6a76ac8a22bcb746190646` |
| `IMMUNE-macOS.zip` | `6a5720c2f027ebc5631a2c10f63b054ba5bf997e162ef36e7b29319641c58f57` |
| `web/index.apple-touch-icon.png` | `eb018a7f2ac08a54c8e41c618af32e66371fcb947a8b9ca61179d51016de03e0` |
| `web/index.audio.position.worklet.js` | `be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8` |
| `web/index.audio.worklet.js` | `5b476a9c9ce642c0ee4256436d1bc31d9c38f868aca0f9a8e2a57c18d2dec2a3` |
| `web/index.html` | `d803e18a3aae20cb3433cedd187e1c060d141cbc5b5e4ad64a7d3a175bb60f6c` |
| `web/index.icon.png` | `28372b54254dbba52ae42da7a4fd706e3217c82552ea1c9c7f07db2f56403e65` |
| `web/index.js` | `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba` |
| `web/index.pck` | `4836feecdafbd28aa811a6ad1200a4d289d3dc659f6a76ac8a22bcb746190646` |
| `web/index.png` | `3cb4495c0b98dfbe4b663cbf2b6836473572339beb66d902367893162a70be0e` |
| `web/index.wasm` | `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |

## Native and Web evidence

The macOS ZIP passes deep/strict code-signature validation, bundle ID
`com.wchklaus97.immune`, version `0.4.0`, icon presence, universal
`x86_64 arm64` architecture inspection, and the Steam-overlay-compatible
non-sandbox entitlement check. A real launch from the extracted app ends with:

`RELEASE_SMOKE_OK platform=macOS nodes=200`

Hash-bound evidence is stored at
`outputs/v7-exact-5747a52/native-smoke/macos.json`. The signature is ad-hoc;
this is not Developer ID signing or notarization.

Exported-Web QA completes the ordered research -> mission -> B selection ->
combat -> mobile duty -> Pause open -> Pause close flow on both profiles:

| Profile | Viewport | Renderer | Mean FPS | p05 FPS | Result |
|---|---:|---|---:|---:|---|
| Baseline | 1600x900 | ANGLE Metal, Apple M4 Pro | 60.002 | 59.524 | pass, no warnings/errors |
| Compatibility stress | 1280x720, 4x CPU | SwiftShader | 12.000 | 10.000 | pass; allowlisted readback warnings |

The report is `outputs/v7-exact-5747a52/web-qa/report.json`. SwiftShader is a
software compatibility stress profile and is not minimum-spec hardware proof.
Windows and Linux artifacts pass structural/hash validation but still require
runtime smoke on their native target platforms.

## Blinded V5.1/V6/V7 visual-preference campaign

The reproducible campaign tool is
`tools/create_visual_preference_campaign.mjs`. It refuses overwrite, builds in
an atomic staging directory, rejects symlinks and unexpected files, validates
PNG signatures and dimensions, and writes a complete `SHA256SUMS` inventory.
Its tests cover counterbalancing, creation/verification, overwrite refusal, and
tamper detection.

The generated campaign is:

`outputs/visual-preference-campaigns/immune-v0.4.0-v5-v6-v7-5747a52/`

- campaign ID: `visual-preference-bc2edd0017f5e93c`;
- six participant kits and all six V5.1/V6/V7 order permutations;
- every version appears twice in every candidate position;
- 53 checksum-locked files;
- minimum three independent adult participants, six recommended;
- zero participant results included;
- participant pages and reports contain anonymous candidate IDs only;
- the version mapping, commits, and source hashes exist only in the private
  facilitator answer key.

The stimuli are bound to these preserved checkpoints:

| Look | Commit | 6144x2048 stimulus SHA-256 |
|---|---|---|
| V5.1 | `2d011b167e79a1d583d368c98ed3c07a41209d3e` | `e14af561209c21750a883b6948871f1faa7f7d4f24ec6cb488ee4be7c0dce303` |
| V6 | `c45c3eb07e8a944c9205dcf14d13ca4b3260c0df` | `36787074a03c9ef45a8439b483158f488f6c61f1216b370d47adee499736035c` |
| V7 | `f9cb6609ec00f483cb33fda2223fe6d52ea1f379` | `7c3540dda11788dd8919082df6fe16bc85a4239dff116bed6b9e8c36028435af` |

The target reference is the 1536x1024 banner artwork with SHA-256
`47a442b7a55dc28f204387d575e1d2f4ee26c389ca614c8b3f809a74b3cdda98`.

### Corrected stimulus and browser workflow

The initial front-only strip made the older T character visibly smaller and
could bias a texture study through framing. Distribution stopped before any
human run. A second, preserved composite was created with front views on the
upper row and equal-detail face close-ups on the lower row. The original strips
remain under `outputs/v7-visual-preference-assets/`; nothing was deleted.

Real in-app-browser QA then checked the offline participant page at desktop and
390x844 mobile widths. All four images load at their declared dimensions after
their sections enter the viewport, page-level horizontal overflow remains off,
the rating and summary grids collapse to one column on mobile, and both action
buttons remain 328px wide. The first health sample saw the third image pending;
HTTP, PNG, checksum, and viewport inspection proved this was the declared lazy
off-screen load, not corruption.

Interaction QA proves:

- incomplete export reports all missing groups inline and leaves 30 controls
  invalid;
- a synthetic completed response fills 18 scores and all 26 required controls,
  leaving zero invalid controls;
- export downloads a `status=complete`, `anonymous-local-only` JSON report;
- the downloaded report and rendered page contain no V5/V6/V7 label or commit;
- console warnings and errors remain empty at desktop and mobile widths.

The synthetic browser report is QA data only. It is not stored in the campaign,
not counted as a human response, and cannot be used to select a winning look.

## Regression matrix

| Gate | Result |
|---|---|
| Root release/tool tests | 58/58 pass |
| Research UI tests | 53/53 pass |
| Research UI production build | pass; optional Sharp JPEG previews skipped |
| Meshy offline paid-request safety | 6/6 pass; no API task or credit use |
| Catalog localization | 200 nodes, 406 generated rows pass |
| Translation CSV | 2 files, 628 rows pass |
| Playtest template | valid incomplete template |
| Steam graphical assets | 17 files, 6 screenshots, transparent logo pass |
| Steam repository readiness | pass with 7 external gate groups open |
| Exact release contract | 14 artifacts verified, unpublished, ad-hoc macOS signing |

## Reproduction

```sh
godot --headless --path godot/immune --export-release "Windows Desktop" \
  build/releases/v7-exact-5747a52/IMMUNE-windows.exe
godot --headless --path godot/immune --export-release "Linux/X11" \
  build/releases/v7-exact-5747a52/IMMUNE-linux.x86_64
godot --headless --path godot/immune --export-release "macOS" \
  build/releases/v7-exact-5747a52/IMMUNE-macOS.zip
godot --headless --path godot/immune --export-release "Web" \
  build/releases/v7-exact-5747a52/web/index.html
node tools/validate_release_contract.mjs \
  --artifacts=godot/immune/build/releases/v7-exact-5747a52
node tools/create_visual_preference_campaign.mjs \
  --verify=outputs/visual-preference-campaigns/immune-v0.4.0-v5-v6-v7-5747a52
npm run test:tools
```

## Honest remaining gates

1. Collect at least three independent adult preference reports, ideally all
   six counterbalanced kits, before choosing the shipping visual look.
2. Run Windows and Linux native smoke plus agreed minimum-spec Windows, Steam
   Deck, and physical-phone tests. Automated capture and SwiftShader do not
   substitute for real hardware.
3. Refresh and owner-approve storefront captures after the visual winner is
   accepted. If the winner changes source, rebuild every platform again from
   that exact approved commit into another non-overwriting directory.
4. Supply final rights/IDs, Developer ID and any required Windows signing,
   notarization credentials, Steamworks app/depot configuration, and owner
   authorization.
5. Complete Valve review and platform publishing. No credential, upload, tag,
   release, or public submission action has been performed here.

These are explicit human, hardware, publisher, and external-platform gates.
They are not silently reported as completed game-development work.
