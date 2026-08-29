# Combat presentation and Compatibility/Web regression

Date: 2026-08-29

## Outcome

The three-phase combat lane now reads as a biological arena instead of a bare
test strip. The camera, membrane rails, lane veins, side tissue, organoids,
cleanse-zone signals, mission briefing, vitals, and bottom action tray were
polished without changing collision, pathing, damage, health, spawning, mission
timers, rewards, or research progression.

The same pass fixed an exported-Web rendering defect in Antibody Construct's
Relay duty. Switching duty during Core Defense could cover most of the arena
with opaque black triangles until the phase changed. The shipping RelayDish now
uses named, shadow-free, fully opaque accent meshes; its thin `RelayRing` no
longer runs the derivative-heavy wet-gel shader or the transparent material
pipeline. Empty `KitSwapBurst` particle placeholders are also prevented from
submitting an undefined GPU draw.

No Meshy request was made and no generation credit was consumed.

## Presentation architecture

`combat_lane.gd` keeps the gameplay floor and collision body unchanged. Its new
`ArenaVisuals` branch contains only lightweight `MeshInstance3D` children:

- two side-tissue beds and two outer membrane rails;
- two lane veins;
- twelve alternating organoids;
- one core membrane ring and one player-home ring.

`CleanseVisuals` adds two rings and eight signal markers around the existing
cleanse trigger. Their material intensity follows the existing mission phase;
they do not own collision or phase logic.

The combat camera remains fixed at a 58-degree field of view. HUD controls keep
their existing actions and input mappings, but now sit in named, styled panels.
The three bottom controls retain 220-by-52 logical hit targets and are visible at
both desktop and 1280x720 output sizes.

## Renderer failure analysis

The initial shadow-only hypothesis was insufficient. Headless smoke confirmed
RelayDish shadows were disabled, but real Chromium input still reproduced the
blackout. The decisive isolation was replacing the thin relay torus's wet-gel
ShaderMaterial with the metallic relay accent. Saved browser PNGs then retained
the full side tissue and organoids immediately after `Space`, during Core
Defense, before any phase material refresh.

The final contract is deliberately narrow:

- RelayDish geometry never casts world shadows;
- `RelayRing` is a named `MeshInstance3D` with an opaque
  `StandardMaterial3D`;
- unconfigured GPU particle placeholders remain non-emitting; and
- a future configured particle effect may still run when it provides both a
  process material and a draw mesh.

## Regression evidence

- Godot smoke: six missions and six families, including the new presentation,
  hit-target, RelayDish material, shadow, and particle contracts.
- Headed batch: six families, two resolutions, three combat states each;
  36/36 PNGs, 12 presentation-contract reports, and zero shutdown leaks.
- Exported Web: real keyboard flow through research, mission desk, MISSION-01,
  and A Fixed-to-Relay duty at 1600x900 and 1280x720.
- Browser layout: canvas exactly matches both viewports with no document scroll.
- Browser diagnostics: zero errors, zero warnings, and every requested local
  resource returned HTTP 200 or a valid cache 304.
- Localization: two CSV files / 595 rows and 200 catalog nodes / 406 generated
  research rows.
- Web application: 53/53 tests and successful production build.
- Layout: Traditional Chinese and English overflow checks pass at 1920x1080.
- Balance: T/B MISSION-01 plus MISSION-06 passes 4/4; MISSION-01 across all six
  families passes 6/6; every run keeps the Core at 12/12.
- Release: Windows, Linux, macOS, and Web exports rebuilt sequentially. The
  universal macOS app passes strict signature verification and native
  `RELEASE_SMOKE_OK platform=macOS nodes=200`.

Local ignored evidence is stored under `outputs/combat-polish-20260829/` and
`outputs/player-qa-20260829/`.

## Remaining product gates

This is a demo-quality presentation and compatibility pass, not a store-release
claim. Developer ID signing/notarization, storefront metadata, non-zero GPU
timing on a backend that exposes it, and longer unscripted human playtests remain
external or product-validation work.
