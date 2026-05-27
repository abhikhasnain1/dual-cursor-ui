class_name DualCursorThemePresets
extends RefCounted

const DEFAULT_LIGHT := "default_light"
const HIGH_CONTRAST := "high_contrast"
const SOFT_COLOR := "soft_color"
const DARK := "dark"

static func preset_names() -> PackedStringArray:
	return PackedStringArray([DEFAULT_LIGHT, HIGH_CONTRAST, SOFT_COLOR, DARK])

static func display_name(preset_name: String) -> String:
	match preset_name:
		DEFAULT_LIGHT:
			return "Default Light"
		HIGH_CONTRAST:
			return "High Contrast"
		SOFT_COLOR:
			return "Soft Color"
		DARK:
			return "Dark"
	return "Default Light"

static func panel_values(preset_name: String) -> Dictionary:
	match preset_name:
		HIGH_CONTRAST:
			return {
				"selection_width": 10.0,
				"selection_padding": 3.0,
				"player_selection_colors": PackedColorArray([
					Color(0.0, 0.12, 0.95, 1.0),
					Color(0.95, 0.16, 0.0, 1.0),
				]),
				"cursor_colors": PackedColorArray([
					Color(0.0, 0.12, 0.95, 1.0),
					Color(0.95, 0.16, 0.0, 1.0),
				]),
			}
		SOFT_COLOR:
			return {
				"selection_width": 7.0,
				"selection_padding": 3.0,
				"player_selection_colors": PackedColorArray([
					Color(0.15, 0.46, 0.72, 1.0),
					Color(0.74, 0.34, 0.22, 1.0),
				]),
				"cursor_colors": PackedColorArray([
					Color(0.15, 0.46, 0.72, 1.0),
					Color(0.74, 0.34, 0.22, 1.0),
				]),
			}
		DARK:
			return {
				"selection_width": 8.0,
				"selection_padding": 3.0,
				"player_selection_colors": PackedColorArray([
					Color(0.18, 0.72, 1.0, 1.0),
					Color(1.0, 0.46, 0.18, 1.0),
				]),
				"cursor_colors": PackedColorArray([
					Color(0.18, 0.72, 1.0, 1.0),
					Color(1.0, 0.46, 0.18, 1.0),
				]),
			}
	return {
		"selection_width": 8.0,
		"selection_padding": 2.0,
		"player_selection_colors": PackedColorArray([
			Color(0.0, 0.42, 0.78, 1.0),
			Color(0.86, 0.28, 0.12, 1.0),
		]),
		"cursor_colors": PackedColorArray([
			Color(0.2, 0.72, 1.0, 1.0),
			Color(1.0, 0.45, 0.25, 1.0),
		]),
	}

static func apply_to_navigation_panel(panel: Control, preset_name: String) -> void:
	var values := panel_values(preset_name)
	panel.set("selection_width", values["selection_width"])
	panel.set("selection_padding", values["selection_padding"])
	panel.set("player_selection_colors", values["player_selection_colors"])
	var colors: PackedColorArray = values["player_selection_colors"]
	if not colors.is_empty():
		panel.set("selection_color", colors[0])

static func apply_to_cursor(cursor: Node, player_id: int, preset_name: String) -> void:
	var values := panel_values(preset_name)
	var colors: PackedColorArray = values["cursor_colors"]
	if player_id >= 0 and player_id < colors.size():
		cursor.set("fallback_cursor_color", colors[player_id])

static func apply_to_button(button: BaseButton, preset_name: String) -> void:
	var palette := _palette(preset_name)
	button.add_theme_color_override("font_color", palette["text"])
	button.add_theme_color_override("font_hover_color", palette["text_on_accent"])
	button.add_theme_color_override("font_pressed_color", palette["text_on_accent"])
	button.add_theme_color_override("font_focus_color", palette["text_on_accent"])
	button.add_theme_stylebox_override("normal", _style_box(palette["button"], palette["border"], 1, 8))
	button.add_theme_stylebox_override("hover", _style_box(palette["accent"], palette["accent_border"], 4, 8))
	button.add_theme_stylebox_override("pressed", _style_box(palette["pressed"], palette["pressed"], 2, 8))
	button.add_theme_stylebox_override("focus", _style_box(palette["accent"], palette["accent_border"], 4, 8))

static func apply_to_surface(control: Control, preset_name: String) -> void:
	var palette := _palette(preset_name)
	if control is Panel:
		(control as Panel).add_theme_stylebox_override("panel", _style_box(palette["surface"], palette["border"], 1, 10))
	elif control is PanelContainer:
		(control as PanelContainer).add_theme_stylebox_override("panel", _style_box(palette["surface"], palette["border"], 1, 10))

static func _palette(preset_name: String) -> Dictionary:
	match preset_name:
		HIGH_CONTRAST:
			return {
				"surface": Color(1, 1, 1, 1),
				"button": Color(0.98, 0.99, 1.0, 1),
				"border": Color(0.0, 0.0, 0.0, 1),
				"accent": Color(0.0, 0.12, 0.95, 1),
				"accent_border": Color(0.0, 0.0, 0.0, 1),
				"pressed": Color(0.0, 0.0, 0.0, 1),
				"text": Color(0.02, 0.02, 0.02, 1),
				"text_on_accent": Color(1, 1, 1, 1),
			}
		SOFT_COLOR:
			return {
				"surface": Color(0.985, 0.99, 1.0, 1),
				"button": Color(0.96, 0.98, 1.0, 1),
				"border": Color(0.70, 0.78, 0.88, 1),
				"accent": Color(0.15, 0.46, 0.72, 1),
				"accent_border": Color(0.07, 0.22, 0.36, 1),
				"pressed": Color(0.06, 0.24, 0.40, 1),
				"text": Color(0.08, 0.12, 0.18, 1),
				"text_on_accent": Color(1, 1, 1, 1),
			}
		DARK:
			return {
				"surface": Color(0.08, 0.10, 0.14, 1),
				"button": Color(0.12, 0.15, 0.20, 1),
				"border": Color(0.30, 0.36, 0.46, 1),
				"accent": Color(0.18, 0.52, 0.84, 1),
				"accent_border": Color(0.72, 0.88, 1.0, 1),
				"pressed": Color(0.05, 0.20, 0.38, 1),
				"text": Color(0.92, 0.95, 0.98, 1),
				"text_on_accent": Color(1, 1, 1, 1),
			}
	return {
		"surface": Color(1, 1, 1, 0.96),
		"button": Color(0.98, 0.99, 1.0, 1),
		"border": Color(0.68, 0.76, 0.88, 1),
		"accent": Color(0.0, 0.42, 0.78, 1),
		"accent_border": Color(0.0, 0.18, 0.42, 1),
		"pressed": Color(0.02, 0.22, 0.48, 1),
		"text": Color(0.08, 0.12, 0.18, 1),
		"text_on_accent": Color(1, 1, 1, 1),
	}

static func _style_box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
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
	style.content_margin_top = 6.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 6.0
	return style
