"""What the arm actually is, slice by slice, before and after the fix.

The concept's arm is a tapered tentacle that hangs down and curls into a hook.
Deciding what to do to the mesh's version needs its dimensions: how far out it
reaches at each height, how thick it is front to back, and where it stops.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bl_fix_t_ops as ops  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))


def slices(P, body, label):
    B = P[body]
    z0, z1 = B[:, 2].min(), B[:, 2].max()
    H = z1 - z0
    print("%s  height %.4f" % (label, H))
    print("   s     xmax    thickness(y)   ycentre   verts")
    for f in np.arange(0.02, 0.46, 0.03):
        z = z0 + f * H
        m = body & (np.abs(P[:, 2] - z) < 0.015 * H) & (P[:, 0] > 0.62 * B[:, 0].max())
        if m.sum() < 3:
            print("  %.2f      -" % f)
            continue
        print("  %.2f   %.4f   %.4f        %+.4f    %d"
              % (f, P[m, 0].max() / H, (P[m, 1].max() - P[m, 1].min()) / H,
                 0.5 * (P[m, 1].max() + P[m, 1].min()) / H, m.sum()))


def main():
    d = np.load(os.path.join(HERE, "dump", "t_mesh_sub.npz"))
    co, tris = d["co"], d["tris"]
    inv, W = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    comp = ops.components(len(W), ops.tri_edges(gt))
    ids, counts = np.unique(comp, return_counts=True)
    body = comp == ids[np.argmax(counts)]

    slices(ops.apply_scale(W, dict(ops.PARAMS)), body, "before")
    P, _ = ops.fix(co, tris, {})
    inv2, W2 = ops.weld(P)
    slices(W2, body, "after")


if __name__ == "__main__":
    main()
