# IMMUNE asset-rights register

Updated: 2026-09-01. This is an evidence register, not legal advice or an owner
attestation. A `conditional` row must be resolved before commercial submission.

| Shipping material | Evidence | Status | Required owner action |
| --- | --- | --- | --- |
| Godot 4.7.2 engine/export templates | MIT text in `THIRD_PARTY_NOTICES.txt`; version-pinned `GODOT_COPYRIGHT.txt` | cleared for staging | Keep both files in every depot. |
| Noto Sans HK VF | `fonts/OFL.txt`; font SHA-256 `70172afd2cf0e045182787219b949e7798253982a36e364114757c09efd55477` | cleared for staging | Keep `NotoSansHK-OFL.txt` in every depot and do not misuse the reserved font name. |
| ProcTexture orange-peel height source | `characters/gel/jelly_micro_height.LICENSE.md`; checked-in PNG SHA-256 `25ba40fcb8a6d800fc1ffe4747a4dadad95593fc8d8f3299aed5eef7888fc9a6` | CC0, cleared | Preserve checksum/provenance record. |
| B-cell Meshy T2 development model | `characters/base_b/ASSET_PROVENANCE.md`; task `01a043a9-4884-7a6f-bd72-1a716f663403`; integrated GLB SHA-256 `c57cbf701c6ec66dfca69715e82ffe9339bc5ebf121fa05251f54157bab3100e` | non-shipping, excluded | Keep only as source/history evidence; do not use in builds or marketing without resolving its separate rights chain. |
| T-cell Tripo development model and embedded texture | `characters/base_t/ASSET_PROVENANCE.md`; GLB SHA-256 `4b969a424da09aad9dfb80b810e7ec6b7ce08db61cb54da7febc482b259dd105` | non-shipping, excluded | Keep only as source/history evidence; do not use in builds or marketing without the missing receipt and input rights. |
| T/B/M/N/A/D authored procedural bodies and runtime materials | GDScript/shader source and repository history; release PCK gate requires authored T/B scenes and rejects generated hero meshes | project-authored | Owner confirms contributor authority and project licence. |
| Steam key art/capsules/library art | `steam/assets/source/immune-key-art-*.png`, generated for this project and locally composited | conditional | Confirm the generating account had authority over every reference/input and approve commercial use. |
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
- Concepts, tool renders, and development-only sprite runs covered by the
  export preset exclusion filters.

Commercial readiness remains fail-closed until every `conditional` or `blocked`
row has a dated owner decision and supporting record.

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
