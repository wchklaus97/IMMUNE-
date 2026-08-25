class_name ImmuneKitBlockout
extends RefCounted

## Primitive stand-ins for the locked 12 concepts. Replace meshes later; do not redraw PNGs.

const _Look := preload("res://characters/family_look.gd")


static func apply(host: Node) -> void:
	if host == null:
		return
	var family := String(host.get("family_id"))
	var jelly := _Look.jelly_material(family)
	var accent := _Look.accent_material(family)
	var base_kit := host.get("base_kit") as Node3D
	var locomotion_kit := host.get("locomotion_kit") as Node3D
	var relay_dish := host.get("relay_dish") as Node3D
	_paint_core(host, jelly)
	_ensure_collision(host)
	_build_face(host, family)
	_build_limbs(host, family, jelly)
	_build_identity(host, family, jelly, accent)
	_build_bubbles(host, jelly)
	if base_kit and base_kit.get_child_count() == 0:
		_build_base(base_kit, family, jelly)
	if family == "A":
		if locomotion_kit:
			locomotion_kit.visible = false
		if relay_dish and relay_dish.get_child_count() == 0:
			_build_relay(relay_dish, jelly, accent)
	elif locomotion_kit and locomotion_kit.get_child_count() == 0:
		_build_loco(locomotion_kit, family, jelly)


static func add_mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scale
	parent.add_child(mi)
	return mi


static func _paint_core(host: Node, jelly: Material) -> void:
	var core := host.get_node_or_null("CoreMesh") as MeshInstance3D
	if core == null:
		return
	core.material_override = jelly


static func _ensure_collision(host: Node) -> void:
	if host.get_node_or_null("CollisionShape3D") != null:
		return
	var shape := SphereShape3D.new()
	shape.radius = 0.48
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.shape = shape
	host.add_child(col)


static func _build_face(host: Node, family: String) -> void:
	var face := host.get_node_or_null("Face") as Node3D
	if face == null or face.get_child_count() > 0:
		return
	var ink := _Look.metal_material(Color(0.08, 0.07, 0.09, 1))
	var eye_l := add_mesh(face, _sphere(0.05), ink, Vector3(-0.09, 0.05, 0.02))
	eye_l.name = "EyeL"
	var eye_r := add_mesh(face, _sphere(0.05), ink, Vector3(0.09, 0.05, 0.02))
	eye_r.name = "EyeR"
	if family == "N":
		var dash := CylinderMesh.new()
		dash.top_radius = 0.018
		dash.bottom_radius = 0.018
		dash.height = 0.1
		var mouth := add_mesh(face, dash, ink, Vector3(0.0, -0.07, 0.02), Vector3(0, 0, 90))
		mouth.name = "Mouth"
		return
	var o_mouth := add_mesh(face, _sphere(0.036), ink, Vector3(0.0, -0.07, 0.03))
	o_mouth.name = "Mouth"


static func _build_limbs(host: Node, family: String, jelly: Material) -> void:
	if host.get_node_or_null("LimbKit") != null:
		return
	var limbs := Node3D.new()
	limbs.name = "LimbKit"
	host.add_child(limbs)
	var arm_l := add_mesh(limbs, _capsule(0.055, 0.2), jelly, Vector3(-0.46, -0.02, 0.02), Vector3(0, 0, 72))
	arm_l.name = "ArmL"
	var arm_r := add_mesh(limbs, _capsule(0.055, 0.2), jelly, Vector3(0.46, -0.02, 0.02), Vector3(0, 0, -72))
	arm_r.name = "ArmR"
	if family == "A":
		return
	var foot_l := add_mesh(limbs, _sphere(0.09), jelly, Vector3(-0.14, -0.48, 0.04))
	foot_l.name = "FootL"
	var foot_r := add_mesh(limbs, _sphere(0.09), jelly, Vector3(0.14, -0.48, 0.04))
	foot_r.name = "FootR"


static func _build_bubbles(host: Node, jelly: Material) -> void:
	var core := host.get_node_or_null("CoreMesh") as MeshInstance3D
	if core == null or core.get_node_or_null("Bubble0") != null:
		return
	var bubble_mat := jelly.duplicate() as StandardMaterial3D
	if bubble_mat:
		var tint := bubble_mat.albedo_color
		tint.a = 0.35
		bubble_mat.albedo_color = tint
		bubble_mat.emission_energy_multiplier = 0.08
	var spots := [Vector3(-0.12, 0.16, -0.08), Vector3(0.14, 0.02, -0.12), Vector3(0.02, -0.14, -0.1)]
	var sizes := [0.09, 0.07, 0.055]
	for i in spots.size():
		var bubble := add_mesh(core, _sphere(sizes[i]), bubble_mat, spots[i])
		bubble.name = "Bubble%d" % i


static func _build_identity(host: Node, family: String, jelly: Material, accent: Material) -> void:
	if bool(host.get_meta("identity_built", false)):
		return
	host.set_meta("identity_built", true)
	var core := host.get_node_or_null("CoreMesh") as MeshInstance3D
	var weapon := host.get("weapon_socket") as Node3D
	if core == null or weapon == null:
		return
	match family:
		"T":
			_t_identity(weapon)
		"B":
			_b_identity(core)
		"M":
			_m_identity(core, weapon, jelly, accent)
		"N":
			_n_identity(weapon, accent)
		"A":
			_a_identity(core)
		"D":
			_d_identity(core, jelly)


static func _t_identity(_weapon: Node3D) -> void:
	## Lineup T is a smooth orange orb with an O-mouth. Combat aims from WeaponSocket.
	pass


static func _b_identity(_core: Node3D) -> void:
	## Lineup B is a smooth purple orb. No gold Y forest on the base body.
	pass


static func _m_identity(core: Node3D, weapon: Node3D, jelly: Material, accent: Material) -> void:
	add_mesh(weapon, _box(Vector3(0.12, 0.08, 0.28)), jelly, Vector3(-0.22, -0.02, 0.08), Vector3(12, 18, 0))
	add_mesh(weapon, _box(Vector3(0.12, 0.08, 0.28)), jelly, Vector3(0.22, -0.02, 0.08), Vector3(12, -18, 0))
	add_mesh(weapon, _sphere(0.07), accent, Vector3(-0.22, 0.02, 0.24))
	add_mesh(weapon, _sphere(0.07), accent, Vector3(0.22, 0.02, 0.24))


static func _n_identity(weapon: Node3D, accent: Material) -> void:
	var housing := _box(Vector3(0.22, 0.16, 0.34))
	add_mesh(weapon, housing, accent, Vector3(0.28, 0.02, 0.06), Vector3(8, -12, 0))
	for i in 3:
		var barrel := CylinderMesh.new()
		barrel.top_radius = 0.03
		barrel.bottom_radius = 0.03
		barrel.height = 0.38
		add_mesh(weapon, barrel, _Look.metal_material(Color(0.22, 0.24, 0.2)), Vector3(0.28, -0.04 + float(i) * 0.05, 0.28), Vector3(90, 0, 0))


static func _a_identity(_core: Node3D) -> void:
	## Lineup A is the same smooth orb as T, distinguished by hover — not a Y body.
	pass


static func _d_identity(core: Node3D, jelly: Material) -> void:
	var angles := [Vector3(18, 0, -28), Vector3(12, 40, 22), Vector3(-8, -30, 18)]
	var positions := [Vector3(-0.22, 0.38, -0.04), Vector3(0.2, 0.42, 0.08), Vector3(0.04, 0.48, -0.16)]
	for i in 3:
		add_mesh(core, _capsule(0.045, 0.55), jelly, positions[i], angles[i])


static func _build_base(base_kit: Node3D, family: String, jelly: Material) -> void:
	match family:
		"A":
			var rim := TorusMesh.new()
			rim.inner_radius = 0.16
			rim.outer_radius = 0.22
			add_mesh(base_kit, rim, jelly, Vector3(0.0, -0.28, 0.0), Vector3(90, 0, 0))
		"M":
			for i in 5:
				var a := TAU * float(i) / 5.0
				add_mesh(base_kit, _capsule(0.05, 0.36), jelly, Vector3(cos(a) * 0.28, -0.42, sin(a) * 0.28), Vector3(20, 0, 0))
		"D":
			add_mesh(base_kit, _capsule(0.07, 0.22), jelly, Vector3(-0.12, -0.48, 0.06), Vector3(12, 0, 8))
			add_mesh(base_kit, _capsule(0.07, 0.22), jelly, Vector3(0.12, -0.48, 0.06), Vector3(12, 0, -8))
		_:
			var skirt := TorusMesh.new()
			skirt.inner_radius = 0.22
			skirt.outer_radius = 0.34
			add_mesh(base_kit, skirt, jelly, Vector3(0.0, -0.42, 0.0), Vector3(90, 0, 0))
			for i in 4:
				var a := TAU * float(i) / 4.0 + 0.4
				add_mesh(base_kit, _sphere(0.07), jelly, Vector3(cos(a) * 0.28, -0.5, sin(a) * 0.28))


static func _build_loco(locomotion_kit: Node3D, family: String, jelly: Material) -> void:
	match family:
		"B":
			add_mesh(locomotion_kit, _box(Vector3(0.08, 0.22, 0.34)), jelly, Vector3(-0.38, -0.12, 0.0), Vector3(0, 0, 18))
			add_mesh(locomotion_kit, _box(Vector3(0.08, 0.22, 0.34)), jelly, Vector3(0.38, -0.12, 0.0), Vector3(0, 0, -18))
			_add_wheels(locomotion_kit, jelly, 0.22, 2)
		"M":
			for i in 3:
				var a := TAU * float(i) / 3.0
				add_mesh(locomotion_kit, _capsule(0.07, 0.28), jelly, Vector3(cos(a) * 0.32, -0.38, sin(a) * 0.32))
			_add_wheels(locomotion_kit, jelly, 0.26, 3)
		"D":
			add_mesh(locomotion_kit, _box(Vector3(0.12, 0.05, 0.28)), jelly, Vector3(-0.18, -0.48, 0.08), Vector3(8, 18, 0))
			add_mesh(locomotion_kit, _box(Vector3(0.12, 0.05, 0.28)), jelly, Vector3(0.18, -0.48, 0.08), Vector3(8, -18, 0))
		_:
			_add_wheels(locomotion_kit, jelly, 0.28, 4)


static func _build_relay(relay_dish: Node3D, jelly: Material, accent: Material) -> void:
	var dish := CylinderMesh.new()
	dish.top_radius = 0.28
	dish.bottom_radius = 0.08
	dish.height = 0.08
	add_mesh(relay_dish, dish, accent, Vector3(0.0, 0.62, 0.08), Vector3(62, 0, 0))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.16
	ring.outer_radius = 0.22
	add_mesh(relay_dish, ring, jelly, Vector3(0.0, -0.42, 0.0), Vector3(90, 0, 0))
	var probe := CylinderMesh.new()
	probe.top_radius = 0.03
	probe.bottom_radius = 0.03
	probe.height = 0.36
	add_mesh(relay_dish, probe, accent, Vector3(0.0, 0.42, 0.18), Vector3(20, 0, 0))


static func _add_wheels(parent: Node3D, jelly: Material, radius: float, count: int) -> void:
	for i in count:
		var a := TAU * float(i) / float(count)
		var wheel := CylinderMesh.new()
		wheel.top_radius = 0.1
		wheel.bottom_radius = 0.1
		wheel.height = 0.08
		add_mesh(parent, wheel, jelly, Vector3(cos(a) * radius, -0.46, sin(a) * radius), Vector3(0, 90, 90))


static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return mesh


static func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	return mesh


static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func _cone(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	return mesh
