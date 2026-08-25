extends Node

## Maps catalog IDs to PackedScenes. Missing files error; never substitute another ID.

func play_skill(skill_id: StringName, host: Node3D, socket: Node3D = null) -> void:
	var specific := "res://vfx/skills/%s.tscn" % String(skill_id)
	var path := specific if ResourceLoader.exists(specific) else "res://vfx/skills/_skill_burst.tscn"
	if path != specific:
		push_warning("Missing per-ID skill VFX %s; using _skill_burst.tscn" % specific)
	var scene := _load_scene(path)
	if scene == null or host == null:
		return
	var fx: Node = scene.instantiate()
	var parent: Node3D = socket if socket != null else host
	parent.add_child(fx)


func play_select(node_id: StringName, anchor: Node) -> void:
	_play_research_ui(node_id, anchor, "select")


func play_research(node_id: StringName, anchor: Node) -> void:
	if _play_research_ui(node_id, anchor, "unlock"):
		return
	if not anchor is Node3D:
		return
	var specific := "res://vfx/research/%s.tscn" % String(node_id)
	var path := specific if ResourceLoader.exists(specific) else "res://vfx/research/_unlock_pulse.tscn"
	var scene := _load_scene(path)
	if scene == null:
		return
	anchor.add_child(scene.instantiate())


func _play_research_ui(node_id: StringName, anchor: Node, kind: String) -> bool:
	if anchor != null and anchor.has_method("spawn_feedback"):
		anchor.call("spawn_feedback", node_id, kind)
		return true
	return false


func _load_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		push_error("Missing VFX scene: %s" % path)
		return null
	return load(path) as PackedScene
