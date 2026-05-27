class_name DualCursorToggleAdapter
extends CheckBox

@export var owner_player_id: int = -1
@export var interaction_enabled: bool = true
@export var hit_priority: int = 0

signal toggled_by_player(player_id: int, pressed: bool, cursor: Node)

func _ready() -> void:
	add_to_group("dual_cursor_interactable")

func can_receive_dual_cursor() -> bool:
	return interaction_enabled and visible and not disabled

func get_denial_reason(player_id: int) -> String:
	if not interaction_enabled:
		return "disabled"
	if disabled:
		return "disabled"
	if owner_player_id != -1 and owner_player_id != player_id:
		return "owned_by_player_%d" % [owner_player_id + 1]
	return ""

func on_cursor_interact(cursor: Node) -> void:
	dual_cursor_activate(int(cursor.get("player_id")), cursor)

func dual_cursor_activate(player_id: int, cursor: Node) -> void:
	var reason := get_denial_reason(player_id)
	if not reason.is_empty():
		return
	button_pressed = not button_pressed
	emit_signal("toggled_by_player", player_id, button_pressed, cursor)
