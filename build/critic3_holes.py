"""Decisive hole test: weld coincident verts (undoing glTF UV-seam splits) then
count true boundary edges, and independently shoot a ray grid through the face
counting intersection parity. A closed surface gives even counts on every ray;
any ray with an odd count passes through an open hole.

blender-launcher.exe --background --factory-startup --python critic3_holes.py -- \
    --glb <path> --out <json>
"""

import argparse
import json
import os
import sys
from collections import defaultdict

import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--glb", required=True)
    ap.add_argument("--out", required=True)
    return ap.parse_args(argv)


def boundary_loops(bm, H, lo_z):
    boundary = [e for e in bm.edges if len(e.link_faces) == 1]
    adj = defaultdict(set)
    for e in boundary:
        a, b = e.verts
        adj[a.index].add(b.index)
        adj[b.index].add(a.index)
    bm.verts.ensure_lookup_table()
    seen = set()
    loops = []
    for start in adj:
        if start in seen:
            continue
        stack = [start]
        seen.add(start)
        comp = []
        while stack:
            cur = stack.pop()
            comp.append(cur)
            for nb in adj[cur]:
                if nb not in seen:
                    seen.add(nb)
                    stack.append(nb)
        pts = [bm.verts[i].co.copy() for i in comp]
        cen = sum(pts, Vector()) / len(pts)
        rad = max((p - cen).length for p in pts)
        loops.append({
            "verts": len(comp),
            "centre": [round(c, 4) for c in cen],
            "z_norm": round((cen.z - lo_z) / H, 4),
            "radius": round(rad, 4),
        })
    loops.sort(key=lambda d: -d["verts"])
    return len(boundary), loops


def main():
    args = parse_args()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args.glb)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]

    out = {"glb": os.path.basename(args.glb)}

    # single combined bmesh in world space
    bm = bmesh.new()
    for obj in meshes:
        tmp = bmesh.new()
        tmp.from_mesh(obj.data)
        tmp.transform(obj.matrix_world)
        me2 = bpy.data.meshes.new("tmp")
        tmp.to_mesh(me2)
        tmp.free()
        bm.from_mesh(me2)
        bpy.data.meshes.remove(me2)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.verts.ensure_lookup_table()
    bm.edges.ensure_lookup_table()

    zs = [v.co.z for v in bm.verts]
    lo_z, hi_z = min(zs), max(zs)
    H = hi_z - lo_z
    out["height"] = round(H, 4)

    nb, loops = boundary_loops(bm, H, lo_z)
    out["pre_weld"] = {"boundary_edges": nb, "loops": len(loops),
                       "biggest_loops": loops[:6]}

    results = {}
    for thr_rel in (1e-6, 1e-5, 1e-4, 1e-3):
        work = bm.copy()
        bmesh.ops.remove_doubles(work, verts=work.verts[:], dist=thr_rel * H)
        nb2, loops2 = boundary_loops(work, H, lo_z)
        nonman = len([e for e in work.edges if len(e.link_faces) > 2])
        results["weld_%g" % thr_rel] = {
            "dist": round(thr_rel * H, 8),
            "verts": len(work.verts),
            "faces": len(work.faces),
            "boundary_edges": nb2,
            "boundary_loops": len(loops2),
            "nonmanifold_edges": nonman,
            "biggest_loops": loops2[:8],
        }
        work.free()
    out["weld_tests"] = results

    # ---- ray parity grid over the whole front of the model ----
    verts = [v.co.copy() for v in bm.verts]
    faces = [[v.index for v in f.verts] for f in bm.faces]
    bvh = BVHTree.FromPolygons(verts, faces, all_triangles=True, epsilon=0.0)

    xs = [v.x for v in verts]
    ys = [v.y for v in verts]
    x0, x1 = min(xs), max(xs)
    y_start = min(ys) - 0.5 * H
    N = 120
    odd_hits = []
    tested = 0
    for i in range(N):
        for k in range(N):
            x = x0 + (x1 - x0) * (i + 0.5) / N
            z = lo_z + H * (k + 0.5) / N
            origin = Vector((x, y_start, z))
            direction = Vector((0.0, 1.0, 0.0))
            count = 0
            pos = origin.copy()
            guard = 0
            while guard < 64:
                guard += 1
                hit = bvh.ray_cast(pos, direction)
                if hit[0] is None:
                    break
                count += 1
                pos = hit[0] + direction * (H * 1e-5)
            if count == 0:
                continue
            tested += 1
            if count % 2 == 1:
                odd_hits.append({
                    "x": round(x, 4), "z": round(z, 4),
                    "z_norm": round((z - lo_z) / H, 4), "crossings": count,
                })
    out["ray_grid"] = {
        "grid": N,
        "rays_that_hit": tested,
        "odd_parity_rays": len(odd_hits),
        "odd_fraction": round(len(odd_hits) / max(tested, 1), 5),
        "samples": odd_hits[:40],
    }
    bm.free()

    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=2)
    print("HOLES %s" % args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
