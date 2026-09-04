@tool
extends EditorExportPlugin

const _SOURCE_PATH := "res://characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb"
const _EXPECTED_SHA256 := "3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3"
const _FEATURE := "v8_6_candidate"


func _get_name() -> String:
	return "v8_6_raw_source_export"


func _export_begin(
		features: PackedStringArray,
		_is_debug: bool,
		_path: String,
		_flags: int
) -> void:
	if not features.has(_FEATURE):
		return
	var source := FileAccess.open(_SOURCE_PATH, FileAccess.READ)
	if source == null:
		push_error("V8_6_RAW_EXPORT_FAILED open=%s" % _SOURCE_PATH)
		return
	var bytes := source.get_buffer(source.get_length())
	source.close()
	if bytes.is_empty():
		push_error("V8_6_RAW_EXPORT_FAILED empty=%s" % _SOURCE_PATH)
		return
	var hash_context := HashingContext.new()
	var hash_error := hash_context.start(HashingContext.HASH_SHA256)
	if hash_error != OK:
		push_error("V8_6_RAW_EXPORT_FAILED hash_start=%d" % hash_error)
		return
	hash_error = hash_context.update(bytes)
	if hash_error != OK:
		push_error("V8_6_RAW_EXPORT_FAILED hash_update=%d" % hash_error)
		return
	var digest := hash_context.finish().hex_encode()
	if digest != _EXPECTED_SHA256:
		push_error("V8_6_RAW_EXPORT_FAILED sha256=%s" % digest)
		return
	add_file(_SOURCE_PATH, bytes, false)
	print("V8_6_RAW_EXPORT_ADDED path=%s bytes=%d sha256=%s" % [
		_SOURCE_PATH,
		bytes.size(),
		digest,
	])
