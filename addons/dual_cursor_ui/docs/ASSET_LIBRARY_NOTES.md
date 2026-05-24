# Asset Library Notes

Package only the `addons/dual_cursor_ui` folder when submitting the addon.

Suggested listing:

- Name: DualCursor UI
- Category: Tools
- License: MIT
- Godot version: 4.6+
- Description: Local multiplayer cursor interaction for Godot Control-based interfaces.

Do not describe this addon as native multifocus. It is a custom local multiplayer interaction layer over `Control` nodes.

## Pre-Submission Checklist

- Enable the plugin in a clean Godot 4.6+ project.
- Confirm custom nodes appear in Add Node.
- Confirm the DualCursor UI dock appears.
- Run Create Playable 2-Player Scene in a blank scene.
- Confirm both cursors can reach the shared exclusive and shared simultaneous panels.
- Run Validate Current Scene.
- Run the created responsive template scene.
- Include README, LICENSE, docs, and demo scene.
- Use a square PNG/JPG icon for the Asset Library listing.
- Use direct raw GitHub image URLs for the icon and screenshots:
  `https://raw.githubusercontent.com/abhikhasnain1/dual-cursor-ui/v0.3.0/asset-library/dual_cursor_icon.png`
- Use matching raw screenshot URLs:
  `https://raw.githubusercontent.com/abhikhasnain1/dual-cursor-ui/v0.3.0/asset-library/5.png`
- Confirm the download archive does not include `.godot`, `.gitignore`, `.gitattributes`, root README/LICENSE, or `asset-library`.
