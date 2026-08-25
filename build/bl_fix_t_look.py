"""Close-up inspection renders of the forehead: flat clay so shape reads, plus a
wireframe pass so topology problems are visible.

blender-launcher.exe --background --factory-startup --python bl_fix_t_look.py -- \
    --glb <path> --out <dir> --tag <name> [--res 900] [--samples 24]
"""

import argparse
import math
import os
import sys

import bpy
from mathutils import Vector

# world-space pore centre of the *fixed* mesh, before the shot harness normalises
PORE = Vector((-0.0038, -0.3100, 0.6763))


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--glb", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--tag", default="look")
    ap.add_argument("--res", type=int, default=900)
    ap.add_argument("--samples", type=int, default=24)
    ap.add_argument("--dist", type=float, default=0.30)
    ap.add_argument("--target", default=None, help="x,y,z to aim at instead of PORE")
    ap.add_argument("--power", type=float, default=1.0)
    return ap.parse_args(argv)


def clay(obj, colour=(0.62, 0.62, 0.64, 1.0)):
    mat = bpy.data.materials.new("Clay")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = colour
    bsdf.inputs["Roughness"].default_value = 0.45
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    return mat


def lights(power=1.0):
    for name, loc, energy in (("K", (0.6, -0.9, 0.9), 260.0),
                              ("F", (-0.9, -0.6, 0.3), 90.0),
                              ("R", (-0.2, 0.9, 0.8), 180.0)):
        data = bpy.data.lights.new(name, type="AREA")
        data.energy = energy * power
        data.size = 1.2
        o = bpy.data.objects.new(name, data)
        o.location = loc
        bpy.context.scene.collection.objects.link(o)
        c = o.constraints.new("TRACK_TO")
        c.track_axis = "TRACK_NEGATIVE_Z"
        c.up_axis = "UP_Y"
    w = bpy.data.worlds.new("W")
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.02, 0.02, 0.03, 1.0)
    bpy.context.scene.world = w


def main():
    args = parse_args()
    global PORE
    if args.target:
        PORE = Vector([float(v) for v in args.target.split(",")])
    os.makedirs(args.out, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args.glb)
    obj = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
    clay(obj)
    lights(args.power)

    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = 70.0
    cam = bpy.data.objects.new("Cam", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    bpy.context.scene.camera = cam

    scene = bpy.context.scene
    scene.render.resolution_x = args.res
    scene.render.resolution_y = args.res
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = args.samples
    scene.cycles.use_denoising = True
    scene.view_settings.view_transform = "Standard"

    views = [("flat", 0.0, 0.0), ("tilt", 28.0, 10.0), ("graze", 62.0, 4.0)]

    def shoot(suffix):
        for name, yaw, pitch in views:
            y = math.radians(yaw)
            p = math.radians(pitch)
            cam.location = PORE + Vector((
                args.dist * math.cos(p) * math.sin(y) * 1.0,
                -args.dist * math.cos(p) * math.cos(y) * 0.92,
                args.dist * math.sin(p) + args.dist * 0.38,
            ))
            d = PORE - cam.location
            cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = os.path.join(
                args.out, "%s-%s%s.png" % (args.tag, name, suffix))
            bpy.ops.render.render(write_still=True)

    shoot("")

    wf = obj.modifiers.new("wire", "WIREFRAME")
    wf.thickness = 0.0009
    wf.use_replace = False
    wf.material_offset = 1
    edge = bpy.data.materials.new("Edge")
    edge.use_nodes = True
    edge.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (
        0.02, 0.03, 0.06, 1.0)
    obj.data.materials.append(edge)
    shoot("-wire")

    with open(os.path.join(args.out, "%s.done" % args.tag), "w") as fh:
        fh.write("ok\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
