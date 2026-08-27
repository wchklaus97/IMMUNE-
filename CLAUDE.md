# IMMUNE project guidance

## GodotPrompter

- Engine target: Godot 4.7.2, GDScript, GL Compatibility renderer.
- Use the Input Map for player controls; do not add raw keycode checks.
- Gameplay UI belongs under `CanvasLayer` and must remain usable at 1920x1080 and smaller desktop windows.
- Persistent progress is versioned JSON under `user://`; failed loads must fall back to a safe demo seed.
- Catalog IDs are canonical. Do not invent research, character, skill, or defense IDs.
- A character has one body whose duty kit transforms between fixed and mobile/relay states.
- Verify changes with the web test/build commands and Godot headless smoke test documented in `CODEX_HANDOFF.md`.
