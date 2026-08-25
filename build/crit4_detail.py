"""Spatial-detail measurement -- the axis every colour metric used so far is blind to.

Every statistic in build/gel_compare.py and in my own crit4_own.py is a per-pixel
colour distribution: channel medians, percentiles, saturation means, clip
fractions, depth-banded aggregates. All of them are invariant under blurring.
Blur the reference until every dimple and every specular ribbon is gone and not
one of those numbers moves appreciably -- but it stops reading as gel. So they
cannot distinguish "has the reference's colour" from "looks like the reference".

This measures the thing they miss:

  microcontrast  RMS of a high-pass (image minus 3px gaussian) over interior body
                 pixels, divided by local mean luminance. Scale-invariant-ish
                 measure of "how much fine surface texture is there".
  speckle        share of interior pixels that are local maxima standing at least
                 12% above their 9px neighbourhood -- a count of distinct small
                 sharp highlights, which is what "wet" is made of.
  edgeness       mean |grad(lum)| / mean lum over the interior.

Both images are first resampled to a COMMON subject height so a difference in
render resolution cannot masquerade as a difference in surface detail. Measured
only at depth > 2% of subject height so the silhouette and its rim are excluded.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from crit4_own import INK, SUBJ, edt  # noqa: E402

TARGET_H = 700  # common subject height in px


def gauss(a: np.ndarray, sigma: float) -> np.ndarray:
    r = max(int(sigma * 3), 1)
    x = np.arange(-r, r + 1, dtype=np.float64)
    k = np.exp(-(x ** 2) / (2 * sigma * sigma))
    k /= k.sum()
    out = np.apply_along_axis(lambda m: np.convolve(m, k, mode="same"), 0, a)
    return np.apply_along_axis(lambda m: np.convolve(m, k, mode="same"), 1, out)


def prep(path: Path) -> tuple[np.ndarray, np.ndarray]:
    img = Image.open(path).convert("RGB")
    a = np.asarray(img, dtype=np.float32)
    m = a.max(2) > SUBJ
    ys = np.nonzero(m.any(axis=1))[0]
    h = float(ys.max() - ys.min() + 1)
    s = TARGET_H / h
    img = img.resize((max(int(img.width * s), 1), max(int(img.height * s), 1)),
                     Image.LANCZOS)
    a = np.asarray(img, dtype=np.float32) / 255.0
    lum = 0.2126 * a[:, :, 0] + 0.7152 * a[:, :, 1] + 0.0722 * a[:, :, 2]
    m = (a.max(2) * 255 > SUBJ)
    interior = m & (edt(m) > TARGET_H * 0.02) & (a.max(2) * 255 > INK)
    return lum, interior


def report(paths: list[Path]) -> None:
    hdr = (f"{'image':<28}{'n_interior':>11}{'mean_lum':>10}"
           f"{'microcontrast':>15}{'speckle/kpx':>13}{'edgeness':>10}")
    print(hdr)
    print("-" * len(hdr))
    for p in paths:
        lum, sel = prep(p)
        n = int(sel.sum())
        base = gauss(lum.astype(np.float64), 3.0)
        hp = lum - base
        ml = float(lum[sel].mean())
        micro = float(np.sqrt((hp[sel] ** 2).mean())) / ml
        # local maxima 12% above a 4px-blurred neighbourhood
        nb = gauss(lum.astype(np.float64), 4.0)
        peak = (lum > nb * 1.12) & sel
        gy, gx = np.gradient(lum.astype(np.float64))
        edge = float(np.sqrt(gx[sel] ** 2 + gy[sel] ** 2).mean()) / ml
        print(f"{p.name:<28}{n:>11}{ml:>10.3f}"
              f"{micro:>15.4f}{peak.sum() / (n / 1000.0):>13.2f}{edge:>10.4f}")
    print()
    print("Control: the same reference, blurred, to show these metrics see what the")
    print("colour metrics cannot.")


if __name__ == "__main__":
    report([Path(a) for a in sys.argv[1:]])
