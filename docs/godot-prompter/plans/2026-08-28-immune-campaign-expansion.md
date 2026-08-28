# IMMUNE campaign expansion implementation plan

1. Extend the Resource schemas with neutral-default progression, signature-hit and
   pathogen-trait fields.
2. Carry family hit data through `PlasmaBolt`; apply per-target effects inside
   `Bacterium` while retaining the legacy `take_hit` API.
3. Author three difficulty resources, six pathogen profiles, three mission
   resources and three thin mission scenes.
4. Add sequential visibility/launch gating to the mission table and expand save
   validation to six mission IDs without changing the save shape.
5. Expand smoke contracts, import twice, run smoke/overflow, then run a quick and
   full deterministic balance matrix. Tune resources only; do not fork runtime
   logic per mission.
