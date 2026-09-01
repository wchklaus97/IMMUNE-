extends SceneTree

## Headless check: six base scenes load and A has no walk kit.

const _LightContract := preload("res://characters/gel/light_contract.gd")
const _GelProfiles := preload("res://characters/gel/gel_profiles.gd")
const JELLY_DIRECT_LIGHT_LIMIT := 3
const JELLY_SHADOWED_DIRECT_LIGHT_LIMIT := 1
const JELLY_DIRECT_LIGHT_RIG_SOURCES := [
	"res://tools/shot.gd",
	"res://tools/gel_perf.gd",
	"res://tools/crit4_probe.gd",
]
const JELLY_PROBE_ALLOWED_ARGS: Array[String] = [
	"jelly-light-probe", "out", "share", "save-path",
]
const REGULAR_SMOKE_ALLOWED_ARGS: Array[String] = ["save-path"]
const JELLY_PROBE_SHARE_MIN := 0.09
const JELLY_PROBE_SHARE_MAX := 0.105
const QA_STARTUP_FAILURE_EXIT_CODE := 74
const GEL_LEGACY_ANIMATIONS: PackedStringArray = [
	"idle", "plant", "uproot", "move", "hit", "attack", "relay_open", "relay_close",
]
const GEL_V8_1_ANIMATIONS: PackedStringArray = [
	"move_start", "move_stop", "relay_glide", "skill_cast",
]
const GEL_V8_1_BASIC_RELEASE_TIME := 0.345
const GEL_V8_1_ACTIVE_RELEASE_TIME := 0.48

var _jelly_probe_args := {}
var _v8_1_release_events: Array[Dictionary] = []
var _v8_1_cancel_events: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# A SceneTree main script can receive its first deferred callback before
	# project autoloads have completed _ready().  Give ResearchState exactly one
	# frame to publish a startup-fatal result before this harness does any work.
	await process_frame
	if _abort_for_qa_startup_failure():
		return
	if _jelly_probe_requested():
		if not _parse_jelly_probe_args():
			quit(2)
			return
		await _run_jelly_light_probe()
		return
	if not _parse_regular_smoke_args():
		quit(2)
		return
	var jelly_rig_error := _jelly_direct_light_rig_error()
	if not jelly_rig_error.is_empty():
		push_error(jelly_rig_error)
		quit(1)
		return
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
	var kit_preview := packed.instantiate()
	root.add_child(kit_preview)
	await create_timer(0.15).timeout
	var kit_light_error := _jelly_runtime_light_error("kit preview", root)
	if not kit_light_error.is_empty():
		push_error(kit_light_error)
		quit(1)
		return
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
		if str(unit.get("family_id")) in ["T", "B", "M", "N", "A", "D"]:
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
		var selector_animation_error := _gel_selector_animation_error(
			unit, animator, str(unit.get("family_id"))
		)
		if not selector_animation_error.is_empty():
			push_error(selector_animation_error)
			quit(1)
			return
		var move_animation := animator.get_animation(&"move")
		var expected_move_length := 1.12 if _GelProfiles.v8_enabled() else 0.92
		if not is_equal_approx(move_animation.length, expected_move_length):
			push_error(
				"%s move loop length drifted for gel look %s"
				% [unit.get("family_id"), _GelProfiles.selected_look()]
			)
			quit(1)
			return
		if _GelProfiles.v8_enabled():
			var core_track := move_animation.find_track(NodePath("CoreMesh:position"), Animation.TYPE_VALUE)
			if core_track < 0:
				push_error("%s V8 move loop must drive the visible core" % unit.get("family_id"))
				quit(1)
				return
			var min_move_y := INF
			var max_move_y := -INF
			for sample in 25:
				var sample_time := move_animation.length * float(sample) / 24.0
				var sample_position: Vector3 = move_animation.value_track_interpolate(core_track, sample_time)
				min_move_y = minf(min_move_y, sample_position.y)
				max_move_y = maxf(max_move_y, sample_position.y)
			if max_move_y - min_move_y > 0.22:
				push_error("%s V8 viscous locomotion must not become a solid-body hop" % unit.get("family_id"))
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
				var a_relay_ring := a_relay.find_child("RelayRing", true, false) as MeshInstance3D
				var a_relay_material := a_relay_ring.material_override as StandardMaterial3D if a_relay_ring != null else null
				if a_relay_material == null or a_relay_material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					push_error("CHAR-BASE-A RelayRing must use the Compatibility-safe relay material")
					quit(1)
					return
	var hardened_motion_error := ""
	if _GelProfiles.v8_1_enabled():
		hardened_motion_error = _gel_v8_1_runtime_error(by_family)
	elif _GelProfiles.selected_look() == "v8":
		hardened_motion_error = _gel_v8_preservation_error(by_family)
	if not hardened_motion_error.is_empty():
		push_error(hardened_motion_error)
		quit(1)
		return
	# Do not leave the two-light lineup stage alive while later combat and mission
	# scenes use the same main viewport. A subtree-only audit would miss those
	# sibling lights and silently test an unsupported four-light composite.
	kit_preview.queue_free()
	await process_frame
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
	var requested_save_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-path="):
			requested_save_path = arg.trim_prefix("--save-path=")
			break
	if not research_state.has_method("active_save_path"):
		push_error("ResearchState must expose the active smoke save path")
		quit(1)
		return
	var active_smoke_save_path := str(research_state.call("active_save_path"))
	if active_smoke_save_path == "user://immune_demo_save.json":
		push_error("Smoke must never use the real player save path")
		quit(1)
		return
	if not requested_save_path.is_empty():
		if active_smoke_save_path != requested_save_path:
			push_error("ResearchState did not activate the requested isolated save path")
			quit(1)
			return
	if not FileAccess.file_exists(active_smoke_save_path):
		push_error("ResearchState did not initialize the isolated smoke save")
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
	for component_path in [
		"res://combat/active_skill_controller.gd",
		"res://combat/combat_encounter_director.gd",
		"res://ui/combat_touch_controls.gd",
		"res://resources/combat/family_active_skill_profile.gd",
	]:
		if not ResourceLoader.exists(component_path):
			push_error("Missing V5.3 gameplay component %s" % component_path)
			quit(1)
			return
	for action in [
		&"demo_pause", &"demo_confirm", &"demo_back", &"demo_toggle_duty",
		&"demo_research", &"demo_combat", &"demo_next_family", &"demo_prev_family",
		&"demo_move_left", &"demo_move_right", &"demo_move_forward", &"demo_move_back",
		&"demo_active_skill",
	]:
		if not InputMap.has_action(action) or not _has_gamepad_event(action):
			push_error("Input action %s is missing its gamepad mapping" % action)
			quit(1)
			return
	var content := load("res://resources/combat/combat_content.gd")
	var active_skill_ids: Array[StringName] = []
	for family_id in ["T", "B", "M", "N", "A", "D"]:
		var family: FamilyCombatProfile = content.call("load_family", StringName(family_id))
		var active_skill := family.get("active_skill") as Resource if family != null else null
		if active_skill == null:
			push_error("Family %s is missing its active-skill profile" % family_id)
			quit(1)
			return
		var active_id := StringName(active_skill.get("id"))
		if active_id.is_empty() or active_skill_ids.has(active_id):
			push_error("Family %s has an empty or duplicate active-skill id" % family_id)
			quit(1)
			return
		if float(active_skill.get("cooldown_seconds")) <= 0.0:
			push_error("Family %s active skill requires a positive cooldown" % family_id)
			quit(1)
			return
		active_skill_ids.append(active_id)
	var active_controller_script := load("res://combat/active_skill_controller.gd")
	var active_controller: Node = active_controller_script.new()
	root.add_child(active_controller)
	var active_events: Array[StringName] = []
	active_controller.connect("activation_requested", func(profile: Resource) -> void:
		active_events.append(StringName(profile.get("id")))
	)
	var t_family: FamilyCombatProfile = content.call("load_family", &"T")
	active_controller.call("configure", t_family.get("active_skill"))
	if not bool(active_controller.call("request_activation")):
		push_error("Active skill must fire when its cooldown is ready")
		quit(1)
		return
	if bool(active_controller.call("request_activation")) or active_events.size() != 1:
		push_error("Active skill must reject repeated activation during cooldown")
		quit(1)
		return
	active_controller.call("tick", float(t_family.get("active_skill").get("cooldown_seconds")) + 0.01)
	if not bool(active_controller.call("request_activation")) or active_events.size() != 2:
		push_error("Active skill must become available after its authored cooldown")
		quit(1)
		return
	active_controller.queue_free()
	var touch_script := load("res://ui/combat_touch_controls.gd")
	var touch_controls: Control = touch_script.new()
	root.add_child(touch_controls)
	await process_frame
	if int(touch_controls.call("directional_button_count")) != 4:
		push_error("Combat touch controls must expose four directional buttons")
		quit(1)
		return
	touch_controls.call("set_direction_pressed", &"right", true)
	if (touch_controls.call("movement_vector") as Vector2).x < 0.9:
		push_error("Combat touch controls did not produce a rightward movement vector")
		quit(1)
		return
	touch_controls.hide()
	if not (touch_controls.call("movement_vector") as Vector2).is_zero_approx():
		push_error("Combat touch controls must cancel held movement when hidden")
		quit(1)
		return
	touch_controls.queue_free()
	await process_frame
	var mission_ids: Array[StringName] = content.call("mission_ids")
	if mission_ids.size() != 6:
		push_error("Expected 6 authored missions, got %d" % mission_ids.size())
		quit(1)
		return
	var previous_rank := 0
	var previous_mission_id: StringName = &""
	var seen_mission_ids: Array[StringName] = []
	var seen_encounter_patterns: Array[StringName] = []
	var encounter_mission: ImmuneMissionData
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
		var encounter_pattern := StringName(mission.get("encounter_pattern"))
		if encounter_pattern.is_empty():
			push_error("Mission %s is missing its encounter pattern" % mission_id)
			quit(1)
			return
		if mission_id != &"MISSION-01":
			if encounter_pattern == &"steady" or seen_encounter_patterns.has(encounter_pattern):
				push_error("Mission %s requires a distinct non-tutorial encounter pattern" % mission_id)
				quit(1)
				return
			seen_encounter_patterns.append(encounter_pattern)
			if encounter_mission == null:
				encounter_mission = mission
		if mission_id == &"MISSION-03" and (
			mission.briefing.contains("最高難度")
			or mission.briefing.to_lower().contains("highest difficulty")
		):
			push_error("MISSION-03 briefing still claims it is the highest difficulty")
			quit(1)
			return
		previous_rank = mission.difficulty.rank
		previous_mission_id = mission.id
	var encounter_script := load("res://combat/combat_encounter_director.gd")
	var encounter_director: Node = encounter_script.new()
	root.add_child(encounter_director)
	var encounter_events: Array[StringName] = []
	encounter_director.connect("event_triggered", func(event_id: StringName, _strength: int, _occurrence: int) -> void:
		encounter_events.append(event_id)
	)
	encounter_director.call("configure", encounter_mission)
	encounter_director.call("enter_phase", &"core")
	encounter_director.call("tick", float(encounter_mission.get("encounter_interval")) + 0.01)
	if encounter_events.size() != 1 or encounter_events[0].is_empty():
		push_error("Encounter director did not emit its authored mission event")
		quit(1)
		return
	encounter_director.queue_free()
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
	var combat_light_error := _jelly_runtime_light_error("combat lane", root)
	if not combat_light_error.is_empty():
		push_error(combat_light_error)
		quit(1)
		return
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
	for property in ["_ability_button", "_duty_button", "_intel_button", "_back_button"]:
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
	var desktop_responsive: Dictionary = combat.call("responsive_contract")
	if int(desktop_responsive.get("action_columns", 0)) != 4:
		push_error("Desktop combat HUD must expose a four-column action tray")
		quit(1)
		return
	if combat.get("_touch_controls") == null:
		push_error("Combat lane is missing reusable touch movement controls")
		quit(1)
		return
	combat.call("debug_spawn_regular")
	await process_frame
	var active_target: Node = null
	for candidate in combat.get_tree().get_nodes_in_group("bacterium"):
		if combat.is_ancestor_of(candidate):
			active_target = candidate
			break
	if active_target == null:
		push_error("Combat active-skill integration requires a spawned target")
		quit(1)
		return
	var active_target_hp := int(active_target.get("hp"))
	combat.call("_request_active_skill")
	await process_frame
	if _GelProfiles.v8_1_enabled():
		# V8.1 commits gameplay at the authored 0.48 s release pose. Advance the
		# live presentation deterministically after the controller's requested
		# signal has reached CombatLane. Production uses immediate method callbacks;
		# the following frame lets the released gameplay payload settle in the scene.
		var combat_player := combat.get("_player") as Node
		var combat_animator := combat_player.get_node_or_null("AnimationPlayer") as AnimationPlayer if combat_player != null else null
		if combat_animator == null:
			push_error("Combat V8.1 active-skill integration requires the live animator")
			quit(1)
			return
		combat_animator.advance(GEL_V8_1_ACTIVE_RELEASE_TIME + 0.01)
		await process_frame
	var combat_active_controller := combat.get("_active_skill_controller") as Node
	if combat_active_controller == null or float(combat_active_controller.call("remaining_seconds")) <= 0.0:
		push_error("Combat lane did not consume the active-skill cooldown")
		quit(1)
		return
	if is_instance_valid(active_target) and int(active_target.get("hp")) >= active_target_hp:
		push_error("Combat active skill did not damage its selected pathogen")
		quit(1)
		return
	var enemies_before_surge := 0
	for candidate in combat.get_tree().get_nodes_in_group("bacterium"):
		if combat.is_ancestor_of(candidate):
			enemies_before_surge += 1
	combat.call("_on_encounter_event", &"surge", 2, 1)
	var enemies_after_surge := 0
	for candidate in combat.get_tree().get_nodes_in_group("bacterium"):
		if combat.is_ancestor_of(candidate):
			enemies_after_surge += 1
	if enemies_after_surge != enemies_before_surge + 2:
		push_error("Combat encounter handler did not spawn its authored surge")
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
	var coat_limit := 1.75 if _GelProfiles.gummy_glass_enabled() else 1.6
	if float(gel_material.get_shader_parameter("coat_strength")) > coat_limit:
		push_error("Wet-gel coat is too strong for the soft reference")
		quit(1)
		return
	if not is_zero_approx(float(gel_material.get_shader_parameter("dimple_depth"))):
		push_error("T Fizzy profile must disable directional legacy dimples")
		quit(1)
		return
	if gel_material.get_shader_parameter("bubble_enabled") != true or gel_material.get_shader_parameter("authored_height_enabled") != true:
		push_error("T Fizzy profile must retain its family profile and V5.1 authored height")
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
	if b_gel_material.get_shader_parameter("authored_height_enabled") != true:
		push_error("B Fizzy profile must enable the V5.1 authored height")
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
	telemetry.call("record_active_skill", &"SKILL-T-EXECUTION-BURST", 2)
	telemetry.call("record_encounter_event", &"surge")
	telemetry.record_enemy_defeated(false, true)
	telemetry.record_enemy_defeated(false, false)
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
	if int(telemetry_snapshot.get("active_skills_used", 0)) != 1 or int(telemetry_snapshot.get("active_skill_hits", 0)) != 2:
		push_error("Playtest telemetry active-skill contract is invalid")
		quit(1)
		return
	if int(telemetry_snapshot.get("encounter_events", 0)) != 1:
		push_error("Playtest telemetry encounter-event contract is invalid")
		quit(1)
		return
	if (
		int(telemetry_snapshot.get("enemies_defeated", 0)) != 2
		or int(telemetry_snapshot.get("objective_kills", 0)) != 1
		or int(telemetry_snapshot.get("reinforcements_defeated", 0)) != 1
	):
		push_error("Playtest telemetry objective/reinforcement contract is invalid")
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
	var active_save_path := str(research_state.call("active_save_path"))
	var smoke_save := active_save_path.get_base_dir().path_join(
		"%s.smoke-roundtrip.json" % active_save_path.get_file().get_basename()
	)
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
		var mission_light_error := _jelly_runtime_light_error("mission runtime", root)
		if not mission_light_error.is_empty():
			push_error(mission_light_error)
			quit(1)
			return
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
	var preview_light_error := _jelly_runtime_light_error("mission preview", root)
	if not preview_light_error.is_empty():
		push_error(preview_light_error)
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
		if preview == null or preview.get_parent() != preview_stage:
			push_error("Mission desk preview escaped its frame for family %s" % family_ids[i])
			quit(1)
			return
		if StringName(preview.get("family_id")) != StringName(family_ids[i]) or StringName(preview.get("duty")) != &"fixed":
			push_error("Mission desk preview state mismatch for family %s" % family_ids[i])
			quit(1)
			return
	mission_desk.queue_free()
	await process_frame
	TranslationServer.set_locale("zh_HK")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(smoke_save))
	if requested_save_path.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(active_save_path))
	research_state.call("seed_demo")
	print(
		"SMOKE_OK missions=6 families=6 save=v2 audio=ready gamepad=ready "
		+ "active_skills=6 encounters=6 touch=ready signatures=T+B traits=enrage+regen "
		+ "authored_jelly=T+B+M+N+A+D gel_fizzy=T+B+M+N+A+D gel_look=%s"
		% _GelProfiles.selected_look()
	)
	var audio_director := root.get_node_or_null("AudioDirector")
	if audio_director != null:
		audio_director.call("stop_all")
	for child in root.get_children():
		if child.name not in [&"Catalog", &"ResearchState", &"SettingsState", &"AudioDirector", &"VfxLibrary"]:
			child.queue_free()
	call_deferred("_finish_success")


func _run_jelly_light_probe() -> void:
	var rig_error := _jelly_direct_light_rig_error()
	if not rig_error.is_empty():
		push_error(rig_error)
		quit(1)
		return
	var out_dir := String(_jelly_probe_args.get("out", ""))
	if not out_dir.is_empty():
		out_dir = _validated_jelly_probe_out_dir(out_dir)
		if out_dir.is_empty():
			quit(2)
			return
		var directory_error := DirAccess.make_dir_recursive_absolute(out_dir)
		if directory_error != OK and not DirAccess.dir_exists_absolute(out_dir):
			push_error("Jelly light probe cannot create %s (%d)" % [out_dir, directory_error])
			quit(1)
			return
		# Recheck after creation so an existing linked final component cannot become
		# a write target merely because make_dir_recursive_absolute returned OK.
		if _jelly_probe_path_crosses_link(out_dir, _jelly_probe_trusted_root(out_dir)):
			push_error("Jelly light probe --out became unsafe or crosses a symbolic link")
			quit(2)
			return

	# Black/ambient-free on purpose: this probe measures the final direct-light
	# composite, without environment energy masking a pass-topology regression.
	var stage := Node3D.new()
	stage.name = "JellyLightProbe"
	root.add_child(stage)
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.002, 0.002, 0.003)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_white = 3.0
	environment.glow_enabled = false
	world_environment.environment = environment
	stage.add_child(world_environment)

	var family_look := load("res://characters/family_look.gd")
	var gel := family_look.call("gel_material", "T", {
		&"membrane_enabled": false,
		&"use_feature_tex": false,
	}) as ShaderMaterial
	if gel == null:
		push_error("Jelly light probe could not build the production T gel material")
		quit(1)
		return
	if _jelly_probe_args.has("share"):
		gel.set_shader_parameter(&"direct_light_budget_share", float(_jelly_probe_args["share"]))
	var sphere := SphereMesh.new()
	sphere.radius = 0.82
	sphere.height = 1.64
	sphere.radial_segments = 64
	sphere.rings = 32
	var body := MeshInstance3D.new()
	body.mesh = sphere
	body.material_override = gel
	stage.add_child(body)

	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 28.0
	camera.position = Vector3(0.0, 0.0, 4.0)
	stage.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	var production_light_specs := [
		{
			"name": "ProductionKey",
			"rotation": Vector3(-38.0, 34.0, 0.0),
			"color": Color(1.0, 0.97, 0.92),
			"energy": 2.1,
			"shadowed": true,
		},
		{
			"name": "ProductionFill",
			"rotation": Vector3(-12.0, -62.0, 0.0),
			"color": Color(0.55, 0.72, 1.0),
			"energy": 0.55,
			"shadowed": false,
		},
		{
			"name": "ProductionRim",
			"rotation": Vector3(-8.0, 168.0, 0.0),
			"color": Color(0.70, 0.86, 1.0),
			"energy": 1.4,
			"shadowed": false,
		},
	]
	var lights: Array[DirectionalLight3D] = []
	for light_spec in production_light_specs:
		var light := DirectionalLight3D.new()
		light.name = StringName(str(light_spec["name"]))
		light.rotation_degrees = light_spec["rotation"]
		light.light_color = light_spec["color"]
		light.light_energy = light_spec["energy"]
		light.shadow_enabled = light_spec["shadowed"]
		light.visible = false
		stage.add_child(light)
		lights.append(light)
	# Prove unsupported light classes and shadow topology fail closed before the
	# first render. Production/lookdev uses one shadowed key plus fill and rim.
	var forbidden_lights: Array[Light3D] = [OmniLight3D.new(), SpotLight3D.new()]
	for forbidden_light in forbidden_lights:
		var forbidden_class := forbidden_light.get_class()
		forbidden_light.name = "Rejected%s" % forbidden_class
		stage.add_child(forbidden_light)
		var rejected_class_error := _jelly_runtime_light_error(
			"invalid %s probe" % forbidden_class, root
		)
		stage.remove_child(forbidden_light)
		forbidden_light.free()
		if (
			rejected_class_error.is_empty()
			or not rejected_class_error.contains(forbidden_class)
			or not rejected_class_error.contains("DirectionalLight3D only")
		):
			push_error("Jelly light probe did not clearly reject %s" % forbidden_class)
			quit(1)
			return
	lights[1].shadow_enabled = true
	var rejected_shadow_error := _jelly_runtime_light_error("invalid two-shadow-key probe", root)
	lights[1].shadow_enabled = false
	if rejected_shadow_error.is_empty() or not rejected_shadow_error.contains("supported maximum is 1"):
		push_error("Jelly light probe did not reject a second shadow-casting direct light")
		quit(1)
		return
	var probe_light_error := _jelly_runtime_light_error("light probe", root)
	if not probe_light_error.is_empty():
		push_error(probe_light_error)
		quit(1)
		return

	# Base-pass emission must improve readability without turning the material into
	# a self-lit lantern. No direct lights is therefore a first-class gate, not an
	# implied side effect of the one-light result.
	for _frame in 8:
		await RenderingServer.frame_post_draw
	var zero_image: Image = root.get_texture().get_image()
	# Logical viewport and texture metadata can be content-scaled on Retina. The
	# readback buffer follows the OS window pixels controlled by --resolution.
	var expected_image_size := DisplayServer.window_get_size()
	if not _jelly_probe_image_valid(zero_image, expected_image_size, "zero-light"):
		quit(1)
		return
	var zero_sample := _jelly_probe_metrics(zero_image)
	zero_sample["lights"] = 0
	if not out_dir.is_empty():
		var zero_save_error := _save_jelly_probe_png(
			zero_image,
			out_dir.path_join("jelly-production-0.png"),
			expected_image_size
		)
		if zero_save_error != OK:
			push_error("Jelly light probe could not save zero-light evidence (%d)" % zero_save_error)
			quit(1)
			return
	print("JELLY_LIGHT_PROBE share=%.4f lights=0 pixels=%d median_luma=%.4f p95_peak=%.4f clip_dom=%.2f%%" % [
		float(gel.get_shader_parameter("direct_light_budget_share")),
		int(zero_sample["pixels"]),
		float(zero_sample["median_luma"]),
		float(zero_sample["p95_peak"]),
		float(zero_sample["clip_fraction"]) * 100.0,
	])

	var metrics: Array[Dictionary] = []
	for light_count in range(1, JELLY_DIRECT_LIGHT_LIMIT + 1):
		for light_index in lights.size():
			lights[light_index].visible = light_index < light_count
		for _frame in 8:
			await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		if not _jelly_probe_image_valid(
			image, expected_image_size, "%d-light" % light_count
		):
			quit(1)
			return
		var sample := _jelly_probe_metrics(image)
		sample["lights"] = light_count
		metrics.append(sample)
		if not out_dir.is_empty():
			var save_error := _save_jelly_probe_png(
				image,
				out_dir.path_join("jelly-production-%d.png" % light_count),
				expected_image_size
			)
			if save_error != OK:
				push_error("Jelly light probe could not save %d-light evidence (%d)" % [light_count, save_error])
				quit(1)
				return
		print("JELLY_LIGHT_PROBE share=%.4f lights=%d pixels=%d median_luma=%.4f p95_peak=%.4f clip_dom=%.2f%%" % [
			float(gel.get_shader_parameter("direct_light_budget_share")),
			light_count,
			int(sample["pixels"]),
			float(sample["median_luma"]),
			float(sample["p95_peak"]),
			float(sample["clip_fraction"]) * 100.0,
		])
	var semantics_error := _gel_light_semantics_error(gel)
	var final_sample: Dictionary = metrics[-1]
	var one_sample: Dictionary = metrics[0]
	var monotonic := (
		float(metrics[1]["median_luma"]) > float(one_sample["median_luma"]) * 1.05
		and float(final_sample["median_luma"]) > float(metrics[1]["median_luma"]) * 1.02
	)
	var composite_error := ""
	if int(zero_sample["pixels"]) <= 0:
		composite_error = "zero-light probe did not render the gel subject"
	elif float(zero_sample["median_luma"]) > 0.15:
		composite_error = "zero-light base fill exceeded the 0.15 luminance ceiling"
	elif float(zero_sample["clip_fraction"]) > 0.0:
		composite_error = "zero-light base fill produced hot pixels"
	elif metrics.any(func(sample: Dictionary) -> bool: return float(sample["clip_fraction"]) > 0.05):
		composite_error = "production progressive lights exceeded the 5%% subject clipping ceiling"
	elif not monotonic:
		composite_error = "production progressive passes did not contribute monotonically"
	elif float(one_sample["median_luma"]) < 0.15:
		composite_error = "one-light composite fell below the readable gel midtone"
	elif float(final_sample["median_luma"]) < 0.24:
		composite_error = "three-light composite fell below the readable gel midtone"
	if not semantics_error.is_empty() or not composite_error.is_empty():
		push_error("JELLY_LIGHT_PROBE_FAIL %s%s" % [
			semantics_error,
			("; " if not semantics_error.is_empty() and not composite_error.is_empty() else "")
				+ composite_error,
		])
		quit(1)
		return
	print("JELLY_LIGHT_PROBE_OK topology=0+1-shadowed-key+2-unshadowed-fills direct_limit=%d shadowed_limit=%d rejected=OmniLight3D+SpotLight3D+2-shadowed identity_albedo=true" % [
		JELLY_DIRECT_LIGHT_LIMIT,
		JELLY_SHADOWED_DIRECT_LIGHT_LIMIT,
	])
	quit(0)


func _jelly_probe_requested() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg == "--jelly-light-probe" or arg.begins_with("--jelly-light-probe="):
			return true
	return false


func _parse_regular_smoke_args() -> bool:
	var seen := {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			push_error("Smoke received unexpected positional argument '%s'" % arg)
			return false
		var pair := arg.trim_prefix("--").split("=", true, 1)
		var key := String(pair[0])
		if key not in REGULAR_SMOKE_ALLOWED_ARGS:
			push_error("Smoke received unknown option --%s" % key)
			return false
		if seen.has(key):
			push_error("Smoke received duplicate option --%s" % key)
			return false
		if pair.size() != 2 or String(pair[1]).is_empty():
			push_error("Smoke --%s requires a non-empty value" % key)
			return false
		seen[key] = true
	return true


func _parse_jelly_probe_args() -> bool:
	_jelly_probe_args.clear()
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			push_error("Jelly light probe received unexpected positional argument '%s'" % arg)
			return false
		var pair := arg.trim_prefix("--").split("=", true, 1)
		var key := String(pair[0])
		if key not in JELLY_PROBE_ALLOWED_ARGS:
			push_error("Jelly light probe received unknown option --%s" % key)
			return false
		if _jelly_probe_args.has(key):
			push_error("Jelly light probe received duplicate option --%s" % key)
			return false
		if key == "jelly-light-probe":
			if pair.size() != 1:
				push_error("Jelly light probe flag does not take a value")
				return false
			_jelly_probe_args[key] = true
			continue
		if pair.size() != 2 or String(pair[1]).is_empty():
			push_error("Jelly light probe --%s requires a non-empty value" % key)
			return false
		_jelly_probe_args[key] = pair[1]
	if not _jelly_probe_args.has("jelly-light-probe"):
		push_error("Jelly light probe mode requires --jelly-light-probe")
		return false
	if _jelly_probe_args.has("share"):
		var parsed_share := _parse_jelly_probe_share(String(_jelly_probe_args["share"]))
		if not bool(parsed_share.get("ok", false)):
			return false
		_jelly_probe_args["share"] = float(parsed_share["value"])
	return true


func _parse_jelly_probe_share(raw_value: String) -> Dictionary:
	var trimmed := raw_value.strip_edges()
	if trimmed.is_empty() or not trimmed.is_valid_float():
		push_error("Jelly light probe --share requires a finite number")
		return {"ok": false}
	var value := float(trimmed)
	if not is_finite(value):
		push_error("Jelly light probe --share requires a finite number")
		return {"ok": false}
	if value < JELLY_PROBE_SHARE_MIN or value > JELLY_PROBE_SHARE_MAX:
		push_error(
			"Jelly light probe --share must be between %.3f and %.3f"
			% [JELLY_PROBE_SHARE_MIN, JELLY_PROBE_SHARE_MAX]
		)
		return {"ok": false}
	return {"ok": true, "value": value}


func _validated_jelly_probe_out_dir(raw_path: String) -> String:
	var absolute_path := raw_path
	if absolute_path.begins_with("res://") or absolute_path.begins_with("user://"):
		absolute_path = ProjectSettings.globalize_path(absolute_path)
	if not absolute_path.is_absolute_path():
		push_error("Jelly light probe --out must be an absolute path")
		return ""
	absolute_path = absolute_path.replace("\\", "/").simplify_path().trim_suffix("/")
	var project_source_root := ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path().trim_suffix("/")
	if _jelly_probe_path_is_within(absolute_path, project_source_root):
		push_error("Jelly light probe --out cannot write into res:// source")
		return ""
	var trusted_root := _jelly_probe_trusted_root(absolute_path)
	if trusted_root.is_empty():
		push_error(
			"Jelly light probe --out must be inside the system temp or repository outputs directory"
		)
		return ""
	if (
		_jelly_probe_path_compare_value(absolute_path)
		== _jelly_probe_path_compare_value(trusted_root)
		or _jelly_probe_path_crosses_link(absolute_path, trusted_root)
	):
		push_error("Jelly light probe --out is unsafe or crosses a symbolic link")
		return ""
	if FileAccess.file_exists(absolute_path):
		push_error("Jelly light probe --out names a file")
		return ""
	return absolute_path


func _jelly_probe_trusted_root(path: String) -> String:
	var temp_root := OS.get_temp_dir().replace("\\", "/").simplify_path().trim_suffix("/")
	var outputs_root := _jelly_probe_repository_outputs_root()
	if _jelly_probe_path_is_within(path, temp_root):
		return temp_root
	if _jelly_probe_path_is_within(path, outputs_root):
		return outputs_root
	return ""


func _jelly_probe_repository_outputs_root() -> String:
	var project_root := ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path()
	return project_root.get_base_dir().get_base_dir().path_join("outputs").simplify_path()


func _jelly_probe_path_is_within(path: String, root_path: String) -> bool:
	var normalized_path := path.replace("\\", "/").simplify_path().trim_suffix("/")
	var normalized_root := root_path.replace("\\", "/").simplify_path().trim_suffix("/")
	var comparable_path := _jelly_probe_path_compare_value(normalized_path)
	var comparable_root := _jelly_probe_path_compare_value(normalized_root)
	return comparable_path == comparable_root or comparable_path.begins_with(comparable_root + "/")


func _jelly_probe_path_compare_value(path: String) -> String:
	return path.to_lower() if OS.get_name() in ["Windows", "macOS"] else path


func _jelly_probe_path_crosses_link(path: String, trusted_root: String) -> bool:
	if trusted_root.is_empty():
		return true
	var relative := path.substr(trusted_root.length()).trim_prefix("/")
	var cursor := trusted_root
	for component: String in relative.split("/", false):
		var directory := DirAccess.open(cursor)
		if directory == null:
			return false
		if directory.is_link(component):
			return true
		cursor = cursor.path_join(component)
	return false


func _jelly_probe_image_valid(image: Image, expected_size: Vector2i, label: String) -> bool:
	if image == null or image.is_empty():
		push_error("Jelly light probe %s viewport returned no image" % label)
		return false
	if expected_size.x <= 0 or expected_size.y <= 0 or image.get_size() != expected_size:
		push_error(
			"Jelly light probe %s image has size %s, expected %s"
			% [label, image.get_size(), expected_size]
		)
		return false
	return true


func _save_jelly_probe_png(image: Image, path: String, expected_size: Vector2i) -> Error:
	if not _jelly_probe_image_valid(image, expected_size, path.get_file()):
		return ERR_FILE_CORRUPT
	var path_error := _jelly_probe_output_file_error(path)
	if not path_error.is_empty():
		push_error(path_error)
		return ERR_FILE_CANT_WRITE
	var save_error := image.save_png(path)
	if save_error != OK:
		return save_error
	# Recheck before trusting/reopening the result. This also fails closed if a
	# concurrent process replaced the evidence filename with a link during save.
	path_error = _jelly_probe_output_file_error(path)
	if not path_error.is_empty():
		push_error(path_error)
		return ERR_FILE_CANT_WRITE
	var reopened := Image.load_from_file(path)
	if not _jelly_probe_image_valid(reopened, expected_size, path.get_file()):
		push_error("Jelly light probe saved PNG cannot be reopened at expected size: %s" % path)
		return ERR_FILE_CORRUPT
	return OK


func _jelly_probe_output_file_error(path: String) -> String:
	var normalized_path := path.replace("\\", "/").simplify_path()
	var trusted_root := _jelly_probe_trusted_root(normalized_path)
	if trusted_root.is_empty():
		return "Jelly light probe evidence path escaped its trusted output roots: %s" % path
	if _jelly_probe_path_crosses_link(normalized_path, trusted_root):
		return "Jelly light probe evidence path crosses a symbolic link: %s" % path
	if DirAccess.dir_exists_absolute(normalized_path):
		return "Jelly light probe evidence path names a directory: %s" % path
	return ""


func _abort_for_qa_startup_failure() -> bool:
	var research_state := root.get_node_or_null("ResearchState")
	if research_state == null or not research_state.has_method("qa_startup_failed"):
		return false
	if not bool(research_state.call("qa_startup_failed")):
		return false
	var exit_code := QA_STARTUP_FAILURE_EXIT_CODE
	if research_state.has_method("qa_startup_failure_exit_code"):
		exit_code = int(research_state.call("qa_startup_failure_exit_code"))
	quit(exit_code)
	return true


func _jelly_probe_metrics(image: Image) -> Dictionary:
	var peaks: Array[float] = []
	var lumas: Array[float] = []
	var clipped := 0
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			var peak := maxf(color.r, maxf(color.g, color.b))
			var luma := 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
			if luma <= 0.025:
				continue
			peaks.append(peak)
			lumas.append(luma)
			if peak >= (250.0 / 255.0):
				clipped += 1
	if peaks.is_empty():
		return {
			"pixels": 0,
			"median_luma": 0.0,
			"p95_peak": 0.0,
			"clip_fraction": 1.0,
		}
	peaks.sort()
	lumas.sort()
	return {
		"pixels": peaks.size(),
		"median_luma": lumas[lumas.size() / 2],
		"p95_peak": peaks[mini(int(float(peaks.size()) * 0.95), peaks.size() - 1)],
		"clip_fraction": float(clipped) / float(peaks.size()),
	}


func _jelly_direct_light_rig_error() -> String:
	if JELLY_DIRECT_LIGHT_LIMIT != 3 or _LightContract.MAX_DIRECT_LIGHTS != 3:
		return "Jelly Compatibility calibration requires an immutable three-light maximum"
	if JELLY_SHADOWED_DIRECT_LIGHT_LIMIT != 1 or _LightContract.MAX_SHADOWED_DIRECT_LIGHTS != 1:
		return "Jelly Compatibility calibration requires exactly one shadow-casting direct-light maximum"
	for source_path in JELLY_DIRECT_LIGHT_RIG_SOURCES:
		if not FileAccess.file_exists(source_path):
			return "Jelly direct-light audit cannot read %s" % source_path
		var source := FileAccess.get_file_as_string(source_path)
		if not source.contains("_LightContract.error("):
			return "Jelly lookdev rig %s must execute the shared runtime light audit" % source_path
	return ""


func _jelly_runtime_light_error(label: String, node: Node) -> String:
	return _LightContract.error(node, label)


func _finish_success() -> void:
	await process_frame
	await process_frame
	quit(0)


func _has_gamepad_event(action: StringName) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


func _gel_selector_animation_error(
	unit: Node, animator: AnimationPlayer, family: String
) -> String:
	if animator == null:
		return "CHAR-BASE-%s missing its generated gel AnimationPlayer" % family
	for animation_name in GEL_LEGACY_ANIMATIONS:
		if not animator.has_animation(StringName(animation_name)):
			return "CHAR-BASE-%s selector %s lost legacy animation %s" % [
				family, _GelProfiles.selected_look(), animation_name,
			]
	var attack := animator.get_animation(&"attack")
	if _GelProfiles.v8_1_enabled():
		for animation_name in GEL_V8_1_ANIMATIONS:
			if not animator.has_animation(StringName(animation_name)):
				return "CHAR-BASE-%s V8.1 missing animation %s" % [family, animation_name]
		if animator.get_animation_list().size() != GEL_LEGACY_ANIMATIONS.size() + GEL_V8_1_ANIMATIONS.size():
			return "CHAR-BASE-%s V8.1 animation set must be additive and exact" % family
		var expected_lengths := {
			&"move_start": 0.28,
			&"move_stop": 0.52,
			&"relay_glide": 1.60,
			&"skill_cast": 0.96,
		}
		for animation_name in expected_lengths:
			var animation := animator.get_animation(animation_name)
			if not is_equal_approx(animation.length, float(expected_lengths[animation_name])):
				return "CHAR-BASE-%s V8.1 %s timing drifted" % [family, animation_name]
		if animator.get_animation(&"relay_glide").loop_mode != Animation.LOOP_LINEAR:
			return "CHAR-BASE-%s V8.1 relay glide must remain a loop" % family
		var basic_markers := _animation_method_marker_times(
			attack, &"_on_combat_release_marker"
		)
		var active_markers := _animation_method_marker_times(
			animator.get_animation(&"skill_cast"), &"_on_combat_release_marker"
		)
		if basic_markers.size() != 1 or not is_equal_approx(
			basic_markers[0], GEL_V8_1_BASIC_RELEASE_TIME
		):
			return "CHAR-BASE-%s V8.1 basic attack must release once at 0.345 s" % family
		if active_markers.size() != 1 or not is_equal_approx(
			active_markers[0], GEL_V8_1_ACTIVE_RELEASE_TIME
		):
			return "CHAR-BASE-%s V8.1 active skill must release once at 0.48 s" % family
		return ""

	# V8 is a named rollback path, not an alias for the hardened controller.
	# Its clip set and method-free attack are kept byte-for-behaviour compatible.
	if _GelProfiles.selected_look() == "v8":
		if animator.get_animation_list().size() != GEL_LEGACY_ANIMATIONS.size():
			return "CHAR-BASE-%s explicit V8 must retain exactly eight legacy clips" % family
		for animation_name in GEL_V8_1_ANIMATIONS:
			if animator.has_animation(StringName(animation_name)):
				return "CHAR-BASE-%s explicit V8 must not inherit V8.1 clip %s" % [
					family, animation_name,
				]
		if _animation_method_track_count(attack) != 0:
			return "CHAR-BASE-%s explicit V8 attack must remain method-track free" % family
	return ""


func _animation_method_marker_times(
	animation: Animation, method_name: StringName
) -> PackedFloat32Array:
	var times := PackedFloat32Array()
	if animation == null:
		return times
	for track_index in animation.get_track_count():
		if animation.track_get_type(track_index) != Animation.TYPE_METHOD:
			continue
		if animation.track_get_path(track_index) != NodePath("."):
			continue
		for key_index in animation.track_get_key_count(track_index):
			var value: Variant = animation.track_get_key_value(track_index, key_index)
			if value is Dictionary and StringName(value.get("method", &"")) == method_name:
				times.append(animation.track_get_key_time(track_index, key_index))
	return times


func _animation_method_track_count(animation: Animation) -> int:
	var count := 0
	if animation == null:
		return count
	for track_index in animation.get_track_count():
		if animation.track_get_type(track_index) == Animation.TYPE_METHOD:
			count += 1
	return count


func _gel_v8_1_runtime_error(by_family: Dictionary) -> String:
	var unit := by_family.get("T") as Node
	var relay_unit := by_family.get("A") as Node
	if unit == null or relay_unit == null:
		return "V8.1 runtime contract requires representative T and A characters"
	var animator := unit.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var relay_animator := relay_unit.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animator == null or relay_animator == null:
		return "V8.1 runtime contract requires both representative animators"
	# The lineup loop has just requested the mobile/relay duty. Resolve those
	# authored one-shots before exercising the combat and locomotion lanes.
	animator.advance(2.0)
	relay_animator.advance(2.0)

	var release_error := _gel_v8_1_release_timing_error(unit, animator)
	if not release_error.is_empty():
		return release_error
	var locomotion_error := _gel_v8_1_locomotion_error(unit, animator)
	if not locomotion_error.is_empty():
		return locomotion_error
	var low_render_error := _gel_v8_1_low_render_motion_truth_error(unit)
	if not low_render_error.is_empty():
		return low_render_error
	var contact_error := _gel_v8_1_contact_error(unit)
	if not contact_error.is_empty():
		return contact_error
	var reversal_error := _gel_v8_1_reversal_error(unit)
	if not reversal_error.is_empty():
		return reversal_error
	var relay_error := _gel_v8_1_relay_error(relay_unit, relay_animator)
	if not relay_error.is_empty():
		return relay_error
	return _gel_v8_1_attachment_error(unit)


func _gel_v8_1_release_timing_error(unit: Node, animator: AnimationPlayer) -> String:
	_v8_1_release_events.clear()
	_v8_1_cancel_events.clear()
	# Release markers are gameplay boundaries, so production V8.1 must process a
	# marker before animation_finished even when one low-FPS advance crosses both.
	if animator.callback_mode_method != AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE:
		return "CHAR-BASE-T V8.1 production method callbacks must be immediate"
	var release_callable := Callable(self, "_capture_v8_1_release")
	var cancel_callable := Callable(self, "_capture_v8_1_cancel")
	if not unit.is_connected("combat_action_released", release_callable):
		unit.connect("combat_action_released", release_callable)
	if not unit.is_connected("combat_action_cancelled", cancel_callable):
		unit.connect("combat_action_cancelled", cancel_callable)
	if not bool(unit.call("request_combat_action", 8101, &"basic", &"BASIC-T", 0.0)):
		return "CHAR-BASE-T V8.1 rejected an idle basic-action presentation token"
	animator.advance(0.0)
	animator.advance(GEL_V8_1_BASIC_RELEASE_TIME - 0.002)
	if not _v8_1_release_events.is_empty():
		return "CHAR-BASE-T V8.1 basic gameplay released before its authored pose"
	animator.advance(0.004)
	if _v8_1_release_events.size() != 1:
		return "CHAR-BASE-T V8.1 basic gameplay did not release exactly once at its pose"
	var basic_event: Dictionary = _v8_1_release_events[0]
	if int(basic_event.get("id", 0)) != 8101 or StringName(basic_event.get("kind", &"")) != &"basic":
		return "CHAR-BASE-T V8.1 basic release token lost its request identity"
	animator.advance(1.0)
	if _v8_1_release_events.size() != 1:
		return "CHAR-BASE-T V8.1 basic method track double-released"

	_v8_1_release_events.clear()
	if not bool(unit.call("request_combat_action", 8102, &"active", &"SKILL-T-ACTIVE", 0.0)):
		return "CHAR-BASE-T V8.1 rejected an idle active-skill presentation token"
	animator.advance(0.0)
	animator.advance(GEL_V8_1_ACTIVE_RELEASE_TIME - 0.002)
	if not _v8_1_release_events.is_empty():
		return "CHAR-BASE-T V8.1 active gameplay released before its authored pose"
	animator.advance(0.004)
	if _v8_1_release_events.size() != 1:
		return "CHAR-BASE-T V8.1 active gameplay did not release exactly once at its pose"
	var active_event: Dictionary = _v8_1_release_events[0]
	if int(active_event.get("id", 0)) != 8102 or StringName(active_event.get("kind", &"")) != &"active":
		return "CHAR-BASE-T V8.1 active release token lost its request identity"
	animator.advance(1.0)
	if _v8_1_release_events.size() != 1 or not _v8_1_cancel_events.is_empty():
		return "CHAR-BASE-T V8.1 completed combat actions must neither duplicate nor cancel"

	# One production-mode advance crosses both the authored marker and clip end.
	# The release must win deterministically; animation_finished must not observe
	# an unreleased request and manufacture a missing_release cancellation.
	_v8_1_release_events.clear()
	_v8_1_cancel_events.clear()
	if not bool(unit.call("request_combat_action", 8103, &"basic", &"BASIC-T", 0.0)):
		return "CHAR-BASE-T V8.1 rejected the low-render release-order token"
	animator.advance(0.0)
	animator.advance(animator.get_animation(&"attack").length + 0.05)
	if _v8_1_release_events.size() != 1:
		return "CHAR-BASE-T V8.1 low-render advance did not release exactly once"
	var crossed_event: Dictionary = _v8_1_release_events[0]
	if int(crossed_event.get("id", 0)) != 8103 or StringName(crossed_event.get("kind", &"")) != &"basic":
		return "CHAR-BASE-T V8.1 low-render release lost its request identity"
	if not _v8_1_cancel_events.is_empty():
		var crossed_cancel: Dictionary = _v8_1_cancel_events[0]
		return "CHAR-BASE-T V8.1 low-render release was cancelled as %s" % String(
			crossed_cancel.get("reason", &"")
		)
	return ""


func _capture_v8_1_release(request_id: int, action_kind: StringName) -> void:
	_v8_1_release_events.append({"id": request_id, "kind": action_kind})


func _capture_v8_1_cancel(
	request_id: int, action_kind: StringName, reason: StringName
) -> void:
	_v8_1_cancel_events.append({"id": request_id, "kind": action_kind, "reason": reason})


func _gel_v8_1_locomotion_error(unit: Node, animator: AnimationPlayer) -> String:
	unit.set("duty", &"mobile")
	unit.call("_apply_duty", &"mobile")
	unit.call("settle_motion", 1.0 / 60.0, false)
	unit.call("_cache_liquid_materials")
	animator.play(&"idle")
	animator.advance(0.0)
	unit.call("submit_motion_truth", Vector3(2.4, 0.0, 0.0), Vector3(2.4, 0.0, 0.0), Vector3.ZERO, 1.0 / 60.0)
	if StringName(unit.call("liquid_locomotion_state")) != &"idle":
		return "CHAR-BASE-T V8.1 locomotion must debounce the first moving frame"
	unit.call("submit_motion_truth", Vector3(2.4, 0.0, 0.0), Vector3(2.4, 0.0, 0.0), Vector3.ZERO, 1.0 / 60.0)
	if StringName(unit.call("liquid_locomotion_state")) != &"starting" or animator.current_animation != &"move_start":
		return "CHAR-BASE-T V8.1 locomotion must enter its viscous start clip after two frames"
	animator.advance(0.30)
	if StringName(unit.call("liquid_locomotion_state")) != &"moving" or animator.current_animation != &"move":
		return "CHAR-BASE-T V8.1 start clip must hand off to the grounded move loop"
	var release_anchor := unit.get_node_or_null("WeaponSocket/LiquidReleaseAnchor") as Node3D
	if release_anchor == null:
		return "CHAR-BASE-T V8.1 must expose a deformation-aware release anchor"
	var anchor_home := release_anchor.transform
	for frame in 30:
		unit.call("submit_motion_truth", Vector3(2.4, 0.0, 0.0), Vector3(2.4, 0.0, 0.0), Vector3.ZERO, 1.0 / 60.0)
	if release_anchor.transform.origin.distance_to(anchor_home.origin) < 0.004:
		return "CHAR-BASE-T V8.1 release anchor must follow the viscous presentation mass"
	for frame in 3:
		unit.call("submit_motion_truth", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, 1.0 / 60.0)
	if StringName(unit.call("liquid_locomotion_state")) != &"stopping" or animator.current_animation != &"move_stop":
		return "CHAR-BASE-T V8.1 locomotion must enter its three-frame stop edge"
	animator.advance(0.55)
	if StringName(unit.call("liquid_locomotion_state")) != &"idle" or animator.current_animation != &"idle":
		return "CHAR-BASE-T V8.1 stop clip must settle into idle"
	return ""


func _gel_v8_1_low_render_motion_truth_error(unit: Node) -> String:
	var original_duty := StringName(unit.get("duty"))
	unit.set("duty", &"fixed")
	unit.call("_apply_duty", &"fixed")
	unit.call("_cache_liquid_materials")
	var moving_velocity := Vector3(2.4, 0.0, 0.0)
	# Normal 60 Hz post-physics submissions precede a deliberately slow 100 ms
	# render frame. Render delta alone must never expire the latest physics truth.
	for physics_tick in 6:
		unit.call(
			"submit_motion_truth",
			moving_velocity,
			moving_velocity,
			Vector3.ZERO,
			1.0 / 60.0
		)
	var motion_before_render := float(unit.call("liquid_motion_mix"))
	unit.call("_process", 0.10)
	var resolved_after_render := unit.call("resolved_motion_velocity") as Vector3
	var motion_after_render := float(unit.call("liquid_motion_mix"))
	unit.call("settle_motion", 1.0 / 60.0, false)
	unit.set("duty", original_duty)
	unit.call("_apply_duty", original_duty)
	unit.call("_cache_liquid_materials")
	if resolved_after_render.distance_to(moving_velocity) > 0.001:
		return "CHAR-BASE-T V8.1 expired fresh physics truth on a 100 ms render frame"
	if motion_after_render + 0.0001 < motion_before_render:
		return "CHAR-BASE-T V8.1 low render FPS incorrectly decayed fresh locomotion"
	return ""


func _gel_v8_1_contact_error(unit: Node) -> String:
	var collision := unit.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null or collision.shape == null:
		return "CHAR-BASE-T V8.1 wall-contact test requires stable gameplay collision"
	var collision_transform := collision.transform
	var collision_shape := collision.shape
	unit.set("duty", &"mobile")
	unit.call("_apply_duty", &"mobile")
	unit.call("_cache_liquid_materials")
	# Requested motion presses into the wall while resolved displacement is zero.
	# Locomotion follows the latter; the former drives only the contact envelope.
	for frame in 5:
		unit.call("submit_motion_truth", Vector3(3.0, 0.0, 0.0), Vector3.ZERO, Vector3(-1.0, 0.0, 0.0), 1.0 / 60.0)
	if StringName(unit.call("liquid_locomotion_state")) != &"idle":
		return "CHAR-BASE-T V8.1 must not walk in place while resolved against a wall"
	if float(unit.call("liquid_motion_mix")) > 0.01:
		return "CHAR-BASE-T V8.1 wall pressure leaked requested speed into locomotion"
	if float(unit.call("liquid_contact_amount")) <= 0.05:
		return "CHAR-BASE-T V8.1 wall contact did not produce a readable viscous response"
	for frame in 120:
		unit.call("submit_motion_truth", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, 1.0 / 60.0)
	if absf(float(unit.call("liquid_contact_amount"))) > 0.002:
		return "CHAR-BASE-T V8.1 wall-contact envelope did not return to zero"
	if (unit.call("liquid_body_lag") as Vector3).length() > 0.012 or float(unit.call("liquid_body_squash")) > 0.008:
		return "CHAR-BASE-T V8.1 wall response retained visible residual deformation"
	if not collision.transform.is_equal_approx(collision_transform) or collision.shape != collision_shape:
		return "CHAR-BASE-T V8.1 visual contact must never deform gameplay collision"
	return ""


func _gel_v8_1_reversal_error(unit: Node) -> String:
	var original_duty := StringName(unit.get("duty"))
	unit.set("duty", &"fixed")
	unit.call("_apply_duty", &"fixed")
	var samples: Array[Vector3] = []
	for fps in [30, 60, 120]:
		unit.call("_cache_liquid_materials")
		var delta := 1.0 / float(fps)
		for frame in int(round(0.50 * fps)):
			unit.call("submit_motion_truth", Vector3(2.4, 0.0, 0.0), Vector3(2.4, 0.0, 0.0), Vector3.ZERO, delta)
		for frame in int(round(0.20 * fps)):
			unit.call("submit_motion_truth", Vector3(-2.4, 0.0, 0.0), Vector3(-2.4, 0.0, 0.0), Vector3.ZERO, delta)
		var direction := unit.call("liquid_flow_direction") as Vector3
		if direction.length() < 0.999:
			return "CHAR-BASE-T V8.1 180-degree reversal collapsed its flow direction at %d Hz" % fps
		samples.append(direction)
	unit.set("duty", original_duty)
	unit.call("_apply_duty", original_duty)
	unit.call("_cache_liquid_materials")
	if samples[0].distance_to(samples[1]) > 0.035 or samples[1].distance_to(samples[2]) > 0.035:
		return "CHAR-BASE-T V8.1 reversal steering drifted across 30/60/120 Hz"
	return ""


func _gel_v8_1_relay_error(unit: Node, animator: AnimationPlayer) -> String:
	unit.set("duty", &"relay")
	unit.call("_apply_duty", &"relay")
	unit.call("settle_motion", 1.0 / 60.0, false)
	unit.call("_cache_liquid_materials")
	animator.play(&"idle")
	animator.advance(0.0)
	for frame in 2:
		unit.call("submit_motion_truth", Vector3(2.4, 0.0, 0.0), Vector3(2.4, 0.0, 0.0), Vector3.ZERO, 1.0 / 60.0)
	if animator.current_animation != &"move_start":
		return "CHAR-BASE-A V8.1 relay travel must retain the viscous start edge"
	animator.advance(0.30)
	if StringName(unit.call("liquid_locomotion_state")) != &"moving" or animator.current_animation != &"relay_glide":
		return "CHAR-BASE-A V8.1 relay travel must hand off to relay_glide"
	if not animator.get_animation(&"relay_glide").loop_mode == Animation.LOOP_LINEAR:
		return "CHAR-BASE-A V8.1 relay_glide must remain an analytic loop"
	return ""


func _gel_v8_1_attachment_error(unit: Node) -> String:
	if not unit.has_method("liquid_attachment_material_count") or int(unit.call("liquid_attachment_material_count")) < 3:
		return "CHAR-BASE-T V8.1 must bind both eyes and the mouth cavity to body-space deformation"
	var release_anchor := unit.get_node_or_null("WeaponSocket/LiquidReleaseAnchor") as Node3D
	if release_anchor == null or unit.get("weapon_socket") != release_anchor:
		return "CHAR-BASE-T V8.1 gameplay VFX must emit from the liquid release anchor"
	var real_mesh := unit.get_node_or_null("CoreMesh/RealMesh") as Node3D
	var cavity := real_mesh.get_node_or_null("MouthCavity") as MeshInstance3D if real_mesh != null else null
	var cavity_material := cavity.material_override as ShaderMaterial if cavity != null else null
	if cavity_material == null or cavity_material.shader == null or not cavity_material.shader.resource_path.ends_with("gel_eye.gdshader"):
		return "CHAR-BASE-T V8.1 mouth cavity must use the coherent gel attachment shader"
	var materials := _shader_materials_with_suffix(unit, [
		"wet_gel.gdshader", "jelly_shell.gdshader", "gel_eye.gdshader",
	])
	if materials.size() < 5:
		return "CHAR-BASE-T V8.1 coherent-material audit found too few gel parts"
	var expected_lag := unit.call("liquid_body_lag") as Vector3
	var expected_squash := float(unit.call("liquid_body_squash"))
	var expected_turn := float(unit.call("liquid_turn_shear"))
	var expected_contact := float(unit.call("liquid_contact_amount"))
	for material in materials:
		if float(material.get_shader_parameter("liquid_body_space_enabled")) < 0.99:
			return "CHAR-BASE-T V8.1 gel attachment escaped shared body-space deformation"
		if not (material.get_shader_parameter("liquid_body_lag") as Vector3).is_equal_approx(expected_lag):
			return "CHAR-BASE-T V8.1 wet core, shell and attachments disagree on body lag"
		if not is_equal_approx(float(material.get_shader_parameter("liquid_body_squash")), expected_squash):
			return "CHAR-BASE-T V8.1 wet core, shell and attachments disagree on squash"
		if not is_equal_approx(float(material.get_shader_parameter("liquid_turn_shear")), expected_turn):
			return "CHAR-BASE-T V8.1 wet core, shell and attachments disagree on turn shear"
		if not is_equal_approx(float(material.get_shader_parameter("liquid_contact_amount")), expected_contact):
			return "CHAR-BASE-T V8.1 wet core, shell and attachments disagree on contact"
	return ""


func _shader_materials_with_suffix(node: Node, suffixes: Array[String]) -> Array[ShaderMaterial]:
	var materials: Array[ShaderMaterial] = []
	var seen := {}
	_shader_materials_with_suffix_recursive(node, suffixes, materials, seen)
	return materials


func _shader_materials_with_suffix_recursive(
	node: Node,
	suffixes: Array[String],
	materials: Array[ShaderMaterial],
	seen: Dictionary
) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		_append_matching_shader_material(mesh_instance.material_override, suffixes, materials, seen)
		if mesh_instance.mesh != null:
			for surface in mesh_instance.mesh.get_surface_count():
				_append_matching_shader_material(mesh_instance.get_surface_override_material(surface), suffixes, materials, seen)
				_append_matching_shader_material(mesh_instance.mesh.surface_get_material(surface), suffixes, materials, seen)
	for child in node.get_children():
		_shader_materials_with_suffix_recursive(child, suffixes, materials, seen)


func _append_matching_shader_material(
	material: Material,
	suffixes: Array[String],
	materials: Array[ShaderMaterial],
	seen: Dictionary
) -> void:
	var current := material
	while current != null:
		var shader_material := current as ShaderMaterial
		if shader_material != null and shader_material.shader != null:
			var instance_id := shader_material.get_instance_id()
			if not seen.has(instance_id):
				for suffix in suffixes:
					if shader_material.shader.resource_path.ends_with(suffix):
						seen[instance_id] = true
						materials.append(shader_material)
						break
		current = current.next_pass


func _gel_v8_preservation_error(by_family: Dictionary) -> String:
	var unit := by_family.get("T") as Node
	if unit == null:
		return "Explicit V8 rollback contract requires CHAR-BASE-T"
	var animator := unit.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animator != null and animator.callback_mode_method != AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_DEFERRED:
		return "Explicit V8 must preserve the scene's deferred method callback mode"
	if bool(unit.call("request_combat_action", 8001, &"basic", &"BASIC-T", 0.0)):
		return "Explicit V8 must not enable V8.1 tokenized combat presentation"
	if int(unit.call("liquid_attachment_material_count")) != 0:
		return "Explicit V8 must not bind V8.1 attachment deformation materials"
	if unit.get_node_or_null("WeaponSocket/LiquidReleaseAnchor") != null:
		return "Explicit V8 must preserve the legacy WeaponSocket hierarchy"
	var materials := _shader_materials_with_suffix(unit, [
		"wet_gel.gdshader", "jelly_shell.gdshader", "gel_eye.gdshader",
	])
	for material in materials:
		var body_space: Variant = material.get_shader_parameter("liquid_body_space_enabled")
		var turn: Variant = material.get_shader_parameter("liquid_turn_shear")
		var contact: Variant = material.get_shader_parameter("liquid_contact_amount")
		if body_space != null and not is_zero_approx(float(body_space)):
			return "Explicit V8 must keep V8.1 body-space attachment deformation disabled"
		if turn != null and not is_zero_approx(float(turn)):
			return "Explicit V8 must keep V8.1 turn shear disabled"
		if contact != null and not is_zero_approx(float(contact)):
			return "Explicit V8 must keep V8.1 contact response disabled"
	return ""


func _has_wet_gel_mesh(node: Node) -> bool:
	return _find_wet_gel_material(node) != null


func _gel_membrane_error(gel: ShaderMaterial) -> String:
	var membrane := gel.next_pass as ShaderMaterial
	if membrane == null or membrane.shader == null:
		return "must attach a clear membrane next pass"
	if not membrane.shader.resource_path.ends_with("jelly_shell.gdshader"):
		return "must use the Compatibility-safe clear membrane shader"
	var energy_error := _gel_shell_energy_error(membrane)
	if not energy_error.is_empty():
		return energy_error
	if float(membrane.get_shader_parameter("shell_thickness")) <= 0.0:
		return "membrane must expand beyond the wet-gel core"
	if float(membrane.get_shader_parameter("face_alpha")) > 0.03:
		return "membrane face alpha must not wash out the gel core"
	return ""


func _gel_shell_energy_error(shell: ShaderMaterial) -> String:
	if _GelProfiles.gummy_glass_enabled():
		return _gel_v7_shell_error(shell)
	if _GelProfiles.banner_match_enabled():
		return _gel_banner_shell_error(shell)
	for required_parameter in [
		"shell_energy_scale",
		"shell_diffuse_strength",
		"shell_specular_level",
		"shell_emission_limit",
		"shell_alpha_limit",
	]:
		if shell.get_shader_parameter(required_parameter) == null:
			return "clear membrane must expose the V5 energy bounds"
	var shell_energy := float(shell.get_shader_parameter("shell_energy_scale"))
	var shell_diffuse := float(shell.get_shader_parameter("shell_diffuse_strength"))
	var shell_specular := float(shell.get_shader_parameter("shell_specular_level"))
	var shell_emission := float(shell.get_shader_parameter("shell_emission_limit"))
	var shell_alpha := float(shell.get_shader_parameter("shell_alpha_limit"))
	if shell_energy < 0.40 or shell_energy > 0.44:
		return "clear membrane edge energy must stay in the accepted V5.3 window"
	if shell_diffuse < 0.16 or shell_diffuse > 0.20:
		return "clear membrane diffuse tint must stay in the accepted V5.3 window"
	if shell_specular < 0.46 or shell_specular > 0.50:
		return "clear membrane specular must stay in the accepted V5.3 window"
	if shell_emission < 0.020 or shell_emission > 0.030:
		return "clear membrane emission must stay in the accepted V5.3 anti-neon window"
	if shell_alpha < 0.27 or shell_alpha > 0.29:
		return "clear membrane alpha must stay in the accepted V5.3 boundary window"
	return ""


func _gel_v7_shell_error(shell: ShaderMaterial) -> String:
	var expected := {
		"shell_energy_scale": 0.74,
		"shell_diffuse_strength": 0.045,
		"shell_specular_level": 0.86,
		"shell_emission_limit": 0.075,
		"shell_alpha_limit": 0.46,
		"shell_white_mix": 0.38,
		"studio_reflection_strength": 0.52,
		"studio_reflection_alpha": 0.055,
		"studio_reflection_budget": 0.075,
		"studio_streak_strength": 0.62,
	}
	for parameter in expected:
		if shell.get_shader_parameter(parameter) == null:
			return "V7 clear membrane must expose %s" % parameter
		if not is_equal_approx(float(shell.get_shader_parameter(parameter)), float(expected[parameter])):
			return "V7 clear membrane %s drifted from its additive profile" % parameter
	var face_alpha := float(shell.get_shader_parameter("face_alpha"))
	if face_alpha < 0.0029 or face_alpha > 0.0041:
		return "V7 authored membrane face alpha must preserve the clear core"
	var edge_alpha := float(shell.get_shader_parameter("edge_alpha"))
	if edge_alpha < 0.549 or edge_alpha > 0.561:
		return "V7 authored membrane edge alpha drifted"
	return ""


func _gel_banner_shell_error(shell: ShaderMaterial) -> String:
	for required_parameter in [
		"shell_energy_scale",
		"shell_diffuse_strength",
		"shell_specular_level",
		"shell_emission_limit",
		"shell_alpha_limit",
		"shell_white_mix",
		"studio_reflection_strength",
		"studio_reflection_alpha",
		"studio_reflection_budget",
	]:
		if shell.get_shader_parameter(required_parameter) == null:
			return "V6 clear membrane must expose its banner-match energy controls"
	if not is_equal_approx(float(shell.get_shader_parameter("shell_energy_scale")), 0.68):
		return "V6 clear membrane energy must remain at the reviewed banner-match value"
	if not is_equal_approx(float(shell.get_shader_parameter("shell_diffuse_strength")), 0.07):
		return "V6 clear membrane diffuse tint must remain subordinate to reflection"
	if not is_equal_approx(float(shell.get_shader_parameter("shell_specular_level")), 0.78):
		return "V6 clear membrane specular must preserve the wet dielectric response"
	if not is_equal_approx(float(shell.get_shader_parameter("shell_emission_limit")), 0.065):
		return "V6 clear membrane emission must keep its Compatibility-safe ceiling"
	if not is_equal_approx(float(shell.get_shader_parameter("shell_alpha_limit")), 0.40):
		return "V6 clear membrane alpha must keep the reviewed silhouette boundary"
	if not is_equal_approx(float(shell.get_shader_parameter("shell_white_mix")), 0.28):
		return "V6 clear membrane must retain the colourless outer-film cue"
	if not is_equal_approx(float(shell.get_shader_parameter("studio_reflection_strength")), 0.42):
		return "V6 clear membrane must retain its analytic softbox reflection"
	if not is_equal_approx(float(shell.get_shader_parameter("studio_reflection_alpha")), 0.045):
		return "V6 clear membrane softbox alpha drifted"
	if not is_equal_approx(float(shell.get_shader_parameter("studio_reflection_budget")), 0.065):
		return "V6 clear membrane softbox energy exceeded its reviewed budget"
	return ""


func _gel_surface_noise_error(gel: ShaderMaterial) -> String:
	if not _GelProfiles.v8_enabled():
		var legacy_motion_error := _gel_legacy_liquid_motion_error(gel)
		if not legacy_motion_error.is_empty():
			return legacy_motion_error
	if _GelProfiles.v8_enabled():
		return _gel_v8_surface_error(gel)
	if _GelProfiles.v7_enabled():
		return _gel_v7_surface_error(gel)
	if _GelProfiles.banner_match_enabled():
		return _gel_banner_surface_error(gel)
	var light_semantics_error := _gel_light_semantics_error(gel)
	if not light_semantics_error.is_empty():
		return light_semantics_error
	for required_parameter in [
		"body_exposure_scale",
		"core_glow",
		"interior_budget",
		"thin_budget_scale",
		"thickness_contrast",
		"thickness_power",
		"membrane_depth_cap",
		"membrane_grazing_floor",
		"membrane_grazing_power",
		"membrane_irregularity",
		"wet_spec_breakup",
		"coat_tint",
		"detail_emission_scale",
		"authored_height_tex",
		"authored_height_enabled",
		"authored_height_scale",
		"authored_height_depth",
		"authored_height_blend",
		"authored_height_lod_bias",
	]:
		if gel.get_shader_parameter(required_parameter) == null:
			return "must expose the V5 body response controls"
	var body_exposure_value: Variant = gel.get_shader_parameter("body_exposure_scale")
	var body_exposure_scale := float(body_exposure_value)
	if body_exposure_scale < 0.86 or body_exposure_scale > 0.92:
		return "V5.3 body exposure must preserve midtone and deep-core separation"
	var core_glow := float(gel.get_shader_parameter("core_glow"))
	if core_glow < 0.42 or core_glow > 0.46:
		return "V5.3 base-pass volume fill must stay inside the measured core/ribbon window"
	var interior_budget := float(gel.get_shader_parameter("interior_budget"))
	if interior_budget < 0.58 or interior_budget > 0.62:
		return "V5.3 interior budget must remain below the zero-light readability ceiling"
	var thin_budget_scale := float(gel.get_shader_parameter("thin_budget_scale"))
	if thin_budget_scale < 0.82 or thin_budget_scale > 0.86:
		return "V5.3 thin-part ceiling is outside the non-neon transmission range"
	var thickness_contrast := float(gel.get_shader_parameter("thickness_contrast"))
	if thickness_contrast < 0.04 or thickness_contrast > 0.14:
		return "V5 macro thickness contrast is outside the restrained gel range"
	var thickness_power := float(gel.get_shader_parameter("thickness_power"))
	if thickness_power < 0.80 or thickness_power > 1.60:
		return "V5 macro thickness power is outside the coherent body-gradient range"
	var membrane_depth_cap := float(gel.get_shader_parameter("membrane_depth_cap"))
	if membrane_depth_cap < 0.008 or membrane_depth_cap > 0.018:
		return "V5 membrane depth cap must prevent crystalline full-body quilting"
	var membrane_grazing_floor := float(gel.get_shader_parameter("membrane_grazing_floor"))
	if membrane_grazing_floor < 0.04 or membrane_grazing_floor > 0.18:
		return "V5 membrane variation must concentrate at grazing angles"
	var membrane_grazing_power := float(gel.get_shader_parameter("membrane_grazing_power"))
	if membrane_grazing_power < 0.90 or membrane_grazing_power > 2.00:
		return "V5 membrane grazing power must keep face-on interiors smooth"
	var membrane_irregularity := float(gel.get_shader_parameter("membrane_irregularity"))
	if membrane_irregularity < 0.55:
		return "V5 membrane cells must use organic amplitude breakup"
	var wet_spec_breakup := float(gel.get_shader_parameter("wet_spec_breakup"))
	if wet_spec_breakup < 0.06 or wet_spec_breakup > 0.12:
		return "V5.3 wet specular breakup is outside the smooth-gel range"
	var coat_tint := float(gel.get_shader_parameter("coat_tint"))
	if coat_tint < 0.08 or coat_tint > 0.30:
		return "V5 tight wet highlight must stay restrained and family-tinted"
	if float(gel.get_shader_parameter("detail_emission_scale")) > 0.35:
		return "V5 detail emission exceeds the non-neon ceiling"
	if gel.get_shader_parameter("authored_height_enabled") != true:
		return "V5.1 must enable its mipmapped authored height"
	var authored_height := gel.get_shader_parameter("authored_height_tex") as Texture2D
	if authored_height == null:
		return "V5.1 authored height texture is missing"
	if authored_height.resource_path != "res://characters/gel/jelly_micro_height.png":
		return "V5.1 authored height must use the reproducible production resource"
	if authored_height.get_width() != 512 or authored_height.get_height() != 512:
		return "V5.1 authored height must remain 512x512"
	var authored_image := authored_height.get_image()
	if authored_image == null or not authored_image.has_mipmaps():
		return "V5.1 authored height import must generate mipmaps"
	var authored_scale := float(gel.get_shader_parameter("authored_height_scale"))
	if authored_scale < 0.40 or authored_scale > 0.50:
		return "V5.1 authored height scale is outside the enlarged-pebble window"
	var authored_depth := float(gel.get_shader_parameter("authored_height_depth"))
	if authored_depth < 0.0010 or authored_depth > 0.0020:
		return "V5.3 authored height depth is outside the smooth wet-skin window"
	var authored_blend := float(gel.get_shader_parameter("authored_height_blend"))
	if authored_blend < 1.5 or authored_blend > 2.5:
		return "V5.1 triplanar blend is outside the seam-safe window"
	var authored_lod_bias := float(gel.get_shader_parameter("authored_height_lod_bias"))
	if authored_lod_bias < 0.25 or authored_lod_bias > 0.55:
		return "V5.1 height mip bias is outside the motion-stable window"
	if gel.get_shader_parameter("microbubble_enabled") == true:
		return "V5.1 must not re-enable the rejected spherical microbubble normal path"
	if gel.get_shader_parameter("inclusion_enabled") == true:
		return "V5.1 must not re-enable the rejected procedural island path"
	for retired_parameter in [
		"bubble_depth",
		"bubble_emission",
		"bubble_shell_emission",
		"microbubble_depth",
		"microbubble_emission",
		"microbubble_shell_emission",
		"inclusion_depth",
		"inclusion_emission",
	]:
		if not is_zero_approx(float(gel.get_shader_parameter(retired_parameter))):
			return "V5.1 retired circular/island detail must remain disabled"
	return ""


func _gel_legacy_liquid_motion_error(gel: ShaderMaterial) -> String:
	for parameter in [
		"liquid_flow_strength",
		"liquid_flow_idle_speed",
		"liquid_flow_move_boost",
		"liquid_flow_advection",
		"liquid_flow_warp",
		"liquid_flow_emission",
		"liquid_flow_budget",
		"liquid_flow_phase",
		"liquid_flow_motion_mix",
		"liquid_slime_strength",
		"liquid_slime_thinness",
		"liquid_body_deform_strength",
		"liquid_body_squash",
	]:
		if gel.get_shader_parameter(parameter) == null:
			return "preserved gel looks must expose the inert V8 %s control" % parameter
		if not is_zero_approx(float(gel.get_shader_parameter(parameter))):
			return "V5/V6/V7 must keep V8 liquid motion disabled at %s" % parameter
	return ""


func _gel_v8_surface_error(gel: ShaderMaterial) -> String:
	var light_semantics_error := _gel_light_semantics_error(gel)
	if not light_semantics_error.is_empty():
		return light_semantics_error
	var expected := {
		# Optical response stays on the exact V7 foundation. Only the suspended
		# detail density is reduced so broad V8 slime folds dominate the read.
		"body_exposure_scale": 0.76,
		"core_glow": 0.14,
		"interior_budget": 0.30,
		"thickness_contrast": 0.32,
		"studio_reflection_strength": 0.74,
		"studio_reflection_budget": 0.32,
		"studio_streak_strength": 0.72,
		"authored_fleck_strength": 0.18,
		"authored_fleck_budget": 0.050,
		"authored_inclusion_strength": 0.30,
		"authored_inclusion_thinness": 0.060,
		"authored_inclusion_budget": 0.070,
		"authored_caustic_strength": 0.20,
		"authored_caustic_budget": 0.040,
		"authored_fiber_strength": 0.30,
		"authored_fiber_scale": 0.18,
		"authored_fiber_threshold": 0.30,
		"authored_fiber_width": 0.016,
		"authored_fiber_thinness": 0.035,
		"authored_fiber_budget": 0.070,
		"authored_fiber_lod_bias": 0.22,
		"liquid_flow_strength": 0.78,
		"liquid_flow_idle_speed": 0.21,
		"liquid_flow_move_boost": 0.50,
		"liquid_flow_advection": 0.25,
		"liquid_flow_warp": 0.14,
		"liquid_flow_emission": 0.46,
		"liquid_flow_budget": 0.070,
		"liquid_flow_motion_mix": 0.0,
		"liquid_slime_strength": 0.94,
		"liquid_slime_scale": 0.92,
		"liquid_slime_threshold": 0.49,
		"liquid_slime_softness": 0.14,
		"liquid_slime_thinness": 0.15,
		"liquid_body_deform_strength": 0.82,
	}
	for parameter in expected:
		if gel.get_shader_parameter(parameter) == null:
			return "V8 living-liquid body must expose %s" % parameter
		if not is_equal_approx(float(gel.get_shader_parameter(parameter)), float(expected[parameter])):
			return "V8 living-liquid body %s drifted from its additive profile" % parameter
	var phase := float(gel.get_shader_parameter("liquid_flow_phase"))
	if phase <= 0.0 or phase >= TAU:
		return "V8 family phase must remain deterministic and inside one cycle"
	if gel.get_shader_parameter("authored_height_enabled") != true:
		return "V8 must retain the mipmapped authored texture source"
	var authored_height := gel.get_shader_parameter("authored_height_tex") as Texture2D
	if authored_height == null or authored_height.resource_path != "res://characters/gel/jelly_micro_height.png":
		return "V8 must reuse the reproducible CC0 authored height resource"
	var authored_image := authored_height.get_image()
	if authored_image == null or not authored_image.has_mipmaps():
		return "V8 authored detail must retain generated mipmaps"
	for retired_parameter in [
		"bubble_depth",
		"bubble_emission",
		"bubble_shell_emission",
		"microbubble_depth",
		"microbubble_emission",
		"microbubble_shell_emission",
		"inclusion_depth",
		"inclusion_emission",
	]:
		if not is_zero_approx(float(gel.get_shader_parameter(retired_parameter))):
			return "V8 must not re-enable retired procedural sphere/island relief"
	var shader_source := gel.shader.code
	if not shader_source.contains("TIME * ("):
		return "V8 idle liquid flow must be driven by an uninterrupted shader clock"
	if not shader_source.contains("liquid_sample_position"):
		return "V8 must advect the internal authored inclusion coordinates"
	if not shader_source.contains("liquid_slime_volume"):
		return "V8 must retain its low-frequency cohesive slime field"
	if not shader_source.contains("liquid_body_lag"):
		return "V8 must retain direction-aware viscous vertex lag"
	if shader_source.contains("hint_screen_texture"):
		return "V8 liquid motion must remain Compatibility/Web safe"
	return ""


func _gel_v7_surface_error(gel: ShaderMaterial) -> String:
	var light_semantics_error := _gel_light_semantics_error(gel)
	if not light_semantics_error.is_empty():
		return light_semantics_error
	var expected := {
		"body_exposure_scale": 0.76,
		"core_glow": 0.14,
		"interior_budget": 0.30,
		"thickness_contrast": 0.32,
		"authored_fleck_strength": 0.38,
		"authored_inclusion_strength": 0.44,
		"authored_caustic_strength": 0.32,
		"authored_caustic_width": 0.014,
		"authored_fiber_strength": 0.58,
		"authored_fiber_scale": 0.18,
		"authored_fiber_threshold": 0.30,
		"authored_fiber_width": 0.016,
		"authored_fiber_thinness": 0.055,
		"authored_fiber_budget": 0.105,
		"authored_fiber_lod_bias": 0.22,
		"studio_reflection_strength": 0.74,
		"studio_reflection_budget": 0.32,
		"studio_streak_strength": 0.72,
	}
	for parameter in expected:
		if gel.get_shader_parameter(parameter) == null:
			return "V7 gummy-glass body must expose %s" % parameter
		if not is_equal_approx(float(gel.get_shader_parameter(parameter)), float(expected[parameter])):
			return "V7 gummy-glass body %s drifted from its additive profile" % parameter
	if gel.get_shader_parameter("authored_height_enabled") != true:
		return "V7 must retain the mipmapped authored texture source"
	var authored_height := gel.get_shader_parameter("authored_height_tex") as Texture2D
	if authored_height == null or authored_height.resource_path != "res://characters/gel/jelly_micro_height.png":
		return "V7 must reuse the reproducible CC0 authored height resource"
	var authored_image := authored_height.get_image()
	if authored_image == null or not authored_image.has_mipmaps():
		return "V7 authored detail must retain generated mipmaps"
	for retired_parameter in [
		"bubble_depth",
		"bubble_emission",
		"bubble_shell_emission",
		"microbubble_depth",
		"microbubble_emission",
		"microbubble_shell_emission",
		"inclusion_depth",
		"inclusion_emission",
	]:
		if not is_zero_approx(float(gel.get_shader_parameter(retired_parameter))):
			return "V7 must not re-enable retired procedural sphere/island relief"
	var shader_source := gel.shader.code
	if not shader_source.contains("authored_fiber_signal"):
		return "V7 must retain the anisotropic object-space fiber signal"
	if not shader_source.contains("studio_streak_strength"):
		return "V7 must retain the Compatibility-safe long reflection card"
	if shader_source.contains("hint_screen_texture"):
		return "V7 must remain independent of screen-texture refraction"
	return ""


func _gel_banner_surface_error(gel: ShaderMaterial) -> String:
	var light_semantics_error := _gel_light_semantics_error(gel)
	if not light_semantics_error.is_empty():
		return light_semantics_error
	for required_parameter in [
		"body_exposure_scale",
		"core_glow",
		"interior_budget",
		"thickness_contrast",
		"studio_reflection_strength",
		"studio_reflection_budget",
		"authored_fleck_strength",
		"authored_fleck_threshold",
		"authored_fleck_budget",
		"authored_inclusion_strength",
		"authored_inclusion_scale",
		"authored_inclusion_threshold",
		"authored_inclusion_thinness",
		"authored_inclusion_budget",
		"authored_caustic_strength",
		"authored_caustic_threshold",
		"authored_caustic_width",
		"authored_caustic_budget",
	]:
		if gel.get_shader_parameter(required_parameter) == null:
			return "must expose the V6 banner-match body controls"
	if not is_equal_approx(float(gel.get_shader_parameter("body_exposure_scale")), 0.82):
		return "V6 body exposure must preserve the reviewed deep-core separation"
	if not is_equal_approx(float(gel.get_shader_parameter("core_glow")), 0.22):
		return "V6 core fill must remain below the self-lit V5 look"
	if not is_equal_approx(float(gel.get_shader_parameter("interior_budget")), 0.38):
		return "V6 interior budget drifted from the reviewed banner match"
	if not is_equal_approx(float(gel.get_shader_parameter("thickness_contrast")), 0.24):
		return "V6 macro thickness must retain its deeper optical core"
	if not is_equal_approx(float(gel.get_shader_parameter("studio_reflection_strength")), 0.66):
		return "V6 body must retain its analytic softbox reflection"
	if not is_equal_approx(float(gel.get_shader_parameter("studio_reflection_budget")), 0.28):
		return "V6 body softbox reflection exceeded its reviewed budget"
	if not is_equal_approx(float(gel.get_shader_parameter("authored_fleck_strength")), 0.56):
		return "V6 fine internal flecks drifted from the reviewed density"
	if not is_equal_approx(float(gel.get_shader_parameter("authored_fleck_threshold")), 0.31):
		return "V6 fine internal fleck threshold drifted"
	if not is_equal_approx(float(gel.get_shader_parameter("authored_fleck_budget")), 0.14):
		return "V6 fine internal flecks exceeded their energy budget"
	if not is_equal_approx(float(gel.get_shader_parameter("authored_inclusion_strength")), 0.34):
		return "V6 coarse inclusions drifted from the reviewed strength"
	if not is_equal_approx(float(gel.get_shader_parameter("authored_inclusion_scale")), 0.13):
		return "V6 coarse inclusion scale drifted"
	if not is_equal_approx(float(gel.get_shader_parameter("authored_inclusion_threshold")), 0.23):
		return "V6 coarse inclusion threshold drifted"
	if not is_equal_approx(float(gel.get_shader_parameter("authored_inclusion_thinness")), 0.08):
		return "V6 coarse inclusions must continue to reveal optical depth"
	if not is_equal_approx(float(gel.get_shader_parameter("authored_inclusion_budget")), 0.085):
		return "V6 coarse inclusions exceeded their energy budget"
	if not is_equal_approx(float(gel.get_shader_parameter("authored_caustic_strength")), 0.58):
		return "V6 folded internal caustic cue drifted from the reviewed strength"
	if not is_equal_approx(float(gel.get_shader_parameter("authored_caustic_threshold")), 0.255):
		return "V6 internal caustic threshold drifted"
	if not is_equal_approx(float(gel.get_shader_parameter("authored_caustic_width")), 0.020):
		return "V6 internal caustic width must remain motion-stable"
	if not is_equal_approx(float(gel.get_shader_parameter("authored_caustic_budget")), 0.095):
		return "V6 internal caustics exceeded their energy budget"
	if gel.get_shader_parameter("authored_height_enabled") != true:
		return "V6 must keep the mipmapped authored texture source"
	var authored_height := gel.get_shader_parameter("authored_height_tex") as Texture2D
	if authored_height == null or authored_height.resource_path != "res://characters/gel/jelly_micro_height.png":
		return "V6 must use the reproducible authored height resource"
	var authored_image := authored_height.get_image()
	if authored_image == null or not authored_image.has_mipmaps():
		return "V6 authored detail texture must retain generated mipmaps"
	for retired_parameter in [
		"bubble_depth",
		"bubble_emission",
		"bubble_shell_emission",
		"microbubble_depth",
		"microbubble_emission",
		"microbubble_shell_emission",
		"inclusion_depth",
		"inclusion_emission",
	]:
		if not is_zero_approx(float(gel.get_shader_parameter(retired_parameter))):
			return "V6 must not re-enable rejected circular procedural stamps"
	var shader_source := gel.shader.code
	if not shader_source.contains("authored_inclusion_signal"):
		return "V6 must retain the mip-stable coarse inclusion signal"
	if not shader_source.contains("authored_caustic_glow"):
		return "V6 must retain the object-space folded caustic cue"
	if not shader_source.contains("studio_reflection_strength"):
		return "V6 must retain the Compatibility-safe analytic softbox"
	return ""


func _gel_light_semantics_error(gel: ShaderMaterial) -> String:
	if gel == null or gel.shader == null:
		return "must expose the wet-gel shader for the V5 light contract"
	if gel.get_shader_parameter("direct_light_budget_share") == null:
		return "must expose the per-light V5 composite-energy share"
	var shader_source := gel.shader.code
	if shader_source.contains("DIFFUSE_LIGHT = peak_limit("):
		return "must not treat DIFFUSE_LIGHT as a cross-pass running total"
	if shader_source.contains("ALBEDO * front"):
		return "must not multiply direct body colour before Godot applies ALBEDO"
	if not shader_source.contains("ALBEDO = vec3(1.0)"):
		return "must use identity engine ALBEDO with the ambient-disabled custom light"
	if not shader_source.contains("ambient_light_disabled"):
		return "identity engine ALBEDO requires the custom gel path to disable ambient light"
	if not shader_source.contains("v_surface_color * front"):
		return "custom gel diffuse must preserve the authored body and ink colour explicitly"
	if not shader_source.contains("DIFFUSE_LIGHT += peak_limit("):
		return "must add one independently bounded contribution per direct light"
	if not shader_source.contains("authored_height_triplanar"):
		return "V5.1 must project its authored height independently of mesh UVs"
	if not shader_source.contains("authored_height_depth * authored_grazing"):
		return "V5.1 authored relief must stay concentrated at grazing angles"
	if not shader_source.contains("filter_linear_mipmap_anisotropic") or not shader_source.contains("repeat_enable"):
		return "V5.1 authored height sampler must be repeatable and mip-filtered"
	if shader_source.count("textureGrad(\n\t\tauthored_height_tex") != 3:
		return "V5.1 triplanar height must use three explicitly filtered plane samples"
	if shader_source.contains("textureLod(authored_height_tex"):
		return "V5.1 authored height must not pin a fixed mip level"
	var direct_light_budget_share := float(gel.get_shader_parameter("direct_light_budget_share"))
	if direct_light_budget_share < 0.09 or direct_light_budget_share > 0.105:
		return "per-light V5 energy share must stay inside the measured Compatibility window"
	return ""


func _authored_jelly_error(unit: Node, family: String) -> String:
	var real_mesh := unit.get_node_or_null("CoreMesh/RealMesh") as Node3D
	if real_mesh == null or unit.get("real_mesh") == null:
		return "CHAR-BASE-%s must realize its zero-credit authored jelly body" % family
	var face := unit.get_node_or_null("Face") as Node3D
	var limbs := unit.get_node_or_null("LimbKit") as Node3D
	if face == null or face.visible or limbs == null or limbs.visible:
		return "CHAR-BASE-%s authored body must replace the procedural face and limbs" % family
	var weapon_socket := unit.get_node_or_null("WeaponSocket") as Node3D
	if weapon_socket == null:
		return "CHAR-BASE-%s authored body missing WeaponSocket" % family
	if _GelProfiles.v8_1_enabled():
		if weapon_socket.get_child_count() != 1 or weapon_socket.get_node_or_null("LiquidReleaseAnchor") == null:
			return "CHAR-BASE-%s V8.1 WeaponSocket must contain only its liquid release anchor" % family
	elif weapon_socket.get_child_count() != 0:
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
	var mesh_error := _shared_authored_sphere_error(
		body, shell, "CHAR-BASE-%s body and membrane" % family
	)
	if not mesh_error.is_empty():
		return mesh_error
	for authored_path in ["EyeL", "EyeR", "MouthCavity"]:
		if real_mesh.get_node_or_null(authored_path) == null:
			return "CHAR-BASE-%s authored body missing %s" % [family, authored_path]
	var runtime_gel := body.material_override as ShaderMaterial
	if runtime_gel == null or runtime_gel.get_shader_parameter("bubble_enabled") != true:
		return "CHAR-BASE-%s authored body must keep its Fizzy bubble material" % family
	if runtime_gel.get_shader_parameter("authored_height_enabled") != true:
		return "CHAR-BASE-%s authored V5.1 profile must keep the mipmapped height" % family
	var noise_error := _gel_surface_noise_error(runtime_gel)
	if not noise_error.is_empty():
		return "CHAR-BASE-%s %s" % [family, noise_error]
	if _GelProfiles.v8_enabled():
		if not unit.has_method("update_liquid_flow") or not unit.has_method("liquid_material_count"):
			return "CHAR-BASE-%s V8 must expose its runtime liquid-flow bridge" % family
		if int(unit.call("liquid_material_count")) <= 0:
			return "CHAR-BASE-%s V8 must discover its per-instance wet-gel materials" % family
		if not unit.has_method("liquid_shell_material_count") or int(unit.call("liquid_shell_material_count")) <= 0:
			return "CHAR-BASE-%s V8 must bind viscosity to its clear membrane" % family
		var collision := unit.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision == null or collision.shape == null:
			return "CHAR-BASE-%s V8 must retain its stable gameplay collision" % family
		var collision_transform := collision.transform
		var collision_shape := collision.shape
		unit.call("update_liquid_flow", Vector3(3.0, 0.0, 0.0), 0.5)
		var moving_mix := float(runtime_gel.get_shader_parameter("liquid_flow_motion_mix"))
		var moving_direction := runtime_gel.get_shader_parameter("liquid_flow_direction") as Vector3
		var moving_lag := runtime_gel.get_shader_parameter("liquid_body_lag") as Vector3
		var moving_squash := float(runtime_gel.get_shader_parameter("liquid_body_squash"))
		if moving_mix < 0.72:
			return "CHAR-BASE-%s V8 walking must smoothly raise the liquid-motion overlay" % family
		if moving_direction.x < 0.70:
			return "CHAR-BASE-%s V8 liquid flow must follow local walking direction" % family
		if moving_lag.x > -0.003 or moving_squash <= 0.004:
			return "CHAR-BASE-%s V8 visible mass must lag and compress like viscous liquid" % family
		for settle_step in 120:
			unit.call("update_liquid_flow", Vector3.ZERO, 1.0 / 60.0)
		var resting_mix := float(runtime_gel.get_shader_parameter("liquid_flow_motion_mix"))
		var resting_lag := runtime_gel.get_shader_parameter("liquid_body_lag") as Vector3
		var resting_squash := float(runtime_gel.get_shader_parameter("liquid_body_squash"))
		if resting_mix >= 0.12 or resting_mix < 0.0:
			return "CHAR-BASE-%s V8 liquid overlay must decay smoothly back to idle" % family
		if resting_lag.length() >= 0.012 or resting_squash >= 0.008:
			return "CHAR-BASE-%s V8 visible mass must settle without a residual wobble" % family
		if (
			not collision.transform.is_equal_approx(collision_transform)
			or collision.shape != collision_shape
		):
			return "CHAR-BASE-%s V8 visual viscosity must not deform gameplay collision" % family
	var shell_material := shell.material_override as ShaderMaterial
	if shell_material == null or shell_material.shader == null or not shell_material.shader.resource_path.ends_with("jelly_shell.gdshader"):
		return "CHAR-BASE-%s authored body must keep its clear membrane" % family
	var shell_error := _gel_shell_energy_error(shell_material)
	if not shell_error.is_empty():
		return "CHAR-BASE-%s %s" % [family, shell_error]
	if _GelProfiles.v8_enabled():
		if not is_equal_approx(float(shell_material.get_shader_parameter("liquid_body_deform_strength")), 0.82):
			return "CHAR-BASE-%s V8 membrane must inherit the body deformation strength" % family
		var body_lag := runtime_gel.get_shader_parameter("liquid_body_lag") as Vector3
		var shell_lag := shell_material.get_shader_parameter("liquid_body_lag") as Vector3
		if not body_lag.is_equal_approx(shell_lag):
			return "CHAR-BASE-%s V8 wet core and clear shell must deform together" % family
	var expected_path := "res://characters/base_%s/reference_body.tscn" % family.to_lower()
	if family == "M":
		expected_path = "res://characters/base_m/authored_body.tscn"
	if not bool(unit.get("imported_preserves_materials")) or str(unit.get("imported_model_path")) != expected_path:
		return "CHAR-BASE-%s scene must lock its authored production adapter" % family
	for replacement_flag in ["imported_replaces_limbs", "imported_replaces_identity", "imported_replaces_bubbles", "imported_replaces_fixed_kit"]:
		if not bool(unit.get(replacement_flag)):
			return "CHAR-BASE-%s production adapter must lock %s" % [family, replacement_flag]
	if not _all_geometry_shadows_disabled(real_mesh):
		return "CHAR-BASE-%s authored body must not cast internal primitive shadows" % family
	if family == "A":
		if _GelProfiles.gummy_glass_enabled():
			if real_mesh.get_node_or_null("FootL") == null or real_mesh.get_node_or_null("FootR") == null:
				return "CHAR-BASE-A V7 body must preserve its banner lower lobes"
		elif real_mesh.get_node_or_null("FootL") != null or real_mesh.get_node_or_null("FootR") != null:
			return "CHAR-BASE-A V5/V6 body must preserve its footless hover silhouette"
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


func _shared_authored_sphere_error(
	body: MeshInstance3D, shell: MeshInstance3D, label: String
) -> String:
	if body.mesh == null or shell.mesh == null or body.mesh != shell.mesh:
		return "%s must share one cached mesh resource" % label
	if body.mesh is not SphereMesh:
		return "%s cached mesh must be SphereMesh" % label
	var sphere := body.mesh as SphereMesh
	if sphere.radial_segments != 96:
		return "%s cached SphereMesh must use radial_segments=96" % label
	if sphere.rings != 48:
		return "%s cached SphereMesh must use rings=48" % label
	if not is_equal_approx(sphere.radius, 0.5):
		return "%s cached SphereMesh must use radius=0.5" % label
	if not is_equal_approx(sphere.height, 1.0):
		return "%s cached SphereMesh must use height=1.0" % label
	if sphere.resource_name != "SharedSphere-96x48":
		return "%s cached SphereMesh must be named SharedSphere-96x48" % label
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
