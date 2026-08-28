# IMMUNE balance candidate 1 specification

Status: implemented and validated on Godot 4.6.1 Compatibility; project target remains Godot 4.7.2 stable.

## Player outcome

T and B families can complete all three authored missions without a spawn/contact soft-lock. Mission length rises visibly from MISSION-01 through MISSION-03, and MISSION-03 applies meaningful core pressure without turning the automated baseline into a forced loss.

## Runtime telemetry contract

Telemetry is opt-in, held in memory, and never uploaded. A snapshot records:

- mission, family, build tag, platform, renderer, and Godot version;
- victory/end state, total time, phase time, and fixed/mobile duty time;
- shots, hits, accuracy, damage, kills, boss kills, and duty switches;
- core health/damage and mean/max frame time.

Normal player sessions do not write telemetry files. The headless balance harness owns local JSON report output.

## Balance acceptance criteria

- Run the real mission scenes, spawn logic, physics contacts, projectiles, combat FSM, and an input-equivalent autopilot at real-time `1.0` simulation speed.
- Complete 12 runs: three missions × T/B × two seeded trials.
- Every run reaches victory, defeats exactly one boss, exercises both duties, fires and hits real projectiles, and leaves the core above zero HP.
- `shots_hit` never exceeds `shots_fired`; accuracy stays in `[0, 1]`.
- Mean completion time rises MISSION-01 < MISSION-02 < MISSION-03 for each family.
- The matrix report contains no failures.

## Candidate 1 evidence

Report: `outputs/playtests/balance-candidate-1-12run.json` (local generated evidence).

| Mission/family | Victories | Mean time | Minimum core | Mean accuracy |
|---|---:|---:|---:|---:|
| MISSION-01 / T | 2/2 | 22.367 s | 12/12 | 95.0% |
| MISSION-01 / B | 2/2 | 20.992 s | 12/12 | 100.0% |
| MISSION-02 / T | 2/2 | 34.534 s | 12/12 | 98.3% |
| MISSION-02 / B | 2/2 | 35.617 s | 12/12 | 91.6% |
| MISSION-03 / T | 2/2 | 51.509 s | 8/12 | 100.0% |
| MISSION-03 / B | 2/2 | 53.800 s | 6/12 | 92.6% |

## Fixed defects

- Enemy visual scale no longer scales `CharacterBody3D` or its physics body. Collision size is authored directly and core contact distance is derived from both radii.
- A plasma bolt becomes spent on its first accepted hit, disables monitoring, and cannot damage or report a hit twice.
- Web asset generation no longer injects wall-clock time by default. `SOURCE_DATE_EPOCH` can add a reproducible release timestamp.

## Out of scope

- Automated telemetry upload, player identity, or analytics services.
- Claiming human fun/usability validation from autopilot results.
- Spending Meshy credits. Paid generation remains an explicit approval gate.
