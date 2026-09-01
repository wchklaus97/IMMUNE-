# CHAR-BASE-T Tripo asset provenance

## Non-shipping development asset

- Current runtime scene: `characters/base_t/character.tscn` loads the authored
  `reference_body.tscn`; it does not load this GLB.
- Development mesh: `CHAR-BASE-T-tripo-5k.glb`
- SHA-256: `4b969a424da09aad9dfb80b810e7ec6b7ce08db61cb54da7febc482b259dd105`
- Repository evidence: the filename, embedded node/material names, and project
  look-development comments identify this as a Tripo remesh.
- Geometry audit: 5,044 triangle faces, 3,277 vertices, one embedded texture,
  one material, no animation or bones.
- Historical look-development material: the Tripo base colour was once used as
  a feature mask. The shipping T appearance is now fully authored in Godot.
- First repository commit: `ed682e0` on 2026-08-27.

## Rejected source variant

- `CHAR-BASE-T-fix.glb`
- SHA-256: `28909badce798b65995db59d373b49776b77a2cbdec82e6c76f93e21c6a5f2a0`
- Geometry audit: 7,522 triangle faces and 4,610 vertices.
- Rejection reason: headed front/face A/B renders confirmed torn/faceted eye
  and pore geometry. It remains in source history for provenance but is
  explicitly excluded from every release preset.

## Commercial-rights gate

The repository does **not** contain the original Tripo task ID, provider receipt,
source prompt/reference, account identity, or a contemporaneous copy of the
applicable commercial terms. The owner must attach those records and confirm
that every input image was owned or licensed before submitting a commercial
Steam build. All release presets therefore exclude this GLB, its texture, and
the rejected variant. This file records what is known; it does not invent
missing rights or authorize future use.
