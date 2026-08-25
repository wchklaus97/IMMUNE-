"""Forehead midline silhouette profile: for slices up the head at x ~ 0, report the
frontmost surface Y. A raised boss makes Y dip forward (more negative) at the pore;
a recessed dish makes Y push back (less negative). Also reports left/right eye
socket symmetry by mirroring X.

blender-launcher.exe --background --factory-startup --python critic3_profile.py -- \
    --glb <path> --out <json>
"""

import argparse
import json
import os
import sys

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
        me2 = bpy.data.meshes.new("tmp")
        tmp.to_mesh(me2)
        tmp.free()
        bm.from_mesh(me2)
        bpy.data.meshes.remove(me2)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.verts.ensure_lookup_table()

    zs = [v.co.z for v in bm.verts]
    ys = [v.co.y for v in bm.verts]
    lo_z, hi_z = min(zs), max(zs)
    H = hi_z - lo_z

    verts = [v.co.copy() for v in bm.verts]
    faces = [[v.index for v in f.verts] for f in bm.faces]
    bvh = BVHTree.FromPolygons(verts, faces, all_triangles=True, epsilon=0.0)
    y_start = min(ys) - 0.6 * H

    out = {"glb": os.path.basename(args.glb), "height": round(H, 5)}

    def front_y(x, z):
        hit = bvh.ray_cast(Vector((x, y_start, z)), Vector((0.0, 1.0, 0.0)))
        return None if hit[0] is None else hit[0].y

    # midline profile up the head (z_norm 0.45 .. 0.99)
    prof = []
    for i in range(140):
        zn = 0.45 + (0.99 - 0.45) * i / 139.0
        z = lo_z + zn * H
        y = front_y(0.0, z)
        prof.append({"z_norm": round(zn, 4),
                     "front_y": None if y is None else round(y, 5)})
    out["midline_profile"] = prof

    # local relief: front_y minus a smooth baseline from neighbours outside the pore
    # measured as deviation from the chord between z_norm 0.60 and 0.80 shoulders
    def sample_band(zn_lo, zn_hi):
        vals = []
        for j in range(30):
            zn = zn_lo + (zn_hi - zn_lo) * j / 29.0
            y = front_y(0.0, lo_z + zn * H)
            if y is not None:
                vals.append((zn, y))
        return vals

    out["band_below"] = [[round(a, 4), round(b, 5)] for a, b in sample_band(0.60, 0.645)]
    out["band_above"] = [[round(a, 4), round(b, 5)] for a, b in sample_band(0.755, 0.80)]

    # horizontal profile across the pore at its own height, both meshes give a dish/boss
    # signature: scan x at the z of the frontmost/backmost anomaly
    def hscan(zn):
        row = []
        for k in range(81):
            x = -0.10 + 0.20 * k / 80.0
            y = front_y(x, lo_z + zn * H)
            row.append([round(x, 4), None if y is None else round(y, 5)])
        return row

    out["hscan"] = {}
    for zn in (0.66, 0.68, 0.70, 0.72, 0.74):
        out["hscan"]["z_norm_%.2f" % zn] = hscan(zn)

    # eye socket symmetry: frontmost Y on a grid over each eye, mirrored
    def eye_grid(sign):
        g = []
        for a in range(13):
            for b in range(13):
                x = sign * (0.10 + 0.14 * a / 12.0)
                zn = 0.50 + 0.12 * b / 12.0
                y = front_y(x, lo_z + zn * H)
                g.append(None if y is None else round(y, 5))
        return g

    gl = eye_grid(-1)
    gr = eye_grid(1)
    misses_l = sum(1 for v in gl if v is None)
    misses_r = sum(1 for v in gr if v is None)
    pairs = [(a, b) for a, b in zip(gl, gr) if a is not None and b is not None]
    out["eye_symmetry"] = {
        "samples": len(gl),
        "misses_negX": misses_l,
        "misses_posX": misses_r,
        "mean_abs_diff": (round(sum(abs(a - b) for a, b in pairs) / len(pairs), 5)
                          if pairs else None),
        "max_abs_diff": (round(max(abs(a - b) for a, b in pairs), 5)
                         if pairs else None),
        "mean_y_negX": round(sum(a for a, _ in pairs) / len(pairs), 5) if pairs else None,
        "mean_y_posX": round(sum(b for _, b in pairs) / len(pairs), 5) if pairs else None,
    }

    bm.free()
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=2)
    print("PROFILE %s" % args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
