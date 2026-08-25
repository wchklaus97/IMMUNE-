extends Node3D

## Headed screenshot rig for character review.
## Run: godot --path <proj> --resolution 1024x1024 res://tools/shot.tscn -- --scene=<res path> --out=<abs dir> [--tag=name] [--anim=idle] [--frames=8]
## Renders 3/4, front, side, back, plus a face close-up so a reviewer can judge
## the head marks against the 2D concept without opening the editor.

const SHOTS := [
	{"name": "34", "yaw": 35.0, "face": false},
	{"name": "front", "yaw": 0.0, "face": false},
	{"name": "side", "yaw": 90.0, "face": false},
	{"name": "back", "yaw": 180.0, "face": false},
	{"name": "face", "yaw": 0.0, "face": true},
	{"name": "face34", "yaw": 30.0, "face": true},
]

var _args := {}
var _subject: Node3D
var _pivot: Node3D
var _camera: Camera3D
var _out_dir := ""
var _tag := "shot"
var _height := 1.0


func _ready() -> void:
	_parse_args()
	_out_dir = String(_args.get("out", ""))
	_tag = String(_args.get("tag", "shot"))
	if _out_dir.is_empty():
		push_error("shot.gd: --out=<dir> required")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_build_stage()
	var loaded: bool = await _load_subject()
	if not loaded:
		get_tree().quit(3)
		return
	await _run()
	get_tree().quit(0)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2:
			_args[pair[0]] = pair[1]
		elif pair.size() == 1:
			_args[pair[0]] = "1"


func _build_stage() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.016)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.30, 0.38, 0.50)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 3.0
	env.ssao_enabled = true
	env.ssao_intensity = 1.1
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

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-12.0, -62.0, 0.0)
	fill.light_energy = 0.55
	fill.light_color = Color(0.55, 0.72, 1.0)
	add_child(fill)

	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-8.0, 168.0, 0.0)
	rim.light_energy = 1.4
	rim.light_color = Color(0.70, 0.86, 1.0)
	add_child(rim)

	_pivot = Node3D.new()
	add_child(_pivot)

	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = 32.0
	add_child(_camera)


func _load_subject() -> bool:
	var scene_path := String(_args.get("scene", ""))
	if scene_path.is_empty():
		push_error("shot.gd: --scene=<res://...> required")
		return false
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("shot.gd: cannot load %s" % scene_path)
		return false
	var node := packed.instantiate()
	if node is not Node3D:
		push_error("shot.gd: %s is not Node3D" % scene_path)
		return false
	_subject = node
	_pivot.add_child(_subject)
	await get_tree().process_frame
	_frame_subject()
	return true


## Centers the model on the pivot and records its height so the camera
## framing does not depend on whatever scale the exporter happened to use.
func _frame_subject() -> void:
	var aabb := _world_aabb(_subject)
	if aabb.size == Vector3.ZERO:
		aabb = AABB(Vector3(-0.5, 0.0, -0.5), Vector3.ONE)
	_height = maxf(aabb.size.y, 0.001)
	var centre := aabb.get_center()
	_subject.position -= Vector3(centre.x, aabb.position.y, centre.z)


func _world_aabb(node: Node) -> AABB:
	var out := AABB()
	var seeded := false
	for mi in _all_mesh_instances(node):
		var box := mi.global_transform * mi.get_aabb()
		if seeded:
			out = out.merge(box)
		else:
			out = box
			seeded = true
	return out


func _all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_all_mesh_instances(child))
	return out


func _place_camera(face: bool) -> void:
	if face:
		# Eye-level close-up on the head so forehead marks read clearly.
		var eye_y := _height * 0.80
		_camera.position = Vector3(0.0, eye_y, _height * 1.15)
		_camera.look_at(Vector3(0.0, eye_y, 0.0), Vector3.UP)
		_camera.fov = 30.0
	else:
		_camera.position = Vector3(0.0, _height * 1.30, _height * 3.05)
		_camera.look_at(Vector3(0.0, _height * 0.46, 0.0), Vector3.UP)
		_camera.fov = 32.0


func _run() -> void:
	var anim_name := String(_args.get("anim", ""))
	if anim_name.is_empty():
		for shot in SHOTS:
			_pivot.rotation_degrees = Vector3(0.0, float(shot["yaw"]), 0.0)
			_place_camera(bool(shot["face"]))
			await _save("%s-%s.png" % [_tag, shot["name"]])
	else:
		await _run_anim(anim_name)


## Samples an animation at even intervals so a reviewer sees the motion arc,
## not just one lucky frame.
func _run_anim(anim_name: String) -> void:
	var player := _find_player(_subject)
	if player == null:
		push_error("shot.gd: no AnimationPlayer under subject")
		return
	if not player.has_animation(anim_name):
		push_error("shot.gd: no animation '%s' (have: %s)" % [anim_name, ", ".join(player.get_animation_list())])
		return
	var frames := int(_args.get("frames", "8"))
	frames = clampi(frames, 2, 32)
	var length := player.get_animation(anim_name).length
	_pivot.rotation_degrees = Vector3(0.0, 35.0, 0.0)
	_place_camera(false)
	player.play(anim_name)
	for i in frames:
		var t := length * float(i) / float(frames)
		player.seek(t, true, true)
		await _save("%s-%s-%02d.png" % [_tag, anim_name, i])


func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null


func _save(file_name: String) -> void:
	# Two frames: one to apply transforms, one so the drawn buffer matches them.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := _out_dir.path_join(file_name)
	var err := image.save_png(path)
	if err == OK:
		print("SHOT %s" % path)
	else:
		push_error("shot.gd: save failed %s (%d)" % [path, err])
