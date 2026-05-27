@tool
class_name DualCursorNarrativeExampleLogger
extends Node

@export var router_path: NodePath
@export var log_label_path: NodePath
@export var clock_label_path: NodePath

var _event_index: int = 0
var _clock_progress: int = 0

func _ready() -> void:
	var router: Node = get_node_or_null(router_path)
	if router and router.has_signal("narrative_event"):
		var callback: Callable = Callable(self, "_on_narrative_event")
		if not router.is_connected("narrative_event", callback):
			router.connect("narrative_event", callback)
	var scan_root: Node = owner if owner else get_tree().current_scene
	if scan_root:
		_watch_tree(scan_root)

func watch_panel(panel: Control) -> void:
	if panel == null:
		return
	if panel.has_signal("target_activated"):
		var target_callback: Callable = Callable(self, "_on_target_activated")
		if not panel.is_connected("target_activated", target_callback):
			panel.connect("target_activated", target_callback)
	if panel.has_signal("choice_selected"):
		var choice_callback: Callable = Callable(self, "_on_choice_selected")
		if not panel.is_connected("choice_selected", choice_callback):
			panel.connect("choice_selected", choice_callback)

func _watch_tree(node: Node) -> void:
	if node is Control:
		watch_panel(node as Control)
	for child in node.get_children():
		_watch_tree(child)

func _on_target_activated(player_id: int, target: Control, cursor: Node) -> void:
	var router: Node = get_node_or_null(router_path)
	if router and router.has_method("route_panel_target"):
		router.route_panel_target(player_id, target, cursor)
	else:
		_append_log("P%d activated %s" % [player_id + 1, target.name])

func _on_choice_selected(player_id: int, choice_id: String, choice_data: Dictionary, cursor: Node) -> void:
	_append_log("P%d dialogue choice: %s" % [player_id + 1, choice_id])

func _on_narrative_event(player_id: int, event_type: String, event_id: String, payload: Dictionary, cursor: Node) -> void:
	if event_type == "skill_check" or payload.has("clock_id"):
		_clock_progress = min(6, _clock_progress + 1)
		var clock_label: Label = get_node_or_null(clock_label_path) as Label
		if clock_label:
			clock_label.text = "Clock: %d/6" % _clock_progress
	_append_log("P%d %s -> %s" % [player_id + 1, event_type, event_id])

func _append_log(message: String) -> void:
	_event_index += 1
	var line: String = "#%03d %s" % [_event_index, message]
	print(line)
	var log_label: RichTextLabel = get_node_or_null(log_label_path) as RichTextLabel
	if log_label:
		log_label.append_text(line + "\n")
		call_deferred("_scroll_log")

func _scroll_log() -> void:
	var log_label: RichTextLabel = get_node_or_null(log_label_path) as RichTextLabel
	if log_label and log_label.get_line_count() > 0:
		log_label.scroll_to_line(log_label.get_line_count() - 1)
