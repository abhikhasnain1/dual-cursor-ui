class_name DualCursorNavigationPanel
extends Control

enum OccupancyPolicy { ALLOW_MULTIPLE, FIRST_PLAYER_LOCKS }

@export var owner_player_id: int = -1
@export var interaction_enabled: bool = true
@export var hit_priority: int = 0
@export var occupancy_policy: OccupancyPolicy = OccupancyPolicy.ALLOW_MULTIPLE
@export var navigation_targets: Array[NodePath] = []
@export var wrap_navigation: bool = true
@export var initial_target_index: int = 0
@export var navigation_deadzone: float = 0.45
@export var repeat_delay: float = 0.35
@export var repeat_interval: float = 0.12
@export var selection_color: Color = Color(0.2, 0.72, 1.0, 0.9)
@export var player_selection_colors: PackedColorArray = PackedColorArray([
	Color(0.2, 0.72, 1.0, 0.9),
	Color(1.0, 0.45, 0.25, 0.9)
])
@export var selection_padding: float = 6.0
@export var selection_width: float = 3.0

signal navigation_entered(player_id: int, cursor: Node)
signal navigation_exited(player_id: int, cursor: Node)
signal selection_changed(player_id: int, target: Control)
signal target_activated(player_id: int, target: Control, cursor: Node)

var _selected_indices: Dictionary = {}
var _cursors: Dictionary = {}
var _selection_visuals: Dictionary = {}

func _ready() -> void:
	add_to_group("dual_cursor_navigation_panel")
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func can_player_enter(player_id: int) -> bool:
	return get_entry_denial_reason(player_id).is_empty()

func get_entry_denial_reason(player_id: int) -> String:
	if not interaction_enabled:
		return "disabled"
	if owner_player_id != -1 and owner_player_id != player_id:
		return "owned_by_player_%d" % [owner_player_id + 1]
	if get_navigation_targets().is_empty():
		return "no_navigation_targets"
	if occupancy_policy == OccupancyPolicy.FIRST_PLAYER_LOCKS and not _cursors.is_empty() and not _cursors.has(player_id):
		var active_player_id := int(_cursors.keys()[0])
		return "occupied_by_player_%d" % [active_player_id + 1]
	return ""

func contains_global_position(global_position: Vector2) -> bool:
	return is_visible_in_tree() and get_global_rect().has_point(global_position)

func enter_player(player_id: int, cursor: Node) -> bool:
	var denial_reason := get_entry_denial_reason(player_id)
	if not denial_reason.is_empty():
		return false

	var targets := get_navigation_targets()
	if targets.is_empty():
		return false

	_cursors[player_id] = cursor
	_selected_indices[player_id] = clamp(initial_target_index, 0, targets.size() - 1)
	emit_signal("navigation_entered", player_id, cursor)
	_emit_selection_changed(player_id)
	_update_target_selection_visuals()
	queue_redraw()
	return true

func exit_player(player_id: int) -> void:
	if not _selected_indices.has(player_id):
		return

	var cursor = _cursors.get(player_id, null)
	_selected_indices.erase(player_id)
	_cursors.erase(player_id)
	emit_signal("navigation_exited", player_id, cursor)
	_update_target_selection_visuals()
	queue_redraw()

func has_player(player_id: int) -> bool:
	return _selected_indices.has(player_id)

func get_active_player_ids() -> PackedInt32Array:
	var player_ids := PackedInt32Array()
	for player_id in _cursors.keys():
		player_ids.append(int(player_id))
	return player_ids

func navigate_player(player_id: int, direction: Vector2, cursor: Node = null) -> void:
	if not _selected_indices.has(player_id):
		return

	var selected_target := get_selected_target(player_id)
	if selected_target and selected_target.has_method("dual_cursor_navigate"):
		if selected_target.dual_cursor_navigate(player_id, direction, cursor):
			return

	var targets := get_navigation_targets()
	if targets.is_empty():
		exit_player(player_id)
		return

	var step := _direction_to_step(direction)
	if step == 0:
		return

	var current := int(_selected_indices[player_id])
	var next := current + step
	if wrap_navigation:
		next = posmod(next, targets.size())
	else:
		next = clamp(next, 0, targets.size() - 1)

	if next == current:
		return

	_selected_indices[player_id] = next
	_emit_selection_changed(player_id)
	_update_target_selection_visuals()
	queue_redraw()

func activate_player(player_id: int, cursor: Node) -> Control:
	var target := get_selected_target(player_id)
	if target == null:
		return null

	if target.has_method("dual_cursor_activate"):
		target.dual_cursor_activate(player_id, cursor)
	elif target.has_method("adjust_by_player"):
		target.adjust_by_player(player_id, 1.0, cursor)
	elif target.has_method("select_next_by_player"):
		target.select_next_by_player(player_id, 1, cursor)
	elif target.has_method("change_tab_by_player"):
		target.change_tab_by_player(player_id, 1, cursor)
	elif target.has_method("on_cursor_interact"):
		target.on_cursor_interact(cursor)
	elif target is BaseButton:
		target.emit_signal("pressed")

	emit_signal("target_activated", player_id, target, cursor)

	return target

func get_selected_target(player_id: int) -> Control:
	var targets := get_navigation_targets()
	if targets.is_empty() or not _selected_indices.has(player_id):
		return null

	var index: int = int(clamp(int(_selected_indices[player_id]), 0, targets.size() - 1))
	_selected_indices[player_id] = index
	return targets[index]

func get_navigation_targets() -> Array[Control]:
	var targets: Array[Control] = []
	for path in navigation_targets:
		if path.is_empty():
			continue

		var target: Control = get_node_or_null(path) as Control
		if target and _is_valid_target(target):
			targets.append(target)

	return targets

func _is_valid_target(target: Control) -> bool:
	if not is_instance_valid(target):
		return false
	if not target.is_visible_in_tree():
		return false
	if target.get_global_rect().size == Vector2.ZERO:
		return false
	if target.has_method("can_receive_dual_cursor") and not target.can_receive_dual_cursor():
		return false
	if "interaction_enabled" in target and not bool(target.get("interaction_enabled")):
		return false
	if target is BaseButton and (target as BaseButton).disabled:
		return false
	return true

func _direction_to_step(direction: Vector2) -> int:
	if abs(direction.x) > abs(direction.y):
		return 1 if direction.x > 0.0 else -1
	return 1 if direction.y > 0.0 else -1

func _emit_selection_changed(player_id: int) -> void:
	var target := get_selected_target(player_id)
	if target:
		emit_signal("selection_changed", player_id, target)

func _update_target_selection_visuals() -> void:
	var selected_targets: Dictionary = {}
	for player_id in _selected_indices.keys():
		var target: Control = get_selected_target(int(player_id))
		if target:
			selected_targets[target] = _get_selection_color(int(player_id))

	for target in _selection_visuals.keys():
		if not selected_targets.has(target):
			_restore_target_visual(target)

	for target in selected_targets.keys():
		_apply_target_visual(target, selected_targets[target])

func _apply_target_visual(target: Control, color: Color) -> void:
	if target == null:
		return
	if not _selection_visuals.has(target):
		var stored: Dictionary = {"modulate": target.modulate}
		if target is BaseButton:
			var stored_button: BaseButton = target as BaseButton
			stored["font_color"] = stored_button.get_theme_color("font_color")
			stored["font_hover_color"] = stored_button.get_theme_color("font_hover_color")
			stored["font_pressed_color"] = stored_button.get_theme_color("font_pressed_color")
			stored["normal_style"] = stored_button.get_theme_stylebox("normal")
			stored["hover_style"] = stored_button.get_theme_stylebox("hover")
			stored["focus_style"] = stored_button.get_theme_stylebox("focus")
		var stored_backing: Control = target.get_node_or_null("Background") as Control
		if stored_backing:
			stored["backing_modulate"] = stored_backing.modulate
			if stored_backing is Panel:
				stored["backing_panel_style"] = (stored_backing as Panel).get_theme_stylebox("panel")
		var stored_label: Label = target.find_child("Label", true, false) as Label
		if stored_label:
			stored["label"] = stored_label
			stored["label_color"] = stored_label.get_theme_color("font_color")
		_selection_visuals[target] = stored

	var selected_color: Color = color
	selected_color.a = 1.0

	if target is BaseButton:
		var button: BaseButton = target as BaseButton
		button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
		button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
		button.add_theme_stylebox_override("normal", _selection_style_box(selected_color, selected_color.darkened(0.45), selection_width))
		button.add_theme_stylebox_override("hover", _selection_style_box(selected_color.lightened(0.08), selected_color.darkened(0.55), selection_width))
		button.add_theme_stylebox_override("focus", _selection_style_box(selected_color, selected_color.darkened(0.45), selection_width))
		return

	var backing: Control = target.get_node_or_null("Background") as Control
	if backing:
		backing.modulate = selected_color.lightened(0.22)
		if backing is Panel:
			(backing as Panel).add_theme_stylebox_override("panel", _selection_style_box(selected_color, selected_color.darkened(0.45), selection_width))

	var label: Label = target.find_child("Label", true, false) as Label
	if label:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))

func _restore_target_visual(target: Control) -> void:
	if target == null:
		_selection_visuals.erase(target)
		return

	var stored: Dictionary = _selection_visuals[target]
	if stored.has("modulate"):
		target.modulate = stored["modulate"]
	if target is BaseButton:
		var button: BaseButton = target as BaseButton
		if stored.has("font_color"):
			button.add_theme_color_override("font_color", stored["font_color"])
		if stored.has("font_hover_color"):
			button.add_theme_color_override("font_hover_color", stored["font_hover_color"])
		if stored.has("font_pressed_color"):
			button.add_theme_color_override("font_pressed_color", stored["font_pressed_color"])
		if stored.has("normal_style"):
			button.add_theme_stylebox_override("normal", stored["normal_style"])
		if stored.has("hover_style"):
			button.add_theme_stylebox_override("hover", stored["hover_style"])
		if stored.has("focus_style"):
			button.add_theme_stylebox_override("focus", stored["focus_style"])

	var backing: Control = target.get_node_or_null("Background") as Control
	if backing:
		if stored.has("backing_modulate"):
			backing.modulate = stored["backing_modulate"]
		if backing is Panel and stored.has("backing_panel_style"):
			(backing as Panel).add_theme_stylebox_override("panel", stored["backing_panel_style"])

	if stored.has("label") and is_instance_valid(stored["label"]):
		var label: Label = stored["label"] as Label
		if stored.has("label_color"):
			label.add_theme_color_override("font_color", stored["label_color"])

	_selection_visuals.erase(target)

func _selection_style_box(fill: Color, border: Color, width: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	var border_width: int = int(max(3.0, width))
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 10.0
	style.content_margin_top = 6.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 6.0
	return style

func _draw() -> void:
	for player_id in _selected_indices.keys():
		var target := get_selected_target(int(player_id))
		if target == null:
			continue

		var global_rect := target.get_global_rect().grow(selection_padding)
		var local_position := get_global_transform().affine_inverse() * global_rect.position
		var selection_rect: Rect2 = Rect2(local_position, global_rect.size)
		var selection_color: Color = _get_selection_color(int(player_id))
		var fill_color: Color = selection_color
		fill_color.a = 0.72
		draw_rect(selection_rect, fill_color, true)
		draw_rect(selection_rect.grow(2.0), Color(1.0, 1.0, 1.0, 0.95), false, max(2.0, selection_width * 0.45))
		draw_rect(selection_rect, selection_color.darkened(0.35), false, selection_width)

func _get_selection_color(player_id: int) -> Color:
	if player_id >= 0 and player_id < player_selection_colors.size():
		return player_selection_colors[player_id]
	return selection_color
