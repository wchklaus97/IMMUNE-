class_name ImmuneIconLibrary
extends RefCounted

## Shared research symbols as generate2dsprite scan sheets.
## Frame count matches the family ladder: CHAR-BASE + BASE-01..08 = 10 statuses (0-9).

const SYMBOL_DIR := "res://ui_icons/symbols/"
const SHEET_DIR := "res://ui_icons/symbols/sheets/"
const SCAN_COLS := 5
const SCAN_ROWS := 2
const SCAN_FRAMES := SCAN_COLS * SCAN_ROWS

static var _cache: Dictionary = {}


static func family_path(family: String) -> String:
	return "%sSYM-FAMILY-%s.png" % [SYMBOL_DIR, family]


static func core_path() -> String:
	return "%sSYM-CORE.png" % SYMBOL_DIR


static func family_sheet_path(family: String) -> String:
	return "%sSYM-FAMILY-%s-scan.png" % [SHEET_DIR, family]


static func core_sheet_path() -> String:
	return "%sSYM-CORE-scan.png" % SHEET_DIR


static func pair_path(code: String) -> String:
	return "%sSYM-PAIR-%s.png" % [SYMBOL_DIR, code]


static func pair_sheet_path(code: String) -> String:
	return "%sSYM-PAIR-%s-scan.png" % [SHEET_DIR, code]


static func triple_path(code: String) -> String:
	return "%sSYM-TRIPLE-%s.png" % [SYMBOL_DIR, code]


static func triple_sheet_path(code: String) -> String:
	return "%sSYM-TRIPLE-%s-scan.png" % [SHEET_DIR, code]


static func _pair_code(id: String) -> String:
	if id.begins_with("CHAR-PAIR-") and id.length() == 12:
		return id.substr(10, 2)
	return ""


static func _triple_code(id: String) -> String:
	if id.begins_with("CHAR-TRIPLE-") and id.length() == 15:
		return id.substr(12, 3)
	return ""


static func apex_path(code: String) -> String:
	if code == "PRIME":
		return "%sSYM-PRIME.png" % SYMBOL_DIR
	return "%sSYM-APEX-%s.png" % [SYMBOL_DIR, code]


static func apex_sheet_path(code: String) -> String:
	if code == "PRIME":
		return "%sSYM-PRIME-scan.png" % SHEET_DIR
	return "%sSYM-APEX-%s-scan.png" % [SHEET_DIR, code]


static func _apex_code(id: String) -> String:
	if id == "CHAR-PRIME":
		return "PRIME"
	if id.begins_with("CHAR-APEX-"):
		var code := id.substr(10)
		if code == "MEMORY" or code == "STERILE" or code == "SILENT":
			return code
	return ""


static func base_slot_path(slot: String) -> String:
	return "%sSYM-BASE-%s.png" % [SYMBOL_DIR, slot]


static func base_slot_sheet_path(slot: String) -> String:
	return "%sSYM-BASE-%s-scan.png" % [SHEET_DIR, slot]


static func _base_slot(id: String) -> String:
	if id.length() != 9 or not id.begins_with("BASE-"):
		return ""
	var family := id.substr(5, 1)
	if not "TBMNAD".contains(family):
		return ""
	if id.substr(6, 1) != "-":
		return ""
	var slot := id.substr(7, 2)
	if slot < "01" or slot > "08":
		return ""
	return slot


static func uni_path(domain: String) -> String:
	return "%sSYM-UNI-%s.png" % [SYMBOL_DIR, domain]


static func uni_sheet_path(domain: String) -> String:
	return "%sSYM-UNI-%s-scan.png" % [SHEET_DIR, domain]


static func _uni_domain(id: String) -> String:
	if id.length() != 10 or not id.begins_with("UNI-"):
		return ""
	var domain := id.substr(4, 3)
	if domain != "DEF" and domain != "EXP" and domain != "WAR" and domain != "MOB" and domain != "FUS" and domain != "SUR":
		return ""
	if id.substr(7, 1) != "-":
		return ""
	var slot := id.substr(8, 2)
	if slot < "01" or slot > "07":
		return ""
	return domain


static func status_path(code: String) -> String:
	return "%sSYM-STATUS-%s.png" % [SYMBOL_DIR, code]


static func status_sheet_path(code: String) -> String:
	return "%sSYM-STATUS-%s-scan.png" % [SHEET_DIR, code]


static func _status_code(id: String) -> String:
	if not id.begins_with("STATUS-"):
		return ""
	var code := id.substr(7)
	if code == "MARK" or code == "AB" or code == "COR" or code == "SLOW" or code == "INF" or code == "CHAIN" or code == "CRIT":
		return code
	return ""


static func pair_research_path(slot: String) -> String:
	return "%sSYM-PAIR-%s.png" % [SYMBOL_DIR, slot]


static func pair_research_sheet_path(slot: String) -> String:
	return "%sSYM-PAIR-%s-scan.png" % [SHEET_DIR, slot]


static func _pair_research_slot(id: String) -> String:
	if id.length() != 10 or not id.begins_with("PAIR-"):
		return ""
	var fam := id.substr(5, 2)
	if fam.length() != 2:
		return ""
	if not "TBMNAD".contains(fam[0]) or not "TBMNAD".contains(fam[1]):
		return ""
	if id.substr(7, 1) != "-":
		return ""
	var slot := id.substr(8, 2)
	if slot == "S1" or slot == "S2" or slot == "S4":
		return slot
	return ""


static func triple_research_path(slot: String) -> String:
	return "%sSYM-TRIPLE-%s.png" % [SYMBOL_DIR, slot]


static func triple_research_sheet_path(slot: String) -> String:
	return "%sSYM-TRIPLE-%s-scan.png" % [SHEET_DIR, slot]


static func _triple_research_slot(id: String) -> String:
	if id.length() != 15 or not id.begins_with("TRIPLE-"):
		return ""
	var fam := id.substr(7, 3)
	if fam.length() != 3:
		return ""
	if not "TBMNAD".contains(fam[0]) or not "TBMNAD".contains(fam[1]) or not "TBMNAD".contains(fam[2]):
		return ""
	if id.substr(10, 1) != "-":
		return ""
	var slot := id.substr(11)
	if slot == "ROLE" or slot == "RULE" or slot == "APEX":
		return slot
	return ""


static func apex_research_path(slot: String) -> String:
	return "%sSYM-APEX-%s.png" % [SYMBOL_DIR, slot]


static func apex_research_sheet_path(slot: String) -> String:
	return "%sSYM-APEX-%s-scan.png" % [SHEET_DIR, slot]


static func _apex_research_slot(id: String) -> String:
	if not id.begins_with("APEX-"):
		return ""
	var slot := ""
	var mid := ""
	if id.ends_with("-GATE"):
		slot = "GATE"
		mid = id.substr(5, id.length() - 10)
	elif id.ends_with("-PROTOCOL"):
		slot = "PROTOCOL"
		mid = id.substr(5, id.length() - 15)
	else:
		return ""
	if mid == "MEMORY" or mid == "STERILE" or mid == "SILENT" or mid == "PRIME":
		return slot
	return ""


static func skill_slot_path(slot: String) -> String:
	return "%sSYM-SKILL-%s.png" % [SYMBOL_DIR, slot]


static func _skill_slot(id: String) -> String:
	if not id.begins_with("SKILL-"):
		return ""
	if id.ends_with("-PASSIVE") or id.ends_with("-P1") or id.ends_with("-ROLE") or id.ends_with("-GATE"):
		return "PASSIVE"
	if id.ends_with("-ACTIVE") or id.ends_with("-P2") or id.ends_with("-RULE"):
		return "ACTIVE"
	if id.ends_with("-FIXED") or id.ends_with("-DEF"):
		return "FIXED"
	if id.ends_with("-PROTO"):
		return "PROTOCOL"
	if id.ends_with("-APEX") or id.ends_with("-ULT"):
		return "APEX"
	return ""


static func texture_for_skill(id: StringName) -> Texture2D:
	var slot := _skill_slot(String(id))
	if slot.is_empty():
		return null
	return _load(skill_slot_path(slot))


static func scan_level(done: int, total: int, frames: int = SCAN_FRAMES) -> int:
	if frames <= 1:
		return 0
	if total <= 0 or done <= 0:
		return 0
	if done >= total:
		return frames - 1
	return clampi(int(round(float(done) / float(total) * float(frames - 1))), 0, frames - 1)


static func scan_level_from_eligibility(eligibility: String, frames: int = SCAN_FRAMES) -> int:
	match eligibility:
		"hidden":
			return 0
		"missing_prerequisite":
			return mini(1, frames - 1)
		"missing_condition":
			return mini(3, frames - 1)
		"missing_resource":
			return mini(5, frames - 1)
		"ready":
			return mini(7, frames - 1)
		"completed":
			return frames - 1
		_:
			return 0


static func texture_for_family(family: String) -> Texture2D:
	if family.is_empty():
		return null
	return _load(family_path(family))


static func sheet_for_family(family: String) -> Texture2D:
	if family.is_empty():
		return null
	return _load(family_sheet_path(family))


static func sheet_for_node(id: StringName, family: String, kind: String) -> Texture2D:
	var text := String(id)
	if kind == "core" or text == "CORE-IMMUNE":
		return _load(core_sheet_path())
	if text.begins_with("CHAR-BASE-") and text.length() == 11:
		return sheet_for_family(family)
	var pair := _pair_code(text)
	if not pair.is_empty():
		return _load(pair_sheet_path(pair))
	var triple := _triple_code(text)
	if not triple.is_empty():
		return _load(triple_sheet_path(triple))
	var apex := _apex_code(text)
	if not apex.is_empty():
		return _load(apex_sheet_path(apex))
	var slot := _base_slot(text)
	if not slot.is_empty():
		return _load(base_slot_sheet_path(slot))
	var uni := _uni_domain(text)
	if not uni.is_empty():
		return _load(uni_sheet_path(uni))
	var status := _status_code(text)
	if not status.is_empty():
		return _load(status_sheet_path(status))
	var pair_slot := _pair_research_slot(text)
	if not pair_slot.is_empty():
		return _load(pair_research_sheet_path(pair_slot))
	var triple_slot := _triple_research_slot(text)
	if not triple_slot.is_empty():
		return _load(triple_research_sheet_path(triple_slot))
	var apex_slot := _apex_research_slot(text)
	if not apex_slot.is_empty():
		return _load(apex_research_sheet_path(apex_slot))
	return null


static func texture_for_node(id: StringName, family: String, kind: String) -> Texture2D:
	var text := String(id)
	if kind == "core" or text == "CORE-IMMUNE":
		return _load(core_path())
	if text.begins_with("CHAR-BASE-") and text.length() == 11:
		return texture_for_family(family)
	var pair := _pair_code(text)
	if not pair.is_empty():
		return _load(pair_path(pair))
	var triple := _triple_code(text)
	if not triple.is_empty():
		return _load(triple_path(triple))
	var apex := _apex_code(text)
	if not apex.is_empty():
		return _load(apex_path(apex))
	var slot := _base_slot(text)
	if not slot.is_empty():
		return _load(base_slot_path(slot))
	var uni := _uni_domain(text)
	if not uni.is_empty():
		return _load(uni_path(uni))
	var status := _status_code(text)
	if not status.is_empty():
		return _load(status_path(status))
	var pair_slot := _pair_research_slot(text)
	if not pair_slot.is_empty():
		return _load(pair_research_path(pair_slot))
	var triple_slot := _triple_research_slot(text)
	if not triple_slot.is_empty():
		return _load(triple_research_path(triple_slot))
	var apex_slot := _apex_research_slot(text)
	if not apex_slot.is_empty():
		return _load(apex_research_path(apex_slot))
	return null


static func atlas_for_family(family: String, level: int) -> AtlasTexture:
	return _atlas(family_sheet_path(family), level)


static func atlas_for_node(id: StringName, family: String, kind: String, level: int) -> AtlasTexture:
	var text := String(id)
	if kind == "core" or text == "CORE-IMMUNE":
		return _atlas(core_sheet_path(), level)
	if text.begins_with("CHAR-BASE-") and text.length() == 11:
		return _atlas(family_sheet_path(family), level)
	var pair := _pair_code(text)
	if not pair.is_empty():
		return _atlas(pair_sheet_path(pair), level)
	var triple := _triple_code(text)
	if not triple.is_empty():
		return _atlas(triple_sheet_path(triple), level)
	var apex := _apex_code(text)
	if not apex.is_empty():
		return _atlas(apex_sheet_path(apex), level)
	var slot := _base_slot(text)
	if not slot.is_empty():
		return _atlas(base_slot_sheet_path(slot), level)
	var uni := _uni_domain(text)
	if not uni.is_empty():
		return _atlas(uni_sheet_path(uni), level)
	var status := _status_code(text)
	if not status.is_empty():
		return _atlas(status_sheet_path(status), level)
	var pair_slot := _pair_research_slot(text)
	if not pair_slot.is_empty():
		return _atlas(pair_research_sheet_path(pair_slot), level)
	var triple_slot := _triple_research_slot(text)
	if not triple_slot.is_empty():
		return _atlas(triple_research_sheet_path(triple_slot), level)
	var apex_slot := _apex_research_slot(text)
	if not apex_slot.is_empty():
		return _atlas(apex_research_sheet_path(apex_slot), level)
	return null


static func _atlas(path: String, level: int) -> AtlasTexture:
	var sheet := _load(path)
	if sheet == null:
		return null
	var frame := clampi(level, 0, SCAN_FRAMES - 1)
	var key := "%s#%d" % [path, frame]
	if _cache.has(key):
		return _cache[key]
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var frame_w := float(sheet.get_width()) / float(SCAN_COLS)
	var frame_h := float(sheet.get_height()) / float(SCAN_ROWS)
	var col := frame % SCAN_COLS
	var row := int(frame / SCAN_COLS)
	atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
	_cache[key] = atlas
	return atlas


static func _load(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null:
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_path):
			var image := Image.new()
			if image.load(abs_path) == OK:
				tex = ImageTexture.create_from_image(image)
	_cache[path] = tex
	return tex
