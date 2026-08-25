extends Node3D

## Wet-gel material preview subject for tools/shot.tscn.
##
## Deliberately contains no lights and no WorldEnvironment: the shared shot
## harness owns the warm key / cool fill / cool rim stage, so whatever this scene
## renders is what the material really does under review lighting.
##
## Extra user args (passed through by shot.gd's `--` tail, all optional):
##   --family=T                  which palette entry to drive the uniforms with
##   --mesh=res://path.glb       force a mesh instead of the auto-pick
##   --set=uniform:value,...     one-off uniform overrides, e.g. --set=rim_energy:2.4

const _Look := preload("res://characters/family_look.gd")

## The clean Tripo remesh is the default on purpose. CHAR-BASE-T-fix.glb has torn
## geometry around the screen-left eye and a faceted pore, which the material faithfully
## renders as holes -- having it first meant every default preview and perf run was
## quietly measuring a damaged mesh. Pass --mesh= to inspect that one deliberately.
## The material itself does not care which it lands on.
const MESH_CANDIDATES: Array[String] = [
	"res://characters/base_t/CHAR-BASE-T-tripo-5k.glb",
	"res://characters/base_t/CHAR-BASE-T-fix.glb",
]

@export var family: String = "T"
@export var mesh_path: String = ""
@export var uniform_overrides: Dictionary = {}

var _materials: Array[ShaderMaterial] = []


func _ready() -> void:
	var args := _user_args()
	if args.has("family"):
		family = String(args["family"])
	if args.has("mesh"):
		mesh_path = String(args["mesh"])
	var opts := uniform_overrides.duplicate()
	if args.has("set"):
		opts.merge(_parse_overrides(String(args["set"])), true)

	var path := _pick_mesh()
	if path.is_empty():
		push_error("gel_preview.gd: no mesh found in %s" % ", ".join(MESH_CANDIDATES))
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("gel_preview.gd: cannot load %s" % path)
		return
	var subject := packed.instantiate() as Node3D
	if subject == null:
		push_error("gel_preview.gd: %s is not a Node3D scene" % path)
		return
	subject.name = "GelSubject"
	add_child(subject)
	_materials = _Look.apply_gel(subject, family, opts)
	print("GEL_PREVIEW mesh=%s family=%s surfaces=%d overrides=%s" % [path, family, _materials.size(), opts])


func _pick_mesh() -> String:
	if not mesh_path.is_empty():
		return mesh_path
	for candidate in MESH_CANDIDATES:
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


func _user_args() -> Dictionary:
	var out := {}
	for arg in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2:
			out[pair[0]] = pair[1]
	return out


## "rim_energy:2.4,body_color:#ff8a10" -> {rim_energy: 2.4, body_color: Color(...)}
## Floats and #hex colours both parse, so a look sweep can be driven from the shell.
func _parse_overrides(spec: String) -> Dictionary:
	var out := {}
	for entry in spec.split(",", false):
		var pair := entry.split(":", true, 1)
		if pair.size() != 2:
			continue
		var key := pair[0].strip_edges()
		var raw := pair[1].strip_edges()
		if raw.begins_with("#"):
			out[key] = Color.from_string(raw, Color.MAGENTA)
		elif raw.is_valid_float():
			out[key] = raw.to_float()
		else:
			out[key] = raw
	return out
