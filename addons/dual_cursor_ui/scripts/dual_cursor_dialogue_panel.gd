@tool
class_name DualCursorDialoguePanel
extends DualCursorNavigationPanel

@export var choice_row_height: float = 38.0
@export var choice_row_gap: float = 8.0
@export var choice_start_y: float = 68.0
@export var choice_side_margin: float = 10.0

signal choice_selected(player_id: int, choice_id: String, choice_data: Dictionary, cursor: Node)

var choices: Array[Dictionary] = []
var _choice_nodes: Array[Control] = []

func set_choices(new_choices: Array) -> void:
	clear_choices()
	choices.clear()

	for choice in new_choices:
		if not (choice is Dictionary):
			continue
		var choice_data: Dictionary = choice.duplicate(true)
		choices.append(choice_data)
		var button: Button = Button.new()
		button.name = _choice_node_name(choice_data, choices.size())
		button.text = str(choice_data.get("text", choice_data.get("id", "Choice %d" % choices.size())))
		button.custom_minimum_size = Vector2(0, choice_row_height)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("choice_data", choice_data)
		button.set_meta("choice_id", str(choice_data.get("id", button.name)))
		for key in choice_data.keys():
			if key != "text":
				button.set_meta(str(key), choice_data[key])
		var parent: Control = _choice_parent()
		parent.add_child(button)
		button.owner = owner
		_choice_nodes.append(button)
		navigation_targets.append(get_path_to(button))

	_layout_choice_nodes()

func clear_choices() -> void:
	for node in _choice_nodes:
		if is_instance_valid(node):
			if node.get_parent():
				node.get_parent().remove_child(node)
			node.queue_free()
	_choice_nodes.clear()
	navigation_targets.clear()

func activate_player(player_id: int, cursor: Node) -> Control:
	var target: Control = super.activate_player(player_id, cursor)
	if target == null:
		return null

	var choice_data: Dictionary = {}
	if target.has_meta("choice_data"):
		var stored_choice_data = target.get_meta("choice_data")
		if stored_choice_data is Dictionary:
			choice_data = stored_choice_data.duplicate(true)
	var choice_id: String = str(target.get_meta("choice_id", choice_data.get("id", target.name)))
	emit_signal("choice_selected", player_id, choice_id, choice_data, cursor)
	return target

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_choice_nodes()

func _layout_choice_nodes() -> void:
	var parent: Control = _choice_parent()
	if parent != self:
		for node in _choice_nodes:
			if node:
				node.custom_minimum_size = Vector2(0, choice_row_height)
				node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return
	var available_w: float = max(1.0, size.x - choice_side_margin * 2.0)
	for index in _choice_nodes.size():
		var node: Control = _choice_nodes[index]
		if node == null:
			continue
		node.position = Vector2(choice_side_margin, choice_start_y + float(index) * (choice_row_height + choice_row_gap))
		node.size = Vector2(available_w, choice_row_height)

func _choice_parent() -> Control:
	var target_container: Control = find_child("TargetsContainer", true, false) as Control
	if target_container:
		return target_container
	return self

func _choice_node_name(choice_data: Dictionary, index: int) -> String:
	var id: String = str(choice_data.get("id", "Choice%d" % index))
	var clean: String = id.to_pascal_case()
	if clean.is_empty():
		return "Choice%d" % index
	return clean
