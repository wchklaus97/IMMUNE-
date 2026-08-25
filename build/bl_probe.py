import sys
import bpy

out = r"C:\Users\wchkl\Documents\Codex\2026-08-12\https-chatgpt-com-share-6a7b9aee-e840-2\build\bl_probe.txt"
with open(out, "w", encoding="utf-8") as fh:
    fh.write("version=%s\n" % (bpy.app.version_string,))
    fh.write("binary=%s\n" % (bpy.app.binary_path,))
    fh.write("python=%s\n" % (sys.version.replace("\n", " "),))
    fh.write("scripts_user=%s\n" % (bpy.utils.script_path_user(),))
    fh.write("addons=%s\n" % (",".join(sorted(bpy.context.preferences.addons.keys())),))
