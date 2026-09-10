extends SceneTree

const _GelProfiles := preload("res://characters/gel/gel_profiles.gd")

const CHARACTER_PATH := "res://characters/base_t/character.tscn"
const FORBIDDEN_MARKERS: PackedStringArray = [
	"v8_4_single_mass",
	"v8_5_single_mass",
	"v8_5_authored_sculpt",
	"v8_6_single_mass_shell",
	"v8_6_authored_sculpt",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	if OS.get_environment("IMMUNE_GEL_LOOK").strip_edges().to_lower() != "v8_3":
		_fail("IMMUNE_GEL_LOOK=v8_3 is required")
		return
	if _GelProfiles.selected_look() != "v8_3" or not _GelProfiles.v8_3_enabled():
		_fail("selector did not resolve exactly to v8_3")
		return
	var packed := load(CHARACTER_PATH) as PackedScene
	if packed == null:
		_fail("T character did not load as PackedScene")
		return
	var character := packed.instantiate()
	if character == null:
		_fail("T character failed to instantiate")
		return
	root.add_child(character)
	await process_frame
	await process_frame

	var rollback_bodies: Array[Node] = []
	var rollback_shells: Array[Node] = []
	var forbidden: Array[Node] = []
	_collect_meta_nodes(character, &"v8_3_single_mass", rollback_bodies)
	_collect_meta_nodes(character, &"v8_3_single_mass_shell", rollback_shells)
	for marker in FORBIDDEN_MARKERS:
		_collect_meta_nodes(character, StringName(marker), forbidden)
	var real_mesh := character.get_node_or_null("CoreMesh/RealMesh") as Node3D
	print("V8_3_ROLLBACK_PROBE selected=%s body=%d shell=%d forbidden=%d" % [
		_GelProfiles.selected_look(),
		rollback_bodies.size(),
		rollback_shells.size(),
		forbidden.size(),
	])
	if (
		real_mesh == null
		or not real_mesh.visible
		or rollback_bodies.size() != 1
		or rollback_shells.size() != 1
		or forbidden.size() != 0
	):
		_fail("exported V8.3 rollback body contract failed")
		return
	print("V8_3_ROLLBACK_PROBE_OK")
	character.queue_free()
	quit(0)


func _collect_meta_nodes(node: Node, marker: StringName, found: Array[Node]) -> void:
	if node.has_meta(marker):
		found.append(node)
	for child in node.get_children():
		_collect_meta_nodes(child, marker, found)


func _fail(message: String) -> void:
	push_error("V8_3_ROLLBACK_PROBE_FAILED: %s" % message)
	quit(1)
