extends SceneTree

## Runs real mission scenes with deterministic autopilot and writes a local JSON report.

const _Content := preload("res://resources/combat/combat_content.gd")
const DEFAULT_OUT := "user://immune_balance_matrix.json"
const DEFAULT_TRIALS: int = 2
const DEFAULT_TIME_SCALE: float = 1.0
const MAX_GAME_SECONDS: float = 120.0
const MAX_WALL_SECONDS: float = 150.0
const BUILD_TAG: String = "campaign-expansion-candidate-1"
const SOAK_BUILD_TAG: String = "all-family-campaign-soak-1"
const ALL_FAMILIES: Array[StringName] = [&"T", &"B", &"M", &"N", &"A", &"D"]
const SOAK_MIN_GAME_SECONDS: float = 1800.0
const SOAK_MAX_MEAN_PROCESS_MS: float = 0.0
const SOAK_MAX_WALL_TO_GAME_RATIO: float = 1.25
const SOAK_MIN_FPS: float = 30.0
const MAX_TRIALS: int = 100
const MAX_THRESHOLD_VALUE: float = 86400.0
const REPORT_TEMP_ATTEMPTS: int = 32
const FLAG_OPTIONS: PackedStringArray = ["soak", "stop-on-failure"]
const VALUE_OPTIONS: PackedStringArray = [
	"out",
	"trials",
	"time-scale",
	"missions",
	"families",
	"min-total-game-seconds",
	"max-mean-process-ms",
	"max-mean-physics-ms",
	"max-wall-to-game-ratio",
	"min-fps",
	"save-path",
]

var _out_path: String = DEFAULT_OUT
var _trials: int = DEFAULT_TRIALS
var _time_scale: float = DEFAULT_TIME_SCALE
var _runs: Array[Dictionary] = []
var _failures: Array[String] = []
var _mission_filter: Array[StringName] = []
var _family_filter: Array[StringName] = [&"T", &"B"]
var _build_tag: String = BUILD_TAG
var _soak_mode: bool = false
var _stop_on_failure: bool = false
var _aborted: bool = false
var _min_total_game_seconds: float = 0.0
var _max_mean_process_ms: float = 0.0
var _max_mean_physics_ms: float = 0.0
var _max_wall_to_game_ratio: float = 0.0
var _min_fps: float = 0.0
var _report_write_failed := false


func _init() -> void:
	var research_state := root.get_node_or_null("ResearchState")
	if _quit_for_qa_startup_failure(research_state):
		return
	if not _parse_args():
		quit(2)
		return
	call_deferred("_run")


func _run() -> void:
	var research_state: Node = root.get_node_or_null("ResearchState")
	if _quit_for_qa_startup_failure(research_state):
		return
	Engine.time_scale = _time_scale
	var settings_state: Node = root.get_node_or_null("SettingsState")
	if research_state == null or settings_state == null:
		_fail("Autoloads ResearchState/SettingsState are missing")
		_finish()
		return
	research_state.call("seed_demo")
	settings_state.set("onboarding_seen", true)
	var mission_ids: Array[StringName] = _Content.mission_ids()
	if not _mission_filter.is_empty():
		mission_ids = _mission_filter
	for mission_id: StringName in mission_ids:
		for family_id: StringName in _family_filter:
			for trial: int in range(1, _trials + 1):
				await _run_one(research_state, mission_id, family_id, trial)
				if _stop_on_failure and not _failures.is_empty():
					_aborted = true
					break
			if _aborted:
				break
		if _aborted:
			break
	_validate_matrix(mission_ids, _family_filter)
	if _soak_mode and not _aborted:
		_validate_soak(mission_ids, _family_filter)
	_finish()


func _run_one(
	research_state: Node,
	mission_id: StringName,
	family_id: StringName,
	trial: int
) -> void:
	# Gameplay code uses the global random stream for spawn lanes and presentation.
	# A stable per-run seed keeps candidate reports reproducible without removing
	# variation between trials.
	seed(("%s:%s:%d" % [mission_id, family_id, trial]).hash())
	if mission_id not in _Content.mission_ids():
		_fail("Missing mission %s" % mission_id)
		return
	if family_id not in ALL_FAMILIES:
		_fail("Missing family %s" % family_id)
		return
	var mission: ImmuneMissionData = _Content.load_mission(mission_id)
	if mission == null:
		_fail("Missing mission %s" % mission_id)
		return
	research_state.set("selected_mission_id", mission_id)
	research_state.set("selected_family_id", family_id)
	var packed := load(mission.scene_path) as PackedScene
	if packed == null:
		_fail("Missing mission scene %s" % mission.scene_path)
		return
	var lane: Node = packed.instantiate()
	lane.set("auto_spawn", true)
	lane.set("persist_rewards", false)
	lane.set("show_onboarding", false)
	lane.set("telemetry_enabled", true)
	lane.set("playtest_autopilot", true)
	lane.set("playtest_build_tag", _build_tag)
	root.add_child(lane)
	await physics_frame
	await physics_frame
	var timed_out: bool = false
	var timeout_reason: String = ""
	var wall_started_ms: int = Time.get_ticks_msec()
	while not bool(lane.call("debug_is_over")):
		var live_snapshot: Dictionary = lane.call("telemetry_snapshot")
		if float(live_snapshot.get("total_seconds", 0.0)) >= MAX_GAME_SECONDS:
			timed_out = true
			timeout_reason = "game-time"
			break
		var wall_seconds := float(Time.get_ticks_msec() - wall_started_ms) / 1000.0
		if wall_seconds >= MAX_WALL_SECONDS:
			timed_out = true
			timeout_reason = "wall-time"
			break
		await physics_frame
	var snapshot: Dictionary = lane.call("telemetry_snapshot")
	var wall_seconds := float(Time.get_ticks_msec() - wall_started_ms) / 1000.0
	snapshot["trial"] = trial
	snapshot["timed_out"] = timed_out
	snapshot["timeout_reason"] = timeout_reason
	snapshot["wall_seconds"] = snappedf(wall_seconds, 0.001)
	var game_seconds := float(snapshot.get("total_seconds", 0.0))
	snapshot["wall_to_game_ratio"] = (
		snappedf(wall_seconds / game_seconds, 0.001) if game_seconds > 0.0 else 0.0
	)
	_runs.append(snapshot)
	_validate_run(snapshot)
	_write_report(false)
	var performance := snapshot.get("performance", {}) as Dictionary
	print(
		"BALANCE_RUN mission=%s family=%s trial=%d victory=%s seconds=%.3f wall=%.3f core=%d/%d shots=%d hits=%d process=%.3fms physics=%.3fms p05_fps=%.1f draw_calls=%d"
		% [
			mission_id,
			family_id,
			trial,
			str(snapshot.get("victory", false)),
			float(snapshot.get("total_seconds", 0.0)),
			wall_seconds,
			int(snapshot.get("core_hp", 0)),
			int(snapshot.get("core_max_hp", 0)),
			int(snapshot.get("shots_fired", 0)),
			int(snapshot.get("shots_hit", 0)),
			float(performance.get("mean_process_ms", 0.0)),
			float(performance.get("mean_physics_process_ms", 0.0)),
			float(performance.get("p05_fps", 0.0)),
			int(performance.get("max_draw_calls", 0)),
		]
	)
	if timed_out:
		_fail("%s/%s trial %d timed out (%s)" % [mission_id, family_id, trial, timeout_reason])
	lane.queue_free()
	await process_frame
	await physics_frame


func _validate_matrix(mission_ids: Array[StringName], family_ids: Array[StringName]) -> void:
	if _aborted:
		return
	var expected: int = mission_ids.size() * family_ids.size() * _trials
	if _runs.size() != expected:
		_fail("Expected %d balance runs, got %d" % [expected, _runs.size()])
	_validate_duration_ladder(mission_ids, family_ids)


func _validate_run(run: Dictionary) -> void:
	var label := "%s/%s trial %d" % [
		run.get("mission_id", "?"),
		run.get("family_id", "?"),
		int(run.get("trial", 0)),
	]
	if not bool(run.get("ended", false)):
		_fail("%s did not reach an end state" % label)
	if not bool(run.get("victory", false)):
		_fail("%s did not produce a baseline victory" % label)
	if int(run.get("bosses_defeated", 0)) != 1:
		_fail("%s did not defeat exactly one boss" % label)
	if int(run.get("shots_fired", 0)) <= 0 or int(run.get("shots_hit", 0)) <= 0:
		_fail("%s did not exercise real projectile combat" % label)
	if int(run.get("shots_hit", 0)) > int(run.get("shots_fired", 0)):
		_fail("%s counted more hits than fired projectiles" % label)
	if int(run.get("active_skills_used", 0)) <= 0:
		_fail("%s did not exercise its active skill" % label)
	if int(run.get("active_skill_hits", 0)) <= 0:
		_fail("%s active skill did not hit a real target" % label)
	var accuracy: float = float(run.get("accuracy", -1.0))
	if accuracy < 0.0 or accuracy > 1.0:
		_fail("%s produced invalid accuracy %.3f" % [label, accuracy])
	var core_hp: int = int(run.get("core_hp", 0))
	var core_max_hp: int = int(run.get("core_max_hp", 0))
	if core_hp <= 0 or core_hp > core_max_hp:
		_fail("%s produced invalid surviving core HP %d/%d" % [label, core_hp, core_max_hp])
	var movement_duty := "relay" if StringName(run.get("family_id", "")) == &"A" else "mobile"
	if float(run.get("duty_seconds", {}).get(movement_duty, 0.0)) <= 0.0:
		_fail("%s did not exercise %s duty" % [label, movement_duty])
	if int(run.get("duty_switches", 0)) < 2:
		_fail("%s did not return from %s to fixed duty" % [label, movement_duty])
	var performance := run.get("performance", {}) as Dictionary
	if int(performance.get("sample_count", 0)) <= 0:
		_fail("%s did not collect performance samples" % label)


func _validate_soak(mission_ids: Array[StringName], family_ids: Array[StringName]) -> void:
	if mission_ids.size() != _Content.mission_ids().size():
		_fail("Soak mode must exercise all campaign missions")
	if family_ids.size() != ALL_FAMILIES.size():
		_fail("Soak mode must exercise all six families")
	for family_id: StringName in ALL_FAMILIES:
		if family_id not in family_ids:
			_fail("Soak mode is missing family %s" % family_id)
	var summary := _summary()
	var total_game_seconds := float(summary.get("total_game_seconds", 0.0))
	if total_game_seconds < _min_total_game_seconds:
		_fail(
			"Soak duration %.3fs is below the %.3fs gate"
			% [total_game_seconds, _min_total_game_seconds]
		)
	var worst_process := float(summary.get("worst_mean_process_ms", 0.0))
	if _max_mean_process_ms > 0.0 and worst_process > _max_mean_process_ms:
		_fail(
			"Soak mean process time %.3fms exceeds %.3fms"
			% [worst_process, _max_mean_process_ms]
		)
	var worst_physics := float(summary.get("worst_mean_physics_process_ms", 0.0))
	if _max_mean_physics_ms > 0.0 and worst_physics > _max_mean_physics_ms:
		_fail(
			"Soak mean physics time %.3fms exceeds %.3fms"
			% [worst_physics, _max_mean_physics_ms]
		)
	var observed_wall_ratio := float(summary.get("max_wall_to_game_ratio", 0.0))
	if _max_wall_to_game_ratio > 0.0 and observed_wall_ratio > _max_wall_to_game_ratio:
		_fail(
			"Soak wall/game ratio %.3f exceeds %.3f"
			% [observed_wall_ratio, _max_wall_to_game_ratio]
		)
	var observed_p05_fps := float(summary.get("minimum_p05_fps", 0.0))
	if _min_fps > 0.0 and observed_p05_fps > 0.0 and observed_p05_fps < _min_fps:
		_fail("Soak 5th-percentile FPS %.1f is below %.1f" % [observed_p05_fps, _min_fps])


func _validate_duration_ladder(
	mission_ids: Array[StringName], family_ids: Array[StringName]
) -> void:
	for family_id: StringName in family_ids:
		var previous_average: float = -1.0
		for mission_id: StringName in mission_ids:
			var total_seconds: float = 0.0
			var count: int = 0
			for run: Dictionary in _runs:
				if StringName(run.get("mission_id", "")) != mission_id:
					continue
				if StringName(run.get("family_id", "")) != family_id:
					continue
				total_seconds += float(run.get("total_seconds", 0.0))
				count += 1
			if count == 0:
				continue
			var average: float = total_seconds / float(count)
			if previous_average >= 0.0 and average <= previous_average:
				_fail(
					"%s duration ladder is not increasing at %s (%.3f <= %.3f)"
					% [family_id, mission_id, average, previous_average]
				)
			previous_average = average


func _finish() -> void:
	Engine.time_scale = 1.0
	_write_report(not _aborted)
	var absolute_path: String = _globalized_out_path()
	print("BALANCE_REPORT %s" % absolute_path)
	if _failures.is_empty():
		if _soak_mode:
			var summary := _summary()
			print(
				"SOAK_MATRIX_OK runs=%d game_seconds=%.3f wall_seconds=%.3f max_wall_ratio=%.3f min_core=%d worst_process=%.3fms physics_observed=%.3fms p05_fps=%.1f cold_start_min_fps=%.1f max_draw_calls=%d peak_memory=%.3fMB"
				% [
					_runs.size(),
					float(summary.get("total_game_seconds", 0.0)),
					float(summary.get("total_wall_seconds", 0.0)),
					float(summary.get("max_wall_to_game_ratio", 0.0)),
					int(summary.get("minimum_core_hp", 0)),
					float(summary.get("worst_mean_process_ms", 0.0)),
					float(summary.get("worst_mean_physics_process_ms", 0.0)),
					float(summary.get("minimum_p05_fps", 0.0)),
					float(summary.get("cold_start_min_fps", 0.0)),
					int(summary.get("max_draw_calls", 0)),
					float(summary.get("peak_static_memory_mb", 0.0)),
				]
			)
		else:
			print("BALANCE_MATRIX_OK runs=%d" % _runs.size())
		quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		quit(1)


func _parse_args() -> bool:
	var seen := {}
	var values := {}
	var flags := {}
	for raw_arg: String in OS.get_cmdline_user_args():
		var arg := raw_arg.strip_edges()
		if not arg.begins_with("--") or arg == "--":
			return _arg_error("positional or malformed argument is not allowed: %s" % raw_arg)
		var body := arg.trim_prefix("--")
		var equals_index := body.find("=")
		var key := body if equals_index < 0 else body.substr(0, equals_index)
		if key.is_empty():
			return _arg_error("empty option name")
		if seen.has(key):
			return _arg_error("duplicate option --%s" % key)
		seen[key] = true
		if equals_index < 0:
			if key not in FLAG_OPTIONS:
				if key in VALUE_OPTIONS:
					return _arg_error("--%s requires =<value>" % key)
				return _arg_error("unknown option --%s" % key)
			flags[key] = true
			continue
		if key not in VALUE_OPTIONS:
			if key in FLAG_OPTIONS:
				return _arg_error("--%s is a flag and does not accept a value" % key)
			return _arg_error("unknown option --%s" % key)
		var value := body.substr(equals_index + 1).strip_edges()
		if value.is_empty():
			return _arg_error("--%s cannot be empty" % key)
		values[key] = value

	if flags.has("soak"):
		_soak_mode = true
		_stop_on_failure = true
		_family_filter = ALL_FAMILIES.duplicate()
		_trials = 1
		_build_tag = SOAK_BUILD_TAG
		_min_total_game_seconds = SOAK_MIN_GAME_SECONDS
		_max_mean_process_ms = SOAK_MAX_MEAN_PROCESS_MS
		_max_wall_to_game_ratio = SOAK_MAX_WALL_TO_GAME_RATIO
		_min_fps = SOAK_MIN_FPS
	if flags.has("stop-on-failure"):
		_stop_on_failure = true

	if values.has("out"):
		_out_path = String(values["out"])
	if not _validate_out_path():
		return false

	if values.has("trials"):
		var trials_result := _parse_strict_int("trials", String(values["trials"]), 1, MAX_TRIALS)
		if not bool(trials_result.get("ok", false)):
			return false
		_trials = int(trials_result["value"])
	if values.has("time-scale"):
		var scale_result := _parse_finite_range(
			"time-scale", String(values["time-scale"]), 0.001, MAX_THRESHOLD_VALUE
		)
		if not bool(scale_result.get("ok", false)):
			return false
		_time_scale = float(scale_result["value"])
		# Engine.time_scale changes physics integration and projectile collision
		# outcomes. Accelerated runs are useful for neither tuning nor release
		# evidence, so the canonical harness fails closed at real-time speed.
		if not is_equal_approx(_time_scale, DEFAULT_TIME_SCALE):
			return _arg_error(
				"--time-scale must be 1 for deterministic balance evidence; "
				+ "accelerated Godot physics is not gameplay-equivalent"
			)

	var mission_ids: Array[StringName] = _Content.mission_ids()
	if values.has("missions"):
		var missions_result := _parse_filter(
			"missions", String(values["missions"]), mission_ids
		)
		if not bool(missions_result.get("ok", false)):
			return false
		_mission_filter = missions_result["value"] as Array[StringName]
	if values.has("families"):
		var families_result := _parse_filter(
			"families", String(values["families"]), ALL_FAMILIES
		)
		if not bool(families_result.get("ok", false)):
			return false
		_family_filter = families_result["value"] as Array[StringName]

	var threshold_targets := {
		"min-total-game-seconds": "_min_total_game_seconds",
		"max-mean-process-ms": "_max_mean_process_ms",
		"max-mean-physics-ms": "_max_mean_physics_ms",
		"max-wall-to-game-ratio": "_max_wall_to_game_ratio",
		"min-fps": "_min_fps",
	}
	for option: String in threshold_targets:
		if not values.has(option):
			continue
		var result := _parse_finite_range(
			option, String(values[option]), 0.0, MAX_THRESHOLD_VALUE
		)
		if not bool(result.get("ok", false)):
			return false
		set(StringName(threshold_targets[option]), float(result["value"]))

	if _soak_mode:
		if values.has("trials") and _trials != 1:
			return _arg_error("--soak requires --trials=1")
		if values.has("time-scale") and not is_equal_approx(_time_scale, 1.0):
			return _arg_error("--soak requires --time-scale=1")
		if values.has("missions") and _mission_filter != mission_ids:
			return _arg_error("--soak must include every mission in campaign order")
		if values.has("families") and _family_filter != ALL_FAMILIES:
			return _arg_error("--soak must include every family in canonical order")

	var selected_mission_count := mission_ids.size() if _mission_filter.is_empty() else _mission_filter.size()
	var expected_run_count := selected_mission_count * _family_filter.size() * _trials
	if expected_run_count <= 0:
		return _arg_error("selected matrix has zero expected runs")
	return true


func _parse_filter(
	option: String, csv: String, allowed_values: Array[StringName]
) -> Dictionary:
	var result: Array[StringName] = []
	for raw_value: String in csv.split(",", true):
		var normalized := raw_value.strip_edges()
		if normalized.is_empty():
			_arg_error("--%s contains an empty value" % option)
			return {"ok": false}
		var name := StringName(normalized)
		if name not in allowed_values:
			_arg_error("--%s contains unknown value %s" % [option, normalized])
			return {"ok": false}
		if name in result:
			_arg_error("--%s contains duplicate value %s" % [option, normalized])
			return {"ok": false}
		result.append(name)
	if result.is_empty():
		_arg_error("--%s must select at least one value" % option)
		return {"ok": false}
	return {"ok": true, "value": result}


func _parse_strict_int(option: String, raw_value: String, minimum: int, maximum: int) -> Dictionary:
	var value_text := raw_value.strip_edges()
	if not value_text.is_valid_int():
		_arg_error("--%s requires an integer" % option)
		return {"ok": false}
	var value := int(value_text)
	if value < minimum or value > maximum:
		_arg_error("--%s must be in range %d..%d" % [option, minimum, maximum])
		return {"ok": false}
	return {"ok": true, "value": value}


func _parse_finite_range(
	option: String, raw_value: String, minimum: float, maximum: float
) -> Dictionary:
	var value_text := raw_value.strip_edges()
	if not value_text.is_valid_float():
		_arg_error("--%s requires a finite number" % option)
		return {"ok": false}
	var value := float(value_text)
	if not is_finite(value):
		_arg_error("--%s requires a finite number" % option)
		return {"ok": false}
	if value < minimum or value > maximum:
		_arg_error("--%s must be in range %.3f..%.3f" % [option, minimum, maximum])
		return {"ok": false}
	return {"ok": true, "value": value}


func _arg_error(message: String) -> bool:
	push_error("balance_matrix: %s" % message)
	return false


func _globalized_out_path() -> String:
	if _out_path.begins_with("user://"):
		return ProjectSettings.globalize_path(_out_path)
	var normalized := _out_path.replace("\\", "/")
	if normalized.is_absolute_path():
		return normalized.simplify_path()
	return _repository_outputs_root().path_join(normalized.trim_prefix("outputs/")).simplify_path()


func _validate_out_path() -> bool:
	var normalized := _out_path.strip_edges().replace("\\", "/")
	if normalized.is_empty() or normalized.to_utf8_buffer().has(0):
		return _arg_error("--out must name a JSON file")
	if normalized.ends_with("/") or normalized.get_extension().to_lower() != "json":
		return _arg_error("--out must name a .json file")
	if normalized.contains("/../") or normalized.ends_with("/.."):
		return _arg_error("--out traversal is not allowed")
	if normalized.begins_with("res://"):
		return _arg_error("--out cannot write below res://")

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
			return _arg_error(
				"absolute --out must be below the OS temporary directory or repository outputs/"
			)
	elif normalized.begins_with("outputs/"):
		allowed_root = _repository_outputs_root()
		absolute_path = allowed_root.path_join(normalized.trim_prefix("outputs/")).simplify_path()
	else:
		return _arg_error("relative --out must begin with outputs/")

	if (
		not _path_is_within(absolute_path, allowed_root)
		or _same_filesystem_path(absolute_path, allowed_root)
	):
		return _arg_error("--out escaped its allowed output root")
	if DirAccess.dir_exists_absolute(absolute_path):
		return _arg_error("--out names a directory")
	if _path_crosses_link(absolute_path, allowed_root):
		return _arg_error("--out crosses a symbolic link")

	var player_save := ProjectSettings.globalize_path(
		"user://immune_demo_save.json"
	).replace("\\", "/").simplify_path()
	if _same_filesystem_path(absolute_path, player_save):
		return _arg_error("--out must not name or alias the player save")
	var research_state := root.get_node_or_null("ResearchState")
	if research_state != null and research_state.has_method("active_save_path"):
		var active_save := ProjectSettings.globalize_path(
			str(research_state.call("active_save_path"))
		).replace("\\", "/").simplify_path()
		if _same_filesystem_path(absolute_path, active_save):
			return _arg_error("--out must not name the active save")
	return true


func _repository_outputs_root() -> String:
	var godot_project_root := ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path()
	return godot_project_root.get_base_dir().get_base_dir().path_join("outputs").simplify_path()


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
	# Once containment is proven with the platform's case rule, lengths remain
	# identical even if a Windows caller used different path casing.
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


func _write_report(complete: bool) -> bool:
	if _report_write_failed:
		return false
	var absolute_path: String = _globalized_out_path()
	var parent_dir: String = absolute_path.get_base_dir()
	if parent_dir.is_empty():
		return _report_error("Report path has no parent directory: %s" % absolute_path)
	var directory_error := DirAccess.make_dir_recursive_absolute(parent_dir)
	if directory_error != OK and not DirAccess.dir_exists_absolute(parent_dir):
		return _report_error(
			"Could not create report directory %s (%s)"
			% [parent_dir, error_string(directory_error)]
		)
	if not _validate_out_path():
		return _report_error("Report path became unsafe before write: %s" % absolute_path)
	var recovery_error := _recover_orphaned_report_backup(absolute_path)
	if recovery_error != OK:
		return _report_error(
			"Could not recover interrupted report transaction for %s (%s)"
			% [absolute_path, error_string(recovery_error)]
		)

	var identity := _report_identity(complete)
	var temporary_path := _reserve_report_temp_path(absolute_path)
	if temporary_path.is_empty():
		return _report_error("Could not reserve transactional report beside %s" % absolute_path)
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return _report_error(
			"Could not open transactional report %s (%s)"
			% [temporary_path, error_string(FileAccess.get_open_error())]
		)
	var report := {
		"schema_version": 2,
		"build_tag": identity["build_tag"],
		"mode": identity["mode"],
		"missions": identity["missions"],
		"families": identity["families"],
		"trials": identity["trials"],
		"expected_run_count": identity["expected_run_count"],
		"complete": identity["complete"],
		"aborted": identity["aborted"],
		"ok": identity["ok"],
		"run_count": identity["run_count"],
		"trials_per_pair": _trials,
		"simulation_time_scale": _time_scale,
		"summary": _summary(),
		"failures": _failures,
		"runs": _runs,
	}
	var encoded := JSON.stringify(report, "\t", false)
	if encoded.is_empty():
		file.close()
		DirAccess.remove_absolute(temporary_path)
		return _report_error("JSON encoder returned an empty balance report")
	file.store_string(encoded)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary_path)
		return _report_error(
			"Could not flush report %s (%s)" % [temporary_path, error_string(write_error)]
		)
	if not _verify_report_file(temporary_path, encoded, identity):
		DirAccess.remove_absolute(temporary_path)
		return _report_error(
			"Transactional report failed payload/schema verification: %s" % temporary_path
		)
	if not _validate_out_path():
		DirAccess.remove_absolute(temporary_path)
		return _report_error("Report path became unsafe before rename: %s" % absolute_path)
	return _transactionally_publish_report(
		temporary_path, absolute_path, encoded, identity
	)


func _report_identity(complete: bool) -> Dictionary:
	var missions: Array[String] = []
	var selected_missions: Array[StringName] = (
		_Content.mission_ids() if _mission_filter.is_empty() else _mission_filter
	)
	for mission_id: StringName in selected_missions:
		missions.append(String(mission_id))
	var families: Array[String] = []
	for family_id: StringName in _family_filter:
		families.append(String(family_id))
	var expected_run_count := missions.size() * families.size() * _trials
	return {
		"build_tag": _build_tag,
		"mode": "soak" if _soak_mode else "balance",
		"missions": missions,
		"families": families,
		"trials": _trials,
		"expected_run_count": expected_run_count,
		"complete": complete,
		"aborted": _aborted,
		"ok": (
			complete
			and not _aborted
			and _failures.is_empty()
			and _runs.size() == expected_run_count
		),
		"run_count": _runs.size(),
	}


func _reserve_report_temp_path(absolute_path: String) -> String:
	return _reserve_report_sibling(absolute_path, "tmp")


func _reserve_report_sibling(absolute_path: String, kind: String) -> String:
	var parent_dir := absolute_path.get_base_dir()
	var file_name := absolute_path.get_file()
	var nonce := "%d-%d-%d-%s" % [
		OS.get_process_id(),
		int(Time.get_unix_time_from_system() * 1000000.0),
		Time.get_ticks_usec(),
		Crypto.new().generate_random_bytes(12).hex_encode(),
	]
	for attempt: int in REPORT_TEMP_ATTEMPTS:
		var candidate := parent_dir.path_join(
			".%s.%s-%s-%02d" % [file_name, kind, nonce, attempt]
		)
		if not FileAccess.file_exists(candidate) and not DirAccess.dir_exists_absolute(candidate):
			return candidate
	return ""


func _transactionally_publish_report(
	temporary_path: String,
	absolute_path: String,
	expected_text: String,
	expected_identity: Dictionary
) -> bool:
	# Godot's Windows rename removes an existing destination first. Move the old
	# report to a unique sibling, publish, verify, and only then remove the backup.
	# This is transactional replacement rather than a cross-platform atomic claim.
	var backup_path := ""
	if DirAccess.dir_exists_absolute(absolute_path):
		DirAccess.remove_absolute(temporary_path)
		return _report_error("Report target is a directory: %s" % absolute_path)
	if FileAccess.file_exists(absolute_path):
		if _final_component_is_link(absolute_path):
			DirAccess.remove_absolute(temporary_path)
			return _report_error("Report target became a symbolic link: %s" % absolute_path)
		backup_path = _reserve_report_sibling(absolute_path, "backup")
		if backup_path.is_empty():
			DirAccess.remove_absolute(temporary_path)
			return _report_error("Could not reserve report backup beside %s" % absolute_path)
		var preserve_error := DirAccess.rename_absolute(absolute_path, backup_path)
		if preserve_error != OK:
			DirAccess.remove_absolute(temporary_path)
			return _report_error(
				"Could not preserve previous report %s (%s)"
				% [absolute_path, error_string(preserve_error)]
			)
	var publish_error := DirAccess.rename_absolute(temporary_path, absolute_path)
	if publish_error != OK:
		_restore_report_backup(absolute_path, backup_path)
		if FileAccess.file_exists(temporary_path):
			DirAccess.remove_absolute(temporary_path)
		return _report_error(
			"Transactional report publish failed for %s (%s); previous report remains recoverable"
			% [absolute_path, error_string(publish_error)]
		)
	if not _verify_report_file(absolute_path, expected_text, expected_identity):
		_restore_report_backup(absolute_path, backup_path)
		return _report_error(
			"Published report failed verification; previous report remains recoverable: %s"
			% absolute_path
		)
	if not backup_path.is_empty() and FileAccess.file_exists(backup_path):
		var cleanup_error := DirAccess.remove_absolute(backup_path)
		if cleanup_error != OK:
			push_warning("Verified report published; backup cleanup failed: %s" % backup_path)
	_cleanup_report_backups(absolute_path)
	return true


func _restore_report_backup(absolute_path: String, backup_path: String) -> void:
	if backup_path.is_empty() or not FileAccess.file_exists(backup_path):
		return
	var displaced_path := ""
	if FileAccess.file_exists(absolute_path):
		displaced_path = _reserve_report_sibling(absolute_path, "failed")
		if displaced_path.is_empty():
			push_error("Previous report remains recoverable at %s" % backup_path)
			return
		if DirAccess.rename_absolute(absolute_path, displaced_path) != OK:
			push_error("Previous report remains recoverable at %s" % backup_path)
			return
	elif DirAccess.dir_exists_absolute(absolute_path):
		push_error("Previous report remains recoverable at %s" % backup_path)
		return
	var restore_error := DirAccess.rename_absolute(backup_path, absolute_path)
	if restore_error != OK:
		push_error(
			"Report restore failed; previous report remains at %s (%s)"
			% [backup_path, error_string(restore_error)]
		)
		return
	print("BALANCE_REPORT_TRANSACTION_RESTORED %s" % absolute_path)
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
	print("BALANCE_REPORT_TRANSACTION_RECOVERED path=%s backup=%s" % [absolute_path, backup_path])
	return OK


func _final_component_is_link(absolute_path: String) -> bool:
	var parent := DirAccess.open(absolute_path.get_base_dir())
	return parent != null and parent.is_link(absolute_path.get_file())


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


func _verify_report_file(
	path: String, expected_text: String = "", expected_identity: Dictionary = {}
) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() <= 0:
		return false
	var text := file.get_as_text()
	file.close()
	if text.strip_edges().is_empty():
		return false
	if not expected_text.is_empty() and text != expected_text:
		return false
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return false
	return _report_schema_error(parsed as Dictionary, expected_identity).is_empty()


func _report_schema_error(report: Dictionary, expected_identity: Dictionary = {}) -> String:
	var required_fields: PackedStringArray = [
		"schema_version", "build_tag", "mode", "missions", "families", "trials",
		"expected_run_count", "complete", "aborted", "ok", "run_count",
		"trials_per_pair", "simulation_time_scale", "summary", "failures", "runs",
	]
	for field: String in required_fields:
		if not report.has(field):
			return "missing required report field %s" % field
	if not _json_integer_equals(report["schema_version"], 2):
		return "schema_version must equal 2"
	if not report["build_tag"] is String or String(report["build_tag"]).is_empty():
		return "build_tag must be a non-empty string"
	if report["mode"] is not String or String(report["mode"]) not in ["balance", "soak"]:
		return "mode must be balance or soak"
	if report["complete"] is not bool or report["aborted"] is not bool or report["ok"] is not bool:
		return "complete, aborted, and ok must be booleans"
	if report["summary"] is not Dictionary:
		return "summary must be a dictionary"
	if report["failures"] is not Array or report["runs"] is not Array:
		return "failures and runs must be arrays"
	for failure: Variant in report["failures"] as Array:
		if failure is not String:
			return "every failure must be a string"

	var missions_error := _report_string_list_error(
		report["missions"], "missions", _Content.mission_ids()
	)
	if not missions_error.is_empty():
		return missions_error
	var families_error := _report_string_list_error(
		report["families"], "families", ALL_FAMILIES
	)
	if not families_error.is_empty():
		return families_error
	var missions := report["missions"] as Array
	var families := report["families"] as Array
	if not _json_integer_in_range(report["trials"], 1, MAX_TRIALS):
		return "trials must be a bounded integer"
	var trials := int(report["trials"])
	if not _json_integer_equals(report["trials_per_pair"], trials):
		return "trials_per_pair must equal trials"
	var expected_run_count := missions.size() * families.size() * trials
	if not _json_integer_equals(report["expected_run_count"], expected_run_count):
		return "expected_run_count does not match requested matrix"
	var runs := report["runs"] as Array
	if not _json_integer_equals(report["run_count"], runs.size()):
		return "run_count does not match runs size"
	if runs.size() > expected_run_count:
		return "run_count exceeds requested matrix"
	if bool(report["complete"]) and not bool(report["aborted"]) and runs.size() != expected_run_count:
		return "complete report does not contain the requested matrix"
	var expected_ok := (
		bool(report["complete"])
		and not bool(report["aborted"])
		and (report["failures"] as Array).is_empty()
		and runs.size() == expected_run_count
	)
	if bool(report["ok"]) != expected_ok:
		return "ok does not match report completion/failures/counts"
	var scale: Variant = report["simulation_time_scale"]
	if typeof(scale) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(scale)):
		return "simulation_time_scale must be finite"

	var seen_runs := {}
	for raw_run: Variant in runs:
		if raw_run is not Dictionary:
			return "every run must be a dictionary"
		var run := raw_run as Dictionary
		for field: String in ["mission_id", "family_id", "trial", "build_tag"]:
			if not run.has(field):
				return "run is missing %s" % field
		var mission_id := str(run["mission_id"])
		var family_id := str(run["family_id"])
		if mission_id not in missions or family_id not in families:
			return "run escaped requested mission/family matrix"
		if not _json_integer_in_range(run["trial"], 1, trials):
			return "run trial is outside requested range"
		if str(run["build_tag"]) != str(report["build_tag"]):
			return "run build_tag does not match report build_tag"
		var run_key := "%s|%s|%d" % [mission_id, family_id, int(run["trial"])]
		if seen_runs.has(run_key):
			return "duplicate run identity %s" % run_key
		seen_runs[run_key] = true

	if not expected_identity.is_empty():
		for field: String in [
			"build_tag", "mode", "missions", "families", "trials",
			"expected_run_count", "complete", "aborted", "ok", "run_count",
		]:
			if not expected_identity.has(field) or report[field] != expected_identity[field]:
				return "report identity mismatch at %s" % field
	return ""


func _report_string_list_error(
	raw_values: Variant, field: String, allowed_values: Array[StringName]
) -> String:
	if raw_values is not Array or (raw_values as Array).is_empty():
		return "%s must be a non-empty array" % field
	var seen := {}
	for raw_value: Variant in raw_values as Array:
		if raw_value is not String:
			return "%s values must be strings" % field
		var value := String(raw_value)
		if StringName(value) not in allowed_values:
			return "%s contains unknown value %s" % [field, value]
		if seen.has(value):
			return "%s contains duplicate value %s" % [field, value]
		seen[value] = true
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


func _report_error(message: String) -> bool:
	_report_write_failed = true
	_fail(message)
	return false


func _summary() -> Dictionary:
	var total_game_seconds: float = 0.0
	var total_wall_seconds: float = 0.0
	var minimum_core_hp: int = 0
	var accuracy_total: float = 0.0
	var worst_mean_process_ms: float = 0.0
	var worst_mean_physics_process_ms: float = 0.0
	var max_wall_to_game_ratio: float = 0.0
	var minimum_p05_fps: float = 0.0
	var cold_start_min_fps: float = 0.0
	var cold_start_max_process_ms: float = 0.0
	var cold_start_max_physics_process_ms: float = 0.0
	var max_draw_calls: int = 0
	var max_render_objects: int = 0
	var peak_static_memory_mb: float = 0.0
	var max_object_count: int = 0
	for run: Dictionary in _runs:
		total_game_seconds += float(run.get("total_seconds", 0.0))
		total_wall_seconds += float(run.get("wall_seconds", 0.0))
		max_wall_to_game_ratio = maxf(
			max_wall_to_game_ratio, float(run.get("wall_to_game_ratio", 0.0))
		)
		accuracy_total += float(run.get("accuracy", 0.0))
		var core_hp := int(run.get("core_hp", 0))
		if minimum_core_hp == 0 or core_hp < minimum_core_hp:
			minimum_core_hp = core_hp
		var performance := run.get("performance", {}) as Dictionary
		var startup := performance.get("startup", {}) as Dictionary
		var run_startup_min_fps := float(startup.get("min_fps", 0.0))
		if run_startup_min_fps > 0.0 and (
			cold_start_min_fps == 0.0 or run_startup_min_fps < cold_start_min_fps
		):
			cold_start_min_fps = run_startup_min_fps
		cold_start_max_process_ms = maxf(
			cold_start_max_process_ms, float(startup.get("max_process_ms", 0.0))
		)
		cold_start_max_physics_process_ms = maxf(
			cold_start_max_physics_process_ms,
			float(startup.get("max_physics_process_ms", 0.0))
		)
		worst_mean_process_ms = maxf(
			worst_mean_process_ms, float(performance.get("mean_process_ms", 0.0))
		)
		worst_mean_physics_process_ms = maxf(
			worst_mean_physics_process_ms,
			float(performance.get("mean_physics_process_ms", 0.0))
		)
		var run_p05_fps := float(performance.get("p05_fps", 0.0))
		if run_p05_fps > 0.0 and (
			minimum_p05_fps == 0.0 or run_p05_fps < minimum_p05_fps
		):
			minimum_p05_fps = run_p05_fps
		max_draw_calls = maxi(max_draw_calls, int(performance.get("max_draw_calls", 0)))
		max_render_objects = maxi(
			max_render_objects, int(performance.get("max_render_objects", 0))
		)
		peak_static_memory_mb = maxf(
			peak_static_memory_mb, float(performance.get("max_static_memory_mb", 0.0))
		)
		max_object_count = maxi(max_object_count, int(performance.get("max_object_count", 0)))
	var mean_accuracy := accuracy_total / float(_runs.size()) if not _runs.is_empty() else 0.0
	return {
		"total_game_seconds": snappedf(total_game_seconds, 0.001),
		"total_wall_seconds": snappedf(total_wall_seconds, 0.001),
		"minimum_core_hp": minimum_core_hp,
		"mean_accuracy": snappedf(mean_accuracy, 0.001),
		"worst_mean_process_ms": snappedf(worst_mean_process_ms, 0.001),
		"worst_mean_physics_process_ms": snappedf(worst_mean_physics_process_ms, 0.001),
		"max_wall_to_game_ratio": snappedf(max_wall_to_game_ratio, 0.001),
		"minimum_p05_fps": snappedf(minimum_p05_fps, 0.001),
		"cold_start_min_fps": snappedf(cold_start_min_fps, 0.001),
		"cold_start_max_process_ms": snappedf(cold_start_max_process_ms, 0.001),
		"cold_start_max_physics_process_ms": snappedf(
			cold_start_max_physics_process_ms, 0.001
		),
		"max_draw_calls": max_draw_calls,
		"max_render_objects": max_render_objects,
		"peak_static_memory_mb": snappedf(peak_static_memory_mb, 0.001),
		"max_object_count": max_object_count,
	}


func _fail(message: String) -> void:
	_failures.append(message)


func _quit_for_qa_startup_failure(research_state: Node) -> bool:
	if research_state == null or not research_state.has_method("qa_startup_failed"):
		return false
	if not bool(research_state.call("qa_startup_failed")):
		return false
	var exit_code := 74
	if research_state.has_method("qa_startup_failure_exit_code"):
		exit_code = int(research_state.call("qa_startup_failure_exit_code"))
	quit(exit_code)
	return true
