"""Prepare IMMUNE's deterministic, tileable jelly-skin height texture.

The source is ProcTexture's CC0 Orange Peel 1K PBR pack. Its fine, shallow,
seamless height map is a closer material reference than the rejected synthetic
RBF fields, which connected into clay-like wrinkles on the curved character.

The checked-in texture packs three decorrelated projections in RGB. The source
pack and its height member are checksum-pinned before any output is written.

Usage:
    python3 build/generate_jelly_height.py
    python3 build/generate_jelly_height.py \
        --source-zip=/path/to/orange-peel.zip \
        --preview=/tmp/jelly-height-preview.png

Source page and license:
    https://proctexture.com/textures/plaster/textured/orange-peel
    CC0; commercial and personal use permitted without attribution.
"""

from __future__ import annotations

import argparse
import hashlib
import io
from pathlib import Path
import urllib.error
import urllib.request
import zipfile

import numpy as np
from PIL import Image


DEFAULT_OUTPUT = Path("godot/immune/characters/gel/jelly_micro_height.png")
SOURCE_PAGE = "https://proctexture.com/textures/plaster/textured/orange-peel"
SOURCE_URL = "https://proctexture.com/pbr-packs/plaster/orange-peel.zip"
SOURCE_ZIP_SHA256 = "a95fa0d0acfe71054d8f2ea8993887e39ce4be7190fb9bf1d354088cac6815c0"
SOURCE_HEIGHT_MEMBER = "plaster-orange-peel-1k/height.png"
SOURCE_HEIGHT_SHA256 = "c1b1a860dec8e404588d9aaba1417140148218553b8af9a90fb09293f5f4ae87"
SIZE = 512
LEVEL_LOW = 0.40
LEVEL_HIGH = 0.60
GREEN_ROLL = (281, 173)  # y, x
BLUE_ROLL = (97, 311)  # y, x, after transposition


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _read_source_pack(source_zip: Path | None) -> bytes:
    if source_zip is not None:
        try:
            packed = source_zip.read_bytes()
        except OSError as exc:
            raise SystemExit(f"cannot read --source-zip {source_zip}: {exc}") from exc
    else:
        request = urllib.request.Request(
            SOURCE_URL,
            headers={"User-Agent": "IMMUNE-jelly-height-builder/1.0"},
        )
        try:
            with urllib.request.urlopen(request, timeout=30.0) as response:
                packed = response.read()
        except (OSError, urllib.error.URLError) as exc:
            raise SystemExit(
                "cannot download the pinned CC0 source pack; download "
                f"{SOURCE_URL} and pass --source-zip=<path>: {exc}"
            ) from exc
    digest = _sha256(packed)
    if digest != SOURCE_ZIP_SHA256:
        raise SystemExit(
            "source pack checksum mismatch: "
            f"expected {SOURCE_ZIP_SHA256}, received {digest}"
        )
    return packed


def _extract_height(source_pack: bytes) -> bytes:
    try:
        with zipfile.ZipFile(io.BytesIO(source_pack)) as archive:
            height = archive.read(SOURCE_HEIGHT_MEMBER)
    except (KeyError, zipfile.BadZipFile) as exc:
        raise SystemExit(f"pinned height member is unavailable: {exc}") from exc
    digest = _sha256(height)
    if digest != SOURCE_HEIGHT_SHA256:
        raise SystemExit(
            "source height checksum mismatch: "
            f"expected {SOURCE_HEIGHT_SHA256}, received {digest}"
        )
    return height


def _prepare_height(source_height: bytes) -> np.ndarray:
    try:
        source = Image.open(io.BytesIO(source_height)).convert("L")
    except OSError as exc:
        raise SystemExit(f"cannot decode pinned height PNG: {exc}") from exc
    source = source.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    gray = np.asarray(source, dtype=np.float64) / 255.0
    leveled = np.clip(
        (gray - LEVEL_LOW) / (LEVEL_HIGH - LEVEL_LOW),
        0.0,
        1.0,
    )
    base = np.rint(leveled * 255.0).astype(np.uint8)
    green = np.roll(base, shift=GREEN_ROLL, axis=(0, 1))
    blue = np.roll(base.T, shift=BLUE_ROLL, axis=(0, 1))
    return np.stack((base, green, blue), axis=2)


def _channel_metrics(channel: np.ndarray) -> dict[str, float]:
    x_step = float(np.abs(np.roll(channel, -1, axis=1) - channel).mean())
    y_step = float(np.abs(np.roll(channel, -1, axis=0) - channel).mean())
    interior_steps = np.concatenate(
        (
            np.abs(np.diff(channel, axis=1)).ravel(),
            np.abs(np.diff(channel, axis=0)).ravel(),
        )
    )
    wrap_steps = np.concatenate(
        (
            np.abs(channel[:, 0] - channel[:, -1]),
            np.abs(channel[0, :] - channel[-1, :]),
        )
    )
    return {
        "mean": float(channel.mean()),
        "std": float(channel.std()),
        "min": float(channel.min()),
        "max": float(channel.max()),
        "anisotropy": max(x_step, y_step) / max(min(x_step, y_step), 1e-12),
        "wrap_p99_ratio": float(np.percentile(wrap_steps, 99.0))
        / max(float(np.percentile(interior_steps, 99.0)), 1e-12),
    }


def validate(height: np.ndarray) -> list[dict[str, float]]:
    """Fail before writing if source processing drifts from the shader contract."""
    if height.shape != (SIZE, SIZE, 3) or height.dtype != np.uint8:
        raise SystemExit(f"unexpected packed height shape/type: {height.shape} {height.dtype}")
    data = height.astype(np.float64) / 255.0
    metrics = [_channel_metrics(data[:, :, channel]) for channel in range(3)]
    for channel, item in enumerate(metrics):
        if not 0.22 <= item["mean"] <= 0.25:
            raise SystemExit(f"channel {channel} mean outside contract: {item['mean']:.6f}")
        if not 0.045 <= item["std"] <= 0.065:
            raise SystemExit(f"channel {channel} deviation outside contract: {item['std']:.6f}")
        if item["min"] < 0.14 or item["max"] > 0.56:
            raise SystemExit(
                f"channel {channel} height range outside soft-peel contract: "
                f"{item['min']:.6f}..{item['max']:.6f}"
            )
        if item["anisotropy"] > 1.05:
            raise SystemExit(f"channel {channel} became directional: {item['anisotropy']:.6f}")
        if item["wrap_p99_ratio"] > 1.10:
            raise SystemExit(
                f"channel {channel} wrap edge exceeds tile contract: "
                f"{item['wrap_p99_ratio']:.6f}"
            )
    correlation = np.corrcoef([data[:, :, channel].ravel() for channel in range(3)])
    max_cross_correlation = float(np.max(np.abs(correlation - np.eye(3))))
    if max_cross_correlation > 0.05:
        raise SystemExit(f"height channels are too correlated: {max_cross_correlation:.6f}")
    for item in metrics:
        item["max_cross_correlation"] = max_cross_correlation
    return metrics


def _save_rgb(data: np.ndarray, output: Path) -> str:
    output.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(data, mode="RGB").save(output, optimize=True)
    return _sha256(output.read_bytes())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-zip", type=Path)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()

    source_pack = _read_source_pack(args.source_zip)
    source_height = _extract_height(source_pack)
    height = _prepare_height(source_height)
    metrics = validate(height)
    digest = _save_rgb(height, args.output)
    if args.preview is not None:
        panels = [
            np.repeat(height[:, :, channel, None], 3, axis=2)
            for channel in range(3)
        ]
        _save_rgb(np.concatenate(panels, axis=1), args.preview)
    pixel_digest = _sha256(height.tobytes())
    summary = ";".join(
        "ch%d:mean=%.4f,std=%.4f,range=%.4f..%.4f,aniso=%.4f,wrap99=%.4f"
        % (
            channel,
            item["mean"],
            item["std"],
            item["min"],
            item["max"],
            item["anisotropy"],
            item["wrap_p99_ratio"],
        )
        for channel, item in enumerate(metrics)
    )
    print(
        "JELLY_HEIGHT_OK "
        f"source={SOURCE_PAGE} license=CC0 source_zip_sha256={SOURCE_ZIP_SHA256} "
        f"source_height_sha256={SOURCE_HEIGHT_SHA256} path={args.output} "
        f"size={SIZE} sha256={digest} pixel_sha256={pixel_digest} "
        f"correlation={metrics[0]['max_cross_correlation']:.4f} {summary}"
    )


if __name__ == "__main__":
    main()
