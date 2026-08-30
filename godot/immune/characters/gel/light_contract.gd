class_name ImmuneGelLightContract
extends RefCounted

## Compatibility renders direct lights in additive passes. The wet-gel energy
## calibration is valid only for DirectionalLight3D and these per-viewport caps.
const MAX_DIRECT_LIGHTS := 3
const MAX_SHADOWED_DIRECT_LIGHTS := 1


static func error(root: Node, label: String) -> String:
	if root == null:
		return "Jelly %s light audit received no scene root" % label
	var per_viewport := {}
	_collect(root, per_viewport)
	for viewport_id in per_viewport:
		var counts: Dictionary = per_viewport[viewport_id]
		var unsupported: Array = counts.get("unsupported", [])
		if not unsupported.is_empty():
			return "Jelly %s viewport %s uses unsupported %s; calibrated jelly direct lighting supports DirectionalLight3D only" % [
				label, str(viewport_id), str(unsupported[0]),
			]
		var direct_count := int(counts.get("direct", 0))
		var shadowed_count := int(counts.get("shadowed", 0))
		if direct_count > MAX_DIRECT_LIGHTS:
			return "Jelly %s viewport %s uses %d directional direct lights; supported maximum is %d" % [
				label, str(viewport_id), direct_count, MAX_DIRECT_LIGHTS,
			]
		if shadowed_count > MAX_SHADOWED_DIRECT_LIGHTS:
			return "Jelly %s viewport %s uses %d shadowed directional direct lights; supported maximum is %d" % [
				label, str(viewport_id), shadowed_count, MAX_SHADOWED_DIRECT_LIGHTS,
			]
	return ""


static func _collect(node: Node, per_viewport: Dictionary) -> void:
	if node is Light3D:
		var viewport := node.get_viewport()
		var viewport_id := viewport.get_instance_id() if viewport != null else 0
		var counts: Dictionary = per_viewport.get(viewport_id, {
			"direct": 0,
			"shadowed": 0,
			"unsupported": [],
		})
		if node is DirectionalLight3D:
			counts["direct"] = int(counts["direct"]) + 1
			if bool(node.get("shadow_enabled")):
				counts["shadowed"] = int(counts["shadowed"]) + 1
		else:
			var unsupported: Array = counts.get("unsupported", [])
			unsupported.append("%s at %s" % [node.get_class(), str(node.get_path())])
			counts["unsupported"] = unsupported
		per_viewport[viewport_id] = counts
	for child in node.get_children():
		_collect(child, per_viewport)
