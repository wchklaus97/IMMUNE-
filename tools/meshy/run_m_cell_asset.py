#!/usr/bin/env python3
"""Cost-gated Meshy runner for IMMUNE base-cell hero assets.

Dry-run is the default and performs no network request. The only mutating mode
requires both --execute and an exact --approve-credits value matching the
manifest. All generated files are stored under meshy_output/.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Any

import requests


API_BASE = "https://api.meshy.ai"
TERMINAL_STATUSES = {"SUCCEEDED", "FAILED", "CANCELED"}
ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = Path(__file__).with_name("m_cell_request.json")
SUPPORTED_ASSETS = {
    "CHAR-BASE-M": {
        "source_image": "godot/immune/characters/concepts/base-cell-line-v2/CHAR-BASE-M.png",
        "output_filename": "CHAR-BASE-M-meshy-t2.glb",
    },
    "CHAR-BASE-N": {
        "source_image": "godot/immune/characters/concepts/base-cell-line-v2/CHAR-BASE-N.png",
        "output_filename": "CHAR-BASE-N-meshy-t2.glb",
    },
    "CHAR-BASE-A": {
        "source_image": "godot/immune/characters/concepts/base-cell-line-v2/CHAR-BASE-A.png",
        "output_filename": "CHAR-BASE-A-meshy-t2.glb",
    },
    "CHAR-BASE-D": {
        "source_image": "godot/immune/characters/concepts/base-cell-line-v2/CHAR-BASE-D.png",
        "output_filename": "CHAR-BASE-D-meshy-t2.glb",
    },
}


class WorkflowError(RuntimeError):
    """Expected, actionable workflow failure."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument(
        "--check-balance",
        "--balance-only",
        dest="check_balance",
        action="store_true",
        help="Call only the free balance endpoint after validation.",
    )
    parser.add_argument(
        "--execute",
        action="store_true",
        help="Create the paid Meshy task after all gates pass.",
    )
    parser.add_argument(
        "--approve-credits",
        type=int,
        help="Required with --execute; must exactly match expected_credits.",
    )
    parser.add_argument("--timeout", type=int, default=600)
    return parser.parse_args()


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise WorkflowError(f"manifest unreadable: {exc}") from exc
    if not isinstance(data, dict):
        raise WorkflowError("manifest root must be an object")
    return data


def validate_manifest(data: dict[str, Any]) -> Path:
    required = {
        "asset_id",
        "source_image",
        "output_filename",
        "endpoint",
        "poll_endpoint",
        "expected_credits",
        "request",
        "acceptance",
    }
    missing = sorted(required - data.keys())
    if missing:
        raise WorkflowError(f"manifest missing fields: {', '.join(missing)}")

    asset_id = str(data.get("asset_id", ""))
    asset_spec = SUPPORTED_ASSETS.get(asset_id)
    if asset_spec is None:
        raise WorkflowError(f"asset_id is not an approved base-cell slot: {asset_id!r}")
    if data.get("source_image") != asset_spec["source_image"]:
        raise WorkflowError(f"source_image does not match the locked {asset_id} reference")
    if data.get("output_filename") != asset_spec["output_filename"]:
        raise WorkflowError(f"output_filename does not match the stable {asset_id} slot")

    payload = data["request"]
    if not isinstance(payload, dict):
        raise WorkflowError("request must be an object")
    expected = {
        "model_type": "smart-topology",
        "ai_model": "meshy-t2",
        "topology": "triangle",
        "should_texture": False,
        "enable_pbr": False,
        "target_formats": ["glb"],
    }
    for field, value in expected.items():
        if payload.get(field) != value:
            raise WorkflowError(f"unsafe or stale request.{field}: expected {value!r}")
    polycount = payload.get("target_polycount")
    if not isinstance(polycount, int) or not 100 <= polycount <= 15_000:
        raise WorkflowError("smart-topology target_polycount must be 100..15000")
    if data["expected_credits"] != 5:
        raise WorkflowError("Smart Topology untextured request must retain the 5-credit gate")
    expected_endpoint = "/openapi/v1/image-to-3d"
    if data["endpoint"] != expected_endpoint or data["poll_endpoint"] != expected_endpoint:
        raise WorkflowError(
            f"create and poll endpoints must both remain {expected_endpoint}"
        )

    source = (ROOT / data["source_image"]).resolve()
    try:
        source.relative_to(ROOT)
    except ValueError as exc:
        raise WorkflowError("source_image escapes the repository root") from exc
    if not source.is_file():
        raise WorkflowError(f"source image not found: {source}")
    if source.suffix.lower() not in {".png", ".jpg", ".jpeg"}:
        raise WorkflowError("source image must be PNG or JPEG")
    if source.stat().st_size > 10 * 1024 * 1024:
        raise WorkflowError("source image exceeds the 10 MiB local safety limit")
    if Path(data["output_filename"]).name != data["output_filename"]:
        raise WorkflowError("output_filename must not contain a directory")
    acceptance = data.get("acceptance")
    if not isinstance(acceptance, dict):
        raise WorkflowError("acceptance must be an object")
    if acceptance.get("required_format") != "glb":
        raise WorkflowError("acceptance.required_format must remain glb")
    max_faces = acceptance.get("max_face_count")
    if not isinstance(max_faces, int) or not 100 <= max_faces <= 15_000:
        raise WorkflowError("acceptance.max_face_count must be 100..15000")
    minimum_bytes = acceptance.get("minimum_file_bytes")
    if not isinstance(minimum_bytes, int) or minimum_bytes < 4096:
        raise WorkflowError("acceptance.minimum_file_bytes must be at least 4096")
    silhouette = acceptance.get("silhouette")
    if not isinstance(silhouette, str) or len(silhouette.strip()) < 24:
        raise WorkflowError("acceptance.silhouette must describe the locked identity")
    return source


def get_api_key() -> str:
    key = os.environ.get("MESHY_API_KEY", "")
    if not key:
        raise WorkflowError("MESHY_API_KEY is not available in this process")
    if not key.startswith("msy_"):
        raise WorkflowError("MESHY_API_KEY does not use the expected msy_ prefix")
    return key


def request_json(
    session: requests.Session,
    method: str,
    url: str,
    headers: dict[str, str],
    *,
    payload: dict[str, Any] | None = None,
    idempotent: bool,
) -> tuple[dict[str, Any], requests.Response]:
    attempts = 0
    # Paid create calls are never retried automatically, including when Meshy
    # returns 429/5xx: the server may already have accepted the task. Inspect the
    # task list before issuing another POST.
    max_attempts = 4 if idempotent else 1
    while True:
        attempts += 1
        try:
            response = session.request(
                method,
                url,
                headers=headers,
                json=payload,
                timeout=30,
            )
        except requests.RequestException as exc:
            if not idempotent:
                raise WorkflowError(
                    "ambiguous POST network failure; stopped without retry. "
                    "Inspect the Meshy task list before any new create call: "
                    f"{exc}"
                ) from exc
            if attempts >= max_attempts:
                raise WorkflowError(f"network failure after {attempts} reads: {exc}") from exc
            time.sleep(min(2**attempts, 10))
            continue

        if response.status_code == 401:
            raise WorkflowError("Meshy rejected the API key (HTTP 401)")
        if response.status_code == 402:
            raise WorkflowError("Meshy reports insufficient credits (HTTP 402)")
        if response.status_code == 422:
            raise WorkflowError(f"Meshy cannot process this input (HTTP 422): {response.text[:300]}")
        if response.status_code == 429:
            if not idempotent:
                raise WorkflowError(
                    "paid POST received HTTP 429; stopped without retry. "
                    "Inspect the Meshy task list before creating another task"
                )
            if attempts >= max_attempts:
                raise WorkflowError("Meshy rate limit persisted after bounded retries")
            time.sleep((5, 10, 20)[min(attempts - 1, 2)])
            continue
        if response.status_code >= 500:
            if not idempotent:
                raise WorkflowError(
                    f"paid POST received HTTP {response.status_code}; stopped without retry. "
                    "Inspect the Meshy task list before creating another task"
                )
            if attempts >= max_attempts:
                raise WorkflowError(
                    f"Meshy server error persisted (HTTP {response.status_code}); stopped"
                )
            time.sleep(10)
            continue
        if response.status_code >= 400:
            raise WorkflowError(
                f"Meshy request rejected (HTTP {response.status_code}): {response.text[:500]}"
            )
        try:
            body = response.json()
        except ValueError as exc:
            raise WorkflowError("Meshy returned non-JSON data") from exc
        if not isinstance(body, dict):
            raise WorkflowError("Meshy returned an unexpected JSON shape")
        return body, response


def balance(session: requests.Session, headers: dict[str, str]) -> tuple[int, str]:
    body, response = request_json(
        session,
        "GET",
        f"{API_BASE}/openapi/v1/balance",
        headers,
        idempotent=True,
    )
    value = body.get("balance")
    if not isinstance(value, int):
        raise WorkflowError("balance response has no integer balance")
    return value, response.headers.get("x-api-version", "unknown")


def image_data_uri(path: Path) -> str:
    mime = "image/png" if path.suffix.lower() == ".png" else "image/jpeg"
    return f"data:{mime};base64,{base64.b64encode(path.read_bytes()).decode('ascii')}"


def poll_task(
    session: requests.Session,
    headers: dict[str, str],
    endpoint: str,
    task_id: str,
    timeout: int,
) -> dict[str, Any]:
    elapsed = 0.0
    delay = 5.0
    last_progress = -1
    while elapsed < timeout:
        body, _ = request_json(
            session,
            "GET",
            f"{API_BASE}{endpoint}/{task_id}",
            headers,
            idempotent=True,
        )
        status = str(body.get("status", "UNKNOWN"))
        progress = body.get("progress", 0)
        if progress != last_progress:
            print(f"TASK_PROGRESS status={status} progress={progress}", flush=True)
            last_progress = progress
        if status in TERMINAL_STATUSES:
            if status != "SUCCEEDED":
                error = body.get("task_error") or {}
                message = error.get("message", "unknown failure") if isinstance(error, dict) else error
                raise WorkflowError(
                    f"task {status}: {message}. No regeneration was attempted; inspect input and task metadata first."
                )
            return body
        wait_for = 15.0 if isinstance(progress, (int, float)) and progress >= 95 else delay
        time.sleep(wait_for)
        elapsed += wait_for
        if wait_for != 15.0:
            delay = min(delay * 1.5, 30.0)
    raise WorkflowError(f"task polling timed out after {timeout}s; task was not recreated")


def project_directory(asset_id: str, task_id: str) -> Path:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    slug = re.sub(r"[^a-z0-9]+", "-", asset_id.lower()).strip("-")
    path = ROOT / "meshy_output" / f"{timestamp}_{slug}_{task_id[:8]}"
    path.mkdir(parents=True, exist_ok=False)
    return path


def download_glb(
    session: requests.Session,
    url: str,
    destination: Path,
    minimum_bytes: int,
) -> None:
    partial = destination.with_suffix(destination.suffix + ".part")
    try:
        with session.get(url, timeout=300, stream=True) as response:
            response.raise_for_status()
            with partial.open("wb") as handle:
                for chunk in response.iter_content(chunk_size=64 * 1024):
                    if chunk:
                        handle.write(chunk)
        size = partial.stat().st_size
        if size < minimum_bytes:
            raise WorkflowError(f"downloaded GLB is suspiciously small: {size} bytes")
        if partial.read_bytes()[:4] != b"glTF":
            raise WorkflowError("downloaded file does not have the binary GLB magic header")
        partial.replace(destination)
    finally:
        if partial.exists():
            partial.unlink()


def download_thumbnail(
    session: requests.Session,
    url: str,
    project_dir: Path,
) -> str:
    partial = project_dir / "thumbnail.part"
    try:
        with session.get(url, timeout=60, stream=True) as response:
            response.raise_for_status()
            with partial.open("wb") as handle:
                for chunk in response.iter_content(chunk_size=64 * 1024):
                    if chunk:
                        handle.write(chunk)
        raw_header = partial.read_bytes()[:12]
        is_png = raw_header.startswith(b"\x89PNG\r\n\x1a\n")
        is_jpeg = raw_header.startswith(b"\xff\xd8\xff")
        if not is_png and not is_jpeg:
            raise WorkflowError("downloaded thumbnail is not PNG or JPEG")
        filename = "thumbnail.png" if is_png else "thumbnail.jpg"
        destination = project_dir / filename
        partial.replace(destination)
        return filename
    finally:
        if partial.exists():
            partial.unlink()


def write_json_atomic(path: Path, value: dict[str, Any]) -> None:
    partial = path.with_suffix(path.suffix + ".part")
    try:
        partial.write_text(
            json.dumps(value, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        partial.replace(path)
    finally:
        if partial.exists():
            partial.unlink()


def write_metadata(
    project_dir: Path,
    manifest: dict[str, Any],
    task: dict[str, Any],
    api_version: str,
    thumbnail_file: str | None,
) -> None:
    safe_manifest = dict(manifest)
    metadata = {
        "asset_id": manifest["asset_id"],
        "task_id": task.get("id"),
        "task_type": task.get("type"),
        "status": task.get("status"),
        "consumed_credits": task.get("consumed_credits"),
        "face_count": task.get("face_count"),
        "api_version": api_version,
        "created_at": datetime.now().isoformat(),
        "manifest": safe_manifest,
        "files": [manifest["output_filename"]],
        "thumbnail_file": thumbnail_file,
    }
    write_json_atomic(project_dir / "metadata.json", metadata)
    history_path = ROOT / "meshy_output" / "history.json"
    if history_path.exists():
        try:
            history = json.loads(history_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise WorkflowError(f"generation history is unreadable: {exc}") from exc
    else:
        history = {"version": 1, "projects": []}
    if not isinstance(history, dict) or not isinstance(history.get("projects"), list):
        raise WorkflowError("generation history has an unexpected shape")
    history["projects"].append(
        {
            "folder": project_dir.name,
            "asset_id": manifest["asset_id"],
            "task_id": task.get("id"),
            "consumed_credits": task.get("consumed_credits"),
            "created_at": metadata["created_at"],
        }
    )
    write_json_atomic(history_path, history)


def main() -> int:
    args = parse_args()
    manifest = load_manifest(args.manifest.resolve())
    source = validate_manifest(manifest)
    expected_credits = int(manifest["expected_credits"])

    print("PREFLIGHT_OK")
    print(f"ASSET={manifest['asset_id']}")
    print(f"SOURCE={source.relative_to(ROOT)}")
    print(f"ENDPOINT={manifest['endpoint']}")
    print(
        "PAYLOAD="
        + json.dumps(manifest["request"], sort_keys=True, separators=(",", ":"))
    )
    print(f"EXPECTED_CREDITS={expected_credits}")

    if not args.check_balance and not args.execute:
        print("DRY_RUN_OK network_calls=0 credits=0")
        return 0

    key = get_api_key()
    session = requests.Session()
    session.trust_env = False
    headers = {"Authorization": f"Bearer {key}"}
    current_balance, api_version = balance(session, headers)
    print(f"BALANCE_OK credits={current_balance} api_version={api_version}")

    if not args.execute:
        print("BALANCE_ONLY_OK generation_calls=0 credits=0")
        return 0
    if args.approve_credits != expected_credits:
        raise WorkflowError(
            "paid generation blocked: pass --approve-credits "
            f"{expected_credits} together with --execute"
        )
    if current_balance < expected_credits:
        raise WorkflowError(
            f"paid generation blocked: balance {current_balance} < {expected_credits}"
        )

    payload = dict(manifest["request"])
    payload["image_url"] = image_data_uri(source)
    body, create_response = request_json(
        session,
        "POST",
        f"{API_BASE}{manifest['endpoint']}",
        headers,
        payload=payload,
        idempotent=False,
    )
    task_id = body.get("result")
    if not isinstance(task_id, str) or not task_id:
        raise WorkflowError("create response did not contain a task id")
    print(f"TASK_CREATED id={task_id}", flush=True)
    task = poll_task(
        session,
        headers,
        manifest["poll_endpoint"],
        task_id,
        args.timeout,
    )
    actual_cost = task.get("consumed_credits")
    if not isinstance(actual_cost, int) or not 0 <= actual_cost <= expected_credits:
        raise WorkflowError(
            f"task reports unexpected cost {actual_cost}; stop before downstream operations"
        )
    model_urls = task.get("model_urls") or {}
    glb_url = model_urls.get("glb") if isinstance(model_urls, dict) else None
    if not isinstance(glb_url, str) or not glb_url:
        raise WorkflowError("succeeded task did not return model_urls.glb")

    project_dir = project_directory(manifest["asset_id"], task_id)
    destination = project_dir / manifest["output_filename"]
    download_glb(
        session,
        glb_url,
        destination,
        int(manifest["acceptance"]["minimum_file_bytes"]),
    )
    thumbnail_file: str | None = None
    thumbnail_url = task.get("thumbnail_url")
    if isinstance(thumbnail_url, str) and thumbnail_url:
        thumbnail_file = download_thumbnail(session, thumbnail_url, project_dir)
    write_metadata(
        project_dir,
        manifest,
        task,
        create_response.headers.get("x-api-version", api_version),
        thumbnail_file,
    )
    remaining, _ = balance(session, headers)
    print(f"GENERATION_OK file={destination} bytes={destination.stat().st_size}")
    print(f"CREDITS_CONSUMED={actual_cost} BALANCE_REMAINING={remaining}")
    print("NEXT=Run Godot import, silhouette review, material replacement, and face-count QA.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except WorkflowError as exc:
        print(f"WORKFLOW_STOPPED: {exc}", file=sys.stderr)
        raise SystemExit(2)
