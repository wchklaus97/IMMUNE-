extends Node

signal node_completed(id: StringName)
signal duty_unlocked(family: StringName, duty: StringName)
signal skill_granted(skill_id: StringName)
signal selection_changed(id: StringName)
signal state_changed()

const SAVE_VERSION := 2
const SAVE_PATH := "user://immune_demo_save.json"
const SAVE_PATH_ARG_PREFIX := "--save-path="
const QA_RESOURCE_PREFIX := "res://tools/"
const QA_TEMP_DIR_NAME := "immune-qa-saves"
const QA_SAVE_RESERVATION_ATTEMPTS := 32
const SAVE_TRANSACTION_ATTEMPTS := 32
const QA_STARTUP_FAILURE_EXIT_CODE := 74
const QA_EXIT_ENFORCEMENT_PROCESS_PRIORITY := 1000000
const SAVE_REQUIRED_V1_FIELDS: PackedStringArray = [
	"version",
	"completedNodeIds",
	"revealedNodeIds",
	"trackedNodeIds",
	"selectedNodeId",
	"resources",
	"unlockedCampaignLevel",
	"discoveryFlags",
]
const SAVE_REQUIRED_V2_FIELDS: PackedStringArray = [
	"selectedMissionId",
	"selectedFamilyId",
	"completedMissionIds",
]
# Values following these engine switches are not positional main-scene paths.
# Keeping user arguments out of the parser is the more important boundary: a
# value such as `--notes=res://tools/foo.gd` can never opt a game run into QA.
const ENGINE_OPTIONS_WITH_VALUE: PackedStringArray = [
	"--debug-server", "--dap-port", "--lsp-port", "--quit-after",
	"-l", "--language", "--path", "--main-pack", "--render-thread",
	"--remote-fs", "--remote-fs-password", "--audio-driver", "--display-driver",
	"--rendering-method", "--rendering-driver", "--gpu-index", "--text-driver",
	"--tablet-driver", "--log-file", "--write-movie", "--resolution", "--position",
	"--screen", "--xr-mode", "--wid", "--accessibility", "--accessibility-driver",
	"-b", "--breakpoints", "--remote-debug", "--max-fps", "--frame-delay",
	"--time-scale", "--fixed-fps", "--delta-smoothing", "--main-loop",
]
const VALID_MISSIONS: PackedStringArray = [
	"MISSION-01", "MISSION-02", "MISSION-03", "MISSION-04", "MISSION-05", "MISSION-06",
]
const VALID_FAMILIES: PackedStringArray = ["T", "B", "M", "N", "A", "D"]

const DEMO_COMPLETED: PackedStringArray = [
	"CORE-IMMUNE",
	"CHAR-BASE-T",
	"CHAR-BASE-B",
	"BASE-T-01",
	"BASE-T-02",
]

const DEMO_REVEALED: PackedStringArray = [
	"CORE-IMMUNE",
	"CHAR-BASE-T",
	"CHAR-BASE-B",
	"UNI-DEF-01",
	"UNI-EXP-01",
	"UNI-WAR-01",
	"UNI-MOB-01",
	"UNI-FUS-01",
	"UNI-SUR-01",
	"BASE-T-01",
	"BASE-T-02",
	"BASE-T-03",
	"BASE-B-01",
	"BASE-B-02",
	"BASE-B-03",
	"UNI-DEF-02",
	"UNI-EXP-02",
	"UNI-WAR-02",
	"UNI-MOB-02",
	"UNI-FUS-02",
	"UNI-SUR-02",
	"PAIR-TB-S1",
	"PAIR-TB-S2",
	"CHAR-PAIR-TB",
	"STATUS-MARK",
	"STATUS-AB",
]

const DEMO_RESOURCES := {
	"antigen": 120,
	"biomass": 40,
	"protomass": 15,
	"fusionCore": 2,
}

var completed_node_ids: Array[StringName] = []
var revealed_node_ids: Array[StringName] = []
var tracked_node_ids: Array[StringName] = []
var selected_node_id: StringName = &"CORE-IMMUNE"
var resources: Dictionary = DEMO_RESOURCES.duplicate(true)


var unlocked_campaign_level: String = "L01"
var discovery_flags: PackedStringArray = []
var global_stats: Dictionary = {}
var selected_mission_id: StringName = &"MISSION-01"
var selected_family_id: StringName = &"T"
var completed_mission_ids: Array[StringName] = []
var _active_save_path: String = SAVE_PATH
var _qa_entry_path := ""
var _qa_uses_explicit_save_path := false
var _qa_uses_auto_save_path := false
var _qa_auto_run_dir := ""
var _startup_save_resolution_error := ""
var _qa_startup_failed := false
var _active_save_write_protected := false
var _reported_protected_save_write := false


func _ready() -> void:
	# Larger process priorities run later. If an older harness requests another
	# code during `_process`, this autoload gets the last per-frame correction.
	process_priority = QA_EXIT_ENFORCEMENT_PROCESS_PRIORITY
	_active_save_path = _resolve_active_save_path()
	if _is_qa_run():
		if not _startup_save_resolution_error.is_empty():
			_fail_qa_startup(_startup_save_resolution_error)
			return
		if _active_save_path.is_empty():
			_fail_qa_startup("QA save isolation resolved to an empty path")
			return
		if not _qa_uses_explicit_save_path and not _qa_uses_auto_save_path:
			_fail_qa_startup("QA entry point was detected without save isolation")
			return
		if _qa_uses_auto_save_path and _active_save_path == SAVE_PATH:
			_fail_qa_startup("automatic QA isolation resolved to the player save")
			return
		print(
			"QA_SAVE_ISOLATED entry=%s mode=%s path=%s"
			% [
				_qa_entry_path,
				"explicit" if _qa_uses_explicit_save_path else "automatic",
				_active_save_path,
			]
		)

	# If a previous process stopped after preserving the old target but before
	# publishing its replacement, restore that sibling before deciding whether to
	# seed. Otherwise a crash-safe backup could be mistaken for a first run.
	var startup_recovery_error := _recover_orphaned_save_backup(
		_absolute_save_path(_active_save_path)
	)
	if startup_recovery_error != OK:
		_active_save_write_protected = true
		if _is_qa_run():
			_fail_qa_startup(
				"cannot recover interrupted QA save transaction (%s)"
				% error_string(startup_recovery_error)
			)
			return
		seed_demo()
		push_warning(
			"ResearchState: interrupted save recovery failed; existing transaction files were preserved"
		)
		return

	var save_existed := FileAccess.file_exists(_active_save_path)
	if save_existed:
		if load_game():
			return
		# A failed load must never be followed by a write to the same path. Apart
		# from protecting QA fixtures byte-for-byte, this preserves a player's
		# malformed save for diagnosis/recovery while keeping the game playable
		# from an in-memory demo state.
		_active_save_write_protected = true
		if _is_qa_run():
			_fail_qa_startup(
				"cannot load existing QA save; original file was preserved: %s"
				% _active_save_path
			)
			return
		seed_demo()
		push_warning(
			"ResearchState: kept unreadable save %s unchanged; using an in-memory demo seed"
			% _active_save_path
		)
		return

	seed_demo()
	var save_error := save_game()
	if save_error != OK and _is_qa_run():
		_fail_qa_startup(
			"cannot initialize QA save %s (%s)"
			% [_active_save_path, error_string(save_error)]
		)


func _process(_delta: float) -> void:
	# A harness can request another exit code after autoload `_ready()`. Keep the
	# startup failure authoritative until teardown; compliant harnesses also use
	# qa_startup_failed() to avoid doing any work after this condition.
	if _qa_startup_failed:
		get_tree().quit(QA_STARTUP_FAILURE_EXIT_CODE)


func _exit_tree() -> void:
	_cleanup_owned_qa_run()
	# This is the final central backstop when a legacy tool queued quit(2) later
	# in the same frame. It intentionally runs after orderly cleanup.
	if _qa_startup_failed:
		get_tree().quit(QA_STARTUP_FAILURE_EXIT_CODE)


func seed_demo() -> void:
	completed_node_ids.clear()
	revealed_node_ids.clear()
	tracked_node_ids.clear()
	for id in DEMO_COMPLETED:
		completed_node_ids.append(StringName(id))
	for id in DEMO_REVEALED:
		revealed_node_ids.append(StringName(id))
	selected_node_id = &"BASE-T-03"
	resources = DEMO_RESOURCES.duplicate(true)
	unlocked_campaign_level = "L02"
	discovery_flags.clear()
	selected_mission_id = &"MISSION-01"
	selected_family_id = &"T"
	completed_mission_ids.clear()
	_rebuild_global_stats()
	state_changed.emit()


func snapshot() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"completedNodeIds": _as_strings(completed_node_ids),
		"revealedNodeIds": _as_strings(revealed_node_ids),
		"trackedNodeIds": _as_strings(tracked_node_ids),
		"selectedNodeId": String(selected_node_id),
		"resources": resources.duplicate(true),
		"unlockedCampaignLevel": unlocked_campaign_level,
		"discoveryFlags": Array(discovery_flags),
		"selectedMissionId": String(selected_mission_id),
		"selectedFamilyId": String(selected_family_id),
		"completedMissionIds": _as_strings(completed_mission_ids),
	}


func apply_snapshot(raw_data: Dictionary, emit_change: bool = true) -> bool:
	var schema_error := _snapshot_schema_error(raw_data)
	if not schema_error.is_empty():
		push_warning("ResearchState: invalid save schema: %s" % schema_error)
		return false
	return _apply_validated_snapshot(raw_data, emit_change)


func _apply_validated_snapshot(raw_data: Dictionary, emit_change: bool = true) -> bool:
	var data := _migrate_snapshot(raw_data)
	if data.is_empty():
		return false
	completed_node_ids = _valid_names(data.get("completedNodeIds", []))
	revealed_node_ids = _valid_names(data.get("revealedNodeIds", []))
	for completed_id in completed_node_ids:
		if not revealed_node_ids.has(completed_id):
			revealed_node_ids.append(completed_id)
	tracked_node_ids = _valid_names(data.get("trackedNodeIds", []), 3)
	var loaded_selection := StringName(str(data.get("selectedNodeId", "CORE-IMMUNE")))
	selected_node_id = loaded_selection if not Catalog.get_node_def(loaded_selection).is_empty() else &"CORE-IMMUNE"
	var loaded_resources: Variant = data.get("resources", {})
	resources = DEMO_RESOURCES.duplicate(true)
	if loaded_resources is Dictionary:
		for key in DEMO_RESOURCES.keys():
			resources[key] = maxi(int(loaded_resources.get(key, resources[key])), 0)
	unlocked_campaign_level = "L0%d" % campaign_rank(str(data.get("unlockedCampaignLevel", "L01")))
	discovery_flags = PackedStringArray(data.get("discoveryFlags", []))
	selected_mission_id = _valid_choice(data.get("selectedMissionId", "MISSION-01"), VALID_MISSIONS, &"MISSION-01")
	selected_family_id = _valid_choice(data.get("selectedFamilyId", "T"), VALID_FAMILIES, &"T")
	completed_mission_ids = _valid_choices(data.get("completedMissionIds", []), VALID_MISSIONS)
	_rebuild_global_stats()
	if emit_change:
		state_changed.emit()
	return true


func active_save_path() -> String:
	return _active_save_path


func qa_startup_failed() -> bool:
	return _qa_startup_failed


func qa_startup_failure_exit_code() -> int:
	return QA_STARTUP_FAILURE_EXIT_CODE


func save_game(path: String = "") -> Error:
	# SceneTree.quit() is applied at the frame boundary. A QA script may already
	# have queued work, so make the fatal state itself fail-closed against every
	# late write instead of relying on process-exit timing.
	if _qa_startup_failed:
		return ERR_UNCONFIGURED
	var resolved_path := _resolved_save_path(path)
	if _active_save_write_protected and _same_save_path(resolved_path, _active_save_path):
		if not _reported_protected_save_write:
			push_warning(
				"ResearchState: refusing to overwrite preserved unreadable save %s"
				% _active_save_path
			)
			_reported_protected_save_write = true
		return ERR_FILE_CORRUPT
	var absolute_path := _absolute_save_path(resolved_path)
	if _is_qa_run():
		var qa_path_error := _qa_temp_path_error(absolute_path)
		if not qa_path_error.is_empty():
			push_error("ResearchState: refusing unsafe QA save: %s" % qa_path_error)
			return ERR_INVALID_PARAMETER
	var directory_error := _ensure_save_parent(resolved_path)
	if directory_error != OK:
		return directory_error
	if _is_qa_run():
		var parent_path_error := _qa_temp_path_error(absolute_path)
		if not parent_path_error.is_empty():
			push_error("ResearchState: refusing unsafe QA save: %s" % parent_path_error)
			return ERR_INVALID_PARAMETER
	var recovery_error := _recover_orphaned_save_backup(absolute_path)
	if recovery_error != OK:
		push_error(
			"ResearchState: cannot recover interrupted save transaction for %s (%s)"
			% [resolved_path, error_string(recovery_error)]
		)
		return recovery_error
	if _final_component_is_link(absolute_path):
		push_error("ResearchState: refusing save target symbolic link %s" % resolved_path)
		return ERR_INVALID_PARAMETER
	var temporary_path := _reserve_sibling_transaction_path(absolute_path, "tmp")
	if temporary_path.is_empty():
		push_error("ResearchState: cannot reserve transactional save beside %s" % resolved_path)
		return ERR_ALREADY_IN_USE
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		var open_error := FileAccess.get_open_error()
		push_error(
			"ResearchState: cannot open transactional save %s (%s)"
			% [temporary_path, error_string(open_error)]
		)
		return open_error
	var encoded := JSON.stringify(snapshot(), "\t")
	file.store_string(encoded)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary_path)
		push_error(
			"ResearchState: failed writing transactional save %s (%s)"
			% [temporary_path, error_string(write_error)]
		)
		return write_error
	if not _verified_save_file(temporary_path, encoded):
		DirAccess.remove_absolute(temporary_path)
		push_error("ResearchState: transactional save did not verify: %s" % temporary_path)
		return ERR_FILE_CORRUPT
	# Re-check after parent creation and writing the sibling. This closes the
	# common symlink-swap window before the only operation touching the target.
	if _is_qa_run():
		var final_path_error := _qa_temp_path_error(absolute_path)
		if not final_path_error.is_empty():
			DirAccess.remove_absolute(temporary_path)
			push_error("ResearchState: refusing unsafe QA save: %s" % final_path_error)
			return ERR_INVALID_PARAMETER
	return _transactionally_replace_save(temporary_path, absolute_path, encoded, resolved_path)


func load_game(path: String = "") -> bool:
	var resolved_path := _resolved_save_path(path)
	var absolute_path := _absolute_save_path(resolved_path)
	var recovery_error := _recover_orphaned_save_backup(absolute_path)
	if recovery_error != OK:
		push_warning(
			"ResearchState: cannot recover interrupted save transaction for %s (%s)"
			% [resolved_path, error_string(recovery_error)]
		)
		return false
	if not FileAccess.file_exists(resolved_path):
		return false
	var file := FileAccess.open(resolved_path, FileAccess.READ)
	if file == null:
		var open_error := FileAccess.get_open_error()
		push_warning("ResearchState: cannot open %s (%s)" % [resolved_path, error_string(open_error)])
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("ResearchState: invalid JSON in %s" % resolved_path)
		return false
	var schema_error := _snapshot_schema_error(parsed)
	if not schema_error.is_empty():
		push_warning(
			"ResearchState: invalid save schema in %s: %s"
			% [resolved_path, schema_error]
		)
		return false
	if not _apply_validated_snapshot(parsed):
		return false
	_cleanup_save_backups(absolute_path)
	return true


func _resolve_active_save_path() -> String:
	_qa_entry_path = _detect_qa_entry_path()
	var debug_overrides_enabled := Engine.is_editor_hint() or OS.is_debug_build()
	if debug_overrides_enabled:
		var requested_path := _debug_save_path_override()
		if not requested_path.is_empty():
			var validation_error := _save_path_override_error(requested_path, _is_qa_run())
			if validation_error.is_empty():
				_qa_uses_explicit_save_path = _is_qa_run()
				return _absolute_save_path(requested_path) if _is_qa_run() else requested_path
			if _is_qa_run():
				_startup_save_resolution_error = validation_error
				return ""
			push_warning("ResearchState: ignoring invalid debug save-path override: %s" % validation_error)
	elif _has_debug_save_path_override():
		# Exported release builds must never let command-line data redirect the
		# player's persistent state. A release-only QA scene, if one is ever
		# shipped, still gets automatic isolation below.
		push_warning("ResearchState: debug save-path override ignored in a release build")

	# Autoloads initialize before both SceneTree scripts and a requested main
	# scene. Detect every project QA entry point here, before any load/seed/write,
	# rather than relying on the individual harness to configure itself later.
	if _is_qa_run():
		var isolated_path := _reserve_unique_qa_save_path()
		if isolated_path.is_empty():
			return ""
		_qa_uses_auto_save_path = true
		return isolated_path
	return SAVE_PATH


func _debug_save_path_override() -> String:
	var requested_path := ""
	var found := false
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with(SAVE_PATH_ARG_PREFIX):
			continue
		var candidate := arg.trim_prefix(SAVE_PATH_ARG_PREFIX).strip_edges()
		if found:
			if _is_qa_run():
				_startup_save_resolution_error = "multiple --save-path overrides are not allowed for QA"
			return ""
		requested_path = candidate
		found = true
	if found and requested_path.is_empty() and _is_qa_run():
		_startup_save_resolution_error = "QA --save-path override cannot be empty"
	return requested_path


func _has_debug_save_path_override() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(SAVE_PATH_ARG_PREFIX):
			return true
	return false


func _save_path_override_error(path: String, qa_run: bool) -> String:
	if path.is_empty():
		return "save path is empty"
	if path.contains("\u0000"):
		return "save path contains a null byte"
	var normalized := path.replace("\\", "/")
	if normalized.ends_with("/"):
		return "save path names a directory: %s" % path
	if normalized.begins_with("res://"):
		return "res:// is read-only and cannot hold runtime saves: %s" % path
	if qa_run and not normalized.is_absolute_path():
		return "QA save path must be absolute and below the system temporary directory: %s" % path
	if not qa_run and not normalized.begins_with("user://") and not normalized.is_absolute_path():
		return "save path must be user:// or absolute: %s" % path
	if normalized.contains("/../") or normalized.ends_with("/.."):
		return "save path traversal is not allowed: %s" % path
	if not qa_run:
		return ""
	var absolute_path := _absolute_save_path(normalized)
	if _same_save_path(absolute_path, SAVE_PATH):
		return "QA save path must not name or alias the player save: %s" % path
	if DirAccess.dir_exists_absolute(absolute_path):
		return "QA save path names a directory: %s" % path
	return _qa_temp_path_error(absolute_path)


func _detect_qa_entry_path() -> String:
	# Autoloads see engine arguments and user arguments separately. Only exact
	# engine entry switches and the engine's positional main scene are eligible.
	var engine_args := PackedStringArray(OS.get_cmdline_args())
	var script_option := _engine_option_value(engine_args, PackedStringArray(["-s", "--script"]))
	if bool(script_option.get("found", false)):
		return _canonical_existing_qa_entry(str(script_option.get("value", "")), ".gd")
	var scene_option := _engine_option_value(engine_args, PackedStringArray(["--scene"]))
	if bool(scene_option.get("found", false)):
		return _canonical_existing_qa_entry(str(scene_option.get("value", "")), ".tscn")

	var skip_next_value := false
	for raw_arg in engine_args:
		var candidate := String(raw_arg).strip_edges()
		if skip_next_value:
			skip_next_value = false
			continue
		if candidate in ENGINE_OPTIONS_WITH_VALUE:
			skip_next_value = true
			continue
		if candidate.begins_with("-"):
			continue
		if candidate.to_lower().ends_with(".tscn"):
			# The first scene-like positional is the engine's requested main scene.
			return _canonical_existing_qa_entry(candidate, ".tscn")

	# With no CLI entry override, the configured main scene is the real entry.
	var configured_main := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	return _canonical_existing_qa_entry(configured_main, ".tscn")


func _engine_option_value(args: PackedStringArray, option_names: PackedStringArray) -> Dictionary:
	for index in args.size():
		var argument := String(args[index]).strip_edges()
		if option_names.has(argument):
			return {
				"found": true,
				"value": String(args[index + 1]) if index + 1 < args.size() else "",
			}
		for option_name in option_names:
			var prefix := "%s=" % option_name
			if argument.begins_with(prefix):
				return {"found": true, "value": argument.trim_prefix(prefix)}
	return {"found": false, "value": ""}


func _canonical_existing_qa_entry(candidate: String, expected_extension: String) -> String:
	var normalized := candidate.strip_edges().replace("\\", "/")
	if normalized.is_empty():
		return ""
	var absolute_candidate := ""
	if normalized.begins_with("res://"):
		absolute_candidate = ProjectSettings.globalize_path(normalized).replace("\\", "/").simplify_path()
	elif normalized.is_absolute_path():
		absolute_candidate = normalized.simplify_path()
	else:
		while normalized.begins_with("./"):
			normalized = normalized.trim_prefix("./")
		absolute_candidate = ProjectSettings.globalize_path("res://%s" % normalized).replace("\\", "/").simplify_path()
	var project_tools_dir := ProjectSettings.globalize_path("res://tools").replace("\\", "/").simplify_path().trim_suffix("/")
	if not _path_is_within(absolute_candidate, project_tools_dir):
		return ""
	if absolute_candidate.get_extension().to_lower() != expected_extension.trim_prefix("."):
		return ""
	var resource_path := ProjectSettings.localize_path(absolute_candidate).replace("\\", "/")
	if not resource_path.begins_with(QA_RESOURCE_PREFIX):
		return ""
	var parent := DirAccess.open(resource_path.get_base_dir())
	if parent == null or not parent.file_exists(resource_path.get_file()):
		return ""
	if not ResourceLoader.exists(resource_path):
		return ""
	return resource_path


func _is_qa_run() -> bool:
	return not _qa_entry_path.is_empty()


func _reserve_unique_qa_save_path() -> String:
	var temp_root := _qa_safe_temp_root().path_join(QA_TEMP_DIR_NAME)
	var root_error := OK
	if not DirAccess.dir_exists_absolute(temp_root):
		root_error = DirAccess.make_dir_recursive_absolute(temp_root)
	# Another QA process can win the root-directory race between the existence
	# check and creation. Accept that only when the root is now truly a directory.
	if root_error != OK and not DirAccess.dir_exists_absolute(temp_root):
		_startup_save_resolution_error = (
			"cannot create QA save root %s (%s)"
			% [temp_root, error_string(root_error)]
		)
		return ""
	var root_security_error := _qa_temp_path_error(temp_root)
	if not root_security_error.is_empty():
		_startup_save_resolution_error = root_security_error
		return ""
	var entry_name := _qa_entry_path.get_file().get_basename().to_lower()
	# PID alone is reusable and collides across container namespaces. Combine it
	# with wall/monotonic clocks and reserve the directory atomically.
	var run_nonce := "%d-%d-%d-%d-%s" % [
		OS.get_process_id(),
		int(Time.get_unix_time_from_system() * 1000000.0),
		Time.get_ticks_usec(),
		get_instance_id(),
		Crypto.new().generate_random_bytes(12).hex_encode(),
	]
	for attempt in QA_SAVE_RESERVATION_ATTEMPTS:
		var run_dir := temp_root.path_join(
			"%s-%s-%02d" % [entry_name, run_nonce, attempt]
		)
		# make_dir_absolute is the reservation: unlike a PID-derived filename,
		# only one concurrent/reused-PID run can claim this exact directory.
		var reserve_error := DirAccess.make_dir_absolute(run_dir)
		if reserve_error == OK:
			var path_security_error := _qa_temp_path_error(run_dir)
			if not path_security_error.is_empty():
				DirAccess.remove_absolute(run_dir)
				_startup_save_resolution_error = path_security_error
				return ""
			_qa_auto_run_dir = run_dir
			return run_dir.path_join("state.json")
		if reserve_error != ERR_ALREADY_EXISTS:
			_startup_save_resolution_error = (
				"cannot reserve QA save directory %s (%s)"
				% [run_dir, error_string(reserve_error)]
			)
			return ""
	_startup_save_resolution_error = (
		"cannot reserve a unique QA save after %d attempts" % QA_SAVE_RESERVATION_ATTEMPTS
	)
	return ""


func _fail_qa_startup(message: String) -> void:
	_qa_startup_failed = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	var detail := "QA_SAVE_STARTUP_FATAL entry=%s error=%s" % [_qa_entry_path, message]
	push_error(detail)
	printerr(detail)
	get_tree().quit(QA_STARTUP_FAILURE_EXIT_CODE)


func _resolved_save_path(path: String) -> String:
	return _active_save_path if path.is_empty() else path


func _same_save_path(left: String, right: String) -> bool:
	return _filesystem_compare_path(_absolute_save_path(left)) == _filesystem_compare_path(
		_absolute_save_path(right)
	)


func _absolute_save_path(path: String) -> String:
	return ProjectSettings.globalize_path(path).replace("\\", "/").simplify_path()


func _qa_safe_temp_root() -> String:
	return OS.get_temp_dir().replace("\\", "/").simplify_path().trim_suffix("/")


func _path_is_within(path: String, root: String) -> bool:
	var normalized_path := _filesystem_compare_path(path)
	var normalized_root := _filesystem_compare_path(root)
	return normalized_path == normalized_root or normalized_path.begins_with(normalized_root + "/")


func _filesystem_compare_path(path: String) -> String:
	var normalized := path.replace("\\", "/").simplify_path().trim_suffix("/")
	# Default Windows and macOS filesystems compare paths without case. Apply the
	# conservative rule to safety boundaries before touching the disk.
	return normalized.to_lower() if OS.get_name() in ["Windows", "macOS"] else normalized


func _qa_temp_path_error(absolute_path: String) -> String:
	var normalized_path := absolute_path.replace("\\", "/").simplify_path()
	var safe_root := _qa_safe_temp_root()
	# OS.get_temp_dir() is the trust boundary and matches CI's mktemp root. Do
	# not walk above it (macOS itself exposes /var through a system symlink), but
	# reject every symlink controlled by the run beneath that boundary.
	if _same_save_path(normalized_path, safe_root) or not _path_is_within(normalized_path, safe_root):
		return "QA save path must be a file below temporary root %s: %s" % [safe_root, absolute_path]
	var relative_path := normalized_path.substr(safe_root.length()).trim_prefix("/")
	var cursor := safe_root
	for component in relative_path.split("/", false):
		var parent := DirAccess.open(cursor)
		if parent == null:
			# Once an ancestor does not exist, no deeper component can be a link.
			return ""
		if parent.is_link(component):
			return "QA save path crosses symbolic link %s" % cursor.path_join(component)
		cursor = cursor.path_join(component)
	return ""


func _reserve_sibling_transaction_path(absolute_path: String, kind: String) -> String:
	var parent := absolute_path.get_base_dir()
	var filename := absolute_path.get_file()
	# The random suffix makes a same-user symlink race against the not-yet-opened
	# sibling impractical; the deterministic fields remain useful in diagnostics.
	var nonce := "%d-%d-%d-%d-%s" % [
		OS.get_process_id(),
		int(Time.get_unix_time_from_system() * 1000000.0),
		Time.get_ticks_usec(),
		get_instance_id(),
		Crypto.new().generate_random_bytes(16).hex_encode(),
	]
	for attempt in SAVE_TRANSACTION_ATTEMPTS:
		var candidate := parent.path_join(
			".%s.%s-%s-%02d" % [filename, kind, nonce, attempt]
		)
		if not FileAccess.file_exists(candidate) and not DirAccess.dir_exists_absolute(candidate):
			return candidate
	return ""


func _transactionally_replace_save(
	temporary_path: String,
	absolute_path: String,
	expected_text: String,
	display_path: String
) -> Error:
	# Godot's Windows rename implementation removes an existing destination before
	# MoveFileW. Preserve the previous file at a unique sibling first, then publish
	# and verify the replacement. This is a transactional replacement, not a claim
	# of platform-wide atomic overwrite semantics.
	var backup_path := ""
	if DirAccess.dir_exists_absolute(absolute_path):
		DirAccess.remove_absolute(temporary_path)
		push_error("ResearchState: save target is a directory: %s" % display_path)
		return ERR_INVALID_PARAMETER
	if FileAccess.file_exists(absolute_path):
		if _final_component_is_link(absolute_path):
			DirAccess.remove_absolute(temporary_path)
			push_error("ResearchState: refusing save target symbolic link %s" % display_path)
			return ERR_INVALID_PARAMETER
		backup_path = _reserve_sibling_transaction_path(absolute_path, "backup")
		if backup_path.is_empty():
			DirAccess.remove_absolute(temporary_path)
			push_error("ResearchState: cannot reserve save backup beside %s" % display_path)
			return ERR_ALREADY_IN_USE
		var preserve_error := DirAccess.rename_absolute(absolute_path, backup_path)
		if preserve_error != OK:
			DirAccess.remove_absolute(temporary_path)
			push_error(
				"ResearchState: cannot preserve previous save %s (%s)"
				% [display_path, error_string(preserve_error)]
			)
			return preserve_error

	var publish_error := DirAccess.rename_absolute(temporary_path, absolute_path)
	if publish_error != OK:
		_restore_save_backup(absolute_path, backup_path)
		if FileAccess.file_exists(temporary_path):
			DirAccess.remove_absolute(temporary_path)
		push_error(
			"ResearchState: transactional publish failed for %s (%s); previous save remains recoverable"
			% [display_path, error_string(publish_error)]
		)
		return publish_error

	if not _verified_save_file(absolute_path, expected_text):
		_restore_save_backup(absolute_path, backup_path)
		push_error(
			"ResearchState: published save failed verification for %s; previous save remains recoverable"
			% display_path
		)
		return ERR_FILE_CORRUPT

	# Only a verified new target makes the previous copy redundant. A cleanup
	# failure is non-fatal and leaves another valid recovery copy beside it.
	if not backup_path.is_empty() and FileAccess.file_exists(backup_path):
		var cleanup_error := DirAccess.remove_absolute(backup_path)
		if cleanup_error != OK:
			push_warning(
				"ResearchState: verified save published but backup cleanup failed: %s"
				% backup_path
			)
	_cleanup_save_backups(absolute_path)
	return OK


func _restore_save_backup(absolute_path: String, backup_path: String) -> void:
	if backup_path.is_empty() or not FileAccess.file_exists(backup_path):
		return
	var displaced_path := ""
	if FileAccess.file_exists(absolute_path):
		displaced_path = _reserve_sibling_transaction_path(absolute_path, "failed")
		if displaced_path.is_empty():
			push_error(
				"ResearchState: cannot reserve failed-save sibling; original remains at %s"
				% backup_path
			)
			return
		var displace_error := DirAccess.rename_absolute(absolute_path, displaced_path)
		if displace_error != OK:
			push_error(
				"ResearchState: cannot move failed replacement; original remains at %s"
				% backup_path
			)
			return
	elif DirAccess.dir_exists_absolute(absolute_path):
		push_error(
			"ResearchState: replacement path became a directory; original remains at %s"
			% backup_path
		)
		return
	var restore_error := DirAccess.rename_absolute(backup_path, absolute_path)
	if restore_error != OK:
		push_error(
			"ResearchState: restore failed; original remains at %s (%s)"
			% [backup_path, error_string(restore_error)]
		)
		return
	print("SAVE_TRANSACTION_RESTORED path=%s" % absolute_path)
	if not displaced_path.is_empty() and FileAccess.file_exists(displaced_path):
		DirAccess.remove_absolute(displaced_path)


func _recover_orphaned_save_backup(absolute_path: String) -> Error:
	if FileAccess.file_exists(absolute_path):
		return OK
	if DirAccess.dir_exists_absolute(absolute_path):
		return ERR_INVALID_PARAMETER
	var parent_path := absolute_path.get_base_dir()
	var directory := DirAccess.open(parent_path)
	if directory == null:
		return OK
	directory.include_hidden = true
	var prefix := ".%s.backup-" % absolute_path.get_file()
	var backups: Array[String] = []
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if _filesystem_compare_path(entry).begins_with(_filesystem_compare_path(prefix)):
			if directory.current_is_dir() or directory.is_link(entry):
				directory.list_dir_end()
				return ERR_INVALID_PARAMETER
			var candidate := parent_path.path_join(entry)
			if _verified_save_file(candidate):
				backups.append(candidate)
		entry = directory.get_next()
	directory.list_dir_end()
	if backups.is_empty():
		return OK
	backups.sort_custom(func(left: String, right: String) -> bool:
		return FileAccess.get_modified_time(left) > FileAccess.get_modified_time(right)
	)
	var recovery_path := backups[0]
	var recovery_error := DirAccess.rename_absolute(recovery_path, absolute_path)
	if recovery_error != OK:
		return recovery_error
	if not _verified_save_file(absolute_path):
		return ERR_FILE_CORRUPT
	print("SAVE_TRANSACTION_RECOVERED path=%s backup=%s" % [absolute_path, recovery_path])
	return OK


func _verified_save_file(path: String, expected_text: String = "") -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() <= 0:
		return false
	var text := file.get_as_text()
	file.close()
	if not expected_text.is_empty() and text != expected_text:
		return false
	var parsed: Variant = JSON.parse_string(text)
	return parsed is Dictionary and _snapshot_schema_error(parsed).is_empty()


func _cleanup_save_backups(absolute_path: String) -> void:
	# Callers invoke this only after the target itself has been reopened and
	# validated, so a leftover sibling is no longer the only good copy.
	var directory := DirAccess.open(absolute_path.get_base_dir())
	if directory == null:
		return
	directory.include_hidden = true
	var prefix := ".%s.backup-" % absolute_path.get_file()
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if (
			_filesystem_compare_path(entry).begins_with(_filesystem_compare_path(prefix))
			and not directory.current_is_dir()
			and not directory.is_link(entry)
		):
			DirAccess.remove_absolute(absolute_path.get_base_dir().path_join(entry))
		entry = directory.get_next()
	directory.list_dir_end()


func _final_component_is_link(absolute_path: String) -> bool:
	var parent := DirAccess.open(absolute_path.get_base_dir())
	return parent != null and parent.is_link(absolute_path.get_file())


func _ensure_save_parent(path: String) -> Error:
	var parent_path := path.get_base_dir()
	if parent_path.is_empty():
		return OK
	var absolute_parent := ProjectSettings.globalize_path(parent_path)
	if DirAccess.dir_exists_absolute(absolute_parent):
		return OK
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_parent)
	if directory_error != OK:
		push_error(
			"ResearchState: cannot create save directory %s (%s)"
			% [parent_path, error_string(directory_error)]
		)
	return directory_error


func _cleanup_owned_qa_run() -> void:
	if not _qa_uses_auto_save_path or _qa_auto_run_dir.is_empty():
		return
	var owned_root := _qa_safe_temp_root().path_join(QA_TEMP_DIR_NAME)
	if _qa_auto_run_dir == owned_root or not _path_is_within(_qa_auto_run_dir, owned_root):
		push_warning("ResearchState: refusing cleanup outside owned QA root: %s" % _qa_auto_run_dir)
		return
	var security_error := _qa_temp_path_error(_qa_auto_run_dir)
	if not security_error.is_empty():
		push_warning("ResearchState: refusing unsafe QA cleanup: %s" % security_error)
		return
	_remove_owned_directory_tree(_qa_auto_run_dir)
	# Multiple QA processes share only this empty container directory. Removing
	# it is safe when empty and harmlessly fails while another run still owns it.
	DirAccess.remove_absolute(owned_root)
	_qa_auto_run_dir = ""


func _remove_owned_directory_tree(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	directory.include_hidden = true
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var child_path := directory_path.path_join(entry)
			if directory.current_is_dir() and not directory.is_link(entry):
				_remove_owned_directory_tree(child_path)
			else:
				DirAccess.remove_absolute(child_path)
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(directory_path)


func grant_demo_rewards(rewards: Dictionary, discovery_flag: String = "", persist: bool = true) -> void:
	grant_mission_rewards(rewards, discovery_flag, "L03", &"MISSION-01", persist)


func grant_mission_rewards(
	rewards: Dictionary,
	discovery_flag: String,
	campaign_level: String,
	mission_id: StringName,
	persist: bool = true
) -> void:
	for key in rewards.keys():
		if not DEMO_RESOURCES.has(key):
			continue
		resources[key] = maxi(int(resources.get(key, 0)) + int(rewards[key]), 0)
	if not discovery_flag.is_empty() and not discovery_flags.has(discovery_flag):
		discovery_flags.append(discovery_flag)
	if VALID_MISSIONS.has(String(mission_id)) and not completed_mission_ids.has(mission_id):
		completed_mission_ids.append(mission_id)
	if campaign_rank(unlocked_campaign_level) < campaign_rank(campaign_level):
		unlocked_campaign_level = "L0%d" % campaign_rank(campaign_level)
	state_changed.emit()
	if persist:
		save_game()


func configure_demo_run(mission_id: StringName, family_id: StringName) -> bool:
	if not VALID_MISSIONS.has(String(mission_id)) or not VALID_FAMILIES.has(String(family_id)):
		return false
	selected_mission_id = mission_id
	selected_family_id = family_id
	state_changed.emit()
	return save_game() == OK


func _snapshot_schema_error(data: Dictionary) -> String:
	for field in SAVE_REQUIRED_V1_FIELDS:
		if not data.has(field):
			return "missing required field %s" % field
	var version_value: Variant = data["version"]
	if not _is_integral_number(version_value):
		return "version must be an integer number"
	var version := int(version_value)
	if version != 1 and version != SAVE_VERSION:
		return "unsupported save version %d" % version
	if version == SAVE_VERSION:
		for field in SAVE_REQUIRED_V2_FIELDS:
			if not data.has(field):
				return "missing required v2 field %s" % field

	for field in ["completedNodeIds", "revealedNodeIds", "trackedNodeIds", "discoveryFlags"]:
		var array_error := _string_array_schema_error(data[field], field)
		if not array_error.is_empty():
			return array_error
	for field in ["selectedNodeId", "unlockedCampaignLevel"]:
		if not data[field] is String:
			return "%s must be a string" % field

	var resources_value: Variant = data["resources"]
	if not resources_value is Dictionary:
		return "resources must be an object"
	var loaded_resources := resources_value as Dictionary
	for required_resource in DEMO_RESOURCES:
		if not loaded_resources.has(required_resource):
			return "resources is missing %s" % required_resource
	for resource_key in loaded_resources:
		if not resource_key is String:
			return "resource keys must be strings"
		var resource_value: Variant = loaded_resources[resource_key]
		if not _is_integral_number(resource_value) or int(resource_value) < 0:
			return "resource %s must be a non-negative integer" % resource_key

	# v1 legitimately lacks these mission fields. If a producer included any of
	# them early, validate it rather than letting migration/defaulting coerce it.
	for field in ["selectedMissionId", "selectedFamilyId"]:
		if data.has(field) and not data[field] is String:
			return "%s must be a string" % field
	if data.has("completedMissionIds"):
		var mission_array_error := _string_array_schema_error(
			data["completedMissionIds"], "completedMissionIds"
		)
		if not mission_array_error.is_empty():
			return mission_array_error
	return ""


func _string_array_schema_error(value: Variant, field: String) -> String:
	if not value is Array:
		return "%s must be an array" % field
	for item in value:
		if not item is String:
			return "%s entries must be strings" % field
	return ""


func _is_integral_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT:
		return false
	var number := float(value)
	return is_finite(number) and number == floorf(number)


func _migrate_snapshot(raw_data: Dictionary) -> Dictionary:
	var data := raw_data.duplicate(true)
	# The caller has already checked the complete v1/v2 schema. Migration is now
	# deliberately narrow: an absent/invalid version never becomes v1 by default.
	var version := int(data["version"])
	while version < SAVE_VERSION:
		match version:
			1:
				data["selectedMissionId"] = data.get("selectedMissionId", "MISSION-01")
				data["selectedFamilyId"] = data.get("selectedFamilyId", "T")
				data["completedMissionIds"] = data.get("completedMissionIds", [])
				data["version"] = 2
				version = 2
			_:
				push_warning("ResearchState: no migration from save version %d" % version)
				return {}
	return data


func _valid_choice(value: Variant, allowed: PackedStringArray, fallback: StringName) -> StringName:
	var text := str(value)
	return StringName(text) if allowed.has(text) else fallback


func _valid_choices(values: Variant, allowed: PackedStringArray) -> Array[StringName]:
	var out: Array[StringName] = []
	for value in _as_names(values):
		if allowed.has(String(value)) and not out.has(value):
			out.append(value)
	return out


func _as_strings(values: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(String(value))
	return out


func _as_names(values: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if values is Array or values is PackedStringArray:
		for value in values:
			out.append(StringName(str(value)))
	return out


func _valid_names(values: Variant, limit: int = 0) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in _as_names(values):
		if id == &"" or out.has(id) or Catalog.get_node_def(id).is_empty():
			continue
		out.append(id)
		if limit > 0 and out.size() >= limit:
			break
	return out


const STAT_CAPS := {
	"attackSpeed": 0.22,
	"moveSpeed": 0.18,
	"cooldown": 0.15,
	"coreRegen": 0.16,
	"unitRegen": 0.16,
	"biomassYield": 0.16,
	"critChance": 0.1,
	"weaknessAmp": 0.12,
	"armorShred": 0.12,
	"enemySlow": 0.16,
	"pathSlow": 0.1,
}


func global_stat(stat: String, duty: StringName = &"") -> float:
	var total := float(global_stats.get(stat, 0.0))
	if duty != &"":
		total += float(global_stats.get("%s:%s" % [stat, String(duty)], 0.0))
	if STAT_CAPS.has(stat):
		return minf(total, float(STAT_CAPS[stat]))
	return total


func _apply_global_stat(op_entry: Dictionary) -> void:
	var stat := str(op_entry.get("stat", ""))
	if stat == "":
		return
	var amount := float(op_entry.get("amount", 0.0))
	var duty := str(op_entry.get("duty", ""))
	var key := stat if duty.is_empty() else "%s:%s" % [stat, duty]
	global_stats[key] = float(global_stats.get(key, 0.0)) + amount


func _rebuild_global_stats() -> void:
	global_stats.clear()
	for id in completed_node_ids:
		var node: Dictionary = Catalog.get_node_def(id)
		if node.is_empty():
			continue
		for op_entry in node.get("effectOps", []):
			if op_entry is Dictionary and str(op_entry.get("op", "")) == "grant_global_stat":
				_apply_global_stat(op_entry)


func is_completed(id: StringName) -> bool:
	return completed_node_ids.has(id)


func is_revealed(id: StringName) -> bool:
	return revealed_node_ids.has(id) or is_completed(id)


func select_node(id: StringName) -> void:
	selected_node_id = id
	selection_changed.emit(id)
	state_changed.emit()
	save_game()


func toggle_track(id: StringName) -> bool:
	if not is_revealed(id):
		return false
	if tracked_node_ids.has(id):
		tracked_node_ids.erase(id)
		state_changed.emit()
		save_game()
		return true
	if tracked_node_ids.size() >= 3:
		return false
	tracked_node_ids.append(id)
	state_changed.emit()
	save_game()
	return true


func complete_node(id: StringName) -> bool:
	if is_completed(id):
		return false
	var runtime := derive_state(id)
	if str(runtime.get("eligibility", "")) != "ready":
		return false
	var node: Dictionary = Catalog.get_node_def(id)
	_deduct_costs(node)
	completed_node_ids.append(id)
	if not revealed_node_ids.has(id):
		revealed_node_ids.append(id)
	_reveal_from(id)
	node_completed.emit(id)
	_grant_from_node(id)
	state_changed.emit()
	save_game()
	return true


func derive_state(id: StringName) -> Dictionary:
	var node: Dictionary = Catalog.get_node_def(id)
	if node.is_empty():
		return {"visibility": "hidden", "completion": "incomplete", "eligibility": "hidden"}
	var visibility := "revealed" if is_revealed(id) else "hidden"
	if visibility == "hidden" and _reveal_rule_met(node):
		visibility = "revealed"
	var completion := "complete" if is_completed(id) else "incomplete"
	var eligibility := "hidden"
	if completion == "complete":
		eligibility = "completed"
	elif visibility == "hidden":
		eligibility = "hidden"
	elif not _prerequisites_met(node):
		eligibility = "missing_prerequisite"
	elif not _conditions_met(node):
		eligibility = "missing_condition"
	elif not _resources_met(node):
		eligibility = "missing_resource"
	else:
		eligibility = "ready"
	return {
		"visibility": visibility,
		"completion": completion,
		"eligibility": eligibility,
		"tracked": tracked_node_ids.has(id),
		"selected": selected_node_id == id,
	}


func _prerequisites_met(node: Dictionary) -> bool:
	var groups: Array = node.get("prerequisiteGroups", [])
	for group in groups:
		if not group is Dictionary:
			continue
		var ids: Array = group.get("nodeIds", [])
		var done := 0
		for pid in ids:
			if is_completed(StringName(str(pid))):
				done += 1
		if str(group.get("mode", "all")) == "atLeast":
			if done < int(group.get("min", 1)):
				return false
		elif done != ids.size():
			return false
	return true


func campaign_rank(id: String) -> int:
	var text := id.strip_edges().to_upper()
	if text.begins_with("L"):
		text = text.substr(1)
	var n := int(text)
	if n < 1:
		return 1
	return mini(n, 6)


func set_unlocked_campaign_level(id: String) -> void:
	var rank := campaign_rank(id)
	unlocked_campaign_level = "L0%d" % rank
	state_changed.emit()
	save_game()


func _conditions_met(node: Dictionary) -> bool:
	for condition in node.get("conditions", []):
		if condition is Dictionary and not _evaluate_condition(condition):
			return false
	return true


func _evaluate_condition(condition: Dictionary) -> bool:
	match str(condition.get("type", "")):
		"campaign_level":
			return campaign_rank(unlocked_campaign_level) >= campaign_rank(str(condition.get("min", "L01")))
		"discovery_flag", "discoveryFlag":
			return str(condition.get("flag", "")) in discovery_flags
		_:
			return true


func _unmet_condition_label(node: Dictionary) -> String:
	for condition in node.get("conditions", []):
		if not condition is Dictionary:
			continue
		if _evaluate_condition(condition):
			continue
		var ctype := str(condition.get("type", ""))
		if ctype == "campaign_level":
			return TranslationServer.translate(&"RESEARCH_STATUS_REQUIRES_MISSION") % str(condition.get("min", ""))
		if ctype == "discovery_flag" or ctype == "discoveryFlag":
			return TranslationServer.translate(&"RESEARCH_STATUS_REQUIRES_DISCOVERY")
	return TranslationServer.translate(&"RESEARCH_STATUS_MISSING_CONDITION")


func eligibility_label(runtime: Dictionary, node: Dictionary) -> String:
	match str(runtime.get("eligibility", "")):
		"completed":
			return TranslationServer.translate(&"RESEARCH_STATUS_COMPLETED")
		"ready":
			return TranslationServer.translate(&"RESEARCH_STATUS_READY")
		"missing_resource":
			return TranslationServer.translate(&"RESEARCH_STATUS_MISSING_RESOURCE")
		"missing_prerequisite":
			return TranslationServer.translate(&"RESEARCH_STATUS_MISSING_PREREQUISITE")
		"missing_condition":
			return _unmet_condition_label(node)
		"hidden":
			return TranslationServer.translate(&"RESEARCH_STATUS_HIDDEN")
		_:
			return TranslationServer.translate(&"RESEARCH_STATUS_LOCKED")


func _reveal_rule_met(node: Dictionary) -> bool:
	var rule: Dictionary = node.get("revealRule", {"type": "on_prerequisite_visible"})
	match str(rule.get("type", "on_prerequisite_visible")):
		"always":
			return true
		"on_prerequisite_visible":
			var groups: Array = node.get("prerequisiteGroups", [])
			if groups.is_empty():
				return true
			for group in groups:
				for pid in group.get("nodeIds", []):
					if not is_revealed(StringName(str(pid))):
						return false
			return true
		"completed", "anyCompleted":
			for pid in rule.get("nodeIds", []):
				if is_completed(StringName(str(pid))):
					return true
			return false
		_:
			return is_revealed(StringName(str(node.get("id", ""))))


func _resources_met(node: Dictionary) -> bool:
	for key in _normalize_costs(node).keys():
		if int(resources.get(key, 0)) < int(_normalize_costs(node)[key]):
			return false
	return true


func _normalize_costs(node: Dictionary) -> Dictionary:
	var out := {}
	var costs: Variant = node.get("costs", [])
	if costs is Array:
		for entry in costs:
			if entry is Dictionary and entry.has("resource"):
				out[str(entry.get("resource"))] = int(entry.get("amount", 0))
	elif costs is Dictionary:
		for key in (costs as Dictionary).keys():
			out[str(key)] = int((costs as Dictionary)[key])
	return out


func cost_table(node: Dictionary) -> Dictionary:
	return _normalize_costs(node)


func _deduct_costs(node: Dictionary) -> void:
	var costs := _normalize_costs(node)
	for key in costs.keys():
		resources[key] = int(resources.get(key, 0)) - int(costs[key])


func _reveal_from(_completed_id: StringName) -> void:
	for node in Catalog.all_nodes():
		if not node is Dictionary:
			continue
		var nid := StringName(str(node.get("id", "")))
		if is_revealed(nid):
			continue
		if _reveal_rule_met(node):
			revealed_node_ids.append(nid)


func _grant_from_node(id: StringName) -> void:
	var node: Dictionary = Catalog.get_node_def(id)
	if node.is_empty():
		return
	var ops: Array = node.get("effectOps", [])
	for op_entry in ops:
		var op := str(op_entry.get("op", ""))
		var family := StringName(str(op_entry.get("familyId", "")))
		match op:
			"grant_character_usage":
				skill_granted.emit(StringName("SKILL-%s-ACTIVE" % String(family)))
			"grant_core_passive":
				skill_granted.emit(StringName("SKILL-%s-PASSIVE" % String(family)))
			"grant_fixed_turret":
				duty_unlocked.emit(family, &"fixed")
				skill_granted.emit(StringName("SKILL-%s-FIXED" % String(family)))
			"grant_mobility":
				duty_unlocked.emit(family, &"mobile")
			"grant_relay_qualification":
				duty_unlocked.emit(family, &"relay")
			"grant_ultimate":
				skill_granted.emit(StringName("SKILL-%s-APEX" % String(family)))
			"grant_global_stat":
				if op_entry is Dictionary:
					_apply_global_stat(op_entry)
