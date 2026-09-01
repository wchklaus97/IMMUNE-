extends Node3D

## Zero-credit authored jelly bodies for the round BASE-cell silhouettes.
##
## These forms are assembled from high-resolution primitives at runtime so the
## silhouettes stay editable in source control and never depend on a paid asset
## generation call. Each family keeps its locked concept identity while sharing
## the selected material language: a wet coloured core, deterministic CC0
## internal detail, and a compatibility-safe clear outer membrane. The project
## setting decides whether that resolves to the V5 control or V6 banner match.

const _Gel := preload("res://characters/gel/gel_look.gd")
const _GelProfiles := preload("res://characters/gel/gel_profiles.gd")
const _PrimitiveMeshes := preload("res://characters/primitive_mesh_cache.gd")
const _SHELL_SHADER := preload("res://characters/gel/jelly_shell.gdshader")
const _EYE_SHADER := preload("res://characters/gel/gel_eye.gdshader")

@export_enum("T", "B", "M", "N", "A", "D") var family_id := "N"

const _FIZZY_BASE := {
	&"albedo_gain": 0.88,
	&"body_roughness": 0.17,
	&"coat_roughness": 0.030,
	&"coat_strength": 1.55,
	&"spec_energy": 0.19,
	&"light_wrap": 0.22,
	&"sss_amount": 0.66,
	&"transmit_strength": 1.34,
	&"thin_glow": 0.55,
	&"rim_energy": 0.12,
	&"interior_budget": 0.12,
	&"rim_budget": 0.06,
	&"body_budget": 0.98,
	&"body_absorb": 0.84,
	&"extinction_density": 2.85,
	&"extinction_spread": 1.52,
	&"extinction_shape": 2.55,
	&"dimple_scale": 145.0,
	&"dimple_depth": 0.0,
	&"dimple_crease": 0.18,
	&"dimple_round": 0.95,
	&"bubble_enabled": true,
	&"bubble_scale": 7.4,
	&"bubble_density": 0.54,
	&"bubble_radius_min": 0.15,
	&"bubble_radius_max": 0.34,
	&"bubble_jitter": 0.17,
	&"bubble_softness": 0.105,
	&"bubble_depth": 0.002,
	&"bubble_thinness": 0.27,
	&"bubble_shell_shadow": 0.0,
	&"bubble_emission": 0.006,
	&"bubble_shell_emission": 0.085,
	&"microbubble_enabled": true,
	&"microbubble_scale": 48.0,
	&"microbubble_density": 1.0,
	&"microbubble_radius_min": 0.72,
	&"microbubble_radius_max": 0.80,
	&"microbubble_jitter": 0.14,
	&"microbubble_softness": 0.10,
	&"microbubble_depth": 0.035,
	&"microbubble_thinness": 0.0,
	&"microbubble_shell_shadow": 0.0,
	&"microbubble_emission": 0.0,
	&"microbubble_shell_emission": 0.0,
	&"inclusion_enabled": true,
	&"inclusion_scale": 72.0,
	&"inclusion_depth": 0.005,
	&"inclusion_threshold": 0.76,
	&"inclusion_softness": 0.050,
	&"inclusion_emission": 0.035,
}

const _FAMILY_LOOK := {
	"T": {
		&"jelly": Color(1.0, 0.48, 0.16, 1.0),
		&"body_color": Color(1.0, 0.30, 0.008, 1.0),
		&"deep_color": Color(0.58, 0.07, 0.002, 1.0),
		&"transmit_color": Color(1.0, 0.68, 0.18, 1.0),
		&"rim_color": Color(1.0, 0.78, 0.30, 1.0),
		&"shell_color": Color(1.0, 0.68, 0.22, 1.0),
		&"cavity_color": Color(0.34, 0.065, 0.006, 1.0),
		&"bubble_seed": 101.0,
		&"microbubble_seed": 103.0,
		&"inclusion_seed": 107.0,
	},
	"B": {
		&"jelly": Color(0.62, 0.22, 0.86, 1.0),
		&"body_color": Color(0.54, 0.07, 0.82, 1.0),
		&"deep_color": Color(0.18, 0.012, 0.36, 1.0),
		&"transmit_color": Color(0.76, 0.50, 1.0, 1.0),
		&"rim_color": Color(0.88, 0.72, 1.0, 1.0),
		&"shell_color": Color(0.76, 0.48, 1.0, 1.0),
		&"cavity_color": Color(0.16, 0.018, 0.27, 1.0),
		&"bubble_seed": 109.0,
		&"microbubble_seed": 113.0,
		&"inclusion_seed": 127.0,
	},
	"M": {
		&"jelly": Color(0.62, 0.28, 0.92, 1.0),
		&"body_color": Color(0.48, 0.18, 0.82, 1.0),
		&"deep_color": Color(0.16, 0.025, 0.36, 1.0),
		&"transmit_color": Color(0.76, 0.60, 1.0, 1.0),
		&"rim_color": Color(0.90, 0.80, 1.0, 1.0),
		&"shell_color": Color(0.82, 0.66, 1.0, 1.0),
		&"cavity_color": Color(0.18, 0.035, 0.34, 1.0),
		&"bubble_seed": 131.0,
		&"microbubble_seed": 137.0,
		&"inclusion_seed": 139.0,
	},
	"N": {
		&"jelly": Color(0.56, 0.86, 0.035, 1.0),
		&"body_color": Color(0.68, 0.86, 0.045, 1.0),
		&"deep_color": Color(0.25, 0.39, 0.008, 1.0),
		&"transmit_color": Color(0.91, 1.0, 0.24, 1.0),
		&"rim_color": Color(0.94, 1.0, 0.44, 1.0),
		&"shell_color": Color(0.88, 1.0, 0.31, 1.0),
		&"cavity_color": Color(0.11, 0.15, 0.015, 1.0),
		&"bubble_seed": 137.0,
		&"microbubble_seed": 149.0,
		&"inclusion_seed": 157.0,
	},
	"A": {
		&"jelly": Color(1.0, 0.55, 0.025, 1.0),
		&"body_color": Color(1.0, 0.58, 0.025, 1.0),
		&"deep_color": Color(0.64, 0.20, 0.004, 1.0),
		&"transmit_color": Color(1.0, 0.79, 0.20, 1.0),
		&"rim_color": Color(1.0, 0.88, 0.38, 1.0),
		&"shell_color": Color(1.0, 0.78, 0.25, 1.0),
		&"cavity_color": Color(0.32, 0.085, 0.008, 1.0),
		&"bubble_seed": 163.0,
		&"microbubble_seed": 173.0,
		&"inclusion_seed": 181.0,
	},
	"D": {
		&"jelly": Color(1.0, 0.39, 0.018, 1.0),
		&"body_color": Color(1.0, 0.42, 0.018, 1.0),
		&"deep_color": Color(0.67, 0.12, 0.003, 1.0),
		&"transmit_color": Color(1.0, 0.63, 0.16, 1.0),
		&"rim_color": Color(1.0, 0.76, 0.29, 1.0),
		&"shell_color": Color(1.0, 0.66, 0.20, 1.0),
		&"cavity_color": Color(0.34, 0.055, 0.006, 1.0),
		&"bubble_seed": 191.0,
		&"microbubble_seed": 199.0,
		&"inclusion_seed": 211.0,
	},
}


func _ready() -> void:
	var profile: Dictionary = _FAMILY_LOOK.get(family_id, _FAMILY_LOOK["N"])
	var options := _FIZZY_BASE.duplicate(true)
	for key in profile:
		if key != &"jelly" and key != &"shell_color" and key != &"cavity_color":
			options[key] = profile[key]
	options = _GelProfiles.with_v5_surface(options, family_id)
	var gel := _Gel.make_material(profile[&"jelly"], options)
	if gel == null:
		push_error("authored_jelly_body.gd: failed to create %s gel material" % family_id)
		return
	var shell := _make_shell(profile[&"shell_color"])
	_build_body(gel, shell)
	_build_face(gel, profile[&"cavity_color"])
	print("AUTHORED_JELLY_BODY family=%s profile=fizzy-zero-credit" % family_id)


func _make_shell(shell_color: Color) -> ShaderMaterial:
	var shell := ShaderMaterial.new()
	shell.shader = _SHELL_SHADER
	_Gel.apply_v5_shell_bounds(shell)
	shell.set_shader_parameter(&"shell_color", shell_color)
	shell.set_shader_parameter(&"face_alpha", 0.008)
	shell.set_shader_parameter(&"edge_alpha", 0.46)
	shell.set_shader_parameter(&"edge_power", 2.4)
	shell.set_shader_parameter(&"shell_roughness", 0.025)
	shell.set_shader_parameter(&"rim_emission", 0.34)
	shell.render_priority = 1
	return shell


func _build_body(gel: Material, shell: Material) -> void:
	match family_id:
		"M":
			_add_gel_sphere("Body", Vector3(0.0, 0.58, 0.0), Vector3(1.12, 1.14, 1.00), gel, shell)
			_add_gel_sphere("ArmL", Vector3(-0.59, 0.48, 0.0), Vector3(0.27, 0.31, 0.27), gel, shell)
			_add_gel_sphere("ArmR", Vector3(0.59, 0.48, 0.0), Vector3(0.27, 0.31, 0.27), gel, shell)
			_add_gel_sphere("FootL", Vector3(-0.28, 0.11, 0.06), Vector3(0.48, 0.32, 0.49), gel, shell)
			_add_gel_sphere("FootR", Vector3(0.28, 0.11, 0.06), Vector3(0.48, 0.32, 0.49), gel, shell)
		"A":
			# A is the only base cell without planted feet. Its Character root adds
			# the gameplay hover lift and routes mobile duty to RelayDish.
			_add_gel_sphere("Body", Vector3(0.0, 0.56, 0.0), Vector3(1.06, 1.08, 0.98), gel, shell)
			_add_gel_sphere("ArmL", Vector3(-0.56, 0.50, 0.0), Vector3(0.25, 0.29, 0.25), gel, shell)
			_add_gel_sphere("ArmR", Vector3(0.56, 0.50, 0.0), Vector3(0.25, 0.29, 0.25), gel, shell)
		"D":
			_add_gel_sphere("Body", Vector3(0.0, 0.53, 0.0), Vector3(1.04, 1.06, 0.96), gel, shell)
			_add_gel_sphere("ArmL", Vector3(-0.56, 0.46, 0.0), Vector3(0.25, 0.29, 0.25), gel, shell)
			_add_gel_sphere("ArmR", Vector3(0.56, 0.46, 0.0), Vector3(0.25, 0.29, 0.25), gel, shell)
			_add_gel_sphere("FootL", Vector3(-0.25, 0.09, 0.06), Vector3(0.43, 0.29, 0.44), gel, shell)
			_add_gel_sphere("FootR", Vector3(0.25, 0.09, 0.06), Vector3(0.43, 0.29, 0.44), gel, shell)
			_build_d_crown(gel, shell)
		_:
			_add_gel_sphere("Body", Vector3(0.0, 0.51, 0.0), Vector3(1.00, 1.02, 0.92), gel, shell)
			_add_gel_sphere("ArmL", Vector3(-0.53, 0.45, 0.0), Vector3(0.24, 0.28, 0.24), gel, shell)
			_add_gel_sphere("ArmR", Vector3(0.53, 0.45, 0.0), Vector3(0.24, 0.28, 0.24), gel, shell)
			_add_gel_sphere("FootL", Vector3(-0.24, 0.085, 0.06), Vector3(0.41, 0.28, 0.42), gel, shell)
			_add_gel_sphere("FootR", Vector3(0.24, 0.085, 0.06), Vector3(0.41, 0.28, 0.42), gel, shell)


func _build_d_crown(gel: Material, shell: Material) -> void:
	var crown := [
		[Vector3(-0.34, 0.99, -0.01), Vector3(0.24, 0.30, 0.23)],
		[Vector3(-0.17, 1.04, -0.01), Vector3(0.20, 0.26, 0.20)],
		[Vector3(0.0, 1.10, -0.01), Vector3(0.23, 0.34, 0.22)],
		[Vector3(0.17, 1.04, -0.01), Vector3(0.20, 0.26, 0.20)],
		[Vector3(0.34, 0.99, -0.01), Vector3(0.24, 0.30, 0.23)],
	]
	for index in crown.size():
		_add_gel_sphere("Crown%d" % index, crown[index][0], crown[index][1], gel, shell)


func _build_face(gel: Material, cavity_color: Color) -> void:
	var eye: Material
	if _GelProfiles.banner_match_enabled():
		var wet_eye := ShaderMaterial.new()
		wet_eye.shader = _EYE_SHADER
		eye = wet_eye
	else:
		var standard_eye := StandardMaterial3D.new()
		standard_eye.albedo_color = Color(0.004, 0.003, 0.006)
		standard_eye.roughness = 0.055
		standard_eye.metallic = 0.0
		eye = standard_eye
	var eye_x := 0.18 if family_id == "N" else 0.19
	var eye_y := 0.60 if family_id == "N" else (0.68 if family_id == "M" else (0.64 if family_id == "A" else 0.61))
	var eye_z := 0.420 if family_id == "N" else (0.475 if family_id == "M" else (0.445 if family_id == "A" else 0.435))
	_add_sphere("EyeL", Vector3(-eye_x, eye_y, eye_z), Vector3(0.155, 0.155, 0.105), eye, 64, 32)
	_add_sphere("EyeR", Vector3(eye_x, eye_y, eye_z), Vector3(0.155, 0.155, 0.105), eye, 64, 32)
	_add_face_ring("EyeRimL", Vector3(-eye_x, eye_y, eye_z + 0.047), 0.073, 0.087, gel)
	_add_face_ring("EyeRimR", Vector3(eye_x, eye_y, eye_z + 0.047), 0.073, 0.087, gel)

	var cavity := StandardMaterial3D.new()
	cavity.albedo_color = cavity_color
	cavity.roughness = 0.18
	if family_id == "N":
		# Two nested horizontal capsules produce the concept's short pill-shaped
		# mouth with a coloured gel lip instead of an O-mouth.
		_add_capsule("MouthRim", Vector3(0.0, 0.40, 0.443), 0.047, 0.19, Vector3(1.0, 1.0, 0.42), Vector3(0.0, 0.0, 90.0), gel)
		_add_capsule("MouthCavity", Vector3(0.0, 0.40, 0.466), 0.032, 0.15, Vector3(1.0, 1.0, 0.34), Vector3(0.0, 0.0, 90.0), cavity)
		return
	var mouth_y := 0.44 if family_id == "M" else (0.39 if family_id == "A" else 0.38)
	var mouth_z := 0.505 if family_id == "M" else (0.465 if family_id == "A" else 0.455)
	_add_sphere("MouthCavity", Vector3(0.0, mouth_y, mouth_z), Vector3(0.185, 0.205, 0.048), cavity, 64, 32)
	_add_face_ring("MouthRim", Vector3(0.0, mouth_y, mouth_z + 0.025), 0.092, 0.114, gel)


func _add_face_ring(name_: String, pos: Vector3, inner_radius: float, outer_radius: float, gel: Material) -> void:
	var ring := MeshInstance3D.new()
	ring.name = name_
	ring.mesh = _PrimitiveMeshes.torus(inner_radius, outer_radius, 48, 24)
	ring.position = pos
	ring.rotation_degrees.x = 90.0
	ring.material_override = gel.duplicate()
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)


func _add_capsule(
	name_: String,
	pos: Vector3,
	radius: float,
	height: float,
	scale_: Vector3,
	rotation_: Vector3,
	material: Material
) -> void:
	var instance := MeshInstance3D.new()
	instance.name = name_
	instance.mesh = _PrimitiveMeshes.capsule(radius, height, 48, 12)
	instance.position = pos
	instance.rotation_degrees = rotation_
	instance.scale = scale_
	instance.material_override = material.duplicate()
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func _add_gel_sphere(name_: String, pos: Vector3, scale_: Vector3, gel: Material, shell: Material) -> void:
	_add_sphere(name_, pos, scale_, gel.duplicate(), 96, 48)
	# Intersecting transparent shells produce dark contour seams where separate
	# primitive limbs meet. The opaque gel core already gives appendages their wet
	# rim; keep the explicit clear membrane on the main mass (and D crown lobes)
	# where it can read as one continuous outer envelope.
	if name_ == "Body" or name_.begins_with("Crown"):
		_add_sphere("%sShell" % name_, pos, scale_ * 1.006, shell.duplicate(), 96, 48)


func _add_sphere(
	name_: String,
	pos: Vector3,
	scale_: Vector3,
	material: Material,
	radial_segments: int,
	rings: int
) -> void:
	var instance := MeshInstance3D.new()
	instance.name = name_
	instance.mesh = _PrimitiveMeshes.sphere(radial_segments, rings)
	instance.position = pos
	instance.scale = scale_
	instance.material_override = material
	# The authored pieces overlap into one poured-gel mass. Disabling their
	# cosmetic self-shadows prevents hard wedges inside the clear membrane.
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
