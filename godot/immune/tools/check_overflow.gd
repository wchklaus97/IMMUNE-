extends SceneTree

## Layout + label overflow check for the research HUD. Exit 1 on failure.


const FORBIDDEN_COVER_LABELS: PackedStringArray = [
	"精準抗體",
	"精準抗體｜強化協同",
	"精準抗體｜基礎相性",
	"精準抗體｜傳承特質協議",
	"免疫網絡",
	"免疫網絡｜強化協同",
	"免疫網絡｜基礎相性",
]

const EXPECTED_COVER_LABELS: PackedStringArray = [
	"免疫核心",
	"T 細胞",
	"B 細胞",
	"巨噬細胞",
	"NK 細胞",
	"抗體構造體",
	"樹突細胞",
]

var _log: PackedStringArray = []


func _catalog_nodes() -> Array:
	var catalog := root.get_node_or_null("Catalog")
	return catalog.call("all_nodes") if catalog != null else []


func _is_revealed(id: StringName) -> bool:
	var research_state := root.get_node_or_null("ResearchState")
	return bool(research_state.call("is_revealed", id)) if research_state != null else false


func _init() -> void:
	call_deferred("_run")


func _log_line(text: String) -> void:
	_log.append(text)
	print(text)
	printerr(text)


func _run() -> void:
	_log_line("OVERFLOW_CHECK_START")
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var packed := load("res://ui/research/research_network.tscn") as PackedScene
	if packed == null:
		_finish(["research_network.tscn missing"], false)
		return
	var hud := packed.instantiate() as Control
	root.add_child(hud)
	await create_timer(0.4).timeout
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.size = Vector2(1920, 1080)
	await process_frame
	await process_frame
	_log_line("HUD_SIZE %s WINDOW %s MAP_WAIT" % [hud.size, DisplayServer.window_get_size()])

	var failures: PackedStringArray = []
	failures.append_array(_check_control_tree(hud, Rect2(Vector2.ZERO, Vector2(1920, 1080))))
	failures.append_array(_check_resource_text(hud))
	var map := _find_map(hud)
	if map == null:
		_finish(["research map missing"], false)
		return
	_log_line("MAP_SIZE %s CLIP %s" % [map.size, map.clip_contents])
	map.call("cover_view")
	await process_frame
	failures.append_array(_check_map_labels(map, "cover"))
	failures.append_array(_check_map_nodes(map, "cover"))
	failures.append_array(_check_drawn_inside_map(map))

	map.set("zoom", 1.2)
	map.queue_redraw()
	await process_frame
	failures.append_array(_check_map_labels(map, "zoom-1.2"))

	map.call("cover_view")
	await process_frame
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw()
		await process_frame
		var tex: ViewportTexture = root.get_texture()
		if tex != null:
			var img: Image = tex.get_image()
			if img != null:
				var out := ProjectSettings.globalize_path("res://tools/overflow_check.png")
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
		report.append("OVERFLOW_CHECK_OK viewport=1920x1080 cover_labels=core+6bases no_pair_stack clip=pass")
	else:
		for line in failures:
			report.append("FAIL %s" % line)
	var path := ProjectSettings.globalize_path("res://tools/overflow_check.txt")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		for line in report:
			file.store_line(line)
		file.close()
		printerr("REPORT %s" % path)
	for line in report:
		printerr(line)
	quit(0 if ok else 1)


func _check_resource_text(node: Node) -> PackedStringArray:
	var failures: PackedStringArray = []
	if node is Label:
		var label := node as Label
		var text := label.text
		if text.contains("一度原質") and text.contains("融合核心"):
			_log_line("RESOURCE_SUB %s visible_lines=%d/%d size=%s" % [text.replace("\n", " | "), label.get_visible_line_count(), label.get_line_count(), label.size])
			if not text.contains("生物質"):
				failures.append("resource_sub missing values %s" % text)
			if label.get_visible_line_count() < label.get_line_count():
				failures.append("resource_sub clipped lines %d/%d" % [label.get_visible_line_count(), label.get_line_count()])
			if text.contains("…") or text.contains("..."):
				failures.append("resource_sub ellipsis %s" % text)
	for child in node.get_children():
		failures.append_array(_check_resource_text(child))
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


func _check_map_labels(map: Control, phase: String) -> PackedStringArray:
	var failures: PackedStringArray = []
	var labels: PackedStringArray = []
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
		var title := str(node.get("name", id))
		if kind == "core":
			title = "免疫核心"
		labels.append(title)
		if phase == "cover" and FORBIDDEN_COVER_LABELS.has(title):
			failures.append("%s forbidden_label %s id=%s" % [phase, title, String(id)])
		var pos: Vector2 = map.call("world_to_local_pos", map.call("_layout_pos", entry))
		var radius := 32.0 * float(map.get("zoom"))
		var label_rect := Rect2(pos + Vector2(-90, radius + 18.0), Vector2(180, 22))
		var map_rect := Rect2(Vector2.ZERO, map.size).grow(24.0)
		if phase == "cover" and not map_rect.intersects(label_rect):
			failures.append("%s label_outside_map %s rect=%s map=%s" % [phase, title, label_rect, map.size])
	_log_line("LABELS_%s count=%d %s" % [phase, labels.size(), ", ".join(labels)])
	if phase == "cover":
		for expected in EXPECTED_COVER_LABELS:
			if not labels.has(expected):
				failures.append("cover missing_label %s" % expected)
		if labels.size() > EXPECTED_COVER_LABELS.size():
			failures.append("cover extra_labels count=%d %s" % [labels.size(), ", ".join(labels)])
	elif phase == "zoom-1.2":
		for title in labels:
			if FORBIDDEN_COVER_LABELS.has(title):
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
