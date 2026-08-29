#!/usr/bin/env python3
"""Add smooth normals to a verified Meshy hero GLB without changing geometry."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

from validate_hero_glb import ASSET_SLOTS, ValidationError, inspect_geometry, parse_glb, sha256


class SmoothError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-dir", type=Path, required=True)
    parser.add_argument("--replace", action="store_true")
    return parser.parse_args()


def read_metadata(project_dir: Path) -> tuple[Path, dict[str, Any]]:
    metadata_path = project_dir / "metadata.json"
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SmoothError(f"invalid project metadata: {exc}") from exc
    asset_id = str(metadata.get("asset_id", ""))
    if asset_id not in ASSET_SLOTS or metadata.get("status") != "SUCCEEDED":
        raise SmoothError("project is not a succeeded approved base-cell generation")
    if metadata.get("consumed_credits") != 5:
        raise SmoothError("project does not retain the exact 5-credit generation record")
    files = metadata.get("files")
    if not isinstance(files, list) or len(files) != 1:
        raise SmoothError("metadata must name one downloaded GLB")
    source_name = str(files[0])
    if Path(source_name).name != source_name:
        raise SmoothError("downloaded GLB filename is unsafe")
    if source_name != f"{asset_id}-meshy-t2.glb":
        raise SmoothError("downloaded GLB filename does not match the asset slot")
    source = (project_dir / source_name).resolve()
    try:
        source.relative_to(project_dir)
    except ValueError as exc:
        raise SmoothError("downloaded GLB escapes the project directory") from exc
    if not source.is_file():
        raise SmoothError("downloaded GLB is missing")
    return source, metadata


def main() -> int:
    args = parse_args()
    project_dir = args.project_dir.resolve()
    source, metadata = read_metadata(project_dir)
    assimp = shutil.which("assimp")
    if assimp is None:
        raise SmoothError("assimp is required to generate smooth normals")
    output = project_dir / f"{source.stem}-smooth.glb"
    if output.exists() and not args.replace:
        raise SmoothError(f"derivative already exists: {output}; pass --replace")
    partial = output.with_suffix(".glb.part")
    if partial.exists():
        partial.unlink()
    try:
        result = subprocess.run(
            [assimp, "export", str(source), str(partial), "-fglb2", "--gen-smooth-normals"],
            check=False,
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0 or not partial.is_file():
            detail = (result.stderr or result.stdout).strip()[-1200:]
            raise SmoothError(f"assimp smooth-normal export failed: {detail}")
        source_geometry = inspect_geometry(parse_glb(source)[0])
        output_geometry = inspect_geometry(parse_glb(partial)[0])
        if not output_geometry["has_normals"]:
            raise SmoothError("assimp output still has no NORMAL attribute")
        for key in ("mesh_count", "primitive_count", "triangle_faces", "extents"):
            if output_geometry[key] != source_geometry[key]:
                raise SmoothError(f"postprocess changed geometry field {key}")
        partial.replace(output)
    finally:
        if partial.exists():
            partial.unlink()
    try:
        version_output = subprocess.run(
            [assimp, "version"],
            check=False,
            capture_output=True,
            text=True,
            timeout=10,
        ).stdout.strip()
    except subprocess.TimeoutExpired:
        version_output = ""
    version = next(
        (line.strip() for line in version_output.splitlines() if line.strip().startswith("Version ")),
        "unknown",
    )
    metadata["postprocess"] = {
        "operation": "gen_smooth_normals",
        "tool": "assimp",
        "tool_version": version,
        "source_file": source.name,
        "source_sha256": sha256(source),
        "output_file": output.name,
        "output_sha256": sha256(output),
        "triangle_faces": output_geometry["triangle_faces"],
        "extents": output_geometry["extents"],
        "created_at": datetime.now().isoformat(),
    }
    metadata_path = project_dir / "metadata.json"
    metadata_partial = metadata_path.with_suffix(".json.part")
    try:
        metadata_partial.write_text(
            json.dumps(metadata, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        metadata_partial.replace(metadata_path)
    finally:
        if metadata_partial.exists():
            metadata_partial.unlink()
    print(
        "SMOOTH_NORMALS_OK "
        f"source_sha256={sha256(source)} output_sha256={sha256(output)} "
        f"faces={output_geometry['triangle_faces']} file={output}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (SmoothError, ValidationError, subprocess.TimeoutExpired) as exc:
        print(f"SMOOTH_NORMALS_STOPPED: {exc}", file=sys.stderr)
        raise SystemExit(2)
