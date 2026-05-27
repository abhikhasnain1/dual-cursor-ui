# Scene Validation

The **DualCursor UI** dock includes a validator for common setup mistakes.

It checks:

- Missing `DualCursorManager`.
- Missing `DualCursor` nodes.
- Invalid cursor `manager_path`.
- Invalid cursor `region_node_path`.
- Invalid cursor `extra_region_node_paths`.
- Missing interact actions.
- Missing interactables.
- Zero-sized interactable rects.
- Hidden interactables.
- Overlapping interactables with the same `hit_priority`.
- Shared controls outside cursor movement regions.
- Player-owned controls reachable by the wrong player's cursor.
- Navigation panels with missing or invalid `navigation_targets`.
- Navigation panels outside all cursor movement regions.
- Private navigation panels unreachable by their owning player.
- Shared simultaneous panels not reachable by both players.
- Overlapping navigation panels with the same `hit_priority`.
- Missing cancel actions used to leave controller-navigation panels.
- Navigation panels with private, exclusive shared, or simultaneous shared access policies.

Warnings are not always fatal. For example, a cursor without `manager_path` can still find a manager through the `dual_cursor_manager` group. Errors should be fixed before publishing a game scene.
