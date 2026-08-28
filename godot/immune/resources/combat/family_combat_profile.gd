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

@export_group("Signature Hit")
@export var signature_name: String = "基礎射擊"
@export_multiline var signature_description: String = "穩定命中單一病原。"
@export_enum("none", "execute", "antibody_mark") var hit_effect: String = "none"
@export_range(0, 10, 1) var hit_effect_power: int = 0
@export_range(0, 10, 1) var hit_effect_cap: int = 0
@export_range(0.0, 1.0, 0.05) var hit_effect_threshold: float = 0.0
