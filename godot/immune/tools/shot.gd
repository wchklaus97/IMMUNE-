extends Node3D

const _LightContract := preload("res://characters/gel/light_contract.gd")
const _GelStudio := preload("res://characters/gel/gel_studio_environment.gd")

## Headed screenshot rig for character review.
## Run: godot --path <proj> --resolution 1024x1024 res://tools/shot.tscn -- --scene=<res path> --out=<abs dir> [--tag=name] [--anim=idle] [--frames=8]
## Look-dev: add [--height-scale=0.75] [--height-depth=0.016]
## and/or [--yaw-sequence=0,0.5,1.0] for deterministic full-body yaw samples.
## Renders 3/4, front, side, back, plus a face close-up so a reviewer can judge
## the head marks against the 2D concept without opening the editor.

const ALLOWED_ARGS: Array[String] = [
	# Harness-owned controls.
	"scene", "out", "tag", "anim", "frames", "height-scale", "height-depth",
	"yaw-sequence", "save-path",
	# Intentional subject passthrough documented by gel_preview, anim_preview, and
	# the accepted M reference-body review scene.
	"family", "mesh", "set", "body", "ground", "variant",
]
const QA_STARTUP_FAILURE_EXIT_CODE := 74
const VALID_PREVIEW_FAMILIES: Array[String] = ["T", "B", "M", "N", "A", "D"]
const GEL_PREVIEW_SCENE := "res://tools/gel_preview.tscn"
const ANIM_PREVIEW_SCENE := "res://tools/anim_preview.tscn"
const M_REFERENCE_SCENES: Array[String] = [
	"res://tools/m_reference_match.tscn",
	"res://characters/base_m/reference_body.tscn",
]
const SUBJECT_PASSTHROUGH_ARGS: Array[String] = [
	"family", "mesh", "set", "body", "ground", "variant",
]
const IMAGE_SAMPLE_GRID := 16
const IMAGE_MIN_VISIBLE_SAMPLES := 16
const IMAGE_MIN_BRIGHT_SAMPLES := 4
const IMAGE_MIN_PEAK_LUMA := 0.04
const IMAGE_MIN_LUMA_RANGE := 0.02
const IMAGE_MIN_COLOUR_RANGE := 0.025
const IMAGE_MIN_LUMA_VARIANCE := 0.00002

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
var _yaw_sequence: Array[float] = []
var _height_overrides := {}
var _animation_frames := 8


func _ready() -> void:
	if _abort_for_qa_startup_failure():
		return
	if not _parse_args():
		get_tree().quit(2)
		return
	_out_dir = String(_args.get("out", ""))
	_tag = String(_args.get("tag", "shot"))
	if not _validate_lookdev_args():
		get_tree().quit(2)
		return
	if _out_dir.is_empty():
		push_error("shot.gd: --out=<dir> required")
		get_tree().quit(2)
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(_out_dir)
	if directory_error != OK:
		push_error("shot.gd: cannot create output directory %s (%d)" % [_out_dir, directory_error])
		get_tree().quit(2)
		return
	_build_stage()
	var loaded: bool = await _load_subject()
	if not loaded:
		get_tree().quit(3)
		return
	if not _apply_height_overrides():
		get_tree().quit(3)
		return
	await get_tree().process_frame
	var light_error := _LightContract.error(self, "shot rig")
	if not light_error.is_empty():
		push_error(light_error)
		get_tree().quit(4)
		return
	var evidence_ok: bool = await _run()
	get_tree().quit(0 if evidence_ok else 5)


func _parse_args() -> bool:
	_args.clear()
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			push_error("shot.gd: unexpected positional argument '%s'" % arg)
			return false
		var pair := arg.trim_prefix("--").split("=", true, 1)
		var key := String(pair[0])
		if key not in ALLOWED_ARGS:
			push_error("shot.gd: unknown option --%s" % key)
			return false
		if _args.has(key):
			push_error("shot.gd: duplicate option --%s" % key)
			return false
		if pair.size() != 2:
			push_error("shot.gd: --%s requires a value" % key)
			return false
		_args[key] = pair[1]
	return true


func _validate_lookdev_args() -> bool:
	if not _is_safe_tag(_tag):
		push_error(
			"shot.gd: --tag must be a non-empty safe filename component using only "
			+ "letters, digits, '_', '-', or single interior '.' characters"
		)
		return false
	if _args.has("anim"):
		var animation_name := String(_args["anim"]).strip_edges()
		if animation_name.is_empty():
			push_error("shot.gd: --anim requires a non-empty animation name")
			return false
		_args["anim"] = animation_name
	if _args.has("frames") and not _args.has("anim"):
		push_error("shot.gd: --frames requires --anim")
		return false
	if _args.has("frames"):
		var raw_frames := String(_args["frames"]).strip_edges()
		if raw_frames.is_empty() or not raw_frames.is_valid_int():
			push_error("shot.gd: --frames requires an integer between 2 and 32")
			return false
		_animation_frames = int(raw_frames)
		if _animation_frames < 2 or _animation_frames > 32:
			push_error("shot.gd: --frames must be between 2 and 32")
			return false
	if _args.has("anim") and _args.has("yaw-sequence"):
		push_error("shot.gd: --anim and --yaw-sequence cannot be used together")
		return false
	if not _validate_subject_passthrough_args():
		return false

	for option in ["height-scale", "height-depth"]:
		if not _args.has(option):
			continue
		var parsed := _parse_finite_float(option, String(_args[option]))
		if not bool(parsed.get("ok", false)):
			return false
		var value := float(parsed["value"])
		match option:
			"height-scale":
				if value < 0.20 or value > 2.0:
					push_error("shot.gd: --height-scale must be between 0.20 and 2.0")
					return false
				_height_overrides[&"authored_height_scale"] = value
			"height-depth":
				if value < 0.0 or value > 0.030:
					push_error("shot.gd: --height-depth must be between 0.0 and 0.030")
					return false
				_height_overrides[&"authored_height_depth"] = value
	if not _args.has("yaw-sequence"):
		return true
	var raw_sequence := String(_args["yaw-sequence"])
	if raw_sequence.strip_edges().is_empty():
		push_error("shot.gd: --yaw-sequence requires one or more comma-separated numbers")
		return false
	var tokens := raw_sequence.split(",", true)
	for index in tokens.size():
		var token := String(tokens[index]).strip_edges()
		if token.is_empty():
			push_error("shot.gd: --yaw-sequence contains an empty value at index %d" % index)
			return false
		var parsed := _parse_finite_float("yaw-sequence[%d]" % index, token)
		if not bool(parsed.get("ok", false)):
			return false
		_yaw_sequence.append(float(parsed["value"]))
	return not _yaw_sequence.is_empty()


func _parse_finite_float(option: String, raw_value: String) -> Dictionary:
	var trimmed := raw_value.strip_edges()
	if trimmed.is_empty() or not trimmed.is_valid_float():
		push_error("shot.gd: --%s requires a finite number, got '%s'" % [option, raw_value])
		return {"ok": false}
	var value := float(trimmed)
	if not is_finite(value):
		push_error("shot.gd: --%s requires a finite number, got '%s'" % [option, raw_value])
		return {"ok": false}
	return {"ok": true, "value": value}


func _validate_subject_passthrough_args() -> bool:
	var scene_path := String(_args.get("scene", ""))
	var supplied: Array[String] = []
	for option in SUBJECT_PASSTHROUGH_ARGS:
		if _args.has(option):
			supplied.append(option)
	if supplied.is_empty():
		return true

	var supported: Array[String] = []
	if scene_path == GEL_PREVIEW_SCENE:
		supported = ["family", "mesh", "set"]
	elif scene_path == ANIM_PREVIEW_SCENE:
		supported = ["family", "body", "ground"]
	elif scene_path in M_REFERENCE_SCENES:
		supported = ["variant"]
	else:
		push_error(
			"shot.gd: subject options %s are not supported by --scene=%s"
			% [", ".join(supplied), scene_path]
		)
		return false
	for option in supplied:
		if option not in supported:
			push_error("shot.gd: --%s is not supported by --scene=%s" % [option, scene_path])
			return false

	if _args.has("family") and String(_args["family"]) not in VALID_PREVIEW_FAMILIES:
		push_error("shot.gd: --family must be one of T, B, M, N, A, D")
		return false
	if _args.has("body") and String(_args["body"]) not in ["mesh", "blockout"]:
		push_error("shot.gd: --body must be mesh or blockout")
		return false
	if _args.has("ground") and String(_args["ground"]) not in ["0", "1"]:
		push_error("shot.gd: --ground must be 0 or 1")
		return false
	if _args.has("variant") and String(_args["variant"]) not in ["clear", "fizzy", "gummy"]:
		push_error("shot.gd: --variant must be clear, fizzy, or gummy")
		return false
	if _args.has("set") and String(_args["set"]).strip_edges().is_empty():
		push_error("shot.gd: --set requires a non-empty gel-preview override list")
		return false
	if _args.has("mesh"):
		var mesh_path := String(_args["mesh"])
		if not mesh_path.begins_with("res://") or not ResourceLoader.exists(mesh_path):
			push_error("shot.gd: --mesh must name an existing res:// PackedScene")
			return false
		if load(mesh_path) is not PackedScene:
			push_error("shot.gd: --mesh is not a PackedScene: %s" % mesh_path)
			return false
	return true


func _is_safe_tag(value: String) -> bool:
	if value.is_empty() or value.length() > 128:
		return false
	if value.begins_with(".") or value.ends_with(".") or value.contains(".."):
		return false
	for index in value.length():
		var code := value.unicode_at(index)
		var is_ascii_alphanumeric := (
			(code >= 48 and code <= 57)
			or (code >= 65 and code <= 90)
			or (code >= 97 and code <= 122)
		)
		if not is_ascii_alphanumeric and code not in [45, 46, 95]:
			return false
	return true


func _abort_for_qa_startup_failure() -> bool:
	if not ResearchState.has_method("qa_startup_failed"):
		return false
	if not bool(ResearchState.call("qa_startup_failed")):
		return false
	var exit_code := QA_STARTUP_FAILURE_EXIT_CODE
	if ResearchState.has_method("qa_startup_failure_exit_code"):
		exit_code = int(ResearchState.call("qa_startup_failure_exit_code"))
	get_tree().quit(exit_code)
	return true


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
	_GelStudio.apply_banner_preview(env)
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
	var readiness_error := _subject_readiness_error(scene_path)
	if not readiness_error.is_empty():
		push_error("shot.gd: %s" % readiness_error)
		return false
	return _frame_subject()


## Centers the model on the pivot and records its height so the camera
## framing does not depend on whatever scale the exporter happened to use.
func _frame_subject() -> bool:
	var aabb := _world_aabb(_subject)
	if aabb.size == Vector3.ZERO:
		push_error("shot.gd: visible subject meshes produced an empty AABB")
		return false
	_height = maxf(aabb.size.y, 0.001)
	var centre := aabb.get_center()
	_subject.position -= Vector3(centre.x, aabb.position.y, centre.z)
	return true


func _subject_readiness_error(scene_path: String) -> String:
	if scene_path == GEL_PREVIEW_SCENE:
		if _subject.get_node_or_null("GelSubject") == null:
			return "gel_preview subject did not finish loading GelSubject"
		var gel_materials: Variant = _subject.get("_materials")
		if gel_materials is not Array or gel_materials.is_empty():
			return "gel_preview subject did not apply any gel materials"
	elif scene_path == ANIM_PREVIEW_SCENE:
		var character: Variant = _subject.get("_character")
		if character is not Node3D:
			return "anim_preview subject did not finish loading its character"
		if _visible_mesh_instances(character).is_empty():
			return "anim_preview character has no non-empty visible MeshInstance3D"
	if _visible_mesh_instances(_subject).is_empty():
		return "subject has no non-empty visible MeshInstance3D after _ready()"
	return ""


func _world_aabb(node: Node) -> AABB:
	var out := AABB()
	var seeded := false
	for mi in _visible_mesh_instances(node):
		var box := mi.global_transform * mi.get_aabb()
		if seeded:
			out = out.merge(box)
		else:
			out = box
			seeded = true
	return out


func _visible_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for mesh_instance in _all_mesh_instances(node):
		if mesh_instance.mesh == null or not mesh_instance.is_visible_in_tree():
			continue
		if mesh_instance.mesh.get_surface_count() <= 0:
			continue
		if mesh_instance.get_aabb().size == Vector3.ZERO:
			continue
		out.append(mesh_instance)
	return out


func _all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_all_mesh_instances(child))
	return out


func _apply_height_overrides() -> bool:
	if _height_overrides.is_empty():
		return true
	var materials: Array[ShaderMaterial] = []
	var seen := {}
	for mesh_instance in _all_mesh_instances(_subject):
		_append_authored_height_material(mesh_instance.material_override, materials, seen)
		_append_authored_height_material(mesh_instance.material_overlay, materials, seen)
		if mesh_instance.mesh == null:
			continue
		for surface_index in mesh_instance.mesh.get_surface_count():
			_append_authored_height_material(
				mesh_instance.get_active_material(surface_index), materials, seen
			)
	if materials.is_empty():
		push_error(
			"shot.gd: height override requested, but no ShaderMaterial exposes authored_height_enabled"
		)
		return false
	for material in materials:
		var enabled_value: Variant = material.get_shader_parameter(&"authored_height_enabled")
		if enabled_value is not bool or not bool(enabled_value):
			push_error(
				"shot.gd: height override requested, but an attached authored-height material is disabled"
			)
			return false

	var application_counts := {}
	for parameter in _height_overrides:
		application_counts[parameter] = 0
	for material in materials:
		for parameter in _height_overrides:
			# Never invent a parameter on an authored-height shader that does not
			# expose the requested control.
			if material.get_shader_parameter(parameter) == null:
				continue
			material.set_shader_parameter(parameter, _height_overrides[parameter])
			application_counts[parameter] = int(application_counts[parameter]) + 1

	for parameter in _height_overrides:
		if int(application_counts[parameter]) == 0:
			push_error(
				"shot.gd: requested override '%s' is not exposed by any authored-height material"
				% String(parameter)
			)
			return false
		print(
			"HEIGHT_OVERRIDE parameter=%s value=%.6f materials=%d"
			% [
				String(parameter),
				float(_height_overrides[parameter]),
				int(application_counts[parameter]),
			]
		)
	return true


func _append_authored_height_material(
	material: Material,
	out: Array[ShaderMaterial],
	seen: Dictionary
) -> void:
	if material == null:
		return
	var instance_id := material.get_instance_id()
	if seen.has(instance_id):
		return
	seen[instance_id] = true
	if material is ShaderMaterial:
		var shader_material := material as ShaderMaterial
		if shader_material.get_shader_parameter(&"authored_height_enabled") != null:
			out.append(shader_material)
	_append_authored_height_material(material.next_pass, out, seen)


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


func _run() -> bool:
	var anim_name := String(_args.get("anim", ""))
	if anim_name.is_empty():
		if not _yaw_sequence.is_empty():
			return await _run_yaw_sequence()
		var all_saved := true
		for shot in SHOTS:
			_pivot.rotation_degrees = Vector3(0.0, float(shot["yaw"]), 0.0)
			_place_camera(bool(shot["face"]))
			all_saved = (await _save("%s-%s.png" % [_tag, shot["name"]]) == OK) and all_saved
		return all_saved
	return await _run_anim(anim_name)


func _run_yaw_sequence() -> bool:
	_place_camera(false)
	var all_saved := true
	for index in _yaw_sequence.size():
		var yaw := _yaw_sequence[index]
		_pivot.rotation_degrees = Vector3(0.0, yaw, 0.0)
		var file_name := "%s-yaw-%03d.png" % [_tag, index]
		var save_error := await _save(file_name)
		if save_error == OK:
			print("SHOT_YAW index=%d degrees=%.6f file=%s" % [index, yaw, file_name])
		else:
			all_saved = false
	return all_saved


## Samples an animation at even intervals so a reviewer sees the motion arc,
## not just one lucky frame.
func _run_anim(anim_name: String) -> bool:
	var player := _find_player(_subject)
	if player == null:
		push_error("shot.gd: no AnimationPlayer under subject")
		return false
	if not player.has_animation(anim_name):
		push_error("shot.gd: no animation '%s' (have: %s)" % [anim_name, ", ".join(player.get_animation_list())])
		return false
	var length := player.get_animation(anim_name).length
	_pivot.rotation_degrees = Vector3(0.0, 35.0, 0.0)
	_place_camera(false)
	player.play(anim_name)
	var all_saved := true
	for i in _animation_frames:
		var t := length * float(i) / float(_animation_frames)
		player.seek(t, true, true)
		all_saved = (await _save("%s-%s-%02d.png" % [_tag, anim_name, i]) == OK) and all_saved
	return all_saved


func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null


func _save(file_name: String) -> Error:
	# Two frames: one to apply transforms, one so the drawn buffer matches them.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := _out_dir.path_join(file_name)
	if image == null or image.is_empty():
		push_error("shot.gd: viewport returned no image for %s" % path)
		return ERR_CANT_CREATE
	# visible_rect and ViewportTexture.get_size() can both be content-scaled on a
	# Retina display. Screenshot readback follows the OS window pixel buffer, which
	# is the same contract controlled by the harness's --resolution argument.
	var expected_size := DisplayServer.window_get_size()
	if image.get_size() != expected_size:
		push_error(
			"shot.gd: viewport image has unexpected size %s (expected %s) for %s"
			% [image.get_size(), expected_size, path]
		)
		return ERR_FILE_CORRUPT
	var err := image.save_png(path)
	if err != OK:
		push_error("shot.gd: save failed %s (%d)" % [path, err])
		return err
	var reopened := Image.load_from_file(path)
	if reopened == null or reopened.is_empty() or reopened.get_size() != expected_size:
		push_error("shot.gd: saved PNG cannot be reopened at expected size: %s" % path)
		return ERR_FILE_CORRUPT
	if not _validate_sampled_image_contract(reopened, path):
		return ERR_FILE_CORRUPT
	print("SHOT %s" % path)
	return OK


func _validate_sampled_image_contract(image: Image, label: String) -> bool:
	if image == null or image.is_empty():
		push_error("shot.gd: PNG content check received an empty image: %s" % label)
		return false
	var size := image.get_size()
	var sample_count := 0
	var visible_samples := 0
	var bright_samples := 0
	var min_luma := INF
	var max_luma := -INF
	var min_channel := INF
	var max_channel := -INF
	var luma_sum := 0.0
	var luma_square_sum := 0.0
	for grid_y in IMAGE_SAMPLE_GRID:
		var y := clampi(
			int((float(grid_y) + 0.5) * float(size.y) / float(IMAGE_SAMPLE_GRID)),
			0,
			size.y - 1
		)
		for grid_x in IMAGE_SAMPLE_GRID:
			var x := clampi(
				int((float(grid_x) + 0.5) * float(size.x) / float(IMAGE_SAMPLE_GRID)),
				0,
				size.x - 1
			)
			var colour := image.get_pixel(x, y)
			var alpha := clampf(colour.a, 0.0, 1.0)
			var luma := colour.get_luminance() * alpha
			var red := colour.r * alpha
			var green := colour.g * alpha
			var blue := colour.b * alpha
			sample_count += 1
			if alpha >= 0.05:
				visible_samples += 1
			if luma >= IMAGE_MIN_PEAK_LUMA:
				bright_samples += 1
			min_luma = minf(min_luma, luma)
			max_luma = maxf(max_luma, luma)
			min_channel = minf(min_channel, minf(red, minf(green, blue)))
			max_channel = maxf(max_channel, maxf(red, maxf(green, blue)))
			luma_sum += luma
			luma_square_sum += luma * luma
	var mean_luma := luma_sum / float(sample_count)
	var luma_variance := maxf(
		(luma_square_sum / float(sample_count)) - mean_luma * mean_luma,
		0.0
	)
	var luma_range := max_luma - min_luma
	var colour_range := max_channel - min_channel
	var valid := (
		visible_samples >= IMAGE_MIN_VISIBLE_SAMPLES
		and bright_samples >= IMAGE_MIN_BRIGHT_SAMPLES
		and max_luma >= IMAGE_MIN_PEAK_LUMA
		and luma_range >= IMAGE_MIN_LUMA_RANGE
		and colour_range >= IMAGE_MIN_COLOUR_RANGE
		and luma_variance >= IMAGE_MIN_LUMA_VARIANCE
	)
	var metrics := (
		"samples=%d visible=%d bright=%d peak=%.6f luma_range=%.6f "
		+ "colour_range=%.6f variance=%.8f"
	) % [
		sample_count,
		visible_samples,
		bright_samples,
		max_luma,
		luma_range,
		colour_range,
		luma_variance,
	]
	if not valid:
		push_error("shot.gd: PNG is uniform, transparent, or near-blank %s (%s)" % [label, metrics])
		return false
	print("SHOT_PNG_CONTENT_OK %s %s" % [label, metrics])
	return true
