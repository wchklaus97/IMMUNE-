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

# V7 is an additive refinement over the preserved V6 checkpoint. It keeps the
# V6 optical model, then replaces the evenly dotted read with anisotropic
# object-space strands and a longer broken reflection card. Every new shader
# control defaults to zero, so selecting v5 or v6 retains the earlier response.
const V7_GUMMY_GLASS: Dictionary = {
	&"albedo_gain": 0.88,
	&"body_exposure_scale": 0.76,
	&"body_roughness": 0.22,
	&"core_glow": 0.14,
	&"interior_budget": 0.30,
	&"thickness_contrast": 0.32,
	&"body_absorb": 1.0,
	&"transmit_strength": 1.56,
	&"thin_glow": 0.64,
	&"rim_energy": 0.20,
	&"rim_budget": 0.11,
	&"coat_roughness": 0.032,
	&"coat_strength": 1.70,
	&"spec_energy": 0.27,
	&"wet_spec_breakup": 0.055,
	&"detail_emission_scale": 0.26,
	&"authored_fleck_strength": 0.38,
	&"authored_fleck_threshold": 0.325,
	&"authored_fleck_softness": 0.014,
	&"authored_fleck_budget": 0.105,
	&"authored_inclusion_strength": 0.44,
	&"authored_inclusion_scale": 0.12,
	&"authored_inclusion_threshold": 0.225,
	&"authored_inclusion_softness": 0.016,
	&"authored_inclusion_thinness": 0.10,
	&"authored_inclusion_budget": 0.105,
	&"authored_caustic_strength": 0.32,
	&"authored_caustic_threshold": 0.255,
	&"authored_caustic_width": 0.014,
	&"authored_caustic_budget": 0.055,
	&"authored_fiber_strength": 0.58,
	&"authored_fiber_scale": 0.18,
	&"authored_fiber_threshold": 0.30,
	&"authored_fiber_width": 0.016,
	&"authored_fiber_thinness": 0.055,
	&"authored_fiber_budget": 0.105,
	&"authored_fiber_lod_bias": 0.22,
	&"studio_reflection_strength": 0.74,
	&"studio_reflection_budget": 0.32,
	&"studio_reflection_edge_share": 0.54,
	&"studio_streak_strength": 0.72,
	&"membrane_face_alpha": 0.004,
	&"membrane_edge_alpha": 0.56,
	&"membrane_edge_power": 1.90,
	&"membrane_roughness": 0.016,
	&"membrane_rim_emission": 0.42,
	&"membrane_thickness": 0.020,
}

const V7_FAMILY: Dictionary = {
	"T": {
		&"body_color": Color(0.98, 0.20, 0.002, 1.0),
		&"deep_color": Color(0.43, 0.028, 0.001, 1.0),
		&"transmit_color": Color(1.0, 0.64, 0.13, 1.0),
		&"rim_color": Color(1.0, 0.78, 0.30, 1.0),
	},
	"B": {
		&"body_color": Color(0.56, 0.006, 0.74, 1.0),
		&"deep_color": Color(0.11, 0.001, 0.22, 1.0),
		&"transmit_color": Color(0.68, 0.40, 1.0, 1.0),
		&"rim_color": Color(0.86, 0.70, 1.0, 1.0),
	},
	"M": {
		&"body_color": Color(0.32, 0.10, 0.72, 1.0),
		&"deep_color": Color(0.065, 0.010, 0.24, 1.0),
		&"transmit_color": Color(0.66, 0.53, 1.0, 1.0),
		&"rim_color": Color(0.84, 0.77, 1.0, 1.0),
	},
	"N": {
		&"body_color": Color(0.44, 0.78, 0.004, 1.0),
		&"deep_color": Color(0.04, 0.20, 0.001, 1.0),
		&"transmit_color": Color(0.72, 1.0, 0.16, 1.0),
		&"rim_color": Color(0.86, 1.0, 0.35, 1.0),
	},
	"A": {
		&"body_color": Color(0.98, 0.47, 0.002, 1.0),
		&"deep_color": Color(0.42, 0.075, 0.001, 1.0),
		&"transmit_color": Color(1.0, 0.76, 0.16, 1.0),
		&"rim_color": Color(1.0, 0.89, 0.39, 1.0),
	},
	"D": {
		&"body_color": Color(0.98, 0.27, 0.002, 1.0),
		&"deep_color": Color(0.46, 0.030, 0.001, 1.0),
		&"transmit_color": Color(1.0, 0.59, 0.10, 1.0),
		&"rim_color": Color(1.0, 0.74, 0.25, 1.0),
	},
}

# V8 is an additive motion layer over the exact V7 gummy-glass foundation. The
# authored skin and silhouette remain unchanged; only the internal inclusion and
# fiber coordinates circulate. Runtime movement supplies direction and a 0..1
# blend, while these values guarantee that idle characters never become static.
const V8_LIVING_LIQUID: Dictionary = {
	# V8 trades V7's dense suspended-fleck read for fewer, quieter anchors so the
	# new broad slime folds remain the dominant internal cue. V7 itself is untouched.
	&"authored_fleck_strength": 0.18,
	&"authored_fleck_budget": 0.050,
	&"authored_inclusion_strength": 0.30,
	&"authored_inclusion_thinness": 0.060,
	&"authored_inclusion_budget": 0.070,
	&"authored_caustic_strength": 0.20,
	&"authored_caustic_budget": 0.040,
	&"authored_fiber_strength": 0.30,
	&"authored_fiber_thinness": 0.035,
	&"authored_fiber_budget": 0.070,
	&"liquid_flow_strength": 0.78,
	&"liquid_flow_idle_speed": 0.21,
	&"liquid_flow_move_boost": 0.50,
	&"liquid_flow_advection": 0.25,
	&"liquid_flow_warp": 0.14,
	&"liquid_flow_emission": 0.46,
	&"liquid_flow_budget": 0.070,
	&"liquid_flow_motion_mix": 0.0,
	&"liquid_slime_strength": 0.94,
	&"liquid_slime_scale": 0.92,
	&"liquid_slime_threshold": 0.49,
	&"liquid_slime_softness": 0.14,
	&"liquid_slime_thinness": 0.15,
	&"liquid_body_deform_strength": 0.82,
}

const V8_FAMILY: Dictionary = {
	"T": {&"liquid_flow_phase": 0.31},
	"B": {&"liquid_flow_phase": 1.17},
	"M": {&"liquid_flow_phase": 2.03},
	"N": {&"liquid_flow_phase": 2.89},
	"A": {&"liquid_flow_phase": 3.73},
	"D": {&"liquid_flow_phase": 4.61},
}

# V8.2 is an additive optical-volume slice over the exact V8.1 foundation. It
# reuses one existing eight-cell bubble field and the existing analytic slime;
# no screen read, raymarch, microbubble field, or extra transparent material is
# introduced. T/B start strongest because they are the reference vertical slice,
# while every family receives a bounded core and a distinct phase/density tune.
const V8_2_LIVING_VOLUME: Dictionary = {
	# Calm the old suspended-detail layer so the broad moving mass, rather than a
	# field of bright fragments, owns the interior read. Surface height stays on.
	&"authored_fleck_strength": 0.10,
	&"authored_fleck_budget": 0.035,
	&"authored_inclusion_strength": 0.16,
	&"authored_inclusion_budget": 0.045,
	&"authored_caustic_strength": 0.12,
	&"authored_caustic_budget": 0.025,
	&"authored_fiber_strength": 0.18,
	&"authored_fiber_budget": 0.045,
	&"liquid_core_color_mix": 0.42,
	&"liquid_core_roughness_mix": 0.40,
	&"liquid_bubble_advection": 0.82,
	&"liquid_flow_emission": 0.30,
	&"liquid_flow_budget": 0.052,
	&"bubble_enabled": true,
	# A few broad pockets remain trackable through motion; the former denser field
	# read as noisy texture and competed with the reference's smooth optical core.
	&"bubble_scale": 4.8,
	&"bubble_density": 0.12,
	&"bubble_radius_min": 0.15,
	&"bubble_radius_max": 0.30,
	&"bubble_jitter": 0.14,
	&"bubble_softness": 0.12,
	&"bubble_depth": 0.0004,
	&"bubble_thinness": 0.06,
	&"bubble_shell_shadow": 0.012,
	&"bubble_emission": 0.0,
	&"bubble_shell_emission": 0.012,
	# One macro field is the V8.2 inclusion budget. Keeping the second field off
	# avoids another eight hashes per fragment and distance-scale fizz.
	&"microbubble_enabled": false,
	&"microbubble_depth": 0.0,
	&"microbubble_thinness": 0.0,
	&"microbubble_shell_shadow": 0.0,
	&"microbubble_emission": 0.0,
	&"microbubble_shell_emission": 0.0,
	# Thin face alpha exposes the moving core; a narrow Fresnel edge and the
	# existing bounded studio cards retain the distinct wet outer membrane.
	&"membrane_face_alpha": 0.0028,
	&"membrane_edge_alpha": 0.58,
	&"membrane_edge_power": 2.20,
	&"membrane_roughness": 0.014,
	&"membrane_rim_emission": 0.36,
	&"membrane_thickness": 0.020,
}

const V8_2_FAMILY: Dictionary = {
	"T": {
		&"liquid_flow_phase": 0.43,
		&"liquid_core_color_mix": 0.70,
		&"liquid_core_roughness_mix": 0.55,
		&"liquid_bubble_advection": 0.90,
		&"bubble_scale": 4.8,
		&"bubble_density": 0.14,
		&"bubble_radius_min": 0.15,
		&"bubble_radius_max": 0.32,
		&"bubble_depth": 0.0004,
		&"bubble_thinness": 0.07,
		&"bubble_shell_shadow": 0.012,
		&"bubble_shell_emission": 0.012,
		&"membrane_face_alpha": 0.0018,
		&"membrane_edge_alpha": 0.62,
		&"membrane_edge_power": 2.30,
		&"membrane_roughness": 0.012,
		&"membrane_thickness": 0.021,
	},
	"B": {
		&"liquid_flow_phase": 1.31,
		&"liquid_core_color_mix": 0.78,
		&"liquid_core_roughness_mix": 0.60,
		&"liquid_bubble_advection": 0.92,
		&"bubble_scale": 4.6,
		&"bubble_density": 0.12,
		&"bubble_radius_min": 0.16,
		&"bubble_radius_max": 0.34,
		&"bubble_depth": 0.0004,
		&"bubble_thinness": 0.06,
		&"bubble_shell_shadow": 0.012,
		&"bubble_shell_emission": 0.012,
		&"membrane_face_alpha": 0.0018,
		&"membrane_edge_alpha": 0.61,
		&"membrane_edge_power": 2.25,
		&"membrane_roughness": 0.013,
		&"membrane_thickness": 0.021,
	},
	"M": {
		&"liquid_flow_phase": 2.17,
		&"liquid_core_color_mix": 0.50,
		&"liquid_core_roughness_mix": 0.44,
		&"liquid_bubble_advection": 0.80,
		&"bubble_scale": 4.8,
		&"bubble_density": 0.11,
	},
	"N": {
		&"liquid_flow_phase": 3.07,
		&"liquid_core_color_mix": 0.42,
		&"liquid_core_roughness_mix": 0.38,
		&"liquid_bubble_advection": 0.76,
		&"bubble_scale": 5.2,
		&"bubble_density": 0.10,
	},
	"A": {
		&"liquid_flow_phase": 3.91,
		&"liquid_core_color_mix": 0.46,
		&"liquid_core_roughness_mix": 0.40,
		&"liquid_bubble_advection": 0.78,
		&"bubble_scale": 5.0,
		&"bubble_density": 0.11,
	},
	"D": {
		&"liquid_flow_phase": 4.83,
		&"liquid_core_color_mix": 0.52,
		&"liquid_core_roughness_mix": 0.45,
		&"liquid_bubble_advection": 0.82,
		&"bubble_scale": 4.7,
		&"bubble_density": 0.13,
	},
}

# V8.3 keeps the accepted V8.2 living core but removes every detail that can
# read as a loose cell, pellet, or fragment. Topology is handled by the matching
# single-mass body branch; these values make the optical volume equally clean.
const V8_3_SINGLE_MASS: Dictionary = {
	&"bubble_enabled": false,
	&"bubble_density": 0.0,
	&"bubble_depth": 0.0,
	&"bubble_thinness": 0.0,
	&"bubble_shell_shadow": 0.0,
	&"bubble_emission": 0.0,
	&"bubble_shell_emission": 0.0,
	&"microbubble_enabled": false,
	&"microbubble_density": 0.0,
	&"microbubble_depth": 0.0,
	&"microbubble_thinness": 0.0,
	&"microbubble_shell_shadow": 0.0,
	&"microbubble_emission": 0.0,
	&"microbubble_shell_emission": 0.0,
	&"inclusion_enabled": false,
	&"inclusion_depth": 0.0,
	&"inclusion_emission": 0.0,
	&"authored_fleck_strength": 0.0,
	&"authored_fleck_budget": 0.0,
	&"authored_inclusion_strength": 0.0,
	&"authored_inclusion_budget": 0.0,
	&"authored_caustic_strength": 0.08,
	&"authored_caustic_budget": 0.018,
	&"authored_fiber_strength": 0.12,
	&"authored_fiber_budget": 0.026,
	&"authored_height_depth": 0.0008,
	&"detail_emission_scale": 0.06,
	&"liquid_flow_emission": 0.26,
	&"liquid_flow_budget": 0.046,
	&"liquid_body_deform_strength": 0.64,
	&"membrane_face_alpha": 0.0022,
	&"membrane_edge_alpha": 0.56,
	&"membrane_edge_power": 2.30,
	&"membrane_roughness": 0.015,
	&"membrane_rim_emission": 0.32,
	&"membrane_thickness": 0.018,
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
	if gummy_glass_enabled():
		for key in V7_GUMMY_GLASS:
			merged[key] = V7_GUMMY_GLASS[key]
		var v7_family_values: Dictionary = V7_FAMILY.get(family, {})
		for key in v7_family_values:
			merged[key] = v7_family_values[key]
	if v8_enabled():
		for key in V8_LIVING_LIQUID:
			merged[key] = V8_LIVING_LIQUID[key]
		var v8_family_values: Dictionary = V8_FAMILY.get(family, {})
		for key in v8_family_values:
			merged[key] = v8_family_values[key]
	if living_volume_enabled():
		for key in V8_2_LIVING_VOLUME:
			merged[key] = V8_2_LIVING_VOLUME[key]
		var v8_2_family_values: Dictionary = V8_2_FAMILY.get(family, {})
		for key in v8_2_family_values:
			merged[key] = v8_2_family_values[key]
	if v8_3_enabled():
		for key in V8_3_SINGLE_MASS:
			merged[key] = V8_3_SINGLE_MASS[key]
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
	if gummy_glass_enabled():
		for key in V7_GUMMY_GLASS:
			merged[key] = V7_GUMMY_GLASS[key]
		var v7_family_values: Dictionary = V7_FAMILY.get(family, {})
		for key in v7_family_values:
			merged[key] = v7_family_values[key]
	if v8_enabled():
		for key in V8_LIVING_LIQUID:
			merged[key] = V8_LIVING_LIQUID[key]
		var v8_family_values: Dictionary = V8_FAMILY.get(family, {})
		for key in v8_family_values:
			merged[key] = v8_family_values[key]
	if living_volume_enabled():
		for key in V8_2_LIVING_VOLUME:
			merged[key] = V8_2_LIVING_VOLUME[key]
		var v8_2_family_values: Dictionary = V8_2_FAMILY.get(family, {})
		for key in v8_2_family_values:
			merged[key] = v8_2_family_values[key]
	if v8_3_enabled():
		for key in V8_3_SINGLE_MASS:
			merged[key] = V8_3_SINGLE_MASS[key]
	return merged


static func selected_look() -> String:
	var override := OS.get_environment("IMMUNE_GEL_LOOK").strip_edges().to_lower()
	if override in ["v5", "v6", "v7", "v8", "v8_1", "v8_2", "v8_3"]:
		return override
	var configured := str(ProjectSettings.get_setting("immune/visual/gel_look", "v6")).strip_edges().to_lower()
	return configured if configured in ["v5", "v6", "v7", "v8", "v8_1", "v8_2", "v8_3"] else "v6"


static func banner_match_enabled() -> bool:
	return selected_look() in ["v6", "v7", "v8", "v8_1", "v8_2", "v8_3"]


static func gummy_glass_enabled() -> bool:
	return selected_look() in ["v7", "v8", "v8_1", "v8_2", "v8_3"]


static func v7_enabled() -> bool:
	return selected_look() == "v7"


static func v8_enabled() -> bool:
	return selected_look() in ["v8", "v8_1", "v8_2", "v8_3"]


## V8.1 inherits the accepted V8 material and clip foundation, then enables the
## motion-truth, release-timing and attachment-coherence hardening layer. Keeping
## this selector separate makes IMMUNE_GEL_LOOK=v8 an exact rollback.
static func v8_1_enabled() -> bool:
	return selected_look() == "v8_1"


static func v8_2_enabled() -> bool:
	return selected_look() == "v8_2"


static func v8_3_enabled() -> bool:
	return selected_look() == "v8_3"


## V8.3 inherits V8.2's fourteen-clip and living-volume foundation while the
## exact v8_2_enabled() selector remains available for rollback assertions.
static func living_volume_enabled() -> bool:
	return selected_look() in ["v8_2", "v8_3"]


## V8.2 inherits V8.1's shared-coordinate attachment and release hardening while
## v8_1_enabled() remains an exact rollback selector for material/smoke checks.
static func motion_truth_enabled() -> bool:
	return selected_look() in ["v8_1", "v8_2", "v8_3"]


static func profile_name(family: String) -> StringName:
	if v8_3_enabled():
		return &"single_mass_clean"
	if family == "B":
		return &"round_bubbles"
	if family == "T":
		return &"authored_membrane"
	if family == "M":
		return &"macrophage_bubbles"
	return &"base_gel"
