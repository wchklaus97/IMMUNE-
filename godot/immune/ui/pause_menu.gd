class_name ImmunePauseMenu
extends CanvasLayer

signal restart_requested
signal research_requested

var _overlay: Control
var _resume_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build_ui()
	SettingsState.input_device_changed.connect(_refresh_prompts)
	visible = false


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


func _build_ui() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.008, 0.018, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 600)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := Label.new()
	title.text = "暫停／設定"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	for bus_name in ["Master", "Music", "SFX", "UI"]:
		box.add_child(_volume_row(bus_name))
	var shake := CheckButton.new()
	shake.text = "鏡頭震動"
	shake.button_pressed = SettingsState.screen_shake_enabled
	shake.toggled.connect(SettingsState.set_screen_shake)
	box.add_child(shake)
	var reduced := CheckButton.new()
	reduced.text = "減少動態效果"
	reduced.button_pressed = SettingsState.reduced_motion
	reduced.toggled.connect(SettingsState.set_reduced_motion)
	box.add_child(reduced)
	_resume_button = Button.new()
	_resume_button.custom_minimum_size.y = 48
	_resume_button.pressed.connect(func() -> void: set_open(false))
	box.add_child(_resume_button)
	var restart := Button.new()
	restart.text = "重新開始任務"
	restart.custom_minimum_size.y = 48
	restart.pressed.connect(_on_restart)
	box.add_child(restart)
	var research := Button.new()
	research.text = "返回任務選擇"
	research.custom_minimum_size.y = 48
	research.pressed.connect(_on_research)
	box.add_child(research)


func _volume_row(bus_name: String) -> Control:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = bus_name
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
	return row


func _refresh_prompts(_is_gamepad: bool) -> void:
	if _resume_button:
		_resume_button.text = "%s · 繼續" % SettingsState.prompt(&"demo_pause")


func _on_restart() -> void:
	set_open(false)
	restart_requested.emit()


func _on_research() -> void:
	set_open(false)
	research_requested.emit()
