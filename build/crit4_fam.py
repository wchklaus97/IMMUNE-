"""Per-family colour, readability and plateau check on the eroded core (>2% of
subject height in from the silhouette). Reports the DOMINANT channel's plateau,
not red's, so cool families are judged on their own hue."""
from __future__ import annotations

import colorsys
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
from crit4_own import INK, edt, geometry, load  # noqa: E402

HDR = (f"{'image':<26}{'n':>7}{'R50':>7}{'G50':>7}{'B50':>7}{'hue':>7}"
       f"{'sat':>7}{'lum':>7}{'dom':>5}{'D>=250':>8}{'D>=254':>8}{'dark%':>7}")


def go(paths: list[Path]) -> None:
    print(HDR)
    print("-" * len(HDR))
    for p in paths:
        rgb = load(p)
        m, h, _w, _b = geometry(rgb)
        d = edt(m) / h
        sel = m & (rgb.max(2) > INK) & (d > 0.02)
        if not sel.any():
            print(f"{p.name:<26} no core")
            continue
        px = rgb[sel] / 255.0
        mx, mn = px.max(1), px.min(1)
        sat = (mx - mn) / np.maximum(mx, 1e-6)
        med = np.median(px, axis=0)
        hue = colorsys.rgb_to_hsv(*med)[0] * 360.0
        di = int(np.argmax(med))
        dch = px[:, di] * 255
        lum = 0.2126 * px[:, 0] + 0.7152 * px[:, 1] + 0.0722 * px[:, 2]
        # "dark%" = share of core dimmer than sRGB 0.25 luminance: a readability
        # proxy, since a family that is mostly below this reads as a silhouette.
        print(f"{p.name:<26}{int(sel.sum()):>7}"
              f"{med[0]:>7.3f}{med[1]:>7.3f}{med[2]:>7.3f}{hue:>7.1f}"
              f"{sat.mean():>7.3f}{np.median(lum):>7.3f}{'RGB'[di]:>5}"
              f"{(dch >= 250).mean() * 100:>7.2f}%{(dch >= 254).mean() * 100:>7.2f}%"
              f"{(lum < 0.25).mean() * 100:>6.1f}%")


if __name__ == "__main__":
    go([Path(a) for a in sys.argv[1:]])
