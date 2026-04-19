@tool
extends EditorPlugin

var _panel: Control

func _enter_tree() -> void:
	_panel = preload("res://addons/theme_generator/theme_generator_panel.gd").new()
	_panel.name = "ThemeGenerator"
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _panel)

func _exit_tree() -> void:
	remove_control_from_docks(_panel)
	_panel.queue_free()
	_panel = null
