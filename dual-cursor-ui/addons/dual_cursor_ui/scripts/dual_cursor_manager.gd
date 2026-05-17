class_name DualCursorManager
extends Node

@export var interactable_group: StringName = &"dual_cursor_interactable"
@export var legacy_interactable_group: StringName = &"ui_interactable"

signal hover_started(player_id: int, target: Control)
signal hover_ended(player_id: int, target: Control)
signal interacted(player_id: int, target: Control)
signal denied(player_id: int, target: Control, reason: String)
signal shared_confirmed(target: Control, player_ids: PackedInt32Array)

var player_states: Dictionary = {}
var _bound_targets: Dictionary = {}

func _ready() -> void:
	add_to_group("dual_cursor_manager")

func update_hover(cursor: Node, global_position: Vector2) -> Control:
	var player_id := int(cursor.get("player_id"))
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
