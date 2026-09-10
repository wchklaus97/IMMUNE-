extends CharacterBody3D

## Generic lane walker. Not a catalog identity — do not invent a research node for it.

signal died(was_boss: bool)
signal reached_core
signal health_changed(hp: int, max_hp: int)
signal hit_received(world_position: Vector3, amount: int, was_boss: bool)

var hp: int = 3
var max_hp: int = 3
var speed: float = 2.4
var attack_damage: int = 1
var is_boss: bool = false
var visual_scale: float = 1.0
var ground_y: float = 0.38
var body_color: Color = Color(0.42, 0.72, 0.28, 1.0)
var enrage_health_threshold: float = 0.0
var enrage_speed_multiplier: float = 1.0
var regeneration_per_second: float = 0.0
var regeneration_delay: float = 2.0
var core: Node3D
var _alive: bool = true
var _body_material: StandardMaterial3D
var _health_bar: Node3D
var _health_fill: MeshInstance3D
var _base_scale: Vector3 = Vector3.ONE
var _visual_root: Node3D
var _antibody_marks: int = 0
var _seconds_since_hit: float = 0.0
var _regeneration_progress: float = 0.0
var _temporary_speed_multiplier: float = 1.0
var _speed_boost_remaining: float = 0.0

const CORE_COLLISION_RADIUS: float = 0.9
const BODY_COLLISION_RADIUS: float = 0.3
const CONTACT_MARGIN: float = 0.08


func configure(
	new_hp: int,
	new_speed: float,
	new_damage: int = 1,
	boss: bool = false,
	new_scale: float = 1.0
) -> void:
	max_hp = maxi(new_hp, 1)
	hp = max_hp
	speed = maxf(new_speed, 0.1)
	attack_damage = maxi(new_damage, 1)
	is_boss = boss
	visual_scale = maxf(new_scale, 0.25)
	ground_y = 0.38 * visual_scale
	body_color = Color(0.88, 0.16, 0.28, 1.0) if boss else Color(0.42, 0.72, 0.28, 1.0)


func configure_profile(profile: PathogenProfile, difficulty: DifficultyProfile = null) -> void:
	if profile == null:
		return
	var hp_multiplier := 1.0
	var speed_multiplier := 1.0
	if difficulty:
		hp_multiplier = difficulty.boss_health_multiplier if profile.is_boss else difficulty.health_multiplier
		speed_multiplier = difficulty.speed_multiplier
	configure(
		maxi(int(round(float(profile.max_health) * hp_multiplier)), 1),
		profile.move_speed * speed_multiplier,
		profile.core_damage,
		profile.is_boss,
		profile.visual_scale
	)
	body_color = profile.body_color
	enrage_health_threshold = profile.enrage_health_threshold
	enrage_speed_multiplier = profile.enrage_speed_multiplier
	regeneration_per_second = profile.regeneration_per_second
	regeneration_delay = profile.regeneration_delay
	set_meta("pathogen_id", profile.id)
	set_meta("display_name", profile.display_name)
	set_meta("emission_strength", profile.emission_strength)
	set_meta("shape_variant", profile.shape_variant)


func _ready() -> void:
	add_to_group("bacterium")
	collision_layer = 2
	collision_mask = 1
	_base_scale = Vector3.ONE * visual_scale
	if is_boss:
		add_to_group("boss_pathogen")
	if get_node_or_null("Mesh") != null:
		return
	_visual_root = Node3D.new()
	_visual_root.name = "VisualRoot"
	_visual_root.scale = _base_scale
	add_child(_visual_root)
	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.56
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = body_color
	_body_material.roughness = 0.34
	_body_material.emission_enabled = true
	_body_material.emission = body_color.darkened(0.3)
	_body_material.emission_energy_multiplier = float(get_meta("emission_strength", 0.32 if is_boss else 0.15))
	mi.material_override = _body_material
	_visual_root.add_child(mi)
	_build_shape_details(int(get_meta("shape_variant", 0)))
	var shape := SphereShape3D.new()
	shape.radius = BODY_COLLISION_RADIUS * visual_scale
	var col := CollisionShape3D.new()
	col.shape = shape
	add_child(col)
	_build_health_bar()


func take_profiled_hit(
	amount: int,
	_source_family: StringName,
	effect: StringName,
	effect_power: int,
	effect_cap: int,
	effect_threshold: float
) -> int:
	var final_damage := maxi(amount, 1)
	match effect:
		&"execute":
			var health_ratio := float(hp) / float(maxi(max_hp, 1))
			if health_ratio <= effect_threshold:
				final_damage += maxi(effect_power, 0)
		&"antibody_mark":
			final_damage += mini(_antibody_marks, maxi(effect_cap, 0)) * maxi(effect_power, 0)
			_antibody_marks = mini(_antibody_marks + 1, maxi(effect_cap, 0))
	take_hit(final_damage)
	return final_damage


func take_hit(amount: int) -> void:
	if not _alive:
		return
	var applied_damage := maxi(amount, 1)
	_seconds_since_hit = 0.0
	_regeneration_progress = 0.0
	hp -= applied_damage
	health_changed.emit(maxi(hp, 0), max_hp)
	hit_received.emit(global_position, applied_damage, is_boss)
	_update_health_bar()
	_play_hit_flash()
	if hp <= 0:
		_alive = false
		died.emit(is_boss)
		queue_free()


## Encounter events may restore a bounded amount without resetting the trait timer.
func restore_health(amount: int) -> int:
	if not _alive or amount <= 0 or hp >= max_hp:
		return 0
	var previous := hp
	hp = mini(hp + amount, max_hp)
	var restored := hp - previous
	if restored > 0:
		health_changed.emit(hp, max_hp)
		_update_health_bar()
	return restored


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if _speed_boost_remaining > 0.0:
		_speed_boost_remaining = maxf(_speed_boost_remaining - delta, 0.0)
		if _speed_boost_remaining <= 0.0:
			_temporary_speed_multiplier = 1.0
	_update_regeneration(delta)
	if core == null or not is_instance_valid(core):
		return
	var to_core := core.global_position - global_position
	to_core.y = 0.0
	if to_core.length() <= core_contact_distance():
		_alive = false
		if core.has_method("take_hit"):
			core.call("take_hit", attack_damage)
		reached_core.emit()
		queue_free()
		return
	velocity = to_core.normalized() * current_move_speed()
	velocity.y = 0.0
	move_and_slide()
	global_position.y = ground_y


func core_contact_distance() -> float:
	return CORE_COLLISION_RADIUS + BODY_COLLISION_RADIUS * visual_scale + CONTACT_MARGIN


func current_move_speed() -> float:
	var trait_multiplier := 1.0
	if enrage_health_threshold <= 0.0:
		return speed * _temporary_speed_multiplier
	var health_ratio := float(hp) / float(maxi(max_hp, 1))
	trait_multiplier = enrage_speed_multiplier if health_ratio <= enrage_health_threshold else 1.0
	return speed * trait_multiplier * _temporary_speed_multiplier


func apply_speed_boost(multiplier: float, duration: float) -> void:
	if not _alive:
		return
	_temporary_speed_multiplier = maxf(_temporary_speed_multiplier, maxf(multiplier, 1.0))
	_speed_boost_remaining = maxf(_speed_boost_remaining, maxf(duration, 0.0))


func antibody_marks() -> int:
	return _antibody_marks


func _update_regeneration(delta: float) -> void:
	_seconds_since_hit += delta
	if regeneration_per_second <= 0.0 or hp >= max_hp or _seconds_since_hit < regeneration_delay:
		return
	_regeneration_progress += regeneration_per_second * delta
	var restored := mini(int(floor(_regeneration_progress)), max_hp - hp)
	if restored <= 0:
		return
	_regeneration_progress -= float(restored)
	hp += restored
	health_changed.emit(hp, max_hp)
	_update_health_bar()


func _build_shape_details(variant: int) -> void:
	var detail_count := 1 if variant == 0 else (4 if variant == 1 else 6)
	for i in detail_count:
		var bump := SphereMesh.new()
		bump.radius = 0.10 if variant < 2 else 0.075
		bump.height = bump.radius * 2.0
		var bump_mi := MeshInstance3D.new()
		bump_mi.mesh = bump
		var angle := TAU * float(i) / float(detail_count)
		bump_mi.position = Vector3(cos(angle) * 0.22, 0.05 + sin(angle * 2.0) * 0.08, sin(angle) * 0.22)
		bump_mi.material_override = _body_material
		_visual_root.add_child(bump_mi)
	if variant == 2:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.2
		ring.outer_radius = 0.27
		var ring_mi := MeshInstance3D.new()
		ring_mi.mesh = ring
		ring_mi.rotation_degrees.x = 90
		ring_mi.material_override = _body_material
		_visual_root.add_child(ring_mi)


func _build_health_bar() -> void:
	_health_bar = Node3D.new()
	_health_bar.name = "HealthBar"
	_health_bar.position = Vector3(0.0, 0.62 * visual_scale, 0.0)
	_health_bar.scale = Vector3.ONE * clampf(visual_scale, 1.0, 1.6)
	add_child(_health_bar)
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.72, 0.055, 0.025)
	var back := MeshInstance3D.new()
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	back_mat.albedo_color = Color(0.08, 0.04, 0.07, 0.95)
	back.material_override = back_mat
	_health_bar.add_child(back)
	var fill_mesh := BoxMesh.new()
	fill_mesh.size = Vector3(0.68, 0.035, 0.032)
	_health_fill = MeshInstance3D.new()
	_health_fill.mesh = fill_mesh
	var fill_mat := StandardMaterial3D.new()
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.albedo_color = Color(0.3, 0.95, 0.5, 1.0) if not is_boss else Color(1.0, 0.26, 0.28, 1.0)
	_health_fill.material_override = fill_mat
	_health_bar.add_child(_health_fill)
	_health_bar.visible = is_boss
	if is_boss:
		var label := Label3D.new()
		label.text = str(get_meta("display_name", "大型病原"))
		label.font_size = 32
		label.position.y = 0.16
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_health_bar.add_child(label)


func _update_health_bar() -> void:
	if _health_fill == null or _health_bar == null:
		return
	var ratio := clampf(float(maxi(hp, 0)) / float(max_hp), 0.0, 1.0)
	_health_fill.scale.x = ratio
	_health_fill.position.x = -0.34 * (1.0 - ratio)
	_health_bar.visible = ratio < 0.999 or is_boss


func _play_hit_flash() -> void:
	if _body_material == null:
		return
	var base_color := body_color
	_body_material.albedo_color = Color.WHITE
	_body_material.emission = Color.WHITE
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_body_material, "albedo_color", base_color, 0.12)
	tween.tween_property(_body_material, "emission", base_color.darkened(0.3), 0.12)
	if not SettingsState.reduced_motion and _visual_root != null:
		_visual_root.scale = _base_scale * 1.1
		tween.tween_property(_visual_root, "scale", _base_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
