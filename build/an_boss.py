"""The forehead boss is its own shell. Before deleting it, find out what the
skull underneath looks like and where the dark pore centre is actually painted.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import an_t  # noqa: E402
import bl_fix_t_ops as ops  # noqa: E402
from an_comp import components  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    d = np.load(os.path.join(HERE, "dump", "t_mesh.npz"))
    co, tris = d["co"], d["tris"]
    uvl, lv = d["uv"], d["loop_vert"]

    p = dict(ops.PARAMS)
    inv, P = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    lab = components(len(P), ops.tri_edges(gt))

    C = np.array(p["pore_centre"])
    near = np.linalg.norm(P - C, axis=1)
    boss = lab[np.argmin(near)]
    print("boss component id %d, size %d" % (boss, (lab == boss).sum()))

    # split-vertex UVs -> luminance, then folded back onto welded groups
    vuv = np.zeros((len(co), 2))
    vuv[lv] = uvl
    L, _ = an_t.tex_lum(vuv)

    gl = np.zeros(len(P))
    cnt = np.zeros(len(P))
    np.add.at(gl, inv, L)
    np.add.at(cnt, inv, 1.0)
    gl /= np.maximum(cnt, 1)

    for name, m in (("boss", lab == boss),
                    ("body near pore", (lab != boss) & (near < 0.10))):
        if not m.any():
            continue
        rr = near[m]
        print("\n%s: %d verts" % (name, m.sum()))
        for lo, hi in ((0, 0.02), (0.02, 0.04), (0.04, 0.06), (0.06, 0.10)):
            k = (rr >= lo) & (rr < hi)
            if k.sum():
                print("   d %.2f-%.2f n=%3d  lum min %.3f p10 %.3f median %.3f"
                      % (lo, hi, k.sum(), gl[m][k].min(),
                         np.percentile(gl[m][k], 10), np.median(gl[m][k])))

    # boundary edges: where are the holes?
    e = np.concatenate([gt[:, [0, 1]], gt[:, [1, 2]], gt[:, [2, 0]]])
    e = np.sort(e, axis=1)
    uq, counts = np.unique(e, axis=0, return_counts=True)
    b = uq[counts == 1]
    if len(b):
        mid = 0.5 * (P[b[:, 0]] + P[b[:, 1]])
        print("\n%d boundary edges; components %s"
              % (len(b), np.unique(lab[b[:, 0]], return_counts=True)))
        print("   bbox %s .. %s" % (mid.min(axis=0).round(3).tolist(),
                                    mid.max(axis=0).round(3).tolist()))
        print("   how many within 0.12 of the pore: %d"
              % (np.linalg.norm(mid - C, axis=1) < 0.12).sum())


if __name__ == "__main__":
    main()
