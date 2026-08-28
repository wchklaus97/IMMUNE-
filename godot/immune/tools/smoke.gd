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
		if str(unit.get("family_id")) == "B":
			var b_real_mesh := unit.get_node_or_null("CoreMesh/RealMesh")
			if b_real_mesh == null or unit.get("real_mesh") == null:
				push_error("CHAR-BASE-B must realize its imported Meshy T2 body")
				quit(1)
				return
			var b_face := unit.get_node_or_null("Face") as Node3D
			var b_limbs := unit.get_node_or_null("LimbKit") as Node3D
			if b_face == null or not b_face.visible or b_limbs == null or b_limbs.visible:
				push_error("CHAR-BASE-B must overlay its ink face and replace procedural limbs")
				quit(1)
				return
			var b_mouth := unit.get_node_or_null("Face/Mouth") as Node3D
			if b_mouth == null or not b_mouth.visible or b_mouth.scale.x < 2.0:
				push_error("CHAR-BASE-B must align its readable ink mouth with the sculpted cavity")
				quit(1)
				return
			var b_runtime_gel := _find_wet_gel_material(b_real_mesh)
			if b_runtime_gel == null or b_runtime_gel.get_shader_parameter("bubble_enabled") != true:
				push_error("CHAR-BASE-B imported body must receive its round-bubble runtime profile")
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
		if not _has_wet_gel_mesh(unit):
			push_error("%s missing wet-gel ShaderMaterial" % unit.get("family_id"))
			quit(1)
			return
		var animator := unit.get_node_or_null("AnimationPlayer") as AnimationPlayer
		for animation_name in [&"idle", &"move", &"hit", &"attack"]:
			if animator == null or not animator.has_animation(animation_name):
				push_error("%s missing %s duty animation" % [unit.get("family_id"), animation_name])
				quit(1)
				return
		if unit.has_method("transform_duty"):
			unit.call("transform_duty", &"mobile")
			if str(unit.get("family_id")) == "B":
				var b_base := unit.get_node_or_null("DutyKits/BaseKit") as Node3D
				var b_loco := unit.get_node_or_null("DutyKits/LocomotionKit") as Node3D
				var b_body := unit.get_node_or_null("CoreMesh/RealMesh") as Node3D
				var invalid_b_duty := b_body == null or not b_body.visible
				invalid_b_duty = invalid_b_duty or b_base == null or b_base.visible
				invalid_b_duty = invalid_b_duty or b_loco == null or not b_loco.visible
				if invalid_b_duty:
					push_error("CHAR-BASE-B duty swap must preserve the imported body")
					quit(1)
					return
				if not _all_geometry_shadows_disabled(b_loco):
					push_error("CHAR-BASE-B mobile accessories must not cast oversized world shadows")
					quit(1)
					return
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
	research_state.call("seed_demo")
	if int(catalog.call("node_count")) != 200:
		push_error("Catalog should have 200 nodes, got %d" % int(catalog.call("node_count")))
		quit(1)
		return
	if not bool(research_state.call("is_completed", &"CORE-IMMUNE")):
		push_error("Demo seed missing CORE-IMMUNE")
		quit(1)
		return
	for bus_name in ["Master", "Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			push_error("Missing audio bus %s" % bus_name)
			quit(1)
			return
	for audio_path in [
		"res://audio/music/immune_pulse.ogg",
		"res://audio/sfx/shot.wav",
		"res://audio/sfx/hit.wav",
		"res://audio/sfx/core_hit.wav",
		"res://audio/sfx/phase.wav",
		"res://audio/sfx/duty.wav",
		"res://audio/sfx/victory.wav",
		"res://audio/sfx/defeat.wav",
		"res://audio/sfx/ui.wav",
	]:
		if not ResourceLoader.exists(audio_path):
			push_error("Missing audio asset %s" % audio_path)
			quit(1)
			return
	for family_id in ["T", "B", "M", "N", "A", "D"]:
		var skill_vfx := "res://vfx/skills/SKILL-%s-ACTIVE.tscn" % family_id
		if not ResourceLoader.exists(skill_vfx):
			push_error("Missing family skill VFX %s" % skill_vfx)
			quit(1)
			return
	for action in [
		&"demo_pause", &"demo_confirm", &"demo_back", &"demo_toggle_duty",
		&"demo_research", &"demo_combat", &"demo_next_family", &"demo_prev_family",
		&"demo_move_left", &"demo_move_right", &"demo_move_forward", &"demo_move_back",
	]:
		if not InputMap.has_action(action) or not _has_gamepad_event(action):
			push_error("Input action %s is missing its gamepad mapping" % action)
			quit(1)
			return
	var content := load("res://resources/combat/combat_content.gd")
	var mission_ids: Array[StringName] = content.call("mission_ids")
	if mission_ids.size() != 3:
		push_error("Expected 3 authored missions, got %d" % mission_ids.size())
		quit(1)
		return
	var previous_rank := 0
	var seen_mission_ids: Array[StringName] = []
	for mission_id in mission_ids:
		var mission: ImmuneMissionData = content.call("load_mission", mission_id)
		if mission == null or mission.regular_enemy == null or mission.boss_enemy == null or mission.difficulty == null:
			push_error("Mission %s has incomplete content resources" % mission_id)
			quit(1)
			return
		if seen_mission_ids.has(mission.id) or mission.id != mission_id:
			push_error("Mission ids must be unique and match their lookup key")
			quit(1)
			return
		seen_mission_ids.append(mission.id)
		if mission.difficulty.rank <= previous_rank or not ResourceLoader.exists(mission.scene_path):
			push_error("Mission %s difficulty progression or scene path is invalid" % mission_id)
			quit(1)
			return
		previous_rank = mission.difficulty.rank
	var combat_packed := load("res://scenes/combat_lane.tscn") as PackedScene
	if combat_packed == null:
		push_error("combat_lane.tscn missing")
		quit(1)
		return
	var combat := combat_packed.instantiate()
	combat.set("auto_spawn", false)
	combat.set("persist_rewards", false)
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
	if combat.get("_pause_menu") == null:
		push_error("Combat lane missing reusable pause/settings menu")
		quit(1)
		return
	var gel_material: ShaderMaterial = look.call("gel_material", "T")
	if gel_material == null:
		push_error("T wet-gel material failed to build")
		quit(1)
		return
	if float(gel_material.get_shader_parameter("rim_energy")) > 0.5:
		push_error("Wet-gel rim is above the anti-neon limit")
		quit(1)
		return
	if float(gel_material.get_shader_parameter("coat_strength")) > 1.6:
		push_error("Wet-gel coat is too strong for the soft reference")
		quit(1)
		return
	var dimple_depth := float(gel_material.get_shader_parameter("dimple_depth"))
	if dimple_depth < 0.01 or dimple_depth > 0.03:
		push_error("Wet-gel microtexture must remain subtle and visible")
		quit(1)
		return
	var b_gel_material: ShaderMaterial = look.call("gel_material", "B")
	if b_gel_material == null:
		push_error("B wet-gel material failed to build")
		quit(1)
		return
	if b_gel_material.get_shader_parameter("bubble_enabled") != true:
		push_error("B Jelly V2 profile must enable object-space round bubbles")
		quit(1)
		return
	if float(b_gel_material.get_shader_parameter("dimple_depth")) > 0.001:
		push_error("B Jelly V2 profile must disable directional legacy dimples")
		quit(1)
		return
	if gel_material.get_shader_parameter("bubble_enabled") == true:
		push_error("T Jelly V2 profile must keep its authored membrane microtexture")
		quit(1)
		return
	var b_fallback: ShaderMaterial = look.call("gel_material", "B", {&"bubble_enabled": false})
	if b_fallback == null or b_fallback.get_shader_parameter("bubble_enabled") != false:
		push_error("Jelly V2 call-site fallback must override the B family profile")
		quit(1)
		return
	if look.call("gel_profile_name", "B") != &"round_bubbles":
		push_error("B Jelly V2 profile name is not stable")
		quit(1)
		return
	if not str(combat.call("phase_name")).contains("核心防守"):
		push_error("Combat should start in Core Defense")
		quit(1)
		return
	var antigen_before := int(research_state.get("resources").get("antigen", 0))
	combat.call("debug_advance_phase")
	if not str(combat.call("phase_name")).contains("前線淨化"):
		push_error("Combat did not advance to Expedition")
		quit(1)
		return
	combat.call("debug_advance_phase")
	if not str(combat.call("phase_name")).contains("總力戰"):
		push_error("Combat did not advance to Total War")
		quit(1)
		return
	if combat.get_tree().get_nodes_in_group("boss_pathogen").is_empty():
		push_error("Total War should spawn a boss pathogen")
		quit(1)
		return
	var boss: Node = combat.get_tree().get_first_node_in_group("boss_pathogen")
	var boss_hp := int(boss.get("hp"))
	if boss.get_node_or_null("HealthBar") == null:
		push_error("Boss pathogen missing world health bar")
		quit(1)
		return
	boss.call("take_hit", 1)
	if int(boss.get("hp")) != boss_hp - 1:
		push_error("Boss hit feedback did not update health")
		quit(1)
		return
	combat.call("debug_advance_phase")
	if str(combat.call("phase_name")) != "任務完成":
		push_error("Combat did not reach Victory")
		quit(1)
		return
	if int(research_state.get("resources").get("antigen", 0)) != antigen_before + 40:
		push_error("Victory did not grant the demo antigen reward")
		quit(1)
		return
	if not research_state.get("discovery_flags").has("MISSION-01-COMPLETE"):
		push_error("Victory discovery flag missing")
		quit(1)
		return
	var smoke_save := "user://immune_demo_smoke.json"
	if int(research_state.call("save_game", smoke_save)) != OK:
		push_error("Smoke save write failed")
		quit(1)
		return
	research_state.get("resources")["antigen"] = 1
	if not bool(research_state.call("load_game", smoke_save)):
		push_error("Smoke save load failed")
		quit(1)
		return
	if int(research_state.get("resources").get("antigen", 0)) != antigen_before + 40:
		push_error("Save/load round-trip did not restore rewards")
		quit(1)
		return
	var v1_snapshot: Dictionary = research_state.call("snapshot")
	v1_snapshot["version"] = 1
	v1_snapshot.erase("selectedMissionId")
	v1_snapshot.erase("selectedFamilyId")
	v1_snapshot.erase("completedMissionIds")
	if not bool(research_state.call("apply_snapshot", v1_snapshot, false)):
		push_error("Save v1 -> v2 migration failed")
		quit(1)
		return
	if research_state.get("selected_mission_id") != &"MISSION-01" or research_state.get("selected_family_id") != &"T":
		push_error("Migrated save did not receive safe mission/family defaults")
		quit(1)
		return
	if int(research_state.call("snapshot").get("version", 0)) != 2:
		push_error("Migrated snapshot did not serialize as v2")
		quit(1)
		return
	combat.queue_free()
	await process_frame
	var family_ids: PackedStringArray = ["T", "B", "M", "N", "A", "D"]
	for i in family_ids.size():
		var mission: ImmuneMissionData = content.call("load_mission", mission_ids[i % mission_ids.size()])
		research_state.set("selected_mission_id", mission.id)
		research_state.set("selected_family_id", StringName(family_ids[i]))
		var mission_scene := load(mission.scene_path) as PackedScene
		if mission_scene == null:
			push_error("Mission scene failed to load: %s" % mission.scene_path)
			quit(1)
			return
		var mission_runtime := mission_scene.instantiate()
		mission_runtime.set("auto_spawn", false)
		mission_runtime.set("persist_rewards", false)
		mission_runtime.set("show_onboarding", false)
		root.add_child(mission_runtime)
		await create_timer(0.08).timeout
		if mission_runtime.call("mission_id") != mission.id or mission_runtime.call("player_family") != StringName(family_ids[i]):
			push_error("Mission/family runtime selection mismatch for %s/%s" % [mission.id, family_ids[i]])
			quit(1)
			return
		mission_runtime.call("debug_spawn_regular")
		await process_frame
		var spawned_enemy: Node = null
		for candidate in get_nodes_in_group("bacterium"):
			if mission_runtime.is_ancestor_of(candidate):
				spawned_enemy = candidate
				break
		if spawned_enemy == null:
			push_error("Mission %s failed to spawn its regular pathogen" % mission.id)
			quit(1)
			return
		var expected_hp := maxi(int(round(float(mission.regular_enemy.max_health) * mission.difficulty.health_multiplier)), 1)
		if int(spawned_enemy.get("max_hp")) != expected_hp:
			push_error("Mission %s difficulty health scaling mismatch" % mission.id)
			quit(1)
			return
		mission_runtime.queue_free()
		await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(smoke_save))
	research_state.call("seed_demo")
	print("SMOKE_OK missions=3 families=6 save=v2 audio=ready gamepad=ready")
	var audio_director := root.get_node_or_null("AudioDirector")
	if audio_director != null:
		audio_director.call("stop_all")
	for child in root.get_children():
		if child.name not in [&"Catalog", &"ResearchState", &"SettingsState", &"AudioDirector", &"VfxLibrary"]:
			child.queue_free()
	call_deferred("_finish_success")


func _finish_success() -> void:
	await process_frame
	await process_frame
	quit(0)


func _has_gamepad_event(action: StringName) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


func _has_wet_gel_mesh(node: Node) -> bool:
	return _find_wet_gel_material(node) != null


func _all_geometry_shadows_disabled(node: Node) -> bool:
	if node is GeometryInstance3D:
		var geometry := node as GeometryInstance3D
		if geometry.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			return false
	for child in node.get_children():
		if not _all_geometry_shadows_disabled(child):
			return false
	return true


func _find_wet_gel_material(node: Node) -> ShaderMaterial:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var materials: Array[Material] = []
		if mesh_instance.material_override != null:
			materials.append(mesh_instance.material_override)
		if mesh_instance.mesh != null:
			for surface in mesh_instance.mesh.get_surface_count():
				var override := mesh_instance.get_surface_override_material(surface)
				if override != null:
					materials.append(override)
				var source := mesh_instance.mesh.surface_get_material(surface)
				if source != null:
					materials.append(source)
		for material in materials:
			if material is ShaderMaterial:
				var shader := (material as ShaderMaterial).shader
				if shader != null and shader.resource_path.ends_with("wet_gel.gdshader"):
					return material as ShaderMaterial
	for child in node.get_children():
		var found := _find_wet_gel_material(child)
		if found != null:
			return found
	return null
