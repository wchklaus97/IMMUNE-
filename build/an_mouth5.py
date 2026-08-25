"""What the basecolor actually paints on the lower face.

Per-vertex texture sampling is useless here: the mouth mark is a few pixels of
UV space and the mesh only has a handful of vertices on it. This rasterises the
front-facing triangles into an (x, z) grid, interpolates the UVs
barycentrically the way the renderer does, and prints the painted luminance.
That settles whether the dark mouth is paint or shading, and how big the paint
is in model units.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import an_t  # noqa: E402
import bl_fix_t_ops as ops  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
RAMP = "@%#*+=-:. "


def main(path):
    d = np.load(path)
    co, tris, uvl, lv = d["co"], d["tris"], d["uv"], d["loop_vert"]
    p = dict(ops.PARAMS)

    vuv = np.zeros((len(co), 2))
    vuv[lv] = uvl

    inv, P = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    N = ops.vertex_normals(P, gt)
    front = (N[:, 1] < -0.25)[inv]

    scale = np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    C = np.array(p["mouth_centre"]) * scale / scale  # pre-scale frame, dump is raw
    C = np.array(p["mouth_centre"])

    xs = np.linspace(C[0] - 0.09, C[0] + 0.09, 73)
    zs = np.linspace(C[2] + 0.045, C[2] - 0.045, 37)
    gx, gz = np.meshgrid(xs, zs)
    lum = np.full(gx.shape, np.nan)
    depth = np.full(gx.shape, 1e9)

    A, B, Cc = co[tris[:, 0]], co[tris[:, 1]], co[tris[:, 2]]
    keep = front[tris].all(axis=1)
    for t in np.nonzero(keep)[0]:
        a, b, c = A[t], B[t], Cc[t]
        x0 = min(a[0], b[0], c[0]); x1 = max(a[0], b[0], c[0])
        z0 = min(a[2], b[2], c[2]); z1 = max(a[2], b[2], c[2])
        if x1 < xs[0] or x0 > xs[-1] or z1 < zs[-1] or z0 > zs[0]:
            continue
        d0 = np.array([b[0] - a[0], b[2] - a[2]])
        d1 = np.array([c[0] - a[0], c[2] - a[2]])
        den = d0[0] * d1[1] - d1[0] * d0[1]
        if abs(den) < 1e-12:
            continue
        px = gx - a[0]
        pz = gz - a[2]
        w1 = (px * d1[1] - d1[0] * pz) / den
        w2 = (d0[0] * pz - px * d0[1]) / den
        w0 = 1.0 - w1 - w2
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        if not inside.any():
            continue
        y = w0 * a[1] + w1 * b[1] + w2 * c[1]
        hit = inside & (y < depth)
        if not hit.any():
            continue
        uv = (w0[hit][:, None] * vuv[tris[t, 0]]
              + w1[hit][:, None] * vuv[tris[t, 1]]
              + w2[hit][:, None] * vuv[tris[t, 2]])
        L, _ = an_t.tex_lum(uv)
        depth[hit] = y[hit]
        lum[hit] = L

    ok = ~np.isnan(lum)
    print("grid coverage %d/%d, luminance %.3f .. %.3f"
          % (ok.sum(), lum.size, np.nanmin(lum), np.nanmax(lum)))
    thr = 0.55 * np.nanmedian(lum)
    dark = ok & (lum < thr)
    print("threshold %.3f -> %d dark cells" % (thr, dark.sum()))
    if dark.any():
        di, dj = np.nonzero(dark)
        print("painted mark spans x %.4f..%.4f (%.4f), z %.4f..%.4f (%.4f)"
              % (xs[dj.min()], xs[dj.max()], xs[dj.max()] - xs[dj.min()],
                 zs[di.max()], zs[di.min()], zs[di.min()] - zs[di.max()]))
    lo, hi = np.nanmin(lum), np.nanmax(lum)
    for row in lum:
        s = ""
        for v in row:
            if np.isnan(v):
                s += " "
            else:
                s += RAMP[min(int((v - lo) / max(hi - lo, 1e-9) * len(RAMP)),
                              len(RAMP) - 1)]
        print("  " + s)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1
         else os.path.join(HERE, "dump", "t_mesh_sub.npz"))
