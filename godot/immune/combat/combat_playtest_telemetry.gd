class_name CombatPlaytestTelemetry
extends RefCounted

## Runtime-only combat metrics. Nothing is uploaded and normal play does not write files.

const SCHEMA_VERSION: int = 2
const PERFORMANCE_SAMPLE_INTERVAL_SECONDS: float = 1.0
const PERFORMANCE_WARMUP_FRAMES: int = 120

var _mission_id: String = ""
var _family_id: String = ""
var _build_tag: String = ""
var _elapsed_seconds: float = 0.0
var _phase_started_at: float = 0.0
var _phase_name: String = ""
var _phase_durations: Dictionary = {}
var _duty_seconds: Dictionary = {"fixed": 0.0, "mobile": 0.0}
var _shots_fired: int = 0
var _shots_hit: int = 0
var _damage_dealt: int = 0
var _boss_damage_dealt: int = 0
var _enemies_defeated: int = 0
var _bosses_defeated: int = 0
var _core_damage_taken: int = 0
var _core_hp: int = 0
var _core_max_hp: int = 0
var _last_core_hp: int = -1
var _duty_switches: int = 0
var _frame_count: int = 0
var _frame_delta_total: float = 0.0
var _max_frame_delta: float = 0.0
var _next_performance_sample_seconds: float = 0.0
var _startup_performance_sample_count: int = 0
var _startup_min_fps: float = INF
var _startup_max_process_ms: float = 0.0
var _startup_max_physics_process_ms: float = 0.0
var _performance_sample_count: int = 0
var _fps_sample_count: int = 0
var _fps_total: float = 0.0
var _min_fps: float = INF
var _fps_samples: Array[float] = []
var _process_ms_total: float = 0.0
var _max_process_ms: float = 0.0
var _physics_process_ms_total: float = 0.0
var _max_physics_process_ms: float = 0.0
var _max_draw_calls: int = 0
var _max_render_objects: int = 0
var _max_static_memory_mb: float = 0.0
var _max_object_count: int = 0
var _victory: bool = false
var _ended: bool = false


func begin(mission_id: StringName, family_id: StringName, build_tag: String = "local") -> void:
	_mission_id = String(mission_id)
	_family_id = String(family_id)
	_build_tag = build_tag


func tick(delta: float, duty: StringName) -> void:
	if _ended:
		return
	var safe_delta: float = maxf(delta, 0.0)
	_elapsed_seconds += safe_delta
	_frame_count += 1
	_frame_delta_total += safe_delta
	_max_frame_delta = maxf(_max_frame_delta, safe_delta)
	if _elapsed_seconds >= _next_performance_sample_seconds:
		_next_performance_sample_seconds += PERFORMANCE_SAMPLE_INTERVAL_SECONDS
		_sample_performance_for_current_frame()
	var duty_key: String = String(duty)
	if not _duty_seconds.has(duty_key):
		_duty_seconds[duty_key] = 0.0
	_duty_seconds[duty_key] = float(_duty_seconds[duty_key]) + safe_delta


func enter_phase(next_phase_name: String) -> void:
	if not _phase_name.is_empty():
		_phase_durations[_phase_name] = float(_phase_durations.get(_phase_name, 0.0)) + (
			_elapsed_seconds - _phase_started_at
		)
	_phase_name = next_phase_name
	_phase_started_at = _elapsed_seconds


func record_shot() -> void:
	_shots_fired += 1


func record_hit(amount: int, was_boss: bool) -> void:
	_shots_hit += 1
	_damage_dealt += maxi(amount, 0)
	if was_boss:
		_boss_damage_dealt += maxi(amount, 0)


func record_enemy_defeated(was_boss: bool) -> void:
	_enemies_defeated += 1
	if was_boss:
		_bosses_defeated += 1


func record_core_hp(hp: int, max_hp: int) -> void:
	_core_hp = maxi(hp, 0)
	_core_max_hp = maxi(max_hp, 0)
	if _last_core_hp >= 0 and hp < _last_core_hp:
		_core_damage_taken += _last_core_hp - hp
	_last_core_hp = hp


func record_duty_switch() -> void:
	_duty_switches += 1


func finish(victory: bool) -> void:
	if _ended:
		return
	_victory = victory
	_ended = true


func is_finished() -> bool:
	return _ended


func snapshot() -> Dictionary:
	var accuracy: float = 0.0
	if _shots_fired > 0:
		accuracy = float(_shots_hit) / float(_shots_fired)
	var mean_frame_ms: float = 0.0
	if _frame_count > 0:
		mean_frame_ms = _frame_delta_total * 1000.0 / float(_frame_count)
	return {
		"schema_version": SCHEMA_VERSION,
		"mission_id": _mission_id,
		"family_id": _family_id,
		"build_tag": _build_tag,
		"platform": OS.get_name(),
		"display_server": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_driver_name(),
		"godot_version": String(Engine.get_version_info().get("string", "unknown")),
		"victory": _victory,
		"ended": _ended,
		"total_seconds": snappedf(_elapsed_seconds, 0.001),
		"phase_durations": _rounded_dictionary(_phase_snapshot()),
		"duty_seconds": _rounded_dictionary(_duty_seconds),
		"duty_switches": _duty_switches,
		"shots_fired": _shots_fired,
		"shots_hit": _shots_hit,
		"accuracy": snappedf(accuracy, 0.001),
		"damage_dealt": _damage_dealt,
		"boss_damage_dealt": _boss_damage_dealt,
		"enemies_defeated": _enemies_defeated,
		"bosses_defeated": _bosses_defeated,
		"core_damage_taken": _core_damage_taken,
		"core_hp": _core_hp,
		"core_max_hp": _core_max_hp,
		"frame_count": _frame_count,
		"mean_frame_ms": snappedf(mean_frame_ms, 0.001),
		"max_frame_ms": snappedf(_max_frame_delta * 1000.0, 0.001),
		"performance": _performance_snapshot(),
	}


func _sample_performance() -> void:
	_performance_sample_count += 1
	var fps := float(Performance.get_monitor(Performance.TIME_FPS))
	if fps > 0.0:
		_fps_sample_count += 1
		_fps_total += fps
		_min_fps = minf(_min_fps, fps)
		_fps_samples.append(fps)
	var process_ms := float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
	var physics_process_ms := (
		float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
	)
	_process_ms_total += maxf(process_ms, 0.0)
	_max_process_ms = maxf(_max_process_ms, process_ms)
	_physics_process_ms_total += maxf(physics_process_ms, 0.0)
	_max_physics_process_ms = maxf(_max_physics_process_ms, physics_process_ms)
	_max_draw_calls = maxi(
		_max_draw_calls,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	)
	_max_render_objects = maxi(
		_max_render_objects,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	)
	_max_static_memory_mb = maxf(
		_max_static_memory_mb,
		float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1_048_576.0
	)
	_max_object_count = maxi(
		_max_object_count,
		int(Performance.get_monitor(Performance.OBJECT_COUNT))
	)


func sample_performance_now() -> void:
	## Explicit probe for focused tests/tools. Normal runtime sampling is paced to
	## one query per simulated second because Godot may hold monitor values that long.
	_sample_performance()


func _sample_performance_for_current_frame() -> void:
	if _frame_count <= PERFORMANCE_WARMUP_FRAMES:
		_sample_startup_performance()
	if _frame_count >= PERFORMANCE_WARMUP_FRAMES:
		_sample_performance()


func _sample_startup_performance() -> void:
	_startup_performance_sample_count += 1
	var fps := float(Performance.get_monitor(Performance.TIME_FPS))
	if fps > 0.0:
		_startup_min_fps = minf(_startup_min_fps, fps)
	_startup_max_process_ms = maxf(
		_startup_max_process_ms,
		float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
	)
	_startup_max_physics_process_ms = maxf(
		_startup_max_physics_process_ms,
		float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
	)


func _performance_snapshot() -> Dictionary:
	var mean_fps: float = 0.0
	var min_fps: float = 0.0
	var p05_fps: float = 0.0
	if _fps_sample_count > 0:
		mean_fps = _fps_total / float(_fps_sample_count)
		min_fps = _min_fps
		var sorted_fps := _fps_samples.duplicate()
		sorted_fps.sort()
		p05_fps = sorted_fps[mini(int(float(sorted_fps.size() - 1) * 0.05), sorted_fps.size() - 1)]
	var mean_process_ms: float = 0.0
	var mean_physics_process_ms: float = 0.0
	if _performance_sample_count > 0:
		mean_process_ms = _process_ms_total / float(_performance_sample_count)
		mean_physics_process_ms = (
			_physics_process_ms_total / float(_performance_sample_count)
		)
	return {
		"warmup_frames": PERFORMANCE_WARMUP_FRAMES,
		"startup": {
			"sample_count": _startup_performance_sample_count,
			"min_fps": snappedf(
				_startup_min_fps if _startup_min_fps < INF else 0.0, 0.001
			),
			"max_process_ms": snappedf(_startup_max_process_ms, 0.001),
			"max_physics_process_ms": snappedf(
				_startup_max_physics_process_ms, 0.001
			),
		},
		"sample_count": _performance_sample_count,
		"fps_sample_count": _fps_sample_count,
		"mean_fps": snappedf(mean_fps, 0.001),
		"min_fps": snappedf(min_fps, 0.001),
		"p05_fps": snappedf(p05_fps, 0.001),
		"mean_process_ms": snappedf(mean_process_ms, 0.001),
		"max_process_ms": snappedf(_max_process_ms, 0.001),
		"mean_physics_process_ms": snappedf(mean_physics_process_ms, 0.001),
		"max_physics_process_ms": snappedf(_max_physics_process_ms, 0.001),
		"max_draw_calls": _max_draw_calls,
		"max_render_objects": _max_render_objects,
		"max_static_memory_mb": snappedf(_max_static_memory_mb, 0.001),
		"max_object_count": _max_object_count,
	}


func _rounded_dictionary(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: Variant in source:
		result[String(key)] = snappedf(float(source[key]), 0.001)
	return result


func _phase_snapshot() -> Dictionary:
	var result: Dictionary = _phase_durations.duplicate(true)
	if not _phase_name.is_empty() and not _ended:
		result[_phase_name] = float(result.get(_phase_name, 0.0)) + (
			_elapsed_seconds - _phase_started_at
		)
	return result
