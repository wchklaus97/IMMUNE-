@tool
class_name ImmuneFamilyRow
extends PanelContainer

signal focused(family: String)

var family := "T"


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			focused.emit(family)
			accept_event()
