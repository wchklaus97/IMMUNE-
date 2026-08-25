"""Where is the frown crease that the remesh already has?

The baseline render shows a usable wide arc; smoothing it flat and re-cutting a
groove somewhere else gave two marks instead of one. Better to find the crease
and work on it in place.
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
    edges = ops.tri_edges(gt)
    comp = ops.components(len(P), edges)
    body = comp == np.bincount(comp).argmax()
    base = ops.taubin(P, edges, 60)
    N = ops.vertex_normals(base, gt)

    C = np.array(p["mouth_centre"])
    near = body & (np.linalg.norm(P - C, axis=1) < 0.13) & (N[:, 1] < -0.25)
    rel = ((P - base) * N).sum(1)          # + is proud of the smoothed skull

    print("mouth neighbourhood: %d verts, relief %.4f .. %.4f"
          % (near.sum(), rel[near].min(), rel[near].max()))
    print("\nrelief by height band (z), most negative = the crease:")
    for k in range(14):
        lo = 0.36 + k * 0.010
        m = near & (P[:, 2] >= lo) & (P[:, 2] < lo + 0.010)
        if m.sum():
            print("   z %.3f-%.3f n=%3d  relief min %+.4f mean %+.4f   |x|<0.02 min %+.4f"
                  % (lo, lo + 0.010, m.sum(), rel[m].min(), rel[m].mean(),
                     rel[m & (np.abs(P[:, 0]) < 0.02)].min()
                     if (m & (np.abs(P[:, 0]) < 0.02)).any() else float("nan")))

    groove = near & (rel < -0.004)
    if groove.sum():
        print("\ncrease verts (relief < -4mm): %d" % groove.sum())
        print("   x %.3f..%.3f   z %.3f..%.3f   mean z %.4f"
              % (P[groove, 0].min(), P[groove, 0].max(), P[groove, 2].min(),
                 P[groove, 2].max(), P[groove, 2].mean()))
        for lo in (-0.06, -0.04, -0.02, 0.0, 0.02, 0.04):
            m = groove & (P[:, 0] >= lo) & (P[:, 0] < lo + 0.02)
            if m.sum():
                print("   x %+.2f..%+.2f  n=%2d  z %.4f  relief %+.4f"
                      % (lo, lo + 0.02, m.sum(), P[m, 2].mean(), rel[m].mean()))
    ridge = near & (rel > 0.004) & (P[:, 2] > C[2])
    if ridge.sum():
        print("\nridge above the mouth (relief > +4mm): %d verts, z %.3f..%.3f"
              % (ridge.sum(), P[ridge, 2].min(), P[ridge, 2].max()))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "dump", "t_mesh.npz"))
