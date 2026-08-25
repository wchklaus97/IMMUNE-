#!/usr/bin/env node
/**
 * Builds docs/vfx/*.md from the live IMMUNE catalog. Does not invent IDs.
 */
import { mkdir, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { readFileSync } from "node:fs";
import vm from "node:vm";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const UI = resolve(__dirname, "..");
const REPO = resolve(UI, "../..");
const OUT = join(REPO, "docs/vfx");

function loadIife(rel, immune) {
  const src = readFileSync(join(UI, rel), "utf8");
  const sandbox = { console };
  sandbox.IMMUNE = immune || sandbox.IMMUNE;
  vm.createContext(sandbox);
  sandbox.globalThis = sandbox;
  sandbox.global = sandbox;
  vm.runInContext(src, sandbox, { filename: rel });
  return sandbox.IMMUNE;
}

const defsMod = loadIife("src/catalog/definitions.js");
const buildMod = loadIife("src/catalog/build-catalog.js", defsMod);
const assetsMod = loadIife("src/assets/game-assets.js", { ...defsMod, ...buildMod });

const IMMUNE = { ...defsMod, ...buildMod, ...assetsMod };
const catalog = IMMUNE.buildCatalog();
const characters = IMMUNE.gameAssets.characters;

const FAMILY = {
  T: { color: "orange #ff8a3d", lock: "橘球臉、中央炮、C 形刺", vfx: "橙細胞毒刃光、短刃軌跡" },
  B: { color: "purple/blue #8b6cff + gold Y", lock: "主色統一 + Y 標", vfx: "紫藍漿液與金色 Y 抗體" },
  M: { color: "lavender #c9a0ff", lock: "紫球臉、雙爪、口中紅球", vfx: "薰衣草吞噬膜、紅吞噬體" },
  N: { color: "olive #8fb03a + gatling", lock: "加特林兩形態都在", vfx: "橄欖曳光彈、靜默白閃" },
  A: { color: "gold Y #f2b84b", lock: "金 Y 身體、中繼碟", vfx: "金色 Y 彈群、導引光束" },
  D: { color: "orange dendrites #ff9b58", lock: "橘球、主幹樹枝", vfx: "樹突掃描弧、信標柱" }
};

const SLOT_ZH = {
  passive: "passive",
  active: "active",
  fixed: "fixed",
  apex: "apex",
  protocol: "protocol"
};

function famOf(ids) {
  if (!ids?.length) return "—";
  return ids.join("+");
}

function famMeta(ids) {
  const f = ids?.[0];
  return FAMILY[f] || { color: "cyan #45bdf2", lock: "家族色", vfx: "家族色脈衝" };
}

function skillKind(slot, id) {
  if (slot === "passive") return "aura";
  if (slot === "fixed") return "duty_kit";
  if (slot === "protocol") return "ui_ping";
  if (id.includes("APEX") || id.endsWith("-ULT")) return "area";
  return "projectile";
}

function skillGameplay(skill, char) {
  const slot = skill.slot;
  const name = skill.name;
  const role = char?.role || "";
  if (slot === "passive") return `常駐被動：${name}。強化 ${char?.name || "該角色"}（${role}）的基礎戰鬥行為。`;
  if (slot === "active") return `主動技：${name}。玩家或 AI 觸發的一次戰鬥行動。`;
  if (slot === "fixed") return `固定炮台勤務技：${name}。僅在 BaseKit 展開時作為防線輸出。`;
  if (slot === "apex") return `終極／Apex：${name}。高可讀性大招，需對應研究解鎖。`;
  if (slot === "protocol") return `研究協議：${name}。關卡前裝備才生效，不佔角色主動欄。`;
  return name;
}

function skillIcon(skill, char) {
  const f = char?.families?.[0];
  const m = famMeta(char?.families);
  const extra = {
    "SKILL-T-PASSIVE": "橘球細胞握一柄發光細胞毒短刃，C 形刺當護甲",
    "SKILL-T-ACTIVE": "橘球從中央炮射出單點處決光束，目標被刺穿",
    "SKILL-T-FIXED": "橘球扎根成炮台，中央炮朝前，無組織台",
    "SKILL-T-APEX": "橘球爆發細胞毒光環，刃與炮同時亮起",
    "SKILL-B-PASSIVE": "紫藍細胞表面冒出金色 Y 形抗體",
    "SKILL-B-ACTIVE": "紫藍細胞核心亮起記憶結晶，Y 標放大",
    "SKILL-B-FIXED": "紫藍生產炮台，炮口噴出金色 Y 彈",
    "SKILL-B-APEX": "漿細胞形態，金色 Y 風暴環繞",
    "SKILL-M-PASSIVE": "薰衣草球雙爪抓住一顆紅吞噬球",
    "SKILL-M-ACTIVE": "薰衣草消化爐大口，紅球在爐心",
    "SKILL-M-FIXED": "厚實薰衣草坦克炮台，爪收在炮側",
    "SKILL-M-APEX": "巨大吞噬膜包住敵人剪影（非組織台）",
    "SKILL-N-PASSIVE": "橄欖球加特林連射截擊曳光",
    "SKILL-N-ACTIVE": "橄欖球靜默一擊，加特林有消音閃",
    "SKILL-N-FIXED": "橄欖刺殺炮台，加特林必須可見",
    "SKILL-N-APEX": "加特林全管過熱的終極截擊",
    "SKILL-A-PASSIVE": "金色 Y 身體在目標上打一個弱點標記",
    "SKILL-A-ACTIVE": "金 Y 導引光束指向遠方炮口",
    "SKILL-A-FIXED": "金 Y 坐在中繼碟上（不是腳走路）",
    "SKILL-A-APEX": "金色 Y 彈群衛星環",
    "SKILL-D-PASSIVE": "橘樹突枝掃描出扇形波",
    "SKILL-D-ACTIVE": "樹突頂端亮起免疫信標柱",
    "SKILL-D-FIXED": "橘樹突支援炮台，枝當天線",
    "SKILL-D-APEX": "樹突網絡連成全圖信標"
  };
  if (extra[skill.id]) return extra[skill.id];
  return `玩具風 3D 圖示：${m.lock}；表現「${skill.name}」；綠幕底，無圓框、無字、無組織台`;
}

function skillVfx(skill, char) {
  const m = famMeta(char?.families);
  const slot = skill.slot;
  const no = "禁止組織台、禁止移動碎屑、禁止換成另一具身體";
  if (skill.id.startsWith("SKILL-A-") && slot === "fixed") {
    return `中繼碟 GPUParticles3D 金色環 0.4s 一發；掛 RelayDish；非 looping。${no}；抗體不走路。`;
  }
  if (slot === "passive") {
    return `CoreMesh 上低密度 GPUParticles3D 光暈，${m.vfx}，looping，數量 < 24。掛 CoreMesh。${no}。`;
  }
  if (slot === "active") {
    return `WeaponSocket 一發 ${m.vfx}，0.6–1.2s one-shot；可跟 Area3D 彈體。${no}。`;
  }
  if (slot === "fixed") {
    return `炮口 GPUParticles3D 槍焰 0.15s + 地面 Decal 射程環（非組織材質）。掛 WeaponSocket。${no}。`;
  }
  if (slot === "apex") {
    return `2.0–3.0s 可讀大招：AnimationPlayer + GPUParticles3D 爆發，${m.vfx}。掛 CharacterRoot。one-shot。${no}。`;
  }
  if (slot === "protocol") {
    return `HUD ColorRect 0.3s 家族色閃 + 角色腳底（無組織）一圈 Decal。one-shot。戰鬥中僅在協議已裝備時播。${no}。`;
  }
  return `${m.vfx}；one-shot 0.5s。${no}。`;
}

function skillGodot(skill, char) {
  const kind = skillKind(skill.slot, skill.id);
  const owner = char ? `${char.id}.tres` : "SkillDef";
  return `res://vfx/skills/${skill.id}.tscn；kind=${kind}；resource=${owner}；signal skill_fired("${skill.id}")；slot=${skill.slot}`;
}

function nodeKind(node) {
  const op = node.effectOps?.[0]?.op || "";
  if (op === "grant_fixed_turret") return "duty_kit";
  if (op === "grant_mobility" || op === "grant_relay_qualification") return "duty_kit";
  if (op === "grant_core_passive" || op === "grant_awakening" || op === "grant_ultimate") return "aura";
  if (op === "grant_status_chemistry") return "area";
  if (op.startsWith("grant_universal") && (node.id.includes("WAR") || node.id.includes("MOB"))) return "ui_ping";
  if (op.includes("protocol") || op.includes("unlock")) return "research_unlock";
  if (node.kind === "character_anchor" || node.kind === "core") return "research_unlock";
  if (op === "grant_targeting" || op === "grant_formation_bonus") return "ui_ping";
  return "research_unlock";
}

function nodeGameplay(node) {
  return node.description || node.name;
}

function nodeIcon(node) {
  const m = famMeta(node.familyIds);
  if (node.id === "CORE-IMMUNE") return "發光免疫核心六面體，綠幕底，無圓框、無組織";
  if (node.kind === "character_anchor") return `角色身份徽：${m.lock} 的可愛 3D 頭像剪影，無組織台、無字`;
  if (node.id.endsWith("-03")) return `${m.lock} 的固定炮台勤務圖示（扎根，無組織台）`;
  if (node.id.endsWith("-04") && node.familyIds?.[0] === "A") return `金 Y 中繼碟打開，不是走路`;
  if (node.id.endsWith("-04")) return `${m.lock} 加上螺栓式移動肢（輪／鰭／偽足），無碎屑`;
  if (node.kind === "status") return `狀態化學符號（標記／Y／腐蝕／緩速／感染／鏈／暴擊），綠幕底，無圓框`;
  return `玩具風符號，表現「${node.name}」，${m.color}，綠幕底，無圓框、無字、無組織`;
}

function nodeVfx(node) {
  const kind = nodeKind(node);
  const pulse = "研究完成：節點膜 0.4s 一發脈衝（GPUParticles3D 或 UI scale+glow），非 looping。禁止組織噴濺。";
  if (kind === "research_unlock") return pulse + " 無戰鬥場景特效。";
  if (kind === "duty_kit") {
    if (node.effectOps?.[0]?.op === "grant_relay_qualification") {
      return pulse + " 戰鬥：RelayDish AnimationPlayer `relay_open` 1.0s；0.3s KitSwapBurst。禁止走路塵。";
    }
    if (node.effectOps?.[0]?.op === "grant_mobility") {
      return pulse + " 戰鬥：uproot 1.0–1.5s + 0.3s KitSwapBurst。禁止粒子當腳。";
    }
    return pulse + " 戰鬥：plant 1.0–1.5s 展開 BaseKit。";
  }
  if (kind === "aura") return pulse + " 戰鬥：解鎖後啟用對應 SKILL 光環場景。";
  if (kind === "area") return pulse + " 戰鬥：狀態命中時在目標播 0.5s 狀態材質 Decal。";
  return pulse + " 戰鬥可選 HUD ping。";
}

function nodeGodot(node) {
  const kind = nodeKind(node);
  const op = node.effectOps?.[0]?.op || "none";
  return `res://vfx/research/${node.id}.tscn；kind=${kind}；op=${op}；ResearchState.node_completed("${node.id}")`;
}

function mdEscape(s) {
  return String(s || "").replace(/\|/g, "\\|").replace(/\n/g, " ");
}

function skillRows() {
  const rows = [];
  for (const char of Object.values(characters)) {
    for (const skill of char.skills || []) {
      rows.push({
        id: skill.id,
        name: skill.name,
        family: famOf(char.families),
        slot: skill.slot,
        gameplay: skillGameplay(skill, char),
        icon: skillIcon(skill, char),
        vfx: skillVfx(skill, char),
        godot: skillGodot(skill, char),
        kind: skillKind(skill.slot, skill.id),
        charId: char.id
      });
    }
  }
  return rows;
}

function groupSkills(rows) {
  const groups = [
    ["六基礎（24）", (r) => r.charId.startsWith("CHAR-BASE-")],
    ["雙融合（60）", (r) => r.charId.startsWith("CHAR-PAIR-")],
    ["三融合（24）", (r) => r.charId.startsWith("CHAR-TRIPLE-")],
    ["Apex / PRIME（16）", (r) => r.charId.includes("APEX") || r.charId === "CHAR-PRIME"]
  ];
  let out = "";
  for (const [title, pred] of groups) {
    const list = rows.filter(pred);
    out += `## ${title}\n\n`;
    out += "| ID | 名稱 | 家族 | slot | 玩法 | 圖示 | VFX | Godot |\n|---|---|---|---|---|---|---|---|\n";
    for (const r of list) {
      out += `| ${r.id} | ${mdEscape(r.name)} | ${r.family} | ${r.slot} | ${mdEscape(r.gameplay)} | ${mdEscape(r.icon)} | ${mdEscape(r.vfx)} | ${mdEscape(r.godot)} |\n`;
    }
    out += "\n";
  }
  return out;
}

function groupNodes(nodes) {
  const order = [
    ["核心", (n) => n.kind === "core"],
    ["角色錨點（31）", (n) => n.kind === "character_anchor"],
    ["基礎研究 BASE-*（48）", (n) => n.kind === "base_character_research"],
    ["雙融研究 PAIR-*（45）", (n) => n.kind === "pair_research"],
    ["三融研究 TRIPLE-*（18）", (n) => n.kind === "triple_research"],
    ["Apex 研究（8）", (n) => n.kind === "apex_research"],
    ["通用 UNI-*（42）", (n) => n.kind === "universal"],
    ["狀態化學 STATUS-*（7）", (n) => n.kind === "status"]
  ];
  let out = "";
  for (const [title, pred] of order) {
    const list = nodes.filter(pred);
    out += `## ${title}\n\n`;
    out += "| ID | 名稱 | 家族 | catalog kind | 戰鬥/UI | 玩法 | 圖示 | VFX | Godot |\n|---|---|---|---|---|---|---|---|---|\n";
    for (const n of list) {
      const k = nodeKind(n);
      const combat = k === "research_unlock" ? "UI／研究回饋" : `戰鬥+解鎖（${k}）`;
      out += `| ${n.id} | ${mdEscape(n.name)} | ${famOf(n.familyIds)} | ${n.kind} | ${combat} | ${mdEscape(nodeGameplay(n))} | ${mdEscape(nodeIcon(n))} | ${mdEscape(nodeVfx(n))} | ${mdEscape(nodeGodot(n))} |\n`;
    }
    out += "\n";
  }
  return out;
}

const skills = skillRows();
const nodes = catalog.nodes;

const skillsMd = `# IMMUNE 技能 VFX 對照（124）

來源：\`src/assets/game-assets.js\`。禁止新增技能。玩家名稱維持繁體中文。

圖示規格：1:1 PNG，綠幕 \`#00ff00\`，玩具風 3D 物件本身，無圓框、無徽章環、無字、無組織台。檔名 = ID + \`.png\`。

${groupSkills(skills)}
`;

const nodesMd = `# IMMUNE 研究節點 VFX 對照（200）

來源：\`src/catalog/build-catalog.js\`。禁止新增節點。純解鎖列標為「UI／研究回饋」，仍有完成脈衝。

${groupNodes(nodes)}
`;

const implMd = `# IMMUNE Godot 實作架構 v0.1

配套技能：\`~/.cursor/skills/godot-immune/SKILL.md\`。
專案骨架：\`godot/immune/\`（編輯器未安裝時仍可當資料夾契約）。

## 6 個基礎套件先鎖

戰鬥 3D 只先做這六套。融合／Apex 立繪未收斂前不要進骨骼。

| 套件 | 角色 | 臉要鎖 | 武器要鎖 | 移動／中繼配件 | 轉換 | 立繪門檻 |
|---|---|---|---|---|---|---|
| \`base_t\` | T 細胞 | 橘球臉、C 形刺 | 中央炮 | C 刺／偽足螺栓在殼上 | plant／uproot 1–1.5s | 可動作 |
| \`base_b\` | B 細胞 | 紫藍統一 + 金 Y | Y 分泌口／炮 | 同色鰭或機械腿，兩形態同一套 | 先收立繪再綁骨 | 立繪先收 |
| \`base_m\` | 巨噬細胞 | 薰衣草臉 | 雙爪 + 紅球 | 觸手扎地 vs 抬起走路 | 同一組根肢 | 可動作 |
| \`base_n\` | NK 細胞 | 橄欖臉 | **加特林兩形態都在** | 螺栓輪／鰭，炮不卸 | 先補移動稿的炮 | 立繪先收 |
| \`base_a\` | 抗體構造體 | 金 Y 身體 | 金 Y 炮 | **中繼碟**，無走路骨 | \`relay_open\` | 可動作（中繼） |
| \`base_d\` | 樹突細胞 | 橘球 + 主幹樹枝數 | 支援信標／輕炮 | 短根扎地 vs 樹枝漂浮 | 同一組骨 | 可動作 |

環境組織台是關卡 prop，不進 \`character.tscn\`。

## 資料流

\`\`\`text
HTML catalog JS  →  immune_catalog.json  →  Catalog autoload
ResearchState.node_completed(id)
    ├─ UI: VfxLibrary.play_research(id)
    └─ flags: duty_unlocked / skill_granted
CharacterRoot 依 flags 顯示 BaseKit 或 LocomotionKit/RelayDish
skill_fired(id) → VfxLibrary.play_skill(id, host, WeaponSocket)
\`\`\`

## 場景對應

| 路徑 | 內容 |
|---|---|
| \`res://autoload/catalog.gd\` | JSON 查表 |
| \`res://autoload/research_state.gd\` | 完成／揭示／協議帶寬 |
| \`res://autoload/vfx_library.gd\` | ID → PackedScene |
| \`res://characters/base_{t,b,m,n,a,d}/\` | 核心 + 勤務套件 |
| \`res://vfx/skills/<SKILL-ID>.tscn\` | 124 技能 |
| \`res://vfx/research/<NODE-ID>.tscn\` | 200 節點完成脈衝（可共用模板 + 改色） |
| \`res://scenes/combat_lane.tscn\` | 第一條戰鬥：一核、一路、T 細胞切勤務 |

研究網 HTML 可繼續當選單。Godot 不必第一天重做星盤。

## 共用研究解鎖模板

大多數非戰鬥節點 instance \`res://vfx/research/_unlock_pulse.tscn\`，用家族色 \`ShaderMaterial\` 參數。
\`BASE-*-03/04\` 額外觸發角色 AnimationPlayer，不是另一套身體。

## 第一條戰鬥切片（kits 之後）

1. 放 T 固定炮台（BaseKit）。
2. 一條細菌路線走向核心。
3. 解鎖 \`BASE-T-04\` 後 uproot，T 加入橫向推進。
4. 抗體不加入移動軍團。

## ID 綁定原則

檔名、\`StringName\`、catalog \`id\` 三者相同。缺檔就 \`push_error\`，不准默默改播隔壁技能。
`;

await mkdir(OUT, { recursive: true });
await writeFile(join(OUT, "skills.md"), skillsMd, "utf8");
await writeFile(join(OUT, "research-nodes.md"), nodesMd, "utf8");
await writeFile(join(OUT, "godot-implementation.md"), implMd, "utf8");

const index = `# IMMUNE Godot／VFX 實作聖經 v0.1

- 技能 124：[vfx/skills.md](vfx/skills.md)
- 研究節點 200：[vfx/research-nodes.md](vfx/research-nodes.md)
- Godot 架構與六套件：[vfx/godot-implementation.md](vfx/godot-implementation.md)
- Cursor skill：\`C:/Users/wchkl/.cursor/skills/godot-immune/SKILL.md\`

產品鎖：先 6 基礎套件；雙形態是勤務切換；角色不含組織台；移動肢螺栓在殼上；抗體是中繼；不再加研究節點。
`;
await writeFile(join(REPO, "docs/IMMUNE_godot_vfx_implementation_v0.1.md"), index, "utf8");

const catalogJson = {
  version: catalog.version,
  campaignLevels: catalog.campaignLevels || [],
  nodes: catalog.nodes,
  skills: skills.map((s) => {
    const src = (characters[s.charId]?.skills || []).find((row) => row.id === s.id) || {};
    return {
      id: s.id,
      name: s.name,
      family: s.family,
      slot: s.slot,
      kind: s.kind,
      characterId: s.charId,
      unlockNodeId: src.unlockNodeId || null,
      requires: src.requires || [],
      tier: src.tier ?? null,
      levelLink: src.levelLink || null,
      route: src.route || null
    };
  }),
  characters: Object.values(characters).map((c) => ({
    id: c.id,
    name: c.name,
    families: c.families,
    role: c.role,
    skills: c.skills,
    forms: c.forms || null
  }))
};
await mkdir(join(REPO, "godot/immune/resources/catalog"), { recursive: true });
await writeFile(
  join(REPO, "godot/immune/resources/catalog/immune_catalog.json"),
  JSON.stringify(catalogJson, null, 2),
  "utf8"
);

console.log(`skills ${skills.length} nodes ${nodes.length}`);
