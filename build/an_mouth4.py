"""Height map of the finished lower face, straight off the fix pipeline.

Renders keep showing the same lopsided crescent no matter what the mouth
parameters do, so this prints the actual front-surface depth on an (x, z) grid
before and after the fix. If the crescent is still in the numbers it is
geometry the flatten is missing; if it is gone, the mark is coming from
somewhere else entirely.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bl_fix_t_ops as ops  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
RAMP = " .:-=+*#%@"


def front_depth(P, gt, xs, zs):
    """Nearest front-facing vertex depth (y) on an (x, z) grid, in mm-ish units."""
    N = ops.vertex_normals(P, gt)
    front = N[:, 1] < -0.25
    Q = P[front]
    out = np.full((len(zs), len(xs)), np.nan)
    for i, z in enumerate(zs):
        for j, x in enumerate(xs):
            d = (Q[:, 0] - x) ** 2 + (Q[:, 2] - z) ** 2
            k = np.argsort(d)[:4]
            w = 1.0 / (np.sqrt(d[k]) + 1e-4)
            out[i, j] = (Q[k, 1] * w).sum() / w.sum()
    return out


def show(name, M):
    lo, hi = np.nanmin(M), np.nanmax(M)
    print("%s  y %.4f .. %.4f (span %.4f)  [%s = further forward]"
          % (name, lo, hi, hi - lo, RAMP[-1]))
    for row in M:
        s = "".join(RAMP[min(int((hi - v) / max(hi - lo, 1e-9) * (len(RAMP) - 1)),
                             len(RAMP) - 1)] for v in row)
        print("   " + s)


def main(path):
    d = np.load(path)
    co, tris = d["co"], d["tris"]
    p = dict(ops.PARAMS)
    inv, P0 = ops.weld(co)
    gt = ops.group_tris(tris, inv)

    scale = np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    C = np.array(p["mouth_centre"]) * scale
    xs = np.linspace(C[0] - 0.12, C[0] + 0.12, 49)
    zs = np.linspace(C[2] + 0.06, C[2] - 0.06, 25)

    P1, _ = ops.fix(co, tris, {})
    inv1, W1 = ops.weld(P1)
    gt1 = ops.group_tris(tris, inv1)
    # ops.fix drops the mesh onto z = 0; put it back so the grid lines up
    W1[:, 2] += ops.apply_scale(P0, p)[:, 2].min()

    show("before (scaled only)", front_depth(ops.apply_scale(P0, p), gt, xs, zs))
    show("after  fix          ", front_depth(W1, gt1, xs, zs))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1
         else os.path.join(HERE, "dump", "t_mesh_sub.npz"))
