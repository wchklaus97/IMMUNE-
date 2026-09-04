# Jelly V8.2 motion lab result

Date: 2026-09-01

Base candidate: `c136ed9`

Plan checkpoint: `75b60f2`

Implementation checkpoint: `8fff33b`

Branch: `feature/v8-2-jelly-motion`

Status: implemented local candidate; not pushed, tagged, exported, signed,
notarized, uploaded to Steam, or published

## Outcome

V8.2 keeps the stable gameplay controller, collision, V8.1 motion-truth
foundation, and one-shell Compatibility renderer. It makes the character read
more like a continuously moving viscous mass by advecting the normally-lit
interior core and the one macro-bubble field through a shared body coordinate.
Idle and movement both retain flow; movement adds direction, lag, squash,
contact compression, and turn shear without moving or scaling the gameplay
collision.

The first dense-interior tuning was rejected during review. The accepted R2
tuning uses a deeper normally-lit core, fewer and larger low-contrast bubbles,
and quieter suspended fleck, inclusion, caustic, and fibre fields. Lowering
global exposure was also rejected because it only darkened the character
without improving the reference match.

V8.2 is the project candidate default:

```text
immune/visual/gel_look="v8_2"
```

Every previous selector remains explicit and testable:

```text
IMMUNE_GEL_LOOK=v5
IMMUNE_GEL_LOOK=v6
IMMUNE_GEL_LOOK=v7
IMMUNE_GEL_LOOK=v8
IMMUNE_GEL_LOOK=v8_1
IMMUNE_GEL_LOOK=v8_2
```

The V8.1 source history, release candidate record, archives, and R1 evidence
were not deleted or overwritten.

## Rendering contract

V8.2 adds three zero-default wet-core controls after the preserved V8.1 profile:

- `liquid_core_color_mix` moves interior density through normally-lit colour;
- `liquid_core_roughness_mix` changes the optical response with that density;
- `liquid_bubble_advection` moves the existing macro-bubble field with the same
  shared body flow.

Only V8.2 enables these controls. V5 through V8.1 keep all three at zero. The
authored mipmapped membrane relief stays in primitive-local coordinates, while
only interior fields advect. The renderer still uses one opaque wet core and
the existing one transparent `BodyShell`; it adds no raymarch, screen texture,
nested volume, or additional silhouette pass. The second procedural
microbubble field remains disabled.

The accepted common profile reduces suspended detail to:

| Control | V8.2 value |
|---|---:|
| authored fleck strength / budget | 0.10 / 0.035 |
| authored inclusion strength / budget | 0.16 / 0.045 |
| authored caustic strength / budget | 0.12 / 0.025 |
| authored fibre strength / budget | 0.18 / 0.045 |
| liquid flow emission / budget | 0.30 / 0.052 |
| bubble scale / density | 4.8 / 0.12 |
| bubble depth / shell emission | 0.0004 / 0.012 |

T and B receive the strongest accepted core and bubble advection. M, N, A, and
D use bounded family-specific phases, core mixes, roughness mixes, bubble
scales, and densities from the same additive profile.

## Motion and animation contract

V8.1 remains exactly 12 clips. V8.2 is exactly 14 clips:

```text
idle, plant, uproot, move, hit, attack, relay_open, relay_close,
move_start, move_stop, relay_glide, skill_cast, victory, defeat
```

`victory` lasts 1.30 seconds and `defeat` lasts 1.18 seconds. Both are
presentation-only, non-looping clips with terminal priority 100. They reject
later combat and duty requests and retain their final authored sample after
playback ends. Combat core shock reuses the existing `hit` clip without owning
or duplicating core damage resolution. Mission victory and defeat enter their
matching terminal presentation.

The basic attack release remains exactly 0.345 seconds. The active-skill release
remains exactly 0.48 seconds. V8.2 does not change callback ordering or gameplay
commit authority.

## Production review tooling

- `anim_preview.gd` defaults to the production authored character. A retired
  generated body requires `--body=legacy-glb`.
- `gel_preview.gd` defaults to the selected family's authored reference body.
  A generated GLB requires both `--source=legacy-glb` and an explicitly
  whitelisted `--mesh`.
- `gel_perf.gd` defaults to the exact production character and records source,
  material, mesh, and geometry identity in schema-v2 reports.
- `shot.gd` now passes production source/body/duty selectors, samples the true
  endpoint of non-looping clips, and supports a per-sample velocity sequence.
  The latter captures a real 180-degree gameplay reversal rather than rotating
  the review camera.

`tools/smoke.gd` locks these default and legacy-opt-in contracts so preview or
profiling cannot silently certify a retired generated mesh.

## Visual evidence

No previous evidence was overwritten.

- Rejected and exploratory R1 comparisons and parameter sweeps:
  `outputs/v8.2-jelly-motion/review-r1/`
- Accepted R2 production captures:
  `outputs/v8.2-jelly-motion/review-r2/`
- T/B idle and move flow overview:
  `outputs/v8.2-jelly-motion/review-r2/comparisons/TB-idle-move-flow-r2.png`
- T/B true 180-degree reversal:
  `outputs/v8.2-jelly-motion/review-r2/comparisons/TB-180-reversal-r2.png`
- T and B motion libraries:
  `outputs/v8.2-jelly-motion/review-r2/comparisons/T-motion-library-r2.png`
  and `B-motion-library-r2.png`
- Six families plus A Relay:
  `outputs/v8.2-jelly-motion/review-r2/comparisons/all-six-plus-A-relay-r2.png`
- T/B terminal final samples:
  `outputs/v8.2-jelly-motion/review-r2/comparisons/TB-terminal-final-holds-r2.png`

The R2 directory contains production-scene static, idle, move, reversal,
start, stop, attack, skill, hit, victory, and defeat captures for T/B, plus
production static captures for M/N/A/D and an explicit A Relay capture.

## Verification completed

Verified locally with official Godot
`4.6.1.stable.official.14d19694e`:

- warm project import with no script, parse, compile, or engine error;
- default V8.2 six-family smoke, including exact clip counts, release markers,
  terminal ownership, combat integration, collision isolation, rendering
  profile, one-shell limits, and production-tool identity;
- explicit V5, V6, V7, V8, and V8.1 rollback smoke, each reporting its exact
  selector;
- executable screenshot-tool contract for scalar velocity parsing, per-sample
  reversal parsing, and fail-closed preview provenance;
- headed scalar and sequence captures, plus shot/direct exit-code-2 rejection
  of the unsupported `B + legacy-glb` pairing;
- six-family MISSION-01 balance matrix: six runs, six victories, core HP 12/12;
- 1920x1080 zh_HK/en layout and overflow contract;
- 64 repository release/tool tests;
- 53 research-network UI tests;
- GitHub Actions workflow validation with `actionlint`;
- independent Godot-specialist final review with every High, Medium, and Low
  finding resolved and no remaining actionable source defect;
- `git diff --check`.

The tests total 117 Node assertions plus the Godot import, selector matrix,
gameplay simulation, and layout checks.

## Honest visual boundary

V8.2 improves material continuity and motion. It does not remodel the authored
base-body topology. Compared with the concept images, the current production
characters remain too spherical, use separate rounded limb primitives, and use
round eye/mouth geometry instead of the concepts' organic silhouette and almond
face shapes. That gap cannot be solved by further exposure, bubble, or shader
parameter tuning alone. The next visual milestone should be a separately
versioned authored mesh/face-topology pass that keeps this V8.2 material and
motion system.

## Release gates still open

This local source candidate is not a publishable Steam build yet:

- Godot 4.7.2 is not installed locally, so the required official 4.7.2 import
  and smoke have not run.
- The data volume has under 0.4 GiB free. The plan requires at least
  2 GiB before same-machine GPU profiling and at least 8 GiB before a four-
  platform export while retaining 5 GiB afterward.
- Therefore the V8.1-versus-V8.2 headed GPU/frame comparison, Web lifecycle,
  four-platform export, native smoke, signing, notarization, Steam upload, and
  owner publication authorization remain open.
- No historical output will be deleted merely to bypass those storage gates.

Passing source tests is evidence for the implementation, not permission to call
the game 100% published or Steam-ready.
