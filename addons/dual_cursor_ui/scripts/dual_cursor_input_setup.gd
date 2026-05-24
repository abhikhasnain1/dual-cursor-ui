class_name DualCursorInputSetup
extends RefCounted

static func ensure_default_actions(save_settings: bool = false) -> void:
	_add_joy_button_action("interact_p1", 0, JOY_BUTTON_A)
	_add_joy_button_action("interact_p2", 1, JOY_BUTTON_A)
	_add_joy_button_action("cancel_p1", 0, JOY_BUTTON_B)
	_add_joy_button_action("cancel_p2", 1, JOY_BUTTON_B)

	if save_settings:
		_persist_action("interact_p1")
		_persist_action("interact_p2")
		_persist_action("cancel_p1")
		_persist_action("cancel_p2")
		ProjectSettings.save()

static func has_default_actions() -> bool:
	return (
		InputMap.has_action("interact_p1")
		and InputMap.has_action("interact_p2")
		and InputMap.has_action("cancel_p1")
		and InputMap.has_action("cancel_p2")
	)

static func _add_joy_button_action(action_name: String, device: int, button_index: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)

	for event in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton and event.device == device and event.button_index == button_index:
			return

	var joy_event := InputEventJoypadButton.new()
	joy_event.device = device
	joy_event.button_index = button_index
	InputMap.action_add_event(action_name, joy_event)

static func _persist_action(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		return

	ProjectSettings.set_setting("input/%s" % action_name, {
		"deadzone": InputMap.action_get_deadzone(action_name),
		"events": InputMap.action_get_events(action_name),
	})
