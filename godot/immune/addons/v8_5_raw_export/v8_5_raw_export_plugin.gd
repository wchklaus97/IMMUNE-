@tool
extends EditorExportPlugin

const _SOURCE_PATH := "res://characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb"
const _EXPECTED_SHA256 := "8f14cfe59a508df413e4d53218f30bbf316e7e5d31e42154b2916a0bd5669294"
const _FEATURE := "v8_5_candidate"


func _get_name() -> String:
	return "v8_5_raw_source_export"


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
		push_error("V8_5_RAW_EXPORT_FAILED open=%s" % _SOURCE_PATH)
		return
	var bytes := source.get_buffer(source.get_length())
	source.close()
	var hash_context := HashingContext.new()
	var hash_error := hash_context.start(HashingContext.HASH_SHA256)
	if hash_error != OK:
		push_error("V8_5_RAW_EXPORT_FAILED hash_start=%d" % hash_error)
		return
	hash_error = hash_context.update(bytes)
	if hash_error != OK:
		push_error("V8_5_RAW_EXPORT_FAILED hash_update=%d" % hash_error)
		return
	var digest := hash_context.finish().hex_encode()
	if digest != _EXPECTED_SHA256:
		push_error("V8_5_RAW_EXPORT_FAILED sha256=%s" % digest)
		return
	add_file(_SOURCE_PATH, bytes, false)
	print("V8_5_RAW_EXPORT_ADDED path=%s bytes=%d sha256=%s" % [
		_SOURCE_PATH,
		bytes.size(),
		digest,
	])
