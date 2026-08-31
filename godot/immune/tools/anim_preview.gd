extends Node3D

## Animation review stage for the gel rig. Root is a Node3D with the character
## (and therefore its AnimationPlayer) underneath, which is all tools/shot.gd
## needs to sample an animation across its length.
##
## Run through the shared harness:
##   godot --path <proj> --resolution 1024x1024 res://tools/shot.tscn -- \
##     --scene=res://tools/anim_preview.tscn --out=<abs dir> --tag=t-anim \
##     --anim=idle --frames=12 [--family=T] [--body=mesh|blockout] [--ground=0]
##
## `--body=mesh` (default) puts the sculpted GLB under CoreMesh and hides the
## blockout face and limbs, so the strip shows what the head marks actually do
## under squash. `--body=blockout` keeps the primitive stand-in.

const _Look := preload("res://characters/family_look.gd")

const GLB_CANDIDATES := {
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


func _ready() -> void:
	_parse_args()
	var family := String(_args.get("family", "T"))
	var scene_path := String(_Look.SCENE_PATH.get(family, _Look.SCENE_PATH["T"]))
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("anim_preview: cannot load %s" % scene_path)
		return
	_character = packed.instantiate() as Node3D
	if _character == null:
		push_error("anim_preview: %s is not a Node3D" % scene_path)
		return
	# add_child runs the character's _ready synchronously, so the blockout and
	# the first animation bake are done before anything below touches nodes.
	add_child(_character)
	if String(_args.get("body", "mesh")) == "mesh":
		_swap_in_sculpt(family)
	_match_duty()
	if String(_args.get("ground", "1")) == "1":
		_add_ground()


## Duty kits are only visible in the duty they belong to, so a `uproot` or
## `relay_open` strip would otherwise show the body growing an invisible kit.
func _match_duty() -> void:
	if not _character.has_method("transform_duty"):
		return
	match String(_args.get("anim", "")):
		"uproot", "move":
			_character.call("transform_duty", &"mobile")
		"relay_open":
			_character.call("transform_duty", &"relay")


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2:
			_args[pair[0]] = pair[1]
		elif pair.size() == 1:
			_args[pair[0]] = "1"


## Parks the sculpted mesh under CoreMesh rather than replacing the node, so the
## rig keeps driving a node path the duty system and smoke test still expect.
##
## The GLB keeps its own imported material. The blockout's flat jelly override
## would erase the painted eyes and frown, and those are exactly what this
## preview exists to judge under squash. The gel surface look is P2's piece.
func _swap_in_sculpt(family: String) -> void:
	var core := _character.get_node_or_null("CoreMesh") as MeshInstance3D
	if core == null:
		return
	var sculpt := _load_sculpt(family)
	if sculpt == null:
		push_warning("anim_preview: no GLB for %s, staying on the blockout body" % family)
		return
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


func _load_sculpt(family: String) -> Node3D:
	for path in GLB_CANDIDATES.get(family, []):
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
