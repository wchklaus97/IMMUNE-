class_name CombatEncounterDirector
extends Node

## Deterministic authored mission-event clock. Effects are resolved by CombatLane.

signal event_triggered(event_id: StringName, strength: int, occurrence: int)

const LIVE_PHASES: Array[StringName] = [&"core", &"expedition", &"total_war"]

var _pattern: StringName = &"steady"
var _interval: float = 10.0
var _strength: int = 0
var _phase: StringName = &""
var _remaining: float = INF
var _occurrence: int = 0


func configure(mission: ImmuneMissionData) -> void:
	_pattern = StringName(mission.encounter_pattern) if mission != null else &"steady"
	_interval = maxf(mission.encounter_interval, 0.25) if mission != null else 10.0
	_strength = maxi(mission.encounter_strength, 0) if mission != null else 0
	_phase = &""
	_remaining = INF
	_occurrence = 0


func enter_phase(phase: StringName) -> void:
	_phase = phase
	_remaining = _interval if _is_live() else INF


func tick(delta: float) -> void:
	if not _is_live() or _pattern == &"steady" or _strength <= 0:
		return
	_remaining -= maxf(delta, 0.0)
	if _remaining > 0.0:
		return
	_occurrence += 1
	_remaining = _interval
	event_triggered.emit(_event_id(), _strength, _occurrence)


func occurrence_count() -> int:
	return _occurrence


func _is_live() -> bool:
	return LIVE_PHASES.has(_phase)


func _event_id() -> StringName:
	if _pattern == &"systemic":
		return &"systemic_surge" if _occurrence % 2 == 1 else &"systemic_biofilm"
	return _pattern
