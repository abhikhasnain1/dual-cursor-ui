class_name DualCursorSpinBoxAdapter
extends SpinBox

@export var owner_player_id: int = -1
@export var interaction_enabled: bool = true
@export var hit_priority: int = 0

signal value_changed_by_player(player_id: int, value: float, cursor: Node)

func _ready() -> void:
	add_to_group("dual_cursor_interactable")

func can_receive_dual_cursor() -> bool:
	return interaction_enabled and visible and editable

func get_denial_reason(player_id: int) -> String:
	if not interaction_enabled:
		return "disabled"
	if not editable:
		return "disabled"
	if owner_player_id != -1 and owner_player_id != player_id:
		return "owned_by_player_%d" % [owner_player_id + 1]
	return ""

func on_cursor_interact(cursor: Node) -> void:
	dual_cursor_activate(int(cursor.get("player_id")), cursor)

func dual_cursor_activate(player_id: int, cursor: Node) -> void:
	adjust_by_player(player_id, 1.0, cursor)

func dual_cursor_navigate(player_id: int, direction: Vector2, cursor: Node) -> bool:
	if abs(direction.x) <= abs(direction.y):
		return false
	adjust_by_player(player_id, direction.x, cursor)
	return true

func adjust_by_player(player_id: int, direction: float, cursor: Node) -> void:
	var reason := get_denial_reason(player_id)
	if not reason.is_empty():
		return
	var delta: float = _step_size() * sign(direction)
	value = clamp(value + delta, min_value, max_value)
	emit_signal("value_changed_by_player", player_id, value, cursor)

func _step_size() -> float:
	if step > 0.0:
		return step
	return 1.0
