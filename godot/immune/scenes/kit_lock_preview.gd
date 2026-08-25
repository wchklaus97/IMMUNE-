extends Node3D

## Six-base lineup. Cards use base-cell-line-v2. Locked 12 duty concepts stay on disk.

const _Look := preload("res://characters/family_look.gd")

const FAMILIES: Array[String] = ["T", "B", "M", "N", "A", "D"]

var _units: Array[Node] = []
var _cards: Dictionary = {}


func _ready() -> void:
	_build_stage()
	for i in FAMILIES.size():
		var family := FAMILIES[i]
		var path: String = _Look.SCENE_PATH[family]
		var packed := load(path) as PackedScene
		if packed == null:
			push_error("Missing base scene: %s" % path)
			continue
		var unit := packed.instantiate()
		if unit == null:
			push_error("Scene is not ImmuneCharacter: %s" % path)
			continue
		unit.position = Vector3((float(i) - 2.5) * 2.35, 0.55, 0.0)
		add_child(unit)
		_units.append(unit)
		_add_label(unit, family)
		_add_concept_card(unit, family)
	_add_lineup_plate()
	_add_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_toggle_all()


func _toggle_all() -> void:
	for unit in _units:
		if unit.get("duty") == &"fixed":
			unit.call("transform_duty", &"mobile")
		else:
			unit.call("transform_duty", &"fixed")
		_refresh_card(unit)


func _build_stage() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.015, 0.03, 0.05)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.45, 0.55, 0.65)
	environment.ambient_light_energy = 0.4
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_white = 3.0
	env.environment = environment
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 28, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -50, 0)
	fill.light_energy = 0.35
	fill.light_color = Color(0.7, 0.85, 1.0)
	add_child(fill)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 4.6, 8.4)
	camera.rotation_degrees = Vector3(-22, 0, 0)
	camera.current = true
	add_child(camera)

	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(22, 10)
	var floor_mi := MeshInstance3D.new()
	floor_mi.mesh = floor_mesh
	floor_mi.position = Vector3(0.0, 0.0, 0.4)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.04, 0.07, 0.1)
	floor_mat.roughness = 0.85
	floor_mi.material_override = floor_mat
	add_child(floor_mi)


func _add_label(unit: Node, family: String) -> void:
	var label := Label3D.new()
	label.text = "%s · %s" % [family, _Look.DISPLAY_NAME[family]]
	label.font_size = 42
	label.position = Vector3(0.0, 1.86 if family == "A" else 1.42, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = _Look.jelly_color(family)
	unit.add_child(label)


func _add_concept_card(unit: Node, family: String) -> void:
	var card := Sprite3D.new()
	card.name = "ConceptCard"
	card.pixel_size = 0.00105
	card.position = Vector3(0.0, 1.28 if family == "A" else 1.08, -0.95)
	card.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	card.transparent = true
	card.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	unit.add_child(card)
	_cards[unit] = card
	_refresh_card(unit)


func _refresh_card(unit: Node) -> void:
	var card := _cards.get(unit) as Sprite3D
	if card == null:
		return
	var tex := _Look.load_png(_Look.line_path(String(unit.get("family_id"))))
	card.texture = tex
	card.visible = tex != null


func _add_lineup_plate() -> void:
	var tex := _Look.load_png(_Look.lineup_path())
	if tex == null:
		return
	var plate := Sprite3D.new()
	plate.name = "LineupPlate"
	plate.texture = tex
	plate.pixel_size = 0.0042
	plate.position = Vector3(0.0, 3.15, -3.4)
	plate.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(plate)


func _add_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "基礎細胞系 v2 並排參考 · T 橘落地 · B 紫落地 · A 金懸浮 · 空白鍵切職責"
	label.offset_left = 24
	label.offset_top = 20
	label.add_theme_font_size_override("font_size", 22)
	layer.add_child(label)
