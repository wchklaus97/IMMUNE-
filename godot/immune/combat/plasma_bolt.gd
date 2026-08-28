extends Area3D

## Catalog bind: SKILL-T-ACTIVE 集中處決. Visual stand-in until a per-ID VFX scene exists.

const SPEED := 16.0
const LIFETIME := 1.15

var velocity := Vector3.ZERO
var damage := 1
var bolt_color := Color(1.0, 0.55, 0.22, 1.0)
var source_family: StringName = &""
var hit_effect: StringName = &"none"
var hit_effect_power: int = 0
var hit_effect_cap: int = 0
var hit_effect_threshold: float = 0.0
var _age := 0.0
var _spent: bool = false


func configure(
	new_damage: int,
	new_color: Color,
	new_source_family: StringName = &"",
	new_hit_effect: String = "none",
	new_hit_effect_power: int = 0,
	new_hit_effect_cap: int = 0,
	new_hit_effect_threshold: float = 0.0
) -> void:
	damage = maxi(new_damage, 1)
	bolt_color = new_color
	source_family = new_source_family
	hit_effect = StringName(new_hit_effect)
	hit_effect_power = maxi(new_hit_effect_power, 0)
	hit_effect_cap = maxi(new_hit_effect_cap, 0)
	hit_effect_threshold = clampf(new_hit_effect_threshold, 0.0, 1.0)


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
	mat.albedo_color = bolt_color
	mat.emission_enabled = true
	mat.emission = bolt_color
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
	if not try_apply_hit(body):
		return
	queue_free()


func try_apply_hit(body: Node3D) -> bool:
	if _spent or not body.is_in_group("bacterium"):
		return false
	_spent = true
	collision_mask = 0
	set_deferred("monitoring", false)
	if body.has_method("take_profiled_hit"):
		body.call(
			"take_profiled_hit",
			damage,
			source_family,
			hit_effect,
			hit_effect_power,
			hit_effect_cap,
			hit_effect_threshold
		)
	elif body.has_method("take_hit"):
		body.call("take_hit", damage)
	return true
