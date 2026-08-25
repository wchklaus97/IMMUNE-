# Codex handoff — CHAR-BASE-T 3D lock

**Read this first.** Then read `gauntlet-workbench.md` and skill
`.agents/skills/immune-3d-lock/SKILL.md`.

## Mission (one sentence)

Lock `CHAR-BASE-T` as a Godot-ready wet-gel combat character that matches
`godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png` on head marks,
bell silhouette, translucent gel material, and readable pore through animations.

## User intent

Cursor session built the pipeline and passed head geometry + animations.
**Material round 5 and silhouette (P1b) were in flight; integration (P4) never
ran.** User is handing off to Codex to finish and ship.

## Start here (Codex)

1. Read this file
2. Read `gauntlet-workbench.md` (live log + evidence pointers)
3. Read `.agents/skills/immune-3d-lock/SKILL.md` + `WORKFLOW-ZH.md`
4. Open evidence gallery: `npm run serve` → http://127.0.0.1:5180/build/gallery/
5. Use **`gauntlet-loop`** for any quality work — builder and critic must be
   separate subagents; no self-grading

**Suggested first message to Codex:**

```
Continue CHAR-BASE-T 3D lock from .agents/HANDOFF.md.
Use gauntlet-loop + immune-3d-lock.
Priority: (1) finish P2 material r5 critic if missing,
(2) P1b silhouette, (3) P4 integrate mesh+gel+anim into character.tscn.
Do not regenerate Tripo mesh from scratch.
```

---

## Status at handoff

| Piece | ID | Status | Evidence |
| ----- | -- | ------ | -------- |
| P1 Head marks (pore, eyes, mouth, nose) | geometry | **WINS** critic `9be95701` | `build/shots/t-fix/`, `build/ref-crops/` |
| P1b Silhouette (bell, wavy skirt, hooked arms) | geometry | **NOT DONE** — was building | `build/ref-crops/sil-overlay.png` |
| P2 Wet-gel material | shader | **LOSES** r1–r4; **r5 built, critic may be incomplete** | `build/shots/t-gel-r5/`, `build/r5/strip-front.png` |
| P3 Gel animations (8 clips, no rig) | anim | **WINS** critic `e711c749` | `build/shots/t-anim/` |
| P4 Integration (one scene, game-ready) | integrate | **NOT STARTED** | `character.tscn` still placeholder sphere |

### What “done” means vs what exists

| Goal | Done? |
| ---- | ----- |
| Forehead flush dish pore (not third eye) | Yes |
| Symmetric eyes, no nose bump, clean mouth | Yes |
| Bell + wavy skirt + hooked tapered arms | **No** |
| Wet-gel material vs concept (not plastic) | **Close, not locked** (r5 pending/failed critic) |
| Animations, pore readable in motion | Yes |
| GLB in `character.tscn` with gel shader in game scenes | **No** |
| ACES tonemapping in combat/preview scenes | **No** |

---

## Key assets

| Asset | Path |
| ----- | ---- |
| Concept bar | `godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png` |
| Tripo baseline GLB | `godot/immune/characters/base_t/CHAR-BASE-T-tripo-5k.glb` (5044 tris) |
| Fixed geometry GLB | `godot/immune/characters/base_t/CHAR-BASE-T-fix.glb` (7522 tris) |
| Gel shader | `godot/immune/characters/gel/wet_gel.gdshader` |
| Gel plumbing | `godot/immune/characters/gel/gel_look.gd`, `family_look.gd` |
| Anim system | `godot/immune/characters/gel_anim.gd`, `character_root.gd` |
| Character scene (placeholder!) | `godot/immune/characters/base_t/character.tscn` |
| Preview scenes | `godot/immune/tools/gel_preview.tscn`, `anim_preview.tscn` |
| Render harness | `godot/immune/tools/shot.gd` + `shot.tscn` — **do not edit** |
| Blender shots | `build/bl_shots.py` — **do not edit** |

Hand-check GLBs: `build/inspect/` (tripo left, fix right) via `build/bl_open_compare.py`.

---

## Environment (Windows, verified)

```powershell
# Blender 5.2 Store — NOT blender.exe directly
$BL = "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe"
# Detaches from shell — write output to files, poll for them

# Godot 4.7.1 Forward+
$GODOT = "$env:LOCALAPPDATA\Microsoft\WinGet\Links\godot_console.exe"
$PROJ  = "godot/immune"

# Kill orphans before each Godot render
Get-Process -Name godot* -ErrorAction SilentlyContinue | Stop-Process -Force
```

Godot **must** render with a real window (`--headless` = no pixels).

---

## Priority queue for Codex

### 1. Close P2 material (if r5 critic never finished)

- Render: `build/shots/t-gel-r5/` (commands in `immune-3d-lock/references/03-wet-gel-material.md`)
- Measure:
  ```powershell
  python build/gel_compare.py --zones --detail `
    godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png `
    build/shots/t-gel-r5/t-gel-r5-front.png
  ```
- Run blurred control: `--detail blur=4` on reference — detail metrics must collapse
- Dispatch **fresh critic** (no builder transcript). Bar: wet gel not vinyl; colour +
  microstructure; gameplay scale 200–400px; eyes ink-black; R≥254 plateau ~3%
- If LOSES: fix **single biggest gap** only, new round `t-gel-r6/`
- Round 5 params starting point: `dimple_depth` 0.05, `dimple_scale` 110,
  `dimple_round` 0.45 — see `gel_look.gd`

**Known material hazards (do not re-litigate):**
- Deep-core blue floor ~0.08 is ACES harness tonemapping — not fixable in shader alone
- Recommend game scenes adopt ACES (`Environment.tonemap_mode`), not linear recalibration
- Dimples vanish by ~160px on screen — needs distance LOD later, not one constant
- `--ink` must erode mask — dark crevices ≠ eye ink
- Colour stats alone cannot pass (blur reference control required)

### 2. Finish P1b silhouette

- Target: squat **bell**, **flared wavy skirt**, **hooked tapered arms** (not tall egg + nubs)
- Method: vertex displacement on Tripo shells — **no boolean/remesh on face**
- Scripts: `build/bl_fix_t.py`, `build/bl_fix_t_ops.py`
- Re-render: `build/bl_shots.py` → `build/shots/t-fix/`
- Critic compares **rendered outline**, not bounding box
- File owner: `characters/base_t/*.glb`, `build/bl_fix_t*.py`

### 3. P4 integration

Wire into game, not just preview tools:

```
[ ] character.tscn loads CHAR-BASE-T-fix.glb (or latest approved GLB)
[ ] apply_gel() from family_look on mesh instances
[ ] rebuild_gel_anims() on ready (character_root.gd)
[ ] ACES tonemapping on combat_lane + kit_lock_preview
[ ] kit_lock_preview renders clean
[ ] Whole-product critic: concept 3/4 + face + idle FACE strip
[ ] Update build/gallery/ with final strip
```

`apply_gel` is currently only called from `gel_preview.gd` and `gel_perf.gd` — **not game scenes**.

---

## File ownership (avoid conflicts)

| Owner | Files |
| ----- | ----- |
| Geometry | `build/bl_fix_t*.py`, `godot/immune/characters/base_t/*.glb` |
| Material | `godot/immune/characters/gel/*`, `tools/gel_preview.tscn` |
| Animation | `gel_anim.gd`, `tools/anim_preview.tscn`, `character_root.gd` anim hooks |
| Shared (no edit without ask) | `tools/shot.gd`, `tools/shot.tscn`, `build/bl_shots.py` |

---

## Critical technical facts (save hours)

1. **Tripo mesh has separate shells** for pore (~1096 verts) and eyes (~104–107 verts);
   body ~2477 verts. Fix by displacing shells, not remeshing.
2. **Open eye hole in mesh data** is inherited from Tripo; invisible in shaded render — not a blocker.
3. **Preview default mesh** must be `CHAR-BASE-T-tripo-5k.glb` or latest **good** fix.glb.
   An early broken `fix.glb` had torn geometry — do not use for material evidence.
4. **Face budget for T:** ~5k target; fix landed 7522 tris — acceptable if quality passes.
5. **UV:** keep Tripo UVs; final look is Godot gel shader, not baked plastic PBR.

---

## Evidence index

| What | Where |
| ---- | ----- |
| Gallery (human) | http://127.0.0.1:5180/build/gallery/ |
| Workflow page | http://127.0.0.1:5180/build/gallery/workflow.html |
| Material compare strip | `build/r5/strip-front.png` |
| Geometry crops | `build/ref-crops/` |
| Anim sheets | `build/shots/t-anim/*-SHEET.png`, `*-FACE.png` |
| Mesh JSON baseline | `build/shots/t-raw/t-raw-report.json` |
| Mesh JSON fix | `build/shots/t-fix/t-fix-report.json`, `build/fix-report.json` |
| Gauntlet log | `gauntlet-workbench.md` |

---

## Skills & methods

| Skill | When |
| ----- | ---- |
| `gauntlet-loop` | Any quality iteration — mandatory |
| `immune-3d-lock` | Full 3D character pipeline |
| `verification-before-completion` | Before claiming done |

Maintain `gauntlet-workbench.md` during gauntlet runs. Do not commit unless user asks.

---

## Out of scope / do not redo

- Regenerating Tripo/Meshy GLB from scratch (unless silhouette is unsalvageable)
- Editing shared render harness without explicit user ask
- Committing `gauntlet-workbench.md` or `build/` evidence unless asked
- Mesh defects in material critic verdict (route separately)
- Re-litigating palette: B is dark but accepted; T/D 0.2° apart in `JELLY` palette

---

## Repo root

```
C:\Users\wchkl\Documents\Codex\2026-08-12\https-chatgpt-com-share-6a7b9aee-e840-2
```

Godot project: `godot/immune`

---

*Handoff prepared 2026-08-18. Update this file when P2/P1b/P4 status changes.*
