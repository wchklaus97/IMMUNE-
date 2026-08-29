# CHAR-BASE-M reference-match production promotion

Status: `fizzy` visual direction accepted and promoted to the shipping M scene;
zero new Meshy credits; N/A/D paid tasks remain paused.

## Why the previous result was rejected

The locked concept is a simple fused round character made from thick violet
jelly. It reads through a clear membrane, dense fine inclusions, multiple air
bubble sizes, soft internal colour depth, embedded glossy eyes, and a purple
mouth cavity. The installed Meshy candidate reads as a more complex sculpt with
extra appendages, a saturated plastic surface, sparse dark surface circles, and
hard kit/feature shadows. This is a geometry, material, and lighting hierarchy
gap, not a one-slider roughness mismatch.

## Accepted production implementation

`res://characters/base_m/reference_body.tscn` rebuilds the concept silhouette
from smooth fused primitives and defaults to the accepted `fizzy` profile. The
retained `res://tools/m_reference_match.tscn` wrapper can still compare `clear`,
`fizzy`, and `gummy`, but production always instantiates the authored body from
`base_m/character.tscn`. It keeps the clear membrane, medium bubbles,
microbubbles, and fine irregular inclusions at both 1024px review and gameplay
distance.

The central 40x40 forehead sample is `#C463ED` in the locked reference and
`#CD62F5` in the current fizzy render: absolute RGB differences 9/1/8. This is a
sanity check, not a substitute for visual approval.

## Acceptance gate completed

- Neutral silhouette is round and fused; no duty kit or unrequested appendage is
  part of the base body.
- Front and 3/4 reads show a pale clear outer membrane without bleaching the core.
- At least two bubble radii plus fine inclusions remain visible at review size;
  bubbles have bright rims and do not read as dark pores painted on the surface.
- Eyes remain glossy black and embedded, the mouth cavity remains visibly purple,
  and no face feature casts a hard wedge across the gel.
- Front, 3/4, side, and back contain no triplanar seam, transparency sort break,
  or disconnected limb gap.
- Compatibility/Metal and Web use the same stable path. Screen-texture refraction
  is excluded because the local Compatibility renderer reported an unavailable
  sampler during the experiment.
- A gameplay-distance capture must retain the jelly cue without inclusion shimmer.
- Ten-body core-shader timing must show no material wall/CPU regression; a real
  GPU measurement is still required on a backend that exposes non-zero timing.
- The user explicitly accepted the `fizzy` look before it replaced the runtime M
  body. It is not automatically a visual or paid-generation approval for N/A/D.

## Verified in the production pass

- Six-angle production renders and fixed/mobile/boss gameplay captures completed
  without shader errors, transparency-sort breaks, or legacy M accessories.
- Two Godot imports, the expanded production-body smoke contract, six-mission
  smoke, 1920x1080 overflow, and six Meshy no-network workflow tests passed.
- MISSION-01 and MISSION-06 deterministic M runs both won with 12/12 core HP;
  durations were 22.367 s and 88.633 s.
- Windows, Linux, macOS, and Web release exports completed without script, parse,
  compile, or engine errors. The exported macOS app passed the native release
  marker through the same `tee`-captured log path now used by CI.
- Ten M core bodies, 180 measured frames at 1920x1080: baseline CPU/wall means
  0.722/1.572 ms; opt-in three-layer core 0.623/1.354 ms. The GPU timer returned
  zero in both runs, so the result supports only "no measurable regression in
  this run," not a GPU performance claim.

## Next safe step

Treat M as the approved playable reference body and keep the rejected Meshy GLB
only as provenance. Reopen N/A/D one asset at a time only after a separate exact
5-credit approval for that asset; never infer paid approval from this M promotion.
