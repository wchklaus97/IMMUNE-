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
const _LightContract := preload("res://characters/gel/light_contract.gd")
const _PauseMenu := preload("res://ui/pause_menu.gd")
const _PlaytestTelemetry := preload("res://combat/combat_playtest_telemetry.gd")
const _Responsive := preload("res://ui/responsive_layout.gd")
const _ActiveSkillController := preload("res://combat/active_skill_controller.gd")
const _EncounterDirector := preload("res://combat/combat_encounter_director.gd")
const _TouchControls := preload("res://ui/combat_touch_controls.gd")

const MISSION_SELECT_SCENE := "res://ui/mission_select/mission_select.tscn"
const NODE_FIXED := &"BASE-T-03"
const NODE_MOBILE := &"BASE-T-04"
const SPAWN_Z := 14.5
const PLAYER_HOME := Vector3(0.0, 0.55, 2.2)
const CLEANSE_CENTER := Vector3(0.0, 0.55, 7.0)
const STRAFE_LIMIT := 5.4
const REAR_LIMIT := -7.0
const FRONT_LIMIT := 8.4
const PORTRAIT_RENDER_SIZE := Vector2i(336, 252)
const PORTRAIT_DISPLAY_SIZE := Vector2(344.0, 260.0)
const PORTRAIT_LEFT_MARGIN := 24.0
const PORTRAIT_BOTTOM_CLEARANCE := 108.0
const PORTRAIT_MIN_VIEWPORT := Vector2(1200.0, 620.0)
const PORTRAIT_MIN_ASPECT := 1.45
const PORTRAIT_SCALE := {
	"T": 1.72,
	"B": 1.58,
	"M": 1.32,
	"N": 1.62,
	"A": 1.32,
	"D": 1.36,
}
const PORTRAIT_Y := {
	"B": 0.64,
}
const HUD_BASE_FONT_SIZE := 16

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
var _hud_root: Control
var _hud_theme: Theme
var _hud_layout_scale: float = 1.0
var _hud_layout_narrow := false
var _hud_safe_insets := Vector4.ZERO
var _duty_button: Button
var _ability_button: Button
var _intel_button: Button
var _back_button: Button
var _result_panel: PanelContainer
var _result_title: Label
var _result_body: Label
var _damage_layer: Control
var _cleanse_zone: MeshInstance3D
var _cleanse_material: StandardMaterial3D
var _cleanse_ring_materials: Array[StandardMaterial3D] = []
var _arena_visuals: Node3D
var _pause_menu: ImmunePauseMenu
var _portrait_layer: CanvasLayer
var _portrait_frame: PanelContainer
var _portrait_viewport: SubViewport
var _portrait_stage: Node3D
var _portrait_camera: Camera3D
var _portrait_character: ImmuneCharacter
var _portrait_refresh_frames: int = 0
var _portrait_layout_frames: int = 0
var _spawn_cd: float = 1.0
var _fire_cd: float = 0.35
var _hud_refresh_cd: float = 0.0
var _kills: int = 0
var _cleanse_progress: float = 0.0
var _over: bool = false
var _rewarded: bool = false
var _onboarding_open: bool = false
var _telemetry: CombatPlaytestTelemetry
var _active_skill_controller: ActiveSkillController
var _encounter_director: CombatEncounterDirector
var _touch_controls: CombatTouchControls
var _encounter_spawn_multiplier: float = 1.0
var _resolving_active_skill: bool = false
var _core_last_hp: int = _Core.MAX_HP


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
	_build_gameplay_components()
	_build_stage()
	_build_cleanse_zone()
	_spawn_core()
	_spawn_player()
	_build_hud()
	_build_combat_portrait()
	_build_pause_menu()
	_assert_jelly_light_contract()
	if ResearchState.has_signal("duty_unlocked"):
		ResearchState.duty_unlocked.connect(_on_duty_unlocked)
	SettingsState.input_device_changed.connect(_on_input_device_changed)
	SettingsState.settings_changed.connect(_on_settings_changed)
	AudioDirector.play_music()
	_set_phase(Phase.CORE_DEFENSE)
	WebQaBridge.publish(&"combat_ready", {
		"mission": String(mission_data.id),
		"family": String(_family_profile.family_id),
		"duty": String(_player.duty),
	})
	if show_onboarding and not SettingsState.onboarding_seen:
		_show_onboarding()


func _assert_jelly_light_contract() -> void:
	if not OS.is_debug_build():
		return
	var contract_error: String = _LightContract.error(self, "combat runtime")
	assert(contract_error.is_empty(), contract_error)


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.disconnect(_on_viewport_size_changed)
	_shutdown_combat_portrait()


func _process(_delta: float) -> void:
	if _portrait_layout_frames > 0:
		_portrait_layout_frames -= 1
		_layout_combat_portrait()
	if _portrait_refresh_frames <= 0 or _portrait_viewport == null:
		return
	if _portrait_frame == null or not _portrait_frame.visible:
		_portrait_refresh_frames = 0
		_portrait_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	_portrait_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_portrait_refresh_frames -= 1


func _build_gameplay_components() -> void:
	_active_skill_controller = _ActiveSkillController.new()
	_active_skill_controller.name = "ActiveSkillController"
	_active_skill_controller.configure(_family_profile.active_skill)
	_active_skill_controller.activation_requested.connect(_on_active_skill_requested)
	_active_skill_controller.cooldown_changed.connect(_on_active_skill_cooldown_changed)
	add_child(_active_skill_controller)
	_encounter_director = _EncounterDirector.new()
	_encounter_director.name = "EncounterDirector"
	_encounter_director.configure(mission_data)
	_encounter_director.event_triggered.connect(_on_encounter_event)
	add_child(_encounter_director)


func _on_duty_unlocked(family: StringName, _duty: StringName) -> void:
	if family == _family_profile.family_id:
		_refresh_hud()
		call_deferred("_sync_combat_portrait_duty")


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
	elif event.is_action_pressed(&"demo_active_skill"):
		_request_active_skill()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"demo_research"):
		_show_intel_or_research()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if _over or _onboarding_open or get_tree().paused:
		return
	_update_playtest_autopilot()
	_move_player()
	if _active_skill_controller != null:
		_active_skill_controller.tick(delta)
	if _encounter_director != null:
		_encounter_director.tick(delta)
	if _telemetry != null and _player != null:
		_telemetry.tick(delta, _player.duty)
	_try_fire(delta)
	_update_expedition(delta)
	if not auto_spawn:
		return
	_spawn_cd -= delta
	if _spawn_cd <= 0.0:
		var base_interval := mission_data.defense_spawn_interval if current_phase == Phase.CORE_DEFENSE else mission_data.late_spawn_interval
		_spawn_cd = (
			base_interval
			* mission_data.difficulty.spawn_interval_multiplier
			* _encounter_spawn_multiplier
		)
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
	_sync_combat_portrait_duty()
	_sync_touch_movement_state()
	AudioDirector.play_sfx(&"duty")
	_refresh_hud()
	WebQaBridge.publish(&"duty_changed", {
		"family": String(_family_profile.family_id),
		"duty": String(_player.duty),
	})


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
	if not playtest_autopilot and _touch_controls != null:
		var touch_input := _touch_controls.movement_vector()
		if not touch_input.is_zero_approx():
			move_input = touch_input
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
		_sync_combat_portrait_duty()
		if _telemetry != null:
			_telemetry.record_duty_switch()
	_update_playtest_active_skill()


func _update_playtest_active_skill() -> void:
	if _active_skill_controller == null or not _active_skill_controller.is_ready():
		return
	var profile := _active_skill_controller.profile
	if profile == null:
		return
	var has_target := not _active_skill_targets(profile).is_empty()
	var can_repair_core := profile.core_heal > 0 and _core != null and _core.hp < _Core.MAX_HP
	if has_target or can_repair_core:
		_request_active_skill()


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


func _request_active_skill() -> void:
	if _active_skill_controller == null or _active_skill_controller.profile == null:
		return
	if not _active_skill_controller.is_ready():
		_set_status(tr("STATUS_ACTIVE_SKILL_COOLDOWN") % ceili(
			_active_skill_controller.remaining_seconds()
		))
		return
	var profile := _active_skill_controller.profile
	var targets := _active_skill_targets(profile)
	var can_repair_core := profile.core_heal > 0 and _core != null and _core.hp < _Core.MAX_HP
	if targets.is_empty() and not can_repair_core:
		_set_status(tr("STATUS_ACTIVE_SKILL_NO_TARGET"))
		return
	_active_skill_controller.request_activation()


func _on_active_skill_requested(profile: FamilyActiveSkillProfile) -> void:
	if _over or _player == null:
		return
	var targets := _active_skill_targets(profile)
	_player.fire_skill(StringName("SKILL-%s-ACTIVE" % String(_family_profile.family_id)))
	_resolving_active_skill = true
	var hits := 0
	for target in targets:
		if not is_instance_valid(target):
			continue
		target.call(
			"take_profiled_hit",
			profile.damage,
			_family_profile.family_id,
			StringName(profile.hit_effect),
			profile.hit_effect_power,
			profile.hit_effect_cap,
			profile.hit_effect_threshold
		)
		hits += 1
	_resolving_active_skill = false
	var restored := 0
	if profile.core_heal > 0 and _core != null:
		restored = int(_core.call("restore_health", profile.core_heal))
	if _telemetry != null:
		_telemetry.record_active_skill(profile.id, hits)
	if restored > 0:
		_set_status(tr("STATUS_ACTIVE_SKILL_HEAL") % [tr(profile.name_key), hits, restored])
	else:
		_set_status(tr("STATUS_ACTIVE_SKILL_USED") % [tr(profile.name_key), hits])
	AudioDirector.play_sfx(&"phase", 1.15, -1.0)
	_shake_camera(0.12)
	WebQaBridge.publish(&"active_skill_used", {
		"family": String(_family_profile.family_id),
		"skill": String(profile.id),
		"hits": hits,
		"core_heal": restored,
	})


func _active_skill_targets(profile: FamilyActiveSkillProfile) -> Array[Node3D]:
	var candidates: Array[Node3D] = []
	if _player == null:
		return candidates
	for enemy in _owned_enemies():
		if _player.global_position.distance_to(enemy.global_position) <= profile.radius:
			candidates.append(enemy)
	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return _active_skill_target_score(a, profile) < _active_skill_target_score(b, profile)
	)
	var selected: Array[Node3D] = []
	for candidate in candidates:
		if selected.size() >= profile.max_targets:
			break
		selected.append(candidate)
	return selected


func _active_skill_target_score(target: Node3D, profile: FamilyActiveSkillProfile) -> float:
	var distance := _player.global_position.distance_to(target.global_position)
	if profile.targeting == "lowest_health":
		return float(target.get("hp")) / float(maxi(int(target.get("max_hp")), 1)) * 1000.0 + distance
	if profile.targeting == "spread":
		return distance + absf(target.global_position.x) * 0.05
	return distance


func _on_active_skill_cooldown_changed(_remaining: float, _duration: float) -> void:
	_refresh_prompts()


func _owned_enemies() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("bacterium"):
		if node is Node3D and is_ancestor_of(node):
			result.append(node as Node3D)
	return result


func _on_encounter_event(event_id: StringName, strength: int, occurrence: int) -> void:
	if _over:
		return
	var outcome := 0
	match event_id:
		&"surge":
			outcome = _spawn_encounter_wave(strength)
		&"systemic_surge":
			# Systemic pressure alternates frequently with biofilm restoration.
			# A single reinforcement keeps that cadence lethal without creating
			# an unavoidable two-hit core spike for lower-DPS families.
			outcome = _spawn_encounter_wave(mini(strength, 1))
		&"cytokine":
			for enemy in _owned_enemies():
				enemy.call("apply_speed_boost", 1.0 + float(strength) * 0.18, 3.5)
			outcome = _owned_enemies().size()
			_shake_camera(0.16)
		&"adaptive":
			_encounter_spawn_multiplier = maxf(
				_encounter_spawn_multiplier * (1.0 - 0.07 * float(strength)), 0.68
			)
			_spawn_cd = minf(_spawn_cd, 0.35)
			outcome = roundi((1.0 - _encounter_spawn_multiplier) * 100.0)
		&"biofilm", &"systemic_biofilm":
			for enemy in _owned_enemies():
				outcome += int(enemy.call("restore_health", strength))
	var status_key := "STATUS_ENCOUNTER_%s" % String(event_id).to_upper()
	_set_status(tr(status_key) % outcome)
	if _telemetry != null:
		_telemetry.record_encounter_event(event_id)
	WebQaBridge.publish(&"encounter_event", {
		"mission": String(mission_data.id),
		"pattern": String(event_id),
		"occurrence": occurrence,
		"outcome": outcome,
	})


func _spawn_encounter_wave(count: int) -> int:
	var spawned := 0
	for _index in maxi(count, 0):
		if current_phase == Phase.TOTAL_WAR and _owned_enemies().size() >= mission_data.total_war_enemy_cap:
			break
		_spawn_regular(false)
		spawned += 1
	return spawned


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


func _spawn_regular(counts_for_objective: bool = true) -> void:
	var bug: _Bacterium = _Bacterium.new()
	bug.configure_profile(mission_data.regular_enemy, mission_data.difficulty)
	_wire_enemy(bug, counts_for_objective)
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


func _wire_enemy(enemy: _Bacterium, counts_for_objective: bool = true) -> void:
	enemy.core = _core
	enemy.died.connect(_on_enemy_died.bind(counts_for_objective))
	enemy.hit_received.connect(_on_enemy_hit)


func _on_enemy_died(was_boss: bool, counts_for_objective: bool = true) -> void:
	if counts_for_objective:
		_kills += 1
	if _telemetry != null:
		_telemetry.record_enemy_defeated(was_boss, counts_for_objective)
	if was_boss and current_phase == Phase.TOTAL_WAR:
		_victory()
	elif current_phase == Phase.CORE_DEFENSE and _kills >= mission_data.defense_kills:
		_set_phase(Phase.EXPEDITION)
	_refresh_hud()


func _on_enemy_hit(world_position: Vector3, amount: int, was_boss: bool) -> void:
	if _telemetry != null and not _resolving_active_skill:
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
	var took_damage := hp < _core_last_hp
	_core_last_hp = hp
	if _telemetry != null:
		_telemetry.record_core_hp(hp, max_hp)
	_core_bar.max_value = max_hp
	_core_bar.value = hp
	_core_value.text = "%d/%d" % [hp, max_hp]
	if took_damage:
		AudioDirector.play_sfx(&"core_hit")
		_shake_camera(0.22)
	_refresh_hud()
	if hp <= 0:
		_defeat()
	elif took_damage and hp < max_hp:
		_set_status(tr("STATUS_CORE_DAMAGED") % [hp, max_hp])


func _set_phase(next_phase: Phase) -> void:
	current_phase = next_phase
	if _encounter_director != null:
		_encounter_director.enter_phase(_phase_code())
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


func _phase_code() -> StringName:
	match current_phase:
		Phase.CORE_DEFENSE:
			return &"core"
		Phase.EXPEDITION:
			return &"expedition"
		Phase.TOTAL_WAR:
			return &"total_war"
		_:
			return &"complete"


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
	sun.name = "CombatKey"
	sun.rotation_degrees = Vector3(-48, 30, 0)
	sun.light_color = Color(1.0, 0.94, 0.86)
	sun.light_energy = 1.18
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.name = "CombatFill"
	fill.rotation_degrees = Vector3(-18, -62, 0)
	fill.light_color = Color(0.58, 0.74, 1.0)
	fill.light_energy = 0.36
	add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.name = "CombatRim"
	rim.rotation_degrees = Vector3(-28, -145, 0)
	rim.light_color = Color(0.52, 0.72, 1.0)
	rim.light_energy = 0.58
	add_child(rim)
	_camera = Camera3D.new()
	_camera.name = "CombatCamera"
	_camera.position = Vector3(0.0, 13.8, 14.8)
	_camera.rotation_degrees = Vector3(-47, 0, 0)
	_camera.fov = 58.0
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
	floor_mat.roughness = 0.68
	floor_mat.emission_enabled = true
	floor_mat.emission = mission_data.floor_color.lightened(0.08)
	floor_mat.emission_energy_multiplier = 0.08
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
	_build_arena_visuals()


func _build_arena_visuals() -> void:
	# This layer is deliberately mesh-only: it adds biological depth without
	# changing the floor collision, pathing bounds, or combat balance.
	_arena_visuals = Node3D.new()
	_arena_visuals.name = "ArenaVisuals"
	add_child(_arena_visuals)
	var tissue_color := mission_data.floor_color.lightened(0.16)
	var tissue_material := _arena_material(tissue_color, 1.0, 0.08, 0.7)
	var vein_material := _arena_material(mission_data.lane_color.lightened(0.18), 0.9, 0.24, 0.5)
	var signal_material := _arena_material(mission_data.zone_color, 0.74, 0.34, 0.42)
	for side in [-1.0, 1.0]:
		var tissue_mesh := BoxMesh.new()
		tissue_mesh.size = Vector3(4.7, 0.08, 31.0)
		_add_arena_mesh(
			"SideTissue%s" % ("Left" if side < 0.0 else "Right"),
			tissue_mesh,
			Vector3(side * 5.5, -0.015, 2.0),
			tissue_material
		)
		var outer_rail := CapsuleMesh.new()
		outer_rail.radius = 0.16
		outer_rail.height = 30.2
		_add_arena_mesh(
			"OuterMembrane%s" % ("Left" if side < 0.0 else "Right"),
			outer_rail,
			Vector3(side * 7.35, 0.12, 2.0),
			vein_material,
			Vector3(90.0, 0.0, 0.0)
		)
		var lane_rail := CapsuleMesh.new()
		lane_rail.radius = 0.045
		lane_rail.height = 26.0
		_add_arena_mesh(
			"LaneVein%s" % ("Left" if side < 0.0 else "Right"),
			lane_rail,
			Vector3(side * 1.24, 0.075, 2.0),
			signal_material,
			Vector3(90.0, 0.0, 0.0)
		)
	var organoid_z: PackedFloat32Array = [-10.4, -6.2, -2.0, 2.1, 6.2, 10.4]
	for i in organoid_z.size():
		for side in [-1.0, 1.0]:
			var blob := SphereMesh.new()
			blob.radius = 0.46
			blob.height = 0.92
			var side_name := "L" if side < 0.0 else "R"
			var x_offset := 0.28 if i % 2 == 0 else -0.18
			var squash := 0.30 + float((i + (0 if side < 0.0 else 1)) % 3) * 0.055
			_add_arena_mesh(
				"Organoid%s%d" % [side_name, i + 1],
				blob,
				Vector3(side * (4.65 + x_offset), 0.14, organoid_z[i]),
				signal_material if i % 3 == 1 else tissue_material,
				Vector3(0.0, float(i * 17) * side, 0.0),
				Vector3(1.55 + float(i % 2) * 0.35, squash, 0.92 + float(i % 3) * 0.16)
			)
	var core_ring := TorusMesh.new()
	core_ring.inner_radius = 2.25
	core_ring.outer_radius = 2.42
	core_ring.rings = 32
	core_ring.ring_segments = 8
	_add_arena_mesh(
		"CoreMembraneRing", core_ring, Vector3(0.0, 0.04, -10.2), vein_material
	)
	var home_ring := TorusMesh.new()
	home_ring.inner_radius = 0.9
	home_ring.outer_radius = 1.02
	home_ring.rings = 24
	home_ring.ring_segments = 8
	_add_arena_mesh(
		"PlayerHomeRing", home_ring, Vector3(0.0, 0.04, PLAYER_HOME.z), signal_material
	)


func _add_arena_mesh(
	node_name: String,
	mesh: Mesh,
	mesh_position: Vector3,
	material: Material,
	mesh_rotation: Vector3 = Vector3.ZERO,
	mesh_scale: Vector3 = Vector3.ONE
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = mesh_position
	instance.rotation_degrees = mesh_rotation
	instance.scale = mesh_scale
	instance.material_override = material
	_arena_visuals.add_child(instance)
	return instance


func _arena_material(
	color: Color, alpha: float, emission_energy: float, material_roughness: float
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	if alpha < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color, alpha)
	material.roughness = material_roughness
	material.emission_enabled = emission_energy > 0.0
	material.emission = color
	material.emission_energy_multiplier = emission_energy
	return material


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
	var ring_root := Node3D.new()
	ring_root.name = "CleanseVisuals"
	add_child(ring_root)
	_cleanse_ring_materials.clear()
	for ring_data in [
		{"name": "OuterRing", "inner": 2.08, "outer": 2.22},
		{"name": "InnerRing", "inner": 1.20, "outer": 1.28},
	]:
		var ring := MeshInstance3D.new()
		ring.name = str(ring_data["name"])
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = float(ring_data["inner"])
		ring_mesh.outer_radius = float(ring_data["outer"])
		ring_mesh.rings = 32
		ring_mesh.ring_segments = 8
		ring.mesh = ring_mesh
		ring.position = Vector3(CLEANSE_CENTER.x, 0.07, CLEANSE_CENTER.z)
		var ring_material := _arena_material(mission_data.zone_color, 0.42, 0.38, 0.38)
		ring.material_override = ring_material
		_cleanse_ring_materials.append(ring_material)
		ring_root.add_child(ring)
	for i in 8:
		var marker := MeshInstance3D.new()
		marker.name = "SignalMarker%02d" % (i + 1)
		var marker_mesh := SphereMesh.new()
		marker_mesh.radius = 0.09
		marker_mesh.height = 0.18
		marker.mesh = marker_mesh
		var angle := TAU * float(i) / 8.0
		marker.position = Vector3(
			CLEANSE_CENTER.x + cos(angle) * 2.15,
			0.13,
			CLEANSE_CENTER.z + sin(angle) * 2.15
		)
		marker.material_override = _cleanse_ring_materials[0]
		ring_root.add_child(marker)


func _update_zone_look() -> void:
	if _cleanse_material == null:
		return
	var active := current_phase == Phase.EXPEDITION
	_cleanse_material.albedo_color = Color(mission_data.zone_color, 0.34 if active else 0.08)
	_cleanse_material.emission_energy_multiplier = 0.75 if active else 0.12
	for ring_material in _cleanse_ring_materials:
		ring_material.albedo_color = Color(mission_data.zone_color, 0.86 if active else 0.36)
		ring_material.emission_energy_multiplier = 1.1 if active else 0.3


func _spawn_core() -> void:
	_core = _Core.new()
	_core.position = Vector3(0.0, 0.7, -10.2)
	_core.hp_changed.connect(_on_core_hit)
	_core.breached.connect(_defeat)
	add_child(_core)
	_core_last_hp = _core.hp
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
	_sync_touch_movement_state()


func _sync_touch_movement_state() -> void:
	if _touch_controls == null:
		return
	_touch_controls.set_movement_enabled(
		_player != null and _player.duty != &"fixed" and not _over
	)


func _build_combat_portrait() -> void:
	# The live player must stay small enough for lane tactics. This bounded,
	# own-world render gives the material and duty silhouette a readable HUD-scale
	# presentation without touching gameplay camera, transforms, or collision.
	_portrait_layer = CanvasLayer.new()
	_portrait_layer.name = "CombatHeroPortraitLayer"
	_portrait_layer.layer = 2
	add_child(_portrait_layer)
	_portrait_frame = PanelContainer.new()
	_portrait_frame.name = "CombatHeroPortrait"
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.clip_contents = true
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.018, 0.035, 0.055, 0.94)
	frame_style.border_color = Color(mission_data.zone_color, 0.72)
	frame_style.set_border_width_all(1)
	frame_style.set_corner_radius_all(14)
	frame_style.content_margin_left = 4.0
	frame_style.content_margin_top = 4.0
	frame_style.content_margin_right = 4.0
	frame_style.content_margin_bottom = 4.0
	_portrait_frame.add_theme_stylebox_override("panel", frame_style)
	_portrait_layer.add_child(_portrait_frame)
	var viewport_container := SubViewportContainer.new()
	viewport_container.name = "CombatHeroViewportContainer"
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.custom_minimum_size = Vector2(PORTRAIT_RENDER_SIZE)
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_portrait_frame.add_child(viewport_container)
	_portrait_viewport = SubViewport.new()
	_portrait_viewport.name = "CombatHeroViewport"
	_portrait_viewport.size = PORTRAIT_RENDER_SIZE
	_portrait_viewport.transparent_bg = true
	_portrait_viewport.own_world_3d = true
	_portrait_viewport.msaa_3d = Viewport.MSAA_2X
	_portrait_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport_container.add_child(_portrait_viewport)
	_portrait_stage = Node3D.new()
	_portrait_stage.name = "CombatHeroStage"
	_portrait_viewport.add_child(_portrait_stage)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.008, 0.016, 0.028)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.46, 0.58, 0.72)
	environment.ambient_light_energy = 0.46
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = environment
	_portrait_stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.name = "CombatHeroKey"
	key.rotation_degrees = Vector3(-40.0, -25.0, 0.0)
	key.light_color = Color(1.0, 0.95, 0.88)
	key.light_energy = 1.55
	key.shadow_enabled = true
	_portrait_stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.name = "CombatHeroRim"
	rim.rotation_degrees = Vector3(-20.0, 155.0, 0.0)
	rim.light_color = Color(0.34, 0.58, 1.0)
	rim.light_energy = 0.85
	_portrait_stage.add_child(rim)
	var fill := DirectionalLight3D.new()
	fill.name = "CombatHeroFill"
	fill.rotation_degrees = Vector3(-12.0, 62.0, 0.0)
	fill.light_color = Color(0.72, 0.82, 1.0)
	fill.light_energy = 0.32
	_portrait_stage.add_child(fill)
	_portrait_camera = Camera3D.new()
	_portrait_camera.name = "CombatHeroCamera"
	_portrait_camera.position = Vector3(1.0, 1.45, 3.75)
	_portrait_camera.fov = 29.5
	_portrait_camera.look_at_from_position(
		_portrait_camera.position, Vector3(0.0, 0.55, 0.0), Vector3.UP
	)
	_portrait_camera.current = true
	_portrait_stage.add_child(_portrait_camera)
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	_connect_portrait_layout_signals()
	_request_combat_portrait_layout(8)


func _spawn_combat_portrait_character() -> void:
	if _portrait_stage == null or _family_profile == null:
		return
	if _portrait_character != null and is_instance_valid(_portrait_character):
		return
	var family := String(_family_profile.family_id)
	var path := str(_Look.SCENE_PATH.get(family, _Look.SCENE_PATH["T"]))
	var scene := load(path) as PackedScene
	if scene == null:
		push_warning("CombatLane: portrait family scene missing %s" % path)
		return
	_portrait_character = scene.instantiate() as ImmuneCharacter
	if _portrait_character == null:
		push_warning("CombatLane: portrait scene did not instantiate ImmuneCharacter")
		return
	_portrait_character.name = "CombatHeroCharacter"
	_portrait_character.position = Vector3(0.0, float(PORTRAIT_Y.get(family, -0.12)), 0.0)
	_portrait_character.rotation_degrees.y = -18.0
	_portrait_character.scale = Vector3.ONE * float(PORTRAIT_SCALE.get(family, 1.45))
	_portrait_stage.add_child(_portrait_character)
	# CharacterRoot normally listens to the global unlock signal. The presentation
	# clone must not race the live player/CombatLane sync or start an animation
	# while its process mode is frozen.
	var unlock_callback := Callable(_portrait_character, "_on_duty_unlocked")
	if ResearchState.duty_unlocked.is_connected(unlock_callback):
		ResearchState.duty_unlocked.disconnect(unlock_callback)
	_portrait_character.remove_from_group("immune_character")
	_disable_portrait_gameplay_nodes(_portrait_character)
	_sync_combat_portrait_duty()
	# The portrait is a frozen presentation pose. Its SubViewport is updated only
	# on demand, so letting the cloned idle animation keep ticking would spend CPU
	# on transforms that are not rendered (including while the portrait is hidden).
	_portrait_character.process_mode = Node.PROCESS_MODE_DISABLED


func _disable_portrait_gameplay_nodes(node: Node) -> void:
	if node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
	elif node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true
	elif node is GPUParticles3D:
		var particles := node as GPUParticles3D
		particles.emitting = false
		particles.visible = false
	for child in node.get_children():
		_disable_portrait_gameplay_nodes(child)


func _sync_combat_portrait_duty() -> void:
	if _player == null or _portrait_character == null:
		return
	_portrait_character.process_mode = Node.PROCESS_MODE_INHERIT
	var target_duty := _player.duty
	if _family_profile.family_id == &"A" and target_duty == &"mobile":
		target_duty = &"relay"
	if _portrait_character.duty != target_duty:
		_portrait_character.transform_duty(target_duty)
		# Resolve the cloned duty transition immediately. The live character keeps
		# its normal animation; only this isolated presentation clone is advanced.
		var animation_player := _portrait_character.animation_player
		if animation_player != null:
			animation_player.advance(1.2)
	_disable_portrait_gameplay_nodes(_portrait_character)
	_portrait_character.process_mode = Node.PROCESS_MODE_DISABLED
	_refresh_combat_portrait(4)


func _refresh_combat_portrait(frames: int = 2) -> void:
	if _portrait_viewport == null or _portrait_frame == null or not _portrait_frame.visible:
		return
	_portrait_refresh_frames = maxi(_portrait_refresh_frames, frames)
	_portrait_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _on_viewport_size_changed() -> void:
	_apply_hud_responsive_layout()
	_request_combat_portrait_layout(4)


func _connect_portrait_layout_signals() -> void:
	for control_name in ["ActionTray", "MissionBriefingPanel", "VitalsPanel"]:
		var control := find_child(control_name, true, false) as Control
		if control == null:
			continue
		if not control.minimum_size_changed.is_connected(_on_critical_hud_geometry_changed):
			control.minimum_size_changed.connect(_on_critical_hud_geometry_changed)
		# Container layout is deferred after minimum_size_changed. Observe the
		# resulting rect as well so a hidden portrait can be rebuilt even while
		# CombatLane processing is paused or frozen by a menu/capture harness.
		if not control.resized.is_connected(_on_critical_hud_geometry_changed):
			control.resized.connect(_on_critical_hud_geometry_changed)
		if not control.visibility_changed.is_connected(_on_critical_hud_geometry_changed):
			control.visibility_changed.connect(_on_critical_hud_geometry_changed)


func _on_critical_hud_geometry_changed() -> void:
	_request_combat_portrait_layout(4)


func _request_combat_portrait_layout(frames: int = 4) -> void:
	_portrait_layout_frames = maxi(_portrait_layout_frames, frames)
	call_deferred("_layout_combat_portrait")


func _layout_combat_portrait() -> void:
	if _portrait_frame == null or _portrait_viewport == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var display_rect := _combat_portrait_display_rect(viewport_size)
	var can_show := _combat_portrait_can_show(viewport_size, display_rect)
	if not can_show:
		_portrait_frame.visible = false
		_portrait_refresh_frames = 0
		_portrait_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_discard_combat_portrait_character()
		return
	_portrait_frame.visible = true
	if _portrait_character == null or not is_instance_valid(_portrait_character):
		_spawn_combat_portrait_character()
	if _portrait_character == null:
		_portrait_frame.visible = false
		_portrait_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	_portrait_frame.anchor_left = 0.0
	_portrait_frame.anchor_top = 1.0
	_portrait_frame.anchor_right = 0.0
	_portrait_frame.anchor_bottom = 1.0
	_portrait_frame.offset_left = display_rect.position.x
	_portrait_frame.offset_top = -PORTRAIT_BOTTOM_CLEARANCE - PORTRAIT_DISPLAY_SIZE.y
	_portrait_frame.offset_right = display_rect.end.x
	_portrait_frame.offset_bottom = -PORTRAIT_BOTTOM_CLEARANCE
	_refresh_combat_portrait(4)


func _discard_combat_portrait_character() -> void:
	if _portrait_character == null:
		return
	var discarded := _portrait_character
	_portrait_character = null
	if is_instance_valid(discarded):
		discarded.process_mode = Node.PROCESS_MODE_DISABLED
		if discarded.get_parent() != null:
			discarded.get_parent().remove_child(discarded)
		discarded.queue_free()


func _combat_portrait_display_rect(viewport_size: Vector2) -> Rect2:
	return Rect2(
		Vector2(
			PORTRAIT_LEFT_MARGIN,
			viewport_size.y - PORTRAIT_BOTTOM_CLEARANCE - PORTRAIT_DISPLAY_SIZE.y
		),
		PORTRAIT_DISPLAY_SIZE
	)


func _combat_portrait_can_show(viewport_size: Vector2, display_rect: Rect2) -> bool:
	var can_show := (
		viewport_size.x >= PORTRAIT_MIN_VIEWPORT.x
		and viewport_size.y >= PORTRAIT_MIN_VIEWPORT.y
		and viewport_size.x / maxf(viewport_size.y, 1.0) >= PORTRAIT_MIN_ASPECT
	)
	if can_show:
		# Keep a protected central playfield and never overlap the three critical
		# HUD surfaces. Narrow/tall layouts hide the optional portrait instead.
		var center_playfield := Rect2(
			Vector2(viewport_size.x * 0.30, viewport_size.y * 0.20),
			Vector2(viewport_size.x * 0.40, viewport_size.y * 0.62)
		)
		can_show = not display_rect.intersects(center_playfield)
		for control_name in ["ActionTray", "MissionBriefingPanel", "VitalsPanel"]:
			var control := find_child(control_name, true, false) as Control
			if control != null and control.is_visible_in_tree():
				can_show = can_show and not display_rect.grow(8.0).intersects(control.get_global_rect())
	return can_show


func _combat_portrait_should_show() -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return _combat_portrait_can_show(
		viewport_size, _combat_portrait_display_rect(viewport_size)
	)


func _shutdown_combat_portrait() -> void:
	_portrait_refresh_frames = 0
	_portrait_layout_frames = 0
	if _portrait_viewport != null and is_instance_valid(_portrait_viewport):
		_portrait_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if _portrait_character != null and is_instance_valid(_portrait_character):
		_portrait_character.set_process(false)
	_portrait_character = null
	_portrait_camera = null
	_portrait_stage = null
	_portrait_viewport = null
	_portrait_frame = null
	_portrait_layer = null


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	_hud_root = Control.new()
	_hud_root.name = "CombatHudRoot"
	_hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_theme = Theme.new()
	_hud_theme.default_font_size = HUD_BASE_FONT_SIZE
	_hud_root.theme = _hud_theme
	layer.add_child(_hud_root)
	# HUD owns viewport responsiveness; the optional portrait observes the same
	# idempotent callback but is not required for tall-layout updates to work.
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	var top_margin := MarginContainer.new()
	top_margin.name = "HudTopMargin"
	top_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_margin.add_theme_constant_override("margin_left", 24)
	top_margin.add_theme_constant_override("margin_top", 18)
	top_margin.add_theme_constant_override("margin_right", 24)
	_hud_root.add_child(top_margin)
	var top_row := GridContainer.new()
	top_row.name = "HudTopRow"
	top_row.columns = 2
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("h_separation", 16)
	top_row.add_theme_constant_override("v_separation", 16)
	top_margin.add_child(top_row)
	var briefing_panel := PanelContainer.new()
	briefing_panel.name = "MissionBriefingPanel"
	briefing_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	briefing_panel.add_theme_stylebox_override("panel", _panel_box(
		Color(0.018, 0.052, 0.078, 0.9), Color(mission_data.zone_color, 0.34), 10
	))
	top_row.add_child(briefing_panel)
	var panel := VBoxContainer.new()
	panel.name = "BriefingColumn"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 6)
	briefing_panel.add_child(panel)
	_hud = Label.new()
	_hud.add_theme_font_size_override("font_size", 21)
	_hud.add_theme_color_override("font_color", _Tokens.TEXT)
	_hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_hud)
	_objective = Label.new()
	_objective.add_theme_font_size_override("font_size", 18)
	_objective.add_theme_color_override("font_color", _Tokens.GOLD)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_objective)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_color", _Tokens.CYAN)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_status)
	var vitals_panel := PanelContainer.new()
	vitals_panel.name = "VitalsPanel"
	vitals_panel.custom_minimum_size.x = 360
	vitals_panel.add_theme_stylebox_override("panel", _panel_box(
		Color(0.02, 0.045, 0.065, 0.92), Color(_Tokens.CYAN, 0.26), 10
	))
	top_row.add_child(vitals_panel)
	var vitals := VBoxContainer.new()
	vitals.name = "VitalsColumn"
	vitals.add_theme_constant_override("separation", 8)
	vitals_panel.add_child(vitals)
	var core_row := HBoxContainer.new()
	vitals.add_child(core_row)
	var core_label := Label.new()
	core_label.name = "CoreLabel"
	core_label.text = "UI_IMMUNE_CORE"
	core_label.custom_minimum_size.x = 90
	core_row.add_child(core_label)
	_core_bar = ProgressBar.new()
	_core_bar.show_percentage = false
	_core_bar.step = 0.0
	_core_bar.max_value = _Core.MAX_HP
	_core_bar.value = _Core.MAX_HP
	_core_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_progress_bar(_core_bar, _Tokens.CYAN)
	core_row.add_child(_core_bar)
	_core_value = Label.new()
	_core_value.text = "%d/%d" % [_Core.MAX_HP, _Core.MAX_HP]
	core_row.add_child(_core_value)
	_boss_row = HBoxContainer.new()
	_boss_row.visible = false
	vitals.add_child(_boss_row)
	var boss_label := Label.new()
	boss_label.name = "BossLabel"
	boss_label.text = "Boss"
	boss_label.custom_minimum_size.x = 90
	_boss_row.add_child(boss_label)
	_boss_bar = ProgressBar.new()
	_boss_bar.show_percentage = false
	_boss_bar.step = 0.0
	_boss_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_progress_bar(_boss_bar, Color(1.0, 0.34, 0.3))
	_boss_row.add_child(_boss_bar)
	_boss_value = Label.new()
	_boss_row.add_child(_boss_value)
	var bottom_margin := MarginContainer.new()
	bottom_margin.name = "HudBottomMargin"
	bottom_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_margin.offset_top = -94.0
	bottom_margin.add_theme_constant_override("margin_left", 24)
	bottom_margin.add_theme_constant_override("margin_right", 24)
	bottom_margin.add_theme_constant_override("margin_bottom", 18)
	_hud_root.add_child(bottom_margin)
	var action_center := CenterContainer.new()
	action_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_margin.add_child(action_center)
	var action_panel := PanelContainer.new()
	action_panel.name = "ActionTray"
	action_panel.custom_minimum_size = Vector2(930, 70)
	action_panel.add_theme_stylebox_override("panel", _panel_box(
		Color(0.012, 0.032, 0.048, 0.94), Color(_Tokens.CYAN, 0.34), 12
	))
	action_center.add_child(action_panel)
	var actions := GridContainer.new()
	actions.name = "ActionRow"
	actions.columns = 4
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("h_separation", 10)
	actions.add_theme_constant_override("v_separation", 10)
	action_panel.add_child(actions)
	_ability_button = Button.new()
	_ability_button.name = "AbilityButton"
	_ability_button.custom_minimum_size = Vector2(210, 52)
	_ability_button.pressed.connect(_request_active_skill)
	_style_action_button(_ability_button, _Tokens.GOLD, true)
	actions.add_child(_ability_button)
	_duty_button = Button.new()
	_duty_button.name = "DutyButton"
	_duty_button.custom_minimum_size = Vector2(220, 52)
	_duty_button.pressed.connect(_toggle_duty)
	_style_action_button(_duty_button, _Tokens.family_color(String(_family_profile.family_id)), true)
	actions.add_child(_duty_button)
	_intel_button = Button.new()
	_intel_button.name = "IntelButton"
	_intel_button.custom_minimum_size = Vector2(220, 52)
	_intel_button.pressed.connect(_show_intel_or_research)
	_style_action_button(_intel_button, _Tokens.CYAN)
	actions.add_child(_intel_button)
	_back_button = Button.new()
	_back_button.name = "MissionDeskButton"
	_back_button.custom_minimum_size = Vector2(220, 52)
	_back_button.pressed.connect(_back_to_missions)
	_style_action_button(_back_button, _Tokens.MUTED)
	actions.add_child(_back_button)
	_touch_controls = _TouchControls.new()
	_touch_controls.name = "CombatTouchControls"
	_touch_controls.visible = false
	_hud_root.add_child(_touch_controls)
	_sync_touch_movement_state()
	_damage_layer = Control.new()
	_damage_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.add_child(_damage_layer)
	var result_center := CenterContainer.new()
	result_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.add_child(result_center)
	_result_panel = PanelContainer.new()
	_result_panel.visible = false
	_result_panel.custom_minimum_size = Vector2(680, 320)
	_result_panel.add_theme_stylebox_override("panel", _panel_box(
		Color(0.018, 0.045, 0.068, 0.98), Color(_Tokens.CYAN, 0.62), 16
	))
	result_center.add_child(_result_panel)
	var result_box := VBoxContainer.new()
	result_box.name = "ResultColumn"
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
	_apply_hud_responsive_layout(true)
	_refresh_prompts()


func _apply_hud_responsive_layout(force: bool = false) -> void:
	if _hud_root == null or not is_instance_valid(_hud_root):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var next_narrow := _Responsive.is_narrow_phone(get_viewport())
	var next_scale := _Responsive.layout_scale(get_viewport())
	var next_insets := _Responsive.logical_safe_insets(get_viewport())
	if (
		not force
		and is_equal_approx(next_scale, _hud_layout_scale)
		and next_narrow == _hud_layout_narrow
		and next_insets.is_equal_approx(_hud_safe_insets)
	):
		return
	_hud_layout_scale = next_scale
	_hud_layout_narrow = next_narrow
	_hud_safe_insets = next_insets
	_hud_theme.default_font_size = _hud_metric(17 if _hud_layout_narrow else HUD_BASE_FONT_SIZE)

	var top_margin := _hud_root.find_child("HudTopMargin", true, false) as MarginContainer
	var top_row := _hud_root.find_child("HudTopRow", true, false) as GridContainer
	var briefing_panel := _hud_root.find_child("MissionBriefingPanel", true, false) as PanelContainer
	var briefing_column := _hud_root.find_child("BriefingColumn", true, false) as VBoxContainer
	var vitals_panel := _hud_root.find_child("VitalsPanel", true, false) as PanelContainer
	var vitals_column := _hud_root.find_child("VitalsColumn", true, false) as VBoxContainer
	var core_label := _hud_root.find_child("CoreLabel", true, false) as Label
	var boss_label := _hud_root.find_child("BossLabel", true, false) as Label
	var bottom_margin := _hud_root.find_child("HudBottomMargin", true, false) as MarginContainer
	var action_panel := _hud_root.find_child("ActionTray", true, false) as PanelContainer
	var actions := _hud_root.find_child("ActionRow", true, false) as GridContainer
	var result_column := _hud_root.find_child("ResultColumn", true, false) as VBoxContainer

	if top_margin != null:
		top_margin.add_theme_constant_override(
			"margin_left", _hud_metric(24) + roundi(_hud_safe_insets.x)
		)
		top_margin.add_theme_constant_override(
			"margin_top", _hud_metric(18) + roundi(_hud_safe_insets.y)
		)
		top_margin.add_theme_constant_override(
			"margin_right", _hud_metric(24) + roundi(_hud_safe_insets.z)
		)
	if top_row != null:
		top_row.columns = 1 if _hud_layout_narrow else 2
		top_row.add_theme_constant_override("h_separation", _hud_metric(16))
		top_row.add_theme_constant_override("v_separation", _hud_metric(10 if _hud_layout_narrow else 16))
	if briefing_panel != null:
		briefing_panel.add_theme_stylebox_override("panel", _panel_box(
			Color(0.018, 0.052, 0.078, 0.9), Color(mission_data.zone_color, 0.34), 10
		))
	if briefing_column != null:
		briefing_column.add_theme_constant_override("separation", _hud_metric(6))
	if vitals_panel != null:
		vitals_panel.custom_minimum_size.x = 0 if _hud_layout_narrow else _hud_metric(360)
		vitals_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vitals_panel.add_theme_stylebox_override("panel", _panel_box(
			Color(0.02, 0.045, 0.065, 0.92), Color(_Tokens.CYAN, 0.26), 10
		))
	if vitals_column != null:
		vitals_column.add_theme_constant_override("separation", _hud_metric(8))
	if core_label != null:
		core_label.custom_minimum_size.x = _hud_metric(90)
	if boss_label != null:
		boss_label.custom_minimum_size.x = _hud_metric(90)
	_style_progress_bar(_core_bar, _Tokens.CYAN)
	_style_progress_bar(_boss_bar, Color(1.0, 0.34, 0.3))

	_hud.add_theme_font_size_override("font_size", _hud_metric(21))
	_objective.add_theme_font_size_override("font_size", _hud_metric(18))
	_status.add_theme_font_size_override("font_size", _hud_metric(17 if _hud_layout_narrow else 16))
	if bottom_margin != null:
		bottom_margin.offset_top = -float(
			_hud_metric(170 if _hud_layout_narrow else 94) + roundi(_hud_safe_insets.w)
		)
		bottom_margin.add_theme_constant_override(
			"margin_left", _hud_metric(24) + roundi(_hud_safe_insets.x)
		)
		bottom_margin.add_theme_constant_override(
			"margin_right", _hud_metric(24) + roundi(_hud_safe_insets.z)
		)
		bottom_margin.add_theme_constant_override(
			"margin_bottom", _hud_metric(18) + roundi(_hud_safe_insets.w)
		)
	var safe_content_width := maxf(
		viewport_size.x
		- _hud_safe_insets.x
		- _hud_safe_insets.z
		- float(_hud_metric(48)),
		1.0
	)
	if action_panel != null:
		action_panel.custom_minimum_size = Vector2(
			safe_content_width if _hud_layout_narrow else _hud_metric(930),
			_hud_metric(150 if _hud_layout_narrow else 70)
		)
		action_panel.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL if _hud_layout_narrow else Control.SIZE_SHRINK_CENTER
		)
		action_panel.add_theme_stylebox_override("panel", _panel_box(
			Color(0.012, 0.032, 0.048, 0.94), Color(_Tokens.CYAN, 0.34), 12
		))
	if actions != null:
		actions.columns = 2 if _hud_layout_narrow else 4
		actions.add_theme_constant_override("h_separation", _hud_metric(10))
		actions.add_theme_constant_override("v_separation", _hud_metric(10))
	for button in [_ability_button, _duty_button, _intel_button, _back_button]:
		button.custom_minimum_size = Vector2(
			0 if _hud_layout_narrow else _hud_metric(210),
			_hud_metric(53 if _hud_layout_narrow else 52)
		)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = _hud_layout_narrow
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_action_button(
		_duty_button, _Tokens.family_color(String(_family_profile.family_id)), true
	)
	_style_action_button(_ability_button, _Tokens.GOLD, true)
	_style_action_button(_intel_button, _Tokens.CYAN)
	_style_action_button(_back_button, _Tokens.MUTED)
	if _touch_controls != null:
		_touch_controls.visible = _hud_layout_narrow or DisplayServer.is_touchscreen_available()
		_touch_controls.apply_layout(
			_hud_layout_scale,
			_hud_safe_insets,
			float(_hud_metric(170 if _hud_layout_narrow else 94))
		)
		_sync_touch_movement_state()
	var result_available_width := (
		viewport_size.x
		- _hud_safe_insets.x
		- _hud_safe_insets.z
		- float(_hud_metric(48))
	)
	_result_panel.custom_minimum_size = Vector2(
		minf(float(_hud_metric(680)), result_available_width) if _hud_layout_narrow else _hud_metric(680),
		_hud_metric(320)
	)
	_result_panel.add_theme_stylebox_override("panel", _panel_box(
		Color(0.018, 0.045, 0.068, 0.98), Color(_Tokens.CYAN, 0.62), 16
	))
	if result_column != null:
		result_column.add_theme_constant_override("separation", _hud_metric(14))
	_result_title.add_theme_font_size_override("font_size", _hud_metric(34))
	_result_body.add_theme_font_size_override("font_size", _hud_metric(19))
	_refresh_prompts()
	_request_combat_portrait_layout(4)


func responsive_contract() -> Dictionary:
	var narrow := _Responsive.is_narrow_phone(get_viewport())
	var physical := _Responsive.physical_window_size()
	var viewport_size := get_viewport().get_visible_rect().size
	var top_margin := _hud_root.find_child("HudTopMargin", true, false) as MarginContainer
	var top_row := _hud_root.find_child("HudTopRow", true, false) as GridContainer
	var bottom_margin := _hud_root.find_child("HudBottomMargin", true, false) as MarginContainer
	var actions := _hud_root.find_child("ActionRow", true, false) as GridContainer
	var min_action_height := INF
	var min_action_width := INF
	for button in [_ability_button, _duty_button, _intel_button, _back_button]:
		var physical_button_size := _Responsive.logical_size_to_physical(
			get_viewport(),
			Vector2(
				maxf(button.size.x, button.custom_minimum_size.x),
				maxf(button.size.y, button.custom_minimum_size.y)
			)
		)
		min_action_width = minf(min_action_width, physical_button_size.x)
		min_action_height = minf(
			min_action_height,
			physical_button_size.y
		)
	var copy_physical := _Responsive.logical_height_to_physical(
		get_viewport(), float(_status.get_theme_font_size("font_size"))
	)
	var min_touch_height := 0.0
	if _touch_controls != null:
		min_touch_height = _Responsive.logical_height_to_physical(
			get_viewport(), _touch_controls.minimum_button_height()
		)
	var safe_pass := (
		top_margin != null
		and bottom_margin != null
		and top_margin.get_theme_constant("margin_left") >= roundi(_hud_safe_insets.x)
		and top_margin.get_theme_constant("margin_top") >= roundi(_hud_safe_insets.y)
		and top_margin.get_theme_constant("margin_right") >= roundi(_hud_safe_insets.z)
		and bottom_margin.get_theme_constant("margin_left") >= roundi(_hud_safe_insets.x)
		and bottom_margin.get_theme_constant("margin_right") >= roundi(_hud_safe_insets.z)
		and bottom_margin.get_theme_constant("margin_bottom") >= roundi(_hud_safe_insets.w)
	)
	var safe_rect := Rect2(
		Vector2(_hud_safe_insets.x, _hud_safe_insets.y),
		Vector2(
			viewport_size.x - _hud_safe_insets.x - _hud_safe_insets.z,
			viewport_size.y - _hud_safe_insets.y - _hud_safe_insets.w
		)
	)
	var critical_inside_safe := true
	var critical_controls := ["MissionBriefingPanel", "VitalsPanel", "ActionTray"]
	var critical_control_contract := {}
	if narrow:
		critical_controls.append("TouchDirectionPad")
	for control_name in critical_controls:
		var control := _hud_root.find_child(control_name, true, false) as Control
		var rect := control.get_global_rect() if control != null else Rect2()
		var inside := control != null and safe_rect.grow(1.0).encloses(rect)
		critical_control_contract[control_name] = {
			"inside": inside,
			"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		}
		critical_inside_safe = (
			critical_inside_safe
			and inside
		)
	var pause_contract := _pause_menu.responsive_contract() if _pause_menu != null else {}
	var all_pass := (
		not narrow
		or (
			top_row != null
			and top_row.columns == 1
			and actions != null
			and actions.columns == 2
			and min_action_width >= 96.0
			and min_action_height >= 44.0
			and _touch_controls != null
			and _touch_controls.visible
			and _touch_controls.directional_button_count() == 4
			and min_touch_height >= 44.0
			and copy_physical >= 14.0
			and safe_pass
			and critical_inside_safe
			and bool(pause_contract.get("all_pass", false))
		)
	)
	return {
		"mode": "narrow-phone" if narrow else ("tall" if _hud_layout_scale > 1.0 else "wide"),
		"physical": [physical.x, physical.y],
		"logical": [viewport_size.x, viewport_size.y],
		"layout_scale": _hud_layout_scale,
		"safe_area_source": _Responsive.safe_area_source(),
		"safe_insets_logical": [_hud_safe_insets.x, _hud_safe_insets.y, _hud_safe_insets.z, _hud_safe_insets.w],
		"safe_rect": [safe_rect.position.x, safe_rect.position.y, safe_rect.size.x, safe_rect.size.y],
		"top_columns": top_row.columns if top_row != null else 0,
		"action_columns": actions.columns if actions != null else 0,
		"minimum_action_width_physical": min_action_width,
		"minimum_action_height_physical": min_action_height,
		"minimum_touch_height_physical": min_touch_height,
		"touch_controls_visible": _touch_controls.visible if _touch_controls != null else false,
		"minimum_copy_size_physical": copy_physical,
		"safe_margins_pass": safe_pass,
		"critical_controls_inside_safe_area": critical_inside_safe,
		"critical_controls": critical_control_contract,
		"pause": pause_contract,
		"all_pass": all_pass,
	}


func _hud_metric(value: int) -> int:
	return maxi(1, roundi(float(value) * _hud_layout_scale))


func _panel_box(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(_hud_metric(1))
	box.set_corner_radius_all(_hud_metric(radius))
	box.content_margin_left = float(_hud_metric(14))
	box.content_margin_right = float(_hud_metric(14))
	box.content_margin_top = float(_hud_metric(10))
	box.content_margin_bottom = float(_hud_metric(10))
	return box


func _style_action_button(button: Button, accent: Color, primary: bool = false) -> void:
	button.add_theme_font_size_override("font_size", _hud_metric(16))
	button.add_theme_color_override("font_color", Color.WHITE if primary else _Tokens.TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.42, 0.5, 0.55))
	button.add_theme_stylebox_override("normal", _button_box(
		Color(accent.darkened(0.72), 0.92), Color(accent, 0.72), 1
	))
	button.add_theme_stylebox_override("hover", _button_box(
		Color(accent.darkened(0.58), 0.96), accent, 2
	))
	button.add_theme_stylebox_override("pressed", _button_box(
		Color(accent.darkened(0.44), 0.98), accent.lightened(0.12), 2
	))
	button.add_theme_stylebox_override("focus", _button_box(Color.TRANSPARENT, accent, 2))
	button.add_theme_stylebox_override("disabled", _button_box(
		Color(0.018, 0.028, 0.038, 0.88), Color(0.12, 0.16, 0.19, 0.7), 1
	))


func _button_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(_hud_metric(border_width))
	box.set_corner_radius_all(_hud_metric(9))
	box.content_margin_left = float(_hud_metric(12))
	box.content_margin_right = float(_hud_metric(12))
	box.content_margin_top = float(_hud_metric(8))
	box.content_margin_bottom = float(_hud_metric(8))
	return box


func _style_progress_bar(bar: ProgressBar, accent: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.008, 0.018, 0.026, 0.92)
	background.border_color = Color(accent, 0.28)
	background.set_border_width_all(_hud_metric(1))
	background.set_corner_radius_all(_hud_metric(5))
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(accent, 0.88)
	fill.set_corner_radius_all(_hud_metric(5))
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)


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
	if _ability_button and _active_skill_controller:
		_ability_button.disabled = _over or not _active_skill_controller.is_ready()
	_sync_touch_movement_state()


func _refresh_prompts() -> void:
	if _ability_button and _active_skill_controller and _active_skill_controller.profile:
		_ability_button.disabled = _over or not _active_skill_controller.is_ready()
		var active_name := tr(_active_skill_controller.profile.name_key)
		var full_ability_text := ""
		if _active_skill_controller.is_ready():
			full_ability_text = tr("UI_ACTIVE_SKILL_READY") % [
				SettingsState.prompt(&"demo_active_skill"), active_name
			]
			_ability_button.text = active_name if _hud_layout_narrow else full_ability_text
		else:
			full_ability_text = tr("UI_ACTIVE_SKILL_COOLDOWN") % [
				active_name, ceili(_active_skill_controller.remaining_seconds())
			]
			_ability_button.text = (
				tr("UI_ACTIVE_SKILL_COOLDOWN_SHORT")
				% [active_name, ceili(_active_skill_controller.remaining_seconds())]
				if _hud_layout_narrow
				else full_ability_text
			)
		_ability_button.tooltip_text = full_ability_text
	if _duty_button:
		var full_duty_text := tr("UI_TOGGLE_DUTY") % SettingsState.prompt(&"demo_toggle_duty")
		_duty_button.text = tr("UI_DUTY_SHORT") if _hud_layout_narrow else full_duty_text
		_duty_button.tooltip_text = full_duty_text
	if _intel_button:
		var intel_name := tr("UI_RESEARCH_T") if _family_profile and _family_profile.family_id == &"T" else tr("UI_CHARACTER_INTEL")
		var full_intel_text := "%s · %s" % [SettingsState.prompt(&"demo_research"), intel_name]
		_intel_button.text = tr("UI_CHARACTER_INTEL_SHORT") if _hud_layout_narrow else full_intel_text
		_intel_button.tooltip_text = full_intel_text
	if _back_button:
		var full_back_text := tr("UI_RETURN_MISSION_DESK")
		_back_button.text = tr("UI_RETURN_MISSION_DESK_SHORT") if _hud_layout_narrow else full_back_text
		_back_button.tooltip_text = full_back_text


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
	body.text = (tr("UI_TUTORIAL_BODY") % [
		SettingsState.prompt(&"demo_active_skill"),
		SettingsState.prompt(&"demo_toggle_duty"),
		SettingsState.prompt(&"demo_pause"),
	]).replace("\\n", "\n")
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
