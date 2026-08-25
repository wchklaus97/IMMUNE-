"""Silhouette of the mesh through bl_shots' own camera, without running Blender.

A full fix plus Cycles render is about two minutes a look, which is too slow to
shape a silhouette by. This reproduces bl_shots' framing exactly — same
normalisation, same 62 mm lens, same target, yaw and pitch — and rasterises the
triangles, so the outline it produces lines up with the render it is standing in
for. An orthographic projection will not do: the feet splay towards the camera
and perspective foreshortens them by a lot.
"""

import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bl_fix_t_ops as ops  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
RES = 768
LENS, SENSOR = 62.0, 36.0
TARGET = np.array([0.0, 0.0, 0.45])
VIEWS = {"front": (0.0, 10.0, 2.9), "side": (90.0, 10.0, 2.9),
         "34": (35.0, 16.0, 2.9), "back": (180.0, 12.0, 2.9)}


def normalise(P):
    lo, hi = P.min(axis=0), P.max(axis=0)
    s = 1.0 / max(hi[2] - lo[2], 1e-9)
    Q = P * s
    Q[:, 0] -= 0.5 * (lo[0] + hi[0]) * s
    Q[:, 1] -= 0.5 * (lo[1] + hi[1]) * s
    Q[:, 2] -= lo[2] * s
    return Q


def project(P, yaw_deg, pitch_deg, dist):
    yaw, pitch = math.radians(yaw_deg), math.radians(pitch_deg)
    loc = TARGET + np.array([dist * math.cos(pitch) * math.sin(yaw),
                             -dist * math.cos(pitch) * math.cos(yaw),
                             dist * math.sin(pitch)])
    f = TARGET - loc
    f /= np.linalg.norm(f)
    cz = -f
    cx = np.cross(np.array([0.0, 0.0, 1.0]), cz)
    cx /= np.linalg.norm(cx)
    cy = np.cross(cz, cx)
    rel = P - loc
    d = np.maximum(-(rel @ cz), 1e-6)
    fp = RES * LENS / SENSOR
    return np.stack([(rel @ cx) / d * fp + RES / 2,
                     RES / 2 - (rel @ cy) / d * fp], axis=1)


def raster(S, tris):
    img = np.zeros((RES, RES), dtype=bool)
    A, B, C = S[tris[:, 0]], S[tris[:, 1]], S[tris[:, 2]]
    lo = np.floor(np.minimum(np.minimum(A, B), C)).astype(int)
    hi = np.ceil(np.maximum(np.maximum(A, B), C)).astype(int)
    for t in range(len(tris)):
        x0, y0 = np.clip(lo[t], 0, RES - 1)
        x1, y1 = np.clip(hi[t], 0, RES - 1)
        gy, gx = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        a, b, c = A[t], B[t], C[t]
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-9:
            img[y0:y1 + 1, x0:x1 + 1] = True
            continue
        w0 = ((b[1] - c[1]) * (gx - c[0]) + (c[0] - b[0]) * (gy - c[1])) / den
        w1 = ((c[1] - a[1]) * (gx - c[0]) + (a[0] - c[0]) * (gy - c[1])) / den
        w2 = 1.0 - w0 - w1
        img[y0:y1 + 1, x0:x1 + 1] |= (w0 >= -0.003) & (w1 >= -0.003) & (w2 >= -0.003)
    return img


def shoot(P, tris, out_dir, tag, views=("front", "side")):
    Q = normalise(P)
    paths = {}
    for v in views:
        img = raster(project(Q, *VIEWS[v]), tris)
        path = os.path.join(out_dir, "sim-%s-%s.png" % (tag, v))
        Image.fromarray((img * 255).astype(np.uint8)).save(path)
        paths[v] = path
    return paths


def main(overrides=None):
    d = np.load(os.path.join(HERE, "dump", "t_mesh_sub.npz"))
    co, tris = d["co"], d["tris"]
    out = os.path.join(HERE, "ref-crops")
    os.makedirs(out, exist_ok=True)

    P, log = ops.fix(co, tris, overrides or {})
    for k in ("body_shell", "limb_verts", "limb_max_push", "limb_hook_verts",
              "size", "wh_ratio"):
        if k in log:
            print("%-16s %s" % (k, log[k]))

    inv, W0 = ops.weld(co)
    before = ops.apply_scale(W0, dict(ops.PARAMS))[inv]
    shoot(before, tris, out, "before")
    now = shoot(P, tris, out, "after", views=("front", "side", "34"))

    print("\nbell check: how wide and how deep the body is at each height")
    print("  s      before w   d     after  w   d")
    for f in np.linspace(0.05, 0.75, 15):
        row = []
        for Q in (before, P):
            z0, z1 = Q[:, 2].min(), Q[:, 2].max()
            zz = z0 + f * (z1 - z0)
            m = np.abs(Q[:, 2] - zz) < 0.012 * (z1 - z0)
            row.append((Q[m, 0].max() - Q[m, 0].min()) / (z1 - z0)
                       if m.any() else np.nan)
            row.append((Q[m, 1].max() - Q[m, 1].min()) / (z1 - z0)
                       if m.any() else np.nan)
        print("  %.2f    %.3f %.3f      %.3f %.3f" % (f, row[0], row[1],
                                                      row[2], row[3]))

    import an_overlay
    an_overlay.main(now["front"], os.path.join(out, "sim-overlay.png"))

    import an_sil3
    ref = an_sil3.profile(an_sil3.mask(an_sil3.SRC["ref"][0], "lum"))[0]
    grn = an_sil3.profile(an_sil3.mask(an_sil3.SRC["green"][0], "green"))[0]
    was = an_sil3.profile(an_sil3.mask(
        os.path.join(out, "sim-before-front.png"), "lum"))[0]
    cur = an_sil3.profile(an_sil3.mask(now["front"], "lum"))[0]
    print("\n frac   s     green    concept  before   after    green/after")
    for i, f in enumerate(np.linspace(0, 1, 51)):
        if i % 2:
            continue
        print("  %4.2f  %4.2f   %.3f    %.3f    %.3f    %.3f    %.3f"
              % (f, 1 - f, grn[i], ref[i], was[i], cur[i],
                 grn[i] / max(cur[i], 1e-6)))
    band = slice(2, 49)
    print("  rms against the green reference: before %.4f  after %.4f"
          % (np.sqrt(((was[band] - grn[band]) ** 2).mean()),
             np.sqrt(((cur[band] - grn[band]) ** 2).mean())))
    print("  overall width/height: green 1.065  after %.3f"
          % (an_sil3.mask(now["front"], "lum").shape[1]
             / an_sil3.mask(now["front"], "lum").shape[0]))
    return log


if __name__ == "__main__":
    main()
