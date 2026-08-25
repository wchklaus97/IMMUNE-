extends SceneTree

## Headless check: six base scenes load and A has no walk kit.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/kit_lock_preview.tscn") as PackedScene
	if packed == null:
		push_error("kit_lock_preview.tscn missing")
		quit(1)
		return
	root.add_child(packed.instantiate())
	await create_timer(0.15).timeout
	var units: Array[Node] = get_nodes_in_group("immune_character")
	if units.size() < 6:
		push_error("Expected 6 immune_character nodes, got %d" % units.size())
		quit(1)
		return
	var by_family := {}
	for unit in units:
		by_family[str(unit.get("family_id"))] = unit
		if unit.get_node_or_null("Face/Mouth") == null:
			push_error("%s missing Face/Mouth" % unit.get("family_id"))
			quit(1)
			return
		if unit.get_node_or_null("LimbKit/ArmL") == null or unit.get_node_or_null("LimbKit/ArmR") == null:
			push_error("%s missing stubby arms" % unit.get("family_id"))
			quit(1)
			return
		if str(unit.get("family_id")) == "A":
			if unit.get_node_or_null("DutyKits/RelayDish") == null:
				push_error("CHAR-BASE-A missing RelayDish")
				quit(1)
				return
			if unit.get_node_or_null("DutyKits/LocomotionKit") != null:
				push_error("CHAR-BASE-A must not keep LocomotionKit")
				quit(1)
				return
			if unit.get_node_or_null("LimbKit/FootL") != null:
				push_error("CHAR-BASE-A must hover without planted feet")
				quit(1)
				return
			var a_core := unit.get_node_or_null("CoreMesh") as Node3D
			if a_core == null or a_core.position.y < 0.2:
				push_error("CHAR-BASE-A core should hover above the line")
				quit(1)
				return
		elif unit.get_node_or_null("LimbKit/FootL") == null:
			push_error("%s missing grounded feet" % unit.get("family_id"))
			quit(1)
			return
	var look := load("res://characters/family_look.gd")
	for family in ["T", "B", "A"]:
		if not by_family.has(family):
			push_error("Missing lineup family %s" % family)
			quit(1)
			return
		var line_tex: Texture2D = look.call("load_png", look.call("line_path", family))
		if line_tex == null:
			push_error("Missing base-cell-line-v2 portrait for %s" % family)
			quit(1)
			return
	if look.call("load_png", look.call("lineup_path")) == null:
		push_error("Missing base-cell-line-v2 LINEUP.png")
		quit(1)
		return
	for unit in units:
		if unit.has_method("transform_duty"):
			unit.call("transform_duty", &"mobile")
	var research := load("res://ui/research/research_network.tscn") as PackedScene
	if research == null:
		push_error("research_network.tscn missing")
		quit(1)
		return
	root.add_child(research.instantiate())
	var catalog := root.get_node_or_null("Catalog")
	var research_state := root.get_node_or_null("ResearchState")
	if catalog == null or research_state == null:
		push_error("Autoloads Catalog/ResearchState missing")
		quit(1)
		return
	if int(catalog.call("node_count")) != 200:
		push_error("Catalog should have 200 nodes, got %d" % int(catalog.call("node_count")))
		quit(1)
		return
	if not bool(research_state.call("is_completed", &"CORE-IMMUNE")):
		push_error("Demo seed missing CORE-IMMUNE")
		quit(1)
		return
	var combat_packed := load("res://scenes/combat_lane.tscn") as PackedScene
	if combat_packed == null:
		push_error("combat_lane.tscn missing")
		quit(1)
		return
	var combat := combat_packed.instantiate()
	root.add_child(combat)
	await create_timer(0.2).timeout
	var t_units := 0
	for unit in combat.get_children():
		if str(unit.get("character_id")) == "CHAR-BASE-T":
			t_units += 1
			if unit.get_node_or_null("DutyKits/BaseKit") == null:
				push_error("Combat T-cell missing BaseKit")
				quit(1)
				return
			if unit.get_node_or_null("DutyKits/LocomotionKit") == null:
				push_error("Combat T-cell missing LocomotionKit")
				quit(1)
				return
			if unit.get("duty") != &"fixed":
				push_error("Combat T-cell should start planted")
				quit(1)
				return
	if t_units != 1:
		push_error("Combat lane should instance one CHAR-BASE-T, got %d" % t_units)
		quit(1)
		return
	if combat.get_tree().get_nodes_in_group("immune_core").is_empty():
		push_error("Combat lane missing immune core")
		quit(1)
		return
	quit(0)
