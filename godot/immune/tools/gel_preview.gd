extends Node3D

## Wet-gel production preview subject for tools/shot.tscn.
##
## The default is the exact authored reference body used by the selected family.
## `--source=character` instantiates the complete production CharacterBody3D, while
## excluded Meshy/Tripo assets are available only through the deliberately noisy
## `--source=legacy-glb --mesh=<known path>` diagnostic contract.
##
## Extra user args (passed through by shot.gd's `--` tail, all optional):
##   --family=T
##   --source=reference|character|legacy-glb
##   --mesh=res://...            production scene override, or required legacy GLB
##   --set=uniform:value,...     verified wet-gel/shell overrides

const _Look := preload("res://characters/family_look.gd")

const WET_SHADER_PATH := "res://characters/gel/wet_gel.gdshader"
const SHELL_SHADER_PATH := "res://characters/gel/jelly_shell.gdshader"

const FAMILIES: PackedStringArray = ["T", "B", "M", "N", "A", "D"]
const VALID_SOURCES: PackedStringArray = ["reference", "character", "legacy-glb"]
const REFERENCE_SCENES := {
	"T": "res://characters/base_t/reference_body.tscn",
	"B": "res://characters/base_b/reference_body.tscn",
	"M": "res://characters/base_m/authored_body.tscn",
	"N": "res://characters/base_n/reference_body.tscn",
	"A": "res://characters/base_a/reference_body.tscn",
	"D": "res://characters/base_d/reference_body.tscn",
}
const LEGACY_GLB_SCENES := {
	"T": [
		"res://characters/base_t/CHAR-BASE-T-tripo-5k.glb",
		"res://characters/base_t/CHAR-BASE-T-fix.glb",
	],
	"B": ["res://characters/base_b/CHAR-BASE-B-meshy-t2.glb"],
	"M": ["res://characters/base_m/CHAR-BASE-M-meshy-t2.glb"],
}
const MEMBRANE_SET_ALIASES := {
	"membrane_face_alpha": "face_alpha",
	"membrane_edge_alpha": "edge_alpha",
	"membrane_edge_power": "edge_power",
	"membrane_roughness": "shell_roughness",
	"membrane_rim_emission": "rim_emission",
	"membrane_thickness": "shell_thickness",
}
const RUNTIME_MANAGED_CONTROLS: PackedStringArray = [
	"liquid_flow_motion_mix",
	"liquid_flow_direction",
	"liquid_body_deform_strength",
	"liquid_body_lag",
	"liquid_body_squash",
	"liquid_turn_shear",
	"liquid_contact_amount",
	"liquid_contact_normal",
]
const ALLOWED_ARGS: PackedStringArray = [
	# Subject controls.
	"family", "source", "mesh", "set",
	# tools/shot.gd-owned controls visible through OS.get_cmdline_user_args().
	"scene", "out", "tag", "anim", "frames", "height-scale", "height-depth",
	"yaw-sequence", "flow-seconds", "flow-velocity", "flow-velocity-sequence", "save-path",
]

@export_enum("T", "B", "M", "N", "A", "D") var family := "T"
@export_enum("reference", "character", "legacy-glb") var source := "reference"
@export var mesh_path := ""
@export var uniform_overrides: Dictionary = {}

var _materials: Array[ShaderMaterial] = []
var _shell_materials: Array[ShaderMaterial] = []
var _shell_meshes: Array[MeshInstance3D] = []
var _subject_path := ""


func _ready() -> void:
	var parsed_args := _user_args()
	if not bool(parsed_args.get("ok", false)):
		return
	var args := parsed_args.get("args", {}) as Dictionary
	if not _configure_source(args):
		return

	var packed := load(_subject_path) as PackedScene
	if packed == null:
		_fail("cannot load %s" % _subject_path)
		return
	var subject := packed.instantiate() as Node3D
	if subject == null:
		_fail("%s is not a Node3D scene" % _subject_path)
		return
	subject.name = "GelSubject"
	add_child(subject)

	if source == "legacy-glb":
		_materials = _Look.apply_gel(subject, family)
	else:
		_materials = _shader_materials(subject, WET_SHADER_PATH)
	_shell_materials = _shader_materials(subject, SHELL_SHADER_PATH)
	_shell_meshes = _mesh_instances_using_shader(subject, SHELL_SHADER_PATH)
	if _materials.is_empty():
		_fail("%s produced no production wet-gel materials" % _subject_path)
		return

	var raw_overrides: Variant = _normalized_export_overrides()
	if raw_overrides == null:
		return
	var overrides: Dictionary = raw_overrides as Dictionary
	if args.has("set"):
		var parsed_overrides := _parse_overrides(String(args["set"]))
		if not bool(parsed_overrides.get("ok", false)):
			return
		overrides.merge(parsed_overrides["values"] as Dictionary, true)
	if not _apply_verified_overrides(overrides):
		_materials.clear()
		return

	print(
		"GEL_PREVIEW source=%s scene=%s family=%s wet_materials=%d shell_materials=%d overrides=%s"
		% [source, _subject_path, family, _materials.size(), _shell_materials.size(), overrides]
	)


func _configure_source(args: Dictionary) -> bool:
	if args.has("family"):
		family = String(args["family"]).strip_edges().to_upper()
	if family not in FAMILIES:
		_fail("--family must be one of %s" % ",".join(FAMILIES))
		return false
	if args.has("source"):
		source = String(args["source"]).strip_edges().to_lower()
	if source not in VALID_SOURCES:
		_fail("--source must be reference, character, or legacy-glb")
		return false
	if args.has("mesh"):
		mesh_path = String(args["mesh"]).strip_edges()

	if source == "legacy-glb":
		if mesh_path.is_empty():
			_fail("--source=legacy-glb requires an explicit --mesh=<known excluded GLB>")
			return false
		var allowed_legacy: Array = LEGACY_GLB_SCENES.get(family, [])
		if mesh_path not in allowed_legacy:
			_fail("--mesh is not an approved %s legacy diagnostic GLB" % family)
			return false
		_subject_path = mesh_path
	else:
		var expected := (
			String(REFERENCE_SCENES[family])
			if source == "reference"
			else String(_Look.SCENE_PATH[family])
		)
		if not mesh_path.is_empty():
			var reference_path := String(REFERENCE_SCENES[family])
			var character_path := String(_Look.SCENE_PATH[family])
			if mesh_path == reference_path:
				if args.has("source") and source != "reference":
					_fail("--source and production --mesh identify different subjects")
					return false
				source = "reference"
			elif mesh_path == character_path:
				if args.has("source") and source != "character":
					_fail("--source and production --mesh identify different subjects")
					return false
				source = "character"
			else:
				_fail(
					"production --mesh must equal the selected family's reference or character scene; "
					+ "excluded GLBs require --source=legacy-glb"
				)
				return false
			expected = mesh_path
		_subject_path = expected
	if not ResourceLoader.exists(_subject_path):
		_fail("subject does not exist: %s" % _subject_path)
		return false
	return true


func _override_contract() -> Dictionary:
	var contract := _shader_control_contract(_materials)
	contract.erase("use_feature_tex")
	contract["membrane_enabled"] = {"type": TYPE_BOOL}
	var shell_contract := _shader_control_contract(_shell_materials)
	for alias in MEMBRANE_SET_ALIASES:
		var shell_name := String(MEMBRANE_SET_ALIASES[alias])
		if not shell_contract.has(shell_name):
			_fail("production shell schema is missing '%s'" % shell_name)
			return {}
		contract[alias] = shell_contract[shell_name]
	return contract


func _shader_control_contract(materials: Array[ShaderMaterial]) -> Dictionary:
	var controls := {}
	for material in materials:
		if material.shader == null:
			continue
		for raw_property in material.shader.get_shader_uniform_list(false):
			var property := raw_property as Dictionary
			var name := String(property.get("name", ""))
			var type := int(property.get("type", TYPE_NIL))
			if name.is_empty() or type not in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_COLOR]:
				continue
			controls[name] = {"type": type}
	return controls


func _normalized_export_overrides() -> Variant:
	var contract := _override_contract()
	if contract.is_empty():
		return null
	var normalized := {}
	for raw_key in uniform_overrides:
		var key := String(raw_key).strip_edges()
		if key.is_empty() or not contract.has(key):
			_fail("unknown or unsupported exported override '%s'" % key)
			return null
		var value: Variant = uniform_overrides[raw_key]
		if not _value_matches_control(value, contract[key] as Dictionary):
			_fail("exported override '%s' has the wrong value type" % key)
			return null
		normalized[key] = value
	return normalized


func _parse_overrides(spec: String) -> Dictionary:
	if spec.strip_edges().is_empty():
		_fail("--set requires name:value entries")
		return {"ok": false}
	var contract := _override_contract()
	if contract.is_empty():
		return {"ok": false}
	var values := {}
	for entry in spec.split(",", true):
		var pair := entry.split(":", true, 1)
		if pair.size() != 2 or String(pair[0]).strip_edges().is_empty():
			_fail("malformed --set entry '%s'" % entry)
			return {"ok": false}
		var key := String(pair[0]).strip_edges()
		if not contract.has(key):
			_fail("unknown or unsupported --set control '%s'" % key)
			return {"ok": false}
		if values.has(key):
			_fail("duplicate --set control '%s'" % key)
			return {"ok": false}
		var parsed := _parse_control_value(key, String(pair[1]).strip_edges(), contract[key])
		if not bool(parsed.get("ok", false)):
			return {"ok": false}
		values[key] = parsed["value"]
	return {"ok": true, "values": values}


func _parse_control_value(key: String, raw: String, control: Dictionary) -> Dictionary:
	var type := int(control.get("type", TYPE_NIL))
	if type == TYPE_BOOL:
		var lowered := raw.to_lower()
		if lowered not in ["true", "false"]:
			_fail("--set control '%s' requires true or false" % key)
			return {"ok": false}
		return {"ok": true, "value": lowered == "true"}
	if type == TYPE_COLOR:
		if not Color.html_is_valid(raw):
			_fail("--set control '%s' requires an HTML colour" % key)
			return {"ok": false}
		return {"ok": true, "value": Color.from_string(raw, Color.MAGENTA)}
	if type in [TYPE_INT, TYPE_FLOAT]:
		if raw.is_empty() or not raw.is_valid_float():
			_fail("--set control '%s' requires a finite number" % key)
			return {"ok": false}
		var value := float(raw)
		if not is_finite(value):
			_fail("--set control '%s' requires a finite number" % key)
			return {"ok": false}
		return {"ok": true, "value": int(value) if type == TYPE_INT else value}
	_fail("--set control '%s' has an unsupported type" % key)
	return {"ok": false}


func _value_matches_control(value: Variant, control: Dictionary) -> bool:
	var type := int(control.get("type", TYPE_NIL))
	if type == TYPE_BOOL:
		return value is bool
	if type == TYPE_COLOR:
		return value is Color
	if type == TYPE_INT:
		return value is int
	if type == TYPE_FLOAT:
		return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))
	return false


func _apply_verified_overrides(overrides: Dictionary) -> bool:
	if source == "character":
		for control in RUNTIME_MANAGED_CONTROLS:
			if overrides.has(control):
				_fail(
					"--set control '%s' is runtime-managed in --source=character; " % control
					+ "use --source=reference for a static material ablation"
				)
				return false
	if overrides.has("membrane_enabled"):
		var membrane_enabled := bool(overrides["membrane_enabled"])
		if not membrane_enabled:
			for alias in MEMBRANE_SET_ALIASES:
				if overrides.has(alias):
					_fail("--set control '%s' requires membrane_enabled=true" % alias)
					return false
			_set_membrane_enabled(false)
		elif not _membrane_is_enabled():
			_fail("membrane_enabled=true requested, but the subject has no production membrane")
			return false

	for raw_key in overrides:
		var key := String(raw_key)
		if key == "membrane_enabled":
			continue
		var targets: Array[ShaderMaterial] = _materials
		var shader_name := String(key)
		if MEMBRANE_SET_ALIASES.has(key):
			targets = _shell_materials
			shader_name = String(MEMBRANE_SET_ALIASES[key])
		if targets.is_empty():
			_fail("--set control '%s' has no material target" % key)
			return false
		var applied := 0
		for material in targets:
			if material.get_shader_parameter(shader_name) == null:
				continue
			material.set_shader_parameter(shader_name, overrides[key])
			if not _values_equal(material.get_shader_parameter(shader_name), overrides[key]):
				_fail("--set control '%s' did not survive material application" % key)
				return false
			applied += 1
		if applied == 0:
			_fail("--set control '%s' is not exposed by the measured materials" % key)
			return false
	if overrides.has("membrane_enabled"):
		if _membrane_is_enabled() != bool(overrides["membrane_enabled"]):
			_fail("applied membrane_enabled does not match request")
			return false
	return true


func _set_membrane_enabled(enabled: bool) -> void:
	for mesh in _shell_meshes:
		mesh.visible = enabled
	if enabled:
		return
	for material in _materials:
		if _material_uses_shader(material.next_pass, SHELL_SHADER_PATH):
			material.next_pass = null


func _membrane_is_enabled() -> bool:
	for mesh in _shell_meshes:
		if mesh.is_visible_in_tree():
			return true
	for material in _materials:
		if _material_uses_shader(material.next_pass, SHELL_SHADER_PATH):
			return true
	return false


func _values_equal(actual: Variant, expected: Variant) -> bool:
	if expected is bool:
		return actual is bool and bool(actual) == bool(expected)
	if expected is Color:
		return actual is Color and (actual as Color).is_equal_approx(expected as Color)
	if typeof(expected) in [TYPE_INT, TYPE_FLOAT]:
		return typeof(actual) in [TYPE_INT, TYPE_FLOAT] and is_equal_approx(float(actual), float(expected))
	return actual == expected


func _shader_materials(root: Node, shader_path: String) -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	var seen := {}
	for mesh in _mesh_instances(root):
		_append_shader_material(mesh.material_override, shader_path, out, seen)
		_append_shader_material(mesh.material_overlay, shader_path, out, seen)
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			_append_shader_material(mesh.get_active_material(surface), shader_path, out, seen)
	return out


func _append_shader_material(
	material: Material,
	shader_path: String,
	out: Array[ShaderMaterial],
	seen: Dictionary
) -> void:
	if material == null:
		return
	var instance_id := material.get_instance_id()
	if seen.has(instance_id):
		return
	seen[instance_id] = true
	if _material_uses_shader(material, shader_path):
		out.append(material as ShaderMaterial)
	_append_shader_material(material.next_pass, shader_path, out, seen)


func _mesh_instances_using_shader(root: Node, shader_path: String) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for mesh in _mesh_instances(root):
		var direct := _material_uses_shader(mesh.material_override, shader_path)
		direct = direct or _material_uses_shader(mesh.material_overlay, shader_path)
		if not direct and mesh.mesh != null:
			for surface in mesh.mesh.get_surface_count():
				if _material_uses_shader(mesh.get_active_material(surface), shader_path):
					direct = true
					break
		if direct:
			out.append(mesh)
	return out


func _material_uses_shader(material: Material, shader_path: String) -> bool:
	return (
		material is ShaderMaterial
		and (material as ShaderMaterial).shader != null
		and (material as ShaderMaterial).shader.resource_path == shader_path
	)


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_mesh_instances(child))
	return out


func _user_args() -> Dictionary:
	var parsed := parse_user_args(OS.get_cmdline_user_args())
	if not bool(parsed.get("ok", false)):
		_fail(String(parsed.get("error", "invalid command-line arguments")))
		return {"ok": false}
	return parsed


static func parse_user_args(raw_args: PackedStringArray) -> Dictionary:
	var out := {}
	for arg in raw_args:
		if not arg.begins_with("--"):
			return {"ok": false, "error": "unexpected positional argument '%s'" % arg}
		var pair := arg.trim_prefix("--").split("=", true, 1)
		var key := String(pair[0])
		if key not in ALLOWED_ARGS:
			return {"ok": false, "error": "unknown option --%s" % key}
		if out.has(key):
			return {"ok": false, "error": "duplicate option --%s" % key}
		if pair.size() != 2:
			return {"ok": false, "error": "--%s requires a value" % key}
		out[key] = pair[1]
	return {"ok": true, "args": out}


func _fail(message: String) -> void:
	_materials.clear()
	push_error("gel_preview.gd: %s" % message)
	get_tree().quit(2)
