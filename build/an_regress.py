"""Re-check the head marks after the silhouette work, on the same mesh.

The silhouette pass runs after every carve, and its field is meant to be zero
everywhere near the face. "Meant to be" is not evidence, so this measures each
mark twice — once on the shipped build and once on a build with the limb and
skirt terms switched off — and prints the difference. Anything that moved is
the silhouette work reaching somewhere it should not.
"""

import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import bl_fix_t_ops as ops  # noqa: E402

OFF = dict(limb_gain=0.0, bell_fill=0.0, hem_flare=0.0, arm_drop=0.0,
           hook_lift=0.0, arm_squeeze=0.0, hem_fill=0.0)


def marks(F, gt, comp, lens, order, p, region=None):
    """Every head-mark number, from one set of welded positions.

    `region` carries the vertex sets the marks are measured over. They have to
    be chosen once and reused across builds: picking them per build by an
    ellipsoid around a fixed point selects different vertices once the geometry
    has moved, and then the comparison measures the selection, not the mark.
    That is how the nose first appeared to have regressed by a factor of three
    when the same vertices had in fact moved by 0.00006.
    """
    out = {}
    keep = region is None
    region = {} if keep else region
    H = np.ptp(F[:, 2])
    scale = np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])

    C, n, t1, t2, coef, _ = ops.pore_frame(F, gt, lens, p)
    rel = F - C
    h, u, v = rel @ n, rel @ t1, rel @ t2
    r = np.hypot(u, v)
    rel_h = h - ops.quad(coef, u, v)
    front = (ops.vertex_normals(F, gt) @ n) > 0.3
    if keep:
        region["core"] = lens & (r < 0.047) & front
    core = region["core"]
    out["pore_boss"] = rel_h[core].max()
    out["pore_boss_pct_h"] = 100 * rel_h[core].max() / H
    out["pore_floor"] = rel_h[core].min()
    body = comp == order[0]
    band = body & (np.abs(F[:, 2] - C[2]) < 0.02)
    out["head_width"] = F[band, 0].max() - F[band, 0].min()
    out["dish_over_head"] = 2 * p["pore_dish_r"] / out["head_width"]

    a, b = comp == order[2], comp == order[3]
    A, B = F[a], F[b] * np.array([-1.0, 1.0, 1.0])
    d = np.linalg.norm(A[:, None, :] - B[None, :, :], axis=2)
    out["eye_mirror_max"] = max(d.min(axis=1).max(), d.min(axis=0).max())
    out["eye_mirror_mean"] = 0.5 * (d.min(axis=1).mean() + d.min(axis=0).mean())
    out["eye_dx_sum"] = F[a].mean(0)[0] + F[b].mean(0)[0]

    base = ops.taubin(F, ops.tri_edges(gt), p["taubin_iters"])
    N = ops.vertex_normals(F, gt)
    bump = ((F - base) * N).sum(1)
    if keep:
        region["nose"] = ops.ellipsoid_weight(
            F, np.array(p["nose_centre"]) * scale, p["nose_radii"]) > 0.3
        region["mouth"] = ops.ellipsoid_weight(
            F, np.array(p["mouth_centre"]) * scale, p["mouth_pinch_radii"]) > 0.3
    out["nose_bump"] = bump[region["nose"]].max()

    mw = region["mouth"]
    out["mouth_open"] = np.ptp(F[mw, 2])
    out["mouth_open_pct_h"] = 100 * np.ptp(F[mw, 2]) / H
    return out, region


def dark_check(inv, uvl, lv, comp, order):
    """Do the dark texels still land on the pore, the eyes and nothing else?"""
    from PIL import Image
    tex = None
    for root, _, files in os.walk(os.path.join(ROOT, "godot")):
        for f in files:
            if f.endswith("remesh_basecolor.jpg"):
                tex = os.path.join(root, f)
                break
        if tex:
            break
    if tex is None:
        print("  basecolor not found on disk, dark check skipped")
        return
    img = np.asarray(Image.open(tex).convert("RGB"), dtype=float)
    h, w = img.shape[:2]
    px = np.clip((uvl[:, 0] * (w - 1)).astype(int), 0, w - 1)
    py = np.clip(((1.0 - uvl[:, 1]) * (h - 1)).astype(int), 0, h - 1)
    dark = img[py, px].mean(axis=1) < 60
    vd = np.zeros(inv.max() + 1, dtype=bool)
    vd[inv[lv[dark]]] = True
    print("  basecolor %s at %dx%d" % (os.path.basename(tex), w, h))
    for name, cid in zip(["body", "pore lens", "eye A", "eye B"], order[:4]):
        m = comp == cid
        print("    %-9s dark verts %4d / %4d  (%4.1f%%)"
              % (name, int((vd & m).sum()), int(m.sum()),
                 100.0 * (vd & m).sum() / m.sum()))


def main():
    d = np.load(os.path.join(HERE, "dump", "t_mesh_sub.npz"))
    co, tris, uvl, lv = d["co"], d["tris"], d["uv"], d["loop_vert"]
    p = dict(ops.PARAMS)

    inv, W = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    comp = ops.components(len(W), ops.tri_edges(gt))
    rep = np.unique(inv, return_index=True)[1]
    ids, counts = np.unique(comp, return_counts=True)
    order = ids[np.argsort(-counts)]
    scale = np.array([p["scale_xy"], p["scale_xy"], p["scale_z"]])
    lens = comp == comp[np.argmin(np.linalg.norm(
        ops.apply_scale(W, p) - np.array(p["pore_centre"]) * scale, axis=1))]

    on, log = ops.fix(co, tris, {})
    off = ops.fix(co, tris, OFF)[0]

    head = on[:, 2] > on[:, 2].min() + 0.55 * np.ptp(on[:, 2])
    move = np.linalg.norm(on - off, axis=1)
    print("how far the silhouette pass reaches into the head")
    print("  above 55%% of height: max %.5f   p99 %.5f   verts moved >1e-4: %d"
          % (move[head].max(), np.percentile(move[head], 99),
             int((move[head] > 1e-4).sum())))
    print("  whole mesh:          max %.5f" % move.max())

    a, region = marks(on[rep], gt, comp, lens, order, p)
    b = marks(off[rep], gt, comp, lens, order, p, region)[0]
    c = marks(ops.apply_scale(W, p), gt, comp, lens, order, p, region)[0]
    print("\nhead marks: shipped, the same build with the limb terms off, "
          "and the untouched remesh")
    print("  %-18s %10s %10s %10s %9s" % ("", "shipped", "limbs off",
                                          "remesh", "delta"))
    for k in a:
        print("  %-18s %10.5f %10.5f %10.5f  %+.5f"
              % (k, a[k], b[k], c[k], a[k] - b[k]))

    print("\ndark paint")
    dark_check(inv, uvl, lv, comp, order)

    print("\nmesh quality")
    print("  strain p99 %.3f  max %.3f  edges over 25%%: %d of %d"
          % (log["strain_p99"], log["strain_max"], log["strain_over_25pct"],
             len(ops.tri_edges(gt))))
    print("  one-sided edges %d (32 inherited from the tripo baseline)"
          % log["edges_one_sided"])
    print("  size %s   width/height %.4f" % (log["size"], log["wh_ratio"]))


if __name__ == "__main__":
    main()
