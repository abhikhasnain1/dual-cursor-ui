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

## DualCursorDebugOverlay

Optional passive `Control` overlay for debugging player reachability. It draws cursor movement regions and `DualCursorNavigationPanel` capture bounds without affecting input or hit testing.

Primary exports:

- `enabled`: shows or hides the overlay.
- `show_cursor_regions`: draws each cursor's movement regions.
- `show_navigation_panels`: draws navigation panel bounds.
- `show_labels`: draws node/player labels.
- `player_1_color`, `player_2_color`, `shared_color`, `warning_color`: overlay colors.

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

## DualCursorGridNavigationPanel

Grid-based controller-navigation panel for inventories, shops, skill trees, and tactical command menus. It implements the same manager-facing methods and signals as `DualCursorNavigationPanel`, so `target_activated(player_id, target, cursor)` remains the main game-logic signal.

Primary exports:

- `columns`: number of grid columns, minimum `1`.
- `wrap_rows`: whether up/down wraps to the opposite row.
- `wrap_columns`: whether left/right wraps within the current row.
- `skip_disabled_targets`: whether disabled buttons are skipped during navigation.

Left/right moves by one target. Up/down moves by `columns`. Use metadata such as `item_id`, `shop_item_id`, `skill_id`, or `action_id` on targets to route selections into game logic.

## DualCursorDialoguePanel

Dialogue-focused navigation panel that populates choices from dictionaries and emits the selected choice id.

- `set_choices(choices: Array[Dictionary])`: clears existing generated choices and creates new button rows.
- `clear_choices()`: removes generated choices and clears `navigation_targets`.
- Signal: `choice_selected(player_id, choice_id, choice_data, cursor)`.

Choice dictionaries should include `id` and `text`. Extra keys are copied to button metadata so they can also be routed through `DualCursorNarrativeRouter`.

## DualCursorNarrativeRouter

Lightweight router for converting target metadata into one normalized signal. It does not store story state, roll dice, update clocks, or choose branches.

- `route_panel_target(player_id, target, cursor)`: reads metadata from a target and emits `narrative_event`.
- `route_event(player_id, event_type, event_id, payload, cursor)`: emits an explicit narrative event.
- Signal: `narrative_event(player_id, event_type, event_id, payload, cursor)`.

Recognized metadata keys include `choice_id`, `skill_id`, `clock_id`, `inventory_action`, `event_id`, and optional `event_type`.

## DualCursorEventMonitor

Optional testing overlay that logs player-aware runtime events directly inside the scene. It is intended for integration debugging, not as a shipping UI.

Primary exports:

- `enabled`: shows or hides the monitor and controls whether it records events.
- `max_events`: maximum log entries to retain.
- `show_hover_events`, `show_navigation_events`, `show_activation_events`, `show_denial_events`, `show_narrative_events`: event filters.

Primary methods:

- `clear_events()`: removes existing log lines.
- `log_event(message)`: appends a custom message.
- `refresh_bindings()`: reconnects to managers, navigation panels, dialogue panels, and narrative routers in the current scene.

## Control Adapters

Attach these scripts to native Godot controls when a panel needs richer widgets than buttons. They can be free-cursor targets or `navigation_targets` inside list/grid panels.

- `DualCursorToggleAdapter` extends `CheckBox` and emits `toggled_by_player(player_id, pressed, cursor)`.
- `DualCursorSliderAdapter` extends `HSlider` and emits `value_changed_by_player(player_id, value, cursor)`.
- `DualCursorVerticalSliderAdapter` extends `VSlider` and emits `value_changed_by_player(player_id, value, cursor)`.
- `DualCursorSpinBoxAdapter` extends `SpinBox` and emits `value_changed_by_player(player_id, value, cursor)`.
- `DualCursorOptionAdapter` extends `OptionButton` and emits `option_selected_by_player(player_id, index, cursor)`.
- `DualCursorTabAdapter` extends `TabContainer` and emits `tab_changed_by_player(player_id, tab_index, cursor)`.

Adapters export `owner_player_id`, `interaction_enabled`, and `hit_priority`. Slider, spin box, option, and tab adapters consume compatible directional navigation while selected inside a navigation panel. Horizontal adapters consume left/right only, leaving up/down for list navigation.

## Panel Builder

The editor dock can configure a selected `Control` as a list or grid navigation panel. It auto-detects child `BaseButton` controls as `navigation_targets`, applies one of the four access presets, sets theme preset selection colors, adds a lightweight two-player cursor runtime when needed, persists default controller actions, and validates the selected panel. It does not overwrite unrelated custom scripts.

The generated `DualCursorRuntime` contains `DualCursorManager`, an invisible `CursorTravelRegion`, and two `DualCursor` nodes. It is safe to keep in game scenes and customize later.

The dock can also open the all-example-panels demo, apply two-controller profiles, apply theme presets, add or toggle `DualCursorDebugOverlay`, add or toggle `DualCursorEventMonitor`, edit common target metadata, generate wiring snippets for selected nodes, and validate unreachable private/shared navigation panels.
