#!/usr/bin/env python3
"""Build the provider-independent V8.5 T hero as one watertight GLB surface.

This builder consumes no image, source mesh, generation API, or provider asset.
The form is defined entirely by the numeric implicit-shape specification below:
a broad torso and base, upper-connected hanging arms, integrated feet, two
shallow eye sockets, a forehead pore, and a small mouth recess. The output is a
material-free GLB with one node, mesh, primitive, and closed triangle component.

The requested output is never overwritten. A candidate is written beside the
destination, validated, and atomically promoted so a failed build cannot leave a
partial final file that poisons a retry.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import struct
import tempfile
from pathlib import Path
from typing import Iterable

import numpy as np
import vtk
from vtk.util.numpy_support import numpy_to_vtk, vtk_to_numpy


GRID_BOUNDS = (-0.84, 0.84, -0.12, 1.60, -0.62, 0.66)
GRID_DIMS = (172, 180, 144)
TARGET_SIZE = (1.50, 1.46, 1.00)
DECIMATION_FACE_BUDGETS = (12_000, 16_000, 24_000)
MIN_DECIMATED_VOLUME_RATIO = 0.995
UNION_SOFTNESS = 0.040
SOCKET_SOFTNESS = 0.008


class BuildError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def smooth_min(a: np.ndarray, b: np.ndarray, radius: float) -> np.ndarray:
    h = np.clip(0.5 + 0.5 * (b - a) / radius, 0.0, 1.0)
    return b * (1.0 - h) + a * h - radius * h * (1.0 - h)


def smooth_max(a: np.ndarray, b: np.ndarray, radius: float) -> np.ndarray:
    return -smooth_min(-a, -b, radius)


def superellipsoid_sdf(
    x: np.ndarray,
    y: np.ndarray,
    z: np.ndarray,
    centre: tuple[float, float, float],
    radii: tuple[float, float, float],
    power: float = 2.0,
    angle_degrees: float = 0.0,
) -> np.ndarray:
    dx = x - centre[0]
    dy = y - centre[1]
    dz = z - centre[2]
    if not math.isclose(angle_degrees, 0.0):
        angle = math.radians(angle_degrees)
        cosine = math.cos(angle)
        sine = math.sin(angle)
        local_x = cosine * dx + sine * dy
        local_y = -sine * dx + cosine * dy
    else:
        local_x = dx
        local_y = dy
    q = (
        np.power(np.abs(local_x / radii[0]), power)
        + np.power(np.abs(local_y / radii[1]), power)
        + np.power(np.abs(dz / radii[2]), power)
    )
    return (np.power(q, 1.0 / power) - 1.0) * min(radii)


def authored_field() -> tuple[np.ndarray, tuple[np.ndarray, np.ndarray, np.ndarray]]:
    x_min, x_max, y_min, y_max, z_min, z_max = GRID_BOUNDS
    nx, ny, nz = GRID_DIMS
    xs = np.linspace(x_min, x_max, nx, dtype=np.float32)[:, None, None]
    ys = np.linspace(y_min, y_max, ny, dtype=np.float32)[None, :, None]
    zs = np.linspace(z_min, z_max, nz, dtype=np.float32)[None, None, :]

    # The first three volumes establish the broad dome, lower belly, and fused
    # base web. Remaining volumes form limbs that are visibly separated below
    # their upper attachment but stay part of the same implicit component.
    solids = [
        ((0.00, 0.80, -0.01), (0.50, 0.70, 0.41), 2.35, 0.0),
        ((0.00, 0.39, 0.03), (0.53, 0.34, 0.44), 2.25, 0.0),
        ((0.00, 0.155, 0.075), (0.46, 0.115, 0.40), 3.10, 0.0),
        ((-0.345, 0.105, 0.175), (0.315, 0.135, 0.390), 2.55, 6.0),
        ((0.345, 0.105, 0.175), (0.315, 0.135, 0.390), 2.55, -6.0),
        ((-0.455, 0.800, -0.005), (0.205, 0.285, 0.275), 2.30, -15.0),
        ((-0.575, 0.615, 0.020), (0.165, 0.255, 0.235), 2.25, -12.0),
        ((-0.590, 0.405, 0.065), (0.140, 0.215, 0.205), 2.20, -5.0),
        ((0.455, 0.800, -0.005), (0.205, 0.285, 0.275), 2.30, 15.0),
        ((0.575, 0.615, 0.020), (0.165, 0.255, 0.235), 2.25, 12.0),
        ((0.590, 0.405, 0.065), (0.140, 0.215, 0.205), 2.20, 5.0),
    ]
    field = superellipsoid_sdf(xs, ys, zs, *solids[0])
    for solid in solids[1:]:
        field = smooth_min(
            field,
            superellipsoid_sdf(xs, ys, zs, *solid),
            UNION_SOFTNESS,
        )

    # Recesses intersect only the front (+Z) skin. Difference against an
    # exterior-overlapping ellipsoid creates a shallow closed socket, not a
    # separate insert or through-hole.
    cavities = [
        ((-0.205, 0.845, 0.420), (0.190, 0.122, 0.048), 2.20, -25.0),
        ((0.205, 0.845, 0.420), (0.190, 0.122, 0.048), 2.20, 25.0),
        ((0.000, 1.075, 0.410), (0.061, 0.061, 0.032), 2.00, 0.0),
        ((0.000, 0.625, 0.450), (0.078, 0.025, 0.030), 2.00, 0.0),
        # This exterior-overlapping subtraction opens a shallow arch between
        # the two front foot pads. It never passes through the body or creates
        # a second component, but prevents the silhouette reading as a plinth.
        ((0.000, 0.045, 0.050), (0.140, 0.135, 0.650), 2.10, 0.0),
    ]
    for cavity in cavities:
        cavity_field = superellipsoid_sdf(xs, ys, zs, *cavity)
        field = smooth_max(field, -cavity_field, SOCKET_SOFTNESS)
    return field.astype(np.float32, copy=False), (xs, ys, zs)


def clean_polydata(source: vtk.vtkPolyData) -> vtk.vtkPolyData:
    triangles = vtk.vtkTriangleFilter()
    triangles.SetInputData(source)
    triangles.Update()
    clean = vtk.vtkCleanPolyData()
    clean.SetInputConnection(triangles.GetOutputPort())
    clean.PointMergingOn()
    clean.ToleranceIsAbsoluteOn()
    clean.SetAbsoluteTolerance(1.0e-7)
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
    scalars = numpy_to_vtk(
        field.ravel(order="F"), deep=True, array_type=vtk.VTK_FLOAT
    )
    scalars.SetName("authored_sdf")
    image.GetPointData().SetScalars(scalars)

    contour = vtk.vtkFlyingEdges3D()
    contour.SetInputData(image)
    contour.SetValue(0, 0.0)
    contour.ComputeNormalsOff()
    contour.ComputeGradientsOff()
    contour.Update()
    surface = clean_polydata(contour.GetOutput())
    raw_faces = triangles(surface)
    raw_metrics = topology(surface, raw_faces)
    print(
        "T_V8_5_STAGE raw_surface "
        f"points={surface.GetNumberOfPoints()} faces={surface.GetNumberOfCells()} "
        f"regions={raw_metrics['regions']} boundary_edges={raw_metrics['boundary_edges']} "
        f"nonmanifold_edges={raw_metrics['nonmanifold_edges']} "
        f"winding_errors={raw_metrics['winding_errors']} "
        f"degenerate_faces={raw_metrics['degenerate_faces']} "
        f"euler={raw_metrics['euler']} "
        f"signed_volume={raw_metrics['signed_volume']:.6f}"
    )
    # FlyingEdges can emit zero-area triangles at exact voxel coincidences.
    # They are allowed only in this intermediate mesh because the bounded
    # decimation/cleanup stage removes them; every promotable candidate still
    # has to satisfy the strict zero-degenerate contract below.
    if not topology_is_closed(
        raw_metrics,
        require_non_degenerate=False,
        require_positive_volume=False,
    ):
        raise BuildError(f"raw SDF surface failed topology contract: {raw_metrics}")
    if surface.GetNumberOfCells() <= DECIMATION_FACE_BUDGETS[0]:
        return surface

    # vtkDecimatePro introduced a non-manifold edge at the 12k target on this
    # closed implicit surface. Quadric decimation preserves the closed surface
    # here, but every bounded candidate is still audited before it can advance.
    # If a future VTK build changes the result, prefer a larger clean candidate
    # instead of silently accepting broken topology.
    for budget in DECIMATION_FACE_BUDGETS:
        decimate = vtk.vtkQuadricDecimation()
        decimate.SetInputData(surface)
        decimate.SetTargetReduction(1.0 - budget / surface.GetNumberOfCells())
        decimate.VolumePreservationOn()
        decimate.Update()
        candidate = clean_polydata(decimate.GetOutput())
        candidate_faces = triangles(candidate)
        candidate_metrics = topology(candidate, candidate_faces)
        volume_ratio = abs(float(candidate_metrics["signed_volume"])) / abs(
            float(raw_metrics["signed_volume"])
        )
        print(
            "T_V8_5_STAGE decimated_surface "
            f"budget={budget} points={candidate.GetNumberOfPoints()} "
            f"faces={candidate.GetNumberOfCells()} regions={candidate_metrics['regions']} "
            f"boundary_edges={candidate_metrics['boundary_edges']} "
            f"nonmanifold_edges={candidate_metrics['nonmanifold_edges']} "
            f"winding_errors={candidate_metrics['winding_errors']} "
            f"degenerate_faces={candidate_metrics['degenerate_faces']} "
            f"euler={candidate_metrics['euler']} volume_ratio={volume_ratio:.6f}"
        )
        # Winding is internally consistent here but may still face inward. The
        # single later with_normals() pass performs deterministic orientation;
        # the final mesh is then required to have strictly positive volume.
        if (
            topology_is_closed(candidate_metrics, require_positive_volume=False)
            and volume_ratio >= MIN_DECIMATED_VOLUME_RATIO
        ):
            return candidate
    raise BuildError(
        "no bounded decimation candidate preserved the watertight topology and volume contract"
    )


def normalise_bounds(source: vtk.vtkPolyData) -> None:
    bounds = source.GetBounds()
    spans = (bounds[1] - bounds[0], bounds[3] - bounds[2], bounds[5] - bounds[4])
    if any(span <= 1.0e-8 for span in spans):
        raise BuildError(f"invalid generated bounds: {bounds}")
    scales = tuple(target / span for target, span in zip(TARGET_SIZE, spans))
    centre_x = (bounds[0] + bounds[1]) * 0.5
    centre_z = (bounds[4] + bounds[5]) * 0.5
    points = source.GetPoints()
    for index in range(points.GetNumberOfPoints()):
        x, y, z = points.GetPoint(index)
        points.SetPoint(
            index,
            (x - centre_x) * scales[0],
            (y - bounds[2]) * scales[1],
            (z - centre_z) * scales[2],
        )
    points.Modified()
    source.Modified()


def with_normals(source: vtk.vtkPolyData) -> vtk.vtkPolyData:
    normals = vtk.vtkPolyDataNormals()
    normals.SetInputData(source)
    normals.ConsistencyOn()
    normals.AutoOrientNormalsOn()
    normals.SplittingOff()
    normals.ComputePointNormalsOn()
    normals.ComputeCellNormalsOff()
    normals.Update()
    return normals.GetOutput()


def triangles(source: vtk.vtkPolyData) -> np.ndarray:
    output = np.empty((source.GetNumberOfCells(), 3), dtype=np.uint32)
    for cell_index in range(source.GetNumberOfCells()):
        cell = source.GetCell(cell_index)
        if cell.GetNumberOfPoints() != 3:
            raise BuildError(f"cell {cell_index} is not a triangle")
        output[cell_index] = [cell.GetPointId(i) for i in range(3)]
    return output


def topology(source: vtk.vtkPolyData, faces: np.ndarray) -> dict[str, float | int]:
    connectivity = vtk.vtkPolyDataConnectivityFilter()
    connectivity.SetInputData(source)
    connectivity.SetExtractionModeToAllRegions()
    connectivity.Update()

    boundary = vtk.vtkFeatureEdges()
    boundary.SetInputData(source)
    boundary.BoundaryEdgesOn()
    boundary.NonManifoldEdgesOff()
    boundary.FeatureEdgesOff()
    boundary.ManifoldEdgesOff()
    boundary.Update()

    nonmanifold = vtk.vtkFeatureEdges()
    nonmanifold.SetInputData(source)
    nonmanifold.BoundaryEdgesOff()
    nonmanifold.NonManifoldEdgesOn()
    nonmanifold.FeatureEdgesOff()
    nonmanifold.ManifoldEdgesOff()
    nonmanifold.Update()

    undirected: dict[tuple[int, int], int] = {}
    directed: dict[tuple[int, int], int] = {}
    for a, b, c in faces.tolist():
        for start, end in ((a, b), (b, c), (c, a)):
            edge = (min(start, end), max(start, end))
            undirected[edge] = undirected.get(edge, 0) + 1
            directed[(start, end)] = directed.get((start, end), 0) + 1
    winding_errors = sum(
        1
        for start, end in undirected
        if directed.get((start, end), 0) != 1
        or directed.get((end, start), 0) != 1
    )
    bad_edge_counts = sum(1 for count in undirected.values() if count != 2)
    euler = source.GetNumberOfPoints() - len(undirected) + len(faces)

    points = vtk_to_numpy(source.GetPoints().GetData()).astype(np.float64, copy=False)
    pa = points[faces[:, 0]]
    pb = points[faces[:, 1]]
    pc = points[faces[:, 2]]
    doubled_areas = np.linalg.norm(np.cross(pb - pa, pc - pa), axis=1)
    degenerate_faces = int(np.count_nonzero(doubled_areas <= 1.0e-12))
    signed_volume = float(np.einsum("ij,ij->i", pa, np.cross(pb, pc)).sum() / 6.0)
    return {
        "regions": connectivity.GetNumberOfExtractedRegions(),
        "boundary_edges": boundary.GetOutput().GetNumberOfCells(),
        "nonmanifold_edges": nonmanifold.GetOutput().GetNumberOfCells(),
        "bad_edge_counts": bad_edge_counts,
        "winding_errors": winding_errors,
        "degenerate_faces": degenerate_faces,
        "euler": euler,
        "signed_volume": signed_volume,
    }


def topology_is_closed(
    metrics: dict[str, float | int], *, require_non_degenerate: bool = True,
    require_positive_volume: bool = True,
) -> bool:
    signed_volume = float(metrics["signed_volume"])
    volume_is_valid = signed_volume > 0.10 if require_positive_volume else abs(signed_volume) > 0.10
    return (
        metrics["regions"] == 1
        and metrics["boundary_edges"] == 0
        and metrics["nonmanifold_edges"] == 0
        and metrics["bad_edge_counts"] == 0
        and metrics["winding_errors"] == 0
        and (not require_non_degenerate or metrics["degenerate_faces"] == 0)
        and metrics["euler"] == 2
        and volume_is_valid
    )


def aligned(chunks: Iterable[bytes]) -> tuple[bytes, list[int]]:
    output = bytearray()
    offsets: list[int] = []
    for chunk in chunks:
        while len(output) % 4:
            output.append(0)
        offsets.append(len(output))
        output.extend(chunk)
    while len(output) % 4:
        output.append(0)
    return bytes(output), offsets


def write_glb(path: Path, source: vtk.vtkPolyData, faces: np.ndarray) -> None:
    positions = np.ascontiguousarray(
        vtk_to_numpy(source.GetPoints().GetData()).astype("<f4", copy=False)
    )
    normal_array = source.GetPointData().GetNormals()
    if normal_array is None:
        raise BuildError("generated mesh has no point normals")
    normals = np.ascontiguousarray(vtk_to_numpy(normal_array).astype("<f4", copy=False))
    indices = np.ascontiguousarray(faces.reshape(-1).astype("<u4", copy=False))
    if positions.shape != normals.shape or positions.shape[1] != 3:
        raise BuildError("POSITION and NORMAL arrays do not share a VEC3 layout")

    position_bytes = positions.tobytes()
    normal_bytes = normals.tobytes()
    index_bytes = indices.tobytes()
    binary, offsets = aligned((position_bytes, normal_bytes, index_bytes))
    minimum = [float(value) for value in positions.min(axis=0)]
    maximum = [float(value) for value in positions.max(axis=0)]
    document = {
        "accessors": [
            {
                "bufferView": 0,
                "componentType": 5126,
                "count": len(positions),
                "max": maximum,
                "min": minimum,
                "type": "VEC3",
            },
            {
                "bufferView": 1,
                "componentType": 5126,
                "count": len(normals),
                "type": "VEC3",
            },
            {
                "bufferView": 2,
                "componentType": 5125,
                "count": len(indices),
                "type": "SCALAR",
            },
        ],
        "asset": {
            "generator": "IMMUNE deterministic project-authored V8.5 sculpt builder",
            "version": "2.0",
        },
        "bufferViews": [
            {
                "buffer": 0,
                "byteLength": len(position_bytes),
                "byteOffset": offsets[0],
                "target": 34962,
            },
            {
                "buffer": 0,
                "byteLength": len(normal_bytes),
                "byteOffset": offsets[1],
                "target": 34962,
            },
            {
                "buffer": 0,
                "byteLength": len(index_bytes),
                "byteOffset": offsets[2],
                "target": 34963,
            },
        ],
        "buffers": [{"byteLength": len(binary)}],
        "meshes": [
            {
                "name": "V8.5-AuthoredSculpt-T",
                "primitives": [
                    {
                        "attributes": {"NORMAL": 1, "POSITION": 0},
                        "indices": 2,
                        "mode": 4,
                    }
                ],
            }
        ],
        "nodes": [{"mesh": 0, "name": "V8.5-AuthoredSculpt-T"}],
        "scene": 0,
        "scenes": [{"nodes": [0]}],
    }
    json_bytes = json.dumps(document, separators=(",", ":"), sort_keys=True).encode("utf-8")
    json_bytes += b" " * ((-len(json_bytes)) % 4)
    total_length = 12 + 8 + len(json_bytes) + 8 + len(binary)
    payload = bytearray(struct.pack("<4sII", b"glTF", 2, total_length))
    payload.extend(struct.pack("<I4s", len(json_bytes), b"JSON"))
    payload.extend(json_bytes)
    payload.extend(struct.pack("<I4s", len(binary), b"BIN\x00"))
    payload.extend(binary)
    path.write_bytes(payload)


def validate_glb_contract(path: Path) -> None:
    raw = path.read_bytes()
    if len(raw) < 20:
        raise BuildError("generated GLB is truncated")
    magic, version, declared_length = struct.unpack_from("<4sII", raw, 0)
    if magic != b"glTF" or version != 2 or declared_length != len(raw):
        raise BuildError("generated output is not a complete GLB 2.0 container")
    json_length, json_type = struct.unpack_from("<I4s", raw, 12)
    if json_type != b"JSON" or 20 + json_length > len(raw):
        raise BuildError("generated GLB has an invalid JSON chunk")
    document = json.loads(raw[20 : 20 + json_length].decode("utf-8").rstrip(" \x00"))
    if len(document.get("nodes", [])) != 1 or len(document.get("meshes", [])) != 1:
        raise BuildError("generated GLB must contain exactly one node and one mesh")
    primitives = document["meshes"][0].get("primitives", [])
    if len(primitives) != 1:
        raise BuildError("generated GLB must contain exactly one primitive")
    for forbidden in ("materials", "textures", "images", "animations", "skins"):
        if document.get(forbidden):
            raise BuildError(f"generated GLB unexpectedly contains {forbidden}")


def main() -> int:
    args = parse_args()
    output = args.output.resolve()
    if output.exists():
        raise BuildError(f"refusing to overwrite existing output: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)

    field, _coordinates = authored_field()
    body = extract_surface(field)
    normalise_bounds(body)
    body = with_normals(body)
    faces = triangles(body)
    metrics = topology(body, faces)
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
            raise BuildError(f"topology contract failed: {name}={metrics[name]} expected={value}")
    if float(metrics["signed_volume"]) <= 0.10:
        raise BuildError(f"positive enclosed volume is invalid: {metrics['signed_volume']}")

    with tempfile.TemporaryDirectory(
        prefix=".immune-v8-5-authored-", dir=output.parent
    ) as raw_tmp:
        candidate = Path(raw_tmp) / "candidate.glb"
        write_glb(candidate, body, faces)
        validate_glb_contract(candidate)
        # The temporary directory is deliberately inside output.parent, making
        # this hard-link promotion same-filesystem and atomic. Unlike replace(),
        # os.link() fails with EEXIST if another process creates the immutable
        # destination during generation, so the no-overwrite promise has no
        # check/use race.
        os.link(candidate, output)

    bounds = tuple(round(value, 6) for value in body.GetBounds())
    print(
        "T_V8_5_AUTHORED_SCULPT_OK "
        f"output={output} bytes={output.stat().st_size} sha256={sha256(output)} "
        f"points={body.GetNumberOfPoints()} faces={body.GetNumberOfCells()} "
        f"bounds={bounds} regions=1 boundary_edges=0 nonmanifold_edges=0 "
        f"winding_errors=0 degenerate_faces=0 euler=2 "
        f"signed_volume={metrics['signed_volume']:.6f} "
        f"numpy={np.__version__} vtk={vtk.vtkVersion.GetVTKVersion()} "
        "source_mesh=none provider_api=none materials=0 textures=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (BuildError, OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"T_V8_5_AUTHORED_SCULPT_FAILED {exc}")
        raise SystemExit(1)
