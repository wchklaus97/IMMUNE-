# IMMUNE playable demo

目標引擎：**Godot 4.7.2 stable（GDScript / GL Compatibility）**。Windows、Linux、macOS 同 Web 共用同一套 wet-gel shader。

**12 張六基礎 3D 概念已鎖。** 不要重畫。融合／Apex 3D 先不動。  
鎖：`docs/vfx/3d-style-lock.md`  
複本：`characters/concepts/`

## 現在開什麼

主場景：`ui/research/research_network.tscn`  
與 HTML `?cover=1` 同一套研究網絡：全屏星盤、六基礎 3D 立繪、左右家族卡（T/M/N · B/A/D）、底部研究／資源。節點 ID 來自 `immune_catalog.json`。

星盤按 **戰鬥切片** 或 `C` 會開啟任務台。Demo 包含 6 個完整三階段任務（核心防守 → 前線淨化 → Boss 總力戰）同 T/B/M/N/A/D 六個可玩家族。後三關加入低血加速、離火再生同兩者融合；T 有低血處決、B 有連擊標記。`R` 顯示角色情報；T 家族亦可推進 `BASE-T-03`／`BASE-T-04` 研究鏈。空白鍵／手掣 A 切勤務，WASD／左搖桿移動，Esc／Menu 開暫停設定。暫停設定可保存繁體中文／英文、音量、鏡頭震動同減少動態效果。

六基礎塊模仍在 `scenes/kit_lock_preview.tscn`。空白鍵切駐守／移動；A 切中繼。

## Jelly Material V5.1

六個 family 保留各自顏色、輪廓、五官同 duty kit。Production 表面改用一張
checksum-pinned CC0 orange-peel height data texture，以 UV-free object-space
triplanar + mipmap 做淺層濕潤啫喱紋理；舊 procedural circles、quilt rows、
wrinkles、microbubble 同 inclusion relief 唔會再疊加。T/B 使用
Compatibility-safe expanded next pass；M/N/A/D 保留獨立 authored shell，避免
重疊兩層膜。源檔、hash、license 同 deterministic 生成器分別喺
`characters/gel/jelly_micro_height.LICENSE.md` 同
`build/generate_jelly_height.py`。

V5.1 lighting calibration 同 QA contract 只覆蓋 `DirectionalLight3D`：每個
viewport 最多三盞，而且只准一盞開 shadow。Debug scene assertion 同 headed QA
probe 會拒絕 Omni、Spot 同第二盞 shadowed directional light，而 release scene
由靜態 topology ownership 同測試鎖定。
Gameplay 角色 scale、camera 同 collision 不變，左下 own-world portrait 只喺 HUD
有空間時建立；隱藏時會 free 角色並停用 SubViewport 更新。M/N/A/D live 同
portrait 會共用 constructed-once high-density primitive mesh（caller 當 read-only），材料仍然逐 instance
獨立。720x1280 tall mode 會放大 HUD，但唔顯示 portrait。

所有 `res://tools/*.gd`／`.tscn` QA 入口都會喺 autoload 階段自動預留獨立暫存
save；合法 debug `--save-path=` 仍可明確覆寫。壞 save 會原封不動保留，QA 以
exit `74` 停止，唔會將玩家真實進度當測試 fixture 覆寫。

完整 V5.1 texture provenance、shader／lighting 合約、六族＋直向 gameplay、
save isolation、效能同 Web evidence 見
`docs/godot-prompter/specs/2026-08-30-jelly-v5-material-polish.md`；歷史 V3/V4
決策同底層 V2 fallback 保留喺原有文件。

Compatibility renderer 下，細小 mobile duty accessories 會停用 shadow casting，避免 custom gel shadow pass 造成 screen-sized wedge；角色主體仍保留正常陰影。

## V5.2 narrow-phone / safe-area QA

390x844 同 360x800 會使用單欄 Mission、Research、Combat 同 Pause layout；
debug QA 可用實體像素順序 `left,top,right,bottom` 模擬安全區。Android/iOS
production 讀取平台 safe area；Godot 預設 Web shell 冇啟用
`viewport-fit=cover`，所以 browser viewport 本身已係 unobscured area。

```bash
evidence="$PWD/outputs/v5.2-narrow-phone-green"
IMMUNE_QA_SAFE_AREA_INSETS=24,47,24,34 godot \
  --path godot/immune --resolution 390x844 \
  res://tools/mission_select_shot.tscn -- \
  --out="$evidence/mission-390" --locale=zh_HK --tag=green-390
IMMUNE_QA_SAFE_AREA_INSETS=24,47,24,34 godot \
  --path godot/immune --resolution 390x844 \
  res://tools/gameplay_shot.tscn -- \
  --out="$evidence/gameplay-390" --family=B --mission=MISSION-01 \
  --tag=green-390 --locale=zh_HK --portrait-expected=hidden
IMMUNE_QA_SAFE_AREA_INSETS=24,47,24,34 godot \
  --path godot/immune --resolution 390x844 \
  --script res://tools/check_overflow.gd -- \
  --out="$evidence/research-390"
```

三個 harness 都會驗證至少 44 physical-pixel action、14px critical copy、
stacked columns 同 safe margins；Research `--out` 只接受 system temp 或 repo
`outputs/` 之下嘅絕對路徑。完整矩陣同風險邊界見
`docs/godot-prompter/specs/2026-08-31-narrow-phone-safe-area.md`。

```bash
capture_root="$PWD/outputs/v5.1-repro-472"
godot --path godot/immune --resolution 1280x720 res://tools/gameplay_shot.tscn -- \
  --out="$capture_root/gameplay" --family=B --mission=MISSION-01 --tag=B-v51 \
  --portrait-expected=visible
godot --path godot/immune --resolution 1920x1080 res://tools/gel_perf.tscn -- \
  --family=B --material=gel --count=10 --frames=300 --sync=true \
  --out="$capture_root/perf/B-gel.json"
```

`--sync=true` 只會喺量度前 drain 一次 render queue；唔會再由
`frame_post_draw` callback 每 frame `force_sync()`，避免 Forward+／Metal
stall。Apple Metal 如內建 viewport GPU timer 全部回傳零，請用 Instruments
`Metal System Trace` 再以 `tools/analyze_metal_gpu_trace.mjs` 分析；完整命令同
限制見 `docs/godot-prompter/specs/2026-08-29-all-family-soak-and-metal-gpu.md`。

```powershell
winget install --id GodotEngine.GodotEngine --version 4.7.2
godot --path godot/immune
$smokeDir = Join-Path ([System.IO.Path]::GetTempPath()) ("immune-smoke-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $smokeDir | Out-Null
godot --headless --path godot/immune --script res://tools/smoke.gd -- "--save-path=$smokeDir/state.json"
```

本機平衡矩陣使用真實任務場景、physics、projectile 同 FSM；預設 1× 實時 simulation，輸出只留喺指定本機 JSON，唔會上傳 telemetry：

```bash
godot --headless --path godot/immune --script res://tools/balance_matrix.gd -- \
  --out=outputs/playtests/campaign-expansion-candidate-1.json --trials=2
```

Release 前嘅全家族 headed soak 會逐局 checkpoint、首個 contract failure 即停，
並驗證六關時間階梯、總實時長度、p05 FPS 同 wall/game ratio。本機約需 34 分鐘，
所以唔放入 30 分鐘 CI job：

```bash
godot --path godot/immune --rendering-method gl_compatibility \
  --script res://tools/balance_matrix.gd -- \
  --soak --out=outputs/playtests/all-family-campaign-soak.json
```

正式平衡 harness 只接受 `--time-scale=1`；任何加速值都會 fail closed，因為
加速 physics 會改變 projectile collision 同 autopilot 結果，唔可以當作
gameplay-equivalent balance 證據。

完整 6 關 × T/B candidate 1（12 runs）已通過；CI 另外固定跑 MISSION-01 與 MISSION-06 嘅 T/B 四組 bounded regression。結果同調校理由見 `docs/godot-prompter/specs/2026-08-28-immune-campaign-expansion-results.md`。

## Hero 資產管線

M 細胞 hero replacement 已由一次獲批准嘅 Meshy Image-to-3D 任務完成：`meshy-t2` smart topology、8,000 target faces、實際 8,832 triangles、untextured GLB，再由 Godot wet-gel shader 上色。下載檔缺少 normals；本機零-credit smooth-normal 衍生檔保持相同 geometry/bounds，已通過驗證並安裝。預設 runner 仍然只做 dry-run，避免誤重跑已完成任務：

```bash
python3 tools/meshy/run_m_cell_asset.py
python3 tools/meshy/run_m_cell_asset.py --balance-only
python3 tools/meshy/validate_hero_glb.py \
  --project-dir meshy_output/20260828_164806_char-base-m_01a0478d
```

真正生成仍必須同時提供 `--execute --approve-credits 5`；不要為咗重建本地檔而再次執行，原始下載、task metadata 同 smooth derivative 已保留。完整 API、失敗處理、smooth normals、驗證同安裝流程見 `tools/meshy/README.md` 及 `docs/vfx/meshy-api-2026-08-28.md`。

N/A/D 已經用 `characters/authored_jelly_body.gd` 完成零-credit production body，同 demo 嘅 fixed/mobile/relay duty 接通；唔需要 Meshy 先可以玩。三份 Meshy manifest 仍保留作將來逐個 asset 比較，但預設只 dry-run，今次驗證全部係 `network_calls=0 credits=0`。實作同驗收證據見 `docs/godot-prompter/specs/2026-08-29-nad-authored-jelly.md`。

## Release 驗證與匯出

```bash
mkdir -p godot/immune/build/releases/web
node --test tools/validate_release_contract.test.mjs
node tools/validate_release_contract.mjs
godot --headless --path godot/immune --import
smoke_dir="$(mktemp -d)"
godot --headless --path godot/immune --script res://tools/smoke.gd -- --save-path="$smoke_dir/state.json"
godot --headless --path godot/immune --script res://tools/check_overflow.gd
godot --headless --path godot/immune --export-release "Windows Desktop" build/releases/IMMUNE-windows.exe
godot --headless --path godot/immune --export-release "Linux/X11" build/releases/IMMUNE-linux.x86_64
godot --headless --path godot/immune --export-release "macOS" build/releases/IMMUNE-macOS.zip
godot --headless --path godot/immune --export-release "Web" build/releases/web/index.html
node tools/validate_release_contract.mjs --artifacts=godot/immune/build/releases
npm ci --ignore-scripts
npm run test:tools
npm run validate:playtest-template
npm run test:web-release -- \
  --artifacts=godot/immune/build/releases/web \
  --out=outputs/web-release-qa --duration-ms=6000
```

匯出需要安裝 Godot 4.7.2 export templates，四個 exporter 必須順序執行。`build/.gdignore` 會阻止 Godot 將生成成品重新當作 source asset import。GitHub Actions 會自動執行 release identity/tag contract、web tests/build、Godot smoke、首尾關 T/B 平衡回歸、HUD overflow check、四平台匯出、artifact contract，以及 Linux／Windows／macOS 原生成品啟動與 metadata 測試。完整決策同 binary evidence 見 `docs/godot-prompter/specs/2026-08-29-release-identity-hardening.md`。

Web 匯出另外會以真實 Chrome 鍵盤輸入跑研究網絡 → 任務台 → B / MISSION-01
→ mobile duty → 暫停流程，並比較 baseline 同 4× CPU + SwiftShader stress
profile。baseline 只表示冇強制 renderer；hosted CI 仍可能用 SwiftShader。
本機預設係 `local-performance-sentinel` 嚴格 FPS/long-frame gate；GitHub CI
顯式用 `--gate-mode=compatibility-only`，只驗證完整互動、資源、畫面 fit、
error contract 同兩秒 frame watchdog。兩種報告都保留所有 cadence 數字；
呢個證據只代表 compatibility stress，唔係真實低階硬件 benchmark；
完整門檻、失敗證據同六家族匿名真人 playtest template 見
`docs/godot-prompter/specs/2026-08-29-constrained-web-and-human-playtest.md`。

真人測試唔再靠人手配對 binary 同 template。以下命令會由成功 CI artifact
建立一個包含四平台成品、14-file SHA-256 inventory 同六個輪換次序雙語 kit
嘅 campaign；派發前可以重新驗證，任何多餘 debug/private file 都會 fail：

```bash
gh run download 33257048004 \
  -n immune-demo-81a3cbe1a5ba60227bbe0d8c873c55d07871b729 \
  -D outputs/release-ci-33257048004
npm run create:playtest-campaign -- \
  --artifacts=outputs/release-ci-33257048004 \
  --build-commit=81a3cbe1a5ba60227bbe0d8c873c55d07871b729 \
  --source-run=33257048004 \
  --source-artifact=immune-demo-81a3cbe1a5ba60227bbe0d8c873c55d07871b729 \
  --out=outputs/human-playtest-campaigns/immune-v0.4.0-81a3cbe-run-33257048004-portable-v4
npm run create:playtest-campaign -- \
  --verify=outputs/human-playtest-campaigns/immune-v0.4.0-81a3cbe-run-33257048004-portable-v4
cd outputs/human-playtest-campaigns/immune-v0.4.0-81a3cbe-run-33257048004-portable-v4
node facilitator/run_human_playtest_session.mjs --campaign=. \
  --participant=tester-01 --platform=web --open
cd ../../..
node tools/validate_human_playtest.mjs /absolute/path/to/completed-report.json
npm run aggregate:playtests -- \
  --dir=outputs/playtests/human/raw/81a3cbe \
  --out=outputs/playtests/human/aggregate-81a3cbe.json \
  --minimum-participants=3 --require-minimum
```

schema-v2 campaign 會將 portable session runner 同四個驗證依賴一齊 checksum；複製
campaign 後只需 Node.js，唔需要 repo 或 npm install。runner 會先重驗 campaign、
tester 次序、平台入口／sidecar 同 Linux execute bit，再開一個只綁 `127.0.0.1`
嘅 facilitator station；Web 成品會以正確 WASM MIME 由同一 station 提供，native
executable 唔會經 HTTP 服務。最低三位只代表初步可比較樣本，建議六位；synthetic
browser fixture 同 session preflight 都唔係真人證據。完整 facilitator 流程見
`docs/playtesting/README.md`，設計同失敗分析見
`docs/godot-prompter/specs/2026-08-29-verified-facilitator-station.md`。

準備正式 tag 時先做精確版本 preflight；呢個命令唔會建立 tag 或發佈：

```bash
node tools/validate_release_contract.mjs --tag=v0.4.0
```

大型 `.glb`、`.wav`、`.ogg`、`.ttf` 等資產已由 `.gitattributes` 指派到 Git LFS。繁中／英文介面使用 `fonts/NotoSansHK-VF.ttf`，授權文字見 `fonts/OFL.txt`。

研究星盤：拖曳平移、滾輪縮放、點節點、左欄點家族聚焦。`R` 研究，`F` 追蹤，`Home` 回核心，`Esc` 顯示全圖，`C` 進戰鬥切片。

## Autoloads

- `Catalog` — `resources/catalog/immune_catalog.json`
- `ResearchState` — v2 save migration、任務/角色選擇、完成記錄、研究進度
- `SettingsState` — 音量、動態效果、繁中／英文 locale、onboarding、鍵鼠/手掣提示
- `AudioDirector` — 音樂 crossfade 同預載 SFX pool
- `VfxLibrary` — `vfx/skills/<ID>.tscn`, `vfx/research/<ID>.tscn`

## 職責契約

同一顆核。`BaseKit`＝駐守裙／短莖。`LocomotionKit`＝螺栓輪／鰭／偽足。A 用 `RelayDish`，禁止 `LocomotionKit`。
