# CHAR-BASE-T Tripo asset provenance

## Non-shipping development source asset

- The default V8.3 runtime scene loads the authored `reference_body.tscn`; it
  does not instantiate this source GLB. The opt-in V8.4 look uses the audited
  derivative recorded below and is not cleared for a commercial release.
- Development mesh: `CHAR-BASE-T-tripo-5k.glb`
- SHA-256: `4b969a424da09aad9dfb80b810e7ec6b7ce08db61cb54da7febc482b259dd105`
- Repository evidence: the filename, embedded node/material names, and project
  look-development comments identify this as a Tripo remesh.
- Geometry audit: 5,044 triangle faces, 3,277 vertices, one embedded texture,
  one material, no animation or bones.
- Historical look-development material: the Tripo base colour was once used as
  a feature mask. The shipping T appearance is now fully authored in Godot.
- First repository commit: `ed682e0` on 2026-08-27.

## V8.4 single-mass development derivative

- Development mesh: `CHAR-BASE-T-v8-4-single-mass-r1.glb`
- SHA-256: `169394df640604f6d5e1302f5ff82b444b088e924125b971441e713185b6f7bb`
- Size: 127,592 bytes.
- Reproducible local builder: `tools/meshy/build_t_single_mass_body.py`
- Builder SHA-256:
  `54d3a727fe6dea2347db3f1e82279ff12686d0d01752c20ba13353d1cfc67f4b`
- Pipeline: Assimp converts the source GLB to OBJ; VTK welds attribute seams,
  keeps the largest connected body surface, fills the three face-insert holes,
  triangulates, normalizes, and regenerates normals; Assimp writes the final
  binary GLB. No external generation API or new provider asset is used.
- Failure safety: Assimp writes to a same-filesystem temporary candidate; the
  builder validates the GLB 2.0 header and declared length, then atomically
  promotes it. A failed conversion cannot leave a partial final output that
  blocks or contaminates a retry.
- Geometry contract: one node, one mesh, one primitive, 2,253 vertices, 4,502
  triangles, one connected component, zero boundary edges, and zero
  non-manifold edges. Eyes, pore, and mouth are regenerated as attached Godot
  face marks so the character remains one coherent body without detached cells.
- Runtime scope: exact selector `v8_4`, family T only. V8.3 and every older
  selector retain their previous procedural/reference body path.
- Rights status: this is a geometry derivative of the source asset above, so it
  inherits the same unresolved commercial-rights gate. Topology cleanup does
  not create or imply a new licence.

## V8.5 project-authored reference sculpt candidate

- Development mesh: `CHAR-BASE-T-v8-5-authored-sculpt-r4.glb`
- SHA-256: `8f14cfe59a508df413e4d53218f30bbf316e7e5d31e42154b2916a0bd5669294`
- Size: 288,900 bytes.
- Deterministic builder: `tools/meshy/build_t_v8_5_authored_sculpt.py`
- Builder SHA-256:
  `7f9ae79363244d0cf30ecf3d6f207ec777f189cf4c31bf00ad1496a8014ec8e5`
- Source scope: numeric project-authored implicit-shape parameters only. The
  builder consumes no Meshy, Tripo, image-to-3D, external provider mesh,
  texture, or concept-image pixels.
- Reproducibility: two independent builds produced the exact same GLB hash;
  existing outputs are immutable and overwrite attempts fail closed.
- Geometry contract: one identity-transform node, one mesh, one indexed
  primitive, 6,002 vertices, 12,000 triangles, one connected genus-zero
  component, zero boundary/non-manifold edges, zero degenerate faces,
  consistent winding, and finite positive signed volume. The GLB has no material,
  texture, UV dependency,
  skeleton, animation, provider metadata, or detached component.
- Bounds: `x=-0.75..0.75`, `y=0.00..1.46`, `z=-0.50..0.50`.
- Reproduction environment: Python 3, NumPy 2.4.4, VTK 9.6.1. Two final
  independent builds and the checked-in GLB share the asset hash above.
- Runtime scope: exact selector `v8_5`, family T only. It is fail-closed if the
  immutable asset identity or mesh contract is missing. V8.4 and all earlier
  selectors retain their previous paths.
- Rights status: the geometry and builder are project-authored, but this record
  is not an owner attestation for the visual concept/reference. The candidate
  remains excluded from release packages until the owner confirms contributor
  authority, concept/reference rights, and commercial promotion.

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
Steam build. Until then, the source GLB, its texture, the rejected variant, and
the V8.4 derivative are development-only and must be excluded from commercial
release artifacts. The separate V8.5 candidate also stays excluded until its
owner concept/reference and contributor-authority confirmations are recorded.
This file records what is known; it does not invent missing rights or authorize
future use.
