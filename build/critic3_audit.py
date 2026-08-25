"""Independent critic audit: topology holes, tri count, UV/texture survival,
dark-feature placement, and pore protrusion profile. Writes JSON, renders nothing.

blender-launcher.exe --background --factory-startup --python critic3_audit.py -- \
    --glb <path> --out <json>
"""

import argparse
import json
import math
import os
import sys
from collections import defaultdict

import bpy
import bmesh
from mathutils import Vector


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--glb", required=True)
    ap.add_argument("--out", required=True)
    return ap.parse_args(argv)


def load(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.context.scene.objects if o.type == "MESH"]


class Sampler:
    """Nearest-neighbour texture sampler over a one-time pixel buffer copy."""

    def __init__(self, img):
        self.w, self.h = img.size
        self.ch = img.channels
        self.px = list(img.pixels) if self.w and self.h else []

    def lum(self, u, v):
        if not self.px:
            return None
        x = int((u % 1.0) * self.w) % self.w
        y = int((v % 1.0) * self.h) % self.h
        i = (y * self.w + x) * self.ch
        return 0.2126 * self.px[i] + 0.7152 * self.px[i + 1] + 0.0722 * self.px[i + 2]


def main():
    args = parse_args()
    meshes = load(args.glb)
    out = {"glb": os.path.basename(args.glb), "objects": []}

    total_tris = 0
    all_dark = []
    all_verts = []

    for obj in meshes:
        me = obj.data
        me.calc_loop_triangles()
        tris = len(me.loop_triangles)
        total_tris += tris

        bm = bmesh.new()
        bm.from_mesh(me)
        bm.verts.ensure_lookup_table()
        bm.edges.ensure_lookup_table()

        boundary = [e for e in bm.edges if len(e.link_faces) == 1]
        nonmanifold = [e for e in bm.edges if len(e.link_faces) > 2]
        loose = [v for v in bm.verts if not v.link_faces]

        # group boundary edges into loops
        adj = defaultdict(set)
        for e in boundary:
            a, b = e.verts
            adj[a.index].add(b.index)
            adj[b.index].add(a.index)
        seen = set()
        loops = []
        for start in adj:
            if start in seen:
                continue
            stack = [start]
            comp = []
            seen.add(start)
            while stack:
                cur = stack.pop()
                comp.append(cur)
                for nb in adj[cur]:
                    if nb not in seen:
                        seen.add(nb)
                        stack.append(nb)
            pts = [obj.matrix_world @ bm.verts[i].co for i in comp]
            cen = sum(pts, Vector()) / len(pts)
            rad = max((p - cen).length for p in pts)
            loops.append({
                "verts": len(comp),
                "centre": [round(c, 4) for c in cen],
                "radius": round(rad, 4),
            })
        loops.sort(key=lambda d: -d["verts"])
        bm.free()

        # texture / UV
        uv_names = [uv.name for uv in me.uv_layers]
        img = None
        mat_info = []
        for slot in obj.material_slots:
            mat = slot.material
            if not mat:
                continue
            imgs = []
            for n in (mat.node_tree.nodes if mat.node_tree else []):
                if n.type == "TEX_IMAGE" and n.image is not None:
                    imgs.append({"name": n.image.name, "size": list(n.image.size)})
                    if img is None:
                        img = n.image
            mat_info.append({"name": mat.name, "images": imgs})

        # dark-feature localisation via UV -> texture sample
        dark_pts = []
        if uv_names and img is not None:
            sampler = Sampler(img)
            uv = me.uv_layers[0].data
            for tri in me.loop_triangles:
                us = [uv[li].uv for li in tri.loops]
                cu = sum(x[0] for x in us) / 3.0
                cv = sum(x[1] for x in us) / 3.0
                lum = sampler.lum(cu, cv)
                if lum is None:
                    continue
                if lum < 0.06:
                    c = obj.matrix_world @ Vector(tri.center)
                    dark_pts.append([c.x, c.y, c.z])
            all_dark.extend(dark_pts)

        for v in me.vertices:
            p = obj.matrix_world @ v.co
            all_verts.append([p.x, p.y, p.z])

        out["objects"].append({
            "name": obj.name,
            "verts": len(me.vertices),
            "tris": tris,
            "uv_layers": uv_names,
            "materials": mat_info,
            "boundary_edges": len(boundary),
            "boundary_loops": loops[:12],
            "nonmanifold_edges": len(nonmanifold),
            "loose_verts": len(loose),
            "dark_tris": len(dark_pts),
        })

    out["total_tris"] = total_tris

    # ---- bounds / head frame ----
    xs = [p[0] for p in all_verts]
    ys = [p[1] for p in all_verts]
    zs = [p[2] for p in all_verts]
    lo = Vector((min(xs), min(ys), min(zs)))
    hi = Vector((max(xs), max(ys), max(zs)))
    H = hi.z - lo.z
    out["bounds_min"] = [round(v, 4) for v in lo]
    out["bounds_max"] = [round(v, 4) for v in hi]
    out["height"] = round(H, 4)

    def norm_z(z):
        return (z - lo.z) / H

    # ---- cluster dark points into features ----
    clusters = []
    if all_dark:
        # simple grid-based clustering
        cell = H * 0.035
        buckets = defaultdict(list)
        for p in all_dark:
            key = (int(p[0] / cell), int(p[1] / cell), int(p[2] / cell))
            buckets[key].append(p)
        keys = list(buckets)
        seenk = set()
        for k in keys:
            if k in seenk:
                continue
            stack = [k]
            seenk.add(k)
            pts = []
            while stack:
                ck = stack.pop()
                pts.extend(buckets[ck])
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        for dz in (-1, 0, 1):
                            nk = (ck[0] + dx, ck[1] + dy, ck[2] + dz)
                            if nk in buckets and nk not in seenk:
                                seenk.add(nk)
                                stack.append(nk)
            cx = sum(p[0] for p in pts) / len(pts)
            cy = sum(p[1] for p in pts) / len(pts)
            cz = sum(p[2] for p in pts) / len(pts)
            clusters.append({
                "n": len(pts),
                "centre": [round(cx, 4), round(cy, 4), round(cz, 4)],
                "z_norm": round(norm_z(cz), 4),
                "x_norm": round(cx / (H * 0.5), 4),
                "extent_x": round(max(p[0] for p in pts) - min(p[0] for p in pts), 4),
                "extent_z": round(max(p[2] for p in pts) - min(p[2] for p in pts), 4),
            })
        clusters.sort(key=lambda d: -d["n"])
    out["dark_clusters"] = clusters[:10]

    # ---- pore protrusion profile ----
    # pore = dark cluster nearest the front midline and highest up the head
    pore = None
    for c in clusters:
        cx, cy, cz = c["centre"]
        if abs(cx) < H * 0.06 and norm_z(cz) > 0.55 and c["n"] >= 3:
            if pore is None or cz > pore["centre"][2]:
                pore = c
    out["pore_cluster"] = pore

    if pore is not None:
        P = Vector(pore["centre"])
        r0 = max(pore["extent_x"], pore["extent_z"]) * 0.5
        r0 = max(r0, H * 0.012)
        out["pore_radius_est"] = round(r0, 4)

        # fit a sphere to the forehead ring around the pore (least squares, linear form)
        ring = [Vector(p) for p in all_verts]
        ring = [p for p in ring
                if 2.0 * r0 <= (p - P).length <= 5.0 * r0 and p.y < P.y + 0.25 * H]
        centre_fit = None
        R = None
        if len(ring) >= 12:
            # solve for sphere: |p|^2 = 2c.p + (R^2 - |c|^2)
            n = len(ring)
            A = [[2 * p.x, 2 * p.y, 2 * p.z, 1.0] for p in ring]
            b = [p.length_squared for p in ring]
            # normal equations 4x4
            M = [[sum(A[i][r] * A[i][c2] for i in range(n)) for c2 in range(4)]
                 for r in range(4)]
            rhs = [sum(A[i][r] * b[i] for i in range(n)) for r in range(4)]
            # gaussian elimination
            for i in range(4):
                piv = max(range(i, 4), key=lambda k: abs(M[k][i]))
                M[i], M[piv] = M[piv], M[i]
                rhs[i], rhs[piv] = rhs[piv], rhs[i]
                if abs(M[i][i]) < 1e-12:
                    M = None
                    break
                for k in range(i + 1, 4):
                    f = M[k][i] / M[i][i]
                    for c2 in range(i, 4):
                        M[k][c2] -= f * M[i][c2]
                    rhs[k] -= f * rhs[i]
            if M is not None:
                sol = [0.0] * 4
                for i in range(3, -1, -1):
                    s = rhs[i] - sum(M[i][k] * sol[k] for k in range(i + 1, 4))
                    sol[i] = s / M[i][i]
                centre_fit = Vector((sol[0], sol[1], sol[2]))
                R2 = sol[3] + centre_fit.length_squared
                R = math.sqrt(R2) if R2 > 0 else None

        if centre_fit is not None and R:
            out["fit_sphere_R"] = round(R, 4)
            out["fit_ring_verts"] = len(ring)
            bins = defaultdict(list)
            for p in all_verts:
                pv = Vector(p)
                d = (pv - P).length
                if d > 5.0 * r0:
                    continue
                if pv.y > P.y + 0.25 * H:
                    continue
                resid = (pv - centre_fit).length - R
                bins[round(d / r0, 0)].append(resid)
            prof = []
            for k in sorted(bins):
                vals = bins[k]
                prof.append({
                    "d_over_r": k,
                    "n": len(vals),
                    "mean_resid_pct_H": round(100.0 * sum(vals) / len(vals) / H, 3),
                    "min_pct_H": round(100.0 * min(vals) / H, 3),
                    "max_pct_H": round(100.0 * max(vals) / H, 3),
                })
            out["pore_profile"] = prof

    # ---- boundary edges near dark eye clusters ----
    eye_report = []
    for c in clusters[:8]:
        cx, cy, cz = c["centre"]
        if norm_z(cz) < 0.45 or abs(cx) < H * 0.03:
            continue
        eye_report.append({"cluster_n": c["n"], "centre": c["centre"],
                           "z_norm": c["z_norm"]})
    out["eye_like_clusters"] = eye_report

    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=2)
    print("AUDIT %s" % args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
