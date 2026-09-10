extends Node

signal settings_changed
signal input_device_changed(is_gamepad: bool)

const CONFIG_PATH := "user://immune_settings.cfg"
const DEFAULT_VOLUMES := {"Master": 0.9, "Music": 0.55, "SFX": 0.8, "UI": 0.75}
const SUPPORTED_LOCALES: PackedStringArray = ["zh_HK", "en"]

var screen_shake_enabled: bool = true
var reduced_motion: bool = false
var onboarding_seen: bool = false
var is_using_gamepad: bool = false
var locale_code: String = "zh_HK"
var _volumes: Dictionary = DEFAULT_VOLUMES.duplicate(true)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_demo_actions()
	load_settings()
	_apply_all()


func _input(event: InputEvent) -> void:
	var next_gamepad := is_using_gamepad
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		next_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		next_gamepad = false
	if next_gamepad != is_using_gamepad:
		is_using_gamepad = next_gamepad
		input_device_changed.emit(is_using_gamepad)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	for bus_name in DEFAULT_VOLUMES.keys():
		_volumes[bus_name] = clampf(float(config.get_value("audio", bus_name, DEFAULT_VOLUMES[bus_name])), 0.0, 1.0)
	screen_shake_enabled = bool(config.get_value("accessibility", "screen_shake", true))
	reduced_motion = bool(config.get_value("accessibility", "reduced_motion", false))
	locale_code = _normalized_locale(str(config.get_value("language", "locale", "zh_HK")))
	onboarding_seen = bool(config.get_value("progress", "onboarding_seen", false))


func save_settings() -> Error:
	var config := ConfigFile.new()
	for bus_name in _volumes.keys():
		config.set_value("audio", bus_name, _volumes[bus_name])
	config.set_value("accessibility", "screen_shake", screen_shake_enabled)
	config.set_value("accessibility", "reduced_motion", reduced_motion)
	config.set_value("language", "locale", locale_code)
	config.set_value("progress", "onboarding_seen", onboarding_seen)
	var err := config.save(CONFIG_PATH)
	if err != OK:
		push_error("SettingsState: cannot save %s (%s)" % [CONFIG_PATH, error_string(err)])
	return err


func set_bus_volume(bus_name: String, linear: float, persist: bool = true) -> void:
	if not DEFAULT_VOLUMES.has(bus_name):
		return
	_volumes[bus_name] = clampf(linear, 0.0, 1.0)
	_apply_bus(bus_name)
	settings_changed.emit()
	if persist:
		save_settings()


func bus_volume(bus_name: String) -> float:
	return float(_volumes.get(bus_name, 1.0))


func set_screen_shake(enabled: bool) -> void:
	screen_shake_enabled = enabled
	settings_changed.emit()
	save_settings()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	settings_changed.emit()
	save_settings()


func set_locale(next_locale: String) -> void:
	var normalized := _normalized_locale(next_locale)
	if normalized == locale_code and TranslationServer.get_locale() == normalized:
		return
	locale_code = normalized
	TranslationServer.set_locale(locale_code)
	settings_changed.emit()
	save_settings()


func mark_onboarding_seen() -> void:
	if onboarding_seen:
		return
	onboarding_seen = true
	save_settings()


func prompt(action: StringName) -> String:
	var gamepad := {
		&"demo_pause": "Menu",
		&"demo_toggle_duty": "A",
		&"demo_research": "Y",
		&"demo_back": "B",
		&"demo_combat": "X",
		&"demo_confirm": "A",
		&"demo_next_family": "RB",
		&"demo_prev_family": "LB",
		&"demo_active_skill": "RB",
	}
	var keyboard := {
		&"demo_pause": "Esc",
		&"demo_toggle_duty": "Space",
		&"demo_research": "R",
		&"demo_back": "Esc",
		&"demo_combat": "C",
		&"demo_confirm": "Enter",
		&"demo_next_family": "E",
		&"demo_prev_family": "Q",
		&"demo_active_skill": "E",
	}
	return str(gamepad.get(action, "A")) if is_using_gamepad else str(keyboard.get(action, "?"))


func _apply_all() -> void:
	TranslationServer.set_locale(locale_code)
	for bus_name in _volumes.keys():
		_apply_bus(bus_name)


func _normalized_locale(value: String) -> String:
	if value.begins_with("zh"):
		return "zh_HK"
	if value.begins_with("en"):
		return "en"
	return "zh_HK"


func _apply_bus(bus_name: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_warning("SettingsState: missing audio bus %s" % bus_name)
		return
	var linear := bus_volume(bus_name)
	AudioServer.set_bus_mute(index, linear <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.001)))


func _ensure_demo_actions() -> void:
	_add_action(&"demo_pause", KEY_ESCAPE, JOY_BUTTON_START)
	_add_action(&"demo_confirm", KEY_ENTER, JOY_BUTTON_A)
	_add_action(&"demo_next_family", KEY_E, JOY_BUTTON_RIGHT_SHOULDER)
	_add_action(&"demo_prev_family", KEY_Q, JOY_BUTTON_LEFT_SHOULDER)
	_add_action(&"demo_active_skill", KEY_E, JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_button(&"demo_back", JOY_BUTTON_B)
	_add_joy_button(&"demo_toggle_duty", JOY_BUTTON_A)
	_add_joy_button(&"demo_research", JOY_BUTTON_Y)
	_add_joy_button(&"demo_combat", JOY_BUTTON_X)
	_add_joy_axis(&"demo_move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis(&"demo_move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis(&"demo_move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis(&"demo_move_back", JOY_AXIS_LEFT_Y, 1.0)


func _add_action(action: StringName, keycode: Key, joy_button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
		var key := InputEventKey.new()
		key.physical_keycode = keycode
		InputMap.action_add_event(action, key)
	_add_joy_button(action, joy_button)


func _add_joy_button(action: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadButton and (existing as InputEventJoypadButton).button_index == button:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func _add_joy_axis(action: StringName, axis: JoyAxis, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	else:
		InputMap.action_set_deadzone(action, 0.2)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadMotion:
			var motion := existing as InputEventJoypadMotion
			if motion.axis == axis and is_equal_approx(signf(motion.axis_value), signf(value)):
				return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)
