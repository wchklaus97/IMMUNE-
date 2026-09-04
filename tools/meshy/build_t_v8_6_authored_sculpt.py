#!/usr/bin/env python3
"""Build the preserved V8.6 R5 T-cell sculpt as one watertight GLB.

R5 is a new numeric, project-authored implicit surface.  It does not consume
R4, a provider mesh, a texture, or reference-image pixels.  The broad lower
body, split feet, and shoulder-connected hook arms are validated before an
immutable destination can be promoted.  Failed candidates stay isolated from
the requested output and an existing output is never overwritten.

The low-level topology and GLB writer are reused from the frozen V8.5 builder;
both builder hashes are therefore recorded in asset provenance.
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

import build_t_v8_5_authored_sculpt as base


GRID_BOUNDS = (-0.94, 0.94, -0.16, 1.60, -0.64, 0.68)
GRID_DIMS = (188, 184, 146)
TARGET_SIZE = (1.48, 1.46, 1.00)
DECIMATION_FACE_BUDGETS = (12_000, 16_000, 24_000)
MIN_DECIMATED_VOLUME_RATIO = 0.995
CORE_UNION_SOFTNESS = 0.075
ARM_UNION_SOFTNESS = 0.040
SOCKET_SOFTNESS = 0.008
WIDTH_HEIGHT_RANGE = (0.98, 1.04)
FOOT_NOTCH_RANGE = (0.12, 0.15)
MIN_ARM_GAP_WIDTH = 0.035
MIN_ARM_GAP_SAMPLES = 4


class BuildError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument(
        "--preview-dir",
        type=Path,
        help="write immutable CPU-rendered neutral front/side/three-quarter PNGs",
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

    # The torso and belly overlap both feet, so the lower union is a soft
    # continuous mass rather than R4's horizontal base bar.  Each arm is a
    # curved chain whose only structural attachment is at the shoulder.
    solids = [
        ((0.000, 0.815, -0.010), (0.595, 0.705, 0.420), 2.28, 0.0),
        ((0.000, 0.445, 0.030), (0.620, 0.335, 0.450), 2.02, 0.0),
        ((0.000, 0.220, 0.075), (0.520, 0.200, 0.415), 2.48, 0.0),
        ((-0.340, 0.115, 0.170), (0.360, 0.155, 0.400), 2.16, 4.0),
        ((0.340, 0.115, 0.170), (0.360, 0.155, 0.400), 2.16, -4.0),
        ((-0.540, 0.800, -0.005), (0.210, 0.280, 0.280), 2.20, -18.0),
        ((-0.690, 0.640, 0.025), (0.145, 0.220, 0.225), 2.12, -12.0),
        ((-0.805, 0.480, 0.070), (0.110, 0.180, 0.195), 2.06, -4.0),
        ((-0.760, 0.355, 0.095), (0.125, 0.115, 0.185), 2.04, 20.0),
        ((0.540, 0.800, -0.005), (0.210, 0.280, 0.280), 2.20, 18.0),
        ((0.690, 0.640, 0.025), (0.145, 0.220, 0.225), 2.12, 12.0),
        ((0.805, 0.480, 0.070), (0.110, 0.180, 0.195), 2.06, 4.0),
        ((0.760, 0.355, 0.095), (0.125, 0.115, 0.185), 2.04, -20.0),
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
        ((-0.238, 0.855, 0.430), (0.218, 0.145, 0.052), 2.18, -38.0),
        ((0.238, 0.855, 0.430), (0.218, 0.145, 0.052), 2.18, 38.0),
        ((0.000, 1.085, 0.420), (0.064, 0.064, 0.034), 2.00, 0.0),
        ((0.000, 0.625, 0.460), (0.084, 0.028, 0.032), 2.00, 0.0),
        # A deeper open-bottom arch separates the foot pads without making a
        # tunnel; its normalized apex is contractually 12--15% of body height.
        ((0.000, 0.020, 0.055), (0.185, 0.168, 0.700), 2.08, 0.0),
    ]
    for cavity in cavities:
        cavity_field = base.superellipsoid_sdf(xs, ys, zs, *cavity)
        field = base.smooth_max(field, -cavity_field, SOCKET_SOFTNESS)
    return field.astype(np.float32, copy=False), (xs, ys, zs)


def clean_polydata(source: vtk.vtkPolyData) -> vtk.vtkPolyData:
    """Triangulate/weld R5 without converting collapsed polys into line cells."""
    triangles = vtk.vtkTriangleFilter()
    triangles.SetInputData(source)
    triangles.PassVertsOff()
    triangles.PassLinesOff()
    triangles.Update()
    clean = vtk.vtkCleanPolyData()
    clean.SetInputConnection(triangles.GetOutputPort())
    clean.PointMergingOn()
    clean.ToleranceIsAbsoluteOn()
    clean.SetAbsoluteTolerance(1.0e-7)
    clean.ConvertLinesToPointsOff()
    clean.ConvertPolysToLinesOff()
    clean.ConvertStripsToPolysOff()
    clean.Update()
    return clean.GetOutput()


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
    scalars.SetName("authored_sdf_r5")
    image.GetPointData().SetScalars(scalars)

    contour = vtk.vtkFlyingEdges3D()
    contour.SetInputData(image)
    contour.SetValue(0, 0.0)
    contour.ComputeNormalsOff()
    contour.ComputeGradientsOff()
    contour.Update()
    surface = clean_polydata(contour.GetOutput())
    raw_faces = base.triangles(surface)
    raw_metrics = base.topology(surface, raw_faces)
    print(
        "T_V8_6_R5_STAGE raw_surface "
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
        raise BuildError(f"raw R5 SDF surface failed topology contract: {raw_metrics}")
    if surface.GetNumberOfCells() <= DECIMATION_FACE_BUDGETS[0]:
        return surface

    for budget in DECIMATION_FACE_BUDGETS:
        decimate = vtk.vtkQuadricDecimation()
        decimate.SetInputData(surface)
        decimate.SetTargetReduction(1.0 - budget / surface.GetNumberOfCells())
        decimate.VolumePreservationOn()
        decimate.Update()
        candidate = clean_polydata(decimate.GetOutput())
        candidate_faces = base.triangles(candidate)
        candidate_metrics = base.topology(candidate, candidate_faces)
        volume_ratio = abs(float(candidate_metrics["signed_volume"])) / abs(
            float(raw_metrics["signed_volume"])
        )
        print(
            "T_V8_6_R5_STAGE decimated_surface "
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
        "no bounded R5 candidate preserved the watertight topology and volume contract"
    )


def _intervals(xs: np.ndarray, inside: np.ndarray) -> list[tuple[float, float]]:
    ranges: list[tuple[float, float]] = []
    start: int | None = None
    for index, value in enumerate(inside.tolist()):
        if value and start is None:
            start = index
        if start is not None and (not value or index == len(inside) - 1):
            end = index if value and index == len(inside) - 1 else index - 1
            ranges.append((float(xs[start]), float(xs[end])))
            start = None
    return ranges


def _view_basis(view: str) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    up = np.array((0.0, 1.0, 0.0), dtype=np.float64)
    if view == "front":
        forward = np.array((0.0, 0.0, 1.0), dtype=np.float64)
    elif view == "side":
        forward = np.array((1.0, 0.0, 0.0), dtype=np.float64)
    elif view == "three-quarter":
        forward = np.array((0.68, 0.0, 0.74), dtype=np.float64)
        forward /= np.linalg.norm(forward)
    else:
        raise BuildError(f"unsupported R5 preview view: {view}")
    right = np.cross(up, forward)
    right /= np.linalg.norm(right)
    return right, up, forward


def _projected_geometry(
    source: vtk.vtkPolyData,
    faces: np.ndarray,
    view: str,
    size: int = 1024,
    margin: int = 72,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, float, float, float]:
    points = base.vtk_to_numpy(source.GetPoints().GetData()).astype(
        np.float64, copy=False
    )
    right, up, forward = _view_basis(view)
    projected = np.column_stack((points @ right, points @ up, points @ forward))
    low = projected[:, :2].min(axis=0)
    high = projected[:, :2].max(axis=0)
    spans = high - low
    if np.any(spans <= 1.0e-8):
        raise BuildError(f"degenerate R5 {view} projection: {spans.tolist()}")
    scale = min((size - 2 * margin) / spans[0], (size - 2 * margin) / spans[1])
    screen = np.empty((len(points), 2), dtype=np.float64)
    screen[:, 0] = margin + (projected[:, 0] - low[0]) * scale
    screen[:, 1] = size - margin - (projected[:, 1] - low[1]) * scale
    return projected, screen, points, float(scale), float(low[0]), float(low[1])


def _front_mask_metrics(
    source: vtk.vtkPolyData,
    faces: np.ndarray,
    size: int = 1024,
    margin: int = 72,
) -> dict[str, float | int]:
    from PIL import Image, ImageDraw

    _projected, screen, _points, scale, low_x, low_y = _projected_geometry(
        source, faces, "front", size, margin
    )
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    for a, b, c in faces.tolist():
        draw.polygon(
            [tuple(screen[a]), tuple(screen[b]), tuple(screen[c])],
            fill=255,
        )
    bbox = mask.getbbox()
    if bbox is None:
        raise BuildError("R5 neutral front mask is empty")
    mask_pixels = np.asarray(mask) > 0
    mask_width = bbox[2] - bbox[0]
    mask_height = bbox[3] - bbox[1]
    centre_x = int(round(margin + (0.0 - low_x) * scale))
    centre_band = mask_pixels[:, max(0, centre_x - 2) : min(size, centre_x + 3)]
    centre_rows = np.flatnonzero(np.any(centre_band, axis=1))
    if centre_rows.size == 0:
        raise BuildError("R5 neutral front mask has no centreline")
    foot_notch_ratio = float((bbox[3] - 1 - centre_rows.max()) / mask_height)

    def row_runs(world_y: float) -> int:
        pixel_y = int(round(size - margin - (world_y - low_y) * scale))
        if not 0 <= pixel_y < size:
            return 0
        row = mask_pixels[pixel_y]
        transitions = np.diff(np.pad(row.astype(np.int8), (1, 1)))
        return int(np.count_nonzero(transitions == 1))

    arm_gap_rows = sum(row_runs(float(y)) == 3 for y in np.linspace(0.27, 0.56, 13))
    shoulder_rows = sum(row_runs(float(y)) == 1 for y in np.linspace(0.70, 0.88, 7))
    return {
        "mask_width_px": mask_width,
        "mask_height_px": mask_height,
        "width_height_ratio": float(mask_width / mask_height),
        "foot_notch_ratio": foot_notch_ratio,
        "arm_gap_rows": arm_gap_rows,
        "shoulder_connected_rows": shoulder_rows,
    }


def _render_neutral_preview(
    source: vtk.vtkPolyData,
    faces: np.ndarray,
    view: str,
    path: Path,
    size: int = 1024,
    margin: int = 72,
) -> None:
    from PIL import Image, ImageDraw

    if path.exists():
        raise BuildError(f"refusing to overwrite existing R5 preview: {path}")
    projected, screen, points, _scale, _low_x, _low_y = _projected_geometry(
        source, faces, view, size, margin
    )
    image = Image.new("RGB", (size, size), (2, 4, 9))
    draw = ImageDraw.Draw(image)
    pa = points[faces[:, 0]]
    pb = points[faces[:, 1]]
    pc = points[faces[:, 2]]
    normals = np.cross(pb - pa, pc - pa)
    lengths = np.linalg.norm(normals, axis=1)
    if np.any(lengths <= 1.0e-12):
        raise BuildError(f"R5 {view} preview encountered a degenerate face")
    normals /= lengths[:, None]
    _right, _up, forward = _view_basis(view)
    light = np.array((-0.35, 0.62, 0.70), dtype=np.float64)
    light /= np.linalg.norm(light)
    depths = projected[faces].mean(axis=1)[:, 2]
    # Painter sorting remains deterministic and is sufficient for this opaque,
    # closed neutral inspection render. Back faces are culled explicitly.
    for face_index in np.argsort(depths):
        normal = normals[face_index]
        if float(np.dot(normal, forward)) <= 0.0:
            continue
        lambert = max(0.0, float(np.dot(normal, light)))
        facing = max(0.0, float(np.dot(normal, forward)))
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
    for view in ("front", "side", "three-quarter"):
        _render_neutral_preview(
            source,
            faces,
            view,
            preview_dir / f"sculpt-r5-neutral-{view}.png",
        )


def silhouette_contract(
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
    x_index = int(np.argmin(np.abs(xs)))
    y_span = raw_bounds[3] - raw_bounds[2]

    centre_inside = field[x_index, :, z_index] <= 0.0
    centre_ys = ys[centre_inside]
    if centre_ys.size == 0:
        raise BuildError("R5 centreline contains no body")
    foot_notch_ratio = float((centre_ys.min() - raw_bounds[2]) / y_span)

    arm_gap_samples = 0
    min_gap = math.inf
    max_gap = 0.0
    for sample_y in np.linspace(0.27, 0.56, 13):
        y_index = int(np.argmin(np.abs(ys - sample_y)))
        sections = _intervals(xs, field[:, y_index, z_index] <= 0.0)
        if len(sections) != 3:
            continue
        gaps = (sections[1][0] - sections[0][1], sections[2][0] - sections[1][1])
        if min(gaps) <= 0.0:
            continue
        arm_gap_samples += 1
        min_gap = min(min_gap, *gaps)
        max_gap = max(max_gap, *gaps)

    shoulder_connected_samples = 0
    for sample_y in np.linspace(0.70, 0.88, 7):
        y_index = int(np.argmin(np.abs(ys - sample_y)))
        if len(_intervals(xs, field[:, y_index, z_index] <= 0.0)) == 1:
            shoulder_connected_samples += 1

    mask = _front_mask_metrics(source, faces)
    width_height_ratio = float(mask["width_height_ratio"])
    final_foot_notch_ratio = float(mask["foot_notch_ratio"])
    metrics: dict[str, float | int] = {
        "width_height_ratio": width_height_ratio,
        "foot_notch_ratio": final_foot_notch_ratio,
        "field_foot_notch_ratio": foot_notch_ratio,
        "arm_gap_samples": arm_gap_samples,
        "arm_gap_min": min_gap if math.isfinite(min_gap) else 0.0,
        "arm_gap_max": max_gap,
        "shoulder_connected_samples": shoulder_connected_samples,
        "mask_width_px": int(mask["mask_width_px"]),
        "mask_height_px": int(mask["mask_height_px"]),
        "mask_arm_gap_rows": int(mask["arm_gap_rows"]),
        "mask_shoulder_connected_rows": int(mask["shoulder_connected_rows"]),
    }
    if not WIDTH_HEIGHT_RANGE[0] <= width_height_ratio <= WIDTH_HEIGHT_RANGE[1]:
        raise BuildError(f"R5 width/height contract failed: {metrics}")
    if not FOOT_NOTCH_RANGE[0] <= final_foot_notch_ratio <= FOOT_NOTCH_RANGE[1]:
        raise BuildError(f"R5 foot-notch contract failed: {metrics}")
    if arm_gap_samples < MIN_ARM_GAP_SAMPLES or min_gap < MIN_ARM_GAP_WIDTH:
        raise BuildError(f"R5 arm-gap contract failed: {metrics}")
    if shoulder_connected_samples < 4:
        raise BuildError(f"R5 shoulder-connection contract failed: {metrics}")
    if int(mask["arm_gap_rows"]) < MIN_ARM_GAP_SAMPLES:
        raise BuildError(f"R5 final-mask arm-gap contract failed: {metrics}")
    if int(mask["shoulder_connected_rows"]) < 4:
        raise BuildError(f"R5 final-mask shoulder contract failed: {metrics}")
    return metrics


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
        raise BuildError("R5 GLB identity replacement changed the JSON chunk layout")
    path.write_bytes(payload[:20] + updated_json + payload[json_end:])


def main() -> int:
    args = parse_args()
    output = args.output.resolve()
    if output.exists():
        raise BuildError(f"refusing to overwrite existing output: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)

    # The frozen helper functions read these module globals at call time.
    base.GRID_BOUNDS = GRID_BOUNDS
    base.GRID_DIMS = GRID_DIMS
    base.TARGET_SIZE = TARGET_SIZE

    field, coordinates = authored_field()
    body = extract_surface(field)
    raw_bounds = body.GetBounds()
    base.normalise_bounds(body)
    body = base.with_normals(body)
    faces = base.triangles(body)
    silhouette = silhouette_contract(field, coordinates, raw_bounds, body, faces)
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
                f"R5 topology contract failed: {name}={metrics[name]} expected={value}"
            )
    if float(metrics["signed_volume"]) <= 0.10:
        raise BuildError(
            f"R5 positive enclosed volume is invalid: {metrics['signed_volume']}"
        )

    with tempfile.TemporaryDirectory(
        prefix=".immune-v8-6-r5-", dir=output.parent
    ) as raw_tmp:
        candidate = Path(raw_tmp) / "candidate.glb"
        write_v8_6_glb(candidate, body, faces)
        base.validate_glb_contract(candidate)
        if args.preview_dir is not None:
            render_neutral_previews(body, faces, args.preview_dir.resolve())
        os.link(candidate, output)

    bounds = tuple(round(value, 6) for value in body.GetBounds())
    print(
        "T_V8_6_AUTHORED_SCULPT_R5_OK "
        f"output={output} bytes={output.stat().st_size} sha256={sha256(output)} "
        f"points={body.GetNumberOfPoints()} faces={body.GetNumberOfCells()} "
        f"bounds={bounds} regions=1 boundary_edges=0 nonmanifold_edges=0 "
        f"winding_errors=0 degenerate_faces=0 euler=2 "
        f"signed_volume={metrics['signed_volume']:.6f} "
        f"width_height_ratio={silhouette['width_height_ratio']:.6f} "
        f"foot_notch_ratio={silhouette['foot_notch_ratio']:.6f} "
        f"field_foot_notch_ratio={silhouette['field_foot_notch_ratio']:.6f} "
        f"front_mask_px={silhouette['mask_width_px']}x{silhouette['mask_height_px']} "
        f"arm_gap_samples={silhouette['arm_gap_samples']} "
        f"arm_gap_min={silhouette['arm_gap_min']:.6f} "
        f"arm_gap_max={silhouette['arm_gap_max']:.6f} "
        f"shoulder_connected_samples={silhouette['shoulder_connected_samples']} "
        f"mask_arm_gap_rows={silhouette['mask_arm_gap_rows']} "
        f"mask_shoulder_connected_rows={silhouette['mask_shoulder_connected_rows']} "
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
        print(f"T_V8_6_AUTHORED_SCULPT_R5_FAILED {exc}")
        raise SystemExit(1)
