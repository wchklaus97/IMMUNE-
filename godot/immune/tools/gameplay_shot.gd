extends Node

## Headed gameplay screenshot harness for material and HUD review.
##
## Run:
##   godot --path <proj> --resolution 1920x1080 res://tools/gameplay_shot.tscn -- \
##     --out=<absolute-dir> [--family=B] [--mission=MISSION-01] [--tag=B-v2] \
##     [--locale=zh_HK|en] --portrait-expected=visible|hidden \
##     [--store-framing=on|off]

const ALLOWED_ARGS: Array[String] = [
	"out", "family", "mission", "tag", "locale", "portrait-expected", "save-path",
	"store-framing",
]
const QA_STARTUP_FAILURE_EXIT_CODE := 74
const IMAGE_SAMPLE_GRID := 16
const IMAGE_MIN_VISIBLE_SAMPLES := 16
const IMAGE_MIN_BRIGHT_SAMPLES := 4
const IMAGE_MIN_PEAK_LUMA := 0.04
const IMAGE_MIN_LUMA_RANGE := 0.02
const IMAGE_MIN_COLOUR_RANGE := 0.025
const IMAGE_MIN_LUMA_VARIANCE := 0.00002

var _args := {}
var _out_dir := ""
var _family := "B"
var _mission := "MISSION-01"
var _tag := "gameplay"
var _locale := "zh_HK"
var _portrait_expected := ""
var _store_framing := false
var _combat: Node
var _presentation_samples: Array[Dictionary] = []
var _baseline_live_scale := Vector3.ONE
var _baseline_camera_position := Vector3.ZERO
var _baseline_camera_rotation := Vector3.ZERO
var _baseline_camera_fov := 0.0
var _evidence_ok := true


func _ready() -> void:
	if _abort_for_qa_startup_failure():
		return
	if not _parse_args():
		get_tree().quit(2)
		return
	_out_dir = String(_args.get("out", ""))
	_family = String(_args.get("family", "B")).to_upper()
	_mission = String(_args.get("mission", "MISSION-01"))
	_tag = String(_args.get("tag", "%s-v2" % _family))
	_locale = String(_args.get("locale", "zh_HK"))
	_portrait_expected = String(_args.get("portrait-expected", "")).to_lower()
	var store_framing_value := String(_args.get("store-framing", "off")).to_lower()
	if not ResearchState.VALID_FAMILIES.has(_family):
		push_error("gameplay_shot.gd: unsupported --family=%s" % _family)
		get_tree().quit(2)
		return
	if not ResearchState.VALID_MISSIONS.has(_mission):
		push_error("gameplay_shot.gd: unsupported --mission=%s" % _mission)
		get_tree().quit(2)
		return
	if _locale not in ["zh_HK", "en"]:
		push_error("gameplay_shot.gd: --locale must be zh_HK or en")
		get_tree().quit(2)
		return
	if _portrait_expected not in ["visible", "hidden"]:
		push_error(
			"gameplay_shot.gd: --portrait-expected=visible|hidden is required"
		)
		get_tree().quit(2)
		return
	if store_framing_value not in ["on", "off"]:
		push_error("gameplay_shot.gd: --store-framing must be on or off")
		get_tree().quit(2)
		return
	_store_framing = store_framing_value == "on"
	if not _is_safe_tag(_tag):
		push_error(
			"gameplay_shot.gd: --tag must be a non-empty safe filename component "
			+ "using only letters, digits, '_', '-', or single interior '.' characters"
		)
		get_tree().quit(2)
		return
	TranslationServer.set_locale(_locale)
	if _out_dir.is_empty():
		push_error("gameplay_shot.gd: --out=<dir> required")
		get_tree().quit(2)
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(_out_dir)
	if directory_error != OK:
		push_error("gameplay_shot.gd: cannot create output directory %s (%d)" % [_out_dir, directory_error])
		get_tree().quit(2)
		return
	ResearchState.seed_demo()
	SettingsState.screen_shake_enabled = false
	if not ResearchState.configure_demo_run(StringName(_mission), StringName(_family)):
		push_error(
			"gameplay_shot.gd: validated selection was rejected family=%s mission=%s"
			% [_family, _mission]
		)
		get_tree().quit(2)
		return
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
	if not _loaded_selection_matches_request():
		AudioDirector.stop_all()
		_combat.queue_free()
		_combat = null
		get_tree().quit(3)
		return
	if _store_framing:
		_configure_store_camera()
	_capture_presentation_baseline()
	if _store_framing:
		await _stage_store_fixed_encounter()
	else:
		_combat.call("debug_spawn_regular")
		await _settle(1)
	# Stop gameplay simulation while leaving renderers, AnimationPlayers, and
	# one-shot particles alive long enough to finish a valid visual frame.
	_freeze_simulation()
	_restore_camera()
	# The second 3D viewport adds one bounded Metal shader/material warm-up. A
	# real-time drain prevents the fixed capture from landing before arena draws.
	await get_tree().create_timer(1.0).timeout
	await _settle(12)
	_hide_particles(_combat)
	_record_presentation_contract("fixed")
	_evidence_ok = (await _save("%s-combat-fixed.png" % _tag) == OK) and _evidence_ok
	# Mobile duty belongs to the expedition beat. Advancing the phase first also
	# refreshes the cleanse materials before Metal viewport readback.
	_combat.call("debug_advance_phase")
	await _settle(3)
	_force_visual_duty()
	if _store_framing:
		await _stage_store_mobile_encounter()
	_restore_camera()
	# Frame-count waits run far faster than real time in this harness. The duty
	# animation is one second long, so wait on the clock before readback or the
	# capture can land on a transient squash frame that obscures the arena.
	await get_tree().create_timer(1.1).timeout
	await _settle(6)
	_hide_particles(_combat)
	_record_presentation_contract("mobile")
	_evidence_ok = (await _save("%s-combat-mobile.png" % _tag) == OK) and _evidence_ok
	_combat.call("debug_advance_phase")
	await _settle(3)
	if _store_framing:
		await _stage_store_boss_encounter()
	_restore_camera()
	_freeze_simulation()
	await get_tree().create_timer(0.2).timeout
	await _settle(12)
	_hide_particles(_combat)
	_record_presentation_contract("boss")
	_evidence_ok = (await _save("%s-combat-boss.png" % _tag) == OK) and _evidence_ok
	_evidence_ok = await _capture_narrow_pause() and _evidence_ok
	if _portrait_expected == "visible":
		_evidence_ok = await _exercise_portrait_lifecycle() and _evidence_ok
	_evidence_ok = _write_presentation_report() and _evidence_ok
	AudioDirector.stop_all()
	_combat.queue_free()
	_combat = null
	# Imported bodies allocate animation libraries and shader materials at
	# runtime. Frame-only waits can finish before Compatibility's render thread,
	# so pair a bounded real-time drain with deferred frees before final sync.
	for _frame in 10:
		await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	RenderingServer.force_sync()
	await get_tree().process_frame
	if not _evidence_ok:
		push_error("gameplay_shot.gd: presentation evidence contract failed")
	get_tree().quit(0 if _evidence_ok else 1)


func _parse_args() -> bool:
	_args.clear()
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			push_error("gameplay_shot.gd: unexpected positional argument '%s'" % arg)
			return false
		var pair := arg.trim_prefix("--").split("=", true, 1)
		var key := String(pair[0])
		if key not in ALLOWED_ARGS:
			push_error("gameplay_shot.gd: unknown option --%s" % key)
			return false
		if _args.has(key):
			push_error("gameplay_shot.gd: duplicate option --%s" % key)
			return false
		if pair.size() != 2:
			push_error("gameplay_shot.gd: --%s requires a value" % key)
			return false
		_args[key] = pair[1]
	return true


func _is_safe_tag(value: String) -> bool:
	if value.is_empty() or value.length() > 128:
		return false
	if value.begins_with(".") or value.ends_with(".") or value.contains(".."):
		return false
	for index in value.length():
		var code := value.unicode_at(index)
		var is_ascii_alphanumeric := (
			(code >= 48 and code <= 57)
			or (code >= 65 and code <= 90)
			or (code >= 97 and code <= 122)
		)
		if not is_ascii_alphanumeric and code not in [45, 46, 95]:
			return false
	return true


func _abort_for_qa_startup_failure() -> bool:
	if not ResearchState.has_method("qa_startup_failed"):
		return false
	if not bool(ResearchState.call("qa_startup_failed")):
		return false
	var exit_code := QA_STARTUP_FAILURE_EXIT_CODE
	if ResearchState.has_method("qa_startup_failure_exit_code"):
		exit_code = int(ResearchState.call("qa_startup_failure_exit_code"))
	get_tree().quit(exit_code)
	return true


func _settle(frames: int) -> void:
	for _frame in frames:
		await RenderingServer.frame_post_draw


func _loaded_selection_matches_request() -> bool:
	if _combat == null or not _combat.has_method("mission_id") or not _combat.has_method("player_family"):
		push_error("gameplay_shot.gd: combat scene does not expose selection identity")
		return false
	var loaded_mission := StringName(_combat.call("mission_id"))
	var loaded_family := StringName(_combat.call("player_family"))
	if loaded_mission != StringName(_mission) or loaded_family != StringName(_family):
		push_error(
			"gameplay_shot.gd: loaded selection mismatch requested=%s/%s loaded=%s/%s"
			% [_mission, _family, String(loaded_mission), String(loaded_family)]
		)
		return false
	print("GAMEPLAY_SELECTION mission=%s family=%s" % [_mission, _family])
	return true


func _restore_camera() -> void:
	var camera_tween := _combat.get("_camera_tween") as Tween
	if camera_tween != null:
		camera_tween.kill()
		_combat.set("_camera_tween", null)
	var camera := _combat.get("_camera") as Camera3D
	if camera != null:
		camera.position = _combat.get("_camera_home")


func _configure_store_camera() -> void:
	# The production camera intentionally shows the complete lane. Steam captures
	# need a closer, still-authentic gameplay composition so characters and enemy
	# silhouettes remain legible at capsule-preview scale. This harness-only camera
	# never changes combat scenes or player settings.
	var camera := _combat.get("_camera") as Camera3D
	if camera == null:
		return
	camera.position = Vector3(0.0, 10.8, 11.8)
	camera.rotation_degrees = Vector3(-50.0, 0.0, 0.0)
	camera.fov = 54.0
	_combat.set("_camera_home", camera.position)


func _stage_store_fixed_encounter() -> void:
	var player := _combat.get("_player") as ImmuneCharacter
	if player != null:
		player.global_position = Vector3(-0.35, 0.55, 1.4)
	await _stage_store_regulars([
		Vector2(-2.45, 7.6),
		Vector2(-1.25, 6.1),
		Vector2(0.0, 8.4),
		Vector2(1.35, 5.3),
		Vector2(2.5, 7.0),
		Vector2(0.2, 4.2),
	])
	print("GAMEPLAY_STORE_STAGE fixed regulars=%d" % _store_regulars().size())


func _stage_store_mobile_encounter() -> void:
	var player := _combat.get("_player") as ImmuneCharacter
	if player != null:
		player.global_position = Vector3(-1.45, 0.55, 5.0)
	await _stage_store_regulars([
		Vector2(-2.55, 8.2),
		Vector2(-0.45, 7.3),
		Vector2(1.35, 6.0),
		Vector2(2.65, 8.4),
		Vector2(0.15, 4.0),
	])
	print("GAMEPLAY_STORE_STAGE mobile regulars=%d" % _store_regulars().size())


func _stage_store_boss_encounter() -> void:
	var player := _combat.get("_player") as ImmuneCharacter
	if player != null:
		player.global_position = Vector3(-0.85, 0.55, 1.8)
	var boss := _combat.get("_boss") as Node3D
	if boss != null:
		boss.global_position = Vector3(0.65, float(boss.get("ground_y")), 6.8)
	await _stage_store_regulars([
		Vector2(-2.45, 6.0),
		Vector2(2.65, 5.3),
		Vector2(-1.4, 8.4),
	])
	print(
		"GAMEPLAY_STORE_STAGE boss=%s escorts=%d"
		% [str(boss != null), _store_regulars().size()]
	)


func _stage_store_regulars(layout: Array[Vector2]) -> void:
	var regulars := _store_regulars()
	while regulars.size() < layout.size():
		_combat.call("debug_spawn_regular")
		await _settle(1)
		regulars = _store_regulars()
	for index in mini(regulars.size(), layout.size()):
		var enemy := regulars[index]
		var xz := layout[index]
		enemy.global_position = Vector3(xz.x, float(enemy.get("ground_y")), xz.y)


func _store_regulars() -> Array[Node3D]:
	var regulars: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("bacterium"):
		if not node is Node3D or not _combat.is_ancestor_of(node):
			continue
		var enemy := node as Node3D
		if bool(enemy.get("is_boss")):
			continue
		regulars.append(enemy)
	return regulars


func _force_visual_duty() -> void:
	# This is a presentation harness, so it must be able to review T's mobile
	# silhouette even when a fresh research save has not unlocked BASE-T-04.
	# The production toggle remains gated; only the isolated capture is forced.
	var player := _combat.get("_player") as ImmuneCharacter
	if player == null:
		return
	var target: StringName = &"relay" if player.family_id == &"A" else &"mobile"
	player.transform_duty(target)
	_combat.call("_sync_combat_portrait_duty")
	# Combat processing is frozen for deterministic evidence, so the normal duty
	# change path cannot refresh the phase header for us. Keep the visible label in
	# lockstep with the live/portrait duty recorded by the contract report.
	_combat.call("_refresh_hud")


func _capture_presentation_baseline() -> void:
	var camera := _combat.get("_camera") as Camera3D
	var player := _combat.get("_player") as ImmuneCharacter
	if camera != null:
		_baseline_camera_position = camera.position
		_baseline_camera_rotation = camera.rotation
		_baseline_camera_fov = camera.fov
	if player != null:
		_baseline_live_scale = player.scale


func _record_presentation_contract(stage: String, expected_override: String = "") -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var camera := _combat.get("_camera") as Camera3D
	var player := _combat.get("_player") as ImmuneCharacter
	var arena := _combat.get_node_or_null("ArenaVisuals") as Node3D
	var cleanse := _combat.get_node_or_null("CleanseVisuals") as Node3D
	var frame := _combat.find_child("CombatHeroPortrait", true, false) as Control
	var portrait_viewport := _combat.find_child("CombatHeroViewport", true, false) as SubViewport
	var portrait_camera := _combat.find_child("CombatHeroCamera", true, false) as Camera3D
	var portrait_character := _combat.find_child("CombatHeroCharacter", true, false) as ImmuneCharacter
	var portrait_loaded := portrait_character != null
	var portrait_visible := frame != null and frame.visible and frame.is_visible_in_tree()
	var portrait_rect := frame.get_global_rect() if frame != null else Rect2()
	# The caller declares the scenario expectation independently. Keep the
	# production predicate as separate diagnostic evidence so a regression that
	# always hides the portrait cannot validate itself.
	var scenario_expected := _portrait_expected if expected_override.is_empty() else expected_override
	var expected_visible := scenario_expected == "visible"
	var production_should_show := bool(_combat.call("_combat_portrait_should_show"))
	var collision_objects: Array[Dictionary] = []
	var collision_shapes: Array[Dictionary] = []
	if portrait_character != null:
		_collect_portrait_collision_contract(
			portrait_character, collision_objects, collision_shapes
		)
	var collision_zero := not portrait_loaded
	if portrait_loaded:
		collision_zero = not collision_objects.is_empty()
	for item in collision_objects:
		collision_zero = collision_zero and int(item["layer"]) == 0 and int(item["mask"]) == 0
	var collision_shapes_disabled := not portrait_loaded
	if portrait_loaded:
		collision_shapes_disabled = not collision_shapes.is_empty()
	for item in collision_shapes:
		collision_shapes_disabled = collision_shapes_disabled and bool(item["disabled"])
	var overlaps := _portrait_overlaps(portrait_rect, portrait_visible, viewport_size)
	var no_overlap := true
	for value in overlaps.values():
		no_overlap = no_overlap and not bool(value)
	var live_scale_unchanged := (
		player != null and player.scale.is_equal_approx(_baseline_live_scale)
	)
	var main_camera_unchanged := (
		camera != null
		and camera.position.is_equal_approx(_baseline_camera_position)
		and camera.rotation.is_equal_approx(_baseline_camera_rotation)
		and is_equal_approx(camera.fov, _baseline_camera_fov)
	)
	var family := String(portrait_character.family_id) if portrait_character != null else ""
	var duty := String(portrait_character.duty) if portrait_character != null else ""
	var sample := {
		"stage": stage,
		"scenario_expected": scenario_expected,
		"resolution": _vector2_value(viewport_size),
		"arena_meshes": arena.get_child_count() if arena != null else 0,
		"cleanse_marks": cleanse.get_child_count() if cleanse != null else 0,
		"portrait": {
			"character_instantiated": portrait_loaded,
			"rect": _rect_value(portrait_rect),
			"visible": frame.visible if frame != null else false,
			"visible_in_tree": portrait_visible,
			"expected_visible": expected_visible,
			"production_should_show": production_should_show,
			"visibility_correct": portrait_visible == expected_visible,
			"own_world_3d": portrait_viewport.own_world_3d if portrait_viewport != null else false,
			"transparent_bg": portrait_viewport.transparent_bg if portrait_viewport != null else false,
			"render_size": _vector2i_value(portrait_viewport.size) if portrait_viewport != null else [0, 0],
			"render_update_mode": int(portrait_viewport.render_target_update_mode) if portrait_viewport != null else -1,
			"msaa_3d": int(portrait_viewport.msaa_3d) if portrait_viewport != null else -1,
			"camera_fov": portrait_camera.fov if portrait_camera != null else -1.0,
			"family": family,
			"duty": duty,
			"collision_zero": collision_zero,
			"collision_shapes_disabled": collision_shapes_disabled,
			"collision_objects": collision_objects,
			"collision_shapes": collision_shapes,
			"hud_overlap": overlaps,
		},
		"live_player": {
			"family": String(player.family_id) if player != null else "",
			"duty": String(player.duty) if player != null else "",
			"scale": _vector3_value(player.scale) if player != null else [0.0, 0.0, 0.0],
			"scale_unchanged": live_scale_unchanged,
			"collision_layer": player.collision_layer if player != null else -1,
			"collision_mask": player.collision_mask if player != null else -1,
		},
		"main_camera": {
			"position": _vector3_value(camera.position) if camera != null else [0.0, 0.0, 0.0],
			"rotation": _vector3_value(camera.rotation) if camera != null else [0.0, 0.0, 0.0],
			"fov": camera.fov if camera != null else -1.0,
			"unchanged": main_camera_unchanged,
		},
		"responsive": _responsive_contract(),
		"checks": {
			"character_lifecycle_correct": portrait_loaded == expected_visible,
			"family_matches": not expected_visible or (portrait_character != null and player != null and portrait_character.family_id == player.family_id),
			"duty_matches": not expected_visible or (portrait_character != null and player != null and portrait_character.duty == player.duty),
			"own_world": portrait_viewport != null and portrait_viewport.own_world_3d,
			"camera_fov": portrait_camera != null and is_equal_approx(portrait_camera.fov, 29.5),
			"collision_zero": collision_zero and collision_shapes_disabled,
			"hidden_render_disabled": expected_visible or (portrait_viewport != null and portrait_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED),
			"portrait_process_frozen": not expected_visible or (portrait_character != null and portrait_character.process_mode == Node.PROCESS_MODE_DISABLED),
			"live_player_scale_unchanged": live_scale_unchanged,
			"main_camera_unchanged": main_camera_unchanged,
			"no_hud_overlap": no_overlap,
			"visibility_correct": portrait_visible == expected_visible,
			"production_visibility_consistent": portrait_visible == production_should_show,
			"narrow_phone_contract": _narrow_phone_contract_passes(),
		},
	}
	var sample_pass := true
	for value in (sample["checks"] as Dictionary).values():
		sample_pass = sample_pass and bool(value)
	(sample["checks"] as Dictionary)["all_pass"] = sample_pass
	_presentation_samples.append(sample)
	print("GAMEPLAY_PRESENTATION %s" % JSON.stringify(sample))


func _responsive_contract() -> Dictionary:
	if _combat != null and _combat.has_method("responsive_contract"):
		return _combat.call("responsive_contract")
	return {}


func _narrow_phone_contract_passes() -> bool:
	var physical_size := DisplayServer.window_get_size()
	if physical_size.x > 430 or physical_size.y <= physical_size.x:
		return true
	var contract := _responsive_contract()
	if contract.is_empty():
		push_error("gameplay_shot.gd: narrow phone responsive contract missing")
		return false
	if not bool(contract.get("all_pass", false)):
		push_error("gameplay_shot.gd: narrow phone responsive contract failed")
		return false
	return true


func _capture_narrow_pause() -> bool:
	var physical_size := DisplayServer.window_get_size()
	if physical_size.x > 430 or physical_size.y <= physical_size.x:
		return true
	var pause_menu := _combat.get("_pause_menu") as ImmunePauseMenu
	if pause_menu == null or not pause_menu.has_method("responsive_contract"):
		push_error("gameplay_shot.gd: pause menu missing for narrow-phone evidence")
		return false
	pause_menu.set_open(true)
	# Keep the deterministic capture coroutine advancing while retaining the
	# exact production overlay that set_open() presents to a player.
	get_tree().paused = false
	await _settle(6)
	var contract: Dictionary = pause_menu.responsive_contract()
	print("GAMEPLAY_PAUSE_RESPONSIVE %s" % JSON.stringify(contract))
	var contract_ok := bool(contract.get("all_pass", false))
	var save_ok := await _save("%s-pause.png" % _tag) == OK
	pause_menu.set_open(false)
	get_tree().paused = false
	if not contract_ok:
		push_error("gameplay_shot.gd: narrow-phone pause contract failed")
	return contract_ok and save_ok


func _exercise_portrait_lifecycle() -> bool:
	# Force a real critical-HUD geometry collision. The production signal path must
	# hide/free the optional clone, then recreate it at the live duty when restored.
	var briefing := _combat.find_child("MissionBriefingPanel", true, false) as Control
	if briefing == null:
		push_error("gameplay_shot.gd: mission briefing panel missing for portrait lifecycle check")
		return false
	var original_minimum := briefing.custom_minimum_size
	var viewport_size := get_viewport().get_visible_rect().size
	briefing.custom_minimum_size = Vector2(
		original_minimum.x,
		maxf(original_minimum.y, viewport_size.y * 0.78)
	)
	await _settle(8)
	_record_presentation_contract("hud-forced-hidden", "hidden")
	briefing.custom_minimum_size = original_minimum
	await _settle(10)
	_record_presentation_contract("hud-restored-visible", "visible")
	var hidden_sample: Dictionary = _presentation_samples[-2]
	var restored_sample: Dictionary = _presentation_samples[-1]
	return (
		bool((hidden_sample["checks"] as Dictionary).get("all_pass", false))
		and bool((restored_sample["checks"] as Dictionary).get("all_pass", false))
	)


func _portrait_overlaps(rect: Rect2, visible: bool, viewport_size: Vector2) -> Dictionary:
	var overlaps := {
		"action_tray": false,
		"mission_briefing_panel": false,
		"vitals_panel": false,
		"center_playfield": false,
	}
	if not visible:
		return overlaps
	for item in [
		["ActionTray", "action_tray"],
		["MissionBriefingPanel", "mission_briefing_panel"],
		["VitalsPanel", "vitals_panel"],
	]:
		var control := _combat.find_child(String(item[0]), true, false) as Control
		if control != null and control.is_visible_in_tree():
			overlaps[String(item[1])] = rect.intersects(control.get_global_rect())
	var center_playfield := Rect2(
		Vector2(viewport_size.x * 0.30, viewport_size.y * 0.20),
		Vector2(viewport_size.x * 0.40, viewport_size.y * 0.62)
	)
	overlaps["center_playfield"] = rect.intersects(center_playfield)
	return overlaps


func _collect_portrait_collision_contract(
	node: Node, collision_objects: Array[Dictionary], collision_shapes: Array[Dictionary]
) -> void:
	if node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		collision_objects.append({
			"path": String(_combat.get_path_to(collision_object)),
			"layer": collision_object.collision_layer,
			"mask": collision_object.collision_mask,
		})
	elif node is CollisionShape3D:
		var shape := node as CollisionShape3D
		collision_shapes.append({
			"path": String(_combat.get_path_to(shape)),
			"disabled": shape.disabled,
		})
	for child in node.get_children():
		_collect_portrait_collision_contract(child, collision_objects, collision_shapes)


func _write_presentation_report() -> bool:
	var expected_stages: Array[String] = ["fixed", "mobile", "boss"]
	if _portrait_expected == "visible":
		expected_stages.append_array(["hud-forced-hidden", "hud-restored-visible"])
	var expected_sample_count := expected_stages.size()
	var all_pass := _presentation_samples.size() == expected_sample_count
	for sample in _presentation_samples:
		all_pass = all_pass and bool((sample["checks"] as Dictionary).get("all_pass", false))
	var report := {
		"tag": _tag,
		"family": _family,
		"mission": _mission,
		"locale": _locale,
		"portrait_expected": _portrait_expected,
		"baseline": {
			"live_player_scale": _vector3_value(_baseline_live_scale),
			"main_camera_position": _vector3_value(_baseline_camera_position),
			"main_camera_rotation": _vector3_value(_baseline_camera_rotation),
			"main_camera_fov": _baseline_camera_fov,
		},
		"samples": _presentation_samples,
		"all_checks_pass": all_pass,
	}
	var path := _out_dir.path_join("%s-presentation.json" % _tag)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("gameplay_shot.gd: presentation report open failed %s" % path)
		return false
	file.store_string(JSON.stringify(report, "\t", false))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("gameplay_shot.gd: presentation report write failed %s (%d)" % [path, write_error])
		return false
	if not _validate_presentation_report(path, expected_stages):
		return false
	print("GAMEPLAY_PRESENTATION_REPORT %s" % path)
	return true


func _validate_presentation_report(path: String, expected_stages: Array[String]) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("gameplay_shot.gd: presentation report reopen failed %s" % path)
		return false
	var encoded := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK:
		push_error(
			"gameplay_shot.gd: presentation report read failed %s (%d)"
			% [path, read_error]
		)
		return false
	var json := JSON.new()
	var parse_error := json.parse(encoded)
	if parse_error != OK:
		push_error(
			"gameplay_shot.gd: presentation report JSON invalid %s line=%d error=%s"
			% [path, json.get_error_line(), json.get_error_message()]
		)
		return false
	var parsed: Variant = json.data
	if parsed is not Dictionary:
		push_error("gameplay_shot.gd: presentation report root is not a Dictionary: %s" % path)
		return false
	var report := parsed as Dictionary
	for identity in [
		["tag", _tag],
		["family", _family],
		["mission", _mission],
		["locale", _locale],
		["portrait_expected", _portrait_expected],
	]:
		var key := String(identity[0])
		var expected := String(identity[1])
		if report.get(key) is not String or String(report.get(key)) != expected:
			push_error(
				"gameplay_shot.gd: presentation report identity mismatch %s expected=%s actual=%s"
				% [key, expected, str(report.get(key))]
			)
			return false
	var report_pass: Variant = report.get("all_checks_pass")
	if report_pass is not bool or not bool(report_pass):
		push_error("gameplay_shot.gd: reopened report does not assert all_checks_pass=true")
		return false
	var samples_value: Variant = report.get("samples")
	if samples_value is not Array:
		push_error("gameplay_shot.gd: reopened report samples is not an Array")
		return false
	var samples := samples_value as Array
	if samples.size() != expected_stages.size():
		push_error(
			"gameplay_shot.gd: reopened report sample count mismatch expected=%d actual=%d"
			% [expected_stages.size(), samples.size()]
		)
		return false
	for index in samples.size():
		var sample_value: Variant = samples[index]
		if sample_value is not Dictionary:
			push_error("gameplay_shot.gd: reopened report sample %d is not a Dictionary" % index)
			return false
		var sample := sample_value as Dictionary
		var stage_value: Variant = sample.get("stage")
		if stage_value is not String or String(stage_value) != expected_stages[index]:
			push_error(
				"gameplay_shot.gd: reopened report stage mismatch index=%d expected=%s actual=%s"
				% [index, expected_stages[index], str(stage_value)]
			)
			return false
		var checks_value: Variant = sample.get("checks")
		if checks_value is not Dictionary:
			push_error("gameplay_shot.gd: reopened report sample %d has no checks Dictionary" % index)
			return false
		var sample_pass: Variant = (checks_value as Dictionary).get("all_pass")
		if sample_pass is not bool or not bool(sample_pass):
			push_error("gameplay_shot.gd: reopened report sample %d did not pass" % index)
			return false
	print(
		"GAMEPLAY_PRESENTATION_REPORT_VERIFIED tag=%s family=%s mission=%s samples=%d"
		% [_tag, _family, _mission, samples.size()]
	)
	return true


func _vector2_value(value: Vector2) -> Array[float]:
	return [value.x, value.y]


func _vector2i_value(value: Vector2i) -> Array[int]:
	return [value.x, value.y]


func _vector3_value(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _rect_value(value: Rect2) -> Dictionary:
	return {
		"position": _vector2_value(value.position),
		"size": _vector2_value(value.size),
	}


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


func _save(file_name: String) -> Error:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	# Compatibility/Metal may expose a partially copied viewport unless pending
	# rendering work is drained before CPU readback.
	RenderingServer.force_sync()
	var image := get_viewport().get_texture().get_image()
	var path := _out_dir.path_join(file_name)
	if image == null or image.is_empty():
		push_error("gameplay_shot.gd: viewport returned no image for %s" % path)
		return ERR_CANT_CREATE
	var expected_size := image.get_size()
	var err := image.save_png(path)
	if err != OK:
		push_error("gameplay_shot.gd: save failed %s (%d)" % [path, err])
		return err
	var reopened := Image.load_from_file(path)
	if reopened == null or reopened.is_empty() or reopened.get_size() != expected_size:
		push_error("gameplay_shot.gd: saved PNG cannot be reopened at expected size: %s" % path)
		return ERR_FILE_CORRUPT
	if not _validate_sampled_image_contract(reopened, path):
		return ERR_FILE_CORRUPT
	print("GAMEPLAY_SHOT %s" % path)
	return OK


func _validate_sampled_image_contract(image: Image, label: String) -> bool:
	if image == null or image.is_empty():
		push_error("gameplay_shot.gd: PNG content check received an empty image: %s" % label)
		return false
	var size := image.get_size()
	var sample_count := 0
	var visible_samples := 0
	var bright_samples := 0
	var min_luma := INF
	var max_luma := -INF
	var min_channel := INF
	var max_channel := -INF
	var luma_sum := 0.0
	var luma_square_sum := 0.0
	for grid_y in IMAGE_SAMPLE_GRID:
		var y := clampi(
			int((float(grid_y) + 0.5) * float(size.y) / float(IMAGE_SAMPLE_GRID)),
			0,
			size.y - 1
		)
		for grid_x in IMAGE_SAMPLE_GRID:
			var x := clampi(
				int((float(grid_x) + 0.5) * float(size.x) / float(IMAGE_SAMPLE_GRID)),
				0,
				size.x - 1
			)
			var colour := image.get_pixel(x, y)
			var alpha := clampf(colour.a, 0.0, 1.0)
			var luma := colour.get_luminance() * alpha
			var red := colour.r * alpha
			var green := colour.g * alpha
			var blue := colour.b * alpha
			sample_count += 1
			if alpha >= 0.05:
				visible_samples += 1
			if luma >= IMAGE_MIN_PEAK_LUMA:
				bright_samples += 1
			min_luma = minf(min_luma, luma)
			max_luma = maxf(max_luma, luma)
			min_channel = minf(min_channel, minf(red, minf(green, blue)))
			max_channel = maxf(max_channel, maxf(red, maxf(green, blue)))
			luma_sum += luma
			luma_square_sum += luma * luma
	var mean_luma := luma_sum / float(sample_count)
	var luma_variance := maxf(
		(luma_square_sum / float(sample_count)) - mean_luma * mean_luma,
		0.0
	)
	var luma_range := max_luma - min_luma
	var colour_range := max_channel - min_channel
	var valid := (
		visible_samples >= IMAGE_MIN_VISIBLE_SAMPLES
		and bright_samples >= IMAGE_MIN_BRIGHT_SAMPLES
		and max_luma >= IMAGE_MIN_PEAK_LUMA
		and luma_range >= IMAGE_MIN_LUMA_RANGE
		and colour_range >= IMAGE_MIN_COLOUR_RANGE
		and luma_variance >= IMAGE_MIN_LUMA_VARIANCE
	)
	var metrics := (
		"samples=%d visible=%d bright=%d peak=%.6f luma_range=%.6f "
		+ "colour_range=%.6f variance=%.8f"
	) % [
		sample_count,
		visible_samples,
		bright_samples,
		max_luma,
		luma_range,
		colour_range,
		luma_variance,
	]
	if not valid:
		push_error("gameplay_shot.gd: PNG is uniform, transparent, or near-blank %s (%s)" % [label, metrics])
		return false
	print("GAMEPLAY_PNG_CONTENT_OK %s %s" % [label, metrics])
	return true
