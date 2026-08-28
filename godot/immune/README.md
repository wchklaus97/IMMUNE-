# IMMUNE playable demo

目標引擎：**Godot 4.7.2 stable（Standard / GDScript）**。專案使用 GL Compatibility，Windows、Linux 同 Web 共用同一套 wet-gel shader。

**12 張六基礎 3D 概念已鎖。** 不要重畫。融合／Apex 3D 先不動。  
鎖：`docs/vfx/3d-style-lock.md`  
複本：`characters/concepts/`

## 現在開什麼

主場景：`ui/research/research_network.tscn`  
與 HTML `?cover=1` 同一套研究網絡：全屏星盤、六基礎 3D 立繪、左右家族卡（T/M/N · B/A/D）、底部研究／資源。節點 ID 來自 `immune_catalog.json`。

星盤按 **戰鬥切片** 或 `C` 會開啟任務台。Demo 包含 6 個完整三階段任務（核心防守 → 前線淨化 → Boss 總力戰）同 T/B/M/N/A/D 六個可玩家族。後三關加入低血加速、離火再生同兩者融合；T 有低血處決、B 有連擊標記。`R` 顯示角色情報；T 家族亦可推進 `BASE-T-03`／`BASE-T-04` 研究鏈。空白鍵／手掣 A 切勤務，WASD／左搖桿移動，Esc／Menu 開暫停設定。暫停設定可保存繁體中文／英文、音量、鏡頭震動同減少動態效果。

六基礎塊模仍在 `scenes/kit_lock_preview.tscn`。空白鍵切駐守／移動；A 切中繼。

## Jelly Material V2

B 細胞使用集中式 `round_bubbles` profile；新 M Meshy 雕模使用較淡薰衣草色嘅 `macrophage_bubbles` profile。兩者都有 UV-free object-space 圓泡、較短吸收路徑、淺層 wet-coat 高光，並關閉會放大低面數法線嘅 directional dimple。T 維持 `authored_membrane` profile；N/A/D 安全關閉泡泡。完整設計、效能結果同 fallback 見 `docs/vfx/jelly-material-v2.md`。

Compatibility renderer 下，細小 mobile duty accessories 會停用 shadow casting，避免 custom gel shadow pass 造成 screen-sized wedge；角色主體仍保留正常陰影。

```bash
godot --path godot/immune --resolution 1920x1080 res://tools/gameplay_shot.tscn -- \
  --out=/absolute/output/path --family=B --mission=MISSION-01 --tag=B-v2
godot --path godot/immune --resolution 1920x1080 res://tools/gel_perf.tscn -- \
  --family=B --material=gel --count=10 --frames=300 --sync=true
```

```powershell
winget install --id GodotEngine.GodotEngine --version 4.7.2
godot --path godot/immune
godot --headless --path godot/immune --script res://tools/smoke.gd
```

本機平衡矩陣使用真實任務場景、physics、projectile 同 FSM；預設 1× 實時 simulation，輸出只留喺指定本機 JSON，唔會上傳 telemetry：

```bash
godot --headless --path godot/immune --script res://tools/balance_matrix.gd -- \
  --out=outputs/playtests/campaign-expansion-candidate-1.json --trials=2
```

調校時不要提高 `--time-scale`；加速 physics 可能令細 projectile tunnelling，只適合診斷流程，唔適合作 balance 證據。

完整 6 關 × T/B candidate 1（12 runs）已通過；CI 另外固定跑 MISSION-01 與 MISSION-06 嘅 T/B 四組 bounded regression。結果同調校理由見 `docs/godot-prompter/specs/2026-08-28-immune-campaign-expansion-results.md`。

## Meshy hero 資產管線

M 細胞 hero replacement 已由一次獲批准嘅 Meshy Image-to-3D 任務完成：`meshy-t2` smart topology、8,000 target faces、實際 8,832 triangles、untextured GLB，再由 Godot wet-gel shader 上色。下載檔缺少 normals；本機零-credit smooth-normal 衍生檔保持相同 geometry/bounds，已通過驗證並安裝。預設 runner 仍然只做 dry-run，避免誤重跑已完成任務：

```bash
python3 tools/meshy/run_m_cell_asset.py
python3 tools/meshy/run_m_cell_asset.py --balance-only
python3 tools/meshy/validate_hero_glb.py \
  --project-dir meshy_output/20260828_164806_char-base-m_01a0478d
```

真正生成仍必須同時提供 `--execute --approve-credits 5`；不要為咗重建本地檔而再次執行，原始下載、task metadata 同 smooth derivative 已保留。完整 API、失敗處理、smooth normals、驗證同安裝流程見 `tools/meshy/README.md` 及 `docs/vfx/meshy-api-2026-08-28.md`。

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

匯出需要安裝 Godot 4.7.2 export templates。GitHub Actions 會自動執行 web tests/build、Godot smoke、首尾關 T/B 平衡回歸、HUD overflow check、四平台匯出，以及 Linux／Windows／macOS 原生成品啟動測試。大型 `.glb`、`.wav`、`.ogg`、`.ttf` 等資產已由 `.gitattributes` 指派到 Git LFS。繁中／英文介面使用 `fonts/NotoSansHK-VF.ttf`，授權文字見 `fonts/OFL.txt`。

研究星盤：拖曳平移、滾輪縮放、點節點、左欄點家族聚焦。`R` 研究，`F` 追蹤，`Home` 回核心，`Esc` 顯示全圖，`C` 進戰鬥切片。

## Autoloads

- `Catalog` — `resources/catalog/immune_catalog.json`
- `ResearchState` — v2 save migration、任務/角色選擇、完成記錄、研究進度
- `SettingsState` — 音量、動態效果、繁中／英文 locale、onboarding、鍵鼠/手掣提示
- `AudioDirector` — 音樂 crossfade 同預載 SFX pool
- `VfxLibrary` — `vfx/skills/<ID>.tscn`, `vfx/research/<ID>.tscn`

## 職責契約

同一顆核。`BaseKit`＝駐守裙／短莖。`LocomotionKit`＝螺栓輪／鰭／偽足。A 用 `RelayDish`，禁止 `LocomotionKit`。
