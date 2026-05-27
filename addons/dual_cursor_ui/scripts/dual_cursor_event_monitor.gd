@tool
class_name DualCursorEventMonitor
extends Control

const MANAGER_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_manager.gd"
const NAVIGATION_PANEL_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_navigation_panel.gd"
const GRID_NAVIGATION_PANEL_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_grid_navigation_panel.gd"
const DIALOGUE_PANEL_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_dialogue_panel.gd"
const NARRATIVE_ROUTER_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_narrative_router.gd"

@export var enabled: bool = false:
	set(value):
		enabled = value
		visible = value
		set_process(value)
@export var max_events: int = 80
@export var show_hover_events: bool = false
@export var show_navigation_events: bool = true
@export var show_activation_events: bool = true
@export var show_denial_events: bool = true
@export var show_narrative_events: bool = true

var _log: RichTextLabel
var _events: PackedStringArray = PackedStringArray()
var _bound_nodes: Dictionary = {}
var _event_index: int = 0
var _refresh_timer: float = 0.0

func _ready() -> void:
	add_to_group("dual_cursor_event_monitor")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)
	visible = enabled
	set_process(enabled)
	_ensure_ui()
	refresh_bindings()

func _process(delta: float) -> void:
	if not enabled:
		return
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.6
		refresh_bindings()

func clear_events() -> void:
	_events.clear()
	_event_index = 0
	if _log:
		_log.clear()

func log_event(message: String) -> void:
	_event_index += 1
	var line: String = "#%03d %s" % [_event_index, message]
	_events.append(line)
	while _events.size() > max(1, max_events):
		_events.remove_at(0)
	_render_events()

func refresh_bindings() -> void:
	var root: Node = _search_root()
	if root == null:
		return
	for manager in _find_by_script_path(root, MANAGER_SCRIPT_PATH):
		_bind_manager(manager)
	for panel in _find_navigation_panels(root):
		_bind_panel(panel)
	for router in _find_by_script_path(root, NARRATIVE_ROUTER_SCRIPT_PATH):
		_bind_router(router)

func _ensure_ui() -> void:
	if _log:
		return
	_log = RichTextLabel.new()
	_log.name = "EventLog"
	_log.position = Vector2(24, 24)
	_log.size = Vector2(620, 220)
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.add_theme_color_override("default_color", Color(0.92, 0.96, 1.0, 1.0))
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.08, 0.82)
	style.border_color = Color(0.2, 0.52, 0.85, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	_log.add_theme_stylebox_override("normal", style)
	add_child(_log)

func _bind_manager(manager: Node) -> void:
	if _bound_nodes.has(manager):
		return
	_bound_nodes[manager] = true
	if manager.has_signal("hover_started"):
		_connect_if_needed(manager, "hover_started", "_on_hover_started")
	if manager.has_signal("hover_ended"):
		_connect_if_needed(manager, "hover_ended", "_on_hover_ended")
	if manager.has_signal("interacted"):
		_connect_if_needed(manager, "interacted", "_on_interacted")
	if manager.has_signal("denied"):
		_connect_if_needed(manager, "denied", "_on_denied")
	if manager.has_signal("navigation_entered"):
		_connect_if_needed(manager, "navigation_entered", "_on_navigation_entered")
	if manager.has_signal("navigation_exited"):
		_connect_if_needed(manager, "navigation_exited", "_on_navigation_exited")
	if manager.has_signal("navigation_selection_changed"):
		_connect_if_needed(manager, "navigation_selection_changed", "_on_navigation_selection_changed")
	if manager.has_signal("navigation_target_activated"):
		_connect_if_needed(manager, "navigation_target_activated", "_on_navigation_target_activated")
	if manager.has_signal("navigation_denied"):
		_connect_if_needed(manager, "navigation_denied", "_on_navigation_denied")

func _bind_panel(panel: Node) -> void:
	if _bound_nodes.has(panel):
		return
	_bound_nodes[panel] = true
	if panel.has_signal("choice_selected"):
		_connect_if_needed(panel, "choice_selected", "_on_choice_selected")

func _bind_router(router: Node) -> void:
	if _bound_nodes.has(router):
		return
	_bound_nodes[router] = true
	if router.has_signal("narrative_event"):
		_connect_if_needed(router, "narrative_event", "_on_narrative_event")

func _connect_if_needed(node: Node, signal_name: StringName, method_name: StringName) -> void:
	var callable := Callable(self, method_name)
	if not node.is_connected(signal_name, callable):
		node.connect(signal_name, callable)

func _on_hover_started(player_id: int, target: Control) -> void:
	if show_hover_events:
		log_event("P%d hover %s" % [player_id + 1, target.name])

func _on_hover_ended(player_id: int, target: Control) -> void:
	if show_hover_events:
		log_event("P%d leave %s" % [player_id + 1, target.name])

func _on_interacted(player_id: int, target: Control) -> void:
	if show_activation_events:
		log_event("P%d interacted %s" % [player_id + 1, target.name])

func _on_denied(player_id: int, target: Control, reason: String) -> void:
	if show_denial_events:
		log_event("P%d denied %s: %s" % [player_id + 1, target.name, reason])

func _on_navigation_entered(player_id: int, panel: Control) -> void:
	if show_navigation_events:
		log_event("P%d entered %s" % [player_id + 1, panel.name])

func _on_navigation_exited(player_id: int, panel: Control) -> void:
	if show_navigation_events:
		log_event("P%d exited %s" % [player_id + 1, panel.name])

func _on_navigation_selection_changed(player_id: int, panel: Control, target: Control) -> void:
	if show_navigation_events:
		log_event("P%d selected %s > %s" % [player_id + 1, panel.name, target.name])

func _on_navigation_target_activated(player_id: int, panel: Control, target: Control) -> void:
	if show_activation_events:
		log_event("P%d activated %s > %s" % [player_id + 1, panel.name, target.name])

func _on_navigation_denied(player_id: int, panel: Control, reason: String) -> void:
	if show_denial_events:
		log_event("P%d cannot enter %s: %s" % [player_id + 1, panel.name, reason])

func _on_choice_selected(player_id: int, choice_id: String, choice_data: Dictionary, cursor: Node) -> void:
	if show_narrative_events:
		log_event("P%d choice %s" % [player_id + 1, choice_id])

func _on_narrative_event(player_id: int, event_type: String, event_id: String, payload: Dictionary, cursor: Node) -> void:
	if show_narrative_events:
		log_event("P%d %s %s" % [player_id + 1, event_type, event_id])

func _render_events() -> void:
	if _log == null:
		return
	_log.clear()
	for event_line in _events:
		_log.append_text(event_line + "\n")
	if _log.get_line_count() > 0:
		_log.scroll_to_line(_log.get_line_count() - 1)

func _find_navigation_panels(root: Node) -> Array:
	var panels: Array = _find_by_script_path(root, NAVIGATION_PANEL_SCRIPT_PATH)
	panels.append_array(_find_by_script_path(root, GRID_NAVIGATION_PANEL_SCRIPT_PATH))
	panels.append_array(_find_by_script_path(root, DIALOGUE_PANEL_SCRIPT_PATH))
	return panels

func _search_root() -> Node:
	if owner:
		return owner
	if get_tree().current_scene:
		return get_tree().current_scene
	return get_tree().root

func _find_by_script_path(root: Node, script_path: String) -> Array:
	var matches: Array = []
	if root == null:
		return matches
	for node in _walk(root):
		var script: Script = node.get_script() as Script
		if script and script.resource_path == script_path:
			matches.append(node)
	return matches

func _walk(root: Node) -> Array:
	var nodes: Array = [root]
	for child in root.get_children():
		nodes.append_array(_walk(child))
	return nodes
