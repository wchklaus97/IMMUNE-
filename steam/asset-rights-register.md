# IMMUNE asset-rights register

Updated: 2026-09-04. This is an evidence register, not legal advice or an owner
attestation. A `conditional` row must be resolved before commercial submission.

| Shipping material | Evidence | Status | Required owner action |
| --- | --- | --- | --- |
| Godot 4.7.2 engine/export templates | MIT text in `THIRD_PARTY_NOTICES.txt`; version-pinned `GODOT_COPYRIGHT.txt` | cleared for staging | Keep both files in every depot. |
| Noto Sans HK VF | `fonts/OFL.txt`; font SHA-256 `70172afd2cf0e045182787219b949e7798253982a36e364114757c09efd55477` | cleared for staging | Keep `NotoSansHK-OFL.txt` in every depot and do not misuse the reserved font name. |
| ProcTexture orange-peel height source | `characters/gel/jelly_micro_height.LICENSE.md`; checked-in PNG SHA-256 `25ba40fcb8a6d800fc1ffe4747a4dadad95593fc8d8f3299aed5eef7888fc9a6` | CC0, cleared | Preserve checksum/provenance record. |
| B-cell Meshy T2 development model | `characters/base_b/ASSET_PROVENANCE.md`; task `01a043a9-4884-7a6f-bd72-1a716f663403`; integrated GLB SHA-256 `c57cbf701c6ec66dfca69715e82ffe9339bc5ebf121fa05251f54157bab3100e` | non-shipping, excluded | Keep only as source/history evidence; do not use in builds or marketing without resolving its separate rights chain. |
| T-cell Tripo development model and embedded texture | `characters/base_t/ASSET_PROVENANCE.md`; GLB SHA-256 `4b969a424da09aad9dfb80b810e7ec6b7ce08db61cb54da7febc482b259dd105` | non-shipping, excluded | Keep only as source/history evidence; do not use in builds or marketing without the missing receipt and input rights. |
| T V8.4 single-mass derivative | `characters/base_t/ASSET_PROVENANCE.md`; GLB SHA-256 `169394df640604f6d5e1302f5ff82b444b088e924125b971441e713185b6f7bb` | development-only, excluded | It inherits the unresolved Tripo source rights. Keep the release-preset and PCK exclusion until the missing source receipt and input rights are verified. |
| T V8.5 project-authored sculpt candidate | `characters/base_t/ASSET_PROVENANCE.md`; deterministic builder SHA-256 `7f9ae79363244d0cf30ecf3d6f207ec777f189cf4c31bf00ad1496a8014ec8e5`; GLB SHA-256 `8f14cfe59a508df413e4d53218f30bbf316e7e5d31e42154b2916a0bd5669294`; `steam/asset-rights-attestation-v8.5-template.md` | project-authored geometry; development-only, excluded; awaiting owner signature | Complete the reference inventory, attach evidence, and sign an affirmative commercial-promotion decision before rebuilding any release candidate with V8.5. |
| T V8.6 R7.2 project-authored sculpt candidate | `characters/base_t/ASSET_PROVENANCE.md`; complete execution-order builder-chain SHA-256 values `7f9ae79363244d0cf30ecf3d6f207ec777f189cf4c31bf00ad1496a8014ec8e5`, `1750976daca5a9d50e9631303ec253c5a82227679a52e2a12d45f819486a3cec`, `a80bbdefe9221bc15e2e3cc8eefb44d284ac620b32146c38c8c6fa363faf6562`, `aa7ca2b5fda461a326c4e81e2b49dc26dfa7ae5ee46d19a2cba01206a38eee7a`, `8ab45c587982f8f3d46ba950eb0d62388d586dca670dd1332b80946e5297a1e5`, and `4755d3a9e1f1a12f5144755b7bf66f86d08e4256d584e1469d3ee86c4d25d790`; GLB SHA-256 `3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3`; `steam/asset-rights-attestation-v8.6-template.md` | project-authored geometry; opt-in technical candidate; excluded from ordinary shipping presets; awaiting owner signature | Complete the reference inventory, attach evidence, and sign an affirmative V8.6 commercial-promotion decision before rebuilding any commercial release candidate with R7.2. |
| T V8.5/V8.6 visual concept/reference set | Primary SHA-256 `3164ea9567836f98f1fcc96fb2ff0058495b91268f2f1e3ead298a24eab9a65c`; secondary SHA-256 values `8916ea0ba811d35142f38f55e651af6a240b494601db991218fcfb90a4298e40`, `7507f10a9f5ace150cc41ba73c1d8835284442182fcd7ccb1069afe1e9fce494`, `bf0971939cbd7f19e482d4ed9c782d3fa36ad8c13de156dc670d99549ab18680`, and `0c34616bef01adaf2c78c766f7ea826021eb9dd2c7ffa81ef50e4bfe04dae253`; exact paths in the signing templates | conditional; awaiting owner evidence and signature | Identify creator/provider/account and applicable commercial terms for every image; attach input-rights evidence and sign the selected candidate decision. |
| T/B/M/N/A/D authored procedural bodies and runtime materials | GDScript/shader source and repository history; release PCK gate requires authored T/B scenes and rejects generated hero meshes | project-authored | Owner confirms contributor authority and project licence. |
| Steam key art/capsules/library art | Landscape source SHA-256 `304cfbdb4b07071e456f38719377462078699d410df0b42a85c6592e5e15c33c`; portrait source SHA-256 `4e5dfaf7424c1f8d861665fb22f09bc8e8742de3398a1c2caf460e28b4bcdd9c`; generated for this project and locally composited; `steam/assets/README.md`; V8.5/V8.6 signing templates | conditional; awaiting owner signature | Confirm the generating account had authority over every reference/input, attach the provider record, and approve commercial use. |
| Wordmark, Steam icons, and UI symbols | SVG/code-native sources and repository history | project-authored | Owner confirms contributor authority. |
| Music and SFX in `godot/immune/audio/` | `audio/AUDIO_PROVENANCE.md`; deterministic source `tools/generate_release_audio.mjs`; nine exact hashes below | project-authored | Owner confirms contributor authority; retain generator, provenance, and checksum gate. |
| English and Traditional Chinese text | Checked-in source/localization tables; AI-assisted drafting disclosed | conditional | Human owner reviews accuracy, trademarks, and authority to publish. |

## Explicitly excluded from release packages

- `characters/base_m/CHAR-BASE-M-meshy-t2.glb`: retained as generation evidence;
  runtime M uses the authored project body.
- `characters/base_b/CHAR-BASE-B-meshy-t2.glb`: retained as generation evidence;
  runtime B uses the authored project body.
- `characters/base_t/CHAR-BASE-T-tripo-5k.glb` and its embedded-feature source
  texture: retained as development evidence; runtime T uses the authored body.
- `characters/base_t/CHAR-BASE-T-fix.glb` and matching `...fix...basecolor.jpg`:
  rejected damaged T variant.
- `characters/base_t/CHAR-BASE-T-v8-4-single-mass-r1.glb`: local watertight
  V8.4 review derivative; excluded until the source model's rights chain is
  resolved. Default V8.3 exports remain on the authored body.
- `characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb`: deterministic,
  provider-independent project-authored V8.5 candidate; excluded until owner
  concept/reference-rights and contributor-authority confirmation. Default
  V8.3 exports remain unchanged.
- `characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r5.glb`, `...r6.glb`,
  `...r7.glb`, and `...r7-1.glb`: preserved V8.6 development/rejected geometry;
  never runtime fallbacks and excluded from the V8.6 candidate PCK.
- `characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb`: exact opt-in
  V8.6 technical candidate; excluded from ordinary shipping and V8.5 presets
  pending owner signature and the remaining technical/platform gates.
- Concepts, tool renders, and development-only sprite runs covered by the
  export preset exclusion filters.

Commercial readiness remains fail-closed until every `conditional` or `blocked`
row has a dated owner decision and supporting record.

The current prepared owner package is
`steam/asset-rights-attestation-v8.6-template.md`; the earlier V8.5 template is
preserved. Both deliberately remain
unsigned in source control. After signing, archive the completed evidence
outside the public repository and enter its path and SHA-256 in the private
publisher-input file; do not change an unchecked owner assertion by automation.

## Project-authored audio inventory

These hashes bind the nine exact binaries to `audio/AUDIO_PROVENANCE.md` and the
checked-in deterministic generator. Godot `.import` metadata is intentionally
omitted because it is an import cache, not provenance.

| Shipping file | Bytes | SHA-256 |
| --- | ---: | --- |
| `audio/music/immune_pulse.ogg` | 33158 | `1daba74fd27ac64db650cda112689ac5b5a9ea4776a5d56b0f71b6d5474de3a4` |
| `audio/sfx/core_hit.wav` | 19448 | `41ae39ffb58e7fe3e1117cccb9d6e3c99afc790e0335b8d1e98e4f36cc81c5fe` |
| `audio/sfx/defeat.wav` | 70604 | `ed52b15f1e95df443c13a02ca183d8d83d6b046b0ffd86bfcbc9ade2b01bf06a` |
| `audio/sfx/duty.wav` | 15920 | `b17e5aedf0a2629b4b90fbc3f1e22111983fce75f8bf276f69e88a9b968acbbe` |
| `audio/sfx/hit.wav` | 10628 | `fc53b90d36baf9fb1a16c4f9695a025fd54c4670e6cd0fbeacbde9d24949405a` |
| `audio/sfx/phase.wav` | 32238 | `881510d74cb039475d0fcd0e943201eb11c4d597f2b0a3f08b62969f1d631d66` |
| `audio/sfx/shot.wav` | 7100 | `1c653efcd6c960650ed7332f33aabfe83baf02f76401287ac67ac70b04c6237c` |
| `audio/sfx/ui.wav` | 7982 | `2a0c5878e276e1f8be32e3ae3991913ceefce8787e9e0fd02bd767ceedd427e5` |
| `audio/sfx/victory.wav` | 66194 | `d62dc33fa149114e75052ef6c11f77356a783510ee17c08d68bcc91b3340e963` |
