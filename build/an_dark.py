"""How wide is the dark pore centre actually painted in the basecolor?

The geometric hole must not open wider than the paint, or the funnel walls come
out orange instead of black.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import an_t  # noqa: E402
import bl_fix_t_ops as ops  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))


def main(path):
    d = np.load(path)
    co, tris, uvl, lv = d["co"], d["tris"], d["uv"], d["loop_vert"]
    p = dict(ops.PARAMS)
    inv, P = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    comp = ops.components(len(P), ops.tri_edges(gt))
    P = ops.apply_scale(P, p)
    scale = np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    lens = comp == comp[np.argmin(
        np.linalg.norm(P - np.array(p["pore_centre"]) * scale, axis=1))]

    C, n, t1, t2, coef, _ = ops.pore_frame(P, gt, lens, p)
    rel = P - C
    r = np.hypot(rel @ t1, rel @ t2)

    vuv = np.zeros((len(co), 2))
    vuv[lv] = uvl
    L, _ = an_t.tex_lum(vuv)
    gl = np.zeros(len(P))
    cnt = np.zeros(len(P))
    np.add.at(gl, inv, L)
    np.add.at(cnt, inv, 1.0)
    gl /= np.maximum(cnt, 1)

    print("painted luminance vs pore radius (lens shell only):")
    for k in range(12):
        lo, hi = k * 0.004, (k + 1) * 0.004
        m = lens & (r >= lo) & (r < hi) & ((rel @ n) > -0.04)
        if m.sum():
            print("   r %.3f-%.3f n=%3d  lum min %.3f p25 %.3f median %.3f max %.3f"
                  % (lo, hi, m.sum(), gl[m].min(), np.percentile(gl[m], 25),
                     np.median(gl[m]), gl[m].max()))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "dump", "t_mesh_sub.npz"))
