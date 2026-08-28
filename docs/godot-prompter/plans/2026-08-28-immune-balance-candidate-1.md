# IMMUNE balance candidate 1 implementation plan

Status: completed.

## RED evidence

1. Accelerated matrix runs exposed MISSION-03 timing out at 120 game seconds without changing phase.
2. Contact inspection showed scaled enemy physics bodies stopping outside a fixed `1.15` reach threshold.
3. Projectile telemetry occasionally reported more hits than shots because one bolt could receive multiple `body_entered` callbacks before deferred deletion.
4. After contact repair, MISSION-03 initially ended in defeat for both families; B also suffered a four-hit breakpoint against armored enemies.

## GREEN work sequence

1. Added opt-in, local-only `CombatPlaytestTelemetry` and wired it to real combat events.
2. Added `balance_matrix.gd` with real scenes, autopilot duty changes, seeded trials, timeout detection, JSON evidence, and strict invariants.
3. Separated enemy visuals from physics scale and derived core contact distance from authored collision radii.
4. Made plasma bolts one-hit objects with an explicit spent guard.
5. Added smoke regressions for contact damage, unscaled physics roots, one-hit projectiles, and telemetry snapshots.
6. Tuned MISSION-03 health, speed, spawn cadence, defense count, armored core damage, and B projectile cadence/damage.
7. Ran the full 12-run real-time matrix and confirmed a monotonic mission-duration ladder with 12/12 victories.
8. Made web-generated artifacts byte-for-byte reproducible across consecutive builds.

## Verification commands

```bash
godot --headless --path godot/immune --script res://tools/smoke.gd
godot --headless --path godot/immune --script res://tools/balance_matrix.gd -- \
  --out=outputs/playtests/balance-candidate-1-12run.json --trials=2
cd ui/immune-research-network
npm test
npm run build
```

Balance runs must stay at the default `1.0` time scale for tuning. Higher values remain available only for diagnostic experiments because discrete projectile physics can tunnel at accelerated simulation speed.
