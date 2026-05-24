# DualCursor UI Walkthroughs

These examples show how to connect DualCursor UI nodes to your own game scripts.

## Connect Buttons to Game Logic

Use `pressed_by_player(player_id, cursor)` when a `DualCursorButton` should trigger dialogue, menu, inventory, or scene logic.

```gdscript
extends Node

@export var choice_button: DualCursorButton

func _ready() -> void:
	choice_button.pressed_by_player.connect(_on_choice_pressed)

func _on_choice_pressed(player_id: int, cursor: Node) -> void:
	print("Player %d selected %s" % [player_id + 1, choice_button.name])
	# Put your dialogue, menu, or game-state change here.
```

## Set Ownership and Regions

Use `owner_player_id` to decide who can interact. Use `region_node_path` for a player's private area and `extra_region_node_paths` for shared areas.

```gdscript
extends Node

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
```

## Require Both Players

Use `REQUIRE_ALL_PLAYERS` when a shared control should wait for both players before it fires.

```gdscript
extends Node

@export var shared_button: DualCursorButton

func _ready() -> void:
	shared_button.owner_player_id = -1
	shared_button.shared_policy = DualCursorInteractable.SharedPolicy.REQUIRE_ALL_PLAYERS
	shared_button.required_players = PackedInt32Array([0, 1])
	shared_button.dual_cursor_shared_confirmed.connect(_on_shared_confirmed)

func _on_shared_confirmed(player_ids: PackedInt32Array) -> void:
	print("Both players confirmed: %s" % [player_ids])
	# Start the scene, commit the vote, or advance the shared choice here.
```

## Controller Navigation Panel

Use `DualCursorNavigationPanel` when a menu is better controlled as an ordered list than as a free cursor target.

```gdscript
extends Node

@export var panel: DualCursorNavigationPanel
@export var first_button: Button
@export var second_button: Button

func _ready() -> void:
	panel.navigation_targets = [
		panel.get_path_to(first_button),
		panel.get_path_to(second_button)
	]
	panel.occupancy_policy = DualCursorNavigationPanel.OccupancyPolicy.FIRST_PLAYER_LOCKS
	panel.target_activated.connect(_on_panel_target_activated)

func _on_panel_target_activated(player_id: int, target: Control, cursor: Node) -> void:
	print("Player %d activated %s" % [player_id + 1, target.name])
```

## Convert An Existing Menu

1. Select a plain `Control` panel that contains child `Button` nodes.
2. In the DualCursor UI dock, choose the matching Panel Builder access preset.
3. Click **Setup Selected Panel**.
4. Click **Validate Selected Panel**.
5. Connect `DualCursorNavigationPanel.target_activated(player_id, target, cursor)` to game logic.
