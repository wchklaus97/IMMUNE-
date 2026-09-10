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

## CHAR-BASE-T local single-mass review derivative

`build_t_single_mass_body.py` performs no network request and spends no provider
credits. It requires Assimp on `PATH` plus the Python `vtk` package. The builder
welds the preserved T development GLB, retains its largest connected body,
closes the three removed face-insert holes, regenerates normals, proves one
closed manifold, and refuses to overwrite an existing output. The final Assimp
conversion is first written and container-validated in a same-filesystem
temporary directory, then atomically promoted, so a failed generation leaves no
partial destination that could poison the next retry.

```sh
python3 tools/meshy/build_t_single_mass_body.py \
  --source godot/immune/characters/base_t/CHAR-BASE-T-tripo-5k.glb \
  --output /tmp/CHAR-BASE-T-v8-4-single-mass-r1.glb
python3 tools/meshy/validate_hero_glb.py \
  --glb /tmp/CHAR-BASE-T-v8-4-single-mass-r1.glb
```

The checked-in result and builder are hash-bound in
`characters/base_t/ASSET_PROVENANCE.md`. This derivative inherits the source
model's unresolved commercial-rights status. It is available only to the exact
V8.4 development selector and is deliberately excluded from all release
presets and the accepted PCK policy until the owner supplies the missing rights
records.

## CHAR-BASE-T V8.5 project-authored sculpt candidate

`build_t_v8_5_authored_sculpt.py` is a separate, provider-independent path. It
does not read the V8.4 derivative, any Meshy/Tripo asset, or any reference-image
pixels. Numeric implicit-shape parameters create one closed surface; the builder
then audits connected regions, boundary and non-manifold edges, winding, Euler
characteristic, degenerate faces, volume, GLB structure, and forbidden payloads
before atomically promoting a new immutable output. Existing destinations are
never overwritten.

The checked-in r4 was reproduced byte-for-byte with Python 3, NumPy 2.4.4, and
VTK 9.6.1. Use the same dependency versions when reproducing the evidence:

```sh
python3 tools/meshy/build_t_v8_5_authored_sculpt.py \
  --output /tmp/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb
shasum -a 256 /tmp/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb
```

The expected asset hash and complete topology record live in
`characters/base_t/ASSET_PROVENANCE.md`. V8.5 is an opt-in source-tree review
selector and the candidate GLB remains excluded from every release preset until
the owner resolves concept/reference rights and approves commercial promotion.
