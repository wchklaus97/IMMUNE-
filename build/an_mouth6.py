"""Front-surface depth map of the lower face, rasterised properly.

Nearest-vertex sampling picks up the interior geometry the remesh is full of,
so this walks the front-facing triangles with a z-buffer instead. Run it on the
subdivided dump to see the mouth before the fix, and on the fixed positions to
see what is actually left.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bl_fix_t_ops as ops  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
RAMP = " .:-=+*#%@"


def raster(co, tris, xs, zs):
    inv, P = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    N = ops.vertex_normals(P, gt)
    front = (N[:, 1] < -0.2)[inv]
    gx, gz = np.meshgrid(xs, zs)
    depth = np.full(gx.shape, np.nan)
    keep = front[tris].all(axis=1)
    for t in np.nonzero(keep)[0]:
        a, b, c = co[tris[t, 0]], co[tris[t, 1]], co[tris[t, 2]]
        if (max(a[0], b[0], c[0]) < xs[0] or min(a[0], b[0], c[0]) > xs[-1]
                or max(a[2], b[2], c[2]) < zs[-1] or min(a[2], b[2], c[2]) > zs[0]):
            continue
        d0 = np.array([b[0] - a[0], b[2] - a[2]])
        d1 = np.array([c[0] - a[0], c[2] - a[2]])
        den = d0[0] * d1[1] - d1[0] * d0[1]
        if abs(den) < 1e-12:
            continue
        px, pz = gx - a[0], gz - a[2]
        w1 = (px * d1[1] - d1[0] * pz) / den
        w2 = (d0[0] * pz - px * d0[1]) / den
        w0 = 1.0 - w1 - w2
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        if not inside.any():
            continue
        y = w0 * a[1] + w1 * b[1] + w2 * c[1]
        hit = inside & (np.isnan(depth) | (y < depth))
        depth[hit] = y[hit]
    return depth


def show(name, M, xs):
    lo, hi = np.nanmin(M), np.nanmax(M)
    print("%s  y %.4f .. %.4f  span %.4f   (@ = nearest the camera)"
          % (name, lo, hi, hi - lo))
    for row in M:
        s = ""
        for v in row:
            if np.isnan(v):
                s += " "
            else:
                s += RAMP[min(int((hi - v) / max(hi - lo, 1e-9) * (len(RAMP) - 1)),
                              len(RAMP) - 1)]
        print("  " + s)


def main(path):
    d = np.load(path)
    co, tris = d["co"], d["tris"]
    p = dict(ops.PARAMS)
    scale = np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])

    C0 = np.array(p["mouth_centre"])
    xs0 = np.linspace(C0[0] - 0.09, C0[0] + 0.09, 61)
    zs0 = np.linspace(C0[2] + 0.05, C0[2] - 0.05, 25)
    show("before", raster(co, tris, xs0, zs0), xs0)

    P1, log = ops.fix(co, tris, {})
    inv, W = ops.weld(co)
    P1 = np.asarray(P1)
    zmin = ops.apply_scale(W, p)[:, 2].min()
    P1 = P1.copy()
    P1[:, 2] += zmin
    C1 = C0 * scale
    xs1 = np.linspace(C1[0] - 0.09, C1[0] + 0.09, 61)
    zs1 = np.linspace(C1[2] + 0.05, C1[2] - 0.05, 25)
    show("after ", raster(P1, tris, xs1, zs1), xs1)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1
         else os.path.join(HERE, "dump", "t_mesh_sub.npz"))
