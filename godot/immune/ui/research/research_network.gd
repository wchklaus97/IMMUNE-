extends Control

## Live HTML ?cover=1 research network, ported to Godot. Catalog IDs only.

const _Tokens := preload("res://ui/research/research_tokens.gd")
const _Look := preload("res://characters/family_look.gd")
const _Icons := preload("res://ui/research/icon_library.gd")
const _ResearchMap = preload("res://ui/research/research_map.gd")
const _FamilyRow = preload("res://ui/research/family_row.gd")
const _Responsive := preload("res://ui/responsive_layout.gd")

const LEFT_FAMILIES: PackedStringArray = ["T", "M", "N"]
const RIGHT_FAMILIES: PackedStringArray = ["B", "A", "D"]

var _map: _ResearchMap
var _family_bars: Dictionary = {}
var _resource_value: Label
var _resource_sub: Label
var _resource_rows: Dictionary = {}
var _campaign_chip: Label
var _detail_panel: PanelContainer
var _detail_title: Label
var _detail_body: Label
var _detail_status: Label
var _detail_meta: Label
var _detail_effects: Label
var _detail_cost: Label
var _research_btn: Button
var _track_btn: Button
var _toast: Label
var _progress_label: Label
var _locale_applied := ""
var _safe_margin: MarginContainer
var _safe_content: Control
var _title_bar: Control
var _left_cards: Control
var _right_cards: Control
var _bottom_hud: GridContainer
var _resource_panel: PanelContainer
var _camera_column: VBoxContainer
var _camera_buttons: Array[Button] = []
var _layout_scale := 1.0
var _safe_insets := Vector4.ZERO

const STAT_LABEL := {
	"attackSpeed": "RESEARCH_STAT_ATTACK_SPEED",
	"moveSpeed": "RESEARCH_STAT_MOVE_SPEED",
	"cooldown": "RESEARCH_STAT_COOLDOWN",
	"coreRegen": "RESEARCH_STAT_CORE_REGEN",
	"unitRegen": "RESEARCH_STAT_UNIT_REGEN",
	"biomassYield": "RESEARCH_STAT_BIOMASS_YIELD",
	"critChance": "RESEARCH_STAT_CRIT_CHANCE",
	"weaknessAmp": "RESEARCH_STAT_WEAKNESS_AMP",
	"armorShred": "RESEARCH_STAT_ARMOR_SHRED",
	"enemySlow": "RESEARCH_STAT_ENEMY_SLOW",
	"pathSlow": "RESEARCH_STAT_PATH_SLOW",
}

const DOMAIN_LABEL := {
	"DEF": "RESEARCH_DOMAIN_DEF",
	"EXP": "RESEARCH_DOMAIN_EXP",
	"WAR": "RESEARCH_DOMAIN_WAR",
	"MOB": "RESEARCH_DOMAIN_MOB",
	"FUS": "RESEARCH_DOMAIN_FUS",
	"SUR": "RESEARCH_DOMAIN_SUR",
}

const STATUS_LABEL := {
	"標記": "RESEARCH_CHEMISTRY_MARK",
	"抗體": "RESEARCH_CHEMISTRY_ANTIBODY",
	"腐蝕": "RESEARCH_CHEMISTRY_CORROSION",
	"緩速": "RESEARCH_CHEMISTRY_SLOW",
	"感染": "RESEARCH_CHEMISTRY_INFECTION",
	"鏈鎖": "RESEARCH_CHEMISTRY_CHAIN",
	"暴擊": "RESEARCH_CHEMISTRY_CRITICAL",
}


func _ready() -> void:
	clip_contents = true
	set_anchors_preset(PRESET_FULL_RECT)
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_reset_ui()
	_build()
	_locale_applied = TranslationServer.get_locale()
	if not Engine.is_editor_hint():
		ResearchState.state_changed.connect(_refresh)
		ResearchState.node_completed.connect(_on_node_completed)
		SettingsState.settings_changed.connect(_on_settings_changed)
	_refresh()
	call_deferred("_home")
	WebQaBridge.publish(&"research_ready", {"nodes": Catalog.node_count()})
	if OS.get_cmdline_user_args().has("--release-smoke"):
		call_deferred("_run_release_smoke")
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.disconnect(_on_viewport_size_changed)


func _reset_ui() -> void:
	while get_child_count() > 0:
		var stale_child := get_child(0)
		remove_child(stale_child)
		stale_child.queue_free()
	_family_bars.clear()
	_resource_rows.clear()
	_camera_buttons.clear()


func _on_settings_changed() -> void:
	var next_locale := TranslationServer.get_locale()
	if next_locale == _locale_applied:
		return
	_locale_applied = next_locale
	_reset_ui()
	_build()
	_refresh()
	call_deferred("_home")


func _run_release_smoke() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var failures: PackedStringArray = []
	if Catalog.node_count() != 200:
		failures.append("catalog=%d" % Catalog.node_count())
	if _map == null or _progress_label == null or _research_btn == null:
		failures.append("research-ui-incomplete")
	if not ResourceLoader.exists("res://fonts/NotoSansHK-VF.ttf"):
		failures.append("font-missing")
	if not failures.is_empty():
		push_error("RELEASE_SMOKE_FAILED %s" % ",".join(failures))
		get_tree().quit(1)
		return
	print("RELEASE_SMOKE_OK platform=%s nodes=%d" % [OS.get_name(), Catalog.node_count()])
	get_tree().quit(0)


func _home() -> void:
	_map.cover_view()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"demo_home") or event.is_action_pressed(&"demo_back"):
		_map.cover_view()
	elif event.is_action_pressed(&"demo_track"):
		ResearchState.toggle_track(ResearchState.selected_node_id)
	elif event.is_action_pressed(&"demo_research"):
		_try_research()
	elif event.is_action_pressed(&"demo_combat"):
		_enter_combat()


func _on_node_clicked(id: StringName) -> void:
	ResearchState.select_node(id)
	VfxLibrary.play_select(id, _map)
	_punch_detail()
	var node := Catalog.get_node_def(id)
	if str(node.get("kind", "")) == "character_anchor":
		_map.focus_id(id, 0.78)


func _on_node_completed(id: StringName) -> void:
	VfxLibrary.play_research(id, _map)
	_flash(tr("RESEARCH_UI_COMPLETE_TOAST"))
	_punch_resources()


func _focus_family(family: String) -> void:
	var anchor := StringName("CHAR-BASE-%s" % family)
	ResearchState.select_node(anchor)
	VfxLibrary.play_select(anchor, _map)
	_map.focus_id(anchor, 0.8)
	_punch_detail()


func _try_research() -> void:
	var id := ResearchState.selected_node_id
	if ResearchState.complete_node(id):
		return
	var runtime := ResearchState.derive_state(id)
	_flash(ResearchState.eligibility_label(runtime, Catalog.get_node_def(id)))
	_punch_detail()


func _punch_detail() -> void:
	if _detail_panel == null:
		return
	_detail_panel.modulate = Color(1.25, 1.18, 1.05)
	var tween := create_tween()
	tween.tween_property(_detail_panel, "modulate", Color.WHITE, 0.28)


func _punch_resources() -> void:
	for key in _resource_rows.keys():
		var row: Dictionary = _resource_rows[key]
		var value: Label = row.get("value")
		if value == null:
			continue
		value.modulate = _Tokens.CYAN
		var tween := create_tween()
		tween.tween_property(value, "modulate", Color.WHITE, 0.35)


func _flash(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.2)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _refresh() -> void:
	_progress_label.text = "%d/200" % ResearchState.completed_node_ids.size()
	var chapter := ResearchState.unlocked_campaign_level
	var chapter_name := Catalog.localized_campaign_level_name(chapter)
	if _campaign_chip:
		_campaign_chip.text = tr("RESEARCH_UI_CAMPAIGN_CHIP") % [chapter, chapter_name]
	_refresh_resources()
	var selected := Catalog.get_node_def(ResearchState.selected_node_id)
	var selected_families: Array = selected.get("familyIds", []) if not selected.is_empty() else []
	for family in _Tokens.FAMILY_ORDER:
		var row: Dictionary = _family_bars.get(family, {})
		if row.is_empty():
			continue
		var counts: Vector2i = Catalog.family_progress(family)
		(row.count as Label).text = "%d/%d" % [counts.x, counts.y]
		var icon: TextureRect = row.get("icon")
		if icon:
			var ladder: Vector2i = Catalog.family_ladder_progress(family)
			icon.texture = _Icons.atlas_for_family(family, _Icons.scan_level(ladder.x, ladder.y))
		var wrap: Control = row.get("wrap")
		if wrap:
			wrap.modulate = Color(1.18, 1.12, 1.04) if selected_families.has(family) else Color.WHITE
	_refresh_detail()


func _refresh_resources() -> void:
	var selected := Catalog.get_node_def(ResearchState.selected_node_id)
	var costs := ResearchState.cost_table(selected) if not selected.is_empty() else {}
	for key in ["antigen", "protomass", "fusionCore", "biomass"]:
		var have := int(ResearchState.resources.get(key, 0))
		if key == "antigen" and _resource_value:
			_resource_value.text = str(have)
		var row: Dictionary = _resource_rows.get(key, {})
		var value: Label = row.get("value")
		if value == null:
			continue
		value.text = str(have)
		var need := int(costs.get(key, 0))
		if need > 0 and have < need:
			value.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42))
		elif need > 0:
			value.add_theme_color_override("font_color", _Tokens.GOLD)
		else:
			value.add_theme_color_override("font_color", _Tokens.CYAN)
	if _resource_sub:
		_resource_sub.text = tr("RESEARCH_UI_RESOURCE_SUMMARY") % [
			int(ResearchState.resources.get("protomass", 0)),
			int(ResearchState.resources.get("fusionCore", 0)),
			int(ResearchState.resources.get("biomass", 0)),
		]


func _refresh_detail() -> void:
	var id := ResearchState.selected_node_id
	var node := Catalog.get_node_def(id)
	var runtime := ResearchState.derive_state(id)
	if node.is_empty():
		_detail_title.text = tr("RESEARCH_UI_SELECT_NODE")
		_detail_body.text = ""
		if _detail_meta:
			_detail_meta.text = ""
		if _detail_effects:
			_detail_effects.text = ""
		if _detail_cost:
			_detail_cost.text = ""
		return
	var hidden := str(runtime.get("visibility")) == "hidden"
	_detail_title.text = tr("RESEARCH_UI_UNKNOWN_NAME") if hidden else Catalog.localized_node_name(node)
	_detail_body.text = tr("RESEARCH_UI_UNKNOWN_DESCRIPTION") if hidden else Catalog.localized_node_description(node)
	if _detail_meta:
		_detail_meta.text = "" if hidden else _format_meta(node)
	if _detail_effects:
		_detail_effects.text = "" if hidden else _format_effects(node)
	if _detail_cost:
		_detail_cost.text = "" if hidden else _format_cost_line(node)
	var eligibility := str(runtime.get("eligibility", ""))
	_detail_status.text = ResearchState.eligibility_label(runtime, node)
	_research_btn.disabled = eligibility != "ready"
	_track_btn.text = tr("RESEARCH_UI_UNTRACK") if bool(runtime.get("tracked", false)) else tr("RESEARCH_UI_TRACK")


func _format_meta(node: Dictionary) -> String:
	var bits: PackedStringArray = []
	if str(node.get("route", "")) != "":
		bits.append(tr("RESEARCH_UI_TREE") % str(node.get("route")))
	var gate := _campaign_min(node)
	if gate != "":
		var name := Catalog.localized_campaign_level_name(gate)
		bits.append(tr("RESEARCH_UI_REQUIRES_UNLOCK") % [gate, name])
	elif str(node.get("levelLink", "")) != "":
		bits.append(tr("RESEARCH_UI_MISSION") % str(node.get("levelLink")))
	return " · ".join(bits)


func _campaign_min(node: Dictionary) -> String:
	for condition in node.get("conditions", []):
		if condition is Dictionary and str(condition.get("type", "")) == "campaign_level":
			return str(condition.get("min", ""))
	return ""


func _format_effects(node: Dictionary) -> String:
	var lines: PackedStringArray = []
	for op in node.get("effectOps", []):
		if not op is Dictionary:
			continue
		var text := _format_effect(op)
		if text != "":
			lines.append(text)
		if lines.size() >= 2:
			break
	return "  ·  ".join(lines)


func _format_effect(op: Dictionary) -> String:
	var kind := str(op.get("op", ""))
	if kind == "grant_global_stat":
		var stat := str(op.get("stat", ""))
		var label_key := str(STAT_LABEL.get(stat, ""))
		var label := tr(label_key) if label_key != "" else stat
		var amount := float(op.get("amount", 0.0))
		var shown := "%d" % int(amount) if absf(amount) >= 1.0 else "%d%%" % int(round(absf(amount) * 100.0))
		var sign := "−" if amount < 0.0 else "+"
		var duty := ""
		if str(op.get("duty", "")) == "fixed":
			duty = tr("RESEARCH_EFFECT_DUTY_FIXED")
		elif str(op.get("duty", "")) == "mobile":
			duty = tr("RESEARCH_EFFECT_DUTY_MOBILE")
		return "%s%s %s%s" % [label, duty, sign, shown]
	if kind == "grant_universal":
		var domain := str(op.get("domain", ""))
		var domain_key := str(DOMAIN_LABEL.get(domain, ""))
		var domain_label := tr(domain_key) if domain_key != "" else str(op.get("layer", domain))
		return tr("RESEARCH_EFFECT_UNLOCK_CORE_LAYER") % domain_label
	if kind == "grant_status_chemistry":
		var status := str(op.get("status", ""))
		var status_key := str(STATUS_LABEL.get(status, ""))
		return tr("RESEARCH_EFFECT_STRENGTHEN_STATUS") % (tr(status_key) if status_key != "" else status)
	if kind == "grant_mobility":
		return tr("RESEARCH_EFFECT_GRANT_MOBILE_DUTY")
	if kind == "grant_relay_qualification":
		return tr("RESEARCH_EFFECT_GRANT_FIXED_RELAY_DUTY")
	if kind == "grant_fixed_turret":
		return tr("RESEARCH_EFFECT_GRANT_FIXED_TURRET_DUTY")
	if kind == "grant_character_usage":
		return tr("RESEARCH_EFFECT_UNLOCK_DEPLOYMENT")
	return ""


func _format_cost_line(node: Dictionary) -> String:
	var costs := ResearchState.cost_table(node)
	if costs.is_empty():
		return tr("RESEARCH_COST_FREE")
	var bits: PackedStringArray = []
	for key in costs.keys():
		var need := int(costs[key])
		var have := int(ResearchState.resources.get(key, 0))
		var resource_key := str(_Tokens.RESOURCE_LABEL.get(key, ""))
		var label := tr(resource_key) if resource_key != "" else str(key)
		bits.append("%s %d／%d" % [label, need, have])
	return tr("RESEARCH_COST_PREFIX") % " · ".join(bits)


func _build() -> void:
	_map = _ResearchMap.new()
	_map.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_map.clip_contents = true
	if not Engine.is_editor_hint():
		_map.node_clicked.connect(_on_node_clicked)
	add_child(_map)
	_safe_margin = MarginContainer.new()
	_safe_margin.name = "ResearchSafeArea"
	_safe_margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_safe_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe_margin)
	_safe_content = Control.new()
	_safe_content.name = "ResearchSafeContent"
	_safe_content.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_safe_content.size_flags_horizontal = SIZE_EXPAND_FILL
	_safe_content.size_flags_vertical = SIZE_EXPAND_FILL
	_safe_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_margin.add_child(_safe_content)

	_title_bar = _make_title_bar()
	_title_bar.name = "ResearchTitleBar"
	_title_bar.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	_title_bar.offset_top = 20
	_title_bar.offset_bottom = 168
	_title_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_content.add_child(_title_bar)

	_left_cards = _make_card_column(LEFT_FAMILIES)
	_left_cards.name = "ResearchLeftFamilies"
	_safe_content.add_child(_left_cards)
	_place_side_cards(_left_cards, false)

	_right_cards = _make_card_column(RIGHT_FAMILIES)
	_right_cards.name = "ResearchRightFamilies"
	_safe_content.add_child(_right_cards)
	_place_side_cards(_right_cards, true)

	_bottom_hud = _make_bottom_hud() as GridContainer
	_bottom_hud.name = "ResearchBottomHud"
	_bottom_hud.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	_bottom_hud.offset_left = 16
	_bottom_hud.offset_right = -16
	_bottom_hud.offset_top = -176
	_bottom_hud.offset_bottom = -16
	_safe_content.add_child(_bottom_hud)

	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 16)
	_toast.add_theme_color_override("font_color", _Tokens.TEXT)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.clip_text = true
	_toast.set_anchors_preset(PRESET_TOP_WIDE)
	_toast.offset_top = 8.0
	_toast.offset_bottom = 36.0
	_safe_content.add_child(_toast)
	_apply_responsive_layout(true)


func _on_viewport_size_changed() -> void:
	call_deferred("_apply_responsive_layout")


func _apply_responsive_layout(force: bool = false) -> void:
	if _safe_margin == null or not is_instance_valid(_safe_margin):
		return
	var narrow := _Responsive.is_narrow_phone(get_viewport())
	var compact := _Responsive.is_compact_landscape(get_viewport())
	var next_scale := _Responsive.layout_scale(get_viewport())
	var next_insets := _Responsive.logical_safe_insets(get_viewport())
	if (
		not force
		and is_equal_approx(next_scale, _layout_scale)
		and next_insets.is_equal_approx(_safe_insets)
	):
		return
	_layout_scale = next_scale
	_safe_insets = next_insets
	_set_research_safe_margins(12 if narrow else 0)
	_scale_control_tree(_safe_content, narrow, compact)
	if narrow:
		_title_bar.offset_top = 0
		_title_bar.offset_bottom = _metric(140)
		_left_cards.visible = false
		_right_cards.visible = false
		_bottom_hud.columns = 1
		_bottom_hud.clip_contents = false
		_bottom_hud.custom_minimum_size = Vector2(0, _metric(440))
		_bottom_hud.offset_left = 0
		_bottom_hud.offset_right = 0
		_bottom_hud.offset_top = -float(_metric(440))
		_bottom_hud.offset_bottom = 0
		_bottom_hud.add_theme_constant_override("h_separation", _metric(8))
		_bottom_hud.add_theme_constant_override("v_separation", _metric(8))
		_resource_panel.custom_minimum_size.x = 0
		_resource_panel.size_flags_horizontal = SIZE_EXPAND_FILL
		_detail_panel.size_flags_horizontal = SIZE_EXPAND_FILL
		_camera_column.size_flags_horizontal = SIZE_EXPAND_FILL
		_camera_column.add_theme_constant_override("separation", _metric(6))
		_toast.offset_top = 0
		_toast.offset_bottom = _metric(30)
	else:
		_title_bar.offset_top = _metric(20)
		_title_bar.offset_bottom = _metric(168)
		_left_cards.visible = true
		_right_cards.visible = true
		_place_side_cards(_left_cards, false)
		_place_side_cards(_right_cards, true)
		_bottom_hud.columns = 3
		_bottom_hud.clip_contents = true
		_bottom_hud.custom_minimum_size = Vector2(0, _metric(160))
		_bottom_hud.offset_left = _metric(16)
		_bottom_hud.offset_right = -_metric(16)
		_bottom_hud.offset_top = -_metric(176)
		_bottom_hud.offset_bottom = -_metric(16)
		_bottom_hud.add_theme_constant_override("h_separation", _metric(12))
		_bottom_hud.add_theme_constant_override("v_separation", _metric(12))
		_resource_panel.custom_minimum_size.x = _metric(188)
		_camera_column.add_theme_constant_override("separation", _metric(6))
		_toast.offset_top = _metric(8)
		_toast.offset_bottom = _metric(36)
	_safe_content.queue_redraw()


func _set_research_safe_margins(base: int) -> void:
	_safe_margin.add_theme_constant_override("margin_left", _metric(base) + roundi(_safe_insets.x))
	_safe_margin.add_theme_constant_override("margin_top", _metric(base) + roundi(_safe_insets.y))
	_safe_margin.add_theme_constant_override("margin_right", _metric(base) + roundi(_safe_insets.z))
	_safe_margin.add_theme_constant_override("margin_bottom", _metric(base) + roundi(_safe_insets.w))


func _scale_control_tree(node: Node, narrow: bool, compact: bool) -> void:
	if node is Control:
		var control := node as Control
		if not control.has_meta("responsive_base_minimum"):
			control.set_meta("responsive_base_minimum", control.custom_minimum_size)
		var base_minimum: Vector2 = control.get_meta("responsive_base_minimum")
		control.custom_minimum_size = base_minimum * _layout_scale if compact else base_minimum
		if control is BaseButton:
			if narrow:
				control.custom_minimum_size = Vector2(
					base_minimum.x,
					maxf(base_minimum.y * _layout_scale, float(_metric(53)))
				)
			elif compact:
				control.custom_minimum_size.y = maxf(
					base_minimum.y * _layout_scale, float(_metric(44))
				)
		if control is Label or control is BaseButton:
			if not control.has_meta("responsive_base_font_size"):
				control.set_meta(
					"responsive_base_font_size", control.get_theme_font_size("font_size")
				)
			var base_font := int(control.get_meta("responsive_base_font_size"))
			var target_font := maxi(base_font, 17) if narrow else (maxi(base_font, 14) if compact else base_font)
			control.add_theme_font_size_override(
				"font_size", _metric(target_font)
			)
	for child in node.get_children():
		_scale_control_tree(child, narrow, compact)


func _metric(value: int) -> int:
	if value == 0:
		return 0
	return maxi(1, roundi(float(value) * _layout_scale))


func responsive_contract() -> Dictionary:
	var narrow := _Responsive.is_narrow_phone(get_viewport())
	var compact := _Responsive.is_compact_landscape(get_viewport())
	var physical := _Responsive.physical_window_size()
	var viewport_size := get_viewport().get_visible_rect().size
	var min_action_height := INF
	var action_buttons: Array[Button] = [_research_btn, _track_btn]
	action_buttons.append_array(_camera_buttons)
	for button in action_buttons:
		min_action_height = minf(
			min_action_height,
			_Responsive.logical_height_to_physical(
				get_viewport(), maxf(button.size.y, button.custom_minimum_size.y)
			)
		)
	var copy_physical := _Responsive.logical_height_to_physical(
		get_viewport(), float(_detail_title.get_theme_font_size("font_size"))
	)
	var map_label_physical := (
		_map.minimum_label_size_physical()
		if _map != null and _map.has_method("minimum_label_size_physical")
		else 0.0
	)
	var safe_pass := (
		_safe_margin.get_theme_constant("margin_left") >= roundi(_safe_insets.x)
		and _safe_margin.get_theme_constant("margin_top") >= roundi(_safe_insets.y)
		and _safe_margin.get_theme_constant("margin_right") >= roundi(_safe_insets.z)
		and _safe_margin.get_theme_constant("margin_bottom") >= roundi(_safe_insets.w)
	)
	var bottom_inside_safe := _safe_content.get_global_rect().grow(1.0).encloses(
		_bottom_hud.get_global_rect()
	)
	var all_pass := true
	if narrow:
		all_pass = (
			_bottom_hud.columns == 1
			and not _left_cards.visible
			and not _right_cards.visible
			and min_action_height >= 44.0
			and copy_physical >= 14.0
			and map_label_physical >= 14.0
			and safe_pass
			and bottom_inside_safe
		)
	elif compact:
		all_pass = (
			_bottom_hud.columns == 3
			and _left_cards.visible
			and _right_cards.visible
			and min_action_height >= 44.0
			and copy_physical >= 14.0
			and map_label_physical >= 14.0
			and safe_pass
			and bottom_inside_safe
		)
	return {
		"mode": "narrow-phone" if narrow else ("compact-landscape" if compact else "wide"),
		"physical": [physical.x, physical.y],
		"logical": [viewport_size.x, viewport_size.y],
		"layout_scale": _layout_scale,
		"safe_area_source": _Responsive.safe_area_source(),
		"safe_insets_logical": [_safe_insets.x, _safe_insets.y, _safe_insets.z, _safe_insets.w],
		"bottom_columns": _bottom_hud.columns,
		"side_cards_hidden": not _left_cards.visible and not _right_cards.visible,
		"minimum_action_height_physical": min_action_height,
		"minimum_copy_size_physical": copy_physical,
		"minimum_map_label_size_physical": map_label_physical,
		"safe_margins_pass": safe_pass,
		"bottom_inside_safe_area": bottom_inside_safe,
		"all_pass": all_pass,
	}


func _place_side_cards(col: Control, on_right: bool) -> void:
	col.anchor_left = 1.0 if on_right else 0.0
	col.anchor_right = 1.0 if on_right else 0.0
	col.anchor_top = 0.18
	col.anchor_bottom = 0.18
	if on_right:
		col.offset_left = -_metric(258)
		col.offset_right = -_metric(18)
	else:
		col.offset_left = _metric(18)
		col.offset_right = _metric(258)
	col.offset_top = 0
	col.offset_bottom = _metric(320)


func _make_title_bar() -> Control:
	var wrap := VBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var brand := Label.new()
	brand.text = "IMMUNE"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.add_theme_font_size_override("font_size", 56)
	brand.add_theme_color_override("font_color", _Tokens.TEXT)
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(brand)
	var subtitle := Label.new()
	subtitle.text = tr("RESEARCH_UI_SUBTITLE")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", _Tokens.CYAN)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(subtitle)
	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 14)
	_progress_label.add_theme_color_override("font_color", _Tokens.MUTED)
	_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(_progress_label)
	_campaign_chip = Label.new()
	_campaign_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_campaign_chip.add_theme_font_size_override("font_size", 13)
	_campaign_chip.add_theme_color_override("font_color", _Tokens.GOLD)
	_campaign_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(_campaign_chip)
	return wrap


func _make_card_column(families: PackedStringArray) -> Control:
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 10)
	for family in families:
		col.add_child(_make_family_card(family))
	return col


func _make_family_card(family: String) -> Control:
	var wrap: _FamilyRow = _FamilyRow.new()
	wrap.family = family
	wrap.clip_contents = true
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	wrap.custom_minimum_size = Vector2(0, 88)
	wrap.focused.connect(_focus_family)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0235, 0.0667, 0.1137, 0.72)
	style.border_color = _Tokens.family_color(family)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	wrap.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	wrap.add_child(row)
	var badge := _make_family_symbol(family)
	row.add_child(badge)
	var icon := badge.get_child(0) as TextureRect
	var names := VBoxContainer.new()
	names.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(names)
	var title := Label.new()
	title.text = tr(str(_Look.DISPLAY_NAME.get(family, family)))
	title.clip_text = true
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", _Tokens.family_color(family))
	names.add_child(title)
	var blurb := Label.new()
	blurb.text = tr(str(_Tokens.FAMILY_ROLE.get(family, "")))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.max_lines_visible = 2
	blurb.clip_text = true
	blurb.size_flags_horizontal = SIZE_EXPAND_FILL
	blurb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	blurb.add_theme_font_size_override("font_size", 12)
	blurb.add_theme_color_override("font_color", _Tokens.MUTED)
	names.add_child(blurb)
	var count := Label.new()
	count.add_theme_font_size_override("font_size", 12)
	count.add_theme_color_override("font_color", _Tokens.TEXT)
	names.add_child(count)
	_family_bars[family] = {"count": count, "bar": count, "wrap": wrap, "icon": icon}
	return wrap


func _make_family_symbol(family: String) -> Control:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(56, 56)
	badge.clip_contents = true
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = _Tokens.family_color(family).darkened(0.55)
	style.border_color = Color(1, 1, 1, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(28)
	badge.add_theme_stylebox_override("panel", style)
	var icon := TextureRect.new()
	var counts := Catalog.family_ladder_progress(family)
	icon.texture = _Icons.atlas_for_family(family, _Icons.scan_level(counts.x, counts.y))
	icon.custom_minimum_size = Vector2(52, 52)
	icon.size_flags_horizontal = SIZE_EXPAND_FILL
	icon.size_flags_vertical = SIZE_EXPAND_FILL
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(icon)
	return badge


func _make_bottom_hud() -> Control:
	var bar := GridContainer.new()
	bar.columns = 3
	bar.custom_minimum_size = Vector2(0, 160)
	bar.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.clip_contents = true
	bar.add_theme_constant_override("h_separation", 12)
	bar.add_theme_constant_override("v_separation", 12)
	bar.add_child(_make_resource_well())
	bar.add_child(_make_detail())
	_camera_column = VBoxContainer.new()
	_camera_column.name = "ResearchNavigation"
	_camera_column.size_flags_horizontal = SIZE_EXPAND_FILL
	_camera_column.add_theme_constant_override("separation", 6)
	bar.add_child(_camera_column)
	_add_cam_btn(_camera_column, tr("RESEARCH_UI_VIEW_ALL"), func() -> void: _map.cover_view())
	_add_cam_btn(_camera_column, tr("RESEARCH_UI_RETURN_CORE"), func() -> void: _map.focus_id(&"CORE-IMMUNE", 0.48))
	_add_cam_btn(_camera_column, tr("RESEARCH_UI_START_MISSION"), _enter_combat)
	return bar


func _enter_combat() -> void:
	if Engine.is_editor_hint():
		return
	var err := get_tree().change_scene_to_file("res://ui/mission_select/mission_select.tscn")
	if err != OK:
		_flash(tr("RESEARCH_UI_SCENE_ERROR"))


func _add_cam_btn(parent: Control, text: String, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = SIZE_EXPAND_FILL
	btn.pressed.connect(cb)
	parent.add_child(btn)
	_camera_buttons.append(btn)


func _make_resource_well() -> Control:
	var panel := PanelContainer.new()
	_resource_panel = panel
	panel.name = "ResearchResources"
	panel.custom_minimum_size = Vector2(188, 0)
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.12, 0.18, 0.9)
	style.border_color = _Tokens.CYAN
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	panel.add_child(col)
	_resource_rows.clear()
	for key in ["antigen", "protomass", "fusionCore", "biomass"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var cap := Label.new()
		var resource_key := str(_Tokens.RESOURCE_LABEL.get(key, ""))
		cap.text = tr(resource_key) if resource_key != "" else str(key)
		cap.size_flags_horizontal = SIZE_EXPAND_FILL
		cap.add_theme_font_size_override("font_size", 12)
		cap.add_theme_color_override("font_color", _Tokens.MUTED)
		row.add_child(cap)
		var value := Label.new()
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.add_theme_font_size_override("font_size", 16 if key == "antigen" else 13)
		value.add_theme_color_override("font_color", _Tokens.CYAN)
		row.add_child(value)
		col.add_child(row)
		_resource_rows[key] = {"value": value, "label": cap}
		if key == "antigen":
			_resource_value = value
	_resource_sub = Label.new()
	_resource_sub.visible = false
	col.add_child(_resource_sub)
	return panel


func _make_detail() -> Control:
	var panel := PanelContainer.new()
	_detail_panel = panel
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	panel.clip_contents = true
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.08, 0.12, 0.92)
	style.border_color = Color(0.365, 0.894, 1.0, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	_detail_title = Label.new()
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_title.max_lines_visible = 1
	_detail_title.clip_text = true
	_detail_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_detail_title.add_theme_font_size_override("font_size", 16)
	col.add_child(_detail_title)
	_detail_status = Label.new()
	_detail_status.clip_text = true
	_detail_status.add_theme_color_override("font_color", _Tokens.GOLD)
	col.add_child(_detail_status)
	_detail_meta = Label.new()
	_detail_meta.clip_text = true
	_detail_meta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_detail_meta.add_theme_font_size_override("font_size", 12)
	_detail_meta.add_theme_color_override("font_color", _Tokens.CYAN)
	col.add_child(_detail_meta)
	_detail_effects = Label.new()
	_detail_effects.clip_text = true
	_detail_effects.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_detail_effects.add_theme_font_size_override("font_size", 12)
	_detail_effects.add_theme_color_override("font_color", _Tokens.TEXT)
	col.add_child(_detail_effects)
	_detail_cost = Label.new()
	_detail_cost.clip_text = true
	_detail_cost.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_detail_cost.add_theme_font_size_override("font_size", 12)
	_detail_cost.add_theme_color_override("font_color", _Tokens.MUTED)
	col.add_child(_detail_cost)
	_detail_body = Label.new()
	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_body.max_lines_visible = 2
	_detail_body.clip_text = true
	_detail_body.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_detail_body.add_theme_font_size_override("font_size", 12)
	_detail_body.add_theme_color_override("font_color", _Tokens.MUTED)
	col.add_child(_detail_body)
	var actions := HBoxContainer.new()
	col.add_child(actions)
	_track_btn = Button.new()
	_track_btn.text = tr("RESEARCH_UI_TRACK")
	_track_btn.pressed.connect(func() -> void: ResearchState.toggle_track(ResearchState.selected_node_id))
	actions.add_child(_track_btn)
	_research_btn = Button.new()
	_research_btn.text = tr("RESEARCH_UI_RESEARCH")
	_research_btn.pressed.connect(_try_research)
	actions.add_child(_research_btn)
	return panel
