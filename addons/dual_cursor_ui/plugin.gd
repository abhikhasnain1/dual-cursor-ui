@tool
extends EditorPlugin

const DualCursorManagerScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_manager.gd")
const DualCursorScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor.gd")
const DualCursorInteractableScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_interactable.gd")
const DualCursorButtonScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_button.gd")
const DualCursorScrollAreaScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_scroll_area.gd")
const DualCursorNavigationPanelScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_navigation_panel.gd")
const DualCursorGridNavigationPanelScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_grid_navigation_panel.gd")
const DualCursorDialoguePanelScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_dialogue_panel.gd")
const DualCursorNarrativeRouterScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_narrative_router.gd")
const DualCursorEventMonitorScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_event_monitor.gd")
const DualCursorToggleAdapterScript := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_toggle_adapter.gd")
const DualCursorSliderAdapterScript := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_slider_adapter.gd")
const DualCursorVerticalSliderAdapterScript := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_vertical_slider_adapter.gd")
const DualCursorOptionAdapterScript := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_option_adapter.gd")
const DualCursorTabAdapterScript := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_tab_adapter.gd")
const DualCursorSpinBoxAdapterScript := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_spin_box_adapter.gd")
const DualCursorInputSetup := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_input_setup.gd")
const DualCursorDockScene := preload("res://addons/dual_cursor_ui/editor/dual_cursor_dock.tscn")

var _dock: Control

func _enter_tree() -> void:
	add_custom_type("DualCursorManager", "Node", DualCursorManagerScript, null)
	add_custom_type("DualCursor", "Sprite2D", DualCursorScript, null)
	add_custom_type("DualCursorInteractable", "Control", DualCursorInteractableScript, null)
	add_custom_type("DualCursorButton", "Control", DualCursorButtonScript, null)
	add_custom_type("DualCursorScrollArea", "ScrollContainer", DualCursorScrollAreaScript, null)
	add_custom_type("DualCursorNavigationPanel", "Control", DualCursorNavigationPanelScript, null)
	add_custom_type("DualCursorGridNavigationPanel", "Control", DualCursorGridNavigationPanelScript, null)
	add_custom_type("DualCursorDialoguePanel", "Control", DualCursorDialoguePanelScript, null)
	add_custom_type("DualCursorNarrativeRouter", "Node", DualCursorNarrativeRouterScript, null)
	add_custom_type("DualCursorEventMonitor", "Control", DualCursorEventMonitorScript, null)
	add_custom_type("DualCursorToggleAdapter", "CheckBox", DualCursorToggleAdapterScript, null)
	add_custom_type("DualCursorSliderAdapter", "HSlider", DualCursorSliderAdapterScript, null)
	add_custom_type("DualCursorVerticalSliderAdapter", "VSlider", DualCursorVerticalSliderAdapterScript, null)
	add_custom_type("DualCursorOptionAdapter", "OptionButton", DualCursorOptionAdapterScript, null)
	add_custom_type("DualCursorTabAdapter", "TabContainer", DualCursorTabAdapterScript, null)
	add_custom_type("DualCursorSpinBoxAdapter", "SpinBox", DualCursorSpinBoxAdapterScript, null)

	DualCursorInputSetup.ensure_default_actions(true)

	_dock = DualCursorDockScene.instantiate()
	_dock.name = "DualCursor UI"
	_dock.call("setup", self)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)

func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null

	remove_custom_type("DualCursorSpinBoxAdapter")
	remove_custom_type("DualCursorTabAdapter")
	remove_custom_type("DualCursorOptionAdapter")
	remove_custom_type("DualCursorVerticalSliderAdapter")
	remove_custom_type("DualCursorSliderAdapter")
	remove_custom_type("DualCursorToggleAdapter")
	remove_custom_type("DualCursorEventMonitor")
	remove_custom_type("DualCursorNarrativeRouter")
	remove_custom_type("DualCursorDialoguePanel")
	remove_custom_type("DualCursorGridNavigationPanel")
	remove_custom_type("DualCursorNavigationPanel")
	remove_custom_type("DualCursorScrollArea")
	remove_custom_type("DualCursorButton")
	remove_custom_type("DualCursorInteractable")
	remove_custom_type("DualCursor")
	remove_custom_type("DualCursorManager")
