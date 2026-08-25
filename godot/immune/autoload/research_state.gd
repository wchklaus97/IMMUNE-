extends Node

signal node_completed(id: StringName)
signal duty_unlocked(family: StringName, duty: StringName)
signal skill_granted(skill_id: StringName)
signal selection_changed(id: StringName)
signal state_changed()

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

var completed_node_ids: Array[StringName] = []
var revealed_node_ids: Array[StringName] = []
var tracked_node_ids: Array[StringName] = []
var selected_node_id: StringName = &"CORE-IMMUNE"
var resources: Dictionary = {
	"antigen": 120,
	"biomass": 40,
	"protomass": 15,
	"fusionCore": 2,
}


var unlocked_campaign_level: String = "L01"
var discovery_flags: PackedStringArray = []
var global_stats: Dictionary = {}


func _ready() -> void:
	if completed_node_ids.is_empty():
		seed_demo()


func seed_demo() -> void:
	completed_node_ids.clear()
	revealed_node_ids.clear()
	for id in DEMO_COMPLETED:
		completed_node_ids.append(StringName(id))
	for id in DEMO_REVEALED:
		revealed_node_ids.append(StringName(id))
	selected_node_id = &"BASE-T-03"
	unlocked_campaign_level = "L02"
	discovery_flags.clear()
	_rebuild_global_stats()
	state_changed.emit()


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


func toggle_track(id: StringName) -> bool:
	if not is_revealed(id):
		return false
	if tracked_node_ids.has(id):
		tracked_node_ids.erase(id)
		state_changed.emit()
		return true
	if tracked_node_ids.size() >= 3:
		return false
	tracked_node_ids.append(id)
	state_changed.emit()
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
