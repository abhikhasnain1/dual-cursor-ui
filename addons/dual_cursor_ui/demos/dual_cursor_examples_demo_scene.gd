@tool
extends Panel

const ManagerScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_manager.gd")
const CursorScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor.gd")
const NavigationPanelScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_navigation_panel.gd")
const GridNavigationPanelScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_grid_navigation_panel.gd")
const DialoguePanelScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_dialogue_panel.gd")
const ToggleAdapterScript := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_toggle_adapter.gd")
const SliderAdapterScript := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_slider_adapter.gd")
const OptionAdapterScript := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_option_adapter.gd")
const SpinBoxAdapterScript := preload("res://addons/dual_cursor_ui/scripts/adapters/dual_cursor_spin_box_adapter.gd")
const DualCursorInputSetup := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_input_setup.gd")
const PANEL_OCCUPANCY_ALLOW_MULTIPLE := 0
const PANEL_OCCUPANCY_FIRST_PLAYER_LOCKS := 1

const COLOR_APP_BG: Color = Color(0.94, 0.965, 0.985, 1.0)
const COLOR_SURFACE: Color = Color(1.0, 1.0, 1.0, 0.98)
const COLOR_TEXT: Color = Color(0.08, 0.12, 0.18, 1.0)
const COLOR_MUTED: Color = Color(0.34, 0.40, 0.50, 1.0)
const COLOR_BORDER: Color = Color(0.76, 0.83, 0.92, 1.0)
const COLOR_P1: Color = Color(0.0, 0.42, 0.78, 1.0)
const COLOR_P2: Color = Color(0.86, 0.28, 0.12, 1.0)

var _manager: Node
var _travel_region: ColorRect
var _examples_grid: GridContainer
var _event_log: RichTextLabel
var _event_index: int = 0

func _ready() -> void:
	DualCursorInputSetup.ensure_default_actions(false)
	_configure_root()
	if has_node("ExamplesRoot"):
		_wire_existing_scene()
		_apply_responsive_columns()
		return
	_build_scene()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_configure_root()
		_apply_responsive_columns()

func _configure_root() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	add_theme_stylebox_override("panel", _style_box(COLOR_APP_BG, COLOR_APP_BG, 0, 0))

func _build_scene() -> void:
	var root: Control = Control.new()
	root.name = "ExamplesRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.set_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_travel_region = ColorRect.new()
	_travel_region.name = "CursorTravelRegion"
	_travel_region.color = COLOR_APP_BG
	_travel_region.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_travel_region.set_anchors_preset(Control.PRESET_FULL_RECT)
	_travel_region.set_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_travel_region)

	_manager = Node.new()
	_manager.name = "DualCursorManager"
	_manager.set_script(ManagerScript)
	root.add_child(_manager)
	_connect_manager_signals()

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "ScreenMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.set_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)

	var screen: VBoxContainer = VBoxContainer.new()
	screen.name = "ScreenLayout"
	screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_theme_constant_override("separation", 8)
	margin.add_child(screen)

	var title: Label = _label("DualCursor UI Example Panels Demo", 20, COLOR_TEXT)
	screen.add_child(title)

	var subtitle: Label = _label("Move into a card to switch to controller navigation. Left/right changes adapted widgets; B/Circle exits.", 12, COLOR_MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen.add_child(subtitle)

	_examples_grid = GridContainer.new()
	_examples_grid.name = "ExamplesGrid"
	_examples_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_examples_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_examples_grid.add_theme_constant_override("h_separation", 12)
	_examples_grid.add_theme_constant_override("v_separation", 12)
	screen.add_child(_examples_grid)

	_add_settings_panel()
	_add_shop_grid_panel()
	_add_character_panel()
	_add_dialogue_panel()
	_add_shared_event_panel()
	_add_clock_panel()

	_event_log = RichTextLabel.new()
	_event_log.name = "ExampleEventLog"
	_event_log.bbcode_enabled = true
	_event_log.scroll_following = true
	_event_log.custom_minimum_size = Vector2(0, 78)
	_event_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_event_log.add_theme_stylebox_override("normal", _style_box(Color(1, 1, 1, 0.96), COLOR_BORDER, 1, 10))
	_event_log.add_theme_color_override("default_color", COLOR_TEXT)
	screen.add_child(_event_log)

	_create_cursor(root, 0, Vector2(80, 80), "interact_p1", "cancel_p1", COLOR_P1)
	_create_cursor(root, 1, Vector2(150, 80), "interact_p2", "cancel_p2", COLOR_P2)
	_apply_responsive_columns()
	_log("Demo ready. Enter any example panel with either cursor.")

func _wire_existing_scene() -> void:
	_manager = get_node_or_null("ExamplesRoot/DualCursorManager")
	_travel_region = get_node_or_null("ExamplesRoot/CursorTravelRegion") as ColorRect
	_examples_grid = get_node_or_null("ExamplesRoot/ScreenMargin/ScreenLayout/ExamplesGrid") as GridContainer
	_event_log = get_node_or_null("ExamplesRoot/ScreenMargin/ScreenLayout/ExampleEventLog") as RichTextLabel
	if _manager:
		_connect_manager_signals()

func _connect_manager_signals() -> void:
	_connect_manager_signal("navigation_entered", "_on_navigation_entered")
	_connect_manager_signal("navigation_exited", "_on_navigation_exited")
	_connect_manager_signal("navigation_denied", "_on_navigation_denied")
	_connect_manager_signal("navigation_target_activated", "_on_navigation_target_activated")

func _connect_manager_signal(signal_name: String, method_name: String) -> void:
	if _manager == null:
		return
	var callable := Callable(self, method_name)
	if not _manager.is_connected(signal_name, callable):
		_manager.connect(signal_name, callable)

func _apply_responsive_columns() -> void:
	if _examples_grid == null:
		return
	var width: float = get_viewport_rect().size.x
	if width >= 1100.0:
		_examples_grid.columns = 3
	elif width >= 760.0:
		_examples_grid.columns = 2
	else:
		_examples_grid.columns = 1

func _add_settings_panel() -> void:
	var panel: Control = _example_card(
		"SettingsAdaptersPanel",
		"Settings adapter panel",
		"Native widgets inside a shared list panel.",
		"Generates CheckBox, HSlider, OptionButton, SpinBox, player-aware adapter signals.",
		"Use for settings, ready checks, filters, numeric choices."
	)
	var ready: CheckBox = CheckBox.new()
	ready.name = "ReadyToggle"
	ready.text = "Ready"
	ready.set_script(ToggleAdapterScript)
	ready.connect("toggled_by_player", Callable(self, "_on_toggle_changed"))
	var volume: HSlider = HSlider.new()
	volume.name = "VolumeSlider"
	volume.min_value = 0.0
	volume.max_value = 100.0
	volume.step = 5.0
	volume.value = 50.0
	volume.set_script(SliderAdapterScript)
	volume.connect("value_changed_by_player", Callable(self, "_on_value_changed").bind("volume"))
	var category: OptionButton = OptionButton.new()
	category.name = "CategoryOptions"
	category.add_item("Dialogue")
	category.add_item("Inventory")
	category.add_item("Skills")
	category.set_script(OptionAdapterScript)
	category.connect("option_selected_by_player", Callable(self, "_on_option_selected"))
	var quantity: SpinBox = SpinBox.new()
	quantity.name = "QuantitySpinBox"
	quantity.min_value = 1.0
	quantity.max_value = 9.0
	quantity.step = 1.0
	quantity.value = 3.0
	quantity.set_script(SpinBoxAdapterScript)
	quantity.connect("value_changed_by_player", Callable(self, "_on_value_changed").bind("quantity"))
	var targets: Array[Control] = []
	targets.append(ready)
	targets.append(volume)
	targets.append(category)
	targets.append(quantity)
	_finish_panel(panel, targets, NavigationPanelScript, -1, PANEL_OCCUPANCY_ALLOW_MULTIPLE, 1)

func _add_shop_grid_panel() -> void:
	var panel: Control = _example_card("ShopGridPanel", "Shop grid panel", "A shared row/column panel for item actions.", "Generates a 3-column grid and shop_item_id metadata.", "Use for inventories, shops, skill grids, maps, and command boards.")
	var targets: Array[Control] = []
	for item_name in ["Potion", "Elixir", "Map", "Key", "Repair", "Leave"]:
		var button: Button = _target_button(item_name)
		button.set_meta("shop_item_id", item_name.to_snake_case())
		targets.append(button)
	_finish_panel(panel, targets, GridNavigationPanelScript, -1, PANEL_OCCUPANCY_ALLOW_MULTIPLE, 3)

func _add_character_panel() -> void:
	var panel: Control = _example_card("CharacterSetupPanel", "Character setup panel", "A Player 1 private form with adapted controls.", "Generates OptionButton, SpinBox, Confirm button.", "Use for character creation, loadouts, and player-owned forms.")
	var class_options: OptionButton = OptionButton.new()
	class_options.name = "ClassOptions"
	class_options.add_item("Warrior")
	class_options.add_item("Mage")
	class_options.add_item("Rogue")
	class_options.set_script(OptionAdapterScript)
	var stat_points: SpinBox = SpinBox.new()
	stat_points.name = "StatPoints"
	stat_points.min_value = 0
	stat_points.max_value = 10
	stat_points.step = 1
	stat_points.value = 3
	stat_points.set_script(SpinBoxAdapterScript)
	var confirm: Button = _target_button("Confirm")
	confirm.name = "ConfirmCharacter"
	confirm.set_meta("action", "confirm_character")
	var targets: Array[Control] = []
	targets.append(class_options)
	targets.append(stat_points)
	targets.append(confirm)
	_finish_panel(panel, targets, NavigationPanelScript, 0, PANEL_OCCUPANCY_ALLOW_MULTIPLE, 1)

func _add_dialogue_panel() -> void:
	var panel: Control = _example_card("DialogueChoicePanel", "Dialogue choice panel", "A Player 1 dialogue helper populated from dictionaries.", "Generates choice buttons with choice_id metadata.", "Use for branching dialogue and player-specific choices.")
	panel.set_script(DialoguePanelScript)
	_configure_panel(panel, 0, PANEL_OCCUPANCY_ALLOW_MULTIPLE)
	panel.call("set_choices", [
		{"id": "ask_ruins", "text": "Ask about the ruins.", "event_type": "choice"},
		{"id": "request_supplies", "text": "Request supplies.", "event_type": "choice"},
		{"id": "leave_conversation", "text": "Leave the conversation.", "event_type": "choice"}
	])
	for target in panel.get("navigation_targets"):
		var button: Button = panel.get_node_or_null(target) as Button
		if button:
			_style_button(button)
	panel.connect("choice_selected", Callable(self, "_on_choice_selected"))

func _add_shared_event_panel() -> void:
	var panel: Control = _example_card("SharedEventPanel", "Shared event panel", "A shared exclusive panel that routes event metadata.", "Generates event_type and event_id metadata.", "Use for shared prompts, inspect actions, and scene triggers.")
	var targets: Array[Control] = []
	for item in [{"text": "Open sealed gate", "event_id": "open_gate"}, {"text": "Read inscription", "event_id": "read_inscription"}, {"text": "Leave it alone", "event_id": "leave_event"}]:
		var button: Button = _target_button(str(item["text"]))
		button.name = str(item["event_id"]).to_pascal_case()
		button.set_meta("event_type", "shared_event")
		button.set_meta("event_id", str(item["event_id"]))
		targets.append(button)
	_finish_panel(panel, targets, NavigationPanelScript, -1, PANEL_OCCUPANCY_FIRST_PLAYER_LOCKS, 1)

func _add_clock_panel() -> void:
	var panel: Control = _example_card("ClockPanel", "TTRPG clock panel", "Skill/check buttons carry clock metadata.", "Generates skill_id, clock_id, and an example clock label.", "Use for clocks, skill checks, danger timers, and dice prompts.")
	var clock_label: Label = _label("Clock: 0/6", 14, COLOR_TEXT)
	clock_label.name = "ClockLabel"
	clock_label.custom_minimum_size = Vector2(0, 28)
	var targets_container: GridContainer = panel.find_child("TargetsContainer", true, false) as GridContainer
	if targets_container:
		targets_container.add_child(clock_label)
	var targets: Array[Control] = []
	for item in [{"text": "Investigate", "skill_id": "investigate"}, {"text": "Force Entry", "skill_id": "force_entry"}, {"text": "Sneak Around", "skill_id": "sneak_around"}]:
		var button: Button = _target_button(str(item["text"]))
		button.name = str(item["skill_id"]).to_pascal_case()
		button.set_meta("event_type", "skill_check")
		button.set_meta("skill_id", str(item["skill_id"]))
		button.set_meta("clock_id", "sealed_gate_clock")
		targets.append(button)
	_finish_panel(panel, targets, NavigationPanelScript, -1, PANEL_OCCUPANCY_ALLOW_MULTIPLE, 1)

func _example_card(node_name: String, title: String, description: String, generated_text: String, use_text: String) -> Control:
	var panel: Control = Control.new()
	panel.name = node_name
	panel.custom_minimum_size = Vector2(320, 220)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_examples_grid.add_child(panel)

	var backing: Panel = Panel.new()
	backing.name = "Background"
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.set_offsets_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.add_theme_stylebox_override("panel", _style_box(COLOR_SURFACE, COLOR_BORDER, 1, 12))
	panel.add_child(backing)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "CardMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.set_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.name = "CardContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 3)
	margin.add_child(content)

	content.add_child(_label(title, 15, COLOR_TEXT))
	var body: Label = _label(description, 11, COLOR_MUTED)
	body.clip_text = true
	content.add_child(body)
	content.add_child(_info_strip("Generates", generated_text))
	content.add_child(_info_strip("Use for", use_text))

	var targets_container: GridContainer = GridContainer.new()
	targets_container.name = "TargetsContainer"
	targets_container.columns = 1
	targets_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	targets_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	targets_container.add_theme_constant_override("h_separation", 8)
	targets_container.add_theme_constant_override("v_separation", 7)
	content.add_child(targets_container)
	return panel

func _info_strip(title: String, text: String) -> Label:
	var label: Label = _label("%s: %s" % [title, text], 10, COLOR_MUTED)
	label.clip_text = true
	return label

func _finish_panel(panel: Control, targets: Array[Control], panel_script: Script, owner_player_id: int, occupancy_policy: int, columns: int) -> void:
	panel.set_script(panel_script)
	_configure_panel(panel, owner_player_id, occupancy_policy)
	var targets_container: GridContainer = panel.find_child("TargetsContainer", true, false) as GridContainer
	if targets_container:
		if panel_script == GridNavigationPanelScript:
			targets_container.columns = columns
		else:
			targets_container.columns = 1
	var paths: Array[NodePath] = []
	for target in targets:
		target.custom_minimum_size = Vector2(0, 30)
		target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if panel_script == GridNavigationPanelScript:
			target.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if targets_container:
			targets_container.add_child(target)
		else:
			panel.add_child(target)
		if target is BaseButton:
			_style_button(target as BaseButton)
		paths.append(panel.get_path_to(target))
	panel.set("navigation_targets", paths)
	if panel_script == GridNavigationPanelScript:
		panel.set("columns", columns)
		panel.set("wrap_columns", true)
		panel.set("wrap_rows", false)

func _configure_panel(panel: Control, owner_player_id: int, occupancy_policy: int) -> void:
	panel.add_to_group("dual_cursor_navigation_panel")
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set("owner_player_id", owner_player_id)
	panel.set("occupancy_policy", occupancy_policy)
	panel.set("hit_priority", 50)
	panel.set("selection_width", 8.0)
	panel.set("selection_padding", 2.0)
	panel.set("player_selection_colors", PackedColorArray([COLOR_P1, COLOR_P2]))

func _target_button(text: String) -> Button:
	var button: Button = Button.new()
	button.name = text.to_pascal_case()
	button.text = text
	return button

func _create_cursor(root: Node, player_id: int, start_position: Vector2, interact_action: String, cancel_action: String, color: Color) -> void:
	var cursor: Sprite2D = Sprite2D.new()
	cursor.name = "Cursor%d" % [player_id + 1]
	cursor.set_script(CursorScript)
	cursor.z_index = 1000
	cursor.set("player_id", player_id)
	cursor.set("manager_path", _manager.get_path())
	cursor.set("region_node_path", _travel_region.get_path())
	cursor.set("interact_action", interact_action)
	cursor.set("cancel_action", cancel_action)
	cursor.set("fallback_cursor_color", color)
	cursor.set("center_on_primary_region_at_ready", false)
	cursor.global_position = start_position
	root.add_child(cursor)

func _on_navigation_entered(player_id: int, panel: Control) -> void:
	_log("P%d entered %s" % [player_id + 1, panel.name])

func _on_navigation_exited(player_id: int, panel: Control) -> void:
	_log("P%d exited %s" % [player_id + 1, panel.name])

func _on_navigation_denied(player_id: int, panel: Control, reason: String) -> void:
	_log("P%d cannot enter %s: %s" % [player_id + 1, panel.name, reason])

func _on_navigation_target_activated(player_id: int, panel: Control, target: Control) -> void:
	_flash_target(target, player_id)
	_log("P%d activated %s > %s" % [player_id + 1, panel.name, target.name])
	if target.has_meta("clock_id"):
		var clock_label: Label = panel.find_child("ClockLabel", true, false) as Label
		if clock_label:
			var current: int = int(clock_label.get_meta("clock_value", 0))
			current = min(6, current + 1)
			clock_label.set_meta("clock_value", current)
			clock_label.text = "Clock: %d/6" % current

func _on_toggle_changed(player_id: int, pressed: bool, cursor: Node) -> void:
	_log("P%d toggled ready: %s" % [player_id + 1, pressed])

func _on_value_changed(player_id: int, value: float, cursor: Node, value_name: String) -> void:
	_log("P%d changed %s: %s" % [player_id + 1, value_name, value])

func _on_option_selected(player_id: int, index: int, cursor: Node) -> void:
	_log("P%d selected option index %d" % [player_id + 1, index])

func _on_choice_selected(player_id: int, choice_id: String, choice_data: Dictionary, cursor: Node) -> void:
	_log("P%d chose dialogue: %s" % [player_id + 1, choice_id])

func _log(message: String) -> void:
	if _event_log == null:
		return
	_event_index += 1
	_event_log.append_text("#%03d %s\n" % [_event_index, message])
	if _event_log.get_line_count() > 0:
		_event_log.scroll_to_line(_event_log.get_line_count() - 1)

func _flash_target(target: Control, player_id: int) -> void:
	if target == null:
		return
	var original_modulate: Color = target.modulate
	var flash_color: Color = COLOR_P1 if player_id == 0 else COLOR_P2
	target.pivot_offset = target.size * 0.5
	target.modulate = flash_color.lightened(0.72)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2(0.97, 0.97), 0.08)
	tween.tween_property(target, "scale", Vector2(1.05, 1.05), 0.13)
	tween.parallel().tween_property(target, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.16)
	tween.tween_property(target, "scale", Vector2.ONE, 0.12)
	tween.tween_callback(func() -> void:
		if is_instance_valid(target):
			target.modulate = original_modulate
	)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _style_button(button: BaseButton) -> void:
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
	button.add_theme_stylebox_override("normal", _style_box(Color(0.98, 0.99, 1.0, 1), COLOR_BORDER, 1, 8))
	button.add_theme_stylebox_override("hover", _style_box(COLOR_P1, Color(0.0, 0.18, 0.42, 1), 4, 8))
	button.add_theme_stylebox_override("pressed", _style_box(Color(0.02, 0.22, 0.48, 1), Color(0.02, 0.22, 0.48, 1), 2, 8))
	button.add_theme_stylebox_override("focus", _style_box(COLOR_P1, Color(0.0, 0.18, 0.42, 1), 4, 8))

func _style_box(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	return style
