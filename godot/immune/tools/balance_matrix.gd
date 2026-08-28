extends SceneTree

## Runs real mission scenes with deterministic autopilot and writes a local JSON report.

const _Content := preload("res://resources/combat/combat_content.gd")
const DEFAULT_OUT := "user://immune_balance_matrix.json"
const DEFAULT_TRIALS: int = 2
const DEFAULT_TIME_SCALE: float = 1.0
const MAX_GAME_SECONDS: float = 120.0
const MAX_WALL_SECONDS: float = 150.0
const BUILD_TAG: String = "campaign-expansion-candidate-1"

var _out_path: String = DEFAULT_OUT
var _trials: int = DEFAULT_TRIALS
var _time_scale: float = DEFAULT_TIME_SCALE
var _runs: Array[Dictionary] = []
var _failures: Array[String] = []
var _mission_filter: Array[StringName] = []
var _family_filter: Array[StringName] = [&"T", &"B"]


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
	_validate_matrix(mission_ids, _family_filter)
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
	lane.set("playtest_build_tag", BUILD_TAG)
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
	snapshot["trial"] = trial
	snapshot["timed_out"] = timed_out
	snapshot["timeout_reason"] = timeout_reason
	_runs.append(snapshot)
	print(
		"BALANCE_RUN mission=%s family=%s trial=%d victory=%s seconds=%.3f core=%d/%d shots=%d hits=%d"
		% [
			mission_id,
			family_id,
			trial,
			str(snapshot.get("victory", false)),
			float(snapshot.get("total_seconds", 0.0)),
			int(snapshot.get("core_hp", 0)),
			int(snapshot.get("core_max_hp", 0)),
			int(snapshot.get("shots_fired", 0)),
			int(snapshot.get("shots_hit", 0)),
		]
	)
	if timed_out:
		_fail("%s/%s trial %d timed out (%s)" % [mission_id, family_id, trial, timeout_reason])
	lane.queue_free()
	await process_frame
	await physics_frame


func _validate_matrix(mission_ids: Array[StringName], family_ids: Array[StringName]) -> void:
	var expected: int = mission_ids.size() * family_ids.size() * _trials
	if _runs.size() != expected:
		_fail("Expected %d balance runs, got %d" % [expected, _runs.size()])
	for run: Dictionary in _runs:
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
		if float(run.get("duty_seconds", {}).get("mobile", 0.0)) <= 0.0:
			_fail("%s did not exercise mobile duty" % label)
		if int(run.get("duty_switches", 0)) < 2:
			_fail("%s did not return from mobile to fixed duty" % label)
	_validate_duration_ladder(mission_ids, family_ids)


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
	var absolute_path: String = _globalized_out_path()
	var parent_dir: String = absolute_path.get_base_dir()
	if not parent_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(parent_dir)
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		_fail("Could not write report %s" % absolute_path)
	var report := {
		"schema_version": 1,
		"build_tag": BUILD_TAG,
		"run_count": _runs.size(),
		"trials_per_pair": _trials,
		"simulation_time_scale": _time_scale,
		"failures": _failures,
		"runs": _runs,
	}
	if file != null:
		file.store_string(JSON.stringify(report, "\t", false))
		file.close()
	print("BALANCE_REPORT %s" % absolute_path)
	if _failures.is_empty():
		print("BALANCE_MATRIX_OK runs=%d" % _runs.size())
		quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		quit(1)


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_path = arg.trim_prefix("--out=")
		elif arg.begins_with("--trials="):
			_trials = maxi(int(arg.trim_prefix("--trials=")), 1)
		elif arg.begins_with("--time-scale="):
			_time_scale = clampf(float(arg.trim_prefix("--time-scale=")), 1.0, 8.0)
		elif arg.begins_with("--missions="):
			_mission_filter = _parse_names(arg.trim_prefix("--missions="))
		elif arg.begins_with("--families="):
			_family_filter = _parse_names(arg.trim_prefix("--families="))


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


func _fail(message: String) -> void:
	_failures.append(message)
