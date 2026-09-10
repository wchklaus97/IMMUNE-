class_name ActiveSkillController
extends Node

## Cooldown-only component. World targeting/effects stay with the combat owner.

signal activation_requested(profile: FamilyActiveSkillProfile)
signal cooldown_changed(remaining_seconds: float, duration_seconds: float)

@export var profile: FamilyActiveSkillProfile

var _remaining_seconds: float = 0.0
var _last_emitted_second: int = 0


func configure(next_profile: FamilyActiveSkillProfile) -> void:
	profile = next_profile
	_remaining_seconds = 0.0
	_last_emitted_second = 0
	cooldown_changed.emit(0.0, cooldown_duration())


func tick(delta: float) -> void:
	if _remaining_seconds <= 0.0:
		return
	var previous := _remaining_seconds
	_remaining_seconds = maxf(_remaining_seconds - maxf(delta, 0.0), 0.0)
	var display_second := ceili(_remaining_seconds)
	if not is_equal_approx(previous, _remaining_seconds) and display_second != _last_emitted_second:
		_last_emitted_second = display_second
		cooldown_changed.emit(_remaining_seconds, cooldown_duration())


func request_activation() -> bool:
	if profile == null or not is_ready():
		return false
	_remaining_seconds = cooldown_duration()
	_last_emitted_second = ceili(_remaining_seconds)
	activation_requested.emit(profile)
	cooldown_changed.emit(_remaining_seconds, cooldown_duration())
	return true


func is_ready() -> bool:
	return profile != null and _remaining_seconds <= 0.0


func remaining_seconds() -> float:
	return _remaining_seconds


func cooldown_duration() -> float:
	return maxf(profile.cooldown_seconds, 0.01) if profile != null else 0.0


func reset() -> void:
	_remaining_seconds = 0.0
	_last_emitted_second = 0
	cooldown_changed.emit(0.0, cooldown_duration())
