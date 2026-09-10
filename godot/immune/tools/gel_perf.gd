extends Node3D

## GPU cost check for the production wet-gel character. Renders N copies of the
## selected authored runtime scene and reports measured render time per frame.
##
## Run (needs a real window, same as the shot harness):
##   godot --path <proj> --resolution 1280x720 res://tools/gel_perf.tscn -- \
##     --count=10 [--frames=240] [--family=T] [--source=character|reference] \
##     [--material=gel|standard]
## Release ABBA evidence additionally supplies the same --run-id to all four
## launches plus --sequence=A1|B1|B2|A2 and an absolute --out path. Those
## sequences fail before spawning unless the complete 4.7.2 Forward+/Metal
## T/character/gel/20/1920x1080/4000 contract and the exact formal-only
## --capture-hold-ms=35000 keepalive are active.
##
## `--source=character` is the default and includes the exact production body,
## animation/runtime bridge, and duty kit. `reference` isolates its authored body.
## Excluded Meshy/Tripo GLBs are never auto-selected: inspecting one requires both
## `--source=legacy-glb` and an explicit whitelisted `--mesh=...`. `none` is valid
## only in that diagnostic mode; production comparisons use gel or standard.

const _Look := preload("res://characters/family_look.gd")
const _Gel := preload("res://characters/gel/gel_look.gd")
const _GelProfiles := preload("res://characters/gel/gel_profiles.gd")
const _LightContract := preload("res://characters/gel/light_contract.gd")

const FAMILIES: PackedStringArray = ["T", "B", "M", "N", "A", "D"]
const VALID_SOURCES: PackedStringArray = ["character", "reference", "legacy-glb"]
const REFERENCE_SCENES := {
	"T": "res://characters/base_t/reference_body.tscn",
	"B": "res://characters/base_b/reference_body.tscn",
	"M": "res://characters/base_m/authored_body.tscn",
	"N": "res://characters/base_n/reference_body.tscn",
	"A": "res://characters/base_a/reference_body.tscn",
	"D": "res://characters/base_d/reference_body.tscn",
}
## These excluded assets remain available only as explicitly named diagnostics.
## There is deliberately no first-existing-candidate fallback.
const LEGACY_GLB_SCENES: Dictionary = {
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
const FORMAL_CAPTURE_HOLD_MS := 35000
const MAX_CAPTURE_HOLD_MS := 60000
const CAPTURE_HOLD_CLOCK_TOLERANCE_MS := 1000
const CAPTURE_SEQUENCE_INDEX := {
	"A1": 1,
	"B1": 2,
	"B2": 3,
	"A2": 4,
}
const CAPTURE_LOOK_FOR_SEQUENCE := {
	"A1": "v8_5",
	"B1": "v8_6",
	"B2": "v8_6",
	"A2": "v8_5",
}
## Versioned canonical stream used to bind a formal GPU report to the ArrayMesh
## that Godot actually imported and handed to the production body. The raw GLB
## digest alone cannot detect a stale `.godot/imported/*.scn` cache entry.
const RUNTIME_MESH_HASH_SCHEMA := "godot-4.7.2-mesh-arrays-v1"
const T_SCULPT_ASSET_FOR_REVISION := {
	"v8_5": {
		"path": "res://characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb",
		"sha256": "8f14cfe59a508df413e4d53218f30bbf316e7e5d31e42154b2916a0bd5669294",
		"revision_label": "r4",
		"resource_name": "V8.5-AuthoredSculpt-T-r4",
		"runtime_mesh_hash_schema": RUNTIME_MESH_HASH_SCHEMA,
		"runtime_mesh_sha256": "ce95be01d9b0b1272c74760f8c8e1d997baa0428e308a8cf50afb78cd77fbc4d",
		"runtime_mesh_surface_count": 1,
		"runtime_mesh_vertex_count": 6002,
		"runtime_mesh_normal_count": 6002,
		"runtime_mesh_index_count": 36000,
		"runtime_mesh_surfaces": [{
			"surface_index": 0,
			"primitive": Mesh.PRIMITIVE_TRIANGLES,
			"format": 34896613383,
			"name": "",
			"vertex_count": 6002,
			"normal_count": 6002,
			"index_count": 36000,
		}],
	},
	"v8_6": {
		"path": "res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb",
		"sha256": "3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3",
		"revision_label": "r7-2",
		"resource_name": "V8.6-AuthoredSculpt-T-r7-2",
		"runtime_mesh_hash_schema": RUNTIME_MESH_HASH_SCHEMA,
		"runtime_mesh_sha256": "d5efe6491bdc51aadafe4aaccb5c1c3321376e29f6949e123a458780bf57f1de",
		"runtime_mesh_surface_count": 1,
		"runtime_mesh_vertex_count": 6002,
		"runtime_mesh_normal_count": 6002,
		"runtime_mesh_index_count": 36000,
		"runtime_mesh_surfaces": [{
			"surface_index": 0,
			"primitive": Mesh.PRIMITIVE_TRIANGLES,
			"format": 34896613383,
			"name": "",
			"vertex_count": 6002,
			"normal_count": 6002,
			"index_count": 36000,
		}],
	},
}
const CAPTURE_ANIMATIONS: PackedStringArray = [
	"attack", "defeat", "hit", "idle", "move", "move_start", "move_stop",
	"plant", "relay_close", "relay_glide", "relay_open", "skill_cast", "uproot", "victory",
]

const ALLOWED_ARGS: Array[String] = [
	"count", "frames", "material", "family", "source", "mesh", "sync", "out",
	"set", "save-path", "run-id", "sequence", "capture-hold-ms",
]
const VALID_MATERIALS: Array[String] = ["gel", "standard", "none"]
const EYE_SHADER_PATH := "res://characters/gel/gel_eye.gdshader"
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
const RUNTIME_MANAGED_CONTROLS: PackedStringArray = [
	"liquid_flow_motion_mix",
	"liquid_flow_direction",
	"liquid_body_deform_strength",
	"liquid_body_lag",
	"liquid_body_squash",
	"liquid_turn_shear",
	"liquid_contact_amount",
	"liquid_contact_normal",
]

var _count := 10
var _frames := 240
var _mode := "gel"
var _family := "T"
var _source := "character"
var _subject_path := ""
var _mesh_path := ""
var _force_sync := false
var _out_path := ""
var _run_id := ""
var _sequence := "adhoc"
var _sequence_index := 0
var _capture_hold_ms := 0
var _measurement_started_unix_ms := 0
var _runtime_identity := {}
var _opts := {}
var _material_stats := {
	"visible_mesh_instances": 0,
	"wet_materials": 0,
	"shell_materials": 0,
	"eye_materials": 0,
	"standard_replacements": 0,
}


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
	if not _capture_runtime_environment_is_valid():
		get_tree().quit(2)
		return
	if not _prepare_formal_capture_window():
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
	if not _configure_capture_identity(args):
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
	if _family not in FAMILIES:
		push_error("gel_perf.gd: unsupported family %s" % _family)
		return false
	if not _configure_subject_source(args):
		return false
	if _mode == "none" and _source != "legacy-glb":
		push_error(
			"gel_perf.gd: --material=none is legacy diagnostic-only; "
			+ "production sources require gel or standard"
		)
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
		return _capture_configuration_is_valid()
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
	if _source == "character":
		for control in RUNTIME_MANAGED_CONTROLS:
			if _opts.has(control):
				push_error(
					"gel_perf.gd: --set control '%s' is runtime-managed in " % control
					+ "--source=character; use --source=reference for a static ablation"
				)
				return false
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
	return _capture_configuration_is_valid()


func _configure_capture_identity(args: Dictionary) -> bool:
	var has_run_id := args.has("run-id")
	var has_sequence := args.has("sequence")
	var has_capture_hold := args.has("capture-hold-ms")
	if has_run_id != has_sequence:
		push_error("gel_perf.gd: --run-id and --sequence must be supplied together")
		return false
	if not has_run_id:
		if has_capture_hold:
			push_error("gel_perf.gd: --capture-hold-ms is valid only for a formal ABBA sequence")
			return false
		_run_id = "adhoc-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
		_sequence = "adhoc"
		_sequence_index = 0
		_capture_hold_ms = 0
		return true
	_run_id = String(args["run-id"]).strip_edges()
	if not _safe_run_id(_run_id):
		push_error("gel_perf.gd: --run-id must use 8-128 safe identifier characters")
		return false
	_sequence = String(args["sequence"]).strip_edges().to_upper()
	if not CAPTURE_SEQUENCE_INDEX.has(_sequence):
		push_error("gel_perf.gd: --sequence must be A1, B1, B2, or A2")
		return false
	_sequence_index = int(CAPTURE_SEQUENCE_INDEX[_sequence])
	if not has_capture_hold:
		push_error(
			"gel_perf.gd: formal ABBA capture requires --capture-hold-ms=%d"
			% FORMAL_CAPTURE_HOLD_MS
		)
		return false
	var parsed_hold := _parse_bounded_int(
		"capture-hold-ms",
		String(args["capture-hold-ms"]),
		1000,
		MAX_CAPTURE_HOLD_MS
	)
	if not bool(parsed_hold.get("ok", false)):
		return false
	_capture_hold_ms = int(parsed_hold["value"])
	if _capture_hold_ms != FORMAL_CAPTURE_HOLD_MS:
		push_error(
			"gel_perf.gd: formal ABBA capture requires --capture-hold-ms=%d exactly"
			% FORMAL_CAPTURE_HOLD_MS
		)
		return false
	return true


func _capture_configuration_is_valid() -> bool:
	if _sequence == "adhoc":
		return true
	var expected_look := String(CAPTURE_LOOK_FOR_SEQUENCE[_sequence])
	var actual_look := _GelProfiles.selected_look()
	if actual_look != expected_look:
		push_error(
			"gel_perf.gd: sequence %s requires gel look %s, got %s"
			% [_sequence, expected_look, actual_look]
		)
		return false
	if (
		_family != "T"
		or _source != "character"
		or _subject_path != "res://characters/base_t/character.tscn"
		or _mode != "gel"
		or _count != 20
		or _frames != 4000
		or _force_sync
		or _capture_hold_ms != FORMAL_CAPTURE_HOLD_MS
		or _out_path.is_empty()
		or not _opts.is_empty()
	):
		push_error(
			"gel_perf.gd: ABBA capture requires T/character/gel/count=20/frames=4000/"
			+ "sync=false, capture-hold-ms=35000, --out, and no --set overrides"
		)
		return false
	return true


func _capture_runtime_environment_is_valid() -> bool:
	if _sequence == "adhoc":
		return true
	var viewport_size := get_viewport().get_visible_rect().size
	if (
		String(Engine.get_version_info().get("string", "")) != "4.7.2-stable (official)"
		or OS.get_name() != "macOS"
		or DisplayServer.get_name() != "macOS"
		or RenderingServer.get_current_rendering_method() != "forward_plus"
		or RenderingServer.get_current_rendering_driver_name() != "metal"
		or int(viewport_size.x) != 1920
		or int(viewport_size.y) != 1080
	):
		push_error(
			"gel_perf.gd: ABBA capture requires Godot 4.7.2 on macOS "
			+ "Forward+/Metal at 1920x1080"
		)
		return false
	return true


func _prepare_formal_capture_window() -> bool:
	if _sequence == "adhoc":
		return true
	# macOS can stop delivering normal frame_post_draw cadence to an occluded
	# headed window. Keep the formal surface visible and request foreground before
	# warm-up so the exact 4,000-frame workload and 8-second trace are comparable.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_move_to_foreground()
	if not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP):
		push_error("gel_perf.gd: formal capture window could not enable always-on-top")
		return false
	return true


func _safe_run_id(value: String) -> bool:
	if value.length() < 8 or value.length() > 128:
		return false
	for index in value.length():
		var code := value.unicode_at(index)
		var is_letter := (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
		var is_digit := code >= 48 and code <= 57
		if index == 0 and not is_letter and not is_digit:
			return false
		if not is_letter and not is_digit and code not in [45, 46, 95]:
			return false
	return true


func _configure_subject_source(args: Dictionary) -> bool:
	_source = String(args.get("source", "character")).strip_edges().to_lower()
	if _source not in VALID_SOURCES:
		push_error("gel_perf.gd: --source must be character, reference, or legacy-glb")
		return false
	_mesh_path = String(args.get("mesh", "")).strip_edges()
	if _source == "legacy-glb":
		if _mesh_path.is_empty():
			push_error(
				"gel_perf.gd: --source=legacy-glb requires "
				+ "--mesh=<known excluded GLB>"
			)
			return false
		var allowed_legacy: Array = LEGACY_GLB_SCENES.get(_family, [])
		if _mesh_path not in allowed_legacy:
			push_error(
				"gel_perf.gd: --mesh is not an approved %s legacy diagnostic GLB"
				% _family
			)
			return false
		_subject_path = _mesh_path
	else:
		if args.has("mesh"):
			push_error(
				"gel_perf.gd: --mesh is valid only with --source=legacy-glb; "
				+ "production scene identity is family-locked"
			)
			return false
		_subject_path = (
			String(_Look.SCENE_PATH[_family])
			if _source == "character"
			else String(REFERENCE_SCENES[_family])
		)
	if not ResourceLoader.exists(_subject_path):
		push_error("gel_perf.gd: measured subject does not exist: %s" % _subject_path)
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
	var packed := load(_subject_path) as PackedScene
	if packed == null:
		push_error("gel_perf.gd: cannot load %s" % _subject_path)
		return false

	var cols := int(ceil(sqrt(float(_count))))
	var rows := int(ceil(float(_count) / float(cols)))
	var step := 1.15
	for i in _count:
		var node := packed.instantiate() as Node3D
		if node == null:
			push_error("gel_perf.gd: %s is not a Node3D scene" % _subject_path)
			return false
		node.name = "MeasuredSubject%03d" % i
		node.position = Vector3(
			(float(i % cols) - float(cols - 1) * 0.5) * step,
			(float(i / cols) - float(rows - 1) * 0.5) * step,
			0.0)
		add_child(node)
		match _mode:
			"gel":
				if _source == "legacy-glb":
					var materials := _Look.apply_gel(node, _family, _opts)
					if not _legacy_options_match(materials):
						return false
					_record_material_stats(
						node,
						materials,
						_shader_materials(node, _Gel.MEMBRANE_SHADER_PATH),
						[],
						0
					)
				elif not _prepare_production_gel(node):
					return false
			"standard":
				if _source == "legacy-glb":
					var legacy_replacements := _replace_legacy_with_standard(node)
					_record_material_stats(node, [], [], [], legacy_replacements)
				else:
					var wet := _shader_materials(node, _Gel.SHADER_PATH)
					var shells := _shader_materials(node, _Gel.MEMBRANE_SHADER_PATH)
					var eyes := _shader_materials(node, EYE_SHADER_PATH)
					if wet.is_empty():
						push_error(
							"gel_perf.gd: production subject exposed no wet-gel materials"
						)
						return false
					var replacements := _replace_production_gel_with_standard(node)
					if replacements == 0:
						push_error("gel_perf.gd: standard control replaced no gel materials")
						return false
					_record_material_stats(node, wet, shells, eyes, replacements)
			_:
				_record_material_stats(node, [], [], [], 0)
		if _source == "character" and _mode == "gel":
			var identity := _production_runtime_identity(node)
			var identity_error := _runtime_identity_contract_error(identity)
			if not identity_error.is_empty():
				push_error(
					"gel_perf.gd: measured subject %d identity failed: %s"
					% [i, identity_error]
				)
				return false
			if _runtime_identity.is_empty():
				_runtime_identity = identity
			elif JSON.stringify(identity) != JSON.stringify(_runtime_identity):
				push_error("gel_perf.gd: production subject identities differ across instances")
				return false

	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 45.0
	camera.position = Vector3(0.0, 0.0, maxf(float(cols), float(rows)) * step * 1.35)
	add_child(camera)
	return true


func _production_runtime_identity(node: Node3D) -> Dictionary:
	var selected_look := _GelProfiles.selected_look()
	var revision := "unknown"
	var body: MeshInstance3D
	var shell: MeshInstance3D
	for mesh in _mesh_instances(node):
		for candidate: String in ["v8_6", "v8_5", "v8_4", "v8_3"]:
			if body == null and bool(mesh.get_meta(StringName("%s_single_mass" % candidate), false)):
				body = mesh
				revision = candidate
			if shell == null and bool(
				mesh.get_meta(StringName("%s_single_mass_shell" % candidate), false)
			):
				shell = mesh
	var asset_path := ""
	var expected_sha256 := ""
	var expected_revision_label := ""
	var expected_resource_name := ""
	if T_SCULPT_ASSET_FOR_REVISION.has(revision):
		var asset := T_SCULPT_ASSET_FOR_REVISION[revision] as Dictionary
		asset_path = String(asset["path"])
		expected_sha256 = String(asset["sha256"])
		expected_revision_label = String(asset["revision_label"])
		expected_resource_name = String(asset["resource_name"])
	var actual_sha256 := FileAccess.get_sha256(asset_path) if not asset_path.is_empty() else ""
	var asset_resource_name := String(body.mesh.resource_name) if body != null and body.mesh != null else ""
	var mesh_fingerprint := _runtime_mesh_fingerprint(body.mesh if body != null else null)
	var asset_revision_label := ""
	var revision_separator := asset_resource_name.rfind("-T-")
	if revision_separator >= 0:
		asset_revision_label = asset_resource_name.substr(revision_separator + 3)
	var authored_sculpt := (
		body != null
		and bool(body.get_meta(StringName("%s_authored_sculpt" % revision), false))
	)
	var animation_player := node.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var animation_catalog: Array[String] = []
	if animation_player != null:
		for animation_name in animation_player.get_animation_list():
			animation_catalog.append(String(animation_name))
		animation_catalog.sort()
	var animation_kind := ""
	if node.has_method("current_animation_kind"):
		animation_kind = String(node.call("current_animation_kind"))
	return {
		"body_revision": revision,
		"asset_path": asset_path,
		"asset_sha256": actual_sha256,
		"expected_asset_sha256": expected_sha256,
		"asset_revision_label": asset_revision_label,
		"expected_asset_revision_label": expected_revision_label,
		"asset_resource_name": asset_resource_name,
		"expected_asset_resource_name": expected_resource_name,
		"runtime_mesh_hash_schema": String(mesh_fingerprint.get("hash_schema", "")),
		"runtime_mesh_sha256": String(mesh_fingerprint.get("sha256", "")),
		"runtime_mesh_surface_count": int(mesh_fingerprint.get("surface_count", 0)),
		"runtime_mesh_vertex_count": int(mesh_fingerprint.get("vertex_count", 0)),
		"runtime_mesh_normal_count": int(mesh_fingerprint.get("normal_count", 0)),
		"runtime_mesh_index_count": int(mesh_fingerprint.get("index_count", 0)),
		"runtime_mesh_surfaces": (mesh_fingerprint.get("surfaces", []) as Array).duplicate(true),
		"runtime_mesh_error": String(mesh_fingerprint.get("error", "")),
		"authored_sculpt": authored_sculpt,
		"fallback_used": selected_look in ["v8_5", "v8_6"] and (
			revision != selected_look or not authored_sculpt
		),
		"body_build_failed": _tree_has_truthy_meta(node, &"authored_body_build_failed"),
		"shell_present": shell != null,
		"shell_visible": shell != null and shell.is_visible_in_tree(),
		"shell_shares_body_mesh": body != null and shell != null and body.mesh == shell.mesh,
		"animation_catalog": animation_catalog,
		"animation_count": animation_catalog.size(),
		"active_animation": (
			String(animation_player.current_animation) if animation_player != null else ""
		),
		"animation_playing": animation_player != null and animation_player.is_playing(),
		"animation_kind": animation_kind,
	}


## Hashes the immutable topology consumed by the renderer, rather than the raw
## source file. Each update is a length/type-delimited Variant encoding, and the
## schema is pinned to the Godot version required by the formal capture contract.
func _runtime_mesh_fingerprint(mesh: Mesh) -> Dictionary:
	if mesh == null:
		return {"ok": false, "error": "body mesh is missing"}
	var surface_count := mesh.get_surface_count()
	if surface_count <= 0:
		return {"ok": false, "error": "body mesh has no surfaces"}
	var context := HashingContext.new()
	var hash_error := context.start(HashingContext.HASH_SHA256)
	if hash_error != OK:
		return {"ok": false, "error": "mesh hash context start failed (%d)" % hash_error}
	hash_error = context.update(var_to_bytes([
		RUNTIME_MESH_HASH_SCHEMA,
		surface_count,
		mesh.get_blend_shape_count(),
	]))
	if hash_error != OK:
		return {"ok": false, "error": "mesh hash header update failed (%d)" % hash_error}

	var total_vertices := 0
	var total_normals := 0
	var total_indices := 0
	var surfaces: Array[Dictionary] = []
	for surface_index in surface_count:
		var arrays := mesh.surface_get_arrays(surface_index)
		if arrays.size() != Mesh.ARRAY_MAX:
			return {
				"ok": false,
				"error": "surface %d array slot count is not Mesh.ARRAY_MAX" % surface_index,
			}
		if (
			arrays[Mesh.ARRAY_VERTEX] is not PackedVector3Array
			or arrays[Mesh.ARRAY_NORMAL] is not PackedVector3Array
			or arrays[Mesh.ARRAY_INDEX] is not PackedInt32Array
		):
			return {
				"ok": false,
				"error": "surface %d is missing packed vertices, normals, or indices"
				% surface_index,
			}
		var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var normals := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
		var indices := arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
		var primitive: int = mesh.surface_get_primitive_type(surface_index)
		var surface_format: int = mesh.surface_get_format(surface_index)
		var surface_name: String = mesh.surface_get_name(surface_index)
		if vertices.is_empty():
			return {"ok": false, "error": "surface %d has no vertices" % surface_index}
		if normals.size() != vertices.size():
			return {
				"ok": false,
				"error": "surface %d normal count does not match vertex count" % surface_index,
			}
		if indices.is_empty():
			return {"ok": false, "error": "surface %d has no indices" % surface_index}
		if primitive == Mesh.PRIMITIVE_TRIANGLES and indices.size() % 3 != 0:
			return {
				"ok": false,
				"error": "surface %d triangle index count is not divisible by three"
				% surface_index,
			}
		var metadata := {
			"surface_index": surface_index,
			"primitive": primitive,
			"format": surface_format,
			"name": surface_name,
			"vertex_count": vertices.size(),
			"normal_count": normals.size(),
			"index_count": indices.size(),
		}
		for payload in [
			[
				"surface_metadata",
				surface_index,
				primitive,
				surface_format,
				surface_name,
				vertices.size(),
				normals.size(),
				indices.size(),
			],
			["vertices", vertices],
			["normals", normals],
			["indices", indices],
		]:
			hash_error = context.update(var_to_bytes(payload))
			if hash_error != OK:
				return {
					"ok": false,
					"error": "surface %d mesh hash update failed (%d)"
					% [surface_index, hash_error],
				}
		total_vertices += vertices.size()
		total_normals += normals.size()
		total_indices += indices.size()
		surfaces.append(metadata)

	return {
		"ok": true,
		"hash_schema": RUNTIME_MESH_HASH_SCHEMA,
		"sha256": context.finish().hex_encode(),
		"surface_count": surface_count,
		"vertex_count": total_vertices,
		"normal_count": total_normals,
		"index_count": total_indices,
		"surfaces": surfaces,
	}


func _runtime_identity_contract_error(identity: Dictionary) -> String:
	var selected_look := _GelProfiles.selected_look()
	if selected_look not in ["v8_5", "v8_6"]:
		return ""
	var expected_asset := T_SCULPT_ASSET_FOR_REVISION[selected_look] as Dictionary
	if String(identity.get("body_revision", "")) != selected_look:
		return "body revision does not match the selected look"
	if String(identity.get("asset_path", "")) != String(expected_asset["path"]):
		return "body asset path does not match the locked sculpt"
	if String(identity.get("asset_sha256", "")) != String(expected_asset["sha256"]):
		return "body asset SHA-256 does not match the locked sculpt"
	if String(identity.get("asset_revision_label", "")) != String(expected_asset["revision_label"]):
		return "body asset revision label does not match the locked sculpt"
	if String(identity.get("asset_resource_name", "")) != String(expected_asset["resource_name"]):
		return "body mesh resource name does not match the locked sculpt"
	if not String(identity.get("runtime_mesh_error", "")).is_empty():
		return "runtime body mesh fingerprint failed: %s" % String(identity["runtime_mesh_error"])
	for field: String in ["runtime_mesh_hash_schema", "runtime_mesh_sha256"]:
		if String(identity.get(field, "")) != String(expected_asset[field]):
			return "%s does not match the locked imported runtime mesh" % field
	for field: String in [
		"runtime_mesh_surface_count",
		"runtime_mesh_vertex_count",
		"runtime_mesh_normal_count",
		"runtime_mesh_index_count",
	]:
		if not _json_integer_equals(identity.get(field), int(expected_asset[field])):
			return "%s does not match the locked imported runtime mesh" % field
	if not _runtime_mesh_surfaces_match(
		identity.get("runtime_mesh_surfaces"), expected_asset["runtime_mesh_surfaces"]
	):
		return "runtime_mesh_surfaces does not match the locked imported runtime mesh"
	if not bool(identity.get("authored_sculpt", false)):
		return "authored sculpt marker is missing"
	if bool(identity.get("fallback_used", true)):
		return "a fallback body was selected"
	if bool(identity.get("body_build_failed", true)):
		return "authored body reported a build failure"
	for field: String in ["shell_present", "shell_visible", "shell_shares_body_mesh"]:
		if not bool(identity.get(field, false)):
			return "%s is false" % field
	if int(identity.get("animation_count", 0)) != CAPTURE_ANIMATIONS.size():
		return "animation count does not equal the locked 14-animation catalog"
	if JSON.stringify(identity.get("animation_catalog", [])) != JSON.stringify(CAPTURE_ANIMATIONS):
		return "animation catalog does not equal the locked 14-animation catalog"
	if String(identity.get("active_animation", "")) != "idle":
		return "measured character is not in idle animation"
	if not bool(identity.get("animation_playing", false)):
		return "idle animation is not playing"
	if String(identity.get("animation_kind", "")) != "rest":
		return "animation arbiter is not in rest state"
	return ""


func _runtime_mesh_surfaces_match(actual_value: Variant, expected_value: Variant) -> bool:
	if actual_value is not Array or expected_value is not Array:
		return false
	var actual := actual_value as Array
	var expected := expected_value as Array
	if actual.size() != expected.size():
		return false
	for index in actual.size():
		if actual[index] is not Dictionary or expected[index] is not Dictionary:
			return false
		var actual_surface := actual[index] as Dictionary
		var expected_surface := expected[index] as Dictionary
		for field: String in [
			"surface_index", "primitive", "format",
			"vertex_count", "normal_count", "index_count",
		]:
			if not _json_integer_equals(
				actual_surface.get(field), int(expected_surface.get(field, -1))
			):
				return false
		if String(actual_surface.get("name", "")) != String(expected_surface.get("name", "")):
			return false
	return true


func _tree_has_truthy_meta(node: Node, meta_name: StringName) -> bool:
	if bool(node.get_meta(meta_name, false)):
		return true
	for child in node.get_children():
		if _tree_has_truthy_meta(child, meta_name):
			return true
	return false


func _prepare_production_gel(node: Node) -> bool:
	var wet := _shader_materials(node, _Gel.SHADER_PATH)
	var shells := _shader_materials(node, _Gel.MEMBRANE_SHADER_PATH)
	var eyes := _shader_materials(node, EYE_SHADER_PATH)
	if wet.is_empty():
		push_error("gel_perf.gd: production subject exposed no wet-gel materials")
		return false
	if not _apply_production_options(node, wet, shells):
		return false
	_record_material_stats(node, wet, shells, eyes, 0)
	return true


func _apply_production_options(
	node: Node,
	wet: Array[ShaderMaterial],
	shells: Array[ShaderMaterial]
) -> bool:
	var shell_meshes := _mesh_instances_using_shader(node, _Gel.MEMBRANE_SHADER_PATH)
	if _opts.has("membrane_enabled"):
		var enabled := bool(_opts["membrane_enabled"])
		if enabled:
			if not _production_membrane_enabled(wet, shell_meshes):
				push_error(
					"gel_perf.gd: membrane_enabled=true requested, but the production "
					+ "subject has no membrane"
				)
				return false
		else:
			_set_production_membrane_enabled(wet, shell_meshes, false)

	for raw_key in _opts:
		var key := String(raw_key)
		if key == "membrane_enabled":
			continue
		var targets: Array[ShaderMaterial] = wet
		var shader_name := String(key)
		if MEMBRANE_SET_ALIASES.has(key):
			targets = shells
			shader_name = String(MEMBRANE_SET_ALIASES[key])
		if targets.is_empty():
			push_error("gel_perf.gd: --set control '%s' has no production target" % key)
			return false
		var applied := 0
		for material in targets:
			if material.get_shader_parameter(shader_name) == null:
				continue
			material.set_shader_parameter(shader_name, _opts[raw_key])
			if not _option_values_equal(
				material.get_shader_parameter(shader_name), _opts[raw_key]
			):
				push_error(
					"gel_perf.gd: production --set control '%s' did not survive application"
					% key
				)
				return false
			applied += 1
		if applied == 0:
			push_error(
				"gel_perf.gd: --set control '%s' is not exposed by production materials"
				% key
			)
			return false
	if _opts.has("membrane_enabled"):
		if (
			_production_membrane_enabled(wet, shell_meshes)
			!= bool(_opts["membrane_enabled"])
		):
			push_error("gel_perf.gd: applied production membrane_enabled does not match request")
			return false
	return true


func _set_production_membrane_enabled(
	wet: Array[ShaderMaterial],
	shell_meshes: Array[MeshInstance3D],
	enabled: bool
) -> void:
	for mesh in shell_meshes:
		mesh.visible = enabled
	if enabled:
		return
	for material in wet:
		if _material_uses_shader(material.next_pass, _Gel.MEMBRANE_SHADER_PATH):
			material.next_pass = null


func _production_membrane_enabled(
	wet: Array[ShaderMaterial],
	shell_meshes: Array[MeshInstance3D]
) -> bool:
	for mesh in shell_meshes:
		if mesh.is_visible_in_tree():
			return true
	for material in wet:
		if _material_uses_shader(material.next_pass, _Gel.MEMBRANE_SHADER_PATH):
			return true
	return false


func _replace_legacy_with_standard(node: Node) -> int:
	var replacements := 0
	for mesh in _mesh_instances(node):
		if mesh.mesh == null:
			continue
		mesh.material_override = _Look.jelly_material(_family)
		replacements += 1
	return replacements


func _replace_production_gel_with_standard(node: Node) -> int:
	var replacements := 0
	for mesh in _mesh_instances(node):
		var override_replaced := false
		if _material_is_production_gel(mesh.material_override):
			mesh.material_override = _Look.jelly_material(_family)
			replacements += 1
			override_replaced = true
		if _material_is_production_gel(mesh.material_overlay):
			mesh.material_overlay = _Look.jelly_material(_family)
			replacements += 1
		if override_replaced or mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			if _material_is_production_gel(mesh.get_active_material(surface)):
				mesh.set_surface_override_material(surface, _Look.jelly_material(_family))
				replacements += 1
	return replacements


func _record_material_stats(
	node: Node,
	wet: Array,
	shells: Array,
	eyes: Array,
	standard_replacements: int
) -> void:
	_material_stats["wet_materials"] = int(_material_stats["wet_materials"]) + wet.size()
	_material_stats["shell_materials"] = int(_material_stats["shell_materials"]) + shells.size()
	_material_stats["eye_materials"] = int(_material_stats["eye_materials"]) + eyes.size()
	_material_stats["standard_replacements"] = (
		int(_material_stats["standard_replacements"]) + standard_replacements
	)
	for mesh in _mesh_instances(node):
		if mesh.mesh != null and mesh.is_visible_in_tree():
			_material_stats["visible_mesh_instances"] = (
				int(_material_stats["visible_mesh_instances"]) + 1
			)


func _legacy_options_match(materials: Array[ShaderMaterial]) -> bool:
	if materials.is_empty():
		push_error("gel_perf.gd: legacy gel application produced no measurable materials")
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


func _option_values_equal(actual: Variant, expected: Variant) -> bool:
	if expected is bool:
		return actual is bool and bool(actual) == bool(expected)
	return (
		typeof(actual) in [TYPE_INT, TYPE_FLOAT]
		and typeof(expected) in [TYPE_INT, TYPE_FLOAT]
		and is_equal_approx(float(actual), float(expected))
	)


func _shader_materials(root: Node, shader_path: String) -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	var seen := {}
	for mesh in _mesh_instances(root):
		_append_shader_material(mesh.material_override, shader_path, out, seen)
		_append_shader_material(mesh.material_overlay, shader_path, out, seen)
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			_append_shader_material(mesh.get_active_material(surface), shader_path, out, seen)
	return out


func _append_shader_material(
	material: Material,
	shader_path: String,
	out: Array[ShaderMaterial],
	seen: Dictionary
) -> void:
	if material == null:
		return
	var instance_id := material.get_instance_id()
	if seen.has(instance_id):
		return
	seen[instance_id] = true
	if _material_uses_shader(material, shader_path):
		out.append(material as ShaderMaterial)
	_append_shader_material(material.next_pass, shader_path, out, seen)


func _mesh_instances_using_shader(root: Node, shader_path: String) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for mesh in _mesh_instances(root):
		var direct := _material_uses_shader(mesh.material_override, shader_path)
		direct = direct or _material_uses_shader(mesh.material_overlay, shader_path)
		if not direct and mesh.mesh != null:
			for surface in mesh.mesh.get_surface_count():
				if _material_uses_shader(mesh.get_active_material(surface), shader_path):
					direct = true
					break
		if direct:
			out.append(mesh)
	return out


func _material_is_production_gel(material: Material) -> bool:
	return (
		_material_uses_shader(material, _Gel.SHADER_PATH)
		or _material_uses_shader(material, _Gel.MEMBRANE_SHADER_PATH)
		or _material_uses_shader(material, EYE_SHADER_PATH)
	)


func _material_uses_shader(material: Material, shader_path: String) -> bool:
	return (
		material is ShaderMaterial
		and (material as ShaderMaterial).shader != null
		and (material as ShaderMaterial).shader.resource_path == shader_path
	)


func _measure() -> bool:
	if _sequence != "adhoc":
		DisplayServer.window_move_to_foreground()
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	_measurement_started_unix_ms = int(Time.get_unix_time_from_system() * 1000.0)
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
	var measurement_finished_unix_ms := int(Time.get_unix_time_from_system() * 1000.0)
	var gpu_timer_available := float(gpu_summary.get("max_ms", 0.0)) > 0.0
	var report := {
		"schema_version": 4,
		"run_id": _run_id,
		"sequence": _sequence,
		"sequence_index": _sequence_index,
		"process_pid": OS.get_process_id(),
		"measurement_started_unix_ms": _measurement_started_unix_ms,
		"measurement_finished_unix_ms": measurement_finished_unix_ms,
		"capture_hold_ms": _capture_hold_ms,
		"capture_hold_status": "ready" if _sequence != "adhoc" else "disabled",
		"capture_hold_started_unix_ms": 0,
		"capture_hold_finished_unix_ms": 0,
		"capture_hold_actual_ms": 0,
		"capture_hold_rendered_frames": 0,
		"capture_window_always_on_top": (
			_sequence != "adhoc"
			and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP)
		),
		"gel_look": _GelProfiles.selected_look(),
		"godot_version": String(Engine.get_version_info().get("string", "unknown")),
		"platform": OS.get_name(),
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"renderer": RenderingServer.get_current_rendering_driver_name(),
		"family": _family,
		"source": _source,
		"subject_scene": _subject_path,
		"production_authored": _source != "legacy-glb",
		"legacy_diagnostic": _source == "legacy-glb",
		"material": _mode,
		"count": _count,
		"material_stats": _material_stats.duplicate(true),
		"runtime_identity": _runtime_identity.duplicate(true),
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
	print("GEL_PERF run_id=%s sequence=%s pid=%d look=%s family=%s source=%s scene=%s mode=%s count=%d viewport=%s sync=%s gpu=%s cpu=%s wall=%s opts=%s" % [
		_run_id,
		_sequence,
		OS.get_process_id(),
		_GelProfiles.selected_look(),
		_family,
		_source,
		_subject_path,
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
	if _sequence != "adhoc":
		# Publish a fail-closed ready record so the external trace runner can bind
		# this exact PID. Only the post-hold rewrite changes status to complete.
		if not _write_report(report):
			return false
		return await _complete_formal_capture_hold(report)
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


func _complete_formal_capture_hold(report: Dictionary) -> bool:
	if _sequence == "adhoc" or _capture_hold_ms != FORMAL_CAPTURE_HOLD_MS:
		push_error("gel_perf.gd: invalid formal capture hold state")
		return false
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_move_to_foreground()
	if not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP):
		push_error("gel_perf.gd: formal capture window lost always-on-top state")
		return false
	var started_ticks_ms := Time.get_ticks_msec()
	var started_unix_ms := int(Time.get_unix_time_from_system() * 1000.0)
	print(
		"GEL_PERF_CAPTURE_HOLD_READY run_id=%s sequence=%s pid=%d hold_ms=%d"
		% [_run_id, _sequence, OS.get_process_id(), _capture_hold_ms]
	)
	var rendered_frames := 0
	while Time.get_ticks_msec() - started_ticks_ms < _capture_hold_ms:
		await RenderingServer.frame_post_draw
		rendered_frames += 1
	var actual_ms := Time.get_ticks_msec() - started_ticks_ms
	var finished_unix_ms := int(Time.get_unix_time_from_system() * 1000.0)
	if actual_ms < _capture_hold_ms or rendered_frames <= 0:
		push_error(
			"gel_perf.gd: formal capture hold ended early (%d ms, %d rendered frames)"
			% [actual_ms, rendered_frames]
		)
		return false
	report["capture_hold_status"] = "complete"
	report["capture_hold_started_unix_ms"] = started_unix_ms
	report["capture_hold_finished_unix_ms"] = finished_unix_ms
	report["capture_hold_actual_ms"] = actual_ms
	report["capture_hold_rendered_frames"] = rendered_frames
	if not _write_report(report):
		return false
	print(
		"GEL_PERF_CAPTURE_HOLD_COMPLETE run_id=%s sequence=%s pid=%d actual_ms=%d frames=%d"
		% [_run_id, _sequence, OS.get_process_id(), actual_ms, rendered_frames]
	)
	return true


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
		"schema_version", "run_id", "sequence", "sequence_index", "process_pid",
		"measurement_started_unix_ms", "measurement_finished_unix_ms",
		"capture_hold_ms", "capture_hold_status", "capture_hold_started_unix_ms",
		"capture_hold_finished_unix_ms", "capture_hold_actual_ms",
		"capture_hold_rendered_frames", "capture_window_always_on_top",
		"gel_look", "godot_version", "platform", "display_server",
		"rendering_method", "renderer",
		"family", "source", "subject_scene", "production_authored",
		"legacy_diagnostic", "material", "count", "material_stats", "runtime_identity",
		"viewport",
		"frames", "warmup_frames",
		"sample_count", "sync_mode", "gpu_timer_available", "gpu_timer_note",
		"gpu", "cpu", "wall", "options",
	]
	for field: String in required_fields:
		if not report.has(field):
			return "missing required gel report field %s" % field
	if not _json_integer_equals(report["schema_version"], 4):
		return "schema_version must equal 4"
	if report["run_id"] is not String or not _safe_run_id(String(report["run_id"])):
		return "run_id must use 8-128 safe identifier characters"
	if report["sequence"] is not String:
		return "sequence must be a string"
	var sequence := String(report["sequence"])
	if sequence == "adhoc":
		if not _json_integer_equals(report["sequence_index"], 0):
			return "adhoc sequence_index must equal zero"
	elif not CAPTURE_SEQUENCE_INDEX.has(sequence):
		return "sequence must be adhoc, A1, B1, B2, or A2"
	elif not _json_integer_equals(report["sequence_index"], int(CAPTURE_SEQUENCE_INDEX[sequence])):
		return "sequence_index does not match sequence"
	if not _json_integer_in_range(report["process_pid"], 1, 2147483647):
		return "process_pid must be a positive bounded integer"
	if (
		not _json_integer_in_range(report["measurement_started_unix_ms"], 1, 9223372036854775807)
		or not _json_integer_in_range(report["measurement_finished_unix_ms"], 1, 9223372036854775807)
		or int(report["measurement_finished_unix_ms"])
		< int(report["measurement_started_unix_ms"])
	):
		return "measurement timestamps are invalid"
	if not _json_integer_in_range(report["capture_hold_ms"], 0, MAX_CAPTURE_HOLD_MS):
		return "capture_hold_ms must be a bounded integer"
	if report["capture_hold_status"] is not String:
		return "capture_hold_status must be a string"
	for field: String in [
		"capture_hold_started_unix_ms", "capture_hold_finished_unix_ms",
		"capture_hold_actual_ms", "capture_hold_rendered_frames",
	]:
		if not _json_integer_in_range(report[field], 0, 9223372036854775807):
			return "%s must be a non-negative bounded integer" % field
	var capture_status := String(report["capture_hold_status"])
	if report["capture_window_always_on_top"] is not bool:
		return "capture_window_always_on_top must be a boolean"
	if sequence == "adhoc":
		if (
			int(report["capture_hold_ms"]) != 0
			or capture_status != "disabled"
			or int(report["capture_hold_started_unix_ms"]) != 0
			or int(report["capture_hold_finished_unix_ms"]) != 0
			or int(report["capture_hold_actual_ms"]) != 0
			or int(report["capture_hold_rendered_frames"]) != 0
			or bool(report["capture_window_always_on_top"])
		):
			return "adhoc reports cannot claim a formal capture hold"
	else:
		if not bool(report["capture_window_always_on_top"]):
			return "formal capture window must remain always-on-top"
		if int(report["capture_hold_ms"]) != FORMAL_CAPTURE_HOLD_MS:
			return "formal capture_hold_ms must equal 35000"
		if capture_status == "ready":
			if (
				int(report["capture_hold_started_unix_ms"]) != 0
				or int(report["capture_hold_finished_unix_ms"]) != 0
				or int(report["capture_hold_actual_ms"]) != 0
				or int(report["capture_hold_rendered_frames"]) != 0
			):
				return "ready capture hold cannot claim completion evidence"
		elif capture_status == "complete":
			var hold_wall_clock_ms := (
				int(report["capture_hold_finished_unix_ms"])
				- int(report["capture_hold_started_unix_ms"])
			)
			if (
				int(report["capture_hold_started_unix_ms"])
				< int(report["measurement_finished_unix_ms"])
				or int(report["capture_hold_finished_unix_ms"])
				< int(report["capture_hold_started_unix_ms"])
			):
				return "capture hold timestamps are invalid"
			if (
				int(report["capture_hold_actual_ms"]) < FORMAL_CAPTURE_HOLD_MS
				or int(report["capture_hold_actual_ms"]) > MAX_CAPTURE_HOLD_MS
			):
				return "completed capture hold duration is outside its bounded contract"
			if (
				hold_wall_clock_ms < FORMAL_CAPTURE_HOLD_MS
				or hold_wall_clock_ms > MAX_CAPTURE_HOLD_MS
				or absi(hold_wall_clock_ms - int(report["capture_hold_actual_ms"]))
				> CAPTURE_HOLD_CLOCK_TOLERANCE_MS
			):
				return "capture hold wall-clock and monotonic durations are inconsistent"
			if int(report["capture_hold_rendered_frames"]) <= 0:
				return "completed capture hold must render at least one frame"
		else:
			return "formal capture_hold_status must be ready or complete"
	if (
		report["gel_look"] is not String
		or String(report["gel_look"]) != _GelProfiles.selected_look()
	):
		return "gel_look must record the exact selected visual profile"
	for field: String in [
		"godot_version", "platform", "display_server", "rendering_method", "renderer",
	]:
		if report[field] is not String or String(report[field]).is_empty():
			return "%s must be a non-empty string" % field
	if report["family"] is not String or String(report["family"]) not in FAMILIES:
		return "family must name a supported production family"
	var family := String(report["family"])
	if report["source"] is not String or String(report["source"]) not in VALID_SOURCES:
		return "source must be character, reference, or legacy-glb"
	var source := String(report["source"])
	if report["subject_scene"] is not String or String(report["subject_scene"]).is_empty():
		return "subject_scene must be a non-empty string"
	var subject_scene := String(report["subject_scene"])
	if source == "character" and subject_scene != String(_Look.SCENE_PATH[family]):
		return "character source must name the family-locked production scene"
	if source == "reference" and subject_scene != String(REFERENCE_SCENES[family]):
		return "reference source must name the family-locked authored body"
	if source == "legacy-glb":
		var allowed_legacy: Array = LEGACY_GLB_SCENES.get(family, [])
		if subject_scene not in allowed_legacy:
			return "legacy source must name an explicitly approved diagnostic GLB"
	if report["production_authored"] is not bool or report["legacy_diagnostic"] is not bool:
		return "production/legacy identity flags must be booleans"
	if bool(report["production_authored"]) != (source != "legacy-glb"):
		return "production_authored is inconsistent with source"
	if bool(report["legacy_diagnostic"]) != (source == "legacy-glb"):
		return "legacy_diagnostic is inconsistent with source"
	if report["material"] is not String or String(report["material"]) not in VALID_MATERIALS:
		return "material must be gel, standard, or none"
	if String(report["material"]) == "none" and source != "legacy-glb":
		return "material none is valid only for a legacy diagnostic"
	if not _json_integer_in_range(report["count"], 1, 200):
		return "count must be a bounded integer"
	if report["material_stats"] is not Dictionary:
		return "material_stats must be a dictionary"
	if report["runtime_identity"] is not Dictionary:
		return "runtime_identity must be a dictionary"
	var material_stats := report["material_stats"] as Dictionary
	for field: String in [
		"visible_mesh_instances", "wet_materials", "shell_materials",
		"eye_materials", "standard_replacements",
	]:
		if not material_stats.has(field):
			return "material_stats is missing %s" % field
		if not _json_integer_in_range(material_stats[field], 0, 10000000):
			return "material_stats %s must be a non-negative bounded integer" % field
	if int(material_stats["visible_mesh_instances"]) == 0:
		return "measured subject must expose at least one visible mesh"
	if String(report["material"]) == "gel" and int(material_stats["wet_materials"]) == 0:
		return "gel measurement must expose at least one wet-gel material"
	if String(report["material"]) == "standard" and int(material_stats["standard_replacements"]) == 0:
		return "standard comparison must replace at least one measured material"
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
	if source == "character" and String(report["material"]) == "gel":
		var identity_error := _runtime_identity_contract_error(
			report["runtime_identity"] as Dictionary
		)
		if not identity_error.is_empty():
			return "runtime identity: %s" % identity_error
	var capture_error := _capture_report_contract_error(report)
	if not capture_error.is_empty():
		return capture_error
	return ""


func _capture_report_contract_error(report: Dictionary) -> String:
	var sequence := String(report.get("sequence", ""))
	if sequence == "adhoc":
		return ""
	if String(report.get("gel_look", "")) != String(CAPTURE_LOOK_FOR_SEQUENCE[sequence]):
		return "capture sequence gel look is inconsistent"
	if String(report.get("godot_version", "")) != "4.7.2-stable (official)":
		return "capture requires Godot 4.7.2-stable (official)"
	if (
		String(report.get("platform", "")) != "macOS"
		or String(report.get("display_server", "")) != "macOS"
		or String(report.get("rendering_method", "")) != "forward_plus"
		or String(report.get("renderer", "")) != "metal"
	):
		return "capture requires macOS Forward+/Metal"
	if (
		String(report.get("family", "")) != "T"
		or String(report.get("source", "")) != "character"
		or String(report.get("subject_scene", ""))
		!= "res://characters/base_t/character.tscn"
		or not bool(report.get("production_authored", false))
		or bool(report.get("legacy_diagnostic", true))
		or String(report.get("material", "")) != "gel"
		or int(report.get("count", 0)) != 20
		or int(report.get("frames", 0)) != 4000
		or int(report.get("sample_count", 0)) != 4000
		or int(report.get("warmup_frames", 0)) != 60
		or String(report.get("sync_mode", "")) != "none"
		or int(report.get("capture_hold_ms", 0)) != FORMAL_CAPTURE_HOLD_MS
		or String(report.get("capture_hold_status", "")) not in ["ready", "complete"]
		or not (report.get("options", {}) as Dictionary).is_empty()
	):
		return "capture workload is not exact T/character/gel/20/4000/35000ms-hold/no-overrides"
	var viewport := report.get("viewport", {}) as Dictionary
	if int(viewport.get("width", 0)) != 1920 or int(viewport.get("height", 0)) != 1080:
		return "capture viewport must equal 1920x1080"
	var material_stats := report.get("material_stats", {}) as Dictionary
	var expected_material_stats := {
		"visible_mesh_instances": 140,
		"wet_materials": 20,
		"shell_materials": 20,
		"eye_materials": 100,
		"standard_replacements": 0,
	}
	for key in expected_material_stats:
		if int(material_stats.get(key, -1)) != int(expected_material_stats[key]):
			return "capture material_stats.%s does not match the locked inventory" % key
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
