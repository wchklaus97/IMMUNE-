# IMMUNE campaign expansion specification

## Outcome

Extend the vertical slice from three to six authored missions while preserving one
data-driven combat runtime. Add readable enemy traits and T/B signature-hit rules
that travel through real projectiles and the pathogen damage contract.

## Player-facing scope

- MISSION-04 introduces low-health acceleration and recommends T execution.
- MISSION-05 introduces out-of-fire regeneration and recommends B mark stacking.
- MISSION-06 combines both traits as the demo campaign capstone.
- MISSION-06 clears its escort wave before the final duel; the shared runtime uses
  the mission's enemy cap instead of a hard-coded add count.
- Missions unlock in order through `required_mission_id`; locked missions remain
  visible at the mission table.
- The family panel names and explains each signature shot.

## Runtime contracts

- Mission content remains `ImmuneMissionData`; no copied combat scripts.
- Pathogen traits are numeric fields on `PathogenProfile` and remain disabled at
  their neutral defaults for existing content.
- `PlasmaBolt` carries the immutable family hit profile. `Bacterium` owns mutable
  per-target state such as antibody marks and regeneration delay.
- T execution adds two damage only when pre-hit HP is at or below 30%.
- B's first hit establishes a mark; subsequent hits add one damage per existing
  mark up to two.
- A failed/duplicate projectile collision cannot apply either mechanic twice.

## Acceptance

- Six unique missions load, have increasing difficulty ranks, valid scenes and a
  strict previous-mission chain.
- Smoke tests exercise T execution, B mark caps, enrage speed, regeneration and
  all six mission contact paths.
- Deterministic T/B autopilot wins all missions, preserves the core and produces
  increasing average mission durations.
