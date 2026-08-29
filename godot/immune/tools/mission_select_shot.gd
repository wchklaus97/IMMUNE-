extends Node

## Headed six-family mission-desk capture for player-facing visual QA.
##
## Run:
##   godot --path <proj> --resolution 1600x900 res://tools/mission_select_shot.tscn -- \
##     --out=<absolute-dir> [--locale=zh_HK|en] [--tag=mission-select]

const FAMILIES: PackedStringArray = ["T", "B", "M", "N", "A", "D"]

var _args := {}
var _out_dir := ""
var _locale := "zh_HK"
var _tag := "mission-select"
var _desk: Node


func _ready() -> void:
	_parse_args()
	_out_dir = String(_args.get("out", ""))
	_locale = String(_args.get("locale", "zh_HK"))
	_tag = String(_args.get("tag", "mission-select"))
	if _out_dir.is_empty() or _locale not in ["zh_HK", "en"]:
		push_error("mission_select_shot.gd: --out is required and --locale must be zh_HK or en")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_out_dir)
	TranslationServer.set_locale(_locale)
	ResearchState.seed_demo()
	ResearchState.selected_mission_id = &"MISSION-01"
	ResearchState.selected_family_id = &"T"
	var packed := load("res://ui/mission_select/mission_select.tscn") as PackedScene
	if packed == null:
		push_error("mission_select_shot.gd: mission_select.tscn missing")
		get_tree().quit(3)
		return
	_desk = packed.instantiate()
	add_child(_desk)
	await _settle(12)
	for i in FAMILIES.size():
		_desk.call("_select_family", i)
		await _settle(10)
		await _save("%s-%s-%s.png" % [_tag, _locale, FAMILIES[i].to_lower()])
	AudioDirector.stop_all()
	_desk.call("_shutdown_preview")
	_desk.queue_free()
	_desk = null
	# Runtime gel bodies own generated ShaderMaterials and next-pass membranes.
	# A frame-only wait can finish in microseconds and race Compatibility's render
	# thread at process exit, so give both the scene tree and real clock a bounded
	# drain before the final sync.
	for _frame in 10:
		await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	RenderingServer.force_sync()
	await get_tree().process_frame
	get_tree().quit(0)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2:
			_args[pair[0]] = pair[1]


func _settle(frames: int) -> void:
	for _frame in frames:
		await RenderingServer.frame_post_draw


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	RenderingServer.force_sync()
	var image := get_viewport().get_texture().get_image()
	var path := _out_dir.path_join(file_name)
	var err := image.save_png(path)
	if err != OK:
		push_error("mission_select_shot.gd: save failed %s (%d)" % [path, err])
		return
	print("MISSION_SELECT_SHOT %s" % path)
