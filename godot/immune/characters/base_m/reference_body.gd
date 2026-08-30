extends Node3D

## Approved CHAR-BASE-M authored jelly body.
##
## The production default is the user-approved `fizzy` treatment. The two retained
## look-development variants are command-line-only review aids and let the same
## body be compared through tools/shot.tscn with `--variant=clear|fizzy|gummy`.

const _Gel := preload("res://characters/gel/gel_look.gd")
const _GelProfiles := preload("res://characters/gel/gel_profiles.gd")
const _PrimitiveMeshes := preload("res://characters/primitive_mesh_cache.gd")
const _SHELL_SHADER := preload("res://characters/gel/jelly_shell.gdshader")

@export_enum("clear", "fizzy", "gummy") var material_variant := "fizzy"

const VARIANTS := {
	"clear": {
		&"body_color": Color(0.70, 0.53, 0.86, 1.0),
		&"deep_color": Color(0.36, 0.12, 0.59, 1.0),
		&"transmit_color": Color(0.90, 0.68, 0.96, 1.0),
		&"rim_color": Color(0.94, 0.78, 1.0, 1.0),
		&"albedo_gain": 0.95,
		&"body_roughness": 0.16,
		&"coat_roughness": 0.030,
		&"coat_strength": 1.8,
		&"spec_energy": 0.22,
		&"light_wrap": 0.24,
		&"sss_amount": 0.68,
		&"transmit_strength": 1.15,
		&"thin_glow": 0.46,
		&"rim_energy": 0.22,
		&"interior_budget": 0.16,
		&"rim_budget": 0.10,
		&"body_budget": 0.94,
		&"body_absorb": 0.68,
		&"extinction_density": 2.5,
		&"extinction_spread": 1.35,
		&"extinction_shape": 2.2,
		&"dimple_scale": 105.0,
		&"dimple_depth": 0.0,
		&"dimple_crease": 0.20,
		&"dimple_round": 0.92,
		&"bubble_enabled": true,
		&"bubble_scale": 8.0,
		&"bubble_density": 0.78,
		&"bubble_radius_min": 0.13,
		&"bubble_radius_max": 0.32,
		&"bubble_jitter": 0.16,
		&"bubble_softness": 0.075,
		&"bubble_depth": 0.004,
		&"bubble_thinness": 0.34,
		&"bubble_shell_shadow": 0.0,
		&"bubble_emission": 0.015,
		&"bubble_shell_emission": 0.30,
		&"bubble_seed": 47.0,
		&"microbubble_enabled": true,
		&"microbubble_scale": 30.0,
		&"microbubble_density": 0.86,
		&"microbubble_radius_min": 0.08,
		&"microbubble_radius_max": 0.24,
		&"microbubble_jitter": 0.17,
		&"microbubble_softness": 0.085,
		&"microbubble_depth": 0.004,
		&"microbubble_thinness": 0.18,
		&"microbubble_shell_shadow": 0.0,
		&"microbubble_emission": 0.020,
		&"microbubble_shell_emission": 0.24,
		&"microbubble_seed": 83.0,
		&"inclusion_enabled": true,
		&"inclusion_scale": 150.0,
		&"inclusion_threshold": 0.68,
		&"inclusion_softness": 0.055,
		&"inclusion_emission": 0.12,
		&"inclusion_seed": 107.0,
	},
	"fizzy": {
		&"body_color": Color(0.72, 0.55, 0.88, 1.0),
		&"deep_color": Color(0.39, 0.14, 0.63, 1.0),
		&"transmit_color": Color(0.92, 0.70, 0.98, 1.0),
		&"rim_color": Color(0.97, 0.84, 1.0, 1.0),
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
		&"bubble_seed": 59.0,
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
		&"microbubble_seed": 89.0,
		&"inclusion_enabled": true,
		&"inclusion_scale": 72.0,
		&"inclusion_depth": 0.005,
		&"inclusion_threshold": 0.76,
		&"inclusion_softness": 0.050,
		&"inclusion_emission": 0.035,
		&"inclusion_seed": 113.0,
	},
	"gummy": {
		&"body_color": Color(0.61, 0.53, 0.86, 1.0),
		&"deep_color": Color(0.34, 0.10, 0.57, 1.0),
		&"transmit_color": Color(0.86, 0.66, 1.0, 1.0),
		&"rim_color": Color(0.91, 0.70, 1.0, 1.0),
		&"albedo_gain": 0.86,
		&"body_roughness": 0.26,
		&"coat_roughness": 0.075,
		&"coat_strength": 1.35,
		&"spec_energy": 0.24,
		&"light_wrap": 0.34,
		&"sss_amount": 0.88,
		&"transmit_strength": 0.86,
		&"thin_glow": 0.32,
		&"rim_energy": 0.15,
		&"interior_budget": 0.14,
		&"rim_budget": 0.08,
		&"body_budget": 0.94,
		&"body_absorb": 0.62,
		&"extinction_density": 2.8,
		&"extinction_spread": 1.45,
		&"extinction_shape": 2.4,
		&"dimple_scale": 82.0,
		&"dimple_depth": 0.0,
		&"dimple_crease": 0.25,
		&"dimple_round": 0.85,
		&"bubble_enabled": true,
		&"bubble_scale": 8.0,
		&"bubble_density": 0.56,
		&"bubble_radius_min": 0.15,
		&"bubble_radius_max": 0.34,
		&"bubble_jitter": 0.15,
		&"bubble_softness": 0.10,
		&"bubble_depth": 0.003,
		&"bubble_thinness": 0.22,
		&"bubble_shell_shadow": 0.0,
		&"bubble_emission": 0.012,
		&"bubble_shell_emission": 0.22,
		&"bubble_seed": 71.0,
		&"microbubble_enabled": true,
		&"microbubble_scale": 25.0,
		&"microbubble_density": 0.68,
		&"microbubble_radius_min": 0.09,
		&"microbubble_radius_max": 0.22,
		&"microbubble_jitter": 0.16,
		&"microbubble_softness": 0.10,
		&"microbubble_depth": 0.003,
		&"microbubble_thinness": 0.12,
		&"microbubble_shell_shadow": 0.0,
		&"microbubble_emission": 0.014,
		&"microbubble_shell_emission": 0.17,
		&"microbubble_seed": 97.0,
		&"inclusion_enabled": true,
		&"inclusion_scale": 120.0,
		&"inclusion_threshold": 0.74,
		&"inclusion_softness": 0.065,
		&"inclusion_emission": 0.060,
		&"inclusion_seed": 127.0,
	},
}


func _ready() -> void:
	var variant := _variant()
	var material_options: Dictionary = VARIANTS[variant]
	if variant == "fizzy":
		material_options = _GelProfiles.with_v5_surface(material_options)
	var gel := _Gel.make_material(Color(0.62, 0.28, 0.92), material_options)
	if gel == null:
		push_error("m_reference_match.gd: failed to create gel material")
		return
	var shell := _make_shell(variant)
	_build_body(gel, shell)
	_build_face(gel)
	print("M_REFERENCE_MATCH variant=%s" % variant)


func _variant() -> String:
	for arg in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2 and pair[0] == "variant" and VARIANTS.has(pair[1]):
			return String(pair[1])
	return material_variant if VARIANTS.has(material_variant) else "fizzy"


func _build_body(gel: Material, shell: Material) -> void:
	# SphereMesh's authored radius is 0.5, so scale values are diameters. These
	# dimensions keep the appendages slightly intersecting the body like one poured
	# jelly mass instead of reading as floating pieces.
	_add_gel_sphere("Body", Vector3(0.0, 0.58, 0.0), Vector3(1.12, 1.14, 1.00), gel, shell)
	_add_gel_sphere("ArmL", Vector3(-0.59, 0.48, 0.00), Vector3(0.27, 0.31, 0.27), gel, shell)
	_add_gel_sphere("ArmR", Vector3(0.59, 0.48, 0.00), Vector3(0.27, 0.31, 0.27), gel, shell)
	_add_gel_sphere("FootL", Vector3(-0.28, 0.11, 0.06), Vector3(0.48, 0.32, 0.49), gel, shell)
	_add_gel_sphere("FootR", Vector3(0.28, 0.11, 0.06), Vector3(0.48, 0.32, 0.49), gel, shell)


func _make_shell(variant: String) -> ShaderMaterial:
	var shell := ShaderMaterial.new()
	shell.shader = _SHELL_SHADER
	_Gel.apply_v5_shell_bounds(shell)
	shell.set_shader_parameter(&"shell_color", Color(0.90, 0.74, 1.0, 1.0))
	shell.set_shader_parameter(&"face_alpha", 0.008 if variant != "gummy" else 0.004)
	shell.set_shader_parameter(&"edge_alpha", 0.48 if variant == "clear" else (0.46 if variant == "fizzy" else 0.38))
	shell.set_shader_parameter(&"edge_power", 2.4)
	shell.set_shader_parameter(&"shell_roughness", 0.025 if variant != "gummy" else 0.050)
	shell.set_shader_parameter(&"rim_emission", 0.34 if variant != "gummy" else 0.24)
	shell.render_priority = 1
	return shell


func _build_face(gel: Material) -> void:
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(0.004, 0.003, 0.008)
	eye.roughness = 0.055
	eye.metallic = 0.0
	_add_sphere("EyeL", Vector3(-0.19, 0.67, 0.455), Vector3(0.164, 0.164, 0.110), eye, 64, 32)
	_add_sphere("EyeR", Vector3(0.19, 0.67, 0.455), Vector3(0.164, 0.164, 0.110), eye, 64, 32)
	_add_face_ring("EyeRimL", Vector3(-0.19, 0.67, 0.505), 0.078, 0.092, gel)
	_add_face_ring("EyeRimR", Vector3(0.19, 0.67, 0.505), 0.078, 0.092, gel)

	var cavity := StandardMaterial3D.new()
	cavity.albedo_color = Color(0.17, 0.025, 0.29)
	cavity.roughness = 0.20
	_add_sphere("MouthCavity", Vector3(0.0, 0.43, 0.480), Vector3(0.210, 0.240, 0.050), cavity, 64, 32)

	_add_face_ring("MouthRim", Vector3(0.0, 0.43, 0.505), 0.105, 0.128, gel)


func _add_face_ring(
	name_: String,
	pos: Vector3,
	inner_radius: float,
	outer_radius: float,
	gel: Material
) -> void:
	var ring := MeshInstance3D.new()
	ring.name = name_
	ring.mesh = _PrimitiveMeshes.torus(inner_radius, outer_radius, 48, 24)
	ring.position = pos
	ring.rotation_degrees.x = 90.0
	ring.material_override = gel.duplicate()
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)


func _add_gel_sphere(
	name_: String,
	pos: Vector3,
	scale_: Vector3,
	gel: Material,
	shell: Material
) -> void:
	_add_sphere(name_, pos, scale_, gel.duplicate(), 96, 48)
	_add_sphere(
		"%sShell" % name_,
		pos,
		scale_ * 1.006,
		shell.duplicate(),
		96,
		48)


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
	# The primitives represent one fused poured-gel body. Directional self-shadows
	# between overlapping pieces create hard wedges that cannot exist inside a
	# translucent mass, especially around the inset eyes and feet.
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
