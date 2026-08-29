extends SceneTree

## Headless check: six base scenes load and A has no walk kit.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not TranslationServer.get_loaded_locales().has("en") or not TranslationServer.get_loaded_locales().has("zh_HK"):
		push_error("Expected English and zh_HK translations to be registered")
		quit(1)
		return
	TranslationServer.set_locale("en")
	if TranslationServer.translate(&"UI_PAUSE_TITLE") != "Pause / Settings":
		push_error("English translation contract is not active")
		quit(1)
		return
	if TranslationServer.translate(&"UI_MISSION_SUBTITLE") != "Choose a mission, then deploy the cell family best suited to the threat.":
		push_error("English mission-desk copy is truncated or stale")
		quit(1)
		return
	TranslationServer.set_locale("zh_HK")
	if TranslationServer.translate(&"UI_PAUSE_TITLE") != "暫停／設定":
		push_error("zh_HK translation contract is not active")
		quit(1)
		return
	var catalog_contract := root.get_node_or_null("Catalog")
	if catalog_contract == null or int(catalog_contract.call("node_count")) != 200:
		push_error("Catalog localization contract requires all 200 nodes")
		quit(1)
		return
	TranslationServer.set_locale("en")
	var localized_fields := 0
	for node in catalog_contract.call("all_nodes"):
		if not node is Dictionary:
			push_error("Catalog localization encountered a non-dictionary node")
			quit(1)
			return
		for field in ["name", "description"]:
			var key: StringName = catalog_contract.call("node_text_key", StringName(str(node.get("id", ""))), field)
			var translated := TranslationServer.translate(key)
			if translated.is_empty() or translated == String(key):
				push_error("Missing English catalog translation %s" % String(key))
				quit(1)
				return
			localized_fields += 1
		if str(catalog_contract.call("localized_node_name", node)) != TranslationServer.translate(catalog_contract.call("node_text_key", StringName(str(node.get("id", ""))), "name")):
			push_error("Catalog localized name accessor drifted for %s" % str(node.get("id", "")))
			quit(1)
			return
	for chapter in ["L01", "L02", "L03", "L04", "L05", "L06"]:
		var campaign_key := StringName("RESEARCH_CAMPAIGN_%s_NAME" % chapter)
		if TranslationServer.translate(campaign_key) == String(campaign_key):
			push_error("Missing campaign catalog translation %s" % chapter)
			quit(1)
			return
	if localized_fields != 400 or str(catalog_contract.call("localized_campaign_level_name", "L01")) != "Mucosal Entry":
		push_error("Catalog localization coverage is incomplete")
		quit(1)
		return
	TranslationServer.set_locale("zh_HK")
	var core_node: Dictionary = catalog_contract.call("get_node_def", &"CORE-IMMUNE")
	if str(catalog_contract.call("localized_node_name", core_node)) != "免疫核心":
		push_error("zh_HK catalog localization did not restore the source name")
		quit(1)
		return
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
		if str(unit.get("family_id")) == "T":
			var t_runtime_gel := _find_wet_gel_material(unit)
			if t_runtime_gel == null or t_runtime_gel.get_shader_parameter("bubble_enabled") != true:
				push_error("CHAR-BASE-T runtime body must receive its Fizzy bubble profile")
				quit(1)
				return
			if t_runtime_gel.get_shader_parameter("microbubble_enabled") != true or t_runtime_gel.get_shader_parameter("inclusion_enabled") != true:
				push_error("CHAR-BASE-T Fizzy runtime profile must keep microbubbles and inclusions")
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
			if b_runtime_gel.get_shader_parameter("microbubble_enabled") != true or b_runtime_gel.get_shader_parameter("inclusion_enabled") != true:
				push_error("CHAR-BASE-B Fizzy runtime profile must keep microbubbles and inclusions")
				quit(1)
				return
		elif str(unit.get("family_id")) == "M":
			var m_real_mesh := unit.get_node_or_null("CoreMesh/RealMesh")
			if m_real_mesh == null or unit.get("real_mesh") == null:
				push_error("CHAR-BASE-M must realize its accepted reference body")
				quit(1)
				return
			var m_face := unit.get_node_or_null("Face") as Node3D
			var m_limbs := unit.get_node_or_null("LimbKit") as Node3D
			if m_face == null or m_face.visible:
				push_error("CHAR-BASE-M accepted body must replace the procedural face")
				quit(1)
				return
			if m_limbs == null or m_limbs.visible:
				push_error("CHAR-BASE-M accepted body must replace procedural base limbs")
				quit(1)
				return
			if unit.get_node_or_null("WeaponSocket").get_child_count() != 0:
				push_error("CHAR-BASE-M accepted body must replace procedural identity props")
				quit(1)
				return
			if unit.get_node_or_null("CoreMesh/Bubble0") != null:
				push_error("CHAR-BASE-M accepted body must replace procedural bubble geometry")
				quit(1)
				return
			var m_base := unit.get_node_or_null("DutyKits/BaseKit") as Node3D
			if m_base == null or m_base.get_child_count() != 0:
				push_error("CHAR-BASE-M fused feet must replace the procedural fixed kit")
				quit(1)
				return
			var m_body := m_real_mesh.get_node_or_null("Body") as MeshInstance3D
			var m_shell := m_real_mesh.get_node_or_null("BodyShell") as MeshInstance3D
			if m_body == null or m_shell == null:
				push_error("CHAR-BASE-M accepted body must expose Body and BodyShell")
				quit(1)
				return
			for authored_path in ["EyeL", "EyeR", "MouthCavity"]:
				if m_real_mesh.get_node_or_null(authored_path) == null:
					push_error("CHAR-BASE-M accepted body missing %s" % authored_path)
					quit(1)
					return
			var m_runtime_gel := m_body.material_override as ShaderMaterial
			if m_runtime_gel == null or m_runtime_gel.get_shader_parameter("bubble_enabled") != true:
				push_error("CHAR-BASE-M accepted body must keep its authored bubble material")
				quit(1)
				return
			if m_runtime_gel.get_shader_parameter("microbubble_enabled") != true or m_runtime_gel.get_shader_parameter("inclusion_enabled") != true:
				push_error("CHAR-BASE-M fizzy profile must keep microbubbles and fine inclusions")
				quit(1)
				return
			var m_noise_error := _gel_surface_noise_error(m_runtime_gel)
			if not m_noise_error.is_empty():
				push_error("CHAR-BASE-M %s" % m_noise_error)
				quit(1)
				return
			var m_shell_material := m_shell.material_override as ShaderMaterial
			if m_shell_material == null or m_shell_material.shader == null or not m_shell_material.shader.resource_path.ends_with("jelly_shell.gdshader"):
				push_error("CHAR-BASE-M accepted body must keep its authored clear membrane")
				quit(1)
				return
			if not bool(unit.get("imported_preserves_materials")) or str(unit.get("imported_model_path")) != "res://characters/base_m/reference_body.tscn":
				push_error("CHAR-BASE-M scene must lock the accepted fizzy production adapter")
				quit(1)
				return
		elif str(unit.get("family_id")) in ["N", "A", "D"]:
			var authored_error := _authored_jelly_error(unit, str(unit.get("family_id")))
			if not authored_error.is_empty():
				push_error(authored_error)
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
			var duty_burst := unit.get_node_or_null("KitSwapBurst") as GPUParticles3D
			if duty_burst != null and duty_burst.draw_pass_1 == null and duty_burst.emitting:
				push_error("%s must not submit its unconfigured duty particle placeholder" % unit.get("family_id"))
				quit(1)
				return
			if duty_burst != null and duty_burst.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				push_error("%s duty particle placeholder must not cast world shadows" % unit.get("family_id"))
				quit(1)
				return
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
			elif str(unit.get("family_id")) == "M":
				var m_base := unit.get_node_or_null("DutyKits/BaseKit") as Node3D
				var m_loco := unit.get_node_or_null("DutyKits/LocomotionKit") as Node3D
				var m_body := unit.get_node_or_null("CoreMesh/RealMesh") as Node3D
				var invalid_m_duty := m_body == null or not m_body.visible
				invalid_m_duty = invalid_m_duty or m_base == null or m_base.visible
				invalid_m_duty = invalid_m_duty or m_loco == null or not m_loco.visible
				if invalid_m_duty:
					push_error("CHAR-BASE-M duty swap must preserve the accepted body")
					quit(1)
					return
				if not _all_geometry_shadows_disabled(m_loco):
					push_error("CHAR-BASE-M mobile accessories must not cast oversized world shadows")
					quit(1)
					return
			elif str(unit.get("family_id")) in ["N", "D"]:
				var authored_base := unit.get_node_or_null("DutyKits/BaseKit") as Node3D
				var authored_loco := unit.get_node_or_null("DutyKits/LocomotionKit") as Node3D
				var authored_body := unit.get_node_or_null("CoreMesh/RealMesh") as Node3D
				var invalid_authored_duty := authored_body == null or not authored_body.visible
				invalid_authored_duty = invalid_authored_duty or authored_base == null or authored_base.visible
				invalid_authored_duty = invalid_authored_duty or authored_loco == null or not authored_loco.visible
				if invalid_authored_duty:
					push_error("CHAR-BASE-%s duty swap must preserve its authored body" % unit.get("family_id"))
					quit(1)
					return
				if not _all_geometry_shadows_disabled(authored_loco):
					push_error("CHAR-BASE-%s mobile accessories must not cast oversized world shadows" % unit.get("family_id"))
					quit(1)
					return
			elif str(unit.get("family_id")) == "A":
				var a_base := unit.get_node_or_null("DutyKits/BaseKit") as Node3D
				var a_relay := unit.get_node_or_null("DutyKits/RelayDish") as Node3D
				var a_body := unit.get_node_or_null("CoreMesh/RealMesh") as Node3D
				var invalid_a_duty := a_body == null or not a_body.visible
				invalid_a_duty = invalid_a_duty or a_base == null or a_base.visible
				invalid_a_duty = invalid_a_duty or a_relay == null or not a_relay.visible
				if invalid_a_duty or unit.get("duty") != &"relay":
					push_error("CHAR-BASE-A mobile request must preserve its authored body and open RelayDish")
					quit(1)
					return
				if not _all_geometry_shadows_disabled(a_relay):
					push_error("CHAR-BASE-A RelayDish must not cast oversized world shadows")
					quit(1)
					return
				var a_relay_ring := a_relay.get_node_or_null("RelayRing") as MeshInstance3D
				var a_relay_material := a_relay_ring.material_override as StandardMaterial3D if a_relay_ring != null else null
				if a_relay_material == null or a_relay_material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					push_error("CHAR-BASE-A RelayRing must use the Compatibility-safe relay material")
					quit(1)
					return
	var research := load("res://ui/research/research_network.tscn") as PackedScene
	if research == null:
		push_error("research_network.tscn missing")
		quit(1)
		return
	var research_instance := research.instantiate() as Control
	root.add_child(research_instance)
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
	research_state.call("select_node", &"CORE-IMMUNE")
	await process_frame
	TranslationServer.set_locale("en")
	research_instance.call("_on_settings_changed")
	await process_frame
	await process_frame
	var detail_title := research_instance.get("_detail_title") as Label
	var campaign_chip := research_instance.get("_campaign_chip") as Label
	if detail_title == null or detail_title.text != "Immune Core":
		push_error("Live locale switch did not refresh the selected research node")
		quit(1)
		return
	if campaign_chip == null or not campaign_chip.text.contains("Mission L02") or not campaign_chip.text.contains("Bloodstream Corridor"):
		push_error("Live locale switch did not refresh research campaign metadata")
		quit(1)
		return
	TranslationServer.set_locale("zh_HK")
	research_instance.call("_on_settings_changed")
	await process_frame
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
	var projectile_script := load("res://combat/plasma_bolt.gd")
	var pathogen_script := load("res://combat/bacterium.gd")
	var projectile: Area3D = projectile_script.new()
	var projectile_target: CharacterBody3D = pathogen_script.new()
	projectile.call("configure", 2, Color.WHITE)
	projectile_target.call("configure", 5, 1.0)
	root.add_child(projectile_target)
	await process_frame
	var first_projectile_hit := bool(projectile.call("try_apply_hit", projectile_target))
	var duplicate_projectile_hit := bool(projectile.call("try_apply_hit", projectile_target))
	if not first_projectile_hit or duplicate_projectile_hit or int(projectile_target.get("hp")) != 3:
		push_error("A plasma bolt must damage at most one pathogen once")
		quit(1)
		return
	projectile.free()
	projectile_target.queue_free()
	await process_frame
	var t_target: CharacterBody3D = pathogen_script.new()
	t_target.call("configure", 10, 2.0)
	root.add_child(t_target)
	await process_frame
	t_target.call("take_hit", 7)
	var t_damage := int(t_target.call("take_profiled_hit", 2, &"T", &"execute", 2, 0, 0.3))
	if t_damage != 4:
		push_error("T execution must add exactly two damage at 30% HP")
		quit(1)
		return
	var b_target: CharacterBody3D = pathogen_script.new()
	b_target.call("configure", 20, 2.0)
	root.add_child(b_target)
	await process_frame
	var b_hits := [
		int(b_target.call("take_profiled_hit", 4, &"B", &"antibody_mark", 1, 2, 0.0)),
		int(b_target.call("take_profiled_hit", 4, &"B", &"antibody_mark", 1, 2, 0.0)),
		int(b_target.call("take_profiled_hit", 4, &"B", &"antibody_mark", 1, 2, 0.0)),
	]
	if b_hits != [4, 5, 6] or int(b_target.call("antibody_marks")) != 2:
		push_error("B antibody marks must scale 4/5/6 and cap at two")
		quit(1)
		return
	var trait_target: CharacterBody3D = pathogen_script.new()
	trait_target.call("configure", 10, 2.0)
	trait_target.set("enrage_health_threshold", 0.5)
	trait_target.set("enrage_speed_multiplier", 1.5)
	trait_target.set("regeneration_per_second", 60.0)
	trait_target.set("regeneration_delay", 0.0)
	root.add_child(trait_target)
	await process_frame
	trait_target.call("take_hit", 6)
	if not is_equal_approx(float(trait_target.call("current_move_speed")), 3.0):
		push_error("Low-health pathogen enrage speed is invalid")
		quit(1)
		return
	var trait_hp_before := int(trait_target.get("hp"))
	await physics_frame
	await physics_frame
	if int(trait_target.get("hp")) <= trait_hp_before:
		push_error("Pathogen regeneration did not resume after its delay")
		quit(1)
		return
	if is_instance_valid(t_target):
		t_target.queue_free()
	b_target.queue_free()
	trait_target.queue_free()
	await process_frame
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
	if mission_ids.size() != 6:
		push_error("Expected 6 authored missions, got %d" % mission_ids.size())
		quit(1)
		return
	var previous_rank := 0
	var previous_mission_id: StringName = &""
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
		if mission.required_mission_id != previous_mission_id:
			push_error("Mission %s prerequisite chain is invalid" % mission_id)
			quit(1)
			return
		previous_rank = mission.difficulty.rank
		previous_mission_id = mission.id
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
	var combat_camera := combat.get("_camera") as Camera3D
	if combat_camera == null or combat_camera.fov < 45.0 or combat_camera.fov > 60.0:
		push_error("Combat camera must preserve the player-readable 45-60 degree framing")
		quit(1)
		return
	var arena_visuals := combat.get_node_or_null("ArenaVisuals") as Node3D
	if arena_visuals == null or arena_visuals.get_child_count() < 18:
		push_error("Combat lane missing the biological arena presentation layer")
		quit(1)
		return
	for visual in arena_visuals.get_children():
		if visual is CollisionObject3D or visual is CollisionShape3D:
			push_error("ArenaVisuals must remain presentation-only and collision-free")
			quit(1)
			return
		if visual is not MeshInstance3D:
			push_error("ArenaVisuals may only contain lightweight mesh instances")
			quit(1)
			return
	var cleanse_visuals := combat.get_node_or_null("CleanseVisuals") as Node3D
	if cleanse_visuals == null or cleanse_visuals.get_child_count() != 10:
		push_error("Cleanse zone must retain two rings and eight signal markers")
		quit(1)
		return
	for property in ["_duty_button", "_intel_button", "_back_button"]:
		var action_button := combat.get(property) as Button
		if action_button == null or not action_button.visible:
			push_error("Combat HUD action button %s is missing or hidden" % property)
			quit(1)
			return
		if action_button.size.x < 210.0 or action_button.size.y < 48.0:
			push_error("Combat HUD action button %s is below its readable hit target" % property)
			quit(1)
			return
		if action_button.get_theme_stylebox("normal") == null:
			push_error("Combat HUD action button %s is missing its authored style" % property)
			quit(1)
			return
		var action_rect := action_button.get_global_rect()
		var viewport_rect := combat.get_viewport().get_visible_rect()
		if action_rect.position.y < viewport_rect.size.y * 0.82 or action_rect.end.y > viewport_rect.end.y + 1.0:
			push_error("Combat HUD action button %s escaped the bottom action tray" % property)
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
	if not is_zero_approx(float(gel_material.get_shader_parameter("dimple_depth"))):
		push_error("T Fizzy profile must disable directional legacy dimples")
		quit(1)
		return
	if gel_material.get_shader_parameter("bubble_enabled") != true or gel_material.get_shader_parameter("microbubble_enabled") != true or gel_material.get_shader_parameter("inclusion_enabled") != true:
		push_error("T Fizzy profile must enable bubbles, microbubbles, and fine inclusions")
		quit(1)
		return
	var t_membrane_error := _gel_membrane_error(gel_material)
	if not t_membrane_error.is_empty():
		push_error("T Fizzy profile %s" % t_membrane_error)
		quit(1)
		return
	var t_noise_error := _gel_surface_noise_error(gel_material)
	if not t_noise_error.is_empty():
		push_error("T Fizzy profile %s" % t_noise_error)
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
	if b_gel_material.get_shader_parameter("microbubble_enabled") != true or b_gel_material.get_shader_parameter("inclusion_enabled") != true:
		push_error("B Fizzy profile must enable microbubbles and fine inclusions")
		quit(1)
		return
	var b_membrane_error := _gel_membrane_error(b_gel_material)
	if not b_membrane_error.is_empty():
		push_error("B Fizzy profile %s" % b_membrane_error)
		quit(1)
		return
	var b_noise_error := _gel_surface_noise_error(b_gel_material)
	if not b_noise_error.is_empty():
		push_error("B Fizzy profile %s" % b_noise_error)
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
	var m_gel_material: ShaderMaterial = look.call("gel_material", "M")
	if m_gel_material == null:
		push_error("M wet-gel material failed to build")
		quit(1)
		return
	if m_gel_material.get_shader_parameter("bubble_enabled") != true:
		push_error("M Jelly V2 profile must enable object-space round bubbles")
		quit(1)
		return
	if not is_zero_approx(float(m_gel_material.get_shader_parameter("dimple_depth"))):
		push_error("M Jelly V2 profile must disable directional legacy dimples")
		quit(1)
		return
	if look.call("gel_profile_name", "M") != &"macrophage_bubbles":
		push_error("M Jelly V2 profile name is not stable")
		quit(1)
		return
	var telemetry_script := load("res://combat/combat_playtest_telemetry.gd")
	var telemetry: CombatPlaytestTelemetry = telemetry_script.new()
	telemetry.begin(&"MISSION-TEST", &"T", "smoke")
	telemetry.record_core_hp(12, 12)
	telemetry.enter_phase("core")
	telemetry.tick(0.5, &"fixed")
	telemetry.record_shot()
	telemetry.record_hit(2, false)
	telemetry.enter_phase("expedition")
	telemetry.record_duty_switch()
	telemetry.tick(0.25, &"mobile")
	# Advance zero-delta frames to the steady-state sampling boundary without
	# changing the phase/duty timing assertions below.
	for _frame in 118:
		telemetry.tick(0.0, &"mobile")
	telemetry.sample_performance_now()
	telemetry.finish(true)
	var telemetry_snapshot: Dictionary = telemetry.snapshot()
	if int(telemetry_snapshot.get("schema_version", 0)) != 2:
		push_error("Playtest telemetry must expose the v2 performance contract")
		quit(1)
		return
	if not bool(telemetry_snapshot.get("victory", false)):
		push_error("Playtest telemetry must preserve the victory result")
		quit(1)
		return
	if int(telemetry_snapshot.get("shots_fired", 0)) != 1 or int(telemetry_snapshot.get("shots_hit", 0)) != 1:
		push_error("Playtest telemetry shot contract is invalid")
		quit(1)
		return
	if float(telemetry_snapshot.get("phase_durations", {}).get("core", 0.0)) != 0.5:
		push_error("Playtest telemetry phase timing contract is invalid")
		quit(1)
		return
	if int(telemetry_snapshot.get("core_hp", 0)) != 12:
		push_error("Playtest telemetry must preserve initial core HP")
		quit(1)
		return
	var telemetry_performance := telemetry_snapshot.get("performance", {}) as Dictionary
	if int(telemetry_performance.get("startup", {}).get("sample_count", 0)) < 1:
		push_error("Playtest telemetry must preserve cold-start performance samples")
		quit(1)
		return
	if int(telemetry_performance.get("sample_count", 0)) < 1:
		push_error("Playtest telemetry must collect at least one opt-in performance sample")
		quit(1)
		return
	for metric in [
		"p05_fps",
		"mean_process_ms",
		"max_process_ms",
		"mean_physics_process_ms",
		"max_physics_process_ms",
		"max_draw_calls",
		"max_render_objects",
		"max_static_memory_mb",
		"max_object_count",
	]:
		if not telemetry_performance.has(metric) or float(telemetry_performance[metric]) < 0.0:
			push_error("Playtest telemetry performance metric is missing or invalid: %s" % metric)
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
		if spawned_enemy.scale != Vector3.ONE:
			push_error("Mission %s pathogen physics body must not use root scaling" % mission.id)
			quit(1)
			return
		var mission_core: Node3D = null
		for candidate in get_nodes_in_group("immune_core"):
			if mission_runtime.is_ancestor_of(candidate):
				mission_core = candidate as Node3D
				break
		if mission_core == null:
			push_error("Mission %s missing runtime core for contact regression" % mission.id)
			quit(1)
			return
		var core_hp_before := int(mission_core.get("hp"))
		var contact_distance := float(spawned_enemy.call("core_contact_distance"))
		spawned_enemy.global_position = mission_core.global_position + Vector3(0.0, 0.0, contact_distance - 0.01)
		spawned_enemy.reset_physics_interpolation()
		await physics_frame
		await physics_frame
		if int(mission_core.get("hp")) >= core_hp_before:
			push_error("Mission %s pathogen contact must damage the core without collision deadlock" % mission.id)
			quit(1)
			return
		mission_runtime.queue_free()
		await process_frame
	TranslationServer.set_locale("en")
	var mission_desk_packed := load("res://ui/mission_select/mission_select.tscn") as PackedScene
	if mission_desk_packed == null:
		push_error("Mission desk scene failed to load")
		quit(1)
		return
	var mission_desk := mission_desk_packed.instantiate()
	root.add_child(mission_desk)
	await process_frame
	await process_frame
	var preview_stage := mission_desk.get("_preview_stage") as Node3D
	var preview_viewport := mission_desk.get("_preview_viewport") as SubViewport
	if preview_stage == null or preview_viewport == null or not preview_viewport.own_world_3d:
		push_error("Mission desk must confine the cell preview to its own SubViewport")
		quit(1)
		return
	var preview_camera := preview_stage.get_node_or_null("CellPreviewCamera") as Camera3D
	if preview_camera == null or preview_camera.fov > 30.0 or preview_camera.position.z > 3.8:
		push_error("Mission desk must use the close hero-preview camera")
		quit(1)
		return
	var preview_key := preview_stage.get_node_or_null("CellPreviewKey") as DirectionalLight3D
	if preview_key == null or preview_key.light_color.g < 0.90 or preview_key.light_color.b < 0.84:
		push_error("Mission desk must use a near-neutral preview key so family gel colours stay truthful")
		quit(1)
		return
	var mission_buttons: Array = mission_desk.get("_mission_buttons")
	var desk_family_buttons: Array = mission_desk.get("_family_buttons")
	if mission_buttons.size() != 6 or desk_family_buttons.size() != 6:
		push_error("Mission desk must expose six mission and six family buttons")
		quit(1)
		return
	for button in mission_buttons + desk_family_buttons:
		if button is not Button or not (button as Button).toggle_mode:
			push_error("Mission desk selection buttons must retain a visible pressed state")
			quit(1)
			return
	for i in family_ids.size():
		mission_desk.call("_select_family", i)
		await process_frame
		var preview := mission_desk.get("_preview") as Node3D
		var expected_duty: StringName = &"relay" if family_ids[i] == "A" else &"mobile"
		if preview == null or preview.get_parent() != preview_stage:
			push_error("Mission desk preview escaped its frame for family %s" % family_ids[i])
			quit(1)
			return
		if StringName(preview.get("family_id")) != StringName(family_ids[i]) or StringName(preview.get("duty")) != expected_duty:
			push_error("Mission desk preview state mismatch for family %s" % family_ids[i])
			quit(1)
			return
	mission_desk.queue_free()
	await process_frame
	TranslationServer.set_locale("zh_HK")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(smoke_save))
	research_state.call("seed_demo")
	print("SMOKE_OK missions=6 families=6 save=v2 audio=ready gamepad=ready signatures=T+B traits=enrage+regen meshy=B authored_jelly=M+N+A+D gel_fizzy=T+B+M+N+A+D")
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


func _gel_membrane_error(gel: ShaderMaterial) -> String:
	var membrane := gel.next_pass as ShaderMaterial
	if membrane == null or membrane.shader == null:
		return "must attach a clear membrane next pass"
	if not membrane.shader.resource_path.ends_with("jelly_shell.gdshader"):
		return "must use the Compatibility-safe clear membrane shader"
	if float(membrane.get_shader_parameter("shell_thickness")) <= 0.0:
		return "membrane must expand beyond the wet-gel core"
	if float(membrane.get_shader_parameter("face_alpha")) > 0.03:
		return "membrane face alpha must not wash out the gel core"
	return ""


func _gel_surface_noise_error(gel: ShaderMaterial) -> String:
	var inclusion_depth := float(gel.get_shader_parameter("inclusion_depth"))
	if inclusion_depth <= 0.0:
		return "must keep a subtle smooth 3D wet-skin microtexture"
	if inclusion_depth > 0.02:
		return "wet-skin microtexture exceeds the anti-rubber depth limit"
	var membrane_cell_depth := float(gel.get_shader_parameter("microbubble_depth"))
	if membrane_cell_depth < 0.003 or membrane_cell_depth > 0.012:
		return "rounded membrane-cell depth is outside the stable wet-skin range"
	var membrane_cell_radius := float(gel.get_shader_parameter("microbubble_radius_max"))
	var membrane_cell_jitter := float(gel.get_shader_parameter("microbubble_jitter"))
	if membrane_cell_radius < 0.50 or membrane_cell_radius + membrane_cell_jitter >= 1.0:
		return "rounded membrane cells must overlap without leaving the eight-sample lattice bound"
	if float(gel.get_shader_parameter("microbubble_thinness")) > 0.02:
		return "rounded membrane cells must shape highlights rather than paint thickness spots"
	if float(gel.get_shader_parameter("bubble_shell_emission")) > 0.12:
		return "large-bubble rings exceed the quiet interior limit"
	if float(gel.get_shader_parameter("microbubble_shell_emission")) > 0.08:
		return "microbubble rings exceed the quiet interior limit"
	if float(gel.get_shader_parameter("inclusion_emission")) > 0.06:
		return "fine inclusions exceed the quiet interior limit"
	return ""


func _authored_jelly_error(unit: Node, family: String) -> String:
	var real_mesh := unit.get_node_or_null("CoreMesh/RealMesh") as Node3D
	if real_mesh == null or unit.get("real_mesh") == null:
		return "CHAR-BASE-%s must realize its zero-credit authored jelly body" % family
	var face := unit.get_node_or_null("Face") as Node3D
	var limbs := unit.get_node_or_null("LimbKit") as Node3D
	if face == null or face.visible or limbs == null or limbs.visible:
		return "CHAR-BASE-%s authored body must replace the procedural face and limbs" % family
	if unit.get_node_or_null("WeaponSocket").get_child_count() != 0:
		return "CHAR-BASE-%s authored body must replace procedural identity props" % family
	if unit.get_node_or_null("CoreMesh/Bubble0") != null:
		return "CHAR-BASE-%s authored body must replace procedural bubble geometry" % family
	var base := unit.get_node_or_null("DutyKits/BaseKit") as Node3D
	if base == null or base.get_child_count() != 0:
		return "CHAR-BASE-%s authored body must replace the procedural fixed kit" % family
	var body := real_mesh.get_node_or_null("Body") as MeshInstance3D
	var shell := real_mesh.get_node_or_null("BodyShell") as MeshInstance3D
	if body == null or shell == null:
		return "CHAR-BASE-%s authored body must expose Body and BodyShell" % family
	for authored_path in ["EyeL", "EyeR", "MouthCavity"]:
		if real_mesh.get_node_or_null(authored_path) == null:
			return "CHAR-BASE-%s authored body missing %s" % [family, authored_path]
	var runtime_gel := body.material_override as ShaderMaterial
	if runtime_gel == null or runtime_gel.get_shader_parameter("bubble_enabled") != true:
		return "CHAR-BASE-%s authored body must keep its Fizzy bubble material" % family
	if runtime_gel.get_shader_parameter("microbubble_enabled") != true or runtime_gel.get_shader_parameter("inclusion_enabled") != true:
		return "CHAR-BASE-%s authored Fizzy profile must keep microbubbles and inclusions" % family
	var noise_error := _gel_surface_noise_error(runtime_gel)
	if not noise_error.is_empty():
		return "CHAR-BASE-%s %s" % [family, noise_error]
	var shell_material := shell.material_override as ShaderMaterial
	if shell_material == null or shell_material.shader == null or not shell_material.shader.resource_path.ends_with("jelly_shell.gdshader"):
		return "CHAR-BASE-%s authored body must keep its clear membrane" % family
	var expected_path := "res://characters/base_%s/reference_body.tscn" % family.to_lower()
	if not bool(unit.get("imported_preserves_materials")) or str(unit.get("imported_model_path")) != expected_path:
		return "CHAR-BASE-%s scene must lock its authored production adapter" % family
	for replacement_flag in ["imported_replaces_limbs", "imported_replaces_identity", "imported_replaces_bubbles", "imported_replaces_fixed_kit"]:
		if not bool(unit.get(replacement_flag)):
			return "CHAR-BASE-%s production adapter must lock %s" % [family, replacement_flag]
	if not _all_geometry_shadows_disabled(real_mesh):
		return "CHAR-BASE-%s authored body must not cast internal primitive shadows" % family
	if family == "A":
		if real_mesh.get_node_or_null("FootL") != null or real_mesh.get_node_or_null("FootR") != null:
			return "CHAR-BASE-A authored body must preserve its footless hover silhouette"
	else:
		if real_mesh.get_node_or_null("FootL") == null or real_mesh.get_node_or_null("FootR") == null:
			return "CHAR-BASE-%s authored body must preserve its grounded feet" % family
	if family == "N" and real_mesh.get_node_or_null("MouthRim") == null:
		return "CHAR-BASE-N authored body must preserve its short pill mouth"
	if family == "D":
		for crown_index in 5:
			if real_mesh.get_node_or_null("Crown%d" % crown_index) == null:
				return "CHAR-BASE-D authored body must preserve all five crown lobes"
	return ""


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
