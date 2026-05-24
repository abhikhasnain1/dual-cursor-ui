class_name DualCursorManager
extends Node

@export var interactable_group: StringName = &"dual_cursor_interactable"
@export var legacy_interactable_group: StringName = &"ui_interactable"
@export var navigation_panel_group: StringName = &"dual_cursor_navigation_panel"

signal hover_started(player_id: int, target: Control)
signal hover_ended(player_id: int, target: Control)
signal interacted(player_id: int, target: Control)
signal denied(player_id: int, target: Control, reason: String)
signal shared_confirmed(target: Control, player_ids: PackedInt32Array)
signal navigation_entered(player_id: int, panel: Control)
signal navigation_exited(player_id: int, panel: Control)
signal navigation_selection_changed(player_id: int, panel: Control, target: Control)
signal navigation_target_activated(player_id: int, panel: Control, target: Control)
signal navigation_denied(player_id: int, panel: Control, reason: String)

var player_states: Dictionary = {}
var _bound_targets: Dictionary = {}

func _ready() -> void:
	add_to_group("dual_cursor_manager")

func update_hover(cursor: Node, global_position: Vector2) -> Control:
	var player_id := int(cursor.get("player_id"))
	if is_cursor_in_navigation(cursor):
		return null

	var target := get_interactable_at(global_position, player_id)
	var previous: Control = player_states.get(player_id, {}).get("hovered", null)

	if previous and previous != target and previous.has_method("stop_hover"):
		previous.stop_hover(player_id)

	if target and target.has_method("on_cursor_hover"):
		_bind_target_signals(target)
		target.on_cursor_hover(cursor)

	_set_player_state(player_id, "hovered", target)
	return target

func interact(cursor: Node, global_position: Vector2) -> Control:
	var player_id := int(cursor.get("player_id"))
	if is_cursor_in_navigation(cursor):
		return process_navigation_activation(cursor)

	var target := get_interactable_at(global_position, player_id)
	if target == null:
		return null

	_bind_target_signals(target)
	if target.has_method("get_denial_reason"):
		var reason := str(target.get_denial_reason(player_id))
		if not reason.is_empty():
			if target.has_method("on_cursor_hover"):
				target.on_cursor_hover(cursor)
			elif not target.has_signal("dual_cursor_denied"):
				emit_signal("denied", player_id, target, reason)
			return target

	if target.has_method("on_cursor_interact"):
		target.on_cursor_interact(cursor)
		if not target.has_signal("dual_cursor_interacted"):
			emit_signal("interacted", player_id, target)
	else:
		emit_signal("interacted", player_id, target)

	return target

func scroll_at(cursor: Node, global_position: Vector2, amount: float) -> void:
	if is_cursor_in_navigation(cursor):
		return

	var target := get_interactable_at(global_position, int(cursor.get("player_id")))
	if target == null:
		return

	if target.has_method("dual_cursor_scroll"):
		target.dual_cursor_scroll(amount)
	elif target is ScrollContainer:
		target.scroll_vertical += amount

func get_interactable_at(global_position: Vector2, _player_id: int = -1) -> Control:
	var candidates := _collect_candidates(global_position)
	if candidates.is_empty():
		return null

	candidates.sort_custom(_sort_candidates)
	return candidates[0]

func register_interactable(interactable: Control) -> void:
	if not interactable.is_in_group(interactable_group):
		interactable.add_to_group(interactable_group)

func unregister_interactable(interactable: Control) -> void:
	if interactable.is_in_group(interactable_group):
		interactable.remove_from_group(interactable_group)

func is_cursor_in_navigation(cursor: Node) -> bool:
	var player_id := int(cursor.get("player_id"))
	return player_states.get(player_id, {}).get("navigation_panel", null) != null

func try_enter_navigation_panel(cursor: Node, global_position: Vector2) -> bool:
	var player_id := int(cursor.get("player_id"))
	if is_cursor_in_navigation(cursor):
		return true

	var state: Dictionary = player_states.get(player_id, {})
	var recapture_panel: Control = state.get("navigation_recapture_panel", null)
	if recapture_panel:
		if is_instance_valid(recapture_panel) and recapture_panel.has_method("contains_global_position") and recapture_panel.contains_global_position(global_position):
			return false
		_set_player_state(player_id, "navigation_recapture_panel", null)

	var panel := get_navigation_panel_at(global_position, player_id)
	if panel == null:
		_set_player_state(player_id, "navigation_denied_panel", null)
		_set_player_state(player_id, "navigation_denied_reason", "")
		return false
	if panel.has_method("get_entry_denial_reason"):
		var denial_reason := str(panel.get_entry_denial_reason(player_id))
		if not denial_reason.is_empty():
			var denied_panel: Control = state.get("navigation_denied_panel", null)
			var denied_reason := str(state.get("navigation_denied_reason", ""))
			if denied_panel != panel or denied_reason != denial_reason:
				emit_signal("navigation_denied", player_id, panel, denial_reason)
				_set_player_state(player_id, "navigation_denied_panel", panel)
				_set_player_state(player_id, "navigation_denied_reason", denial_reason)
			return false
	_set_player_state(player_id, "navigation_denied_panel", null)
	_set_player_state(player_id, "navigation_denied_reason", "")
	_bind_navigation_panel_signals(panel)
	if not panel.has_method("enter_player") or not panel.enter_player(player_id, cursor):
		return false

	var previous: Control = state.get("hovered", null)
	if previous and previous.has_method("stop_hover"):
		previous.stop_hover(player_id)
	_set_player_state(player_id, "hovered", null)
	_set_player_state(player_id, "navigation_panel", panel)
	_set_player_state(player_id, "navigation_repeat_direction", Vector2.ZERO)
	_set_player_state(player_id, "navigation_repeat_timer", 0.0)
	if cursor is CanvasItem:
		(cursor as CanvasItem).visible = false
	emit_signal("navigation_entered", player_id, panel)
	return true

func process_navigation_input(cursor: Node, delta: float) -> void:
	var player_id := int(cursor.get("player_id"))
	var panel: Control = player_states.get(player_id, {}).get("navigation_panel", null)
	if panel == null or not is_instance_valid(panel):
		exit_navigation(cursor)
		return
	if panel.has_method("can_player_enter") and not panel.can_player_enter(player_id):
		exit_navigation(cursor)
		return

	var cancel_action := str(cursor.get("cancel_action"))
	if _is_action_just_pressed(cancel_action):
		exit_navigation(cursor)
		return

	if _is_action_just_pressed(str(cursor.get("interact_action"))):
		process_navigation_activation(cursor)

	var direction := Vector2(
		Input.get_joy_axis(player_id, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
	)
	var deadzone := float(panel.get("navigation_deadzone")) if "navigation_deadzone" in panel else 0.45
	if direction.length() < deadzone:
		_set_player_state(player_id, "navigation_repeat_direction", Vector2.ZERO)
		_set_player_state(player_id, "navigation_repeat_timer", 0.0)
		return

	direction = direction.normalized()
	var previous_direction: Vector2 = player_states.get(player_id, {}).get("navigation_repeat_direction", Vector2.ZERO)
	var timer := float(player_states.get(player_id, {}).get("navigation_repeat_timer", 0.0))
	var should_navigate := previous_direction == Vector2.ZERO or previous_direction.dot(direction) < 0.85
	if should_navigate:
		timer = float(panel.get("repeat_delay")) if "repeat_delay" in panel else 0.35
	else:
		timer -= delta
		if timer <= 0.0:
			should_navigate = true
			timer = float(panel.get("repeat_interval")) if "repeat_interval" in panel else 0.12

	if should_navigate and panel.has_method("navigate_player"):
		panel.navigate_player(player_id, direction)

	_set_player_state(player_id, "navigation_repeat_direction", direction)
	_set_player_state(player_id, "navigation_repeat_timer", timer)

func process_navigation_activation(cursor: Node) -> Control:
	var player_id := int(cursor.get("player_id"))
	var panel: Control = player_states.get(player_id, {}).get("navigation_panel", null)
	if panel == null or not is_instance_valid(panel):
		return null
	if not panel.has_method("activate_player"):
		return null

	var target: Control = panel.activate_player(player_id, cursor)
	if target:
		emit_signal("navigation_target_activated", player_id, panel, target)
	return target

func exit_navigation(cursor: Node) -> void:
	var player_id := int(cursor.get("player_id"))
	var panel: Control = player_states.get(player_id, {}).get("navigation_panel", null)
	if panel and is_instance_valid(panel) and panel.has_method("exit_player"):
		panel.exit_player(player_id)

	_set_player_state(player_id, "navigation_panel", null)
	_set_player_state(player_id, "navigation_repeat_direction", Vector2.ZERO)
	_set_player_state(player_id, "navigation_repeat_timer", 0.0)
	_set_player_state(player_id, "navigation_recapture_panel", panel)
	if cursor is CanvasItem:
		(cursor as CanvasItem).visible = true
	if panel:
		emit_signal("navigation_exited", player_id, panel)

func get_navigation_panel_at(global_position: Vector2, _player_id: int = -1) -> Control:
	var candidates: Array = []
	for node in get_tree().get_nodes_in_group(navigation_panel_group):
		if not (node is Control):
			continue
		if not node.is_visible_in_tree():
			continue
		if node.has_method("contains_global_position"):
			if not node.contains_global_position(global_position):
				continue
		elif not node.get_global_rect().has_point(global_position):
			continue
		candidates.append(node)

	if candidates.is_empty():
		return null

	candidates.sort_custom(_sort_candidates)
	return candidates[0]

func _collect_candidates(global_position: Vector2) -> Array:
	var candidates: Array = []
	var seen: Dictionary = {}
	for group_name in [interactable_group, legacy_interactable_group]:
		for node in get_tree().get_nodes_in_group(group_name):
			if seen.has(node):
				continue
			seen[node] = true
			if node is Control and _is_candidate_at(node, global_position):
				candidates.append(node)
	return candidates

func _is_candidate_at(node: Control, global_position: Vector2) -> bool:
	if not is_instance_valid(node):
		return false
	if not node.is_visible_in_tree():
		return false
	if node.has_method("can_receive_dual_cursor") and not node.can_receive_dual_cursor():
		return false
	return node.get_global_rect().has_point(global_position)

func _sort_candidates(a: Control, b: Control) -> bool:
	var a_priority := int(a.get("hit_priority")) if "hit_priority" in a else 0
	var b_priority := int(b.get("hit_priority")) if "hit_priority" in b else 0
	if a_priority != b_priority:
		return a_priority > b_priority
	if a.z_index != b.z_index:
		return a.z_index > b.z_index
	return a.get_index() > b.get_index()

func _set_player_state(player_id: int, key: String, value) -> void:
	if not player_states.has(player_id):
		player_states[player_id] = {}
	player_states[player_id][key] = value

func _bind_target_signals(target: Control) -> void:
	if _bound_targets.has(target):
		return

	_bound_targets[target] = true
	if target.has_signal("dual_cursor_hover_started"):
		target.dual_cursor_hover_started.connect(func(player_id: int, _cursor: Node): emit_signal("hover_started", player_id, target))
	if target.has_signal("dual_cursor_hover_ended"):
		target.dual_cursor_hover_ended.connect(func(player_id: int, _cursor: Node): emit_signal("hover_ended", player_id, target))
	if target.has_signal("dual_cursor_interacted"):
		target.dual_cursor_interacted.connect(func(player_id: int, _cursor: Node): emit_signal("interacted", player_id, target))
	if target.has_signal("dual_cursor_denied"):
		target.dual_cursor_denied.connect(func(player_id: int, _cursor: Node, reason: String): emit_signal("denied", player_id, target, reason))
	if target.has_signal("dual_cursor_shared_confirmed"):
		target.dual_cursor_shared_confirmed.connect(func(player_ids: PackedInt32Array): emit_signal("shared_confirmed", target, player_ids))

func _bind_navigation_panel_signals(panel: Control) -> void:
	if _bound_targets.has(panel):
		return

	_bound_targets[panel] = true
	if panel.has_signal("selection_changed"):
		panel.selection_changed.connect(func(player_id: int, target: Control): emit_signal("navigation_selection_changed", player_id, panel, target))

func _is_action_just_pressed(action_name: String) -> bool:
	if action_name.is_empty() or not InputMap.has_action(action_name):
		return false
	return Input.is_action_just_pressed(action_name)
