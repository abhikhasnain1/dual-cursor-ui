@tool
extends EditorPlugin

const DualCursorManagerScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_manager.gd")
const DualCursorScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor.gd")
const DualCursorInteractableScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_interactable.gd")
const DualCursorButtonScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_button.gd")
const DualCursorScrollAreaScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_scroll_area.gd")
const DualCursorDockScript := preload("res://addons/dual_cursor_ui/editor/dual_cursor_dock.gd")

var _dock: Control

func _enter_tree() -> void:
	add_custom_type("DualCursorManager", "Node", DualCursorManagerScript, null)
	add_custom_type("DualCursor", "Sprite2D", DualCursorScript, null)
	add_custom_type("DualCursorInteractable", "Control", DualCursorInteractableScript, null)
	add_custom_type("DualCursorButton", "Control", DualCursorButtonScript, null)
	add_custom_type("DualCursorScrollArea", "ScrollContainer", DualCursorScrollAreaScript, null)

	_dock = DualCursorDockScript.new()
	_dock.name = "DualCursor UI"
	_dock.setup(self)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)

func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null

	remove_custom_type("DualCursorScrollArea")
	remove_custom_type("DualCursorButton")
	remove_custom_type("DualCursorInteractable")
	remove_custom_type("DualCursor")
	remove_custom_type("DualCursorManager")
