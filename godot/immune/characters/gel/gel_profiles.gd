class_name ImmuneGelProfiles
extends RefCounted

## Family-level tuning for the shared wet-gel shader.
##
## Profiles live here instead of inside character_root.gd so imported meshes,
## procedural duty pieces, previews, combat instances, and tests all receive the
## same material contract. Call-site overrides always win.

const BASE: Dictionary = {
	&"bubble_enabled": false,
	&"bubble_scale": 5.0,
	&"bubble_density": 0.5,
	&"bubble_radius_min": 0.17,
	&"bubble_radius_max": 0.32,
	&"bubble_jitter": 0.16,
	&"bubble_softness": 0.08,
	&"bubble_depth": 0.0,
	&"bubble_thinness": 0.0,
	&"bubble_shell_shadow": 0.0,
	&"bubble_emission": 0.0,
	&"bubble_seed": 0.0,
}

# Jelly V5 surface controls are merged into every family after legacy/profile
# values and before explicit call-site overrides. M/N/A/D production builders
# call with_v5_surface() as well, so their locally-authored colour/silhouette
# dictionaries cannot accidentally retain the V4 crystalline membrane response.
const V5_SURFACE: Dictionary = {
	# V5.3 keeps the measured per-light ceiling but raises the light-independent
	# interior enough for gameplay scale. The former profile only became readable
	# under the three-light look-dev rig and read as dark hard plastic in combat.
	&"body_exposure_scale": 0.90,
	&"direct_light_budget_share": 0.10,
	# Compatibility adds EMISSION only in the base colour pass for this opaque
	# material, so this bounded hue-preserving fill is not multiplied by shadowed
	# additive lights. This slight V5.1 lift restores the reference's readable core;
	# the zero-light probe below guards it from becoming a self-lit lantern.
	&"core_glow": 0.44,
	&"interior_budget": 0.60,
	&"thin_budget_scale": 0.84,
	&"thickness_contrast": 0.11,
	&"thickness_power": 1.15,
	&"thin_bias": 2.7,
	&"glow_power": 2.0,
	&"curv_low": 18.0,
	&"curv_high": 48.0,
	&"thin_curvature": 0.06,
	&"transmit_strength": 1.02,
	&"thin_glow": 0.36,
	&"rim_energy": 0.075,
	&"rim_budget": 0.045,
	&"coat_roughness": 0.045,
	&"coat_strength": 1.35,
	&"spec_energy": 0.18,
	&"membrane_depth_cap": 0.014,
	&"membrane_grazing_floor": 0.10,
	&"membrane_grazing_power": 1.35,
	&"membrane_irregularity": 0.72,
	&"wet_spec_breakup": 0.08,
	&"coat_tint": 0.10,
	&"detail_emission_scale": 0.08,
	# V5.1 replaces the procedural sphere/island normals with one deterministic,
	# mipmapped height source. The former fields produced circular stamps, closed
	# contour rings, and half-degree yaw shimmer in the rejected look-dev sweep.
	&"authored_height_enabled": true,
	# The CC0 orange-peel control is deliberately enlarged and shallow. Combined
	# with grazing weighting in the shader, it keeps the face-on core calm while
	# retaining compact wet pebbles on turning edges and thin limbs.
	&"authored_height_scale": 0.45,
	&"authored_height_depth": 0.0015,
	&"authored_height_blend": 2.0,
	&"authored_height_lod_bias": 0.35,
	&"bubble_depth": 0.0,
	&"bubble_emission": 0.0,
	&"bubble_shell_emission": 0.0,
	&"microbubble_enabled": false,
	&"microbubble_scale": 42.0,
	&"microbubble_density": 0.68,
	&"microbubble_radius_min": 0.18,
	&"microbubble_radius_max": 0.48,
	&"microbubble_jitter": 0.18,
	&"microbubble_softness": 0.10,
	&"microbubble_depth": 0.0,
	&"microbubble_thinness": 0.0,
	&"microbubble_shell_shadow": 0.0,
	&"microbubble_emission": 0.0,
	&"microbubble_shell_emission": 0.0,
	&"inclusion_enabled": false,
	&"inclusion_scale": 64.0,
	&"inclusion_depth": 0.0,
	&"inclusion_threshold": 0.74,
	&"inclusion_softness": 0.060,
	&"inclusion_emission": 0.0,
}

# Banner-match production profile. The project selects it by default after the
# six-family, mission-preview, combat-portrait, motion, and performance gates.
# IMMUNE_GEL_LOOK=v5 remains a reversible A/B control for regression diagnosis.
#
# V6 does not bring back the rejected procedural bubble/island normals. Its visual
# change comes from a darker optical core, a broader transmitted edge, a clearer
# dielectric membrane, and bounded analytic studio reflections in wet_gel.gdshader.
const V6_BANNER_MATCH: Dictionary = {
	&"albedo_gain": 0.84,
	&"body_exposure_scale": 0.82,
	&"body_roughness": 0.26,
	&"direct_light_budget_share": 0.10,
	&"core_glow": 0.22,
	&"interior_budget": 0.38,
	&"thin_budget_scale": 0.82,
	&"thickness_contrast": 0.24,
	&"thickness_power": 0.90,
	&"body_absorb": 0.99,
	&"light_wrap": 0.13,
	&"sss_amount": 0.62,
	&"thin_power": 1.15,
	&"thin_fresnel": 1.0,
	&"thin_floor": 0.04,
	&"transmit_strength": 1.42,
	&"transmit_tint": 0.34,
	&"thin_glow": 0.58,
	&"thin_bias": 1.90,
	&"glow_power": 1.15,
	&"rim_power": 6.0,
	&"rim_energy": 0.18,
	&"rim_budget": 0.10,
	&"coat_roughness": 0.038,
	&"coat_strength": 1.52,
	&"spec_energy": 0.24,
	&"wet_spec_breakup": 0.065,
	&"coat_tint": 0.06,
	&"detail_emission_scale": 0.28,
	&"bubble_enabled": true,
	&"bubble_depth": 0.0,
	&"bubble_thinness": 0.0,
	&"bubble_shell_shadow": 0.0,
	&"bubble_emission": 0.0,
	&"bubble_shell_emission": 0.0,
	&"authored_fleck_strength": 0.56,
	&"authored_fleck_threshold": 0.31,
	&"authored_fleck_softness": 0.012,
	&"authored_fleck_budget": 0.14,
	&"authored_inclusion_strength": 0.34,
	&"authored_inclusion_scale": 0.13,
	&"authored_inclusion_threshold": 0.23,
	&"authored_inclusion_softness": 0.015,
	&"authored_inclusion_thinness": 0.08,
	&"authored_inclusion_budget": 0.085,
	&"authored_inclusion_lod_bias": 0.18,
	&"authored_caustic_strength": 0.58,
	&"authored_caustic_threshold": 0.255,
	&"authored_caustic_width": 0.020,
	&"authored_caustic_budget": 0.095,
	&"studio_reflection_strength": 0.66,
	&"studio_reflection_budget": 0.28,
	&"studio_reflection_edge_share": 0.62,
	&"studio_key_color": Color(0.90, 0.97, 1.0, 1.0),
	&"studio_cool_color": Color(0.24, 0.48, 1.0, 1.0),
	&"studio_warm_color": Color(1.0, 0.28, 0.16, 1.0),
	&"membrane_face_alpha": 0.006,
	&"membrane_edge_alpha": 0.58,
	&"membrane_edge_power": 2.05,
	&"membrane_roughness": 0.020,
	&"membrane_rim_emission": 0.38,
	&"membrane_thickness": 0.018,
}

const V6_FAMILY: Dictionary = {
	"T": {
		&"body_color": Color(0.92, 0.20, 0.005, 1.0),
		&"deep_color": Color(0.54, 0.055, 0.002, 1.0),
		&"transmit_color": Color(1.0, 0.62, 0.16, 1.0),
		&"rim_color": Color(1.0, 0.75, 0.28, 1.0),
	},
	"B": {
		&"body_color": Color(0.42, 0.025, 0.74, 1.0),
		&"deep_color": Color(0.115, 0.006, 0.29, 1.0),
		&"transmit_color": Color(0.70, 0.42, 1.0, 1.0),
		&"rim_color": Color(0.84, 0.66, 1.0, 1.0),
	},
	"M": {
		&"body_color": Color(0.38, 0.10, 0.68, 1.0),
		&"deep_color": Color(0.12, 0.018, 0.29, 1.0),
		&"transmit_color": Color(0.72, 0.56, 1.0, 1.0),
		&"rim_color": Color(0.88, 0.78, 1.0, 1.0),
	},
	"N": {
		&"body_color": Color(0.34, 0.70, 0.018, 1.0),
		&"deep_color": Color(0.06, 0.23, 0.002, 1.0),
		&"transmit_color": Color(0.70, 1.0, 0.22, 1.0),
		&"rim_color": Color(0.84, 1.0, 0.38, 1.0),
	},
	"A": {
		&"body_color": Color(0.94, 0.43, 0.008, 1.0),
		&"deep_color": Color(0.47, 0.10, 0.001, 1.0),
		&"transmit_color": Color(1.0, 0.76, 0.20, 1.0),
		&"rim_color": Color(1.0, 0.88, 0.38, 1.0),
	},
	"D": {
		&"body_color": Color(0.94, 0.24, 0.004, 1.0),
		&"deep_color": Color(0.50, 0.045, 0.001, 1.0),
		&"transmit_color": Color(1.0, 0.58, 0.12, 1.0),
		&"rim_color": Color(1.0, 0.72, 0.24, 1.0),
	},
}

# Historical Fizzy/V5 base values retained as the reversible material control.
# V6 overrides its production-facing response after this dictionary is merged;
# legacy look-dev callers can still request these values directly.
const FIZZY: Dictionary = {
	&"albedo_gain": 0.90,
	&"body_roughness": 0.17,
	&"coat_roughness": 0.030,
	&"coat_strength": 1.56,
	&"spec_energy": 0.19,
	&"light_wrap": 0.22,
	&"sss_amount": 0.66,
	&"transmit_strength": 1.34,
	&"thin_glow": 0.55,
	&"rim_energy": 0.12,
	&"interior_budget": 0.12,
	&"rim_budget": 0.06,
	&"body_budget": 1.02,
	&"body_absorb": 0.84,
	&"extinction_density": 2.85,
	&"extinction_spread": 1.52,
	&"extinction_shape": 2.55,
	&"dimple_depth": 0.0,
	&"membrane_enabled": true,
	&"membrane_face_alpha": 0.008,
	&"membrane_edge_alpha": 0.50,
	&"membrane_edge_power": 2.25,
	&"membrane_roughness": 0.025,
	&"membrane_rim_emission": 0.40,
	&"membrane_thickness": 0.0045,
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
	# V5 no longer asks the sphere lattice to tile the complete surface. A
	# sparser radius range supplies irregular grazing dimples; the shared shader
	# caps and noise-modulates their effective depth for distance stability.
	&"microbubble_scale": 42.0,
	&"microbubble_density": 0.68,
	&"microbubble_radius_min": 0.18,
	&"microbubble_radius_max": 0.48,
	&"microbubble_jitter": 0.18,
	&"microbubble_softness": 0.10,
	&"microbubble_depth": 0.012,
	&"microbubble_thinness": 0.0,
	&"microbubble_shell_shadow": 0.0,
	&"microbubble_emission": 0.0,
	&"microbubble_shell_emission": 0.0,
	&"inclusion_enabled": true,
	&"inclusion_scale": 64.0,
	&"inclusion_depth": 0.004,
	&"inclusion_threshold": 0.74,
	&"inclusion_softness": 0.060,
	&"inclusion_emission": 0.018,
}

const FAMILY: Dictionary = {
	# T keeps its authored face and finer bubbles so the aggressive sculpt remains
	# distinct without retaining the old rubber-like dimple normal field.
	"T": {
		# Identity engine ALBEDO removes the old accidental second colour multiply.
		# A deeper amber input now restores the reference's orange core without
		# hiding another albedo multiplication inside the custom light function.
		&"body_color": Color(1.0, 0.28, 0.0, 1.0),
		&"bubble_scale": 8.5,
		&"bubble_density": 0.44,
		&"bubble_radius_min": 0.13,
		&"bubble_radius_max": 0.29,
		&"bubble_seed": 223.0,
		&"bubble_depth": 0.0,
		&"bubble_thinness": 0.0,
		&"bubble_emission": 0.0,
		&"bubble_shell_emission": 0.0,
		&"microbubble_seed": 227.0,
		&"inclusion_seed": 229.0,
	},
	# B's UV-less Meshy sculpt exposed the directional seams of the old triplanar
	# field. Sparse 3D spheres intersect the actual surface as round pockets from
	# every view and make the body read as gel without changing its topology.
	"B": {
		&"albedo_gain": 1.04,
		&"body_budget": 1.10,
		&"light_wrap": 0.27,
		&"bubble_scale": 6.6,
		&"bubble_density": 0.58,
		&"bubble_radius_min": 0.16,
		&"bubble_radius_max": 0.35,
		&"bubble_jitter": 0.16,
		&"bubble_softness": 0.09,
		&"bubble_depth": 0.0025,
		&"bubble_thinness": 0.29,
		&"bubble_emission": 0.006,
		&"bubble_shell_emission": 0.09,
		&"bubble_seed": 19.0,
		&"microbubble_seed": 23.0,
		&"inclusion_threshold": 0.74,
		&"inclusion_emission": 0.04,
		&"inclusion_seed": 29.0,
	},
	# M uses an untextured 8.8k-triangle Meshy T2 sculpt. The legacy triplanar
	# dimple normal exaggerates its triangles at grazing angles, so the sculpt uses
	# the same view-independent air-pocket cue as B with a quieter macrophage tune.
	"M": {
		&"body_color": Color(0.78, 0.58, 0.98, 1.0),
		&"deep_color": Color(0.42, 0.14, 0.66, 1.0),
		&"transmit_color": Color(0.90, 0.80, 1.0, 1.0),
		&"rim_color": Color(0.96, 0.88, 1.0, 1.0),
		&"bubble_enabled": true,
		&"bubble_scale": 5.2,
		&"bubble_density": 0.40,
		&"bubble_radius_min": 0.16,
		&"bubble_radius_max": 0.30,
		&"bubble_jitter": 0.14,
		&"bubble_softness": 0.10,
		&"bubble_depth": 0.010,
		&"bubble_thinness": 0.30,
		&"bubble_shell_shadow": 0.018,
		&"bubble_emission": 0.025,
		&"bubble_seed": 31.0,
		&"dimple_depth": 0.0,
		&"thin_curvature": 0.03,
		&"rim_energy": 0.08,
		&"coat_strength": 1.10,
	},
}


static func options(family: String, overrides: Dictionary = {}) -> Dictionary:
	var merged := BASE.duplicate(true)
	if family == "T" or family == "B":
		for key in FIZZY:
			merged[key] = FIZZY[key]
	var family_values: Dictionary = FAMILY.get(family, {})
	for key in family_values:
		merged[key] = family_values[key]
	for key in V5_SURFACE:
		merged[key] = V5_SURFACE[key]
	if banner_match_enabled():
		for key in V6_BANNER_MATCH:
			merged[key] = V6_BANNER_MATCH[key]
		var v6_family_values: Dictionary = V6_FAMILY.get(family, {})
		for key in v6_family_values:
			merged[key] = v6_family_values[key]
	for key in overrides:
		merged[key] = overrides[key]
	return merged


static func with_v5_surface(values: Dictionary, family: String = "") -> Dictionary:
	var merged := values.duplicate(true)
	for key in V5_SURFACE:
		merged[key] = V5_SURFACE[key]
	if banner_match_enabled():
		for key in V6_BANNER_MATCH:
			merged[key] = V6_BANNER_MATCH[key]
		var v6_family_values: Dictionary = V6_FAMILY.get(family, {})
		for key in v6_family_values:
			merged[key] = v6_family_values[key]
	return merged


static func banner_match_enabled() -> bool:
	var override := OS.get_environment("IMMUNE_GEL_LOOK").strip_edges().to_lower()
	if override in ["v5", "v6"]:
		return override == "v6"
	return str(ProjectSettings.get_setting("immune/visual/gel_look", "v6")).to_lower() == "v6"


static func profile_name(family: String) -> StringName:
	if family == "B":
		return &"round_bubbles"
	if family == "T":
		return &"authored_membrane"
	if family == "M":
		return &"macrophage_bubbles"
	return &"base_gel"
