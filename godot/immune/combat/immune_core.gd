extends StaticBody3D

## Lane-end organ. Environment prop only — never parented under a character kit.

signal hp_changed(hp: int, max_hp: int)
signal breached

const MAX_HP := 12

var hp := MAX_HP


func _ready() -> void:
	add_to_group("immune_core")
	collision_layer = 1
	collision_mask = 0
	if get_child_count() > 0:
		return
	var mesh := SphereMesh.new()
	mesh.radius = 0.85
	mesh.height = 1.7
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.78, 0.92, 0.92)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.7, 0.9)
	mat.emission_energy_multiplier = 0.35
	mi.material_override = mat
	add_child(mi)
	var shape := SphereShape3D.new()
	shape.radius = 0.9
	var col := CollisionShape3D.new()
	col.shape = shape
	add_child(col)
	var label := Label3D.new()
	label.text = "免疫核心"
	label.font_size = 48
	label.position = Vector3(0.0, 1.35, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


## Bacteria that reach the organ call this. Amount is integer HP.
func take_hit(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, MAX_HP)
	if hp <= 0:
		breached.emit()


## Returns the HP actually restored by a support ability.
func restore_health(amount: int) -> int:
	if hp <= 0 or amount <= 0:
		return 0
	var previous := hp
	hp = mini(hp + amount, MAX_HP)
	var restored := hp - previous
	if restored > 0:
		hp_changed.emit(hp, MAX_HP)
	return restored
