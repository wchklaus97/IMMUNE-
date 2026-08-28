class_name ImmuneGelLook
extends RefCounted

## Wet-gel ShaderMaterial builder for the base-cell bodies.
##
## Palette-agnostic on purpose: it takes a Color and derives the interior and rim
## hues from it, so all six families are served by changing uniforms only.
## ImmuneFamilyLook owns the palette and calls in here; nothing in this file
## reaches back the other way, which keeps the preload graph acyclic.

const SHADER_PATH := "res://characters/gel/wet_gel.gdshader"

## Uniforms that carry family identity. Everything else is shared look tuning.
## All four are derived from the one palette entry, so a family is one Color.
const FAMILY_UNIFORMS: Array[StringName] = [&"body_color", &"deep_color", &"transmit_color", &"rim_color"]

## How far the palette colour's saturation is pushed for the body albedo. A gel
## absorbs its complement, so the channel opposite the family hue must sit AT
## zero, not merely near it -- every lamp in the scene multiplies whatever is left
## there, and the stage's fill and rim are both cool. A residual of 0.03 was enough
## to hold blue flat through the deepest core where the reference sits at 0.004,
## which is what inverted the saturation profile: the reference gets more saturated
## with depth as its blue vanishes, and ours got less.
const BODY_SATURATE := 1.20

## ACES rotates saturated warm hues toward red as exposure rises, so a warm palette
## colour fed in straight renders too red. Pre-rotating lands the rendered body back
## on the palette hue. Fitted on T under tools/shot.tscn.
##
## Refitted at the exposure the material now actually runs at, which is the reason it
## roughly doubled rather than any change of intent. ACES compresses hard near the top
## of its range, and that compression pulls the ratio between channels down with it: at
## the old dim exposure a linear green of 0.62 rendered as 0.46 against red, so the
## shift needed to land a given rendered hue is a function of how hot the body is. The
## body is now driven to the ceiling across the whole shell, so it needs more.
##
## Measured rather than judged: the reference's green sits at 0.573 against red 0.984
## through its shell, a rendered ratio of 0.582, and this is the authored hue that lands
## there. The albedo is a fairly yellow amber as authored; it renders as saturated
## orange, which is the entire purpose of pre-compensating.
const BODY_HUE_SHIFT := 0.115

## How much of BODY_HUE_SHIFT a hue actually needs. The ACES rotation this corrects
## for is a warm-hue effect: it is strong on red through orange and negligible by
## the time the hue reaches green or purple. Applying the full T-fitted shift to
## every family was over-rotating the cool ones toward red, which is what collapsed
## B and M onto the same rendered hue despite the palette separating them. Weighting
## by warmth means greens and purples keep the hue they were authored with, and the
## constant is no longer a value fitted on one family and applied blindly to six.
static func _warmth(h: float) -> float:
	return maxf(cos(TAU * h), 0.0)

## Perceived brightness the body albedo is normalised to, and the floor under which a
## saturation push is judged unaffordable.
##
## Lowered once the body radiance gained a real ceiling. This threshold used to buy
## brightness by refusing saturation, because brightness was scarce -- the albedo was
## the only thing setting rendered exposure, so a dark saturated albedo rendered as a
## dark body. `body_budget` now sets exposure directly, which frees the albedo to do
## the one job only it can do: hold the channel RATIOS. That matters concretely here,
## because a gel's non-dominant channel has to sit at essentially zero. The reference's
## blue falls to 0.004 at its core, and any blue left in the albedo gets lifted straight
## back up by the stage's cool fill and rim -- which is what held ours flat at 0.086 and
## inverted the saturation profile, making it fall inward where the reference's rises.
##
## Kept rather than removed because it still does real work: it is what stops a
## blue-dominant family being driven toward black by a push it cannot pay for, so B and
## M keep their authored saturation while the warm families take the full push.
const LUMA_TARGET := 0.52

## There is deliberately no per-family exposure correction any more.
##
## There used to be one, normalising each family's albedo luminance to LUMA_TARGET and
## capping it by the headroom above its peak channel. `body_budget` makes it redundant
## and then harmful: the ceiling already drives every family's dominant channel to the
## same rendered exposure, so a second normaliser can only fight it -- and because it
## divided by albedo luminance, it dimmed hardest exactly the families whose albedo the
## saturation and hue work had just made brightest.
##
## The honest consequence is unchanged and worth restating: the ceiling equalises the
## PEAK channel, not perceived luminance, so a blue-dominant family whose peak carries
## only 0.072 of Rec.709 luminance still renders darker than an orange one. B and M are
## darker by construction. That is a palette property, not a material defect.
static func _luma(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


## Saturation the body can afford. The BODY_SATURATE push is paid for in luminance:
## driving a hue toward full saturation crushes its non-dominant channels, and for a
## hue whose dominant channel carries little perceived brightness the bill is steep.
## Where a family cannot afford the push, fall back to the authored saturation rather
## than driving the body toward black. Never below what the palette asked for -- that
## is the family's identity, not a tuning knob.
## Warmth-weighted hue the body actually renders at. Shared so the affordability test
## below judges the colour that ships, not the unshifted palette entry.
static func body_hue(jelly: Color) -> float:
	return fposmod(jelly.h + BODY_HUE_SHIFT * _warmth(jelly.h), 1.0)


static func body_sat(jelly: Color) -> float:
	var pushed := minf(jelly.s * BODY_SATURATE, 1.0)
	if _luma(Color.from_hsv(body_hue(jelly), pushed, 1.0)) >= LUMA_TARGET:
		return pushed
	return jelly.s


## Baseline tuning, measured against characters/concepts/CHAR-BASE-T-3d-alt.png
## under tools/shot.tscn lighting. Override per call via the `opts` dictionary.
const DEFAULTS := {
	# Sensitive: the deep core's clip fraction roughly doubles between 1.08 and 1.12,
	# because this scales the one term that covers the whole body. Measured against the
	# reference's own core luminance rather than picked for brightness.
	# Deliberately over-driven relative to what lands on screen. The ceiling absorbs the
	# excess, and driving past it is the whole mechanism: red pins to the plateau while
	# green and blue keep whatever the absorption left them. Its exact value only shows
	# where the ceiling does NOT bind, i.e. in the deepest core, which is why it is
	# calibrated against the reference's core sag rather than its overall brightness.
	&"albedo_gain": 0.90,
	&"absorption": 1.0,
	&"body_roughness": 0.24,
	&"spec_tint": 1.0,
	# Not razor-tight. At 0.06 the dimple normals aliased inside the coat lobe and the
	# crown sheen broke into a field of hard sparkle rather than the reference's smooth
	# sheen with the cellular texture reading through it.
	&"coat_roughness": 0.10,
	# Wet gloss comes from the tight coat, not from driving both lobes hard. At
	# spec_energy 1.3 the broad lobe blew a single wide highlight across the crown --
	# measurably, it was contributing eight points of the deep core's above-0.75 pixel
	# fraction and most of its blue, where the reference's core is almost entirely deep
	# and saturated. Cutting the shared energy and leaving the coat tight keeps several
	# small sharp highlights instead of one broad blown one.
	&"coat_strength": 1.35,
	&"spec_energy": 0.16,
	&"spec_f0": 0.06,
	&"env_specular": 0.0,
	# Low on purpose. A heavily wrapped terminator plus a strong interior fill left
	# almost nothing on the body dark, so the dominant channel had nowhere to fall to
	# and sat against the ceiling everywhere. Letting the shaded side actually go
	# deep is what gives the gradient its range -- "deepest where the body is thick"
	# needs somewhere deep to exist.
	&"light_wrap": 0.16,
	&"sss_amount": 0.5,
	&"transmit_power": 2.6,
	&"transmit_strength": 0.85,
	&"transmit_distort": 0.30,
	# Transmitted light is mostly the lamp's own colour, tinted only by what the gel
	# took out of it on the way through. This is the term that makes a thin edge come
	# out yellow-white with live blue instead of the same saturated orange as the core:
	# the measured saturation fall from core to edge is what reads as light travelling
	# through gel rather than as a brighter coat of paint.
	&"transmit_tint": 0.72,
	# Shape of the hot band. thin_bias concentrates energy toward the thin end;
	# glow_power sets how far in from the silhouette it reaches, independent of the
	# absorption depth; glow_gain over-drives it into a clamped plateau so the outer
	# shell is uniformly hot rather than spiking at the outline. The reference measures
	# equally hot across its whole outer 5%, and clamping is what lets the zone be
	# widened without its peak rising too -- every earlier attempt to widen it by
	# softening the falloff raised the peak as well and overshot.
	&"thin_bias": 2.4,
	&"glow_power": 2.5,
	&"glow_gain": 1.0,
	# Keeps the hot band off the facial detail. Signed convexity stops concave folds
	# glowing, but the raised lip around an eye socket really is convex, so the plateau
	# still snapped it to full glow and ringed every feature with a pale chalky halo the
	# reference does not have. A blurred read of the bake is dark only near a feature,
	# which turns the eyes, pore and mouth into a small keep-out zone.
	&"glow_ao_strength": 1.0,
	&"glow_ao_lod": 3.0,
	&"glow_ao_low": 0.30,
	&"glow_ao_high": 0.55,
	# Broad on purpose, and only safe to be broad because glow_power was split off this
	# in the previous round. This is the depth over which absorption acts, and the
	# reference's thickness gradient is not a rim -- its green falls steadily across the
	# whole outer 12% while red holds flat. At 2.6 the fresnel term collapsed into a
	# one-to-two-pixel edge, so the body had a bright rim on an otherwise uniform solid;
	# near-linear in fresnel spreads the same gradient over the shell. The hot band is
	# unaffected because it reads glow_power instead.
	&"thin_power": 1.0,
	# Exactly 1.0, not more. `thin` now also colours the escaping interior light, and
	# above 1.0 it clamps to full thinness across a wide band -- which would put a broad
	# plateau of near-white back where the spectral ramp is supposed to be.
	&"thin_fresnel": 1.0,
	# A small baseline so a thin part is lit through its whole width, not only in a band
	# at its outline. A slab of gel glows throughout, and with only fresnel and curvature
	# feeding the band the limb interiors stayed dull while their edges ran hot. Small on
	# purpose: this is the one glow term that reaches the deep core too, so it is bought
	# directly out of the clip budget.
	&"thin_floor": 0.08,
	# Curvature is the thinness cue that actually finds the limbs -- fresnel alone only
	# finds the outline -- but a broad dome like the crown is curved too, and with the
	# plateau above it was saturating there and flooding the interior. These are now
	# thresholds on signed convexity, so they read as curvature radii and a concave
	# fold scores below zero instead of scoring as high as a limb tip.
	&"curv_low": 25.0,
	&"curv_high": 60.0,
	# Deliberately small. Curvature comes from screen-space derivatives of the
	# interpolated normal, which are piecewise-constant per triangle, so on a 5k-tri
	# mesh a strong weight here draws the faceting: the eye rims and pore rang with a
	# jagged pale outline that tracked the tessellation rather than the shape. Fresnel
	# uses the normal directly and stays smooth, so it carries the band and curvature
	# only nudges genuinely convex tips.
	&"thin_curvature": 0.10,
	&"thin_glow": 0.22,
	&"core_glow": 0.02,
	# Narrower than before: the rim needs to read as a ribbon on the turn of a solid
	# body, not as a band wide enough to swallow a whole limb.
	&"rim_power": 9.0,
	&"rim_energy": 0.14,
	# Absorption model, now almost purely spectral. These numbers are solved against
	# the reference's own measured channel profile rather than tuned by eye: across the
	# body its red holds 0.98 and only sags to 0.93 at the deepest core, while green
	# halves (0.58 -> 0.29) and blue falls by a factor of 26 (0.106 -> 0.004). Inverting
	# Beer-Lambert on those three ratios gives sigma of roughly 0.06 / 0.73 / 3.0, and
	# base 0.025 with spread 1.24 at shape 1.35 reproduces that triple.
	#
	# The previous base of 1.0 was the defect: neutral extinction on the dominant
	# channel cost red exp(-2.5) at full thickness, so the term that was supposed to
	# give red dynamic range was the same term flattening its exposure. Relaxing it
	# alone is not the answer either -- it floods the body to pale peach. It has to be
	# relaxed AND ceilinged, which is what body_budget below is for.
	# Solved for sigma of roughly 0.09 / 1.25 / 5.7 across red, green and blue. The shape
	# term is what opens the green-to-blue gap: the reference's green only halves through
	# the body while its blue falls by a factor of 26, and a linear spectral weight
	# cannot separate two channels of the same tint that far apart. At 1.35 blue survived
	# at 0.20 across the whole shell as a broad pedestal where the reference sits at 0.06.
	&"extinction_density": 3.5,
	&"extinction_base": 0.025,
	&"extinction_spread": 1.8,
	&"extinction_shape": 3.5,
	# Near-total, which is only safe now that extinction is spectral. When the neutral
	# term dominated sigma, this was a brightness control and 0.65 was as high as it
	# could go without darkening the body; the leftover 35% was a channel-agnostic
	# bypass that let blue through unabsorbed and put a floor under it. With sigma at
	# 0.09 on the dominant channel, running absorption near-full costs red almost
	# nothing while finally letting green hold the reference's gradient slope and
	# letting blue actually reach zero at depth.
	&"body_absorb": 0.95,
	# Ceilings, not amounts -- and the distinction is the whole shape of this material.
	# They were choked down to 0.12/0.10 to stop a flat clipped plateau, but choking
	# the ceiling also removed the transmitted light instead of shaping it, which left
	# absorption as the only carrier of the gradient. Subtractive absorption can deepen
	# a thick shoulder; it can never make a thin edge incandescent, and the reference's
	# limb tips are incandescent. With thin_bias concentrating the energy in the narrow
	# band the ceiling only ever binds where the gel is genuinely thin, so it can sit
	# high: the ribbon runs hot underneath it while the core is untouched.
	# Both much lower than the round-3 values, and not because the look wants less light.
	# They were calibrated when the neutral extinction was pre-attenuating every interior
	# path by exp(-2.5); removing that raised the same paths tenfold, so the old budgets
	# no longer bound anything. interior_budget now governs only the ambient core term --
	# the thin-band glow it used to cap moved inside body_budget.
	&"interior_budget": 0.10,
	&"rim_budget": 0.05,
	# Calibrated as a pair with albedo_gain, and the pairing is the point: the gain
	# drives the dominant channel past clipping across the whole shell and this catches
	# it just underneath. Set the ceiling too low and the drive is wasted; remove it and
	# the drive pins the body at 255 across two thirds of the core.
	&"body_budget": 1.06,
	# Surface microstructure, and the thing four rounds of colour review could not see.
	# These were previously 160.0 / 0.009 / 0.5, which is the feature switched OFF: at
	# that depth and cell count the bump is below visibility at any range this character
	# is ever seen at, so the body rendered as an airbrushed gradient. That measured as
	# microcontrast 0.0410 against the reference's 0.0614 and 0.40 distinct small
	# highlights per 1000 interior px against 2.07 -- BELOW the opaque plastic baseline's
	# 0.56 on the second cue. Colour statistics are blind to it; see the blurred-
	# reference control documented in build/gel_compare.py.
	#
	# Turning it on costs nothing elsewhere, which was worth verifying rather than
	# assuming: hue moved 18.3 -> 18.6 degrees, core R>=250 46.42% -> 46.22%, R>=254
	# 0.42% -> 0.36%, and core saturation actually improved 0.890 -> 0.897.
	#
	# Scale is deliberately held near the low end of what the metric would reward. 160
	# cells reaches exact microcontrast parity, but at the ~500px subject height of a
	# harness shot that is roughly three pixels per cell, and at gameplay size it is
	# about one -- i.e. aliasing that a still-image metric cannot see and an animating
	# character would shimmer with. 110 survives being shrunk.
	&"dimple_scale": 60.0,
	&"dimple_depth": 0.027,
	&"dimple_crease": 0.26,
	# Well under 1.0 on purpose. Fully rounded cells look right but register as fewer
	# distinct highlights, while a pure crease field scores best of all and renders as a
	# bright cracked net at face range. This is the blend that reads as dimpling and
	# still resolves per-cell.
	&"dimple_round": 0.68,
	# Jelly V2 volumetric bubble defaults are deliberately off. Family profiles
	# opt in only after a mesh passes visual and performance review.
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
	&"ink_low": 0.13,
	&"ink_high": 0.36,
	&"ink_roughness": 0.05,
	&"tex_tint_mix": 0.0,
}


## Body albedo: the palette hue at near-full saturation, pre-rotated for ACES by
## only as much as this hue's warmth actually calls for.
static func body_color(jelly: Color) -> Color:
	return Color.from_hsv(body_hue(jelly), body_sat(jelly), jelly.v)


## Deeper, slightly warmer version of the family hue. This is what light picks up
## crossing a thick part, so it must not be a plain darken.
static func deep_color(jelly: Color) -> Color:
	return Color.from_hsv(fposmod(jelly.h - 0.010, 1.0), 0.99, maxf(jelly.v * 0.84, 0.05))


## What a thin part glows: light crossed less material, so it keeps more of the
## short wavelengths and comes out hotter and yellower than deep_color.
static func transmit_color(jelly: Color) -> Color:
	return Color.from_hsv(
		fposmod(jelly.h + 0.030 * _warmth(jelly.h), 1.0),
		clampf(jelly.s * 1.15, 0.0, 0.95),
		1.0)


## Silhouette fresnel. Kept near-fully saturated on purpose: the rim reads hot
## because rim_energy overdrives it into the glow pass, not because it is pale.
## Washing it out with white is what made earlier rounds look like a lantern.
static func rim_color(jelly: Color) -> Color:
	return Color.from_hsv(
		fposmod(jelly.h + 0.032 * _warmth(jelly.h), 1.0),
		clampf(jelly.s * 1.12, 0.0, 0.97),
		1.0)


static func make_material(jelly: Color, opts: Dictionary = {}) -> ShaderMaterial:
	var shader := load(SHADER_PATH) as Shader
	if shader == null:
		push_error("ImmuneGelLook: cannot load %s" % SHADER_PATH)
		return null
	var mat := ShaderMaterial.new()
	mat.shader = shader
	for key in DEFAULTS:
		mat.set_shader_parameter(key, DEFAULTS[key])
	mat.set_shader_parameter(&"body_color", body_color(jelly))
	mat.set_shader_parameter(&"deep_color", deep_color(jelly))
	mat.set_shader_parameter(&"transmit_color", transmit_color(jelly))
	mat.set_shader_parameter(&"rim_color", rim_color(jelly))
	mat.set_shader_parameter(&"use_feature_tex", false)
	for key in opts:
		mat.set_shader_parameter(StringName(key), opts[key])
	return mat


## Replaces every surface on every MeshInstance3D under `root` with the gel
## material, carrying each surface's baked basecolor across as the feature mask so
## the dark eyes, pore hole and mouth line survive.
## Returns the materials it created, newest first, for later live tweaking.
static func apply(root: Node, jelly: Color, opts: Dictionary = {}) -> Array[ShaderMaterial]:
	var made: Array[ShaderMaterial] = []
	if root == null:
		return made
	for mi in _mesh_instances(root):
		var mesh := mi.mesh
		if mesh == null:
			continue
		# material_override would hide per-surface textures, so go surface by surface.
		mi.material_override = null
		for i in mesh.get_surface_count():
			var mat := make_material(jelly, opts)
			if mat == null:
				continue
			var tex := _baked_texture(mi, mesh, i)
			if tex != null:
				mat.set_shader_parameter(&"feature_tex", tex)
				mat.set_shader_parameter(&"use_feature_tex", true)
			mi.set_surface_override_material(i, mat)
			made.append(mat)
	return made


## The imported GLB material is where Tripo's basecolor JPG lives. An existing
## surface override wins, since that is what the scene author last chose.
static func _baked_texture(mi: MeshInstance3D, mesh: Mesh, surface: int) -> Texture2D:
	var candidates: Array[Material] = [
		mi.get_surface_override_material(surface),
		mesh.surface_get_material(surface),
	]
	for candidate in candidates:
		var std := candidate as BaseMaterial3D
		if std != null and std.albedo_texture != null:
			return std.albedo_texture
	return null


static func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_mesh_instances(child))
	return out
