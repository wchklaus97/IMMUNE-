# IMMUNE Godot skeleton

Godot 4.3+。編輯器未裝時：`winget install --id GodotEngine.GodotEngine`。

**12 張六基礎 3D 概念已鎖。** 不要重畫。融合／Apex 3D 先不動。  
鎖：`docs/vfx/3d-style-lock.md`  
複本：`characters/concepts/`

## 現在開什麼

主場景：`ui/research/research_network.tscn`  
與 HTML `?cover=1` 同一套研究網絡：全屏星盤、六基礎 3D 立繪、左右家族卡（T/M/N · B/A/D）、底部研究／資源。節點 ID 來自 `immune_catalog.json`。

戰鬥切片：`scenes/combat_lane.tscn`（星盤按 **戰鬥切片** 或 `C`）。一核、一路、T 細胞扎根開火；`R` 研究 `BASE-T-03`／`BASE-T-04`，空白鍵切勤務，A/D 橫向推進。抗體不進這條路。

六基礎塊模仍在 `scenes/kit_lock_preview.tscn`。空白鍵切駐守／移動；A 切中繼。

```powershell
winget install --id GodotEngine.GodotEngine
godot --path godot/immune
godot --headless --path godot/immune --script res://tools/smoke.gd
```

研究星盤：拖曳平移、滾輪縮放、點節點、左欄點家族聚焦。`R` 研究，`F` 追蹤，`Home` 回核心，`Esc` 顯示全圖，`C` 進戰鬥切片。

## Autoloads

- `Catalog` — `resources/catalog/immune_catalog.json`
- `ResearchState` — completed nodes, duty unlocks, demo seed (5/200)
- `VfxLibrary` — `vfx/skills/<ID>.tscn`, `vfx/research/<ID>.tscn`

## 職責契約

同一顆核。`BaseKit`＝駐守裙／短莖。`LocomotionKit`＝螺栓輪／鰭／偽足。A 用 `RelayDish`，禁止 `LocomotionKit`。
