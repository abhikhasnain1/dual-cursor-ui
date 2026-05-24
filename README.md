# DualCursor UI

DualCursor UI is a Godot 4.6+ addon for local multiplayer cursor interaction over `Control`-based interfaces.

It is designed for split-screen and co-op games where multiple local players need independent virtual cursors in the same UI layer. It does not replace Godot's native `Control` focus system. Instead, it provides a custom routing layer for hover, selection, denial feedback, shared controls, and scroll areas.

## What You Can Build

- Two-player menus.
- Split-screen dialogue choice panels.
- Shared confirmation prompts.
- Dice, card, inventory, or map interfaces.
- Co-op UI where each player can point at a different `Control` at the same time.

## Quick Start

1. Copy `addons/dual_cursor_ui` into a Godot project.
2. Enable **DualCursor UI** in Project Settings > Plugins.
3. Open the **DualCursor UI** dock.
4. Click **Create Playable 2-Player Scene** in a blank scene. This creates a playable template with private menu panels, private dialogue choices, exclusive shared panels, simultaneous shared panels, cursors, logging, and controller actions.
5. Click **Validate Current Scene**.
6. Press Play. Move player 1 with controller 1's left stick and player 2 with controller 2's left stick.
7. For your own UI, select a `Control` panel and use **Panel Builder** to configure controller navigation.
8. Connect `DualCursorButton.pressed_by_player(player_id, cursor)` or `DualCursorNavigationPanel.target_activated(player_id, target, cursor)` to your game logic.

The fastest way to see the plugin working is to open:

```text
res://addons/dual_cursor_ui/demos/two_player_menu_demo.tscn
```

For copyable programming examples, open the **Use In Your Game** section in the editor dock or read:

```text
res://addons/dual_cursor_ui/docs/WALKTHROUGHS.md
```

## Core Nodes

- `DualCursorManager`: routes hover, interaction, hit priority, and scroll behavior.
- `DualCursor`: visible gamepad-controlled cursor.
- `DualCursorInteractable`: base `Control` target with ownership and shared policies.
- `DualCursorButton`: button-like interactable with hover/select/deny feedback.
- `DualCursorScrollArea`: `ScrollContainer` adapter for joystick scrolling.
- `DualCursorNavigationPanel`: captures a cursor inside a panel and switches that player to ordered controller navigation, with private, exclusive shared, or simultaneous shared access.

## Shared Policies

- `ALLOW_ANY`: any player can activate the shared control.
- `FIRST_PLAYER_LOCKS`: first interacting player locks the control.
- `REQUIRE_ALL_PLAYERS`: all required players must confirm.
- `DENY_IF_OWNED`: denies interaction when the target is player-owned.

## Editor Dock

The plugin adds a **DualCursor UI** dock to the editor. It can:

- Create a ready-to-edit responsive two-player template scene.
- Configure selected `Control` nodes as controller-navigation panels.
- Set up default controller actions as part of scene creation.
- Validate common scene setup mistakes.
- Explain the next integration step for a new user.

## Common Signal

Most games start by connecting:

```gdscript
func _on_button_pressed_by_player(player_id: int, cursor: Node) -> void:
	print("Player %d pressed this control." % player_id)
```

Use `owner_player_id = 0` for player 1, `owner_player_id = 1` for player 2, and `owner_player_id = -1` for shared controls.

More examples are available in `docs/WALKTHROUGHS.md`, including ownership setup and shared confirmation.

## Movement Regions

Each `DualCursor` moves only inside its assigned Control regions:

- `region_node_path`: the cursor's private home region.
- `extra_region_node_paths`: additional allowed regions, usually shared UI areas.

For a two-player setup, player 1 should use Player1Region plus SharedRegion, and player 2 should use Player2Region plus SharedRegion. Do not give both cursors one large play area unless both players are meant to reach every control in it.

## Controller Actions

DualCursor uses Godot Input Map actions to know when each player selects a control. The setup dock creates:

- `interact_p1`: controller 1, A/Cross.
- `interact_p2`: controller 2, A/Cross.
- `cancel_p1`: controller 1, B/Circle.
- `cancel_p2`: controller 2, B/Circle.

You can change these later in Project Settings > Input Map.

## Navigation Panels

Use `DualCursorNavigationPanel` for dense menus where free cursor movement is too awkward. When a cursor enters the panel, that player is captured into virtual focus and navigates the configured `navigation_targets` with the controller. Press the cursor's `cancel_action` to return to free cursor movement.

Set `owner_player_id` for player-only panels, or set `occupancy_policy` to `FIRST_PLAYER_LOCKS` for a shared panel that only one player can use at a time. The demo event log shows which player entered, exited, was denied, and activated each target first.

## Panel Builder

Select a `Control` node in your scene, choose one of the four access presets in the dock, then click **Setup Selected Panel**. The dock assigns `DualCursorNavigationPanel`, auto-detects child buttons as navigation targets, applies the preset, and validates the panel. The builder uses Player 1 Private, Player 2 Private, Shared Exclusive, and Shared Simultaneous presets.

## Limitations

DualCursor UI does not make every existing Godot `Control` automatically multifocus-aware. Complex widgets should use one of the addon nodes or an adapter script that forwards DualCursor signals into the widget's own behavior.
