class_name DualCursorTabAdapter
extends TabContainer

@export var owner_player_id: int = -1
@export var interaction_enabled: bool = true
@export var hit_priority: int = 0
@export var wrap_tabs: bool = true

signal tab_changed_by_player(player_id: int, tab_index: int, cursor: Node)

func _ready() -> void:
	add_to_group("dual_cursor_interactable")

func can_receive_dual_cursor() -> bool:
	return interaction_enabled and visible and get_tab_count() > 0

func get_denial_reason(player_id: int) -> String:
	if not interaction_enabled:
		return "disabled"
	if get_tab_count() <= 0:
		return "no_tabs"
	if owner_player_id != -1 and owner_player_id != player_id:
		return "owned_by_player_%d" % [owner_player_id + 1]
	return ""

func on_cursor_interact(cursor: Node) -> void:
	dual_cursor_activate(int(cursor.get("player_id")), cursor)

func dual_cursor_activate(player_id: int, cursor: Node) -> void:
	change_tab_by_player(player_id, 1, cursor)

func dual_cursor_navigate(player_id: int, direction: Vector2, cursor: Node) -> bool:
	if abs(direction.x) <= abs(direction.y):
		return false
	change_tab_by_player(player_id, int(sign(direction.x)), cursor)
	return true

func change_tab_by_player(player_id: int, direction: int, cursor: Node) -> void:
	var reason := get_denial_reason(player_id)
	if not reason.is_empty():
		return
	var next: int = current_tab + int(sign(direction))
	if wrap_tabs:
		next = posmod(next, get_tab_count())
	else:
		next = int(clamp(next, 0, get_tab_count() - 1))
	current_tab = next
	emit_signal("tab_changed_by_player", player_id, current_tab, cursor)
