"""Objective read on how close a gel render sits to the reference material.

Compares only the subject pixels (anything meaningfully above the near-black
stage), because the background is identical in both and would dominate any
whole-image statistic.

Usage:
    python build/gel_compare.py <reference.png> <candidate.png> [candidate.png ...]
    python build/gel_compare.py --montage <out.png> <img.png> [img.png ...]
    python build/gel_compare.py --clip <img.png> [img.png ...]
    python build/gel_compare.py --clipmap <out.png> <img.png> [img.png ...]
    python build/gel_compare.py --scan <img.png> <y> [x0] [x1]
    python build/gel_compare.py --zones <reference.png> <img.png> [img.png ...]
    python build/gel_compare.py --ribbon <reference.png> <img.png> [img.png ...]
    python build/gel_compare.py --ink <reference.png> <img.png> [img.png ...]
    python build/gel_compare.py --detail [blur=N] <reference.png> <img.png> [img.png ...]
    python build/gel_compare.py --crop <l,t,r,b> <out.png> <img.png> [img.png ...]

`--zones` is the one to trust for the thick-to-thin gradient. A single band
aggregate can sit on a one-pixel rim and look correct while the volume behind it
is flat, so zones splits the subject into depth bands measured inward from the
silhouette and reports each separately. `--crop` boxes are fractions of the
subject bounding box, not pixels, so the same box frames the same body part in
the reference and in a render at a different scale.
"""

from __future__ import annotations

import colorsys
import sys
from pathlib import Path

import numpy as np
from PIL import Image

SUBJECT_THRESHOLD = 30  # 0-255; above the stage background, below any lit gel
# Anti-aliased silhouette pixels are a fade to black and would dominate the low
# percentiles. They also scale with perimeter, and the reference frames the
# subject much larger than the 1024x576 harness output, so leaving them in makes
# the two images incomparable. Erode them away before measuring tone.
EDGE_ERODE = 4


def _mask(rgb: np.ndarray, erode: int = EDGE_ERODE) -> np.ndarray:
    mask = rgb.max(axis=2) > SUBJECT_THRESHOLD
    for _ in range(erode):
        shrunk = mask.copy()
        shrunk[1:, :] &= mask[:-1, :]
        shrunk[:-1, :] &= mask[1:, :]
        shrunk[:, 1:] &= mask[:, :-1]
        shrunk[:, :-1] &= mask[:, 1:]
        mask = shrunk
    return mask


def _subject_pixels(path: Path) -> np.ndarray:
    rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)
    mask = _mask(rgb)
    if not mask.any():
        raise SystemExit(f"{path}: no subject pixels found")
    # Drop the near-black ink features too: eyes/pore/mouth are meant to be dark
    # in both images, and they carry no information about the gel body's tone.
    px = rgb[mask]
    lit = px.max(axis=1) > 60
    return px[lit] if lit.any() else px


def _hsv_stats(px: np.ndarray) -> dict[str, float]:
    r, g, b = (px[:, i] / 255.0 for i in range(3))
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    # Hue only where there is enough chroma to have a meaningful one.
    chromatic = (mx - mn) > 0.04
    hues = []
    for rr, gg, bb in px[chromatic][::37] / 255.0:
        hues.append(colorsys.rgb_to_hsv(rr, gg, bb)[0])
    hue = float(np.median(hues)) if hues else float("nan")
    return {
        "coverage_px": float(px.shape[0]),
        "hue_deg": hue * 360.0,
        "sat_mean": float(sat.mean()),
        "val_mean": float(mx.mean()),
        "lum_p10": float(np.percentile(lum, 10)),
        "lum_p50": float(np.percentile(lum, 50)),
        "lum_p90": float(np.percentile(lum, 90)),
        "blown_pct": float((mn > 0.92).mean() * 100.0),
    }


# Channel-clip measurement. A clipped channel cannot carry a gradient, so a gel
# whose dominant channel is pinned across a whole limb can only get brighter as it
# thins, never deeper -- which is the opposite of what absorption does. Measured on
# a harder-eroded core so the anti-aliased rim is not what is being counted.
CORE_ERODE = 6
CLIP_LEVEL = 254  # 0-255


def _core_pixels(path: Path) -> np.ndarray:
    rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)
    mask = _mask(rgb, erode=CORE_ERODE)
    if not mask.any():
        raise SystemExit(f"{path}: no core pixels found")
    px = rgb[mask]
    return px[px.max(axis=1) > 60]


def _clip_stats(px: np.ndarray) -> dict[str, float]:
    clipped = px >= CLIP_LEVEL
    dominant = int(np.argmax(px.mean(axis=0)))
    return {
        "core_px": float(px.shape[0]),
        "clip_r": float(clipped[:, 0].mean() * 100.0),
        "clip_g": float(clipped[:, 1].mean() * 100.0),
        "clip_b": float(clipped[:, 2].mean() * 100.0),
        "clip_dom": float(clipped[:, dominant].mean() * 100.0),
        "dom": "RGB"[dominant],
        "clip_any": float(clipped.any(axis=1).mean() * 100.0),
    }


def _clip_report(paths: list[Path]) -> None:
    header = (
        f"{'image':<26}{'core_px':>9}{'dom':>5}"
        f"{'clipR%':>8}{'clipG%':>8}{'clipB%':>8}{'clipDom%':>10}{'clipAny%':>10}"
    )
    print(header)
    print("-" * len(header))
    for path in paths:
        s = _clip_stats(_core_pixels(path))
        print(
            f"{path.name:<26}{s['core_px']:>9.0f}{s['dom']:>5}"
            f"{s['clip_r']:>8.2f}{s['clip_g']:>8.2f}{s['clip_b']:>8.2f}"
            f"{s['clip_dom']:>10.2f}{s['clip_any']:>10.2f}"
        )


def _clipmap(out: Path, paths: list[Path], height: int = 560) -> None:
    """Paint every red-clipped subject pixel cyan, so a flooded band is instantly
    distinguishable from speckles that live inside real highlights."""
    panels = []
    for path in paths:
        rgb = np.asarray(Image.open(path).convert("RGB"))
        subject = _mask(rgb.astype(np.float32), erode=0)
        hit = subject & (rgb[:, :, 0] >= CLIP_LEVEL)
        painted = rgb.copy()
        painted[hit] = (0, 255, 255)
        img = Image.fromarray(painted)
        ys, xs = np.nonzero(subject)
        pad = 12
        crop = img.crop((
            max(int(xs.min()) - pad, 0), max(int(ys.min()) - pad, 0),
            min(int(xs.max()) + pad, img.width), min(int(ys.max()) + pad, img.height),
        ))
        scale = height / crop.height
        panels.append(crop.resize((max(int(crop.width * scale), 1), height), Image.NEAREST))
    sheet = Image.new("RGB", (sum(p.width for p in panels), height), (0, 0, 0))
    x = 0
    for p in panels:
        sheet.paste(p, (x, 0))
        x += p.width
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"CLIPMAP {out} ({' | '.join(p.name for p in paths)})")


def _scan(path: Path, y: int, x0: int | None, x1: int | None) -> None:
    """Dump one horizontal scanline of subject pixels. The question a scanline
    answers that an aggregate cannot: does the dominant channel actually modulate
    across a limb, or is it welded to 1.0 while only the others ramp?"""
    rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)
    row = rgb[y]
    lit = np.nonzero(row.max(axis=1) > SUBJECT_THRESHOLD)[0]
    if lit.size == 0:
        raise SystemExit(f"{path}: row {y} has no subject pixels")
    a = int(lit.min()) if x0 is None else x0
    b = int(lit.max()) if x1 is None else x1
    seg = row[a:b + 1] / 255.0
    pinned = int((seg[:, 0] >= CLIP_LEVEL / 255.0).sum())
    print(f"SCAN {path.name} y={y} x={a}..{b} n={b - a + 1} R_pinned={pinned}")
    print(f"  R {seg[:, 0].min():.3f} -> {seg[:, 0].max():.3f}   "
          f"G {seg[:, 1].min():.3f} -> {seg[:, 1].max():.3f}   "
          f"B {seg[:, 2].min():.3f} -> {seg[:, 2].max():.3f}")
    step = max(1, seg.shape[0] // 24)
    for i in range(0, seg.shape[0], step):
        r, g, bl = seg[i]
        print(f"  x={a + i:>4}  R={r:.3f} G={g:.3f} B={bl:.3f}"
              f"{'  <-- R PINNED' if r >= CLIP_LEVEL / 255.0 else ''}")


# Depth-banded measurement. Whether a thin part reads as "light coming through"
# rather than "the same orange, brighter" is a question about a narrow band just
# inside the silhouette, and about whether that band DESATURATES -- short-path light
# keeps its green and blue and emerges yellow-white, so a real transmission term
# shows up as saturation falling from core to edge. A whole-subject aggregate cannot
# see any of that. Depths are a fraction of subject height so the reference and the
# harness output are comparable despite framing the subject at different sizes.
RIBBON_DEPTH = 0.012
SHELL_DEPTH = 0.05
CORE_DEPTH = 0.12


def _inward_depth(rgb: np.ndarray) -> tuple[np.ndarray, float]:
    """Distance from the silhouette, in fractions of subject height, for every
    subject pixel. Chamfer-style iterative erosion: no SciPy dependency."""
    mask = rgb.max(axis=2) > SUBJECT_THRESHOLD
    ys = np.nonzero(mask.any(axis=1))[0]
    height = float(ys.max() - ys.min() + 1)
    depth = np.zeros(mask.shape, dtype=np.float32)
    cur = mask.copy()
    # Erode until nothing is left, recording the pass each pixel survived to.
    for step in range(1, int(height * (CORE_DEPTH + 0.02)) + 2):
        shrunk = cur.copy()
        shrunk[1:, :] &= cur[:-1, :]
        shrunk[:-1, :] &= cur[1:, :]
        shrunk[:, 1:] &= cur[:, :-1]
        shrunk[:, :-1] &= cur[:, 1:]
        depth[shrunk] = step
        if not shrunk.any():
            break
        cur = shrunk
    return depth / height, height


def _band(rgb: np.ndarray, depth: np.ndarray, lo: float, hi: float) -> np.ndarray:
    sel = (depth > lo) & (depth <= hi) & (rgb.max(axis=2) > 60)
    return rgb[sel] / 255.0


def _band_stats(px: np.ndarray) -> dict[str, float]:
    if px.shape[0] == 0:
        return {k: float("nan") for k in
                ("n", "lum50", "lum90", "sat", "b90", "hot")}
    r, g, b = px[:, 0], px[:, 1], px[:, 2]
    mx = px.max(axis=1)
    mn = px.min(axis=1)
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    return {
        "n": float(px.shape[0]),
        "lum50": float(np.percentile(lum, 50)),
        "lum90": float(np.percentile(lum, 90)),
        "sat": float(sat.mean()),
        "b90": float(np.percentile(b, 90)),
        "hot": float((lum > 0.75).mean() * 100.0),
    }


def _ribbon_report(paths: list[Path]) -> None:
    header = (
        f"{'image':<26}{'band':>8}{'n':>8}{'lum50':>8}{'lum90':>8}"
        f"{'sat':>7}{'blue90':>8}{'hot%':>7}"
    )
    print(header)
    print("-" * len(header))
    for path in paths:
        rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)
        depth, _h = _inward_depth(rgb)
        bands = [
            ("ribbon", 0.0, RIBBON_DEPTH),
            ("shell", 0.0, SHELL_DEPTH),
            ("core", CORE_DEPTH, 1.0),
        ]
        stats = {}
        for name, lo, hi in bands:
            s = _band_stats(_band(rgb, depth, lo, hi))
            stats[name] = s
            print(
                f"{path.name if name == 'ribbon' else '':<26}{name:>8}{s['n']:>8.0f}"
                f"{s['lum50']:>8.3f}{s['lum90']:>8.3f}{s['sat']:>7.3f}"
                f"{s['b90']:>8.3f}{s['hot']:>7.2f}"
            )
        # The spectral test: does saturation actually fall from core to edge?
        drop = stats["core"]["sat"] - stats["ribbon"]["sat"]
        print(f"{'':<26}{'SAT DROP core->ribbon':>40}{drop:>+8.3f}")
        # How much of the subject is genuinely thin at all. If the reference concept
        # has proportionally more shell than the mesh does, then part of any
        # shell-brightness gap is the silhouette's shape, not the material's response,
        # and no amount of shader tuning closes it.
        total = float((rgb.max(axis=2) > SUBJECT_THRESHOLD).sum())
        frac = stats["shell"]["n"] / max(total, 1.0) * 100.0
        print(f"{'':<26}{'SHELL % of subject':>40}{frac:>8.1f}")
    print()


# Depth-zone profile. A single band aggregate hid a real defect: averaged over one
# ribbon the render matched the reference, but the match was a one-to-two-pixel bright
# rim and the deficit opened from 0.8% depth inward -- "a lit volume versus a rim on a
# solid". Reporting per-channel medians at successive depths makes that visible, and it
# is the only view that shows the thing that actually distinguishes gel: WHICH channel
# carries the thickness gradient. In the reference red is nearly flat across the whole
# body while green and blue fall away; a neutral darkener moves all three together.
ZONE_EDGES = [0.0, 0.004, 0.008, 0.016, 0.03, 0.05, 0.08, 0.12, 1.01]
# The reference threads a needle: red sits at 250-253 over most of the body, so it is
# pinned high without ever reaching the 254 clip point. Both thresholds are needed --
# one alone cannot tell "correctly exposed" from "blown".
HOT_R = 250
CLIP_R = 254


def _zones(paths: list[Path]) -> None:
    header = (
        f"{'image':<22}{'depth%':>12}{'n':>7}{'R':>7}{'G':>7}{'B':>7}"
        f"{'lum':>7}{'sat':>7}"
    )
    print(header)
    print("-" * len(header))
    for path in paths:
        rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)
        depth, _h = _inward_depth(rgb)
        for lo, hi in zip(ZONE_EDGES[:-1], ZONE_EDGES[1:]):
            px = _band(rgb, depth, lo, hi)
            label = f"{lo * 100:.1f}-{hi * 100:.1f}" if hi <= 1.0 else f"{lo * 100:.1f}+"
            if px.shape[0] == 0:
                continue
            r, g, b = px[:, 0], px[:, 1], px[:, 2]
            mx, mn = px.max(axis=1), px.min(axis=1)
            lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
            sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
            name = path.name if lo == ZONE_EDGES[0] else ""
            print(
                f"{name:<22}{label:>12}{px.shape[0]:>7}"
                f"{np.median(r):>7.3f}{np.median(g):>7.3f}{np.median(b):>7.3f}"
                f"{np.median(lum):>7.3f}{sat.mean():>7.3f}"
            )
        core = _core_pixels(path)
        hot = (core[:, 0] >= HOT_R).mean() * 100.0
        clip = (core[:, 0] >= CLIP_R).mean() * 100.0
        print(f"{'':<22}{'CORE R>=250':>12}{hot:>7.2f}%   "
              f"R>={CLIP_R}: {clip:.2f}%   (ref 46.72 / 3.02)")
    print()


# --- surface microstructure -------------------------------------------------------
#
# Every metric above this line is a statistic of COLOUR, and colour statistics cannot
# see the difference between "has the reference's tone" and "looks like the reference".
# The round-4 critic proved it with a control worth keeping permanently: blur the
# reference by 4px and every number four rounds of review optimised is unchanged --
# R50 0.973 -> 0.973, hue 22.7 -> 23.1, saturation 0.929 -> 0.926, R>=250 45.30% ->
# 44.86% -- while the blurred reference no longer looks remotely like gel. What
# actually separates gel from vinyl at that point is surface microstructure: dense
# cellular dimpling where each cell catches its own micro-highlight. So these two are
# first-class metrics, measured alongside the colour ones, never instead of them.
#
# Run the control with `--detail <ref> blur=4 <ref>` and confirm the instrument
# collapses on the blurred copy. If it does not, the instrument is not measuring
# detail and no reading from it means anything.

# Both images are resampled to a common subject height first. Detail is a per-pixel
# measure, so the reference framed large and a 1024-wide harness render are not
# comparable until the subject covers the same number of pixels.
DETAIL_HEIGHT = 700
# Radius of the local mean the high-pass is taken against, in common-height pixels.
# Large enough to pass a dimple cell, small enough not to flatten body shading.
DETAIL_RADIUS = 6
# Erode further than the tone metrics: the silhouette is the largest high-frequency
# edge in the frame and would swamp a microcontrast reading taken across it.
DETAIL_ERODE = 10
# A highlight counts as "sharp" at this fractional excess over its local mean, and as
# "small" below this area. The upper area bound is what distinguishes the reference's
# many per-cell speckles from one broad blown specular lobe, which is the entire point.
SPECK_EXCESS = 0.18
SPECK_MAX_AREA = 400


def _box_blur(a: np.ndarray, radius: int) -> np.ndarray:
    """Separable box blur via integral images, so no scipy dependency."""
    pad = radius
    out = a
    for axis in (0, 1):
        padded = np.pad(out, [(pad, pad) if i == axis else (0, 0) for i in range(2)],
                        mode="edge")
        cum = np.cumsum(padded, axis=axis)
        cum = np.concatenate(
            [np.zeros_like(np.take(cum, [0], axis=axis)), cum], axis=axis)
        n = out.shape[axis]
        hi = np.take(cum, np.arange(n) + 2 * radius + 1, axis=axis)
        lo = np.take(cum, np.arange(n), axis=axis)
        out = (hi - lo) / float(2 * radius + 1)
    return out


def _label_small(flags: np.ndarray, max_area: int) -> int:
    """Count 4-connected components of `flags` whose area is at most max_area.
    Union-find over only the flagged pixels; there are few, so this is cheap."""
    ys, xs = np.nonzero(flags)
    if ys.size == 0:
        return 0
    index = {}
    for i, (y, x) in enumerate(zip(ys.tolist(), xs.tolist())):
        index[(y, x)] = i
    parent = list(range(ys.size))

    def find(a: int) -> int:
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for (y, x), i in index.items():
        for neighbour in ((y - 1, x), (y, x - 1)):
            j = index.get(neighbour)
            if j is not None:
                ri, rj = find(i), find(j)
                if ri != rj:
                    parent[ri] = rj
    areas: dict[int, int] = {}
    for i in range(ys.size):
        root = find(i)
        areas[root] = areas.get(root, 0) + 1
    return sum(1 for a in areas.values() if a <= max_area)


def _detail_stats(path: Path, blur: float = 0.0) -> dict[str, float]:
    from PIL import ImageFilter

    img = Image.open(path).convert("RGB")
    arr = np.asarray(img, dtype=np.float32)
    mask = _mask(arr, erode=0)
    if not mask.any():
        raise SystemExit(f"{path}: no subject pixels found")
    ys, xs = np.nonzero(mask)
    img = img.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
    scale = DETAIL_HEIGHT / float(img.height)
    img = img.resize((max(1, round(img.width * scale)), DETAIL_HEIGHT), Image.LANCZOS)
    # Blur AFTER normalising scale, so a requested 4px control blur means 4px of the
    # common frame in every image rather than 4px of whatever that file happened to be.
    if blur > 0.0:
        img = img.filter(ImageFilter.GaussianBlur(blur))

    arr = np.asarray(img, dtype=np.float32)
    lum = 0.2126 * arr[:, :, 0] + 0.7152 * arr[:, :, 1] + 0.0722 * arr[:, :, 2]
    # Interior only, and ink excluded: the eyes are meant to be flat, so counting the
    # hard rim around them as microstructure would reward the wrong thing.
    interior = _mask(arr, erode=DETAIL_ERODE) & (lum > 60.0)
    if interior.sum() < 100:
        raise SystemExit(f"{path}: too little interior to measure detail")

    local = _box_blur(lum, DETAIL_RADIUS)
    excess = (lum - local) / np.maximum(local, 1e-3)
    micro = float(np.sqrt(np.mean(np.square(excess[interior]))))
    speck = _label_small(interior & (excess > SPECK_EXCESS), SPECK_MAX_AREA)
    return {
        "interior_px": float(interior.sum()),
        "micro": micro,
        "speck_per_1k": speck / (interior.sum() / 1000.0),
    }


def _detail_report(paths: list[Path], blur: float = 0.0) -> None:
    header = (f"{'image':<26}{'interior':>10}{'micro':>9}{'speck/1k':>10}"
              f"{'blur':>6}")
    print(header)
    print("-" * len(header))
    for path in paths:
        s = _detail_stats(path, blur)
        print(f"{path.name:<26}{s['interior_px']:>10.0f}{s['micro']:>9.4f}"
              f"{s['speck_per_1k']:>10.2f}{blur:>6.1f}")
    print()


# The eyes, pore centre and mouth line come from the baked basecolor and are meant to
# stay flat dark ink no matter how hot the body runs. Every round that raises body
# exposure risks the subsurface glow bleeding through them, and the body statistics
# deliberately exclude these pixels, so nothing else here can catch that regression.
INK_MAX = 60
# Eroded, because "dark subject pixel" is not the same thing as "ink". The gel body has
# genuinely dark crevices -- under the skirt lobes, where an arm meets the body -- and
# those are thin, so an un-eroded threshold sweeps them in with the eyes. That mattered
# concretely: switching the dimples on moved this statistic's p90 while leaving the eyes
# untouched, because the added specular sparkle landed in those crevices, where sparkle
# is correct. Eroding keeps the eye interiors, which are broad, and drops the creases.
INK_ERODE = 2


def _ink_report(paths: list[Path]) -> None:
    header = f"{'image':<26}{'n':>8}{'R':>7}{'G':>7}{'B':>7}{'lum':>7}{'p90lum':>8}"
    print(header)
    print("-" * len(header))
    for path in paths:
        rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)
        dark = _mask(rgb) & (rgb.max(axis=2) <= INK_MAX)
        for _ in range(INK_ERODE):
            shrunk = dark.copy()
            shrunk[1:, :] &= dark[:-1, :]
            shrunk[:-1, :] &= dark[1:, :]
            shrunk[:, 1:] &= dark[:, :-1]
            shrunk[:, :-1] &= dark[:, 1:]
            dark = shrunk
        ink = rgb[dark]
        if ink.shape[0] == 0:
            print(f"{path.name:<26}{0:>8}   no ink pixels found")
            continue
        ink = ink / 255.0
        lum = 0.2126 * ink[:, 0] + 0.7152 * ink[:, 1] + 0.0722 * ink[:, 2]
        print(
            f"{path.name:<26}{ink.shape[0]:>8}"
            f"{np.median(ink[:, 0]):>7.3f}{np.median(ink[:, 1]):>7.3f}"
            f"{np.median(ink[:, 2]):>7.3f}{np.median(lum):>7.3f}"
            f"{np.percentile(lum, 90):>8.3f}"
        )
    print()


def _report(paths: list[Path]) -> None:
    header = (
        f"{'image':<26}{'hue°':>7}{'sat':>7}{'val':>7}"
        f"{'lum10':>8}{'lum50':>8}{'lum90':>8}{'white%':>8}"
    )
    print(header)
    print("-" * len(header))
    for path in paths:
        s = _hsv_stats(_subject_pixels(path))
        print(
            f"{path.name:<26}{s['hue_deg']:>7.1f}{s['sat_mean']:>7.3f}{s['val_mean']:>7.3f}"
            f"{s['lum_p10']:>8.3f}{s['lum_p50']:>8.3f}{s['lum_p90']:>8.3f}{s['blown_pct']:>8.2f}"
        )


def _montage(out: Path, paths: list[Path], height: int = 560) -> None:
    """Side-by-side strip, each panel cropped to its subject and scaled to a
    common height so silhouettes and tones line up for eyeballing."""
    panels = []
    for path in paths:
        img = Image.open(path).convert("RGB")
        arr = _mask(np.asarray(img, dtype=np.float32), erode=0)
        ys, xs = np.nonzero(arr)
        pad = 12
        box = (
            max(int(xs.min()) - pad, 0),
            max(int(ys.min()) - pad, 0),
            min(int(xs.max()) + pad, img.width),
            min(int(ys.max()) + pad, img.height),
        )
        crop = img.crop(box)
        scale = height / crop.height
        panels.append(crop.resize((max(int(crop.width * scale), 1), height), Image.LANCZOS))
    total = sum(p.width for p in panels)
    sheet = Image.new("RGB", (total, height), (0, 0, 0))
    x = 0
    for p in panels:
        sheet.paste(p, (x, 0))
        x += p.width
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"MONTAGE {out} ({' | '.join(p.name for p in paths)})")


def _crop_pair(out: Path, paths: list[Path], box: tuple[float, float, float, float],
               height: int = 420) -> None:
    """Crop the same region of each subject's own bounding box and montage them.
    Cropping in subject-relative coordinates is what makes a close-up of the reference
    and a close-up of a render comparable when the two frame the character at
    different sizes."""
    tiles = []
    for path in paths:
        img = Image.open(path).convert("RGB")
        rgb = np.asarray(img, dtype=np.float32)
        mask = rgb.max(axis=2) > SUBJECT_THRESHOLD
        ys = np.nonzero(mask.any(axis=1))[0]
        xs = np.nonzero(mask.any(axis=0))[0]
        y0, y1 = int(ys.min()), int(ys.max())
        x0, x1 = int(xs.min()), int(xs.max())
        w, h = x1 - x0, y1 - y0
        cl, ct, cr, cb = box
        tile = img.crop((x0 + int(cl * w), y0 + int(ct * h),
                         x0 + int(cr * w), y0 + int(cb * h)))
        scale = height / max(tile.height, 1)
        tiles.append(tile.resize((max(int(tile.width * scale), 1), height), Image.LANCZOS))
    total = sum(t.width for t in tiles) + 8 * (len(tiles) - 1)
    sheet = Image.new("RGB", (total, height), (0, 0, 0))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0))
        x += t.width + 8
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"CROP {out} ({' | '.join(p.name for p in paths)})")


def main(argv: list[str]) -> int:
    if len(argv) >= 3 and argv[0] == "--montage":
        _montage(Path(argv[1]), [Path(a) for a in argv[2:]])
        return 0
    if len(argv) >= 3 and argv[0] == "--clipmap":
        _clipmap(Path(argv[1]), [Path(a) for a in argv[2:]])
        return 0
    if len(argv) >= 2 and argv[0] == "--clip":
        _clip_report([Path(a) for a in argv[1:]])
        return 0
    if len(argv) >= 4 and argv[0] == "--crop":
        box = tuple(float(v) for v in argv[1].split(","))
        _crop_pair(Path(argv[2]), [Path(a) for a in argv[3:]], box)  # type: ignore[arg-type]
        return 0
    if len(argv) >= 2 and argv[0] == "--zones":
        _zones([Path(a) for a in argv[1:]])
        return 0
    if len(argv) >= 2 and argv[0] == "--detail":
        rest = argv[1:]
        blur = 0.0
        keep = []
        for a in rest:
            if a.startswith("blur="):
                blur = float(a.split("=", 1)[1])
            else:
                keep.append(a)
        _detail_report([Path(a) for a in keep], blur)
        return 0
    if len(argv) >= 2 and argv[0] == "--ink":
        _ink_report([Path(a) for a in argv[1:]])
        return 0
    if len(argv) >= 2 and argv[0] == "--ribbon":
        _ribbon_report([Path(a) for a in argv[1:]])
        return 0
    if len(argv) >= 3 and argv[0] == "--scan":
        _scan(Path(argv[1]), int(argv[2]),
              int(argv[3]) if len(argv) > 3 else None,
              int(argv[4]) if len(argv) > 4 else None)
        return 0
    if len(argv) < 1:
        print(__doc__)
        return 2
    _report([Path(a) for a in argv])
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
