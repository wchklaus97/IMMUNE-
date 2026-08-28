class_name ImmuneFamilyLook
extends RefCounted

## Six-base color lock from docs/vfx/3d-style-lock.md. Fusion stays off.

const JELLY := {
	"T": Color(1.0, 0.48, 0.16, 0.88),
	"B": Color(0.62, 0.22, 0.86, 0.88),
	"M": Color(0.78, 0.58, 0.98, 0.88),
	"N": Color(0.52, 0.86, 0.18, 0.88),
	"A": Color(0.98, 0.62, 0.22, 0.88),
	"D": Color(1.0, 0.50, 0.22, 0.88),
}

const ACCENT := {
	"T": Color(0.92, 0.20, 0.22, 0.95),
	"B": Color(0.95, 0.78, 0.29, 1.0),
	"M": Color(0.86, 0.16, 0.22, 1.0),
	"N": Color(0.32, 0.36, 0.26, 1.0),
	"A": Color(0.98, 0.86, 0.45, 1.0),
	"D": Color(1.0, 0.42, 0.20, 0.95),
}

const DISPLAY_NAME := {
	"T": "T 細胞",
	"B": "B 細胞",
	"M": "巨噬細胞",
	"N": "NK 細胞",
	"A": "抗體構造體",
	"D": "樹突細胞",
}

const SCENE_PATH := {
	"T": "res://characters/base_t/character.tscn",
	"B": "res://characters/base_b/character.tscn",
	"M": "res://characters/base_m/character.tscn",
	"N": "res://characters/base_n/character.tscn",
	"A": "res://characters/base_a/character.tscn",
	"D": "res://characters/base_d/character.tscn",
}

const LINE_DIR := "res://characters/concepts/base-cell-line-v2/"
const DUTY_CONCEPT_DIR := "res://characters/concepts/"

const _Gel := preload("res://characters/gel/gel_look.gd")
const _GelProfiles := preload("res://characters/gel/gel_profiles.gd")


static func jelly_color(family: String) -> Color:
	return JELLY.get(family, Color.WHITE)


static func accent_color(family: String) -> Color:
	return ACCENT.get(family, Color.WHITE)


static func jelly_material(family: String) -> StandardMaterial3D:
	return _make_material(jelly_color(family), 0.08, 0.28)


## Translucent wet-gel body material. Same six-colour lock as jelly_material, but
## a ShaderMaterial instead of StandardMaterial3D, so it is offered alongside
## rather than swapped in — primitive blockouts have no UVs to carry a feature mask.
static func gel_material(family: String, opts: Dictionary = {}) -> ShaderMaterial:
	return _Gel.make_material(jelly_color(family), _GelProfiles.options(family, opts))


## Paints every MeshInstance3D under `root` with the gel material, keeping each
## surface's baked basecolor as the dark-feature mask. Use on sculpted meshes.
static func apply_gel(root: Node, family: String, opts: Dictionary = {}) -> Array[ShaderMaterial]:
	return _Gel.apply(root, jelly_color(family), _GelProfiles.options(family, opts))


static func gel_profile_name(family: String) -> StringName:
	return _GelProfiles.profile_name(family)


static func accent_material(family: String) -> StandardMaterial3D:
	var metallic := 0.55 if family == "N" or family == "A" else 0.08
	var roughness := 0.28 if family == "N" else 0.16
	return _make_material(accent_color(family), roughness, 0.08, metallic)


static func metal_material(color: Color) -> StandardMaterial3D:
	return _make_material(color, 0.32, 0.04, 0.7)


static func line_path(family: String) -> String:
	return "%sCHAR-BASE-%s.png" % [LINE_DIR, family]


static func lineup_path() -> String:
	return "%sLINEUP.png" % LINE_DIR


static func concept_path(family: String, duty: StringName) -> String:
	var suffix := "fixed"
	if duty == &"relay" or (duty == &"mobile" and family == "A"):
		suffix = "relay"
	elif duty == &"mobile":
		suffix = "mobile"
	return "%sCHAR-BASE-%s-3d-%s.png" % [DUTY_CONCEPT_DIR, family, suffix]


static func load_png(res_path: String) -> Texture2D:
	var abs_path := ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(abs_path):
		return null
	var image := Image.new()
	if image.load(abs_path) != OK:
		return null
	return ImageTexture.create_from_image(image)


static func _make_material(color: Color, roughness: float, emission: float, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = emission > 0.0
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = emission
	return mat
