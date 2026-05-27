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

## Connect Panel Buttons to Game Actions

For real game menus, give each target an action id with metadata. This keeps game logic stable even if node names change.

```gdscript
extends Node

@export var panel: DualCursorNavigationPanel
@export var inventory_button: Button
@export var skill_button: Button
@export var ready_button: Button

func _ready() -> void:
	inventory_button.set_meta("action", "inventory")
	skill_button.set_meta("action", "skill")
	ready_button.set_meta("action", "ready")
	panel.target_activated.connect(_on_panel_target_activated)

func _on_panel_target_activated(player_id: int, target: Control, cursor: Node) -> void:
	match str(target.get_meta("action", "")):
		"inventory":
			open_inventory(player_id)
		"skill":
			open_skill_tree(player_id)
		"ready":
			set_ready(player_id)

func open_inventory(player_id: int) -> void:
	print("Open inventory for player %d" % [player_id + 1])

func open_skill_tree(player_id: int) -> void:
	print("Open skill tree for player %d" % [player_id + 1])

func set_ready(player_id: int) -> void:
	print("Player %d is ready" % [player_id + 1])
```

## Populate Dialogue Choices

Dialogue panels use the same `target_activated` signal. Create normal Godot buttons or custom `Control` rows, add them to `navigation_targets`, and store your dialogue choice id in metadata.

```gdscript
extends Node

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
		button.custom_minimum_size = Vector2(420, 44)
		choices_container.add_child(button)
		dialogue_panel.navigation_targets.append(dialogue_panel.get_path_to(button))

func _on_dialogue_choice_selected(player_id: int, target: Control, cursor: Node) -> void:
	var choice_id := str(target.get_meta("choice_id", ""))
	choose_dialogue_option(player_id, choice_id)

func choose_dialogue_option(player_id: int, choice_id: String) -> void:
	print("Player %d chose %s" % [player_id + 1, choice_id])
```

For shared dialogue, set `owner_player_id = -1`. Use `ALLOW_MULTIPLE` when both players can choose at the same time, or `FIRST_PLAYER_LOCKS` when one player should control the choices until they exit.

## Inventory, Shop, Skill, Or Tactical Grids

Use `DualCursorGridNavigationPanel` when targets are arranged as cells. Store game ids in metadata and route `target_activated` into your own inventory, shop, skill, or tactical systems.

```gdscript
extends Node

@export var grid_panel: DualCursorGridNavigationPanel

func _ready() -> void:
	grid_panel.columns = 4
	grid_panel.wrap_columns = true
	grid_panel.wrap_rows = false
	grid_panel.target_activated.connect(_on_grid_target_activated)

func _on_grid_target_activated(player_id: int, target: Control, cursor: Node) -> void:
	var item_id := str(target.get_meta("item_id", ""))
	var shop_item_id := str(target.get_meta("shop_item_id", ""))
	var skill_id := str(target.get_meta("skill_id", ""))
	var action_id := str(target.get_meta("action_id", ""))

	if not item_id.is_empty():
		use_item(player_id, item_id)
	elif not shop_item_id.is_empty():
		buy_or_inspect_shop_item(player_id, shop_item_id)
	elif not skill_id.is_empty():
		open_skill(player_id, skill_id)
	elif not action_id.is_empty():
		choose_tactical_action(player_id, action_id)

func use_item(player_id: int, item_id: String) -> void:
	print("Player %d used %s" % [player_id + 1, item_id])

func buy_or_inspect_shop_item(player_id: int, shop_item_id: String) -> void:
	print("Player %d selected shop item %s" % [player_id + 1, shop_item_id])

func open_skill(player_id: int, skill_id: String) -> void:
	print("Player %d opened skill %s" % [player_id + 1, skill_id])

func choose_tactical_action(player_id: int, action_id: String) -> void:
	print("Player %d chose action %s" % [player_id + 1, action_id])
```

## Player-Aware Control Adapters

Use adapter scripts when a player needs to change a normal Godot widget inside a DualCursor panel.

```gdscript
extends Node

@export var ready_toggle: DualCursorToggleAdapter
@export var volume_slider: DualCursorSliderAdapter
@export var category_options: DualCursorOptionAdapter
@export var quantity: DualCursorSpinBoxAdapter

func _ready() -> void:
	ready_toggle.toggled_by_player.connect(_on_ready_toggled)
	volume_slider.value_changed_by_player.connect(_on_volume_changed)
	category_options.option_selected_by_player.connect(_on_category_selected)
	quantity.value_changed_by_player.connect(_on_quantity_changed)

func _on_ready_toggled(player_id: int, pressed: bool, cursor: Node) -> void:
	print("Player %d ready: %s" % [player_id + 1, pressed])

func _on_volume_changed(player_id: int, value: float, cursor: Node) -> void:
	print("Player %d set volume to %s" % [player_id + 1, value])

func _on_category_selected(player_id: int, index: int, cursor: Node) -> void:
	print("Player %d selected category %d" % [player_id + 1, index])

func _on_quantity_changed(player_id: int, value: float, cursor: Node) -> void:
	print("Player %d quantity: %s" % [player_id + 1, value])
```

Adapters can be used directly under free cursor movement or as targets inside `DualCursorNavigationPanel` and `DualCursorGridNavigationPanel`.

## Narrative And TTRPG-Style Events

DualCursor UI should route player-aware UI events to your game state, not own your story database, dice rules, clocks, inventory, save data, or branching narrative. Use metadata on panel targets to keep that handoff explicit.

```gdscript
extends Node

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
		choose_dialogue_option(player_id, choice_id)
	elif not skill_id.is_empty():
		request_skill_check(player_id, skill_id)
	elif not event_id.is_empty():
		confirm_shared_event(player_id, event_id)

func choose_dialogue_option(player_id: int, choice_id: String) -> void:
	print("Player %d chose dialogue branch %s" % [player_id + 1, choice_id])

func request_skill_check(player_id: int, skill_id: String) -> void:
	print("Player %d requested skill check %s" % [player_id + 1, skill_id])
	progress_clock += 1
	clock_label.text = "Clock: %d/6" % progress_clock

func confirm_shared_event(player_id: int, event_id: String) -> void:
	print("Player %d confirmed shared event %s" % [player_id + 1, event_id])
```

Recommended metadata keys:

- `choice_id`: dialogue branch or response id.
- `event_id`: shared narrative event id.
- `skill_id`: dice or skill-check id owned by your game logic.
- `inventory_action`: inventory/menu command id.

## Dialogue Panel Helper

Use `DualCursorDialoguePanel` when dialogue choices come from game data and you want the panel to build its own choice rows.

```gdscript
extends Node

@export var dialogue_panel: DualCursorDialoguePanel

func _ready() -> void:
	dialogue_panel.choice_selected.connect(_on_choice_selected)
	dialogue_panel.owner_player_id = 0
	dialogue_panel.set_choices([
		{"id": "ask_ruins", "text": "Ask about the ruins.", "event_type": "choice"},
		{"id": "request_supplies", "text": "Request supplies.", "event_type": "choice"},
		{"id": "leave", "text": "Leave the conversation.", "event_type": "choice"}
	])

func _on_choice_selected(player_id: int, choice_id: String, choice_data: Dictionary, cursor: Node) -> void:
	print("Player %d chose %s" % [player_id + 1, choice_id])
```

## Narrative Router Helper

Use `DualCursorNarrativeRouter` when different panels should report choices, checks, clocks, inventory commands, and shared events through one signal.

```gdscript
extends Node

@export var panel: DualCursorNavigationPanel
@export var router: DualCursorNarrativeRouter

func _ready() -> void:
	panel.target_activated.connect(_on_target_activated)
	router.narrative_event.connect(_on_narrative_event)

func _on_target_activated(player_id: int, target: Control, cursor: Node) -> void:
	router.route_panel_target(player_id, target, cursor)

func _on_narrative_event(player_id: int, event_type: String, event_id: String, payload: Dictionary, cursor: Node) -> void:
	print("Player %d triggered %s %s" % [player_id + 1, event_type, event_id])
```

## Convert An Existing Menu

1. Select a plain `Control` panel that contains child `Button` nodes.
2. In the DualCursor UI dock, choose the matching Panel Builder access preset.
3. Click **Setup Selected Panel**. The builder also adds the two-player cursor runtime if the scene needs one.
4. Click **Validate Selected Panel**.
5. Connect `DualCursorNavigationPanel.target_activated(player_id, target, cursor)` to game logic.
