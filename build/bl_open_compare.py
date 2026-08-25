"""Open Blender with the fixed T model beside the Tripo baseline for hand review.

blender-launcher.exe --python bl_open_compare.py

Left is the original Tripo remesh, right is the current fixed mesh, both dropped
on the floor at matched height so the forehead pore and eyes can be compared by
eye. Material preview is on so the baked texture shows.
"""

import bpy
from mathutils import Vector

INSPECT = (
    r"C:\Users\wchkl\Documents\Codex\2026-08-12"
    r"\https-chatgpt-com-share-6a7b9aee-e840-2\build\inspect"
)
MODELS = [
    ("baseline-tripo", "CHAR-BASE-T-tripo-5k.glb", -0.75),
    ("current-fix", "CHAR-BASE-T-fix.glb", 0.75),
]


def bounds(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for obj in objs:
        for corner in obj.bound_box:
            p = obj.matrix_world @ Vector(corner)
            for i in range(3):
                lo[i] = min(lo[i], p[i])
                hi[i] = max(hi[i], p[i])
    return lo, hi


def load(name, filename, x_offset):
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath="%s\\%s" % (INSPECT, filename))
    fresh = [o for o in bpy.context.scene.objects if o not in before]
    meshes = [o for o in fresh if o.type == "MESH"]
    if not meshes:
        return
    lo, hi = bounds(meshes)
    scale = 1.0 / max(hi.z - lo.z, 1e-6)
    centre = (lo + hi) * 0.5

    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    for obj in fresh:
        if obj.parent is None:
            obj.parent = root
    root.scale = (scale, scale, scale)
    root.location = Vector((
        x_offset - centre.x * scale,
        -centre.y * scale,
        -lo.z * scale,
    ))


def add_lights():
    for name, loc, energy, color in (
        ("Key", (2.2, -2.6, 2.6), 800.0, (1.0, 0.96, 0.90)),
        ("Fill", (-2.8, -1.6, 1.1), 240.0, (0.55, 0.72, 1.0)),
        ("Rim", (-0.6, 3.2, 1.9), 600.0, (0.68, 0.86, 1.0)),
    ):
        data = bpy.data.lights.new(name, type="AREA")
        data.energy = energy
        data.color = color
        data.size = 3.0
        obj = bpy.data.objects.new(name, data)
        obj.location = loc
        bpy.context.scene.collection.objects.link(obj)
        track = obj.constraints.new("TRACK_TO")
        track.track_axis = "TRACK_NEGATIVE_Z"
        track.up_axis = "UP_Y"


def frame_view():
    for area in bpy.context.screen.areas:
        if area.type != "VIEW_3D":
            continue
        for space in area.spaces:
            if space.type == "VIEW_3D":
                space.shading.type = "MATERIAL"
                space.clip_start = 0.01
        for region in area.regions:
            if region.type == "WINDOW":
                with bpy.context.temp_override(area=area, region=region):
                    bpy.ops.view3d.view_all()
                break


bpy.ops.wm.read_factory_settings(use_empty=True)
for entry in MODELS:
    load(*entry)
add_lights()
frame_view()
print("OPENED baseline (left) vs fix (right)")
