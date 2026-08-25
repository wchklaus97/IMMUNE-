#!/usr/bin/env python3
"""Build 6-frame scan-to-mastery sprite sheets from keyed bio icons."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

FRAME = 512
FRAMES = 6
TINTS = [
    (236, 244, 255),  # LV.0 white
    (140, 210, 255),  # LV.1 cyan
    (120, 230, 150),  # LV.2 green
    (255, 210, 90),   # LV.3 gold
    (190, 140, 255),  # LV.4 violet
]


def _load_square(path: Path, size: int) -> Image.Image:
    src = Image.open(path).convert("RGBA")
    src = src.resize((size, size), Image.Resampling.LANCZOS)
    return src


def _alpha(img: Image.Image) -> Image.Image:
    return img.split()[3]


def _mask_points(alpha: Image.Image, threshold: int = 40) -> list[tuple[int, int]]:
    pix = alpha.load()
    w, h = alpha.size
    return [(x, y) for y in range(h) for x in range(w) if pix[x, y] >= threshold]


def _edge_points(alpha: Image.Image, threshold: int = 40) -> list[tuple[int, int]]:
    pix = alpha.load()
    w, h = alpha.size
    pts: list[tuple[int, int]] = []
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if pix[x, y] < threshold:
                continue
            if (
                pix[x - 1, y] < threshold
                or pix[x + 1, y] < threshold
                or pix[x, y - 1] < threshold
                or pix[x, y + 1] < threshold
            ):
                pts.append((x, y))
    return pts


def _sample(points: list[tuple[int, int]], count: int, min_dist: float, rng: random.Random) -> list[tuple[int, int]]:
    if not points:
        return []
    shuffled = points[:]
    rng.shuffle(shuffled)
    chosen: list[tuple[int, int]] = []
    dist2 = min_dist * min_dist
    for pt in shuffled:
        if len(chosen) >= count:
            break
        if all((pt[0] - c[0]) ** 2 + (pt[1] - c[1]) ** 2 >= dist2 for c in chosen):
            chosen.append(pt)
    if len(chosen) < count:
        chosen.extend(shuffled[: max(0, count - len(chosen))])
    return chosen[:count]


def _ordered_contour(edges: list[tuple[int, int]], step: int) -> list[tuple[int, int]]:
    if not edges:
        return []
    cx = sum(p[0] for p in edges) / len(edges)
    cy = sum(p[1] for p in edges) / len(edges)
    ordered = sorted(edges, key=lambda p: math.atan2(p[1] - cy, p[0] - cx))
    return ordered[:: max(1, step)]


def _blank() -> Image.Image:
    return Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))


def _dots(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], color: tuple[int, int, int], radius: int, alpha: int) -> None:
    fill = (*color, alpha)
    for x, y in points:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=fill)


def _polyline(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], color: tuple[int, int, int], width: int, alpha: int) -> None:
    if len(points) < 2:
        return
    draw.line(points + [points[0]], fill=(*color, alpha), width=width, joint="curve")


def _grid(draw: ImageDraw.ImageDraw, alpha_img: Image.Image, step: int, color: tuple[int, int, int], line_alpha: int) -> None:
    pix = alpha_img.load()
    w, h = alpha_img.size
    fill = (*color, line_alpha)
    for x in range(step // 2, w, step):
        run: list[tuple[int, int]] = []
        for y in range(h):
            if pix[x, y] >= 40:
                run.append((x, y))
            elif len(run) >= 4:
                draw.line(run, fill=fill, width=1)
                run = []
            else:
                run = []
        if len(run) >= 4:
            draw.line(run, fill=fill, width=1)
    for y in range(step // 2, h, step):
        run = []
        for x in range(w):
            if pix[x, y] >= 40:
                run.append((x, y))
            elif len(run) >= 4:
                draw.line(run, fill=fill, width=1)
                run = []
            else:
                run = []
        if len(run) >= 4:
            draw.line(run, fill=fill, width=1)


def _silhouette(alpha: Image.Image, color: tuple[int, int, int], opacity: int) -> Image.Image:
    layer = Image.new("RGBA", alpha.size, (*color, 0))
    solid = Image.new("RGBA", alpha.size, (*color, opacity))
    layer.paste(solid, mask=alpha.point(lambda a: 255 if a >= 40 else 0))
    return layer


def build_frames(src: Image.Image) -> list[Image.Image]:
    rng = random.Random(7)
    alpha = _alpha(src)
    body = _mask_points(alpha)
    edges = _edge_points(alpha)
    contour = _ordered_contour(edges, 3)

    lv0 = _blank()
    d0 = ImageDraw.Draw(lv0, "RGBA")
    _dots(d0, _sample(body, 90, 14, rng), TINTS[0], 2, 210)

    lv1 = _blank()
    d1 = ImageDraw.Draw(lv1, "RGBA")
    _dots(d1, _sample(body, 70, 16, rng), TINTS[1], 2, 180)
    _polyline(d1, _ordered_contour(edges, 8), TINTS[1], 2, 220)

    lv2 = _blank()
    d2 = ImageDraw.Draw(lv2, "RGBA")
    lv2.alpha_composite(_silhouette(alpha, TINTS[2], 28))
    _grid(d2, alpha, 22, TINTS[2], 170)
    _polyline(d2, _ordered_contour(edges, 5), TINTS[2], 2, 230)
    _dots(d2, _sample(edges, 40, 18, rng), TINTS[2], 1, 200)

    lv3 = _blank()
    d3 = ImageDraw.Draw(lv3, "RGBA")
    lv3.alpha_composite(_silhouette(alpha, TINTS[3], 70))
    _grid(d3, alpha, 12, TINTS[3], 150)
    _polyline(d3, contour[::2], (255, 255, 255), 2, 200)

    lv4 = _blank()
    faint = src.copy()
    faint.putalpha(alpha.point(lambda a: int(a * 0.42) if a >= 40 else 0))
    color_shift = ImageEnhance.Color(faint).enhance(0.55)
    lv4.alpha_composite(color_shift)
    d4 = ImageDraw.Draw(lv4, "RGBA")
    _grid(d4, alpha, 8, TINTS[4], 140)
    _polyline(d4, contour, TINTS[4], 2, 220)

    lv5 = src.copy()
    glow = src.filter(ImageFilter.GaussianBlur(1.2))
    lv5.alpha_composite(glow)
    lv5.alpha_composite(src)
    return [lv0, lv1, lv2, lv3, lv4, lv5]


def pack_sheet(frames: list[Image.Image]) -> Image.Image:
    sheet = Image.new("RGBA", (FRAME * FRAMES, FRAME), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * FRAME, 0), frame)
    return sheet


def build_one(src_path: Path, out_path: Path) -> None:
    src = _load_square(src_path, FRAME)
    sheet = pack_sheet(build_frames(src))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path, "PNG")
    print(f"Wrote {out_path} ({sheet.size[0]}x{sheet.size[1]})")


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    src_dir = root / "ui_icons" / "symbols"
    out_dir = src_dir / "sheets"
    names = [
        "SYM-FAMILY-T",
        "SYM-FAMILY-B",
        "SYM-FAMILY-M",
        "SYM-FAMILY-N",
        "SYM-FAMILY-A",
        "SYM-FAMILY-D",
        "SYM-CORE",
    ]
    html_dir = root.parent.parent / "ui" / "immune-research-network" / "assets" / "symbols" / "sheets"
    for name in names:
        src = src_dir / f"{name}.png"
        if not src.exists():
            raise SystemExit(f"Missing source icon: {src}")
        out = out_dir / f"{name}-scan.png"
        build_one(src, out)
        html_dir.mkdir(parents=True, exist_ok=True)
        html_copy = html_dir / f"{name}-scan.png"
        html_copy.write_bytes(out.read_bytes())
        print(f"Copied {html_copy}")


if __name__ == "__main__":
    main()
