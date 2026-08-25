"""Split the mouth mark into paint and geometry.

The textured render still shows a thick dark crescent after the crease is
flattened to the smoothed skull, so either the basecolor carries the frown or
the flatten is not reaching. This prints, for the mouth band only, the painted
luminance and the surface depth relative to the smoothed skull, before and
after the fix, so the two causes can be told apart.
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
    inv, P0 = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    edges = ops.tri_edges(gt)
    comp = ops.components(len(P0), edges)

    vuv = np.zeros((len(co), 2))
    vuv[lv] = uvl
    L, _ = an_t.tex_lum(vuv)
    gl = np.zeros(len(P0))
    cnt = np.zeros(len(P0))
    np.add.at(gl, inv, L)
    np.add.at(cnt, inv, 1.0)
    gl /= np.maximum(cnt, 1)

    scale = np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    P = ops.apply_scale(P0, p)
    P = ops.symmetrize(P, gt, comp, p)
    base = ops.taubin(P, edges, p["taubin_iters"])
    before = P.copy()
    P = ops.flatten_region(P, base, np.array(p["nose_centre"]) * scale,
                           p["nose_radii"], p["nose_strength"])
    P = ops.flatten_region(P, base, np.array(p["mouth_centre"]) * scale,
                           p["mouth_radii"], p["mouth_smooth"])
    flat = P.copy()
    P = ops.carve_mouth(P, gt, p)

    C = np.array(p["mouth_centre"]) * scale
    N = ops.vertex_normals(base, gt)
    band = (np.abs(P[:, 0] - C[0]) < 0.11) & (np.abs(P[:, 2] - C[2]) < 0.05)
    band &= N[:, 1] < -0.3
    print("mouth band verts: %d" % band.sum())

    # depth measured along the smoothed-skull normal: negative = pressed in
    def depth(Q):
        return np.einsum('ij,ij->i', Q - base, N)

    for name, Q in (("raw   ", before), ("flat  ", flat), ("carved", P)):
        dd = depth(Q)[band]
        print("  %s depth min %+.4f max %+.4f mean %+.4f" %
              (name, dd.min(), dd.max(), dd.mean()))

    print("  painted lum in band: min %.3f p10 %.3f median %.3f" %
          (gl[band].min(), np.percentile(gl[band], 10), np.median(gl[band])))
    dark = band & (gl < 0.30)
    print("  painted dark in band: %d verts" % dark.sum())
    if dark.sum():
        print("   dark x range %.3f..%.3f  z range %.3f..%.3f" %
              (P[dark, 0].min(), P[dark, 0].max(),
               P[dark, 2].min(), P[dark, 2].max()))

    # per-x slice: how deep is the carved groove, and where is its floor
    print("   x      zmin_depth  z_at_min   lum_at_min")
    dd = depth(P)
    for x0 in np.arange(-0.10, 0.101, 0.02):
        s = band & (np.abs(P[:, 0] - x0) < 0.011)
        if s.sum() < 2:
            continue
        i = np.argmin(np.where(s, dd, 1e9))
        print("  %+.3f   %+.4f    %.4f    %.3f" % (x0, dd[i], P[i, 2], gl[i]))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "dump", "t_mesh.npz"))
