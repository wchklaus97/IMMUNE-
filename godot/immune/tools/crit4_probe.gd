extends Node3D

const _LightContract := preload("res://characters/gel/light_contract.gd")

## ROUND-4 CRITIC ANALYSIS SCAFFOLD -- not production code, delete after review.
##
## An independent copy of tools/shot.gd's stage with the environment terms made
## switchable, so the round-4 claim ("the residual blue floor is ACES + glow, not
## the material") can be tested rather than accepted. shot.gd itself is untouched.
##
## Args: --scene= --out= --tag= [--tonemap=aces|linear] [--glow=1|0]
##       [--lights=all|key|keyfill] [--ambient=1|0] [--white=3.0] [--yaw=0]

const ALLOWED_ARGS: Array[String] = [
	"scene", "out", "tag", "tonemap", "glow", "lights", "ambient", "white", "yaw", "bare",
	"save-path",
]

var _args := {}
var _subject: Node3D
var _pivot: Node3D
var _camera: Camera3D
var _out := ""
var _tag := "probe"
var _scene_path := ""
var _height := 1.0
var _bare := false
var _tonemap := "aces"
var _glow := true
var _lights := "all"
var _ambient := true
var _white := 3.0
var _yaw := 0.0


func _ready() -> void:
	if _quit_for_qa_startup_failure():
		return
	if not _parse_args():
		get_tree().quit(2)
		return
	if not _validate_args():
		get_tree().quit(2)
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(_out)
	if directory_error != OK:
		push_error("crit4_probe: cannot create output directory %s (%d)" % [_out, directory_error])
		get_tree().quit(2)
		return
	# --bare: add no environment, no lights and no camera, so a scene that owns its
	# own stage (scenes/kit_lock_preview.tscn, scenes/combat_lane.tscn) renders under
	# the environment the GAME actually uses rather than the review harness's.
	if not _bare:
		_stage()
	else:
		_pivot = Node3D.new()
		add_child(_pivot)
	if not await _load():
		get_tree().quit(3)
		return
	var light_error := _LightContract.error(self, "critic probe rig")
	if not light_error.is_empty():
		push_error(light_error)
		get_tree().quit(4)
		return
	if not _bare:
		_pivot.rotation_degrees = Vector3(0.0, _yaw, 0.0)
		_camera.position = Vector3(0.0, _height * 1.30, _height * 3.05)
		_camera.look_at(Vector3(0.0, _height * 0.46, 0.0), Vector3.UP)
		_camera.fov = 32.0
	for _i in 6:
		await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := _out.path_join("%s.png" % _tag)
	if img == null or img.is_empty():
		push_error("crit4_probe: viewport returned no image for %s" % path)
		get_tree().quit(5)
		return
	var expected_size := img.get_size()
	var save_error := img.save_png(path)
	if save_error != OK:
		push_error("crit4_probe: cannot save %s (%d)" % [path, save_error])
		get_tree().quit(5)
		return
	var reopened := Image.load_from_file(path)
	if reopened == null or reopened.is_empty() or reopened.get_size() != expected_size:
		push_error("crit4_probe: saved PNG cannot be reopened at expected size: %s" % path)
		get_tree().quit(5)
		return
	print("PROBE %s tonemap=%s glow=%s lights=%s ambient=%s" % [
		path, _tonemap, "1" if _glow else "0", _lights, "1" if _ambient else "0"])
	get_tree().quit(0)


func _parse_args() -> bool:
	for raw_arg: String in OS.get_cmdline_user_args():
		var arg := raw_arg.strip_edges()
		if not arg.begins_with("--") or arg == "--":
			push_error("crit4_probe: positional or malformed argument: %s" % raw_arg)
			return false
		var pair := arg.trim_prefix("--").split("=", true, 1)
		var key := String(pair[0]).strip_edges()
		if key not in ALLOWED_ARGS:
			push_error("crit4_probe: unknown option --%s" % key)
			return false
		if _args.has(key):
			push_error("crit4_probe: duplicate option --%s" % key)
			return false
		if pair.size() == 2:
			var value := String(pair[1]).strip_edges()
			if value.is_empty():
				push_error("crit4_probe: --%s cannot be empty" % key)
				return false
			_args[key] = value
		elif pair.size() == 1:
			if key != "bare":
				push_error("crit4_probe: --%s requires =<value>" % key)
				return false
			_args[key] = "1"
	return true


func _validate_args() -> bool:
	_out = String(_args.get("out", "")).strip_edges()
	if _out.is_empty():
		push_error("crit4_probe: --out required")
		return false
	_scene_path = String(_args.get("scene", "")).strip_edges()
	if _scene_path.is_empty():
		push_error("crit4_probe: --scene required")
		return false
	_tag = String(_args.get("tag", "probe")).strip_edges()
	if _tag.is_empty() or _tag.contains("/") or _tag.contains("\\"):
		push_error("crit4_probe: --tag must be a non-empty file-name component")
		return false
	_tonemap = String(_args.get("tonemap", "aces")).strip_edges().to_lower()
	if _tonemap not in ["aces", "linear"]:
		push_error("crit4_probe: --tonemap must be aces or linear")
		return false
	_lights = String(_args.get("lights", "all")).strip_edges().to_lower()
	if _lights not in ["all", "key", "keyfill"]:
		push_error("crit4_probe: --lights must be all, key, or keyfill")
		return false
	var glow_value := _parse_binary("glow", String(_args.get("glow", "1")))
	if not bool(glow_value.get("ok", false)):
		return false
	_glow = bool(glow_value["value"])
	var ambient_value := _parse_binary("ambient", String(_args.get("ambient", "1")))
	if not bool(ambient_value.get("ok", false)):
		return false
	_ambient = bool(ambient_value["value"])
	var bare_value := _parse_binary("bare", String(_args.get("bare", "0")))
	if not bool(bare_value.get("ok", false)):
		return false
	_bare = bool(bare_value["value"])
	var white_value := _parse_finite_float("white", String(_args.get("white", "3.0")))
	if not bool(white_value.get("ok", false)):
		return false
	_white = float(white_value["value"])
	if _white <= 0.0:
		push_error("crit4_probe: --white must be greater than zero")
		return false
	var yaw_value := _parse_finite_float("yaw", String(_args.get("yaw", "0")))
	if not bool(yaw_value.get("ok", false)):
		return false
	_yaw = float(yaw_value["value"])
	return true


func _parse_binary(option: String, raw_value: String) -> Dictionary:
	var value := raw_value.strip_edges()
	if value not in ["0", "1"]:
		push_error("crit4_probe: --%s must be 0 or 1" % option)
		return {"ok": false}
	return {"ok": true, "value": value == "1"}


func _parse_finite_float(option: String, raw_value: String) -> Dictionary:
	var trimmed := raw_value.strip_edges()
	if trimmed.is_empty() or not trimmed.is_valid_float():
		push_error("crit4_probe: --%s requires a finite number" % option)
		return {"ok": false}
	var value := float(trimmed)
	if not is_finite(value):
		push_error("crit4_probe: --%s requires a finite number" % option)
		return {"ok": false}
	return {"ok": true, "value": value}


func _stage() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.016)
	if _ambient:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.30, 0.38, 0.50)
		env.ambient_light_energy = 0.45
	else:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	if _tonemap == "aces":
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
	else:
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_white = _white
	env.ssao_enabled = true
	env.ssao_intensity = 1.1
	if _glow:
		env.glow_enabled = true
		env.glow_intensity = 0.5
		env.glow_bloom = 0.12
	world.environment = env
	add_child(world)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38.0, 34.0, 0.0)
	key.light_energy = 2.1
	key.light_color = Color(1.0, 0.97, 0.92)
	key.shadow_enabled = true
	add_child(key)
	if _lights == "all" or _lights == "keyfill":
		var fill := DirectionalLight3D.new()
		fill.rotation_degrees = Vector3(-12.0, -62.0, 0.0)
		fill.light_energy = 0.55
		fill.light_color = Color(0.55, 0.72, 1.0)
		add_child(fill)
	if _lights == "all":
		var rim := DirectionalLight3D.new()
		rim.rotation_degrees = Vector3(-8.0, 168.0, 0.0)
		rim.light_energy = 1.4
		rim.light_color = Color(0.70, 0.86, 1.0)
		add_child(rim)

	_pivot = Node3D.new()
	add_child(_pivot)
	_camera = Camera3D.new()
	_camera.current = true
	add_child(_camera)


func _load() -> bool:
	var packed := load(_scene_path) as PackedScene
	if packed == null:
		push_error("crit4_probe: bad scene")
		return false
	_subject = packed.instantiate() as Node3D
	if _subject == null:
		return false
	_pivot.add_child(_subject)
	await get_tree().process_frame
	if _bare:
		return true
	var aabb := _aabb(_subject)
	_height = maxf(aabb.size.y, 0.001)
	var c := aabb.get_center()
	_subject.position -= Vector3(c.x, aabb.position.y, c.z)
	return true


func _aabb(node: Node) -> AABB:
	var out := AABB()
	var seeded := false
	for mi in _meshes(node):
		var box := mi.global_transform * mi.get_aabb()
		if seeded:
			out = out.merge(box)
		else:
			out = box
			seeded = true
	return out


func _meshes(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_meshes(child))
	return out


func _quit_for_qa_startup_failure() -> bool:
	if not ResearchState.has_method("qa_startup_failed"):
		return false
	if not bool(ResearchState.call("qa_startup_failed")):
		return false
	var exit_code := 74
	if ResearchState.has_method("qa_startup_failure_exit_code"):
		exit_code = int(ResearchState.call("qa_startup_failure_exit_code"))
	get_tree().quit(exit_code)
	return true
