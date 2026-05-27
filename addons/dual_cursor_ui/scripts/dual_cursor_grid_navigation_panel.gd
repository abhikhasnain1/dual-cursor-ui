class_name DualCursorGridNavigationPanel
extends DualCursorNavigationPanel

@export var columns: int = 4
@export var wrap_rows: bool = false
@export var wrap_columns: bool = true
@export var skip_disabled_targets: bool = true

func navigate_player(player_id: int, direction: Vector2) -> void:
	if not _selected_indices.has(player_id):
		return

	var targets := get_navigation_targets()
	if targets.is_empty():
		exit_player(player_id)
		return

	var current := clamp(int(_selected_indices[player_id]), 0, targets.size() - 1)
	var next := _next_index(current, direction, targets)
	if next == current:
		return

	_selected_indices[player_id] = next
	_emit_selection_changed(player_id)
	_update_target_selection_visuals()
	queue_redraw()

func get_navigation_targets() -> Array[Control]:
	var targets: Array[Control] = []
	for path in navigation_targets:
		if path.is_empty():
			continue

		var target: Control = get_node_or_null(path) as Control
		if target == null:
			continue
		if skip_disabled_targets:
			if _is_selectable_target(target):
				targets.append(target)
		elif _is_visible_target(target):
			targets.append(target)
	return targets

func _next_index(current: int, direction: Vector2, targets: Array[Control]) -> int:
	var column_count: int = max(1, columns)
	var target_count: int = targets.size()
	var step := _direction_to_grid_step(direction, column_count)
	if step == 0:
		return current

	var attempts := target_count
	var candidate := current
	while attempts > 0:
		candidate = _candidate_index(candidate, step, column_count, target_count)
		if candidate == current:
			return current
		if candidate >= 0 and candidate < target_count and _is_selectable_target(targets[candidate]):
			return candidate
		if not skip_disabled_targets:
			return current
		attempts -= 1

	return current

func _direction_to_grid_step(direction: Vector2, column_count: int) -> int:
	if abs(direction.x) > abs(direction.y):
		return 1 if direction.x > 0.0 else -1
	return column_count if direction.y > 0.0 else -column_count

func _candidate_index(current: int, step: int, column_count: int, target_count: int) -> int:
	if step == 1 or step == -1:
		return _horizontal_candidate(current, step, column_count, target_count)
	return _vertical_candidate(current, step, column_count, target_count)

func _horizontal_candidate(current: int, step: int, column_count: int, target_count: int) -> int:
	var row_start: int = int(current / column_count) * column_count
	var row_end: int = min(row_start + column_count - 1, target_count - 1)
	var next := current + step
	if next < row_start:
		return row_end if wrap_columns else current
	if next > row_end:
		return row_start if wrap_columns else current
	return next

func _vertical_candidate(current: int, step: int, column_count: int, target_count: int) -> int:
	var next := current + step
	if next >= 0 and next < target_count:
		return next
	if not wrap_rows:
		return current

	var column: int = current % column_count
	if step > 0:
		return column if column < target_count else current

	var last_row: int = int((target_count - 1) / column_count)
	var wrapped := last_row * column_count + column
	while wrapped >= target_count and wrapped >= 0:
		wrapped -= column_count
	return wrapped if wrapped >= 0 else current

func _is_visible_target(target: Control) -> bool:
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
	return true

func _is_selectable_target(target: Control) -> bool:
	if not _is_visible_target(target):
		return false
	if target is BaseButton and (target as BaseButton).disabled:
		return false
	return true
