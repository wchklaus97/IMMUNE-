extends Node

signal node_completed(id: StringName)
signal duty_unlocked(family: StringName, duty: StringName)
signal skill_granted(skill_id: StringName)
signal selection_changed(id: StringName)
signal state_changed()

const SAVE_VERSION := 2
const SAVE_PATH := "user://immune_demo_save.json"
const VALID_MISSIONS: PackedStringArray = [
	"MISSION-01", "MISSION-02", "MISSION-03", "MISSION-04", "MISSION-05", "MISSION-06",
]
const VALID_FAMILIES: PackedStringArray = ["T", "B", "M", "N", "A", "D"]

const DEMO_COMPLETED: PackedStringArray = [
	"CORE-IMMUNE",
	"CHAR-BASE-T",
	"CHAR-BASE-B",
	"BASE-T-01",
	"BASE-T-02",
]

const DEMO_REVEALED: PackedStringArray = [
	"CORE-IMMUNE",
	"CHAR-BASE-T",
	"CHAR-BASE-B",
	"UNI-DEF-01",
	"UNI-EXP-01",
	"UNI-WAR-01",
	"UNI-MOB-01",
	"UNI-FUS-01",
	"UNI-SUR-01",
	"BASE-T-01",
	"BASE-T-02",
	"BASE-T-03",
	"BASE-B-01",
	"BASE-B-02",
	"BASE-B-03",
	"UNI-DEF-02",
	"UNI-EXP-02",
	"UNI-WAR-02",
	"UNI-MOB-02",
	"UNI-FUS-02",
	"UNI-SUR-02",
	"PAIR-TB-S1",
	"PAIR-TB-S2",
	"CHAR-PAIR-TB",
	"STATUS-MARK",
	"STATUS-AB",
]

const DEMO_RESOURCES := {
	"antigen": 120,
	"biomass": 40,
	"protomass": 15,
	"fusionCore": 2,
}

var completed_node_ids: Array[StringName] = []
var revealed_node_ids: Array[StringName] = []
var tracked_node_ids: Array[StringName] = []
var selected_node_id: StringName = &"CORE-IMMUNE"
var resources: Dictionary = DEMO_RESOURCES.duplicate(true)


var unlocked_campaign_level: String = "L01"
var discovery_flags: PackedStringArray = []
var global_stats: Dictionary = {}
var selected_mission_id: StringName = &"MISSION-01"
var selected_family_id: StringName = &"T"
var completed_mission_ids: Array[StringName] = []


func _ready() -> void:
	if not load_game():
		seed_demo()
		save_game()


func seed_demo() -> void:
	completed_node_ids.clear()
	revealed_node_ids.clear()
	tracked_node_ids.clear()
	for id in DEMO_COMPLETED:
		completed_node_ids.append(StringName(id))
	for id in DEMO_REVEALED:
		revealed_node_ids.append(StringName(id))
	selected_node_id = &"BASE-T-03"
	resources = DEMO_RESOURCES.duplicate(true)
	unlocked_campaign_level = "L02"
	discovery_flags.clear()
	selected_mission_id = &"MISSION-01"
	selected_family_id = &"T"
	completed_mission_ids.clear()
	_rebuild_global_stats()
	state_changed.emit()


func snapshot() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"completedNodeIds": _as_strings(completed_node_ids),
		"revealedNodeIds": _as_strings(revealed_node_ids),
		"trackedNodeIds": _as_strings(tracked_node_ids),
		"selectedNodeId": String(selected_node_id),
		"resources": resources.duplicate(true),
		"unlockedCampaignLevel": unlocked_campaign_level,
		"discoveryFlags": Array(discovery_flags),
		"selectedMissionId": String(selected_mission_id),
		"selectedFamilyId": String(selected_family_id),
		"completedMissionIds": _as_strings(completed_mission_ids),
	}


func apply_snapshot(raw_data: Dictionary, emit_change: bool = true) -> bool:
	var data := _migrate_snapshot(raw_data)
	if data.is_empty():
		return false
	completed_node_ids = _valid_names(data.get("completedNodeIds", []))
	revealed_node_ids = _valid_names(data.get("revealedNodeIds", []))
	for completed_id in completed_node_ids:
		if not revealed_node_ids.has(completed_id):
			revealed_node_ids.append(completed_id)
	tracked_node_ids = _valid_names(data.get("trackedNodeIds", []), 3)
	var loaded_selection := StringName(str(data.get("selectedNodeId", "CORE-IMMUNE")))
	selected_node_id = loaded_selection if not Catalog.get_node_def(loaded_selection).is_empty() else &"CORE-IMMUNE"
	var loaded_resources: Variant = data.get("resources", {})
	resources = DEMO_RESOURCES.duplicate(true)
	if loaded_resources is Dictionary:
		for key in DEMO_RESOURCES.keys():
			resources[key] = maxi(int(loaded_resources.get(key, resources[key])), 0)
	unlocked_campaign_level = "L0%d" % campaign_rank(str(data.get("unlockedCampaignLevel", "L01")))
	discovery_flags = PackedStringArray(data.get("discoveryFlags", []))
	selected_mission_id = _valid_choice(data.get("selectedMissionId", "MISSION-01"), VALID_MISSIONS, &"MISSION-01")
	selected_family_id = _valid_choice(data.get("selectedFamilyId", "T"), VALID_FAMILIES, &"T")
	completed_mission_ids = _valid_choices(data.get("completedMissionIds", []), VALID_MISSIONS)
	_rebuild_global_stats()
	if emit_change:
		state_changed.emit()
	return true


func save_game(path: String = SAVE_PATH) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var open_error := FileAccess.get_open_error()
		push_error("ResearchState: cannot write %s (%s)" % [path, error_string(open_error)])
		return open_error
	file.store_string(JSON.stringify(snapshot(), "\t"))
	return OK


func load_game(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("ResearchState: cannot open %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("ResearchState: invalid JSON in %s; using demo seed" % path)
		return false
	return apply_snapshot(parsed)


func grant_demo_rewards(rewards: Dictionary, discovery_flag: String = "", persist: bool = true) -> void:
	grant_mission_rewards(rewards, discovery_flag, "L03", &"MISSION-01", persist)


func grant_mission_rewards(
	rewards: Dictionary,
	discovery_flag: String,
	campaign_level: String,
	mission_id: StringName,
	persist: bool = true
) -> void:
	for key in rewards.keys():
		if not DEMO_RESOURCES.has(key):
			continue
		resources[key] = maxi(int(resources.get(key, 0)) + int(rewards[key]), 0)
	if not discovery_flag.is_empty() and not discovery_flags.has(discovery_flag):
		discovery_flags.append(discovery_flag)
	if VALID_MISSIONS.has(String(mission_id)) and not completed_mission_ids.has(mission_id):
		completed_mission_ids.append(mission_id)
	if campaign_rank(unlocked_campaign_level) < campaign_rank(campaign_level):
		unlocked_campaign_level = "L0%d" % campaign_rank(campaign_level)
	state_changed.emit()
	if persist:
		save_game()


func configure_demo_run(mission_id: StringName, family_id: StringName) -> bool:
	if not VALID_MISSIONS.has(String(mission_id)) or not VALID_FAMILIES.has(String(family_id)):
		return false
	selected_mission_id = mission_id
	selected_family_id = family_id
	state_changed.emit()
	return save_game() == OK


func _migrate_snapshot(raw_data: Dictionary) -> Dictionary:
	var data := raw_data.duplicate(true)
	var version := int(data.get("version", 0))
	if version < 0 or version > SAVE_VERSION:
		push_warning("ResearchState: unsupported save version %d" % version)
		return {}
	while version < SAVE_VERSION:
		match version:
			0:
				# Pre-versioned demo saves used the v1 field names.
				data["version"] = 1
				version = 1
			1:
				data["selectedMissionId"] = str(data.get("selectedMissionId", "MISSION-01"))
				data["selectedFamilyId"] = str(data.get("selectedFamilyId", "T"))
				data["completedMissionIds"] = data.get("completedMissionIds", [])
				data["version"] = 2
				version = 2
			_:
				push_warning("ResearchState: no migration from save version %d" % version)
				return {}
	return data


func _valid_choice(value: Variant, allowed: PackedStringArray, fallback: StringName) -> StringName:
	var text := str(value)
	return StringName(text) if allowed.has(text) else fallback


func _valid_choices(values: Variant, allowed: PackedStringArray) -> Array[StringName]:
	var out: Array[StringName] = []
	for value in _as_names(values):
		if allowed.has(String(value)) and not out.has(value):
			out.append(value)
	return out


func _as_strings(values: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(String(value))
	return out


func _as_names(values: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if values is Array or values is PackedStringArray:
		for value in values:
			out.append(StringName(str(value)))
	return out


func _valid_names(values: Variant, limit: int = 0) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in _as_names(values):
		if id == &"" or out.has(id) or Catalog.get_node_def(id).is_empty():
			continue
		out.append(id)
		if limit > 0 and out.size() >= limit:
			break
	return out


const STAT_CAPS := {
	"attackSpeed": 0.22,
	"moveSpeed": 0.18,
	"cooldown": 0.15,
	"coreRegen": 0.16,
	"unitRegen": 0.16,
	"biomassYield": 0.16,
	"critChance": 0.1,
	"weaknessAmp": 0.12,
	"armorShred": 0.12,
	"enemySlow": 0.16,
	"pathSlow": 0.1,
}


func global_stat(stat: String, duty: StringName = &"") -> float:
	var total := float(global_stats.get(stat, 0.0))
	if duty != &"":
		total += float(global_stats.get("%s:%s" % [stat, String(duty)], 0.0))
	if STAT_CAPS.has(stat):
		return minf(total, float(STAT_CAPS[stat]))
	return total


func _apply_global_stat(op_entry: Dictionary) -> void:
	var stat := str(op_entry.get("stat", ""))
	if stat == "":
		return
	var amount := float(op_entry.get("amount", 0.0))
	var duty := str(op_entry.get("duty", ""))
	var key := stat if duty.is_empty() else "%s:%s" % [stat, duty]
	global_stats[key] = float(global_stats.get(key, 0.0)) + amount


func _rebuild_global_stats() -> void:
	global_stats.clear()
	for id in completed_node_ids:
		var node: Dictionary = Catalog.get_node_def(id)
		if node.is_empty():
			continue
		for op_entry in node.get("effectOps", []):
			if op_entry is Dictionary and str(op_entry.get("op", "")) == "grant_global_stat":
				_apply_global_stat(op_entry)


func is_completed(id: StringName) -> bool:
	return completed_node_ids.has(id)


func is_revealed(id: StringName) -> bool:
	return revealed_node_ids.has(id) or is_completed(id)


func select_node(id: StringName) -> void:
	selected_node_id = id
	selection_changed.emit(id)
	state_changed.emit()
	save_game()


func toggle_track(id: StringName) -> bool:
	if not is_revealed(id):
		return false
	if tracked_node_ids.has(id):
		tracked_node_ids.erase(id)
		state_changed.emit()
		save_game()
		return true
	if tracked_node_ids.size() >= 3:
		return false
	tracked_node_ids.append(id)
	state_changed.emit()
	save_game()
	return true


func complete_node(id: StringName) -> bool:
	if is_completed(id):
		return false
	var runtime := derive_state(id)
	if str(runtime.get("eligibility", "")) != "ready":
		return false
	var node: Dictionary = Catalog.get_node_def(id)
	_deduct_costs(node)
	completed_node_ids.append(id)
	if not revealed_node_ids.has(id):
		revealed_node_ids.append(id)
	_reveal_from(id)
	node_completed.emit(id)
	_grant_from_node(id)
	state_changed.emit()
	save_game()
	return true


func derive_state(id: StringName) -> Dictionary:
	var node: Dictionary = Catalog.get_node_def(id)
	if node.is_empty():
		return {"visibility": "hidden", "completion": "incomplete", "eligibility": "hidden"}
	var visibility := "revealed" if is_revealed(id) else "hidden"
	if visibility == "hidden" and _reveal_rule_met(node):
		visibility = "revealed"
	var completion := "complete" if is_completed(id) else "incomplete"
	var eligibility := "hidden"
	if completion == "complete":
		eligibility = "completed"
	elif visibility == "hidden":
		eligibility = "hidden"
	elif not _prerequisites_met(node):
		eligibility = "missing_prerequisite"
	elif not _conditions_met(node):
		eligibility = "missing_condition"
	elif not _resources_met(node):
		eligibility = "missing_resource"
	else:
		eligibility = "ready"
	return {
		"visibility": visibility,
		"completion": completion,
		"eligibility": eligibility,
		"tracked": tracked_node_ids.has(id),
		"selected": selected_node_id == id,
	}


func _prerequisites_met(node: Dictionary) -> bool:
	var groups: Array = node.get("prerequisiteGroups", [])
	for group in groups:
		if not group is Dictionary:
			continue
		var ids: Array = group.get("nodeIds", [])
		var done := 0
		for pid in ids:
			if is_completed(StringName(str(pid))):
				done += 1
		if str(group.get("mode", "all")) == "atLeast":
			if done < int(group.get("min", 1)):
				return false
		elif done != ids.size():
			return false
	return true


func campaign_rank(id: String) -> int:
	var text := id.strip_edges().to_upper()
	if text.begins_with("L"):
		text = text.substr(1)
	var n := int(text)
	if n < 1:
		return 1
	return mini(n, 6)


func set_unlocked_campaign_level(id: String) -> void:
	var rank := campaign_rank(id)
	unlocked_campaign_level = "L0%d" % rank
	state_changed.emit()
	save_game()


func _conditions_met(node: Dictionary) -> bool:
	for condition in node.get("conditions", []):
		if condition is Dictionary and not _evaluate_condition(condition):
			return false
	return true


func _evaluate_condition(condition: Dictionary) -> bool:
	match str(condition.get("type", "")):
		"campaign_level":
			return campaign_rank(unlocked_campaign_level) >= campaign_rank(str(condition.get("min", "L01")))
		"discovery_flag", "discoveryFlag":
			return str(condition.get("flag", "")) in discovery_flags
		_:
			return true


func _unmet_condition_label(node: Dictionary) -> String:
	for condition in node.get("conditions", []):
		if not condition is Dictionary:
			continue
		if _evaluate_condition(condition):
			continue
		var ctype := str(condition.get("type", ""))
		if ctype == "campaign_level":
			return "需解鎖關卡 %s" % str(condition.get("min", ""))
		if ctype == "discovery_flag" or ctype == "discoveryFlag":
			return "需遠征發現"
	return "缺少條件"


func _reveal_rule_met(node: Dictionary) -> bool:
	var rule: Dictionary = node.get("revealRule", {"type": "on_prerequisite_visible"})
	match str(rule.get("type", "on_prerequisite_visible")):
		"always":
			return true
		"on_prerequisite_visible":
			var groups: Array = node.get("prerequisiteGroups", [])
			if groups.is_empty():
				return true
			for group in groups:
				for pid in group.get("nodeIds", []):
					if not is_revealed(StringName(str(pid))):
						return false
			return true
		"completed", "anyCompleted":
			for pid in rule.get("nodeIds", []):
				if is_completed(StringName(str(pid))):
					return true
			return false
		_:
			return is_revealed(StringName(str(node.get("id", ""))))


func _resources_met(node: Dictionary) -> bool:
	for key in _normalize_costs(node).keys():
		if int(resources.get(key, 0)) < int(_normalize_costs(node)[key]):
			return false
	return true


func _normalize_costs(node: Dictionary) -> Dictionary:
	var out := {}
	var costs: Variant = node.get("costs", [])
	if costs is Array:
		for entry in costs:
			if entry is Dictionary and entry.has("resource"):
				out[str(entry.get("resource"))] = int(entry.get("amount", 0))
	elif costs is Dictionary:
		for key in (costs as Dictionary).keys():
			out[str(key)] = int((costs as Dictionary)[key])
	return out


func cost_table(node: Dictionary) -> Dictionary:
	return _normalize_costs(node)


func _deduct_costs(node: Dictionary) -> void:
	var costs := _normalize_costs(node)
	for key in costs.keys():
		resources[key] = int(resources.get(key, 0)) - int(costs[key])


func _reveal_from(_completed_id: StringName) -> void:
	for node in Catalog.all_nodes():
		if not node is Dictionary:
			continue
		var nid := StringName(str(node.get("id", "")))
		if is_revealed(nid):
			continue
		if _reveal_rule_met(node):
			revealed_node_ids.append(nid)


func _grant_from_node(id: StringName) -> void:
	var node: Dictionary = Catalog.get_node_def(id)
	if node.is_empty():
		return
	var ops: Array = node.get("effectOps", [])
	for op_entry in ops:
		var op := str(op_entry.get("op", ""))
		var family := StringName(str(op_entry.get("familyId", "")))
		match op:
			"grant_character_usage":
				skill_granted.emit(StringName("SKILL-%s-ACTIVE" % String(family)))
			"grant_core_passive":
				skill_granted.emit(StringName("SKILL-%s-PASSIVE" % String(family)))
			"grant_fixed_turret":
				duty_unlocked.emit(family, &"fixed")
				skill_granted.emit(StringName("SKILL-%s-FIXED" % String(family)))
			"grant_mobility":
				duty_unlocked.emit(family, &"mobile")
			"grant_relay_qualification":
				duty_unlocked.emit(family, &"relay")
			"grant_ultimate":
				skill_granted.emit(StringName("SKILL-%s-APEX" % String(family)))
			"grant_global_stat":
				if op_entry is Dictionary:
					_apply_global_stat(op_entry)
