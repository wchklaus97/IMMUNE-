class_name FamilyActiveSkillProfile
extends Resource

## Read-only designer data for one deliberate family ability.

@export_group("Identity")
@export var id: StringName = &"SKILL-T-EXECUTION-BURST"
@export var name_key: StringName = &"SKILL_T_ACTIVE_NAME"
@export var description_key: StringName = &"SKILL_T_ACTIVE_DESCRIPTION"

@export_group("Timing and targeting")
@export_range(1.0, 30.0, 0.25) var cooldown_seconds: float = 8.0
@export_range(1.0, 20.0, 0.25) var radius: float = 11.0
@export_range(1, 12, 1) var max_targets: int = 1
@export_enum("nearest", "lowest_health", "spread") var targeting: String = "nearest"

@export_group("Effect")
@export_range(0, 30, 1) var damage: int = 4
@export_enum("none", "execute", "antibody_mark") var hit_effect: String = "none"
@export_range(0, 10, 1) var hit_effect_power: int = 0
@export_range(0, 10, 1) var hit_effect_cap: int = 0
@export_range(0.0, 1.0, 0.05) var hit_effect_threshold: float = 0.0
@export_range(0, 12, 1) var core_heal: int = 0
