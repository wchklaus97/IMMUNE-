# IMMUNE playable demo specification

Status: completed. The delivered demo exceeds this original one-unit/one-arena scope; see `CODEX_HANDOFF.md` for the current contract.

## Player promise

The player can inspect permanent immune research, deploy the approved T-cell into one compact mission, transform it between turret and mobile duties, complete three distinct objectives, and bring rewards back to the network.

## Scope

- Keep the existing 200-node catalog and six-family art direction.
- Ship one polished playable unit: `CHAR-BASE-T`.
- Ship one arena containing three sequential objectives:
  - Core Defense: eliminate the first wave before the immune core breaks.
  - Expedition: transform to mobile duty, advance to the cleanse zone, and hold it.
  - Total War: eliminate one boss pathogen.
- Show objective, phase, progress, core health, controls, and a result panel.
- Persist research completion, revealed/tracked/selected nodes, resources, campaign level, and discovery flags.
- Tune the T-cell material toward a soft wet jelly: warm translucent body, broad controlled highlights, subtle cellular microtexture, restrained rim emission.

## Out of scope

- Completing all 31 character models or all campaign missions.
- Final production balance, online services, multiplayer, monetization, or store packaging.
- Replacing already approved character geometry.

## Acceptance criteria

- No syntax, catalog, or scene-load failures in automated tests.
- Web tests pass and the single-file build is reproducible without a creator-specific Windows path.
- All six base character scenes parse in Godot.
- The combat FSM reaches Defense, Expedition, Total War, and Victory deterministically in smoke tests.
- Victory changes ResearchState rewards and a save/load round-trip restores them.
- Gameplay uses named Input Map actions rather than raw keycodes.
- The gel tuning stays within explicit anti-neon thresholds checked by smoke tests.
