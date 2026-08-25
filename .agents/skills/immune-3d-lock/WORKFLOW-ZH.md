# IMMUNE 3D 角色锁定 — 工作流总览（中文）

从 AI 生成的 GLB，到 Godot 里可玩的湿果冻角色，一共五步。
配合 `gauntlet-loop` 使用：每一步都由独立评审看图判输赢，做的人不能给自己打分。

## 流程图

```
Tripo/Meshy GLB
      ↓
① 入库 & 量基准          → build/shots/t-raw/ + JSON
      ↓
② Blender 修几何         → CHAR-*-fix.glb + ref-crops/
      ↓
③ Godot 湿果冻 shader    → wet_gel.gdshader + t-gel-r*/
      ↓
④ 果冻动画（无骨骼）      → gel_anim.gd + t-anim/
      ↓
⑤ 证据汇总 & 网站展示     → build/gallery/ + 最终集成
```

## 五步分别做什么

### ① 入库 & 量基准
- 把 GLB 复制进 `godot/immune/characters/<家族>/`
- 用 `bl_shots.py` 出 Blender 六角度图 + mesh 数据
- 列出和概念图的差距（孔、鼻、眼、嘴、轮廓、材质）
- **产出：** `CHAR-BASE-T-tripo-5k.glb`，5044 面

### ② Blender 修几何
- 关键：Tripo 的额头孔和眼睛是**独立壳**，只能推顶点，不能布尔/重拓扑
- 修：额头凹孔、去鼻凸、对称眼、干净嘴缝
- 身形（钟形+裙边+钩臂）是单独的 P1b 任务
- **产出：** `CHAR-BASE-T-fix.glb`，7522 面，`build/ref-crops/` 对比图

### ③ Godot 湿果冻材质
- `wet_gel.gdshader` + `gel_look.gd`，颜色来自 `family_look.gd` 调色板
- 五轮迭代教训：过曝 → 薄处不发光 → 太暗 → 太光滑 → 打开凹点颗粒
- 测量工具 `gel_compare.py`：`--zones`（颜色梯度）、`detail`（颗粒感）、`ink`（眼睛）
- **注意：** 颜色统计不够，必须同时看微对比和小高光；游戏场景建议统一 ACES
- **产出：** `build/shots/t-gel-r5/`，`build/r5/strip-front.png`

### ④ 果冻动画
- 不用骨骼、不用形变键，纯节点变换：压扁、拉伸、晃动、回弹
- 八个动作 + relay 开关
- 每个动作出 12 帧 + 合成条 + 脸部可读性条
- **产出：** `build/shots/t-anim/`

### ⑤ 证据 & 集成
- 所有截图进 `build/shots/`，对比条进 `build/r5/`
- 网站：`npm run serve` → http://127.0.0.1:5180/build/gallery/
- 最后把模型+材质+动作合进 `character.tscn`，整体验收

## 怎么调用这些 skill

| 你说的话 | 用的 skill |
| -------- | ---------- |
| 导入 Tripo GLB / 量基准 | `immune-3d-lock` → Phase 1 |
| 修额头孔 / 修眼睛 / Blender 修模型 | Phase 2 |
| 果冻材质 / 塑料感太重 / shader | Phase 3 |
| 做动画 / 果冻晃动 | Phase 4 |
| 开证据网站 / 汇总 build | Phase 5 |
| 一直改到过关 / gauntlet | `gauntlet-loop` + `immune-3d-lock` |

## 文件归属（避免互相踩）

| 谁 | 拥有 |
| -- | ---- |
| P1 几何 | `build/bl_fix_t*.py`，`characters/base_t/*.glb` |
| P2 材质 | `characters/gel/*`，`tools/gel_preview.tscn` |
| P3 动画 | `gel_anim.gd`，`tools/anim_preview.tscn` |
| 共享 | `shot.gd`、`bl_shots.py` — 没有明确要求不要改 |

## 当前 CHAR-BASE-T 状态

| 块 | 状态 |
| -- | ---- |
| 头部几何 P1 | ✅ 通过 |
| 材质 P2 | 🔄 第 5 轮评审中 |
| 身形 P1b | 🔄 进行中 |
| 动画 P3 | ✅ 通过 |
| 集成 P4 | ⏳ 待前三块完成 |

详细证据：http://127.0.0.1:5180/build/gallery/
