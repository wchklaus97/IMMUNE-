extends SceneTree

const _GelProfiles := preload("res://characters/gel/gel_profiles.gd")

const CHARACTER_PATH := "res://characters/base_t/character.tscn"
const ASSET_PATH := "res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb"
const EXPECTED_SHA256 := "3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3"
const BODY_MARKER := &"v8_6_authored_sculpt"
const SHELL_MARKER := &"v8_6_single_mass_shell"
const FORBIDDEN_FALLBACK_MARKERS: PackedStringArray = [
	"v8_3_single_mass",
	"v8_4_single_mass",
	"v8_5_single_mass",
	"v8_5_authored_sculpt",
]
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
	var candidate_feature := OS.has_feature("v8_6_candidate")
	var shipping_feature := OS.has_feature("v8_6_shipping")
	if not candidate_feature and not shipping_feature:
		_fail("V8.6 candidate or shipping export feature is missing")
		return
	var configured := str(ProjectSettings.get_setting("immune/visual/gel_look", "missing"))
	if configured != "v8_6":
		_fail("shipping default drifted from v8_6 to %s" % configured)
		return
	var selected := _GelProfiles.selected_look()
	if selected != "v8_6" or not _GelProfiles.v8_6_enabled():
		_fail("candidate selector resolved to %s instead of v8_6" % selected)
		return
	var profile := _GelProfiles.profile_name("T")
	if profile != &"reference_convergence":
		_fail("T profile resolved to %s instead of reference_convergence" % profile)
		return
	if not FileAccess.file_exists(ASSET_PATH):
		_fail("raw V8.6 source is missing")
		return
	var digest := FileAccess.get_sha256(ASSET_PATH)
	if digest != EXPECTED_SHA256:
		_fail("raw V8.6 source SHA-256 drifted to %s" % digest)
		return
	var raw_asset := load(ASSET_PATH) as PackedScene
	if raw_asset == null:
		_fail("raw V8.6 source did not import as PackedScene")
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
	var failed_nodes: Array[Node] = []
	var fallback_nodes: Array[Node] = []
	_collect_meta_nodes(character, BODY_MARKER, marked_bodies)
	_collect_meta_nodes(character, SHELL_MARKER, marked_shells)
	_collect_meta_nodes(character, &"authored_body_build_failed", failed_nodes)
	for marker in FORBIDDEN_FALLBACK_MARKERS:
		_collect_meta_nodes(character, StringName(marker), fallback_nodes)
	var real_mesh := character.get_node_or_null("CoreMesh/RealMesh") as Node3D
	var loose_burst := character.get_node_or_null("KitSwapBurst") as GPUParticles3D
	var loose_burst_hidden := loose_burst != null and not loose_burst.visible and not loose_burst.emitting
	var wet_materials := (
		int(character.call(&"liquid_material_count"))
		if character.has_method(&"liquid_material_count")
		else -1
	)
	var shell_materials := (
		int(character.call(&"liquid_shell_material_count"))
		if character.has_method(&"liquid_shell_material_count")
		else -1
	)
	var animator := character.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var animation_count := animator.get_animation_list().size() if animator != null else 0
	var animations_ok := animation_count == EXPECTED_ANIMATIONS.size()
	if animations_ok:
		for animation_name in EXPECTED_ANIMATIONS:
			if not animator.has_animation(StringName(animation_name)):
				animations_ok = false
				break
	print(
		"V8_6_EXPORT_PROBE candidate=%s shipping=%s default=%s selected=%s profile=%s sha256=%s body=%d shell=%d wet=%d shell_material=%d build_failed=%d fallback=%d loose_burst_hidden=%s animations=%d animations_ok=%s"
		% [
			candidate_feature,
			shipping_feature,
			configured,
			selected,
			profile,
			digest,
			marked_bodies.size(),
			marked_shells.size(),
			wet_materials,
			shell_materials,
			failed_nodes.size(),
			fallback_nodes.size(),
			loose_burst_hidden,
			animation_count,
			animations_ok,
		]
	)
	if (
		real_mesh == null
		or not real_mesh.visible
		or marked_bodies.size() != 1
		or marked_shells.size() != 1
		or wet_materials != 1
		or shell_materials != 1
		or not failed_nodes.is_empty()
		or not fallback_nodes.is_empty()
		or not loose_burst_hidden
		or not animations_ok
	):
		_fail("single-body, material, fallback, loose-burst, or animation contract failed")
		return
	print("V8_6_EXPORT_PROBE_OK")
	character.queue_free()
	quit(0)


func _collect_meta_nodes(node: Node, marker: StringName, found: Array[Node]) -> void:
	if node.has_meta(marker):
		found.append(node)
	for child in node.get_children():
		_collect_meta_nodes(child, marker, found)


func _fail(message: String) -> void:
	push_error("V8_6_EXPORT_PROBE_FAILED: %s" % message)
	quit(1)
