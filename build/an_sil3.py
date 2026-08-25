"""Shape of the rendered outline, not just its extent.

The previous silhouette check compared one number — overall width over height —
and passed a stubby shape against a flared one. This prints the profile that
number came from: half width against height at 2% steps, where the widest point
sits, how far the hem flares past the body's own widest point above the limbs,
and the bottom edge's height across x, which is what "wavy hem" means.
"""

import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

SRC = {
    "ref": (os.path.join(ROOT, "godot", "immune", "characters", "concepts",
                         "CHAR-BASE-T-3d-alt.png"), "lum"),
    "green": (os.path.join(ROOT, "ui", "immune-research-network", "assets",
                           "characters", "alt", "CHAR-BASE-T-alt.png"), "green"),
    "raw": (os.path.join(HERE, "shots", "t-raw", "t-raw-front.png"), "lum"),
    "fix": (os.path.join(HERE, "shots", "t-fix", "t-fix-front.png"), "lum"),
}


def mask(path, kind):
    im = Image.open(path).convert("RGB")
    a = np.asarray(im, dtype=float)
    if kind == "green":
        m = ~((a[:, :, 1] > a[:, :, 0] + 20) & (a[:, :, 1] > a[:, :, 2] + 20))
    else:
        m = a.mean(axis=2) > 28
    ys, xs = np.nonzero(m)
    return m[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def profile(m, steps=51):
    """Half width and outline centre at each height, normalised on height."""
    h, w = m.shape
    hw, cen = [], []
    for f in np.linspace(0.0, 1.0, steps):
        row = m[min(int(f * (h - 1)), h - 1)]
        idx = np.nonzero(row)[0]
        if len(idx) == 0:
            hw.append(0.0)
            cen.append(0.5)
        else:
            hw.append((idx.max() - idx.min() + 1) / 2.0 / h)
            cen.append((idx.max() + idx.min()) / 2.0 / w)
    return np.array(hw), np.array(cen)


def hem(m, steps=41):
    """Height of the lowest lit pixel across x, normalised on height."""
    h, w = m.shape
    out = []
    for f in np.linspace(0.0, 1.0, steps):
        col = m[:, min(int(f * (w - 1)), w - 1)]
        idx = np.nonzero(col)[0]
        out.append(np.nan if len(idx) == 0 else (h - 1 - idx.max()) / h)
    return np.array(out)


def main():
    data = {}
    for name, (path, kind) in SRC.items():
        m = mask(path, kind)
        hw, cen = profile(m)
        data[name] = dict(m=m, hw=hw, cen=cen, hem=hem(m),
                          wh=m.shape[1] / m.shape[0])

    names = ["ref", "green", "raw", "fix"]
    print("overall width / height: " +
          "  ".join("%s %.3f" % (n, data[n]["wh"]) for n in names))

    print("\nhalf width / height, by height fraction from the top")
    print("  frac   " + "".join("%-8s" % n for n in names))
    for i, f in enumerate(np.linspace(0.0, 1.0, 51)):
        print("  %4.2f   " % f
              + "".join("%-8.3f" % data[n]["hw"][i] for n in names))

    print("\nkey shape numbers")
    for n in names:
        hw = data[n]["hw"]
        fr = np.linspace(0.0, 1.0, 51)
        i = int(np.argmax(hw))
        # 'shoulder' = widest point of the body above the limbs, taken at 45%
        shoulder = hw[:24].max()
        skirt = hw[30:].max()
        print("  %-6s widest %.3f at frac %.2f | body-above-limbs %.3f"
              " | skirt max %.3f | flare %+.1f%%"
              % (n, hw[i], fr[i], shoulder, skirt,
                 100.0 * (skirt / max(shoulder, 1e-6) - 1.0)))

    print("\nbottom edge height across the width (hem waviness)")
    print("  x      " + "".join("%-8s" % n for n in names))
    for i, f in enumerate(np.linspace(0.0, 1.0, 41)):
        print("  %4.2f   " % f
              + "".join("%-8s" % ("  --  " if np.isnan(data[n]["hem"][i])
                                  else "%.3f" % data[n]["hem"][i])
                        for n in names))

    for n in names:
        hm = data[n]["hem"]
        good = ~np.isnan(hm)
        print("  %-6s hem rises %.3f between its lowest and highest point"
              % (n, np.nanmax(hm[good]) - np.nanmin(hm[good])))


if __name__ == "__main__":
    main()
