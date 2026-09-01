extends Node3D

const _Content := preload("res://resources/combat/combat_content.gd")
const _Look := preload("res://characters/family_look.gd")
const _Responsive := preload("res://ui/responsive_layout.gd")
const _GelStudio := preload("res://characters/gel/gel_studio_environment.gd")
const RESEARCH_SCENE := "res://ui/research/research_network.tscn"
const FAMILIES: PackedStringArray = ["T", "B", "M", "N", "A", "D"]
const PREVIEW_SCALE := {
	"T": 1.52,
	"B": 1.48,
	"M": 1.34,
	"N": 1.50,
	"A": 1.40,
	"D": 1.36,
}
const PREVIEW_Y := -0.12
const TEXT := Color("d8e9f4")
const MUTED := Color("91a8b8")
const ACCENT := Color("72e7ff")
const WARM := Color("f2c66d")

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
var _back_button: Button
var _mission_buttons: Array[Button] = []
var _family_buttons: Array[Button] = []
var _preview_stage: Node3D
var _preview_viewport: SubViewport
var _scroll: ScrollContainer
var _safe_margin: MarginContainer
var _columns: GridContainer
var _left_column: VBoxContainer
var _right_column: VBoxContainer
var _family_grid: GridContainer
var _heading: Label
var _subtitle: Label
var _family_label: Label
var _preview_space: Control
var _layout_scale := 1.0
var _safe_insets := Vector4.ZERO


func _ready() -> void:
	for mission_id in _Content.mission_ids():
		var mission := _Content.load_mission(mission_id)
		if mission:
			_missions.append(mission)
	_mission_index = maxi(_mission_index_for(ResearchState.selected_mission_id), 0)
	_family_index = maxi(FAMILIES.find(String(ResearchState.selected_family_id)), 0)
	_build_ui()
	_apply_responsive_layout(true)
	_refresh()
	AudioDirector.play_music()
	WebQaBridge.publish(&"mission_select_ready", {
		"mission": String(_missions[_mission_index].id) if not _missions.is_empty() else "",
		"family": FAMILIES[_family_index],
	})


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.disconnect(_on_viewport_size_changed)
	_shutdown_preview()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"demo_back"):
		_back()
	elif event.is_action_pressed(&"demo_confirm"):
		_start()
	elif event.is_action_pressed(&"demo_prev_family"):
		_select_family(posmod(_family_index - 1, FAMILIES.size()))
	elif event.is_action_pressed(&"demo_next_family"):
		_select_family((_family_index + 1) % FAMILIES.size())


func _build_preview_stage(host: Control) -> void:
	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.018, 0.035, 0.055, 0.96)
	frame_style.border_color = Color(0.18, 0.55, 0.68, 0.72)
	frame_style.set_border_width_all(1)
	frame_style.set_corner_radius_all(14)
	frame.add_theme_stylebox_override("panel", frame_style)
	host.add_child(frame)
	var viewport_container := SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(viewport_container)
	_preview_viewport = SubViewport.new()
	_preview_viewport.name = "CellPreviewViewport"
	_preview_viewport.size = Vector2i(800, 360)
	_preview_viewport.own_world_3d = true
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_preview_viewport.msaa_3d = Viewport.MSAA_2X
	viewport_container.add_child(_preview_viewport)
	_preview_stage = Node3D.new()
	_preview_stage.name = "CellPreviewStage"
	_preview_viewport.add_child(_preview_stage)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.008, 0.016, 0.028)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.46, 0.58, 0.72)
	environment.ambient_light_energy = 0.46
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	_GelStudio.apply_banner_preview(environment)
	env.environment = environment
	_preview_stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.name = "CellPreviewKey"
	key.rotation_degrees = Vector3(-40, -25, 0)
	# A near-neutral warm key keeps the gel inviting without shifting T/A/D red
	# or collapsing B/M purple. The material is colour-managed under this family
	# review light; a strongly amber key made the mission desk lie about the asset.
	key.light_color = Color(1.0, 0.95, 0.88)
	key.light_energy = 1.55
	key.shadow_enabled = true
	_preview_stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.name = "CellPreviewRim"
	rim.rotation_degrees = Vector3(-20, 155, 0)
	rim.light_color = Color(0.34, 0.58, 1.0)
	rim.light_energy = 0.85
	_preview_stage.add_child(rim)
	var fill := DirectionalLight3D.new()
	fill.name = "CellPreviewFill"
	fill.rotation_degrees = Vector3(-12, 62, 0)
	fill.light_color = Color(0.72, 0.82, 1.0)
	fill.light_energy = 0.32
	_preview_stage.add_child(fill)
	var camera := Camera3D.new()
	camera.name = "CellPreviewCamera"
	camera.position = Vector3(1.0, 1.45, 3.75)
	camera.fov = 29.5
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.55, 0.0), Vector3.UP)
	camera.current = true
	_preview_stage.add_child(camera)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var background := ColorRect.new()
	background.color = Color(0.005, 0.009, 0.015, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(background)
	_scroll = ScrollContainer.new()
	_scroll.name = "MissionScroll"
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	layer.add_child(_scroll)
	_safe_margin = MarginContainer.new()
	_safe_margin.name = "MissionSafeArea"
	_safe_margin.custom_minimum_size = Vector2(1268, 700)
	_safe_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_safe_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_safe_margin.add_theme_constant_override("margin_left", 42)
	_safe_margin.add_theme_constant_override("margin_top", 34)
	_safe_margin.add_theme_constant_override("margin_right", 42)
	_safe_margin.add_theme_constant_override("margin_bottom", 34)
	_scroll.add_child(_safe_margin)
	_columns = GridContainer.new()
	_columns.name = "MissionColumns"
	_columns.columns = 2
	_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_columns.add_theme_constant_override("h_separation", 34)
	_columns.add_theme_constant_override("v_separation", 34)
	_safe_margin.add_child(_columns)
	_left_column = VBoxContainer.new()
	_left_column.name = "MissionChoices"
	_left_column.custom_minimum_size.x = 650
	_left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_column.add_theme_constant_override("separation", 12)
	_columns.add_child(_left_column)
	_heading = Label.new()
	_heading.name = "MissionHeading"
	_heading.text = "UI_MISSION_HEADING"
	_heading.add_theme_font_size_override("font_size", 38)
	_heading.add_theme_color_override("font_color", TEXT)
	_left_column.add_child(_heading)
	_subtitle = Label.new()
	_subtitle.name = "MissionSubtitle"
	_subtitle.text = "UI_MISSION_SUBTITLE"
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.add_theme_color_override("font_color", MUTED)
	_left_column.add_child(_subtitle)
	for i in _missions.size():
		var button := Button.new()
		button.name = "MissionButton%d" % (i + 1)
		button.custom_minimum_size.y = 56
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		_style_button(button)
		button.pressed.connect(_select_mission.bind(i))
		_left_column.add_child(button)
		_mission_buttons.append(button)
	_family_label = Label.new()
	_family_label.name = "FamilyHeading"
	_family_label.text = "UI_FAMILY_HEADING"
	_family_label.add_theme_font_size_override("font_size", 23)
	_family_label.add_theme_color_override("font_color", TEXT)
	_left_column.add_child(_family_label)
	_family_grid = GridContainer.new()
	_family_grid.name = "MissionFamilyGrid"
	_family_grid.columns = 3
	_family_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_family_grid.add_theme_constant_override("h_separation", 8)
	_family_grid.add_theme_constant_override("v_separation", 8)
	_left_column.add_child(_family_grid)
	for i in FAMILIES.size():
		var button := Button.new()
		button.name = "Family%sButton" % FAMILIES[i]
		button.custom_minimum_size = Vector2(190, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		_style_button(button)
		button.pressed.connect(_select_family.bind(i))
		_family_grid.add_child(button)
		_family_buttons.append(button)
	_right_column = VBoxContainer.new()
	_right_column.name = "MissionPreviewAndActions"
	_right_column.custom_minimum_size.x = 500
	_right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_column.add_theme_constant_override("separation", 12)
	_columns.add_child(_right_column)
	_preview_space = Control.new()
	_preview_space.name = "MissionCellPreview"
	_preview_space.custom_minimum_size.y = 250
	_right_column.add_child(_preview_space)
	_build_preview_stage(_preview_space)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", TEXT)
	_right_column.add_child(_title)
	_difficulty = Label.new()
	_difficulty.add_theme_font_size_override("font_size", 18)
	_difficulty.add_theme_color_override("font_color", WARM)
	_right_column.add_child(_difficulty)
	_briefing = Label.new()
	_briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_briefing.custom_minimum_size.y = 70
	_briefing.add_theme_color_override("font_color", MUTED)
	_right_column.add_child(_briefing)
	_family_title = Label.new()
	_family_title.add_theme_font_size_override("font_size", 24)
	_family_title.add_theme_color_override("font_color", ACCENT)
	_right_column.add_child(_family_title)
	_family_role = Label.new()
	_family_role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_family_role.add_theme_color_override("font_color", TEXT)
	_right_column.add_child(_family_role)
	_start_button = Button.new()
	_start_button.name = "MissionStartButton"
	_start_button.custom_minimum_size.y = 58
	_style_button(_start_button, true)
	_start_button.pressed.connect(_start)
	_right_column.add_child(_start_button)
	_back_button = Button.new()
	_back_button.name = "MissionBackButton"
	_back_button.custom_minimum_size.y = 48
	_style_button(_back_button)
	_back_button.pressed.connect(_back)
	_right_column.add_child(_back_button)
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	SettingsState.input_device_changed.connect(func(_gamepad: bool) -> void: _refresh())
	SettingsState.settings_changed.connect(_refresh)


func _on_viewport_size_changed() -> void:
	call_deferred("_apply_responsive_layout")


func _apply_responsive_layout(force: bool = false) -> void:
	if _safe_margin == null or not is_instance_valid(_safe_margin):
		return
	var narrow := _Responsive.is_narrow_phone(get_viewport())
	var next_scale := _Responsive.layout_scale(get_viewport())
	var next_insets := _Responsive.logical_safe_insets(get_viewport())
	if (
		not force
		and is_equal_approx(next_scale, _layout_scale)
		and next_insets.is_equal_approx(_safe_insets)
	):
		return
	_layout_scale = next_scale
	_safe_insets = next_insets
	if narrow:
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		_safe_margin.custom_minimum_size = Vector2.ZERO
		_set_safe_margins(18, 18, 18, 18)
		_columns.columns = 1
		_columns.add_theme_constant_override("h_separation", _metric(18))
		_columns.add_theme_constant_override("v_separation", _metric(18))
		_left_column.custom_minimum_size.x = 0
		_right_column.custom_minimum_size.x = 0
		_left_column.add_theme_constant_override("separation", _metric(10))
		_right_column.add_theme_constant_override("separation", _metric(10))
		_heading.add_theme_font_size_override("font_size", _metric(30))
		_subtitle.add_theme_font_size_override("font_size", _metric(17))
		_family_label.add_theme_font_size_override("font_size", _metric(20))
		_family_grid.columns = 2
		_family_grid.add_theme_constant_override("h_separation", _metric(6))
		_family_grid.add_theme_constant_override("v_separation", _metric(6))
		_preview_space.custom_minimum_size.y = _metric(150)
		_title.add_theme_font_size_override("font_size", _metric(24))
		_difficulty.add_theme_font_size_override("font_size", _metric(17))
		_briefing.add_theme_font_size_override("font_size", _metric(17))
		_briefing.custom_minimum_size.y = _metric(60)
		_family_title.add_theme_font_size_override("font_size", _metric(20))
		_family_role.add_theme_font_size_override("font_size", _metric(17))
		for button in _mission_buttons:
			button.custom_minimum_size = Vector2(0, _metric(53))
			button.add_theme_font_size_override("font_size", _metric(17))
		for button in _family_buttons:
			button.custom_minimum_size = Vector2(0, _metric(53))
			button.add_theme_font_size_override("font_size", _metric(16))
		_start_button.custom_minimum_size.y = _metric(53)
		_back_button.custom_minimum_size.y = _metric(53)
		_start_button.add_theme_font_size_override("font_size", _metric(17))
		_back_button.add_theme_font_size_override("font_size", _metric(17))
	else:
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_safe_margin.custom_minimum_size = Vector2(_metric(1268), _metric(700))
		_set_safe_margins(42, 34, 42, 34)
		_columns.columns = 2
		_columns.add_theme_constant_override("h_separation", _metric(34))
		_columns.add_theme_constant_override("v_separation", _metric(34))
		_left_column.custom_minimum_size.x = _metric(650)
		_right_column.custom_minimum_size.x = _metric(500)
		_left_column.add_theme_constant_override("separation", _metric(12))
		_right_column.add_theme_constant_override("separation", _metric(12))
		_heading.add_theme_font_size_override("font_size", _metric(38))
		_subtitle.add_theme_font_size_override("font_size", _metric(16))
		_family_label.add_theme_font_size_override("font_size", _metric(23))
		_family_grid.columns = 3
		_family_grid.add_theme_constant_override("h_separation", _metric(8))
		_family_grid.add_theme_constant_override("v_separation", _metric(8))
		_preview_space.custom_minimum_size.y = _metric(250)
		_title.add_theme_font_size_override("font_size", _metric(30))
		_difficulty.add_theme_font_size_override("font_size", _metric(18))
		_briefing.add_theme_font_size_override("font_size", _metric(16))
		_briefing.custom_minimum_size.y = _metric(70)
		_family_title.add_theme_font_size_override("font_size", _metric(24))
		_family_role.add_theme_font_size_override("font_size", _metric(16))
		for button in _mission_buttons:
			button.custom_minimum_size = Vector2(0, _metric(56))
			button.add_theme_font_size_override("font_size", _metric(16))
		for button in _family_buttons:
			button.custom_minimum_size = Vector2(_metric(190), _metric(48))
			button.add_theme_font_size_override("font_size", _metric(16))
		_start_button.custom_minimum_size.y = _metric(58)
		_back_button.custom_minimum_size.y = _metric(48)
		_start_button.add_theme_font_size_override("font_size", _metric(16))
		_back_button.add_theme_font_size_override("font_size", _metric(16))
	for button in _mission_buttons:
		_style_button(button)
	for button in _family_buttons:
		_style_button(button)
	_style_button(_start_button, true)
	_style_button(_back_button)
	_safe_margin.queue_redraw()


func _set_safe_margins(left: int, top: int, right: int, bottom: int) -> void:
	_safe_margin.add_theme_constant_override("margin_left", _metric(left) + roundi(_safe_insets.x))
	_safe_margin.add_theme_constant_override("margin_top", _metric(top) + roundi(_safe_insets.y))
	_safe_margin.add_theme_constant_override("margin_right", _metric(right) + roundi(_safe_insets.z))
	_safe_margin.add_theme_constant_override("margin_bottom", _metric(bottom) + roundi(_safe_insets.w))


func _metric(value: int) -> int:
	return maxi(1, roundi(float(value) * _layout_scale))


func responsive_contract() -> Dictionary:
	var viewport_size := get_viewport().get_visible_rect().size
	var physical_size := _Responsive.physical_window_size()
	var narrow := _Responsive.is_narrow_phone(get_viewport())
	var compact := _Responsive.is_compact_landscape(get_viewport())
	var button_physical := minf(
		_Responsive.logical_height_to_physical(get_viewport(), _start_button.size.y),
		_Responsive.logical_height_to_physical(get_viewport(), _back_button.size.y)
	)
	var copy_physical := minf(
		_Responsive.logical_height_to_physical(
			get_viewport(), float(_subtitle.get_theme_font_size("font_size"))
		),
		_Responsive.logical_height_to_physical(
			get_viewport(), float(_briefing.get_theme_font_size("font_size"))
		)
	)
	var no_horizontal_scroll := (
		_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED
		and not _scroll.get_h_scroll_bar().visible
	)
	var safe_pass := (
		_safe_margin.get_theme_constant("margin_left") >= roundi(_safe_insets.x)
		and _safe_margin.get_theme_constant("margin_top") >= roundi(_safe_insets.y)
		and _safe_margin.get_theme_constant("margin_right") >= roundi(_safe_insets.z)
		and _safe_margin.get_theme_constant("margin_bottom") >= roundi(_safe_insets.w)
	)
	var layout_pass := true
	if narrow:
		layout_pass = (
			_columns.columns == 1
			and _family_grid.columns == 2
			and no_horizontal_scroll
			and button_physical >= 44.0
			and copy_physical >= 14.0
			and safe_pass
		)
	elif compact:
		layout_pass = (
			_columns.columns == 2
			and _family_grid.columns == 3
			and button_physical >= 44.0
			and copy_physical >= 14.0
			and safe_pass
		)
	return {
		"mode": "narrow-phone" if narrow else ("compact-landscape" if compact else "wide"),
		"physical": [physical_size.x, physical_size.y],
		"logical": [viewport_size.x, viewport_size.y],
		"layout_scale": _layout_scale,
		"safe_area_source": _Responsive.safe_area_source(),
		"safe_insets_logical": [_safe_insets.x, _safe_insets.y, _safe_insets.z, _safe_insets.w],
		"main_columns": _columns.columns,
		"family_columns": _family_grid.columns,
		"horizontal_scroll_disabled": no_horizontal_scroll,
		"minimum_action_height_physical": button_physical,
		"minimum_copy_size_physical": copy_physical,
		"safe_margins_pass": safe_pass,
		"all_pass": layout_pass,
	}


func _select_mission(index: int) -> void:
	_mission_index = clampi(index, 0, _missions.size() - 1)
	AudioDirector.play_sfx(&"ui")
	_refresh()


func _select_family(index: int) -> void:
	_family_index = clampi(index, 0, FAMILIES.size() - 1)
	AudioDirector.play_sfx(&"ui", 1.0 + float(_family_index) * 0.03)
	_refresh()
	WebQaBridge.publish(&"family_selected", {"family": FAMILIES[_family_index]})


func _refresh() -> void:
	if _missions.is_empty():
		return
	var mission := _missions[_mission_index]
	var family := StringName(FAMILIES[_family_index])
	var profile := _Content.load_family(family)
	var unlocked := _is_mission_unlocked(mission)
	_title.text = tr(mission.title)
	_briefing.text = tr(mission.briefing) if unlocked else "%s\n%s" % [tr(mission.briefing), tr("UI_MISSION_LOCKED")]
	_difficulty.text = tr("UI_DIFFICULTY") % [
		mission.difficulty.rank, tr(mission.difficulty.display_name), mission.defense_kills, mission.cleanse_seconds
	]
	var family_name := tr(str(_Look.DISPLAY_NAME.get(String(family), String(family))))
	_family_title.text = "%s · %s" % [family_name, tr(profile.role_name)]
	_family_role.text = "%s\n%s" % [tr(profile.role_description), tr("UI_FAMILY_STATS") % [
		tr(profile.signature_name), tr(profile.signature_description),
		profile.projectile_damage, profile.fire_range, profile.move_speed
	]]
	_start_button.disabled = not unlocked
	_start_button.text = (
		tr("UI_START_MISSION") % [SettingsState.prompt(&"demo_confirm"), family_name]
		if unlocked else tr("UI_COMPLETE_TO_UNLOCK")
	)
	_back_button.text = tr("UI_BACK_RESEARCH") % SettingsState.prompt(&"demo_back")
	for i in _mission_buttons.size():
		var button := _mission_buttons[i]
		var completed := ResearchState.completed_mission_ids.has(_missions[i].id)
		var mission_unlocked := _is_mission_unlocked(_missions[i])
		button.disabled = not mission_unlocked
		var badge := tr("UI_MISSION_BADGE_COMPLETE") if completed else (tr("UI_MISSION_BADGE_LOCKED") if not mission_unlocked else "")
		button.text = "%s%s" % [tr(_missions[i].title), badge]
		button.button_pressed = i == _mission_index
	for i in _family_buttons.size():
		var id := String(FAMILIES[i])
		_family_buttons[i].text = "%s%s" % [tr(str(_Look.DISPLAY_NAME.get(id, id))), "  ●" if i == _family_index else ""]
	_refresh_preview(family)


func _refresh_preview(family: StringName) -> void:
	if _preview and is_instance_valid(_preview):
		var old_parent := _preview.get_parent()
		if old_parent != null:
			old_parent.remove_child(_preview)
		_preview.queue_free()
	if _preview_stage == null:
		return
	var scene := load(str(_Look.SCENE_PATH.get(String(family), _Look.SCENE_PATH["T"]))) as PackedScene
	if scene == null:
		return
	_preview = scene.instantiate() as ImmuneCharacter
	if _preview == null:
		return
	_preview.position = Vector3(0.0, PREVIEW_Y, 0.0)
	_preview.rotation_degrees.y = -18
	_preview.scale = Vector3.ONE * float(PREVIEW_SCALE.get(String(family), 1.45))
	_preview_stage.add_child(_preview)
	# The desk is a family/silhouette review, not a combat-duty preview. The
	# authored bodies already initialize in fixed duty; forcing mobile here added
	# legacy wheel/relay props below the new feet and made the banner match look
	# broken before a mission had even started.


func _shutdown_preview() -> void:
	if _preview_viewport and is_instance_valid(_preview_viewport):
		_preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if _preview and is_instance_valid(_preview):
		_preview.queue_free()
	_preview = null


func _style_button(button: Button, primary: bool = false) -> void:
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.46, 0.54, 0.60, 1.0))
	button.add_theme_stylebox_override("normal", _button_box(
		Color(0.035, 0.060, 0.080, 0.96), Color(0.12, 0.33, 0.42, 0.86), 1
	))
	button.add_theme_stylebox_override("hover", _button_box(
		Color(0.055, 0.120, 0.155, 0.98), ACCENT, 1
	))
	button.add_theme_stylebox_override("pressed", _button_box(
		Color(0.075, 0.185, 0.225, 0.98) if not primary else Color(0.08, 0.25, 0.30, 0.98),
		ACCENT, 2
	))
	button.add_theme_stylebox_override("focus", _button_box(Color.TRANSPARENT, ACCENT, 2))
	button.add_theme_stylebox_override("disabled", _button_box(
		Color(0.024, 0.033, 0.045, 0.92), Color(0.08, 0.12, 0.15, 0.75), 1
	))


func _button_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(_metric(border_width))
	box.set_corner_radius_all(_metric(8))
	box.content_margin_left = float(_metric(14))
	box.content_margin_right = float(_metric(14))
	box.content_margin_top = float(_metric(8))
	box.content_margin_bottom = float(_metric(8))
	return box


func _start() -> void:
	if _missions.is_empty():
		return
	var mission := _missions[_mission_index]
	if not _is_mission_unlocked(mission):
		return
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


func _is_mission_unlocked(mission: ImmuneMissionData) -> bool:
	return (
		mission.required_mission_id == &""
		or ResearchState.completed_mission_ids.has(mission.required_mission_id)
	)
