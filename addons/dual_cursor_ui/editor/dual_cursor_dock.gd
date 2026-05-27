@tool
extends VBoxContainer

const DualCursorInputSetup := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_input_setup.gd")
const MANAGER_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_manager.gd"
const MANAGER_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_manager.gd")
const CURSOR_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor.gd"
const CURSOR_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor.gd")
const DEBUG_OVERLAY_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_debug_overlay.gd"
const DEBUG_OVERLAY_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_debug_overlay.gd")
const EVENT_MONITOR_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_event_monitor.gd"
const EVENT_MONITOR_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_event_monitor.gd")
const NAVIGATION_PANEL_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_navigation_panel.gd"
const NAVIGATION_PANEL_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_navigation_panel.gd")
const GRID_NAVIGATION_PANEL_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_grid_navigation_panel.gd"
const GRID_NAVIGATION_PANEL_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_grid_navigation_panel.gd")
const DIALOGUE_PANEL_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_dialogue_panel.gd"
const DIALOGUE_PANEL_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_dialogue_panel.gd")
const NARRATIVE_ROUTER_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_narrative_router.gd"
const NARRATIVE_ROUTER_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_narrative_router.gd")
const NARRATIVE_EXAMPLE_LOGGER_SCRIPT_PATH := "res://addons/dual_cursor_ui/scripts/dual_cursor_narrative_example_logger.gd"
const NARRATIVE_EXAMPLE_LOGGER_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_narrative_example_logger.gd")
const TOGGLE_ADAPTER_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_toggle_adapter.gd")
const SLIDER_ADAPTER_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_slider_adapter.gd")
const OPTION_ADAPTER_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_option_adapter.gd")
const SPIN_BOX_ADAPTER_SCRIPT := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_spin_box_adapter.gd")
const DualCursorThemePresets := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_theme_presets.gd")
const DEMO_SCENE_PATH := "res://addons/dual_cursor_ui/demos/two_player_menu_demo.tscn"
const ALL_EXAMPLES_DEMO_SCENE_PATH := "res://addons/dual_cursor_ui/demos/all_example_panels_demo.tscn"
const PANEL_OCCUPANCY_ALLOW_MULTIPLE := 0
const PANEL_OCCUPANCY_FIRST_PLAYER_LOCKS := 1
const PANEL_TYPE_LIST := 0
const PANEL_TYPE_GRID := 1
const METADATA_KEYS := [
	"action",
	"choice_id",
	"event_type",
	"event_id",
	"skill_id",
	"clock_id",
	"item_id",
	"shop_item_id",
	"inventory_action"
]
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
const CONTROL_ADAPTER_EXAMPLE := """extends Node

@export var ready_toggle: DualCursorToggleAdapter
@export var volume_slider: DualCursorSliderAdapter
@export var category_options: DualCursorOptionAdapter

func _ready() -> void:
	ready_toggle.toggled_by_player.connect(_on_ready_toggled)
	volume_slider.value_changed_by_player.connect(_on_volume_changed)
	category_options.option_selected_by_player.connect(_on_category_selected)

func _on_ready_toggled(player_id: int, pressed: bool, cursor: Node) -> void:
	print("P%d ready: %s" % [player_id + 1, pressed])

func _on_volume_changed(player_id: int, value: float, cursor: Node) -> void:
	print("P%d volume: %s" % [player_id + 1, value])

func _on_category_selected(player_id: int, index: int, cursor: Node) -> void:
	print("P%d category: %d" % [player_id + 1, index])
"""
const DIALOGUE_PANEL_EXAMPLE := """extends Node

@export var dialogue_panel: DualCursorDialoguePanel

func _ready() -> void:
	dialogue_panel.choice_selected.connect(_on_choice_selected)
	dialogue_panel.set_choices([
		{"id": "ask_ruins", "text": "Ask about the ruins."},
		{"id": "request_supplies", "text": "Request supplies."},
		{"id": "leave", "text": "Leave the conversation."}
	])

func _on_choice_selected(player_id: int, choice_id: String, choice_data: Dictionary, cursor: Node) -> void:
	print("P%d chose %s" % [player_id + 1, choice_id])
"""
const NARRATIVE_ROUTER_EXAMPLE := """extends Node

@export var panel: DualCursorNavigationPanel
@export var router: DualCursorNarrativeRouter

func _ready() -> void:
	panel.target_activated.connect(_on_target_activated)
	router.narrative_event.connect(_on_narrative_event)

func _on_target_activated(player_id: int, target: Control, cursor: Node) -> void:
	router.route_panel_target(player_id, target, cursor)

func _on_narrative_event(player_id: int, event_type: String, event_id: String, payload: Dictionary, cursor: Node) -> void:
	print("P%d %s: %s" % [player_id + 1, event_type, event_id])
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
var _metadata_status: RichTextLabel
var _metadata_key: OptionButton
var _metadata_value: LineEdit
var _wiring_status: Label
var _wiring_code: TextEdit

func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin

func _ready() -> void:
	name = "DualCursor UI"
	custom_minimum_size = Vector2(360, 0)
	_build_ui()
	_connect_editor_selection_changed()
	_refresh_selected_panel_info()
	_refresh_metadata_editor()
	_refresh_wiring_assistant()
	_run_validation()

func _connect_editor_selection_changed() -> void:
	if _plugin == null:
		return
	var selection: EditorSelection = _plugin.get_editor_interface().get_selection()
	var callable := Callable(self, "_on_editor_selection_changed")
	if not selection.is_connected("selection_changed", callable):
		selection.connect("selection_changed", callable)

func _on_editor_selection_changed() -> void:
	_refresh_selected_panel_info()
	_refresh_metadata_editor()
	_refresh_wiring_assistant()

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
	var examples_demo_button := _button("Open All Example Panels Demo")
	examples_demo_button.pressed.connect(_open_all_examples_demo)
	body.add_child(examples_demo_button)
	body.add_child(_paragraph("Opens a separate full-screen demo with every example panel organized in a responsive layout. Use it to test adapters, grids, dialogue, shared events, clocks, logging, and controller navigation in one place."))

	body.add_child(_section("Controller Profile"))
	body.add_child(_paragraph("DualCursor UI v0.7.0 supports the two-controller workflow. Apply a profile to create or repair the player select/cancel actions."))
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
	body.add_child(_paragraph("Select one of your own Control panels, choose who can enter it, then choose how focus moves inside it. List panels move target-to-target through a simple menu. Grid panels move by rows and columns for inventories, shops, skill trees, and tactical commands."))
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
	_panel_type.add_item("List Panel - menu/dialogue order", PANEL_TYPE_LIST)
	_panel_type.add_item("Grid Panel - inventory/shop rows", PANEL_TYPE_GRID)
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

	body.add_child(_section("Target Metadata"))
	body.add_child(_paragraph("Select a panel target or button, then add ids used by your game logic and narrative routing. Values are stored as strings."))
	_metadata_status = RichTextLabel.new()
	_metadata_status.bbcode_enabled = true
	_metadata_status.fit_content = true
	_metadata_status.selection_enabled = true
	_metadata_status.custom_minimum_size = Vector2(0, 90)
	body.add_child(_metadata_status)
	_metadata_key = OptionButton.new()
	_metadata_key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for key in METADATA_KEYS:
		_metadata_key.add_item(str(key))
	_metadata_key.item_selected.connect(func(_index: int) -> void: _refresh_metadata_editor())
	body.add_child(_metadata_key)
	_metadata_value = LineEdit.new()
	_metadata_value.placeholder_text = "Metadata value"
	_metadata_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_metadata_value)
	var refresh_metadata_button := _button("Refresh Metadata")
	refresh_metadata_button.pressed.connect(_refresh_metadata_editor)
	body.add_child(refresh_metadata_button)
	var apply_metadata_button := _button("Apply Metadata To Selected Node")
	apply_metadata_button.pressed.connect(_apply_metadata_to_selected_node)
	body.add_child(apply_metadata_button)
	var clear_metadata_button := _button("Clear Selected Metadata Key")
	clear_metadata_button.pressed.connect(_clear_selected_metadata_key)
	body.add_child(clear_metadata_button)

	body.add_child(_section("Panel Wiring Assistant"))
	body.add_child(_paragraph("Select a DualCursor panel, button, adapter, or router to generate copyable handler code for your game script. This does not edit your scripts."))
	_wiring_status = _paragraph("Selected node: none")
	body.add_child(_wiring_status)
	_wiring_code = TextEdit.new()
	_wiring_code.editable = false
	_wiring_code.selecting_enabled = true
	_wiring_code.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_wiring_code.custom_minimum_size = Vector2(0, 190)
	_wiring_code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_wiring_code)
	var refresh_wiring_button := _button("Refresh Wiring Snippet")
	refresh_wiring_button.pressed.connect(_refresh_wiring_assistant)
	body.add_child(refresh_wiring_button)
	var copy_wiring_button := _button("Copy Handler Code")
	copy_wiring_button.pressed.connect(_copy_wiring_code)
	body.add_child(copy_wiring_button)

	body.add_child(_section("Example Panels"))
	body.add_child(_paragraph("These create small editable panels in the current scene, add the needed targets, configure navigation, and add the lightweight two-player runtime if needed."))
	var settings_example_button := _button("Create Settings Adapter Example")
	settings_example_button.pressed.connect(_create_settings_adapter_example)
	body.add_child(settings_example_button)
	var shop_example_button := _button("Create Shop Grid Example")
	shop_example_button.pressed.connect(_create_shop_grid_example)
	body.add_child(shop_example_button)
	var character_example_button := _button("Create Character Setup Example")
	character_example_button.pressed.connect(_create_character_setup_example)
	body.add_child(character_example_button)
	var dialogue_example_button := _button("Create Dialogue Choice Example")
	dialogue_example_button.pressed.connect(_create_dialogue_choice_example)
	body.add_child(dialogue_example_button)
	var shared_event_example_button := _button("Create Shared Event Example")
	shared_event_example_button.pressed.connect(_create_shared_event_example)
	body.add_child(shared_event_example_button)
	var clock_example_button := _button("Create TTRPG Clock Example")
	clock_example_button.pressed.connect(_create_ttrpg_clock_example)
	body.add_child(clock_example_button)

	body.add_child(_section("Validate Scene"))
	var overlay_button := _button("Add/Toggle Debug Overlay")
	overlay_button.pressed.connect(_toggle_debug_overlay)
	body.add_child(overlay_button)
	var monitor_button := _button("Add/Toggle Runtime Event Monitor")
	monitor_button.pressed.connect(_toggle_event_monitor)
	body.add_child(monitor_button)
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
		"Dialogue Panel Helper",
		"Use DualCursorDialoguePanel when you want to populate player-specific dialogue choices from dictionaries.",
		DIALOGUE_PANEL_EXAMPLE
	))
	body.add_child(_guide_panel(
		"Narrative Router Helper",
		"Use DualCursorNarrativeRouter when you want a single normalized signal for choices, checks, clocks, inventory commands, and shared events.",
		NARRATIVE_ROUTER_EXAMPLE
	))
	body.add_child(_guide_panel(
		"Control Adapters",
		"Use player-aware adapters for normal Godot widgets. Add them to navigation_targets just like buttons; while selected, compatible stick directions change the widget and emit a signal with player_id.",
		CONTROL_ADAPTER_EXAMPLE
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

	var next_enabled: bool = true if created else not bool(overlay.get("enabled"))
	overlay.set("enabled", next_enabled)
	_mark_scene_unsaved()
	_show_results(["[color=green]Debug overlay %s.[/color]" % ("enabled" if next_enabled else "disabled")])

func _toggle_event_monitor() -> void:
	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=yellow]No edited scene is open.[/color]"])
		return

	var monitor: Control = _find_first_by_script_path(root, EVENT_MONITOR_SCRIPT_PATH) as Control
	var created: bool = false
	if monitor == null:
		monitor = Control.new()
		monitor.name = "DualCursorEventMonitor"
		monitor.set_script(EVENT_MONITOR_SCRIPT)
		monitor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		monitor.z_index = 4097
		monitor.set_anchors_preset(Control.PRESET_FULL_RECT)
		monitor.set_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(monitor)
		_set_owner_recursive(monitor, root)
		created = true

	var next_enabled: bool = true if created else not bool(monitor.get("enabled"))
	monitor.set("enabled", next_enabled)
	if monitor.has_method("refresh_bindings"):
		monitor.call("refresh_bindings")
	_mark_scene_unsaved()
	_show_results(["[color=green]Runtime Event Monitor %s.[/color]" % ("enabled" if next_enabled else "disabled")])

func _open_all_examples_demo() -> void:
	if _plugin == null:
		return
	_plugin.get_editor_interface().open_scene_from_path(ALL_EXAMPLES_DEMO_SCENE_PATH)
	_show_results(["[color=green]Opened All Example Panels Demo.[/color]"])

func _refresh_metadata_editor() -> void:
	if _metadata_status == null:
		return
	var node: Node = _get_selected_node()
	if node == null:
		_metadata_status.clear()
		_metadata_status.append_text("[color=yellow]Selected node: none[/color]")
		return

	_metadata_status.clear()
	_metadata_status.append_text("[b]Selected:[/b] %s\n" % node.name)
	var meta_keys: Array = node.get_meta_list()
	if meta_keys.is_empty():
		_metadata_status.append_text("No metadata on this node.")
	else:
		for key in meta_keys:
			_metadata_status.append_text("%s = %s\n" % [str(key), str(node.get_meta(key))])

	if _metadata_key and _metadata_value and _metadata_key.selected >= 0:
		var selected_key: String = _metadata_key.get_item_text(_metadata_key.selected)
		_metadata_value.text = str(node.get_meta(selected_key, ""))

func _apply_metadata_to_selected_node() -> void:
	var node: Node = _get_selected_node()
	if node == null:
		_show_results(["[color=red]Select a node before applying metadata.[/color]"])
		return
	if _metadata_key == null or _metadata_value == null or _metadata_key.selected < 0:
		_show_results(["[color=red]Choose a metadata key first.[/color]"])
		return

	var key: String = _metadata_key.get_item_text(_metadata_key.selected)
	node.set_meta(key, _metadata_value.text)
	_mark_scene_unsaved()
	_refresh_metadata_editor()
	_show_results(["[color=green]OK: Set %s = %s on %s.[/color]" % [key, _metadata_value.text, node.name]])

func _clear_selected_metadata_key() -> void:
	var node: Node = _get_selected_node()
	if node == null:
		_show_results(["[color=red]Select a node before clearing metadata.[/color]"])
		return
	if _metadata_key == null or _metadata_key.selected < 0:
		_show_results(["[color=red]Choose a metadata key first.[/color]"])
		return

	var key: String = _metadata_key.get_item_text(_metadata_key.selected)
	if node.has_meta(key):
		node.remove_meta(key)
		_mark_scene_unsaved()
	_refresh_metadata_editor()
	_show_results(["[color=green]OK: Cleared %s on %s.[/color]" % [key, node.name]])

func _refresh_wiring_assistant() -> void:
	if _wiring_status == null or _wiring_code == null:
		return
	var node: Node = _get_selected_node()
	if node == null:
		_wiring_status.text = "Selected node: none"
		_wiring_code.text = ""
		return

	_wiring_status.text = "Selected node: %s" % node.name
	_wiring_code.text = _wiring_snippet_for_node(node)

func _copy_wiring_code() -> void:
	if _wiring_code == null or _wiring_code.text.is_empty():
		_show_results(["[color=yellow]No wiring code to copy. Select a supported node and refresh.[/color]"])
		return
	DisplayServer.clipboard_set(_wiring_code.text)
	_show_results(["[color=green]Copied wiring snippet.[/color]"])

func _wiring_snippet_for_node(node: Node) -> String:
	var script: Script = node.get_script() as Script
	var script_path: String = script.resource_path if script else ""
	if script_path == DIALOGUE_PANEL_SCRIPT_PATH or node.has_signal("choice_selected"):
		return _dialogue_wiring_snippet(node.name)
	if script_path == NARRATIVE_ROUTER_SCRIPT_PATH or node.has_signal("narrative_event"):
		return _router_wiring_snippet(node.name)
	if script_path == NAVIGATION_PANEL_SCRIPT_PATH or script_path == GRID_NAVIGATION_PANEL_SCRIPT_PATH or node.has_signal("target_activated"):
		return _panel_wiring_snippet(node.name)
	if node.has_signal("pressed_by_player"):
		return _button_wiring_snippet(node.name)
	if node.has_signal("toggled_by_player"):
		return _toggle_wiring_snippet(node.name)
	if node.has_signal("value_changed_by_player"):
		return _value_adapter_wiring_snippet(node.name)
	if node.has_signal("option_selected_by_player"):
		return _option_wiring_snippet(node.name)
	if node.has_signal("tab_changed_by_player"):
		return _tab_wiring_snippet(node.name)
	return "# Select a DualCursor panel, button, adapter, dialogue panel, or narrative router.\n# Then click Refresh Wiring Snippet."

func _panel_wiring_snippet(node_name: String) -> String:
	return """extends Node

@export var panel: DualCursorNavigationPanel

func _ready() -> void:
	panel.target_activated.connect(_on_panel_target_activated)

func _on_panel_target_activated(player_id: int, target: Control, cursor: Node) -> void:
	var action_id := str(target.get_meta("action", ""))
	var choice_id := str(target.get_meta("choice_id", ""))
	var event_id := str(target.get_meta("event_id", ""))
	var skill_id := str(target.get_meta("skill_id", ""))
	var clock_id := str(target.get_meta("clock_id", ""))
	var shop_item_id := str(target.get_meta("shop_item_id", ""))
	var inventory_action := str(target.get_meta("inventory_action", ""))
	print("P%d activated %s" % [player_id + 1, target.name])
"""

func _dialogue_wiring_snippet(node_name: String) -> String:
	return """extends Node

@export var dialogue_panel: DualCursorDialoguePanel

func _ready() -> void:
	dialogue_panel.choice_selected.connect(_on_choice_selected)

func _on_choice_selected(player_id: int, choice_id: String, choice_data: Dictionary, cursor: Node) -> void:
	print("P%d chose %s" % [player_id + 1, choice_id])
"""

func _router_wiring_snippet(node_name: String) -> String:
	return """extends Node

@export var router: DualCursorNarrativeRouter

func _ready() -> void:
	router.narrative_event.connect(_on_narrative_event)

func _on_narrative_event(player_id: int, event_type: String, event_id: String, payload: Dictionary, cursor: Node) -> void:
	print("P%d %s -> %s" % [player_id + 1, event_type, event_id])
"""

func _button_wiring_snippet(node_name: String) -> String:
	return """extends Node

@export var button: DualCursorButton

func _ready() -> void:
	button.pressed_by_player.connect(_on_pressed_by_player)

func _on_pressed_by_player(player_id: int, cursor: Node) -> void:
	print("P%d pressed %s" % [player_id + 1, button.name])
"""

func _toggle_wiring_snippet(node_name: String) -> String:
	return """extends Node

@export var toggle: DualCursorToggleAdapter

func _ready() -> void:
	toggle.toggled_by_player.connect(_on_toggled_by_player)

func _on_toggled_by_player(player_id: int, pressed: bool, cursor: Node) -> void:
	print("P%d toggled: %s" % [player_id + 1, pressed])
"""

func _value_adapter_wiring_snippet(node_name: String) -> String:
	return """extends Node

@export var value_control: Node

func _ready() -> void:
	value_control.value_changed_by_player.connect(_on_value_changed_by_player)

func _on_value_changed_by_player(player_id: int, value: float, cursor: Node) -> void:
	print("P%d value: %s" % [player_id + 1, value])
"""

func _option_wiring_snippet(node_name: String) -> String:
	return """extends Node

@export var options: DualCursorOptionAdapter

func _ready() -> void:
	options.option_selected_by_player.connect(_on_option_selected_by_player)

func _on_option_selected_by_player(player_id: int, index: int, cursor: Node) -> void:
	print("P%d option index: %d" % [player_id + 1, index])
"""

func _tab_wiring_snippet(node_name: String) -> String:
	return """extends Node

@export var tabs: DualCursorTabAdapter

func _ready() -> void:
	tabs.tab_changed_by_player.connect(_on_tab_changed_by_player)

func _on_tab_changed_by_player(player_id: int, tab_index: int, cursor: Node) -> void:
	print("P%d tab: %d" % [player_id + 1, tab_index])
"""

func _create_settings_adapter_example() -> void:
	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=red]Open or create a scene before adding an example panel.[/color]"])
		return

	var panel_size: Vector2 = Vector2(460, 460)
	var panel: Control = _new_example_panel(
		root,
		"DualCursorSettingsExample",
		_next_example_panel_position(root, panel_size),
		panel_size,
		"Settings adapter example",
		"A shared list panel with adapted Godot widgets.",
		"CheckBox, slider, options, spin box. Shared List Panel + runtime.",
		"Settings, ready checks, filters, and numeric choices."
	)
	var targets: Array[Control] = []
	var ready: CheckBox = CheckBox.new()
	ready.name = "ReadyToggle"
	ready.text = "Ready"
	ready.set_script(TOGGLE_ADAPTER_SCRIPT)
	targets.append(ready)

	var volume: HSlider = HSlider.new()
	volume.name = "VolumeSlider"
	volume.min_value = 0.0
	volume.max_value = 100.0
	volume.step = 5.0
	volume.value = 50.0
	volume.set_script(SLIDER_ADAPTER_SCRIPT)
	targets.append(volume)

	var category: OptionButton = OptionButton.new()
	category.name = "CategoryOptions"
	category.add_item("Dialogue")
	category.add_item("Inventory")
	category.add_item("Skills")
	category.set_script(OPTION_ADAPTER_SCRIPT)
	targets.append(category)

	var quantity: SpinBox = SpinBox.new()
	quantity.name = "QuantitySpinBox"
	quantity.min_value = 1.0
	quantity.max_value = 9.0
	quantity.step = 1.0
	quantity.value = 1.0
	quantity.set_script(SPIN_BOX_ADAPTER_SCRIPT)
	targets.append(quantity)

	_finish_example_panel(root, panel, targets, NAVIGATION_PANEL_SCRIPT, 3, 1)
	_show_results([
		"[color=green]OK: Created Settings Adapter Example.[/color]",
		"Use List navigation. A/Cross toggles or advances selected widgets; stick left/right adjusts sliders, options, and spin boxes.",
		"Connect each adapter signal such as toggled_by_player or value_changed_by_player to your game logic."
	])

func _create_shop_grid_example() -> void:
	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=red]Open or create a scene before adding an example panel.[/color]"])
		return

	var panel_size: Vector2 = Vector2(500, 430)
	var panel: Control = _new_example_panel(
		root,
		"DualCursorShopGridExample",
		_next_example_panel_position(root, panel_size),
		panel_size,
		"Shop grid example",
		"A shared row/column panel for item-like actions.",
		"Six cells, 3-column Grid Panel, shop_item_id metadata + runtime.",
		"Inventories, shops, skill grids, maps, and command boards."
	)
	var targets: Array[Control] = []
	for item_name in ["Potion", "Elixir", "Map", "Key", "Repair", "Leave"]:
		var button: Button = Button.new()
		button.name = item_name.to_pascal_case()
		button.text = item_name
		button.set_meta("shop_item_id", item_name.to_snake_case())
		targets.append(button)

	_finish_example_panel(root, panel, targets, GRID_NAVIGATION_PANEL_SCRIPT, 3, 3)
	_show_results([
		"[color=green]OK: Created Shop Grid Example.[/color]",
		"Use Grid navigation when targets are arranged in rows and columns. Left/right changes columns; up/down changes rows.",
		"Connect target_activated(player_id, target, cursor), then read target metadata such as shop_item_id."
	])

func _create_character_setup_example() -> void:
	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=red]Open or create a scene before adding an example panel.[/color]"])
		return

	var panel_size: Vector2 = Vector2(460, 420)
	var panel: Control = _new_example_panel(
		root,
		"DualCursorCharacterSetupExample",
		_next_example_panel_position(root, panel_size),
		panel_size,
		"Character setup example",
		"A private Player 1 panel for setup choices.",
		"OptionButton, SpinBox, Confirm. Player 1 private List Panel.",
		"Class selection, stat allocation, loadouts, and ready flows."
	)
	var targets: Array[Control] = []
	var class_options: OptionButton = OptionButton.new()
	class_options.name = "ClassOptions"
	class_options.add_item("Warrior")
	class_options.add_item("Mage")
	class_options.add_item("Rogue")
	class_options.set_script(OPTION_ADAPTER_SCRIPT)
	targets.append(class_options)

	var stat_points: SpinBox = SpinBox.new()
	stat_points.name = "StatPoints"
	stat_points.min_value = 0.0
	stat_points.max_value = 10.0
	stat_points.step = 1.0
	stat_points.value = 3.0
	stat_points.set_script(SPIN_BOX_ADAPTER_SCRIPT)
	targets.append(stat_points)

	var confirm: Button = Button.new()
	confirm.name = "ConfirmCharacter"
	confirm.text = "Confirm"
	confirm.set_meta("action", "confirm_character")
	targets.append(confirm)

	_finish_example_panel(root, panel, targets, NAVIGATION_PANEL_SCRIPT, 0, 1)
	_show_results([
		"[color=green]OK: Created Character Setup Example.[/color]",
		"This is a Player 1 private List panel. Change owner_player_id to 1 for Player 2 or -1 for shared.",
		"Use adapter signals for class/stat changes and target_activated for the Confirm button."
	])

func _create_dialogue_choice_example() -> void:
	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=red]Open or create a scene before adding an example panel.[/color]"])
		return

	var panel_size: Vector2 = Vector2(460, 420)
	var panel: Control = _new_example_panel(
		root,
		"DualCursorDialogueChoiceExample",
		_next_example_panel_position(root, panel_size),
		panel_size,
		"Dialogue choice example",
		"A Player 1 dialogue helper populated from dictionaries.",
		"DualCursorDialoguePanel, three choices + choice_id metadata.",
		"Data-driven dialogue. Connect choice_selected."
	)
	panel.set_script(DIALOGUE_PANEL_SCRIPT)
	panel.add_to_group("dual_cursor_navigation_panel")
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set("owner_player_id", 0)
	panel.set("occupancy_policy", PANEL_OCCUPANCY_ALLOW_MULTIPLE)
	panel.set("hit_priority", 50)
	panel.set("selection_width", 8.0)
	panel.set("selection_padding", 2.0)
	panel.set("player_selection_colors", PackedColorArray([Color(0.0, 0.42, 0.78, 1.0), Color(0.86, 0.28, 0.12, 1.0)]))
	panel.set("choice_start_y", 218.0)
	panel.set("choice_row_height", 34.0)
	panel.set("choice_row_gap", 8.0)
	panel.call("set_choices", [
		{"id": "ask_ruins", "text": "Ask about the ruins.", "event_type": "choice"},
		{"id": "request_supplies", "text": "Request supplies.", "event_type": "choice"},
		{"id": "leave_conversation", "text": "Leave the conversation.", "event_type": "choice"}
	])
	_style_dialogue_panel_targets(panel)
	var logger: Node = _ensure_narrative_example_logger(root)
	if logger and logger.has_method("watch_panel"):
		logger.call("watch_panel", panel)
	DualCursorThemePresets.apply_to_navigation_panel(panel, _selected_theme_preset())
	DualCursorInputSetup.ensure_profile(_selected_controller_profile(), true)
	_ensure_cursor_runtime(panel)
	_mark_scene_unsaved()
	_refresh_selected_panel_info()
	_run_validation()
	_show_results([
		"[color=green]OK: Created Dialogue Choice Example.[/color]",
		"Runtime behavior: selecting a choice appends a player-specific dialogue entry to DualCursorNarrativeExampleLog.",
		"Connect choice_selected(player_id, choice_id, choice_data, cursor) to your dialogue or branch system.",
		"Change owner_player_id to 1 for Player 2 dialogue or -1 for shared dialogue."
	])

func _create_shared_event_example() -> void:
	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=red]Open or create a scene before adding an example panel.[/color]"])
		return

	var panel_size: Vector2 = Vector2(460, 420)
	var panel: Control = _new_example_panel(
		root,
		"DualCursorSharedEventExample",
		_next_example_panel_position(root, panel_size),
		panel_size,
		"Shared event example",
		"A shared exclusive panel that routes event metadata.",
		"Shared-exclusive List Panel, event_id metadata + router.",
		"One-player-at-a-time events, shared prompts, inspect, take, and leave."
	)
	var targets: Array[Control] = []
	for item in [
		{"text": "Open sealed gate", "event_id": "open_sealed_gate"},
		{"text": "Read the inscription", "event_id": "read_inscription"},
		{"text": "Leave it alone", "event_id": "leave_event"}
	]:
		var button: Button = Button.new()
		button.name = str(item["event_id"]).to_pascal_case()
		button.text = str(item["text"])
		button.set_meta("event_type", "shared_event")
		button.set_meta("event_id", str(item["event_id"]))
		targets.append(button)

	_finish_example_panel(root, panel, targets, NAVIGATION_PANEL_SCRIPT, 2, 1)
	var logger: Node = _ensure_narrative_example_logger(root)
	if logger and logger.has_method("watch_panel"):
		logger.call("watch_panel", panel)
	_show_results([
		"[color=green]OK: Created Shared Event Example.[/color]",
		"Runtime behavior: selecting a target routes event_type=shared_event and event_id into DualCursorNarrativeExampleLog.",
		"This uses Shared Exclusive access, so one player controls the event panel at a time.",
		"Route target_activated through DualCursorNarrativeRouter or read event_id directly from target metadata."
	])

func _create_ttrpg_clock_example() -> void:
	var root := _get_scene_root()
	if root == null:
		_show_results(["[color=red]Open or create a scene before adding an example panel.[/color]"])
		return

	var panel_size: Vector2 = Vector2(460, 460)
	var panel: Control = _new_example_panel(
		root,
		"DualCursorClockExample",
		_next_example_panel_position(root, panel_size),
		panel_size,
		"TTRPG clock example",
		"Skill/check buttons carry clock metadata.",
		"Shared List Panel, skill_id, clock_id, clock label + log.",
		"Clocks, skill checks, danger timers, dice prompts."
	)
	var clock_label: Label = Label.new()
	clock_label.name = "ClockLabel"
	clock_label.text = "Clock: 0/6"
	clock_label.custom_minimum_size = Vector2(0, 28)
	clock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clock_label.add_theme_font_size_override("font_size", 14)
	clock_label.add_theme_color_override("font_color", Color(0.08, 0.12, 0.18, 1.0))
	var clock_targets_container: GridContainer = panel.find_child("TargetsContainer", true, false) as GridContainer
	if clock_targets_container:
		clock_targets_container.add_child(clock_label)
	else:
		panel.add_child(clock_label)
	clock_label.owner = root

	var targets: Array[Control] = []
	for item in [
		{"text": "Investigate", "skill_id": "investigate"},
		{"text": "Force Entry", "skill_id": "force_entry"},
		{"text": "Sneak Around", "skill_id": "sneak_around"}
	]:
		var button: Button = Button.new()
		button.name = str(item["skill_id"]).to_pascal_case()
		button.text = str(item["text"])
		button.set_meta("event_type", "skill_check")
		button.set_meta("skill_id", str(item["skill_id"]))
		button.set_meta("clock_id", "sealed_gate_clock")
		targets.append(button)

	_finish_example_panel(root, panel, targets, NAVIGATION_PANEL_SCRIPT, 3, 1)
	var logger: Node = _ensure_narrative_example_logger(root)
	if logger and logger.has_method("watch_panel"):
		logger.call("watch_panel", panel)
		logger.set("clock_label_path", logger.get_path_to(clock_label))
	_show_results([
		"[color=green]OK: Created TTRPG Clock Example.[/color]",
		"Runtime behavior: selecting a skill/check target routes skill_id and clock_id, then advances this example's ClockLabel.",
		"The addon routes skill_id and clock_id. Your game decides dice results and when to update ClockLabel.",
		"Connect target_activated or route through DualCursorNarrativeRouter."
	])

func _next_example_panel_position(root: Node, panel_size: Vector2) -> Vector2:
	var viewport_size: Vector2 = root.get_viewport().get_visible_rect().size
	var margin: float = 56.0
	var gap: float = 32.0
	var slot_w: float = max(panel_size.x, 520.0)
	var slot_h: float = max(panel_size.y, 430.0)
	var available_w: float = max(slot_w, viewport_size.x - margin * 2.0)
	var columns: int = max(1, int((available_w + gap) / (slot_w + gap)))
	columns = min(columns, 3)
	var index: int = 0
	for child in root.get_children():
		if child is Control and (child.has_meta("dual_cursor_example_panel") or _is_example_panel_name(str(child.name))):
			index += 1
	var column: int = index % columns
	var row: int = int(index / columns)
	return Vector2(margin + float(column) * (slot_w + gap), 80.0 + float(row) * (slot_h + gap))

func _is_example_panel_name(node_name: String) -> bool:
	return (
		node_name.begins_with("DualCursorSettingsExample")
		or node_name.begins_with("DualCursorShopGridExample")
		or node_name.begins_with("DualCursorCharacterSetupExample")
		or node_name.begins_with("DualCursorDialogueChoiceExample")
		or node_name.begins_with("DualCursorSharedEventExample")
		or node_name.begins_with("DualCursorClockExample")
	)

func _new_example_panel(root: Node, base_name: String, position_value: Vector2, size_value: Vector2, title: String, description: String, generated_summary: String, use_summary: String) -> Control:
	var panel: Control = Control.new()
	panel.name = _unique_child_name(root, base_name)
	panel.position = position_value
	panel.size = size_value
	panel.custom_minimum_size = size_value
	panel.set_meta("dual_cursor_example_panel", true)
	root.add_child(panel)
	_set_owner_recursive(panel, root)

	var backing: Panel = Panel.new()
	backing.name = "Background"
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.set_offsets_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DualCursorThemePresets.apply_to_surface(backing, _selected_theme_preset())
	panel.add_child(backing)
	backing.owner = root

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "CardMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.set_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)
	margin.owner = root

	var content: VBoxContainer = VBoxContainer.new()
	content.name = "CardContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	content.owner = root

	var title_label: Label = Label.new()
	title_label.name = "Title"
	title_label.text = title
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.add_theme_color_override("font_color", Color(0.08, 0.12, 0.18, 1.0))
	content.add_child(title_label)
	title_label.owner = root

	var description_label: Label = Label.new()
	description_label.name = "Description"
	description_label.text = description
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 13)
	description_label.add_theme_color_override("font_color", Color(0.31, 0.38, 0.48, 1.0))
	content.add_child(description_label)
	description_label.owner = root

	var summary_grid: GridContainer = GridContainer.new()
	summary_grid.name = "SummaryGrid"
	summary_grid.columns = 2
	summary_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_grid.add_theme_constant_override("h_separation", 10)
	summary_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(summary_grid)
	summary_grid.owner = root
	_add_example_info_block(summary_grid, root, "Generates", generated_summary)
	_add_example_info_block(summary_grid, root, "Use for", use_summary)

	var targets_container: GridContainer = GridContainer.new()
	targets_container.name = "TargetsContainer"
	targets_container.columns = 1
	targets_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	targets_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	targets_container.add_theme_constant_override("h_separation", 10)
	targets_container.add_theme_constant_override("v_separation", 10)
	content.add_child(targets_container)
	targets_container.owner = root

	var note_label: Label = Label.new()
	note_label.name = "UseThis"
	note_label.text = "Run scene: events print in ExampleLog."
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.add_theme_font_size_override("font_size", 12)
	note_label.add_theme_color_override("font_color", Color(0.31, 0.38, 0.48, 1.0))
	content.add_child(note_label)
	note_label.owner = root
	return panel

func _add_example_info_block(parent: Control, root: Node, heading_text: String, body_text: String) -> void:
	var block: PanelContainer = PanelContainer.new()
	block.name = heading_text.replace(" ", "") + "Info"
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_theme_stylebox_override("panel", _dock_style_box(Color(0.965, 0.975, 0.99, 1.0), Color(0.80, 0.86, 0.94, 1.0), 1, 8))
	parent.add_child(block)
	block.owner = root

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	block.add_child(margin)
	margin.owner = root

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	box.owner = root

	var heading: Label = Label.new()
	heading.text = heading_text
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", Color(0.08, 0.12, 0.18, 1.0))
	box.add_child(heading)
	heading.owner = root

	var body: Label = Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 12)
	body.add_theme_color_override("font_color", Color(0.31, 0.38, 0.48, 1.0))
	box.add_child(body)
	body.owner = root

func _finish_example_panel(root: Node, panel: Control, targets: Array[Control], panel_script: Script, preset_id: int, columns: int) -> void:
	panel.set_script(panel_script)
	panel.add_to_group("dual_cursor_navigation_panel")
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set("owner_player_id", _preset_owner_player_id(preset_id))
	panel.set("occupancy_policy", _preset_occupancy_policy(preset_id))
	panel.set("hit_priority", 50)
	panel.set("selection_width", 8.0)
	panel.set("selection_padding", 2.0)
	panel.set("player_selection_colors", PackedColorArray([Color(0.0, 0.42, 0.78, 1.0), Color(0.86, 0.28, 0.12, 1.0)]))

	var target_paths: Array[NodePath] = []
	var targets_container: GridContainer = panel.find_child("TargetsContainer", true, false) as GridContainer
	if targets_container == null:
		targets_container = GridContainer.new()
		targets_container.name = "TargetsContainer"
		targets_container.columns = 1
		targets_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		targets_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.add_child(targets_container)
		targets_container.owner = root
	if panel_script.resource_path == GRID_NAVIGATION_PANEL_SCRIPT_PATH:
		targets_container.columns = max(1, columns)
	else:
		targets_container.columns = 1
	for index in targets.size():
		var target: Control = targets[index]
		target.custom_minimum_size = Vector2(0, 44)
		target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if panel_script.resource_path == GRID_NAVIGATION_PANEL_SCRIPT_PATH:
			target.size_flags_vertical = Control.SIZE_EXPAND_FILL
		else:
			target.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		targets_container.add_child(target)
		target.owner = root
		if target is BaseButton:
			DualCursorThemePresets.apply_to_button(target as BaseButton, _selected_theme_preset())
		target_paths.append(panel.get_path_to(target))

	panel.set("navigation_targets", target_paths)
	if panel_script.resource_path == GRID_NAVIGATION_PANEL_SCRIPT_PATH:
		panel.set("columns", columns)
		panel.set("wrap_columns", true)
		panel.set("wrap_rows", false)
		panel.set("skip_disabled_targets", true)

	DualCursorThemePresets.apply_to_navigation_panel(panel, _selected_theme_preset())
	DualCursorInputSetup.ensure_profile(_selected_controller_profile(), true)
	_ensure_cursor_runtime(panel)
	_mark_scene_unsaved()
	_refresh_selected_panel_info()
	_run_validation()

func _layout_example_grid_targets(targets: Array[Control], panel_size: Vector2, columns: int) -> void:
	for index in targets.size():
		var target: Control = targets[index]
		target.custom_minimum_size = Vector2(0, 44)
		target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		target.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _unique_child_name(parent: Node, base_name: String) -> String:
	var candidate: String = base_name
	var index: int = 2
	while parent.has_node(candidate):
		candidate = "%s%d" % [base_name, index]
		index += 1
	return candidate

func _ensure_narrative_router(root: Node) -> Node:
	var existing: Node = _find_first_by_script_path(root, "res://addons/dual_cursor_ui/scripts/dual_cursor_narrative_router.gd")
	if existing:
		return existing
	var router: Node = Node.new()
	router.name = "DualCursorNarrativeRouter"
	router.set_script(NARRATIVE_ROUTER_SCRIPT)
	root.add_child(router)
	router.owner = root
	return router

func _ensure_narrative_example_logger(root: Node) -> Node:
	var logger: Node = _find_first_by_script_path(root, NARRATIVE_EXAMPLE_LOGGER_SCRIPT_PATH)
	var router: Node = _ensure_narrative_router(root)
	if logger == null:
		logger = Node.new()
		logger.name = "DualCursorNarrativeExampleLogger"
		logger.set_script(NARRATIVE_EXAMPLE_LOGGER_SCRIPT)
		root.add_child(logger)
		logger.owner = root
	if router:
		logger.set("router_path", logger.get_path_to(router))

	var log_label: RichTextLabel = root.get_node_or_null("DualCursorNarrativeExampleLog") as RichTextLabel
	if log_label == null:
		log_label = RichTextLabel.new()
		log_label.name = "DualCursorNarrativeExampleLog"
		log_label.position = Vector2(80, 740)
		log_label.size = Vector2(920, 150)
		log_label.bbcode_enabled = true
		log_label.scroll_following = true
		root.add_child(log_label)
		log_label.owner = root
	if log_label:
		logger.set("log_label_path", logger.get_path_to(log_label))
	return logger

func _style_dialogue_panel_targets(panel: Control) -> void:
	var target_paths: Array = panel.get("navigation_targets")
	for target_path in target_paths:
		var target: Button = panel.get_node_or_null(target_path) as Button
		if target:
			DualCursorThemePresets.apply_to_button(target, _selected_theme_preset())

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

	var panel_type: int = _selected_panel_type()
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
		_refresh_metadata_editor()
		_refresh_wiring_assistant()
		return

	var script: Script = panel.get_script() as Script
	var script_status: String = "plain Control"
	if script:
		if script.resource_path == NAVIGATION_PANEL_SCRIPT_PATH:
			script_status = "DualCursorNavigationPanel"
		elif script.resource_path == GRID_NAVIGATION_PANEL_SCRIPT_PATH:
			script_status = "DualCursorGridNavigationPanel"
		elif script.resource_path == DIALOGUE_PANEL_SCRIPT_PATH:
			script_status = "DualCursorDialoguePanel"
		else:
			script_status = "custom script"
	_selected_panel_status.text = "Selected panel: %s (%s)" % [panel.name, script_status]
	_selected_target_status.text = "Detected targets: %d" % _detect_navigation_target_paths(panel).size()
	_refresh_metadata_editor()
	_refresh_wiring_assistant()

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

func _get_selected_node() -> Node:
	if _plugin == null:
		return null
	var selection := _plugin.get_editor_interface().get_selection()
	if selection == null:
		return null
	var nodes: Array = selection.get_selected_nodes()
	if nodes.is_empty():
		return null
	return nodes[0] as Node

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
		return control is BaseButton or _is_adapter_control(control)
	if control is Label or control is ColorRect or control is TextureRect:
		return false
	return control.size != Vector2.ZERO

func _is_adapter_control(control: Control) -> bool:
	return (
		control.has_method("dual_cursor_activate")
		or control.has_method("dual_cursor_navigate")
		or control.has_method("adjust_by_player")
		or control.has_method("select_next_by_player")
		or control.has_method("change_tab_by_player")
	)

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
	return script.resource_path == NAVIGATION_PANEL_SCRIPT_PATH or script.resource_path == GRID_NAVIGATION_PANEL_SCRIPT_PATH or script.resource_path == DIALOGUE_PANEL_SCRIPT_PATH

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
	if script and script.resource_path == DIALOGUE_PANEL_SCRIPT_PATH:
		return "Dialogue Panel"
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
	navigation_panels.append_array(_find_by_script_path(root, DIALOGUE_PANEL_SCRIPT_PATH))
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

	var panel_script: Script = panel.get_script() as Script
	if panel_script and panel_script.resource_path == DIALOGUE_PANEL_SCRIPT_PATH and not control.has_meta("choice_id"):
		lines.append("[color=yellow]Warning: %s dialogue target %s has no choice_id metadata.[/color]" % [panel.name, control.name])
	elif _looks_like_narrative_target(control) and not _has_routable_metadata(control):
		lines.append("[color=yellow]Warning: %s target %s has event_type but no routable metadata id.[/color]" % [panel.name, control.name])

func _looks_like_narrative_target(control: Control) -> bool:
	return control.has_meta("event_type")

func _has_routable_metadata(control: Control) -> bool:
	for key in ["choice_id", "event_id", "skill_id", "clock_id", "item_id", "shop_item_id", "inventory_action", "action"]:
		if control.has_meta(key) and not str(control.get_meta(key)).is_empty():
			return true
	return false

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

func _dock_style_box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	return style

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
