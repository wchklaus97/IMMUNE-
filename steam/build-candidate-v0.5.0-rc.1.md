# IMMUNE v0.5.0-rc.1 V8.6 promotion candidate

Built and verified: 2026-09-04

Artifact source commit:
`2f61c39187b253bb72d87d4a79a5c24b6ede6d35`

Authoritative GitHub Actions run:
<https://github.com/wchklaus97/IMMUNE-/actions/runs/33875825213>

This is an unpublished release-candidate record. It is not a Git tag, GitHub
Release, notarized distribution, Steam upload, Valve approval, or public
release. Documentation-only commits after the source commit do not alter the
recorded game source or artifact bytes.

All four release exports were built sequentially with official Godot
`4.7.2.stable.official.ed1daf0bf`. The run completed the main validation/export
job plus native release and preserved-candidate smoke on Ubuntu, Windows, and
macOS: seven jobs total, all successful.

## Exact 14-file remote release inventory

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `IMMUNE-windows.exe` | 109245952 | `83186b2342c9a76290eeaf44d1166a06a9c65ba5613543382ffadabe65cb9fda` |
| `IMMUNE-windows.pck` | 58246448 | `fd8afee9f8653acfd8a13f16dd0ab10e88a1dcae72ae8e64dd4317058d5452d1` |
| `IMMUNE-linux.x86_64` | 73519416 | `d9f79ab89b5ae369aeed11c6052d402e8218cd503bf85b4a235f9c30c46a7c63` |
| `IMMUNE-linux.pck` | 58246448 | `fd8afee9f8653acfd8a13f16dd0ab10e88a1dcae72ae8e64dd4317058d5452d1` |
| `IMMUNE-macOS.zip` | 117632113 | `c82061938624e4db8a78ee008b411c4333d9b05aa0ad3dd7287eea9aff81d748` |
| `web/index.html` | 5438 | `ad16de0b7bf85814749083131d808effc9d5d05d46fd07d9ddcc6b053eed29eb` |
| `web/index.js` | 279815 | `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba` |
| `web/index.pck` | 58246448 | `fd8afee9f8653acfd8a13f16dd0ab10e88a1dcae72ae8e64dd4317058d5452d1` |
| `web/index.wasm` | 39514754 | `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |
| `web/index.audio.worklet.js` | 7298 | `5b476a9c9ce642c0ee4256436d1bc31d9c38f868aca0f9a8e2a57c18d2dec2a3` |
| `web/index.audio.position.worklet.js` | 2973 | `be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8` |
| `web/index.png` | 21443 | `3cb4495c0b98dfbe4b663cbf2b6836473572339beb66d902367893162a70be0e` |
| `web/index.icon.png` | 918785 | `28372b54254dbba52ae42da7a4fd706e3217c82552ea1c9c7f07db2f56403e65` |
| `web/index.apple-touch-icon.png` | 41952 | `eb018a7f2ac08a54c8e41c618af32e66371fcb947a8b9ca61179d51016de03e0` |

The Windows, Linux, and Web PCKs are byte-identical. Read-only revalidation of
the downloaded run accepts the exact 14-file release inventory, Steam
repository readiness, and the V8.6 PCK policy. The Linux-produced PCK contains
520 validated files, the exact SHA-bound R7.2 body, and no excluded R5, R6, R7,
or R7.1 body.

## Native evidence

| Platform | Evidence SHA-256 | Runtime marker |
| --- | --- | --- |
| Linux | `027c70dec80dd3360a9be204dbd1e6da76f6f9abf0c7c7a51ad82c6fbf21775e` | `RELEASE_SMOKE_OK platform=Linux nodes=200` |
| Windows | `870d92c44f87d274edba16f90d3ddc65c0e536ebccbf16fbb54df721df122657` | `RELEASE_SMOKE_OK platform=Windows nodes=200` |
| macOS | `e92f6e46145993d2aaffd380e431e183ed1481c243a2808b0a341ff451d29a71` | `RELEASE_SMOKE_OK platform=macOS nodes=200` |

Each evidence record reports `status=pass`, version `0.5.0-rc.1`, the exact
source commit above, a clean tracked tree, the corresponding target runner,
and hash/size bindings for its executable or bundle and PCK where applicable.
Windows metadata is file version `0.5.0.1` and product version
`0.5.0-rc.1`. macOS is universal `arm64+x86_64`, bundle short version `0.5.0`,
build `1`, and strictly ad-hoc signed for test launch only.

## Promotion evidence

- Shipping defaults to `v8_6`; all ordinary presets carry
  `v8_6_shipping` and inject only exact R7.2 raw geometry.
- A mounted shipping-PCK probe proves one body, one shell, one wet material,
  one shell material, all 14 animations, no loose burst, no build failure, and
  no fallback.
- A second mounted-PCK probe with `IMMUNE_GEL_LOOK=v8_3` proves exact V8.3
  rollback without any V8.4/V8.5/V8.6 body marker.
- The preserved V8.5 and V8.6 candidate presets and probes remain green.
- The full repository tool suite passes 139/139; the research-network UI passes
  53/53; translations, catalog, audio, Steam art, screenshot provenance, HUD
  layout, bounded campaign balance, and six-family gameplay regressions pass.
- The local Apple M4 Pro Web release pass records 60.000 mean / 59.524 p05 FPS.
  Remote GitHub Web evidence is intentionally compatibility-only SwiftShader
  evidence and is not presented as GPU or minimum-spec performance.
- The earlier formal Apple M4 Pro Forward+/Metal ABBA evidence remains the
  performance authority: V8.6 mean/p95 `7.721/8.066 ms`, both slightly better
  than the V8.5 baseline and below every locked ceiling.

The complete downloaded run is preserved locally, ignored by Git, under
`outputs/v8.6-promotion-rc1/remote-ci-33875825213/`. Local R1 and R2 preflight
exports, all earlier candidates, models, captures, and failed/successful GPU
evidence roots remain preserved.

## Deliberately open publisher gates

- The V8.6 rights attestation and content survey remain unsigned. No agent can
  sign for the rights holder or account owner.
- The macOS bundle is ad-hoc signed. Developer ID signing, notarization, and
  ticket verification are not complete.
- Real Steam App/depot IDs, onboarding, SteamPipe preview/upload, private-branch
  Steam-client installs, pricing/release metadata, and Valve review are absent.
- Physical minimum-spec machines, Steam Deck, and real human visual/gameplay/
  accessibility sessions remain external evidence gates.
- No tag, release, merge, upload, signing, notarization, submission, or public
  distribution was performed.

Do not represent this technical RC as storefront-ready until every unchecked
owner/platform gate in `release-checklist.md` is supported by archived evidence
and the owner explicitly authorizes the final publishing action.
