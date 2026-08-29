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


func _init() -> void:
	_parse_args()
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = _time_scale
	var research_state: Node = root.get_node_or_null("ResearchState")
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


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--soak":
			_soak_mode = true
			_stop_on_failure = true
			_family_filter = ALL_FAMILIES.duplicate()
			_trials = 1
			_build_tag = SOAK_BUILD_TAG
			_min_total_game_seconds = SOAK_MIN_GAME_SECONDS
			_max_mean_process_ms = SOAK_MAX_MEAN_PROCESS_MS
			_max_wall_to_game_ratio = SOAK_MAX_WALL_TO_GAME_RATIO
			_min_fps = SOAK_MIN_FPS
		elif arg == "--stop-on-failure":
			_stop_on_failure = true
		elif arg.begins_with("--out="):
			_out_path = arg.trim_prefix("--out=")
		elif arg.begins_with("--trials="):
			_trials = maxi(int(arg.trim_prefix("--trials=")), 1)
		elif arg.begins_with("--time-scale="):
			_time_scale = clampf(float(arg.trim_prefix("--time-scale=")), 1.0, 8.0)
		elif arg.begins_with("--missions="):
			_mission_filter = _parse_names(arg.trim_prefix("--missions="))
		elif arg.begins_with("--families="):
			_family_filter = _parse_names(arg.trim_prefix("--families="))
		elif arg.begins_with("--min-total-game-seconds="):
			_min_total_game_seconds = maxf(
				float(arg.trim_prefix("--min-total-game-seconds=")), 0.0
			)
		elif arg.begins_with("--max-mean-process-ms="):
			_max_mean_process_ms = maxf(float(arg.trim_prefix("--max-mean-process-ms=")), 0.0)
		elif arg.begins_with("--max-mean-physics-ms="):
			_max_mean_physics_ms = maxf(float(arg.trim_prefix("--max-mean-physics-ms=")), 0.0)
		elif arg.begins_with("--max-wall-to-game-ratio="):
			_max_wall_to_game_ratio = maxf(
				float(arg.trim_prefix("--max-wall-to-game-ratio=")), 0.0
			)
		elif arg.begins_with("--min-fps="):
			_min_fps = maxf(float(arg.trim_prefix("--min-fps=")), 0.0)


func _parse_names(csv: String) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: String in csv.split(",", false):
		var normalized: String = value.strip_edges()
		if not normalized.is_empty():
			result.append(StringName(normalized))
	return result


func _globalized_out_path() -> String:
	if _out_path.begins_with("user://") or _out_path.begins_with("res://"):
		return ProjectSettings.globalize_path(_out_path)
	return _out_path


func _write_report(complete: bool) -> void:
	var absolute_path: String = _globalized_out_path()
	var parent_dir: String = absolute_path.get_base_dir()
	if not parent_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(parent_dir)
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		_fail("Could not write report %s" % absolute_path)
		return
	var report := {
		"schema_version": 2,
		"build_tag": _build_tag,
		"mode": "soak" if _soak_mode else "balance",
		"complete": complete,
		"aborted": _aborted,
		"run_count": _runs.size(),
		"trials_per_pair": _trials,
		"simulation_time_scale": _time_scale,
		"summary": _summary(),
		"failures": _failures,
		"runs": _runs,
	}
	file.store_string(JSON.stringify(report, "\t", false))
	file.close()


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
