class_name ImmuneResponsiveLayout
extends RefCounted

## Shared physical-pixel contract for the expanded 1920x1080 canvas.
##
## On a 390x844 window, stretch/aspect=expand exposes roughly 1920x4155
## logical units. Layout decisions therefore use the physical window while
## control metrics and safe-area insets are converted back to logical units.

const NARROW_PHONE_MAX_WIDTH := 430
const TALL_ASPECT_MAX := 0.8
const TALL_LAYOUT_SCALE := 2.25
const NARROW_REFERENCE_WIDTH := 720.0
const NARROW_MAX_SCALE := 4.5
const QA_SAFE_AREA_ENV := "IMMUNE_QA_SAFE_AREA_INSETS"


static func physical_window_size() -> Vector2:
	var size := Vector2(DisplayServer.window_get_size())
	if size.x <= 1.0 or size.y <= 1.0:
		# The headless display server reports (0, 0). Use the project's logical
		# baseline so import/smoke checks never amplify QA insets by thousands.
		size = Vector2(
			float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
			float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
		)
	return Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))


static func visible_size(viewport: Viewport) -> Vector2:
	if viewport == null:
		return physical_window_size()
	var size := viewport.get_visible_rect().size
	return Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))


static func logical_per_physical(viewport: Viewport) -> Vector2:
	return visible_size(viewport) / physical_window_size()


static func is_narrow_phone(_viewport: Viewport = null) -> bool:
	var physical := physical_window_size()
	return physical.x <= NARROW_PHONE_MAX_WIDTH and physical.y > physical.x


static func layout_scale(viewport: Viewport) -> float:
	var physical := physical_window_size()
	if is_narrow_phone(viewport):
		return clampf(
			TALL_LAYOUT_SCALE * NARROW_REFERENCE_WIDTH / physical.x,
			TALL_LAYOUT_SCALE,
			NARROW_MAX_SCALE
		)
	var logical := visible_size(viewport)
	var aspect := logical.x / maxf(logical.y, 1.0)
	return TALL_LAYOUT_SCALE if aspect <= TALL_ASPECT_MAX else 1.0


static func logical_safe_insets(viewport: Viewport) -> Vector4:
	var physical := _physical_safe_insets()
	var ratio := logical_per_physical(viewport)
	return Vector4(
		physical.x * ratio.x,
		physical.y * ratio.y,
		physical.z * ratio.x,
		physical.w * ratio.y
	)


static func logical_size_to_physical(viewport: Viewport, logical: Vector2) -> Vector2:
	var ratio := logical_per_physical(viewport)
	return Vector2(logical.x / ratio.x, logical.y / ratio.y)


static func logical_height_to_physical(viewport: Viewport, logical_height: float) -> float:
	return logical_height / logical_per_physical(viewport).y


static func safe_area_source() -> String:
	if OS.is_debug_build():
		var override := OS.get_environment(QA_SAFE_AREA_ENV).strip_edges()
		if not override.is_empty() and _parse_insets(override).x >= 0.0:
			return "debug-env"
	if OS.get_name() in ["Android", "iOS"]:
		return "platform"
	return "none"


static func _physical_safe_insets() -> Vector4:
	if OS.is_debug_build():
		var override := OS.get_environment(QA_SAFE_AREA_ENV).strip_edges()
		if not override.is_empty():
			var parsed := _parse_insets(override)
			if parsed.x >= 0.0:
				return parsed
			push_warning(
				"ResponsiveLayout: %s must be left,top,right,bottom non-negative pixels"
				% QA_SAFE_AREA_ENV
			)
	# Godot currently implements display-safe-area geometry on Android/iOS.
	# Its default Web shell omits viewport-fit=cover, so the browser viewport is
	# already unobscured; treating the desktop usable screen as canvas-relative
	# Web insets would be incorrect.
	if OS.get_name() not in ["Android", "iOS"]:
		return Vector4.ZERO
	var window := physical_window_size()
	var safe := DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4.ZERO
	return Vector4(
		clampf(float(safe.position.x), 0.0, window.x),
		clampf(float(safe.position.y), 0.0, window.y),
		clampf(window.x - float(safe.end.x), 0.0, window.x),
		clampf(window.y - float(safe.end.y), 0.0, window.y)
	)


static func _parse_insets(raw: String) -> Vector4:
	var parts := raw.split(",", false)
	if parts.size() != 4:
		return Vector4(-1.0, -1.0, -1.0, -1.0)
	var values: Array[float] = []
	for part in parts:
		var token := String(part).strip_edges()
		if not token.is_valid_float():
			return Vector4(-1.0, -1.0, -1.0, -1.0)
		var value := token.to_float()
		if value < 0.0:
			return Vector4(-1.0, -1.0, -1.0, -1.0)
		values.append(value)
	return Vector4(values[0], values[1], values[2], values[3])
