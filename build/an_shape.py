"""Shape descriptors for a silhouette, chosen to fail when a row-width profile passes.

Row half-width cannot tell a flared, hooked, lobed outline from a stubby one of
the same extent — that is exactly how the last silhouette check passed a shape
two critics then called wrong. These measure the things that differ:

  concavity   how much of the convex hull the outline does not fill. Hooks,
              notches between limbs and a scalloped hem all eat into it; a
              tall egg with nubs barely dents it.
  runs        rows where the outline breaks into more than one span, i.e. rows
              where you can see background between a limb and the body.
  hem lobes   local minima of the bottom edge, and how deep they are.
  waist       the width just above the limbs against the width at the hem, so
              "the skirt flares past the body" becomes a number.
"""

import os
import sys

import numpy as np
from PIL import Image


def load(path, kind="lum"):
    a = np.asarray(Image.open(path).convert("RGB"), dtype=float)
    if kind == "green":
        m = ~((a[:, :, 1] > a[:, :, 0] + 20) & (a[:, :, 1] > a[:, :, 2] + 20))
    else:
        m = a.mean(axis=2) > 28
    ys, xs = np.nonzero(m)
    return m[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def hull_area(m):
    """Area of the convex hull, via a monotone chain on the row extremes."""
    pts = []
    for y in range(m.shape[0]):
        idx = np.nonzero(m[y])[0]
        if len(idx):
            pts.append((idx.min(), y))
            pts.append((idx.max(), y))
    pts = sorted(set(pts))
    if len(pts) < 3:
        return float(m.sum())

    def half(seq):
        out = []
        for p in seq:
            while len(out) >= 2:
                (ax, ay), (bx, by) = out[-2], out[-1]
                if (bx - ax) * (p[1] - ay) - (by - ay) * (p[0] - ax) <= 0:
                    out.pop()
                else:
                    break
            out.append(p)
        return out

    hull = half(pts)[:-1] + half(pts[::-1])[:-1]
    a = 0.0
    for i in range(len(hull)):
        x0, y0 = hull[i]
        x1, y1 = hull[(i + 1) % len(hull)]
        a += x0 * y1 - x1 * y0
    return abs(a) * 0.5


def runs_per_row(m, min_gap):
    out = []
    for y in range(m.shape[0]):
        row = m[y]
        idx = np.nonzero(row)[0]
        if len(idx) < 2:
            out.append(1 if len(idx) else 0)
            continue
        gaps = np.nonzero(np.diff(idx) > min_gap)[0]
        out.append(len(gaps) + 1)
    return np.array(out)


def bottom_edge(m, steps=181):
    h, w = m.shape
    out = np.full(steps, np.nan)
    for i, f in enumerate(np.linspace(0.0, 1.0, steps)):
        col = m[:, min(int(f * (w - 1)), w - 1)]
        idx = np.nonzero(col)[0]
        if len(idx):
            out[i] = (h - 1 - idx.max()) / h
    return out


def lobes(edge, prom=0.012):
    """Local minima of the bottom edge that clear a minimum prominence."""
    e = edge.copy()
    ok = ~np.isnan(e)
    e[~ok] = np.nanmax(e)
    k = np.ones(7) / 7.0
    e = np.convolve(np.pad(e, 3, mode="edge"), k, mode="valid")
    mins = []
    for i in range(2, len(e) - 2):
        if e[i] <= e[i - 1] and e[i] <= e[i + 1]:
            left = e[:i].max() if i else e[i]
            right = e[i + 1:].max()
            if min(left, right) - e[i] >= prom:
                if not mins or i - mins[-1][0] > 6:
                    mins.append((i, e[i]))
                elif e[i] < mins[-1][1]:
                    mins[-1] = (i, e[i])
    return mins, e


def describe(name, m):
    h, w = m.shape
    area = float(m.sum())
    hull = hull_area(m)
    rr = runs_per_row(m, min_gap=max(int(0.012 * h), 2))
    edge = bottom_edge(m)
    mins, sm = lobes(edge)

    rows = np.array([len(np.nonzero(m[y])[0]) and
                     (np.nonzero(m[y])[0].max() - np.nonzero(m[y])[0].min() + 1)
                     for y in range(h)], dtype=float) / h
    waist = rows[int(0.44 * h):int(0.56 * h)].min()
    hem = rows[int(0.80 * h):int(0.96 * h)].max()

    print("%-8s concavity %5.1f%%  split rows %3d (%4.1f%%)  hem lobes %d"
          "  waist %.3f  hem %.3f  flare %+5.1f%%"
          % (name, 100.0 * (1.0 - area / hull),
             int((rr > 1).sum()), 100.0 * (rr > 1).sum() / h,
             len(mins), waist, hem, 100.0 * (hem / max(waist, 1e-6) - 1.0)))
    prof = " ".join("%.2f" % v for v in sm[::10])
    print("         bottom edge across x: %s" % prof)
    return dict(concavity=1.0 - area / hull, split=(rr > 1).sum() / h,
                lobes=len(mins), waist=waist, hem=hem)


def main(paths):
    for name, path, kind in paths:
        if not os.path.exists(path):
            print("%-8s missing %s" % (name, path))
            continue
        describe(name, load(path, kind))


if __name__ == "__main__":
    HERE = os.path.dirname(os.path.abspath(__file__))
    ROOT = os.path.dirname(HERE)
    args = [
        ("concept", os.path.join(ROOT, "godot", "immune", "characters", "concepts",
                                 "CHAR-BASE-T-3d-alt.png"), "lum"),
        ("green", os.path.join(ROOT, "ui", "immune-research-network", "assets",
                               "characters", "alt", "CHAR-BASE-T-alt.png"), "green"),
    ]
    if len(sys.argv) > 1:
        args += [(os.path.basename(a).split(".")[0], a, "lum") for a in sys.argv[1:]]
    else:
        args += [("raw", os.path.join(HERE, "shots", "t-raw", "t-raw-front.png"), "lum"),
                 ("fix", os.path.join(HERE, "shots", "t-fix", "t-fix-front.png"), "lum"),
                 ("sim-b", os.path.join(HERE, "ref-crops", "sim-before-front.png"), "lum"),
                 ("sim-a", os.path.join(HERE, "ref-crops", "sim-after-front.png"), "lum")]
    main(args)
