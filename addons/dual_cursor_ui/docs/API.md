# DualCursor UI API

## DualCursorManager

Routes cursor hover, interaction, scrolling, and deterministic hit priority.

Primary methods:

- `get_interactable_at(global_position, player_id = -1) -> Control`
- `update_hover(cursor, global_position) -> Control`
- `interact(cursor, global_position) -> Control`
- `scroll_at(cursor, global_position, amount) -> void`
- `register_interactable(interactable) -> void`
- `unregister_interactable(interactable) -> void`

## DualCursor

Visible gamepad cursor. Export `player_id`, `region_node_path`, `extra_region_node_paths`, `manager_path`, `interact_action`, and `scroll_axis`.

- `region_node_path`: primary private movement region.
- `extra_region_node_paths`: additional movement regions, commonly shared UI spaces.

## DualCursorInteractable

Base `Control` target. Export `owner_player_id`, `interaction_enabled`, `hit_priority`, and `shared_policy`.

Signals:

- `dual_cursor_hover_started(player_id, cursor)`
- `dual_cursor_hover_ended(player_id, cursor)`
- `dual_cursor_interacted(player_id, cursor)`
- `dual_cursor_denied(player_id, cursor, reason)`
- `dual_cursor_shared_confirmed(player_ids)`

## DualCursorButton

Button-like interactable that emits `pressed_by_player(player_id, cursor)`.

## DualCursorScrollArea

`ScrollContainer` adapter with `dual_cursor_scroll(amount)`.
