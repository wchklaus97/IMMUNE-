"""Headless Blender inspector: import a GLB, report mesh facts, render review views.

blender-launcher.exe --background --factory-startup --python bl_shots.py -- \
    --glb <path> --out <dir> --tag <name> [--res 768] [--samples 48] [--engine cycles|eevee]

Renders 3/4, front, side, back and two head close-ups so the forehead mark can be
judged against the 2D concept without opening the GUI.
"""

import argparse
import json
import math
import os
import sys

import bpy
from mathutils import Vector


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--glb", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--tag", default="shot")
    ap.add_argument("--res", type=int, default=768)
    ap.add_argument("--samples", type=int, default=48)
    ap.add_argument("--engine", default="cycles")
    return ap.parse_args(argv)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_glb(path):
    bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.context.scene.objects if o.type == "MESH"]


def mesh_report(meshes):
    report = {"objects": []}
    total_tris = 0
    total_verts = 0
    for obj in meshes:
        me = obj.data
        me.calc_loop_triangles()
        tris = len(me.loop_triangles)
        total_tris += tris
        total_verts += len(me.vertices)
        mats = []
        for slot in obj.material_slots:
            mat = slot.material
            if mat is None:
                continue
            images = sorted({
                n.image.name for n in (mat.node_tree.nodes if mat.node_tree else [])
                if n.type == "TEX_IMAGE" and n.image is not None
            })
            mats.append({"name": mat.name, "images": images})
        report["objects"].append({
            "name": obj.name,
            "verts": len(me.vertices),
            "tris": tris,
            "uv_layers": [uv.name for uv in me.uv_layers],
            "shape_keys": (
                [k.name for k in me.shape_keys.key_blocks] if me.shape_keys else []
            ),
            "materials": mats,
            "modifiers": [m.type for m in obj.modifiers],
        })
    report["total_tris"] = total_tris
    report["total_verts"] = total_verts
    report["armatures"] = [
        o.name for o in bpy.context.scene.objects if o.type == "ARMATURE"
    ]
    report["actions"] = [a.name for a in bpy.data.actions]
    return report


def world_bounds(meshes):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for obj in meshes:
        for corner in obj.bound_box:
            p = obj.matrix_world @ Vector(corner)
            for i in range(3):
                lo[i] = min(lo[i], p[i])
                hi[i] = max(hi[i], p[i])
    return lo, hi


def normalise(meshes):
    """Drop the model onto Z=0, centre it on XY, scale so it is 1 unit tall."""
    lo, hi = world_bounds(meshes)
    size = hi - lo
    height = max(size.z, 1e-6)
    scale = 1.0 / height
    root = bpy.data.objects.new("Root", None)
    bpy.context.scene.collection.objects.link(root)
    for obj in meshes:
        if obj.parent is None:
            obj.parent = root
            obj.matrix_parent_inverse = root.matrix_world.inverted()
    centre = (lo + hi) * 0.5
    root.location = Vector((-centre.x * scale, -centre.y * scale, -lo.z * scale))
    root.scale = (scale, scale, scale)
    bpy.context.view_layer.update()
    return size, height


def build_lights():
    def add(name, loc, energy, color, size=3.0):
        data = bpy.data.lights.new(name, type="AREA")
        data.energy = energy
        data.color = color
        data.size = size
        obj = bpy.data.objects.new(name, data)
        obj.location = loc
        bpy.context.scene.collection.objects.link(obj)
        track = obj.constraints.new("TRACK_TO")
        track.track_axis = "TRACK_NEGATIVE_Z"
        track.up_axis = "UP_Y"
        return obj

    add("Key", (2.2, -2.6, 2.6), 900.0, (1.0, 0.96, 0.90))
    add("Fill", (-2.8, -1.6, 1.1), 260.0, (0.55, 0.72, 1.0))
    add("Rim", (-0.6, 3.2, 1.9), 700.0, (0.68, 0.86, 1.0))

    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.012, 0.015, 0.02, 1.0)
    bg.inputs[1].default_value = 1.0
    bpy.context.scene.world = world


def make_camera():
    data = bpy.data.cameras.new("Cam")
    data.lens = 62.0
    cam = bpy.data.objects.new("Cam", data)
    bpy.context.scene.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    return cam


def aim(cam, target, yaw_deg, pitch_deg, distance):
    yaw = math.radians(yaw_deg)
    pitch = math.radians(pitch_deg)
    cam.location = Vector((
        target.x + distance * math.cos(pitch) * math.sin(yaw),
        target.y - distance * math.cos(pitch) * math.cos(yaw),
        target.z + distance * math.sin(pitch),
    ))
    direction = target - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_render(engine, res, samples):
    scene = bpy.context.scene
    scene.render.resolution_x = res
    scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    if engine == "eevee":
        for name in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
            try:
                scene.render.engine = name
                break
            except TypeError:
                continue
        if hasattr(scene, "eevee"):
            scene.eevee.taa_render_samples = samples
    else:
        scene.render.engine = "CYCLES"
        scene.cycles.device = "CPU"
        scene.cycles.samples = samples
        scene.cycles.use_denoising = True
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Punchy"


def render_to(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("SHOT %s" % path)


def main():
    args = parse_args()
    os.makedirs(args.out, exist_ok=True)
    clear_scene()
    meshes = import_glb(args.glb)
    if not meshes:
        print("ERROR: no meshes in %s" % args.glb)
        return 2

    report = mesh_report(meshes)
    raw_lo, raw_hi = world_bounds(meshes)
    report["raw_bounds_min"] = [round(v, 4) for v in raw_lo]
    report["raw_bounds_max"] = [round(v, 4) for v in raw_hi]
    size, height = normalise(meshes)
    report["raw_size"] = [round(v, 4) for v in size]
    report["raw_height"] = round(height, 4)

    report_path = os.path.join(args.out, "%s-report.json" % args.tag)
    with open(report_path, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)
    print("REPORT %s" % report_path)

    build_lights()
    cam = make_camera()
    setup_render(args.engine, args.res, args.samples)

    body = Vector((0.0, 0.0, 0.45))
    head = Vector((0.0, 0.0, 0.78))
    views = [
        ("34", body, 35.0, 16.0, 2.9),
        ("front", body, 0.0, 10.0, 2.9),
        ("side", body, 90.0, 10.0, 2.9),
        ("back", body, 180.0, 12.0, 2.9),
        ("face", head, 0.0, 4.0, 1.15),
        ("face34", head, 30.0, 6.0, 1.15),
        ("facehigh", head, 0.0, 28.0, 1.15),
    ]
    for name, target, yaw, pitch, dist in views:
        aim(cam, target, yaw, pitch, dist)
        render_to(os.path.join(args.out, "%s-%s.png" % (args.tag, name)))
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
