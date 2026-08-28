class_name ImmuneMissionData
extends Resource

## Authored mission content. CombatLane owns behavior; this owns tuning and copy.

@export_group("Identity")
@export var id: StringName = &"MISSION-01"
@export var title: String = "核心防線"
@export_multiline var briefing: String = "保護免疫核心，推進並清除大型病原。"
@export var scene_path: String = "res://scenes/missions/mission_01_core_siege.tscn"
@export var recommended_family: StringName = &"T"
@export var required_mission_id: StringName = &""

@export_group("Objectives")
@export_range(1, 50, 1) var defense_kills: int = 6
@export_range(1.0, 20.0, 0.25) var cleanse_seconds: float = 3.5
@export_range(0.4, 8.0, 0.05) var defense_spawn_interval: float = 1.75
@export_range(0.4, 8.0, 0.05) var late_spawn_interval: float = 3.2
@export_range(1, 8, 1) var total_war_enemy_cap: int = 4

@export_group("Content")
@export var regular_enemy: PathogenProfile
@export var boss_enemy: PathogenProfile
@export var difficulty: DifficultyProfile

@export_group("Stage")
@export var background_color: Color = Color(0.015, 0.025, 0.045)
@export var floor_color: Color = Color(0.055, 0.04, 0.065)
@export var lane_color: Color = Color(0.34, 0.10, 0.14)
@export var zone_color: Color = Color(0.18, 0.9, 1.0)

@export_group("Progression")
@export var rewards: Dictionary = {"antigen": 40, "biomass": 20, "protomass": 5}
@export var discovery_flag: String = "DEMO-CLEANSE-COMPLETE"
@export var unlock_campaign_level: String = "L03"
