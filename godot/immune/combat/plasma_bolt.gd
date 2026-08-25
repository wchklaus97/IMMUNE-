extends Area3D

## Catalog bind: SKILL-T-ACTIVE 集中處決. Visual stand-in until a per-ID VFX scene exists.

const SPEED := 16.0
const LIFETIME := 1.15

var velocity := Vector3.ZERO
var damage := 1
var _age := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	if get_child_count() > 0:
		return
	var mesh := SphereMesh.new()
	mesh.radius = 0.09
	mesh.height = 0.18
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.22, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.45, 0.12)
	mat.emission_energy_multiplier = 1.4
	mi.material_override = mat
	add_child(mi)
	var shape := SphereShape3D.new()
	shape.radius = 0.12
	var col := CollisionShape3D.new()
	col.shape = shape
	add_child(col)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	global_position += velocity * delta


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("bacterium"):
		return
	if body.has_method("take_hit"):
		body.call("take_hit", damage)
	queue_free()
