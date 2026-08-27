extends CharacterBody3D
class_name ImmuneCharacter

## One core mesh. Duty kits swap. Never freeze-and-swap a second body.

signal planted
signal uprooted
signal skill_fired(skill_id: StringName)

const _KitBlockout := preload("res://characters/kit_blockout.gd")
const _GelAnim := preload("res://characters/gel_anim.gd")
const _Look := preload("res://characters/family_look.gd")

@export var family_id: StringName = &"T"
@export var character_id: StringName = &"CHAR-BASE-T"

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

const A_HOVER_LIFT := 0.38
const A_HOVER_BOB := 0.055
const _HOVER_NODES: PackedStringArray = ["CoreMesh", "Face", "WeaponSocket", "DutyKits", "KitSwapBurst", "LimbKit"]


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
	if family_id == &"A":
		_cache_hover_homes()
		_apply_hover(A_HOVER_LIFT)
	# The gel rig carries A's hover and bob itself, so the per-frame offset
	# would only fight the animation tracks for the same properties.
	set_process(family_id == &"A" and not _gel_driven)
	_play_rest()


func _realize_imported_mesh() -> void:
	if family_id != &"T" and family_id != &"B":
		return
	real_mesh = get_node_or_null("CoreMesh/RealMesh")
	if real_mesh == null:
		return
	# Imported bodies keep the shared blockout path for duty kits/collision. T's
	# textured sculpt carries its final face; B's untextured Meshy sculpt needs the
	# procedural ink face aligned over the raised eye and mouth geometry.
	var face := get_node_or_null("Face") as Node3D
	if face:
		face.visible = family_id == &"B"
		if family_id == &"B":
			var eye_l := face.get_node_or_null("EyeL") as Node3D
			var eye_r := face.get_node_or_null("EyeR") as Node3D
			var mouth := face.get_node_or_null("Mouth") as Node3D
			if eye_l:
				eye_l.position = Vector3(-0.13, 0.05, 0.02)
				eye_l.scale = Vector3.ONE * 1.15
			if eye_r:
				eye_r.position = Vector3(0.13, 0.05, 0.02)
				eye_r.scale = Vector3.ONE * 1.15
			if mouth:
				# Sit behind the sculpted lip as a dark cavity backing instead of
				# floating in front of the face like a third eye.
				mouth.position = Vector3(0.0, -0.09, -0.05)
				mouth.scale = Vector3(2.2, 2.2, 0.45)
	var limbs := get_node_or_null("LimbKit") as Node3D
	if limbs:
		limbs.visible = false
	var gel_opts := {}
	if family_id == &"B":
		# Smooth regenerated vertex normals carry both the soft silhouette and its
		# wet highlights. The procedural cell field stays off here: on this UV-less
		# topology it resolves as directional ripples instead of round jelly pores.
		gel_opts = {
			&"dimple_depth": 0.0,
			&"thin_curvature": 0.04,
			&"rim_energy": 0.10,
			&"coat_strength": 1.15,
		}
	_Look.apply_gel(real_mesh, String(family_id), gel_opts)


func _process(delta: float) -> void:
	if family_id != &"A" or _gel_driven:
		return
	_hover_t += delta
	_apply_hover(A_HOVER_LIFT + sin(_hover_t * 2.2) * A_HOVER_BOB)


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
	if kit_swap_burst:
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
