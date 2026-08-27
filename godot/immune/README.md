# IMMUNE playable demo

目標引擎：**Godot 4.7.2 stable（Standard / GDScript）**。專案使用 GL Compatibility，Windows、Linux 同 Web 共用同一套 wet-gel shader。

**12 張六基礎 3D 概念已鎖。** 不要重畫。融合／Apex 3D 先不動。  
鎖：`docs/vfx/3d-style-lock.md`  
複本：`characters/concepts/`

## 現在開什麼

主場景：`ui/research/research_network.tscn`  
與 HTML `?cover=1` 同一套研究網絡：全屏星盤、六基礎 3D 立繪、左右家族卡（T/M/N · B/A/D）、底部研究／資源。節點 ID 來自 `immune_catalog.json`。

星盤按 **戰鬥切片** 或 `C` 會開啟任務台。Demo 包含 3 個完整三階段任務（核心防守 → 前線淨化 → Boss 總力戰）同 T/B/M/N/A/D 六個可玩家族。`R` 顯示角色情報；T 家族亦可推進 `BASE-T-03`／`BASE-T-04` 研究鏈。空白鍵／手掣 A 切勤務，WASD／左搖桿移動，Esc／Menu 開暫停設定。

六基礎塊模仍在 `scenes/kit_lock_preview.tscn`。空白鍵切駐守／移動；A 切中繼。

```powershell
winget install --id GodotEngine.GodotEngine --version 4.7.2
godot --path godot/immune
godot --headless --path godot/immune --script res://tools/smoke.gd
```

## Release 驗證與匯出

```bash
mkdir -p godot/immune/build/releases/web
godot --headless --path godot/immune --import
godot --headless --path godot/immune --script res://tools/smoke.gd
godot --headless --path godot/immune --script res://tools/check_overflow.gd
godot --headless --path godot/immune --export-release "Windows Desktop" build/releases/IMMUNE-windows.exe
godot --headless --path godot/immune --export-release "Linux/X11" build/releases/IMMUNE-linux.x86_64
godot --headless --path godot/immune --export-release "macOS" build/releases/IMMUNE-macOS.zip
godot --headless --path godot/immune --export-release "Web" build/releases/web/index.html
```

匯出需要安裝 Godot 4.7.2 export templates。GitHub Actions 會自動執行 web tests/build、Godot smoke、HUD overflow check、四平台匯出，以及 Linux／Windows／macOS 原生成品啟動測試。大型 `.glb`、`.wav`、`.ogg`、`.ttf` 等資產已由 `.gitattributes` 指派到 Git LFS。繁中介面使用 `fonts/NotoSansHK-VF.ttf`，授權文字見 `fonts/OFL.txt`。

研究星盤：拖曳平移、滾輪縮放、點節點、左欄點家族聚焦。`R` 研究，`F` 追蹤，`Home` 回核心，`Esc` 顯示全圖，`C` 進戰鬥切片。

## Autoloads

- `Catalog` — `resources/catalog/immune_catalog.json`
- `ResearchState` — v2 save migration、任務/角色選擇、完成記錄、研究進度
- `SettingsState` — 音量、動態效果、onboarding、鍵鼠/手掣提示
- `AudioDirector` — 音樂 crossfade 同預載 SFX pool
- `VfxLibrary` — `vfx/skills/<ID>.tscn`, `vfx/research/<ID>.tscn`

## 職責契約

同一顆核。`BaseKit`＝駐守裙／短莖。`LocomotionKit`＝螺栓輪／鰭／偽足。A 用 `RelayDish`，禁止 `LocomotionKit`。
