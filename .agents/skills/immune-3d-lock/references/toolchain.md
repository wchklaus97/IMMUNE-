# Toolchain

Verified on Windows for this repo.

## Blender 5.2 (Microsoft Store)

- Direct `blender.exe` → Access denied. Use launcher.
- Launcher **detaches** from shell; write output to a file and poll it.

```powershell
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe" `
  --background --factory-startup --python <script.py> -- <args>
```

GUI compare (two GLBs side by side):

```powershell
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe" `
  --python build/bl_open_compare.py
```

## Godot 4.7.1 Forward+

```powershell
$GODOT = "$env:LOCALAPPDATA\Microsoft\WinGet\Links\godot_console.exe"
$PROJ  = "godot/immune"

# Import after adding GLBs
& $GODOT --path $PROJ --headless --import

# Render harness — MUST have a real window; --headless gives no pixels
Get-Process -Name godot* -ErrorAction SilentlyContinue | Stop-Process -Force
& $GODOT --path $PROJ --resolution 1024x1024 --position 60,60 `
  res://tools/shot.tscn -- --scene=<res://...> --out=<abs dir> --tag=<name>
```

## Evidence scripts

| Script | Role |
| ------ | ---- |
| `build/bl_shots.py` | Blender: import GLB, mesh JSON, 7 review angles |
| `godot/immune/tools/shot.gd` | Godot: 6 angles + optional anim strips |
| `build/gel_compare.py` | Pixel metrics: `--zones`, `--detail`, `--ink` |
| `build/bl_fix_t.py` | Geometry fix pipeline |
| `build/anim_sheet.py` | Compose animation SHEET PNGs |

## ACES integration note

Material exposure (`BODY_HUE_SHIFT`, `albedo_gain`, `body_budget`) was
calibrated through the shot harness tonemapper. Game scenes should adopt ACES
tonemapping (`Environment.tonemap_mode`) rather than refitting shader uniforms
for a linear pipeline.

## Gallery server

```powershell
npm run serve
# http://127.0.0.1:5180/build/gallery/
```
