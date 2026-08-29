@tool
class_name ImmuneResearchMap
extends Control

## Radial research star map. Pan, zoom, click catalog nodes. No invented IDs.

signal node_clicked(id: StringName)
signal hovered(id: StringName)

const _Tokens := preload("res://ui/research/research_tokens.gd")
const _Layout := preload("res://ui/research/radial_layout.gd")
const _Icons := preload("res://ui/research/icon_library.gd")

const WORLD_CENTER := Vector2(1500, 1500)
const MIN_ZOOM := 0.18
const MAX_ZOOM := 1.35
const COVER_ZOOM := 0.42

var zoom := COVER_ZOOM
var pan := Vector2.ZERO
var _dragging := false
var _drag_from := Vector2.ZERO
var _pan_from := Vector2.ZERO
var _layout: Dictionary = {}
var _hover_id: StringName = &""
var _pulses: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_layout = _Layout.layout_catalog(Catalog.all_nodes())
	if not Engine.is_editor_hint():
		ResearchState.state_changed.connect(queue_redraw)
		ResearchState.selection_changed.connect(func(_id: StringName) -> void: queue_redraw())
	cover_view()


func world_to_local_pos(world: Vector2) -> Vector2:
	return (world - WORLD_CENTER) * zoom + size * 0.5 + pan


func local_to_world(local: Vector2) -> Vector2:
	return (local - size * 0.5 - pan) / zoom + WORLD_CENTER


func focus_id(id: StringName, next_zoom: float = 0.72) -> void:
	var entry: Dictionary = _layout.get(String(id), {})
	if entry.is_empty():
		return
	var world: Vector2 = WORLD_CENTER
	var stored: Variant = entry.get("position", WORLD_CENTER)
	if stored is Vector2:
		world = stored
	zoom = clampf(next_zoom, MIN_ZOOM, MAX_ZOOM)
	pan = -(world - WORLD_CENTER) * zoom
	queue_redraw()


func fit_all() -> void:
	cover_view()


func home_core() -> void:
	cover_view()


func cover_view() -> void:
	zoom = COVER_ZOOM
	pan = Vector2.ZERO
	queue_redraw()


func spawn_feedback(id: StringName, kind: String) -> void:
	var entry: Dictionary = _layout.get(String(id), {})
	if entry.is_empty():
		return
	var node := Catalog.get_node_def(id)
	var family := _Tokens.node_family(node)
	var color := _Tokens.CYAN if kind == "unlock" else _Tokens.family_color(family)
	if color == Color(0, 0, 0, 1) or family == "":
		color = _Tokens.CYAN
	_pulses.append({
		"world": _layout_pos(entry),
		"age": 0.0,
		"duration": 0.42 if kind == "unlock" else 0.32,
		"kind": kind,
		"color": color,
		"radius": _node_radius(node) * (1.15 if str(node.get("kind", "")) == "character_anchor" else 1.0),
	})
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if _pulses.is_empty():
		set_process(false)
		return
	var next: Array[Dictionary] = []
	for pulse in _pulses:
		var age := float(pulse.get("age", 0.0)) + delta
		if age < float(pulse.get("duration", 0.3)):
			var copy := pulse.duplicate()
			copy["age"] = age
			next.append(copy)
	_pulses = next
	queue_redraw()


func _is_cover_anchor(id: StringName) -> bool:
	var text := String(id)
	return text.begins_with("CHAR-BASE-") and text.length() == 11


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			_zoom_at(mouse.position, 1.12)
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			_zoom_at(mouse.position, 0.89)
		elif mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				var hit := _hit_test(mouse.position)
				if hit != &"":
					node_clicked.emit(hit)
				else:
					_dragging = true
					_drag_from = mouse.position
					_pan_from = pan
			else:
				_dragging = false
		elif mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
			var hit := _hit_test(mouse.position)
			if hit != &"":
				node_clicked.emit(hit)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _dragging:
			pan = _pan_from + (motion.position - _drag_from)
			queue_redraw()
		var next := _hit_test(motion.position)
		if next != _hover_id:
			_hover_id = next
			hovered.emit(next)
			queue_redraw()


func _zoom_at(local: Vector2, factor: float) -> void:
	var world := local_to_world(local)
	zoom = clampf(zoom * factor, MIN_ZOOM, MAX_ZOOM)
	pan = local - size * 0.5 - (world - WORLD_CENTER) * zoom
	queue_redraw()


func _layout_pos(entry: Dictionary) -> Vector2:
	var stored: Variant = entry.get("position", Vector2.ZERO)
	if stored is Vector2:
		return stored
	return Vector2.ZERO


func _hit_test(local: Vector2) -> StringName:
	var best := &""
	var best_d := INF
	for id in _layout.keys():
		var nid := StringName(str(id))
		var layout_entry: Variant = _layout.get(id, {})
		if not layout_entry is Dictionary:
			continue
		var layout := layout_entry as Dictionary
		var node := Catalog.get_node_def(nid)
		if node.is_empty() or not _should_draw_node(node, layout, nid):
			continue
		var pos := world_to_local_pos(_layout_pos(layout))
		var d := local.distance_to(pos)
		var radius := (_node_radius(node) * zoom) + (8.0 if _is_cover_anchor(nid) else 10.0)
		if d <= radius and d < best_d:
			best_d = d
			best = nid
	return best


func _lod() -> String:
	if zoom <= 0.55:
		return "overview"
	if zoom <= 1.0:
		return "structure"
	return "detail"


func _is_layout_anchor(layout: Dictionary) -> bool:
	return bool(layout.get("anchor", false))


func _should_draw_node(node: Dictionary, layout: Dictionary, id: StringName) -> bool:
	var kind := str(node.get("kind", ""))
	var revealed := ResearchState.is_revealed(id)
	var anchor := _is_layout_anchor(layout) or _is_cover_anchor(id)
	var lod := _lod()
	if not revealed and not anchor and kind != "core":
		return false
	if lod == "overview":
		return kind == "core" or anchor or _is_cover_anchor(id)
	if lod == "structure":
		return anchor or kind == "core" or kind != "universal" or String(id).ends_with("-01")
	return true


func _draw() -> void:
	_draw_void()
	_draw_rings()
	_draw_edges()
	_draw_nodes()
	_draw_pulses()
	_draw_labels()
	_draw_hover_tip()


func _draw_void() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _Tokens.VOID)
	var core := world_to_local_pos(WORLD_CENTER)
	draw_circle(core, minf(size.x, size.y) * 0.28, Color(0.365, 0.894, 1.0, 0.10))
	draw_circle(Vector2(size.x * 0.22, size.y * 0.30), minf(size.x, size.y) * 0.22, Color(0.659, 0.471, 1.0, 0.06))
	draw_circle(Vector2(size.x * 0.78, size.y * 0.68), minf(size.x, size.y) * 0.20, Color(1.0, 0.608, 0.345, 0.05))


func _draw_rings() -> void:
	var core := world_to_local_pos(WORLD_CENTER)
	for radius in [180.0, 420.0, 560.0, 900.0, 1250.0, 1500.0]:
		draw_arc(core, radius * zoom, 0.0, TAU, 72, Color(0.365, 0.894, 1.0, 0.07), 1.2, true)


func _draw_edges() -> void:
	for node in Catalog.all_nodes():
		if not node is Dictionary:
			continue
		var dest_id := StringName(str(node.get("id", "")))
		if not ResearchState.is_revealed(dest_id):
			continue
		var dest_layout: Dictionary = _layout.get(String(dest_id), {})
		if dest_layout.is_empty():
			continue
		if not _should_draw_node(node, dest_layout, dest_id):
			continue
		var dest_pos := world_to_local_pos(_layout_pos(dest_layout))
		var family := _Tokens.node_family(node)
		var color := _Tokens.family_color(family)
		color.a = 0.55 if ResearchState.is_completed(dest_id) else 0.28
		var groups: Array = node.get("prerequisiteGroups", [])
		var sources: Array = []
		for group in groups:
			for pid in group.get("nodeIds", []):
				if ResearchState.is_revealed(StringName(str(pid))):
					sources.append(str(pid))
		if sources.is_empty() and dest_id != &"CORE-IMMUNE":
			sources.append("CORE-IMMUNE")
		for sid in sources:
			var src_layout: Dictionary = _layout.get(str(sid), {})
			if src_layout.is_empty():
				continue
			var src_node := Catalog.get_node_def(StringName(str(sid)))
			if not src_node.is_empty() and not _should_draw_node(src_node, src_layout, StringName(str(sid))):
				continue
			var src := world_to_local_pos(_layout_pos(src_layout))
			var width := 3.4 if bool(dest_layout.get("anchor", false)) else 1.4
			_draw_organic(src, dest_pos, color, width * maxf(zoom, 0.35))


func _draw_organic(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	var mid := (a + b) * 0.5
	var chord := b - a
	if chord.length() < 2.0:
		return
	var bulge := chord.orthogonal().normalized() * minf(48.0 * zoom, chord.length() * 0.18)
	var control := mid + bulge
	var pts := PackedVector2Array()
	for i in 14:
		var t := float(i) / 13.0
		var omt := 1.0 - t
		pts.append(omt * omt * a + 2.0 * omt * t * control + t * t * b)
	draw_polyline(pts, color, width, true)


func _draw_nodes() -> void:
	for node in Catalog.all_nodes():
		if not node is Dictionary:
			continue
		var id := StringName(str(node.get("id", "")))
		var layout: Dictionary = _layout.get(String(id), {})
		if layout.is_empty():
			continue
		var revealed := ResearchState.is_revealed(id)
		if not _should_draw_node(node, layout, id):
			continue
		var pos := world_to_local_pos(_layout_pos(layout))
		if pos.x < -80.0 or pos.x > size.x + 80.0 or pos.y < -80.0 or pos.y > size.y + 80.0:
			continue
		var family := _Tokens.node_family(node)
		var color := _Tokens.CYAN if str(node.get("kind")) == "core" else _Tokens.family_color(family)
		var radius := _node_radius(node) * zoom
		if str(node.get("kind")) == "character_anchor":
			radius *= 1.15
		if not revealed and not _is_cover_anchor(id):
			draw_circle(pos, radius * 0.7, Color(0.2, 0.28, 0.34, 0.18))
			continue
		var runtime := ResearchState.derive_state(id)
		var fill := color.darkened(0.28)
		if str(runtime.get("completion")) == "complete":
			fill = color
		elif str(runtime.get("eligibility")) == "ready":
			fill = color.lightened(0.12)
		var kind := str(node.get("kind", ""))
		var scan := _scan_level_for(id, family, kind, runtime)
		var has_symbol := _Icons.sheet_for_node(id, family, kind) != null or _Icons.texture_for_node(id, family, kind) != null
		if has_symbol:
			fill = color.darkened(0.55)
			fill.a = 0.35
		draw_circle(pos, radius, fill)
		draw_arc(pos, radius, 0.0, TAU, 24, Color(1, 1, 1, 0.4), 1.4, true)
		_draw_node_symbol(pos, radius, id, family, kind, scan)
		if runtime.get("tracked", false):
			draw_arc(pos, radius + 4.0, 0.0, TAU, 24, _Tokens.GOLD, 2.0, true)
		if runtime.get("selected", false) or id == _hover_id:
			draw_arc(pos, radius + 6.0, 0.0, TAU, 28, _Tokens.CYAN, 2.0, true)
		if runtime.get("selected", false):
			var halo := _Tokens.CYAN
			halo.a = 0.35
			draw_arc(pos, radius + 10.0, 0.0, TAU, 28, halo, 1.4, true)


func _draw_pulses() -> void:
	for pulse in _pulses:
		var duration := maxf(float(pulse.get("duration", 0.32)), 0.01)
		var t := clampf(float(pulse.get("age", 0.0)) / duration, 0.0, 1.0)
		var pos := world_to_local_pos(pulse.get("world", WORLD_CENTER))
		var base := float(pulse.get("radius", 12.0)) * zoom
		var color: Color = pulse.get("color", _Tokens.CYAN)
		if str(pulse.get("kind", "select")) == "unlock":
			color.a = (1.0 - t) * 0.9
			draw_arc(pos, base * (1.0 + t * 2.6), 0.0, TAU, 36, color, 3.4, true)
			var fill := color
			fill.a *= 0.2
			draw_circle(pos, base * (1.0 + t * 1.35), fill)
		else:
			color.a = (1.0 - t) * 0.95
			draw_arc(pos, base * (1.0 + t * 1.7), 0.0, TAU, 32, color, 2.6, true)


func _draw_hover_tip() -> void:
	if _hover_id == &"":
		return
	var node := Catalog.get_node_def(_hover_id)
	if node.is_empty():
		return
	var layout: Dictionary = _layout.get(String(_hover_id), {})
	if layout.is_empty():
		return
	var runtime := ResearchState.derive_state(_hover_id)
	var hidden := str(runtime.get("visibility")) == "hidden"
	var title := tr("RESEARCH_UI_UNKNOWN_NAME") if hidden else Catalog.localized_node_name(node)
	var status := _hover_status_text(runtime, node)
	var pos := world_to_local_pos(_layout_pos(layout))
	var font := ThemeDB.fallback_font
	var width := 220.0
	var box := Rect2(pos + Vector2(18, -36), Vector2(width, 44))
	if box.position.x + box.size.x > size.x - 8.0:
		box.position.x = pos.x - width - 18.0
	if box.position.y < 8.0:
		box.position.y = pos.y + 18.0
	draw_rect(box, Color(0.02, 0.07, 0.11, 0.92), true)
	var border := _Tokens.CYAN
	border.a = 0.45
	draw_rect(box, border, false, 1.0)
	draw_string(font, box.position + Vector2(10, 18), title, HORIZONTAL_ALIGNMENT_LEFT, width - 16, 14, _Tokens.TEXT)
	draw_string(font, box.position + Vector2(10, 36), status, HORIZONTAL_ALIGNMENT_LEFT, width - 16, 12, _Tokens.GOLD)


func _hover_status_text(runtime: Dictionary, node: Dictionary) -> String:
	return ResearchState.eligibility_label(runtime, node)


func _draw_labels() -> void:
	for node in Catalog.all_nodes():
		if not node is Dictionary:
			continue
		var id := StringName(str(node.get("id", "")))
		var layout: Dictionary = _layout.get(String(id), {})
		if layout.is_empty():
			continue
		if not _should_draw_node(node, layout, id):
			continue
		var kind := str(node.get("kind", ""))
		var portrait := _is_cover_anchor(id)
		if not ResearchState.is_revealed(id) and not portrait:
			continue
		if not _should_show_label(kind, portrait, id):
			continue
		var pos := world_to_local_pos(_layout_pos(layout))
		var title := Catalog.localized_node_name(node)
		var font := ThemeDB.fallback_font
		var size_px := 22 if kind == "core" else 16
		var radius := _node_radius(node) * zoom
		if kind == "character_anchor":
			radius *= 1.15
		if pos.x < -40.0 or pos.x > size.x + 40.0 or pos.y < -20.0 or pos.y > size.y + 20.0:
			continue
		var offset := Vector2(-90, radius + 18.0)
		draw_string(font, pos + offset, title, HORIZONTAL_ALIGNMENT_CENTER, 180, size_px, _Tokens.TEXT)


func _scan_level_for(id: StringName, family: String, kind: String, runtime: Dictionary) -> int:
	if kind == "core" or String(id) == "CORE-IMMUNE":
		return _Icons.scan_level_from_eligibility(str(runtime.get("eligibility", "")))
	var text := String(id)
	if text.begins_with("CHAR-BASE-") and text.length() == 11:
		var counts := Catalog.family_ladder_progress(family)
		return _Icons.scan_level(counts.x, counts.y)
	if text.begins_with("CHAR-PAIR-") and text.length() == 12:
		var pair_counts := Catalog.pair_ladder_progress(text.substr(10, 2))
		return _Icons.scan_level(pair_counts.x, pair_counts.y)
	if text.begins_with("CHAR-TRIPLE-") and text.length() == 15:
		var triple_counts := Catalog.triple_ladder_progress(text.substr(12, 3))
		return _Icons.scan_level(triple_counts.x, triple_counts.y)
	if text == "CHAR-PRIME":
		var prime_counts := Catalog.apex_ladder_progress("PRIME")
		return _Icons.scan_level(prime_counts.x, prime_counts.y)
	if text.begins_with("CHAR-APEX-"):
		var apex_counts := Catalog.apex_ladder_progress(text.substr(10))
		return _Icons.scan_level(apex_counts.x, apex_counts.y)
	return _Icons.scan_level_from_eligibility(str(runtime.get("eligibility", "")))


func _draw_node_symbol(pos: Vector2, radius: float, id: StringName, family: String, kind: String, scan: int) -> void:
	var sheet := _Icons.sheet_for_node(id, family, kind)
	var size := radius * 1.9
	var dest := Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size))
	if sheet != null:
		var frame := clampi(scan, 0, _Icons.SCAN_FRAMES - 1)
		var frame_w := float(sheet.get_width()) / float(_Icons.SCAN_COLS)
		var frame_h := float(sheet.get_height()) / float(_Icons.SCAN_ROWS)
		var col := frame % _Icons.SCAN_COLS
		var row := int(frame / _Icons.SCAN_COLS)
		var src := Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
		draw_texture_rect_region(sheet, dest, src)
		return
	var tex := _Icons.texture_for_node(id, family, kind)
	if tex == null:
		return
	draw_texture_rect(tex, dest, false)


func _should_show_label(kind: String, portrait: bool, id: StringName) -> bool:
	if kind == "core" or portrait:
		return true
	if _lod() == "overview":
		return false
	return id == ResearchState.selected_node_id or id == _hover_id


func _node_radius(node: Dictionary) -> float:
	match str(node.get("kind", "")):
		"core":
			return 36.0
		"character_anchor":
			return 28.0
		"apex_research":
			return 20.0
		"triple_research":
			return 18.0
		"pair_research":
			return 16.0
		"base_character_research":
			return 14.0
		"status":
			return 12.0
		"universal":
			return 12.0
		_:
			return 11.0
