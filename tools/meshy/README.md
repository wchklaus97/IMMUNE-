# Meshy hero-asset pipeline

This directory contains reviewed, cost-gated Meshy requests. Generated assets do
not belong here: the runner stores them in `meshy_output/<timestamp>_<asset>_<id>/`
with task metadata and a global history file.

## CHAR-BASE-M

The M-cell request uses the locked 1024x1024 reference art and the current Image
to 3D Smart Topology route. It intentionally requests an untextured GLB: the game
uses its own wet-gel shader so baked studio highlights do not fight Godot lighting.

No-network preflight (default):

```sh
python3 tools/meshy/run_m_cell_asset.py
```

No-network safety tests (including the paid-POST no-retry contract):

```sh
python3 -m unittest tools/meshy/test_workflow.py
```

Free authenticated balance check:

```sh
python3 tools/meshy/run_m_cell_asset.py --check-balance
```

Paid generation is deliberately impossible without both flags below. This is a
5-credit operation under the API pricing checked on 2026-08-28:

```sh
python3 tools/meshy/run_m_cell_asset.py --execute --approve-credits 5
```

If creation, polling, schema validation, download validation, or task processing
fails, the runner stops. It does not create a replacement task automatically.
For ambiguous POST network failures, inspect Meshy's task list before retrying so
the same asset cannot be charged twice.

After a successful paid run, validate the GLB and its task metadata without
changing the game:

```sh
python3 tools/meshy/validate_hero_glb.py --project-dir meshy_output/<project-folder>
```

Meshy Smart Topology may omit vertex normals. If validation reports
`normals=false`, preserve the downloaded GLB and create a geometry-identical
smooth-normal derivative locally (0 credits):

```sh
python3 tools/meshy/smooth_hero_glb.py --project-dir meshy_output/<project-folder>
python3 tools/meshy/validate_hero_glb.py --project-dir meshy_output/<project-folder>
```

The smoother refuses geometry changes and records both immutable hashes in task
metadata. Installation then selects the verified derivative automatically.
Thumbnail downloads also detect their real PNG/JPEG format before naming the
file, and partial GLB/thumbnail/metadata files are never promoted until their
validation succeeds.

Installation is a separate explicit gate. It copies the verified GLB into the M
family's stable runtime slot and writes provenance; `character.tscn` automatically
uses it after Godot import while retaining its procedural fallback:

```sh
python3 tools/meshy/validate_hero_glb.py \
  --project-dir meshy_output/<project-folder> --install
godot --headless --editor --path godot/immune --import --quit
godot --headless --path godot/immune --script res://tools/smoke.gd
```
