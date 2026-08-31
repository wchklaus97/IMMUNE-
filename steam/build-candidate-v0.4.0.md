# IMMUNE v0.4.0 local Steam build candidate

Built: 2026-09-01

Artifact source commit:
`80ae5affc90165871a73e11312d744fbaa57808d`

This record describes a local, repository-generated candidate. It is not a
Steam upload, a public release, or Valve approval. All four exports were rebuilt
sequentially from the source commit above with the official signed Godot
`4.7.2.stable.official.ed1daf0bf` editor and matching export templates. The
record itself is committed separately so documenting the build cannot change
the artifact source.

## Exact 14-file artifact inventory

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `IMMUNE-windows.exe` | 109245952 | `198e8e41c131937abf58676e18de522a6612a96885309512609036ec994c2832` |
| `IMMUNE-windows.pck` | 66860992 | `37ed4ef313318fb14e0756985ffbafdcfc3a76d9e6146b794ef8221afcd0f3c9` |
| `IMMUNE-linux.x86_64` | 73519416 | `d9f79ab89b5ae369aeed11c6052d402e8218cd503bf85b4a235f9c30c46a7c63` |
| `IMMUNE-linux.pck` | 66860992 | `37ed4ef313318fb14e0756985ffbafdcfc3a76d9e6146b794ef8221afcd0f3c9` |
| `IMMUNE-macOS.zip` | 126018596 | `26b4dae9213be78c8b65336113bb83215540c3b765a22cecff16ce73f401b594` |
| `web/index.html` | 5438 | `a5fca15408da8160cfc07bcc8fb442672f47fc0ae4ad088fd09796612eb97016` |
| `web/index.js` | 279815 | `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba` |
| `web/index.pck` | 66860992 | `37ed4ef313318fb14e0756985ffbafdcfc3a76d9e6146b794ef8221afcd0f3c9` |
| `web/index.wasm` | 39514754 | `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |
| `web/index.audio.worklet.js` | 7298 | `5b476a9c9ce642c0ee4256436d1bc31d9c38f868aca0f9a8e2a57c18d2dec2a3` |
| `web/index.audio.position.worklet.js` | 2973 | `be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8` |
| `web/index.png` | 21443 | `3cb4495c0b98dfbe4b663cbf2b6836473572339beb66d902367893162a70be0e` |
| `web/index.icon.png` | 918785 | `28372b54254dbba52ae42da7a4fd706e3217c82552ea1c9c7f07db2f56403e65` |
| `web/index.apple-touch-icon.png` | 41952 | `eb018a7f2ac08a54c8e41c618af32e66371fcb947a8b9ca61179d51016de03e0` |

## Exact-candidate verification

- `validate_release_contract.mjs` accepts exactly these 14 files and reports
  four coherent presets, version `0.4.0`, unpublished tag state, ad-hoc macOS
  signing, and a single-threaded Web export. The PCK inspection proves the clean
  shipping T marker is present and damaged/non-shipping comparison models are
  absent.
- `validate_steam_readiness.mjs` reports
  `repository-ready-publisher-gates-open`: 17 graphical assets, six gameplay
  screenshots, 13 rights hashes, and seven explicitly external gate groups.
- The macOS ZIP expands to a valid ad-hoc-signed universal `arm64+x86_64` app
  with bundle identifier `com.wchklaus97.immune`, version `0.4.0`, ICNS icon,
  no App Sandbox entitlement, and
  `RELEASE_SMOKE_OK platform=macOS nodes=200`. Machine-readable evidence is in
  `outputs/v5.4-release-hardening/native-smoke-macos-80ae5af.json` and binds the
  full source commit plus ZIP/log hashes.
- Exported-Web QA completes research -> mission selection -> family B -> combat
  -> mobile duty -> Pause in both profiles. Metal reports `119.998` mean /
  `101.010` p05 FPS at 1600x900. The explicit 4x CPU + SwiftShader profile
  reports `13.092` / `9.346` at 1280x720. Both have exact canvas fit, no page or
  request failure, and no unexpected browser warning. SwiftShader is
  compatibility stress, not a real lower-end-hardware benchmark.
- Final regression passes root tools `55/55`, research-network tests `53/53`,
  Meshy offline workflow `6/6`, two clean Godot imports, 628 translation rows,
  full content smoke, release smoke, strict release/readiness contracts, and
  `git diff --check`. The optional `sharp` package is absent, so the successful
  UI build skips only non-shipping JPG preview generation.
- Responsive evidence covers 360x800 and 390x844 with simulated safe insets,
  plus 1280x720, 1280x800, 1600x900, and 1920x1080 in both locales across
  Mission, Research, Combat, and Pause. Compact-landscape actions remain at
  least 44 physical pixels and critical copy remains at least 14 physical
  pixels. These automated desktop runs are not physical phone or Steam Deck
  evidence.
- The complete 36-pair 1x balance soak passes 36/36, 1,913.284 aggregate game
  seconds, all victories, one boss per run, increasing M01->M06 duration, and
  6-12 surviving core HP. It ran immediately before the clean tree was
  committed as `80ae5af`; because the report schema does not embed a Git SHA,
  this is truthfully retained as same-tree pre-commit evidence rather than
  described as cryptographically commit-bound evidence.
- Synthetic Steam staging was freshly regenerated from these artifacts using
  fixture IDs `4800000`-`4800003`. Its manifest checksums 22 native content
  files including all per-platform notices, preserves the Linux executable
  bit, renders `preview=1`, and records `upload_performed=false`. No SteamCMD,
  login, network upload, or credential was used.

## Deliberately open publisher gates

- This exact candidate has not run natively on Windows or Linux. Their PE/ELF
  headers, PCK sidecars, sizes, hashes, execute permission, and depot staging
  pass locally; native launch evidence needs those operating systems or an
  owner-authorized CI push.
- macOS remains ad-hoc signed. Developer ID signing and Apple notarization have
  not happened.
- Audio provenance and the shipping Tripo T model's original task/receipt/terms
  are absent; conditional marketing/asset rights still need owner confirmation.
- No real base/demo App IDs or depot IDs, Steamworks onboarding/payment/tax/bank
  completion, SteamCMD preview, private Steam-client install, store review,
  Coming Soon period, pricing/date/support metadata, or public-release approval
  exists.
- Real minimum-spec Windows/Linux/macOS, physical Steam Deck, real phone, and
  six-family human play sessions remain required. Automation is not relabelled
  as device, accessibility, or human-judgement evidence.

Do not tag, push, upload, submit, or press Steamworks release controls until the
owner completes `release-checklist.md` with real evidence and explicitly
authorizes that publishing action.
