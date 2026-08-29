# Research catalog localization and six-family regression

Date: 2026-08-29

## Outcome

The playable Godot demo now has complete Traditional Chinese and English text
coverage for the permanent research catalog: 200 node names, 200 node
descriptions, and six campaign names. Research search/detail/status/resource and
effect copy follows the active locale at runtime, including a live locale switch
while the research scene is already open.

The deterministic real-scene balance harness now also covers all six playable
families in MISSION-01. That expansion exposed and fixed an A-family projectile
aiming defect and an autopilot duty mismatch. A focused MISSION-06 retest then
identified a small endgame throughput deficit, resolved by changing A's fixed
fire cooldown from 0.62 s to 0.58 s, matching its relay cooldown.

## Localization contract

`tools/generate_catalog_localization.mjs` reads the canonical Godot JSON catalog
and emits `godot/immune/translations/research_catalog.csv`. The output contract
is deliberately strict:

- exactly 200 catalog nodes;
- one semantic `RESEARCH_<NODE_ID>_NAME` key and one
  `RESEARCH_<NODE_ID>_DESCRIPTION` key per node;
- six `RESEARCH_CAMPAIGN_<LEVEL>_NAME` keys;
- exactly 406 non-empty rows with no duplicate keys;
- no Han characters in the English column; and
- byte-for-byte drift detection through `--check` in CI.

Godot imports the CSV as separate `zh_HK` and `en` Translation resources.
`Catalog.localized_node_name()`, `Catalog.localized_node_description()`, and
`Catalog.localized_campaign_level_name()` are the only display accessors. If a
translation resource is missing or a key is unresolved, the accessors retain the
catalog's authored Traditional Chinese source text as a safe fallback.

The remaining research interface strings use semantic keys in `game.csv`:
eligibility, hidden-state copy, costs, resources, family roles, universal
domains, status chemistry, stat effects, duty qualifiers, navigation, and
campaign metadata. The research scene rebuilds its generated controls only when
the effective locale changes, then restores its home view and selected-node
detail.

## A-family defect and correction

### Observed failure

The first real-time six-family MISSION-01 run produced 46 A shots, zero hits,
and a destroyed Core. Visual/body smoke tests had passed because the failure was
in combat trajectory calculation, not model import or duty assembly.

### Root cause

`combat_lane.gd::_try_fire()` flattened the complete muzzle-to-target vector to
the ground plane before assigning projectile velocity. A's authored body hovers,
so its `WeaponSocket` is elevated. Every projectile retained the elevated muzzle
height and travelled horizontally above the pathogen collision centre.

### Fix

Range and body-facing calculations still use a horizontal vector. Projectile
velocity now uses the full three-dimensional muzzle-to-target vector, allowing
the bolt to descend into the target. The deterministic autopilot also requests
A's valid `relay` expedition duty instead of attempting the unavailable
`mobile` duty every physics frame. The matrix validates `relay` duty time for A
and `mobile` duty time for the other five families.

An attempted 8x-engine-speed matrix was rejected as invalid evidence: accelerated
physics distorted collision, movement, and autopilot timing and generated false
failures. Balance evidence must remain at the real 1x simulation rate.

## Deterministic balance evidence

All runs used one trial, real 1x simulation speed, real projectiles, the normal
three-phase combat scene, and the automated duty cycle.

| Mission | Family | Duration | Shots / hits | Core | Result |
|---|---:|---:|---:|---:|---|
| MISSION-01 | T | 21.833 s | real hits | 12/12 | Victory |
| MISSION-01 | B | 20.033 s | real hits | 12/12 | Victory |
| MISSION-01 | M | 20.833 s | real hits | 12/12 | Victory |
| MISSION-01 | N | 20.533 s | real hits | 12/12 | Victory |
| MISSION-01 | A | 22.400 s | 29 / 28 | 12/12 | Victory |
| MISSION-01 | D | 20.200 s | real hits | 12/12 | Victory |
| MISSION-06 | N | 87.150 s | 165 / 165 | 12/12 | Victory |
| MISSION-06 | D | 87.767 s | 106 / 106 | 12/12 | Victory |
| MISSION-06 | A | 95.467 s | 164 / 164 | 12/12 | Victory |

The unchanged T/B endgame sentinel still passes after the trajectory correction:
T MISSION-06 completes in 89.750 s and B MISSION-06 in 81.283 s, both with
12/12 Core health. A's MISSION-01 and MISSION-06 pair has an increasing duration
ladder and passes all matrix invariants.

## Automated gates

Local verification completed with Godot 4.6.1 and the Web workspace:

- localization generator drift check: 200 nodes / 406 rows;
- Godot smoke: all 400 node fields, six campaigns, and a live `zh_HK` → `en`
  → `zh_HK` research-scene switch;
- 1920x1080 layout/label check in both locales;
- 53/53 Web Node tests and production build;
- real-time MISSION-01 six-family matrix;
- focused N/D/A MISSION-06 and T/B MISSION-01/MISSION-06 sentinels;
- sequential Windows, Linux, macOS, and Web release exports with clean logs; and
- exported macOS native `RELEASE_SMOKE_OK platform=macOS nodes=200`.

CI now runs both `node tools/generate_catalog_localization.mjs --check` and a
bounded MISSION-01 six-family regression in addition to the existing T/B first /
final-mission balance sentinel.

## Remaining product gates

This tranche does not claim store readiness. Longer human play sessions across
all families, non-zero GPU timing on a backend that exposes it, Developer ID /
notarization credentials, and storefront metadata remain external validation or
credential gates. N/A/D Meshy generations remain optional comparisons and still
require a separate explicit five-credit approval per asset; the playable demo
does not depend on them.
