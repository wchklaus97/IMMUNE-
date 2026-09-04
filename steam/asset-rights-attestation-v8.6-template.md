# IMMUNE V8.6 owner asset-rights attestation

- Status: **AWAITING OWNER SIGNATURE**
- Prepared: 2026-09-04
- Scope: V8.6 R7.2 promotion RC1 and current Steam key art

This is a signing template and evidence checklist, not legal advice. It is not
an approval until an authorized owner completes every applicable blank, makes
the explicit decisions below, signs and dates it, and archives the signed copy.
Keep the signed record outside the public repository and bind it to the final
`publisher-inputs.json` using its absolute path and SHA-256.

## Candidate identity

- Repository: `wchklaus97/IMMUNE-`
- Release identity: `0.5.0-rc.1`
- Shipping/default selector: exact `v8_6`; authored R7.2 geometry applies to
  family T only
- Preserved rollback selector: exact `IMMUNE_GEL_LOOK=v8_3`
- Candidate mesh:
  `godot/immune/characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb`
- Mesh SHA-256:
  `3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3`
- Complete transitive builder chain, in execution order:
  `tools/meshy/build_t_v8_5_authored_sculpt.py`,
  `tools/meshy/build_t_v8_6_authored_sculpt.py`,
  `tools/meshy/build_t_v8_6_authored_sculpt_r6.py`,
  `tools/meshy/build_t_v8_6_authored_sculpt_r7.py`,
  `tools/meshy/build_t_v8_6_authored_sculpt_r7_1.py`, and
  `tools/meshy/build_t_v8_6_authored_sculpt_r7_2.py`
- Builder SHA-256 values, in the same order:
  `7f9ae79363244d0cf30ecf3d6f207ec777f189cf4c31bf00ad1496a8014ec8e5`,
  `1750976daca5a9d50e9631303ec253c5a82227679a52e2a12d45f819486a3cec`,
  `a80bbdefe9221bc15e2e3cc8eefb44d284ac620b32146c38c8c6fa363faf6562`,
  `aa7ca2b5fda461a326c4e81e2b49dc26dfa7ae5ee46d19a2cba01206a38eee7a`,
  `8ab45c587982f8f3d46ba950eb0d62388d586dca670dd1332b80946e5297a1e5`,
  `4755d3a9e1f1a12f5144755b7bf66f86d08e4256d584e1469d3ee86c4d25d790`
- Candidate commit to approve: `________________________________________`
- Candidate export SHA-256: `___________________________________________`

The builder chain uses numeric project-authored implicit-shape parameters. It
does not ingest concept pixels, a provider mesh, a texture, or an image-to-3D
response. That implementation fact does not remove the need to confirm rights
to every visual reference used for artistic direction.

## Exact V8.6 visual-reference inventory

| Role | Repository file | SHA-256 | Owner/source evidence |
| --- | --- | --- | --- |
| Primary appearance reference | `godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png` | `3164ea9567836f98f1fcc96fb2ff0058495b91268f2f1e3ead298a24eab9a65c` | `____________________________` |
| Secondary shape reference | `godot/immune/characters/concepts/base-cell-line-v2/CHAR-BASE-T.png` | `8916ea0ba811d35142f38f55e651af6a240b494601db991218fcfb90a4298e40` | `____________________________` |
| Secondary raw reference | `godot/immune/characters/concepts/base-cell-line-v2/CHAR-BASE-T-raw.png` | `7507f10a9f5ace150cc41ba73c1d8835284442182fcd7ccb1069afe1e9fce494` | `____________________________` |
| Secondary fixed reference | `godot/immune/characters/concepts/CHAR-BASE-T-3d-fixed.png` | `bf0971939cbd7f19e482d4ed9c782d3fa36ad8c13de156dc670d99549ab18680` | `____________________________` |
| Secondary mobile reference | `godot/immune/characters/concepts/CHAR-BASE-T-3d-mobile.png` | `0c34616bef01adaf2c78c766f7ea826021eb9dd2c7ffa81ef50e4bfe04dae253` | `____________________________` |

For every row, attach or identify the creator, creation date, provider/account
where applicable, original prompt/task record where available, input-image
authority, applicable commercial terms, and restrictions.

## Material and marketing inventory

| Role | Repository file | SHA-256 | Known status |
| --- | --- | --- | --- |
| CC0 orange-peel height source | `godot/immune/characters/gel/jelly_micro_height.png` | `25ba40fcb8a6d800fc1ffe4747a4dadad95593fc8d8f3299aed5eef7888fc9a6` | ProcTexture CC0 record checked in |
| Steam landscape source art | `steam/assets/source/immune-key-art-landscape-v1.png` | `304cfbdb4b07071e456f38719377462078699d410df0b42a85c6592e5e15c33c` | OpenAI-generated for this project; owner must confirm account and input authority |
| Steam portrait source art | `steam/assets/source/immune-key-art-portrait-v1.png` | `4e5dfaf7424c1f8d861665fb22f09bc8e8742de3398a1c2caf460e28b4bcdd9c` | OpenAI-generated for this project; owner must confirm account and input authority |
| Code-native wordmark | `steam/assets/source/immune-wordmark.svg` | `a5d8c6f027528ceeb28881af31a2fbd1fb24d52521ff45450438c56fafb6b330` | Project-authored; contributor authority needs owner confirmation |

## Development assets that remain excluded

This signature does not promote historical provider experiments or rejected
geometry. Unless separately cleared and recorded, Meshy/Tripo source models,
embedded provider textures, V8.4's provider-derived remesh, V8.6 R5, R6, R7,
and R7.1 remain development-only and excluded. R7.2 is the only V8.6 raw body
included in the technical RC1 package. That package must not be commercially
distributed until the affirmative rights decision below is completed and the
remaining platform/release gates are satisfied.

## Owner confirmations

- [ ] I have authority to make these confirmations for the project, and every
  contributor has granted the necessary rights.
- [ ] Every V8.6 visual-reference image above is owned by the project or used
  under terms permitting this commercial game, derivatives, and marketing;
  supporting evidence is attached.
- [ ] The current OpenAI-generated key art was made through an authorized
  account, every supplied input/reference was authorized, and the applicable
  terms permit the intended commercial use.
- [ ] The project-authored R7.2 geometry, R4.1 shader/material work, 14
  animations, runtime code, UI, localization, deterministic audio, wordmark,
  and other shipping contributions may be commercially distributed.
- [ ] Notices and CC0/OFL/MIT records in
  `steam/asset-rights-register.md` will remain with the appropriate depots.
- [ ] Historical Meshy/Tripo experiments and all explicitly excluded assets
  will remain out of shipping builds and marketing unless separately cleared.
- [ ] I reviewed `steam/content-survey-draft.md` and will submit an accurate
  generative-AI disclosure for the exact final build and store page.
- [ ] I understand this decision does not replace platform testing, code
  signing, notarization, Steamworks configuration, Valve review, or release
  authorization.

## Explicit decisions

V8.6 R7.2 commercial promotion (select one):

- [ ] **APPROVE** the exact V8.6 candidate above for commercial distribution of
  the already-built technical RC, subject to the remaining platform gates.
- [ ] **DO NOT APPROVE**; block publication and rebuild shipping packages
  without V8.6.

Current Steam key art (select one):

- [ ] **APPROVE** the two exact key-art files above for commercial Steam
  store/library derivatives.
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
