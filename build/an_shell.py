"""How much of the forehead neighbourhood is actually buried geometry?

The pore carve treats 'outer shell' and 'buried pocket' differently, and the
switch between the two was a hard threshold. If barely anything is buried the
switch can go away entirely; if plenty is, it has to become continuous.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bl_fix_t_ops as ops  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))


def main(path):
    d = np.load(path)
    co, tris = d["co"], d["tris"]
    p = dict(ops.PARAMS)
    inv, P = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    P = ops.apply_scale(P, p)
    P = ops.symmetrize(P, gt, p)

    C = np.array(p["pore_centre"]) * np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    NS = ops.vertex_normals(P, gt)
    near = np.linalg.norm(P - C, axis=1) < p["pore_blend_r"]
    n = NS[near].mean(axis=0)
    n[0] = 0.0
    n /= np.linalg.norm(n)
    t1 = np.cross(n, np.array([0.0, 0.0, 1.0]))
    t1 /= np.linalg.norm(t1)
    t2 = np.cross(n, t1)

    rel = P - C
    h, u, v = rel @ n, rel @ t1, rel @ t2
    r = np.hypot(u, v)
    sample = ops.outer_height_field(P, gt, C, n, t1, t2, half=p["pore_blend_r"] * 1.35)
    under = sample(u, v) - h

    print("tris %d  welded verts %d" % (len(tris), len(P)))
    for lo, hi in ((0.0, p["pore_dish_r"]), (p["pore_dish_r"], p["pore_blend_r"])):
        m = (r >= lo) & (r < hi) & (h > -0.06)
        un = under[m]
        print("  r %.3f-%.3f  n=%3d   under: p50 %+.4f p90 %+.4f max %+.4f   "
              ">2mm %d  >6mm %d  >20mm %d"
              % (lo, hi, m.sum(), np.median(un), np.percentile(un, 90), un.max(),
                 (un > 0.002).sum(), (un > 0.006).sum(), (un > 0.020).sum()))

    # radial roughness of the current surface relative to a smooth fit
    band = (r < p["pore_blend_r"]) & (under < 0.004)
    print("  shell verts inside blend radius: %d" % band.sum())
    for k in range(8):
        lo, hi = k * 0.016, (k + 1) * 0.016
        m = band & (r >= lo) & (r < hi)
        if m.sum() > 2:
            print("    r %.3f-%.3f  n=%3d  h mean %+.4f  spread %.4f"
                  % (lo, hi, m.sum(), h[m].mean(), h[m].std()))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "dump", "t_mesh_sub.npz"))
