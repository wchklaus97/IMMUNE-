extends Node3D

## GPU cost check for the wet-gel material. Renders N copies of the T mesh filling
## the frame and reports measured GPU time per frame, so the combat budget claim is
## measured rather than asserted.
##
## Run (needs a real window, same as the shot harness):
##   godot --path <proj> --resolution 1280x720 res://tools/gel_perf.tscn -- \
##     --count=10 [--frames=240] [--material=gel|standard|none]
##
## `--material=standard` renders the same meshes with the old StandardMaterial3D
## jelly look, and `none` leaves the imported GLB material, which together give the
## comparison the gel number is only meaningful against.

const _Look := preload("res://characters/family_look.gd")
const _Gel := preload("res://characters/gel/gel_look.gd")
const _GelProfiles := preload("res://characters/gel/gel_profiles.gd")
const _LightContract := preload("res://characters/gel/light_contract.gd")

## Clean mesh first, same reasoning as tools/gel_preview.gd: a published cost number
## should not have been measured on a mesh with holes torn through the eyes.
const MESH_CANDIDATES: Dictionary = {
	"T": [
		"res://characters/base_t/CHAR-BASE-T-tripo-5k.glb",
		"res://characters/base_t/CHAR-BASE-T-fix.glb",
	],
	"B": [
		"res://characters/base_b/CHAR-BASE-B-meshy-t2.glb",
	],
	"M": [
		"res://characters/base_m/CHAR-BASE-M-meshy-t2.glb",
	],
}

## Frames discarded before measuring, so shader compilation and the first-frame
## pipeline warm-up do not land in the average.
const WARMUP_FRAMES := 60

const ALLOWED_ARGS: Array[String] = [
	"count", "frames", "material", "family", "sync", "out", "set", "save-path",
]
const VALID_MATERIALS: Array[String] = ["gel", "standard", "none"]
const MEMBRANE_SET_ALIASES: Dictionary = {
	"membrane_face_alpha": "face_alpha",
	"membrane_edge_alpha": "edge_alpha",
	"membrane_edge_power": "edge_power",
	"membrane_roughness": "shell_roughness",
	"membrane_rim_emission": "rim_emission",
	"membrane_thickness": "shell_thickness",
}
const QA_STARTUP_FAILURE_EXIT_CODE := 74
const REPORT_TRANSACTION_ATTEMPTS := 32

var _count := 10
var _frames := 240
var _mode := "gel"
var _family := "T"
var _force_sync := false
var _out_path := ""
var _opts := {}


func _ready() -> void:
	if _abort_for_qa_startup_failure():
		return
	# Compatibility/Metal can report a zero GPU timer even when viewport timing is
	# enabled. Disable VSync and keep CPU + wall-frame samples as honest fallbacks.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var parsed_args := _user_args()
	if not bool(parsed_args.get("ok", false)):
		get_tree().quit(2)
		return
	if not _configure(parsed_args["args"] as Dictionary):
		get_tree().quit(2)
		return
	_build_stage()
	if not _spawn():
		get_tree().quit(3)
		return
	await get_tree().process_frame
	var light_error := _LightContract.error(self, "gel perf rig")
	if not light_error.is_empty():
		push_error(light_error)
		get_tree().quit(5)
		return
	if not await _measure():
		get_tree().quit(4)
		return
	get_tree().quit(0)


func _configure(args: Dictionary) -> bool:
	for key in args:
		if String(key) not in ALLOWED_ARGS:
			push_error("gel_perf.gd: unknown option --%s" % String(key))
			return false

	var parsed_count := _parse_bounded_int("count", String(args.get("count", "10")), 1, 200)
	if not bool(parsed_count.get("ok", false)):
		return false
	_count = int(parsed_count["value"])
	var parsed_frames := _parse_bounded_int("frames", String(args.get("frames", "240")), 30, 4000)
	if not bool(parsed_frames.get("ok", false)):
		return false
	_frames = int(parsed_frames["value"])

	_mode = String(args.get("material", "gel")).strip_edges().to_lower()
	if _mode not in VALID_MATERIALS:
		push_error("gel_perf.gd: --material must be gel, standard, or none")
		return false
	_family = String(args.get("family", "T")).strip_edges().to_upper()
	if not MESH_CANDIDATES.has(_family):
		push_error("gel_perf.gd: unsupported family %s" % _family)
		return false
	var sync_value := String(args.get("sync", "false")).strip_edges().to_lower()
	if sync_value not in ["true", "false"]:
		push_error("gel_perf.gd: --sync must be true or false")
		return false
	_force_sync = sync_value == "true"
	_out_path = String(args.get("out", "")).strip_edges()
	if args.has("out"):
		if _out_path.is_empty():
			push_error("gel_perf.gd: --out cannot be empty")
			return false
		if not _validate_out_path():
			return false

	if not args.has("set"):
		return true
	if _mode != "gel":
		push_error("gel_perf.gd: --set is only valid with --material=gel")
		return false
	var raw_options := String(args["set"])
	if raw_options.strip_edges().is_empty():
		push_error("gel_perf.gd: --set requires name:value entries")
		return false
	# Same --set=name:value form as gel_preview, but fail closed against the live
	# wet-gel and membrane schemas so a typo cannot be reported as a measured
	# ablation even though ShaderMaterial silently ignored it.
	var control_contract := _set_control_contract()
	if control_contract.is_empty():
		return false
	for entry in raw_options.split(",", true):
		var pair := entry.split(":", true, 1)
		if pair.size() != 2 or String(pair[0]).strip_edges().is_empty():
			push_error("gel_perf.gd: malformed --set entry '%s'" % entry)
			return false
		var key := String(pair[0]).strip_edges()
		if not control_contract.has(key):
			push_error("gel_perf.gd: unknown or unsupported --set control '%s'" % key)
			return false
		if _opts.has(key):
			push_error("gel_perf.gd: duplicate --set control '%s'" % key)
			return false
		var parsed_value := _parse_set_control(
			key, String(pair[1]).strip_edges(), control_contract[key] as Dictionary
		)
		if not bool(parsed_value.get("ok", false)):
			return false
		_opts[key] = parsed_value["value"]
	var effective_options := _GelProfiles.options(_family, _opts)
	if (
		float(effective_options.get("microbubble_radius_max", 0.0))
		+ float(effective_options.get("microbubble_jitter", 0.0))
		>= 1.0
	):
		push_error(
			"gel_perf.gd: microbubble_radius_max + microbubble_jitter must stay below 1.0"
		)
		return false
	if not bool(effective_options.get("membrane_enabled", false)):
		for alias in MEMBRANE_SET_ALIASES:
			if _opts.has(alias):
				push_error(
					"gel_perf.gd: --set control '%s' requires membrane_enabled=true"
					% alias
				)
				return false
	return true


func _set_control_contract() -> Dictionary:
	var wet_shader := load(_Gel.SHADER_PATH) as Shader
	if wet_shader == null:
		push_error("gel_perf.gd: cannot load wet-gel shader control schema")
		return {}
	var contract := _scalar_shader_controls(wet_shader)
	# apply() deliberately restores this from the imported texture after material
	# creation, so accepting it here would report an override that did not survive.
	contract.erase("use_feature_tex")
	if contract.is_empty():
		push_error("gel_perf.gd: wet-gel shader exposed no scalar control schema")
		return {}
	var shell_shader := load(_Gel.MEMBRANE_SHADER_PATH) as Shader
	if shell_shader == null:
		push_error("gel_perf.gd: cannot load membrane shader control schema")
		return {}
	var shell_controls := _scalar_shader_controls(shell_shader)
	contract["membrane_enabled"] = {"type": TYPE_BOOL}
	for alias in MEMBRANE_SET_ALIASES:
		var shader_name := String(MEMBRANE_SET_ALIASES[alias])
		if not shell_controls.has(shader_name):
			push_error(
				"gel_perf.gd: membrane control schema is missing '%s' for '%s'"
				% [shader_name, alias]
			)
			return {}
		contract[alias] = (shell_controls[shader_name] as Dictionary).duplicate(true)
	return contract


func _scalar_shader_controls(shader: Shader) -> Dictionary:
	var controls := {}
	for raw_property in shader.get_shader_uniform_list(false):
		var property := raw_property as Dictionary
		var name := String(property.get("name", ""))
		var type := int(property.get("type", TYPE_NIL))
		if name.is_empty() or type not in [TYPE_BOOL, TYPE_FLOAT]:
			continue
		var control := {"type": type}
		if type == TYPE_FLOAT and int(property.get("hint", PROPERTY_HINT_NONE)) == PROPERTY_HINT_RANGE:
			var range_parts := String(property.get("hint_string", "")).split(",", false)
			if range_parts.size() >= 2:
				var raw_minimum := String(range_parts[0]).strip_edges()
				var raw_maximum := String(range_parts[1]).strip_edges()
				if raw_minimum.is_valid_float() and raw_maximum.is_valid_float():
					var minimum := float(raw_minimum)
					var maximum := float(raw_maximum)
					if is_finite(minimum) and is_finite(maximum) and minimum <= maximum:
						control["minimum"] = minimum
						control["maximum"] = maximum
		controls[name] = control
	return controls


func _parse_set_control(key: String, raw_value: String, control: Dictionary) -> Dictionary:
	var expected_type := int(control.get("type", TYPE_NIL))
	var lowered := raw_value.to_lower()
	if expected_type == TYPE_BOOL:
		if lowered not in ["true", "false"]:
			push_error("gel_perf.gd: --set control '%s' requires true or false" % key)
			return {"ok": false}
		return {"ok": true, "value": lowered == "true"}
	if expected_type != TYPE_FLOAT:
		push_error("gel_perf.gd: --set control '%s' has an unsupported value type" % key)
		return {"ok": false}
	if lowered in ["true", "false"]:
		push_error("gel_perf.gd: --set control '%s' requires a finite number" % key)
		return {"ok": false}
	var parsed := _parse_finite_float("set %s" % key, raw_value)
	if not bool(parsed.get("ok", false)):
		return parsed
	var value := float(parsed["value"])
	# Shader hint ranges are editor UI metadata, not runtime constraints. Existing
	# look-development sweeps intentionally drive a few values past those hints, so
	# the CLI preserves finite numeric overrides while enforcing the actual type.
	return {"ok": true, "value": value}


func _parse_bounded_int(option: String, raw_value: String, minimum: int, maximum: int) -> Dictionary:
	var trimmed := raw_value.strip_edges()
	if trimmed.is_empty() or not trimmed.is_valid_int():
		push_error("gel_perf.gd: --%s requires an integer" % option)
		return {"ok": false}
	var value := int(trimmed)
	if value < minimum or value > maximum:
		push_error("gel_perf.gd: --%s must be between %d and %d" % [option, minimum, maximum])
		return {"ok": false}
	return {"ok": true, "value": value}


func _parse_finite_float(option: String, raw_value: String) -> Dictionary:
	var trimmed := raw_value.strip_edges()
	if trimmed.is_empty() or not trimmed.is_valid_float():
		push_error("gel_perf.gd: --%s requires a finite number" % option)
		return {"ok": false}
	var value := float(trimmed)
	if not is_finite(value):
		push_error("gel_perf.gd: --%s requires a finite number" % option)
		return {"ok": false}
	return {"ok": true, "value": value}


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
	env.glow_enabled = true
	world.environment = env
	add_child(world)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38.0, 34.0, 0.0)
	key.light_energy = 2.1
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


## Grid laid out to roughly fill the frame: the material is fragment-bound, so a
## count that covers little screen area would flatter it.
func _spawn() -> bool:
	var path := ""
	for candidate in MESH_CANDIDATES[_family]:
		if ResourceLoader.exists(candidate):
			path = candidate
			break
	if path.is_empty():
		push_error("gel_perf.gd: no mesh found")
		return false
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("gel_perf.gd: cannot load %s" % path)
		return false

	var cols := int(ceil(sqrt(float(_count))))
	var rows := int(ceil(float(_count) / float(cols)))
	var step := 1.15
	for i in _count:
		var node := packed.instantiate() as Node3D
		if node == null:
			push_error("gel_perf.gd: %s is not a Node3D scene" % path)
			return false
		node.position = Vector3(
			(float(i % cols) - float(cols - 1) * 0.5) * step,
			(float(i / cols) - float(rows - 1) * 0.5) * step,
			0.0)
		add_child(node)
		match _mode:
			"gel":
				var materials := _Look.apply_gel(node, _family, _opts)
				if not _applied_options_match(materials):
					return false
			"standard":
				for mi in _mesh_instances(node):
					mi.material_override = _Look.jelly_material(_family)
			_:
				pass

	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 45.0
	camera.position = Vector3(0.0, 0.0, maxf(float(cols), float(rows)) * step * 1.35)
	add_child(camera)
	return true


func _applied_options_match(materials: Array[ShaderMaterial]) -> bool:
	if materials.is_empty():
		push_error("gel_perf.gd: gel application produced no measurable materials")
		return false
	for material in materials:
		for key in _opts:
			var expected: Variant = _opts[key]
			if key == "membrane_enabled":
				if (material.next_pass != null) != bool(expected):
					push_error("gel_perf.gd: applied membrane_enabled does not match request")
					return false
				continue
			if MEMBRANE_SET_ALIASES.has(key):
				var membrane := material.next_pass as ShaderMaterial
				var shell_name := StringName(MEMBRANE_SET_ALIASES[key])
				var actual_shell: Variant = (
					membrane.get_shader_parameter(shell_name) if membrane != null else null
				)
				if actual_shell == null or not is_equal_approx(float(actual_shell), float(expected)):
					push_error("gel_perf.gd: applied membrane control '%s' does not match request" % key)
					return false
				continue
			var actual: Variant = material.get_shader_parameter(StringName(key))
			if expected is bool:
				if actual is not bool or bool(actual) != bool(expected):
					push_error("gel_perf.gd: applied boolean control '%s' does not match request" % key)
					return false
			elif actual == null or not is_equal_approx(float(actual), float(expected)):
				push_error("gel_perf.gd: applied numeric control '%s' does not match request" % key)
				return false
	return true


func _measure() -> bool:
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	# Calling force_sync() from the frame_post_draw continuation can stall the
	# Forward+ Metal backend indefinitely. A requested sync is therefore a single
	# pre-measure drain, before any signal await, rather than one sync per frame.
	if _force_sync:
		RenderingServer.force_sync()
	for _i in WARMUP_FRAMES:
		await RenderingServer.frame_post_draw
	var gpu_samples: Array[float] = []
	var cpu_samples: Array[float] = []
	var wall_samples: Array[float] = []
	for _i in _frames:
		var frame_start := Time.get_ticks_usec()
		await RenderingServer.frame_post_draw
		gpu_samples.append(RenderingServer.viewport_get_measured_render_time_gpu(vp))
		cpu_samples.append(RenderingServer.viewport_get_measured_render_time_cpu(vp))
		wall_samples.append(float(Time.get_ticks_usec() - frame_start) / 1000.0)
	var gpu_summary := _summary(gpu_samples)
	var cpu_summary := _summary(cpu_samples)
	var wall_summary := _summary(wall_samples)
	var gpu_timer_available := float(gpu_summary.get("max_ms", 0.0)) > 0.0
	var report := {
		"schema_version": 1,
		"godot_version": String(Engine.get_version_info().get("string", "unknown")),
		"platform": OS.get_name(),
		"display_server": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_driver_name(),
		"family": _family,
		"material": _mode,
		"count": _count,
		"viewport": {
			"width": int(get_viewport().get_visible_rect().size.x),
			"height": int(get_viewport().get_visible_rect().size.y),
		},
		"frames": _frames,
		"warmup_frames": WARMUP_FRAMES,
		"sample_count": _frames,
		"sync_mode": "pre_measure_drain" if _force_sync else "none",
		"gpu_timer_available": gpu_timer_available,
		"gpu_timer_note": (
			"measured"
			if gpu_timer_available
			else "backend returned zero for every viewport GPU timing sample"
		),
		"gpu": gpu_summary,
		"cpu": cpu_summary,
		"wall": wall_summary,
		"options": _opts,
	}
	print("GEL_PERF family=%s mode=%s count=%d viewport=%s sync=%s gpu=%s cpu=%s wall=%s opts=%s" % [
		_family,
		_mode,
		_count,
		str(get_viewport().get_visible_rect().size),
		_force_sync,
		_summary_text(gpu_summary),
		_summary_text(cpu_summary),
		_summary_text(wall_summary),
		_opts,
	])
	print("GEL_PERF_GPU_TIMER available=%s renderer=%s display=%s" % [
		str(gpu_timer_available),
		report["renderer"],
		report["display_server"],
	])
	if not _out_path.is_empty() and not _write_report(report):
		return false
	return true


func _summary(samples: Array[float]) -> Dictionary:
	var sorted_samples := samples.duplicate()
	sorted_samples.sort()
	var total := 0.0
	for sample in sorted_samples:
		total += sample
	var mean := total / float(sorted_samples.size())
	var p95: float = float(sorted_samples[
		mini(int(float(sorted_samples.size()) * 0.95), sorted_samples.size() - 1)
	])
	return {
		"sample_count": sorted_samples.size(),
		"mean_ms": snappedf(mean, 0.001),
		"p95_ms": snappedf(p95, 0.001),
		"max_ms": snappedf(float(sorted_samples[-1]), 0.001),
	}


func _summary_text(summary: Dictionary) -> String:
	return "mean_ms=%.3f,p95_ms=%.3f,max_ms=%.3f" % [
		float(summary.get("mean_ms", 0.0)),
		float(summary.get("p95_ms", 0.0)),
		float(summary.get("max_ms", 0.0)),
	]


func _write_report(report: Dictionary) -> bool:
	if not _validate_out_path():
		return false
	var path := _globalized_out_path()
	var parent_dir := path.get_base_dir()
	if parent_dir.is_empty():
		push_error("gel_perf.gd: report path has no parent directory")
		return false
	var directory_error := DirAccess.make_dir_recursive_absolute(parent_dir)
	if directory_error != OK and not DirAccess.dir_exists_absolute(parent_dir):
		push_error(
			"gel_perf.gd: cannot create report directory %s (%s)"
			% [parent_dir, error_string(directory_error)]
		)
		return false
	if not _validate_out_path():
		push_error("gel_perf.gd: report path became unsafe before write")
		return false
	var recovery_error := _recover_orphaned_report_backup(path)
	if recovery_error != OK:
		push_error(
			"gel_perf.gd: cannot recover interrupted report transaction %s (%s)"
			% [path, error_string(recovery_error)]
		)
		return false
	var temporary_path := _reserve_report_sibling(path, "tmp")
	if temporary_path.is_empty():
		push_error("gel_perf.gd: cannot reserve transactional report beside %s" % path)
		return false
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_error("gel_perf.gd: cannot open transactional report %s" % temporary_path)
		return false
	var encoded := JSON.stringify(report, "\t", false)
	file.store_string(encoded)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary_path)
		push_error(
			"gel_perf.gd: transactional write failed %s (%s)"
			% [temporary_path, error_string(write_error)]
		)
		return false
	if not _verify_report_file(temporary_path, encoded):
		DirAccess.remove_absolute(temporary_path)
		push_error("gel_perf.gd: transactional report failed reopen validation")
		return false
	if not _validate_out_path():
		DirAccess.remove_absolute(temporary_path)
		push_error("gel_perf.gd: report path became unsafe before publish")
		return false
	if not _transactionally_publish_report(temporary_path, path, encoded):
		return false
	print("GEL_PERF_REPORT %s" % path)
	return true


func _validate_out_path() -> bool:
	var normalized := _out_path.strip_edges().replace("\\", "/")
	if normalized.is_empty() or normalized.to_utf8_buffer().has(0):
		push_error("gel_perf.gd: --out must name a JSON file")
		return false
	if normalized.ends_with("/") or normalized.get_extension().to_lower() != "json":
		push_error("gel_perf.gd: --out must name a .json file")
		return false
	if normalized.contains("/../") or normalized.ends_with("/.."):
		push_error("gel_perf.gd: --out traversal is not allowed")
		return false
	if normalized.begins_with("res://"):
		push_error("gel_perf.gd: --out cannot write below res://")
		return false

	var absolute_path := ""
	var allowed_root := ""
	if normalized.begins_with("user://"):
		allowed_root = ProjectSettings.globalize_path("user://").replace("\\", "/").simplify_path()
		absolute_path = ProjectSettings.globalize_path(normalized).replace("\\", "/").simplify_path()
	elif normalized.is_absolute_path():
		absolute_path = normalized.simplify_path()
		var temp_root := OS.get_temp_dir().replace("\\", "/").simplify_path()
		var outputs_root := _repository_outputs_root()
		if _path_is_within(absolute_path, temp_root):
			allowed_root = temp_root
		elif _path_is_within(absolute_path, outputs_root):
			allowed_root = outputs_root
		else:
			push_error(
				"gel_perf.gd: absolute --out must be below the OS temporary directory or repository outputs/"
			)
			return false
	elif normalized.begins_with("outputs/"):
		allowed_root = _repository_outputs_root()
		absolute_path = allowed_root.path_join(normalized.trim_prefix("outputs/")).simplify_path()
	else:
		push_error("gel_perf.gd: relative --out must begin with outputs/")
		return false

	if (
		not _path_is_within(absolute_path, allowed_root)
		or _same_filesystem_path(absolute_path, allowed_root)
	):
		push_error("gel_perf.gd: --out escaped its allowed root")
		return false
	if DirAccess.dir_exists_absolute(absolute_path):
		push_error("gel_perf.gd: --out names a directory")
		return false
	if _path_crosses_link(absolute_path, allowed_root):
		push_error("gel_perf.gd: --out crosses a symbolic link")
		return false

	var player_save := ProjectSettings.globalize_path(
		"user://immune_demo_save.json"
	).replace("\\", "/").simplify_path()
	if _same_filesystem_path(absolute_path, player_save):
		push_error("gel_perf.gd: --out must not name or alias the player save")
		return false
	if ResearchState.has_method("active_save_path"):
		var active_save := ProjectSettings.globalize_path(
			str(ResearchState.call("active_save_path"))
		).replace("\\", "/").simplify_path()
		if _same_filesystem_path(absolute_path, active_save):
			push_error("gel_perf.gd: --out must not name or alias the active save")
			return false
	return true


func _globalized_out_path() -> String:
	if _out_path.begins_with("user://"):
		return ProjectSettings.globalize_path(_out_path).replace("\\", "/").simplify_path()
	var normalized := _out_path.replace("\\", "/")
	if normalized.is_absolute_path():
		return normalized.simplify_path()
	return _repository_outputs_root().path_join(normalized.trim_prefix("outputs/")).simplify_path()


func _repository_outputs_root() -> String:
	var project_root := ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path()
	return project_root.get_base_dir().get_base_dir().path_join("outputs").simplify_path()


func _path_is_within(path: String, root_path: String) -> bool:
	var normalized_path := _filesystem_compare_path(path)
	var normalized_root := _filesystem_compare_path(root_path)
	return normalized_path == normalized_root or normalized_path.begins_with(normalized_root + "/")


func _same_filesystem_path(left: String, right: String) -> bool:
	return _filesystem_compare_path(left) == _filesystem_compare_path(right)


func _filesystem_compare_path(path: String) -> String:
	var normalized := path.replace("\\", "/").simplify_path().trim_suffix("/")
	return normalized.to_lower() if OS.get_name() in ["Windows", "macOS"] else normalized


func _path_crosses_link(path: String, trusted_root: String) -> bool:
	var normalized_path := path.replace("\\", "/").simplify_path()
	var normalized_root := trusted_root.replace("\\", "/").simplify_path().trim_suffix("/")
	if not _path_is_within(normalized_path, normalized_root):
		return true
	var relative := normalized_path.substr(normalized_root.length()).trim_prefix("/")
	var cursor := normalized_root
	for component: String in relative.split("/", false):
		var directory := DirAccess.open(cursor)
		if directory == null:
			return false
		if directory.is_link(component):
			return true
		cursor = cursor.path_join(component)
	return false


func _reserve_report_sibling(absolute_path: String, kind: String) -> String:
	var parent_dir := absolute_path.get_base_dir()
	var file_name := absolute_path.get_file()
	var nonce := "%d-%d-%d-%s" % [
		OS.get_process_id(),
		int(Time.get_unix_time_from_system() * 1000000.0),
		Time.get_ticks_usec(),
		Crypto.new().generate_random_bytes(12).hex_encode(),
	]
	for attempt in REPORT_TRANSACTION_ATTEMPTS:
		var candidate := parent_dir.path_join(
			".%s.%s-%s-%02d" % [file_name, kind, nonce, attempt]
		)
		if not FileAccess.file_exists(candidate) and not DirAccess.dir_exists_absolute(candidate):
			return candidate
	return ""


func _transactionally_publish_report(
	temporary_path: String, absolute_path: String, expected_text: String
) -> bool:
	var backup_path := ""
	if DirAccess.dir_exists_absolute(absolute_path):
		DirAccess.remove_absolute(temporary_path)
		push_error("gel_perf.gd: report target is a directory")
		return false
	if FileAccess.file_exists(absolute_path):
		backup_path = _reserve_report_sibling(absolute_path, "backup")
		if backup_path.is_empty():
			DirAccess.remove_absolute(temporary_path)
			push_error("gel_perf.gd: cannot reserve previous-report backup")
			return false
		var preserve_error := DirAccess.rename_absolute(absolute_path, backup_path)
		if preserve_error != OK:
			DirAccess.remove_absolute(temporary_path)
			push_error(
				"gel_perf.gd: cannot preserve previous report (%s)"
				% error_string(preserve_error)
			)
			return false
	var publish_error := DirAccess.rename_absolute(temporary_path, absolute_path)
	if publish_error != OK:
		_restore_report_backup(absolute_path, backup_path)
		if FileAccess.file_exists(temporary_path):
			DirAccess.remove_absolute(temporary_path)
		push_error(
			"gel_perf.gd: transactional publish failed (%s); previous report remains recoverable"
			% error_string(publish_error)
		)
		return false
	if not _verify_report_file(absolute_path, expected_text):
		_restore_report_backup(absolute_path, backup_path)
		push_error("gel_perf.gd: published report failed verification; previous report remains recoverable")
		return false
	if not backup_path.is_empty() and FileAccess.file_exists(backup_path):
		var cleanup_error := DirAccess.remove_absolute(backup_path)
		if cleanup_error != OK:
			push_warning("gel_perf.gd: verified report backup cleanup failed: %s" % backup_path)
	_cleanup_report_backups(absolute_path)
	return true


func _restore_report_backup(absolute_path: String, backup_path: String) -> void:
	if backup_path.is_empty() or not FileAccess.file_exists(backup_path):
		return
	var displaced_path := ""
	if FileAccess.file_exists(absolute_path):
		displaced_path = _reserve_report_sibling(absolute_path, "failed")
		if displaced_path.is_empty():
			push_error("gel_perf.gd: previous report remains at %s" % backup_path)
			return
		if DirAccess.rename_absolute(absolute_path, displaced_path) != OK:
			push_error("gel_perf.gd: previous report remains at %s" % backup_path)
			return
	elif DirAccess.dir_exists_absolute(absolute_path):
		push_error("gel_perf.gd: previous report remains at %s" % backup_path)
		return
	var restore_error := DirAccess.rename_absolute(backup_path, absolute_path)
	if restore_error != OK:
		push_error(
			"gel_perf.gd: restore failed; previous report remains at %s (%s)"
			% [backup_path, error_string(restore_error)]
		)
		return
	print("GEL_PERF_REPORT_TRANSACTION_RESTORED %s" % absolute_path)
	if not displaced_path.is_empty() and FileAccess.file_exists(displaced_path):
		DirAccess.remove_absolute(displaced_path)


func _recover_orphaned_report_backup(absolute_path: String) -> Error:
	if FileAccess.file_exists(absolute_path):
		return OK
	if DirAccess.dir_exists_absolute(absolute_path):
		return ERR_INVALID_PARAMETER
	var parent_path := absolute_path.get_base_dir()
	var directory := DirAccess.open(parent_path)
	if directory == null:
		return OK
	directory.include_hidden = true
	var prefix := ".%s.backup-" % absolute_path.get_file()
	var backups: Array[String] = []
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if _filesystem_compare_path(entry).begins_with(_filesystem_compare_path(prefix)):
			if directory.current_is_dir() or directory.is_link(entry):
				directory.list_dir_end()
				return ERR_INVALID_PARAMETER
			var candidate := parent_path.path_join(entry)
			if _verify_report_file(candidate):
				backups.append(candidate)
		entry = directory.get_next()
	directory.list_dir_end()
	if backups.is_empty():
		return OK
	backups.sort_custom(func(left: String, right: String) -> bool:
		return FileAccess.get_modified_time(left) > FileAccess.get_modified_time(right)
	)
	var backup_path := backups[0]
	var recovery_error := DirAccess.rename_absolute(backup_path, absolute_path)
	if recovery_error != OK:
		return recovery_error
	if not _verify_report_file(absolute_path):
		return ERR_FILE_CORRUPT
	print("GEL_PERF_REPORT_TRANSACTION_RECOVERED path=%s backup=%s" % [absolute_path, backup_path])
	return OK


func _verify_report_file(path: String, expected_text: String = "") -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() <= 0:
		return false
	var text := file.get_as_text()
	file.close()
	if not expected_text.is_empty() and text != expected_text:
		return false
	var parsed: Variant = JSON.parse_string(text)
	return parsed is Dictionary and _report_schema_error(parsed as Dictionary).is_empty()


func _report_schema_error(report: Dictionary) -> String:
	var required_fields: PackedStringArray = [
		"schema_version", "godot_version", "platform", "display_server", "renderer",
		"family", "material", "count", "viewport", "frames", "warmup_frames",
		"sample_count", "sync_mode", "gpu_timer_available", "gpu_timer_note",
		"gpu", "cpu", "wall", "options",
	]
	for field: String in required_fields:
		if not report.has(field):
			return "missing required gel report field %s" % field
	if not _json_integer_equals(report["schema_version"], 1):
		return "schema_version must equal 1"
	for field: String in ["godot_version", "platform", "display_server", "renderer"]:
		if report[field] is not String or String(report[field]).is_empty():
			return "%s must be a non-empty string" % field
	if report["family"] is not String or not MESH_CANDIDATES.has(String(report["family"])):
		return "family must name a supported measured mesh"
	if report["material"] is not String or String(report["material"]) not in VALID_MATERIALS:
		return "material must be gel, standard, or none"
	if not _json_integer_in_range(report["count"], 1, 200):
		return "count must be a bounded integer"
	if not _json_integer_in_range(report["frames"], 30, 4000):
		return "frames must be a bounded integer"
	var frame_count := int(report["frames"])
	if not _json_integer_equals(report["warmup_frames"], WARMUP_FRAMES):
		return "warmup_frames does not match the harness contract"
	if not _json_integer_equals(report["sample_count"], frame_count):
		return "sample_count must equal frames"
	if report["viewport"] is not Dictionary:
		return "viewport must be a dictionary"
	var viewport := report["viewport"] as Dictionary
	if (
		not viewport.has("width")
		or not viewport.has("height")
		or not _json_integer_in_range(viewport["width"], 1, 32768)
		or not _json_integer_in_range(viewport["height"], 1, 32768)
	):
		return "viewport width/height must be positive bounded integers"
	if report["sync_mode"] is not String or String(report["sync_mode"]) not in [
		"none", "pre_measure_drain",
	]:
		return "sync_mode is invalid"
	if report["gpu_timer_available"] is not bool or report["gpu_timer_note"] is not String:
		return "GPU timer availability/note types are invalid"
	for summary_name: String in ["gpu", "cpu", "wall"]:
		var summary_error := _summary_schema_error(
			report[summary_name], summary_name, frame_count
		)
		if not summary_error.is_empty():
			return summary_error
	var gpu := report["gpu"] as Dictionary
	if bool(report["gpu_timer_available"]):
		if String(report["gpu_timer_note"]) != "measured" or float(gpu["max_ms"]) <= 0.0:
			return "available GPU timer must report measured positive timing"
	else:
		if (
			String(report["gpu_timer_note"])
			!= "backend returned zero for every viewport GPU timing sample"
			or float(gpu["mean_ms"]) != 0.0
			or float(gpu["p95_ms"]) != 0.0
			or float(gpu["max_ms"]) != 0.0
		):
			return "unavailable GPU timer fields are internally inconsistent"
	if report["options"] is not Dictionary:
		return "options must be a dictionary"
	var options := report["options"] as Dictionary
	if String(report["material"]) != "gel" and not options.is_empty():
		return "non-gel report cannot contain gel overrides"
	for raw_key: Variant in options:
		if raw_key is not String or String(raw_key).is_empty():
			return "option keys must be non-empty strings"
		var value: Variant = options[raw_key]
		if value is bool:
			continue
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
			return "option values must be booleans or finite numbers"
	return ""


func _summary_schema_error(raw_summary: Variant, name: String, frame_count: int) -> String:
	if raw_summary is not Dictionary:
		return "%s summary must be a dictionary" % name
	var summary := raw_summary as Dictionary
	for field: String in ["sample_count", "mean_ms", "p95_ms", "max_ms"]:
		if not summary.has(field):
			return "%s summary is missing %s" % [name, field]
	if not _json_integer_equals(summary["sample_count"], frame_count):
		return "%s sample_count must equal frames" % name
	for field: String in ["mean_ms", "p95_ms", "max_ms"]:
		var value: Variant = summary[field]
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
			return "%s %s must be finite" % [name, field]
		if float(value) < 0.0:
			return "%s %s cannot be negative" % [name, field]
	if (
		float(summary["mean_ms"]) > float(summary["max_ms"])
		or float(summary["p95_ms"]) > float(summary["max_ms"])
	):
		return "%s summary exceeds its maximum" % name
	return ""


func _json_integer_equals(raw_value: Variant, expected: int) -> bool:
	return (
		typeof(raw_value) in [TYPE_INT, TYPE_FLOAT]
		and is_finite(float(raw_value))
		and float(raw_value) == float(expected)
	)


func _json_integer_in_range(raw_value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(raw_value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(raw_value)):
		return false
	var value := float(raw_value)
	return value == floorf(value) and value >= float(minimum) and value <= float(maximum)


func _cleanup_report_backups(absolute_path: String) -> void:
	var directory := DirAccess.open(absolute_path.get_base_dir())
	if directory == null:
		return
	directory.include_hidden = true
	var prefix := ".%s.backup-" % absolute_path.get_file()
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if (
			_filesystem_compare_path(entry).begins_with(_filesystem_compare_path(prefix))
			and not directory.current_is_dir()
			and not directory.is_link(entry)
		):
			DirAccess.remove_absolute(absolute_path.get_base_dir().path_join(entry))
		entry = directory.get_next()
	directory.list_dir_end()


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_mesh_instances(child))
	return out


func _user_args() -> Dictionary:
	var out := {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			push_error("gel_perf.gd: unexpected positional argument '%s'" % arg)
			return {"ok": false}
		var pair := arg.trim_prefix("--").split("=", true, 1)
		var key := String(pair[0])
		if out.has(key):
			push_error("gel_perf.gd: duplicate option --%s" % key)
			return {"ok": false}
		if pair.size() != 2:
			push_error("gel_perf.gd: --%s requires a value" % key)
			return {"ok": false}
		out[key] = pair[1]
	return {"ok": true, "args": out}


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
