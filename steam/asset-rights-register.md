# IMMUNE asset-rights register

Updated: 2026-09-01. This is an evidence register, not legal advice or an owner
attestation. A `conditional` row must be resolved before commercial submission.

| Shipping material | Evidence | Status | Required owner action |
| --- | --- | --- | --- |
| Godot 4.7.2 engine/export templates | MIT text in `THIRD_PARTY_NOTICES.txt`; version-pinned `GODOT_COPYRIGHT.txt` | cleared for staging | Keep both files in every depot. |
| Noto Sans HK VF | `fonts/OFL.txt`; font SHA-256 `70172afd2cf0e045182787219b949e7798253982a36e364114757c09efd55477` | cleared for staging | Keep `NotoSansHK-OFL.txt` in every depot and do not misuse the reserved font name. |
| ProcTexture orange-peel height source | `characters/gel/jelly_micro_height.LICENSE.md`; checked-in PNG SHA-256 `25ba40fcb8a6d800fc1ffe4747a4dadad95593fc8d8f3299aed5eef7888fc9a6` | CC0, cleared | Preserve checksum/provenance record. |
| B-cell Meshy T2 model | `characters/base_b/ASSET_PROVENANCE.md`; task `01a043a9-4884-7a6f-bd72-1a716f663403`; integrated GLB SHA-256 `c57cbf701c6ec66dfca69715e82ffe9339bc5ebf121fa05251f54157bab3100e` | conditional | Confirm ownership/licence of the reference image and retain the Meshy account receipt/terms. |
| T-cell Tripo remesh and embedded feature texture | `characters/base_t/ASSET_PROVENANCE.md`; shipping GLB SHA-256 `4b969a424da09aad9dfb80b810e7ec6b7ce08db61cb54da7febc482b259dd105` | **blocked: missing receipt** | Attach the original Tripo task/receipt, prompt/reference rights, and applicable commercial terms. Replace the asset if this cannot be proven. |
| M/N/A/D authored procedural bodies and runtime materials | GDScript/shader source and repository history | project-authored | Owner confirms contributor authority and project licence. |
| Steam key art/capsules/library art | `steam/assets/source/immune-key-art-*.png`, generated for this project and locally composited | conditional | Confirm the generating account had authority over every reference/input and approve commercial use. |
| Wordmark, Steam icons, and UI symbols | SVG/code-native sources and repository history | project-authored | Owner confirms contributor authority. |
| Music and SFX in `godot/immune/audio/` | Binary files entered in commit `af7c9a1`; no source-session or licence note is checked in | **blocked: provenance absent** | Provide DAW/generator/source records and a signed ownership/licence attestation, or replace all nine files with documented assets. |
| English and Traditional Chinese text | Checked-in source/localization tables; AI-assisted drafting disclosed | conditional | Human owner reviews accuracy, trademarks, and authority to publish. |

## Explicitly excluded from release packages

- `characters/base_m/CHAR-BASE-M-meshy-t2.glb`: retained as generation evidence;
  runtime M uses the authored project body.
- `characters/base_t/CHAR-BASE-T-fix.glb` and matching `...fix...basecolor.jpg`:
  rejected damaged T variant.
- Concepts, tool renders, and development-only sprite runs covered by the
  export preset exclusion filters.

Commercial readiness remains fail-closed until every `conditional` or `blocked`
row has a dated owner decision and supporting record.

## Blocked audio inventory

These hashes identify the nine exact binaries that require source-session,
generator, commission, or licence evidence. Godot `.import` metadata is not a
rights record and is intentionally omitted.

| Shipping file | Bytes | SHA-256 |
| --- | ---: | --- |
| `audio/music/immune_pulse.ogg` | 27465 | `fa81aeb7ef4bcb5eab7d47374b1c6f6ef74041505252829128bc1ce3fff95e8c` |
| `audio/sfx/core_hit.wav` | 19482 | `852662350ab846736b69224112c5bf22534a065afb676287c923f39bcf10f1f5` |
| `audio/sfx/defeat.wav` | 70638 | `084e968270f4457c1bde9894134ea5df312f02245acfb0c59359de8a7148f126` |
| `audio/sfx/duty.wav` | 15954 | `e93f1edf282a2af483c38cc9276ab9808d0d93efb9f97bb32db04044d17683e2` |
| `audio/sfx/hit.wav` | 10662 | `db65fbf670fdd942491a3a173f798f940ab50aab86210536a400012a5a2e742d` |
| `audio/sfx/phase.wav` | 32270 | `fb86c677b47bf614542fc439c4c6270f276d0e085118d055841703fd5ae41702` |
| `audio/sfx/shot.wav` | 7134 | `833c78f25a5615cbd70e529979be2d24db9637588b1311f9766f75258db18394` |
| `audio/sfx/ui.wav` | 8016 | `a14af0ed734b778ae0c923df24c1afdc2eef0ea9a02b60cd72046dc93c8b3d56` |
| `audio/sfx/victory.wav` | 66228 | `0c6b4170755d5fa58d20271d8c6106f652569187ac0afb7eee9b44c3f653027d` |
