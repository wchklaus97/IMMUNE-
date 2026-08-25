"""Connected-component and eye-region topology report after welding coincident
verts. Answers: is either eye a detached shell, and where exactly is the open rim.

blender-launcher.exe --background --factory-startup --python critic3_comps.py -- \
    --glb <path> --out <json>
"""

import argparse
import json
import os
import sys
from collections import deque

import bpy
import bmesh
from mathutils import Vector


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--glb", required=True)
    ap.add_argument("--out", required=True)
    return ap.parse_args(argv)


def main():
    args = parse_args()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args.glb)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]

    bm = bmesh.new()
    for obj in meshes:
        tmp = bmesh.new()
        tmp.from_mesh(obj.data)
        tmp.transform(obj.matrix_world)
        me2 = bpy.data.meshes.new("t")
        tmp.to_mesh(me2)
        tmp.free()
        bm.from_mesh(me2)
        bpy.data.meshes.remove(me2)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    zs = [v.co.z for v in bm.verts]
    lo_z, hi_z = min(zs), max(zs)
    H = hi_z - lo_z
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=H * 1e-5)
    bm.faces.ensure_lookup_table()
    bm.verts.ensure_lookup_table()

    out = {"glb": os.path.basename(args.glb), "height": round(H, 5)}

    # face-connected components (through shared edges)
    seen = set()
    comps = []
    for f0 in bm.faces:
        if f0.index in seen:
            continue
        q = deque([f0])
        seen.add(f0.index)
        fs = []
        while q:
            f = q.popleft()
            fs.append(f)
            for e in f.edges:
                for nf in e.link_faces:
                    if nf.index not in seen:
                        seen.add(nf.index)
                        q.append(nf)
        pts = [v.co for f in fs for v in f.verts]
        lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        cen = sum(pts, Vector()) / len(pts)
        bnd = sum(1 for f in fs for e in f.edges if len(e.link_faces) == 1)
        comps.append({
            "faces": len(fs),
            "centre": [round(c, 4) for c in cen],
            "size": [round(hi[i] - lo[i], 4) for i in range(3)],
            "z_norm_centre": round((cen.z - lo_z) / H, 4),
            "boundary_edge_incidences": bnd,
        })
    comps.sort(key=lambda d: -d["faces"])
    out["components"] = comps
    out["component_count"] = len(comps)

    # boundary vertices, listed so the open rim can be plotted
    bverts = sorted({v.index for e in bm.edges if len(e.link_faces) == 1 for v in e.verts})
    out["boundary_vert_count"] = len(bverts)
    out["boundary_verts"] = [[round(c, 4) for c in bm.verts[i].co] for i in bverts]

    # is the boundary rim shared with the head (i.e. does a head face touch it)?
    rim_faces = set()
    for i in bverts:
        for f in bm.verts[i].link_faces:
            rim_faces.add(f.index)
    out["faces_touching_rim"] = len(rim_faces)

    bm.free()
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=2)
    print("COMPS %s" % args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
