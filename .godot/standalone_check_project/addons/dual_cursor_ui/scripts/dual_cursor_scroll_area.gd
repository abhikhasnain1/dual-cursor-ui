class_name DualCursorScrollArea
extends ScrollContainer

@export var owner_player_id: int = -1
@export var interaction_enabled: bool = true
@export var hit_priority: int = -10
@export var scroll_multiplier: float = 1.0

func _ready() -> void:
	add_to_group("dual_cursor_interactable")

func can_receive_dual_cursor() -> bool:
	return interaction_enabled

func get_denial_reason(player_id: int) -> String:
	if not interaction_enabled:
		return "disabled"
	if owner_player_id != -1 and owner_player_id != player_id:
		return "owned_by_other_player"
	return ""

func dual_cursor_scroll(amount: float) -> void:
	scroll_vertical += amount * scroll_multiplier
