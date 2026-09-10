# IMMUNE release audio provenance

Updated: 2026-09-01.

All shipping music and sound effects are synthesized for this repository by
`tools/generate_release_audio.mjs`. The generator uses only mathematical
oscillators, deterministic integer noise, envelopes, and PCM encoding written
in project source. It contains no recordings, sample-library content, model
outputs, commissioned material, or third-party musical composition.

The eight short effects are deterministic 44.1 kHz, 16-bit mono PCM WAV files.
The eight-second stereo music loop is synthesized to deterministic PCM (source
SHA-256 `03dc0e0350308cd20fc13258a86a43894212dd29605a7ccf433b67a4c8e55328`)
and encoded as Ogg Vorbis with FFmpeg. The release binary is checksum-locked;
`node tools/generate_release_audio.mjs --check` verifies the checked-in files
without requiring an encoder. `--write` refuses to emit a mislabeled track when
FFmpeg exposes no Vorbis encoder.

## Shipping inventory

| File | SHA-256 |
| --- | --- |
| `music/immune_pulse.ogg` | `1daba74fd27ac64db650cda112689ac5b5a9ea4776a5d56b0f71b6d5474de3a4` |
| `sfx/core_hit.wav` | `41ae39ffb58e7fe3e1117cccb9d6e3c99afc790e0335b8d1e98e4f36cc81c5fe` |
| `sfx/defeat.wav` | `ed52b15f1e95df443c13a02ca183d8d83d6b046b0ffd86bfcbc9ade2b01bf06a` |
| `sfx/duty.wav` | `b17e5aedf0a2629b4b90fbc3f1e22111983fce75f8bf276f69e88a9b968acbbe` |
| `sfx/hit.wav` | `fc53b90d36baf9fb1a16c4f9695a025fd54c4670e6cd0fbeacbde9d24949405a` |
| `sfx/phase.wav` | `881510d74cb039475d0fcd0e943201eb11c4d597f2b0a3f08b62969f1d631d66` |
| `sfx/shot.wav` | `1c653efcd6c960650ed7332f33aabfe83baf02f76401287ac67ac70b04c6237c` |
| `sfx/ui.wav` | `2a0c5878e276e1f8be32e3ae3991913ceefce8787e9e0fd02bd767ceedd427e5` |
| `sfx/victory.wav` | `d62dc33fa149114e75052ef6c11f77356a783510ee17c08d68bcc91b3340e963` |

Repository authors grant this project the same distribution rights they grant
to the surrounding project source. The account owner must still confirm
contributor authority in the final asset-rights attestation; this provenance
record does not sign that owner decision on their behalf.
