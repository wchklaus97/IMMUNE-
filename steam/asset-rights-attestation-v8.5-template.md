# IMMUNE V8.5 owner asset-rights attestation

- Status: **AWAITING OWNER SIGNATURE**
- Prepared: 2026-09-02
- Scope: opt-in T-cell V8.5 promotion candidate and the current Steam key art

This document is a signing template and evidence checklist, not legal advice.
It does not become an attestation until an authorized owner completes every
applicable blank, selects an explicit decision, signs, dates, and archives the
signed record. The signed copy should be kept outside the public repository and
bound to `publisher-inputs.json` by its absolute path and SHA-256.

## Candidate identity

- Repository: `wchklaus97/IMMUNE-`
- Candidate selector: exact `v8_5`, family T only
- Current release/default selector: `v8_3` (unchanged)
- Candidate mesh:
  `godot/immune/characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb`
- Mesh SHA-256:
  `8f14cfe59a508df413e4d53218f30bbf316e7e5d31e42154b2916a0bd5669294`
- Deterministic builder:
  `tools/meshy/build_t_v8_5_authored_sculpt.py`
- Builder SHA-256:
  `7f9ae79363244d0cf30ecf3d6f207ec777f189cf4c31bf00ad1496a8014ec8e5`
- Candidate commit to be approved: `________________________________________`

The builder uses numeric implicit-shape parameters. It does not ingest concept
pixels, provider meshes, textures, or image-to-3D output. That implementation
fact does not remove the need to confirm rights to the visual references used
for artistic direction.

## Exact V8.5 visual-reference inventory

| Role | Repository file | SHA-256 | Owner/source evidence |
| --- | --- | --- | --- |
| Primary appearance reference | `godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png` | `3164ea9567836f98f1fcc96fb2ff0058495b91268f2f1e3ead298a24eab9a65c` | `____________________________` |
| Secondary shape reference | `godot/immune/characters/concepts/base-cell-line-v2/CHAR-BASE-T.png` | `8916ea0ba811d35142f38f55e651af6a240b494601db991218fcfb90a4298e40` | `____________________________` |
| Secondary raw reference | `godot/immune/characters/concepts/base-cell-line-v2/CHAR-BASE-T-raw.png` | `7507f10a9f5ace150cc41ba73c1d8835284442182fcd7ccb1069afe1e9fce494` | `____________________________` |
| Secondary fixed reference | `godot/immune/characters/concepts/CHAR-BASE-T-3d-fixed.png` | `bf0971939cbd7f19e482d4ed9c782d3fa36ad8c13de156dc670d99549ab18680` | `____________________________` |
| Secondary mobile reference | `godot/immune/characters/concepts/CHAR-BASE-T-3d-mobile.png` | `0c34616bef01adaf2c78c766f7ea826021eb9dd2c7ffa81ef50e4bfe04dae253` | `____________________________` |

For each row above, attach or identify the creator, creation date, generating
provider/account where applicable, original prompt/task record where available,
input-image authority, applicable commercial terms, and any restrictions.

## Exact material and marketing inventory

| Role | Repository file | SHA-256 | Known status |
| --- | --- | --- | --- |
| CC0 orange-peel height source | `godot/immune/characters/gel/jelly_micro_height.png` | `25ba40fcb8a6d800fc1ffe4747a4dadad95593fc8d8f3299aed5eef7888fc9a6` | ProcTexture CC0 record checked in |
| Steam landscape source art | `steam/assets/source/immune-key-art-landscape-v1.png` | `304cfbdb4b07071e456f38719377462078699d410df0b42a85c6592e5e15c33c` | OpenAI-generated for this project; account/input authority requires owner confirmation |
| Steam portrait source art | `steam/assets/source/immune-key-art-portrait-v1.png` | `4e5dfaf7424c1f8d861665fb22f09bc8e8742de3398a1c2caf460e28b4bcdd9c` | OpenAI-generated for this project; account/input authority requires owner confirmation |
| Code-native wordmark | `steam/assets/source/immune-wordmark.svg` | `a5d8c6f027528ceeb28881af31a2fbd1fb24d52521ff45450438c56fafb6b330` | Project-authored; contributor authority requires owner confirmation |

## Development assets that remain excluded

This signature does not silently promote historical provider experiments.
Unless separately cleared in writing, all Meshy/Tripo source models, embedded
textures, rejected variants, and the V8.4 Tripo-derived single-mass model remain
development-only and excluded by the release preset. The V8.5 candidate also
remains excluded until the affirmative V8.5 decision below is signed and a new
release candidate is rebuilt and audited.

## Owner confirmations

The authorized signer should initial every applicable statement:

- [ ] I have authority to make these confirmations for the project and every
  identified contributor has granted the project the necessary rights.
- [ ] Every V8.5 visual-reference image listed above is owned by the project or
  used under terms permitting this commercial game, its derivatives, and its
  marketing; supporting evidence is attached.
- [ ] The current OpenAI-generated Steam key art was made through an authorized
  account, every supplied input/reference was authorized, and its applicable
  terms permit the intended commercial use; supporting evidence is attached.
- [ ] The project-authored V8.5 geometry, shaders, runtime materials, wordmark,
  UI, localization, deterministic audio, and other shipping contributions may
  be commercially distributed by the project.
- [ ] Third-party notices and the CC0/OFL/MIT records identified in
  `steam/asset-rights-register.md` will remain with the appropriate depots.
- [ ] Historical Meshy/Tripo experiments and every other explicitly excluded
  asset will remain out of shipping builds and marketing unless separately
  cleared and recorded.
- [ ] I reviewed `steam/content-survey-draft.md` and will submit an accurate
  generative-AI disclosure for the exact final build and store page.
- [ ] I understand that this rights decision does not replace platform testing,
  code signing, notarization, Steamworks configuration, Valve review, or final
  release authorization.

## Explicit decisions

V8.5 commercial promotion (select one):

- [ ] **APPROVE** the exact V8.5 candidate identified above for inclusion in a
  newly built commercial release candidate, subject to the remaining technical
  and platform gates.
- [ ] **DO NOT APPROVE**; keep V8.5 development-only and excluded.

Current Steam key art (select one):

- [ ] **APPROVE** the two exact key-art files identified above for commercial
  Steam store/library derivatives.
- [ ] **DO NOT APPROVE**; replace them before submission.

## Evidence attachments

| Evidence | File/archive reference | SHA-256 or record ID |
| --- | --- | --- |
| Reference-image creation/licence records | `____________________________` | `____________________________` |
| OpenAI account/task/terms record | `____________________________` | `____________________________` |
| Contributor grants or employment/assignment record | `____________________________` | `____________________________` |
| Other restrictions or approvals | `____________________________` | `____________________________` |

## Signature

- Legal name: `______________________________________________________________`
- Role/capacity: `___________________________________________________________`
- Organization: `____________________________________________________________`
- Signature: `________________________________________________________________`
- Date (YYYY-MM-DD): `________________________________________________________`
- Signed evidence file: `_____________________________________________________`
- Signed evidence SHA-256: `__________________________________________________`
