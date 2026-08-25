"""Apply the CHAR-BASE-T geometry fix and export a GLB with the texture embedded.

blender-launcher.exe --background --factory-startup --python bl_fix_t.py -- \
    --glb <in.glb> --out <out.glb> --report <report.json> [--set key=value ...]

Only vertex positions change, so the tri count, the UVMap and the baked
basecolor all survive untouched. Blender detaches: poll for the report file.
"""

import argparse
import json
import os
import sys
import traceback

import bmesh
import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bl_fix_t_ops as ops  # noqa: E402

# Pre-scale, world space. At 5k tris the pore disc is only ~15 vertices across,
# which is not enough for a circular rim or a cylindrical hole, so the pore gets
# two passes: a broad one for the dish and a tight one for the rim.
#
# The tight pass is centred *behind* the lens's front face, not on it. The rim
# is where the sunk lens crosses the skull, so it is the skull that has to be
# dense there — and the skull sits about 0.05 further back. A sphere centred on
# the face only reached the skull within r = 0.037, just inside the crossing at
# r = 0.043, which left the skull with 30 vertices around the rim and 40-degree
# gaps between them. That is the polygonal rim, and no amount of extra passes on
# the lens was ever going to fix it: the lens already had 223.
#
# The mouth needs no pass: it is squeezed shut by a smooth field now rather than
# carved, and dropping its two passes buys back 1,100 triangles.
#
# The last two passes are rings rather than balls, and each is cut off in depth
# so it lands on one shell only: the lens is still a raised boss at this stage,
# standing about 0.03 in front of the skull at the rim radius, so a depth window
# separates them cleanly. Spending on the rim band alone rather than on another
# ball costs 450 triangles fewer than the ball did and leaves the rim finer.
REFINE = [
    dict(centre=(-0.004, -0.327, 0.641), radius=0.118, axis=(0.0, -0.90, 0.44)),
    dict(centre=(-0.004, -0.302, 0.629), radius=0.058, axis=(0.0, -0.90, 0.44)),
    dict(centre=(-0.004, -0.327, 0.641), radius=0.062, inner=0.026,
         axis=(0.0, -0.90, 0.44), depth=(-0.055, -0.004)),
    dict(centre=(-0.004, -0.327, 0.641), radius=0.056, inner=0.034,
         axis=(0.0, -0.90, 0.44), depth=(0.004, 0.030)),
]


def refine_regions(obj, regions):
    """Loop-subdivide small patches. UVs interpolate linearly inside a triangle,
    which is exactly how the texture is sampled, so the bake keeps landing.

    Edges are picked by where they *are*, never by which face they belong to.
    The GLB duplicates vertices along every UV seam, so a seam edge exists twice
    as two unrelated edges lying on top of each other; a face-based selection
    can take one copy and leave the other, and the resulting T-junction splits
    wide open as soon as the carve displaces the new midpoint vertex.
    """
    mw = obj.matrix_world
    inv_mw = mw.inverted()
    me = obj.data
    counts = []
    for reg in regions:
        bm = bmesh.new()
        bm.from_mesh(me)
        c = inv_mw @ Vector(reg["centre"])
        n = (inv_mw.to_3x3() @ Vector(reg["axis"])).normalized()
        inner, depth = reg.get("inner", 0.0), reg.get("depth")
        edges = []
        for e in bm.edges:
            d = (e.verts[0].co + e.verts[1].co) * 0.5 - c
            if d.length >= reg["radius"]:
                continue
            h = d.dot(n)
            if depth is not None and not depth[0] <= h <= depth[1]:
                continue
            if (d - h * n).length < inner:
                continue
            edges.append(e)
        if edges:
            bmesh.ops.subdivide_edges(bm, edges=edges, cuts=1, use_grid_fill=True)
            bmesh.ops.triangulate(bm, faces=bm.faces[:])
        bm.to_mesh(me)
        bm.free()
        me.update()
        me.calc_loop_triangles()
        counts.append({"radius": reg["radius"], "edges": len(edges),
                       "tris_after": len(me.loop_triangles)})
    return counts


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--glb", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--report", required=True)
    ap.add_argument("--set", action="append", default=[])
    ap.add_argument("--dump", default=None)
    ap.add_argument("--refine", default=None, help="JSON file, overrides REFINE")
    return ap.parse_args(argv)


def overrides(pairs):
    out = {}
    for item in pairs:
        key, _, val = item.partition("=")
        out[key] = json.loads(val)
    return out


def reshade(me, co_local, tris):
    """Rebuild smooth shading: mark every face smooth, then write split normals
    taken from the *welded* topology so UV seams do not shade as creases."""
    state = []
    try:
        bpy.ops.mesh.customdata_custom_splitnormals_clear()
        state.append("split-cleared")
    except Exception:
        pass
    try:
        me.attributes.remove(me.attributes["custom_normal"])
        state.append("attr-removed")
    except Exception:
        pass
    try:
        me.polygons.foreach_set("use_smooth", np.ones(len(me.polygons), dtype=bool))
        state.append("polys-smooth")
    except Exception:
        pass
    try:
        me.attributes.remove(me.attributes["sharp_face"])
        state.append("sharp-face-removed")
    except Exception:
        pass
    try:
        normals = ops.welded_normals(co_local, tris)
        me.normals_split_custom_set_from_vertices([tuple(n) for n in normals])
        state.append("custom-normals-set")
    except Exception as exc:
        state.append("custom-normals-failed:%s" % type(exc).__name__)
    return "+".join(state)


def export_glb(path):
    tries = [
        dict(filepath=path, export_format="GLB", export_image_format="AUTO",
             export_materials="EXPORT", export_yup=True, export_apply=False),
        dict(filepath=path, export_format="GLB", export_image_format="AUTO"),
        dict(filepath=path, export_format="GLB"),
    ]
    last = None
    for kw in tries:
        try:
            bpy.ops.export_scene.gltf(**kw)
            return kw
        except TypeError as exc:
            last = exc
    raise last


def main():
    args = parse_args()
    report = {"ok": False}
    try:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=args.glb)
        obj = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        me = obj.data
        me.calc_loop_triangles()
        report["tris_in"] = len(me.loop_triangles)
        if args.refine:
            with open(args.refine, encoding="utf-8") as fh:
                regions = json.load(fh)
        else:
            regions = REFINE
        report["refine"] = refine_regions(obj, regions)

        nv = len(me.vertices)
        co = np.empty(nv * 3, dtype=np.float64)
        me.vertices.foreach_get("co", co)
        co = co.reshape(nv, 3)
        mw = np.array(obj.matrix_world)
        R, t = mw[:3, :3], mw[:3, 3]
        world = co @ R.T + t

        nt = len(me.loop_triangles)
        tv = np.empty(nt * 3, dtype=np.int32)
        me.loop_triangles.foreach_get("vertices", tv)
        tris = tv.reshape(nt, 3)

        if args.dump:
            nl = len(me.loops)
            uv = np.empty(nl * 2, dtype=np.float64)
            me.uv_layers.active.data.foreach_get("uv", uv)
            lv = np.empty(nl, dtype=np.int32)
            me.loops.foreach_get("vertex_index", lv)
            os.makedirs(args.dump, exist_ok=True)
            np.savez(os.path.join(args.dump, "t_mesh_sub.npz"),
                     co=world, tris=tris, uv=uv.reshape(nl, 2), loop_vert=lv)

        new_world, log = ops.fix(world, tris, overrides(args.set))
        new_local = (new_world - t) @ np.linalg.inv(R).T
        me.vertices.foreach_set("co", new_local.reshape(-1))
        me.update()

        log["shading"] = reshade(me, new_local, tris)
        me.update()

        os.makedirs(os.path.dirname(args.out), exist_ok=True)
        log["export_kwargs"] = {k: str(v) for k, v in export_glb(args.out).items()}

        me.calc_loop_triangles()
        report.update({
            "ok": True,
            "in": args.glb,
            "out": args.out,
            "verts": nv,
            "tris": len(me.loop_triangles),
            "uv_layers": [uv.name for uv in me.uv_layers],
            "materials": [s.material.name for s in obj.material_slots if s.material],
            "images": sorted({
                n.image.name
                for s in obj.material_slots if s.material and s.material.node_tree
                for n in s.material.node_tree.nodes
                if n.type == "TEX_IMAGE" and n.image
            }),
            "log": log,
        })
    except Exception:
        report["error"] = traceback.format_exc()

    with open(args.report, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
