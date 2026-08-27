class_name FamilyCombatProfile
extends Resource

## Designer-owned combat tuning for one base immune family.

@export var family_id: StringName = &"T"
@export var role_name: String = "處決者"
@export_multiline var role_description: String = ""
@export_range(1, 20, 1) var projectile_damage: int = 1
@export_range(0.15, 2.0, 0.01) var fixed_fire_cooldown: float = 0.55
@export_range(0.15, 2.0, 0.01) var mobile_fire_cooldown: float = 0.72
@export_range(4.0, 20.0, 0.25) var fire_range: float = 11.0
@export_range(2.0, 12.0, 0.1) var move_speed: float = 6.4
@export var projectile_color: Color = Color(1.0, 0.55, 0.22, 1.0)
