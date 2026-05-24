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

## Connect A Button

Select a `DualCursorButton`, open the Node dock, and connect:

```text
pressed_by_player(player_id, cursor)
```

Example handler:

```gdscript
func _on_pressed_by_player(player_id: int, cursor: Node) -> void:
	print("Player %d selected this button." % player_id)
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

## Convert Your Own Menu Panel

1. Build a normal Godot `Control` panel with child buttons.
2. Select the panel node in the Scene dock.
3. In the DualCursor UI dock, choose a Panel Builder preset: Player 1 Private, Player 2 Private, Shared Exclusive, or Shared Simultaneous.
4. Click **Setup Selected Panel**. The builder also adds two cursors and a manager if the scene does not already have them.
5. Click **Validate Selected Panel**.
6. Run the scene, move a cursor into the panel, navigate with the left stick, activate with A/Cross, and exit with B/Circle.

Panel Builder will not overwrite a custom script. Use a plain `Control` node or an existing `DualCursorNavigationPanel`.

## Overlaps

If controls overlap, increase `hit_priority` on the control that should win.
