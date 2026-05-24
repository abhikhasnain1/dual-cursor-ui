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

Visible gamepad cursor. Export `player_id`, `region_node_path`, `extra_region_node_paths`, `manager_path`, `interact_action`, `cancel_action`, and `scroll_axis`.

- `region_node_path`: primary private movement region.
- `extra_region_node_paths`: additional movement regions, commonly shared UI spaces.
- `center_on_primary_region_at_ready`: when true, the cursor starts at the center of its primary movement region. Panel Builder disables this for generated cursors so they can start near the configured panel.

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

## DualCursorNavigationPanel

Controller-navigation zone for places where free cursor movement feels awkward. Add target controls to `navigation_targets`. When a cursor enters the panel, that player is captured into virtual focus, the cursor sprite is hidden, and left-stick navigation moves through the configured targets.

Primary exports:

- `navigation_targets`: ordered `Control` targets to navigate.
- `owner_player_id`: `-1` for shared, or a player id for private panel navigation.
- `occupancy_policy`: `ALLOW_MULTIPLE` for simultaneous use, or `FIRST_PLAYER_LOCKS` for one player at a time.
- `wrap_navigation`: whether moving past the end wraps around.
- `navigation_deadzone`, `repeat_delay`, `repeat_interval`: stick navigation tuning.

Activation priority:

1. Target method `dual_cursor_activate(player_id, cursor)`.
2. Target method `on_cursor_interact(cursor)`.
3. Normal Godot `BaseButton.pressed`.
After any activation path, the panel emits `target_activated(player_id, target, cursor)` and the manager emits `navigation_target_activated(player_id, panel, target)`.

Entry denial is available through manager signal `navigation_denied(player_id, panel, reason)`.

## Panel Builder

The editor dock can configure a selected `Control` as a `DualCursorNavigationPanel`. It auto-detects child `BaseButton` controls as `navigation_targets`, applies one of the four access presets, sets default selection colors, adds a lightweight two-player cursor runtime when needed, persists default controller actions, and validates the selected panel. It does not overwrite unrelated custom scripts.

The generated `DualCursorRuntime` contains `DualCursorManager`, an invisible `CursorTravelRegion`, and two `DualCursor` nodes. It is safe to keep in game scenes and customize later.
