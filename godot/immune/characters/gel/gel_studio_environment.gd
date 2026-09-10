class_name ImmuneGelStudioEnvironment
extends RefCounted

## Shared V6 look-development environment for large character presentations.
## Gameplay keeps each mission's authored arena background; this only supplies
## the dark lab gradient and reflected-light palette used by review/portrait views.

const _Profiles := preload("res://characters/gel/gel_profiles.gd")


static func apply_banner_preview(environment: Environment) -> void:
	if environment == null or not _Profiles.banner_match_enabled():
		return
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.012, 0.034, 0.085)
	sky_material.sky_horizon_color = Color(0.085, 0.19, 0.32)
	sky_material.sky_curve = 0.22
	sky_material.ground_horizon_color = Color(0.085, 0.13, 0.23)
	sky_material.ground_bottom_color = Color(0.018, 0.038, 0.080)
	sky_material.ground_curve = 0.18
	sky_material.sun_angle_max = 0.0
	sky_material.sky_energy_multiplier = 0.92
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.background_energy_multiplier = 0.90
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.ambient_light_energy = 0.34
	environment.glow_enabled = true
	environment.glow_intensity = 0.68
	environment.glow_bloom = 0.10
