class_name DualCursorButton
extends "res://addons/dual_cursor_ui/scripts/dual_cursor_interactable.gd"

enum ButtonEffect { HOVER, RESET, DENY, CHOSEN }

@export var click_audio_path: NodePath
@export var label_path: NodePath
@export var hover_scale: Vector2 = Vector2(1.05, 1.05)
@export var chosen_scale: Vector2 = Vector2(1.15, 1.15)
@export var tween_duration: float = 0.1

signal pressed_by_player(player_id: int, cursor: Node)

func _ready() -> void:
	super()
	dual_cursor_hover_started.connect(_on_dual_cursor_hover_started)
	dual_cursor_hover_ended.connect(_on_dual_cursor_hover_ended)
	dual_cursor_interacted.connect(_on_dual_cursor_interacted)
	dual_cursor_denied.connect(_on_dual_cursor_denied)

func set_text(text: String) -> void:
	var label := _get_label()
	if label:
		label.text = text

func play_disappear_and_free() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_callback(func(): queue_free())

func play_effect(effect: ButtonEffect) -> void:
	match effect:
		ButtonEffect.HOVER:
			_play_click()
			_tween_scale(hover_scale)
		ButtonEffect.RESET:
			_tween_scale(Vector2.ONE)
		ButtonEffect.DENY:
			_play_deny_shake()
		ButtonEffect.CHOSEN:
			_play_click()
			_tween_scale(chosen_scale)

func _on_dual_cursor_hover_started(_player_id: int, _cursor: Node) -> void:
	play_effect(ButtonEffect.HOVER)

func _on_dual_cursor_hover_ended(_player_id: int, _cursor: Node) -> void:
	play_effect(ButtonEffect.RESET)

func _on_dual_cursor_interacted(player_id: int, cursor: Node) -> void:
	play_effect(ButtonEffect.CHOSEN)
	emit_signal("pressed_by_player", player_id, cursor)

func _on_dual_cursor_denied(_player_id: int, _cursor: Node, _reason: String) -> void:
	play_effect(ButtonEffect.DENY)

func _get_label() -> Label:
	if not label_path.is_empty():
		return get_node_or_null(label_path) as Label
	return find_child("Label", true, false) as Label

func _play_click() -> void:
	var audio: AudioStreamPlayer = get_node_or_null(click_audio_path) as AudioStreamPlayer
	if audio and not audio.playing:
		audio.play()

func _tween_scale(target_scale: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", target_scale, tween_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _play_deny_shake() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:x", position.x - 10, 0.05)
	tween.tween_property(self, "position:x", position.x + 10, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.05)
