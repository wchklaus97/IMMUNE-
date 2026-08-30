# Jelly V5.1 material, lighting, portrait, and validation lock

Date: 2026-08-30
Status: implemented and locally verified with Godot 4.7.2 stable,
Compatibility/OpenGL-on-Metal, and an exported WebGL 2 build

## Outcome

V5.1 replaces the rejected crystalline/procedural skin response with a calmer,
wet jelly surface driven by one deterministic CC0 micro-height texture. The six
families retain their authored silhouettes, colours, faces, and duty kits. The
gameplay camera and collision scale are unchanged; a bounded, presentation-only
combat portrait makes the material readable without changing combat.

The accepted local result has:

- a dark coloured core, readable midtone, and brighter thin/grazing regions;
- compact irregular wet pebbles instead of rings, quilt rows, or clay wrinkles;
- a dielectric clear shell with bounded alpha and emission;
- one shadowed directional key plus up to two unshadowed directional fills per
  viewport, with Omni/Spot lights rejected;
- a portrait that is created only when the HUD has room and is freed otherwise;
- a 720x1280 tall-HUD mode with larger text, spacing, and controls;
- automatically save-isolated QA tools that fail closed on bad inputs, corrupt
  saves, and invalid output paths.

This is a local automated and visual acceptance lock. It is not a completed
six-family human playtest, a real low-end hardware benchmark, or a four-platform
V5.1 release campaign.

## Why the earlier generation path stopped

The V5 investigation did not blindly retry a poor generation:

1. Dense procedural sphere and island fields produced circular stamps, closed
   contour rings, connected wrinkles, and half-degree yaw shimmer.
2. Those candidates were rejected before shipping and the workflow changed to
   a band-limited data texture with mipmaps.
3. No Meshy POST was submitted for V5.1 and no credits were consumed. Existing
   Meshy assets and their provenance remain unchanged.
4. The final generator verifies the source archive and source member hashes,
   validates the processed channel statistics, and writes only after all gates
   pass. A bad download or changed archive stops with no output.

## Texture source and deterministic build

`godot/immune/characters/gel/jelly_micro_height.png` is derived from the height channel of
ProcTexture's **Orange Peel Seamless PBR Texture** 1K pack. The source is CC0.
Runtime uses no source colour, normal, roughness, or AO map.

| Item | Locked value |
|---|---|
| Source page | `https://proctexture.com/textures/plaster/textured/orange-peel` |
| Pack SHA-256 | `a95fa0d0acfe71054d8f2ea8993887e39ce4be7190fb9bf1d354088cac6815c0` |
| Height member SHA-256 | `c1b1a860dec8e404588d9aaba1417140148218553b8af9a90fb09293f5f4ae87` |
| Checked-in PNG SHA-256 | `25ba40fcb8a6d800fc1ffe4747a4dadad95593fc8d8f3299aed5eef7888fc9a6` |
| Packed pixel SHA-256 | `15c1b78932e75d1e4fe8e71cd9ca20a0fb999a499bcf22fb78a4eb683109244e` |
| Output | 512x512 RGB, three decorrelated tileable projections |

The verified processed data has mean `0.2329`, standard deviation `0.0549`,
range `0.1569..0.5294`, maximum anisotropy `1.0029`, wrap p99 ratio `1.0000`,
and maximum cross-channel correlation `0.0108`. Godot imports it as linear data
with mipmaps. Production uses scale `0.45`, depth `0.004`, soft triplanar blend
`2.0`, and LOD bias `0.35`.

Rebuild from a previously downloaded, checksum-pinned pack:

```sh
texture_tmp="$(mktemp -d)"
python3 build/generate_jelly_height.py \
  --source-zip=/absolute/path/orange-peel.zip \
  --output="$texture_tmp/jelly_micro_height.png"
shasum -a 256 "$texture_tmp/jelly_micro_height.png" \
  godot/immune/characters/gel/jelly_micro_height.png
```

The source and processing details are also stored beside the asset in
`godot/immune/characters/gel/jelly_micro_height.LICENSE.md`.

## Material implementation

### Opaque body

`wet_gel.gdshader` samples the height map in object-space triplanar projection,
so fragmented UVs do not create seams and imported/authored meshes need no
re-authoring. Mipmapped explicit-gradient samples keep the feature stable during
minification. A grazing mask keeps the face-on core calm; the same height signal
slightly breaks up coat roughness and produces coherent wet highlights.

The V5.1 production profile disables the former bubble, microbubble, and
procedural inclusion relief. Those shader paths remain for non-production
look-dev profiles, but they are not stacked with the accepted height texture.

Custom lighting carries the authored surface colour through a varying and keeps
engine `ALBEDO` at identity. Godot's Compatibility path multiplies custom
diffuse by `ALBEDO` after `light()`, so this prevents a second body-colour
multiply. Each direct-light contribution uses `DIFFUSE_LIGHT +=` and is bounded
independently; it never assumes the accumulator survives a shadowed additive
pass.

### Clear shell

`jelly_shell.gdshader` remains one Compatibility-safe transparent second pass.
It does not sample the screen. V5.1 enforces a dielectric response:

| Control | Value |
|---|---:|
| Shell energy scale | 0.38 |
| Diffuse strength | 0.22 |
| Specular level | 0.38 |
| Emission ceiling | 0.02 |
| Alpha ceiling | 0.24 |
| Roughness floor | 0.055 |

T/B use the expanded next pass; M/N/A/D keep their authored shell geometry.
`ImmuneGelLook` applies the same bounds to generated and attached materials.

### Six-family propagation

`ImmuneGelProfiles.V5_SURFACE` is merged after legacy/family values and before
explicit call-site overrides. M/N/A/D builders also call `with_v5_surface()`, so
an authored silhouette cannot silently retain the V4 membrane response. Smoke
checks the attached runtime materials for T/B and the production M/N/A/D
adapters. The final contract prints:

```text
SMOKE_OK missions=6 families=6 save=v2 audio=ready gamepad=ready signatures=T+B traits=enrage+regen meshy=B authored_jelly=M+N+A+D gel_fizzy=T+B+M+N+A+D
```

## Direct-light topology

The Compatibility calibration is valid for `DirectionalLight3D` only, at most
three per viewport and at most one shadow-casting directional light.
`ImmuneGelLightContract` audits production scenes, isolated portraits, and test
rigs. Combat invokes this assertion in debug/editor builds; the release scene
topology is statically owned and covered by the QA probe rather than a claimed
release-build rejection layer. Before rendering, the probe proves that Omni,
Spot, and a second shadowed directional light are rejected. It then renders the
exact production/look-dev key, fill, and rim progressively.

| Active lights | Median luma | P95 peak | Dominant clipping |
|---:|---:|---:|---:|
| 0 | 0.0509 | 0.2471 | 0.00% |
| 1 shadowed key | 0.1574 | 0.5333 | 0.34% |
| + 1 unshadowed fill | 0.2331 | 0.7294 | 0.52% |
| + 2 unshadowed fills | 0.2703 | 0.8314 | 0.52% |

The final headed Godot 4.7.2 probe prints:

```text
JELLY_LIGHT_PROBE_OK topology=0+1-shadowed-key+2-unshadowed-fills direct_limit=3 shadowed_limit=1 rejected=OmniLight3D+SpotLight3D+2-shadowed identity_albedo=true
```

Evidence: `outputs/v5.1-final-validation-472/light-contract-final/` and
`outputs/v5.1-final-validation-472/logs/final-source-locked-light-probe.log`.

## Gameplay portrait and responsive HUD

The live lane character stays at scale `1.0`, with the original camera and
collision layers. `CombatHeroPortrait` uses a 336x252 own-world `SubViewport`,
one shadowed key and one unshadowed rim, no active collision, and `UPDATE_ONCE`
only while visible.

Authored M/N/A/D body, face, and membrane instances share constructed-once cached
SphereMesh, CapsuleMesh, and TorusMesh resources between live and portrait
characters; callers treat the returned meshes as read-only. Per-instance
material overrides remain separate. Smoke asserts the resource identity and the
96x48 sphere's exact type, dimensions, segment counts, and resource name.

At insufficient viewport size/aspect the portrait character is freed, the
SubViewport update mode becomes disabled, and its processing is frozen. A
Control resize callback recreates it after layout is restored. The capture
harness verifies visible -> duty sync -> forced hidden/free -> restored visible.

At aspect `<= 0.8`, the combat HUD applies a cohesive `2.25x` theme and spacing
scale under a full-rect Control root. At 720x1280 this yields roughly 14-18 px
rendered text and 44 px action buttons. Landscape metrics remain unchanged.
Portraits remain absent in all tall samples.

Final gameplay evidence covers T/B/M/N/A/D at 1280x720 and T at 720x1280:

- 21 PNGs have the requested dimensions;
- every landscape report passes 5/5 lifecycle states;
- the tall report passes 3/3 states;
- every sample has `no_hud_overlap=true`;
- T/B/M/N/D show `Mobile duty`; A shows `Relay duty`;
- capture review found no unintended static-arena composition change across
  fixed/mobile/boss for any family; this observation is not presented as a
  machine-computed pixel-identity metric.

The accepted aggregate audit independently reopens every PNG, verifies its IHDR
dimensions and SHA-256, and binds every report to the exact English locale,
MISSION-01, family, tag, stage order, duty, portrait expectation, and per-sample
checks. Evidence: `outputs/v5.1-final-validation-472/gameplay/`,
`gameplay/final-source-locked-audit.json`, and the seven
`outputs/v5.1-final-validation-472/logs/gameplay-*-source-locked.log` files.

The tall layout is locked for 720x1280, not yet for 360/390 px phone widths or
notched-device safe areas.

## Save and capture isolation

`ResearchState` resolves `--save-path=` before it loads or seeds state. The
override is accepted only in editor/debug builds; release builds keep
`user://immune_demo_save.json`. During autoload initialization, every project
QA entry under `res://tools/*.gd` or `.tscn` is detected and reserves a unique
PID/timestamp/tick run directory unless a valid explicit debug path was provided.
Isolation therefore happens before a harness can load, seed, or write.

Both explicit isolated smoke and no-argument automatic smoke pass. A malformed
explicit QA save exits `74` and remains SHA-identical; an unwritable override
also exits `74`. Normal gameplay preserves an unreadable player save and uses an
in-memory demo seed instead of overwriting it. The real save before and after the
automatic QA run is byte- and metadata-identical:

```text
SHA-256 cbd96336128406c9df490eee626c598ccf1f17c1b69e685be53b4226c63c4a11
size 859; mtime 1788075108; ctime 1788075108
```

`gameplay_shot.gd` now requires `--portrait-expected`, validates exact
family/mission selection, output directory creation, PNG/JSON writes, and saved
PNG reopen/dimensions. `crit4_probe.gd` rejects unknown/non-finite options and
also verifies its PNG; `gel_perf.gd` validates bounded inputs and reopens its
JSON report; `shot.gd` rejects a height override when the attached authored
height path is disabled. These checks stop the pipeline instead of treating
missing or mismatched evidence as success.

Save and JSON replacement use a same-directory backup-backed transaction: the
new bytes are reopened and checked against the expected schema/identity before
the backup is removed, and a valid orphaned backup is recovered on the next run.
This is recoverable for ordinary process and validation failures; it is not a
claim of power-loss durability or a filesystem-wide atomic guarantee.

## Visual and performance evidence

The accepted review set contains six views for each family plus a five-frame
half-degree T yaw sequence. An independent automated visual critic accepted the intended
stylized wet-jelly direction across all six families; future polish should
focus on a clearer shell, deeper light transport, a broader highlight, and
facial-normal cleanup rather than reintroducing dense relief.

Evidence: `outputs/v5.1-final-validation-472/family-shots/` and
`outputs/v5.1-final-validation-472/yaw/`.

The matched local implementation-cost sentinel uses ten B bodies, 60 warm-up
frames, 300 measured frames, 1920x1080, and Godot 4.7.2 Compatibility on Apple
M4 Pro:

| Metric | V5.1 gel | StandardMaterial3D | Delta |
|---|---:|---:|---:|
| CPU mean | 1.140 ms | 1.036 ms | +0.104 ms / +10.04% |
| CPU p95 | 1.496 ms | 1.358 ms | +0.138 ms / +10.16% |
| Wall mean | 2.788 ms | 2.817 ms | -0.029 ms / -1.03% |
| Wall p95 | 4.596 ms | 4.587 ms | +0.009 ms / +0.20% |

The viewport GPU timer returned zero, so this is one uncontended local CPU/wall
sentinel only; scheduler noise can be larger than small deltas. The standard
material is a cost control, not a V4 substitute. An exact matched V4 run remains
pending because the local GPU launch permission timed out twice; no V4 number is
inferred.

Evidence: `outputs/v5.1-final-validation-472/perf/B-gel.json`,
`outputs/v5.1-final-validation-472/perf/B-standard.json`, and
`outputs/v5.1-final-validation-472/perf/comparison.json`.

A separate real-scene MISSION-01 autopilot regression passes all six families:
6/6 victories, a surviving `12/12` core in every run, real projectile hits, and
the appropriate mobile/relay duty exercised. Evidence:
`outputs/v5.1-final-validation-472/balance-final-six-family.json`.

The six zh_HK mission-select captures also pass exact family/mission identity,
nonblank, write, and reopen checks. Evidence:
`outputs/v5.1-final-validation-472/mission-select/` and
`outputs/v5.1-final-validation-472/logs/final-source-locked-mission-select.log`.

## Godot 4.7.2 Web export

The official Godot 4.7.2 Web no-threads template was selectively installed from
the official export-template archive with ZIP size and CRC verification. The
source archive digest is
`f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`;
the installed-member manifest is stored at
`outputs/v5.1-final-validation-472/godot-4.7.2-web-template-manifest.json`.

The final ignored build is under
`godot/immune/build/releases/v5.1-final-validation-472/web/`. Required file
digests are:

| File | SHA-256 |
|---|---|
| `index.html` | `169edb5a9fa98e44166003a1023ba0de34a32163f0b948cc5ddc786f688f1948` |
| `index.js` | `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba` |
| `index.pck` | `4e75492dba648e66aa57237970f8770b92a6929072af1f4959c9716bed06072d` |
| `index.wasm` | `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |

The local browser gate follows research -> mission select -> B/MISSION-01 ->
mobile duty -> pause open/close. All four required resources return HTTP 200;
both profiles have exact canvas fit, no scroll, no page/console/effective
request errors, and all eight ordered events.

The report also preserves two baseline `ERR_ABORTED` preloads that were
superseded by HTTP-200 WASM/PCK requests, plus the expected SwiftShader
`ReadPixels` performance warnings. The validator classifies these separately;
they are not hidden or counted as effective request/console failures.

| Profile | Mean / p05 FPS | Renderer |
|---|---:|---|
| Baseline, 1600x900 | 119.841 / 103.093 | ANGLE Metal, Apple M4 Pro |
| 4x CPU throttle, 1280x720 | 11.284 / 7.937 | SwiftShader software Vulkan |

This is a deterministic compatibility stress, not a real low-end-hardware
benchmark. Evidence: `outputs/v5.1-final-validation-472/web-qa/report.json` and
`outputs/v5.1-final-validation-472/web-artifact-sha256.json`.

## Final validation matrix

| Gate | Accepted source-locked result |
|---|---|
| Root Node tools | 36/36 pass |
| Web UI tests | 53/53 pass |
| Web UI production build | pass; SVG fallbacks generated when optional Sharp was unavailable |
| Height generator | deterministic rerun matches checked-in PNG and locked pixel hash |
| Godot import | exit 0; no `SCRIPT ERROR`, parse/compile failure, or uppercase `ERROR` marker |
| Smoke | automatic and explicit temporary-save modes pass |
| Research HUD overflow | pass |
| Light topology | 4/4 progressive captures and all rejection cases pass |
| Family/yaw/mission capture | 36 + 5 + 6 PNGs pass strict write/reopen checks |
| Gameplay capture | 7 reports, 21 PNGs, all exact identity/lifecycle/layout checks pass |
| Balance | 6/6 MISSION-01 victories; every core remains 12/12 |
| Web export/browser | four checksum-bound files; both browser profiles pass full lifecycle |

The accepted evidence index is
`outputs/v5.1-final-validation-472/accepted-manifest.json`. Older files named
`final-source-aligned-*`, `final-rerun-*`, or without `source-locked` are retained
only as diagnostic history and are not release evidence. Godot import can emit a
longstanding non-fatal Unicode/NUL warning while scanning unrelated generated
content; the accepted log contains no script/parse/compile/error failure.

## Reproduction

Use Godot 4.7.2 stable and run captures headed with Compatibility rendering:

```sh
godot --headless --path godot/immune --import

smoke_dir="$(mktemp -d)"
godot --headless --path godot/immune --script res://tools/smoke.gd -- \
  --save-path="$smoke_dir/state.json"

probe_dir="$PWD/outputs/jelly-light-probe"
godot --path godot/immune --resolution 1024x1024 \
  --script res://tools/smoke.gd -- \
  --jelly-light-probe --out="$probe_dir"

gameplay_dir="$PWD/outputs/jelly-gameplay"
godot --path godot/immune --resolution 1280x720 \
  res://tools/gameplay_shot.tscn -- \
  --out="$gameplay_dir" --family=T --mission=MISSION-01 \
  --tag=T-v51 --locale=en --portrait-expected=visible

godot --headless --path godot/immune --export-release Web \
  build/releases/v5.1-final-validation-472/web/index.html
npm run test:web-release -- \
  --artifacts=godot/immune/build/releases/v5.1-final-validation-472/web \
  --out=outputs/v5.1-final-validation-472/web-qa --duration-ms=6000
```

## Honest remaining gates

1. Run a checksum-locked six-family human-playtest campaign only after a V5.1
   commit has passed remote Godot 4.7.2 CI and produced all four platform artifacts.
2. Repeat the exported Web/native build on an agreed real lower-end Windows or
   Web machine. SwiftShader is stress evidence, not hardware evidence.
3. If approved, run the exact matched V4/V5 performance pair from separate,
   checksum-identified source trees. Until then, use only the standard-material
   cost sentinel.
4. Add a narrow-phone stacked layout and display-safe-area handling before
   claiming 360/390 px or notch support.
5. Imported T geometry still facets around some facial features. Fix geometry or
   normals rather than raising texture depth or emission.
6. Four-platform V5.1 export/campaign, push, tag, release, notarization, and
   storefront publication are not performed locally in this tranche.
