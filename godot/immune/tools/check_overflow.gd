extends SceneTree

## Layout + label overflow check for the research HUD. Exit 1 on failure.
##
## Optional evidence output:
##   godot --path <proj> --resolution 390x844 --script res://tools/check_overflow.gd -- \
##     --out=<absolute-temp-or-repository-outputs-dir>


const FORBIDDEN_COVER_LABELS := {
	"zh_HK": ["精準抗體", "精準抗體｜強化協同", "精準抗體｜基礎相性", "精準抗體｜傳承特質協議", "免疫網絡", "免疫網絡｜強化協同", "免疫網絡｜基礎相性"],
	"en": ["Precision Antibody", "Precision Antibody | Enhanced Synergy", "Precision Antibody | Base Affinity", "Precision Antibody | Legacy Trait Protocol", "Immune Network", "Immune Network | Enhanced Synergy", "Immune Network | Base Affinity"],
}

const EXPECTED_COVER_LABELS := {
	"zh_HK": ["免疫核心", "T 細胞", "B 細胞", "巨噬細胞", "NK 細胞", "抗體構造體", "樹突細胞"],
	"en": ["Immune Core", "T Cell", "B Cell", "Macrophage", "NK Cell", "Antibody Construct", "Dendritic Cell"],
}

var _log: PackedStringArray = []
var _target_window := Vector2i(1920, 1080)
var _viewport_size := Vector2(1920, 1080)
var _artifact_dir := ""


func _catalog_nodes() -> Array:
	var catalog := root.get_node_or_null("Catalog")
	return catalog.call("all_nodes") if catalog != null else []


func _is_revealed(id: StringName) -> bool:
	var research_state := root.get_node_or_null("ResearchState")
	return bool(research_state.call("is_revealed", id)) if research_state != null else false


func _init() -> void:
	var research_state := root.get_node_or_null("ResearchState")
	if research_state != null and research_state.has_method("qa_startup_failed"):
		if bool(research_state.call("qa_startup_failed")):
			var exit_code := 74
			if research_state.has_method("qa_startup_failure_exit_code"):
				exit_code = int(research_state.call("qa_startup_failure_exit_code"))
			quit(exit_code)
			return
	call_deferred("_run")


func _log_line(text: String) -> void:
	_log.append(text)
	print(text)
	printerr(text)


func _run() -> void:
	var research_state := root.get_node_or_null("ResearchState")
	if research_state != null and research_state.has_method("qa_startup_failed"):
		if bool(research_state.call("qa_startup_failed")):
			var exit_code := 74
			if research_state.has_method("qa_startup_failure_exit_code"):
				exit_code = int(research_state.call("qa_startup_failure_exit_code"))
			quit(exit_code)
			return
	if not _parse_args():
		quit(2)
		return
	_log_line("OVERFLOW_CHECK_START")
	var requested_window := DisplayServer.window_get_size()
	var narrow_phone := requested_window.x <= 430 and requested_window.y > requested_window.x
	_target_window = requested_window if narrow_phone else Vector2i(1920, 1080)
	DisplayServer.window_set_size(_target_window)
	TranslationServer.set_locale("zh_HK")
	var packed := load("res://ui/research/research_network.tscn") as PackedScene
	if packed == null:
		_finish(["research_network.tscn missing"], false)
		return
	var hud := packed.instantiate() as Control
	root.add_child(hud)
	await create_timer(0.4).timeout
	_viewport_size = root.get_visible_rect().size if narrow_phone else Vector2(1920, 1080)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.size = _viewport_size
	await process_frame
	await process_frame
	_log_line("HUD_SIZE %s WINDOW %s MAP_WAIT" % [hud.size, DisplayServer.window_get_size()])

	var failures: PackedStringArray = []
	var map: Control
	for locale in ["zh_HK", "en"]:
		TranslationServer.set_locale(locale)
		hud.call("_on_settings_changed")
		await process_frame
		await process_frame
		map = _find_map(hud)
		if map == null:
			_finish(["research map missing for %s" % locale], false)
			return
		_log_line("MAP_%s SIZE %s CLIP %s" % [locale, map.size, map.clip_contents])
		failures.append_array(_check_control_tree(hud, Rect2(Vector2.ZERO, _viewport_size)))
		failures.append_array(_check_resource_text(hud, locale))
		if narrow_phone:
			if not hud.has_method("responsive_contract"):
				failures.append("narrow phone responsive contract missing")
			else:
				var contract: Dictionary = hud.call("responsive_contract")
				_log_line("RESPONSIVE_%s %s" % [locale, JSON.stringify(contract)])
				if not bool(contract.get("all_pass", false)):
					failures.append("narrow phone responsive contract failed %s" % JSON.stringify(contract))
		map.call("cover_view")
		await process_frame
		failures.append_array(_check_map_labels(map, "cover", locale))
		failures.append_array(_check_map_nodes(map, "cover"))
		failures.append_array(_check_drawn_inside_map(map))

		map.set("zoom", 1.2)
		map.queue_redraw()
		await process_frame
		failures.append_array(_check_map_labels(map, "zoom-1.2", locale))

		map.call("cover_view")
		await process_frame
	TranslationServer.set_locale("zh_HK")
	hud.call("_on_settings_changed")
	await process_frame
	map = _find_map(hud)
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw()
		await process_frame
		var tex: ViewportTexture = root.get_texture()
		if tex != null:
			var img: Image = tex.get_image()
			if img != null:
				var out := _artifact_path("overflow_check.png")
				var err: Error = img.save_png(out)
				if err != OK:
					_log_line("WARN screenshot_save %s" % error_string(err))
				else:
					_log_line("SCREENSHOT %s %dx%d" % [out, img.get_width(), img.get_height()])
	else:
		_log_line("SCREENSHOT_SKIPPED headless")

	_finish(failures, failures.is_empty())


func _finish(failures: PackedStringArray, ok: bool) -> void:
	var report := PackedStringArray()
	report.append_array(_log)
	if ok:
		report.append(
			"OVERFLOW_CHECK_OK viewport=%dx%d window=%dx%d locales=zh_HK+en cover_labels=core+6bases no_pair_stack clip=pass"
			% [_viewport_size.x, _viewport_size.y, _target_window.x, _target_window.y]
		)
	else:
		for line in failures:
			report.append("FAIL %s" % line)
	var path := _artifact_path("overflow_check.txt")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		for line in report:
			file.store_line(line)
		file.close()
		printerr("REPORT %s" % path)
	for line in report:
		printerr(line)
	quit(0 if ok else 1)


func _artifact_path(file_name: String) -> String:
	if not _artifact_dir.is_empty():
		return _artifact_dir.path_join(file_name)
	# QA save isolation already owns a unique per-run directory. Keep screenshots
	# and reports beside that isolated save so a routine check cannot dirty tracked
	# source files under res://tools.
	var directory := OS.get_temp_dir().path_join("immune-overflow")
	var research_state := root.get_node_or_null("ResearchState")
	if research_state != null and research_state.has_method("active_save_path"):
		var save_path := str(research_state.call("active_save_path"))
		if not save_path.is_empty():
			directory = ProjectSettings.globalize_path(save_path).get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(directory)
	if directory_error != OK:
		printerr("OVERFLOW_ARTIFACT_DIR_ERROR %s %s" % [directory, error_string(directory_error)])
	return directory.path_join(file_name)


func _parse_args() -> bool:
	var seen := {}
	for raw_arg: String in OS.get_cmdline_user_args():
		var arg := raw_arg.strip_edges()
		if not arg.begins_with("--") or arg == "--":
			push_error("check_overflow.gd: positional or malformed argument: %s" % raw_arg)
			return false
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() != 2:
			push_error("check_overflow.gd: option requires =<value>: %s" % raw_arg)
			return false
		var key := String(pair[0]).strip_edges()
		var value := String(pair[1]).strip_edges()
		if key not in ["out", "save-path"]:
			push_error("check_overflow.gd: unknown option --%s" % key)
			return false
		if seen.has(key):
			push_error("check_overflow.gd: duplicate option --%s" % key)
			return false
		if value.is_empty():
			push_error("check_overflow.gd: --%s cannot be empty" % key)
			return false
		seen[key] = value
	if not seen.has("out"):
		return true
	return _prepare_artifact_dir(String(seen["out"]))


func _prepare_artifact_dir(raw_path: String) -> bool:
	var normalized := raw_path.strip_edges().replace("\\", "/")
	if normalized.is_empty() or normalized.contains("\u0000") or not normalized.is_absolute_path():
		push_error("check_overflow.gd: --out must be an absolute directory")
		return false
	var absolute_path := normalized.simplify_path().trim_suffix("/")
	var temp_root := OS.get_temp_dir().replace("\\", "/").simplify_path().trim_suffix("/")
	var outputs_root := _repository_outputs_root()
	var project_source_root := ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path().trim_suffix("/")
	if _path_is_within(absolute_path, project_source_root):
		push_error("check_overflow.gd: --out cannot write into res:// source")
		return false
	var trusted_root := ""
	if _path_is_within(absolute_path, temp_root):
		trusted_root = temp_root
	elif _path_is_within(absolute_path, outputs_root):
		trusted_root = outputs_root
	else:
		push_error(
			"check_overflow.gd: --out must be inside the system temp or repository outputs directory"
		)
		return false
	if (
		_path_compare_value(absolute_path) == _path_compare_value(trusted_root)
		or _path_crosses_link(absolute_path, trusted_root)
	):
		push_error("check_overflow.gd: --out is unsafe or crosses a symbolic link")
		return false
	if FileAccess.file_exists(absolute_path):
		push_error("check_overflow.gd: --out names a file")
		return false
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_path)
	if directory_error != OK and not DirAccess.dir_exists_absolute(absolute_path):
		push_error(
			"check_overflow.gd: cannot create --out %s (%s)"
			% [absolute_path, error_string(directory_error)]
		)
		return false
	_artifact_dir = absolute_path
	return true


func _repository_outputs_root() -> String:
	var godot_project_root := ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path()
	return godot_project_root.get_base_dir().get_base_dir().path_join("outputs").simplify_path()


func _path_is_within(path: String, root_path: String) -> bool:
	var normalized_path := path.replace("\\", "/").simplify_path().trim_suffix("/")
	var normalized_root := root_path.replace("\\", "/").simplify_path().trim_suffix("/")
	var comparable_path := _path_compare_value(normalized_path)
	var comparable_root := _path_compare_value(normalized_root)
	return comparable_path == comparable_root or comparable_path.begins_with(comparable_root + "/")


func _path_compare_value(path: String) -> String:
	return path.to_lower() if OS.get_name() in ["Windows", "macOS"] else path


func _path_crosses_link(path: String, trusted_root: String) -> bool:
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


func _check_resource_text(node: Node, locale: String) -> PackedStringArray:
	var failures: PackedStringArray = []
	var protomass := "一度原質" if locale == "zh_HK" else "Protomass"
	var fusion := "融合核心" if locale == "zh_HK" else "Fusion Cores"
	var biomass := "生物質" if locale == "zh_HK" else "Biomass"
	if node is Label:
		var label := node as Label
		var text := label.text
		if text.contains(protomass) and text.contains(fusion):
			_log_line("RESOURCE_SUB_%s %s visible_lines=%d/%d size=%s" % [locale, text.replace("\n", " | "), label.get_visible_line_count(), label.get_line_count(), label.size])
			if not text.contains(biomass):
				failures.append("resource_sub missing values %s" % text)
			if label.get_visible_line_count() < label.get_line_count():
				failures.append("resource_sub clipped lines %d/%d" % [label.get_visible_line_count(), label.get_line_count()])
			if text.contains("…") or text.contains("..."):
				failures.append("resource_sub ellipsis %s" % text)
	for child in node.get_children():
		failures.append_array(_check_resource_text(child, locale))
	return failures


func _find_map(node: Node) -> Control:
	if node.get_script() != null and String(node.get_script().resource_path).ends_with("research_map.gd"):
		return node as Control
	for child in node.get_children():
		var found := _find_map(child)
		if found != null:
			return found
	return null


func _check_control_tree(node: Node, viewport: Rect2) -> PackedStringArray:
	var failures: PackedStringArray = []
	if node is Control:
		var ctrl := node as Control
		var rect := ctrl.get_global_rect()
		if rect.size.x > 1.0 and rect.size.y > 1.0:
			if not viewport.encloses(rect.grow(-0.5)):
				if rect.intersects(viewport):
					var overflow_x := maxf(0.0, rect.end.x - viewport.end.x) + maxf(0.0, viewport.position.x - rect.position.x)
					var overflow_y := maxf(0.0, rect.end.y - viewport.end.y) + maxf(0.0, viewport.position.y - rect.position.y)
					if overflow_x > 2.0 or overflow_y > 2.0:
						failures.append(
							"control_overflow %s rect=%s viewport_overflow=(%.1f,%.1f)"
							% [ctrl.get_path(), rect, overflow_x, overflow_y]
						)
		if ctrl.clip_contents:
			for child in ctrl.get_children():
				if child is Control:
					var kid := child as Control
					var kid_rect := kid.get_global_rect()
					if kid_rect.size.x > 1.0 and kid_rect.size.y > 1.0 and not rect.grow(1.0).encloses(kid_rect):
						var ox := maxf(0.0, kid_rect.end.x - rect.end.x) + maxf(0.0, rect.position.x - kid_rect.position.x)
						var oy := maxf(0.0, kid_rect.end.y - rect.end.y) + maxf(0.0, rect.position.y - kid_rect.position.y)
						if ox > 2.0 or oy > 2.0:
							failures.append(
								"child_clip_overflow %s in %s overflow=(%.1f,%.1f)"
								% [kid.get_path(), ctrl.get_path(), ox, oy]
							)
	for child in node.get_children():
		failures.append_array(_check_control_tree(child, viewport))
	return failures


func _check_map_labels(map: Control, phase: String, locale: String) -> PackedStringArray:
	var failures: PackedStringArray = []
	var labels: PackedStringArray = []
	var catalog := root.get_node_or_null("Catalog")
	var forbidden: PackedStringArray = FORBIDDEN_COVER_LABELS[locale]
	var expected_labels: PackedStringArray = EXPECTED_COVER_LABELS[locale]
	var layout: Dictionary = map.get("_layout")
	for node in _catalog_nodes():
		if not node is Dictionary:
			continue
		var id := StringName(str(node.get("id", "")))
		var entry: Dictionary = layout.get(String(id), {})
		if entry.is_empty():
			continue
		if not bool(map.call("_should_draw_node", node, entry, id)):
			continue
		var kind := str(node.get("kind", ""))
		var portrait := bool(map.call("_is_cover_anchor", id))
		if not _is_revealed(id) and not portrait:
			continue
		if not bool(map.call("_should_show_label", kind, portrait, id)):
			continue
		var title := str(catalog.call("localized_node_name", node))
		labels.append(title)
		if phase == "cover" and forbidden.has(title):
			failures.append("%s forbidden_label %s id=%s" % [phase, title, String(id)])
		var pos: Vector2 = map.call("world_to_local_pos", map.call("_layout_pos", entry))
		var radius := 32.0 * float(map.get("zoom"))
		var label_rect := Rect2(pos + Vector2(-90, radius + 18.0), Vector2(180, 22))
		var map_rect := Rect2(Vector2.ZERO, map.size).grow(24.0)
		if phase == "cover" and not map_rect.intersects(label_rect):
			failures.append("%s label_outside_map %s rect=%s map=%s" % [phase, title, label_rect, map.size])
	_log_line("LABELS_%s_%s count=%d %s" % [locale, phase, labels.size(), ", ".join(labels)])
	if phase == "cover":
		for expected in expected_labels:
			if not labels.has(expected):
				failures.append("cover missing_label %s" % expected)
		if labels.size() > expected_labels.size():
			failures.append("cover extra_labels count=%d %s" % [labels.size(), ", ".join(labels)])
	elif phase == "zoom-1.2":
		for title in labels:
			if forbidden.has(title):
				failures.append("%s stacked_pair_label %s" % [phase, title])
	return failures


func _check_map_nodes(map: Control, phase: String) -> PackedStringArray:
	var failures: PackedStringArray = []
	var drawn := 0
	var pair_anchors := 0
	var layout: Dictionary = map.get("_layout")
	for node in _catalog_nodes():
		if not node is Dictionary:
			continue
		var id := StringName(str(node.get("id", "")))
		var entry: Dictionary = layout.get(String(id), {})
		if entry.is_empty():
			continue
		if not bool(map.call("_should_draw_node", node, entry, id)):
			continue
		drawn += 1
		if str(id).begins_with("CHAR-PAIR-") or str(id).begins_with("PAIR-"):
			pair_anchors += 1
	_log_line("NODES_%s drawn=%d pairish=%d" % [phase, drawn, pair_anchors])
	if phase == "cover" and drawn < 7:
		failures.append("%s missing_cover_nodes drawn=%d" % [phase, drawn])
	if phase == "cover" and map.size.x < 1800.0:
		failures.append("%s map_not_full_bleed %s" % [phase, map.size])
	return failures


func _check_drawn_inside_map(map: Control) -> PackedStringArray:
	var failures: PackedStringArray = []
	var layout: Dictionary = map.get("_layout")
	var bounds := Rect2(Vector2.ZERO, map.size)
	for node in _catalog_nodes():
		if not node is Dictionary:
			continue
		var id := StringName(str(node.get("id", "")))
		var entry: Dictionary = layout.get(String(id), {})
		if entry.is_empty():
			continue
		if not bool(map.call("_should_draw_node", node, entry, id)):
			continue
		if not bool(map.call("_is_cover_anchor", id)) and str(node.get("kind", "")) != "core":
			continue
		var pos: Vector2 = map.call("world_to_local_pos", map.call("_layout_pos", entry))
		var radius := (32.0 if bool(map.call("_is_cover_anchor", id)) else 36.0) * float(map.get("zoom")) + 8.0
		var circle := Rect2(pos - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
		if not bounds.intersects(circle):
			continue
		if not bounds.encloses(circle.grow(-1.0)):
			failures.append("node_clip_edge %s pos=%s radius=%.1f map=%s" % [String(id), pos, radius, map.size])
	return failures
