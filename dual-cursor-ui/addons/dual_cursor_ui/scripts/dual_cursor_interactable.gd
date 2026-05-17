class_name DualCursorInteractable
extends Control

enum SharedPolicy { ALLOW_ANY, FIRST_PLAYER_LOCKS, REQUIRE_ALL_PLAYERS, DENY_IF_OWNED }

@export var owner_player_id: int = -1
@export var interaction_enabled: bool = true
@export var hit_priority: int = 0
@export var shared_policy: SharedPolicy = SharedPolicy.ALLOW_ANY
@export var required_players: PackedInt32Array = PackedInt32Array([0, 1])

signal dual_cursor_hover_started(player_id: int, cursor: Node)
signal dual_cursor_hover_ended(player_id: int, cursor: Node)
signal dual_cursor_interacted(player_id: int, cursor: Node)
signal dual_cursor_denied(player_id: int, cursor: Node, reason: String)
signal dual_cursor_shared_confirmed(player_ids: PackedInt32Array)

var _hovering_players: Dictionary = {}
var _shared_lock_player_id: int = -1
var _shared_confirmations: Dictionary = {}

func _ready() -> void:
	add_to_group("dual_cursor_interactable")

func can_player_interact(player_id: int) -> bool:
	return interaction_enabled and (owner_player_id == -1 or owner_player_id == player_id)

func get_denial_reason(player_id: int) -> String:
	if not interaction_enabled:
		return "disabled"
	if owner_player_id != -1 and owner_player_id != player_id:
		return "owned_by_other_player"
	if shared_policy == SharedPolicy.DENY_IF_OWNED and owner_player_id != -1:
		return "owned"
	return ""

func on_cursor_hover(cursor: Node) -> void:
	var player_id := int(cursor.get("player_id"))
	var reason := get_denial_reason(player_id)
	if not reason.is_empty():
		emit_signal("dual_cursor_denied", player_id, cursor, reason)
		return

	if not _hovering_players.has(player_id):
		_hovering_players[player_id] = cursor
		emit_signal("dual_cursor_hover_started", player_id, cursor)

func stop_hover(player_id: int) -> void:
	if not _hovering_players.has(player_id):
		return

	var cursor = _hovering_players[player_id]
	_hovering_players.erase(player_id)
	emit_signal("dual_cursor_hover_ended", player_id, cursor)

func on_cursor_interact(cursor: Node) -> void:
	var player_id := int(cursor.get("player_id"))
	var reason := get_denial_reason(player_id)
	if not reason.is_empty():
		emit_signal("dual_cursor_denied", player_id, cursor, reason)
		return

	if owner_player_id == -1:
		_handle_shared_interaction(player_id, cursor)
	else:
		emit_signal("dual_cursor_interacted", player_id, cursor)

func release_shared_lock(player_id: int = -1) -> void:
	if player_id == -1 or _shared_lock_player_id == player_id:
		_shared_lock_player_id = -1
	_shared_confirmations.clear()

func _handle_shared_interaction(player_id: int, cursor: Node) -> void:
	match shared_policy:
		SharedPolicy.ALLOW_ANY:
			emit_signal("dual_cursor_interacted", player_id, cursor)
		SharedPolicy.FIRST_PLAYER_LOCKS:
			if _shared_lock_player_id == -1:
				_shared_lock_player_id = player_id
				emit_signal("dual_cursor_interacted", player_id, cursor)
			elif _shared_lock_player_id == player_id:
				emit_signal("dual_cursor_interacted", player_id, cursor)
			else:
				emit_signal("dual_cursor_denied", player_id, cursor, "shared_locked")
		SharedPolicy.REQUIRE_ALL_PLAYERS:
			_shared_confirmations[player_id] = true
			if _has_all_required_confirmations():
				emit_signal("dual_cursor_shared_confirmed", required_players)
				_shared_confirmations.clear()
		SharedPolicy.DENY_IF_OWNED:
			emit_signal("dual_cursor_interacted", player_id, cursor)

func _has_all_required_confirmations() -> bool:
	for player_id in required_players:
		if not _shared_confirmations.has(player_id):
			return false
	return true
