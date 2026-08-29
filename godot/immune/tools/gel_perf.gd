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

var _count := 10
var _frames := 240
var _mode := "gel"
var _family := "T"
var _force_sync := false
var _out_path := ""
var _opts := {}


func _ready() -> void:
	# Compatibility/Metal can report a zero GPU timer even when viewport timing is
	# enabled. Disable VSync and keep CPU + wall-frame samples as honest fallbacks.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var args := _user_args()
	_count = clampi(int(args.get("count", "10")), 1, 200)
	_frames = clampi(int(args.get("frames", "240")), 30, 4000)
	_mode = String(args.get("material", "gel"))
	_family = String(args.get("family", "T")).to_upper()
	_force_sync = String(args.get("sync", "false")).to_lower() == "true"
	_out_path = String(args.get("out", ""))
	if not MESH_CANDIDATES.has(_family):
		push_error("gel_perf.gd: unsupported family %s" % _family)
		get_tree().quit(2)
		return
	# Same --set=name:value form as gel_preview, so a cost can be attributed to one
	# feature by switching it off here rather than by guessing.
	for entry in String(args.get("set", "")).split(",", false):
		var pair := entry.split(":", true, 1)
		if pair.size() != 2:
			continue
		var key := pair[0].strip_edges()
		var value := pair[1].strip_edges().to_lower()
		if value == "true" or value == "false":
			_opts[key] = value == "true"
		elif value.is_valid_float():
			_opts[key] = value.to_float()
	_build_stage()
	if not _spawn():
		get_tree().quit(3)
		return
	if not await _measure():
		get_tree().quit(4)
		return
	get_tree().quit(0)


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
				_Look.apply_gel(node, _family, _opts)
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
	var path := _out_path
	if path.begins_with("user://") or path.begins_with("res://"):
		path = ProjectSettings.globalize_path(path)
	var parent_dir := path.get_base_dir()
	if not parent_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(parent_dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("gel_perf.gd: cannot write %s" % path)
		return false
	file.store_string(JSON.stringify(report, "\t", false))
	file.close()
	print("GEL_PERF_REPORT %s" % path)
	return true


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
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2:
			out[pair[0]] = pair[1]
	return out
