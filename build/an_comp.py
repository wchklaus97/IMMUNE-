"""Is the buried forehead geometry a separate shell, or folded into the skin?

If it is separate, it can simply be deleted and the carve gets a clean single
surface to work on. If it is connected, it has to be carried along instead.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bl_fix_t_ops as ops  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))


def components(n, edges):
    parent = np.arange(n)

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for a, b in edges:
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb
    return np.array([find(i) for i in range(n)])


def main(path):
    d = np.load(path)
    co, tris = d["co"], d["tris"]
    p = dict(ops.PARAMS)
    inv, P = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    edges = ops.tri_edges(gt)

    lab = components(len(P), edges)
    uniq, cnt = np.unique(lab, return_counts=True)
    order = np.argsort(-cnt)
    print("connected components: %d" % len(uniq))
    for i in order[:8]:
        print("   size %5d" % cnt[i])

    # boundary edges = seams / holes in the surface
    e = np.concatenate([gt[:, [0, 1]], gt[:, [1, 2]], gt[:, [2, 0]]])
    e = np.sort(e, axis=1)
    _, counts = np.unique(e, axis=0, return_counts=True)
    print("edges used once (boundary): %d, twice: %d, 3+: %d"
          % ((counts == 1).sum(), (counts == 2).sum(), (counts > 2).sum()))

    C = np.array(p["pore_centre"]) * np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    P2 = ops.apply_scale(P, p)
    NS = ops.vertex_normals(P2, gt)
    near0 = np.linalg.norm(P2 - C, axis=1) < p["pore_blend_r"]
    n = NS[near0].mean(axis=0)
    n[0] = 0.0
    n /= np.linalg.norm(n)
    t1 = np.cross(n, np.array([0.0, 0.0, 1.0]))
    t1 /= np.linalg.norm(t1)
    t2 = np.cross(n, t1)
    rel = P2 - C
    h, u, v = rel @ n, rel @ t1, rel @ t2
    r = np.hypot(u, v)
    sample = ops.outer_height_field(P2, gt, C, n, t1, t2, half=p["pore_blend_r"] * 1.35)
    under = sample(u, v) - h

    near = (r < 0.09) & (h > -0.06)
    print("\nper component, verts near the pore (r<0.09, h>-0.06):")
    for c in np.unique(lab):
        m = lab == c
        k = m & near
        lo, hi = P2[m].min(axis=0), P2[m].max(axis=0)
        print("  comp %5d  size %5d  bbox %s..%s  near %4d"
              % (c, m.sum(), lo.round(2).tolist(), hi.round(2).tolist(), k.sum()))
        if k.sum():
            print("        under: p10 %+.4f p50 %+.4f p90 %+.4f max %+.4f"
                  % tuple(np.percentile(under[k], [10, 50, 90]).tolist()
                          + [under[k].max()]))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "dump", "t_mesh_sub.npz"))
