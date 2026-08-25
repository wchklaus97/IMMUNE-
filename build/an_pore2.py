"""Dry-run the carve outside Blender and report the forehead cross-section.

Cheap sanity gate before spending a render: does the lens front actually end up
recessed, does the skull stay behind it, and does anything invert.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bl_fix_t_ops as ops  # noqa: E402
from an_boss2 import frame  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))


def main(path):
    d = np.load(path)
    co, tris = d["co"], d["tris"]
    p = dict(ops.PARAMS)
    inv, P0 = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    comp = ops.components(len(P0), ops.tri_edges(gt))

    # replay the pipeline on the welded arrays so vertex indices stay comparable
    scale = np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    edges = ops.tri_edges(gt)
    P = ops.apply_scale(P0, p)
    lens = comp == comp[np.argmin(
        np.linalg.norm(P - np.array(p["pore_centre"]) * scale, axis=1))]
    P = ops.symmetrize(P, gt, comp, p)
    base = ops.taubin(P, edges, p["taubin_iters"])
    P = ops.flatten_region(P, base, np.array(p["nose_centre"]) * scale,
                           p["nose_radii"], p["nose_strength"])
    P = ops.flatten_region(P, base, np.array(p["mouth_centre"]) * scale,
                           p["mouth_radii"], p["mouth_smooth"])
    P = ops.carve_mouth(P, gt, p)
    log = {}
    P1 = ops.carve_pore(P, gt, lens, p, log)
    for k in sorted(log):
        print("  %-20s %s" % (k, log[k]))

    C, n, t1, t2, coef, _ = ops.pore_frame(P, gt, lens, p)
    rel = P1 - C
    h, u, v = rel @ n, rel @ t1, rel @ t2
    r = np.hypot(u, v)
    relh = h - ops.quad(coef, u, v)

    print("\nafter carve, height above the fitted skull (mm):")
    print("   r-band     lens front            skull")
    for k in range(9):
        lo, hi = k * 0.010, (k + 1) * 0.010
        band = (r >= lo) & (r < hi)
        a = band & lens & (relh > -0.045)
        b = band & (~lens) & (relh > -0.060)
        fmt = lambda m: ("n=%3d %+6.1f..%+6.1f" % (m.sum(), relh[m].min() * 1000,
                                                   relh[m].max() * 1000)
                         ) if m.sum() else "        -        "
        print("   %.3f-%.3f  %s   %s" % (lo, hi, fmt(a), fmt(b)))

    # does the skull cut through the dish anywhere inside the lens footprint?
    R = p["pore_sink_r0"]
    inside = (r < R) & (~lens) & (relh > -0.060)
    lensf = (r < R) & lens & (relh > -0.045)
    if inside.sum() and lensf.sum():
        print("\nskull max %+.4f vs lens-front min %+.4f inside r<%.3f"
              % (relh[inside].max(), relh[lensf].min(), R))

    # triangle health in the neighbourhood
    cen = P1[gt].mean(axis=1)
    near = np.linalg.norm(cen - C, axis=1) < 0.12
    a, b, c = P1[gt[:, 0]], P1[gt[:, 1]], P1[gt[:, 2]]
    ar = 0.5 * np.linalg.norm(np.cross(b - a, c - a), axis=1)
    a0, b0, c0 = P[gt[:, 0]], P[gt[:, 1]], P[gt[:, 2]]
    fn0 = np.cross(b0 - a0, c0 - a0)
    fn1 = np.cross(b - a, c - a)
    dot = (fn0 * fn1).sum(1) / np.maximum(
        np.linalg.norm(fn0, axis=1) * np.linalg.norm(fn1, axis=1), 1e-20)
    print("\nnear tris %d: flipped %d, turned >60deg %d, area<1e-7 %d"
          % (near.sum(), (near & (dot < 0)).sum(),
             (near & (dot < 0.5)).sum(), (near & (ar < 1e-7)).sum()))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "dump", "t_mesh_sub.npz"))
