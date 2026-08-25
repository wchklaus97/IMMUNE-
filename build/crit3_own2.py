"""Where the ribbon energy actually sits, and how much texture the body carries.

A whole-ribbon aggregate cannot tell "the silhouette glows all the way round"
from "the lit side has a bright specular edge and the rest is dark", which is the
difference between transmitted light and a shiny opaque surface. So:

    python build/crit3_own2.py zones <img> [img...]   ribbon split by vertical band
    python build/crit3_own2.py halo  <img> [img...]   light OUTSIDE the silhouette
    python build/crit3_own2.py grain <img> [img...]   high-frequency detail on body
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

BG = 30.0
LIT = 60.0
RIBBON = 0.012


def load(p: Path) -> np.ndarray:
    return np.asarray(Image.open(p).convert("RGB"), dtype=np.float32)


def mask_of(rgb):
    return rgb.max(axis=2) > BG


def erode(m, n=1):
    for _ in range(n):
        e = m.copy()
        e[1:, :] &= m[:-1, :]
        e[:-1, :] &= m[1:, :]
        e[:, 1:] &= m[:, :-1]
        e[:, :-1] &= m[:, 1:]
        m = e
    return m


def dilate(m, n=1):
    for _ in range(n):
        d = m.copy()
        d[1:, :] |= m[:-1, :]
        d[:-1, :] |= m[1:, :]
        d[:, 1:] |= m[:, :-1]
        d[:, :-1] |= m[:, 1:]
        m = d
    return m


def depth_map(m, limit):
    d = np.zeros(m.shape, np.int32)
    cur = m.copy()
    for s in range(1, limit + 1):
        cur = erode(cur)
        if not cur.any():
            break
        d[cur] = s
    return d


def lum_of(px):
    v = px / 255.0
    return 0.2126 * v[:, 0] + 0.7152 * v[:, 1] + 0.0722 * v[:, 2]


def zones(paths):
    hdr = f"{'image':<30}{'zone':>12}{'n':>7}{'lum50':>8}{'lum90':>8}{'sat':>7}{'hot%':>7}"
    print(hdr)
    print("-" * len(hdr))
    for p in paths:
        rgb = load(p)
        m = mask_of(rgb)
        ys = np.flatnonzero(m.any(axis=1))
        xs = np.flatnonzero(m.any(axis=0))
        y0, y1 = ys[0], ys[-1]
        x0, x1 = xs[0], xs[-1]
        h = float(y1 - y0 + 1)
        w = float(x1 - x0 + 1)
        d = depth_map(m, int(h * RIBBON) + 2)
        ribbon = (d > 0) & (d <= max(int(h * RIBBON), 1)) & (rgb.max(axis=2) > LIT)
        yy = np.arange(rgb.shape[0])[:, None] * np.ones((1, rgb.shape[1]))
        xx = np.ones((rgb.shape[0], 1)) * np.arange(rgb.shape[1])[None, :]
        fy = (yy - y0) / h
        fx = (xx - x0) / w
        zs = [
            ("all", ribbon),
            ("top 0-25%", ribbon & (fy <= 0.25)),
            ("mid 25-65%", ribbon & (fy > 0.25) & (fy <= 0.65)),
            ("bot 65-100%", ribbon & (fy > 0.65)),
            ("bot 88-100%", ribbon & (fy > 0.88)),
            ("left 0-22%", ribbon & (fx <= 0.22)),
            ("right 78-100%", ribbon & (fx > 0.78)),
        ]
        for name, sel in zs:
            if sel.sum() < 20:
                print(f"{p.name if name=='all' else '':<30}{name:>12}{sel.sum():>7}   (too few)")
                continue
            px = rgb[sel]
            v = px / 255.0
            mx, mn = v.max(axis=1), v.min(axis=1)
            L = lum_of(px)
            print(f"{p.name if name=='all' else '':<30}{name:>12}{sel.sum():>7}"
                  f"{np.percentile(L,50):>8.3f}{np.percentile(L,90):>8.3f}"
                  f"{((mx-mn)/np.maximum(mx,1e-6)).mean():>7.3f}"
                  f"{(L>0.75).mean()*100:>7.2f}")
        print()


def halo(paths):
    """Energy in the background ring 1-4% of subject height outside the silhouette.
    A body that is genuinely emitting spills into the bloom; a shiny opaque one
    barely does."""
    hdr = f"{'image':<30}{'ringPx':>8}{'meanLum':>9}{'p90Lum':>8}{'above8/255%':>12}"
    print(hdr)
    print("-" * len(hdr))
    for p in paths:
        rgb = load(p)
        m = mask_of(rgb)
        ys = np.flatnonzero(m.any(axis=1))
        h = float(ys[-1] - ys[0] + 1)
        r = max(int(h * 0.04), 3)
        ring = dilate(m, r) & ~dilate(m, 1)
        px = rgb[ring]
        L = lum_of(px)
        print(f"{p.name:<30}{px.shape[0]:>8}{L.mean():>9.4f}{np.percentile(L,90):>8.4f}"
              f"{(px.max(axis=1)>8).mean()*100:>12.2f}")


def grain(paths):
    """High-frequency contrast on the body: |I - blur3(I)| over interior pixels.
    Cellular dimples are exactly this. Reported for all interior pixels and for
    the brighter half, since the reference shows them mostly in highlights."""
    hdr = f"{'image':<30}{'subjH':>7}{'grainAll':>10}{'grainBright':>13}{'grain/px@ref':>14}"
    print(hdr)
    print("-" * len(hdr))
    for p in paths:
        rgb = load(p)
        m = mask_of(rgb)
        ys = np.flatnonzero(m.any(axis=1))
        h = float(ys[-1] - ys[0] + 1)
        g = rgb.mean(axis=2)
        k = np.zeros_like(g)
        cnt = np.zeros_like(g)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                s = np.roll(np.roll(g, dy, 0), dx, 1)
                k += s
                cnt += 1
        blur = k / cnt
        hf = np.abs(g - blur)
        inner = erode(m, 6)
        body = inner & (rgb.max(axis=2) > LIT)
        L = g[body]
        bright = L >= np.percentile(L, 50)
        # normalise by scale: detail per unit of subject height is what a viewer sees
        print(f"{p.name:<30}{h:>7.0f}{hf[body].mean():>10.3f}"
              f"{hf[body][bright].mean():>13.3f}{hf[body].mean()*(901.0/h):>14.3f}")


def main(a):
    if not a:
        print(__doc__)
        return 2
    cmd, rest = a[0], [Path(x) for x in a[1:]]
    {"zones": zones, "halo": halo, "grain": grain}[cmd](rest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
