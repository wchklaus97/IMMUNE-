extends CharacterBody3D
class_name ImmuneCharacter

## One core mesh. Duty kits swap. Never freeze-and-swap a second body.

signal planted
signal uprooted
signal skill_fired(skill_id: StringName)
signal duty_changed(new_duty: StringName)
signal combat_action_released(request_id: int, action_kind: StringName)
signal combat_action_cancelled(request_id: int, action_kind: StringName, reason: StringName)

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
var _liquid_attachment_materials: Array[ShaderMaterial] = []
var _liquid_seen_materials: Dictionary = {}
var _liquid_motion_mix := 0.0
var _liquid_flow_direction := Vector3.FORWARD
var _viscous_body_lag := Vector3.ZERO
var _viscous_body_velocity := Vector3.ZERO
var _viscous_body_squash := 0.0
var _viscous_last_local_velocity := Vector3.ZERO
var _liquid_effective_lag := Vector3.ZERO
var _liquid_effective_squash := 0.0
var _liquid_locomotion_active := false
var _liquid_locomotion_state: StringName = &"idle"
var _liquid_start_frames := 0
var _liquid_stop_frames := 0
var _liquid_last_resolved_speed := 0.0
var _liquid_last_turn_sign := 1.0
var _liquid_direction_error := 0.0
var _liquid_turn_elapsed := INF
var _liquid_turn_duration := 0.0
var _liquid_turn_peak := 0.0
var _liquid_turn_shear := 0.0
var _liquid_contact_elapsed := INF
var _liquid_contact_cooldown := 0.0
var _liquid_contact_peak := 0.0
var _liquid_contact_amount := 0.0
var _liquid_contact_normal := Vector3.ZERO
var _motion_truth_received := false
var _motion_truth_physics_frame := -1
var _requested_world_velocity := Vector3.ZERO
var _resolved_world_velocity := Vector3.ZERO
var _contact_world_normal := Vector3.ZERO
var _liquid_visual_anchors: Array[Node3D] = []
var _liquid_visual_anchor_homes: Dictionary = {}
var _liquid_visual_anchor_weights: Dictionary = {}
var _release_anchor: Node3D
var _liquid_last_sent_motion := -1.0
var _liquid_last_sent_direction := Vector3.ZERO
var _liquid_last_sent_lag := Vector3(99.0, 99.0, 99.0)
var _liquid_last_sent_squash := -1.0
var _liquid_last_sent_turn := INF
var _liquid_last_sent_contact := INF
var _liquid_last_sent_contact_normal := Vector3(99.0, 99.0, 99.0)
var _animation_priority := 0
var _animation_kind: StringName = &"rest"
var _managed_animation: StringName = &""
var _combat_request: Dictionary = {}
var _buffered_combat_request: Dictionary = {}
var _pending_duty: StringName = &""
var _terminal_animation := false
var _method_callback_mode_before_v8_1 := AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_DEFERRED

const A_HOVER_LIFT := 0.38
const A_HOVER_BOB := 0.055
const _HOVER_NODES: PackedStringArray = ["CoreMesh", "Face", "WeaponSocket", "DutyKits", "KitSwapBurst", "LimbKit"]
const _WET_GEL_SHADER_SUFFIX := "characters/gel/wet_gel.gdshader"
const _GEL_SHELL_SHADER_SUFFIX := "characters/gel/jelly_shell.gdshader"
const _GEL_EYE_SHADER_SUFFIX := "characters/gel/gel_eye.gdshader"
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
const _V8_1_DIRECTION_SPEED := 8.5
const _V8_1_START_SPEED := 0.14
const _V8_1_STOP_SPEED := 0.08
const _V8_1_TURN_START := PI * 55.0 / 180.0
const _V8_1_TURN_FULL := PI * 150.0 / 180.0
const _V8_1_CONTACT_SPEED := 0.9
const _V8_1_CONTACT_FULL_SPEED := 6.0
const _V8_1_CONTACT_RETRIGGER := 0.18
const _V8_1_TRUTH_MAX_MISSED_PHYSICS_TICKS := 2
static var _V8_1_TURN_RESPONSE: PackedVector2Array = PackedVector2Array([
	Vector2(0.00, 0.00), Vector2(0.22, 1.00), Vector2(0.50, 0.45),
	Vector2(0.72, -0.18), Vector2(1.00, 0.00),
])
static var _V8_1_CONTACT_RESPONSE: PackedVector2Array = PackedVector2Array([
	Vector2(0.000, 0.00), Vector2(0.125, 1.00), Vector2(0.292, 0.95),
	Vector2(0.611, -0.20), Vector2(1.000, 0.00),
])
const _ANIM_REST := 0
const _ANIM_LOCOMOTION_EDGE := 10
const _ANIM_DUTY := 30
const _ANIM_BASIC := 50
const _ANIM_HIT := 70
const _ANIM_ACTIVE := 80
const _ANIM_TERMINAL := 100
const _KIND_REST := &"rest"
const _KIND_LOCOMOTION := &"locomotion"
const _KIND_DUTY := &"duty"
const _KIND_BASIC := &"basic"
const _KIND_HIT := &"hit"
const _KIND_ACTIVE := &"active"
const _KIND_TERMINAL := &"terminal"


func _ready() -> void:
	animation_player = $AnimationPlayer
	_method_callback_mode_before_v8_1 = animation_player.callback_mode_method
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
		if _GelProfiles.motion_truth_enabled():
			if not _motion_truth_received:
				# Preview and lineup scenes do not own a physics controller. Until the
				# first authoritative sample arrives, retain the V8 velocity fallback.
				update_liquid_flow(velocity, delta)
			elif _motion_truth_is_stale():
				# Freshness follows physics ticks, not render time. A 100 ms render frame
				# may contain several valid post-physics submissions and must not erase
				# the newest one; only genuinely missed physics samples decay to rest.
				_requested_world_velocity = Vector3.ZERO
				_resolved_world_velocity = Vector3.ZERO
				_contact_world_normal = Vector3.ZERO
				update_liquid_flow(Vector3.ZERO, delta)
		else:
			update_liquid_flow(velocity, delta)
	if family_id == &"A" and not _gel_driven:
		_hover_t += delta
		_apply_hover(A_HOVER_LIFT + sin(_hover_t * 2.2) * A_HOVER_BOB)


## Authoritative movement bridge for V8.1. Combat submits this after
## move_and_slide() and manual arena clamps, so presentation follows resolved
## displacement while requested motion remains available only for wall pressure.
func submit_motion_truth(
	requested_velocity: Vector3,
	resolved_velocity: Vector3,
	contact_normal: Vector3,
	physics_delta: float
) -> void:
	if not _GelProfiles.motion_truth_enabled():
		return
	_motion_truth_received = true
	_motion_truth_physics_frame = Engine.get_physics_frames()
	_requested_world_velocity = requested_velocity
	_resolved_world_velocity = resolved_velocity
	_contact_world_normal = contact_normal.normalized() if not contact_normal.is_zero_approx() else Vector3.ZERO
	update_liquid_flow(_resolved_world_velocity, maxf(physics_delta, 0.0))


func _motion_truth_is_stale() -> bool:
	if _motion_truth_physics_frame < 0:
		return false
	var missed_ticks := Engine.get_physics_frames() - _motion_truth_physics_frame
	return missed_ticks > _V8_1_TRUTH_MAX_MISSED_PHYSICS_TICKS


## Explicitly settles motion and optionally closes the animation arbiter. Pause
## does not call this; terminal gameplay states do.
func settle_motion(physics_delta: float = 1.0 / 60.0, terminal: bool = false) -> void:
	velocity = Vector3.ZERO
	submit_motion_truth(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, physics_delta)
	if terminal and _GelProfiles.motion_truth_enabled():
		_terminal_animation = true
		cancel_combat_action(&"terminal")
		_animation_priority = _ANIM_TERMINAL
		_animation_kind = _KIND_TERMINAL
		_buffered_combat_request.clear()
		_pending_duty = &""
		_liquid_locomotion_active = false
		_liquid_locomotion_state = &"stopping"
		if animation_player != null and animation_player.has_animation(&"move_stop"):
			_managed_animation = &"move_stop"
			animation_player.play(&"move_stop", 0.08)
		elif animation_player != null:
			_managed_animation = &""
			animation_player.stop()


## Starts a V8.2 terminal one-shot and permanently reserves the presentation
## lane for its authored final pose. Gameplay state remains owned by CombatLane;
## this method only freezes motion, cancels unreleased presentation requests and
## selects the matching terminal animation.
func enter_terminal(result: StringName, physics_delta: float = 1.0 / 60.0) -> bool:
	if (
		not _GelProfiles.v8_2_enabled()
		or (result != &"victory" and result != &"defeat")
		or animation_player == null
		or not animation_player.has_animation(result)
	):
		return false
	if _terminal_animation:
		return _managed_animation == result
	velocity = Vector3.ZERO
	submit_motion_truth(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, physics_delta)
	_terminal_animation = true
	cancel_combat_action(&"terminal")
	_buffered_combat_request.clear()
	_pending_duty = &""
	_liquid_locomotion_active = false
	_liquid_locomotion_state = &"idle"
	return _request_managed_animation(
		result, _ANIM_TERMINAL, _KIND_TERMINAL, 0.08
	)


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
		if _GelProfiles.motion_truth_enabled():
			_liquid_flow_direction = _steer_liquid_direction(
				_liquid_flow_direction, target_direction, safe_delta
			)
		else:
			var direction_alpha := 1.0 - exp(-_LIQUID_DIRECTION_RESPONSE * safe_delta)
			var blended_direction := _liquid_flow_direction.lerp(target_direction, direction_alpha)
			_liquid_flow_direction = (
				target_direction
				if blended_direction.length_squared() < 0.000001
				else blended_direction.normalized()
			)
	_update_viscous_body(local_velocity, target_motion, safe_delta)
	if _GelProfiles.motion_truth_enabled():
		_update_v8_1_responses(local_velocity, target_motion, safe_delta)
		_update_v8_1_locomotion_state(speed)
	else:
		_liquid_effective_lag = _viscous_body_lag
		_liquid_effective_squash = _viscous_body_squash
		_update_v8_locomotion_state(speed)
	_apply_liquid_runtime_uniforms()


## Planar angular steering cannot collapse at antipodal vectors. When the target
## is exactly opposite, the last non-zero turn sign chooses a deterministic arc.
func _steer_liquid_direction(current: Vector3, target: Vector3, delta: float) -> Vector3:
	var current_planar := Vector3(current.x, 0.0, current.z)
	var target_planar := Vector3(target.x, 0.0, target.z)
	if target_planar.length_squared() < 0.000001:
		_liquid_direction_error = 0.0
		return current_planar.normalized() if current_planar.length_squared() > 0.000001 else Vector3.FORWARD
	if current_planar.length_squared() < 0.000001:
		_liquid_direction_error = 0.0
		return target_planar.normalized()
	current_planar = current_planar.normalized()
	target_planar = target_planar.normalized()
	var current_angle := atan2(current_planar.z, current_planar.x)
	var target_angle := atan2(target_planar.z, target_planar.x)
	var angle_error := wrapf(target_angle - current_angle, -PI, PI)
	if absf(absf(angle_error) - PI) < 0.0001:
		angle_error = PI * _liquid_last_turn_sign
	elif absf(angle_error) > 0.0001:
		_liquid_last_turn_sign = signf(angle_error)
	_liquid_direction_error = angle_error
	var max_step := _V8_1_DIRECTION_SPEED * maxf(delta, 0.0)
	var next_angle := current_angle + clampf(angle_error, -max_step, max_step)
	return Vector3(cos(next_angle), 0.0, sin(next_angle)).normalized()


func _update_viscous_body(local_velocity: Vector3, target_motion: float, delta: float) -> void:
	var planar_velocity := Vector3(local_velocity.x, 0.0, local_velocity.z)
	var target_lag := Vector3.ZERO
	if planar_velocity.length() > _LIQUID_SPEED_FLOOR:
		var lag_distance := 0.10 if _GelProfiles.motion_truth_enabled() and family_id == &"A" and duty == &"relay" else _VISCOUS_LAG_DISTANCE
		target_lag = -planar_velocity.normalized() * lag_distance * target_motion
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


func _update_v8_1_responses(local_velocity: Vector3, target_motion: float, delta: float) -> void:
	_liquid_contact_cooldown = maxf(_liquid_contact_cooldown - delta, 0.0)
	_maybe_trigger_turn(local_velocity)
	_maybe_trigger_contact(delta)
	_advance_turn_response(delta)
	_advance_contact_response(delta)

	var turn_squash := absf(_liquid_turn_shear) * 0.45
	var contact_squash := maxf(_liquid_contact_amount, 0.0) * 0.060
	_liquid_effective_squash = clampf(
		_viscous_body_squash + turn_squash + contact_squash,
		0.0,
		0.12
	)
	var contact_rebound := _liquid_contact_normal * minf(_liquid_contact_amount, 0.0) * 0.025
	_liquid_effective_lag = _viscous_body_lag + contact_rebound
	if target_motion <= 0.001 and _liquid_effective_lag.length() < 0.00001:
		_liquid_effective_lag = Vector3.ZERO


func _maybe_trigger_turn(local_velocity: Vector3) -> void:
	var planar_speed := Vector2(local_velocity.x, local_velocity.z).length()
	var absolute_error := absf(_liquid_direction_error)
	if planar_speed <= _V8_1_START_SPEED or absolute_error < _V8_1_TURN_START:
		return
	# Do not restart the same shear every physics frame. A later, materially
	# sharper change may replace the active envelope.
	var turn_01 := _smooth_range(_V8_1_TURN_START, _V8_1_TURN_FULL, absolute_error)
	var requested_peak := 0.035 + 0.055 * turn_01
	if _liquid_turn_elapsed < _liquid_turn_duration * 0.72 and requested_peak <= _liquid_turn_peak * 1.25:
		return
	_liquid_turn_elapsed = 0.0
	_liquid_turn_duration = 0.24 + 0.16 * turn_01
	_liquid_turn_peak = requested_peak
	_liquid_last_turn_sign = signf(_liquid_direction_error) if absf(_liquid_direction_error) > 0.0001 else _liquid_last_turn_sign


func _advance_turn_response(delta: float) -> void:
	if _liquid_turn_duration <= 0.0 or _liquid_turn_elapsed >= _liquid_turn_duration:
		_liquid_turn_shear = 0.0
		return
	_liquid_turn_elapsed += delta
	var phase := clampf(_liquid_turn_elapsed / _liquid_turn_duration, 0.0, 1.0)
	var envelope := _response_curve(phase, _V8_1_TURN_RESPONSE)
	_liquid_turn_shear = envelope * _liquid_turn_peak * _liquid_last_turn_sign


func _maybe_trigger_contact(_delta: float) -> void:
	if _contact_world_normal.is_zero_approx():
		return
	var impact_speed := maxf(0.0, -_requested_world_velocity.dot(_contact_world_normal))
	if impact_speed <= _V8_1_CONTACT_SPEED:
		return
	var impact_01 := _smooth_range(
		_V8_1_CONTACT_SPEED, _V8_1_CONTACT_FULL_SPEED, impact_speed
	)
	var requested_peak := 0.45 + 0.55 * impact_01
	if _liquid_contact_cooldown > 0.0 and requested_peak <= _liquid_contact_peak * 1.25:
		return
	var local_normal := global_transform.basis.orthonormalized().inverse() * _contact_world_normal
	_liquid_contact_normal = Vector3(local_normal.x, 0.0, local_normal.z).normalized()
	_liquid_contact_elapsed = 0.0
	_liquid_contact_peak = requested_peak
	_liquid_contact_cooldown = _V8_1_CONTACT_RETRIGGER


func _advance_contact_response(delta: float) -> void:
	const CONTACT_DURATION := 0.36
	if _liquid_contact_elapsed >= CONTACT_DURATION:
		_liquid_contact_amount = 0.0
		if _liquid_contact_elapsed < INF:
			_liquid_contact_elapsed = CONTACT_DURATION
		return
	_liquid_contact_elapsed += delta
	var phase := clampf(_liquid_contact_elapsed / CONTACT_DURATION, 0.0, 1.0)
	var envelope := _response_curve(phase, _V8_1_CONTACT_RESPONSE)
	_liquid_contact_amount = envelope * _liquid_contact_peak


func _smooth_range(from: float, to: float, value: float) -> float:
	var ratio := clampf((value - from) / maxf(to - from, 0.00001), 0.0, 1.0)
	return ratio * ratio * (3.0 - 2.0 * ratio)


func _response_curve(phase: float, keys: PackedVector2Array) -> float:
	if keys.is_empty():
		return 0.0
	if phase <= keys[0].x:
		return keys[0].y
	for index in keys.size() - 1:
		var next_time := keys[index + 1].x
		if phase > next_time:
			continue
		var time := keys[index].x
		var amount := (phase - time) / maxf(next_time - time, 0.00001)
		amount = amount * amount * (3.0 - 2.0 * amount)
		return lerpf(keys[index].y, keys[index + 1].y, amount)
	return keys[keys.size() - 1].y


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


func _update_v8_1_locomotion_state(speed: float) -> void:
	_liquid_last_resolved_speed = speed
	var can_translate := _can_visually_locomote()
	var above_start := can_translate and speed > _V8_1_START_SPEED
	var below_stop := not can_translate or speed < _V8_1_STOP_SPEED
	_liquid_start_frames = _liquid_start_frames + 1 if above_start else 0
	_liquid_stop_frames = _liquid_stop_frames + 1 if below_stop else 0

	match _liquid_locomotion_state:
		&"idle":
			if _liquid_start_frames >= 2:
				_liquid_locomotion_state = &"starting"
				_liquid_locomotion_active = true
				if not _request_managed_animation(
					&"move_start", _ANIM_LOCOMOTION_EDGE, _KIND_LOCOMOTION, 0.06
				):
					_liquid_locomotion_state = &"moving"
		&"starting":
			if _liquid_stop_frames >= 3:
				_begin_v8_1_stop()
		&"moving":
			if _liquid_stop_frames >= 3:
				_begin_v8_1_stop()
			elif _animation_priority == _ANIM_REST:
				_play_rest()
		&"stopping":
			if _liquid_start_frames >= 2:
				_liquid_locomotion_state = &"starting"
				_liquid_locomotion_active = true
				if not _request_managed_animation(
					&"move_start", _ANIM_LOCOMOTION_EDGE, _KIND_LOCOMOTION, 0.06
				):
					_liquid_locomotion_state = &"moving"


func _begin_v8_1_stop() -> void:
	_liquid_locomotion_state = &"stopping"
	_liquid_locomotion_active = false
	if not _request_managed_animation(
		&"move_stop", _ANIM_LOCOMOTION_EDGE, _KIND_LOCOMOTION, 0.06
	):
		_liquid_locomotion_state = &"idle"


func _can_visually_locomote() -> bool:
	return duty == &"mobile" or (family_id == &"A" and duty == &"relay")


func liquid_material_count() -> int:
	return _liquid_materials.size()


func liquid_motion_mix() -> float:
	return _liquid_motion_mix


func liquid_flow_direction() -> Vector3:
	return _liquid_flow_direction


func liquid_body_lag() -> Vector3:
	return _liquid_effective_lag if _GelProfiles.motion_truth_enabled() else _viscous_body_lag


func liquid_body_squash() -> float:
	return _liquid_effective_squash if _GelProfiles.motion_truth_enabled() else _viscous_body_squash


func liquid_shell_material_count() -> int:
	return _liquid_shell_materials.size()


func liquid_attachment_material_count() -> int:
	return _liquid_attachment_materials.size()


func liquid_locomotion_state() -> StringName:
	return _liquid_locomotion_state


func liquid_turn_shear() -> float:
	return _liquid_turn_shear


func liquid_contact_amount() -> float:
	return _liquid_contact_amount


func liquid_contact_normal() -> Vector3:
	return _liquid_contact_normal


func resolved_motion_velocity() -> Vector3:
	return _resolved_world_velocity


func motion_truth_received() -> bool:
	return _motion_truth_received


func _cache_liquid_materials() -> void:
	_liquid_materials.clear()
	_liquid_shell_materials.clear()
	_liquid_attachment_materials.clear()
	_liquid_seen_materials.clear()
	_liquid_motion_mix = 0.0
	_liquid_flow_direction = Vector3.FORWARD
	_viscous_body_lag = Vector3.ZERO
	_viscous_body_velocity = Vector3.ZERO
	_viscous_body_squash = 0.0
	_viscous_last_local_velocity = Vector3.ZERO
	_liquid_effective_lag = Vector3.ZERO
	_liquid_effective_squash = 0.0
	_liquid_locomotion_active = false
	_liquid_locomotion_state = &"idle"
	_liquid_start_frames = 0
	_liquid_stop_frames = 0
	_liquid_last_resolved_speed = 0.0
	_liquid_direction_error = 0.0
	_liquid_turn_elapsed = INF
	_liquid_turn_duration = 0.0
	_liquid_turn_peak = 0.0
	_liquid_turn_shear = 0.0
	_liquid_contact_elapsed = INF
	_liquid_contact_cooldown = 0.0
	_liquid_contact_peak = 0.0
	_liquid_contact_amount = 0.0
	_liquid_contact_normal = Vector3.ZERO
	_motion_truth_received = false
	_motion_truth_physics_frame = -1
	_requested_world_velocity = Vector3.ZERO
	_resolved_world_velocity = Vector3.ZERO
	_contact_world_normal = Vector3.ZERO
	_liquid_last_sent_motion = -1.0
	_liquid_last_sent_direction = Vector3.ZERO
	_liquid_last_sent_lag = Vector3(99.0, 99.0, 99.0)
	_liquid_last_sent_squash = -1.0
	_liquid_last_sent_turn = INF
	_liquid_last_sent_contact = INF
	_liquid_last_sent_contact_normal = Vector3(99.0, 99.0, 99.0)
	if not _GelProfiles.v8_enabled():
		return
	if _GelProfiles.motion_truth_enabled():
		_configure_v8_1_visual_anchors()
	_collect_liquid_materials(self)
	_apply_liquid_runtime_uniforms(true)


func _collect_liquid_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		_append_liquid_material(mesh_instance.material_override, mesh_instance)
		if mesh_instance.mesh != null:
			for surface in mesh_instance.mesh.get_surface_count():
				_append_liquid_material(mesh_instance.get_surface_override_material(surface), mesh_instance)
				_append_liquid_material(mesh_instance.mesh.surface_get_material(surface), mesh_instance)
	for child in node.get_children():
		_collect_liquid_materials(child)


func _append_liquid_material(material: Material, owner_mesh: MeshInstance3D) -> void:
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
		elif _GelProfiles.motion_truth_enabled() and shader_path.ends_with(_GEL_EYE_SHADER_SUFFIX):
			_liquid_attachment_materials.append(shader_material)
		if _GelProfiles.motion_truth_enabled() and (
			shader_path.ends_with(_WET_GEL_SHADER_SUFFIX)
			or shader_path.ends_with(_GEL_SHELL_SHADER_SUFFIX)
			or shader_path.ends_with(_GEL_EYE_SHADER_SUFFIX)
		):
			_configure_material_body_space(shader_material, owner_mesh)
	_append_liquid_material(material.next_pass, owner_mesh)


func _configure_material_body_space(material: ShaderMaterial, owner_mesh: MeshInstance3D) -> void:
	var authored_root := real_mesh as Node3D
	if authored_root == null or owner_mesh == null:
		return
	var relative := authored_root.global_transform.affine_inverse() * owner_mesh.global_transform
	var part_scale := relative.basis.get_scale()
	part_scale.x = maxf(absf(part_scale.x), 0.0001)
	part_scale.y = maxf(absf(part_scale.y), 0.0001)
	part_scale.z = maxf(absf(part_scale.z), 0.0001)
	material.set_shader_parameter(&"liquid_body_space_enabled", 1.0)
	material.set_shader_parameter(&"liquid_part_origin", relative.origin)
	material.set_shader_parameter(&"liquid_part_basis", relative.basis.orthonormalized())
	material.set_shader_parameter(&"liquid_part_scale", part_scale)


func _configure_v8_1_visual_anchors() -> void:
	# A rebuild can happen while runtime deformation is non-zero. Restore the
	# previous neutral transforms before taking a new snapshot to avoid cumulative
	# lag/scale drift on kits and the release socket.
	for previous_anchor in _liquid_visual_anchors:
		if not is_instance_valid(previous_anchor):
			continue
		var previous_key := previous_anchor.get_instance_id()
		if _liquid_visual_anchor_homes.has(previous_key):
			previous_anchor.transform = _liquid_visual_anchor_homes[previous_key]
	_liquid_visual_anchors.clear()
	_liquid_visual_anchor_homes.clear()
	_liquid_visual_anchor_weights.clear()
	var socket_root := get_node_or_null("WeaponSocket") as Node3D
	if socket_root != null:
		_release_anchor = socket_root.get_node_or_null("LiquidReleaseAnchor") as Node3D
		if _release_anchor == null:
			_release_anchor = Node3D.new()
			_release_anchor.name = "LiquidReleaseAnchor"
			socket_root.add_child(_release_anchor)
		weapon_socket = _release_anchor
		_register_visual_anchor(_release_anchor, 0.92, 0.0)
	for kit_root in [base_kit, locomotion_kit, relay_dish]:
		if kit_root == null:
			continue
		var anchor := kit_root.get_node_or_null("LiquidAttachmentAnchor") as Node3D
		if anchor != null:
			_register_visual_anchor(anchor, 0.54, 0.32)
			continue
		var movable_children: Array[Node] = []
		for child in kit_root.get_children():
			movable_children.append(child)
		if movable_children.is_empty():
			continue
		anchor = Node3D.new()
		anchor.name = "LiquidAttachmentAnchor"
		kit_root.add_child(anchor)
		for child in movable_children:
			child.reparent(anchor, true)
		_register_visual_anchor(anchor, 0.54, 0.32)


func _register_visual_anchor(anchor: Node3D, lag_weight: float, scale_weight: float) -> void:
	if anchor == null:
		return
	_liquid_visual_anchors.append(anchor)
	var key := anchor.get_instance_id()
	_liquid_visual_anchor_homes[key] = anchor.transform
	_liquid_visual_anchor_weights[key] = Vector2(lag_weight, scale_weight)


func _apply_visual_anchor_deformation() -> void:
	if not _GelProfiles.motion_truth_enabled():
		return
	var turn_axis := Vector3(-_liquid_flow_direction.z, 0.0, _liquid_flow_direction.x)
	if turn_axis.length_squared() > 0.000001:
		turn_axis = turn_axis.normalized()
	for anchor in _liquid_visual_anchors:
		if not is_instance_valid(anchor):
			continue
		var key := anchor.get_instance_id()
		var home: Transform3D = _liquid_visual_anchor_homes.get(key, Transform3D.IDENTITY)
		var weights: Vector2 = _liquid_visual_anchor_weights.get(key, Vector2(0.5, 0.25))
		var offset := _liquid_effective_lag * weights.x
		offset += turn_axis * _liquid_turn_shear * weights.x
		offset += _liquid_contact_normal * maxf(_liquid_contact_amount, 0.0) * 0.032 * weights.x
		var squash := _liquid_effective_squash * weights.y
		var anchor_scale := Vector3(1.0 + squash * 0.55, 1.0 - squash, 1.0 + squash * 0.55)
		var turn_basis := Basis(Vector3.UP, _liquid_turn_shear * weights.x * 2.4)
		anchor.transform = Transform3D(
			turn_basis * home.basis.scaled(anchor_scale),
			home.origin + offset
		)


func _apply_liquid_runtime_uniforms(force: bool = false) -> void:
	var runtime_lag := _liquid_effective_lag if _GelProfiles.motion_truth_enabled() else _viscous_body_lag
	var runtime_squash := _liquid_effective_squash if _GelProfiles.motion_truth_enabled() else _viscous_body_squash
	if (
		not force
		and absf(_liquid_motion_mix - _liquid_last_sent_motion) < 0.001
		and _liquid_flow_direction.distance_squared_to(_liquid_last_sent_direction) < 0.000004
		and runtime_lag.distance_squared_to(_liquid_last_sent_lag) < 0.000002
		and absf(runtime_squash - _liquid_last_sent_squash) < 0.0005
		and absf(_liquid_turn_shear - _liquid_last_sent_turn) < 0.0003
		and absf(_liquid_contact_amount - _liquid_last_sent_contact) < 0.001
		and _liquid_contact_normal.distance_squared_to(_liquid_last_sent_contact_normal) < 0.000004
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
	for material in _liquid_attachment_materials:
		material.set_shader_parameter(&"liquid_flow_motion_mix", _liquid_motion_mix)
		material.set_shader_parameter(&"liquid_flow_direction", _liquid_flow_direction)
		_apply_viscous_material_uniforms(material)
	_apply_visual_anchor_deformation()
	_liquid_last_sent_motion = _liquid_motion_mix
	_liquid_last_sent_direction = _liquid_flow_direction
	_liquid_last_sent_lag = runtime_lag
	_liquid_last_sent_squash = runtime_squash
	_liquid_last_sent_turn = _liquid_turn_shear
	_liquid_last_sent_contact = _liquid_contact_amount
	_liquid_last_sent_contact_normal = _liquid_contact_normal


func _apply_viscous_material_uniforms(material: ShaderMaterial) -> void:
	material.set_shader_parameter(&"liquid_body_deform_strength", _VISCOUS_DEFORM_STRENGTH)
	material.set_shader_parameter(
		&"liquid_body_lag",
		_liquid_effective_lag if _GelProfiles.motion_truth_enabled() else _viscous_body_lag
	)
	material.set_shader_parameter(
		&"liquid_body_squash",
		_liquid_effective_squash if _GelProfiles.motion_truth_enabled() else _viscous_body_squash
	)
	if _GelProfiles.motion_truth_enabled():
		material.set_shader_parameter(&"liquid_turn_shear", _liquid_turn_shear)
		material.set_shader_parameter(&"liquid_contact_amount", _liquid_contact_amount)
		material.set_shader_parameter(&"liquid_contact_normal", _liquid_contact_normal)


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
	if _GelProfiles.motion_truth_enabled():
		if _terminal_animation:
			return
		if _animation_priority > _ANIM_DUTY and _animation_kind != _KIND_REST:
			_pending_duty = new_duty
			return
	duty = new_duty
	duty_changed.emit(new_duty)
	# The base scenes intentionally keep an empty particle placeholder. Submitting
	# a GPUParticles3D restart without both a process material and draw mesh can
	# rasterize undefined full-screen triangles on the Compatibility/Web renderer.
	if kit_swap_burst and kit_swap_burst.process_material != null and kit_swap_burst.draw_pass_1 != null:
		kit_swap_burst.restart()
	_apply_duty(new_duty)
	if animation_player == null:
		return
	var duty_animation: StringName
	if new_duty == &"fixed":
		if family_id == &"A" and animation_player.has_animation("relay_close"):
			duty_animation = &"relay_close"
		else:
			duty_animation = &"plant"
		planted.emit()
	elif new_duty == &"relay":
		duty_animation = &"relay_open"
	else:
		duty_animation = &"uproot"
		uprooted.emit()
	if _GelProfiles.motion_truth_enabled():
		_request_managed_animation(duty_animation, _ANIM_DUTY, _KIND_DUTY, 0.06)
	else:
		animation_player.play(duty_animation)


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


## Registers a tokenized combat presentation request. Gameplay remains in the
## caller and commits only after combat_action_released reaches the authored
## method key. V8 and earlier callers keep fire_skill() as an immediate fallback.
func request_combat_action(
	request_id: int,
	action_kind: StringName,
	visual_id: StringName,
	cadence_seconds: float = 0.0
) -> bool:
	if not _GelProfiles.motion_truth_enabled() or _terminal_animation or request_id <= 0:
		return false
	if action_kind != _KIND_BASIC and action_kind != _KIND_ACTIVE:
		return false
	var request := {
		"id": request_id,
		"kind": action_kind,
		"visual_id": visual_id,
		"cadence": maxf(cadence_seconds, 0.0),
		"released": false,
	}
	if action_kind == _KIND_BASIC:
		# Auto-fire retries without consuming cadence while a transform or another
		# action owns the one-shot layer; it never grows an unbounded queue.
		if _animation_priority >= _ANIM_DUTY:
			return false
		_start_combat_request(request)
		return true

	# Active skills preempt an unreleased basic, but wait behind an already
	# visible duty transformation so the body cannot pop between two poses.
	if _animation_kind == _KIND_DUTY:
		_buffer_combat_request(request)
		return true
	if _animation_kind == _KIND_ACTIVE:
		return false
	if _animation_kind == _KIND_BASIC:
		_cancel_current_combat_action(&"preempted")
	_start_combat_request(request)
	return true


func cancel_combat_action(reason: StringName = &"cancelled") -> void:
	_cancel_current_combat_action(reason)
	if not _buffered_combat_request.is_empty():
		var buffered_id := int(_buffered_combat_request.get("id", 0))
		var buffered_kind := StringName(_buffered_combat_request.get("kind", &""))
		_buffered_combat_request.clear()
		if buffered_id > 0:
			combat_action_cancelled.emit(buffered_id, buffered_kind, reason)


func _start_combat_request(request: Dictionary) -> void:
	_combat_request = request.duplicate(true)
	var kind := StringName(_combat_request.get("kind", _KIND_BASIC))
	var animation_name := &"skill_cast" if kind == _KIND_ACTIVE and animation_player.has_animation(&"skill_cast") else &"attack"
	var priority := _ANIM_ACTIVE if kind == _KIND_ACTIVE else _ANIM_BASIC
	var cadence := float(_combat_request.get("cadence", 0.0))
	var playback_speed := 1.0
	if cadence > 0.0 and animation_player.has_animation(animation_name):
		var animation := animation_player.get_animation(animation_name)
		playback_speed = maxf(1.0, animation.length / maxf(cadence, 0.08))
	if not _request_managed_animation(animation_name, priority, kind, 0.06, playback_speed):
		_cancel_current_combat_action(&"rejected")


func _buffer_combat_request(request: Dictionary) -> void:
	if not _buffered_combat_request.is_empty():
		var replaced_id := int(_buffered_combat_request.get("id", 0))
		var replaced_kind := StringName(_buffered_combat_request.get("kind", &""))
		if replaced_id > 0:
			combat_action_cancelled.emit(replaced_id, replaced_kind, &"replaced")
	_buffered_combat_request = request.duplicate(true)


func _consume_buffered_combat_request() -> bool:
	if _buffered_combat_request.is_empty():
		return false
	var request := _buffered_combat_request.duplicate(true)
	_buffered_combat_request.clear()
	_start_combat_request(request)
	return true


func _cancel_current_combat_action(reason: StringName) -> void:
	if _combat_request.is_empty():
		return
	var request_id := int(_combat_request.get("id", 0))
	var kind := StringName(_combat_request.get("kind", &""))
	var released := bool(_combat_request.get("released", false))
	_combat_request.clear()
	if request_id > 0 and not released:
		combat_action_cancelled.emit(request_id, kind, reason)


## AnimationPlayer Call Method tracks invoke this exactly at the authored release
## pose. The request is marked first so re-entrant signal handlers cannot double fire.
func _on_combat_release_marker() -> void:
	if _combat_request.is_empty() or bool(_combat_request.get("released", false)):
		return
	var request_id := int(_combat_request.get("id", 0))
	var kind := StringName(_combat_request.get("kind", &""))
	if request_id <= 0 or (kind != _KIND_BASIC and kind != _KIND_ACTIVE):
		return
	_combat_request["released"] = true
	var visual_id := StringName(_combat_request.get("visual_id", &""))
	skill_fired.emit(visual_id)
	if kind == _KIND_ACTIVE:
		VfxLibrary.play_skill(visual_id, self, weapon_socket)
	combat_action_released.emit(request_id, kind)


## Reactive squash, ~0.3 s. Safe to spam; it always resolves back to rest.
func play_hit() -> void:
	if _GelProfiles.motion_truth_enabled():
		if _animation_kind == _KIND_ACTIVE and not bool(_combat_request.get("released", false)):
			return
		if _animation_kind == _KIND_BASIC:
			_cancel_current_combat_action(&"hit")
		_request_managed_animation(&"hit", _ANIM_HIT, _KIND_HIT, 0.03)
	else:
		_play_once(&"hit")


## Wind-up and release. The projectile itself is VfxLibrary's job.
func play_attack() -> void:
	if _GelProfiles.motion_truth_enabled():
		_request_managed_animation(&"attack", _ANIM_BASIC, _KIND_BASIC, 0.06)
	else:
		_play_once(&"attack")


## Whichever loop matches the current duty: the travel lope when mobile,
## the breathe when planted.
func play_rest() -> void:
	_play_rest()


## Rebuilds the gel animation set against the character's current nodes.
## Call this after swapping CoreMesh, since the squash pivot is measured from
## the mesh bounds.
func rebuild_gel_anims() -> void:
	if _GelProfiles.motion_truth_enabled():
		cancel_combat_action(&"animation_rebuild")
		_animation_priority = _ANIM_REST
		_animation_kind = _KIND_REST
		_managed_animation = &""
		_pending_duty = &""
		_terminal_animation = false
	_cache_liquid_materials()
	_gel_driven = false
	if animation_player == null:
		return
	# Combat release keys are gameplay boundaries in V8.1. Immediate callbacks
	# guarantee the marker is consumed before animation_finished when a low-FPS
	# advance crosses both. Explicit V5-V8 restores the scene's original mode.
	animation_player.callback_mode_method = (
		AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
		if _GelProfiles.motion_truth_enabled()
		else _method_callback_mode_before_v8_1
	)
	# Undo any static hover offset so the rest pose is read clean on a re-bake.
	for node_name in _hover_homes.keys():
		var node := get_node_or_null(String(node_name)) as Node3D
		if node:
			node.position.y = float(_hover_homes[node_name])
	var lift := A_HOVER_LIFT if family_id == &"A" else 0.0
	var lib := _GelAnim.build_library(self, lift)
	if animation_player.has_animation_library(""):
		var existing := animation_player.get_animation_library("")
		# A profile can be changed by the smoke harness without rebuilding the
		# process. Remove the complete generated set first so selecting V8 after
		# V8.1 cannot leave V8.1-only clips behind.
		var generated_names := _GelAnim.NAMES.duplicate()
		generated_names.append_array(_GelAnim.V8_1_NAMES)
		generated_names.append_array(_GelAnim.V8_2_NAMES)
		for generated_name in generated_names:
			if existing.has_animation(generated_name):
				existing.remove_animation(generated_name)
		for anim_name in lib.get_animation_list():
			existing.add_animation(anim_name, lib.get_animation(anim_name))
	else:
		animation_player.add_animation_library("", lib)
	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
	_gel_driven = true


func _rest_anim() -> StringName:
	if _GelProfiles.motion_truth_enabled():
		if _can_visually_locomote() and _liquid_locomotion_active:
			if family_id == &"A" and duty == &"relay" and animation_player.has_animation(&"relay_glide"):
				return &"relay_glide"
			return &"move"
		return &"idle"
	if _GelProfiles.v8_enabled() and duty == &"mobile":
		return &"move" if _liquid_locomotion_active else &"idle"
	return &"move" if duty == &"mobile" else &"idle"


func _play_rest() -> void:
	if animation_player == null:
		return
	if _GelProfiles.motion_truth_enabled() and (
		_terminal_animation or _animation_priority > _ANIM_REST
	):
		return
	var rest := _rest_anim()
	if animation_player.has_animation(rest):
		if _GelProfiles.motion_truth_enabled():
			_animation_priority = _ANIM_REST
			_animation_kind = _KIND_REST
			_managed_animation = rest
			if animation_player.is_playing() and animation_player.current_animation == rest:
				return
		animation_player.play(rest, 0.18)


func _request_managed_animation(
	anim_name: StringName,
	priority: int,
	kind: StringName,
	blend: float,
	custom_speed: float = 1.0
) -> bool:
	if (
		animation_player == null
		or not animation_player.has_animation(anim_name)
		or (_terminal_animation and priority < _ANIM_TERMINAL)
		or priority < _animation_priority
	):
		return false
	# A higher-priority one-shot may blend a locomotion edge out before Godot
	# emits animation_finished. Resolve the presentation state explicitly so the
	# controller cannot remain stuck in "starting" or "stopping" forever.
	if priority > _animation_priority and _animation_kind == _KIND_LOCOMOTION:
		if _managed_animation == &"move_start":
			_liquid_locomotion_state = &"moving"
		elif _managed_animation == &"move_stop":
			_liquid_locomotion_state = &"idle"
	_animation_priority = priority
	_animation_kind = kind
	_managed_animation = anim_name
	animation_player.play(anim_name, maxf(blend, 0.0), maxf(custom_speed, 0.01))
	return true


func current_animation_kind() -> StringName:
	return _animation_kind


func current_animation_priority() -> int:
	return _animation_priority


func has_buffered_combat_action() -> bool:
	return not _buffered_combat_request.is_empty()


func _play_once(anim_name: StringName) -> void:
	if animation_player == null or not animation_player.has_animation(anim_name):
		return
	animation_player.play(anim_name, 0.06)


func _on_animation_finished(anim_name: StringName) -> void:
	if not _GelProfiles.motion_truth_enabled():
		if anim_name == &"idle" or anim_name == &"move":
			return
		_play_rest()
		return
	if anim_name == &"idle" or anim_name == &"move" or anim_name == &"relay_glide":
		return
	# Ignore a completion emitted by an animation which was blended out and no
	# longer owns the presentation lane.
	if anim_name != _managed_animation:
		return
	var finished_kind := _animation_kind
	# Terminal clips are non-looping, but their final sample is the intended end
	# state. Keep priority and ownership latched so no idle/duty/combat request can
	# replace that pose after AnimationPlayer emits animation_finished.
	if finished_kind == _KIND_TERMINAL:
		return
	if finished_kind == _KIND_BASIC or finished_kind == _KIND_ACTIVE:
		if not _combat_request.is_empty() and not bool(_combat_request.get("released", false)):
			push_warning(
				"Combat animation %s completed without its release marker" % anim_name
			)
			_cancel_current_combat_action(&"missing_release")
		else:
			_combat_request.clear()
	_animation_priority = _ANIM_REST
	_animation_kind = _KIND_REST
	_managed_animation = &""

	if anim_name == &"move_start" and _liquid_locomotion_state == &"starting":
		_liquid_locomotion_state = &"moving"
	elif anim_name == &"move_stop" and _liquid_locomotion_state == &"stopping":
		_liquid_locomotion_state = &"idle"

	if finished_kind == _KIND_DUTY and _consume_buffered_combat_request():
		return
	if not _pending_duty.is_empty():
		var pending_duty := _pending_duty
		_pending_duty = &""
		transform_duty(pending_duty)
		if _animation_priority > _ANIM_REST:
			return
	if _consume_buffered_combat_request():
		return
	_play_rest()
