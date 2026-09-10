extends SceneTree

## Deterministic V8.6 animation and procedural-liquid acceptance gate.
##
## AnimationPlayer owns the fourteen fixed clips. CharacterRoot's liquid bridge
## is an independent procedural layer that remains active during idle and is
## driven by resolved locomotion velocity while moving. This gate validates both
## systems without changing gameplay state or relying on pixel comparisons.

const _GelProfiles := preload("res://characters/gel/gel_profiles.gd")

const CHARACTER_PATH := "res://characters/base_t/character.tscn"
const BODY_MARKER := &"v8_6_authored_sculpt"
const SHELL_MARKER := &"v8_6_single_mass_shell"
const EXPECTED_SCULPT_PATH := (
	"res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb"
)
const EXPECTED_SCULPT_SHA256 := (
	"3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3"
)
const EXPECTED_SCULPT_RESOURCE_NAME := "V8.6-AuthoredSculpt-T-r7-2"
const EXPECTED_SCULPT_AABB_POSITION := Vector3(-0.82, 0.0, -0.50)
const EXPECTED_SCULPT_AABB_SIZE := Vector3(1.64, 1.46, 1.00)
const EXPECTED_ANIMATIONS: PackedStringArray = [
	"idle",
	"plant",
	"uproot",
	"move",
	"hit",
	"attack",
	"relay_open",
	"relay_close",
	"move_start",
	"move_stop",
	"relay_glide",
	"skill_cast",
	"victory",
	"defeat",
]
const EXPECTED_LENGTHS := {
	"idle": 2.60,
	"plant": 1.15,
	"uproot": 1.00,
	"move": 1.12,
	"hit": 0.36,
	"attack": 0.78,
	"relay_open": 1.00,
	"relay_close": 1.15,
	"move_start": 0.28,
	"move_stop": 0.52,
	"relay_glide": 1.60,
	"skill_cast": 0.96,
	"victory": 1.30,
	"defeat": 1.18,
}
const LOOPING_ANIMATIONS: PackedStringArray = ["idle", "move", "relay_glide"]
const EXPECTED_RENDER_MESHES: PackedStringArray = [
	"Body",
	"BodyShell",
	"EyeL",
	"EyeR",
	"ForeheadPore",
	"ForeheadPoreRim",
	"MouthCavity",
]
const FORBIDDEN_FALLBACK_MARKERS: PackedStringArray = [
	"v8_3_single_mass",
	"v8_4_single_mass",
	"v8_5_single_mass",
	"v8_5_authored_sculpt",
]
const SAMPLE_COUNT_PER_CLIP := 11
const SCALE_FLOOR := 0.70
const SCALE_CEILING := 1.30

var _errors: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_check_selector_contract()
	var packed := load(CHARACTER_PATH) as PackedScene
	_check(packed != null, "T character did not load as PackedScene")
	if packed == null:
		_finish({})
		return
	var character := packed.instantiate() as Node3D
	_check(character != null, "T character failed to instantiate")
	if character == null:
		_finish({})
		return
	root.add_child(character)
	await process_frame
	await process_frame

	var animation_metrics := _check_animation_contract(character)
	var shape_metrics := _check_single_mass_contract(character)
	var liquid_metrics := _check_liquid_contract(character)
	var report := {
		"schema": 2,
		"selector": _GelProfiles.selected_look(),
		"profile": String(_GelProfiles.profile_name("T")),
		"sculpt_path": String(shape_metrics.get("sculpt_path", "")),
		"sculpt_sha256": String(shape_metrics.get("sculpt_sha256", "")),
		"sculpt_resource_name": String(shape_metrics.get("sculpt_resource_name", "")),
		"sculpt_aabb_position": shape_metrics.get("sculpt_aabb_position", []),
		"sculpt_aabb_size": shape_metrics.get("sculpt_aabb_size", []),
		"fallback_nodes": int(shape_metrics.get("fallback_nodes", -1)),
		"animation_count": int(animation_metrics.get("animation_count", 0)),
		"animations": Array(EXPECTED_ANIMATIONS),
		"sampled_clips": int(animation_metrics.get("sampled_clips", 0)),
		"sampled_poses": int(animation_metrics.get("sampled_poses", 0)),
		"min_scale": float(animation_metrics.get("min_scale", 0.0)),
		"max_scale": float(animation_metrics.get("max_scale", 0.0)),
		"move_scale_span": float(animation_metrics.get("move_scale_span", 0.0)),
		"idle_flow_speed": float(liquid_metrics.get("idle_flow_speed", 0.0)),
		"idle_slime_strength": float(liquid_metrics.get("idle_slime_strength", 0.0)),
		"moving_mix": float(liquid_metrics.get("moving_mix", 0.0)),
		"moving_lag": float(liquid_metrics.get("moving_lag", 0.0)),
		"moving_squash": float(liquid_metrics.get("moving_squash", 0.0)),
		"settling_lag": float(liquid_metrics.get("settling_lag", 0.0)),
		"settled_mix": float(liquid_metrics.get("settled_mix", 0.0)),
		"settled_lag": float(liquid_metrics.get("settled_lag", 0.0)),
		"settled_squash": float(liquid_metrics.get("settled_squash", 0.0)),
		"wet_materials": int(liquid_metrics.get("wet_materials", 0)),
		"shell_materials": int(liquid_metrics.get("shell_materials", 0)),
		"collision_unchanged": bool(liquid_metrics.get("collision_unchanged", false)),
		"detached_meshes": int(shape_metrics.get("detached_meshes", -1)),
	}
	_finish(report)
	character.queue_free()


func _check_selector_contract() -> void:
	_check(_GelProfiles.selected_look() == "v8_6", "selector did not resolve exactly to v8_6")
	_check(_GelProfiles.v8_6_enabled(), "exact V8.6 selector helper is false")
	_check(not _GelProfiles.v8_5_enabled(), "V8.6 incorrectly aliases the exact V8.5 selector")
	_check(_GelProfiles.motion_truth_enabled(), "V8.6 lost the movement-truth layer")
	_check(_GelProfiles.living_volume_enabled(), "V8.6 lost living-volume animation inventory")
	_check(_GelProfiles.single_mass_enabled(), "V8.6 lost the single-mass contract")
	_check(_GelProfiles.reference_viscosity_enabled(), "V8.6 lost reference viscosity")
	_check(
		_GelProfiles.reference_sculpt_behavior_enabled(),
		"V8.6 did not inherit the approved V8.5 motion behavior",
	)
	_check(
		_GelProfiles.profile_name("T") == &"reference_convergence",
		"T profile is not reference_convergence",
	)


func _check_animation_contract(character: Node3D) -> Dictionary:
	var animator := character.get_node_or_null("AnimationPlayer") as AnimationPlayer
	_check(animator != null, "AnimationPlayer is missing")
	if animator == null:
		return {}
	animator.stop()
	var actual_names := animator.get_animation_list()
	_check(
		actual_names.size() == EXPECTED_ANIMATIONS.size(),
		"expected exactly 14 animations, got %d" % actual_names.size(),
	)
	for animation_name in EXPECTED_ANIMATIONS:
		_check(
			animator.has_animation(StringName(animation_name)),
			"required animation is missing: %s" % animation_name,
		)
	for actual_name in actual_names:
		_check(
			String(actual_name) in EXPECTED_ANIMATIONS,
			"unexpected animation leaked into V8.6: %s" % actual_name,
		)

	var sampled_clips := 0
	var sampled_poses := 0
	var min_scale := INF
	var max_scale := -INF
	var move_scale_min := INF
	var move_scale_max := -INF
	for animation_name in EXPECTED_ANIMATIONS:
		if not animator.has_animation(StringName(animation_name)):
			continue
		var animation := animator.get_animation(StringName(animation_name))
		_check(animation != null, "animation resource is null: %s" % animation_name)
		if animation == null:
			continue
		sampled_clips += 1
		_check(
			is_equal_approx(animation.length, float(EXPECTED_LENGTHS[animation_name])),
			"%s length drifted to %.6f" % [animation_name, animation.length],
		)
		var expected_loop := (
			Animation.LOOP_LINEAR
			if animation_name in LOOPING_ANIMATIONS
			else Animation.LOOP_NONE
		)
		_check(
			animation.loop_mode == expected_loop,
			"%s loop mode drifted to %s" % [animation_name, animation.loop_mode],
		)
		var scale_track := _find_core_scale_track(animation)
		_check(scale_track >= 0, "%s lost its whole-body scale track" % animation_name)
		if scale_track < 0:
			continue
		for sample_index in SAMPLE_COUNT_PER_CLIP:
			var sample_time := animation.length * float(sample_index) / float(SAMPLE_COUNT_PER_CLIP - 1)
			var value: Variant = animation.value_track_interpolate(scale_track, sample_time)
			_check(value is Vector3, "%s scale track returned a non-Vector3 value" % animation_name)
			if not (value is Vector3):
				continue
			var sampled_scale: Vector3 = value
			sampled_scale = sampled_scale.abs()
			for component in [sampled_scale.x, sampled_scale.y, sampled_scale.z]:
				_check(is_finite(component), "%s emitted a non-finite scale" % animation_name)
				min_scale = minf(min_scale, component)
				max_scale = maxf(max_scale, component)
				_check(
					component >= SCALE_FLOOR and component <= SCALE_CEILING,
					"%s sampled scale %.6f is outside %.2f..%.2f"
					% [animation_name, component, SCALE_FLOOR, SCALE_CEILING],
				)
			if animation_name == "move":
				move_scale_min = minf(move_scale_min, sampled_scale.y)
				move_scale_max = maxf(move_scale_max, sampled_scale.y)
			sampled_poses += 1

	var move_scale_span := maxf(0.0, move_scale_max - move_scale_min)
	_check(move_scale_span >= 0.03, "move clip no longer carries visible viscous squash")
	return {
		"animation_count": actual_names.size(),
		"sampled_clips": sampled_clips,
		"sampled_poses": sampled_poses,
		"min_scale": min_scale if is_finite(min_scale) else 0.0,
		"max_scale": max_scale if is_finite(max_scale) else 0.0,
		"move_scale_span": move_scale_span,
	}


func _find_core_scale_track(animation: Animation) -> int:
	for track_index in animation.get_track_count():
		if (
			animation.track_get_type(track_index) == Animation.TYPE_VALUE
			and String(animation.track_get_path(track_index)) == "CoreMesh:scale"
		):
			return track_index
	return -1


func _check_single_mass_contract(character: Node3D) -> Dictionary:
	var real_mesh := character.get_node_or_null("CoreMesh/RealMesh") as Node3D
	_check(real_mesh != null, "authored RealMesh is missing")
	if real_mesh == null:
		return {
			"detached_meshes": -1,
			"fallback_nodes": -1,
		}
	var body := real_mesh.get_node_or_null("Body") as MeshInstance3D
	var shell := real_mesh.get_node_or_null("BodyShell") as MeshInstance3D
	_check(body != null and body.mesh != null, "authored R7.2 Body mesh is missing")
	_check(shell != null and shell.mesh != null, "authored R7.2 BodyShell mesh is missing")
	var body_markers: Array[Node] = []
	var shell_markers: Array[Node] = []
	var fallback_nodes: Array[Node] = []
	_collect_meta_nodes(character, BODY_MARKER, body_markers)
	_collect_meta_nodes(character, SHELL_MARKER, shell_markers)
	for marker in FORBIDDEN_FALLBACK_MARKERS:
		_collect_meta_nodes(character, StringName(marker), fallback_nodes)
	_check(body_markers.size() == 1, "expected one V8.6 authored body marker")
	_check(shell_markers.size() == 1, "expected one V8.6 authored shell marker")
	_check(fallback_nodes.is_empty(), "a V8.3/V8.4/V8.5 fallback body leaked into V8.6")
	_check(body != null and body_markers.has(body), "R7.2 authored body marker is not on Body")
	_check(shell != null and shell_markers.has(shell), "R7.2 single-mass marker is not on BodyShell")

	var source_exists := ResourceLoader.exists(EXPECTED_SCULPT_PATH)
	_check(source_exists, "exact R7.2 sculpt source is unavailable; fallback is forbidden")
	var sculpt_sha256 := (
		FileAccess.get_sha256(EXPECTED_SCULPT_PATH)
		if FileAccess.file_exists(EXPECTED_SCULPT_PATH)
		else ""
	)
	_check(
		sculpt_sha256 == EXPECTED_SCULPT_SHA256,
		"R7.2 sculpt SHA-256 drifted: %s" % sculpt_sha256,
	)
	var sculpt_resource_name := body.mesh.resource_name if body != null and body.mesh != null else ""
	_check(
		sculpt_resource_name == EXPECTED_SCULPT_RESOURCE_NAME,
		"runtime Body did not bind exact R7.2 mesh resource: %s" % sculpt_resource_name,
	)
	var sculpt_bounds := body.mesh.get_aabb() if body != null and body.mesh != null else AABB()
	_check(
		sculpt_bounds.position.is_equal_approx(EXPECTED_SCULPT_AABB_POSITION),
		"R7.2 Body AABB position drifted: %s" % sculpt_bounds.position,
	)
	_check(
		sculpt_bounds.size.is_equal_approx(EXPECTED_SCULPT_AABB_SIZE),
		"R7.2 Body AABB size drifted: %s" % sculpt_bounds.size,
	)
	_check(
		body != null and shell != null and body.mesh == shell.mesh,
		"R7.2 wet core and shell do not share one bonded sculpt mesh",
	)

	var face := character.get_node_or_null("Face") as Node3D
	_check(face != null and not face.visible, "procedural Face must remain hidden")
	_check(face != null and face.get_child_count() == 0, "procedural Face allocated detached marks")
	_check(character.get_node_or_null("LimbKit") == null, "detached procedural LimbKit exists")
	_check(character.get_node_or_null("CoreMesh/Bubble0") == null, "detached procedural bubble exists")
	for kit_path in ["DutyKits/BaseKit", "DutyKits/LocomotionKit", "DutyKits/RelayDish"]:
		var kit := character.get_node_or_null(kit_path) as Node3D
		if kit != null:
			_check(not kit.visible, "%s became visible in single-mass V8.6" % kit_path)
			_check(kit.get_child_count() == 0, "%s allocated detached geometry" % kit_path)
	var burst := character.get_node_or_null("KitSwapBurst") as GPUParticles3D
	_check(burst != null and not burst.visible and not burst.emitting, "loose kit-swap particles are active")

	var detached_paths: PackedStringArray = []
	var render_mesh_counts := {}
	_collect_render_mesh_contract(character, real_mesh, detached_paths, render_mesh_counts)
	for mesh_name in EXPECTED_RENDER_MESHES:
		_check(
			int(render_mesh_counts.get(mesh_name, 0)) == 1,
			"expected exactly one bonded %s mesh" % mesh_name,
		)
	_check(
		detached_paths.is_empty(),
		"unexpected or detached render meshes: %s" % ", ".join(detached_paths),
	)
	return {
		"sculpt_path": EXPECTED_SCULPT_PATH if source_exists else "",
		"sculpt_sha256": sculpt_sha256,
		"sculpt_resource_name": sculpt_resource_name,
		"sculpt_aabb_position": _vector3_report(sculpt_bounds.position),
		"sculpt_aabb_size": _vector3_report(sculpt_bounds.size),
		"fallback_nodes": fallback_nodes.size(),
		"detached_meshes": detached_paths.size(),
	}


func _vector3_report(value: Vector3) -> Array[float]:
	return [
		snappedf(value.x, 0.000001),
		snappedf(value.y, 0.000001),
		snappedf(value.z, 0.000001),
	]


func _collect_render_mesh_contract(
	node: Node,
	real_mesh: Node3D,
	detached_paths: PackedStringArray,
	render_mesh_counts: Dictionary,
) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		var inside_authored_body := real_mesh.is_ancestor_of(mesh_instance)
		var mesh_name := String(mesh_instance.name)
		if inside_authored_body and mesh_name in EXPECTED_RENDER_MESHES:
			render_mesh_counts[mesh_name] = int(render_mesh_counts.get(mesh_name, 0)) + 1
		else:
			detached_paths.append(String(character_path_to(node)))
	for child in node.get_children():
		_collect_render_mesh_contract(child, real_mesh, detached_paths, render_mesh_counts)


func character_path_to(node: Node) -> NodePath:
	return root.get_path_to(node)


func _check_liquid_contract(character: Node3D) -> Dictionary:
	var real_mesh := character.get_node_or_null("CoreMesh/RealMesh") as Node3D
	var body := real_mesh.get_node_or_null("Body") as MeshInstance3D if real_mesh != null else null
	var shell := real_mesh.get_node_or_null("BodyShell") as MeshInstance3D if real_mesh != null else null
	var wet := body.material_override as ShaderMaterial if body != null else null
	var membrane := shell.material_override as ShaderMaterial if shell != null else null
	_check(wet != null, "wet-gel body material is missing")
	_check(membrane != null, "clear shell material is missing")
	if wet == null or membrane == null:
		return {}

	var wet_materials := (
		int(character.call("liquid_material_count"))
		if character.has_method("liquid_material_count")
		else -1
	)
	var shell_materials := (
		int(character.call("liquid_shell_material_count"))
		if character.has_method("liquid_shell_material_count")
		else -1
	)
	_check(wet_materials == 1, "V8.6 T must bind exactly one wet material")
	_check(shell_materials == 1, "V8.6 T must bind exactly one shell material")
	var idle_flow_strength := float(wet.get_shader_parameter("liquid_flow_strength"))
	var idle_flow_speed := float(wet.get_shader_parameter("liquid_flow_idle_speed"))
	var idle_slime_strength := float(wet.get_shader_parameter("liquid_slime_strength"))
	var idle_laminar_strength := float(wet.get_shader_parameter("liquid_laminar_strength"))
	var idle_wobble_strength := float(wet.get_shader_parameter("liquid_wobble_strength"))
	var idle_mix := float(wet.get_shader_parameter("liquid_flow_motion_mix"))
	_check(idle_flow_strength > 0.001, "idle internal flow field is disabled")
	_check(idle_flow_speed > 0.001, "idle internal flow speed is zero")
	_check(idle_slime_strength > 0.001, "cohesive internal slime field is disabled")
	_check(idle_laminar_strength > 0.001, "laminar internal flow is disabled")
	_check(idle_wobble_strength > 0.001, "continuous body wobble is disabled")
	_check(is_zero_approx(idle_mix), "movement overlay is already active at idle")

	var collision := character.get_node_or_null("CollisionShape3D") as CollisionShape3D
	_check(collision != null and collision.shape != null, "stable gameplay collision is missing")
	var collision_transform := collision.transform if collision != null else Transform3D.IDENTITY
	var collision_shape := collision.shape if collision != null else null
	_check(character.has_method("update_liquid_flow"), "runtime liquid-flow bridge is missing")
	if character.has_method("update_liquid_flow"):
		character.call("update_liquid_flow", Vector3(3.0, 0.0, 0.0), 0.5)
	var moving_mix := float(wet.get_shader_parameter("liquid_flow_motion_mix"))
	var moving_direction := wet.get_shader_parameter("liquid_flow_direction") as Vector3
	var moving_lag_vector := wet.get_shader_parameter("liquid_body_lag") as Vector3
	var moving_lag := moving_lag_vector.length()
	var moving_squash := float(wet.get_shader_parameter("liquid_body_squash"))
	var shell_lag := membrane.get_shader_parameter("liquid_body_lag") as Vector3
	var shell_squash := float(membrane.get_shader_parameter("liquid_body_squash"))
	_check(moving_mix >= 0.72 and moving_mix <= 1.0, "movement overlay did not activate")
	_check(moving_direction.x >= 0.70, "internal flow did not follow movement direction")
	_check(moving_lag_vector.x < -0.003, "visible mass did not drag behind movement")
	_check(moving_lag > 0.003 and moving_lag <= 0.14, "viscous lag is outside its guard rails")
	_check(moving_squash > 0.004 and moving_squash <= 0.12, "movement compression is missing or excessive")
	_check(shell_lag.is_equal_approx(moving_lag_vector), "wet core and shell have split apart under drag")
	_check(is_equal_approx(shell_squash, moving_squash), "wet core and shell squash is incoherent")
	_check(
		is_equal_approx(float(wet.get_shader_parameter("liquid_flow_idle_speed")), idle_flow_speed),
		"idle flow stopped while movement overlay was active",
	)

	if character.has_method("update_liquid_flow"):
		character.call("update_liquid_flow", Vector3.ZERO, 1.0 / 60.0)
	var settling_lag := (wet.get_shader_parameter("liquid_body_lag") as Vector3).length()
	_check(settling_lag > 0.003, "viscous drag vanished immediately on movement stop")
	if character.has_method("update_liquid_flow"):
		for _settle_step in 120:
			character.call("update_liquid_flow", Vector3.ZERO, 1.0 / 60.0)
	var settled_mix := float(wet.get_shader_parameter("liquid_flow_motion_mix"))
	var settled_lag := (wet.get_shader_parameter("liquid_body_lag") as Vector3).length()
	var settled_squash := float(wet.get_shader_parameter("liquid_body_squash"))
	_check(settled_mix >= 0.0 and settled_mix < 0.12, "movement overlay did not decay to idle")
	_check(settled_lag < 0.012, "viscous lag did not settle")
	_check(settled_squash < 0.008, "viscous compression did not settle")
	var collision_unchanged := (
		collision != null
		and collision.transform.is_equal_approx(collision_transform)
		and collision.shape == collision_shape
	)
	_check(collision_unchanged, "visual viscosity changed gameplay collision")
	return {
		"idle_flow_speed": idle_flow_speed,
		"idle_slime_strength": idle_slime_strength,
		"moving_mix": moving_mix,
		"moving_lag": moving_lag,
		"moving_squash": moving_squash,
		"settling_lag": settling_lag,
		"settled_mix": settled_mix,
		"settled_lag": settled_lag,
		"settled_squash": settled_squash,
		"wet_materials": wet_materials,
		"shell_materials": shell_materials,
		"collision_unchanged": collision_unchanged,
	}


func _collect_meta_nodes(node: Node, marker: StringName, found: Array[Node]) -> void:
	if node.has_meta(marker):
		found.append(node)
	for child in node.get_children():
		_collect_meta_nodes(child, marker, found)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _finish(report: Dictionary) -> void:
	if not _errors.is_empty():
		for message in _errors:
			push_error("V8_6_ANIMATION_GATE_FAILED: %s" % message)
		quit(1)
		return
	print("V8_6_ANIMATION_GATE_OK %s" % JSON.stringify(report))
	quit(0)
