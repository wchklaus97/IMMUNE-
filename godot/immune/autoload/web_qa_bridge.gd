extends Node

## Opt-in exported-Web QA bridge. It is inert unless the page URL contains
## `?web_qa=1`; normal play does not expose state or sample additional frames.

const SCHEMA_VERSION: int = 1

var _enabled: bool = false
var _sequence: int = 0


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	var window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	if window == null:
		return
	_enabled = _query_requests_qa(String(window.location.search))
	if not _enabled:
		return
	JavaScriptBridge.eval(
		"globalThis.__immuneWebQa = {schemaVersion: %d, events: [], latest: null};" % SCHEMA_VERSION,
		true
	)
	publish(&"engine_ready", {
		"godot_version": String(Engine.get_version_info().get("string", "unknown")),
		"renderer": RenderingServer.get_current_rendering_driver_name(),
		"display_server": DisplayServer.get_name(),
	})


func _query_requests_qa(search: String) -> bool:
	for parameter: String in search.trim_prefix("?").split("&"):
		var parts: PackedStringArray = parameter.split("=", true, 1)
		if parts.size() == 2 and parts[0] == "web_qa" and parts[1] == "1":
			return true
	return false


func is_enabled() -> bool:
	return _enabled


func publish(event_name: StringName, payload: Dictionary = {}) -> void:
	if not _enabled:
		return
	_sequence += 1
	var event: Dictionary = payload.duplicate(true)
	event["event"] = String(event_name)
	event["sequence"] = _sequence
	event["engine_time_ms"] = Time.get_ticks_msec()
	var encoded: String = JSON.stringify(event)
	JavaScriptBridge.eval(
		"(() => { const qa = globalThis.__immuneWebQa; if (!qa) return; const event = %s; qa.events.push(event); qa.latest = event; })();" % encoded,
		true
	)
