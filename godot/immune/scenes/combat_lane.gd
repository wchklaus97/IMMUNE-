extends Node3D

## Data-driven mission runtime: Core Defense -> Expedition -> Total War.

signal phase_changed(phase_name: String, objective: String)
signal combat_completed(victory: bool, rewards: Dictionary)

enum Phase {
	CORE_DEFENSE,
	EXPEDITION,
	TOTAL_WAR,
	VICTORY,
	DEFEAT,
}

const _Core := preload("res://combat/immune_core.gd")
const _Bacterium := preload("res://combat/bacterium.gd")
const _Bolt := preload("res://combat/plasma_bolt.gd")
const _Tokens := preload("res://ui/research/research_tokens.gd")
const _Content := preload("res://resources/combat/combat_content.gd")
const _Look := preload("res://characters/family_look.gd")
const _PauseMenu := preload("res://ui/pause_menu.gd")
const _PlaytestTelemetry := preload("res://combat/combat_playtest_telemetry.gd")

const MISSION_SELECT_SCENE := "res://ui/mission_select/mission_select.tscn"
const NODE_FIXED := &"BASE-T-03"
const NODE_MOBILE := &"BASE-T-04"
const SPAWN_Z := 14.5
const PLAYER_HOME := Vector3(0.0, 0.55, 2.2)
const CLEANSE_CENTER := Vector3(0.0, 0.55, 7.0)
const STRAFE_LIMIT := 5.4
const REAR_LIMIT := -7.0
const FRONT_LIMIT := 8.4

@export var mission_data: ImmuneMissionData
@export var auto_spawn: bool = true
@export var persist_rewards: bool = true
@export var show_onboarding: bool = true
@export var telemetry_enabled: bool = false
@export var playtest_autopilot: bool = false
@export var playtest_build_tag: String = "local"

var current_phase: Phase = Phase.CORE_DEFENSE
var _player: ImmuneCharacter
var _family_profile: FamilyCombatProfile
var _core: _Core
var _boss: _Bacterium
var _camera: Camera3D
var _camera_home: Vector3
var _camera_tween: Tween
var _hud: Label
var _objective: Label
var _status: Label
var _core_bar: ProgressBar
var _core_value: Label
var _boss_row: Control
var _boss_bar: ProgressBar
var _boss_value: Label
var _duty_button: Button
var _intel_button: Button
var _back_button: Button
var _result_panel: PanelContainer
var _result_title: Label
var _result_body: Label
var _damage_layer: Control
var _cleanse_zone: MeshInstance3D
var _cleanse_material: StandardMaterial3D
var _pause_menu: ImmunePauseMenu
var _spawn_cd: float = 1.0
var _fire_cd: float = 0.35
var _hud_refresh_cd: float = 0.0
var _kills: int = 0
var _cleanse_progress: float = 0.0
var _over: bool = false
var _rewarded: bool = false
var _onboarding_open: bool = false
var _telemetry: CombatPlaytestTelemetry


func _ready() -> void:
	if mission_data == null:
		mission_data = _Content.load_mission(ResearchState.selected_mission_id)
	if mission_data == null:
		push_error("CombatLane: mission data is missing")
		return
	_family_profile = _Content.load_family(ResearchState.selected_family_id)
	if _family_profile == null:
		_family_profile = _Content.load_family(mission_data.recommended_family)
	if telemetry_enabled:
		_telemetry = _PlaytestTelemetry.new()
		_telemetry.begin(mission_data.id, _family_profile.family_id, playtest_build_tag)
	_build_stage()
	_build_cleanse_zone()
	_spawn_core()
	_spawn_player()
	_build_hud()
	_build_pause_menu()
	if ResearchState.has_signal("duty_unlocked"):
		ResearchState.duty_unlocked.connect(_on_duty_unlocked)
	SettingsState.input_device_changed.connect(_on_input_device_changed)
	SettingsState.settings_changed.connect(_on_settings_changed)
	AudioDirector.play_music()
	_set_phase(Phase.CORE_DEFENSE)
	if show_onboarding and not SettingsState.onboarding_seen:
		_show_onboarding()


func _on_duty_unlocked(family: StringName, _duty: StringName) -> void:
	if family == _family_profile.family_id:
		_refresh_hud()


func _on_input_device_changed(_is_gamepad: bool) -> void:
	_refresh_prompts()


func _on_settings_changed() -> void:
	_refresh_hud()
	_refresh_prompts()


func _unhandled_input(event: InputEvent) -> void:
	if _over or _onboarding_open:
		return
	if event.is_action_pressed(&"demo_toggle_duty"):
		_toggle_duty()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"demo_research"):
		_show_intel_or_research()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if _over or _onboarding_open or get_tree().paused:
		return
	_update_playtest_autopilot()
	_move_player()
	if _telemetry != null and _player != null:
		_telemetry.tick(delta, _player.duty)
	_try_fire(delta)
	_update_expedition(delta)
	if not auto_spawn:
		return
	_spawn_cd -= delta
	if _spawn_cd <= 0.0:
		var base_interval := mission_data.defense_spawn_interval if current_phase == Phase.CORE_DEFENSE else mission_data.late_spawn_interval
		_spawn_cd = base_interval * mission_data.difficulty.spawn_interval_multiplier
		if (
			current_phase != Phase.TOTAL_WAR
			or get_tree().get_nodes_in_group("bacterium").size() < mission_data.total_war_enemy_cap
		):
			_spawn_regular()


func _back_to_missions() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MISSION_SELECT_SCENE)


func _restart_mission() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _toggle_duty() -> void:
	if _player == null:
		return
	if _family_profile.family_id == &"T" and not ResearchState.is_completed(NODE_MOBILE):
		_set_status(tr("STATUS_T_MOBILE_REQUIRED") % SettingsState.prompt(&"demo_research"))
		return
	if _player.duty == &"fixed":
		_player.transform_duty(&"mobile")
		_set_status(tr("STATUS_DUTY_MOBILE"))
	else:
		_player.transform_duty(&"fixed")
		_set_status(tr("STATUS_DUTY_FIXED"))
	AudioDirector.play_sfx(&"duty")
	_refresh_hud()


func _show_intel_or_research() -> void:
	if _family_profile.family_id != &"T":
		_set_status("%s：%s" % [tr(_family_profile.role_name), tr(_family_profile.role_description)])
		return
	_research_t_chain()


func _research_t_chain() -> void:
	if not ResearchState.is_completed(NODE_FIXED):
		ResearchState.select_node(NODE_FIXED)
		if ResearchState.complete_node(NODE_FIXED):
			_set_status(tr("STATUS_T_FIXED_COMPLETE"))
		else:
			_set_status(tr("STATUS_T_FIXED_BLOCKED"))
		_refresh_hud()
		return
	if not ResearchState.is_completed(NODE_MOBILE):
		ResearchState.select_node(NODE_MOBILE)
		if ResearchState.complete_node(NODE_MOBILE):
			_set_status(tr("STATUS_T_MOBILE_COMPLETE"))
		else:
			_set_status(tr("STATUS_T_MOBILE_BLOCKED"))
		_refresh_hud()
		return
	_set_status(tr("STATUS_T_MOBILE_OWNED"))


func _move_player() -> void:
	if _player == null:
		return
	if _player.duty == &"fixed":
		_player.velocity = Vector3.ZERO
		_player.global_position.y = PLAYER_HOME.y
		return
	var move_input: Vector2 = _playtest_move_input() if playtest_autopilot else Input.get_vector(
		&"demo_move_left", &"demo_move_right", &"demo_move_back", &"demo_move_forward"
	)
	var move_speed := _family_profile.move_speed * (1.0 + ResearchState.global_stat("moveSpeed"))
	_player.velocity = Vector3(move_input.x, 0.0, move_input.y) * move_speed
	_player.move_and_slide()
	_player.global_position.y = PLAYER_HOME.y
	_player.global_position.x = clampf(_player.global_position.x, -STRAFE_LIMIT, STRAFE_LIMIT)
	_player.global_position.z = clampf(_player.global_position.z, REAR_LIMIT, FRONT_LIMIT)


func _update_playtest_autopilot() -> void:
	if not playtest_autopilot or _player == null:
		return
	var expedition_duty: StringName = &"relay" if _family_profile.family_id == &"A" else &"mobile"
	var desired_duty: StringName = expedition_duty if current_phase == Phase.EXPEDITION else &"fixed"
	if _player.duty != desired_duty:
		_player.transform_duty(desired_duty)
		if _telemetry != null:
			_telemetry.record_duty_switch()


func _playtest_move_input() -> Vector2:
	if current_phase != Phase.EXPEDITION or _player == null:
		return Vector2.ZERO
	var offset := Vector2(
		CLEANSE_CENTER.x - _player.global_position.x,
		CLEANSE_CENTER.z - _player.global_position.z
	)
	if offset.length() <= 0.18:
		return Vector2.ZERO
	return offset.normalized()


func _try_fire(delta: float) -> void:
	_fire_cd -= delta
	if _fire_cd > 0.0 or _player == null:
		return
	var target := _nearest_bacterium()
	if target == null:
		return
	var from := _muzzle()
	var aim := target.global_position - from
	var horizontal_aim := Vector3(aim.x, 0.0, aim.z)
	if horizontal_aim.length() > _family_profile.fire_range:
		return
	var base_cd := _family_profile.fixed_fire_cooldown if _player.duty == &"fixed" else _family_profile.mobile_fire_cooldown
	var speed := 1.0 + ResearchState.global_stat("attackSpeed", _player.duty)
	_fire_cd = base_cd / maxf(speed, 0.25)
	_player.look_at(_player.global_position + horizontal_aim, Vector3.UP, true)
	_player.fire_skill(StringName("SKILL-%s-ACTIVE" % String(_family_profile.family_id)))
	var bolt: _Bolt = _Bolt.new()
	bolt.configure(
		_family_profile.projectile_damage,
		_family_profile.projectile_color,
		_family_profile.family_id,
		_family_profile.hit_effect,
		_family_profile.hit_effect_power,
		_family_profile.hit_effect_cap,
		_family_profile.hit_effect_threshold
	)
	add_child(bolt)
	bolt.global_position = from
	# Keep range and body facing on the ground plane, but let the projectile
	# descend from elevated/hovering muzzles into the target collision centre.
	# Flattening this vector made CHAR-BASE-A fire above every pathogen.
	bolt.velocity = aim.normalized() * _Bolt.SPEED
	if _telemetry != null:
		_telemetry.record_shot()
	AudioDirector.play_sfx(&"shot", randf_range(0.96, 1.04), -2.0)


func _muzzle() -> Vector3:
	if _player != null and _player.weapon_socket != null:
		return _player.weapon_socket.global_position
	return _player.global_position + Vector3(0.0, 0.2, 0.55)


func _nearest_bacterium() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("bacterium"):
		if not node is Node3D:
			continue
		var body := node as Node3D
		var distance := _muzzle().distance_to(body.global_position)
		if distance < best_d:
			best_d = distance
			best = body
	return best


func _spawn_regular() -> void:
	var bug: _Bacterium = _Bacterium.new()
	bug.configure_profile(mission_data.regular_enemy, mission_data.difficulty)
	_wire_enemy(bug)
	add_child(bug)
	bug.global_position = Vector3(randf_range(-2.2, 2.2), bug.ground_y, SPAWN_Z)


func _spawn_boss() -> void:
	_boss = _Bacterium.new()
	_boss.configure_profile(mission_data.boss_enemy, mission_data.difficulty)
	_wire_enemy(_boss)
	add_child(_boss)
	_boss.global_position = Vector3(0.0, _boss.ground_y, SPAWN_Z + 1.5)
	_boss_bar.max_value = _boss.max_hp
	_boss_bar.value = _boss.hp
	_boss_value.text = "%d/%d" % [_boss.hp, _boss.max_hp]
	_boss_row.visible = true
	_boss.health_changed.connect(_on_boss_health_changed)


func _wire_enemy(enemy: _Bacterium) -> void:
	enemy.core = _core
	enemy.died.connect(_on_enemy_died)
	enemy.hit_received.connect(_on_enemy_hit)


func _on_enemy_died(was_boss: bool) -> void:
	_kills += 1
	if _telemetry != null:
		_telemetry.record_enemy_defeated(was_boss)
	if was_boss and current_phase == Phase.TOTAL_WAR:
		_victory()
	elif current_phase == Phase.CORE_DEFENSE and _kills >= mission_data.defense_kills:
		_set_phase(Phase.EXPEDITION)
	_refresh_hud()


func _on_enemy_hit(world_position: Vector3, amount: int, was_boss: bool) -> void:
	if _telemetry != null:
		_telemetry.record_hit(amount, was_boss)
	AudioDirector.play_sfx(&"hit", randf_range(0.92, 1.08), -1.0)
	_spawn_damage_number(world_position, amount, was_boss)
	_shake_camera(0.15 if was_boss else 0.07)
	if was_boss:
		for device in Input.get_connected_joypads():
			Input.start_joy_vibration(device, 0.25, 0.35, 0.12)


func _on_boss_health_changed(hp: int, max_hp: int) -> void:
	_boss_bar.max_value = max_hp
	_boss_bar.value = hp
	_boss_value.text = "%d/%d" % [hp, max_hp]


func _update_expedition(delta: float) -> void:
	if current_phase != Phase.EXPEDITION or _player == null:
		return
	var planar_distance := Vector2(_player.global_position.x, _player.global_position.z).distance_to(
		Vector2(CLEANSE_CENTER.x, CLEANSE_CENTER.z)
	)
	if _player.duty != &"fixed" and planar_distance <= 1.9:
		_cleanse_progress = minf(_cleanse_progress + delta, mission_data.cleanse_seconds)
	else:
		_cleanse_progress = maxf(_cleanse_progress - delta * 0.6, 0.0)
	_hud_refresh_cd -= delta
	if _hud_refresh_cd <= 0.0:
		_hud_refresh_cd = 0.1
		_refresh_hud()
	if _cleanse_progress >= mission_data.cleanse_seconds:
		_set_phase(Phase.TOTAL_WAR)


func _on_core_hit(hp: int, max_hp: int) -> void:
	if _telemetry != null:
		_telemetry.record_core_hp(hp, max_hp)
	_core_bar.max_value = max_hp
	_core_bar.value = hp
	_core_value.text = "%d/%d" % [hp, max_hp]
	AudioDirector.play_sfx(&"core_hit")
	_shake_camera(0.22)
	_refresh_hud()
	if hp <= 0:
		_defeat()
	elif hp < max_hp:
		_set_status(tr("STATUS_CORE_DAMAGED") % [hp, max_hp])


func _set_phase(next_phase: Phase) -> void:
	current_phase = next_phase
	if _telemetry != null:
		_telemetry.enter_phase(phase_name())
	match current_phase:
		Phase.CORE_DEFENSE:
			_spawn_cd = 0.35
			_set_status(tr("STATUS_CORE_DEFENSE") % tr(mission_data.title))
		Phase.EXPEDITION:
			_cleanse_progress = 0.0
			_set_status(tr("STATUS_EXPEDITION"))
		Phase.TOTAL_WAR:
			_clear_enemies()
			_spawn_boss()
			_set_status(tr("STATUS_TOTAL_WAR") % tr(mission_data.boss_enemy.display_name))
		Phase.VICTORY:
			_finish_victory()
		Phase.DEFEAT:
			_finish_defeat()
	_update_zone_look()
	_refresh_hud()
	AudioDirector.play_sfx(&"phase", 1.0 + float(current_phase) * 0.04)
	phase_changed.emit(phase_name(), objective_text())


func _victory() -> void:
	if not _over:
		_set_phase(Phase.VICTORY)


func _defeat() -> void:
	if not _over:
		_set_phase(Phase.DEFEAT)


func _finish_victory() -> void:
	_over = true
	if _telemetry != null:
		_telemetry.finish(true)
	if not _rewarded:
		_rewarded = true
		ResearchState.grant_mission_rewards(
			mission_data.rewards,
			mission_data.discovery_flag,
			mission_data.unlock_campaign_level,
			mission_data.id,
			persist_rewards
		)
	var reward_text := tr("RESULT_REWARDS") % [
		int(mission_data.rewards.get("antigen", 0)),
		int(mission_data.rewards.get("biomass", 0)),
		int(mission_data.rewards.get("protomass", 0)),
	]
	_show_result(tr("RESULT_VICTORY_TITLE"), "%s\n%s\n%s" % [tr(mission_data.title), tr("RESULT_VICTORY_SUMMARY"), tr("RESULT_REWARD_LINE") % reward_text])
	AudioDirector.play_sfx(&"victory")
	combat_completed.emit(true, mission_data.rewards.duplicate(true))


func _finish_defeat() -> void:
	_over = true
	if _telemetry != null:
		_telemetry.finish(false)
	_show_result(tr("RESULT_DEFEAT_TITLE"), tr("RESULT_DEFEAT_BODY") % tr(mission_data.title))
	AudioDirector.play_sfx(&"defeat")
	combat_completed.emit(false, {})


func phase_name() -> String:
	match current_phase:
		Phase.CORE_DEFENSE:
			return tr("PHASE_CORE_DEFENSE")
		Phase.EXPEDITION:
			return tr("PHASE_EXPEDITION")
		Phase.TOTAL_WAR:
			return tr("PHASE_TOTAL_WAR")
		Phase.VICTORY:
			return tr("PHASE_VICTORY")
		_:
			return tr("PHASE_DEFEAT")


func objective_text() -> String:
	match current_phase:
		Phase.CORE_DEFENSE:
			return tr("OBJECTIVE_CORE_DEFENSE") % [mini(_kills, mission_data.defense_kills), mission_data.defense_kills]
		Phase.EXPEDITION:
			return tr("OBJECTIVE_EXPEDITION") % [_cleanse_progress, mission_data.cleanse_seconds]
		Phase.TOTAL_WAR:
			return tr("OBJECTIVE_TOTAL_WAR") % tr(mission_data.boss_enemy.display_name)
		Phase.VICTORY:
			return tr("OBJECTIVE_VICTORY")
		_:
			return tr("OBJECTIVE_DEFEAT")


func debug_advance_phase() -> void:
	match current_phase:
		Phase.CORE_DEFENSE:
			_kills = mission_data.defense_kills
			_set_phase(Phase.EXPEDITION)
		Phase.EXPEDITION:
			_cleanse_progress = mission_data.cleanse_seconds
			_set_phase(Phase.TOTAL_WAR)
		Phase.TOTAL_WAR:
			_victory()


func debug_spawn_regular() -> void:
	_spawn_regular()


func mission_id() -> StringName:
	return mission_data.id if mission_data else &""


func player_family() -> StringName:
	return _family_profile.family_id if _family_profile else &""


func telemetry_snapshot() -> Dictionary:
	return _telemetry.snapshot() if _telemetry != null else {}


func debug_is_over() -> bool:
	return _over


func _clear_enemies() -> void:
	for node in get_tree().get_nodes_in_group("bacterium"):
		if node is Node and is_ancestor_of(node):
			node.queue_free()


func _build_stage() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = mission_data.background_color
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.36, 0.48, 0.58)
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_white = 4.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.8
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 30, 0)
	sun.light_color = Color(1.0, 0.83, 0.67)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-28, -145, 0)
	rim.light_color = Color(0.35, 0.58, 0.8)
	rim.light_energy = 0.38
	add_child(rim)
	_camera = Camera3D.new()
	_camera.position = Vector3(0.0, 13.8, 14.8)
	_camera.rotation_degrees = Vector3(-47, 0, 0)
	_camera.current = true
	_camera_home = _camera.position
	add_child(_camera)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(16, 0.2, 32)
	var floor_mi := MeshInstance3D.new()
	floor_mi.mesh = floor_mesh
	floor_mi.position = Vector3(0.0, -0.1, 2.0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = mission_data.floor_color
	floor_mat.roughness = 0.92
	floor_mi.material_override = floor_mat
	floor_body.add_child(floor_mi)
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(16, 0.2, 32)
	var floor_col := CollisionShape3D.new()
	floor_col.shape = floor_shape
	floor_col.position = Vector3(0.0, -0.1, 2.0)
	floor_body.add_child(floor_col)
	add_child(floor_body)
	var lane := MeshInstance3D.new()
	var lane_mesh := BoxMesh.new()
	lane_mesh.size = Vector3(2.4, 0.04, 26)
	lane.mesh = lane_mesh
	lane.position = Vector3(0.0, 0.02, 2.0)
	var lane_mat := StandardMaterial3D.new()
	lane_mat.albedo_color = mission_data.lane_color
	lane_mat.emission_enabled = true
	lane_mat.emission = mission_data.lane_color.darkened(0.2)
	lane_mat.emission_energy_multiplier = 0.14
	lane.material_override = lane_mat
	add_child(lane)


func _build_cleanse_zone() -> void:
	_cleanse_zone = MeshInstance3D.new()
	_cleanse_zone.name = "CleanseZone"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.0
	mesh.bottom_radius = 2.0
	mesh.height = 0.035
	_cleanse_zone.mesh = mesh
	_cleanse_zone.position = Vector3(CLEANSE_CENTER.x, 0.045, CLEANSE_CENTER.z)
	_cleanse_material = StandardMaterial3D.new()
	_cleanse_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cleanse_material.albedo_color = Color(mission_data.zone_color, 0.12)
	_cleanse_material.emission_enabled = true
	_cleanse_material.emission = mission_data.zone_color
	_cleanse_material.emission_energy_multiplier = 0.18
	_cleanse_zone.material_override = _cleanse_material
	add_child(_cleanse_zone)


func _update_zone_look() -> void:
	if _cleanse_material == null:
		return
	var active := current_phase == Phase.EXPEDITION
	_cleanse_material.albedo_color = Color(mission_data.zone_color, 0.34 if active else 0.08)
	_cleanse_material.emission_energy_multiplier = 0.75 if active else 0.12


func _spawn_core() -> void:
	_core = _Core.new()
	_core.position = Vector3(0.0, 0.7, -10.2)
	_core.hp_changed.connect(_on_core_hit)
	_core.breached.connect(_defeat)
	add_child(_core)
	if _telemetry != null:
		_telemetry.record_core_hp(_core.hp, _Core.MAX_HP)


func _spawn_player() -> void:
	var path := str(_Look.SCENE_PATH.get(String(_family_profile.family_id), _Look.SCENE_PATH["T"]))
	var scene := load(path) as PackedScene
	if scene == null:
		push_error("CombatLane: missing family scene %s" % path)
		return
	_player = scene.instantiate() as ImmuneCharacter
	if _player == null:
		push_error("CombatLane: family scene did not instantiate ImmuneCharacter")
		return
	_player.position = PLAYER_HOME
	add_child(_player)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	var top_margin := MarginContainer.new()
	top_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_margin.add_theme_constant_override("margin_left", 24)
	top_margin.add_theme_constant_override("margin_top", 18)
	top_margin.add_theme_constant_override("margin_right", 24)
	layer.add_child(top_margin)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 24)
	top_margin.add_child(top_row)
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 6)
	top_row.add_child(panel)
	_hud = Label.new()
	_hud.add_theme_font_size_override("font_size", 21)
	_hud.add_theme_color_override("font_color", _Tokens.TEXT)
	panel.add_child(_hud)
	_objective = Label.new()
	_objective.add_theme_font_size_override("font_size", 18)
	_objective.add_theme_color_override("font_color", _Tokens.GOLD)
	panel.add_child(_objective)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_color", _Tokens.CYAN)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_status)
	var vitals := VBoxContainer.new()
	vitals.custom_minimum_size.x = 340
	top_row.add_child(vitals)
	var core_row := HBoxContainer.new()
	vitals.add_child(core_row)
	var core_label := Label.new()
	core_label.text = "UI_IMMUNE_CORE"
	core_label.custom_minimum_size.x = 90
	core_row.add_child(core_label)
	_core_bar = ProgressBar.new()
	_core_bar.show_percentage = false
	_core_bar.step = 0.0
	_core_bar.max_value = _Core.MAX_HP
	_core_bar.value = _Core.MAX_HP
	_core_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	core_row.add_child(_core_bar)
	_core_value = Label.new()
	_core_value.text = "%d/%d" % [_Core.MAX_HP, _Core.MAX_HP]
	core_row.add_child(_core_value)
	_boss_row = HBoxContainer.new()
	_boss_row.visible = false
	vitals.add_child(_boss_row)
	var boss_label := Label.new()
	boss_label.text = "Boss"
	boss_label.custom_minimum_size.x = 90
	_boss_row.add_child(boss_label)
	_boss_bar = ProgressBar.new()
	_boss_bar.show_percentage = false
	_boss_bar.step = 0.0
	_boss_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_row.add_child(_boss_bar)
	_boss_value = Label.new()
	_boss_row.add_child(_boss_value)
	var bottom_margin := MarginContainer.new()
	bottom_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_margin.add_theme_constant_override("margin_left", 24)
	bottom_margin.add_theme_constant_override("margin_right", 24)
	bottom_margin.add_theme_constant_override("margin_bottom", 18)
	layer.add_child(bottom_margin)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	bottom_margin.add_child(actions)
	_duty_button = Button.new()
	_duty_button.custom_minimum_size = Vector2(220, 48)
	_duty_button.pressed.connect(_toggle_duty)
	actions.add_child(_duty_button)
	_intel_button = Button.new()
	_intel_button.custom_minimum_size = Vector2(220, 48)
	_intel_button.pressed.connect(_show_intel_or_research)
	actions.add_child(_intel_button)
	_back_button = Button.new()
	_back_button.custom_minimum_size = Vector2(220, 48)
	_back_button.pressed.connect(_back_to_missions)
	actions.add_child(_back_button)
	_damage_layer = Control.new()
	_damage_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_damage_layer)
	var result_center := CenterContainer.new()
	result_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(result_center)
	_result_panel = PanelContainer.new()
	_result_panel.visible = false
	_result_panel.custom_minimum_size = Vector2(680, 320)
	result_center.add_child(_result_panel)
	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 14)
	_result_panel.add_child(result_box)
	_result_title = Label.new()
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.add_theme_font_size_override("font_size", 34)
	result_box.add_child(_result_title)
	_result_body = Label.new()
	_result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_body.add_theme_font_size_override("font_size", 19)
	result_box.add_child(_result_body)
	var retry_button := Button.new()
	retry_button.text = "UI_RETRY"
	retry_button.pressed.connect(_restart_mission)
	result_box.add_child(retry_button)
	var return_button := Button.new()
	return_button.text = "UI_RETURN_MISSIONS"
	return_button.pressed.connect(_back_to_missions)
	result_box.add_child(return_button)
	_refresh_prompts()


func _build_pause_menu() -> void:
	_pause_menu = _PauseMenu.new() as ImmunePauseMenu
	add_child(_pause_menu)
	_pause_menu.restart_requested.connect(_restart_mission)
	_pause_menu.research_requested.connect(_back_to_missions)


func _refresh_hud() -> void:
	if _hud == null or _core == null or _family_profile == null:
		return
	var duty := tr("DUTY_FIXED") if _player == null or _player.duty == &"fixed" else (tr("DUTY_RELAY") if _player.duty == &"relay" else tr("DUTY_MOBILE"))
	_hud.text = tr("UI_COMBAT_HUD") % [tr(mission_data.title), tr(str(_Look.DISPLAY_NAME.get(String(_family_profile.family_id), String(_family_profile.family_id)))), duty]
	_objective.text = objective_text()
	if _duty_button:
		_duty_button.disabled = _over


func _refresh_prompts() -> void:
	if _duty_button:
		_duty_button.text = tr("UI_TOGGLE_DUTY") % SettingsState.prompt(&"demo_toggle_duty")
	if _intel_button:
		_intel_button.text = "%s · %s" % [SettingsState.prompt(&"demo_research"), tr("UI_RESEARCH_T") if _family_profile and _family_profile.family_id == &"T" else tr("UI_CHARACTER_INTEL")]
	if _back_button:
		_back_button.text = tr("UI_RETURN_MISSION_DESK")


func _set_status(text: String) -> void:
	if _status:
		_status.text = text


func _show_result(title: String, body: String) -> void:
	_result_title.text = title
	_result_body.text = body
	_result_panel.visible = true


func _spawn_damage_number(world_position: Vector3, amount: int, critical: bool) -> void:
	if _camera == null or _damage_layer == null or _camera.is_position_behind(world_position):
		return
	var label := Label.new()
	label.text = "-%d" % amount
	label.position = _camera.unproject_position(world_position + Vector3(0.0, 0.8, 0.0))
	label.add_theme_font_size_override("font_size", 28 if critical else 21)
	label.add_theme_color_override("font_color", _Tokens.GOLD if critical else Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_layer.add_child(label)
	var duration := 0.35 if SettingsState.reduced_motion else 0.7
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - (24.0 if SettingsState.reduced_motion else 58.0), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(label.queue_free)


func _shake_camera(strength: float) -> void:
	if _camera == null or not SettingsState.screen_shake_enabled or SettingsState.reduced_motion:
		return
	if _camera_tween:
		_camera_tween.kill()
	_camera.position = _camera_home + Vector3(randf_range(-strength, strength), randf_range(-strength, strength), 0.0)
	_camera_tween = create_tween()
	_camera_tween.tween_property(_camera, "position", _camera_home, 0.16).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _show_onboarding() -> void:
	_onboarding_open = true
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.008, 0.018, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 460)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := Label.new()
	title.text = "UI_TUTORIAL_TITLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)
	var body := Label.new()
	body.text = (tr("UI_TUTORIAL_BODY") % [SettingsState.prompt(&"demo_toggle_duty"), SettingsState.prompt(&"demo_pause")]).replace("\\n", "\n")
	body.add_theme_font_size_override("font_size", 21)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	var confirm := Button.new()
	confirm.text = tr("UI_TUTORIAL_START") % SettingsState.prompt(&"demo_confirm")
	confirm.custom_minimum_size.y = 56
	confirm.pressed.connect(func() -> void:
		_onboarding_open = false
		SettingsState.mark_onboarding_seen()
		layer.queue_free()
	)
	box.add_child(confirm)
	confirm.grab_focus()
