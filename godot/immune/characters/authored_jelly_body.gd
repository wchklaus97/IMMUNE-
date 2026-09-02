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
const _SingleMassBlob := preload("res://characters/single_mass_blob_mesh.gd")
const _SHELL_SHADER := preload("res://characters/gel/jelly_shell.gdshader")
const _EYE_SHADER := preload("res://characters/gel/gel_eye.gdshader")
const _T_V8_4_SINGLE_MASS_PATH := (
	"res://characters/base_t/CHAR-BASE-T-v8-4-single-mass-r1.glb"
)
const _T_V8_5_SINGLE_MASS_PATH := (
	"res://characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb"
)
const _T_V8_5_SINGLE_MASS_SHA256 := (
	"8f14cfe59a508df413e4d53218f30bbf316e7e5d31e42154b2916a0bd5669294"
)

static var _t_v8_4_mesh_cache: ArrayMesh
static var _t_v8_5_mesh_cache: ArrayMesh

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
	var shell := _make_shell(profile[&"shell_color"], options)
	if not _build_body(gel, shell):
		# Fail the complete presentation node closed. In particular, a gated V8.5
		# asset failure must never continue into floating eyes, mouth, or pore marks.
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		set_meta(&"authored_body_build_failed", true)
		return
	_build_face(gel, profile[&"cavity_color"])
	if _GelProfiles.reference_viscosity_enabled():
		_configure_v8_4_material_coherence(gel)
	print("AUTHORED_JELLY_BODY family=%s profile=fizzy-zero-credit" % family_id)


func _make_shell(shell_color: Color, options: Dictionary) -> ShaderMaterial:
	var shell := ShaderMaterial.new()
	shell.shader = _SHELL_SHADER
	_Gel.apply_v5_shell_bounds(shell)
	shell.set_shader_parameter(&"shell_color", shell_color)
	if _GelProfiles.living_volume_enabled():
		# V8.2 keeps the production topology at one explicit Body membrane. These
		# family/profile values sharpen the dielectric edge while lowering face
		# alpha enough for the moving optical core to remain legible underneath.
		shell.set_shader_parameter(
			&"face_alpha", options.get(&"membrane_face_alpha", 0.0028))
		shell.set_shader_parameter(
			&"edge_alpha", options.get(&"membrane_edge_alpha", 0.58))
		shell.set_shader_parameter(
			&"edge_power", options.get(&"membrane_edge_power", 2.20))
		shell.set_shader_parameter(
			&"shell_roughness", options.get(&"membrane_roughness", 0.014))
		shell.set_shader_parameter(
			&"rim_emission", options.get(&"membrane_rim_emission", 0.36))
		shell.set_shader_parameter(
			&"shell_thickness", options.get(&"membrane_thickness", 0.020))
	elif _GelProfiles.gummy_glass_enabled():
		shell.set_shader_parameter(&"face_alpha", 0.003)
		shell.set_shader_parameter(&"edge_alpha", 0.55)
		shell.set_shader_parameter(&"edge_power", 1.95)
		shell.set_shader_parameter(&"shell_roughness", 0.016)
		shell.set_shader_parameter(&"rim_emission", 0.40)
	else:
		shell.set_shader_parameter(&"face_alpha", 0.008)
		shell.set_shader_parameter(&"edge_alpha", 0.46)
		shell.set_shader_parameter(&"edge_power", 2.4)
		shell.set_shader_parameter(&"shell_roughness", 0.025)
		shell.set_shader_parameter(&"rim_emission", 0.34)
	shell.render_priority = 1
	return shell


func _build_body(gel: Material, shell: Material) -> bool:
	if _GelProfiles.single_mass_enabled():
		return _build_single_mass_body(gel, shell)
	if _GelProfiles.gummy_glass_enabled():
		_build_v7_body(gel, shell)
		return true
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
	return true


func _build_v7_body(gel: Material, shell: Material) -> void:
	# V7 is a separate silhouette branch. The preserved V5/V6 body values above
	# remain untouched and are selected again with IMMUNE_GEL_LOOK=v5/v6.
	match family_id:
		"M":
			_add_gel_sphere("Body", Vector3(0.0, 0.56, 0.0), Vector3(1.18, 1.10, 1.08), gel, shell)
			_add_gel_sphere("ArmL", Vector3(-0.60, 0.47, 0.0), Vector3(0.26, 0.30, 0.25), gel, shell)
			_add_gel_sphere("ArmR", Vector3(0.60, 0.47, 0.0), Vector3(0.26, 0.30, 0.25), gel, shell)
			_add_gel_sphere("FootL", Vector3(-0.30, 0.10, 0.07), Vector3(0.47, 0.30, 0.46), gel, shell)
			_add_gel_sphere("FootR", Vector3(0.30, 0.10, 0.07), Vector3(0.47, 0.30, 0.46), gel, shell)
		"A":
			_add_gel_sphere("Body", Vector3(0.0, 0.53, 0.0), Vector3(1.10, 1.02, 1.01), gel, shell)
			_add_gel_sphere("ArmL", Vector3(-0.55, 0.47, 0.0), Vector3(0.23, 0.27, 0.23), gel, shell)
			_add_gel_sphere("ArmR", Vector3(0.55, 0.47, 0.0), Vector3(0.23, 0.27, 0.23), gel, shell)
			# The banner gives A two small lower lobes. They remain cosmetic and do
			# not change A's hover movement, collision, or Relay duty.
			_add_gel_sphere("FootL", Vector3(-0.24, 0.085, 0.06), Vector3(0.33, 0.21, 0.32), gel, shell)
			_add_gel_sphere("FootR", Vector3(0.24, 0.085, 0.06), Vector3(0.33, 0.21, 0.32), gel, shell)
		"D":
			_add_gel_sphere("Body", Vector3(0.0, 0.51, 0.0), Vector3(1.08, 1.01, 1.00), gel, shell)
			_add_gel_sphere("ArmL", Vector3(-0.54, 0.44, 0.0), Vector3(0.23, 0.27, 0.23), gel, shell)
			_add_gel_sphere("ArmR", Vector3(0.54, 0.44, 0.0), Vector3(0.23, 0.27, 0.23), gel, shell)
			_add_gel_sphere("FootL", Vector3(-0.26, 0.085, 0.06), Vector3(0.42, 0.27, 0.42), gel, shell)
			_add_gel_sphere("FootR", Vector3(0.26, 0.085, 0.06), Vector3(0.42, 0.27, 0.42), gel, shell)
			_build_d_crown(gel, shell)
		_:
			_add_gel_sphere("Body", Vector3(0.0, 0.50, 0.0), Vector3(1.07, 1.00, 1.00), gel, shell)
			_add_gel_sphere("ArmL", Vector3(-0.53, 0.43, 0.0), Vector3(0.23, 0.27, 0.23), gel, shell)
			_add_gel_sphere("ArmR", Vector3(0.53, 0.43, 0.0), Vector3(0.23, 0.27, 0.23), gel, shell)
			_add_gel_sphere("FootL", Vector3(-0.25, 0.080, 0.06), Vector3(0.41, 0.27, 0.41), gel, shell)
			_add_gel_sphere("FootR", Vector3(0.25, 0.080, 0.06), Vector3(0.41, 0.27, 0.41), gel, shell)


func _build_single_mass_body(gel: Material, shell: Material) -> bool:
	# One indexed watertight surface owns the full silhouette. Arms, lower lobes,
	# and D's top ridge are sculpted into this mesh; no free-standing gel pieces
	# exist for animation to expose or separate.
	var revision := (
		"v8_5" if _GelProfiles.v8_5_enabled()
		else ("v8_4" if _GelProfiles.v8_4_enabled() else "v8_3")
	)
	var body_mesh: ArrayMesh
	var body_position := Vector3.ZERO
	if revision == "v8_5" and family_id == "T":
		var authored_mesh := _v8_5_t_single_mass_mesh()
		if authored_mesh == null:
			# Exact V8.5 fails closed. Presenting a procedural fallback under the
			# accepted sculpt selector would make topology/rights evidence dishonest.
			push_error("authored_jelly_body.gd: exact V8.5 T sculpt failed to load")
			return false
		body_mesh = authored_mesh
	else:
		body_mesh = _SingleMassBlob.mesh(family_id, revision)
		body_position = _SingleMassBlob.centre(family_id, revision)
		if revision == "v8_4" and family_id == "T":
			var reference_mesh := _v8_4_t_single_mass_mesh()
			if reference_mesh != null:
				body_mesh = reference_mesh
				body_position = Vector3.ZERO
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = body_mesh
	body.position = body_position
	body.material_override = gel.duplicate()
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.set_meta(StringName("%s_single_mass" % revision), true)
	if revision == "v8_5" and family_id == "T":
		# This marker is set only after source SHA and imported-mesh validation.
		body.set_meta(&"v8_5_authored_sculpt", true)
	if revision == "v8_4" and family_id == "T":
		body.set_meta(&"v8_4_reference_remesh", body_mesh == _t_v8_4_mesh_cache)
	add_child(body)

	var membrane := MeshInstance3D.new()
	membrane.name = "BodyShell"
	membrane.mesh = body_mesh
	membrane.position = body_position
	membrane.scale = Vector3.ONE * 1.006
	membrane.material_override = shell.duplicate()
	membrane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	membrane.set_meta(StringName("%s_single_mass_shell" % revision), true)
	add_child(membrane)
	return true


func _v8_5_t_single_mass_mesh() -> ArrayMesh:
	if _t_v8_5_mesh_cache != null:
		return _t_v8_5_mesh_cache
	var source_error := _v8_5_t_source_contract_error(
		_T_V8_5_SINGLE_MASS_PATH,
		_T_V8_5_SINGLE_MASS_SHA256
	)
	if not source_error.is_empty():
		push_error("authored_jelly_body.gd: %s" % source_error)
		return null
	var packed := load(_T_V8_5_SINGLE_MASS_PATH) as PackedScene
	if packed == null:
		push_error("authored_jelly_body.gd: V8.5 T sculpt did not import as PackedScene")
		return null
	var source := packed.instantiate()
	if source == null:
		push_error("authored_jelly_body.gd: V8.5 T sculpt PackedScene failed to instantiate")
		return null
	var mesh_count := _array_mesh_instance_count(source)
	if mesh_count != 1:
		source.free()
		push_error(
			"authored_jelly_body.gd: V8.5 T sculpt must contain exactly one ArrayMesh; got %d"
			% mesh_count
		)
		return null
	var mesh_instance := _first_array_mesh(source)
	if mesh_instance == null:
		source.free()
		push_error("authored_jelly_body.gd: V8.5 T sculpt has no ArrayMesh")
		return null
	var candidate := mesh_instance.mesh as ArrayMesh
	var mesh_error := _v8_5_t_mesh_contract_error(candidate)
	if not mesh_error.is_empty():
		source.free()
		push_error("authored_jelly_body.gd: %s" % mesh_error)
		return null
	_t_v8_5_mesh_cache = candidate
	_t_v8_5_mesh_cache.resource_name = "V8.5-AuthoredSculpt-T-r4"
	source.free()
	return _t_v8_5_mesh_cache


func _v8_5_t_source_contract_error(path: String, expected_sha256: String) -> String:
	if not ResourceLoader.exists(path):
		return "V8.5 project-authored T sculpt is unavailable; the selector will not fall back"
	var actual_sha256 := FileAccess.get_sha256(path)
	if actual_sha256 != expected_sha256:
		return "V8.5 T sculpt SHA-256 drifted: %s" % actual_sha256
	return ""


func _v8_5_t_mesh_contract_error(mesh: ArrayMesh) -> String:
	if mesh == null:
		return "V8.5 T sculpt did not provide an ArrayMesh"
	if mesh.get_surface_count() != 1:
		return "V8.5 T sculpt must contain exactly one surface"
	if mesh.surface_get_primitive_type(0) != Mesh.PRIMITIVE_TRIANGLES:
		return "V8.5 T sculpt surface must use indexed triangles"
	# The immutable source-file SHA proves the GLB has no material payload. Godot's
	# scene importer may still attach its own default StandardMaterial3D to the
	# imported surface, so that derived runtime value is intentionally ignored.
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if vertices.size() != 6002 or normals.size() != 6002 or indices.size() != 36000:
		return "V8.5 T sculpt topology drifted (%d vertices, %d normals, %d indices)" % [
			vertices.size(), normals.size(), indices.size(),
		]
	var bounds := mesh.get_aabb()
	if (
		not bounds.position.is_equal_approx(Vector3(-0.75, 0.0, -0.50))
		or not bounds.size.is_equal_approx(Vector3(1.50, 1.46, 1.00))
	):
		return "V8.5 T sculpt bounds drifted: %s" % bounds
	return ""


func _v8_4_t_single_mass_mesh() -> ArrayMesh:
	if _t_v8_4_mesh_cache != null:
		return _t_v8_4_mesh_cache
	# This development derivative is intentionally excluded from commercial
	# presets until its inherited source rights are documented. Runtime loading
	# keeps the default V8.3 export independent from the optional review asset.
	if not ResourceLoader.exists(_T_V8_4_SINGLE_MASS_PATH):
		push_error(
			"authored_jelly_body.gd: V8.4 T review mesh is unavailable; "
			+ "see characters/base_t/ASSET_PROVENANCE.md"
		)
		return null
	var packed := load(_T_V8_4_SINGLE_MASS_PATH) as PackedScene
	if packed == null:
		push_error("authored_jelly_body.gd: V8.4 T review mesh did not import as PackedScene")
		return null
	var source := packed.instantiate()
	var mesh_instance := _first_array_mesh(source)
	if mesh_instance == null:
		source.free()
		push_error("authored_jelly_body.gd: V8.4 T single-mass asset has no ArrayMesh")
		return null
	_t_v8_4_mesh_cache = mesh_instance.mesh as ArrayMesh
	_t_v8_4_mesh_cache.resource_name = "V8.4-SingleMass-T"
	source.free()
	return _t_v8_4_mesh_cache


static func _first_array_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh is ArrayMesh:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _first_array_mesh(child)
		if found != null:
			return found
	return null


static func _array_mesh_instance_count(node: Node) -> int:
	var count := 1 if node is MeshInstance3D and (node as MeshInstance3D).mesh is ArrayMesh else 0
	for child in node.get_children():
		count += _array_mesh_instance_count(child)
	return count


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
		wet_eye.set_shader_parameter(
			&"face_visibility_gate", 1.0 if _GelProfiles.reference_viscosity_enabled() else 0.0
		)
		if _GelProfiles.reference_viscosity_enabled():
			wet_eye.set_shader_parameter(&"studio_strength", 0.42)
			wet_eye.set_shader_parameter(&"studio_budget", 0.65)
			wet_eye.set_shader_parameter(&"surface_roughness", 0.035)
			wet_eye.set_shader_parameter(&"main_card_center", Vector2(-0.22, 0.28))
			wet_eye.set_shader_parameter(&"main_card_shape", Vector2(8.0, 13.0))
			wet_eye.set_shader_parameter(&"pin_card_center", Vector2(0.30, 0.42))
			wet_eye.set_shader_parameter(&"pin_card_shape", Vector2(42.0, 42.0))
			wet_eye.set_shader_parameter(&"eye_catchlight_strength", 0.90)
			wet_eye.set_shader_parameter(&"eye_catchlight_center", Vector2(-0.32, 0.32))
			wet_eye.set_shader_parameter(&"eye_catchlight_shape", Vector2(38.0, 48.0))
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
	if _GelProfiles.gummy_glass_enabled():
		eye_x = 0.20 if family_id != "M" else 0.215
		eye_y = 0.61 if family_id == "N" else (0.68 if family_id == "M" else (0.63 if family_id == "A" else 0.60))
		eye_z = 0.475 if family_id == "N" else (0.515 if family_id == "M" else (0.490 if family_id == "A" else 0.480))
	var eye_scale := Vector3(0.155, 0.155, 0.105)
	if _GelProfiles.single_mass_enabled():
		# Embed smaller marks into the continuous skin. The former protruding eye
		# spheres could escape the silhouette at 3/4 view and read as loose cells.
		# The R6 inset keeps their front face only a thin mark above the membrane.
		eye_x = 0.175 if family_id == "M" else 0.165
		eye_z = (
			0.475 if family_id == "M"
			else (0.445 if family_id == "A" else (0.442 if family_id == "N" else 0.438))
		)
		eye_scale = Vector3(0.132, 0.132, 0.040)
	if _GelProfiles.reference_viscosity_enabled():
		# Match the reference's wide, low black lenses. Keeping their depth shallow
		# plus the camera-facing fragment gate makes these larger marks feel inset
		# without letting either eye escape the silhouette at a three-quarter view.
		eye_x = 0.190 if family_id == "T" else (0.235 if family_id == "M" else 0.210)
		eye_y = {
			"T": 0.680,
			"B": 0.695,
			"M": 0.755,
			"N": 0.700,
			"A": 0.715,
			"D": 0.715,
		}.get(family_id, 0.700)
		eye_z = {
			"T": 0.445,
			"B": 0.417,
			"M": 0.450,
			"N": 0.412,
			"A": 0.417,
			"D": 0.421,
		}.get(family_id, 0.412)
		eye_scale = (
			Vector3(0.182, 0.118, 0.018)
			if family_id == "T"
			else (Vector3(0.210, 0.124, 0.020) if family_id == "M" else Vector3(0.198, 0.120, 0.020))
		)
		if _GelProfiles.v8_5_enabled() and family_id == "T":
			# The authored r4 sculpt is taller than V8.4 and contains measured shallow
			# sockets. Seat the presentation lenses in those sockets instead of reusing
			# the old body's world-space marks.
			eye_x = 0.218
			eye_y = 0.835
			eye_z = 0.452
			eye_scale = Vector3(0.190, 0.122, 0.016)
	if _GelProfiles.motion_truth_enabled():
		# Body-space origin/scale are per material instance. Keep one instance per
		# eye so the right eye can never inherit the left eye's deformation frame.
		_add_sphere(
			"EyeL", Vector3(-eye_x, eye_y, eye_z), eye_scale,
			eye.duplicate() as Material, 64, 32
		)
		_add_sphere(
			"EyeR", Vector3(eye_x, eye_y, eye_z), eye_scale,
			eye.duplicate() as Material, 64, 32
		)
	else:
		_add_sphere("EyeL", Vector3(-eye_x, eye_y, eye_z), eye_scale, eye, 64, 32)
		_add_sphere("EyeR", Vector3(eye_x, eye_y, eye_z), eye_scale, eye, 64, 32)
	if _GelProfiles.reference_viscosity_enabled():
		var eye_angle := 30.0 if _GelProfiles.v8_5_enabled() and family_id == "T" else 36.0
		(get_node("EyeL") as Node3D).rotation_degrees.z = -eye_angle
		(get_node("EyeR") as Node3D).rotation_degrees.z = eye_angle
	if not _GelProfiles.gummy_glass_enabled():
		_add_face_ring("EyeRimL", Vector3(-eye_x, eye_y, eye_z + 0.047), 0.073, 0.087, gel)
		_add_face_ring("EyeRimR", Vector3(eye_x, eye_y, eye_z + 0.047), 0.073, 0.087, gel)

	var cavity: Material
	if _GelProfiles.motion_truth_enabled():
		# V8.1+ treats the mouth interior as part of the same viscous visual mass.
		# The shared eye shader keeps it deformable without adding a new material
		# path; zero studio strength preserves the authored dark cavity read.
		var wet_cavity := ShaderMaterial.new()
		wet_cavity.shader = _EYE_SHADER
		wet_cavity.set_shader_parameter(
			&"eye_color",
			Color(0.004, 0.002, 0.003, 1.0)
			if _GelProfiles.reference_viscosity_enabled()
			else (cavity_color.darkened(0.42) if _GelProfiles.single_mass_enabled() else cavity_color)
		)
		wet_cavity.set_shader_parameter(&"studio_strength", 0.0)
		wet_cavity.set_shader_parameter(&"surface_roughness", 0.18)
		wet_cavity.set_shader_parameter(
			&"face_visibility_gate", 1.0 if _GelProfiles.reference_viscosity_enabled() else 0.0
		)
		cavity = wet_cavity
	else:
		var standard_cavity := StandardMaterial3D.new()
		standard_cavity.albedo_color = cavity_color
		standard_cavity.roughness = 0.18
		cavity = standard_cavity
	if _GelProfiles.reference_viscosity_enabled():
		# V8.4+ places every facial mark from the same measured reference ratios.
		# The T pore is an inset, camera-gated mark plus a wet torus bonded to the
		# body; it is never a free cell, particle, or independently animated mass.
		if family_id == "T":
			var pore_rim := ShaderMaterial.new()
			pore_rim.shader = _EYE_SHADER
			pore_rim.set_shader_parameter(
				&"eye_color", (gel as ShaderMaterial).get_shader_parameter(&"body_color")
			)
			pore_rim.set_shader_parameter(&"studio_strength", 0.18)
			pore_rim.set_shader_parameter(&"studio_budget", 0.22)
			pore_rim.set_shader_parameter(&"surface_roughness", 0.08)
			# The V8.5 torus is already depth-occluded by the opaque authored body.
			# Discarding it by each torus vertex normal cuts the front ring in half.
			pore_rim.set_shader_parameter(
				&"face_visibility_gate", 0.0 if _GelProfiles.v8_5_enabled() else 1.0
			)
			var pore_y := 1.050 if _GelProfiles.v8_5_enabled() else 0.800
			var pore_z := 0.452 if _GelProfiles.v8_5_enabled() else 0.436
			_add_face_ring(
				"ForeheadPoreRim", Vector3(0.0, pore_y, pore_z),
				0.036, 0.060, pore_rim
			)
			_add_sphere(
				"ForeheadPore", Vector3(0.0, pore_y, pore_z - 0.006),
				Vector3(0.058, 0.058, 0.010), cavity.duplicate(), 64, 32
			)
		var mouth_y_v8_4: float = {
			"T": 0.600,
			"B": 0.595,
			"M": 0.685,
			"N": 0.600,
			"A": 0.655,
			"D": 0.655,
		}.get(family_id, 0.600)
		var mouth_z_v8_4: float = {
			"T": 0.455,
			"B": 0.430,
			"M": 0.462,
			"N": 0.425,
			"A": 0.430,
			"D": 0.434,
		}.get(family_id, 0.425)
		if _GelProfiles.v8_5_enabled() and family_id == "T":
			mouth_y_v8_4 = 0.625
			mouth_z_v8_4 = 0.462
		_add_sphere(
			"MouthCavity", Vector3(0.0, mouth_y_v8_4, mouth_z_v8_4),
			Vector3(0.060, 0.014, 0.010), cavity.duplicate(), 64, 32
		)
		return
	if family_id == "N":
		# Two nested horizontal capsules produce the concept's short pill-shaped
		# mouth with a coloured gel lip instead of an O-mouth.
		var n_mouth_z := 0.508 if _GelProfiles.gummy_glass_enabled() else 0.443
		var n_cavity_z := 0.492 if _GelProfiles.single_mass_enabled() else (0.532 if _GelProfiles.gummy_glass_enabled() else 0.466)
		if not _GelProfiles.single_mass_enabled():
			_add_capsule("MouthRim", Vector3(0.0, 0.40, n_mouth_z), 0.047, 0.19, Vector3(1.0, 1.0, 0.42), Vector3(0.0, 0.0, 90.0), gel)
		_add_capsule("MouthCavity", Vector3(0.0, 0.40, n_cavity_z), 0.032, 0.15, Vector3(1.0, 1.0, 0.34), Vector3(0.0, 0.0, 90.0), cavity)
		return
	var mouth_y := 0.44 if family_id == "M" else (0.39 if family_id == "A" else 0.38)
	var mouth_z := 0.505 if family_id == "M" else (0.465 if family_id == "A" else 0.455)
	if _GelProfiles.gummy_glass_enabled():
		mouth_y = 0.43 if family_id == "M" else (0.37 if family_id == "A" else 0.365)
		mouth_z = 0.545 if family_id == "M" else (0.515 if family_id == "A" else 0.505)
	var mouth_scale := Vector3(0.185, 0.205, 0.048)
	if _GelProfiles.single_mass_enabled():
		mouth_z = 0.515 if family_id == "M" else (0.480 if family_id == "A" else 0.480)
		mouth_scale = Vector3(0.170, 0.190, 0.026)
	if _GelProfiles.reference_viscosity_enabled():
		mouth_y -= 0.010
		mouth_scale = Vector3(0.080, 0.026, 0.012)
	_add_sphere("MouthCavity", Vector3(0.0, mouth_y, mouth_z), mouth_scale, cavity, 64, 32)
	var mouth_inner := 0.102 if _GelProfiles.gummy_glass_enabled() else 0.092
	if not _GelProfiles.single_mass_enabled():
		_add_face_ring("MouthRim", Vector3(0.0, mouth_y, mouth_z + 0.025), mouth_inner, 0.114, gel)


func _configure_v8_4_material_coherence(source_gel: ShaderMaterial) -> void:
	# Standalone look-dev scenes do not own CharacterRoot's runtime material cache.
	# Configure the same authored-root coordinate here so the membrane and shallow
	# face marks follow the core's TIME-driven wobble in previews as well as gameplay.
	for child in get_children():
		var mesh := child as MeshInstance3D
		if mesh == null:
			continue
		var material := mesh.material_override as ShaderMaterial
		if material == null or material.shader == null:
			continue
		for parameter in [
			&"liquid_wobble_strength",
			&"liquid_wobble_speed",
			&"liquid_wobble_scale",
			&"liquid_wobble_phase",
			&"liquid_wobble_normal_follow",
		]:
			material.set_shader_parameter(parameter, source_gel.get_shader_parameter(parameter))
		var relative := global_transform.affine_inverse() * mesh.global_transform
		var part_scale := relative.basis.get_scale().abs()
		part_scale.x = maxf(part_scale.x, 0.0001)
		part_scale.y = maxf(part_scale.y, 0.0001)
		part_scale.z = maxf(part_scale.z, 0.0001)
		material.set_shader_parameter(&"liquid_body_space_enabled", 1.0)
		material.set_shader_parameter(&"liquid_part_origin", relative.origin)
		material.set_shader_parameter(&"liquid_part_basis", relative.basis.orthonormalized())
		material.set_shader_parameter(&"liquid_part_scale", part_scale)


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
