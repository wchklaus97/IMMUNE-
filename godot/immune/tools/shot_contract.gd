extends SceneTree

## Headless executable contract for screenshot argument parsing and preview
## provenance. This deliberately avoids rendering so CI can catch evidence-path
## failures before a mislabeled PNG is produced.

const _Shot := preload("res://tools/shot.gd")
const _AnimPreview := preload("res://tools/anim_preview.gd")
const _GelPreview := preload("res://tools/gel_preview.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var scalar_error := _scalar_flow_error()
	if not scalar_error.is_empty():
		_fail(scalar_error)
		return
	var sequence_error := _sequence_flow_error()
	if not sequence_error.is_empty():
		_fail(sequence_error)
		return
	var provenance_error := _preview_provenance_error()
	if not provenance_error.is_empty():
		_fail(provenance_error)
		return
	print("SHOT_CONTRACT_OK scalar=3,-0.5,1 sequence=forward+reverse preview=fail-closed")
	quit(0)


func _scalar_flow_error() -> String:
	var shot := _Shot.new()
	shot.set("_args", {
		"scene": "res://tools/anim_preview.tscn",
		"anim": "move",
		"family": "T",
		"body": "production",
		"flow-seconds": "0.10,0.20",
		"flow-velocity": "3,-0.5,1",
	})
	if not bool(shot.call("_validate_lookdev_args")):
		shot.free()
		return "shot scalar flow parser rejected a valid x,y,z velocity"
	var velocity := shot.get("_flow_velocity") as Vector3
	shot.free()
	if not velocity.is_equal_approx(Vector3(3.0, -0.5, 1.0)):
		return "shot scalar flow parser did not preserve its three components"
	return ""


func _sequence_flow_error() -> String:
	var gel_parse := _GelPreview.parse_user_args(PackedStringArray([
		"--scene=res://tools/gel_preview.tscn",
		"--out=/tmp/contract-output",
		"--tag=contract",
		"--family=T",
		"--source=character",
		"--anim=move",
		"--flow-seconds=0.10,0.20",
		"--flow-velocity-sequence=3,0,0;-3,0,0",
		"--save-path=/tmp/contract-state.json",
	]))
	if not bool(gel_parse.get("ok", false)):
		return "gel preview rejected shot's flow-velocity-sequence passthrough"
	var shot := _Shot.new()
	shot.set("_args", {
		"scene": "res://tools/gel_preview.tscn",
		"anim": "move",
		"family": "T",
		"source": "character",
		"flow-seconds": "0.10,0.20",
		"flow-velocity-sequence": "3,0,0;-3,0,0",
	})
	if not bool(shot.call("_validate_lookdev_args")):
		shot.free()
		return "shot sequence parser rejected a valid character-backed gel preview"
	var velocities: Array = shot.get("_flow_velocity_sequence")
	shot.free()
	if velocities.size() != 2:
		return "shot sequence parser did not preserve one velocity per sample"
	if (
		Vector3(velocities[0]) != Vector3(3.0, 0.0, 0.0)
		or Vector3(velocities[1]) != Vector3(-3.0, 0.0, 0.0)
	):
		return "shot sequence parser lost the forward-to-reverse transition"
	return ""


func _preview_provenance_error() -> String:
	if not _AnimPreview.selection_error("X", "production").contains("unsupported family"):
		return "animation preview no longer rejects an unknown family"
	if not _AnimPreview.selection_error("B", "legacy-glb").contains("no approved legacy"):
		return "animation preview silently permits a B-to-production legacy fallback"
	if not _Shot.anim_preview_selection_error({
		"family": "B", "body": "legacy-glb",
	}).contains("no approved legacy"):
		return "shot dispatch no longer rejects an unsupported legacy family/body pair"
	if not _AnimPreview.selection_error("T", "production").is_empty():
		return "animation preview rejected the production T subject"
	if not _AnimPreview.selection_error("T", "legacy-glb").is_empty():
		return "animation preview could not resolve its approved T legacy diagnostic"
	return ""


func _fail(message: String) -> void:
	push_error("shot_contract.gd: %s" % message)
	quit(1)
