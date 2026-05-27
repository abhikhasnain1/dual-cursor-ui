@tool
class_name DualCursorDebugOverlay
extends Control

const CURSOR_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor.gd"
const NAVIGATION_PANEL_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_navigation_panel.gd"
const GRID_NAVIGATION_PANEL_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_grid_navigation_panel.gd"

@export var enabled: bool = false:
	set(value):
		enabled = value
		visible = value
		queue_redraw()
@export var show_cursor_regions: bool = true
@export var show_navigation_panels: bool = true
@export var show_labels: bool = true
@export var player_1_color: Color = Color(0.0, 0.42, 0.78, 0.24)
@export var player_2_color: Color = Color(0.86, 0.28, 0.12, 0.24)
@export var shared_color: Color = Color(0.42, 0.28, 0.82, 0.20)
@export var warning_color: Color = Color(1.0, 0.72, 0.0, 0.30)
@export var line_width: float = 3.0

func _ready() -> void:
	add_to_group("dual_cursor_debug_overlay")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)
	visible = enabled

func _process(_delta: float) -> void:
	if enabled:
		queue_redraw()

func _draw() -> void:
	if not enabled:
		return
	if show_cursor_regions:
		_draw_cursor_regions()
	if show_navigation_panels:
		_draw_navigation_panels()

func _draw_cursor_regions() -> void:
	for cursor in _find_by_script_path(_search_root(), CURSOR_SCRIPT_PATH):
		if not is_instance_valid(cursor):
			continue
		var player_id := int(cursor.get("player_id"))
		var color := _player_color(player_id)
		for region in _cursor_regions(cursor):
			_draw_global_rect(region.get_global_rect(), color, "P%d region" % [player_id + 1])

func _draw_navigation_panels() -> void:
	var panels := _find_by_script_path(_search_root(), NAVIGATION_PANEL_SCRIPT_PATH)
	panels.append_array(_find_by_script_path(_search_root(), GRID_NAVIGATION_PANEL_SCRIPT_PATH))
	for panel in panels:
		if not (panel is Control) or not panel.is_visible_in_tree():
			continue
		var panel_control: Control = panel as Control
		var owner_player_id := int(panel_control.get("owner_player_id"))
		var color := shared_color if owner_player_id == -1 else _player_color(owner_player_id)
		var label := panel_control.name
		if panel_control.has_method("get_active_player_ids"):
			var active_players: PackedInt32Array = panel_control.get_active_player_ids()
			if not active_players.is_empty():
				label += " active:"
				for player_id in active_players:
					label += " P%d" % [player_id + 1]
		_draw_global_rect(panel_control.get_global_rect(), color, label)

func _draw_global_rect(global_rect: Rect2, color: Color, label: String) -> void:
	var local_position := get_global_transform().affine_inverse() * global_rect.position
	var rect := Rect2(local_position, global_rect.size)
	var fill := color
	fill.a = min(fill.a, 0.28)
	var border := Color(color.r, color.g, color.b, 0.92)
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, line_width)
	if show_labels:
		var font := get_theme_default_font()
		if font:
			draw_string(font, rect.position + Vector2(8, 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, border)

func _cursor_regions(cursor: Node) -> Array[Control]:
	var regions: Array[Control] = []
	var region_path: NodePath = cursor.get("region_node_path")
	var primary: Control = cursor.get_node_or_null(region_path) as Control
	if primary:
		regions.append(primary)

	var extra_paths: Array = cursor.get("extra_region_node_paths")
	for extra_path in extra_paths:
		if not (extra_path is NodePath):
			continue
		var extra: Control = cursor.get_node_or_null(extra_path) as Control
		if extra and not regions.has(extra):
			regions.append(extra)
	return regions

func _player_color(player_id: int) -> Color:
	if player_id == 0:
		return player_1_color
	if player_id == 1:
		return player_2_color
	return warning_color

func _search_root() -> Node:
	if owner:
		return owner
	if get_tree().current_scene:
		return get_tree().current_scene
	return get_tree().root

func _find_by_script_path(root: Node, script_path: String) -> Array:
	var matches := []
	if root == null:
		return matches
	for node in _walk(root):
		var script: Script = node.get_script() as Script
		if script and script.resource_path == script_path:
			matches.append(node)
	return matches

func _walk(root: Node) -> Array:
	var nodes := [root]
	for child in root.get_children():
		nodes.append_array(_walk(child))
	return nodes
