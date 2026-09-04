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
- Visual-reference inventory (none of these files is read by the builder):
  - primary appearance reference `characters/concepts/CHAR-BASE-T-3d-alt.png`,
    SHA-256
    `3164ea9567836f98f1fcc96fb2ff0058495b91268f2f1e3ead298a24eab9a65c`;
  - secondary shape reference
    `characters/concepts/base-cell-line-v2/CHAR-BASE-T.png`, SHA-256
    `8916ea0ba811d35142f38f55e651af6a240b494601db991218fcfb90a4298e40`;
  - secondary raw, fixed, and mobile references, SHA-256 respectively
    `7507f10a9f5ace150cc41ba73c1d8835284442182fcd7ccb1069afe1e9fce494`,
    `bf0971939cbd7f19e482d4ed9c782d3fa36ad8c13de156dc670d99549ab18680`,
    and
    `0c34616bef01adaf2c78c766f7ea826021eb9dd2c7ffa81ef50e4bfe04dae253`.
- Rights status: the geometry and builder are project-authored, but this record
  is not an owner attestation for the visual concept/reference. The candidate
  remains excluded from release packages until the owner confirms contributor
  authority, concept/reference rights, and commercial promotion. The complete
  signing package is `steam/asset-rights-attestation-v8.5-template.md`; its
  current status is **AWAITING OWNER SIGNATURE**.

## V8.6 project-authored reference-convergence sculpt R5

- Development mesh: `CHAR-BASE-T-v8-6-authored-sculpt-r5.glb`
- SHA-256: `473fcb356a166eb113bc3532d471e2bc51c6dea85dbf7146e417d293e103197f`
- Size: 288,928 bytes.
- Deterministic R5 builder: `tools/meshy/build_t_v8_6_authored_sculpt.py`
- R5 builder SHA-256:
  `1750976daca5a9d50e9631303ec253c5a82227679a52e2a12d45f819486a3cec`
- Frozen low-level topology/GLB helper:
  `tools/meshy/build_t_v8_5_authored_sculpt.py`, SHA-256
  `7f9ae79363244d0cf30ecf3d6f207ec777f189cf4c31bf00ad1496a8014ec8e5`.
- Source scope: numeric project-authored implicit-shape parameters only. The
  R5 builder does not read R4, a Meshy/Tripo/provider asset, a texture, or any
  concept/reference image pixels.
- Geometry contract: one identity-transform node, one mesh, one indexed
  primitive, 6,002 vertices/normals, 36,000 indices, 12,000 triangles, one
  connected genus-zero component, zero boundary/non-manifold edges, zero
  degenerate faces, consistent winding, Euler characteristic 2, and positive
  signed volume `0.934785`. The GLB contains no material, texture, UV, skin,
  skeleton, animation, provider metadata, or detached component.
- Bounds: `x=-0.74..0.74`, `y=0.00..1.46`, `z=-0.50..0.50`. Godot's expected
  ArrayMesh AABB is position `(-0.74, 0.0, -0.50)`, size
  `(1.48, 1.46, 1.00)`.
- Final-mesh neutral front-mask audit at 1,024 px: bounding box `881x870`,
  width/height ratio `1.012644`, centre foot-notch ratio `0.126437`, readable
  three-part torso/arm separation on 7/13 lower sample rows, and a continuous
  shoulder silhouette on 7/7 upper sample rows. This audit is derived from the
  final decimated triangle surface, not from target constants.
- Shape revision: the lower torso and paired feet use a softer, wider union;
  the central arch is deeper; rounded hook arms attach only through the upper
  side mass and remain separated below. The face sockets are centred at
  `x=+/-0.238, y=0.855, z=0.430`, use radii `(0.218, 0.145, 0.052)`, and tilt
  outward by 38 degrees. Face cards remain runtime Godot geometry rather than
  extra GLB components.
- Reproducibility: two independent final builds in
  `outputs/v8.6-reference-convergence/sculpt-r5/repro-formatted-r5-eye/` and the
  checked-in GLB are byte-for-byte identical. Final CPU neutral front, side,
  and three-quarter renders plus the build log are preserved under
  `outputs/v8.6-reference-convergence/sculpt-r5/final-eye/`.
- Failure history is intentionally preserved. Attempt 1 stopped because two
  closed arm-gap tunnels produced Euler characteristic `-2`; the gaps were
  redesigned as open silhouette space. Attempt 4 stopped when a voxel-coincident
  intermediate polygon collapsed to a line cell; the R5 cleaner now forbids
  polygon-to-line conversion while the promoted mesh still requires zero
  degenerate faces. The pre-eye-spacing candidate is retained at
  `outputs/v8.6-reference-convergence/sculpt-r5/attempt-7-promoted-pre-eye-tuning.glb`.
- Reproduction environment: Python 3, NumPy 2.4.4, VTK 9.6.1, and Pillow
  12.0.0. VTK's macOS headless OpenGL preview exited before rendering, so the
  accepted evidence uses deterministic CPU triangle rasterization and does not
  make a GPU-render equivalence claim.
- Runtime scope: exact selector `v8_6`, family T only. V8.5 R4 and all earlier
  selectors remain immutable. R5 is a technical candidate until runtime
  reference-match, animation, real-GPU, export, and owner approval gates pass.
- Rights status: project-authored geometry does not establish rights to the
  visual concept/reference. Commercial promotion remains blocked by the same
  owner contributor-authority and concept/reference attestation gate recorded
  above.

## V8.6 perspective-aware reference-convergence sculpt R6

- Development mesh: `CHAR-BASE-T-v8-6-authored-sculpt-r6.glb`
- SHA-256: `6fa587a26af3a248713986fd7614c028ae787a11cf22c310d89ac97d590dc770`
- Size: 288,928 bytes.
- Deterministic R6 builder: `tools/meshy/build_t_v8_6_authored_sculpt_r6.py`,
  SHA-256
  `a80bbdefe9221bc15e2e3cc8eefb44d284ac620b32146c38c8c6fa363faf6562`.
- Audited helper chain: R5 topology-safe cleaner
  `tools/meshy/build_t_v8_6_authored_sculpt.py`, SHA-256
  `1750976daca5a9d50e9631303ec253c5a82227679a52e2a12d45f819486a3cec`,
  and the frozen V8.5 topology/GLB helper, SHA-256
  `7f9ae79363244d0cf30ecf3d6f207ec777f189cf4c31bf00ad1496a8014ec8e5`.
- Source scope: numeric project-authored implicit-shape parameters only. R6
  reads no prior GLB, provider mesh/API response, texture, or reference-image
  pixels.
- Geometry contract: one identity-transform node, one mesh, one indexed
  primitive, 6,002 vertices/normals, 36,000 indices, and 12,000 triangles.
  The surface is one watertight genus-zero component with zero boundary or
  non-manifold edges, zero winding errors, zero degenerate faces, Euler
  characteristic 2, and positive signed volume `1.001473`. The GLB contains no
  material, texture, UV dependency, skin, skeleton, animation, provider
  metadata, or detached particle/component.
- Bounds: `x=-0.82..0.82`, `y=0.00..1.46`, `z=-0.50..0.50`. Godot's expected
  ArrayMesh AABB is position `(-0.82, 0.0, -0.50)`, size
  `(1.64, 1.46, 1.00)`.
- Perspective contract: the builder reproduces `res://tools/shot.gd` full-body
  framing (`32` degree vertical FOV; camera `(0, 1.30H, 3.05H)` looking at
  `(0, 0.46H, 0)`). Its final 1,024 px triangle mask is `633x600`, ratio
  `1.055000`. A headed Godot 4.6.1 OpenGL3 Compatibility capture of the raw
  opaque GLB measured `632x599`, ratio `1.055092`, at the stable 0.30 luma
  threshold. Applying the observed R5 transparent-edge visibility factor
  (`562/615` rendered versus `571/601` geometric) gives a conservative expected
  gel trim ratio of `1.014734`, near the reference ratio `907/896 = 1.012277`.
  This calibrated value is an estimate, not a substitute for the final
  Forward+/Metal textured-character capture.
- Orthographic and shape audit: front mask `880x785`, ratio `1.121019`; centre
  foot notch `0.140127`; low arch opening `0.194318`; readable body/arm gaps on
  8/13 final-mask rows and continuous shoulders on 7/7 rows. For comparison,
  the same audit on R5 measured foot notch `0.126437`, arch opening `0.170261`,
  and body/arm gaps on 6/13 rows.
- Face contract: pre-normalization compensation places final socket centres at
  `x=+/-0.238000, y=0.855000`; source z remains `0.430` so each cavity intersects
  the face surface. Socket radii are `(0.305, 0.185, 0.065)` with 38 degree
  outward tilt. Around runtime eye scale `(0.205, 0.136, 0.014)`, the normalized
  authored half-extent leaves calculated amber lip margins `0.037608` horizontal
  and `0.036999` vertical. The forehead pore and mouth cavities are preserved.
- Reproducibility: two independent builds under
  `outputs/v8.6-reference-convergence/sculpt-r6/repro-final-eye-aligned/` and
  the checked-in GLB are byte-for-byte identical. Final CPU neutral previews
  and build log are under `outputs/v8.6-reference-convergence/sculpt-r6/final/`;
  the headed raw-GLB Godot evidence is under
  `outputs/v8.6-reference-convergence/sculpt-r6/godot-raw-shot-final/`.
- Failure history is preserved. Attempt 1 generated valid geometry but its CPU
  preview sorted per-vertex rather than per-face depth and drew only part of the
  mesh; `attempt-1/DIAGNOSIS.md` records the fix. Attempt 2 passed silhouette
  gates but normalization moved source socket centres to final x `+/-0.190251`;
  its GLB, import sidecar, images, logs, and diagnosis remain preserved. The
  first raw Godot attempt crashed when the sandbox blocked `user://logs`; the
  second used the dummy headless renderer and produced no frames. Both logs and
  diagnoses are retained; the explicit writable log plus headed OpenGL3 run
  succeeded without changing project settings or mesh geometry.
- Reproduction environment: Python 3, NumPy 2.4.4, VTK 9.6.1, Pillow 12.0.0,
  and Godot 4.6.1 for the independent raw-GLB projection capture.
- Runtime scope: R6 is a preserved V8.6 T-only technical candidate. R5, V8.5
  R4, and every earlier selector/asset remain immutable. Runtime reference
  matching, all 14 animation clips, Forward+/Metal performance, export, and
  owner approval remain separate promotion gates.
- Rights status: project-authored geometry does not establish rights to the
  visual concept/reference. Commercial promotion remains blocked by the owner
  contributor-authority and concept/reference attestation gate recorded above.

## V8.6 bounded geometry lock R7.2

- Promoted development mesh: `CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb`.
  SHA-256: `3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3`;
  size: 288,928 bytes.
- Complete deterministic builder chain, in execution order:
  `build_t_v8_5_authored_sculpt.py`
  (`7f9ae79363244d0cf30ecf3d6f207ec777f189cf4c31bf00ad1496a8014ec8e5`),
  `build_t_v8_6_authored_sculpt.py`
  (`1750976daca5a9d50e9631303ec253c5a82227679a52e2a12d45f819486a3cec`),
  `build_t_v8_6_authored_sculpt_r6.py`
  (`a80bbdefe9221bc15e2e3cc8eefb44d284ac620b32146c38c8c6fa363faf6562`),
  `build_t_v8_6_authored_sculpt_r7.py`
  (`aa7ca2b5fda461a326c4e81e2b49dc26dfa7ae5ee46d19a2cba01206a38eee7a`),
  `build_t_v8_6_authored_sculpt_r7_1.py`
  (`8ab45c587982f8f3d46ba950eb0d62388d586dca670dd1332b80946e5297a1e5`),
  and `build_t_v8_6_authored_sculpt_r7_2.py`
  (`4755d3a9e1f1a12f5144755b7bf66f86d08e4256d584e1469d3ee86c4d25d790`).
  A second build at `/private/tmp/CHAR-BASE-T-v8-6-authored-sculpt-r7-2-gate2.glb`
  reproduced the promoted SHA-256 byte-for-byte.
- R7.2 changes only R6's bounded implicit-shape joins and eye cavities:
  core union softness `0.084`, arm union softness `0.050`, eye-only subtraction
  softness `0.014`, all other cavity softness `0.008`, and socket radii
  `(0.285, 0.190, 0.060)`. It consumes no provider API, source mesh, texture,
  or reference-image pixels.
- Geometry contract: one watertight genus-zero component, 6,002 vertices and
  normals, 36,000 indices, 12,000 triangles, zero boundary/non-manifold/
  winding/degenerate errors, Euler characteristic 2, signed volume `1.006122`,
  and unchanged Godot AABB position `(-0.82, 0.0, -0.50)` with size
  `(1.64, 1.46, 1.00)`.
- Shape contract: orthographic ratio `1.121019`, perspective ratio `1.053333`,
  calibrated gel-trim ratio `1.013131`, foot notch `0.140127`, foot-arch
  opening `0.194318`, minimum arm gap `0.050233`, and final socket centres
  `x=+/-0.238000, y=0.855065`.
- The new intersection-aware socket gate samples the hard cavity against the
  pre-subtraction front skin instead of trusting analytic radii alone. Both
  sides measured outboard extent `0.030300`, minor-axis span `0.251684`, and
  inboard overhang `0.028576`; they cross both local axes and are symmetric.
- Preserved rejected candidates: global-cavity R7
  `CHAR-BASE-T-v8-6-authored-sculpt-r7.glb`
  (`2ee384882c8c41c6a1454a457b5ed17ce2e934999ecc24337e27b9948299d587`)
  changed the pore, mouth, and foot-arch smoothing unnecessarily. Selective
  R7.1 `CHAR-BASE-T-v8-6-authored-sculpt-r7-1.glb`
  (`8af1663976140b6769ae638217efe46873e9a71a57e0294005c49361a7bf40a0`)
  used a `0.045` socket depth but failed the later intersection-aware opening
  review. Neither file is a runtime fallback or release candidate.
- Official Godot 4.7.2 Compatibility/Metal six-view evidence is preserved at
  `outputs/v8.6-reference-convergence/lookdev-r7-2-r4-1-face-lock/`. The R4.1
  material is frozen for V8.6, with eyes seated at z `0.436` and the attached
  pore rim seated at z `0.438`; no loose cell or secondary character was added.
- R7.2 is the bounded V8.6 gameplay-scale geometry lock, not a claim of
  pixel-identical marketing-render parity. Any future close-up retopology is a
  new revision. Concept/reference and contributor-authority rights still need
  the owner's signed attestation before commercial promotion.

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
