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
3. Click **Create 2-Player Setup**. The dock creates Player1Region, Player2Region, and SharedRegion.
4. Click **Set Up Controller Actions**. This creates `interact_p1` and `interact_p2` in the project Input Map.
5. Click **Validate Current Scene**.
6. Save and run the scene with two controllers connected.
7. Move each cursor with the matching controller's left stick.
8. Press A/Cross to activate a button.
9. Use the **Use In Your Game** section in the dock for copyable GDScript examples.

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

Shared controls still need to be inside a movement region that every intended player can reach. The generated scene uses `SharedRegion`, and both cursors list it in `extra_region_node_paths`.

If validation says a shared control is outside all cursor regions, move the control into the shared region or add that region to the cursor's `extra_region_node_paths`.

## Movement Regions

- `region_node_path`: the cursor's private home region.
- `extra_region_node_paths`: shared or extra regions that cursor may also enter.

Keep player-owned controls inside that player's private region. Put shared controls inside a shared region assigned to both cursors.

## Overlaps

If controls overlap, increase `hit_priority` on the control that should win.
