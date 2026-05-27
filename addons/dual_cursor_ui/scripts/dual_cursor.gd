class_name DualCursor
extends Sprite2D

@export var player_id: int = 0
@export var move_speed: float = 300.0
@export var region_node_path: NodePath = ".."
@export var extra_region_node_paths: Array[NodePath] = []
@export var manager_path: NodePath
@export var interact_action: String = "interact_p1"
@export var cancel_action: String = "cancel_p1"
@export var scroll_axis: int = JOY_AXIS_RIGHT_Y
@export var scroll_speed: float = 20.0
@export var movement_deadzone: float = 0.05
@export var scroll_deadzone: float = 0.1
@export var fallback_cursor_color: Color = Color(0.2, 0.72, 1.0, 1.0)
@export var center_on_primary_region_at_ready: bool = true

var last_hovered: Control = null
var _movement_region_rects: Array[Rect2] = []
var _manager = null
var _missing_action_warnings: Dictionary = {}

func _ready() -> void:
	add_to_group("dual_cursor_cursor")
	DualCursorInputSetup.ensure_default_actions(false)

	if texture == null:
		texture = _create_fallback_texture(fallback_cursor_color)

	_movement_region_rects = _resolve_region_rects()
	if _movement_region_rects.is_empty():
		push_warning("%s has no valid movement regions." % name)
	elif center_on_primary_region_at_ready:
		global_position = _movement_region_rects[0].position + _movement_region_rects[0].size * 0.5
	else:
		global_position = _constrain_to_regions(global_position)

	_manager = _resolve_manager()

func _process(delta: float) -> void:
	if _manager and _manager.is_cursor_in_navigation(self):
		_manager.process_navigation_input(self, delta)
		return

	_move_cursor(delta)
	if _manager and _manager.try_enter_navigation_panel(self, global_position):
		return

	_handle_scroll()
	_handle_hover()
	_handle_interaction()

func get_control_under_cursor() -> Control:
	if _manager:
		return _manager.get_interactable_at(global_position, player_id)
	return null

func refresh_movement_regions() -> void:
	_movement_region_rects = _resolve_region_rects()
	global_position = _constrain_to_regions(global_position)

func _move_cursor(delta: float) -> void:
	var axis_x := Input.get_joy_axis(player_id, JOY_AXIS_LEFT_X)
	var axis_y := Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
	var input_vec := Vector2(axis_x, axis_y)
	if input_vec.length() < movement_deadzone:
		input_vec = Vector2.ZERO
	else:
		input_vec = input_vec.limit_length(1.0)

	var desired_position := global_position + input_vec * move_speed * delta
	global_position = _constrain_to_regions(desired_position)

func _handle_scroll() -> void:
	var scroll_input := Input.get_joy_axis(player_id, scroll_axis)
	if abs(scroll_input) <= scroll_deadzone:
		return

	if _manager:
		_manager.scroll_at(self, global_position, scroll_input * scroll_speed)

func _handle_hover() -> void:
	var under: Control = _manager.update_hover(self, global_position) if _manager else null
	last_hovered = under

func _handle_interaction() -> void:
	if not _is_action_ready(interact_action):
		return
	if not Input.is_action_just_pressed(interact_action):
		return

	if _manager:
		_manager.interact(self, global_position)

func _is_action_ready(action_name: String) -> bool:
	if action_name.is_empty():
		return false
	if InputMap.has_action(action_name):
		return true
	if not _missing_action_warnings.has(action_name):
		_missing_action_warnings[action_name] = true
		push_warning("%s uses missing InputMap action: %s" % [name, action_name])
	return false

func _resolve_manager() -> Node:
	if not manager_path.is_empty():
		return get_node_or_null(manager_path)

	var managers := get_tree().get_nodes_in_group("dual_cursor_manager")
	if not managers.is_empty():
		return managers[0]

	return null

func _resolve_region_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	_append_region_rect(rects, region_node_path)
	for path in extra_region_node_paths:
		_append_region_rect(rects, path)
	return rects

func _append_region_rect(rects: Array[Rect2], path: NodePath) -> void:
	if path.is_empty():
		return

	var region_node: Control = get_node_or_null(path) as Control
	if region_node:
		rects.append(region_node.get_global_rect())

func _constrain_to_regions(position: Vector2) -> Vector2:
	if _movement_region_rects.is_empty():
		return position

	if _is_inside_any_region(position):
		return position

	var best_position := position
	var best_distance := INF
	for rect in _movement_region_rects:
		var clamped := Vector2(
			clamp(position.x, rect.position.x, rect.position.x + rect.size.x),
			clamp(position.y, rect.position.y, rect.position.y + rect.size.y)
		)
		var distance := position.distance_squared_to(clamped)
		if distance < best_distance:
			best_distance = distance
			best_position = clamped

	return best_position

func _is_inside_any_region(position: Vector2) -> bool:
	for rect in _movement_region_rects:
		if rect.has_point(position):
			return true
	return false

func _create_fallback_texture(color: Color) -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	for y in 32:
		for x in 32:
			if x <= y * 0.55 and y < 28:
				image.set_pixel(x, y, color)
			elif x <= y * 0.55 + 1 and y < 29:
				image.set_pixel(x, y, Color.BLACK)

	for i in 9:
		image.set_pixel(12 + i, 22 + i, Color.BLACK)
		image.set_pixel(13 + i, 22 + i, color)

	return ImageTexture.create_from_image(image)
