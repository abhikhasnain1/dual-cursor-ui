@tool
extends VBoxContainer

const DualCursorInputSetup := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_input_setup.gd")
const MANAGER_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_manager.gd"
const MANAGER_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_manager.gd")
const CURSOR_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor.gd"
const CURSOR_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor.gd")
const DEBUG_OVERLAY_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_debug_overlay.gd"
const DEBUG_OVERLAY_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_debug_overlay.gd")
const NAVIGATION_PANEL_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_navigation_panel.gd"
const NAVIGATION_PANEL_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_navigation_panel.gd")
const GRID_NAVIGATION_PANEL_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_grid_navigation_panel.gd"
const GRID_NAVIGATION_PANEL_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_grid_navigation_panel.gd")
const DualCursorThemePresets := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_theme_presets.gd")
const DEMO_SCENE_PATH := "res://addons/dual_cursor_ui/demos/two_player_menu_demo.tscn"
const PANEL_OCCUPANCY_ALLOW_MULTIPLE := 0
const PANEL_OCCUPANCY_FIRST_PLAYER_LOCKS := 1
const PANEL_TYPE_LIST := 0
const PANEL_TYPE_GRID := 1
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
const PANEL_ACTION_EXAMPLE := """extends Node

@export var panel: DualCursorNavigationPanel

func _ready() -> void:
	panel.target_activated.connect(_on_panel_target_activated)

func _on_panel_target_activated(player_id: int, target: Control, cursor: Node) -> void:
	match str(target.get_meta("action", target.name)):
		"inventory":
			open_inventory(player_id)
		"skill":
			open_skill_tree(player_id)
		"ready":
			set_ready(player_id)
"""
const DIALOGUE_CHOICES_EXAMPLE := """extends Node

@export var dialogue_panel: DualCursorNavigationPanel
@export var choices_container: VBoxContainer

func _ready() -> void:
	dialogue_panel.target_activated.connect(_on_dialogue_choice_selected)

func show_dialogue_choices(player_id: int, choices: Array[Dictionary]) -> void:
	for child in choices_container.get_children():
		child.queue_free()

	dialogue_panel.navigation_targets.clear()
	dialogue_panel.owner_player_id = player_id

	for choice in choices:
		var button := Button.new()
		button.text = str(choice["text"])
		button.set_meta("choice_id", choice["id"])
		choices_container.add_child(button)
		dialogue_panel.navigation_targets.append(dialogue_panel.get_path_to(button))

func _on_dialogue_choice_selected(player_id: int, target: Control, cursor: Node) -> void:
	var choice_id := str(target.get_meta("choice_id", ""))
	print("Player %d chose %s" % [player_id + 1, choice_id])
"""
const NARRATIVE_EVENT_EXAMPLE := """extends Node

@export var narrative_panel: DualCursorNavigationPanel
@export var clock_label: Label

var progress_clock: int = 0

func _ready() -> void:
	narrative_panel.target_activated.connect(_on_narrative_target_activated)

func _on_narrative_target_activated(player_id: int, target: Control, cursor: Node) -> void:
	var choice_id := str(target.get_meta("choice_id", ""))
	var event_id := str(target.get_meta("event_id", ""))
	var skill_id := str(target.get_meta("skill_id", ""))

	if not choice_id.is_empty():
		print("P%d chose %s" % [player_id + 1, choice_id])
	elif not skill_id.is_empty():
		progress_clock += 1
		clock_label.text = "Clock: %d/6" % progress_clock
	elif not event_id.is_empty():
		print("P%d confirmed %s" % [player_id + 1, event_id])
"""

var _plugin: EditorPlugin
var _results: RichTextLabel
var _panel_preset: OptionButton
var _panel_type: OptionButton
var _grid_columns: SpinBox
var _controller_profile: OptionButton
var _theme_preset: OptionButton
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

	body.add_child(_section("Controller Profile"))
	body.add_child(_paragraph("DualCursor UI v0.5.0 supports the two-controller workflow. Apply a profile to create or repair the player select/cancel actions."))
	_controller_profile = OptionButton.new()
	_controller_profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for profile_name in DualCursorInputSetup.profile_names():
		_controller_profile.add_item(DualCursorInputSetup.profile_display_name(profile_name))
		_controller_profile.set_item_metadata(_controller_profile.get_item_count() - 1, profile_name)
	body.add_child(_controller_profile)
	var apply_profile_button := _button("Apply Controller Profile")
	apply_profile_button.pressed.connect(_apply_controller_profile)
	body.add_child(apply_profile_button)

	body.add_child(_section("Theme Preset"))
	body.add_child(_paragraph("Apply a visual preset to selected navigation panels or generated cursors. Use High Contrast when controller focus needs stronger visibility."))
	_theme_preset = OptionButton.new()
	_theme_preset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for preset_name in DualCursorThemePresets.preset_names():
		_theme_preset.add_item(DualCursorThemePresets.display_name(preset_name))
		_theme_preset.set_item_metadata(_theme_preset.get_item_count() - 1, preset_name)
	body.add_child(_theme_preset)
	var apply_panel_theme_button := _button("Apply Theme To Selected Panel")
	apply_panel_theme_button.pressed.connect(_apply_theme_to_selected_panel)
	body.add_child(apply_panel_theme_button)
	var apply_scene_theme_button := _button("Apply Theme To Generated Runtime")
	apply_scene_theme_button.pressed.connect(_apply_theme_to_generated_runtime)
	body.add_child(apply_scene_theme_button)

	body.add_child(_section("Panel Builder"))
	body.add_child(_paragraph("Select one of your own Control panels, choose an access preset, choose List or Grid, then configure it for controller navigation. Grid panels are intended for inventories, shops, skill trees, and tactical commands."))
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

	_panel_type = OptionButton.new()
	_panel_type.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_type.add_item("List Panel", PANEL_TYPE_LIST)
	_panel_type.add_item("Grid Panel", PANEL_TYPE_GRID)
	body.add_child(_panel_type)

	_grid_columns = SpinBox.new()
	_grid_columns.min_value = 1
	_grid_columns.max_value = 12
	_grid_columns.step = 1
	_grid_columns.value = 4
	_grid_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_columns.tooltip_text = "Grid columns used when Panel Type is Grid Panel."
	body.add_child(_grid_columns)

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
	var overlay_button := _button("Add/Toggle Debug Overlay")
	overlay_button.pressed.connect(_toggle_debug_overlay)
	body.add_child(overlay_button)
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
	body.add_child(_paragraph("Use Create Playable 2-Player Scene to test the full template, or select your own Control panel and run Panel Builder. Press A/Cross to activate and B/Circle to leave controller-navigation panels."))
	body.add_child(_paragraph("For built panels, connect DualCursorNavigationPanel.target_activated(player_id, target, cursor). For standalone DualCursorButton nodes, connect pressed_by_player(player_id, cursor). Set owner_player_id to 0 for player 1, 1 for player 2, and -1 for shared."))

	body.add_child(_section("Use In Your Game"))
	body.add_child(_paragraph("These examples are safe to paste into a normal game script. Assign the exported nodes in the Inspector, then connect the plugin's player-aware signals to your own game state."))
	body.add_child(_guide_panel(
		"Connect Panel Buttons",
		"Use target_activated for buttons inside Panel Builder menus because it reports both the player and selected target.",
		PANEL_ACTION_EXAMPLE
	))
	body.add_child(_guide_panel(
		"Populate Dialogue Choices",
		"Create normal Button or Control rows, append them to navigation_targets, and store your dialogue choice id in metadata.",
		DIALOGUE_CHOICES_EXAMPLE
	))
	body.add_child(_guide_panel(
		"Narrative And TTRPG Events",
		"Route choice_id, skill_id, and event_id metadata into your own story, dice, clock, inventory, or location systems.",
		NARRATIVE_EVENT_EXAMPLE
	))
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

func _apply_controller_profile() -> void:
	var profile_name := _selected_controller_profile()
	DualCursorInputSetup.ensure_profile(profile_name, true)
	_show_results([
		"[color=green]OK: Applied %s controller profile.[/color]" % DualCursorInputSetup.profile_display_name(profile_name),
		"This creates or repairs two-controller select/cancel actions.",
		"Select remains A/Cross. Cancel remains B/Circle."
	])

func _apply_theme_to_selected_panel() -> void:
	var panel: Control = _get_selected_control()
	if panel == null:
		_show_results(["[color=red]Select a DualCursorNavigationPanel or plain panel first.[/color]"])
		return

	var script: Script = panel.get_script() as Script
	if script == null or not _is_supported_panel_script(script):
		_show_results(["[color=red]%s is not a DualCursor navigation panel. Run Setup Selected Panel first.[/color]" % panel.name])
		return

	var preset_name := _selected_theme_preset()
	DualCursorThemePresets.apply_to_navigation_panel(panel, preset_name)
	_mark_scene_unsaved()
	_show_results(["[color=green]OK: Applied %s theme to %s.[/color]" % [DualCursorThemePresets.display_name(preset_name), panel.name]])

func _apply_theme_to_generated_runtime() -> void:
	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=yellow]No edited scene is open.[/color]"])
		return

	var preset_name := _selected_theme_preset()
	for panel in _find_by_script_path(root, NAVIGATION_PANEL_SCRIPT_PATH):
		if panel is Control:
			DualCursorThemePresets.apply_to_navigation_panel(panel, preset_name)
	for panel in _find_by_script_path(root, GRID_NAVIGATION_PANEL_SCRIPT_PATH):
		if panel is Control:
			DualCursorThemePresets.apply_to_navigation_panel(panel, preset_name)
	for cursor in _find_by_script_path(root, CURSOR_SCRIPT_PATH):
		DualCursorThemePresets.apply_to_cursor(cursor, int(cursor.get("player_id")), preset_name)
	for node in _walk(root):
		if node is BaseButton:
			DualCursorThemePresets.apply_to_button(node as BaseButton, preset_name)
		elif node is Panel or node is PanelContainer:
			DualCursorThemePresets.apply_to_surface(node as Control, preset_name)

	_mark_scene_unsaved()
	_show_results(["[color=green]OK: Applied %s theme to generated DualCursor panels and cursors.[/color]" % DualCursorThemePresets.display_name(preset_name)])

func _toggle_debug_overlay() -> void:
	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=yellow]No edited scene is open.[/color]"])
		return

	var overlay: Control = _find_first_by_script_path(root, DEBUG_OVERLAY_SCRIPT_PATH) as Control
	var created := false
	if overlay == null:
		overlay = Control.new()
		overlay.name = "DualCursorDebugOverlay"
		overlay.set_script(DEBUG_OVERLAY_SCRIPT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.z_index = 4096
		root.add_child(overlay)
		_set_owner_recursive(overlay, root)
		created = true

	var next_enabled := true if created else not bool(overlay.get("enabled"))
	overlay.set("enabled", next_enabled)
	_mark_scene_unsaved()
	_show_results(["[color=green]Debug overlay %s.[/color]" % ("enabled" if next_enabled else "disabled")])

func _setup_selected_panel() -> void:
	var panel: Control = _get_selected_control()
	if panel == null:
		_show_results(["[color=red]Select a Control node before running Panel Builder.[/color]"])
		_refresh_selected_panel_info()
		return

	var script: Script = panel.get_script() as Script
	if script and not _is_supported_panel_script(script):
		_show_results([
			"[color=red]Panel Builder will not overwrite %s's existing script.[/color]" % panel.name,
			"Use a plain Control node, DualCursorNavigationPanel, or DualCursorGridNavigationPanel."
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

	var panel_type := _selected_panel_type()
	var selected_script := _panel_script_for_type(panel_type)
	if script == null or script.resource_path != selected_script.resource_path:
		panel.set_script(selected_script)

	var preset_id: int = _panel_preset.get_selected_id() if _panel_preset else 0
	panel.set("owner_player_id", _preset_owner_player_id(preset_id))
	panel.set("occupancy_policy", _preset_occupancy_policy(preset_id))
	panel.set("navigation_targets", target_paths)
	if panel.get_script() and (panel.get_script() as Script).resource_path == GRID_NAVIGATION_PANEL_SCRIPT_PATH:
		panel.set("columns", _selected_grid_columns())
		panel.set("wrap_columns", true)
		panel.set("wrap_rows", false)
		panel.set("skip_disabled_targets", true)
	DualCursorThemePresets.apply_to_navigation_panel(panel, _selected_theme_preset())

	DualCursorInputSetup.ensure_profile(_selected_controller_profile(), true)
	var rig_messages: Array[String] = _ensure_cursor_runtime(panel)
	_mark_scene_unsaved()
	_refresh_selected_panel_info()
	var result_lines: Array[String] = [
		"[color=green]OK: Configured %s as %s.[/color]" % [panel.name, _preset_name(preset_id)],
		"Panel type: %s" % _panel_type_name(panel),
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
	if script == null or not _is_supported_panel_script(script):
		lines.append("[color=red]Fix needed: %s is not a DualCursor navigation panel. Click Setup Selected Panel.[/color]" % panel.name)
		_show_results(lines)
		_refresh_selected_panel_info()
		return

	lines.append("[color=green]OK: %s uses %s.[/color]" % [panel.name, _panel_type_name(panel)])
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
	if script.resource_path == GRID_NAVIGATION_PANEL_SCRIPT_PATH:
		_validate_grid_panel(panel, lines)
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
		if script.resource_path == NAVIGATION_PANEL_SCRIPT_PATH:
			script_status = "DualCursorNavigationPanel"
		elif script.resource_path == GRID_NAVIGATION_PANEL_SCRIPT_PATH:
			script_status = "DualCursorGridNavigationPanel"
		else:
			script_status = "custom script"
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

func _is_supported_panel_script(script: Script) -> bool:
	return script.resource_path == NAVIGATION_PANEL_SCRIPT_PATH or script.resource_path == GRID_NAVIGATION_PANEL_SCRIPT_PATH

func _selected_panel_type() -> int:
	if _panel_type == null:
		return PANEL_TYPE_LIST
	return _panel_type.get_selected_id()

func _selected_grid_columns() -> int:
	if _grid_columns == null:
		return 4
	return max(1, int(_grid_columns.value))

func _panel_script_for_type(panel_type: int) -> Script:
	return GRID_NAVIGATION_PANEL_SCRIPT if panel_type == PANEL_TYPE_GRID else NAVIGATION_PANEL_SCRIPT

func _panel_type_name(panel: Control) -> String:
	var script: Script = panel.get_script() as Script
	if script and script.resource_path == GRID_NAVIGATION_PANEL_SCRIPT_PATH:
		return "Grid Panel"
	return "List Panel"

func _selected_controller_profile() -> String:
	if _controller_profile == null or _controller_profile.selected < 0:
		return DualCursorInputSetup.PROFILE_GENERIC_GAMEPAD
	var metadata = _controller_profile.get_item_metadata(_controller_profile.selected)
	return str(metadata)

func _selected_theme_preset() -> String:
	if _theme_preset == null or _theme_preset.selected < 0:
		return DualCursorThemePresets.DEFAULT_LIGHT
	var metadata = _theme_preset.get_item_metadata(_theme_preset.selected)
	return str(metadata)

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
	if _ensure_debug_overlay(rig, root):
		lines.append("Added disabled DualCursorDebugOverlay. Toggle it from the dock when debugging regions.")
	return lines

func _ensure_debug_overlay(rig: Control, scene_root: Node) -> bool:
	var overlay: Control = _find_first_by_script_path(scene_root, DEBUG_OVERLAY_SCRIPT_PATH) as Control
	if overlay:
		return false

	overlay = Control.new()
	overlay.name = "DualCursorDebugOverlay"
	overlay.set_script(DEBUG_OVERLAY_SCRIPT)
	overlay.z_index = 4096
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set("enabled", false)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.set_offsets_preset(Control.PRESET_FULL_RECT)
	rig.add_child(overlay)
	overlay.owner = scene_root
	return true

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
	DualCursorThemePresets.apply_to_cursor(cursor, player_id, _selected_theme_preset())
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
	navigation_panels.append_array(_find_by_script_path(root, GRID_NAVIGATION_PANEL_SCRIPT_PATH))
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
		_validate_navigation_panels(navigation_panels, cursors, lines)

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

func _validate_navigation_panels(navigation_panels: Array, cursors: Array, lines: Array[String]) -> void:
	for panel_index in navigation_panels.size():
		var panel = navigation_panels[panel_index]
		if not (panel is Control):
			continue
		var panel_control: Control = panel as Control
		var target_paths: Array = panel.get("navigation_targets")
		if target_paths.is_empty():
			lines.append("[color=red]Fix needed: %s has no navigation_targets.[/color]" % panel.name)
		else:
			for target_path in target_paths:
				if not (target_path is NodePath) or (target_path as NodePath).is_empty():
					lines.append("[color=red]Fix needed: %s has an empty navigation target path.[/color]" % panel.name)
					continue
				_validate_navigation_target(panel, target_path, lines)

		var script: Script = panel_control.get_script() as Script
		if script and script.resource_path == GRID_NAVIGATION_PANEL_SCRIPT_PATH:
			_validate_grid_panel(panel_control, lines)
		_validate_navigation_panel_reachability(panel_control, cursors, lines)

		for other_index in range(panel_index + 1, navigation_panels.size()):
			var other: Control = navigation_panels[other_index] as Control
			if other == null:
				continue
			if panel_control.get_global_rect().intersects(other.get_global_rect()) and int(panel_control.get("hit_priority")) == int(other.get("hit_priority")):
				lines.append("[color=yellow]Warning: Navigation panels %s and %s overlap with the same hit_priority. Increase hit_priority on the panel that should capture first.[/color]" % [panel_control.name, other.name])

func _validate_navigation_panel_reachability(panel: Control, cursors: Array, lines: Array[String]) -> void:
	if cursors.is_empty():
		return

	var owner_player_id := int(panel.get("owner_player_id"))
	var reachable_players: PackedInt32Array = PackedInt32Array()
	for cursor in cursors:
		if _cursor_can_reach_control(cursor, panel):
			reachable_players.append(int(cursor.get("player_id")))

	if reachable_players.is_empty():
		lines.append("[color=red]Fix needed: %s is outside every cursor movement region. Move it into a reachable region or add that region to a cursor's extra_region_node_paths.[/color]" % panel.name)
		return

	if owner_player_id >= 0:
		if not _packed_int_array_has(reachable_players, owner_player_id):
			lines.append("[color=red]Fix needed: %s belongs to Player %d but that player's cursor cannot reach it.[/color]" % [panel.name, owner_player_id + 1])
		return

	var occupancy_policy := int(panel.get("occupancy_policy"))
	if occupancy_policy == PANEL_OCCUPANCY_ALLOW_MULTIPLE and reachable_players.size() < cursors.size():
		lines.append("[color=yellow]Warning: Shared simultaneous panel %s is reachable by only %d cursor(s). Both players usually need access.[/color]" % [panel.name, reachable_players.size()])
	elif occupancy_policy == PANEL_OCCUPANCY_FIRST_PLAYER_LOCKS and reachable_players.size() < cursors.size():
		lines.append("[color=yellow]Warning: Shared exclusive panel %s is not reachable by every cursor. That may be intentional, but shared panels usually belong in shared space.[/color]" % panel.name)

func _validate_grid_panel(panel: Control, lines: Array[String]) -> void:
	var columns := int(panel.get("columns"))
	if columns < 1:
		lines.append("[color=red]Fix needed: %s grid columns must be at least 1.[/color]" % panel.name)
		return

	var target_paths: Array = panel.get("navigation_targets")
	if target_paths.is_empty():
		return

	if target_paths.size() < columns:
		lines.append("[color=yellow]Warning: %s has fewer targets than columns. Reduce columns or add more grid cells.[/color]" % panel.name)

	if bool(panel.get("skip_disabled_targets")):
		return

	for target_path in target_paths:
		var target: BaseButton = panel.get_node_or_null(target_path) as BaseButton
		if target and target.disabled:
			lines.append("[color=yellow]Warning: %s contains disabled target %s and skip_disabled_targets is off.[/color]" % [panel.name, target.name])

func _packed_int_array_has(values: PackedInt32Array, value: int) -> bool:
	for item in values:
		if item == value:
			return true
	return false

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
