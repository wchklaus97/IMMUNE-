"""See-through test: put a bright emissive wall behind the model, strip the
material to flat matte, and render the face plus tight crops on each eye and the
pore. Any genuine open hole reads as a bright patch. Also renders a plain-clay
version so silhouette/rim quality can be judged without texture masking it.

blender-launcher.exe --background --factory-startup --python critic3_backlit.py -- \
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
    ap.add_argument("--tag", default="bl")
    ap.add_argument("--res", type=int, default=900)
    return ap.parse_args(argv)


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


def aim(cam, target, yaw_deg, pitch_deg, distance):
    yaw = math.radians(yaw_deg)
    pitch = math.radians(pitch_deg)
    cam.location = Vector((
        target.x + distance * math.cos(pitch) * math.sin(yaw),
        target.y - distance * math.cos(pitch) * math.cos(yaw),
        target.z + distance * math.sin(pitch),
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
    scale = 1.0 / H
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

    # flat matte grey material, no texture, so holes are not confused with dark pixels
    clay = bpy.data.materials.new("Clay")
    clay.use_nodes = True
    bsdf = clay.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.32, 0.33, 0.35, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.62
    for obj in meshes:
        obj.data.materials.clear()
        obj.data.materials.append(clay)

    # bright emissive wall BEHIND the model (+Y), and a second one filling the frame
    for name, loc, rot, size, power in (
        ("Wall", (0.0, 2.2, 0.5), (math.pi / 2, 0.0, 0.0), 14.0, 6.0),
    ):
        bpy.ops.mesh.primitive_plane_add(size=size, location=loc, rotation=rot)
        wall = bpy.context.active_object
        wall.name = name
        m = bpy.data.materials.new(name + "Mat")
        m.use_nodes = True
        nt = m.node_tree
        nt.nodes.clear()
        em = nt.nodes.new("ShaderNodeEmission")
        em.inputs[0].default_value = (0.05, 1.0, 0.25, 1.0)  # vivid green = unmistakable
        em.inputs[1].default_value = power
        outn = nt.nodes.new("ShaderNodeOutputMaterial")
        nt.links.new(em.outputs[0], outn.inputs[0])
        wall.data.materials.append(m)

    def add_light(loc, energy, size=3.0):
        d = bpy.data.lights.new("L", type="AREA")
        d.energy = energy
        d.size = size
        o = bpy.data.objects.new("L", d)
        o.location = loc
        bpy.context.scene.collection.objects.link(o)
        t = o.constraints.new("TRACK_TO")
        t.track_axis = "TRACK_NEGATIVE_Z"
        t.up_axis = "UP_Y"
        return o

    add_light((1.8, -2.4, 2.2), 700.0)
    add_light((-2.2, -1.8, 1.2), 320.0)

    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.0, 0.0, 0.0, 1.0)
    bpy.context.scene.world = world

    data = bpy.data.cameras.new("Cam")
    data.lens = 135.0
    cam = bpy.data.objects.new("Cam", data)
    bpy.context.scene.collection.objects.link(cam)
    bpy.context.scene.camera = cam

    sc = bpy.context.scene
    sc.render.resolution_x = args.res
    sc.render.resolution_y = args.res
    sc.render.image_settings.file_format = "PNG"
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 48
    sc.cycles.use_denoising = True
    sc.view_settings.view_transform = "AgX"

    # eye centres measured from the audit, in normalised model space
    eye_z = 0.568
    views = [
        ("faceWide", Vector((0.0, 0.0, 0.70)), 0.0, 4.0, 2.10),
        ("eyeR", Vector((0.19, 0.0, eye_z)), 0.0, 0.0, 1.00),
        ("eyeL", Vector((-0.19, 0.0, eye_z)), 0.0, 0.0, 1.00),
        ("eyeR34", Vector((0.19, 0.0, eye_z)), 34.0, 6.0, 1.00),
        ("eyeL34", Vector((-0.19, 0.0, eye_z)), -34.0, 6.0, 1.00),
        ("eyeRlow", Vector((0.19, 0.0, eye_z)), 12.0, -26.0, 1.00),
        ("poreZ", Vector((0.0, 0.0, 0.696)), 0.0, 6.0, 0.90),
        ("poreZ34", Vector((0.0, 0.0, 0.696)), 38.0, 14.0, 0.90),
        ("poreTop", Vector((0.0, 0.0, 0.696)), 0.0, 52.0, 0.90),
        ("poreSide", Vector((0.0, 0.0, 0.696)), 76.0, 6.0, 0.95),
    ]
    for name, target, yaw, pitch, dist in views:
        aim(cam, target, yaw, pitch, dist)
        sc.render.filepath = os.path.join(args.out, "%s-%s.png" % (args.tag, name))
        bpy.ops.render.render(write_still=True)
        print("SHOT %s" % name)
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
