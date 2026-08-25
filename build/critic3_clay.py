"""Clay head pass: untextured matte so silhouette, eye rims and the forehead mark are
judged as geometry only. Green emissive wall behind so any see-through reads green.

blender-launcher.exe --background --factory-startup --python critic3_clay.py -- \
    --glb <path> --out <dir> --tag <name> [--res 900]
"""

import argparse
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
    ap.add_argument("--tag", default="clay")
    ap.add_argument("--res", type=int, default=900)
    return ap.parse_args(argv)


def world_bounds(meshes):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for obj in meshes:
        for c in obj.bound_box:
            p = obj.matrix_world @ Vector(c)
            for i in range(3):
                lo[i] = min(lo[i], p[i])
                hi[i] = max(hi[i], p[i])
    return lo, hi


def aim(cam, target, yaw, pitch, dist):
    y = math.radians(yaw)
    p = math.radians(pitch)
    cam.location = Vector((
        target.x + dist * math.cos(p) * math.sin(y),
        target.y - dist * math.cos(p) * math.cos(y),
        target.z + dist * math.sin(p),
    ))
    d = target - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()


def main():
    args = parse_args()
    os.makedirs(args.out, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args.glb)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]

    lo, hi = world_bounds(meshes)
    H = hi.z - lo.z
    s = 1.0 / H
    root = bpy.data.objects.new("Root", None)
    bpy.context.scene.collection.objects.link(root)
    for o in meshes:
        if o.parent is None:
            o.parent = root
            o.matrix_parent_inverse = root.matrix_world.inverted()
    c = (lo + hi) * 0.5
    root.location = Vector((-c.x * s, -c.y * s, -lo.z * s))
    root.scale = (s, s, s)
    bpy.context.view_layer.update()

    clay = bpy.data.materials.new("Clay")
    clay.use_nodes = True
    b = clay.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.42, 0.43, 0.45, 1.0)
    b.inputs["Roughness"].default_value = 0.55
    for o in meshes:
        o.data.materials.clear()
        o.data.materials.append(clay)

    bpy.ops.mesh.primitive_plane_add(size=16.0, location=(0.0, 2.4, 0.5),
                                     rotation=(math.pi / 2, 0.0, 0.0))
    wall = bpy.context.active_object
    m = bpy.data.materials.new("WallMat")
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs[0].default_value = (0.02, 1.0, 0.15, 1.0)
    em.inputs[1].default_value = 5.0
    on = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(em.outputs[0], on.inputs[0])
    wall.data.materials.append(m)

    for loc, en in (((1.9, -2.5, 2.3), 800.0), ((-2.3, -1.9, 1.1), 340.0),
                    ((0.0, -2.6, 0.2), 200.0)):
        d = bpy.data.lights.new("L", type="AREA")
        d.energy = en
        d.size = 3.0
        o = bpy.data.objects.new("L", d)
        o.location = loc
        bpy.context.scene.collection.objects.link(o)
        t = o.constraints.new("TRACK_TO")
        t.track_axis = "TRACK_NEGATIVE_Z"
        t.up_axis = "UP_Y"

    w = bpy.data.worlds.new("W")
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.0, 0.0, 0.0, 1.0)
    bpy.context.scene.world = w

    cd = bpy.data.cameras.new("Cam")
    cd.lens = 85.0
    cam = bpy.data.objects.new("Cam", cd)
    bpy.context.scene.collection.objects.link(cam)
    bpy.context.scene.camera = cam

    sc = bpy.context.scene
    sc.render.resolution_x = args.res
    sc.render.resolution_y = args.res
    sc.render.image_settings.file_format = "PNG"
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 44
    sc.cycles.use_denoising = True
    sc.view_settings.view_transform = "AgX"

    head = Vector((0.0, 0.0, 0.66))
    views = [
        ("head", head, 0.0, 6.0, 1.30),
        ("headL", head, -30.0, 6.0, 1.30),
        ("headR", head, 30.0, 6.0, 1.30),
        ("headTop", head, 0.0, 42.0, 1.30),
        ("headLow", head, 0.0, -26.0, 1.30),
        ("poreProf", Vector((0.0, 0.0, 0.70)), 68.0, 4.0, 0.80),
        ("full", Vector((0.0, 0.0, 0.50)), 0.0, 8.0, 2.30),
    ]
    for n, t, yaw, pitch, dist in views:
        aim(cam, t, yaw, pitch, dist)
        sc.render.filepath = os.path.join(args.out, "%s-%s.png" % (args.tag, n))
        bpy.ops.render.render(write_still=True)
        print("SHOT %s" % n)
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
