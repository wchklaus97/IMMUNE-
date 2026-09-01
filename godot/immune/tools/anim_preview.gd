extends Node3D

## Animation review stage for the gel rig. Root is a Node3D with the character
## (and therefore its AnimationPlayer) underneath, which is all tools/shot.gd
## needs to sample an animation across its length.
##
## Run through the shared harness:
##   godot --path <proj> --resolution 1024x1024 res://tools/shot.tscn -- \
##     --scene=res://tools/anim_preview.tscn --out=<abs dir> --tag=t-anim \
##     --anim=idle --frames=12 [--family=T] \
##     [--body=production|legacy-glb] [--duty=fixed|mobile|relay] [--ground=0]
##
## `--body=production` (default) reviews the same authored body used by gameplay.
## `--body=legacy-glb` explicitly opts into the retired T-family GLB comparison.

const _Look := preload("res://characters/family_look.gd")

const VALID_BODY_MODES: PackedStringArray = ["production", "legacy-glb"]

const LEGACY_GLB_CANDIDATES := {
	"T": [
		"res://characters/base_t/CHAR-BASE-T-tripo-5k.glb",
		"res://characters/base_t/CHAR-BASE-T-fix.glb",
	],
}

## Height the sculpt is normalised to, matching the blockout sphere so the
## duty kits and the camera framing stay comparable between modes.
const BODY_HEIGHT := 0.90
const BODY_BOTTOM := -0.45

var _args := {}
var _character: Node3D
var _load_error := ""


func _ready() -> void:
	_parse_args()
	var family := String(_args.get("family", "T")).strip_edges().to_upper()
	var body_mode := String(_args.get("body", "production")).strip_edges().to_lower()
	var contract_error := selection_error(family, body_mode)
	if not contract_error.is_empty():
		_fail(contract_error)
		return
	var scene_path := String(_Look.SCENE_PATH[family])
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("cannot load %s" % scene_path)
		return
	_character = packed.instantiate() as Node3D
	if _character == null:
		_fail("%s is not a Node3D" % scene_path)
		return
	# add_child runs the character's _ready synchronously, so the blockout and
	# the first animation bake are done before anything below touches nodes.
	add_child(_character)
	if body_mode == "legacy-glb":
		if not _swap_in_legacy_glb(family):
			_fail("failed to load the approved legacy GLB for %s" % family)
			return
	_match_duty()
	if String(_args.get("ground", "1")) == "1":
		_add_ground()


## Duty kits are only visible in the duty they belong to, so a `uproot` or
## `relay_open` strip would otherwise show the body growing an invisible kit.
func _match_duty() -> void:
	if not _character.has_method("transform_duty"):
		return
	var requested := String(_args.get("duty", ""))
	if requested == "fixed" or requested == "mobile" or requested == "relay":
		_character.call("transform_duty", StringName(requested))
		return
	# Inferred duty makes every generated loop/edge/transform clip reviewable
	# without extra flags; combat and terminal one-shots keep the default fixed kit.
	match String(_args.get("anim", "")):
		"uproot", "move_start", "move", "move_stop":
			_character.call("transform_duty", &"mobile")
		"relay_open", "relay_glide":
			_character.call("transform_duty", &"relay")
		"plant", "relay_close":
			_character.call("transform_duty", &"fixed")


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2:
			_args[pair[0]] = pair[1]
		elif pair.size() == 1:
			_args[pair[0]] = "1"


static func selection_error(family: String, body_mode: String) -> String:
	var normalized_family := family.strip_edges().to_upper()
	var normalized_body := body_mode.strip_edges().to_lower()
	if not _Look.SCENE_PATH.has(normalized_family):
		return "unsupported family '%s'" % family
	if normalized_body not in VALID_BODY_MODES:
		return "unsupported body mode '%s'" % body_mode
	if normalized_body != "legacy-glb":
		return ""
	if not LEGACY_GLB_CANDIDATES.has(normalized_family):
		return "no approved legacy GLB exists for family %s" % normalized_family
	for path in LEGACY_GLB_CANDIDATES[normalized_family]:
		if ResourceLoader.exists(String(path)):
			return ""
	return "approved legacy GLB assets are unavailable for family %s" % normalized_family


func _fail(message: String) -> void:
	_load_error = "anim_preview: %s" % message
	push_error(_load_error)
	if _character != null:
		_character.queue_free()
		_character = null
	get_tree().quit(2)


## Parks the sculpted mesh under CoreMesh rather than replacing the node, so the
## rig keeps driving a node path the duty system and smoke test still expect.
##
## The GLB keeps its own imported material. The blockout's flat jelly override
## would erase the painted eyes and frown, and those are exactly what this
## preview exists to judge under squash. The gel surface look is P2's piece.
func _swap_in_legacy_glb(family: String) -> bool:
	var core := _character.get_node_or_null("CoreMesh") as MeshInstance3D
	if core == null:
		return false
	var sculpt := _load_sculpt(family)
	if sculpt == null:
		return false
	# Blockout stand-ins for marks the sculpt already has: interior bubbles,
	# stubby limbs and the primitive face would all read as artefacts on it.
	for child in core.get_children():
		if child is Node3D:
			(child as Node3D).visible = false
	core.mesh = null
	sculpt.name = "Sculpt"
	core.add_child(sculpt)
	_normalise(sculpt)
	var hide := ["Face", "LimbKit"]
	if String(_args.get("kits", "0")) != "1":
		hide.append("DutyKits")
	for hidden in hide:
		var node := _character.get_node_or_null(hidden) as Node3D
		if node != null:
			node.visible = false
	if _character.has_method("rebuild_gel_anims"):
		_character.call("rebuild_gel_anims")
		_character.call("play_rest")
	return true


func _load_sculpt(family: String) -> Node3D:
	for path in LEGACY_GLB_CANDIDATES.get(family, []):
		if not ResourceLoader.exists(path):
			continue
		var packed := load(path) as PackedScene
		if packed == null:
			continue
		var node := packed.instantiate() as Node3D
		if node != null:
			return node
	return null


## Fits the sculpt to the blockout's footprint: centred on X/Z, soles on the
## same plane, same overall height. Keeps camera framing honest between modes.
func _normalise(sculpt: Node3D) -> void:
	var box := _local_aabb(sculpt)
	if box.size.y <= 0.0001:
		return
	var factor := BODY_HEIGHT / box.size.y
	sculpt.scale = Vector3(factor, factor, factor)
	var centre := box.get_center()
	sculpt.position = Vector3(
		-centre.x * factor,
		BODY_BOTTOM - box.position.y * factor,
		-centre.z * factor
	)


func _local_aabb(root: Node3D) -> AABB:
	var out := AABB()
	var seeded := false
	for mi in _mesh_instances(root):
		var box: AABB = (root.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
		if seeded:
			out = out.merge(box)
		else:
			out = box
			seeded = true
	return out


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_mesh_instances(child))
	return out


## A floor pad so a reviewer can tell a hop from a scale-up. Sized inside the
## body footprint so it does not distort the harness's framing.
func _add_ground() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = 0.78
	disc.bottom_radius = 0.78
	disc.height = 0.010
	disc.radial_segments = 48
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.035, 0.045, 0.062)
	mat.roughness = 1.0
	var mi := MeshInstance3D.new()
	mi.name = "GroundPad"
	mi.mesh = disc
	mi.material_override = mat
	mi.position = Vector3(0.0, BODY_BOTTOM - 0.006, 0.0)
	add_child(mi)
