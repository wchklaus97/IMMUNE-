"""Mesh sanity check for the fix pass: folded, degenerate and stretched triangles."""

import json

import numpy as np

import bl_fix_t_ops as ops


def check(co, new, tris, C, n, verbose=True):
    def tri_normals(P):
        A, B, Cc = P[tris[:, 0]], P[tris[:, 1]], P[tris[:, 2]]
        m = np.cross(B - A, Cc - A)
        return m, np.linalg.norm(m, axis=1) * 0.5

    n0, a0 = tri_normals(co)
    n1, a1 = tri_normals(new)
    dot = (n0 * n1).sum(1) / np.maximum(
        np.linalg.norm(n0, axis=1) * np.linalg.norm(n1, axis=1), 1e-30)

    cen = new[tris].mean(1)
    rel = cen - C
    h = rel @ n
    r = np.linalg.norm(rel - np.outer(h, n), axis=1)

    # tear metric: how fast the displacement changes across an edge of the
    # outward-facing shell. Anything above ~1 shows up as a fin on the silhouette.
    inv, W = ops.weld(co)
    gt = ops.group_tris(tris, inv)
    edges = ops.tri_edges(gt)
    m = inv.max() + 1
    acc = np.zeros((m, 3))
    cnt = np.zeros(m)
    np.add.at(acc, inv, new)
    np.add.at(cnt, inv, 1)
    Wn = acc / cnt[:, None]
    Ws = W * np.array([ops.PARAMS["scale_xy"], ops.PARAMS["scale_xy"],
                       ops.PARAMS["scale_z"]])
    disp = Wn - Ws
    N = ops.vertex_normals(Ws, gt)
    outer = (N @ n) > 0.0
    el = np.linalg.norm(Ws[edges[:, 0]] - Ws[edges[:, 1]], axis=1)
    grad = np.linalg.norm(disp[edges[:, 0]] - disp[edges[:, 1]], axis=1) / np.maximum(el, 1e-9)
    rel = Ws - C
    hh = rel @ n
    rr = np.linalg.norm(rel - np.outer(hh, n), axis=1)
    face_edge = outer[edges[:, 0]] & outer[edges[:, 1]] & (
        (rr[edges[:, 0]] < 0.16) | (rr[edges[:, 1]] < 0.16))

    out = {
        "tris": int(len(tris)),
        "tear_max_grad_face": round(float(grad[face_edge].max()), 3),
        "tear_edges_over_1": int((grad[face_edge] > 1.0).sum()),
        "min_area_before": float(a0.min()),
        "min_area_after": float(a1.min()),
        "degenerate_after": int((a1 < 1e-9).sum()),
        "flipped": int((dot < 0).sum()),
        "turned_gt72deg": int((dot < 0.3).sum()),
        "flipped_near_pore": int(((dot < 0) & (r < 0.13)).sum()),
        "turned_near_pore": int(((dot < 0.3) & (r < 0.13)).sum()),
        "area_ratio_p999": float(np.percentile(a1 / np.maximum(a0, 1e-12), 99.9)),
    }
    if verbose:
        print(json.dumps(out, indent=1))
    return out


if __name__ == "__main__":
    z = np.load("dump/t_mesh_sub.npz")
    co, tris = z["co"], z["tris"]
    new, log = ops.fix(co, tris)
    print(json.dumps({k: v for k, v in log.items()
                      if k.startswith("pore") or k in ("size", "wh_ratio")}, indent=1))
    check(co, new, tris, np.array(log["pore_centre_scaled"]),
          np.array(log["pore_axis"]))
    np.save("dump/new_co.npy", new)
