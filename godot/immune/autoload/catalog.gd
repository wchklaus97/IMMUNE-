extends Node

## Loads immune_catalog.json. IDs must match the HTML catalog exactly.

var _data: Dictionary = {}

func _ready() -> void:
	var path := "res://resources/catalog/immune_catalog.json"
	if not FileAccess.file_exists(path):
		push_error("IMMUNE catalog missing: %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open catalog")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Catalog JSON is not an object")
		return
	_data = parsed


func all_nodes() -> Array:
	var nodes: Variant = _data.get("nodes", [])
	if nodes is Array:
		return nodes
	return []


func node_count() -> int:
	return all_nodes().size()


func get_node_def(id: StringName) -> Dictionary:
	for node in all_nodes():
		if StringName(str(node.get("id", ""))) == id:
			return node
	push_error("Unknown research node: %s" % String(id))
	return {}


func family_ladder_progress(family: String) -> Vector2i:
	var done := 0
	var total := 0
	var ids: PackedStringArray = ["CHAR-BASE-%s" % family]
	for slot in range(1, 9):
		ids.append("BASE-%s-%02d" % [family, slot])
	for id in ids:
		var node := _find_node(StringName(id))
		if node.is_empty():
			continue
		total += 1
		if ResearchState.is_completed(StringName(id)):
			done += 1
	return Vector2i(done, total)


func pair_ladder_progress(code: String) -> Vector2i:
	var done := 0
	var total := 0
	var ids: PackedStringArray = [
		"CHAR-PAIR-%s" % code,
		"PAIR-%s-S1" % code,
		"PAIR-%s-S2" % code,
		"PAIR-%s-S4" % code
	]
	for id in ids:
		var node := _find_node(StringName(id))
		if node.is_empty():
			continue
		total += 1
		if ResearchState.is_completed(StringName(id)):
			done += 1
	return Vector2i(done, total)


func triple_ladder_progress(code: String) -> Vector2i:
	var done := 0
	var total := 0
	var ids: PackedStringArray = [
		"CHAR-TRIPLE-%s" % code,
		"TRIPLE-%s-ROLE" % code,
		"TRIPLE-%s-RULE" % code,
		"TRIPLE-%s-APEX" % code
	]
	for id in ids:
		var node := _find_node(StringName(id))
		if node.is_empty():
			continue
		total += 1
		if ResearchState.is_completed(StringName(id)):
			done += 1
	return Vector2i(done, total)


func apex_ladder_progress(code: String) -> Vector2i:
	var done := 0
	var total := 0
	var ids: PackedStringArray = []
	if code == "PRIME":
		ids = PackedStringArray(["CHAR-PRIME", "APEX-PRIME-GATE", "APEX-PRIME-PROTOCOL"])
	else:
		ids = PackedStringArray([
			"CHAR-APEX-%s" % code,
			"APEX-%s-GATE" % code,
			"APEX-%s-PROTOCOL" % code
		])
	for id in ids:
		var node := _find_node(StringName(id))
		if node.is_empty():
			continue
		total += 1
		if ResearchState.is_completed(StringName(id)):
			done += 1
	return Vector2i(done, total)


func family_progress(family: String) -> Vector2i:
	var total := 0
	var done := 0
	for node in all_nodes():
		if not node is Dictionary:
			continue
		var ids: Array = node.get("familyIds", [])
		if not ids.has(family):
			continue
		total += 1
		if ResearchState.is_completed(StringName(str(node.get("id", "")))):
			done += 1
	return Vector2i(done, total)


func _find_node(id: StringName) -> Dictionary:
	for node in all_nodes():
		if StringName(str(node.get("id", ""))) == id:
			return node
	return {}


func get_skill(id: StringName) -> Dictionary:
	for skill in _data.get("skills", []):
		if StringName(str(skill.get("id", ""))) == id:
			return skill
	push_error("Unknown skill: %s" % String(id))
	return {}


func character_skills(character_id: StringName) -> Array:
	for character in _data.get("characters", []):
		if StringName(str(character.get("id", ""))) == character_id:
			return character.get("skills", [])
	return []


func campaign_level_name(id: String) -> String:
	for row in _data.get("campaignLevels", []):
		if row is Array and (row as Array).size() >= 2 and str((row as Array)[0]) == id:
			return str((row as Array)[1])
	return ""
