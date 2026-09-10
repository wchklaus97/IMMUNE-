class_name CombatTouchControls
extends Control

## Reusable four-direction touch pad. It emits intent and never mutates InputMap.

signal movement_changed(direction: Vector2)

const DIRECTIONS := {
	&"left": Vector2.LEFT,
	&"right": Vector2.RIGHT,
	&"forward": Vector2.DOWN,
	&"back": Vector2.UP,
}
const LABELS := {
	&"left": "←",
	&"right": "→",
	&"forward": "↑",
	&"back": "↓",
}

var _pressed := {
	&"left": false,
	&"right": false,
	&"forward": false,
	&"back": false,
}
var _buttons: Dictionary = {}
var _panel: PanelContainer
var _movement_enabled := true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_pad()
	apply_layout(1.0, Vector4.ZERO, 94.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_all()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_release_all()


func apply_layout(layout_scale: float, safe_insets: Vector4, action_tray_height: float) -> void:
	if _panel == null:
		return
	var scale := maxf(layout_scale, 0.5)
	var button_size := roundf(54.0 * scale)
	var gap := roundf(8.0 * scale)
	var padding := roundf(10.0 * scale)
	for button in _buttons.values():
		(button as Button).custom_minimum_size = Vector2(button_size, button_size)
		(button as Button).add_theme_font_size_override("font_size", roundi(22.0 * scale))
	var width := button_size * 3.0 + gap * 2.0 + padding * 2.0
	var height := button_size * 2.0 + gap + padding * 2.0
	_panel.offset_left = roundf(18.0 * scale + safe_insets.x)
	_panel.offset_right = _panel.offset_left + width
	_panel.offset_bottom = -roundf(action_tray_height + 14.0 * scale + safe_insets.w)
	_panel.offset_top = _panel.offset_bottom - height
	var grid := _panel.get_node_or_null("DirectionGrid") as GridContainer
	if grid != null:
		grid.add_theme_constant_override("h_separation", roundi(gap))
		grid.add_theme_constant_override("v_separation", roundi(gap))


func set_movement_enabled(enabled: bool) -> void:
	_movement_enabled = enabled
	for button in _buttons.values():
		(button as Button).disabled = not enabled
	if not enabled:
		_release_all()


func set_direction_pressed(direction: StringName, pressed: bool) -> void:
	if not _pressed.has(direction):
		return
	_pressed[direction] = pressed and _movement_enabled
	movement_changed.emit(movement_vector())


func movement_vector() -> Vector2:
	var result := Vector2.ZERO
	for direction in DIRECTIONS:
		if bool(_pressed.get(direction, false)):
			result += DIRECTIONS[direction]
	return result.normalized() if result.length_squared() > 1.0 else result


func directional_button_count() -> int:
	return _buttons.size()


func minimum_button_height() -> float:
	var result := INF
	for button in _buttons.values():
		var control := button as Button
		result = minf(result, maxf(control.size.y, control.custom_minimum_size.y))
	return 0.0 if result == INF else result


func _build_pad() -> void:
	_panel = PanelContainer.new()
	_panel.name = "TouchDirectionPad"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = Color(0.01, 0.035, 0.055, 0.82)
	panel_box.border_color = Color(0.2, 0.9, 1.0, 0.5)
	panel_box.set_border_width_all(2)
	panel_box.set_corner_radius_all(18)
	panel_box.content_margin_left = 10.0
	panel_box.content_margin_right = 10.0
	panel_box.content_margin_top = 10.0
	panel_box.content_margin_bottom = 10.0
	_panel.add_theme_stylebox_override("panel", panel_box)
	var grid := GridContainer.new()
	grid.name = "DirectionGrid"
	grid.columns = 3
	_panel.add_child(grid)
	_add_spacer(grid)
	_add_direction_button(grid, &"forward")
	_add_spacer(grid)
	_add_direction_button(grid, &"left")
	_add_direction_button(grid, &"back")
	_add_direction_button(grid, &"right")


func _add_spacer(parent: GridContainer) -> void:
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spacer)


func _add_direction_button(parent: GridContainer, direction: StringName) -> void:
	var button := Button.new()
	button.name = "%sButton" % String(direction).capitalize()
	button.text = str(LABELS[direction])
	button.tooltip_text = "Move %s" % String(direction)
	button.focus_mode = Control.FOCUS_NONE
	button.button_down.connect(set_direction_pressed.bind(direction, true))
	button.button_up.connect(set_direction_pressed.bind(direction, false))
	parent.add_child(button)
	_buttons[direction] = button


func _release_all() -> void:
	var changed := false
	for direction in _pressed:
		if bool(_pressed[direction]):
			_pressed[direction] = false
			changed = true
	if changed:
		movement_changed.emit(Vector2.ZERO)
