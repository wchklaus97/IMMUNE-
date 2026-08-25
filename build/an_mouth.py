"""Is the frown painted into the basecolor, or is it only geometry?

If the dark mark is in the texture then its width and shape are fixed and no
amount of carving will widen it; the groove can only be lined up with it.
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

    vuv = np.zeros((len(co), 2))
    vuv[lv] = uvl
    L, _ = an_t.tex_lum(vuv)
    gl = np.zeros(len(P))
    cnt = np.zeros(len(P))
    np.add.at(gl, inv, L)
    np.add.at(cnt, inv, 1.0)
    gl /= np.maximum(cnt, 1)

    C = np.array(p["mouth_centre"])
    near = (np.linalg.norm(P - C, axis=1) < 0.14) & (P[:, 1] < C[1] + 0.05)
    dark = near & (gl < 0.30)
    print("verts within 0.14 of the mouth: %d, painted dark: %d" % (near.sum(), dark.sum()))
    if dark.sum():
        lo, hi = P[dark].min(axis=0), P[dark].max(axis=0)
        print("  painted mark bbox %s .. %s  (x span %.4f, z span %.4f)"
              % (lo.round(4).tolist(), hi.round(4).tolist(), hi[0] - lo[0], hi[2] - lo[2]))
        print("  centre %s" % P[dark].mean(axis=0).round(4).tolist())
    for lo, hi in ((0.0, 0.10), (0.10, 0.25), (0.25, 0.45), (0.45, 1.01)):
        m = near & (gl >= lo) & (gl < hi)
        print("  lum %.2f-%.2f: %d verts" % (lo, hi, m.sum()))

    # same question for the eyes, as a control
    for name, cc in (("eye +x", np.array([0.16, -0.30, 0.52])),
                     ("eye -x", np.array([-0.16, -0.30, 0.52]))):
        m = np.linalg.norm(P - cc, axis=1) < 0.10
        print("  %s: %d verts, %d painted dark" % (name, m.sum(), (m & (gl < 0.30)).sum()))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "dump", "t_mesh.npz"))
