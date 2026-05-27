# Getting Started

## Install

Copy the addon folder into your project:

```text
addons/dual_cursor_ui/
```

Enable it in:

```text
Project > Project Settings > Plugins > DualCursor UI
```

## Make Your First Scene

1. Create a new empty scene.
2. Open the **DualCursor UI** dock.
3. Click **Create Playable 2-Player Scene**. The dock creates a complete playable template with private menu panels, private dialogue choices, exclusive shared panels, simultaneous shared panels, cursors, logging, and controller actions.
4. Click **Validate Current Scene**.
5. Save and run the scene with two controllers connected.
6. Move each cursor with the matching controller's left stick.
7. Press A/Cross to activate a button.
8. Move into any private or shared panel to switch from free cursor movement to controller navigation. Press B/Circle to exit it.
9. Use **Panel Builder** on your own selected `Control` panels when you are ready to configure a real game UI.
10. Use the **Use In Your Game** section in the dock for copyable GDScript examples.

DualCursor UI v0.5.0 is still a two-controller workflow. It does not provide independent multi-mouse or multi-keyboard device routing.

## Connect A Button

For standalone `DualCursorButton` nodes, open the Node dock and connect:

```text
pressed_by_player(player_id, cursor)
```

Example handler:

```gdscript
func _on_pressed_by_player(player_id: int, cursor: Node) -> void:
	print("Player %d selected this button." % [player_id + 1])
```

More examples are in:

```text
res://addons/dual_cursor_ui/docs/WALKTHROUGHS.md
```

## Ownership

- `owner_player_id = 0`: only player 1 can interact.
- `owner_player_id = 1`: only player 2 can interact.
- `owner_player_id = -1`: shared control.

## Shared Controls

Shared controls still need to be inside a movement region that every intended player can reach. The starter scene uses `SharedRegion`, and both cursors list it in `extra_region_node_paths`.

If validation says a shared control is outside all cursor regions, move the control into the shared region or add that region to the cursor's `extra_region_node_paths`.

## Movement Regions

- `region_node_path`: the cursor's private home region.
- `extra_region_node_paths`: shared or extra regions that cursor may also enter.

Keep player-owned controls inside that player's private region. Put shared controls inside a shared region assigned to both cursors.

## Navigation Panels

Use `DualCursorNavigationPanel` for dense menus or panels where pointing a free cursor at every option feels awkward. Add the panel to a reachable movement region, then assign its `navigation_targets` in the order players should move through them. Entering the panel automatically captures that player into controller navigation; `cancel_action` exits back to free cursor movement.

For private panels, set `owner_player_id` to the allowed player. For shared panels that only one player can use at a time, set `occupancy_policy` to `FIRST_PLAYER_LOCKS`. For dialogue choices, use normal `Control` rows as `navigation_targets` and listen to `target_activated`.

Use `target_activated` for buttons inside navigation panels:

```gdscript
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
```

## Convert Your Own Menu Panel

1. Build a normal Godot `Control` panel with child buttons.
2. Select the panel node in the Scene dock.
3. In the DualCursor UI dock, choose a Panel Builder preset: Player 1 Private, Player 2 Private, Shared Exclusive, or Shared Simultaneous.
4. Choose **List Panel** for linear menus or **Grid Panel** for inventories, shops, skill trees, and tactical commands.
5. For Grid Panel, set the column count.
6. Click **Setup Selected Panel**. The builder also adds two cursors and a manager if the scene does not already have them.
7. Click **Validate Selected Panel**.
8. Run the scene, move a cursor into the panel, navigate with the left stick, activate with A/Cross, and exit with B/Circle.

Panel Builder will not overwrite a custom script. Use a plain `Control` node or an existing `DualCursorNavigationPanel`.

## Grid Panels

Use `DualCursorGridNavigationPanel` when options are arranged as cells instead of a single list. Left/right moves between neighboring cells. Up/down moves by the configured column count.

Recommended metadata keys:

- `item_id`: inventory item.
- `shop_item_id`: shop item or service.
- `skill_id`: skill tree node.
- `action_id`: tactical command.

## Debug Regions

Click **Add/Toggle Debug Overlay** in the dock when a cursor cannot reach a panel or when a shared panel captures incorrectly. The overlay draws each cursor's movement regions and every navigation panel capture zone. It is disabled by default and does not change gameplay input.

## Controller Profiles And Themes

Use **Controller Profile** to create or repair two-controller select/cancel actions for generic gamepad, Xbox/XInput, or PlayStation-style controllers. Select remains A/Cross and cancel remains B/Circle.

Use **Theme Preset** to apply Default Light, High Contrast, Soft Color, or Dark selection styling to a selected panel or generated runtime. High Contrast is the recommended accessibility preset when focus visibility is more important than visual subtlety.

## DualCursorRuntime

Panel Builder adds `DualCursorRuntime` when the scene needs a playable two-player setup. It contains:

- `DualCursorManager`: routes hover, panel entry, activation, denial, and navigation.
- `CursorTravelRegion`: invisible full-viewport movement area.
- `Cursor1` and `Cursor2`: controller-driven cursors.

You can keep this runtime in real game scenes. Replace it only if your game has custom cursor spawning, split-screen-specific cursor regions, or a different input architecture.

## Populate Dialogue Choices

Dialogue choices can be normal `Button` nodes or custom `Control` rows. Add them under a container, store a choice id in metadata, and append each path to the panel's `navigation_targets`.

```gdscript
@export var dialogue_panel: DualCursorNavigationPanel
@export var choices_container: VBoxContainer

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

func _ready() -> void:
	dialogue_panel.target_activated.connect(_on_dialogue_choice_selected)

func _on_dialogue_choice_selected(player_id: int, target: Control, cursor: Node) -> void:
	var choice_id := str(target.get_meta("choice_id", ""))
	choose_dialogue_option(player_id, choice_id)
```

## Overlaps

If controls overlap, increase `hit_priority` on the control that should win.
