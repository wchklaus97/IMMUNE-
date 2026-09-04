extends SceneTree

const CHARACTER_PATH := "res://characters/base_t/character.tscn"
const ASSET_PATH := "res://characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb"
const EXPECTED_SHA256 := "8f14cfe59a508df413e4d53218f30bbf316e7e5d31e42154b2916a0bd5669294"
const BODY_MARKER := &"v8_5_authored_sculpt"
const SHELL_MARKER := &"v8_5_single_mass_shell"
const EXPECTED_ANIMATIONS: PackedStringArray = [
	"idle",
	"plant",
	"uproot",
	"move",
	"hit",
	"attack",
	"relay_open",
	"relay_close",
	"move_start",
	"move_stop",
	"relay_glide",
	"skill_cast",
	"victory",
	"defeat",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	if not OS.has_feature("v8_5_candidate"):
		_fail("export feature v8_5_candidate is missing")
		return
	var configured := str(ProjectSettings.get_setting("immune/visual/gel_look", "missing"))
	if configured != "v8_6":
		_fail("shipping default drifted from v8_6 to %s" % configured)
		return
	if not FileAccess.file_exists(ASSET_PATH):
		_fail("raw V8.5 source is missing")
		return
	var digest := FileAccess.get_sha256(ASSET_PATH)
	if digest != EXPECTED_SHA256:
		_fail("raw V8.5 source SHA-256 drifted to %s" % digest)
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

	var marked_bodies: Array[Node] = []
	var marked_shells: Array[Node] = []
	_collect_meta_nodes(character, BODY_MARKER, marked_bodies)
	_collect_meta_nodes(character, SHELL_MARKER, marked_shells)
	var real_mesh := character.get_node_or_null("CoreMesh/RealMesh")
	var build_failed := real_mesh != null and real_mesh.has_meta(&"authored_body_build_failed")
	var loose_burst := character.get_node_or_null("KitSwapBurst") as GPUParticles3D
	var loose_burst_hidden := loose_burst != null and not loose_burst.visible and not loose_burst.emitting
	var animator := character.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var animation_count := animator.get_animation_list().size() if animator != null else 0
	var animations_ok := animation_count == EXPECTED_ANIMATIONS.size()
	if animations_ok:
		for animation_name in EXPECTED_ANIMATIONS:
			if not animator.has_animation(StringName(animation_name)):
				animations_ok = false
				break
	print(
		"V8_5_CANDIDATE_PROBE feature=%s default=%s sha256=%s body=%d shell=%d build_failed=%s loose_burst_hidden=%s animations=%d animations_ok=%s"
		% [
			OS.has_feature("v8_5_candidate"),
			configured,
			digest,
			marked_bodies.size(),
			marked_shells.size(),
			build_failed,
			loose_burst_hidden,
			animation_count,
			animations_ok,
		]
	)
	if (
		real_mesh == null
		or marked_bodies.size() != 1
		or marked_shells.size() != 1
		or build_failed
		or not loose_burst_hidden
		or not animations_ok
	):
		_fail("single-body or animation contract failed after PCK instantiation")
		return
	print("V8_5_CANDIDATE_PROBE_OK")
	character.queue_free()
	quit(0)


func _collect_meta_nodes(node: Node, marker: StringName, found: Array[Node]) -> void:
	if node.has_meta(marker):
		found.append(node)
	for child in node.get_children():
		_collect_meta_nodes(child, marker, found)


func _fail(message: String) -> void:
	push_error("V8_5_CANDIDATE_PROBE_FAILED: %s" % message)
	quit(1)
