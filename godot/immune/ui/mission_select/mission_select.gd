extends Node3D

const _Content := preload("res://resources/combat/combat_content.gd")
const _Look := preload("res://characters/family_look.gd")
const RESEARCH_SCENE := "res://ui/research/research_network.tscn"
const FAMILIES: PackedStringArray = ["T", "B", "M", "N", "A", "D"]

var _missions: Array[ImmuneMissionData] = []
var _mission_index: int = 0
var _family_index: int = 0
var _preview: ImmuneCharacter
var _title: Label
var _briefing: Label
var _difficulty: Label
var _family_title: Label
var _family_role: Label
var _start_button: Button
var _mission_buttons: Array[Button] = []
var _family_buttons: Array[Button] = []


func _ready() -> void:
	for mission_id in _Content.mission_ids():
		var mission := _Content.load_mission(mission_id)
		if mission:
			_missions.append(mission)
	_mission_index = maxi(_mission_index_for(ResearchState.selected_mission_id), 0)
	_family_index = maxi(FAMILIES.find(String(ResearchState.selected_family_id)), 0)
	_build_preview_stage()
	_build_ui()
	_refresh()
	AudioDirector.play_music()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"demo_back"):
		_back()
	elif event.is_action_pressed(&"demo_confirm"):
		_start()
	elif event.is_action_pressed(&"demo_prev_family"):
		_select_family(posmod(_family_index - 1, FAMILIES.size()))
	elif event.is_action_pressed(&"demo_next_family"):
		_select_family((_family_index + 1) % FAMILIES.size())


func _build_preview_stage() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.01, 0.015, 0.03)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.42, 0.5, 0.62)
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = environment
	add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, -25, 0)
	key.light_color = Color(1.0, 0.78, 0.58)
	key.light_energy = 1.2
	key.shadow_enabled = true
	add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 155, 0)
	rim.light_color = Color(0.34, 0.58, 1.0)
	rim.light_energy = 0.55
	add_child(rim)
	var camera := Camera3D.new()
	camera.position = Vector3(3.5, 2.4, 5.8)
	camera.look_at_from_position(camera.position, Vector3(2.8, 0.2, 0.0), Vector3.UP)
	camera.current = true
	add_child(camera)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	layer.add_child(scroll)
	var margin := MarginContainer.new()
	margin.custom_minimum_size = Vector2(1268, 700)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 34)
	scroll.add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 34)
	margin.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 650
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	columns.add_child(left)
	var heading := Label.new()
	heading.text = "免疫任務台"
	heading.add_theme_font_size_override("font_size", 38)
	left.add_child(heading)
	var sub := Label.new()
	sub.text = "選擇任務同細胞家族。六個家族都共用 wet-gel 材質同 duty 動畫管線。"
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(sub)
	for i in _missions.size():
		var button := Button.new()
		button.custom_minimum_size.y = 56
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select_mission.bind(i))
		left.add_child(button)
		_mission_buttons.append(button)
	var family_label := Label.new()
	family_label.text = "出擊細胞"
	family_label.add_theme_font_size_override("font_size", 23)
	left.add_child(family_label)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	left.add_child(grid)
	for i in FAMILIES.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(190, 48)
		button.pressed.connect(_select_family.bind(i))
		grid.add_child(button)
		_family_buttons.append(button)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 500
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)
	var preview_space := Control.new()
	preview_space.custom_minimum_size.y = 240
	right.add_child(preview_space)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 30)
	right.add_child(_title)
	_difficulty = Label.new()
	_difficulty.add_theme_font_size_override("font_size", 18)
	right.add_child(_difficulty)
	_briefing = Label.new()
	_briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_briefing.custom_minimum_size.y = 70
	right.add_child(_briefing)
	_family_title = Label.new()
	_family_title.add_theme_font_size_override("font_size", 24)
	right.add_child(_family_title)
	_family_role = Label.new()
	_family_role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_family_role)
	_start_button = Button.new()
	_start_button.custom_minimum_size.y = 58
	_start_button.pressed.connect(_start)
	right.add_child(_start_button)
	var back := Button.new()
	back.text = "%s · 返回研究網絡" % SettingsState.prompt(&"demo_back")
	back.custom_minimum_size.y = 48
	back.pressed.connect(_back)
	right.add_child(back)
	SettingsState.input_device_changed.connect(func(_gamepad: bool) -> void: _refresh())


func _select_mission(index: int) -> void:
	_mission_index = clampi(index, 0, _missions.size() - 1)
	AudioDirector.play_sfx(&"ui")
	_refresh()


func _select_family(index: int) -> void:
	_family_index = clampi(index, 0, FAMILIES.size() - 1)
	AudioDirector.play_sfx(&"ui", 1.0 + float(_family_index) * 0.03)
	_refresh()


func _refresh() -> void:
	if _missions.is_empty():
		return
	var mission := _missions[_mission_index]
	var family := StringName(FAMILIES[_family_index])
	var profile := _Content.load_family(family)
	_title.text = mission.title
	_briefing.text = mission.briefing
	_difficulty.text = "難度 %d · %s · 防守 %d 隻 · 淨化 %.1f 秒" % [
		mission.difficulty.rank, mission.difficulty.display_name, mission.defense_kills, mission.cleanse_seconds
	]
	_family_title.text = "%s · %s" % [_Look.DISPLAY_NAME.get(String(family), String(family)), profile.role_name]
	_family_role.text = "%s  傷害 %d · 射程 %.1f · 移速 %.1f" % [
		profile.role_description, profile.projectile_damage, profile.fire_range, profile.move_speed
	]
	_start_button.text = "%s · 以 %s 開始任務" % [SettingsState.prompt(&"demo_confirm"), _Look.DISPLAY_NAME.get(String(family), String(family))]
	for i in _mission_buttons.size():
		var button := _mission_buttons[i]
		var completed := ResearchState.completed_mission_ids.has(_missions[i].id)
		button.text = "%s%s" % [_missions[i].title, "  ✓" if completed else ""]
		button.button_pressed = i == _mission_index
	for i in _family_buttons.size():
		var id := String(FAMILIES[i])
		_family_buttons[i].text = "%s%s" % [_Look.DISPLAY_NAME.get(id, id), "  ●" if i == _family_index else ""]
	_refresh_preview(family)


func _refresh_preview(family: StringName) -> void:
	if _preview and is_instance_valid(_preview):
		_preview.queue_free()
	var scene := load(str(_Look.SCENE_PATH.get(String(family), _Look.SCENE_PATH["T"]))) as PackedScene
	if scene == null:
		return
	_preview = scene.instantiate() as ImmuneCharacter
	if _preview == null:
		return
	_preview.position = Vector3(2.8, 0.4, 0.0)
	_preview.rotation_degrees.y = -18
	add_child(_preview)
	_preview.transform_duty(&"mobile")


func _start() -> void:
	if _missions.is_empty():
		return
	var mission := _missions[_mission_index]
	var family := StringName(FAMILIES[_family_index])
	if not ResearchState.configure_demo_run(mission.id, family):
		push_error("MissionSelect: failed to persist selection")
		return
	AudioDirector.play_sfx(&"phase")
	var err := get_tree().change_scene_to_file(mission.scene_path)
	if err != OK:
		push_error("MissionSelect: cannot load %s" % mission.scene_path)


func _back() -> void:
	get_tree().change_scene_to_file(RESEARCH_SCENE)


func _mission_index_for(id: StringName) -> int:
	for i in _missions.size():
		if _missions[i].id == id:
			return i
	return 0
