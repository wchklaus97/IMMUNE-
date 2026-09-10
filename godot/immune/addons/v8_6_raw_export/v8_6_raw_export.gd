@tool
extends EditorPlugin

const _ExportPlugin := preload("res://addons/v8_6_raw_export/v8_6_raw_export_plugin.gd")

var _export_plugin: EditorExportPlugin


func _enter_tree() -> void:
	if _export_plugin != null:
		return
	_export_plugin = _ExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	if _export_plugin == null:
		return
	remove_export_plugin(_export_plugin)
	_export_plugin = null
