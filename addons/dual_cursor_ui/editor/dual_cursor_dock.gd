@tool
extends VBoxContainer

const DualCursorInputSetup := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_input_setup.gd")
const MANAGER_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_manager.gd"
const MANAGER_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_manager.gd")
const CURSOR_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor.gd"
const CURSOR_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor.gd")
const NAVIGATION_PANEL_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_navigation_panel.gd"
const NAVIGATION_PANEL_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_navigation_panel.gd")
const DEMO_SCENE_PATH := "res://addons/dual_cursor_ui/demos/two_player_menu_demo.tscn"
const PANEL_OCCUPANCY_ALLOW_MULTIPLE := 0
const PANEL_OCCUPANCY_FIRST_PLAYER_LOCKS := 1
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
var _panel_preset: OptionButton
var _selected_panel_status: Label
var _selected_target_status: Label

func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin

func _ready() -> void:
	name = "DualCursor UI"
	custom_minimum_size = Vector2(360, 0)
	_build_ui()
	_refresh_selected_panel_info()
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
	var create_button := _button("Create Playable 2-Player Scene")
	create_button.pressed.connect(_create_playable_scene)
	body.add_child(create_button)
	body.add_child(_paragraph("Creates a complete playable template with private menu panels, private dialogue choices, exclusive shared panels, simultaneous shared panels, cursors, logging, and controller actions. The template adapts to the current viewport and does not require a fixed project window size."))

	body.add_child(_section("Panel Builder"))
	body.add_child(_paragraph("Select one of your own Control panels, choose an access preset, then configure it for controller navigation. The builder also adds a lightweight two-player cursor runtime if the scene does not already have one."))
	_selected_panel_status = _paragraph("Selected panel: none")
	body.add_child(_selected_panel_status)
	_selected_target_status = _paragraph("Detected targets: 0")
	body.add_child(_selected_target_status)

	_panel_preset = OptionButton.new()
	_panel_preset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_preset.add_item("Player 1 Private", 0)
	_panel_preset.add_item("Player 2 Private", 1)
	_panel_preset.add_item("Shared Exclusive", 2)
	_panel_preset.add_item("Shared Simultaneous", 3)
	body.add_child(_panel_preset)

	var refresh_panel_button := _button("Refresh Selected Panel Info")
	refresh_panel_button.pressed.connect(_refresh_selected_panel_info)
	body.add_child(refresh_panel_button)

	var setup_panel_button := _button("Setup Selected Panel")
	setup_panel_button.pressed.connect(_setup_selected_panel)
	body.add_child(setup_panel_button)

	var validate_panel_button := _button("Validate Selected Panel")
	validate_panel_button.pressed.connect(_validate_selected_panel)
	body.add_child(validate_panel_button)

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
	body.add_child(_paragraph("Try this now: click Create Playable 2-Player Scene, press Play, move each cursor with the left stick, enter each panel type, press A/Cross on choices, and press B/Circle to return to free movement."))
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

func _create_playable_scene() -> void:
	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=red]Open or create a scene before running setup.[/color]"])
		return

	if not ResourceLoader.exists(DEMO_SCENE_PATH):
		_show_results(["[color=red]Demo scene not found: %s[/color]" % DEMO_SCENE_PATH])
		return

	var existing: Node = root.get_node_or_null("DualCursorUIDemo")
	if existing:
		root.remove_child(existing)
		existing.free()

	var demo_scene: PackedScene = load(DEMO_SCENE_PATH) as PackedScene
	var demo := demo_scene.instantiate()
	demo.name = "DualCursorUIDemo"
	_make_scene_local(demo)
	root.add_child(demo)
	_set_owner_recursive(demo, root)
	_prepare_demo_root(demo)
	_add_input_actions()

	_show_results([
		"[color=green]OK: Created a playable 2-player DualCursor scene.[/color]",
		"Try next: Press Play and move both cursors with the left sticks.",
		"Try next: Enter the private menu, private dialogue, exclusive shared, and simultaneous shared panels.",
		"Try next: Press A/Cross on targets, press B/Circle to exit, and watch the event log."
	])
	_run_validation()

func _add_input_actions() -> void:
	DualCursorInputSetup.ensure_default_actions(true)
	_show_results([
		"[color=green]OK: Controller A/Cross and B/Circle actions are ready.[/color]",
		"This creates the project-level actions DualCursor uses for select and panel-navigation exit.",
		"You usually only need to press this once per project.",
		"`interact_p1` and `interact_p2` use A/Cross. `cancel_p1` and `cancel_p2` use B/Circle."
	])

func _setup_selected_panel() -> void:
	var panel: Control = _get_selected_control()
	if panel == null:
		_show_results(["[color=red]Select a Control node before running Panel Builder.[/color]"])
		_refresh_selected_panel_info()
		return

	var script: Script = panel.get_script() as Script
	if script and script.resource_path != NAVIGATION_PANEL_SCRIPT_PATH:
		_show_results([
			"[color=red]Panel Builder will not overwrite %s's existing script.[/color]" % panel.name,
			"Use a plain Control node or an existing DualCursorNavigationPanel."
		])
		_refresh_selected_panel_info()
		return

	var target_paths: Array[NodePath] = _detect_navigation_target_paths(panel)
	if target_paths.is_empty():
		_show_results([
			"[color=red]No usable navigation targets found under %s.[/color]" % panel.name,
			"Add visible Button children, or visible Control rows, then refresh."
		])
		_refresh_selected_panel_info()
		return

	if script == null:
		panel.set_script(NAVIGATION_PANEL_SCRIPT)

	var preset_id: int = _panel_preset.get_selected_id() if _panel_preset else 0
	panel.set("owner_player_id", _preset_owner_player_id(preset_id))
	panel.set("occupancy_policy", _preset_occupancy_policy(preset_id))
	panel.set("navigation_targets", target_paths)
	panel.set("selection_width", 8.0)
	panel.set("selection_padding", 2.0)
	panel.set("player_selection_colors", PackedColorArray([
		Color(0.0, 0.42, 0.78, 1.0),
		Color(0.86, 0.28, 0.12, 1.0)
	]))

	DualCursorInputSetup.ensure_default_actions(true)
	var rig_messages: Array[String] = _ensure_cursor_runtime(panel)
	_mark_scene_unsaved()
	_refresh_selected_panel_info()
	var result_lines: Array[String] = [
		"[color=green]OK: Configured %s as %s.[/color]" % [panel.name, _preset_name(preset_id)],
		"Navigation targets: %d" % target_paths.size(),
		"Run Validate Selected Panel, then run the scene and move a cursor into this panel."
	]
	result_lines.append_array(rig_messages)
	_show_results(result_lines)

func _validate_selected_panel() -> void:
	var panel: Control = _get_selected_control()
	if panel == null:
		_show_results(["[color=red]Select a Control node to validate.[/color]"])
		_refresh_selected_panel_info()
		return

	var lines: Array[String] = []
	var script: Script = panel.get_script() as Script
	if script == null or script.resource_path != NAVIGATION_PANEL_SCRIPT_PATH:
		lines.append("[color=red]Fix needed: %s is not a DualCursorNavigationPanel. Click Setup Selected Panel.[/color]" % panel.name)
		_show_results(lines)
		_refresh_selected_panel_info()
		return

	lines.append("[color=green]OK: %s uses DualCursorNavigationPanel.[/color]" % panel.name)
	var target_paths: Array = panel.get("navigation_targets")
	if target_paths.is_empty():
		lines.append("[color=red]Fix needed: %s has no navigation_targets.[/color]" % panel.name)
	else:
		lines.append("[color=green]OK: %d navigation target(s) assigned.[/color]" % target_paths.size())
		for target_path in target_paths:
			if not (target_path is NodePath) or (target_path as NodePath).is_empty():
				lines.append("[color=red]Fix needed: %s has an empty navigation target path.[/color]" % panel.name)
				continue
			_validate_navigation_target(panel, target_path, lines)

	lines.append("[color=green]Preset: %s.[/color]" % _panel_preset_summary(panel))
	_show_results(lines)
	_refresh_selected_panel_info()

func _refresh_selected_panel_info() -> void:
	if _selected_panel_status == null or _selected_target_status == null:
		return

	var panel: Control = _get_selected_control()
	if panel == null:
		_selected_panel_status.text = "Selected panel: none"
		_selected_target_status.text = "Detected targets: 0"
		return

	var script: Script = panel.get_script() as Script
	var script_status: String = "plain Control"
	if script:
		script_status = "DualCursorNavigationPanel" if script.resource_path == NAVIGATION_PANEL_SCRIPT_PATH else "custom script"
	_selected_panel_status.text = "Selected panel: %s (%s)" % [panel.name, script_status]
	_selected_target_status.text = "Detected targets: %d" % _detect_navigation_target_paths(panel).size()

func _get_selected_control() -> Control:
	if _plugin == null:
		return null
	var selection := _plugin.get_editor_interface().get_selection()
	if selection == null:
		return null
	var nodes: Array = selection.get_selected_nodes()
	if nodes.is_empty():
		return null
	for node in nodes:
		if node is Control:
			return node
	return null

func _detect_navigation_target_paths(panel: Control) -> Array[NodePath]:
	var buttons: Array[Control] = []
	_collect_target_controls(panel, panel, buttons, true)
	var controls: Array[Control] = []
	if buttons.is_empty():
		_collect_target_controls(panel, panel, controls, false)
	else:
		controls.append_array(buttons)

	var paths: Array[NodePath] = []
	for control in controls:
		paths.append(panel.get_path_to(control))
	return paths

func _collect_target_controls(root_panel: Control, node: Node, results: Array[Control], buttons_only: bool) -> void:
	for child in node.get_children():
		if child is Control:
			var control: Control = child as Control
			if _is_usable_panel_target(root_panel, control, buttons_only):
				results.append(control)
			_collect_target_controls(root_panel, child, results, buttons_only)

func _is_usable_panel_target(root_panel: Control, control: Control, buttons_only: bool) -> bool:
	if control == root_panel:
		return false
	if control.name == "DualCursorRuntime":
		return false
	if not control.visible:
		return false
	if buttons_only:
		return control is BaseButton
	if control is Label or control is ColorRect or control is TextureRect:
		return false
	return control.size != Vector2.ZERO

func _preset_owner_player_id(preset_id: int) -> int:
	match preset_id:
		0:
			return 0
		1:
			return 1
		_:
			return -1

func _preset_occupancy_policy(preset_id: int) -> int:
	return PANEL_OCCUPANCY_FIRST_PLAYER_LOCKS if preset_id == 2 else PANEL_OCCUPANCY_ALLOW_MULTIPLE

func _preset_name(preset_id: int) -> String:
	match preset_id:
		0:
			return "Player 1 Private"
		1:
			return "Player 2 Private"
		2:
			return "Shared Exclusive"
		3:
			return "Shared Simultaneous"
	return "Unknown Preset"

func _panel_preset_summary(panel: Control) -> String:
	var owner_player_id: int = int(panel.get("owner_player_id"))
	var occupancy_policy: int = int(panel.get("occupancy_policy"))
	if owner_player_id == 0:
		return "Player 1 Private"
	if owner_player_id == 1:
		return "Player 2 Private"
	if occupancy_policy == PANEL_OCCUPANCY_FIRST_PLAYER_LOCKS:
		return "Shared Exclusive"
	return "Shared Simultaneous"

func _mark_scene_unsaved() -> void:
	if _plugin == null:
		return
	var editor_interface := _plugin.get_editor_interface()
	if editor_interface and editor_interface.has_method("mark_scene_as_unsaved"):
		editor_interface.mark_scene_as_unsaved()

func _ensure_cursor_runtime(panel: Control) -> Array[String]:
	var lines: Array[String] = []
	var root := _get_scene_root()
	if root == null:
		return lines

	var manager: Node = _find_first_by_script_path(root, MANAGER_SCRIPT_PATH)
	var rig: Control = root.get_node_or_null("DualCursorRuntime") as Control
	if rig == null:
		rig = Control.new()
		rig.name = "DualCursorRuntime"
		rig.set_anchors_preset(Control.PRESET_FULL_RECT)
		rig.set_offsets_preset(Control.PRESET_FULL_RECT)
		rig.size = panel.get_viewport_rect().size
		rig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(rig)
		_set_owner_recursive(rig, root)
		lines.append("Added DualCursorRuntime with a full-viewport movement region.")

	var travel_region: ColorRect = rig.get_node_or_null("CursorTravelRegion") as ColorRect
	if travel_region == null:
		travel_region = ColorRect.new()
		travel_region.name = "CursorTravelRegion"
		travel_region.color = Color(0, 0, 0, 0)
		travel_region.mouse_filter = Control.MOUSE_FILTER_IGNORE
		travel_region.set_anchors_preset(Control.PRESET_FULL_RECT)
		travel_region.set_offsets_preset(Control.PRESET_FULL_RECT)
		travel_region.size = panel.get_viewport_rect().size
		rig.add_child(travel_region)
		travel_region.owner = root

	if manager == null:
		manager = Node.new()
		manager.name = "DualCursorManager"
		manager.set_script(MANAGER_SCRIPT)
		rig.add_child(manager)
		manager.owner = root
		lines.append("Added DualCursorManager.")

	if _ensure_runtime_cursor(rig, root, manager, travel_region, "Cursor1", 0, "interact_p1", "cancel_p1", Color(0.2, 0.72, 1.0, 1.0), panel):
		lines.append("Added Player 1 cursor.")
	if _ensure_runtime_cursor(rig, root, manager, travel_region, "Cursor2", 1, "interact_p2", "cancel_p2", Color(1.0, 0.45, 0.25, 1.0), panel):
		lines.append("Added Player 2 cursor.")
	return lines

func _ensure_runtime_cursor(rig: Control, scene_root: Node, manager: Node, travel_region: Control, cursor_name: String, player_id: int, interact_action: String, cancel_action: String, color: Color, panel: Control) -> bool:
	var cursor: Sprite2D = _find_cursor_by_player(scene_root, player_id)
	var created := false
	if cursor == null:
		cursor = Sprite2D.new()
		cursor.name = cursor_name
		cursor.z_index = 100
		cursor.set_script(CURSOR_SCRIPT)
		rig.add_child(cursor)
		cursor.owner = scene_root
		created = true

	cursor.set("player_id", player_id)
	cursor.set("manager_path", cursor.get_path_to(manager))
	cursor.set("region_node_path", cursor.get_path_to(travel_region))
	cursor.set("extra_region_node_paths", [cursor.get_path_to(panel)])
	cursor.set("interact_action", interact_action)
	cursor.set("cancel_action", cancel_action)
	cursor.set("fallback_cursor_color", color)
	cursor.set("center_on_primary_region_at_ready", false)
	_place_cursor_near_panel(cursor, panel, player_id)
	return created

func _place_cursor_near_panel(cursor: Sprite2D, panel: Control, player_id: int) -> void:
	var panel_rect: Rect2 = panel.get_global_rect()
	var viewport_size: Vector2 = panel.get_viewport_rect().size
	var player_offset: float = float(player_id) * 36.0
	var start_position: Vector2 = panel_rect.position + Vector2(-48.0, 24.0 + player_offset)

	if start_position.x < 8.0:
		start_position.x = panel_rect.position.x + 24.0 + player_offset

	start_position.x = clamp(start_position.x, 8.0, max(8.0, viewport_size.x - 8.0))
	start_position.y = clamp(start_position.y, 8.0, max(8.0, viewport_size.y - 8.0))
	cursor.global_position = start_position

func _find_cursor_by_player(root: Node, player_id: int) -> Sprite2D:
	for node in _find_by_script_path(root, CURSOR_SCRIPT_PATH):
		if int(node.get("player_id")) == player_id and node is Sprite2D:
			return node as Sprite2D
	return null

func _find_first_by_script_path(root: Node, script_path: String) -> Node:
	var nodes := _find_by_script_path(root, script_path)
	if nodes.is_empty():
		return null
	return nodes[0]

func _run_validation() -> void:
	if _results == null:
		return

	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=yellow]No edited scene is open.[/color]"])
		return

	var lines: Array[String] = []
	var managers := _find_by_script_path(root, MANAGER_SCRIPT_PATH)
	var cursors := _find_by_script_path(root, CURSOR_SCRIPT_PATH)
	var navigation_panels := _find_by_script_path(root, NAVIGATION_PANEL_SCRIPT_PATH)
	var interactables := _find_interactables(root)

	if managers.is_empty():
		lines.append("[color=red]Fix needed: Missing DualCursorManager. Click Create Playable 2-Player Scene.[/color]")
	elif managers.size() > 1:
		lines.append("[color=yellow]Warning: Multiple DualCursorManager nodes found. One is usually enough.[/color]")
	else:
		lines.append("[color=green]OK: Scene has the router that connects cursors to UI controls.[/color]")

	if cursors.is_empty():
		lines.append("[color=red]Fix needed: No DualCursor nodes found. Click Create Playable 2-Player Scene.[/color]")
	else:
		lines.append("[color=green]OK: %d player cursor node(s) found.[/color]" % cursors.size())

	for cursor in cursors:
		_validate_cursor(cursor, lines)

	if interactables.is_empty() and navigation_panels.is_empty():
		lines.append("[color=red]Fix needed: No clickable DualCursor controls found.[/color]")
	elif interactables.is_empty():
		lines.append("[color=green]OK: Scene uses controller-navigation panels for interaction.[/color]")
	else:
		lines.append("[color=green]OK: %d clickable DualCursor control(s) found.[/color]" % interactables.size())
		_validate_interactables(interactables, lines)
		_validate_shared_reachability(cursors, interactables, lines)
		_validate_private_boundaries(cursors, interactables, lines)

	if not navigation_panels.is_empty():
		lines.append("[color=green]OK: %d controller-navigation panel(s) found.[/color]" % navigation_panels.size())
		_validate_navigation_panels(navigation_panels, lines)

	if not InputMap.has_action("interact_p1"):
		lines.append("[color=red]Fix needed: Missing controller action interact_p1. Click Create Playable 2-Player Scene.[/color]")
	if not InputMap.has_action("interact_p2"):
		lines.append("[color=red]Fix needed: Missing controller action interact_p2. Click Create Playable 2-Player Scene.[/color]")
	if not InputMap.has_action("cancel_p1"):
		lines.append("[color=yellow]Warning: Missing controller action cancel_p1. Panel navigation needs a release action.[/color]")
	if not InputMap.has_action("cancel_p2"):
		lines.append("[color=yellow]Warning: Missing controller action cancel_p2. Panel navigation needs a release action.[/color]")
	if InputMap.has_action("interact_p1") and InputMap.has_action("interact_p2") and InputMap.has_action("cancel_p1") and InputMap.has_action("cancel_p2"):
		lines.append("[color=green]OK: Controller select and cancel actions are ready.[/color]")

	if managers.size() == 1 and not cursors.is_empty() and (not interactables.is_empty() or not navigation_panels.is_empty()) and InputMap.has_action("interact_p1") and InputMap.has_action("interact_p2") and InputMap.has_action("cancel_p1") and InputMap.has_action("cancel_p2"):
		lines.append("[color=green]Ready: Run the scene, then use the Use In Your Game examples below to connect DualCursor UI to your game logic.[/color]")

	_show_results(lines)

func _validate_cursor(cursor: Node, lines: Array[String]) -> void:
	var manager_path: NodePath = cursor.get("manager_path")
	var region_path: NodePath = cursor.get("region_node_path")

	if manager_path.is_empty():
		lines.append("[color=yellow]Warning: %s has no manager_path. It can still run by finding a manager automatically, but an explicit path is clearer.[/color]" % cursor.name)
	elif cursor.get_node_or_null(manager_path) == null:
		lines.append("[color=red]Fix needed: %s manager_path is invalid. Click Create Playable 2-Player Scene again to repair generated cursors.[/color]" % cursor.name)

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

	var interact_action := str(cursor.get("interact_action"))
	if not interact_action.is_empty() and not InputMap.has_action(interact_action):
		lines.append("[color=red]Fix needed: %s uses missing interact action %s.[/color]" % [cursor.name, interact_action])

	var cancel_action := str(cursor.get("cancel_action"))
	if not cancel_action.is_empty() and not InputMap.has_action(cancel_action):
		lines.append("[color=yellow]Warning: %s uses missing cancel action %s. Panel navigation needs a release action.[/color]" % [cursor.name, cancel_action])

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

func _validate_navigation_panels(navigation_panels: Array, lines: Array[String]) -> void:
	for panel in navigation_panels:
		if not (panel is Control):
			continue
		var target_paths: Array = panel.get("navigation_targets")
		if target_paths.is_empty():
			lines.append("[color=red]Fix needed: %s has no navigation_targets.[/color]" % panel.name)
			continue
		for target_path in target_paths:
			if not (target_path is NodePath) or (target_path as NodePath).is_empty():
				lines.append("[color=red]Fix needed: %s has an empty navigation target path.[/color]" % panel.name)
				continue
			_validate_navigation_target(panel, target_path, lines)

func _validate_navigation_target(panel: Control, target_path: NodePath, lines: Array[String]) -> void:
	var node: Node = panel.get_node_or_null(target_path)
	if node == null or not (node is Control):
		lines.append("[color=red]Fix needed: %s has an invalid navigation target: %s.[/color]" % [panel.name, target_path])
		return

	var control: Control = node as Control
	if control.get_global_rect().size == Vector2.ZERO:
		lines.append("[color=yellow]Warning: %s navigation target %s has a zero-sized rect.[/color]" % [panel.name, control.name])
	elif not control.is_visible_in_tree():
		lines.append("[color=yellow]Warning: %s navigation target %s is hidden.[/color]" % [panel.name, control.name])

func _cursor_can_reach_control(cursor: Node, control: Control) -> bool:
	for region in _get_cursor_regions(cursor):
		if region.get_global_rect().intersects(control.get_global_rect()):
			return true
	return false

func _get_cursor_regions(cursor: Node) -> Array[Control]:
	var regions: Array[Control] = []
	var region_path: NodePath = cursor.get("region_node_path")
	var primary: Control = cursor.get_node_or_null(region_path) as Control
	if primary:
		regions.append(primary)

	var extra_paths: Array = cursor.get("extra_region_node_paths")
	for extra_path in extra_paths:
		if not (extra_path is NodePath):
			continue
		var extra: Control = cursor.get_node_or_null(extra_path) as Control
		if extra and not regions.has(extra):
			regions.append(extra)

	return regions

func _find_by_script_path(root: Node, script_path: String) -> Array:
	var matches := []
	for node in _walk(root):
		var script: Script = node.get_script() as Script
		if script and script.resource_path == script_path:
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

func _get_scene_root() -> Node:
	if _plugin == null:
		return null
	return _plugin.get_editor_interface().get_edited_scene_root()

func _make_scene_local(node: Node) -> void:
	node.scene_file_path = ""
	for child in node.get_children():
		_make_scene_local(child)

func _set_owner_recursive(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_set_owner_recursive(child, owner)

func _prepare_demo_root(demo: Node) -> void:
	if demo is Control:
		var control: Control = demo as Control
		control.position = Vector2.ZERO
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
		control.set_offsets_preset(Control.PRESET_FULL_RECT)
		control.size = control.get_viewport_rect().size

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
