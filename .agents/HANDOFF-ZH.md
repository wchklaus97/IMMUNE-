# Codex 交接 — CHAR-BASE-T 3D 锁定（中文速览）

**英文完整版：** [.agents/HANDOFF.md](../HANDOFF.md)

## 你要继续做什么

把橙色基础角色 `CHAR-BASE-T` 做到和概念图一致，并能进 Godot 战斗场景使用。

概念图：`godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png`

## 给 Codex 的第一句话（复制粘贴）

```
Continue CHAR-BASE-T 3D lock from .agents/HANDOFF.md.
Use gauntlet-loop + immune-3d-lock.
Priority: (1) finish P2 material r5 critic if missing,
(2) P1b silhouette, (3) P4 integrate mesh+gel+anim into character.tscn.
Do not regenerate Tripo mesh from scratch.
```

## 已完成 ✅

| 块 | 说明 |
| -- | ---- |
| 头部几何 P1 | 额头凹孔、去鼻凸、眼对称、嘴缝 — 评审通过 |
| 动画 P3 | 8 个动作，无骨骼，孔可读 — 评审通过 |
| 工具链 | Blender/Godot 截图、像素测量、证据网站、skill 文档 |

## 未完成 ❌（Codex 优先做）

| 优先级 | 块 | 说明 |
| ------ | -- | ---- |
| 1 | 材质 P2 | 第 5 轮已做，评审可能未完成；前 4 轮全败 |
| 2 | 身形 P1b | 钟形+波浪裙边+钩臂 — 未做 |
| 3 | 集成 P4 | `character.tscn` 还是球体占位，游戏场景未接果冻材质 |

## 关键文件

- 模型：`godot/immune/characters/base_t/CHAR-BASE-T-fix.glb`
- Shader：`godot/immune/characters/gel/wet_gel.gdshader`
- 动画：`godot/immune/characters/gel_anim.gd`
- 证据网站：`npm run serve` → http://127.0.0.1:5180/build/gallery/

## 必读文档

1. `.agents/HANDOFF.md` — 完整交接
2. `gauntlet-workbench.md` — 迭代日志
3. `.agents/skills/immune-3d-lock/` — 五步工作流

## 铁律

- 用 `gauntlet-loop`：做的人不能给自己打分
- Tripo 额头孔/眼睛是**独立壳**，只能推顶点，不能布尔
- 材质颜色统计不够，必须测微对比 + 小高光
- 游戏场景建议统一 **ACES** 色调映射
