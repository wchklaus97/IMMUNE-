# IMMUNE Godot 實作架構 v0.1

配套技能：`~/.cursor/skills/godot-immune/SKILL.md`。
專案骨架：`godot/immune/`（編輯器未安裝時仍可當資料夾契約）。

## 6 個基礎套件先鎖

戰鬥 3D 只先做這六套。融合／Apex 立繪未收斂前不要進骨骼。

| 套件 | 角色 | 臉要鎖 | 武器要鎖 | 移動／中繼配件 | 轉換 | 立繪門檻 |
|---|---|---|---|---|---|---|
| `base_t` | T 細胞 | 橘球臉、C 形刺 | 中央炮 | C 刺／偽足螺栓在殼上 | plant／uproot 1–1.5s | 可動作 |
| `base_b` | B 細胞 | 紫藍統一 + 金 Y | Y 分泌口／炮 | 同色鰭或機械腿，兩形態同一套 | 先收立繪再綁骨 | 立繪先收 |
| `base_m` | 巨噬細胞 | 薰衣草臉 | 雙爪 + 紅球 | 觸手扎地 vs 抬起走路 | 同一組根肢 | 可動作 |
| `base_n` | NK 細胞 | 橄欖臉 | **加特林兩形態都在** | 螺栓輪／鰭，炮不卸 | 先補移動稿的炮 | 立繪先收 |
| `base_a` | 抗體構造體 | 金 Y 身體 | 金 Y 炮 | **中繼碟**，無走路骨 | `relay_open` | 可動作（中繼） |
| `base_d` | 樹突細胞 | 橘球 + 主幹樹枝數 | 支援信標／輕炮 | 短根扎地 vs 樹枝漂浮 | 同一組骨 | 可動作 |

環境組織台是關卡 prop，不進 `character.tscn`。

## 資料流

```text
HTML catalog JS  →  immune_catalog.json  →  Catalog autoload
ResearchState.node_completed(id)
    ├─ UI: VfxLibrary.play_research(id)
    └─ flags: duty_unlocked / skill_granted
CharacterRoot 依 flags 顯示 BaseKit 或 LocomotionKit/RelayDish
skill_fired(id) → VfxLibrary.play_skill(id, host, WeaponSocket)
```

## 場景對應

| 路徑 | 內容 |
|---|---|
| `res://autoload/catalog.gd` | JSON 查表 |
| `res://autoload/research_state.gd` | 完成／揭示／協議帶寬 |
| `res://autoload/vfx_library.gd` | ID → PackedScene |
| `res://characters/base_{t,b,m,n,a,d}/` | 核心 + 勤務套件 |
| `res://vfx/skills/<SKILL-ID>.tscn` | 124 技能 |
| `res://vfx/research/<NODE-ID>.tscn` | 200 節點完成脈衝（可共用模板 + 改色） |
| `res://scenes/combat_lane.tscn` | 第一條戰鬥：一核、一路、T 細胞切勤務 |

研究網 HTML 可繼續當選單。Godot 不必第一天重做星盤。

## 共用研究解鎖模板

大多數非戰鬥節點 instance `res://vfx/research/_unlock_pulse.tscn`，用家族色 `ShaderMaterial` 參數。
`BASE-*-03/04` 額外觸發角色 AnimationPlayer，不是另一套身體。

## 第一條戰鬥切片（kits 之後）

1. 放 T 固定炮台（BaseKit）。
2. 一條細菌路線走向核心。
3. 解鎖 `BASE-T-04` 後 uproot，T 加入橫向推進。
4. 抗體不加入移動軍團。

## ID 綁定原則

檔名、`StringName`、catalog `id` 三者相同。缺檔就 `push_error`，不准默默改播隔壁技能。
