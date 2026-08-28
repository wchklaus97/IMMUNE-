#!/usr/bin/env python3
"""Validate a Meshy GLB and optionally install CHAR-BASE-M into Godot.

Validation is read-only by default. Installation requires --install and never
overwrites a different existing asset unless --replace is also provided.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import struct
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
M_TARGET = ROOT / "godot/immune/characters/base_m/CHAR-BASE-M-meshy-t2.glb"
M_PROVENANCE = ROOT / "godot/immune/characters/base_m/ASSET_PROVENANCE.md"
GLB_JSON_CHUNK = 0x4E4F534A
TRIANGLES_MODE = 4


class ValidationError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--project-dir", type=Path)
    source.add_argument("--glb", type=Path)
    parser.add_argument("--max-faces", type=int, default=12_000)
    parser.add_argument("--install", action="store_true")
    parser.add_argument("--replace", action="store_true")
    return parser.parse_args()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_source(args: argparse.Namespace) -> tuple[Path, dict[str, Any] | None]:
    if args.glb:
        return args.glb.resolve(), None
    project_dir = args.project_dir.resolve()
    metadata_path = project_dir / "metadata.json"
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"invalid project metadata: {exc}") from exc
    if metadata.get("asset_id") != "CHAR-BASE-M":
        raise ValidationError("project metadata is not for CHAR-BASE-M")
    if metadata.get("status") != "SUCCEEDED":
        raise ValidationError("Meshy task did not finish with SUCCEEDED")
    cost = metadata.get("consumed_credits")
    if not isinstance(cost, int) or cost > 5:
        raise ValidationError(f"unexpected or missing credit cost: {cost!r}")
    files = metadata.get("files")
    if not isinstance(files, list) or len(files) != 1:
        raise ValidationError("metadata must name exactly one generated file")
    filename = str(files[0])
    if Path(filename).name != filename:
        raise ValidationError("metadata file name must not contain a directory")
    downloaded = (project_dir / filename).resolve()
    try:
        downloaded.relative_to(project_dir)
    except ValueError as exc:
        raise ValidationError("metadata file escapes the project directory") from exc
    postprocess = metadata.get("postprocess")
    if postprocess is None:
        return downloaded, metadata
    if not isinstance(postprocess, dict):
        raise ValidationError("postprocess metadata must be an object")
    if postprocess.get("operation") != "gen_smooth_normals":
        raise ValidationError("unsupported postprocess operation")
    if postprocess.get("source_file") != filename:
        raise ValidationError("postprocess source does not match the downloaded GLB")
    if not downloaded.is_file():
        raise ValidationError("downloaded source GLB is missing")
    if postprocess.get("source_sha256") != sha256(downloaded):
        raise ValidationError("downloaded source GLB hash no longer matches metadata")
    output_filename = str(postprocess.get("output_file", ""))
    if not output_filename or Path(output_filename).name != output_filename:
        raise ValidationError("postprocess output file name is unsafe")
    source = (project_dir / output_filename).resolve()
    try:
        source.relative_to(project_dir)
    except ValueError as exc:
        raise ValidationError("postprocess output escapes the project directory") from exc
    if not source.is_file() or postprocess.get("output_sha256") != sha256(source):
        raise ValidationError("postprocessed GLB is missing or its hash changed")
    return source, metadata


def parse_glb(path: Path) -> tuple[dict[str, Any], bytes]:
    try:
        raw = path.read_bytes()
    except OSError as exc:
        raise ValidationError(f"GLB unreadable: {exc}") from exc
    if len(raw) < 20:
        raise ValidationError("GLB is too small")
    magic, version, declared_length = struct.unpack_from("<4sII", raw, 0)
    if magic != b"glTF" or version != 2:
        raise ValidationError("asset is not a GLB 2.0 file")
    if declared_length != len(raw):
        raise ValidationError(
            f"GLB declared length {declared_length} does not match {len(raw)}"
        )
    offset = 12
    json_chunk: bytes | None = None
    while offset + 8 <= len(raw):
        chunk_length, chunk_type = struct.unpack_from("<II", raw, offset)
        offset += 8
        end = offset + chunk_length
        if end > len(raw):
            raise ValidationError("GLB chunk extends beyond the file")
        if chunk_type == GLB_JSON_CHUNK and json_chunk is None:
            json_chunk = raw[offset:end]
        offset = end
    if offset != len(raw) or json_chunk is None:
        raise ValidationError("GLB chunks are malformed or JSON is missing")
    try:
        document = json.loads(json_chunk.decode("utf-8").rstrip(" \t\r\n\x00"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ValidationError(f"GLB JSON is invalid: {exc}") from exc
    if not isinstance(document, dict):
        raise ValidationError("GLB JSON root must be an object")
    return document, raw


def accessor_count(document: dict[str, Any], accessor_index: int) -> int:
    accessors = document.get("accessors") or []
    if not isinstance(accessors, list) or not 0 <= accessor_index < len(accessors):
        raise ValidationError(f"invalid accessor index {accessor_index}")
    count = accessors[accessor_index].get("count")
    if not isinstance(count, int) or count <= 0:
        raise ValidationError(f"accessor {accessor_index} has no positive count")
    return count


def inspect_geometry(document: dict[str, Any]) -> dict[str, Any]:
    meshes = document.get("meshes") or []
    nodes = document.get("nodes") or []
    if not isinstance(meshes, list) or not meshes:
        raise ValidationError("GLB contains no meshes")
    triangle_faces = 0
    primitive_count = 0
    has_normals = True
    bounds_min = [float("inf")] * 3
    bounds_max = [float("-inf")] * 3
    for mesh in meshes:
        primitives = mesh.get("primitives") or []
        if not isinstance(primitives, list) or not primitives:
            raise ValidationError("mesh contains no primitives")
        for primitive in primitives:
            primitive_count += 1
            if int(primitive.get("mode", TRIANGLES_MODE)) != TRIANGLES_MODE:
                raise ValidationError("hero asset contains a non-triangle primitive")
            indices = primitive.get("indices")
            attributes = primitive.get("attributes") or {}
            position_index = attributes.get("POSITION") if isinstance(attributes, dict) else None
            normal_index = attributes.get("NORMAL") if isinstance(attributes, dict) else None
            if not isinstance(normal_index, int):
                has_normals = False
            elif isinstance(position_index, int):
                normal_count = accessor_count(document, normal_index)
                if normal_count != accessor_count(document, position_index):
                    raise ValidationError("NORMAL and POSITION accessor counts differ")
            if isinstance(indices, int):
                index_count = accessor_count(document, indices)
                if index_count % 3 != 0:
                    raise ValidationError("triangle index count is not divisible by three")
                triangle_faces += index_count // 3
            elif isinstance(position_index, int):
                vertex_count = accessor_count(document, position_index)
                if vertex_count % 3 != 0:
                    raise ValidationError("non-indexed triangle vertex count is not divisible by three")
                triangle_faces += vertex_count // 3
            else:
                raise ValidationError("primitive has neither indices nor POSITION")
            if isinstance(position_index, int):
                accessor = document["accessors"][position_index]
                low, high = accessor.get("min"), accessor.get("max")
                if isinstance(low, list) and isinstance(high, list) and len(low) >= 3 and len(high) >= 3:
                    for axis in range(3):
                        bounds_min[axis] = min(bounds_min[axis], float(low[axis]))
                        bounds_max[axis] = max(bounds_max[axis], float(high[axis]))
    if triangle_faces <= 0:
        raise ValidationError("no triangle faces were counted")
    extents = [bounds_max[i] - bounds_min[i] for i in range(3)]
    if any(value <= 0.0 for value in extents):
        extents = []
    return {
        "mesh_count": len(meshes),
        "node_count": len(nodes) if isinstance(nodes, list) else 0,
        "primitive_count": primitive_count,
        "triangle_faces": triangle_faces,
        "extents": extents,
        "has_normals": has_normals,
    }


def install(path: Path, metadata: dict[str, Any] | None, replace: bool) -> None:
    if metadata is None:
        raise ValidationError("--install requires --project-dir with immutable task metadata")
    M_TARGET.parent.mkdir(parents=True, exist_ok=True)
    source_hash = sha256(path)
    identical = False
    if M_TARGET.exists():
        if sha256(M_TARGET) == source_hash:
            identical = True
        elif not replace:
            raise ValidationError(
                f"target already contains a different asset: {M_TARGET}; pass --replace explicitly"
            )
    if not identical:
        shutil.copy2(path, M_TARGET)
    task_id = metadata.get("task_id", "unknown")
    api_version = metadata.get("api_version", "unknown")
    postprocess = metadata.get("postprocess")
    face_count = metadata.get("face_count")
    if not isinstance(face_count, int) and isinstance(postprocess, dict):
        face_count = postprocess.get("triangle_faces", "unknown")
    if not isinstance(face_count, int):
        face_count = "unknown"
    postprocess_note = "- Post-process: none\n"
    if isinstance(postprocess, dict):
        postprocess_note = (
            "- Post-process: Assimp smooth normals; geometry unchanged\n"
            f"- Downloaded SHA-256: `{postprocess.get('source_sha256', 'unknown')}`\n"
        )
    provenance = (
        "# CHAR-BASE-M Meshy T2 asset provenance\n\n"
        f"- Task ID: `{task_id}`\n"
        f"- API server version: `{api_version}`\n"
        "- Model: `model_type=smart-topology`, `ai_model=meshy-t2`\n"
        f"- Meshy-reported face count: {face_count}\n"
        f"- Credits consumed: {metadata.get('consumed_credits', 'unknown')}\n"
        f"{postprocess_note}"
        f"- Installed SHA-256: `{source_hash}`\n"
        "- Material strategy: shared Godot wet-gel shader; Meshy texture disabled.\n"
        "- Runtime slot: `characters/base_m/character.tscn` loads this GLB when present and keeps the procedural blockout as fallback.\n"
    )
    M_PROVENANCE.write_text(provenance, encoding="utf-8")
    action = "INSTALL_REFRESHED_PROVENANCE" if identical else "INSTALL_OK"
    print(f"{action} target={M_TARGET.relative_to(ROOT)} sha256={source_hash}")


def main() -> int:
    args = parse_args()
    if args.max_faces <= 0:
        raise ValidationError("--max-faces must be positive")
    path, metadata = load_source(args)
    if not path.is_file():
        raise ValidationError(f"GLB not found: {path}")
    document, raw = parse_glb(path)
    geometry = inspect_geometry(document)
    if geometry["triangle_faces"] > args.max_faces:
        raise ValidationError(
            f"face budget exceeded: {geometry['triangle_faces']} > {args.max_faces}"
        )
    if metadata is not None and metadata.get("postprocess") is not None and not geometry["has_normals"]:
        raise ValidationError("postprocessed hero GLB is missing smooth normals")
    print(
        "GLB_VALIDATION_OK "
        f"bytes={len(raw)} sha256={sha256(path)} "
        f"meshes={geometry['mesh_count']} nodes={geometry['node_count']} "
        f"primitives={geometry['primitive_count']} faces={geometry['triangle_faces']} "
        f"normals={str(geometry['has_normals']).lower()} extents={geometry['extents']}"
    )
    if args.install:
        install(path, metadata, args.replace)
    else:
        print("VALIDATION_ONLY no_files_changed=true")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidationError as exc:
        print(f"VALIDATION_STOPPED: {exc}", file=sys.stderr)
        raise SystemExit(2)
