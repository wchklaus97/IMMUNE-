# IMMUNE campaign expansion — candidate 1 results

Updated: 2026-08-28

## Outcome

The campaign expansion candidate passes the deterministic real-scene balance
matrix across all six missions for T and B. Every run exercised the production
mission FSM, physics, projectiles, fixed/mobile duty switching, regular enemy
contact, and a boss kill. No simulation time scaling was used.

| Mission | Family | Result | Time | Core HP | Shots / hits |
|---|---|---:|---:|---:|---:|
| MISSION-01 | T | Victory | 21.833 s | 12/12 | 29 / 28 |
| MISSION-01 | B | Victory | 20.033 s | 12/12 | 14 / 14 |
| MISSION-02 | T | Victory | 31.383 s | 12/12 | 53 / 52 |
| MISSION-02 | B | Victory | 33.117 s | 12/12 | 33 / 30 |
| MISSION-03 | T | Victory | 50.367 s | 8/12 | 86 / 86 |
| MISSION-03 | B | Victory | 49.300 s | 10/12 | 49 / 45 |
| MISSION-04 | T | Victory | 68.183 s | 8/12 | 117 / 117 |
| MISSION-04 | B | Victory | 59.467 s | 10/12 | 55 / 51 |
| MISSION-05 | T | Victory | 85.733 s | 6/12 | 138 / 138 |
| MISSION-05 | B | Victory | 76.933 s | 9/12 | 66 / 61 |
| MISSION-06 | T | Victory | 89.750 s | 12/12 | 141 / 141 |
| MISSION-06 | B | Victory | 81.283 s | 12/12 | 61 / 56 |

## Candidate changes

- MISSION-04 introduces low-health enrage and uses a 4.0-second defense spawn interval.
- MISSION-05 introduces out-of-fire regeneration and uses a 4.8-second interval.
- MISSION-06 combines both traits, uses a 5.8-second interval, and caps the
  Total War add population at one so the final duel tests sustained boss focus
  rather than target-starvation noise.
- Regular enemy core contact damage is one in missions 4–5 and two in mission 6.
- T executes targets below 30% health for +2 damage.
- B marks a target on hit; prior stacks add +1 damage each up to two stacks.

## Regression policy

The full 12-run report is intentionally local (`outputs/playtests/` is ignored).
CI runs a bounded four-run sentinel covering MISSION-01 and MISSION-06 with both
T and B. Run the complete matrix before changing mission timings, enemy traits,
projectile behavior, duty transitions, or either family signature.

```bash
godot --headless --path godot/immune --script res://tools/balance_matrix.gd -- \
  --out=outputs/playtests/campaign-expansion-candidate-1.json --trials=1
```
