#!/usr/bin/env python3
"""Build the preserved V8.6 R7 T-cell smoothing candidate.

R7 keeps R6's audited silhouette, projection, topology, and GLB contracts while
softening only the implicit unions and socket depth that produced fixed cheek,
arm, foot, and back creases in the six-view R4.1 review. R6 is imported as a
frozen helper and is never overwritten.
"""

from __future__ import annotations

import os
import tempfile
from pathlib import Path

import numpy as np
import vtk

import build_t_v8_6_authored_sculpt_r6 as r6


CORE_UNION_SOFTNESS = 0.084
ARM_UNION_SOFTNESS = 0.050
SOCKET_SOFTNESS = 0.014
SOCKET_RADII = (0.305, 0.185, 0.045)


def render_neutral_previews(
    source: vtk.vtkPolyData,
    faces: np.ndarray,
    preview_dir: Path,
) -> None:
    preview_dir.mkdir(parents=True, exist_ok=True)
    for view in ("front-shot", "front-orthographic", "side", "three-quarter"):
        r6._render_neutral_preview(
            source,
            faces,
            view,
            preview_dir / f"sculpt-r7-neutral-{view}.png",
        )


def main() -> int:
    args = r6.parse_args()
    output = args.output.resolve()
    if output.exists():
        raise r6.BuildError(f"refusing to overwrite existing R7 output: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)

    r6.CORE_UNION_SOFTNESS = CORE_UNION_SOFTNESS
    r6.ARM_UNION_SOFTNESS = ARM_UNION_SOFTNESS
    r6.SOCKET_SOFTNESS = SOCKET_SOFTNESS
    r6.SOCKET_RADII = SOCKET_RADII
    r6.base.GRID_BOUNDS = r6.GRID_BOUNDS
    r6.base.GRID_DIMS = r6.GRID_DIMS
    r6.base.TARGET_SIZE = r6.TARGET_SIZE

    field, coordinates = r6.authored_field()
    body = r6.extract_surface(field)
    raw_bounds = body.GetBounds()
    r6.base.normalise_bounds(body)
    body = r6.base.with_normals(body)
    faces = r6.base.triangles(body)
    shape = r6.shape_contract(field, coordinates, raw_bounds, body, faces)
    metrics = r6.base.topology(body, faces)
    expected = {
        "regions": 1,
        "boundary_edges": 0,
        "nonmanifold_edges": 0,
        "bad_edge_counts": 0,
        "winding_errors": 0,
        "degenerate_faces": 0,
        "euler": 2,
    }
    for name, value in expected.items():
        if metrics[name] != value:
            raise r6.BuildError(
                f"R7 topology contract failed: {name}={metrics[name]} expected={value}"
            )
    if float(metrics["signed_volume"]) <= 0.10:
        raise r6.BuildError(
            f"R7 positive enclosed volume is invalid: {metrics['signed_volume']}"
        )

    with tempfile.TemporaryDirectory(
        prefix=".immune-v8-6-r7-", dir=output.parent
    ) as raw_tmp:
        candidate = Path(raw_tmp) / "candidate.glb"
        r6.write_v8_6_glb(candidate, body, faces)
        r6.base.validate_glb_contract(candidate)
        if args.preview_dir is not None:
            render_neutral_previews(body, faces, args.preview_dir.resolve())
        os.link(candidate, output)

    bounds = tuple(round(value, 6) for value in body.GetBounds())
    print(
        "T_V8_6_AUTHORED_SCULPT_R7_OK "
        f"output={output} bytes={output.stat().st_size} sha256={r6.sha256(output)} "
        f"points={body.GetNumberOfPoints()} faces={body.GetNumberOfCells()} "
        f"bounds={bounds} regions=1 boundary_edges=0 nonmanifold_edges=0 "
        f"winding_errors=0 degenerate_faces=0 euler=2 "
        f"signed_volume={metrics['signed_volume']:.6f} "
        f"orthographic_ratio={shape['orthographic_ratio']:.6f} "
        f"shot_perspective_ratio={shape['shot_perspective_ratio']:.6f} "
        f"calibrated_godot_trim_ratio={shape['calibrated_godot_trim_ratio']:.6f} "
        f"foot_notch_ratio={shape['foot_notch_ratio']:.6f} "
        f"foot_arch_opening_ratio={shape['foot_arch_opening_ratio']:.6f} "
        f"arm_gap_samples={shape['arm_gap_samples']} "
        f"arm_gap_min={shape['arm_gap_min']:.6f} "
        f"shoulder_connected_samples={shape['shoulder_connected_samples']} "
        f"final_socket_center=+/-{shape['final_socket_center_x']:.6f},{shape['final_socket_center_y']:.6f} "
        f"authored_socket_lip={shape['authored_socket_lip_x']:.6f},{shape['authored_socket_lip_y']:.6f} "
        f"core_softness={CORE_UNION_SOFTNESS:.3f} "
        f"arm_softness={ARM_UNION_SOFTNESS:.3f} "
        f"socket_softness={SOCKET_SOFTNESS:.3f} socket_depth={SOCKET_RADII[2]:.3f} "
        f"numpy={np.__version__} vtk={vtk.vtkVersion.GetVTKVersion()} "
        "source_mesh=none provider_api=none materials=0 textures=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (
        r6.BuildError,
        r6.base.BuildError,
        OSError,
        ValueError,
    ) as exc:
        print(f"T_V8_6_AUTHORED_SCULPT_R7_FAILED {exc}")
        raise SystemExit(1)
