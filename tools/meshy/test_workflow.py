#!/usr/bin/env python3
"""No-network safety contracts for the IMMUNE Meshy workflow."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent))

import run_m_cell_asset as runner  # noqa: E402


class _ServerErrorResponse:
    status_code = 500
    text = "simulated server error"


class _CountingSession:
    def __init__(self) -> None:
        self.calls = 0

    def request(self, *_args, **_kwargs) -> _ServerErrorResponse:
        self.calls += 1
        return _ServerErrorResponse()


class _DownloadResponse:
    def __init__(self, content: bytes) -> None:
        self.content = content

    def __enter__(self) -> "_DownloadResponse":
        return self

    def __exit__(self, *_args) -> None:
        return None

    def raise_for_status(self) -> None:
        return None

    def iter_content(self, chunk_size: int):
        del chunk_size
        yield self.content


class _DownloadSession:
    def __init__(self, content: bytes) -> None:
        self.content = content

    def get(self, *_args, **_kwargs) -> _DownloadResponse:
        return _DownloadResponse(self.content)


class MeshyWorkflowSafetyTests(unittest.TestCase):
    def test_paid_post_is_never_retried_after_server_error(self) -> None:
        session = _CountingSession()
        with self.assertRaises(runner.WorkflowError):
            runner.request_json(
                session,
                "POST",
                "https://api.meshy.ai/openapi/v1/image-to-3d",
                {"Authorization": "Bearer redacted"},
                payload={},
                idempotent=False,
            )
        self.assertEqual(session.calls, 1)

    def test_default_manifest_passes_no_network_preflight(self) -> None:
        manifest = runner.load_manifest(runner.DEFAULT_MANIFEST)
        source = runner.validate_manifest(manifest)
        self.assertTrue(source.is_file())
        self.assertEqual(manifest["expected_credits"], 5)

    def test_jpeg_thumbnail_keeps_its_real_extension(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            project_dir = Path(directory)
            filename = runner.download_thumbnail(
                _DownloadSession(b"\xff\xd8\xff\xe0fake-jpeg"),
                "https://example.invalid/thumbnail",
                project_dir,
            )
            self.assertEqual(filename, "thumbnail.jpg")
            self.assertTrue((project_dir / filename).is_file())
            self.assertFalse((project_dir / "thumbnail.part").exists())

    def test_atomic_json_write_leaves_no_partial_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "metadata.json"
            runner.write_json_atomic(output, {"status": "SUCCEEDED"})
            self.assertEqual(json.loads(output.read_text()), {"status": "SUCCEEDED"})
            self.assertFalse((Path(directory) / "metadata.json.part").exists())


if __name__ == "__main__":
    unittest.main()
