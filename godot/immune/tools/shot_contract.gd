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
	var animation_yaw_error := _animation_yaw_error()
	if not animation_yaw_error.is_empty():
		_fail(animation_yaw_error)
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


func _animation_yaw_error() -> String:
	if not _Shot.animation_yaw_error({"anim": "idle", "anim-yaw": "0"}).is_empty():
		return "shot animation yaw parser rejected a valid frontal angle"
	if not _Shot.animation_yaw_error({"anim-yaw": "0"}).contains("requires --anim"):
		return "shot animation yaw parser accepted an angle without --anim"
	if not _Shot.animation_yaw_error({"anim": "idle", "anim-yaw": "181"}).contains("-180..180"):
		return "shot animation yaw parser accepted an angle outside its bounded range"
	if not _Shot.animation_yaw_error({"anim": "idle", "anim-yaw": "nan"}).contains("finite"):
		return "shot animation yaw parser accepted a non-finite angle"

	var frontal := _Shot.new()
	frontal.set("_args", {"anim": "idle", "anim-yaw": "0"})
	if not bool(frontal.call("_validate_lookdev_args")):
		frontal.free()
		return "shot animation yaw validation rejected zero degrees"
	var parsed_frontal_yaw := float(frontal.get("_animation_yaw"))
	frontal.free()
	if not is_zero_approx(parsed_frontal_yaw):
		return "shot animation yaw parser did not preserve zero degrees"

	var legacy_default := _Shot.new()
	legacy_default.set("_args", {"anim": "idle"})
	if not bool(legacy_default.call("_validate_lookdev_args")):
		legacy_default.free()
		return "shot animation yaw validation rejected the legacy default"
	var parsed_default_yaw := float(legacy_default.get("_animation_yaw"))
	legacy_default.free()
	if not is_equal_approx(parsed_default_yaw, 35.0):
		return "shot animation yaw default drifted from the preserved 35 degrees"
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
