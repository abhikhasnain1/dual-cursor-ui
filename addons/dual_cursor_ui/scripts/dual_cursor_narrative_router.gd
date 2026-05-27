@tool
class_name DualCursorNarrativeRouter
extends Node

signal narrative_event(player_id: int, event_type: String, event_id: String, payload: Dictionary, cursor: Node)

func route_panel_target(player_id: int, target: Control, cursor: Node) -> void:
	if target == null:
		return

	var payload: Dictionary = _metadata_payload(target)
	var event_type: String = str(payload.get("event_type", ""))
	var event_id: String = ""

	if payload.has("choice_id"):
		event_type = "choice" if event_type.is_empty() else event_type
		event_id = str(payload["choice_id"])
	elif payload.has("skill_id"):
		event_type = "skill_check" if event_type.is_empty() else event_type
		event_id = str(payload["skill_id"])
	elif payload.has("clock_id"):
		event_type = "clock" if event_type.is_empty() else event_type
		event_id = str(payload["clock_id"])
	elif payload.has("inventory_action"):
		event_type = "inventory" if event_type.is_empty() else event_type
		event_id = str(payload["inventory_action"])
	elif payload.has("event_id"):
		event_type = "shared_event" if event_type.is_empty() else event_type
		event_id = str(payload["event_id"])
	else:
		event_type = "target" if event_type.is_empty() else event_type
		event_id = target.name

	route_event(player_id, event_type, event_id, payload, cursor)

func route_event(player_id: int, event_type: String, event_id: String, payload: Dictionary = {}, cursor: Node = null) -> void:
	emit_signal("narrative_event", player_id, event_type, event_id, payload.duplicate(true), cursor)

func _metadata_payload(target: Control) -> Dictionary:
	var payload: Dictionary = {}
	for key in target.get_meta_list():
		payload[str(key)] = target.get_meta(key)
	return payload
