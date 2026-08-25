"""Independent round-4 critic measurement. Written from scratch; shares no code
with build/gel_compare.py or the prior critics' scripts.

Design decisions and why:

* Depth is a true Euclidean distance transform (two-pass chamfer with diagonal
  steps), not 4-connected erosion. 4-connected erosion overestimates depth on
  diagonal boundaries by up to sqrt(2), which biases the outermost zones -- the
  exact zones the verdict turns on.
* Depth is normalised by subject HEIGHT in pixels so the 819px reference and the
  much smaller harness subject are comparable.
* Ink is excluded by a fixed max-channel gate, and the gate level is reported so
  it can be seen how many pixels it removes.
* Every zone reports per-channel p10/p50/p90 AND the fraction of pixels with
  R>=250 and R>=254 IN THAT ZONE, because a whole-core aggregate cannot say
  whether the plateau lives on the shell (correct) or floods the core (wrong).
* Saturation reported as (max-min)/max, mean and p50.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

SUBJ = 30          # max-channel level that separates subject from stage
INK = 60           # max-channel level below which a pixel is a dark baked feature
ZONES = [0.0, 0.005, 0.012, 0.025, 0.045, 0.07, 0.11, 0.16, 1.01]


def load(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)


def edt(mask: np.ndarray) -> np.ndarray:
    """Euclidean-ish distance to the nearest non-subject pixel, chamfer 3x3
    with 1 / sqrt(2) weights. Two sequential passes, standard Borgefors."""
    big = 1e9
    d = np.where(mask, big, 0.0).astype(np.float64)
    h, w = d.shape
    s2 = float(np.sqrt(2.0))
    # forward
    for y in range(1, h):
        row, prev = d[y], d[y - 1]
        row[1:] = np.minimum(row[1:], prev[:-1] + s2)
        row[:] = np.minimum(row, prev + 1.0)
        row[:-1] = np.minimum(row[:-1], prev[1:] + s2)
        for x in range(1, w):
            if row[x] > row[x - 1] + 1.0:
                row[x] = row[x - 1] + 1.0
    # backward
    for y in range(h - 2, -1, -1):
        row, nxt = d[y], d[y + 1]
        row[1:] = np.minimum(row[1:], nxt[:-1] + s2)
        row[:] = np.minimum(row, nxt + 1.0)
        row[:-1] = np.minimum(row[:-1], nxt[1:] + s2)
        for x in range(w - 2, -1, -1):
            if row[x] > row[x + 1] + 1.0:
                row[x] = row[x + 1] + 1.0
    return d


def geometry(rgb: np.ndarray):
    mask = rgb.max(axis=2) > SUBJ
    ys = np.nonzero(mask.any(axis=1))[0]
    xs = np.nonzero(mask.any(axis=0))[0]
    h = float(ys.max() - ys.min() + 1)
    w = float(xs.max() - xs.min() + 1)
    return mask, h, w, (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))


def profile(path: Path) -> None:
    rgb = load(path)
    mask, h, w, box = geometry(rgb)
    depth = edt(mask) / h
    lit = mask & (rgb.max(axis=2) > INK)
    ink_n = int((mask & ~lit).sum())
    print(f"\n=== {path} ")
    print(f"    image {rgb.shape[1]}x{rgb.shape[0]}  subject bbox {box} "
          f"= {int(w)}x{int(h)}px  subject_px={int(mask.sum())}  ink_px={ink_n}")
    print(f"    {'zone(%h)':>11}{'n':>8}"
          f"{'R50':>7}{'G50':>7}{'B50':>7}{'R10':>7}{'R90':>7}"
          f"{'sat50':>8}{'lum50':>7}{'R>=250':>8}{'R>=254':>8}")
    for lo, hi in zip(ZONES[:-1], ZONES[1:]):
        sel = lit & (depth > lo) & (depth <= hi)
        n = int(sel.sum())
        if n == 0:
            continue
        px = rgb[sel] / 255.0
        r, g, b = px[:, 0], px[:, 1], px[:, 2]
        mx, mn = px.max(1), px.min(1)
        sat = (mx - mn) / np.maximum(mx, 1e-6)
        lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        lab = f"{lo*100:.1f}-{hi*100:.1f}" if hi <= 1.0 else f"{lo*100:.1f}+"
        print(f"    {lab:>11}{n:>8}"
              f"{np.median(r):>7.3f}{np.median(g):>7.3f}{np.median(b):>7.3f}"
              f"{np.percentile(r,10):>7.3f}{np.percentile(r,90):>7.3f}"
              f"{np.median(sat):>8.3f}{np.median(lum):>7.3f}"
              f"{(r*255>=250).mean()*100:>7.2f}%{(r*255>=254).mean()*100:>7.2f}%")
    # whole-body and eroded-core rollups
    for name, lo in (("BODY(all lit)", 0.0), ("CORE(>2%h)", 0.02), ("DEEP(>8%h)", 0.08)):
        sel = lit & (depth > lo)
        if not sel.any():
            continue
        px = rgb[sel] / 255.0
        r, g, b = px[:, 0], px[:, 1], px[:, 2]
        mx, mn = px.max(1), px.min(1)
        sat = (mx - mn) / np.maximum(mx, 1e-6)
        print(f"    {name:>14} n={int(sel.sum()):>7}  "
              f"R50={np.median(r):.3f} G50={np.median(g):.3f} B50={np.median(b):.3f} "
              f"sat_mean={sat.mean():.3f}  R>=250={ (r*255>=250).mean()*100:5.2f}%  "
              f"R>=254={(r*255>=254).mean()*100:5.2f}%")


def ink(path: Path) -> None:
    rgb = load(path)
    mask, _h, _w, _b = geometry(rgb)
    # only interior ink, so the anti-aliased outer edge is not counted as ink
    d = edt(mask)
    sel = mask & (d > 3) & (rgb.max(axis=2) <= INK)
    n = int(sel.sum())
    if n == 0:
        print(f"INK {path.name}: none")
        return
    px = rgb[sel] / 255.0
    lum = 0.2126 * px[:, 0] + 0.7152 * px[:, 1] + 0.0722 * px[:, 2]
    print(f"INK {path.name:<28} n={n:>6} "
          f"med=({np.median(px[:,0]):.3f},{np.median(px[:,1]):.3f},{np.median(px[:,2]):.3f}) "
          f"lum50={np.median(lum):.4f} lum90={np.percentile(lum,90):.4f} "
          f"lum99={np.percentile(lum,99):.4f} max={lum.max():.4f}")


def hotmap(out: Path, paths: list[Path], level: int = 250, height: int = 520) -> None:
    """Paint R>=level cyan, R>=254 magenta. Shows WHERE the plateau lives."""
    tiles = []
    for p in paths:
        rgb = load(p)
        mask, _h, _w, box = geometry(rgb)
        img = np.asarray(Image.open(p).convert("RGB")).copy()
        hot = mask & (rgb[:, :, 0] >= level) & (rgb[:, :, 0] < 254)
        clp = mask & (rgb[:, :, 0] >= 254)
        img[hot] = (0, 255, 255)
        img[clp] = (255, 0, 255)
        im = Image.fromarray(img).crop((box[0] - 6, box[1] - 6, box[2] + 6, box[3] + 6))
        s = height / im.height
        tiles.append(im.resize((int(im.width * s), height), Image.NEAREST))
    sheet = Image.new("RGB", (sum(t.width for t in tiles) + 8 * (len(tiles) - 1), height))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0))
        x += t.width + 8
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"HOTMAP {out}")


def satmap(out: Path, paths: list[Path], height: int = 520) -> None:
    """False-colour saturation so the spatial structure of the spectral gradient
    is visible: blue = desaturated (light got through), red = saturated (thick)."""
    tiles = []
    for p in paths:
        rgb = load(p)
        mask, _h, _w, box = geometry(rgb)
        mx, mn = rgb.max(2), rgb.min(2)
        sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
        # map sat 0.35..1.0 -> blue..red
        t = np.clip((sat - 0.35) / 0.65, 0, 1)
        img = np.zeros(rgb.shape, dtype=np.uint8)
        img[:, :, 0] = (t * 255).astype(np.uint8)
        img[:, :, 2] = ((1 - t) * 255).astype(np.uint8)
        img[~mask] = 0
        im = Image.fromarray(img).crop((box[0] - 6, box[1] - 6, box[2] + 6, box[3] + 6))
        s = height / im.height
        tiles.append(im.resize((int(im.width * s), height), Image.NEAREST))
    sheet = Image.new("RGB", (sum(t.width for t in tiles) + 8 * (len(tiles) - 1), height))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0))
        x += t.width + 8
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"SATMAP {out}")


def montage(out: Path, paths: list[Path], height: int = 620) -> None:
    tiles = []
    for p in paths:
        rgb = load(p)
        _m, _h, _w, box = geometry(rgb)
        im = Image.open(p).convert("RGB").crop((box[0] - 8, box[1] - 8, box[2] + 8, box[3] + 8))
        s = height / im.height
        tiles.append(im.resize((int(im.width * s), height), Image.LANCZOS))
    sheet = Image.new("RGB", (sum(t.width for t in tiles) + 8 * (len(tiles) - 1), height))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0))
        x += t.width + 8
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"MONTAGE {out}")


if __name__ == "__main__":
    a = sys.argv[1:]
    if a and a[0] == "--ink":
        for p in a[1:]:
            ink(Path(p))
    elif a and a[0] == "--hotmap":
        hotmap(Path(a[1]), [Path(x) for x in a[2:]])
    elif a and a[0] == "--satmap":
        satmap(Path(a[1]), [Path(x) for x in a[2:]])
    elif a and a[0] == "--montage":
        montage(Path(a[1]), [Path(x) for x in a[2:]])
    else:
        for p in a:
            profile(Path(p))
