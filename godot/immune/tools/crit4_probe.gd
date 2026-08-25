extends Node3D

## ROUND-4 CRITIC ANALYSIS SCAFFOLD -- not production code, delete after review.
##
## An independent copy of tools/shot.gd's stage with the environment terms made
## switchable, so the round-4 claim ("the residual blue floor is ACES + glow, not
## the material") can be tested rather than accepted. shot.gd itself is untouched.
##
## Args: --scene= --out= --tag= [--tonemap=aces|linear] [--glow=1|0]
##       [--lights=all|key|keyfill] [--ambient=1|0] [--white=3.0] [--yaw=0]

var _args := {}
var _subject: Node3D
var _pivot: Node3D
var _camera: Camera3D
var _out := ""
var _tag := "probe"
var _height := 1.0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2:
			_args[pair[0]] = pair[1]
		elif pair.size() == 1:
			_args[pair[0]] = "1"
	_out = String(_args.get("out", ""))
	_tag = String(_args.get("tag", "probe"))
	if _out.is_empty():
		push_error("crit4_probe: --out required")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	# --bare: add no environment, no lights and no camera, so a scene that owns its
	# own stage (scenes/kit_lock_preview.tscn, scenes/combat_lane.tscn) renders under
	# the environment the GAME actually uses rather than the review harness's.
	var bare := String(_args.get("bare", "0")) == "1"
	if not bare:
		_stage()
	else:
		_pivot = Node3D.new()
		add_child(_pivot)
	if not await _load():
		get_tree().quit(3)
		return
	if not bare:
		_pivot.rotation_degrees = Vector3(0.0, float(_args.get("yaw", "0")), 0.0)
		_camera.position = Vector3(0.0, _height * 1.30, _height * 3.05)
		_camera.look_at(Vector3(0.0, _height * 0.46, 0.0), Vector3.UP)
		_camera.fov = 32.0
	for _i in 6:
		await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := _out.path_join("%s.png" % _tag)
	img.save_png(path)
	print("PROBE %s tonemap=%s glow=%s lights=%s ambient=%s" % [
		path, _args.get("tonemap", "aces"), _args.get("glow", "1"),
		_args.get("lights", "all"), _args.get("ambient", "1")])
	get_tree().quit(0)


func _stage() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.016)
	if String(_args.get("ambient", "1")) == "1":
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.30, 0.38, 0.50)
		env.ambient_light_energy = 0.45
	else:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	if String(_args.get("tonemap", "aces")) == "aces":
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
	else:
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_white = float(_args.get("white", "3.0"))
	env.ssao_enabled = true
	env.ssao_intensity = 1.1
	if String(_args.get("glow", "1")) == "1":
		env.glow_enabled = true
		env.glow_intensity = 0.5
		env.glow_bloom = 0.12
	world.environment = env
	add_child(world)

	var mode := String(_args.get("lights", "all"))
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38.0, 34.0, 0.0)
	key.light_energy = 2.1
	key.light_color = Color(1.0, 0.97, 0.92)
	key.shadow_enabled = true
	add_child(key)
	if mode == "all" or mode == "keyfill":
		var fill := DirectionalLight3D.new()
		fill.rotation_degrees = Vector3(-12.0, -62.0, 0.0)
		fill.light_energy = 0.55
		fill.light_color = Color(0.55, 0.72, 1.0)
		add_child(fill)
	if mode == "all":
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
	var packed := load(String(_args.get("scene", ""))) as PackedScene
	if packed == null:
		push_error("crit4_probe: bad scene")
		return false
	_subject = packed.instantiate() as Node3D
	if _subject == null:
		return false
	_pivot.add_child(_subject)
	await get_tree().process_frame
	if String(_args.get("bare", "0")) == "1":
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
