"""Dump CHAR-BASE-T mesh arrays + basecolor texture so analysis can run outside Blender.

blender-launcher.exe --background --factory-startup --python bl_fix_t_dump.py -- \
    --glb <path> --outdir <dir>

Writes <outdir>/t_mesh.npz (co, uv_loop, loop_vert, tris, edges) and
<outdir>/t_basecolor.png. Blender detaches; poll for the files.
"""

import argparse
import os
import sys

import bpy
import numpy as np


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--glb", required=True)
    ap.add_argument("--outdir", required=True)
    return ap.parse_args(argv)


def main():
    args = parse_args()
    os.makedirs(args.outdir, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args.glb)
    obj = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
    me = obj.data
    me.calc_loop_triangles()

    nv = len(me.vertices)
    co = np.empty(nv * 3, dtype=np.float64)
    me.vertices.foreach_get("co", co)
    co = co.reshape(nv, 3)
    mw = np.array(obj.matrix_world)
    co = co @ mw[:3, :3].T + mw[:3, 3]

    nl = len(me.loops)
    uv = np.empty(nl * 2, dtype=np.float64)
    me.uv_layers.active.data.foreach_get("uv", uv)
    uv = uv.reshape(nl, 2)
    lv = np.empty(nl, dtype=np.int32)
    me.loops.foreach_get("vertex_index", lv)

    nt = len(me.loop_triangles)
    tv = np.empty(nt * 3, dtype=np.int32)
    me.loop_triangles.foreach_get("vertices", tv)
    tv = tv.reshape(nt, 3)
    tl = np.empty(nt * 3, dtype=np.int32)
    me.loop_triangles.foreach_get("loops", tl)
    tl = tl.reshape(nt, 3)

    ne = len(me.edges)
    ev = np.empty(ne * 2, dtype=np.int32)
    me.edges.foreach_get("vertices", ev)
    ev = ev.reshape(ne, 2)

    np.savez(
        os.path.join(args.outdir, "t_mesh.npz"),
        co=co, uv=uv, loop_vert=lv, tris=tv, tri_loops=tl, edges=ev,
        matrix_world=mw,
    )

    for node in obj.material_slots[0].material.node_tree.nodes:
        if node.type == "TEX_IMAGE" and node.image is not None:
            img = node.image
            copy = img.copy()
            copy.filepath_raw = os.path.join(args.outdir, "t_basecolor.png")
            copy.file_format = "PNG"
            copy.save()
            bpy.data.images.remove(copy)
            break

    with open(os.path.join(args.outdir, "t_dump.done"), "w") as fh:
        fh.write("ok %d verts %d tris\n" % (nv, nt))
    return 0


if __name__ == "__main__":
    sys.exit(main())
