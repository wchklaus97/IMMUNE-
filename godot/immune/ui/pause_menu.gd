class_name ImmunePauseMenu
extends CanvasLayer

signal restart_requested
signal research_requested

const _Responsive := preload("res://ui/responsive_layout.gd")

var _overlay: Control
var _resume_button: Button
var _locale_button: OptionButton
var _locale_codes: PackedStringArray = ["zh_HK", "en"]
var _safe_margin: MarginContainer
var _panel: PanelContainer
var _box: VBoxContainer
var _title: Label
var _language_label: Label
var _language_row: HBoxContainer
var _restart_button: Button
var _research_button: Button
var _volume_rows: Array[HBoxContainer] = []
var _volume_labels: Array[Label] = []
var _volume_sliders: Array[HSlider] = []
var _toggle_buttons: Array[CheckButton] = []
var _layout_scale := 1.0
var _safe_insets := Vector4.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build_ui()
	_apply_responsive_layout(true)
	SettingsState.input_device_changed.connect(_refresh_prompts)
	SettingsState.settings_changed.connect(_refresh_copy)
	visible = false


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.disconnect(_on_viewport_size_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"demo_pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	set_open(not visible)


func set_open(open: bool) -> void:
	visible = open
	get_tree().paused = open
	if open and _resume_button:
		_resume_button.grab_focus()
	_refresh_prompts(SettingsState.is_using_gamepad)
	WebQaBridge.publish(&"pause_changed", {"open": open})


func _build_ui() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.008, 0.018, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(shade)
	_safe_margin = MarginContainer.new()
	_safe_margin.name = "PauseSafeArea"
	_safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(_safe_margin)
	var center := CenterContainer.new()
	center.name = "PauseCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_safe_margin.add_child(center)
	_panel = PanelContainer.new()
	_panel.name = "PausePanel"
	_panel.custom_minimum_size = Vector2(560, 660)
	center.add_child(_panel)
	_box = VBoxContainer.new()
	_box.name = "PauseSettings"
	_box.add_theme_constant_override("separation", 14)
	_panel.add_child(_box)
	_title = Label.new()
	_title.text = "UI_PAUSE_TITLE"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	_box.add_child(_title)
	for bus_name in ["Master", "Music", "SFX", "UI"]:
		_box.add_child(_volume_row(bus_name))
	var shake := CheckButton.new()
	shake.name = "ScreenShakeToggle"
	shake.text = "UI_SCREEN_SHAKE"
	shake.button_pressed = SettingsState.screen_shake_enabled
	shake.toggled.connect(SettingsState.set_screen_shake)
	_box.add_child(shake)
	_toggle_buttons.append(shake)
	var reduced := CheckButton.new()
	reduced.name = "ReducedMotionToggle"
	reduced.text = "UI_REDUCED_MOTION"
	reduced.button_pressed = SettingsState.reduced_motion
	reduced.toggled.connect(SettingsState.set_reduced_motion)
	_box.add_child(reduced)
	_toggle_buttons.append(reduced)
	_language_row = HBoxContainer.new()
	_language_row.name = "LanguageRow"
	_language_row.add_theme_constant_override("separation", 10)
	_language_label = Label.new()
	_language_label.text = "UI_LANGUAGE"
	_language_label.custom_minimum_size.x = 160
	_language_row.add_child(_language_label)
	_locale_button = OptionButton.new()
	_locale_button.name = "LocaleButton"
	_locale_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_locale_button.custom_minimum_size.y = 44
	_locale_button.add_item("繁體中文（香港）")
	_locale_button.add_item("English")
	_locale_button.item_selected.connect(_on_locale_selected)
	_language_row.add_child(_locale_button)
	_box.add_child(_language_row)
	_resume_button = Button.new()
	_resume_button.name = "ResumeButton"
	_resume_button.custom_minimum_size.y = 48
	_resume_button.pressed.connect(func() -> void: set_open(false))
	_box.add_child(_resume_button)
	_restart_button = Button.new()
	_restart_button.name = "RestartButton"
	_restart_button.text = "UI_RESTART_MISSION"
	_restart_button.custom_minimum_size.y = 48
	_restart_button.pressed.connect(_on_restart)
	_box.add_child(_restart_button)
	_research_button = Button.new()
	_research_button.name = "ReturnMissionsButton"
	_research_button.text = "UI_RETURN_MISSIONS"
	_research_button.custom_minimum_size.y = 48
	_research_button.pressed.connect(_on_research)
	_box.add_child(_research_button)
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	_refresh_copy()


func _volume_row(bus_name: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "%sVolumeRow" % bus_name
	var label := Label.new()
	label.text = "UI_VOLUME_%s" % bus_name.to_upper()
	label.custom_minimum_size.x = 110
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = SettingsState.bus_volume(bus_name)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(300, 44)
	slider.value_changed.connect(func(value: float) -> void: SettingsState.set_bus_volume(bus_name, value, false))
	slider.drag_ended.connect(func(_changed: bool) -> void: SettingsState.save_settings())
	row.add_child(slider)
	_volume_rows.append(row)
	_volume_labels.append(label)
	_volume_sliders.append(slider)
	return row


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
		_set_safe_margins(12)
		var viewport_size := get_viewport().get_visible_rect().size
		var available := Vector2(
			viewport_size.x - _safe_insets.x - _safe_insets.z - float(_metric(24)),
			viewport_size.y - _safe_insets.y - _safe_insets.w - float(_metric(24))
		)
		_panel.custom_minimum_size = Vector2(
			maxf(1.0, minf(float(_metric(560)), available.x)),
			maxf(1.0, minf(float(_metric(660)), available.y))
		)
		_box.add_theme_constant_override("separation", _metric(10))
		_title.add_theme_font_size_override("font_size", _metric(28))
		_language_label.custom_minimum_size.x = _metric(130)
		_language_label.add_theme_font_size_override("font_size", _metric(17))
		_language_row.add_theme_constant_override("separation", _metric(10))
		_locale_button.custom_minimum_size.y = _metric(53)
		_locale_button.add_theme_font_size_override("font_size", _metric(17))
		for index in _volume_rows.size():
			_volume_rows[index].custom_minimum_size.y = _metric(53)
			_volume_labels[index].custom_minimum_size.x = _metric(110)
			_volume_labels[index].add_theme_font_size_override("font_size", _metric(17))
			_volume_sliders[index].custom_minimum_size = Vector2(0, _metric(53))
		for toggle in _toggle_buttons:
			toggle.custom_minimum_size.y = _metric(53)
			toggle.add_theme_font_size_override("font_size", _metric(17))
		for button in [_resume_button, _restart_button, _research_button]:
			button.custom_minimum_size.y = _metric(53)
			button.add_theme_font_size_override("font_size", _metric(17))
	else:
		_set_safe_margins(0)
		_panel.custom_minimum_size = Vector2(_metric(560), _metric(660))
		_box.add_theme_constant_override("separation", _metric(14))
		_title.add_theme_font_size_override("font_size", _metric(32))
		_language_label.custom_minimum_size.x = _metric(160)
		_language_label.add_theme_font_size_override("font_size", _metric(16))
		_language_row.add_theme_constant_override("separation", _metric(10))
		_locale_button.custom_minimum_size.y = _metric(44)
		_locale_button.add_theme_font_size_override("font_size", _metric(16))
		for index in _volume_rows.size():
			_volume_rows[index].custom_minimum_size.y = _metric(44)
			_volume_labels[index].custom_minimum_size.x = _metric(110)
			_volume_labels[index].add_theme_font_size_override("font_size", _metric(16))
			_volume_sliders[index].custom_minimum_size = Vector2(_metric(300), _metric(44))
		for toggle in _toggle_buttons:
			toggle.custom_minimum_size.y = _metric(48)
			toggle.add_theme_font_size_override("font_size", _metric(16))
		for button in [_resume_button, _restart_button, _research_button]:
			button.custom_minimum_size.y = _metric(48)
			button.add_theme_font_size_override("font_size", _metric(16))


func _set_safe_margins(base: int) -> void:
	_safe_margin.add_theme_constant_override("margin_left", _metric(base) + roundi(_safe_insets.x))
	_safe_margin.add_theme_constant_override("margin_top", _metric(base) + roundi(_safe_insets.y))
	_safe_margin.add_theme_constant_override("margin_right", _metric(base) + roundi(_safe_insets.z))
	_safe_margin.add_theme_constant_override("margin_bottom", _metric(base) + roundi(_safe_insets.w))


func _metric(value: int) -> int:
	if value == 0:
		return 0
	return maxi(1, roundi(float(value) * _layout_scale))


func responsive_contract() -> Dictionary:
	var narrow := _Responsive.is_narrow_phone(get_viewport())
	var compact := _Responsive.is_compact_landscape(get_viewport())
	var physical := _Responsive.physical_window_size()
	var viewport_size := get_viewport().get_visible_rect().size
	var min_action_height := INF
	var action_controls: Array[Control] = [
		_locale_button,
		_resume_button,
		_restart_button,
		_research_button,
	]
	action_controls.append_array(_toggle_buttons)
	for control in action_controls:
		min_action_height = minf(
			min_action_height,
			_Responsive.logical_height_to_physical(
				get_viewport(), maxf(control.size.y, control.custom_minimum_size.y)
			)
		)
	for slider in _volume_sliders:
		min_action_height = minf(
			min_action_height,
			_Responsive.logical_height_to_physical(
				get_viewport(), maxf(slider.size.y, slider.custom_minimum_size.y)
			)
		)
	var copy_physical := _Responsive.logical_height_to_physical(
		get_viewport(), float(_language_label.get_theme_font_size("font_size"))
	)
	var safe_pass := (
		_safe_margin.get_theme_constant("margin_left") >= roundi(_safe_insets.x)
		and _safe_margin.get_theme_constant("margin_top") >= roundi(_safe_insets.y)
		and _safe_margin.get_theme_constant("margin_right") >= roundi(_safe_insets.z)
		and _safe_margin.get_theme_constant("margin_bottom") >= roundi(_safe_insets.w)
	)
	var safe_rect := Rect2(
		Vector2(_safe_insets.x, _safe_insets.y),
		Vector2(
			viewport_size.x - _safe_insets.x - _safe_insets.z,
			viewport_size.y - _safe_insets.y - _safe_insets.w
		)
	)
	var required_panel_size := _panel.get_combined_minimum_size()
	var panel_fits_safe := (
		required_panel_size.x <= safe_rect.size.x + 1.0
		and required_panel_size.y <= safe_rect.size.y + 1.0
	)
	# A hidden CanvasLayer does not receive a final container layout until it is
	# shown. Validate its required size while hidden, then add the actual global
	# rectangle assertion whenever the production overlay is visible.
	var panel_inside_safe := (
		panel_fits_safe
		and (
			not visible
			or safe_rect.grow(1.0).encloses(_panel.get_global_rect())
		)
	)
	var all_pass := (
		not (narrow or compact)
		or (
			min_action_height >= 44.0
			and copy_physical >= 14.0
			and safe_pass
			and panel_inside_safe
		)
	)
	return {
		"mode": "narrow-phone" if narrow else ("compact-landscape" if compact else "wide"),
		"physical": [physical.x, physical.y],
		"logical": [viewport_size.x, viewport_size.y],
		"layout_scale": _layout_scale,
		"safe_area_source": _Responsive.safe_area_source(),
		"safe_insets_logical": [_safe_insets.x, _safe_insets.y, _safe_insets.z, _safe_insets.w],
		"minimum_action_height_physical": min_action_height,
		"minimum_copy_size_physical": copy_physical,
		"safe_margins_pass": safe_pass,
		"panel_inside_safe_area": panel_inside_safe,
		"all_pass": all_pass,
	}


func _refresh_prompts(_is_gamepad: bool) -> void:
	if _resume_button:
		_resume_button.text = tr("UI_RESUME") % SettingsState.prompt(&"demo_pause")


func _refresh_copy() -> void:
	_refresh_prompts(SettingsState.is_using_gamepad)
	if _locale_button:
		_locale_button.select(maxi(_locale_codes.find(SettingsState.locale_code), 0))


func _on_locale_selected(index: int) -> void:
	if index >= 0 and index < _locale_codes.size():
		SettingsState.set_locale(_locale_codes[index])


func _on_restart() -> void:
	set_open(false)
	restart_requested.emit()


func _on_research() -> void:
	set_open(false)
	research_requested.emit()
