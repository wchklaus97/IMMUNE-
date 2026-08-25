"""Shape of the detached forehead boss in the pore's own frame.

The boss is a closed shell sitting on top of the skull, so it has a front face
(visible, carries the painted dark centre) and a back face buried in the head.
Sizing the dish means knowing how far the boss reaches and how thick it is.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bl_fix_t_ops as ops  # noqa: E402
from an_comp import components  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))


def frame(P, gt, p):
    C = np.array(p["pore_centre"]) * np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    NS = ops.vertex_normals(P, gt)
    near = np.linalg.norm(P - C, axis=1) < p["pore_blend_r"]
    n = NS[near].mean(axis=0)
    n[0] = 0.0
    n /= np.linalg.norm(n)
    t1 = np.cross(n, np.array([0.0, 0.0, 1.0]))
    t1 /= np.linalg.norm(t1)
    t2 = np.cross(n, t1)
    return C, n, t1, t2, NS


def main(path):
    d = np.load(path)
    co, tris = d["co"], d["tris"]
    p = dict(ops.PARAMS)
    inv, P = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    P = ops.apply_scale(P, p)
    P = ops.symmetrize(P, gt, p)
    lab = components(len(P), ops.tri_edges(gt))

    C, n, t1, t2, N = frame(P, gt, p)
    rel = P - C
    h, u, v = rel @ n, rel @ t1, rel @ t2
    r = np.hypot(u, v)
    boss = lab[np.argmin(np.linalg.norm(P - C, axis=1))]
    b = lab == boss
    front = b & ((N @ n) > 0.0)
    back = b & ((N @ n) <= 0.0)
    body = (~b) & (r < 0.16) & (h > -0.08)

    print("boss comp %d: %d verts (front %d, back %d)"
          % (boss, b.sum(), front.sum(), back.sum()))
    print("boss radial extent: p50 %.4f p90 %.4f max %.4f"
          % (np.percentile(r[b], 50), np.percentile(r[b], 90), r[b].max()))
    print("boss height h: min %+.4f p50 %+.4f max %+.4f"
          % (h[b].min(), np.median(h[b]), h[b].max()))
    print("front h: min %+.4f max %+.4f | back h: min %+.4f max %+.4f"
          % (h[front].min(), h[front].max(), h[back].min(), h[back].max()))

    print("\nboss front, by radius:")
    for k in range(9):
        lo, hi = k * 0.008, (k + 1) * 0.008
        m = front & (r >= lo) & (r < hi)
        if m.sum():
            print("   r %.3f-%.3f n=%3d  h %+.4f .. %+.4f (mean %+.4f)"
                  % (lo, hi, m.sum(), h[m].min(), h[m].max(), h[m].mean()))

    print("\nskull (body) near the pore, by radius:")
    for k in range(10):
        lo, hi = k * 0.016, (k + 1) * 0.016
        m = body & (r >= lo) & (r < hi)
        if m.sum():
            print("   r %.3f-%.3f n=%3d  h %+.4f .. %+.4f (mean %+.4f)"
                  % (lo, hi, m.sum(), h[m].min(), h[m].max(), h[m].mean()))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "dump", "t_mesh_sub.npz"))
