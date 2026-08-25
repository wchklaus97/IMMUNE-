"""Blue-floor isolation. The one number that separates the render from the
reference in my zone profile is blue in the deep core: reference 0.004, render
0.082. This asks, for every image given, what blue actually does at depth --
p10/p50/p90 so a floor is distinguishable from a highlight tail -- plus the
saturation that floor costs.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from crit4_own import SUBJ, INK, edt, geometry, load  # noqa: E402


def row(path: Path) -> None:
    rgb = load(path)
    mask, h, _w, _b = geometry(rgb)
    d = edt(mask) / h
    out = [f"{path.name:<24}"]
    for lo, hi, lab in ((0.045, 0.07, "s"), (0.08, 1.01, "deep")):
        sel = mask & (rgb.max(2) > INK) & (d > lo) & (d <= hi)
        if not sel.any():
            out.append(f"{lab}: none")
            continue
        px = rgb[sel] / 255.0
        b = px[:, 2]
        mx, mn = px.max(1), px.min(1)
        sat = (mx - mn) / np.maximum(mx, 1e-6)
        out.append(
            f"| {lab} n={int(sel.sum()):>6} "
            f"B10={np.percentile(b,10):.3f} B50={np.median(b):.3f} "
            f"B90={np.percentile(b,90):.3f} "
            f"R50={np.median(px[:,0]):.3f} G50={np.median(px[:,1]):.3f} "
            f"sat50={np.median(sat):.3f} "
            f"B<0.02={((b<0.02).mean()*100):5.1f}%")
    print(" ".join(out))


if __name__ == "__main__":
    print(f"{'image':<24} zones: s=shell 4.5-7%h, deep=>8%h")
    for p in sys.argv[1:]:
        row(Path(p))
