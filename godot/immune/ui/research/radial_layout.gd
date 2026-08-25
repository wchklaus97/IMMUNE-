class_name ImmuneRadialLayout
extends RefCounted

## Port of ui/immune-research-network/src/layout/radial-layout.js. World is 3000×3000.

const _Tokens := preload("res://ui/research/research_tokens.gd")

const WORLD_SIZE := 3000.0
const CENTER := Vector2(1500, 1500)
const FAMILY_ORDER: PackedStringArray = ["T", "B", "M", "N", "A", "D"]
const DOMAINS: PackedStringArray = ["DEF", "EXP", "WAR", "MOB", "FUS", "SUR"]
const MAX_RADIUS := 1490.0

const PAIR_SLOTS := {
	"TB": Vector2(300, 980),
	"BM": Vector2(0, 980),
	"MN": Vector2(60, 980),
	"NA": Vector2(120, 980),
	"AD": Vector2(180, 980),
	"TD": Vector2(240, 980),
	"TM": Vector2(330, 1060),
	"BN": Vector2(30, 1060),
	"MA": Vector2(90, 1060),
	"ND": Vector2(150, 1060),
	"TA": Vector2(210, 1060),
	"BD": Vector2(270, 1060),
	"TN": Vector2(0, 1150),
	"BA": Vector2(60, 1150),
	"MD": Vector2(120, 1150),
}


static func family_angle(family_id: String) -> float:
	var index := FAMILY_ORDER.find(family_id)
	if index < 0:
		return 0.0
	return float(index) * 60.0 - 90.0


static func polar(angle_deg: float, radius: float) -> Vector2:
	var r := clampf(radius, 0.0, MAX_RADIUS)
	var rad := deg_to_rad(angle_deg)
	var point := CENTER + Vector2(cos(rad), sin(rad)) * r
	return Vector2(clampf(point.x, 0.0, WORLD_SIZE), clampf(point.y, 0.0, WORLD_SIZE))


static func ring_radius(ring: String, slot: int = 1, slots: int = 1) -> float:
	match ring:
		"core":
			return 0.0
		"status":
			return 460.0
		"family_anchor":
			return 560.0
		"pair_anchor":
			return 1050.0
		"triple_anchor":
			return 1320.0
		"apex_anchor":
			return 1580.0
		"prime_anchor":
			return 1650.0
		"universal":
			return lerpf(180.0, 420.0, _slot_t(slot, 7))
		"family":
			return lerpf(560.0, 850.0, _slot_t(slot, 8))
		"pair":
			return lerpf(900.0, 1150.0, _slot_t(slot, 3))
		"triple":
			return lerpf(1250.0, 1400.0, _slot_t(slot, 3))
		"apex":
			return lerpf(1500.0, 1650.0, _slot_t(slot, 2))
		_:
			return 700.0


static func _slot_t(slot: int, slots: int) -> float:
	if slots <= 1:
		return 0.5
	return float(slot - 1) / float(slots - 1)


static func layout_node(node: Dictionary) -> Dictionary:
	var hint: Dictionary = node.get("layoutHint", {})
	var ring := str(hint.get("ring", "family"))
	var slot := int(hint.get("slot", 1))
	var kind := str(node.get("kind", ""))
	if ring == "core" or kind == "core":
		return {"position": CENTER, "ring": "core", "anchor": false}
	if kind == "character_anchor":
		return _layout_anchor(node, hint, ring)
	match ring:
		"universal":
			return _layout_universal(hint, slot)
		"status":
			return _layout_status(hint, slot)
		"pair":
			return _layout_pair(hint)
		"triple":
			return _layout_triple(node, hint, slot)
		"apex":
			return _layout_apex(hint, slot)
		_:
			return _layout_family(node, hint, slot)


static func layout_catalog(nodes: Array) -> Dictionary:
	var map := {}
	for node in nodes:
		if node is Dictionary:
			map[str(node.get("id", ""))] = layout_node(node)
	return map


static func _layout_anchor(node: Dictionary, hint: Dictionary, ring: String) -> Dictionary:
	var sector := str(hint.get("sector", ""))
	if ring == "pair_anchor" or sector.length() == 2:
		var point := _layout_pair(hint)
		point["anchor"] = true
		point["ring"] = "pair_anchor"
		return point
	if ring == "prime_anchor":
		return {"position": polar(-90.0, 1650.0), "ring": "prime_anchor", "anchor": true}
	if ring == "apex_anchor":
		var pair := "ND"
		if sector == "MEMORY":
			pair = "TB"
		elif sector == "STERILE":
			pair = "MA"
		var slot: Vector2 = PAIR_SLOTS.get(pair, Vector2(180, 1580))
		return {"position": polar(slot.x, 1580.0), "ring": "apex_anchor", "anchor": true}
	if ring == "triple_anchor":
		var families: Array = node.get("familyIds", [])
		var fam := str(families[0]) if families.size() > 0 else "T"
		return {"position": polar(family_angle(fam) + 20.0, 1320.0), "ring": "triple_anchor", "anchor": true}
	var family := sector if sector != "" else _Tokens.node_family(node)
	return {"position": polar(family_angle(family), 560.0), "ring": "family_anchor", "anchor": true}


static func _layout_universal(hint: Dictionary, slot: int) -> Dictionary:
	var domain := str(hint.get("domain", "DEF"))
	var domain_index := DOMAINS.find(domain)
	if domain_index < 0:
		domain_index = 0
	var lane := float(hint.get("lane", 0))
	var angle := float(domain_index) * 60.0 - 90.0 + lane * 8.0
	return {"position": polar(angle, _branch_radius("universal", hint, slot, 7)), "ring": "universal", "anchor": false}


static func _layout_family(node: Dictionary, hint: Dictionary, slot: int) -> Dictionary:
	var sector := str(hint.get("sector", _Tokens.node_family(node)))
	var lane := float(hint.get("lane", 0))
	var angle := family_angle(sector) + lane * 9.0
	return {"position": polar(angle, _branch_radius("family", hint, slot, 8)), "ring": "family", "anchor": false}


static func _layout_status(hint: Dictionary, slot: int) -> Dictionary:
	var lane := float(hint.get("lane", slot - 4))
	var angle := 90.0 + lane * 14.0
	return {"position": polar(angle, _branch_radius("status", hint, slot, 1)), "ring": "status", "anchor": false}


static func _branch_radius(ring: String, hint: Dictionary, slot: int, slots: int) -> float:
	var tier := int(hint.get("tier", 0))
	var stage := str(hint.get("stage", ""))
	if ring == "family":
		if tier == 1 and stage == "branch":
			return 600.0
		if tier == 1 and stage == "merge":
			return 680.0
		if tier == 2 and stage == "branch":
			return 760.0
		if tier == 2 and stage == "merge":
			return 820.0
		if tier == 3:
			return 850.0
	if ring == "universal":
		if tier == 1 and stage == "branch":
			return 210.0
		if tier == 1 and stage == "merge":
			return 300.0
		if tier == 2 and stage == "branch":
			return 360.0
		if tier == 2 and stage == "merge":
			return 410.0
	if ring == "status":
		if tier == 1 and stage == "branch":
			return 430.0
		if tier == 1 and stage == "merge":
			return 470.0
		if tier == 2 and stage == "branch":
			return 510.0
		if tier == 2 and stage == "merge":
			return 540.0
		return 460.0
	return ring_radius(ring, slot, slots)


static func _layout_pair(hint: Dictionary) -> Dictionary:
	var sector := str(hint.get("sector", "TB"))
	var slot: Vector2 = PAIR_SLOTS.get(sector, Vector2(0, 980))
	var extra := float(int(hint.get("slot", 1)) - 1) * 18.0
	return {"position": polar(slot.x, slot.y + extra), "ring": "pair", "anchor": false}


static func _layout_triple(node: Dictionary, hint: Dictionary, slot: int) -> Dictionary:
	var families: Array = node.get("familyIds", [])
	var fam := str(families[0]) if families.size() > 0 else "T"
	var angle := family_angle(fam) + float(slot) * 4.0
	return {"position": polar(angle, ring_radius("triple", slot, 3)), "ring": "triple", "anchor": false}


static func _layout_apex(hint: Dictionary, slot: int) -> Dictionary:
	var sector := str(hint.get("sector", "MEMORY"))
	if sector == "PRIME":
		return {"position": polar(-90.0, 1650.0), "ring": "apex", "anchor": false}
	var pair := "ND"
	if sector == "MEMORY":
		pair = "TB"
	elif sector == "STERILE":
		pair = "MA"
	var pair_slot: Vector2 = PAIR_SLOTS.get(pair, Vector2(0, 1500))
	return {"position": polar(pair_slot.x, ring_radius("apex", slot, 2)), "ring": "apex", "anchor": false}
