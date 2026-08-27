class_name DifficultyProfile
extends Resource

## Mission-wide difficulty curve. Applied to shared pathogen blueprints.

@export var id: StringName = &"normal"
@export var display_name: String = "正常"
@export_range(1, 10, 1) var rank: int = 1
@export_range(0.5, 4.0, 0.05) var health_multiplier: float = 1.0
@export_range(0.5, 3.0, 0.05) var speed_multiplier: float = 1.0
@export_range(0.4, 2.0, 0.05) var spawn_interval_multiplier: float = 1.0
@export_range(0.5, 4.0, 0.05) var boss_health_multiplier: float = 1.0
