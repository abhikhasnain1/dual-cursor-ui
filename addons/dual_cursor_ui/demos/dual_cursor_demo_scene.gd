@tool
extends Panel

const ManagerScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_manager.gd")
const CursorScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor.gd")
const NavigationPanelScript := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_navigation_panel.gd")
const DualCursorInputSetup := preload("res://addons/dual_cursor_ui/scripts/dual_cursor_input_setup.gd")
const MIN_LAYOUT_SIZE: Vector2 = Vector2(1280, 720)
const COLOR_APP_BG: Color = Color(0.94, 0.965, 0.985, 1.0)
const COLOR_SURFACE: Color = Color(1.0, 1.0, 1.0, 0.96)
const COLOR_TEXT: Color = Color(0.08, 0.12, 0.18, 1.0)
const COLOR_MUTED_TEXT: Color = Color(0.31, 0.38, 0.48, 1.0)
const COLOR_P1: Color = Color(0.82, 0.92, 1.0, 1.0)
const COLOR_P2: Color = Color(1.0, 0.88, 0.84, 1.0)
const COLOR_SHARED: Color = Color(0.91, 0.88, 1.0, 1.0)
const COLOR_P1_ACCENT: Color = Color(0.0, 0.42, 0.78, 1.0)
const COLOR_P2_ACCENT: Color = Color(0.86, 0.28, 0.12, 1.0)
const COLOR_SHARED_ACCENT: Color = Color(0.42, 0.28, 0.82, 1.0)

var _manager: Node
var _event_log: RichTextLabel
var _status: Label
var _travel_region: ColorRect
var _event_index: int = 0

func _ready() -> void:
	DualCursorInputSetup.ensure_default_actions(false)
	_configure_root()
	if has_node("DemoRoot"):
		_wire_existing_demo()
		_layout_demo()
		return
	_build_demo()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and has_node("DemoRoot"):
		_layout_demo()

func _wire_existing_demo() -> void:
	_manager = get_node_or_null("DemoRoot/DualCursorManager")
	_event_log = get_node_or_null("DemoRoot/EventLog") as RichTextLabel
	_status = get_node_or_null("DemoRoot/Status") as Label
	_travel_region = get_node_or_null("DemoRoot/CursorTravelRegion") as ColorRect
	if _manager == null:
		return
	_connect_manager_signal("navigation_entered", "_on_navigation_entered")
	_connect_manager_signal("navigation_exited", "_on_navigation_exited")
	_connect_manager_signal("navigation_denied", "_on_navigation_denied")
	_connect_manager_signal("navigation_target_activated", "_on_navigation_target_activated")

func _connect_manager_signal(signal_name: String, method_name: String) -> void:
	var callback: Callable = Callable(self, method_name)
	if not _manager.is_connected(signal_name, callback):
		_manager.connect(signal_name, callback)

func _set_demo_background() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_APP_BG
	add_theme_stylebox_override("panel", style)

func _configure_root() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2.ZERO
	size = get_viewport_rect().size

func _build_demo() -> void:
	_configure_root()
	_set_demo_background()

	var root: Control = Control.new()
	root.name = "DemoRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.set_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_travel_region = ColorRect.new()
	_travel_region.name = "CursorTravelRegion"
	_travel_region.color = COLOR_APP_BG
	_travel_region.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_travel_region)

	_manager = Node.new()
	_manager.name = "DualCursorManager"
	_manager.set_script(ManagerScript)
	root.add_child(_manager)
	_manager.connect("navigation_entered", Callable(self, "_on_navigation_entered"))
	_manager.connect("navigation_exited", Callable(self, "_on_navigation_exited"))
	_manager.connect("navigation_denied", Callable(self, "_on_navigation_denied"))
	_manager.connect("navigation_target_activated", Callable(self, "_on_navigation_target_activated"))

	var title: Label = _label("DualCursor UI Panel Navigation Demo", Vector2(30, 16), Vector2(760, 28), 22)
	title.name = "Title"
	title.add_theme_color_override("font_color", COLOR_TEXT)
	root.add_child(title)

	var p1_region: ColorRect = _region("Player1Region", Vector2(30, 60), Vector2(380, 330), COLOR_P1, "Player 1 private space")
	root.add_child(p1_region)
	var p2_region: ColorRect = _region("Player2Region", Vector2(870, 60), Vector2(380, 330), COLOR_P2, "Player 2 private space")
	root.add_child(p2_region)
	var shared_region: ColorRect = _region("SharedRegion", Vector2(430, 60), Vector2(420, 590), COLOR_SHARED, "Shared space")
	root.add_child(shared_region)

	_navigation_panel(
		p1_region,
		"P1PrivatePanel",
		Vector2(20, 50),
		Vector2(340, 230),
		"P1 private controller panel",
		"Only Player 1 can enter. Player 2 is denied.",
		0,
		DualCursorNavigationPanel.OccupancyPolicy.ALLOW_MULTIPLE,
		["P1 Inventory", "P1 Skill", "P1 Ready"]
	)
	var p1_dialogue_panel: Control = _navigation_panel(
		p1_region,
		"P1DialoguePanel",
		Vector2(20, 300),
		Vector2(340, 230),
		"P1 dialogue choices",
		"Player 1 navigates choices without a cursor.",
		0,
		DualCursorNavigationPanel.OccupancyPolicy.ALLOW_MULTIPLE,
		["Ask about the ruins.", "Request supplies.", "Leave conversation."],
		false
	)
	p1_dialogue_panel.set("selection_color", COLOR_P1_ACCENT)
	_navigation_panel(
		p2_region,
		"P2PrivatePanel",
		Vector2(20, 50),
		Vector2(340, 230),
		"P2 private controller panel",
		"Only Player 2 can enter. Player 1 is denied.",
		1,
		DualCursorNavigationPanel.OccupancyPolicy.ALLOW_MULTIPLE,
		["P2 Inventory", "P2 Skill", "P2 Ready"]
	)
	var p2_dialogue_panel: Control = _navigation_panel(
		p2_region,
		"P2DialoguePanel",
		Vector2(20, 300),
		Vector2(340, 230),
		"P2 dialogue choices",
		"Player 2 navigates choices without a cursor.",
		1,
		DualCursorNavigationPanel.OccupancyPolicy.ALLOW_MULTIPLE,
		["Ask about the ruins.", "Request supplies.", "Leave conversation."],
		false
	)
	p2_dialogue_panel.set("selection_color", COLOR_P2_ACCENT)
	_navigation_panel(
		shared_region,
		"SharedExclusivePanel",
		Vector2(20, 50),
		Vector2(180, 250),
		"Shared exclusive",
		"Both can enter, one player at a time.",
		-1,
		DualCursorNavigationPanel.OccupancyPolicy.FIRST_PLAYER_LOCKS,
		["Trade", "Inspect", "Take"]
	)
	_navigation_panel(
		shared_region,
		"SharedSimultaneousPanel",
		Vector2(220, 50),
		Vector2(180, 250),
		"Shared simultaneous",
		"Both can enter together. Actions log by player.",
		-1,
		DualCursorNavigationPanel.OccupancyPolicy.ALLOW_MULTIPLE,
		["Attack", "Defend", "Assist"]
	)

	_status = _label("Status: move into a panel to switch from cursor movement to controller navigation. Press B/Circle to exit.", Vector2(30, 410), Vector2(800, 42), 15)
	_status.name = "Status"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", COLOR_TEXT)
	root.add_child(_status)

	_event_log = RichTextLabel.new()
	_event_log.name = "EventLog"
	_event_log.position = Vector2(30, 462)
	_event_log.size = Vector2(800, 188)
	_event_log.bbcode_enabled = true
	_event_log.fit_content = false
	_event_log.scroll_following = true
	_event_log.add_theme_color_override("default_color", COLOR_MUTED_TEXT)
	_event_log.add_theme_stylebox_override("normal", _style_box(Color(1.0, 1.0, 1.0, 0.78), Color(0.76, 0.83, 0.91, 1.0), 1, 10))
	root.add_child(_event_log)

	var help: Label = _label("Private panels reject the other player. Dialogue choices are private. Shared exclusive locks to one player. Shared simultaneous allows both players.", Vector2(870, 430), Vector2(380, 90), 15)
	help.name = "Help"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_color_override("font_color", COLOR_MUTED_TEXT)
	root.add_child(help)

	_add_cursor(root, "Cursor1", 0, _travel_region, [], "interact_p1", "cancel_p1", Color(0.2, 0.72, 1.0, 1.0))
	_add_cursor(root, "Cursor2", 1, _travel_region, [], "interact_p2", "cancel_p2", Color(1.0, 0.45, 0.25, 1.0))

	_layout_demo()
	call_deferred("_refresh_cursors")
	_log("Demo ready. Enter a panel with either cursor, press A/Cross to activate, B/Circle to exit.")

func _layout_demo() -> void:
	var root: Control = get_node_or_null("DemoRoot") as Control
	if root == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = size

	var layout_scale: float = min(1.0, min(viewport_size.x / MIN_LAYOUT_SIZE.x, viewport_size.y / MIN_LAYOUT_SIZE.y))
	if layout_scale <= 0.0:
		layout_scale = 1.0
	var layout_size: Vector2 = viewport_size / layout_scale

	position = Vector2.ZERO
	size = viewport_size
	root.scale = Vector2(layout_scale, layout_scale)
	root.position = (viewport_size - layout_size * layout_scale) * 0.5
	root.size = layout_size

	if _travel_region:
		_travel_region.position = Vector2.ZERO
		_travel_region.size = layout_size

	var min_side: float = min(layout_size.x, layout_size.y)
	var margin: float = clamp(min_side * 0.035, 18.0, 56.0)
	var gap: float = clamp(min_side * 0.035, 22.0, 64.0)
	var header_h: float = clamp(layout_size.y * 0.06, 34.0, 58.0)
	var bottom_h: float = clamp(layout_size.y * 0.22, 120.0, 230.0)
	var top_y: float = margin + header_h
	var region_h: float = max(260.0, layout_size.y - top_y - bottom_h - gap - margin)
	var content_w: float = max(1.0, layout_size.x - margin * 2.0)
	var side_ratio: float = 0.24 if layout_size.x > layout_size.y * 2.0 else 0.27
	var left_w: float = max(220.0, (content_w - gap * 2.0) * side_ratio)
	var center_w: float = max(360.0, content_w - left_w * 2.0 - gap * 2.0)
	if left_w * 2.0 + center_w + gap * 2.0 > content_w:
		left_w = max(180.0, (content_w - gap * 2.0) * 0.25)
		center_w = max(260.0, content_w - left_w * 2.0 - gap * 2.0)
	var right_w: float = left_w
	var left_x: float = margin
	var center_x: float = left_x + left_w + gap
	var right_x: float = center_x + center_w + gap

	_layout_rect("DemoRoot/Player1Region", Vector2(left_x, top_y), Vector2(left_w, region_h))
	_layout_rect("DemoRoot/SharedRegion", Vector2(center_x, top_y), Vector2(center_w, region_h))
	_layout_rect("DemoRoot/Player2Region", Vector2(right_x, top_y), Vector2(right_w, region_h))
	_layout_rect("DemoRoot/Status", Vector2(margin, top_y + region_h + 10.0), Vector2(left_w + center_w + gap, 34.0))
	_layout_rect("DemoRoot/EventLog", Vector2(margin, top_y + region_h + 50.0), Vector2(left_w + center_w + gap, max(78.0, bottom_h - 64.0)))
	_layout_rect("DemoRoot/Help", Vector2(right_x, top_y + region_h + 10.0), Vector2(right_w, bottom_h - 10.0))

	var title: Control = get_node_or_null("DemoRoot/Title") as Control
	if title:
		title.position = Vector2(margin, 12.0)
		title.size = Vector2(content_w, 30.0)

	var panel_top_y: float = 52.0
	var panel_stack_gap: float = clamp(gap * 0.55, 12.0, 22.0)
	var private_panel_w: float = max(150.0, left_w - gap * 2.0)
	var private_menu_h: float = _panel_content_height(3, 30.0)
	var private_dialogue_h: float = _panel_content_height(3, 30.0)
	var private_second_y: float = panel_top_y + private_menu_h + panel_stack_gap
	_layout_navigation_panel(
		"DemoRoot/Player1Region/P1PrivatePanel",
		Vector2(gap, panel_top_y),
		Vector2(private_panel_w, private_menu_h)
	)
	_layout_navigation_panel(
		"DemoRoot/Player1Region/P1DialoguePanel",
		Vector2(gap, private_second_y),
		Vector2(private_panel_w, private_dialogue_h)
	)
	private_panel_w = max(150.0, right_w - gap * 2.0)
	_layout_navigation_panel(
		"DemoRoot/Player2Region/P2PrivatePanel",
		Vector2(gap, panel_top_y),
		Vector2(private_panel_w, private_menu_h)
	)
	_layout_navigation_panel(
		"DemoRoot/Player2Region/P2DialoguePanel",
		Vector2(gap, private_second_y),
		Vector2(private_panel_w, private_dialogue_h)
	)

	var shared_inner_w: float = max(260.0, center_w - gap * 2.0)
	var two_col_gap: float = clamp(center_w * 0.08, 28.0, 80.0)
	var shared_col_w: float = (shared_inner_w - two_col_gap) * 0.5
	var top_panel_h: float = _panel_content_height(3, 38.0)
	_layout_navigation_panel(
		"DemoRoot/SharedRegion/SharedExclusivePanel",
		Vector2(gap, panel_top_y),
		Vector2(shared_col_w, top_panel_h)
	)
	_layout_navigation_panel(
		"DemoRoot/SharedRegion/SharedSimultaneousPanel",
		Vector2(gap + shared_col_w + two_col_gap, panel_top_y),
		Vector2(shared_col_w, top_panel_h)
	)

	call_deferred("_refresh_cursors")

func _layout_rect(path: String, position_value: Vector2, size_value: Vector2) -> void:
	var control: Control = get_node_or_null(path) as Control
	if control == null:
		return
	control.position = position_value
	control.size = size_value
	if control is ColorRect and control.get_child_count() > 0:
		var title: Control = control.get_child(0) as Control
		if title:
			title.position = Vector2(12, 10)
			title.size = Vector2(size_value.x - 24, 28)

func _layout_navigation_panel(path: String, position_value: Vector2, size_value: Vector2) -> void:
	var panel: Control = get_node_or_null(path) as Control
	if panel == null:
		return
	panel.position = position_value
	panel.size = size_value

	var backing: Control = panel.get_node_or_null("Background") as Control
	if backing:
		backing.position = Vector2.ZERO
		backing.size = size_value

	var title: Control = null
	if panel.get_child_count() > 1:
		title = panel.get_child(1) as Control
	if title:
		title.position = Vector2(10, 8)
		title.size = Vector2(size_value.x - 20, 26)

	var description: Control = null
	if panel.get_child_count() > 2:
		description = panel.get_child(2) as Control
	if description:
		description.position = Vector2(10, 32)
		description.size = Vector2(size_value.x - 20, 30)

	var first_target_index: int = 3
	var target_count: int = max(1, panel.get_child_count() - first_target_index)
	var row_gap: float = 6.0
	var row_h: float = max(30.0, min(42.0, (size_value.y - 70.0 - row_gap * float(target_count - 1)) / float(target_count)))
	var start_y: float = 68.0
	for child_index in range(first_target_index, panel.get_child_count()):
		var target: Control = panel.get_child(child_index) as Control
		if target == null:
			continue
		var target_i: int = child_index - first_target_index
		target.position = Vector2(10, start_y + float(target_i) * (row_h + row_gap))
		target.size = Vector2(size_value.x - 20, row_h)
		target.pivot_offset = target.size * 0.5
		var target_backing: Control = target.get_node_or_null("Background") as Control
		if target_backing:
			target_backing.position = Vector2.ZERO
			target_backing.size = target.size
		var label: Control = null
		if target.get_child_count() > 1:
			label = target.get_child(1) as Control
		if label:
			label.position = Vector2(10, 0)
			label.size = Vector2(target.size.x - 20, target.size.y)

func _panel_content_height(target_count: int, row_h: float) -> float:
	var row_gap: float = 6.0
	return 78.0 + row_h * float(target_count) + row_gap * float(max(0, target_count - 1))

func _refresh_cursors() -> void:
	for cursor_name in ["Cursor1", "Cursor2"]:
		var cursor: Node = get_node_or_null("DemoRoot/%s" % cursor_name)
		if cursor and cursor.has_method("refresh_movement_regions"):
			cursor.refresh_movement_regions()

func _region(node_name: String, position_value: Vector2, size_value: Vector2, color: Color, title: String) -> ColorRect:
	var region: ColorRect = ColorRect.new()
	region.name = node_name
	region.position = position_value
	region.size = size_value
	region.color = color
	var title_label: Label = _label(title, Vector2(12, 10), Vector2(size_value.x - 24, 28), 16)
	title_label.add_theme_color_override("font_color", COLOR_TEXT)
	region.add_child(title_label)
	return region

func _navigation_panel(parent: Control, node_name: String, position_value: Vector2, size_value: Vector2, title: String, description: String, owner_player_id: int, occupancy_policy: int, choices: Array, use_buttons: bool = true) -> Control:
	var panel: Control = Control.new()
	panel.name = node_name
	panel.position = position_value
	panel.size = size_value
	panel.set_script(NavigationPanelScript)
	parent.add_child(panel)

	panel.set("owner_player_id", owner_player_id)
	panel.set("occupancy_policy", occupancy_policy)
	panel.set("hit_priority", 50)
	panel.set("selection_width", 8.0)
	panel.set("selection_padding", 2.0)
	panel.set("player_selection_colors", PackedColorArray([COLOR_P1_ACCENT, COLOR_P2_ACCENT]))

	var backing: Panel = Panel.new()
	backing.name = "Background"
	backing.position = Vector2.ZERO
	backing.size = size_value
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.add_theme_stylebox_override("panel", _style_box(COLOR_SURFACE, Color(0.77, 0.83, 0.91, 1.0), 1, 12))
	panel.add_child(backing)

	var title_label: Label = _label(title, Vector2(10, 8), Vector2(size_value.x - 20, 26), 14)
	title_label.add_theme_color_override("font_color", COLOR_TEXT)
	panel.add_child(title_label)

	var description_label: Label = _label(description, Vector2(10, 32), Vector2(size_value.x - 20, 36), 12)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_color_override("font_color", COLOR_MUTED_TEXT)
	panel.add_child(description_label)

	var target_paths: Array[NodePath] = []
	for i in choices.size():
		var target: Control
		if use_buttons:
			var button: Button = Button.new()
			button.text = str(choices[i])
			_apply_button_theme(button)
			target = button
		else:
			target = _dialogue_choice(str(choices[i]), Vector2(size_value.x - 20, 42))
		target.name = "Choice%d" % [i + 1]
		target.position = Vector2(10, 44 + i * 54)
		target.size = Vector2(size_value.x - 20, 42)
		panel.add_child(target)
		target_paths.append(panel.get_path_to(target))

	panel.set("navigation_targets", target_paths)
	return panel

func _dialogue_choice(text: String, size_value: Vector2) -> Control:
	var row: Control = Control.new()
	row.size = size_value
	var backing: Panel = Panel.new()
	backing.name = "Background"
	backing.size = size_value
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.add_theme_stylebox_override("panel", _style_box(Color(0.975, 0.982, 1.0, 1.0), Color(0.78, 0.84, 0.94, 1.0), 1, 9))
	row.add_child(backing)
	var label: Label = _label(text, Vector2(10, 0), Vector2(size_value.x - 20, size_value.y), 14)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(label)
	return row

func _apply_button_theme(button: Button) -> void:
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_stylebox_override("normal", _style_box(Color(0.98, 0.99, 1.0, 1.0), Color(0.68, 0.76, 0.88, 1.0), 1, 9))
	button.add_theme_stylebox_override("hover", _style_box(Color(0.0, 0.42, 0.78, 1.0), Color(0.0, 0.18, 0.42, 1.0), 4, 9))
	button.add_theme_stylebox_override("pressed", _style_box(Color(0.02, 0.22, 0.48, 1.0), Color(0.02, 0.22, 0.48, 1.0), 2, 9))
	button.add_theme_stylebox_override("focus", _style_box(Color(0.0, 0.42, 0.78, 1.0), Color(0.0, 0.18, 0.42, 1.0), 4, 9))

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
	style.content_margin_top = 6.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 6.0
	return style

func _add_cursor(parent: Node, node_name: String, player_id: int, primary_region: Control, extra_regions: Array[Control], interact_action: String, cancel_action: String, color: Color) -> void:
	var cursor: Sprite2D = Sprite2D.new()
	cursor.name = node_name
	cursor.z_index = 100
	cursor.set_script(CursorScript)
	parent.add_child(cursor)
	cursor.set("player_id", player_id)
	cursor.set("manager_path", cursor.get_path_to(_manager))
	cursor.set("region_node_path", cursor.get_path_to(primary_region))
	cursor.set("interact_action", interact_action)
	cursor.set("cancel_action", cancel_action)
	cursor.set("fallback_cursor_color", color)
	var paths: Array[NodePath] = []
	for region in extra_regions:
		paths.append(cursor.get_path_to(region))
	cursor.set("extra_region_node_paths", paths)

func _label(text: String, position_value: Vector2, size_value: Vector2, font_size: int) -> Label:
	var label: Label = Label.new()
	label.position = position_value
	label.size = size_value
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _on_navigation_entered(player_id: int, panel: Control) -> void:
	_log("P%d entered %s" % [player_id + 1, panel.name])

func _on_navigation_exited(player_id: int, panel: Control) -> void:
	_log("P%d exited %s" % [player_id + 1, panel.name])

func _on_navigation_denied(player_id: int, panel: Control, reason: String) -> void:
	var message: String = "P%d cannot enter %s: %s" % [player_id + 1, panel.name, _human_reason(reason)]
	if _status:
		_status.text = "Status: " + message
	_log(message)

func _on_navigation_target_activated(player_id: int, panel: Control, target: Control) -> void:
	_flash_target(target, player_id)
	_log("P%d activated %s > %s" % [player_id + 1, panel.name, target.name])

func _human_reason(reason: String) -> String:
	if reason.begins_with("occupied_by_player_"):
		return "Player %s is using this panel" % [reason.trim_prefix("occupied_by_player_")]
	if reason.begins_with("owned_by_player_"):
		return "only Player %s can use this panel" % [reason.trim_prefix("owned_by_player_")]
	if reason == "no_navigation_targets":
		return "there are no navigation targets"
	return reason.replace("_", " ")

func _log(message: String) -> void:
	_event_index += 1
	var line: String = "#%03d %s" % [_event_index, message]
	print(line)
	if _event_log:
		_event_log.append_text(line + "\n")
		call_deferred("_scroll_log_to_bottom")

func _scroll_log_to_bottom() -> void:
	if _event_log == null:
		return
	var line_count: int = _event_log.get_line_count()
	if line_count > 0:
		_event_log.scroll_to_line(line_count - 1)

func _flash_target(target: Control, player_id: int) -> void:
	if target == null:
		return
	var original_modulate: Color = target.modulate
	var flash_color: Color = COLOR_P1_ACCENT if player_id == 0 else COLOR_P2_ACCENT
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
