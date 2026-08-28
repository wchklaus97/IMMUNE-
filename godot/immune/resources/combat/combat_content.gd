class_name CombatContent
extends RefCounted

## Stable lookup table for shipped demo resources.

const MISSION_PATHS := {
	&"MISSION-01": "res://resources/missions/mission_01_core_siege.tres",
	&"MISSION-02": "res://resources/missions/mission_02_bloodstream.tres",
	&"MISSION-03": "res://resources/missions/mission_03_cytokine_storm.tres",
	&"MISSION-04": "res://resources/missions/mission_04_mutation_breach.tres",
	&"MISSION-05": "res://resources/missions/mission_05_biofilm_regency.tres",
	&"MISSION-06": "res://resources/missions/mission_06_systemic_collapse.tres",
}

const FAMILY_PATHS := {
	&"T": "res://resources/families/family_t.tres",
	&"B": "res://resources/families/family_b.tres",
	&"M": "res://resources/families/family_m.tres",
	&"N": "res://resources/families/family_n.tres",
	&"A": "res://resources/families/family_a.tres",
	&"D": "res://resources/families/family_d.tres",
}


static func mission_ids() -> Array[StringName]:
	return Array(MISSION_PATHS.keys(), TYPE_STRING_NAME, "", null)


static func load_mission(id: StringName) -> ImmuneMissionData:
	var path := str(MISSION_PATHS.get(id, MISSION_PATHS[&"MISSION-01"]))
	return load(path) as ImmuneMissionData


static func load_family(id: StringName) -> FamilyCombatProfile:
	var path := str(FAMILY_PATHS.get(id, FAMILY_PATHS[&"T"]))
	return load(path) as FamilyCombatProfile
