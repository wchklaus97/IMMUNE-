# V8.5 Rights-Safe Reference Sculpt Plan

## Outcome

V8.5 replaces the development-only V8.4 T derivative with a deterministic,
project-authored, provider-independent single-mass sculpt. It targets the
concept's broad lower body, integrated hanging arms and feet, recessed eye/pore
areas, fine continuous orange-peel skin, and coherent wet highlights during
wobble. V8.4 remains frozen at commit `ee404cd`; V5 through V8.4 and the
release-safe V8.3 default remain selectable.

## Fail-closed scope

- No Meshy, Tripo, image-to-3D, paid API, or source mesh is consumed by the V8.5
  geometry builder.
- The builder contains only project-authored numeric implicit-shape parameters,
  writes to a same-filesystem temporary candidate, validates it, and promotes
  it atomically without overwriting an existing output.
- V8.5 stays opt-in and excluded from commercial presets until visual, topology,
  performance, concept-rights, and owner approval gates are all complete.
- No signing, upload, Steam submission, public deployment, or store mutation is
  authorized by this plan.

## Geometry contract

- One indexed triangle surface, one connected component, genus zero.
- Zero boundary edges, zero non-manifold edges, consistent opposite winding on
  every shared edge, finite positive enclosed volume, and no degenerate faces.
- One GLB node, one mesh, one primitive, normals present, no material, texture,
  skeleton, animation, or provider metadata.
- Target world bounds after normalization: width 1.42–1.58, height 1.38–1.52,
  depth 0.88–1.06; width/height ratio 0.96–1.10.
- Arms connect only through the upper side mass and separate visibly from the
  lower torso; feet merge through the base web. Eye sockets and forehead pore
  are shallow subtractions in the same closed surface, never separate pieces.
- Runtime collision remains the existing stable gameplay primitive. Render
  geometry must never become the moving collision shape.

## Shader contract

- New V8.5 controls default to zero/inert for V5 through V8.4.
- Fine orange-peel relief remains continuous and mip-filtered; it may not turn
  into discrete cells, flecks, bubbles, or particles.
- Wobble changes both position and the corresponding shading normal so the wet
  highlight follows the surface instead of sliding over it.
- Core, membrane, eyes, pore, and mouth use the same body-space deformation
  frame. Face visibility remains front-gated.
- Compatibility/Web stays free of screen-texture reads and raymarching. Texture
  sample and trigonometric cost changes are counted and profiled.

## Motion contract

- Exactly fourteen existing clips remain: `idle`, `plant`, `uproot`, `move`,
  `hit`, `attack`, `relay_open`, `relay_close`, `move_start`, `move_stop`,
  `relay_glide`, `skill_cast`, `victory`, and `defeat`.
- Shader time/flow phase is never reset by an animation or duty transition.
- The broader base retains ground contact; start/move/stop use bounded volume
  transfer with no collapse, rigid-ball hop, detached region, or rubber snap.
- Gameplay hit timing and collision remain unchanged.

## Ordered implementation

1. Add an exact V8.5 selector and smoke assertions first; prove the new selector
   fails before production support exists.
2. Build and audit the provider-independent implicit sculpt outside the runtime.
3. Import it under a new immutable filename and bind builder/asset hashes in
   provenance.
4. Integrate exact V8.5 T loading with procedural single-mass fallbacks for the
   other five families; never preload a gated review asset into release builds.
5. Add rollback-zero shader controls, normal correction, and fine continuous
   micro-relief; wire them only through the V8.5 profile.
6. Capture static front/three-quarter/side/back evidence before motion tuning.
7. Retune V8.5-only motion values only where the new silhouette proves it is
   necessary; keep all V8.4 animation data unchanged.
8. Run selector rollback, topology, import, animation, gameplay, CPU, native GPU,
   Web compatibility, UI, audio, Steam-assets, PCK, and readiness checks.
9. Obtain independent architecture, shader, animation, performance, and code
   review before a local commit.

## Implementation result — 2026-09-02

The source-tree V8.5 technical candidate is complete. Commercial promotion is
not complete and remains fail-closed behind the gates below.

- Exact asset: `CHAR-BASE-T-v8-5-authored-sculpt-r4.glb`, SHA-256
  `8f14cfe59a508df413e4d53218f30bbf316e7e5d31e42154b2916a0bd5669294`.
  It contains 6,002 vertices and 12,000 indexed triangles in one closed
  genus-zero component, with zero boundary/non-manifold edges, zero degenerate
  faces, consistent winding, positive signed volume `1.038087`, and bounds
  `(-0.75, 0.0, -0.5)` through `(0.75, 1.46, 0.5)`.
- Final builder SHA-256 is
  `7f9ae79363244d0cf30ecf3d6f207ec777f189cf4c31bf00ad1496a8014ec8e5`.
  Two independent builds in `outputs/v8.5-reference-sculpt/repro-final-r4/`
  reproduce the checked-in GLB byte-for-byte. Atomic hard-link promotion now
  fails on a concurrent or existing destination instead of overwriting it.
- Generation failures were stopped and diagnosed rather than retried blindly:
  the raw SDF's four zero-area intermediate triangles are removed by the bounded
  decimation stage; only the zero-degenerate final candidate can ship. Inward
  intermediate winding is deterministically oriented once, after which final
  validation requires positive rather than absolute signed volume.
- Exact runtime loading is source-SHA-bound and validates the imported mesh's
  node/surface count, triangle primitive, vertex/normal/index counts, and AABB.
  Missing or malformed sources disable the complete authored presentation, so
  eyes, pore, and mouth can never remain as a floating face. Smoke includes
  missing-source and malformed-mesh negative fixtures.
- Fine orange-peel detail runs only on the opaque wet core. The permanently
  disabled transparent-shell implementation was removed so older selectors do
  not carry an unused varying or fragment branch. Wobble-normal correction stays
  coherent across core, shell, eyes, pore, and mouth.
- The fourteen-clip animation inventory, clip timing, collision primitive, and
  gameplay markers remain unchanged. V8.5-only start/move/stop envelopes and the
  runtime spring pass loop-seam, volume, collapse, collision, and 30/60/120 Hz
  reversal/settle checks.
- Final local selector matrix passes V5, V6, V7, V8, V8.1, V8.2, V8.3, V8.4,
  V8.5, plus the unset default resolving to V8.3. Tool tests pass 64/64, and
  Steam readiness verifies 16 rights-bound hashes including both the builder
  and GLB.
- Accepted visual evidence is preserved under
  `outputs/v8.5-reference-sculpt/motion-retuned-r2-grounded/`,
  `gameplay-r2-framed/`, and `mission-select-r2-framed/`; earlier revisions were
  not removed.
- Ten-character 1920x1080 performance evidence records V8.4 CPU mean
  `0.8355 ms` and V8.5 `0.8578 ms` (`+2.67%`), with an inferred enabled gel cost
  of about `0.0164 ms` per character. Compatibility GPU timing returned zero and
  is explicitly unavailable; no native-GPU performance claim is made.
- Fresh release-safe artifacts from the final source live in
  `outputs/v8.5-reference-sculpt/release-safe-v8.3-final-r2/`. All four exports
  keep V8.3 as the default and exclude V8.5. Artifact/PCK readiness passes; the
  universal macOS bundle also passes codesign verification and native
  `RELEASE_SMOKE_OK platform=macOS nodes=200`.
- Local import/shader/smoke evidence passes both the installed Godot 4.6.1 and an
  official checksum-verified Godot 4.7.2 universal binary. The 4.7.2 run used a
  genuinely empty import cache and passed the full selector/default matrix with
  zero engine errors. Repository CI is pinned to the same 4.7.2 and now repeats
  the full matrix plus a fail-on-error cold import gate; its hosted run remains a
  pre-merge requirement.
- Independent architecture, shader, motion, and final Godot code review were
  completed. Their fail-closed loader, provenance, builder race, positive-volume,
  and shared-shell-cost findings are incorporated above.

## Promotion gates

- Default plus V5–V8.5 selector smoke all pass from the final source tree.
- T geometry passes the full contract above and rebuilds to the same SHA-256.
- Six-family front/back evidence contains one substantial body per character,
  no floating face marks, and no loose particles.
- Static and motion strips show a material improvement over R24 without a new
  clipping, collapse, or readability regression.
- Ten-character CPU time does not regress more than 10% from V8.4. Actual native
  GPU timing is recorded; Web software evidence is labelled compatibility stress,
  never presented as a hardware benchmark.
- The release-safe PCK excludes every unresolved development asset.
- Commercial promotion additionally requires owner confirmation of concept-art
  rights, store materials, legal text, pricing, signing identities, and Steam
  publisher actions.
