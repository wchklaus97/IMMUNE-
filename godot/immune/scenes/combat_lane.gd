extends Node3D

## First combat slice: one core, one lane, T-cell duty switch. Antibody does not join.

const _Core := preload("res://combat/immune_core.gd")
const _Bacterium := preload("res://combat/bacterium.gd")
const _Bolt := preload("res://combat/plasma_bolt.gd")
const _Tokens := preload("res://ui/research/research_tokens.gd")
const _TCell := preload("res://characters/character_root.gd")

const T_SCENE := "res://characters/base_t/character.tscn"
const SKILL_T_ACTIVE := &"SKILL-T-ACTIVE"
const NODE_FIXED := &"BASE-T-03"
const NODE_MOBILE := &"BASE-T-04"

const SPAWN_Z := 14.5
const T_HOME := Vector3(0.0, 0.55, 2.2)
const STRAFE_LIMIT := 5.4
const FIRE_RANGE := 11.0

var _t: _TCell
var _core: _Core
var _hud: Label
var _status: Label
var _spawn_cd := 1.2
var _fire_cd := 0.35
var _kills := 0
var _over := false


func _ready() -> void:
	_build_stage()
	_spawn_core()
	_spawn_t()
	_build_hud()
	if ResearchState.has_signal("duty_unlocked"):
		ResearchState.duty_unlocked.connect(_on_duty_unlocked)
	_refresh_hud()


func _on_duty_unlocked(family: StringName, _duty: StringName) -> void:
	if family == &"T":
		_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if _over:
		if event.is_action_pressed("ui_cancel"):
			_back_to_research()
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key := event as InputEventKey
	match key.keycode:
		KEY_ESCAPE:
			_back_to_research()
		KEY_SPACE:
			_toggle_duty()
		KEY_R:
			_research_t_chain()
		KEY_U:
			_research_t_chain()


func _back_to_research() -> void:
	get_tree().change_scene_to_file("res://ui/research/research_network.tscn")


func _toggle_duty() -> void:
	if _t == null:
		return
	if not ResearchState.is_completed(NODE_MOBILE):
		_set_status("需要完成 BASE-T-04 移動資格。按 R 研究。")
		return
	if _t.duty == &"fixed":
		_t.transform_duty(&"mobile")
		_set_status("拔根完成。A / D 橫向推進。")
	else:
		_t.transform_duty(&"fixed")
		_set_status("扎根完成。適應型炮台開火中。")
	_refresh_hud()


func _research_t_chain() -> void:
	if not ResearchState.is_completed(NODE_FIXED):
		ResearchState.select_node(NODE_FIXED)
		if ResearchState.complete_node(NODE_FIXED):
			_set_status("BASE-T-03 固定炮台專精完成。再按 R 解鎖移動。")
		else:
			_set_status("無法研究 BASE-T-03。")
		_refresh_hud()
		return
	if not ResearchState.is_completed(NODE_MOBILE):
		ResearchState.select_node(NODE_MOBILE)
		if ResearchState.complete_node(NODE_MOBILE):
			_set_status("BASE-T-04 移動資格已授予。空白鍵切勤務。")
		else:
			_set_status("無法研究 BASE-T-04。")
		_refresh_hud()
		return
	_set_status("移動資格已擁有。空白鍵扎根／拔根。")


func _physics_process(delta: float) -> void:
	if _over:
		return
	_move_t(delta)
	_try_fire(delta)
	_spawn_cd -= delta
	if _spawn_cd <= 0.0:
		_spawn_cd = 2.4
		_spawn_bacterium()


func _move_t(_delta: float) -> void:
	if _t == null:
		return
	if _t.duty != &"mobile":
		_t.velocity = Vector3.ZERO
		_t.global_position.y = T_HOME.y
		_t.global_position.z = T_HOME.z
		return
	var axis := Input.get_axis("ui_left", "ui_right")
	_t.velocity = Vector3(axis * 6.4 * (1.0 + ResearchState.global_stat("moveSpeed")), 0.0, 0.0)
	_t.move_and_slide()
	_t.global_position.y = T_HOME.y
	_t.global_position.z = T_HOME.z
	_t.global_position.x = clampf(_t.global_position.x, -STRAFE_LIMIT, STRAFE_LIMIT)


func _try_fire(delta: float) -> void:
	_fire_cd -= delta
	if _fire_cd > 0.0 or _t == null:
		return
	var target := _nearest_bacterium()
	if target == null:
		return
	var from := _muzzle()
	var aim := target.global_position - from
	aim.y = 0.0
	if aim.length() > FIRE_RANGE:
		return
	var base_cd := 0.55 if _t.duty == &"fixed" else 0.72
	var speed := 1.0 + ResearchState.global_stat("attackSpeed", _t.duty)
	_fire_cd = base_cd / maxf(speed, 0.25)
	_t.look_at(_t.global_position + Vector3(aim.x, 0.0, aim.z), Vector3.UP, true)
	_t.fire_skill(SKILL_T_ACTIVE)
	var bolt: _Bolt = _Bolt.new()
	add_child(bolt)
	bolt.global_position = from
	bolt.velocity = aim.normalized() * _Bolt.SPEED


func _muzzle() -> Vector3:
	if _t != null and _t.weapon_socket != null:
		return _t.weapon_socket.global_position
	return _t.global_position + Vector3(0.0, 0.2, 0.55)


func _nearest_bacterium() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("bacterium"):
		if not node is Node3D:
			continue
		var body := node as Node3D
		var d := _muzzle().distance_to(body.global_position)
		if d < best_d:
			best_d = d
			best = body
	return best


func _spawn_bacterium() -> void:
	var bug: CharacterBody3D = _Bacterium.new()
	add_child(bug)
	bug.core = _core
	bug.global_position = Vector3(randf_range(-0.6, 0.6), 0.38, SPAWN_Z)
	bug.died.connect(_on_kill)


func _on_kill() -> void:
	_kills += 1
	_refresh_hud()


func _on_core_hit(hp: int, max_hp: int) -> void:
	_refresh_hud()
	if hp <= 0:
		_fail()
	elif hp < max_hp:
		_set_status("核心受損 %d/%d" % [hp, max_hp])


func _fail() -> void:
	_over = true
	_set_status("核心失守。Esc 回研究網絡。")
	_refresh_hud()


func _build_stage() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.02, 0.04, 0.06)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.5, 0.62, 0.7)
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_white = 3.0
	env.environment = environment
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 11.2, 13.6)
	camera.rotation_degrees = Vector3(-42, 0, 0)
	camera.current = true
	add_child(camera)

	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(16, 0.2, 32)
	var floor_mi := MeshInstance3D.new()
	floor_mi.mesh = floor_mesh
	floor_mi.position = Vector3(0.0, -0.1, 2.0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.07, 0.05, 0.06)
	floor_mat.roughness = 0.9
	floor_mi.material_override = floor_mat
	floor_body.add_child(floor_mi)
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(16, 0.2, 32)
	var floor_col := CollisionShape3D.new()
	floor_col.shape = floor_shape
	floor_col.position = Vector3(0.0, -0.1, 2.0)
	floor_body.add_child(floor_col)
	add_child(floor_body)

	# Tissue path is a level prop, never attached to the T-cell kit.
	var lane := MeshInstance3D.new()
	var lane_mesh := BoxMesh.new()
	lane_mesh.size = Vector3(2.2, 0.04, 26)
	lane.mesh = lane_mesh
	lane.position = Vector3(0.0, 0.02, 2.0)
	var lane_mat := StandardMaterial3D.new()
	lane_mat.albedo_color = Color(0.42, 0.16, 0.18, 0.85)
	lane_mat.emission_enabled = true
	lane_mat.emission = Color(0.35, 0.08, 0.1)
	lane_mat.emission_energy_multiplier = 0.12
	lane.material_override = lane_mat
	add_child(lane)


func _spawn_core() -> void:
	_core = _Core.new()
	_core.position = Vector3(0.0, 0.7, -10.2)
	_core.hp_changed.connect(_on_core_hit)
	_core.breached.connect(_fail)
	add_child(_core)


func _spawn_t() -> void:
	var packed := load(T_SCENE) as PackedScene
	if packed == null:
		push_error("Missing T-cell scene: %s" % T_SCENE)
		return
	_t = packed.instantiate() as _TCell
	if _t == null:
		push_error("CHAR-BASE-T did not instantiate")
		return
	_t.position = T_HOME
	add_child(_t)
	_t.transform_duty(&"fixed")


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.offset_left = 24
	panel.offset_top = 18
	panel.add_theme_constant_override("separation", 6)
	layer.add_child(panel)
	_hud = Label.new()
	_hud.add_theme_font_size_override("font_size", 20)
	_hud.add_theme_color_override("font_color", _Tokens.TEXT)
	panel.add_child(_hud)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_color", _Tokens.CYAN)
	_status.text = "T 細胞駐守中。R 研究 BASE-T-03／04，空白鍵切勤務，Esc 回星盤。"
	panel.add_child(_status)


func _refresh_hud() -> void:
	if _hud == null or _core == null:
		return
	var duty := "駐守"
	if _t != null and _t.duty == &"mobile":
		duty = "移動"
	var mobile_ready := "已解鎖" if ResearchState.is_completed(NODE_MOBILE) else "未解鎖"
	_hud.text = "戰鬥切片 · 核心 %d/%d · 擊殺 %d · T 勤務 %s · 移動 %s" % [
		_core.hp,
		_Core.MAX_HP,
		_kills,
		duty,
		mobile_ready,
	]


func _set_status(text: String) -> void:
	if _status:
		_status.text = text
