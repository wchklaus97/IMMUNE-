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

const FAMILY: Dictionary = {
	# T's authored texture already carries fine membrane cells and face detail.
	# Keep the existing dimple layer and do not stack B's larger air-pocket cue.
	"T": {
		&"bubble_enabled": false,
	},
	# B's UV-less Meshy sculpt exposed the directional seams of the old triplanar
	# field. Sparse 3D spheres intersect the actual surface as round pockets from
	# every view and make the body read as gel without changing its topology.
	"B": {
		&"bubble_enabled": true,
		&"bubble_scale": 4.8,
		&"bubble_density": 0.46,
		&"bubble_radius_min": 0.18,
		&"bubble_radius_max": 0.34,
		&"bubble_jitter": 0.16,
		&"bubble_softness": 0.09,
		&"bubble_depth": 0.014,
		&"bubble_thinness": 0.38,
		&"bubble_shell_shadow": 0.025,
		&"bubble_emission": 0.035,
		&"bubble_seed": 19.0,
		&"dimple_depth": 0.0,
		&"thin_curvature": 0.04,
		&"rim_energy": 0.10,
		&"coat_strength": 1.15,
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
