# CHAR-BASE-N/A/D zero-credit authored jelly production pass

Status: implemented, visually reviewed, integrated into the playable demo, and
release-validated on 2026-08-29. No Meshy generation request was submitted and
no credit was consumed.

## Goal

Replace the remaining generic N, A, and D runtime blockouts with bodies that
match the locked `base-cell-line-v2` portraits and the accepted M Fizzy material
language, without making another paid generation call. The result must remain
editable in source control, work in Godot's Compatibility renderer, and preserve
the existing fixed/mobile/relay gameplay contract.

## Production implementation

`res://characters/authored_jelly_body.gd` is one reusable source-authored body
builder with three family profiles. Each family gets an independent saturated
core colour, deep absorption colour, transmission/rim colour, clear-membrane
tint, cavity colour, and bubble/microbubble/inclusion seed. The material uses the
same bounded object-space wet-gel layers and Compatibility-safe Fresnel membrane
as the accepted M direction, so no UV unwrap, imported texture, or screen-space
refraction is required.

The family scenes instantiate small adapters:

- `base_n/reference_body.tscn`: lime round body, tiny side arms, broad fused feet,
  glossy embedded eyes, and the locked short pill mouth;
- `base_a/reference_body.tscn`: amber floating round body, tiny side arms, glossy
  embedded eyes, O-mouth, and deliberately no feet; and
- `base_d/reference_body.tscn`: deep-orange round body, tiny side arms, broad
  fused feet, O-mouth, and five overlapping crown lobes.

Each production `character.tscn` now points at its reference body and explicitly
suppresses only the conflicting procedural face, limbs, identity props, bubble
geometry, and fixed kit. The imported adapter preserves the authored materials.
N and D retain their existing `LocomotionKit`; A remains footless, retains its
hover animation, and maps a mobile request to `RelayDish` rather than creating a
walk kit.

## Quality and regression gates

- Six-angle 1024×1024 captures for every family show a stable front, 3/4, side,
  back, face, and face-3/4 read.
- N keeps two feet and a horizontal mouth; A has no feet; D exposes all five
  crown lobes. Eyes and mouth remain more readable than the interior texture.
- Body and appendage features remain round from side and back because all
  bubbles and inclusions are object-space, not UV- or screen-space.
- Overlapping authored primitives and mobile accessories do not cast internal
  or screen-sized wedge shadows.
- Fixed/mobile/boss gameplay captures were generated for N, A, and D. N/D body
  visibility survives the locomotion swap; A body visibility survives the relay
  swap and its duty becomes `relay`.
- Runtime smoke asserts reference paths, authored node names, Fizzy material
  layers, clear membrane shader, shadow settings, family silhouettes, and duty
  visibility. The marker is now
  `authored_jelly=M+N+A+D gel_bubbles=B+M+N+A+D`.

## Verification record

- Godot 4.6.1 import and expanded six-family smoke: pass.
- Web research UI: 53/53 tests and production build pass.
- Meshy workflow: 6/6 unit tests pass; N/A/D manifests each report
  `DRY_RUN_OK network_calls=0 credits=0`.
- 1920×1080 research HUD overflow check: pass.
- MISSION-01/MISSION-06 T/B balance sentinel: 4/4 victories, both final runs
  retain 12/12 core HP.
- Windows, Linux, macOS, and Web release export logs: no script, parse, compile,
  or engine errors.
- Exported macOS app: `RELEASE_SMOKE_OK platform=macOS nodes=200`.
- Exported Web HTML, WASM, and PCK: HTTP 200 from a local server.

## Cost and future boundary

The N/A/D Meshy manifests remain useful as separately approval-gated future
experiments, but they are not runtime dependencies and were not executed in this
pass. Any future paid comparison still requires an explicit, per-asset exact
approval (`--execute --approve-credits 5`). Do not batch-create or automatically
retry those tasks. The present playable demo is complete without them.
