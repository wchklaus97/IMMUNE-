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

# The production Fizzy language already approved on M/N/A/D: a smooth clear
# coat, softened absorption, three readable interior scales, and no directional
# triplanar dimples. T and B still keep their own sculpt, face texture, colour,
# bubble scale, and seeds; this layer only makes their material response belong
# to the same poured-gel family.
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

const FAMILY: Dictionary = {
	# T keeps its authored face and finer bubbles so the aggressive sculpt remains
	# distinct without retaining the old rubber-like dimple normal field.
	"T": {
		# The generic warm-hue pre-rotation was fitted before the Fizzy lighting
		# stack existed and now lands yellow under ACES. This authored amber input
		# renders as the saturated orange core in CHAR-BASE-T-3d-alt.png.
		&"body_color": Color(1.0, 0.753, 0.0, 1.0),
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
	for key in overrides:
		merged[key] = overrides[key]
	return merged


static func profile_name(family: String) -> StringName:
	if family == "B":
		return &"round_bubbles"
	if family == "T":
		return &"authored_membrane"
	if family == "M":
		return &"macrophage_bubbles"
	return &"base_gel"
