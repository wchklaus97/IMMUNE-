#!/usr/bin/env python3
"""Build the preserved V8.6 R6 T-cell sculpt as one watertight GLB.

R6 is a new numeric, project-authored implicit surface. It does not consume
R5, a provider mesh, a texture, or reference-image pixels. Unlike R5's
orthographic-only silhouette gate, R6 reproduces the full-body camera in
``res://tools/shot.gd`` and validates the final triangle surface under that
32-degree perspective projection before immutable promotion.

The frozen V8.5 writer and R5's topology-safe cleaner are reused as audited
low-level helpers. Their hashes must be recorded with this builder in asset
provenance. Existing outputs and preview evidence are never overwritten.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import tempfile
from pathlib import Path

import numpy as np
import vtk

import build_t_v8_6_authored_sculpt as r5


base = r5.base

GRID_BOUNDS = (-1.08, 1.08, -0.16, 1.60, -0.64, 0.68)
GRID_DIMS = (216, 184, 146)
TARGET_SIZE = (1.64, 1.46, 1.00)
DECIMATION_FACE_BUDGETS = (12_000, 16_000, 24_000)
MIN_DECIMATED_VOLUME_RATIO = 0.995
CORE_UNION_SOFTNESS = 0.078
ARM_UNION_SOFTNESS = 0.042
SOCKET_SOFTNESS = 0.008

AABB_WIDTH_RANGE = (1.62, 1.66)
ORTHOGRAPHIC_RATIO_RANGE = (1.10, 1.14)
SHOT_PERSPECTIVE_RATIO_RANGE = (1.02, 1.08)
CALIBRATED_GODOT_RATIO_RANGE = (0.98, 1.04)
FOOT_NOTCH_RANGE = (0.135, 0.175)
FOOT_ARCH_OPENING_RANGE = (0.16, 0.32)
MIN_ARM_GAP_WIDTH = 0.040
MIN_ARM_GAP_SAMPLES = 5

# shot.gd full-body camera contract. Camera and target coordinates are scaled
# by the framed subject height, exactly as _place_camera() does at runtime.
SHOT_FOV_DEGREES = 32.0
SHOT_CAMERA_HEIGHT = 1.30
SHOT_CAMERA_DISTANCE = 3.05
SHOT_TARGET_HEIGHT = 0.46

SOCKET_SOURCE_CENTER = (0.297734, 0.861586, 0.430)
SOCKET_TARGET_FINAL = (0.238, 0.855)
SOCKET_RADII = (0.305, 0.185, 0.065)
SOCKET_ANGLE_DEGREES = 38.0
RUNTIME_EYE_SCALE = (0.205, 0.136, 0.014)
SOCKET_CENTER_TOLERANCE = 0.003
MIN_AUTHORED_SOCKET_LIP = 0.025

# R5's final triangle-mask projection was 571/601 while its observed Godot
# trim was 562/615. This conservative visibility factor accounts for transparent
# edge pixels rejected by the render trim, and is reported separately from the
# exact geometric perspective metric. It is not presented as a GPU render.
R5_GEOMETRIC_PERSPECTIVE_RATIO = 571.0 / 601.0
R5_OBSERVED_GODOT_TRIM_RATIO = 562.0 / 615.0
R5_GODOT_VISIBILITY_FACTOR = (
    R5_OBSERVED_GODOT_TRIM_RATIO / R5_GEOMETRIC_PERSPECTIVE_RATIO
)


class BuildError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument(
        "--preview-dir",
        type=Path,
        help="write immutable CPU neutral front-shot/orthographic/side/3Q PNGs",
    )
    return parser.parse_args()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def authored_field() -> tuple[np.ndarray, tuple[np.ndarray, np.ndarray, np.ndarray]]:
    x_min, x_max, y_min, y_max, z_min, z_max = GRID_BOUNDS
    nx, ny, nz = GRID_DIMS
    xs = np.linspace(x_min, x_max, nx, dtype=np.float32)[:, None, None]
    ys = np.linspace(y_min, y_max, ny, dtype=np.float32)[None, :, None]
    zs = np.linspace(z_min, z_max, nz, dtype=np.float32)[None, None, :]

    # The torso stays broad and low. Feet carry more lateral mass than R5, and
    # each hook arm moves outward while retaining only an upper-shoulder union.
    solids = [
        ((0.000, 0.810, -0.010), (0.620, 0.700, 0.420), 2.28, 0.0),
        ((0.000, 0.430, 0.030), (0.655, 0.345, 0.450), 2.02, 0.0),
        ((0.000, 0.215, 0.075), (0.570, 0.210, 0.415), 2.48, 0.0),
        ((-0.385, 0.112, 0.170), (0.405, 0.165, 0.400), 2.16, 3.0),
        ((0.385, 0.112, 0.170), (0.405, 0.165, 0.400), 2.16, -3.0),
        ((-0.575, 0.800, -0.005), (0.235, 0.290, 0.290), 2.20, -20.0),
        ((-0.755, 0.640, 0.025), (0.170, 0.225, 0.230), 2.12, -14.0),
        ((-0.900, 0.475, 0.070), (0.125, 0.185, 0.200), 2.06, -5.0),
        ((-0.850, 0.345, 0.095), (0.150, 0.125, 0.190), 2.04, 22.0),
        ((0.575, 0.800, -0.005), (0.235, 0.290, 0.290), 2.20, 20.0),
        ((0.755, 0.640, 0.025), (0.170, 0.225, 0.230), 2.12, 14.0),
        ((0.900, 0.475, 0.070), (0.125, 0.185, 0.200), 2.06, 5.0),
        ((0.850, 0.345, 0.095), (0.150, 0.125, 0.190), 2.04, -22.0),
    ]
    field = base.superellipsoid_sdf(xs, ys, zs, *solids[0])
    for solid_index, solid in enumerate(solids[1:], start=1):
        softness = CORE_UNION_SOFTNESS if solid_index < 5 else ARM_UNION_SOFTNESS
        field = base.smooth_min(
            field,
            base.superellipsoid_sdf(xs, ys, zs, *solid),
            softness,
        )

    cavities = [
        # The wider socket opening leaves a visible amber lip around the
        # runtime eye card at scale approximately (0.205, 0.136, 0.014).
        # The source coordinates compensate for the audited non-uniform bounds
        # normalization and land at final centres x=+/-0.238, y=0.855.
        (
            (
                -SOCKET_SOURCE_CENTER[0],
                SOCKET_SOURCE_CENTER[1],
                SOCKET_SOURCE_CENTER[2],
            ),
            SOCKET_RADII,
            2.18,
            -SOCKET_ANGLE_DEGREES,
        ),
        (
            SOCKET_SOURCE_CENTER,
            SOCKET_RADII,
            2.18,
            SOCKET_ANGLE_DEGREES,
        ),
        ((0.000, 1.085, 0.420), (0.064, 0.064, 0.034), 2.00, 0.0),
        ((0.000, 0.625, 0.460), (0.084, 0.028, 0.032), 2.00, 0.0),
        # An open-bottom, wider/deeper arch preserves genus zero while moving
        # the two soft foot pads toward the reference silhouette.
        ((0.000, 0.015, 0.055), (0.235, 0.185, 0.720), 2.08, 0.0),
    ]
    for cavity in cavities:
        cavity_field = base.superellipsoid_sdf(xs, ys, zs, *cavity)
        field = base.smooth_max(field, -cavity_field, SOCKET_SOFTNESS)
    return field.astype(np.float32, copy=False), (xs, ys, zs)


def extract_surface(field: np.ndarray) -> vtk.vtkPolyData:
    x_min, x_max, y_min, y_max, z_min, z_max = GRID_BOUNDS
    nx, ny, nz = GRID_DIMS
    image = vtk.vtkImageData()
    image.SetDimensions(nx, ny, nz)
    image.SetOrigin(x_min, y_min, z_min)
    image.SetSpacing(
        (x_max - x_min) / (nx - 1),
        (y_max - y_min) / (ny - 1),
        (z_max - z_min) / (nz - 1),
    )
    scalars = base.numpy_to_vtk(
        field.ravel(order="F"), deep=True, array_type=vtk.VTK_FLOAT
    )
    scalars.SetName("authored_sdf_r6")
    image.GetPointData().SetScalars(scalars)

    contour = vtk.vtkFlyingEdges3D()
    contour.SetInputData(image)
    contour.SetValue(0, 0.0)
    contour.ComputeNormalsOff()
    contour.ComputeGradientsOff()
    contour.Update()
    surface = r5.clean_polydata(contour.GetOutput())
    raw_faces = base.triangles(surface)
    raw_metrics = base.topology(surface, raw_faces)
    print(
        "T_V8_6_R6_STAGE raw_surface "
        f"points={surface.GetNumberOfPoints()} faces={surface.GetNumberOfCells()} "
        f"regions={raw_metrics['regions']} boundary_edges={raw_metrics['boundary_edges']} "
        f"nonmanifold_edges={raw_metrics['nonmanifold_edges']} "
        f"winding_errors={raw_metrics['winding_errors']} "
        f"degenerate_faces={raw_metrics['degenerate_faces']} "
        f"euler={raw_metrics['euler']} signed_volume={raw_metrics['signed_volume']:.6f}"
    )
    if not base.topology_is_closed(
        raw_metrics,
        require_non_degenerate=False,
        require_positive_volume=False,
    ):
        raise BuildError(f"raw R6 SDF surface failed topology contract: {raw_metrics}")
    if surface.GetNumberOfCells() <= DECIMATION_FACE_BUDGETS[0]:
        return surface

    for budget in DECIMATION_FACE_BUDGETS:
        decimate = vtk.vtkQuadricDecimation()
        decimate.SetInputData(surface)
        decimate.SetTargetReduction(1.0 - budget / surface.GetNumberOfCells())
        decimate.VolumePreservationOn()
        decimate.Update()
        candidate = r5.clean_polydata(decimate.GetOutput())
        candidate_faces = base.triangles(candidate)
        candidate_metrics = base.topology(candidate, candidate_faces)
        volume_ratio = abs(float(candidate_metrics["signed_volume"])) / abs(
            float(raw_metrics["signed_volume"])
        )
        print(
            "T_V8_6_R6_STAGE decimated_surface "
            f"budget={budget} points={candidate.GetNumberOfPoints()} "
            f"faces={candidate.GetNumberOfCells()} regions={candidate_metrics['regions']} "
            f"boundary_edges={candidate_metrics['boundary_edges']} "
            f"nonmanifold_edges={candidate_metrics['nonmanifold_edges']} "
            f"winding_errors={candidate_metrics['winding_errors']} "
            f"degenerate_faces={candidate_metrics['degenerate_faces']} "
            f"euler={candidate_metrics['euler']} volume_ratio={volume_ratio:.6f}"
        )
        if (
            base.topology_is_closed(candidate_metrics, require_positive_volume=False)
            and volume_ratio >= MIN_DECIMATED_VOLUME_RATIO
        ):
            return candidate
    raise BuildError(
        "no bounded R6 candidate preserved the watertight topology and volume contract"
    )


def _view_basis(view: str) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    up = np.array((0.0, 1.0, 0.0), dtype=np.float64)
    if view == "front-orthographic":
        forward = np.array((0.0, 0.0, 1.0), dtype=np.float64)
    elif view == "side":
        forward = np.array((1.0, 0.0, 0.0), dtype=np.float64)
    elif view == "three-quarter":
        forward = np.array((0.68, 0.0, 0.74), dtype=np.float64)
        forward /= np.linalg.norm(forward)
    else:
        raise BuildError(f"unsupported R6 orthographic preview view: {view}")
    right = np.cross(up, forward)
    right /= np.linalg.norm(right)
    return right, up, forward


def _orthographic_projection(
    points: np.ndarray,
    view: str,
    size: int,
    margin: int,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    right, up, forward = _view_basis(view)
    projected = np.column_stack((points @ right, points @ up, points @ forward))
    low = projected[:, :2].min(axis=0)
    high = projected[:, :2].max(axis=0)
    spans = high - low
    if np.any(spans <= 1.0e-8):
        raise BuildError(f"degenerate R6 {view} projection: {spans.tolist()}")
    scale = min((size - 2 * margin) / spans[0], (size - 2 * margin) / spans[1])
    screen = np.empty((len(points), 2), dtype=np.float64)
    screen[:, 0] = margin + (projected[:, 0] - low[0]) * scale
    screen[:, 1] = size - margin - (projected[:, 1] - low[1]) * scale
    return screen, projected[:, 2], forward


def _shot_projection(
    points: np.ndarray,
    height: float,
    size: int = 1024,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    camera = np.array(
        (
            0.0,
            height * SHOT_CAMERA_HEIGHT,
            height * SHOT_CAMERA_DISTANCE,
        ),
        dtype=np.float64,
    )
    target = np.array((0.0, height * SHOT_TARGET_HEIGHT, 0.0), dtype=np.float64)
    forward = target - camera
    forward /= np.linalg.norm(forward)
    right = np.cross(forward, np.array((0.0, 1.0, 0.0), dtype=np.float64))
    right /= np.linalg.norm(right)
    up = np.cross(right, forward)
    relative = points - camera
    depth = relative @ forward
    if np.any(depth <= 1.0e-6):
        raise BuildError("R6 shot projection has geometry behind the camera")
    tangent = math.tan(math.radians(SHOT_FOV_DEGREES) * 0.5)
    ndc_x = (relative @ right) / (depth * tangent)
    ndc_y = (relative @ up) / (depth * tangent)
    screen = np.column_stack(
        (
            (ndc_x + 1.0) * size * 0.5,
            (1.0 - ndc_y) * size * 0.5,
        )
    )
    return screen, depth, camera


def _raster_mask(
    screen: np.ndarray,
    faces: np.ndarray,
    size: int,
) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    from PIL import Image, ImageDraw

    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    for a, b, c in faces.tolist():
        draw.polygon([tuple(screen[a]), tuple(screen[b]), tuple(screen[c])], fill=255)
    bbox = mask.getbbox()
    if bbox is None:
        raise BuildError("R6 projected mask is empty")
    return np.asarray(mask) > 0, bbox


def _mask_runs(row: np.ndarray) -> list[tuple[int, int]]:
    padded = np.pad(row.astype(np.int8), (1, 1))
    transitions = np.diff(padded)
    starts = np.flatnonzero(transitions == 1)
    ends = np.flatnonzero(transitions == -1) - 1
    return [(int(start), int(end)) for start, end in zip(starts, ends, strict=True)]


def projection_metrics(
    source: vtk.vtkPolyData,
    faces: np.ndarray,
    size: int = 1024,
) -> dict[str, float | int]:
    points = base.vtk_to_numpy(source.GetPoints().GetData()).astype(
        np.float64, copy=False
    )
    bounds = source.GetBounds()
    height = float(bounds[3] - bounds[2])

    ortho_screen, _ortho_depth, _ortho_forward = _orthographic_projection(
        points, "front-orthographic", size, 72
    )
    ortho_pixels, ortho_bbox = _raster_mask(ortho_screen, faces, size)
    ortho_width = ortho_bbox[2] - ortho_bbox[0]
    ortho_height = ortho_bbox[3] - ortho_bbox[1]

    shot_screen, _shot_depth, _camera = _shot_projection(points, height, size)
    shot_pixels, shot_bbox = _raster_mask(shot_screen, faces, size)
    shot_width = shot_bbox[2] - shot_bbox[0]
    shot_height = shot_bbox[3] - shot_bbox[1]
    shot_ratio = float(shot_width / shot_height)

    # Measure the centreline notch from the orthographic final triangle mask.
    centre_x = int(round((ortho_bbox[0] + ortho_bbox[2] - 1) * 0.5))
    centre_band = ortho_pixels[:, max(0, centre_x - 2) : min(size, centre_x + 3)]
    centre_rows = np.flatnonzero(np.any(centre_band, axis=1))
    if centre_rows.size == 0:
        raise BuildError("R6 orthographic mask has no centreline")
    foot_notch_ratio = float((ortho_bbox[3] - 1 - centre_rows.max()) / ortho_height)

    # At 5% of final height, the reference has a broad two-pad opening. The
    # ratio is measured from the final mask, not the SDF target constants.
    arch_y = float(bounds[2] + height * 0.05)
    ortho_y_min = float(bounds[2])
    usable = size - 144
    scale = min(usable / (bounds[1] - bounds[0]), usable / height)
    pixel_y = int(round(size - 72 - (arch_y - ortho_y_min) * scale))
    runs = _mask_runs(ortho_pixels[pixel_y]) if 0 <= pixel_y < size else []
    arch_opening_ratio = 0.0
    if len(runs) == 2:
        arch_opening_ratio = float((runs[1][0] - runs[0][1] - 1) / ortho_width)

    def runs_at_world_y(world_y: float) -> int:
        row_y = int(round(size - 72 - (world_y - ortho_y_min) * scale))
        if not 0 <= row_y < size:
            return 0
        return len(_mask_runs(ortho_pixels[row_y]))

    arm_gap_rows = sum(
        runs_at_world_y(float(y)) == 3 for y in np.linspace(0.27, 0.58, 13)
    )
    shoulder_rows = sum(
        runs_at_world_y(float(y)) == 1 for y in np.linspace(0.70, 0.90, 7)
    )
    return {
        "orthographic_width_px": ortho_width,
        "orthographic_height_px": ortho_height,
        "orthographic_ratio": float(ortho_width / ortho_height),
        "shot_width_px": shot_width,
        "shot_height_px": shot_height,
        "shot_perspective_ratio": shot_ratio,
        "calibrated_godot_trim_ratio": shot_ratio * R5_GODOT_VISIBILITY_FACTOR,
        "foot_notch_ratio": foot_notch_ratio,
        "foot_arch_opening_ratio": arch_opening_ratio,
        "mask_arm_gap_rows": arm_gap_rows,
        "mask_shoulder_connected_rows": shoulder_rows,
    }


def shape_contract(
    field: np.ndarray,
    coordinates: tuple[np.ndarray, np.ndarray, np.ndarray],
    raw_bounds: tuple[float, float, float, float, float, float],
    source: vtk.vtkPolyData,
    faces: np.ndarray,
) -> dict[str, float | int]:
    xs = coordinates[0][:, 0, 0]
    ys = coordinates[1][0, :, 0]
    zs = coordinates[2][0, 0, :]
    z_index = int(np.argmin(np.abs(zs)))

    arm_gap_samples = 0
    min_gap = math.inf
    max_gap = 0.0
    for sample_y in np.linspace(0.27, 0.58, 13):
        y_index = int(np.argmin(np.abs(ys - sample_y)))
        sections = r5._intervals(xs, field[:, y_index, z_index] <= 0.0)
        if len(sections) != 3:
            continue
        gaps = (sections[1][0] - sections[0][1], sections[2][0] - sections[1][1])
        if min(gaps) <= 0.0:
            continue
        arm_gap_samples += 1
        min_gap = min(min_gap, *gaps)
        max_gap = max(max_gap, *gaps)

    shoulder_connected_samples = 0
    for sample_y in np.linspace(0.70, 0.90, 7):
        y_index = int(np.argmin(np.abs(ys - sample_y)))
        if len(r5._intervals(xs, field[:, y_index, z_index] <= 0.0)) == 1:
            shoulder_connected_samples += 1

    metrics = projection_metrics(source, faces)
    scale_x = TARGET_SIZE[0] / (raw_bounds[1] - raw_bounds[0])
    scale_y = TARGET_SIZE[1] / (raw_bounds[3] - raw_bounds[2])
    raw_centre_x = (raw_bounds[0] + raw_bounds[1]) * 0.5
    final_socket_x = (SOCKET_SOURCE_CENTER[0] - raw_centre_x) * scale_x
    final_socket_y = (SOCKET_SOURCE_CENTER[1] - raw_bounds[2]) * scale_y
    angle = math.radians(SOCKET_ANGLE_DEGREES)
    cosine = math.cos(angle)
    sine = math.sin(angle)
    socket_half_width = math.hypot(
        SOCKET_RADII[0] * cosine * scale_x,
        SOCKET_RADII[1] * sine * scale_y,
    )
    socket_half_height = math.hypot(
        SOCKET_RADII[0] * sine * scale_x,
        SOCKET_RADII[1] * cosine * scale_y,
    )
    eye_half_width = math.hypot(
        RUNTIME_EYE_SCALE[0] * cosine,
        RUNTIME_EYE_SCALE[1] * sine,
    )
    eye_half_height = math.hypot(
        RUNTIME_EYE_SCALE[0] * sine,
        RUNTIME_EYE_SCALE[1] * cosine,
    )
    metrics.update(
        {
            "arm_gap_samples": arm_gap_samples,
            "arm_gap_min": min_gap if math.isfinite(min_gap) else 0.0,
            "arm_gap_max": max_gap,
            "shoulder_connected_samples": shoulder_connected_samples,
            "final_socket_center_x": final_socket_x,
            "final_socket_center_y": final_socket_y,
            "authored_socket_lip_x": socket_half_width - eye_half_width,
            "authored_socket_lip_y": socket_half_height - eye_half_height,
        }
    )
    bounds = source.GetBounds()
    aabb_width = float(bounds[1] - bounds[0])
    if not AABB_WIDTH_RANGE[0] <= aabb_width <= AABB_WIDTH_RANGE[1]:
        raise BuildError(f"R6 AABB-width contract failed: {metrics}")
    if (
        not ORTHOGRAPHIC_RATIO_RANGE[0]
        <= metrics["orthographic_ratio"]
        <= ORTHOGRAPHIC_RATIO_RANGE[1]
    ):
        raise BuildError(f"R6 orthographic-ratio contract failed: {metrics}")
    if (
        not SHOT_PERSPECTIVE_RATIO_RANGE[0]
        <= metrics["shot_perspective_ratio"]
        <= SHOT_PERSPECTIVE_RATIO_RANGE[1]
    ):
        raise BuildError(f"R6 shot-perspective contract failed: {metrics}")
    if (
        not CALIBRATED_GODOT_RATIO_RANGE[0]
        <= metrics["calibrated_godot_trim_ratio"]
        <= CALIBRATED_GODOT_RATIO_RANGE[1]
    ):
        raise BuildError(f"R6 calibrated-Godot-trim contract failed: {metrics}")
    if not FOOT_NOTCH_RANGE[0] <= metrics["foot_notch_ratio"] <= FOOT_NOTCH_RANGE[1]:
        raise BuildError(f"R6 foot-notch contract failed: {metrics}")
    if (
        not FOOT_ARCH_OPENING_RANGE[0]
        <= metrics["foot_arch_opening_ratio"]
        <= FOOT_ARCH_OPENING_RANGE[1]
    ):
        raise BuildError(f"R6 foot-arch-opening contract failed: {metrics}")
    if arm_gap_samples < MIN_ARM_GAP_SAMPLES or min_gap < MIN_ARM_GAP_WIDTH:
        raise BuildError(f"R6 arm-gap contract failed: {metrics}")
    if shoulder_connected_samples < 4:
        raise BuildError(f"R6 shoulder-connection contract failed: {metrics}")
    if int(metrics["mask_arm_gap_rows"]) < MIN_ARM_GAP_SAMPLES:
        raise BuildError(f"R6 final-mask arm-gap contract failed: {metrics}")
    if int(metrics["mask_shoulder_connected_rows"]) < 4:
        raise BuildError(f"R6 final-mask shoulder contract failed: {metrics}")
    if (
        abs(final_socket_x - SOCKET_TARGET_FINAL[0]) > SOCKET_CENTER_TOLERANCE
        or abs(final_socket_y - SOCKET_TARGET_FINAL[1]) > SOCKET_CENTER_TOLERANCE
    ):
        raise BuildError(f"R6 normalized socket-centre contract failed: {metrics}")
    if (
        metrics["authored_socket_lip_x"] < MIN_AUTHORED_SOCKET_LIP
        or metrics["authored_socket_lip_y"] < MIN_AUTHORED_SOCKET_LIP
    ):
        raise BuildError(f"R6 authored socket-lip contract failed: {metrics}")
    return metrics


def _render_neutral_preview(
    source: vtk.vtkPolyData,
    faces: np.ndarray,
    view: str,
    path: Path,
    size: int = 1024,
) -> None:
    from PIL import Image, ImageDraw

    if path.exists():
        raise BuildError(f"refusing to overwrite existing R6 preview: {path}")
    points = base.vtk_to_numpy(source.GetPoints().GetData()).astype(
        np.float64, copy=False
    )
    if view == "front-shot":
        height = float(source.GetBounds()[3] - source.GetBounds()[2])
        screen, vertex_depths, camera = _shot_projection(points, height, size)
        face_centres = points[faces].mean(axis=1)
        face_view = camera - face_centres
        face_view /= np.linalg.norm(face_view, axis=1)[:, None]
    else:
        screen, vertex_depths, forward = _orthographic_projection(
            points, view, size, 72
        )
        face_view = np.broadcast_to(forward, (len(faces), 3))
    face_depths = vertex_depths[faces].mean(axis=1)

    image = Image.new("RGB", (size, size), (2, 4, 9))
    draw = ImageDraw.Draw(image)
    pa = points[faces[:, 0]]
    pb = points[faces[:, 1]]
    pc = points[faces[:, 2]]
    normals = np.cross(pb - pa, pc - pa)
    lengths = np.linalg.norm(normals, axis=1)
    if np.any(lengths <= 1.0e-12):
        raise BuildError(f"R6 {view} preview encountered a degenerate face")
    normals /= lengths[:, None]
    light = np.array((-0.35, 0.62, 0.70), dtype=np.float64)
    light /= np.linalg.norm(light)
    order = (
        np.argsort(face_depths)[::-1]
        if view == "front-shot"
        else np.argsort(face_depths)
    )
    for face_index in order:
        normal = normals[face_index]
        facing = float(np.dot(normal, face_view[face_index]))
        if facing <= 0.0:
            continue
        lambert = max(0.0, float(np.dot(normal, light)))
        intensity = 0.31 + 0.54 * lambert + 0.15 * math.pow(1.0 - facing, 2.0)
        colour = (
            min(255, int(255 * intensity)),
            min(255, int(112 * intensity)),
            min(255, int(24 * intensity)),
        )
        a, b, c = faces[face_index]
        draw.polygon(
            [tuple(screen[a]), tuple(screen[b]), tuple(screen[c])], fill=colour
        )
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=False)


def render_neutral_previews(
    source: vtk.vtkPolyData,
    faces: np.ndarray,
    preview_dir: Path,
) -> None:
    preview_dir.mkdir(parents=True, exist_ok=True)
    for view in ("front-shot", "front-orthographic", "side", "three-quarter"):
        _render_neutral_preview(
            source,
            faces,
            view,
            preview_dir / f"sculpt-r6-neutral-{view}.png",
        )


def write_v8_6_glb(path: Path, source: vtk.vtkPolyData, faces: np.ndarray) -> None:
    base.write_glb(path, source, faces)
    payload = path.read_bytes()
    json_length, json_type = base.struct.unpack_from("<I4s", payload, 12)
    json_end = 20 + json_length
    json_chunk = payload[20:json_end]
    if (
        json_type != b"JSON"
        or json_chunk.count(b"V8.5") != 3
        or b"V8.5" in payload[json_end:]
    ):
        raise BuildError("could not replace frozen writer's V8.5 identity")
    updated_json = json_chunk.replace(b"V8.5", b"V8.6")
    if len(updated_json) != json_length or b"V8.5" in updated_json:
        raise BuildError("R6 GLB identity replacement changed the JSON chunk layout")
    path.write_bytes(payload[:20] + updated_json + payload[json_end:])


def main() -> int:
    args = parse_args()
    output = args.output.resolve()
    if output.exists():
        raise BuildError(f"refusing to overwrite existing output: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)

    base.GRID_BOUNDS = GRID_BOUNDS
    base.GRID_DIMS = GRID_DIMS
    base.TARGET_SIZE = TARGET_SIZE

    field, coordinates = authored_field()
    body = extract_surface(field)
    raw_bounds = body.GetBounds()
    base.normalise_bounds(body)
    body = base.with_normals(body)
    faces = base.triangles(body)
    shape = shape_contract(field, coordinates, raw_bounds, body, faces)
    metrics = base.topology(body, faces)
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
            raise BuildError(
                f"R6 topology contract failed: {name}={metrics[name]} expected={value}"
            )
    if float(metrics["signed_volume"]) <= 0.10:
        raise BuildError(
            f"R6 positive enclosed volume is invalid: {metrics['signed_volume']}"
        )

    with tempfile.TemporaryDirectory(
        prefix=".immune-v8-6-r6-", dir=output.parent
    ) as raw_tmp:
        candidate = Path(raw_tmp) / "candidate.glb"
        write_v8_6_glb(candidate, body, faces)
        base.validate_glb_contract(candidate)
        if args.preview_dir is not None:
            render_neutral_previews(body, faces, args.preview_dir.resolve())
        os.link(candidate, output)

    bounds = tuple(round(value, 6) for value in body.GetBounds())
    print(
        "T_V8_6_AUTHORED_SCULPT_R6_OK "
        f"output={output} bytes={output.stat().st_size} sha256={sha256(output)} "
        f"points={body.GetNumberOfPoints()} faces={body.GetNumberOfCells()} "
        f"bounds={bounds} regions=1 boundary_edges=0 nonmanifold_edges=0 "
        f"winding_errors=0 degenerate_faces=0 euler=2 "
        f"signed_volume={metrics['signed_volume']:.6f} "
        f"orthographic_ratio={shape['orthographic_ratio']:.6f} "
        f"orthographic_mask_px={shape['orthographic_width_px']}x{shape['orthographic_height_px']} "
        f"shot_fov={SHOT_FOV_DEGREES:.1f} "
        f"shot_perspective_ratio={shape['shot_perspective_ratio']:.6f} "
        f"shot_mask_px={shape['shot_width_px']}x{shape['shot_height_px']} "
        f"calibrated_godot_trim_ratio={shape['calibrated_godot_trim_ratio']:.6f} "
        f"foot_notch_ratio={shape['foot_notch_ratio']:.6f} "
        f"foot_arch_opening_ratio={shape['foot_arch_opening_ratio']:.6f} "
        f"arm_gap_samples={shape['arm_gap_samples']} "
        f"arm_gap_min={shape['arm_gap_min']:.6f} "
        f"arm_gap_max={shape['arm_gap_max']:.6f} "
        f"shoulder_connected_samples={shape['shoulder_connected_samples']} "
        f"mask_arm_gap_rows={shape['mask_arm_gap_rows']} "
        f"mask_shoulder_connected_rows={shape['mask_shoulder_connected_rows']} "
        f"final_socket_center=+/-{shape['final_socket_center_x']:.6f},{shape['final_socket_center_y']:.6f} "
        f"authored_socket_lip={shape['authored_socket_lip_x']:.6f},{shape['authored_socket_lip_y']:.6f} "
        f"numpy={np.__version__} vtk={vtk.vtkVersion.GetVTKVersion()} "
        "source_mesh=none provider_api=none materials=0 textures=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (
        BuildError,
        base.BuildError,
        OSError,
        ValueError,
        json.JSONDecodeError,
    ) as exc:
        print(f"T_V8_6_AUTHORED_SCULPT_R6_FAILED {exc}")
        raise SystemExit(1)
