#!/usr/bin/env python3
"""Build a watertight, material-free T body from the preserved reference GLB.

The source GLB stores the torso/limbs and three facial inserts in one primitive.
This tool welds attribute seams, retains only the largest connected region,
fills the eye/pore openings, normalises the hero bounds, and proves that the
result is one closed manifold before exporting a new GLB. It never overwrites
an existing output.
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
import struct
import subprocess
import tempfile
from pathlib import Path

import vtk


TARGET_SIZE = (1.18, 1.16, 1.00)
WELD_TOLERANCE = 1.0e-5


class BuildError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args()


def run(command: list[str]) -> None:
    completed = subprocess.run(command, check=False, capture_output=True, text=True)
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise BuildError(f"command failed ({completed.returncode}): {' '.join(command)}\n{detail}")


def clean_polydata(source: vtk.vtkPolyData) -> vtk.vtkPolyData:
    clean = vtk.vtkCleanPolyData()
    clean.SetInputData(source)
    clean.PointMergingOn()
    clean.ToleranceIsAbsoluteOn()
    clean.SetAbsoluteTolerance(WELD_TOLERANCE)
    clean.Update()
    return clean.GetOutput()


def largest_region(source: vtk.vtkPolyData) -> vtk.vtkPolyData:
    connectivity = vtk.vtkPolyDataConnectivityFilter()
    connectivity.SetInputData(source)
    connectivity.SetExtractionModeToLargestRegion()
    connectivity.Update()
    return clean_polydata(connectivity.GetOutput())


def fill_and_triangulate(source: vtk.vtkPolyData) -> vtk.vtkPolyData:
    fill = vtk.vtkFillHolesFilter()
    fill.SetInputData(source)
    fill.SetHoleSize(10.0)
    fill.Update()
    triangles = vtk.vtkTriangleFilter()
    triangles.SetInputConnection(fill.GetOutputPort())
    triangles.Update()
    return clean_polydata(triangles.GetOutput())


def normalise_bounds(source: vtk.vtkPolyData) -> None:
    bounds = source.GetBounds()
    spans = (bounds[1] - bounds[0], bounds[3] - bounds[2], bounds[5] - bounds[4])
    if any(span <= 1.0e-8 for span in spans):
        raise BuildError(f"invalid source bounds: {bounds}")
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


def topology(source: vtk.vtkPolyData) -> tuple[int, int, int]:
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
    return (
        connectivity.GetNumberOfExtractedRegions(),
        boundary.GetOutput().GetNumberOfCells(),
        nonmanifold.GetOutput().GetNumberOfCells(),
    )


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_glb_container(path: Path) -> None:
    """Reject a partial Assimp output before it can become the requested asset."""
    try:
        with path.open("rb") as handle:
            header = handle.read(12)
    except OSError as exc:
        raise BuildError(f"generated GLB is unreadable: {exc}") from exc
    if len(header) != 12:
        raise BuildError("generated GLB is truncated before its header")
    magic, version, declared_length = struct.unpack("<4sII", header)
    actual_length = path.stat().st_size
    if magic != b"glTF" or version != 2:
        raise BuildError("generated output is not a GLB 2.0 container")
    if declared_length != actual_length:
        raise BuildError(
            "generated GLB length mismatch: "
            f"declared={declared_length} actual={actual_length}"
        )


def main() -> int:
    args = parse_args()
    source = args.source.resolve()
    output = args.output.resolve()
    if not source.is_file():
        raise BuildError(f"source GLB does not exist: {source}")
    if output.exists():
        raise BuildError(f"refusing to overwrite existing output: {output}")
    assimp = shutil.which("assimp")
    if assimp is None:
        raise BuildError("assimp is required but was not found on PATH")
    output.parent.mkdir(parents=True, exist_ok=True)

    # Keep the candidate beside the destination so the final Path.replace() is
    # an atomic same-filesystem operation. A failed Assimp conversion or failed
    # container validation is removed with this directory and can never leave a
    # partial file at --output that blocks a safe retry.
    with tempfile.TemporaryDirectory(
        prefix=".immune-t-single-mass-", dir=output.parent
    ) as raw_tmp:
        temporary = Path(raw_tmp)
        source_obj = temporary / "source.obj"
        body_ply = temporary / "body.ply"
        candidate_glb = temporary / "candidate.glb"
        run([assimp, "export", str(source), str(source_obj), "-f", "objnomtl"])

        reader = vtk.vtkOBJReader()
        reader.SetFileName(str(source_obj))
        reader.Update()
        welded = clean_polydata(reader.GetOutput())
        body = fill_and_triangulate(largest_region(welded))
        normalise_bounds(body)
        body = with_normals(body)
        regions, boundary_edges, nonmanifold_edges = topology(body)
        if (regions, boundary_edges, nonmanifold_edges) != (1, 0, 0):
            raise BuildError(
                "single-mass topology failed: "
                f"regions={regions} boundary_edges={boundary_edges} "
                f"nonmanifold_edges={nonmanifold_edges}"
            )

        # VTK 9.6's macOS OBJ writer can segfault on filled-hole output. PLY is
        # a geometry-equivalent, material-free interchange here and keeps the
        # conversion deterministic before Assimp writes the final GLB.
        writer = vtk.vtkPLYWriter()
        writer.SetFileName(str(body_ply))
        writer.SetInputData(body)
        writer.SetFileTypeToBinary()
        if writer.Write() != 1:
            raise BuildError("VTK failed to write the intermediate body PLY")
        run([assimp, "export", str(body_ply), str(candidate_glb), "-f", "glb2"])
        validate_glb_container(candidate_glb)
        candidate_glb.replace(output)

    print(
        "T_SINGLE_MASS_OK "
        f"output={output} bytes={output.stat().st_size} sha256={sha256(output)} "
        f"points={body.GetNumberOfPoints()} faces={body.GetNumberOfCells()} "
        f"bounds={tuple(round(value, 6) for value in body.GetBounds())} "
        "regions=1 boundary_edges=0 nonmanifold_edges=0"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BuildError as exc:
        print(f"T_SINGLE_MASS_FAILED {exc}")
        raise SystemExit(1)
