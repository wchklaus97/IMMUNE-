extends CharacterBody3D
class_name ImmuneCharacter

## One core mesh. Duty kits swap. Never freeze-and-swap a second body.

signal planted
signal uprooted
signal skill_fired(skill_id: StringName)

const _KitBlockout := preload("res://characters/kit_blockout.gd")
const _GelAnim := preload("res://characters/gel_anim.gd")
const _GelProfiles := preload("res://characters/gel/gel_profiles.gd")
const _Look := preload("res://characters/family_look.gd")

@export var family_id: StringName = &"T"
@export var character_id: StringName = &"CHAR-BASE-T"

@export_group("Imported Body")
@export var imported_model_path: String = ""
@export var imported_model_position: Vector3 = Vector3.ZERO
@export var imported_model_rotation_degrees: Vector3 = Vector3.ZERO
@export var imported_model_scale: Vector3 = Vector3.ONE
@export var imported_face_overlay: bool = false
@export var imported_replaces_limbs: bool = true
@export var imported_replaces_identity: bool = false
@export var imported_replaces_bubbles: bool = false
@export var imported_replaces_fixed_kit: bool = false
@export var imported_preserves_materials: bool = false

var animation_player: AnimationPlayer
var base_kit: Node3D
var locomotion_kit: Node3D
var relay_dish: Node3D
var kit_swap_burst: GPUParticles3D
var weapon_socket: Node3D
var real_mesh: Node

var duty: StringName = &"fixed"
var _hover_t := 0.0
var _hover_homes: Dictionary = {}
var _gel_driven := false
var _liquid_materials: Array[ShaderMaterial] = []
var _liquid_shell_materials: Array[ShaderMaterial] = []
var _liquid_seen_materials: Dictionary = {}
var _liquid_motion_mix := 0.0
var _liquid_flow_direction := Vector3.FORWARD
var _viscous_body_lag := Vector3.ZERO
var _viscous_body_velocity := Vector3.ZERO
var _viscous_body_squash := 0.0
var _viscous_last_local_velocity := Vector3.ZERO
var _liquid_locomotion_active := false
var _liquid_last_sent_motion := -1.0
var _liquid_last_sent_direction := Vector3.ZERO
var _liquid_last_sent_lag := Vector3(99.0, 99.0, 99.0)
var _liquid_last_sent_squash := -1.0

const A_HOVER_LIFT := 0.38
const A_HOVER_BOB := 0.055
const _HOVER_NODES: PackedStringArray = ["CoreMesh", "Face", "WeaponSocket", "DutyKits", "KitSwapBurst", "LimbKit"]
const _WET_GEL_SHADER_SUFFIX := "characters/gel/wet_gel.gdshader"
const _GEL_SHELL_SHADER_SUFFIX := "characters/gel/jelly_shell.gdshader"
const _LIQUID_SPEED_FLOOR := 0.04
const _LIQUID_FULL_SPEED := 2.20
const _LIQUID_ACCEL_RESPONSE := 3.4
const _LIQUID_DECEL_RESPONSE := 1.65
const _LIQUID_DIRECTION_RESPONSE := 2.2
const _VISCOUS_LAG_DISTANCE := 0.13
const _VISCOUS_LAG_LIMIT := 0.16
const _VISCOUS_SPRING_STIFFNESS := 24.0
const _VISCOUS_SPRING_DAMPING := 7.2
const _VISCOUS_SQUASH_RESPONSE := 4.0
const _VISCOUS_DEFORM_STRENGTH := 0.82


func _ready() -> void:
	animation_player = $AnimationPlayer
	base_kit = $DutyKits/BaseKit
	locomotion_kit = get_node_or_null("DutyKits/LocomotionKit")
	relay_dish = get_node_or_null("DutyKits/RelayDish")
	kit_swap_burst = $KitSwapBurst
	weapon_socket = $WeaponSocket
	if family_id == &"A" and locomotion_kit != null:
		push_warning("CHAR-BASE-A uses RelayDish, not a walk kit")
		locomotion_kit.visible = false
	add_to_group("immune_character")
	_KitBlockout.apply(self)
	_realize_imported_mesh()
	# Rest pose must be captured before the hover offset, or the lift is baked twice.
	rebuild_gel_anims()
	if ResearchState.has_signal("duty_unlocked"):
		ResearchState.duty_unlocked.connect(_on_duty_unlocked)
	_apply_duty(&"fixed")
	if kit_swap_burst:
		kit_swap_burst.emitting = false
		kit_swap_burst.one_shot = true
		kit_swap_burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if family_id == &"A":
		_cache_hover_homes()
		_apply_hover(A_HOVER_LIFT)
	# The gel rig carries A's hover and bob itself, so the legacy per-frame offset
	# only runs when that rig is absent. V8's internal flow is independent and runs
	# for every character that owns a wet-gel material.
	set_process(
		(family_id == &"A" and not _gel_driven)
		or not _liquid_materials.is_empty()
	)
	_play_rest()


func _realize_imported_mesh() -> void:
	real_mesh = get_node_or_null("CoreMesh/RealMesh")
	if real_mesh == null and not imported_model_path.is_empty() and ResourceLoader.exists(imported_model_path):
		var packed := load(imported_model_path) as PackedScene
		var core_mesh := get_node_or_null("CoreMesh") as Node3D
		if packed != null and core_mesh != null:
			real_mesh = packed.instantiate() as Node3D
			if real_mesh != null:
				real_mesh.name = "RealMesh"
				real_mesh.position = imported_model_position
				real_mesh.rotation_degrees = imported_model_rotation_degrees
				real_mesh.scale = imported_model_scale
				core_mesh.add_child(real_mesh)
				if core_mesh is MeshInstance3D:
					(core_mesh as MeshInstance3D).mesh = null
	if real_mesh == null:
		return
	# Imported bodies keep the shared blockout path for duty kits/collision. Each
	# scene decides whether its sculpt carries a readable face and limb silhouette.
	var face := get_node_or_null("Face") as Node3D
	if face:
		face.visible = imported_face_overlay
		if family_id == &"B" or family_id == &"M":
			var eye_l := face.get_node_or_null("EyeL") as Node3D
			var eye_r := face.get_node_or_null("EyeR") as Node3D
			var mouth := face.get_node_or_null("Mouth") as Node3D
			if eye_l:
				eye_l.position = Vector3(-0.13, 0.05, 0.02)
				eye_l.scale = Vector3.ONE * 1.15
			if eye_r:
				eye_r.position = Vector3(0.13, 0.05, 0.02)
				eye_r.scale = Vector3.ONE * 1.15
			if mouth and family_id == &"B":
				# Sit behind the sculpted lip as a dark cavity backing instead of
				# floating in front of the face like a third eye.
				mouth.position = Vector3(0.0, -0.09, -0.05)
				mouth.scale = Vector3(2.2, 2.2, 0.45)
			elif mouth:
				# CHAR-BASE-M's Meshy sculpt has a real open cavity. A second ink
				# sphere in front reads as a duplicate mouth, while the overlay eyes
				# remain necessary because this untextured GLB has one material.
				mouth.visible = false
	var limbs := get_node_or_null("LimbKit") as Node3D
	if limbs:
		limbs.visible = not imported_replaces_limbs
	# Imported GLBs normally receive the family gel profile. Authored bodies may
	# opt out when their material layering is itself part of the approved asset.
	if not imported_preserves_materials:
		_Look.apply_gel(real_mesh, String(family_id))


func _process(delta: float) -> void:
	if not _liquid_materials.is_empty():
		update_liquid_flow(velocity, delta)
	if family_id == &"A" and not _gel_driven:
		_hover_t += delta
		_apply_hover(A_HOVER_LIFT + sin(_hover_t * 2.2) * A_HOVER_BOB)


## Smoothly overlays movement onto the shader's uninterrupted TIME-driven idle
## circulation. Public for deterministic smoke/preview harnesses; gameplay simply
## feeds CharacterBody3D.velocity from _process().
func update_liquid_flow(world_velocity: Vector3, delta: float) -> void:
	if _liquid_materials.is_empty():
		return
	var speed := world_velocity.length()
	var speed_ratio := clampf(
		(speed - _LIQUID_SPEED_FLOOR) / (_LIQUID_FULL_SPEED - _LIQUID_SPEED_FLOOR),
		0.0,
		1.0
	)
	var target_motion := speed_ratio * speed_ratio * (3.0 - 2.0 * speed_ratio)
	var response := _LIQUID_ACCEL_RESPONSE if target_motion > _liquid_motion_mix else _LIQUID_DECEL_RESPONSE
	var safe_delta := maxf(delta, 0.0)
	var motion_alpha := 1.0 - exp(-response * safe_delta)
	_liquid_motion_mix = lerpf(_liquid_motion_mix, target_motion, motion_alpha)

	var local_velocity := global_transform.basis.orthonormalized().inverse() * world_velocity
	if speed > _LIQUID_SPEED_FLOOR:
		var target_direction := local_velocity.normalized()
		var direction_alpha := 1.0 - exp(-_LIQUID_DIRECTION_RESPONSE * safe_delta)
		var blended_direction := _liquid_flow_direction.lerp(target_direction, direction_alpha)
		_liquid_flow_direction = (
			target_direction
			if blended_direction.length_squared() < 0.000001
			else blended_direction.normalized()
		)
	_update_viscous_body(local_velocity, target_motion, safe_delta)
	_update_v8_locomotion_state(speed)
	_apply_liquid_runtime_uniforms()


func _update_viscous_body(local_velocity: Vector3, target_motion: float, delta: float) -> void:
	var planar_velocity := Vector3(local_velocity.x, 0.0, local_velocity.z)
	var target_lag := Vector3.ZERO
	if planar_velocity.length() > _LIQUID_SPEED_FLOOR:
		target_lag = -planar_velocity.normalized() * _VISCOUS_LAG_DISTANCE * target_motion
	var spring_delta := minf(delta, 0.05)
	var spring_acceleration := (
		(target_lag - _viscous_body_lag) * _VISCOUS_SPRING_STIFFNESS
		- _viscous_body_velocity * _VISCOUS_SPRING_DAMPING
	)
	_viscous_body_velocity += spring_acceleration * spring_delta
	_viscous_body_lag += _viscous_body_velocity * spring_delta
	if _viscous_body_lag.length() > _VISCOUS_LAG_LIMIT:
		_viscous_body_lag = _viscous_body_lag.normalized() * _VISCOUS_LAG_LIMIT

	var velocity_delta := (planar_velocity - _viscous_last_local_velocity).length()
	var acceleration_ratio := clampf(velocity_delta / maxf(delta, 0.001) / 24.0, 0.0, 1.0)
	var target_squash := target_motion * 0.018 + acceleration_ratio * 0.055
	var squash_alpha := 1.0 - exp(-_VISCOUS_SQUASH_RESPONSE * delta)
	_viscous_body_squash = lerpf(_viscous_body_squash, target_squash, squash_alpha)
	_viscous_last_local_velocity = planar_velocity


func _update_v8_locomotion_state(speed: float) -> void:
	var threshold := 0.08 if _liquid_locomotion_active else 0.14
	var next_active := duty == &"mobile" and speed > threshold
	if next_active == _liquid_locomotion_active:
		return
	_liquid_locomotion_active = next_active
	if animation_player == null:
		return
	var current := animation_player.current_animation
	if current == "idle" or current == "move" or not animation_player.is_playing():
		_play_rest()


func liquid_material_count() -> int:
	return _liquid_materials.size()


func liquid_motion_mix() -> float:
	return _liquid_motion_mix


func liquid_flow_direction() -> Vector3:
	return _liquid_flow_direction


func liquid_body_lag() -> Vector3:
	return _viscous_body_lag


func liquid_body_squash() -> float:
	return _viscous_body_squash


func liquid_shell_material_count() -> int:
	return _liquid_shell_materials.size()


func _cache_liquid_materials() -> void:
	_liquid_materials.clear()
	_liquid_shell_materials.clear()
	_liquid_seen_materials.clear()
	_liquid_motion_mix = 0.0
	_liquid_flow_direction = Vector3.FORWARD
	_viscous_body_lag = Vector3.ZERO
	_viscous_body_velocity = Vector3.ZERO
	_viscous_body_squash = 0.0
	_viscous_last_local_velocity = Vector3.ZERO
	_liquid_locomotion_active = false
	_liquid_last_sent_motion = -1.0
	_liquid_last_sent_direction = Vector3.ZERO
	_liquid_last_sent_lag = Vector3(99.0, 99.0, 99.0)
	_liquid_last_sent_squash = -1.0
	if not _GelProfiles.v8_enabled():
		return
	_collect_liquid_materials(self)
	_apply_liquid_runtime_uniforms(true)


func _collect_liquid_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		_append_liquid_material(mesh_instance.material_override)
		if mesh_instance.mesh != null:
			for surface in mesh_instance.mesh.get_surface_count():
				_append_liquid_material(mesh_instance.get_surface_override_material(surface))
				_append_liquid_material(mesh_instance.mesh.surface_get_material(surface))
	for child in node.get_children():
		_collect_liquid_materials(child)


func _append_liquid_material(material: Material) -> void:
	if material == null:
		return
	var instance_id := material.get_instance_id()
	if _liquid_seen_materials.has(instance_id):
		return
	_liquid_seen_materials[instance_id] = true
	var shader_material := material as ShaderMaterial
	if shader_material != null and shader_material.shader != null:
		var shader_path := shader_material.shader.resource_path
		if shader_path.ends_with(_WET_GEL_SHADER_SUFFIX):
			_liquid_materials.append(shader_material)
		elif shader_path.ends_with(_GEL_SHELL_SHADER_SUFFIX):
			_liquid_shell_materials.append(shader_material)
	_append_liquid_material(material.next_pass)


func _apply_liquid_runtime_uniforms(force: bool = false) -> void:
	if (
		not force
		and absf(_liquid_motion_mix - _liquid_last_sent_motion) < 0.001
		and _liquid_flow_direction.distance_squared_to(_liquid_last_sent_direction) < 0.000004
		and _viscous_body_lag.distance_squared_to(_liquid_last_sent_lag) < 0.000002
		and absf(_viscous_body_squash - _liquid_last_sent_squash) < 0.0005
	):
		return
	for material in _liquid_materials:
		material.set_shader_parameter(&"liquid_flow_motion_mix", _liquid_motion_mix)
		material.set_shader_parameter(&"liquid_flow_direction", _liquid_flow_direction)
		_apply_viscous_material_uniforms(material)
	for material in _liquid_shell_materials:
		material.set_shader_parameter(&"liquid_flow_motion_mix", _liquid_motion_mix)
		material.set_shader_parameter(&"liquid_flow_direction", _liquid_flow_direction)
		_apply_viscous_material_uniforms(material)
	_liquid_last_sent_motion = _liquid_motion_mix
	_liquid_last_sent_direction = _liquid_flow_direction
	_liquid_last_sent_lag = _viscous_body_lag
	_liquid_last_sent_squash = _viscous_body_squash


func _apply_viscous_material_uniforms(material: ShaderMaterial) -> void:
	material.set_shader_parameter(&"liquid_body_deform_strength", _VISCOUS_DEFORM_STRENGTH)
	material.set_shader_parameter(&"liquid_body_lag", _viscous_body_lag)
	material.set_shader_parameter(&"liquid_body_squash", _viscous_body_squash)


func _cache_hover_homes() -> void:
	for node_name in _HOVER_NODES:
		var node := get_node_or_null(node_name) as Node3D
		if node:
			_hover_homes[node_name] = node.position.y


func _apply_hover(lift: float) -> void:
	for node_name in _hover_homes.keys():
		var node := get_node_or_null(String(node_name)) as Node3D
		if node:
			node.position.y = float(_hover_homes[node_name]) + lift


func _on_duty_unlocked(family: StringName, new_duty: StringName) -> void:
	if family != family_id:
		return
	transform_duty(new_duty)


func transform_duty(new_duty: StringName) -> void:
	if new_duty == &"mobile" and family_id == &"A":
		new_duty = &"relay"
	if new_duty == duty:
		return
	duty = new_duty
	# The base scenes intentionally keep an empty particle placeholder. Submitting
	# a GPUParticles3D restart without both a process material and draw mesh can
	# rasterize undefined full-screen triangles on the Compatibility/Web renderer.
	if kit_swap_burst and kit_swap_burst.process_material != null and kit_swap_burst.draw_pass_1 != null:
		kit_swap_burst.restart()
	_apply_duty(new_duty)
	if animation_player == null:
		return
	if new_duty == &"fixed":
		if family_id == &"A" and animation_player.has_animation("relay_close"):
			animation_player.play("relay_close")
		else:
			animation_player.play("plant")
		planted.emit()
	elif new_duty == &"relay":
		animation_player.play("relay_open")
	else:
		animation_player.play("uproot")
		uprooted.emit()


func _apply_duty(new_duty: StringName) -> void:
	if base_kit:
		base_kit.visible = new_duty == &"fixed"
		base_kit.scale = Vector3.ONE if base_kit.visible else Vector3(0.15, 0.15, 0.15)
	if family_id == &"A":
		if locomotion_kit:
			locomotion_kit.visible = false
		if relay_dish:
			relay_dish.visible = new_duty == &"relay"
			relay_dish.scale = Vector3.ONE if relay_dish.visible else Vector3(0.15, 0.15, 0.15)
		return
	if locomotion_kit:
		locomotion_kit.visible = new_duty == &"mobile"
		locomotion_kit.scale = Vector3.ONE if locomotion_kit.visible else Vector3(0.15, 0.15, 0.15)


func fire_skill(skill_id: StringName) -> void:
	skill_fired.emit(skill_id)
	play_attack()
	VfxLibrary.play_skill(skill_id, self, weapon_socket)


## Reactive squash, ~0.3 s. Safe to spam; it always resolves back to rest.
func play_hit() -> void:
	_play_once(&"hit")


## Wind-up and release. The projectile itself is VfxLibrary's job.
func play_attack() -> void:
	_play_once(&"attack")


## Whichever loop matches the current duty: the travel lope when mobile,
## the breathe when planted.
func play_rest() -> void:
	_play_rest()


## Rebuilds the gel animation set against the character's current nodes.
## Call this after swapping CoreMesh, since the squash pivot is measured from
## the mesh bounds.
func rebuild_gel_anims() -> void:
	_cache_liquid_materials()
	_gel_driven = false
	if animation_player == null:
		return
	# Undo any static hover offset so the rest pose is read clean on a re-bake.
	for node_name in _hover_homes.keys():
		var node := get_node_or_null(String(node_name)) as Node3D
		if node:
			node.position.y = float(_hover_homes[node_name])
	var lift := A_HOVER_LIFT if family_id == &"A" else 0.0
	var lib := _GelAnim.build_library(self, lift)
	if animation_player.has_animation_library(""):
		var existing := animation_player.get_animation_library("")
		for anim_name in lib.get_animation_list():
			if existing.has_animation(anim_name):
				existing.remove_animation(anim_name)
			existing.add_animation(anim_name, lib.get_animation(anim_name))
	else:
		animation_player.add_animation_library("", lib)
	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
	_gel_driven = true


func _rest_anim() -> StringName:
	if _GelProfiles.v8_enabled() and duty == &"mobile":
		return &"move" if _liquid_locomotion_active else &"idle"
	return &"move" if duty == &"mobile" else &"idle"


func _play_rest() -> void:
	if animation_player == null:
		return
	var rest := _rest_anim()
	if animation_player.has_animation(rest):
		animation_player.play(rest, 0.18)


func _play_once(anim_name: StringName) -> void:
	if animation_player == null or not animation_player.has_animation(anim_name):
		return
	animation_player.play(anim_name, 0.06)


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"idle" or anim_name == &"move":
		return
	_play_rest()
