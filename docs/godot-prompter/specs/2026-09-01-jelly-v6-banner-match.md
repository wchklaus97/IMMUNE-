# Jelly V6 banner-match visual convergence

Date: 2026-09-01
Status: implemented and locally verified with official Godot 4.7.2 stable,
Compatibility/OpenGL-on-Metal, and an exported WebGL 2 build

## Outcome

V6 closes the largest visual gap between the `BASE CELL LINE` concept/banner
and the playable characters. It replaces the production T, B, and M asset
silhouettes with editable source-controlled bodies, unifies all six families on
one banner-oriented material response, and propagates the same presentation to
character shots, mission selection, and the combat portrait.

The result deliberately targets the banner's readable art direction rather
than photoreal glass:

- rounded, family-specific bodies with stub limbs, black wet eyes, O/pill
  mouths, the footless A silhouette, and D's five-lobe crown;
- a dark optical core with brighter transmitted edges instead of a flat waxy
  or hard-plastic fill;
- a clear dielectric membrane and broad studio reflection cards;
- fine flecks, coarse irregular inclusions, and contour-like caustic bands from
  the existing checksum-locked, mipmapped CC0 data texture;
- stable object-space detail that does not depend on fragmented model UVs;
- no paid Meshy/Tripo generation and no screen-texture refraction.

This is a Compatibility-safe stylized approximation of translucent jelly. It
does not claim physically correct background refraction or volumetric light
transport.

## Why a shader-only adjustment was insufficient

The concept's identity comes from both surface response and silhouette. The
previous T/B/M production assets retained elongated or mismatched shapes,
facial topology, and baked model assumptions. Increasing gloss, emission, or
normal depth could not make those forms read like the round concept lineup and
made the surface look more plastic.

The accepted workflow therefore stopped treating generation as the only route:

1. Keep existing generated GLBs and their provenance as comparisons/history.
2. Build the six concept identities from high-resolution Godot primitives so
   proportions, face placement, and family features remain editable.
3. Put the shared material language in one profile/shader contract.
4. Verify the same character resources in presentation and gameplay contexts.

This path costs zero generation credits, avoids a paid retry loop, and can be
adjusted deterministically in source control.

## Geometry and identity

`authored_jelly_body.gd` now owns T/B/M/N/A/D. T and B load through new
`reference_body.tscn` adapters; M uses a new `authored_body.tscn` adapter. Their
character roots, gameplay scripts, collisions, skills, duties, and animation
hooks remain intact. Only the visual body assembly changed.

The body uses one cached 96x48 sphere mesh and separate material instances.
Transparent shell geometry is limited to the main body and D crown. Intersecting
transparent shells on arms and feet were intentionally removed because they
created dark seams at primitive joins; the opaque gel response supplies their
wet edge instead.

## V6 material contract

`ImmuneGelProfiles.V6_BANNER_MATCH` is selected by the project setting
`immune/visual/gel_look="v6"`. `IMMUNE_GEL_LOOK=v5` is the explicit diagnostic
rollback and `IMMUNE_GEL_LOOK=v6` forces the promoted path.

The V6 opaque shader adds:

- a deeper colour core with bounded wrapped transmission and rim energy;
- three mip-filtered object-space detail scales: flecks, inclusions, and narrow
  caustic contours;
- bounded view-space analytic reflection cards for the broad white/cool/warm
  highlights visible in the concept;
- no screen sampling, refraction buffer, or renderer-specific extension.

The clear-shell shader uses a nearly colourless face, stronger grazing edge,
and the same bounded studio reflections. `gel_eye.gdshader` gives the eyes a
stable black dielectric response and analytic highlights without environment
map dependence.

`gel_studio_environment.gd` supplies a restrained blue/purple procedural
environment only to isolated character shots, mission preview, and the combat
portrait. The authored combat arena environment is not replaced.

## Framing propagation

Mission-select and combat-portrait framing now use one common vertical origin
and per-family scale. The old B-only vertical offset, which cropped the new
round body, is removed. Mission selection previews fixed duty only, keeping
mobile wheel/relay kit geometry out of the silhouette-selection view. Gameplay
still switches duties normally.

## Visual evidence

The ignored local evidence root is `outputs/v6-banner-ab/`:

- `promoted-six/lineup-promoted-front.png`: final T/B/M/N/A/D contact strip;
- `promoted-six/{t,b,m,n,a,d}/`: per-family front and turn captures;
- `caustic-motion/b/b-v6-caustic-motion-strip.png`: five-frame yaw stability;
- `mission-framed/`: corrected mission-selection framing;
- `gameplay-b-framed/`: B combat portrait and gameplay framing;
- `web-qa/screenshots/`: exported-Web research, mission, combat, and pause.

The concept source remains
`godot/immune/characters/concepts/base-cell-line-v2/LINEUP.png`.

## Performance sentinel

The matched local harness renders ten B bodies at 1920x1080 for 60 warm-up and
600 measured frames:

| Metric | V5 control | V6 promoted |
|---|---:|---:|
| CPU mean | 0.622 ms | 0.609 ms |
| Wall mean | 1.553 ms | 1.454 ms |

The Compatibility/Metal viewport GPU timer returned zero for every sample, so
this proves no measured CPU/wall regression in this local harness only. It is
not a GPU-parity claim or a lower-end-hardware benchmark.

## Validation matrix

| Gate | Result |
|---|---|
| Official Godot 4.7.2 clean import | two consecutive passes; no warning/error |
| Default V6 content smoke | pass; authored-body and material contracts for 6/6 families |
| Explicit `IMMUNE_GEL_LOOK=v5` smoke | pass; rollback remains functional |
| Mission selection | 6/6 identity, capture, and responsive checks pass |
| B gameplay | fixed/mobile/boss and portrait lifecycle pass |
| Motion stability | five B yaw captures pass |
| Root tools / Web UI / Meshy offline safety | 55/55, 53/53, and 6/6 pass |
| Catalog / translation | 200 nodes and 628 rows pass |
| Research overflow | zh_HK and en pass at 1920x1080 |
| UI production build | pass; optional Sharp JPEG previews skipped |
| Steam repository checks | assets pass; readiness correctly leaves 7 external gate groups open |
| Web export | official Godot 4.7.2 release export passes |
| Real-browser lifecycle | Metal and SwiftShader profiles pass all 8 ordered events |

The exported-Web baseline measured `60.003` mean / `59.88` p05 FPS on ANGLE
Metal. SwiftShader measured `13.095` / `11.99` and completed without a watchdog
stall. SwiftShader is a compatibility stress profile, not hardware evidence.

## Reproduction

```sh
godot --headless --path godot/immune --import
godot --headless --path godot/immune --script res://tools/smoke.gd
IMMUNE_GEL_LOOK=v5 godot --headless --path godot/immune \
  --script res://tools/smoke.gd
godot --headless --path godot/immune --export-release "Web" \
  build/releases/web/index.html
npm run test:web-release -- \
  --artifacts=godot/immune/build/releases/web \
  --out=outputs/v6-banner-ab/web-qa --duration-ms=6000
```

## Honest remaining gates

1. Run a six-family human preference/readability playtest against the banner.
   Automated rendering cannot decide whether players prefer the art direction.
2. Test the exported build on the agreed real minimum-spec Windows machine,
   Steam Deck, and physical mobile devices. SwiftShader is not a substitute.
3. True refractive glass would require screen/depth sampling, different sorting
   and overlap handling, and a separate performance budget. It is intentionally
   outside this Web-compatible V6 path.
4. Refresh and owner-approve storefront screenshots only after V6 is committed
   and the exact cross-platform candidate is rebuilt; current repository Steam
   assets still satisfy dimensions/contracts but predate this working-tree look.
5. This source/spec is preserved as the local V6 checkpoint before V7 work.
   No push, tag, upload, notarization, or Steam submission is performed by this
   visual tranche.
