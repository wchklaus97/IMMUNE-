# CHAR-BASE-B Meshy T2 asset provenance

- Source reference: `characters/concepts/base-cell-line-v2/CHAR-BASE-B.png`
- Meshy endpoint: `POST /openapi/v1/image-to-3d`
- Task ID: `01a043a9-4884-7a6f-bd72-1a716f663403`
- API server version: `v2026.08.27.post6`
- Model: `model_type=smart-topology`, `ai_model=meshy-t2`
- Requested budget: 8,000 faces; delivered: 8,755 triangle faces / 4,380 vertices
- Texturing: disabled; the shared Godot wet-gel shader supplies the violet jelly look
- Meshy output: GLB only, 158,348 bytes
- Integrated GLB: 736,468 bytes after Assimp 6.0.2 regenerated missing smooth vertex normals and repaired the rear-pole shading seam; geometry, topology, and silhouette unchanged
- Integrated GLB SHA-256: `c57cbf701c6ec66dfca69715e82ffe9339bc5ebf121fa05251f54157bab3100e`
- Reproducible post-process source: `tools/smooth_meshy_b_normals.cpp`
- Credits consumed: 5
- Generated: 2026-08-27 (Asia/Hong_Kong)

The immutable API response, thumbnails, and generation metadata are retained in the
outer workspace under `work/meshy_output/20260827_223931_b-cell-jelly-smart-topology_01a043a9/`.

Known review note: the single-view reconstruction produced a circular rear shading
seam. The integrated GLB corrects that local normal patch without moving vertices;
regenerate from a true multi-view reference before a final commercial hero-asset pass.

## Shipping status

V8.1 runtime B loads the project-authored `reference_body.tscn`. The Meshy GLB
is retained only as development provenance and is explicitly excluded from all
release presets. It must not be restored to a build or used in marketing until
the input-image rights, account receipt, and applicable commercial terms are
attached and approved by the owner.
