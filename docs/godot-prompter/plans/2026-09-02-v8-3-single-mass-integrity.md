# V8.3 Single-Mass Integrity Plan

Date: 2026-09-02  
Branch: `feature/v8-3-single-mass-integrity`  
Foundation: V8.2 checkpoint `400c4f5`

## Problem

The production body is visually assembled from overlapping sphere primitives.
Arms, feet, and the D-family crown are separate meshes, so squash, turns, and
terminal poses can expose seams or make parts read as detached cells. The V8.2
macro-bubble field can add another unwanted small-cell cue.

## V8.3 contract

- Keep V5, V6, V7, V8, V8.1, and V8.2 selectors exact and runnable.
- Add `v8_3` as a new rollback-safe selector and eventual project default.
- Render each family with one watertight gel `Body` mesh plus one matching clear
  `BodyShell`; no independent gel arms, feet, crown lobes, or bubble meshes.
- Sculpt family silhouette cues into the continuous body surface.
- Disable macro bubbles, microbubbles, loose inclusions, and duty-burst particles
  in V8.3 while retaining continuous idle and locomotion liquid flow.
- Preserve face, gameplay collision, weapon socket, duty logic, and all fourteen
  V8.2 animations.
- Clamp clip and runtime deformation so no sampled frame becomes inverted,
  collapsed, detached, or unreasonably flat.

## Implementation slices

1. Add a cached procedural single-mass mesh generator with deterministic family
   profiles and a shared mesh for the core and membrane.
2. Route only V8.3 authored bodies through the new topology.
3. Add the clean-volume material profile and integrity motion guard rails.
4. Add smoke contracts for topology, disabled loose detail, collision isolation,
   and deformation bounds across all six families and fourteen clips.
5. Capture T/B stress states and a six-family lineup into a new V8.3 evidence
   directory without overwriting prior output.
6. Run default and all rollback-selector smokes, performance checks when local
   disk/tooling permits, then record review results and checkpoint commits.

## Acceptance gates

- Exactly one visible wet-gel body surface per family.
- Exactly one matching membrane surface per family.
- Zero `Arm*`, `Foot*`, `Crown*`, `Bubble*`, or emitting `KitSwapBurst` geometry
  in the V8.3 authored body contract.
- All core animation scale samples remain positive and within the V8.3 bounds.
- The physics collision transform and shape do not follow visual deformation.
- Default V8.3 smoke and V5-through-V8.2 rollback smoke all pass.
- Previous source checkpoints, selectors, and evidence files remain untouched.
