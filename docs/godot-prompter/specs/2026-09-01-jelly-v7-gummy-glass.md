# Jelly V7 gummy-glass additive refinement

Date: 2026-09-01
Status: implemented and locally verified with official Godot 4.7.2 stable,
Compatibility/OpenGL-on-Metal, and an exported WebGL 2 build

## Outcome

V7 is a new, additive visual version. It does not replace or delete V5, V6,
their selectors, their generated-model history, or their ignored evidence.
It keeps V6's banner-oriented optical model and moves the live characters
closer to the soft gummy reference by combining:

- rounder, more integrated body/limb proportions;
- clean black dielectric eyes without the previous coloured eye rims;
- a clearer outer membrane and a longer diagonal studio reflection;
- fewer contour bands and more irregular, filled internal strands;
- separated six-family palettes that remain readable in mission and combat;
- two small cosmetic lower lobes for A, without changing hover movement,
  collision, Relay duty, or gameplay logic.

The project setting now selects `immune/visual/gel_look="v7"`. The diagnostic
environment selectors `IMMUNE_GEL_LOOK=v5`, `IMMUNE_GEL_LOOK=v6`, and
`IMMUNE_GEL_LOOK=v7` keep all three material/silhouette paths runnable.

V7 remains a Compatibility-safe stylized gummy material. It does not claim
screen-space refraction, physically correct transmission, subsurface
scattering, or volumetric light transport.

## Preservation contract

| Look | Preservation mechanism | Runtime selection |
|---|---|---|
| V5 | Historical source/checkpoints, unchanged V5 branch and assets | `IMMUNE_GEL_LOOK=v5` |
| V6 | Immutable local source checkpoint `c45c3eb90c97018bfcae7c56e21f377572ef4170`; unchanged V6 values/geometry branch | `IMMUNE_GEL_LOOK=v6` |
| V7 | Immutable local source checkpoint `f9cb6609ec00f483cb33fda2223fe6d52ea1f379`; additive profile, controls, and silhouette branch | project default or `IMMUNE_GEL_LOOK=v7` |

All V7 shader uniforms default to zero, so the new fiber and streak paths are
inert under V5/V6. V6 source preservation is proven by its checkpoint, selector,
and passing smoke contract. Fresh headed PNG captures are not treated as
pixel-identical proof because otherwise identical captures show small
renderer/glow nondeterminism.

The old Meshy/Tripo GLBs and their provenance remain untouched. V7 submitted no
Meshy task, made no paid retry, and consumed zero generation credits.

## Rejected prototype and corrected workflow

The first V7 B prototype is retained under
`outputs/v7-gummy-glass/prototype-b/`. Its new detail read produced too many
closed contour rings, making the body resemble patterned plastic instead of
gummy tissue. Batch generation stopped at that point.

The accepted correction was to:

1. rotate and stretch the existing mipmapped object-space height source;
2. use a filled anisotropic threshold instead of another contour extraction;
3. gate the strand with the coarser inclusion signal;
4. lower caustic energy and keep a strict per-channel emission budget;
5. remove the coloured eye rims and rebalance the shell/face response;
6. validate one revised B prototype before generating all six families.

The accepted B prototype is retained under
`outputs/v7-gummy-glass/prototype-b2/`. This stop-diagnose-correct sequence is
the required workflow for future material iterations; failed visual directions
must not trigger unattended paid or batch generation.

## Material and silhouette implementation

`ImmuneGelProfiles.V7_GUMMY_GLASS` is applied after the preserved V6 values.
The body shader adds two opt-in controls:

- a rotated, stretched, mip-filtered object-space fiber read from the existing
  checksum-controlled `jelly_micro_height.png` texture;
- an analytic elongated reflection card based on the view-space reflection
  vector, with no screen/depth sampling.

The clear-shell shader receives the matching elongated card. Both body and
shell paths retain explicit energy/alpha budgets. V7 body construction is a
separate `_build_v7_body` branch; the V5/V6 dimensions above it are not edited.
The scene roots, collisions, duties, skill controllers, animation hooks, and
combat balance are unchanged.

## Accepted visual evidence

The ignored local evidence root is `outputs/v7-gummy-glass/`:

- `lineup-v7-front.png`: accepted T/B/M/N/A/D front contact strip;
- `family-shots/{t,b,m,n,a,d}/`: six views for every family;
- `motion-b/b-v7-motion-strip.png`: five-frame B yaw stability strip;
- `mission-select/`: six exact family/mission identity captures;
- `gameplay-b/`: fixed, mobile, boss, and portrait lifecycle evidence;
- `preservation-v6-b/` and `preservation-v6-b2/`: visual V6 rollback checks;
- `overflow-portrait-windowed/`: real 390x844 bilingual layout check;
- `overflow-compact-landscape/`: real 1280x720 bilingual layout check;
- `web-qa/`: exported-Web reports and research/mission/combat/pause captures.

The separate local Web export is
`godot/immune/build/releases/web-v7/`. The existing
`godot/immune/build/releases/web/` directory was not overwritten.

## Performance sentinel

Two order-varied local pairs rendered ten B bodies after warm-up. Pair one used
600 measured frames; pair two used 1,200 measured frames and reversed the run
order.

| Run | Look | CPU mean | Wall mean |
|---|---|---:|---:|
| Pair 1 | V6 | 0.883 ms | 2.295 ms |
| Pair 1 | V7 | 0.809 ms | 2.383 ms |
| Pair 2 | V7 | 0.784 ms | 2.357 ms |
| Pair 2 | V6 | 0.843 ms | 2.316 ms |

V7 shows no measured CPU regression. Its wall mean is approximately
0.04-0.09 ms (1.8-3.8%) higher in these two local pairs. The Compatibility/Metal
viewport GPU timer returned zero for every sample, so this is a local CPU/wall
sentinel only, not GPU parity or lower-end-hardware evidence.

## Validation matrix

| Gate | Result |
|---|---|
| Official Godot 4.7.2 clean import | two consecutive passes; no warning/error |
| Default V7 content smoke | pass; `gel_look=v7` and 6/6 material/body contracts |
| Explicit V6 rollback smoke | pass; `gel_look=v6` |
| Explicit V5 rollback smoke | pass; `gel_look=v5` |
| Character shots | 6/6 families and all requested views pass |
| Mission selection | 6/6 exact family identity/capture checks pass |
| B gameplay | fixed/mobile/boss and portrait hide/restore pass |
| Motion stability | five B yaw captures pass visual review |
| Root tools / Web UI / Meshy offline safety | 55/55, 53/53, and 6/6 pass |
| Catalog / translation | 200 nodes and 628 translation rows pass |
| UI production build | pass; optional Sharp JPEG previews skipped |
| Research overflow | zh_HK/en pass at 1920x1080, real 390x844, and real 1280x720 |
| Steam repository checks | 17 assets/6 screenshots pass; 7 external gate groups correctly remain open |
| Web export | official Godot 4.7.2 release export passes in separate `web-v7/` |
| Real-browser lifecycle | Metal and SwiftShader complete all 8 ordered events |

The exported-Web baseline measured `60.002` mean / `59.88` p05 FPS on ANGLE
Metal with no long frames, console errors, or warnings. The 4x CPU-throttled
SwiftShader profile measured `13.26` / `11.99` and completed the lifecycle.
SwiftShader is a compatibility stress profile, not a hardware benchmark.

The four required local Web artifact hashes are:

| File | SHA-256 |
|---|---|
| `index.html` | `d803e18a3aae20cb3433cedd187e1c060d141cbc5b5e4ad64a7d3a175bb60f6c` |
| `index.js` | `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba` |
| `index.pck` | `4836feecdafbd28aa811a6ad1200a4d289d3dc659f6a76ac8a22bcb746190646` |
| `index.wasm` | `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |

These are same-tree, pre-checkpoint local artifacts. They are not relabelled as
cross-platform release artifacts and do not replace the older release folders.

## Reproduction

```sh
godot --headless --path godot/immune --import
godot --headless --path godot/immune --script res://tools/smoke.gd
IMMUNE_GEL_LOOK=v6 godot --headless --path godot/immune \
  --script res://tools/smoke.gd
IMMUNE_GEL_LOOK=v5 godot --headless --path godot/immune \
  --script res://tools/smoke.gd
godot --headless --path godot/immune --export-release "Web" \
  build/releases/web-v7/index.html
npm run test:web-release -- \
  --artifacts=godot/immune/build/releases/web-v7 \
  --out=outputs/v7-gummy-glass/web-qa --duration-ms=6000
```

## Honest remaining gates

1. A six-family human preference/readability test against the banner is still
   required; automated captures cannot prove player preference.
2. Test the exact V7 build on the agreed minimum-spec Windows machine, Steam
   Deck, and physical mobile devices. SwiftShader is not a substitute.
3. Rebuild Windows, Linux, macOS, and Web from the eventual exact release
   commit before calling V7 a release candidate.
4. Refresh and owner-approve storefront screenshots after that exact rebuild.
5. Rights/IDs, Developer ID signing, notarization, Steamworks configuration,
   Valve review, and final owner authorization remain external publisher gates.
6. No push, tag, GitHub release, public upload, notarization, or Steam submission
   was performed by this visual tranche.
