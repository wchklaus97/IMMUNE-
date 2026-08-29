extends Node

## Headed gameplay screenshot harness for material and HUD review.
##
## Run:
##   godot --path <proj> --resolution 1920x1080 res://tools/gameplay_shot.tscn -- \
##     --out=<absolute-dir> [--family=B] [--mission=MISSION-01] [--tag=B-v2] \
##     [--locale=zh_HK|en]

var _args := {}
var _out_dir := ""
var _family := "B"
var _mission := "MISSION-01"
var _tag := "gameplay"
var _locale := "zh_HK"
var _combat: Node


func _ready() -> void:
	_parse_args()
	_out_dir = String(_args.get("out", ""))
	_family = String(_args.get("family", "B")).to_upper()
	_mission = String(_args.get("mission", "MISSION-01"))
	_tag = String(_args.get("tag", "%s-v2" % _family))
	_locale = String(_args.get("locale", "zh_HK"))
	if _locale not in ["zh_HK", "en"]:
		push_error("gameplay_shot.gd: --locale must be zh_HK or en")
		get_tree().quit(2)
		return
	TranslationServer.set_locale(_locale)
	if _out_dir.is_empty():
		push_error("gameplay_shot.gd: --out=<dir> required")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_out_dir)
	ResearchState.seed_demo()
	SettingsState.screen_shake_enabled = false
	ResearchState.selected_mission_id = StringName(_mission)
	ResearchState.selected_family_id = StringName(_family)
	var packed := load("res://scenes/combat_lane.tscn") as PackedScene
	if packed == null:
		push_error("gameplay_shot.gd: combat_lane.tscn missing")
		get_tree().quit(3)
		return
	_combat = packed.instantiate()
	_combat.set("auto_spawn", false)
	_combat.set("persist_rewards", false)
	_combat.set("show_onboarding", false)
	add_child(_combat)
	await _settle(8)
	_report_presentation_contract()
	_combat.call("debug_spawn_regular")
	await _settle(1)
	# Stop gameplay simulation while leaving renderers, AnimationPlayers, and
	# one-shot particles alive long enough to finish a valid visual frame.
	_freeze_simulation()
	_restore_camera()
	await _settle(12)
	_hide_particles(_combat)
	await _save("%s-combat-fixed.png" % _tag)
	# Mobile duty belongs to the expedition beat. Advancing the phase first also
	# refreshes the cleanse materials before Metal viewport readback.
	_combat.call("debug_advance_phase")
	await _settle(3)
	_combat.call("_toggle_duty")
	_restore_camera()
	# Frame-count waits run far faster than real time in this harness. The duty
	# animation is one second long, so wait on the clock before readback or the
	# capture can land on a transient squash frame that obscures the arena.
	await get_tree().create_timer(1.1).timeout
	await _settle(6)
	_hide_particles(_combat)
	await _save("%s-combat-mobile.png" % _tag)
	_combat.call("debug_advance_phase")
	_restore_camera()
	_freeze_simulation()
	await _settle(12)
	_hide_particles(_combat)
	await _save("%s-combat-boss.png" % _tag)
	AudioDirector.stop_all()
	_combat.queue_free()
	# Imported bodies allocate animation libraries and shader materials at
	# runtime. Give deferred frees and the render thread time to release them so
	# batch QA does not report intermittent three-resource leaks at process exit.
	for _frame in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	RenderingServer.force_sync()
	_combat = null
	get_tree().quit(0)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2:
			_args[pair[0]] = pair[1]


func _settle(frames: int) -> void:
	for _frame in frames:
		await RenderingServer.frame_post_draw


func _restore_camera() -> void:
	var camera_tween := _combat.get("_camera_tween") as Tween
	if camera_tween != null:
		camera_tween.kill()
		_combat.set("_camera_tween", null)
	var camera := _combat.get("_camera") as Camera3D
	if camera != null:
		camera.position = _combat.get("_camera_home")


func _report_presentation_contract() -> void:
	var camera := _combat.get("_camera") as Camera3D
	var arena := _combat.get_node_or_null("ArenaVisuals") as Node3D
	var cleanse := _combat.get_node_or_null("CleanseVisuals") as Node3D
	var button_rects: Array[String] = []
	for property in ["_duty_button", "_intel_button", "_back_button"]:
		var button := _combat.get(property) as Button
		if button != null:
			button_rects.append("%s=%s" % [button.name, button.get_global_rect()])
	print(
		"GAMEPLAY_PRESENTATION camera_fov=%.1f arena_meshes=%d cleanse_marks=%d buttons=[%s]"
		% [
			camera.fov if camera != null else -1.0,
			arena.get_child_count() if arena != null else 0,
			cleanse.get_child_count() if cleanse != null else 0,
			", ".join(button_rects),
		]
	)


func _freeze_simulation() -> void:
	_combat.set_process(false)
	_combat.set_physics_process(false)
	for node in get_tree().get_nodes_in_group("bacterium"):
		if _combat.is_ancestor_of(node):
			node.process_mode = Node.PROCESS_MODE_DISABLED
	for node in get_tree().get_nodes_in_group("boss_pathogen"):
		if _combat.is_ancestor_of(node):
			node.process_mode = Node.PROCESS_MODE_DISABLED


func _hide_particles(node: Node) -> void:
	if node is GPUParticles3D:
		(node as GPUParticles3D).emitting = false
		(node as GPUParticles3D).visible = false
	for child in node.get_children():
		_hide_particles(child)


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	# Compatibility/Metal may expose a partially copied viewport unless pending
	# rendering work is drained before CPU readback.
	RenderingServer.force_sync()
	var image := get_viewport().get_texture().get_image()
	var path := _out_dir.path_join(file_name)
	var err := image.save_png(path)
	if err != OK:
		push_error("gameplay_shot.gd: save failed %s (%d)" % [path, err])
		return
	print("GAMEPLAY_SHOT %s" % path)
