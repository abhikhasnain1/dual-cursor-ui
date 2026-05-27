# Asset Library Notes

Package only the `addons/dual_cursor_ui` folder when submitting the addon.

Suggested listing:

- Name: DualCursor UI
- Category: Tools
- License: MIT
- Godot version: 4.6+
- Description: Local multiplayer cursor interaction, list/grid controller-navigation panels, region debugging, and theme presets for Godot Control-based interfaces.

Do not describe this addon as native multifocus. It is a custom local multiplayer interaction layer over `Control` nodes.

## Pre-Submission Checklist

- Enable the plugin in a clean Godot 4.6+ project.
- Confirm custom nodes appear in Add Node.
- Confirm the DualCursor UI dock appears.
- Run Create Playable 2-Player Scene in a blank scene.
- Confirm both cursors can reach the shared exclusive and shared simultaneous panels.
- In a clean scene, create a `Control` or `HBoxContainer` with child `Button` nodes, run Panel Builder, and confirm the generated runtime, controller actions, panel entry, and `target_activated` path work.
- Toggle the debug overlay and confirm it draws cursor movement regions and navigation panel capture bounds.
- Apply each controller profile and theme preset at least once.
- Build and validate a Grid Panel with three or four columns.
- Run Validate Current Scene.
- Run the created responsive template scene.
- Include README, LICENSE, docs, and demo scene.
- Use a square PNG/JPG icon for the Asset Library listing.
- Use direct raw GitHub image URLs for the icon and screenshots:
  `https://raw.githubusercontent.com/abhikhasnain1/dual-cursor-ui/v0.5.0/asset-library/icon.png`
- Use matching raw screenshot URLs:
  `https://raw.githubusercontent.com/abhikhasnain1/dual-cursor-ui/v0.5.0/asset-library/full1.png`
- Confirm the download archive does not include `.godot`, `.gitignore`, `.gitattributes`, root README/LICENSE, or `asset-library`.
