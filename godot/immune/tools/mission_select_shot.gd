extends Node

## Headed six-family mission-desk capture for player-facing visual QA.
##
## Run:
##   godot --path <proj> --resolution 1600x900 res://tools/mission_select_shot.tscn -- \
##     --out=<absolute-dir> [--locale=zh_HK|en] [--tag=mission-select]

const FAMILIES: PackedStringArray = ["T", "B", "M", "N", "A", "D"]
const ALLOWED_ARGS: PackedStringArray = ["out", "locale", "tag", "save-path"]
const MAX_TAG_LENGTH: int = 64
const IMAGE_SAMPLE_GRID := 16
const IMAGE_MIN_VISIBLE_SAMPLES := 16
const IMAGE_MIN_BRIGHT_SAMPLES := 4
const IMAGE_MIN_PEAK_LUMA := 0.04
const IMAGE_MIN_LUMA_RANGE := 0.02
const IMAGE_MIN_COLOUR_RANGE := 0.025
const IMAGE_MIN_LUMA_VARIANCE := 0.00002

var _args := {}
var _out_dir := ""
var _locale := "zh_HK"
var _tag := "mission-select"
var _desk: Node
var _capture_records: Array[Dictionary] = []
var _layout_contract_ok := true


func _ready() -> void:
	if _quit_for_qa_startup_failure():
		return
	if not _parse_args():
		get_tree().quit(2)
		return
	_out_dir = String(_args.get("out", ""))
	_locale = String(_args.get("locale", "zh_HK"))
	_tag = String(_args.get("tag", "mission-select"))
	if not _validate_args():
		get_tree().quit(2)
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(_out_dir)
	if directory_error != OK and not DirAccess.dir_exists_absolute(_out_dir):
		push_error(
			"mission_select_shot.gd: cannot create --out %s (%s)"
			% [_out_dir, error_string(directory_error)]
		)
		get_tree().quit(2)
		return
	if not _validate_output_dir(_out_dir):
		get_tree().quit(2)
		return
	TranslationServer.set_locale(_locale)
	ResearchState.seed_demo()
	ResearchState.selected_mission_id = &"MISSION-01"
	ResearchState.selected_family_id = &"T"
	var packed := load("res://ui/mission_select/mission_select.tscn") as PackedScene
	if packed == null:
		push_error("mission_select_shot.gd: mission_select.tscn missing")
		get_tree().quit(3)
		return
	_desk = packed.instantiate()
	add_child(_desk)
	await _settle(12)
	_layout_contract_ok = _verify_responsive_contract()
	var saved_count := 0
	for i in FAMILIES.size():
		var requested_family := String(FAMILIES[i])
		_desk.call("_select_family", i)
		await _settle(10)
		var identity := _mission_desk_family_identity(requested_family)
		if not bool(identity.get("ok", false)):
			break
		var selected_family := String(identity["selected_family"])
		var file_name := "%s-%s-%s.png" % [_tag, _locale, selected_family.to_lower()]
		if await _save(file_name):
			identity["file"] = file_name
			_capture_records.append(identity)
			print("MISSION_SELECT_IDENTITY %s" % JSON.stringify(identity))
			saved_count += 1
		else:
			break
	AudioDirector.stop_all()
	_desk.call("_shutdown_preview")
	_desk.queue_free()
	_desk = null
	# Runtime gel bodies own generated ShaderMaterials and next-pass membranes.
	# A frame-only wait can finish in microseconds and race Compatibility's render
	# thread at process exit, so give both the scene tree and real clock a bounded
	# drain before the final sync.
	for _frame in 10:
		await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	RenderingServer.force_sync()
	await get_tree().process_frame
	if (
		saved_count != FAMILIES.size()
		or not _capture_records_match_contract()
		or not _layout_contract_ok
	):
		push_error(
			"mission_select_shot.gd: required 6 identity-bound PNGs, successfully verified %d"
			% saved_count
		)
		get_tree().quit(4)
		return
	print("MISSION_SELECT_SHOTS_OK count=%d" % saved_count)
	get_tree().quit(0)


func _verify_responsive_contract() -> bool:
	if _desk == null or not _desk.has_method("responsive_contract"):
		push_error("mission_select_shot.gd: responsive contract missing")
		return false
	var contract: Dictionary = _desk.call("responsive_contract")
	print("MISSION_SELECT_RESPONSIVE %s" % JSON.stringify(contract))
	if not bool(contract.get("all_pass", false)):
		push_error("mission_select_shot.gd: responsive contract failed")
		return false
	return true


func _parse_args() -> bool:
	for raw_arg: String in OS.get_cmdline_user_args():
		var arg := raw_arg.strip_edges()
		if not arg.begins_with("--") or arg == "--":
			push_error("mission_select_shot.gd: positional or malformed argument: %s" % raw_arg)
			return false
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() != 2:
			push_error("mission_select_shot.gd: option requires =<value>: %s" % raw_arg)
			return false
		var key := String(pair[0]).strip_edges()
		var value := String(pair[1]).strip_edges()
		if key not in ALLOWED_ARGS:
			push_error("mission_select_shot.gd: unknown option --%s" % key)
			return false
		if _args.has(key):
			push_error("mission_select_shot.gd: duplicate option --%s" % key)
			return false
		if value.is_empty():
			push_error("mission_select_shot.gd: --%s cannot be empty" % key)
			return false
		_args[key] = value
	return true


func _validate_args() -> bool:
	if _out_dir.is_empty():
		push_error("mission_select_shot.gd: --out is required")
		return false
	if _locale not in ["zh_HK", "en"]:
		push_error("mission_select_shot.gd: --locale must be zh_HK or en")
		return false
	if not _is_safe_tag(_tag):
		push_error(
			"mission_select_shot.gd: --tag must be a safe 1-%d character file-name component"
			% MAX_TAG_LENGTH
		)
		return false
	return _validate_output_dir(_out_dir)


func _is_safe_tag(value: String) -> bool:
	if value.is_empty() or value.length() > MAX_TAG_LENGTH or value in [".", ".."]:
		return false
	var valid := RegEx.new()
	if valid.compile("^[A-Za-z0-9][A-Za-z0-9._-]*$") != OK:
		return false
	return valid.search(value) != null


func _validate_output_dir(raw_path: String) -> bool:
	var normalized := raw_path.strip_edges().replace("\\", "/")
	if normalized.is_empty() or normalized.to_utf8_buffer().has(0) or not normalized.is_absolute_path():
		push_error("mission_select_shot.gd: --out must be an absolute directory")
		return false
	var absolute_path := normalized.simplify_path().trim_suffix("/")
	var temp_root := OS.get_temp_dir().replace("\\", "/").simplify_path().trim_suffix("/")
	var outputs_root := _repository_outputs_root()
	var project_source_root := ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path().trim_suffix("/")
	if _path_is_within(absolute_path, project_source_root):
		push_error("mission_select_shot.gd: --out cannot write into res:// source")
		return false
	var trusted_root := ""
	if _path_is_within(absolute_path, temp_root):
		trusted_root = temp_root
	elif _path_is_within(absolute_path, outputs_root):
		trusted_root = outputs_root
	else:
		push_error(
			"mission_select_shot.gd: --out must be inside the system temp or repository outputs directory"
		)
		return false
	if (
		_path_compare_value(absolute_path) == _path_compare_value(trusted_root)
		or _path_crosses_link(absolute_path, trusted_root)
	):
		push_error("mission_select_shot.gd: --out is unsafe or crosses a symbolic link")
		return false
	if FileAccess.file_exists(absolute_path):
		push_error("mission_select_shot.gd: --out names a file")
		return false
	_out_dir = absolute_path
	return true


func _repository_outputs_root() -> String:
	var godot_project_root := ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path()
	return godot_project_root.get_base_dir().get_base_dir().path_join("outputs").simplify_path()


func _path_is_within(path: String, root_path: String) -> bool:
	var normalized_path := path.replace("\\", "/").simplify_path().trim_suffix("/")
	var normalized_root := root_path.replace("\\", "/").simplify_path().trim_suffix("/")
	var comparable_path := _path_compare_value(normalized_path)
	var comparable_root := _path_compare_value(normalized_root)
	return comparable_path == comparable_root or comparable_path.begins_with(comparable_root + "/")


func _path_compare_value(path: String) -> String:
	# Windows drive paths and the default macOS volume are case-insensitive. Use
	# the stricter comparison there so RES/Res casing cannot bypass containment.
	return path.to_lower() if OS.get_name() in ["Windows", "macOS"] else path


func _path_crosses_link(path: String, trusted_root: String) -> bool:
	# Containment was already established with the platform-aware comparison.
	# Slice by length so differently cased drive/root spellings cannot defeat the
	# component walk on case-insensitive file systems.
	var relative := path.substr(trusted_root.length()).trim_prefix("/")
	var cursor := trusted_root
	for component: String in relative.split("/", false):
		var directory := DirAccess.open(cursor)
		if directory == null:
			return false
		if directory.is_link(component):
			return true
		cursor = cursor.path_join(component)
	return false


func _settle(frames: int) -> void:
	for _frame in frames:
		await RenderingServer.frame_post_draw


func _mission_desk_family_identity(requested_family: String) -> Dictionary:
	var result := {
		"ok": false,
		"requested_family": requested_family,
		"selected_family": "",
		"preview_family": "",
		"preview_ready": false,
	}
	if _desk == null or not is_instance_valid(_desk):
		push_error("mission_select_shot.gd: mission desk is unavailable")
		return result
	var family_index_value: Variant = _desk.get("_family_index")
	if family_index_value is not int:
		push_error("mission_select_shot.gd: mission desk does not expose an integer family index")
		return result
	var family_index := int(family_index_value)
	if family_index < 0 or family_index >= FAMILIES.size():
		push_error("mission_select_shot.gd: mission desk family index is out of range: %d" % family_index)
		return result
	var selected_family := String(FAMILIES[family_index])
	result["selected_family"] = selected_family
	var preview_value: Variant = _desk.get("_preview")
	if preview_value is not ImmuneCharacter:
		push_error(
			"mission_select_shot.gd: preview is absent for requested family %s"
			% requested_family
		)
		return result
	var preview := preview_value as ImmuneCharacter
	var preview_family := String(preview.family_id)
	result["preview_family"] = preview_family
	var preview_stage := _desk.get("_preview_stage") as Node3D
	var preview_viewport := _desk.get("_preview_viewport") as SubViewport
	var mesh_ready := not _visible_mesh_instances(preview).is_empty()
	var preview_ready := (
		is_instance_valid(preview)
		and preview.is_inside_tree()
		and preview.is_visible_in_tree()
		and preview_stage != null
		and preview.get_parent() == preview_stage
		and preview_viewport != null
		and preview_viewport.render_target_update_mode != SubViewport.UPDATE_DISABLED
		and mesh_ready
	)
	result["preview_ready"] = preview_ready
	var matches := (
		selected_family == requested_family
		and preview_family == requested_family
		and preview_ready
	)
	result["ok"] = matches
	if not matches:
		push_error(
			"mission_select_shot.gd: family identity mismatch requested=%s selected=%s preview=%s ready=%s"
			% [requested_family, selected_family, preview_family, preview_ready]
		)
	return result


func _visible_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if (
			mesh_instance.mesh != null
			and mesh_instance.mesh.get_surface_count() > 0
			and mesh_instance.get_aabb().size != Vector3.ZERO
			and mesh_instance.is_visible_in_tree()
		):
			meshes.append(mesh_instance)
	for child in node.get_children():
		meshes.append_array(_visible_mesh_instances(child))
	return meshes


func _capture_records_match_contract() -> bool:
	if _capture_records.size() != FAMILIES.size():
		return false
	var seen := {}
	for index in FAMILIES.size():
		var expected_family := String(FAMILIES[index])
		var record: Dictionary = _capture_records[index]
		var requested_family := String(record.get("requested_family", ""))
		var selected_family := String(record.get("selected_family", ""))
		var preview_family := String(record.get("preview_family", ""))
		var expected_file := "%s-%s-%s.png" % [_tag, _locale, expected_family.to_lower()]
		if (
			requested_family != expected_family
			or selected_family != expected_family
			or preview_family != expected_family
			or not bool(record.get("preview_ready", false))
			or not bool(record.get("ok", false))
			or String(record.get("file", "")) != expected_file
			or seen.has(expected_family)
		):
			return false
		seen[expected_family] = true
	return true


func _save(file_name: String) -> bool:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	RenderingServer.force_sync()
	if not _validate_output_dir(_out_dir):
		return false
	var image := get_viewport().get_texture().get_image()
	var path := _out_dir.path_join(file_name)
	var output_directory := DirAccess.open(_out_dir)
	if output_directory == null or output_directory.is_link(file_name):
		push_error("mission_select_shot.gd: output path is unavailable or symbolic: %s" % path)
		return false
	if image == null or image.is_empty():
		push_error("mission_select_shot.gd: viewport returned no image for %s" % path)
		return false
	var expected_size: Vector2i = get_viewport().size
	if image.get_size() != expected_size:
		push_error(
			"mission_select_shot.gd: viewport capture size mismatch %s != %s"
			% [image.get_size(), expected_size]
		)
		return false
	var err := image.save_png(path)
	if err != OK:
		push_error("mission_select_shot.gd: save failed %s (%d)" % [path, err])
		return false
	var reopened := Image.load_from_file(path)
	if reopened == null or reopened.is_empty() or reopened.get_size() != expected_size:
		push_error(
			"mission_select_shot.gd: saved PNG did not reopen at %dx%d: %s"
			% [expected_size.x, expected_size.y, path]
		)
		return false
	if not _validate_sampled_image_contract(reopened, path):
		return false
	print("MISSION_SELECT_SHOT %s" % path)
	return true


func _validate_sampled_image_contract(image: Image, label: String) -> bool:
	if image == null or image.is_empty():
		push_error("mission_select_shot.gd: PNG content check received an empty image: %s" % label)
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
		push_error("mission_select_shot.gd: PNG is uniform, transparent, or near-blank %s (%s)" % [label, metrics])
		return false
	print("MISSION_SELECT_PNG_CONTENT_OK %s %s" % [label, metrics])
	return true


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
