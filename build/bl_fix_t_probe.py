"""Probe CHAR-BASE-T geometry so the fix pass can be aimed numerically.

blender-launcher.exe --background --factory-startup --python bl_fix_t_probe.py -- \
    --glb <path> --out <json>

Writes a JSON describing bounds, the dark texture clusters (eyes + pore hole),
and the radial protrusion of the forehead boss. Blender detaches, so nothing
here is printed for consumption; read the JSON instead.
"""

import argparse
import json
import math
import os
import sys

import bpy
import numpy as np


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--glb", required=True)
    ap.add_argument("--out", required=True)
    return ap.parse_args(argv)


def load(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    return meshes[0]


def vert_arrays(obj):
    me = obj.data
    n = len(me.vertices)
    co = np.empty(n * 3, dtype=np.float64)
    me.vertices.foreach_get("co", co)
    co = co.reshape(n, 3)
    mw = np.array(obj.matrix_world)
    world = co @ mw[:3, :3].T + mw[:3, 3]
    return world


def vert_uvs(obj):
    """Average the loop UVs landing on each vertex."""
    me = obj.data
    uvl = me.uv_layers.active
    nl = len(me.loops)
    uv = np.empty(nl * 2, dtype=np.float64)
    uvl.data.foreach_get("uv", uv)
    uv = uv.reshape(nl, 2)
    vidx = np.empty(nl, dtype=np.int32)
    me.loops.foreach_get("vertex_index", vidx)
    n = len(me.vertices)
    acc = np.zeros((n, 2), dtype=np.float64)
    cnt = np.zeros(n, dtype=np.float64)
    np.add.at(acc, vidx, uv)
    np.add.at(cnt, vidx, 1.0)
    cnt[cnt == 0] = 1.0
    return acc / cnt[:, None]


def sample_texture(obj, uvs, size=512):
    mat = obj.material_slots[0].material
    img = None
    for node in mat.node_tree.nodes:
        if node.type == "TEX_IMAGE" and node.image is not None:
            img = node.image
            break
    if img is None:
        return None, None
    copy = img.copy()
    orig_size = tuple(img.size)
    copy.scale(size, size)
    px = np.empty(size * size * copy.channels, dtype=np.float32)
    copy.pixels.foreach_get(px)
    px = px.reshape(size, size, copy.channels)
    u = np.clip((uvs[:, 0] % 1.0) * (size - 1), 0, size - 1).astype(np.int32)
    v = np.clip((uvs[:, 1] % 1.0) * (size - 1), 0, size - 1).astype(np.int32)
    cols = px[v, u, :3]
    bpy.data.images.remove(copy)
    return cols, {"name": img.name, "size": list(orig_size)}


def edges_of(obj):
    me = obj.data
    ne = len(me.edges)
    ev = np.empty(ne * 2, dtype=np.int32)
    me.edges.foreach_get("vertices", ev)
    return ev.reshape(ne, 2)


def clusters(mask, edges, nverts):
    """Connected components restricted to masked vertices."""
    adj = [[] for _ in range(nverts)]
    for a, b in edges:
        if mask[a] and mask[b]:
            adj[a].append(b)
            adj[b].append(a)
    seen = np.zeros(nverts, dtype=bool)
    out = []
    for i in range(nverts):
        if not mask[i] or seen[i]:
            continue
        stack = [i]
        seen[i] = True
        comp = []
        while stack:
            v = stack.pop()
            comp.append(v)
            for w in adj[v]:
                if not seen[w]:
                    seen[w] = True
                    stack.append(w)
        out.append(comp)
    out.sort(key=len, reverse=True)
    return out


def main():
    args = parse_args()
    obj = load(args.glb)
    me = obj.data
    P = vert_arrays(obj)
    uvs = vert_uvs(obj)
    cols, imginfo = sample_texture(obj, uvs)
    edges = edges_of(obj)
    n = len(P)

    lum = cols @ np.array([0.2126, 0.7152, 0.0722]) if cols is not None else None

    rep = {
        "verts": n,
        "tris": len(me.loop_triangles) if me.loop_triangles else None,
        "bounds_min": P.min(axis=0).round(5).tolist(),
        "bounds_max": P.max(axis=0).round(5).tolist(),
        "size": (P.max(axis=0) - P.min(axis=0)).round(5).tolist(),
        "image": imginfo,
    }
    me.calc_loop_triangles()
    rep["tris"] = len(me.loop_triangles)

    if lum is not None:
        rep["lum_percentiles"] = {
            str(p): float(np.percentile(lum, p)) for p in (1, 2, 5, 10, 25, 50, 90)
        }
        thr = 0.10
        mask = lum < thr
        rep["dark_count"] = int(mask.sum())
        comps = clusters(mask, edges, n)
        rep["dark_clusters"] = []
        for comp in comps[:8]:
            pts = P[comp]
            rep["dark_clusters"].append({
                "count": len(comp),
                "centroid": pts.mean(axis=0).round(5).tolist(),
                "min": pts.min(axis=0).round(5).tolist(),
                "max": pts.max(axis=0).round(5).tolist(),
            })

    # Forehead boss: fit a sphere to upper-front verts, look at radial residual.
    cz = P[:, 2]
    front = P[:, 1] < 0.0
    upper = cz > 0.55 * P[:, 2].max()
    sel = front & upper
    Q = P[sel]
    A = np.concatenate([2 * Q, np.ones((len(Q), 1))], axis=1)
    b = (Q ** 2).sum(axis=1)
    sol, *_ = np.linalg.lstsq(A, b, rcond=None)
    centre = sol[:3]
    radius = math.sqrt(sol[3] + (centre ** 2).sum())
    rad = np.linalg.norm(P - centre, axis=1)
    resid = rad - radius
    rep["head_sphere"] = {"centre": centre.round(5).tolist(), "radius": round(radius, 5)}

    # protruding verts on the front upper face
    cand = sel & (resid > 0.004)
    idx = np.argsort(-resid)
    top = [i for i in idx if cand[i]][:40]
    rep["protruding_top"] = [
        {"i": int(i), "p": P[i].round(5).tolist(), "resid": round(float(resid[i]), 5)}
        for i in top
    ]
    if top:
        pts = P[top]
        rep["protrusion_centroid"] = pts.mean(axis=0).round(5).tolist()

    # front-face profile slices: z vs min-y along the centre line
    strip = np.abs(P[:, 0]) < 0.03
    order = np.argsort(P[strip][:, 2])
    prof = P[strip][order]
    rep["centre_profile"] = [[round(float(p[2]), 4), round(float(p[1]), 4)] for p in prof]

    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(rep, fh, indent=2)
    print("PROBE DONE %s" % args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
