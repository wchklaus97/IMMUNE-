"""Width of the mesh as a function of height, against the concept silhouette.

A single global squash is the wrong tool: the concept is a bell, and the remesh
differs from it mostly at one height — the side nubs stick out too far — while
the dome and the foot lobes are already close.
"""

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bl_fix_t_ops as ops  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))


def ref_profile(path, bg, thr=0.20, bins=20):
    im = np.asarray(Image.open(path).convert("RGB")).astype(float) / 255.0
    m = np.abs(im - np.array(bg)).sum(-1) > thr
    ys, xs = np.nonzero(m)
    m = m[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    h = m.shape[0]
    out = []
    for k in range(bins):
        rows = m[int(k * h / bins):max(int((k + 1) * h / bins), int(k * h / bins) + 1)]
        out.append(rows.sum(1).max() / m.shape[1])
    return np.array(out)               # width as a fraction of overall width


def mesh_profile(P, bins=20):
    z = P[:, 2] - P[:, 2].min()
    H = z.max()
    out = []
    for k in range(bins):
        m = (z >= k * H / bins) & (z < (k + 1) * H / bins)
        out.append((P[m, 0].max() - P[m, 0].min()) if m.sum() > 3 else 0.0)
    out = np.array(out)
    return out / out.max(), out


def main():
    d = np.load(os.path.join(HERE, "dump", "t_mesh.npz"))
    inv, P = ops.weld(d["co"])
    frac, absw = mesh_profile(P)
    ref = ref_profile(os.path.join(
        os.path.dirname(HERE), "godot", "immune", "characters", "concepts",
        "CHAR-BASE-T-3d-alt.png"), (0, 0, 0))
    refg = ref_profile(os.path.join(
        os.path.dirname(HERE), "ui", "immune-research-network", "assets",
        "characters", "alt", "CHAR-BASE-T-alt.png"), (0.0, 0.8, 0.05), 0.25)

    print("band (top->bottom)   concept  green   mesh    mesh/concept")
    for k in range(20):
        i = 19 - k
        print("  %2d  z %.2f-%.2f     %.3f   %.3f   %.3f    %.2f"
              % (k, i / 20, (i + 1) / 20, ref[k], refg[k], frac[i],
                 frac[i] / max(ref[k], 1e-6)))
    print("\nmesh absolute width by band (bottom->top): %s"
          % np.round(absw, 3).tolist())
    print("bbox %s" % np.round(P.max(axis=0) - P.min(axis=0), 4).tolist())


if __name__ == "__main__":
    main()
