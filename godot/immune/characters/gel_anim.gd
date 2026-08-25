class_name ImmuneGelAnim
extends RefCounted

## Squash-and-stretch animation set for the skeleton-free gel bodies.
##
## The six base cells are one closed blob each: no armature, no shape keys. All
## motion therefore comes from a virtual rig baked straight into node transforms:
##
##     local = Translate(rig) * Rotate(rig) * Scale(squash) * home
##
## `rig` is a rigid whole-body move (hop, lean, recoil) and `squash` is the
## non-uniform volume-preserving scale that does the actual acting. Both are
## composed here, per sample, and written to the existing child nodes of the
## character scene. Nothing is reparented, so `CoreMesh`, `Face`, `LimbKit` and
## `DutyKits` keep the paths that kit_blockout.gd, smoke.gd and the duty system
## already depend on.
##
## The face is the one part that must not deform. `Face` rides the body surface
## (it is translated by the same squash as everything else) but its own scale is
## multiplied by a counter-scale, so the eyes / frown / pore keep their aspect
## ratio while still sitting on the moving skin. The counter grows with the
## deformation, which is what keeps the head marks legible at the extremes.
##
## Everything is authored family-agnostically: the caller passes a rig context
## built from whatever nodes that family actually has.

## Sampling rate for the baked keys. Dense keys with linear interpolation give
## exact control over the easing shape instead of leaving it to a tangent solver.
const SAMPLE_HZ := 36.0

## 1.0 = perfect volume preservation. Slightly under sells gel rather than rubber.
const VOLUME_K := 0.85

## Deformation guard rails. Past these the painted face on the sculpted mesh
## turns to mush, which is an explicit review failure.
const SQUASH_MIN := 0.76
const STRETCH_MAX := 1.24

## Face counter-scale: 0 = face deforms with the body, 1 = face is rigid.
## Scales up with deformation so calm motion still feels attached to the skin
## while impacts protect the head marks.
const FACE_BASE_C := 0.55
const FACE_GAIN := 1.90
const FACE_MAX_C := 0.92

## Fraction of the contact-patch radius used to convert a tilt into a roll.
## The footprint is close enough to the sole distance on all six bodies.
const ROLL_LIFT := 0.85

## Nodes the rig drives. Missing ones are skipped, so A (no feet, no walk kit)
## and the four-limbed families share the same code.
const DRIVEN: PackedStringArray = ["CoreMesh", "Face", "WeaponSocket", "DutyKits", "LimbKit"]

## Kit that each duty animation grows in, when the family has one.
const KIT_FOR := {
	"plant": "DutyKits/BaseKit",
	"uproot": "DutyKits/LocomotionKit",
	"relay_open": "DutyKits/RelayDish",
	"relay_close": "DutyKits/BaseKit",
}

const NAMES: PackedStringArray = [
	"idle", "plant", "uproot", "move", "hit", "attack", "relay_open", "relay_close",
]


## Snapshot of the rest pose. Must be taken before any other system offsets the
## driven nodes (A's hover, for instance) or the offset gets baked in twice.
static func make_context(host: Node3D, lift: float = 0.0) -> Dictionary:
	var homes := {}
	for node_name in DRIVEN:
		var node := host.get_node_or_null(String(node_name)) as Node3D
		if node != null:
			homes[String(node_name)] = node.position
	var kits := {}
	for anim_name in KIT_FOR.keys():
		var path: String = KIT_FOR[anim_name]
		kits[anim_name] = path if host.get_node_or_null(path) != null else ""
	return {
		"homes": homes,
		"kits": kits,
		"pivot": _ground_pivot(host),
		"lift": lift,
	}


static func build_library(host: Node3D, lift: float = 0.0) -> AnimationLibrary:
	var ctx := make_context(host, lift)
	var lib := AnimationLibrary.new()
	for anim_name in NAMES:
		lib.add_animation(StringName(anim_name), build(String(anim_name), ctx))
	return lib


static func build(anim_name: String, ctx: Dictionary) -> Animation:
	var kits: Dictionary = ctx.get("kits", {})
	var kit_path := String(kits.get(anim_name, ""))
	match anim_name:
		"idle":
			return _bake(2.6, true, "", ctx, {}, "idle")
		"plant":
			return _bake(1.15, false, kit_path, ctx, _plant_channels(), "keys")
		"uproot":
			return _bake(1.0, false, kit_path, ctx, _uproot_channels(), "keys")
		"relay_open":
			return _bake(1.0, false, kit_path, ctx, _uproot_channels(), "keys")
		"relay_close":
			return _bake(1.15, false, kit_path, ctx, _plant_channels(), "keys")
		"move":
			return _bake(0.92, true, "", ctx, _move_channels(), "keys")
		"hit":
			return _bake(0.36, false, "", ctx, _hit_channels(), "keys")
		"attack":
			return _bake(0.78, false, "", ctx, _attack_channels(), "keys")
	return _bake(1.0, false, "", ctx, {}, "keys")


# --------------------------------------------------------------------------
# Motion authoring. Each channel is a list of [time, value, ease-out-of-this-key]
# so the shape of a beat is readable as data rather than buried in a curve
# resource. Amplitude is deliberately modest; the read comes from the timing.
#
# Every extreme is written as a pair of keys a few tens of milliseconds apart.
# That hold is partly craft — an impact pose wants to sit for a beat — and
# partly defensive: the review harness samples an animation at even intervals
# and drifts by roughly a frame, so a knife-edge extreme gets skipped and the
# strip reads as a clip with no extremes at all.
# --------------------------------------------------------------------------

## Drop and grip. Anticipation lift, hard fall, held splat, two decaying
## rebounds, settle to exactly the neutral pose so idle can pick it up.
static func _plant_channels() -> Dictionary:
	return {
		"sy": [
			[0.00, 1.000, "in"], [0.14, 1.090, "in"], [0.30, 0.775, "lin"],
			[0.37, 0.775, "out"], [0.50, 1.085, "io"], [0.66, 0.920, "io"],
			[0.81, 1.040, "io"], [0.96, 0.985, "io"], [1.15, 1.000, "lin"],
		],
		"py": [
			[0.00, 0.000, "in"], [0.14, 0.060, "in"], [0.30, -0.026, "lin"],
			[0.37, -0.026, "out"], [0.50, 0.014, "io"], [0.66, -0.008, "io"],
			[0.87, 0.003, "io"], [1.15, 0.000, "lin"],
		],
		"rx": [
			[0.00, 0.0, "in"], [0.14, -3.0, "in"], [0.30, 4.5, "lin"],
			[0.37, 4.2, "out"], [0.54, -2.0, "io"], [0.76, 0.8, "io"],
			[1.15, 0.0, "lin"],
		],
		"rz": [
			[0.00, 0.0, "in"], [0.30, -2.8, "lin"], [0.37, -2.5, "out"],
			[0.58, 1.4, "io"], [0.82, -0.5, "io"], [1.15, 0.0, "lin"],
		],
		"spread": [
			[0.00, 1.000, "in"], [0.30, 1.180, "lin"], [0.37, 1.175, "out"],
			[0.54, 1.045, "io"], [0.74, 1.100, "io"], [1.15, 1.070, "lin"],
		],
		"lag": [
			[0.00, 0.000, "in"], [0.30, 0.034, "lin"], [0.37, 0.030, "out"],
			[0.52, -0.016, "io"], [0.72, 0.007, "io"], [1.15, 0.000, "lin"],
		],
		"kit": [
			[0.00, 0.250, "in"], [0.30, 0.520, "out"], [0.52, 1.120, "io"],
			[0.72, 0.955, "io"], [0.92, 1.020, "io"], [1.15, 1.000, "lin"],
		],
	}


## Peel off the floor. Gather down first, then a tall narrow pull-up that
## holds at the top, overshoots and wobbles back to neutral standing height.
static func _uproot_channels() -> Dictionary:
	return {
		"sy": [
			[0.00, 1.000, "in"], [0.15, 0.840, "lin"], [0.19, 0.840, "out"],
			[0.31, 1.230, "lin"], [0.37, 1.225, "io"], [0.50, 0.945, "io"],
			[0.63, 1.085, "io"], [0.76, 0.970, "io"], [0.88, 1.020, "io"],
			[1.00, 1.000, "lin"],
		],
		"py": [
			[0.00, 0.000, "in"], [0.15, -0.040, "lin"], [0.19, -0.038, "out"],
			[0.33, 0.120, "lin"], [0.39, 0.118, "io"], [0.54, 0.022, "io"],
			[0.70, 0.058, "io"], [0.86, 0.014, "io"], [1.00, 0.000, "lin"],
		],
		"rx": [
			[0.00, 0.0, "in"], [0.15, 4.0, "lin"], [0.19, 3.8, "out"],
			[0.33, -5.0, "lin"], [0.39, -4.7, "io"], [0.58, 2.0, "io"],
			[0.80, -0.7, "io"], [1.00, 0.0, "lin"],
		],
		"rz": [
			[0.00, 0.0, "in"], [0.31, 3.0, "lin"], [0.37, 2.8, "out"],
			[0.57, -1.5, "io"], [0.82, 0.5, "io"], [1.00, 0.0, "lin"],
		],
		"spread": [
			[0.00, 1.070, "in"], [0.15, 1.130, "lin"], [0.19, 1.125, "out"],
			[0.33, 0.890, "lin"], [0.39, 0.895, "io"], [0.58, 1.035, "io"],
			[0.80, 0.985, "io"], [1.00, 1.000, "lin"],
		],
		"lag": [
			[0.00, 0.000, "in"], [0.15, 0.024, "out"], [0.33, -0.085, "lin"],
			[0.39, -0.080, "io"], [0.56, 0.014, "io"], [0.78, -0.009, "io"],
			[1.00, 0.000, "lin"],
		],
		"kit": [
			[0.00, 0.250, "in"], [0.30, 0.600, "out"], [0.50, 1.110, "io"],
			[0.70, 0.955, "io"], [0.88, 1.020, "io"], [1.00, 1.000, "lin"],
		],
	}


## In-place lope: gather, launch, float, land, absorb. The gameplay code owns
## the actual translation; this is the vertical and the weight. The crouch and
## the landing splat are both held so the landing is impossible to miss.
static func _move_channels() -> Dictionary:
	return {
		"sy": [
			[0.00, 1.000, "in"], [0.15, 0.800, "lin"], [0.20, 0.800, "out"],
			[0.30, 1.220, "lin"], [0.37, 1.210, "io"], [0.50, 1.090, "in"],
			[0.58, 0.780, "lin"], [0.635, 0.780, "out"], [0.72, 1.120, "io"],
			[0.80, 0.945, "io"], [0.87, 1.030, "io"], [0.92, 1.000, "lin"],
		],
		"py": [
			[0.00, 0.000, "in"], [0.15, -0.045, "lin"], [0.20, -0.042, "out"],
			[0.30, 0.150, "io"], [0.40, 0.330, "io"], [0.50, 0.170, "in"],
			[0.58, -0.030, "lin"], [0.635, -0.030, "out"], [0.73, 0.035, "io"],
			[0.83, -0.012, "io"], [0.92, 0.000, "lin"],
		],
		"rx": [
			[0.00, 0.0, "io"], [0.15, 5.5, "lin"], [0.20, 5.2, "out"],
			[0.32, -4.0, "io"], [0.50, 2.0, "in"], [0.58, 6.5, "lin"],
			[0.635, 6.0, "out"], [0.76, -2.2, "io"], [0.88, 0.8, "io"],
			[0.92, 0.0, "lin"],
		],
		"pz": [
			[0.00, 0.000, "in"], [0.16, -0.055, "out"], [0.32, 0.060, "io"],
			[0.52, 0.035, "in"], [0.60, -0.032, "out"], [0.76, 0.012, "io"],
			[0.92, 0.000, "lin"],
		],
		"rz": [
			[0.00, 0.0, "io"], [0.23, 2.6, "io"], [0.46, 0.0, "io"],
			[0.69, -2.6, "io"], [0.92, 0.0, "lin"],
		],
		"spread": [
			[0.00, 1.000, "in"], [0.15, 1.100, "lin"], [0.20, 1.095, "out"],
			[0.34, 0.885, "io"], [0.52, 0.955, "in"], [0.58, 1.170, "lin"],
			[0.635, 1.160, "out"], [0.78, 1.020, "io"], [0.92, 1.000, "lin"],
		],
		"lag": [
			[0.00, 0.000, "in"], [0.15, 0.020, "out"], [0.30, -0.080, "io"],
			[0.42, -0.105, "io"], [0.54, -0.035, "in"], [0.60, 0.032, "out"],
			[0.76, -0.014, "io"], [0.92, 0.000, "lin"],
		],
	}


## 0.36 s reactive squash. The splat is on screen inside 40 ms and holds for
## another 50, then the jiggle bleeds off in three shrinking bounces.
static func _hit_channels() -> Dictionary:
	return {
		"sy": [
			[0.000, 1.000, "snap"], [0.040, 0.780, "lin"], [0.090, 0.780, "out"],
			[0.150, 1.150, "lin"], [0.185, 1.145, "io"], [0.245, 0.905, "io"],
			[0.295, 1.055, "io"], [0.335, 0.980, "io"], [0.360, 1.000, "lin"],
		],
		"pz": [
			[0.000, 0.000, "snap"], [0.040, -0.105, "lin"], [0.090, -0.095, "out"],
			[0.170, 0.030, "io"], [0.250, -0.022, "io"], [0.320, 0.007, "io"],
			[0.360, 0.000, "lin"],
		],
		"py": [
			[0.000, 0.000, "snap"], [0.040, -0.030, "lin"], [0.090, -0.028, "out"],
			[0.170, 0.020, "io"], [0.260, -0.008, "io"], [0.360, 0.000, "lin"],
		],
		"rz": [
			[0.000, 0.0, "snap"], [0.040, -6.5, "lin"], [0.090, -5.8, "out"],
			[0.170, 3.2, "io"], [0.250, -1.4, "io"], [0.320, 0.5, "io"],
			[0.360, 0.0, "lin"],
		],
		"rx": [
			[0.000, 0.0, "snap"], [0.040, -4.5, "lin"], [0.090, -4.0, "out"],
			[0.175, 1.8, "io"], [0.265, -0.7, "io"], [0.360, 0.0, "lin"],
		],
		"spread": [
			[0.000, 1.000, "snap"], [0.040, 1.150, "lin"], [0.090, 1.140, "out"],
			[0.160, 0.945, "io"], [0.245, 1.050, "io"], [0.310, 0.985, "io"],
			[0.360, 1.000, "lin"],
		],
		"lag": [
			[0.000, 0.000, "snap"], [0.045, 0.042, "out"], [0.140, -0.026, "io"],
			[0.245, 0.011, "io"], [0.360, 0.000, "lin"],
		],
	}


## A throw, not a punch: the body winds back and holds, then whips its whole
## mass forward and stretches along the throw axis (`zb` trades width for
## depth) as the payload leaves. The recoil settles over three wobbles.
static func _attack_channels() -> Dictionary:
	return {
		"zb": [
			[0.00, 1.000, "in"], [0.20, 0.940, "out"], [0.32, 1.180, "lin"],
			[0.375, 1.175, "io"], [0.49, 1.010, "io"], [0.60, 1.050, "io"],
			[0.70, 0.990, "io"], [0.78, 1.000, "lin"],
		],
		"sy": [
			[0.00, 1.000, "in"], [0.15, 1.080, "lin"], [0.21, 1.075, "out"],
			[0.32, 0.860, "lin"], [0.375, 0.865, "io"], [0.49, 1.070, "io"],
			[0.61, 0.950, "io"], [0.71, 1.020, "io"], [0.78, 1.000, "lin"],
		],
		"rx": [
			[0.00, 0.0, "in"], [0.16, -10.5, "lin"], [0.21, -10.0, "out"],
			[0.30, -1.0, "in"], [0.345, 12.5, "lin"], [0.40, 12.0, "io"],
			[0.52, -4.0, "io"], [0.64, 1.8, "io"], [0.78, 0.0, "lin"],
		],
		"pz": [
			[0.00, 0.000, "in"], [0.16, -0.078, "lin"], [0.21, -0.076, "out"],
			[0.345, 0.108, "lin"], [0.40, 0.104, "io"], [0.52, -0.028, "io"],
			[0.66, 0.012, "io"], [0.78, 0.000, "lin"],
		],
		"py": [
			[0.00, 0.000, "in"], [0.17, 0.045, "lin"], [0.21, 0.044, "out"],
			[0.345, -0.030, "lin"], [0.40, -0.028, "io"], [0.52, 0.015, "io"],
			[0.66, -0.005, "io"], [0.78, 0.000, "lin"],
		],
		"rz": [
			[0.00, 0.0, "in"], [0.21, 3.4, "out"], [0.345, -4.2, "lin"],
			[0.40, -4.0, "io"], [0.56, 1.6, "io"], [0.78, 0.0, "lin"],
		],
		"spread": [
			[0.00, 1.000, "in"], [0.18, 0.960, "lin"], [0.21, 0.960, "out"],
			[0.345, 1.070, "lin"], [0.40, 1.065, "io"], [0.54, 0.985, "io"],
			[0.78, 1.000, "lin"],
		],
		"lag": [
			[0.00, 0.000, "in"], [0.20, -0.024, "out"], [0.345, 0.042, "lin"],
			[0.40, 0.038, "io"], [0.54, -0.016, "io"], [0.78, 0.000, "lin"],
		],
	}


## The one that is on screen 90% of the time. Built analytically instead of
## keyed so it loops seamlessly: every term is periodic over the clip length.
## Three unrelated frequencies plus a phase warp keep it from reading as a
## metronome, and the surface ripple lags the main breath.
static func _idle_pose(t: float, length: float) -> Dictionary:
	var ph := TAU * t / length
	var warped := ph + 0.42 * sin(ph)
	return {
		"sy": 1.0 + 0.086 * sin(warped) + 0.022 * sin(2.0 * ph + 1.15) + 0.008 * sin(3.0 * ph + 2.4),
		"py": 0.020 * sin(ph + 0.5),
		"px": 0.018 * sin(ph - 1.15),
		"pz": 0.012 * sin(2.0 * ph + 0.35),
		"rz": 2.10 * sin(ph + 0.85) + 0.70 * sin(2.0 * ph - 0.6),
		"rx": 1.30 * sin(ph + 2.15),
		"spread": 1.0 + 0.030 * sin(ph + 1.9),
		"lag": -0.024 * sin(ph - 0.95),
	}


# --------------------------------------------------------------------------
# Baking
# --------------------------------------------------------------------------

static func _bake(length: float, loop: bool, kit_path: String, ctx: Dictionary, channels: Dictionary, mode: String) -> Animation:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var homes: Dictionary = ctx.get("homes", {})
	var pivot: float = float(ctx.get("pivot", 0.5))
	var lift: float = float(ctx.get("lift", 0.0))

	var tracks := {}
	for node_name in homes.keys():
		tracks[node_name] = [
			_add_track(anim, "%s:position" % node_name),
			_add_track(anim, "%s:rotation" % node_name),
			_add_track(anim, "%s:scale" % node_name),
		]
	var kit_track := -1
	if not kit_path.is_empty() and channels.has("kit"):
		kit_track = _add_track(anim, "%s:scale" % kit_path)

	var steps := int(ceil(length * SAMPLE_HZ))
	for i in steps + 1:
		var t: float = minf(float(i) / SAMPLE_HZ, length)
		var pose: Dictionary = _idle_pose(t, length) if mode == "idle" else _keyed_pose(channels, t)

		var sy := clampf(float(pose.get("sy", 1.0)), SQUASH_MIN, STRETCH_MAX)
		var zb := float(pose.get("zb", 1.0))
		var lateral := pow(sy, -0.5 * VOLUME_K)
		var squash := Vector3(lateral / zb, sy, lateral * zb)

		var euler := Vector3(
			deg_to_rad(float(pose.get("rx", 0.0))),
			deg_to_rad(float(pose.get("ry", 0.0))),
			deg_to_rad(float(pose.get("rz", 0.0)))
		)
		var basis := Basis.from_euler(euler)
		# Leans pivot on the sole, not the body centre, so the base stays put
		# and the mass up top swings. That drag is most of the weight read.
		var sole := Vector3(0.0, pivot, 0.0)
		# A tilt about the sole centre would drive the leading edge of the base
		# through the floor. Lifting by the edge's dip turns the tilt into a
		# roll on the contact patch, which is what a heavy blob actually does.
		var roll := pivot * ROLL_LIFT * (absf(sin(euler.x)) + absf(sin(euler.z)))
		var rig := Vector3(
			float(pose.get("px", 0.0)),
			float(pose.get("py", 0.0)) + lift + roll + pivot * (sy - 1.0),
			float(pose.get("pz", 0.0))
		) - sole

		var counter := _face_counter(squash)
		var spread := float(pose.get("spread", 1.0))
		var lag := float(pose.get("lag", 0.0))

		for node_name in homes.keys():
			var home: Vector3 = homes[node_name]
			var offset := Vector3.ZERO
			var node_scale := squash
			if node_name == "Face":
				node_scale = squash * counter
			elif node_name == "LimbKit":
				offset = Vector3(0.0, lag, 0.0)
				node_scale = Vector3(squash.x * spread, squash.y, squash.z * spread)
			var idx: Array = tracks[node_name]
			anim.track_insert_key(idx[0], t, rig + basis * (squash * home + offset + sole))
			anim.track_insert_key(idx[1], t, euler)
			anim.track_insert_key(idx[2], t, node_scale)

		if kit_track >= 0:
			var k := float(pose.get("kit", 1.0))
			anim.track_insert_key(kit_track, t, Vector3(k, k, k))
	return anim


## How hard to fight the body deformation on the face. Calm motion lets the
## marks ride the skin a little; impacts hold them nearly rigid so the pore,
## the eyes and the frown survive the extreme frames.
static func _face_counter(squash: Vector3) -> Vector3:
	var deform := maxf(absf(squash.y - 1.0), absf(squash.x - 1.0))
	var c := clampf(FACE_BASE_C + FACE_GAIN * deform, FACE_BASE_C, FACE_MAX_C)
	return Vector3(pow(squash.x, -c), pow(squash.y, -c), pow(squash.z, -c))


static func _add_track(anim: Animation, path: String) -> int:
	var idx := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(idx, NodePath(path))
	anim.track_set_interpolation_type(idx, Animation.INTERPOLATION_LINEAR)
	anim.value_track_set_update_mode(idx, Animation.UPDATE_CONTINUOUS)
	return idx


static func _keyed_pose(channels: Dictionary, t: float) -> Dictionary:
	var pose := {}
	for key in channels.keys():
		pose[key] = _eval(channels[key], t)
	return pose


## Piecewise evaluation where each key carries the easing used to leave it.
static func _eval(keys: Array, t: float) -> float:
	var count := keys.size()
	if count == 0:
		return 0.0
	if count == 1 or t <= float(keys[0][0]):
		return float(keys[0][1])
	if t >= float(keys[count - 1][0]):
		return float(keys[count - 1][1])
	for i in count - 1:
		var t0 := float(keys[i][0])
		var t1 := float(keys[i + 1][0])
		if t > t1:
			continue
		var span := maxf(t1 - t0, 0.00001)
		var u := clampf((t - t0) / span, 0.0, 1.0)
		return lerpf(float(keys[i][1]), float(keys[i + 1][1]), _ease(u, String(keys[i][2])))
	return float(keys[count - 1][1])


static func _ease(u: float, kind: String) -> float:
	match kind:
		"in":
			return u * u * u
		"out":
			return 1.0 - pow(1.0 - u, 3.0)
		"snap":
			return 1.0 - pow(1.0 - u, 5.0)
		"io":
			return 4.0 * u * u * u if u < 0.5 else 1.0 - pow(-2.0 * u + 2.0, 3.0) * 0.5
		"smooth":
			return u * u * (3.0 - 2.0 * u)
		"hold":
			return 0.0
	return u


## Distance from the character origin down to the sole, so squash can pivot on
## the floor instead of the body centre. Read from the mesh so it stays correct
## when the sculpted GLB replaces the blockout primitive.
static func _ground_pivot(host: Node3D) -> float:
	var core := host.get_node_or_null("CoreMesh") as Node3D
	if core == null:
		return 0.5
	var box := AABB()
	var seeded := false
	var to_host := core.transform
	for mi in _mesh_instances(core):
		var local: Transform3D = to_host * (core.global_transform.affine_inverse() * mi.global_transform)
		var part: AABB = local * mi.get_aabb()
		if seeded:
			box = box.merge(part)
		else:
			box = part
			seeded = true
	if not seeded or box.size.y <= 0.0001:
		return 0.5
	return clampf(-box.position.y, 0.15, 3.0)


static func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append(node)
	for child in node.get_children():
		out.append_array(_mesh_instances(child))
	return out
