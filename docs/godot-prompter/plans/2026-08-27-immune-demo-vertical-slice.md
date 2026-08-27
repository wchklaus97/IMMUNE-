# IMMUNE vertical-slice implementation plan

Status: completed and expanded to three authored missions, six playable families, and four release platforms. See `CODEX_HANDOFF.md` for the current release state.

## Scene tree

```text
ResearchNetwork (Control)
  -> CombatLane (Node3D)
       WorldEnvironment / lights / Camera3D
       ImmuneCore (StaticBody3D)
       CHAR-BASE-T (CharacterBody3D)
       Enemies and projectiles
       CleanseZone (MeshInstance3D)
       CanvasLayer
         HUD
         ResultPanel
```

## Signals and state flow

```text
ResearchState.state_changed -> research HUD refresh
Bacterium.died -> CombatLane objective progress
ImmuneCore.hp_changed/breached -> combat HUD / defeat
CombatLane.phase_changed -> objective and arena refresh
CombatLane.combat_completed -> ResearchState rewards -> versioned save
```

## Work sequence

1. Repair JavaScript syntax, portable asset generation, offline bundle build, and BOM scene failures.
2. Add named research/combat/movement actions to `project.godot` and migrate handlers.
3. Add versioned JSON persistence and reward helpers to `ResearchState`.
4. Extend `CombatLane` into a three-phase FSM with a cleanse objective, boss, results, and reward return path.
5. Make bacterium statistics configurable for wave and boss roles.
6. Tune wet-gel defaults to reduce clipped neon rim/specular and keep subtle dimples visible in motion.
7. Extend smoke tests for material bounds, phase flow, rewards, and save/load.
8. Run web tests/build, Godot import/smoke, and scene launches; update this handoff with results.
