class_name ImmunePrimitiveMeshCache
extends RefCounted

## PrimitiveMesh resources are constructed once and shared by every live/portrait
## MeshInstance3D. Callers treat the returned resources as read-only. Authored
## jelly characters previously built a fresh 96x48 sphere for every body and shell
## piece, doubling the same vertex buffers again when the HUD portrait was present.

static var _spheres: Dictionary = {}
static var _capsules: Dictionary = {}
static var _toruses: Dictionary = {}


static func sphere(radial_segments: int, rings: int) -> SphereMesh:
	assert(radial_segments >= 3 and rings >= 2)
	var key := Vector2i(radial_segments, rings)
	if _spheres.has(key):
		return _spheres[key] as SphereMesh
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = radial_segments
	mesh.rings = rings
	mesh.resource_name = "SharedSphere-%dx%d" % [radial_segments, rings]
	_spheres[key] = mesh
	return mesh


static func capsule(
	radius: float,
	height: float,
	radial_segments: int,
	rings: int
) -> CapsuleMesh:
	assert(radius > 0.0 and height >= radius * 2.0)
	assert(radial_segments >= 3 and rings >= 1)
	var key := "%0.6f:%0.6f:%d:%d" % [radius, height, radial_segments, rings]
	if _capsules.has(key):
		return _capsules[key] as CapsuleMesh
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	mesh.rings = rings
	mesh.resource_name = "SharedCapsule-%s" % key
	_capsules[key] = mesh
	return mesh


static func torus(
	inner_radius: float,
	outer_radius: float,
	rings: int,
	ring_segments: int
) -> TorusMesh:
	assert(inner_radius > 0.0 and outer_radius > inner_radius)
	assert(rings >= 3 and ring_segments >= 3)
	var key := "%0.6f:%0.6f:%d:%d" % [inner_radius, outer_radius, rings, ring_segments]
	if _toruses.has(key):
		return _toruses[key] as TorusMesh
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = rings
	mesh.ring_segments = ring_segments
	mesh.resource_name = "SharedTorus-%s" % key
	_toruses[key] = mesh
	return mesh
