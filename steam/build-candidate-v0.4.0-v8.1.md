# IMMUNE v0.4.0 V8.1 local Steam build candidate

Built: 2026-09-01

Artifact source commit:
`52e05f2562470bc6cbe6db505f8df7ded3f53bf0`

Release-validator follow-up commit:
`695fd3181abbdd15d45e8e26686a9308f8c07add`

This is the current local V8.1 candidate record. It is not a Steam upload,
Valve approval, notarized distribution, tag, or public release. The validator
follow-up changes only repository release tooling/tests; it does not change the
Godot project or the artifact bytes built from the source commit above.

All four exports were built sequentially with official Godot
`4.7.2.stable.official.ed1daf0bf` and matching templates. The official macOS
editor download was verified against SHA-256
`c58a24e31d720be9d62f60cb5627c4e695fb72f21b0cfe1bc9ccaa9a3b3ba63e`
before use.

## Exact 14-file artifact inventory

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `IMMUNE-windows.exe` | 109245952 | `198e8e41c131937abf58676e18de522a6612a96885309512609036ec994c2832` |
| `IMMUNE-windows.pck` | 58026520 | `77e8078c5e22b4195082736806ca1680d22421ce4f47c94567853c6eb5c7093b` |
| `IMMUNE-linux.x86_64` | 73519416 | `d9f79ab89b5ae369aeed11c6052d402e8218cd503bf85b4a235f9c30c46a7c63` |
| `IMMUNE-linux.pck` | 58026520 | `77e8078c5e22b4195082736806ca1680d22421ce4f47c94567853c6eb5c7093b` |
| `IMMUNE-macOS.zip` | 117466869 | `cb7b0f92292586e80bd4f1acd0c2638d2139b102e31dc458797f24f06741e206` |
| `web/index.html` | 5438 | `044ab854538d2066cc72be51b8b9f90c5917330841556a1773fd147004b713f6` |
| `web/index.js` | 279815 | `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba` |
| `web/index.pck` | 58026520 | `77e8078c5e22b4195082736806ca1680d22421ce4f47c94567853c6eb5c7093b` |
| `web/index.wasm` | 39514754 | `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |
| `web/index.audio.worklet.js` | 7298 | `5b476a9c9ce642c0ee4256436d1bc31d9c38f868aca0f9a8e2a57c18d2dec2a3` |
| `web/index.audio.position.worklet.js` | 2973 | `be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8` |
| `web/index.png` | 21443 | `3cb4495c0b98dfbe4b663cbf2b6836473572339beb66d902367893162a70be0e` |
| `web/index.icon.png` | 918785 | `28372b54254dbba52ae42da7a4fd706e3217c82552ea1c9c7f07db2f56403e65` |
| `web/index.apple-touch-icon.png` | 41952 | `eb018a7f2ac08a54c8e41c618af32e66371fcb947a8b9ca61179d51016de03e0` |

The Windows, Linux, and Web PCKs are byte-identical. PCK policy checks 534
directory entries, requires authored jelly bytecode, the T/B logical scene
remaps, and six compiled reference-body scenes. It rejects any B/M Meshy or T
Tripo/fix resource. The generated development models remain in source/history
but are not distributed.

## Verification evidence

- Two official Godot 4.7.2 imports and the isolated source smoke pass. The
  exact marker reports six missions, six families, six active skills, six
  encounters, authored T/B/M/N/A/D bodies, fizzy T/B/M/N/A/D profiles, and
  `gel_look=v8_1`.
- Root release tools pass `64/64`; release audio, Steam graphical assets,
  translation/catalog, strict artifact inventory, repository readiness, and
  `git diff --check` pass.
- `validate_release_contract.mjs` accepts exactly these 14 files. The hardened
  `validate_steam_readiness.mjs` accepts their PCK policy and reports seven
  publisher-controlled gate groups still open.
- Exported-Web QA in `outputs/v8.1-final-web-qa/report.json` completes research
  -> mission selection -> family B -> combat -> mobile duty -> Pause. Metal at
  1600x900 reports `60.003` mean / `59.524` p05 FPS with no long frames.
  Four-times CPU throttle plus SwiftShader at 1280x720 reports `12.735` /
  `11.990`; this is compatibility stress, not minimum-spec hardware evidence.
- Exact macOS evidence is
  `outputs/v8.1-final-macos-smoke-52e05f2/macos.json` (SHA-256
  `e61e35b0f087d099567f1bdd1daa76c816b54e1f4859c187587acb2bfb0f4ac5`).
  It binds the clean source commit, ZIP, and runtime log. The app passes strict
  ad-hoc signature verification, bundle/version/icon checks, universal
  `arm64+x86_64`, required Steam-overlay entitlements, no App Sandbox, and
  `RELEASE_SMOKE_OK platform=macOS nodes=200`.
- Nine shipping audio files are project-synthesized, checksum-locked, and
  documented in `godot/immune/audio/AUDIO_PROVENANCE.md`. The six current
  1920x1080 Steam screenshots are real V8.1 gameplay captures covering all six
  families and missions; exact hashes are in `steam/assets/README.md`.

## Preservation

- `steam/build-candidate-v0.4.0.md` remains the historical V5.4 record.
- The prior intermediate 14-file directory is preserved as the ignored,
  recoverable archive
  `godot/immune/build/history/v8-1-intermediate-5bed69d.tar.zst` (264798859
  bytes, SHA-256
  `5ddcdc3b589a4233ef7999c9da24bd1402065bc6473da88fb766875cbc3ff702`).
  Its zstd integrity and exact 14-file tar inventory were verified before the
  current release directory was rebuilt.
- Earlier V5/V6/V7/V8 source checkpoints, look selectors, captures, campaign
  bundles, and history directories were not removed.

## Deliberately open publisher gates

- Windows and Linux executables have not launched natively for this exact
  source commit. PE/ELF structure and PCK identity pass locally, but only native
  runners can close these two runtime gates.
- macOS is ad-hoc signed. The machine has no Developer ID Application identity
  or notary profile; Developer ID signing, hardened-runtime review, Apple
  notarization, and ticket verification remain owner-controlled work.
- Real base-game/demo App IDs, depot IDs, Steamworks onboarding, private-branch
  packages, SteamCMD preview/upload, and Steam-client installs are absent. No
  synthetic IDs are represented as publisher evidence.
- The owner must sign the asset/marketing-rights attestation and content survey,
  approve the OpenAI-generated key-art inputs/terms, contributor authority,
  bilingual copy, privacy/support metadata, and exact final store preview.
- Real minimum-spec Windows/Linux/macOS, physical Steam Deck, and independent
  human motion/readability/accessibility playtests remain required.
- Valve store/build review, the Coming Soon timing requirement, and explicit
  owner authorization to use the final release control remain external.

Do not tag, push, upload, submit, notarize, or press Steamworks release controls
until `release-checklist.md` is supported by real archived evidence and the
owner explicitly authorizes those actions.
