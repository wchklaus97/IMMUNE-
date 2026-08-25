extends CharacterBody3D

## Generic lane walker. Not a catalog identity — do not invent a research node for it.

signal died
signal reached_core

var hp := 3
var speed := 2.4
var core: Node3D
var _alive := true


func _ready() -> void:
	add_to_group("bacterium")
	collision_layer = 2
	collision_mask = 1
	if get_node_or_null("Mesh") != null:
		return
	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.56
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.72, 0.28, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.45, 0.12)
	mat.emission_energy_multiplier = 0.15
	mi.material_override = mat
	add_child(mi)
	var bump := SphereMesh.new()
	bump.radius = 0.12
	bump.height = 0.24
	var bump_mi := MeshInstance3D.new()
	bump_mi.mesh = bump
	bump_mi.position = Vector3(0.16, 0.08, 0.1)
	bump_mi.material_override = mat
	add_child(bump_mi)
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	var col := CollisionShape3D.new()
	col.shape = shape
	add_child(col)


func take_hit(amount: int) -> void:
	if not _alive:
		return
	hp -= amount
	if hp <= 0:
		_alive = false
		died.emit()
		queue_free()


func _physics_process(_delta: float) -> void:
	if not _alive or core == null or not is_instance_valid(core):
		return
	var to_core := core.global_position - global_position
	to_core.y = 0.0
	if to_core.length() < 1.15:
		_alive = false
		if core.has_method("take_hit"):
			core.call("take_hit", 1)
		reached_core.emit()
		queue_free()
		return
	velocity = to_core.normalized() * speed
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.38
