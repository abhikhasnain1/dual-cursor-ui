@tool
extends VBoxContainer

const MANAGER_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_manager.gd")
const CURSOR_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor.gd")
const BUTTON_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_button.gd")
const DEMO_SCENE_PATH := "res://addons/dual_cursor_ui/demos/two_player_menu_demo.tscn"
const CONNECT_BUTTON_EXAMPLE := """extends Node

@export var choice_button: DualCursorButton

func _ready() -> void:
	choice_button.pressed_by_player.connect(_on_choice_pressed)

func _on_choice_pressed(player_id: int, cursor: Node) -> void:
	print("Player %d selected %s" % [player_id + 1, choice_button.name])
	# Put your dialogue, menu, or game-state change here.
"""
const OWNERSHIP_EXAMPLE := """extends Node

@export var player_1_cursor: DualCursor
@export var player_2_cursor: DualCursor
@export var player_1_region: Control
@export var player_2_region: Control
@export var shared_region: Control
@export var player_1_button: DualCursorButton
@export var player_2_button: DualCursorButton
@export var shared_button: DualCursorButton

func _ready() -> void:
	player_1_cursor.region_node_path = player_1_cursor.get_path_to(player_1_region)
	player_1_cursor.extra_region_node_paths = [player_1_cursor.get_path_to(shared_region)]
	player_2_cursor.region_node_path = player_2_cursor.get_path_to(player_2_region)
	player_2_cursor.extra_region_node_paths = [player_2_cursor.get_path_to(shared_region)]

	player_1_button.owner_player_id = 0
	player_2_button.owner_player_id = 1
	shared_button.owner_player_id = -1
"""
const SHARED_CONFIRM_EXAMPLE := """extends Node

@export var shared_button: DualCursorButton

func _ready() -> void:
	shared_button.owner_player_id = -1
	shared_button.shared_policy = DualCursorInteractable.SharedPolicy.REQUIRE_ALL_PLAYERS
	shared_button.required_players = PackedInt32Array([0, 1])
	shared_button.dual_cursor_shared_confirmed.connect(_on_shared_confirmed)

func _on_shared_confirmed(player_ids: PackedInt32Array) -> void:
	print("Both players confirmed: %s" % [player_ids])
	# Start the scene, commit the vote, or advance the shared choice here.
"""

var _plugin: EditorPlugin
var _results: RichTextLabel

func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin

func _ready() -> void:
	name = "DualCursor UI"
	custom_minimum_size = Vector2(360, 0)
	_build_ui()
	_run_validation()

func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)

	body.add_child(_heading("DualCursor UI"))
	body.add_child(_paragraph("Build local multiplayer UI with independent virtual cursors over Godot Control nodes. DualCursor UI does not replace Godot focus; it routes hover, select, denial, shared controls, and scroll areas for each player."))

	body.add_child(_section("Quick Setup"))
	var create_button := _button("Create 2-Player Setup")
	create_button.pressed.connect(_create_two_player_setup)
	body.add_child(create_button)

	var input_button := _button("Set Up Controller Actions")
	input_button.pressed.connect(_add_input_actions)
	body.add_child(input_button)

	var demo_button := _button("Open Demo Scene")
	demo_button.pressed.connect(_open_demo_scene)
	body.add_child(demo_button)

	body.add_child(_section("Validate Scene"))
	var validate_button := _button("Validate Current Scene")
	validate_button.pressed.connect(_run_validation)
	body.add_child(validate_button)

	_results = RichTextLabel.new()
	_results.fit_content = true
	_results.bbcode_enabled = true
	_results.selection_enabled = true
	_results.custom_minimum_size = Vector2(0, 220)
	body.add_child(_results)

	body.add_child(_section("Next Steps"))
	body.add_child(_paragraph("Try this now: press Play, move each cursor with the left stick, press A/Cross on your own button, then move both cursors into the Shared region and press A/Cross on Shared Confirm."))
	body.add_child(_paragraph("When that works, connect DualCursorButton.pressed_by_player(player_id, cursor) to your game logic. Change owner_player_id to decide who can use a control: 0 for player 1, 1 for player 2, and -1 for shared. Keep private controls inside the matching player region; put shared controls inside a region assigned to both cursors."))

	body.add_child(_section("Use In Your Game"))
	body.add_child(_paragraph("These examples are safe to paste into a normal game script. Assign the exported nodes in the Inspector, then connect the plugin's player-aware signals to your own game state."))
	body.add_child(_guide_panel(
		"Connect Buttons to Game Logic",
		"Use pressed_by_player when a DualCursorButton should trigger dialogue, menu, inventory, or scene logic.",
		CONNECT_BUTTON_EXAMPLE
	))
	body.add_child(_guide_panel(
		"Set Ownership and Regions",
		"Use owner_player_id to decide who can interact. Use region_node_path for a player's private area and extra_region_node_paths for shared areas.",
		OWNERSHIP_EXAMPLE
	))
	body.add_child(_guide_panel(
		"Require Both Players",
		"Use REQUIRE_ALL_PLAYERS when a shared control should wait for both players before it fires.",
		SHARED_CONFIRM_EXAMPLE
	))

func _create_two_player_setup() -> void:
	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=red]Open or create a scene before running setup.[/color]"])
		return

	var manager := _ensure_manager(root)
	var p1_region := _ensure_region(root, "Player1Region", Rect2(80, 180, 360, 300), Color(0.12, 0.16, 0.22, 1.0))
	var p2_region := _ensure_region(root, "Player2Region", Rect2(520, 180, 360, 300), Color(0.12, 0.16, 0.22, 1.0))
	var shared_region := _ensure_region(root, "SharedRegion", Rect2(300, 440, 360, 140), Color(0.16, 0.13, 0.2, 1.0))
	var p1_button := _ensure_button(p1_region, "P1ActionButton", "P1 Action", 0, Rect2(70, 112, 220, 72))
	var p2_button := _ensure_button(p2_region, "P2ActionButton", "P2 Action", 1, Rect2(70, 112, 220, 72))
	var shared_button := _ensure_button(shared_region, "SharedConfirmButton", "Shared Confirm", -1, Rect2(50, 34, 260, 72))
	shared_button.hit_priority = 20
	shared_button.shared_policy = 2

	_ensure_cursor(root, "DualCursorP1", 0, p1_region, [shared_region], manager, "interact_p1")
	_ensure_cursor(root, "DualCursorP2", 1, p2_region, [shared_region], manager, "interact_p2")
	_add_input_actions()

	_show_results([
		"[color=green]OK: Created or updated a 2-player DualCursor setup.[/color]",
		"Try next: Press Play and move both cursors with the left sticks.",
		"Try next: Confirm each cursor stays in its own private region and can also enter SharedRegion.",
		"Try next: Press A/Cross on P1 Action, P2 Action, and Shared Confirm.",
		"Created controls: %s, %s, %s." % [p1_button.name, p2_button.name, shared_button.name]
	])
	_run_validation()

func _add_input_actions() -> void:
	_add_action_if_missing("interact_p1", 0)
	_add_action_if_missing("interact_p2", 1)
	ProjectSettings.save()
	_show_results([
		"[color=green]OK: Controller A/Cross actions are ready.[/color]",
		"This creates the project-level actions DualCursor uses when each player presses A/Cross.",
		"You usually only need to press this once per project.",
		"`interact_p1` is controller 1, A/Cross. `interact_p2` is controller 2, A/Cross."
	])

func _run_validation() -> void:
	if _results == null:
		return

	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=yellow]No edited scene is open.[/color]"])
		return

	var lines: Array[String] = []
	var managers := _find_by_script(root, MANAGER_SCRIPT)
	var cursors := _find_by_script(root, CURSOR_SCRIPT)
	var interactables := _find_interactables(root)

	if managers.is_empty():
		lines.append("[color=red]Fix needed: Missing DualCursorManager. Click Create 2-Player Setup.[/color]")
	elif managers.size() > 1:
		lines.append("[color=yellow]Warning: Multiple DualCursorManager nodes found. One is usually enough.[/color]")
	else:
		lines.append("[color=green]OK: Scene has the router that connects cursors to UI controls.[/color]")

	if cursors.is_empty():
		lines.append("[color=red]Fix needed: No DualCursor nodes found. Click Create 2-Player Setup.[/color]")
	else:
		lines.append("[color=green]OK: %d player cursor node(s) found.[/color]" % cursors.size())

	for cursor in cursors:
		_validate_cursor(cursor, lines)

	if interactables.is_empty():
		lines.append("[color=red]Fix needed: No clickable DualCursor controls found.[/color]")
	else:
		lines.append("[color=green]OK: %d clickable DualCursor control(s) found.[/color]" % interactables.size())
		_validate_interactables(interactables, lines)
		_validate_shared_reachability(cursors, interactables, lines)
		_validate_private_boundaries(cursors, interactables, lines)

	if not InputMap.has_action("interact_p1"):
		lines.append("[color=red]Fix needed: Missing controller action interact_p1. Click Set Up Controller Actions.[/color]")
	if not InputMap.has_action("interact_p2"):
		lines.append("[color=red]Fix needed: Missing controller action interact_p2. Click Set Up Controller Actions.[/color]")
	if InputMap.has_action("interact_p1") and InputMap.has_action("interact_p2"):
		lines.append("[color=green]OK: Controller A/Cross actions are ready.[/color]")

	if managers.size() == 1 and not cursors.is_empty() and not interactables.is_empty() and InputMap.has_action("interact_p1") and InputMap.has_action("interact_p2"):
		lines.append("[color=green]Ready: Run the scene, then use the Use In Your Game examples below to connect DualCursor UI to your game logic.[/color]")

	_show_results(lines)

func _open_demo_scene() -> void:
	if ResourceLoader.exists(DEMO_SCENE_PATH):
		_plugin.get_editor_interface().open_scene_from_path(DEMO_SCENE_PATH)
	else:
		_show_results(["[color=red]Demo scene not found: %s[/color]" % DEMO_SCENE_PATH])

func _validate_cursor(cursor: Node, lines: Array[String]) -> void:
	var manager_path: NodePath = cursor.get("manager_path")
	var region_path: NodePath = cursor.get("region_node_path")

	if manager_path.is_empty():
		lines.append("[color=yellow]Warning: %s has no manager_path. It can still run by finding a manager automatically, but an explicit path is clearer.[/color]" % cursor.name)
	elif cursor.get_node_or_null(manager_path) == null:
		lines.append("[color=red]Fix needed: %s manager_path is invalid. Click Create 2-Player Setup again to repair generated cursors.[/color]" % cursor.name)

	if region_path.is_empty() or cursor.get_node_or_null(region_path) == null:
		lines.append("[color=red]Fix needed: %s has an invalid region_node_path. The cursor needs a Control region to clamp movement.[/color]" % cursor.name)

	var extra_paths: Array = cursor.get("extra_region_node_paths")
	for extra_path in extra_paths:
		if extra_path is NodePath and (extra_path as NodePath).is_empty():
			continue
		if not (extra_path is NodePath) or cursor.get_node_or_null(extra_path) == null:
			lines.append("[color=red]Fix needed: %s has an invalid extra movement region. Shared controls need valid extra_region_node_paths.[/color]" % cursor.name)

	if cursor is Sprite2D and cursor.texture == null:
		lines.append("[color=yellow]Warning: %s has no texture. It will use a generated fallback cursor at runtime.[/color]" % cursor.name)

func _validate_interactables(interactables: Array, lines: Array[String]) -> void:
	for node in interactables:
		if node is Control:
			if node.get_global_rect().size == Vector2.ZERO:
				lines.append("[color=yellow]Warning: %s has a zero-sized rect.[/color]" % node.name)
			if not node.is_visible_in_tree():
				lines.append("[color=yellow]Warning: %s is not visible in tree.[/color]" % node.name)

	for i in interactables.size():
		for j in range(i + 1, interactables.size()):
			var a: Control = interactables[i]
			var b: Control = interactables[j]
			if not (a is Control and b is Control):
				continue
			if a.get_global_rect().intersects(b.get_global_rect()) and int(a.get("hit_priority")) == int(b.get("hit_priority")):
				lines.append("[color=yellow]Warning: %s and %s overlap with the same hit_priority. Increase hit_priority on the one that should win.[/color]" % [a.name, b.name])

func _validate_shared_reachability(cursors: Array, interactables: Array, lines: Array[String]) -> void:
	for interactable in interactables:
		if not (interactable is Control):
			continue
		if int(interactable.get("owner_player_id")) != -1:
			continue

		var reachable_count := 0
		for cursor in cursors:
			if _cursor_can_reach_control(cursor, interactable):
				reachable_count += 1

		if reachable_count == 0:
			lines.append("[color=red]Fix needed: Shared control %s is outside all cursor movement regions.[/color]" % interactable.name)
		elif reachable_count < cursors.size():
			lines.append("[color=yellow]Warning: Shared control %s is reachable by only %d cursor(s).[/color]" % [interactable.name, reachable_count])

func _validate_private_boundaries(cursors: Array, interactables: Array, lines: Array[String]) -> void:
	for cursor in cursors:
		var cursor_player_id := int(cursor.get("player_id"))
		for interactable in interactables:
			if not (interactable is Control):
				continue

			var owner_player_id := int(interactable.get("owner_player_id"))
			if owner_player_id == -1 or owner_player_id == cursor_player_id:
				continue

			if _cursor_can_reach_control(cursor, interactable):
				lines.append("[color=red]Fix needed: %s can reach %s, but that control belongs to player %d. Move the control or remove the overlapping cursor region.[/color]" % [cursor.name, interactable.name, owner_player_id + 1])

func _cursor_can_reach_control(cursor: Node, control: Control) -> bool:
	for region in _get_cursor_regions(cursor):
		if region.get_global_rect().intersects(control.get_global_rect()):
			return true
	return false

func _get_cursor_regions(cursor: Node) -> Array[Control]:
	var regions: Array[Control] = []
	var region_path: NodePath = cursor.get("region_node_path")
	var primary := cursor.get_node_or_null(region_path) as Control
	if primary:
		regions.append(primary)

	var extra_paths: Array = cursor.get("extra_region_node_paths")
	for extra_path in extra_paths:
		if not (extra_path is NodePath):
			continue
		var extra := cursor.get_node_or_null(extra_path) as Control
		if extra and not regions.has(extra):
			regions.append(extra)

	return regions

func _ensure_manager(root: Node) -> Node:
	var existing := _find_by_script(root, MANAGER_SCRIPT)
	if not existing.is_empty():
		return existing[0]

	var manager := Node.new()
	manager.name = "DualCursorManager"
	manager.set_script(MANAGER_SCRIPT)
	_add_owned_child(root, manager)
	return manager

func _ensure_region(root: Node, node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var existing := root.get_node_or_null(node_name) as ColorRect
	if existing:
		existing.position = rect.position
		existing.size = rect.size
		existing.color = color
		return existing

	var region := ColorRect.new()
	region.name = node_name
	region.color = color
	region.position = rect.position
	region.size = rect.size
	_add_owned_child(root, region)
	return region

func _ensure_cursor(root: Node, node_name: String, player_id: int, region: Node, extra_regions: Array, manager: Node, interact_action: String) -> Node:
	var existing := root.get_node_or_null(node_name)
	if existing:
		existing.player_id = player_id
		existing.region_node_path = existing.get_path_to(region)
		existing.extra_region_node_paths = _paths_to(existing, extra_regions)
		existing.manager_path = existing.get_path_to(manager)
		existing.interact_action = interact_action
		if existing is Sprite2D and existing.texture == null:
			existing.texture = _create_preview_cursor_texture(Color(0.2, 0.72, 1.0, 1.0) if player_id == 0 else Color(1.0, 0.78, 0.25, 1.0))
		return existing

	var cursor := Sprite2D.new()
	cursor.name = node_name
	cursor.set_script(CURSOR_SCRIPT)
	_add_owned_child(root, cursor)
	cursor.player_id = player_id
	cursor.region_node_path = cursor.get_path_to(region)
	cursor.extra_region_node_paths = _paths_to(cursor, extra_regions)
	cursor.manager_path = cursor.get_path_to(manager)
	cursor.interact_action = interact_action
	cursor.texture = _create_preview_cursor_texture(Color(0.2, 0.72, 1.0, 1.0) if player_id == 0 else Color(1.0, 0.78, 0.25, 1.0))
	return cursor

func _paths_to(from_node: Node, nodes: Array) -> Array[NodePath]:
	var paths: Array[NodePath] = []
	for node in nodes:
		if node is Node:
			paths.append(from_node.get_path_to(node))
	return paths

func _ensure_button(parent: Node, node_name: String, text: String, owner_player_id: int, rect: Rect2) -> Control:
	var existing := parent.get_node_or_null(node_name) as Control
	if existing:
		return existing

	var button := Control.new()
	button.name = node_name
	button.position = rect.position
	button.size = rect.size
	button.custom_minimum_size = rect.size
	button.set_script(BUTTON_SCRIPT)
	button.owner_player_id = owner_player_id
	button.hit_priority = 10
	button.label_path = ^"Panel/Label"
	_add_owned_child(parent, button)

	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_add_owned_child(button, panel)

	var label := Label.new()
	label.name = "Label"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_add_owned_child(panel, label)
	return button

func _add_action_if_missing(action_name: String, device: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)

	var has_event := false
	for event in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton and event.device == device and event.button_index == JOY_BUTTON_A:
			has_event = true
			break

	if not has_event:
		var joy_event := InputEventJoypadButton.new()
		joy_event.device = device
		joy_event.button_index = JOY_BUTTON_A
		InputMap.action_add_event(action_name, joy_event)

func _find_by_script(root: Node, script: Script) -> Array:
	var matches := []
	for node in _walk(root):
		if node.get_script() == script:
			matches.append(node)
	return matches

func _find_interactables(root: Node) -> Array:
	var matches := []
	for node in _walk(root):
		if node is Control and node.has_method("on_cursor_interact") and node.has_method("get_denial_reason"):
			matches.append(node)
	return matches

func _walk(root: Node) -> Array:
	var nodes := [root]
	for child in root.get_children():
		nodes.append_array(_walk(child))
	return nodes

func _add_owned_child(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _get_scene_root()

func _get_scene_root() -> Node:
	if _plugin == null:
		return null
	return _plugin.get_editor_interface().get_edited_scene_root()

func _show_results(lines: Array) -> void:
	if _results == null:
		return
	_results.clear()
	_results.append_text("\n".join(lines))

func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	return label

func _section(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	return label

func _paragraph(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _guide_panel(title: String, description: String, code: String) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 14)
	box.add_child(heading)

	box.add_child(_paragraph(description))

	var code_box := TextEdit.new()
	code_box.text = code
	code_box.editable = false
	code_box.selecting_enabled = true
	code_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	code_box.custom_minimum_size = Vector2(0, 170)
	code_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(code_box)

	var copy_button := _button("Copy Code")
	copy_button.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(code)
		_show_results(["[color=green]Copied example: %s[/color]" % title])
	)
	box.add_child(copy_button)

	return panel

func _create_preview_cursor_texture(color: Color) -> Texture2D:
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
