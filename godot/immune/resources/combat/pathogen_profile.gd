class_name PathogenProfile
extends Resource

## Read-only pathogen blueprint. Runtime HP remains on Bacterium instances.

@export_group("Identity")
@export var id: StringName = &"pathogen"
@export var display_name: String = "病原"
@export_multiline var description: String = ""

@export_group("Combat")
@export_range(1, 500, 1) var max_health: int = 3
@export_range(0.1, 12.0, 0.05) var move_speed: float = 2.4
@export_range(1, 50, 1) var core_damage: int = 1
@export_range(0.25, 5.0, 0.05) var visual_scale: float = 1.0
@export var is_boss: bool = false

@export_group("Presentation")
@export var body_color: Color = Color(0.42, 0.72, 0.28, 1.0)
@export_range(0.0, 2.0, 0.05) var emission_strength: float = 0.15
@export_range(0, 2, 1) var shape_variant: int = 0
