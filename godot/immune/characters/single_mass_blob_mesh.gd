class_name ImmuneSingleMassBlobMesh
extends RefCounted

## Deterministic, watertight V8.3/V8.4 character surface.
##
## Earlier authored bodies overlapped independent sphere primitives for the
## torso, arms, feet, and D crown. That construction looked acceptable at rest,
## but animation exposed intersections and let appendages read as loose cells.
## This generator keeps every family star-shaped around one origin and sculpts
## broad silhouette cues directly into one indexed surface.

const RADIAL_SEGMENTS := 96
const RINGS := 48

const _PROFILES: Dictionary = {
	"T": {
		"radii": Vector3(0.505, 0.500, 0.500),
		"arms": 0.285,
		"feet": 0.180,
		"skirt": 0.050,
		"top": 0.000,
	},
	"B": {
		"radii": Vector3(0.505, 0.500, 0.500),
		"arms": 0.260,
		"feet": 0.170,
		"skirt": 0.052,
		"top": 0.000,
	},
	"M": {
		"radii": Vector3(0.555, 0.550, 0.540),
		"arms": 0.280,
		"feet": 0.190,
		"skirt": 0.060,
		"top": 0.018,
	},
	"N": {
		"radii": Vector3(0.505, 0.505, 0.500),
		"arms": 0.240,
		"feet": 0.155,
		"skirt": 0.048,
		"top": 0.000,
	},
	"A": {
		"radii": Vector3(0.510, 0.510, 0.505),
		"arms": 0.225,
		"feet": 0.000,
		"skirt": 0.025,
		"top": 0.010,
	},
	"D": {
		"radii": Vector3(0.515, 0.515, 0.505),
		"arms": 0.255,
		"feet": 0.170,
		"skirt": 0.050,
		"top": 0.095,
	},
}

# V8.4 keeps the exact same closed topology and index count, but moves the
# envelope toward the taller reference silhouette. Wider, softer angular kernels
# read as arms/lower lobes while remaining part of the one radial surface.
const _V8_4_PROFILES: Dictionary = {
	"T": {
		"radii": Vector3(0.490, 0.580, 0.490),
		"arms": 1.000,
		"feet": 0.380,
		"skirt": 0.035,
		"top": 0.000,
		"arm_power": 8.0,
		"foot_power": 18.0,
		"side_notch": 0.24,
	},
	"B": {
		"radii": Vector3(0.500, 0.550, 0.505),
		"arms": 0.880,
		"feet": 0.320,
		"skirt": 0.057,
		"top": 0.000,
		"arm_power": 8.0,
		"foot_power": 17.0,
		"side_notch": 0.20,
	},
	"M": {
		"radii": Vector3(0.555, 0.610, 0.545),
		"arms": 0.900,
		"feet": 0.340,
		"skirt": 0.064,
		"top": 0.018,
		"arm_power": 8.0,
		"foot_power": 17.0,
		"side_notch": 0.20,
	},
	"N": {
		"radii": Vector3(0.495, 0.555, 0.500),
		"arms": 0.840,
		"feet": 0.300,
		"skirt": 0.052,
		"top": 0.000,
		"arm_power": 8.0,
		"foot_power": 17.0,
		"side_notch": 0.19,
	},
	"A": {
		"radii": Vector3(0.500, 0.550, 0.505),
		"arms": 0.780,
		"feet": 0.000,
		"skirt": 0.030,
		"top": 0.010,
		"arm_power": 8.0,
		"foot_power": 17.0,
		"side_notch": 0.12,
	},
	"D": {
		"radii": Vector3(0.510, 0.570, 0.510),
		"arms": 0.860,
		"feet": 0.320,
		"skirt": 0.055,
		"top": 0.090,
		"arm_power": 8.0,
		"foot_power": 17.0,
		"side_notch": 0.19,
	},
}

const _CENTRES: Dictionary = {
	"T": Vector3(0.0, 0.500, 0.0),
	"B": Vector3(0.0, 0.500, 0.0),
	"M": Vector3(0.0, 0.550, 0.0),
	"N": Vector3(0.0, 0.505, 0.0),
	"A": Vector3(0.0, 0.530, 0.0),
	"D": Vector3(0.0, 0.515, 0.0),
}

const _V8_4_CENTRES: Dictionary = {
	"T": Vector3(0.0, 0.580, 0.0),
	"B": Vector3(0.0, 0.550, 0.0),
	"M": Vector3(0.0, 0.610, 0.0),
	"N": Vector3(0.0, 0.555, 0.0),
	"A": Vector3(0.0, 0.570, 0.0),
	"D": Vector3(0.0, 0.570, 0.0),
}

static var _cache: Dictionary = {}


static func mesh(family: String, revision: String = "v8_3") -> ArrayMesh:
	var profiles := _V8_4_PROFILES if revision == "v8_4" else _PROFILES
	var resolved := family if profiles.has(family) else "N"
	var cache_key := "%s:%s" % [revision, resolved]
	if _cache.has(cache_key):
		return _cache[cache_key] as ArrayMesh
	var generated := _build(resolved, revision)
	_cache[cache_key] = generated
	return generated


static func centre(family: String, revision: String = "v8_3") -> Vector3:
	var centres := _V8_4_CENTRES if revision == "v8_4" else _CENTRES
	return centres.get(family, centres["N"])


static func _build(family: String, revision: String) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The wet-gel shader is object-space/triplanar, so this surface needs no UV
	# seam. One shared top vertex, closed intermediate rings, and one shared sole
	# vertex produce an actually connected manifold rather than coincident edges.
	surface.add_vertex(_sculpt(Vector3.UP, family, revision))
	for ring in range(1, RINGS):
		var v := float(ring) / float(RINGS)
		var latitude := PI * v
		var planar := sin(latitude)
		var y := cos(latitude)
		for segment in RADIAL_SEGMENTS:
			var u := float(segment) / float(RADIAL_SEGMENTS)
			var longitude := TAU * u
			var direction := Vector3(
				planar * cos(longitude),
				y,
				planar * sin(longitude)
			)
			surface.add_vertex(_sculpt(direction, family, revision))
	var bottom_index := 1 + (RINGS - 1) * RADIAL_SEGMENTS
	surface.add_vertex(_sculpt(Vector3.DOWN, family, revision))

	# Upper cap.
	for segment in RADIAL_SEGMENTS:
		var current := 1 + segment
		var next := 1 + (segment + 1) % RADIAL_SEGMENTS
		surface.add_index(0)
		surface.add_index(next)
		surface.add_index(current)

	# Connected middle bands.
	for ring in range(RINGS - 2):
		var upper_start := 1 + ring * RADIAL_SEGMENTS
		var lower_start := upper_start + RADIAL_SEGMENTS
		for segment in RADIAL_SEGMENTS:
			var next_segment := (segment + 1) % RADIAL_SEGMENTS
			var a := upper_start + segment
			var b := upper_start + next_segment
			var c := lower_start + segment
			var d := lower_start + next_segment
			surface.add_index(a)
			surface.add_index(b)
			surface.add_index(c)
			surface.add_index(b)
			surface.add_index(d)
			surface.add_index(c)

	# Lower cap.
	var last_ring_start := 1 + (RINGS - 2) * RADIAL_SEGMENTS
	for segment in RADIAL_SEGMENTS:
		var current := last_ring_start + segment
		var next := last_ring_start + (segment + 1) % RADIAL_SEGMENTS
		surface.add_index(bottom_index)
		surface.add_index(current)
		surface.add_index(next)
	surface.generate_normals()
	var result := surface.commit() as ArrayMesh
	result.resource_name = "%s-SingleMass-%s" % [
		"V8.4" if revision == "v8_4" else "V8.3",
		family,
	]
	return result


static func _sculpt(direction: Vector3, family: String, revision: String) -> Vector3:
	var profiles := _V8_4_PROFILES if revision == "v8_4" else _PROFILES
	var profile: Dictionary = profiles.get(family, profiles["N"])
	var radii: Vector3 = profile["radii"]
	var point := direction * radii

	# A broad lower skirt gives a planted slime contact patch without producing
	# individual bead-like toes. A keeps a quieter taper because it hovers.
	var lower := smoothstep(0.05, 0.94, -direction.y)
	var skirt := float(profile["skirt"]) * lower * lower
	point.x *= 1.0 + skirt
	point.z *= 1.0 + skirt * 0.62

	# Side lobes are deliberately broad, low-amplitude angular fields. V8.4 uses
	# a shoulder plus a lower tip kernel so the silhouette reads as a soft hooked
	# arm rather than a triangular ghost skirt. Both fields deform this same
	# radial surface; there are still no appendage nodes or disconnected islands.
	var arm_drop := -0.25 if revision == "v8_4" else -0.17
	var arm_l := Vector3(-0.97 if revision == "v8_4" else -0.985, arm_drop, 0.0).normalized()
	var arm_r := Vector3(0.97 if revision == "v8_4" else 0.985, arm_drop, 0.0).normalized()
	var arms := (
		pow(maxf(direction.dot(arm_l), 0.0), float(profile.get("arm_power", 14.0)))
		+ pow(maxf(direction.dot(arm_r), 0.0), float(profile.get("arm_power", 14.0)))
	)
	if revision == "v8_4":
		var arm_tip_l := Vector3(-0.84, -0.54, 0.0).normalized()
		var arm_tip_r := Vector3(0.84, -0.54, 0.0).normalized()
		var arm_tips := (
			pow(maxf(direction.dot(arm_tip_l), 0.0), 16.0)
			+ pow(maxf(direction.dot(arm_tip_r), 0.0), 16.0)
		)
		var arm_strength := float(profile["arms"])
		point *= 1.0 + arm_strength * (0.12 * arms + 0.34 * arm_tips)
	else:
		point.x *= 1.0 + float(profile["arms"]) * arms

	# The two lower bulges are subtle continuations of the skirt, not separate
	# feet. Their wide kernels preserve the mascot stance without a pinched seam.
	var feet_strength := float(profile["feet"])
	if feet_strength > 0.0:
		var foot_l := Vector3(-0.55, -0.84, 0.05).normalized() if revision == "v8_4" else Vector3(-0.42, -0.90, 0.08).normalized()
		var foot_r := Vector3(0.55, -0.84, 0.05).normalized() if revision == "v8_4" else Vector3(0.42, -0.90, 0.08).normalized()
		var foot_power := float(profile.get("foot_power", 14.0))
		var feet := (
			pow(maxf(direction.dot(foot_l), 0.0), foot_power)
			+ pow(maxf(direction.dot(foot_r), 0.0), foot_power)
		)
		if revision == "v8_4":
			point.x *= 1.0 + feet_strength * 2.80 * feet
			point.y *= 1.0 + feet_strength * 0.75 * feet
			point.z *= 1.0 + feet_strength * 0.32 * feet
		else:
			point.x *= 1.0 + feet_strength * 1.15 * feet
			point.y *= 1.0 + feet_strength * 0.32 * feet
			point.z *= 1.0 + feet_strength * 0.35 * feet

	# A local inward fold between each side lobe and foot gives the continuous
	# surface a readable under-arm gap. It is a radial indentation in this same
	# manifold, never a cut, boolean island, or separately moving appendage.
	if revision == "v8_4":
		var notch_l := Vector3(-0.72, -0.69, 0.0).normalized()
		var notch_r := Vector3(0.72, -0.69, 0.0).normalized()
		var side_notch := (
			pow(maxf(direction.dot(notch_l), 0.0), 16.0)
			+ pow(maxf(direction.dot(notch_r), 0.0), 16.0)
		)
		var notch_strength := float(profile.get("side_notch", 0.0)) * side_notch
		point *= 1.0 - notch_strength

	# D keeps a restrained continuous crown ridge. It deforms the upper envelope
	# itself rather than spawning five free-standing spheres.
	var top_strength := float(profile["top"])
	if top_strength > 0.0:
		var upper := smoothstep(0.48, 0.96, direction.y)
		var angle := atan2(direction.z, direction.x)
		var ridge := 0.76 + 0.24 * cos(3.0 * angle)
		point *= 1.0 + top_strength * upper * upper * ridge

	# Round the extreme sole into one continuous pad. This leaves a strictly
	# positive, non-self-intersecting star surface while avoiding a needle point.
	if direction.y < (-0.76 if revision == "v8_4" else -0.82):
		var sole_blend := smoothstep(0.76 if revision == "v8_4" else 0.82, 1.0, -direction.y)
		if revision == "v8_4":
			point.y = lerpf(point.y, -radii.y * 0.985, sole_blend * 0.84)
		else:
			point.y = lerpf(point.y, -radii.y * 0.985, sole_blend * 0.72)
	if revision == "v8_4":
		# A broad centre lift creates the reference's rounded arch between two
		# planted pads. The x gate fades before either foot direction, avoiding the
		# pointed star shape produced by moving only the shared bottom vertex.
		var arch_vertical := smoothstep(0.62, 0.98, -direction.y)
		var arch_centre := 1.0 - smoothstep(0.10, 0.48, absf(direction.x))
		point.y += radii.y * 0.26 * arch_vertical * arch_centre
	return point
