import { mkdir, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(__dirname, "..");
const JSON_OUT = join(ROOT, "assets", "3d-character-prompts.json");
const MD_OUT = resolve(ROOT, "../../docs/vfx/3d-character-prompts.md");

await import("../src/catalog/definitions.js");
await import("../src/assets/game-assets.js");

const { characters } = globalThis.IMMUNE.gameAssets;

/**
 * 3D keeps the honest 濕果凍 / wet-jelly material from 2D portraits.
 * Dogan Ural is used only for production craft: chunky readable forms,
 * beveled edges, soft lighting, isometric 3/4, black bg, silhouette.
 * Do not copy backpack plum/teal or painted wood. Do not flatten jelly into matte clay.
 */
const STYLE =
  "stylized 3D game character asset, chunky simplified geometry, broad readable shapes, softly beveled edges, honest wet gelatinous organic body, glossy jelly membrane, wet specular highlights, subsurface scatter glow from inside, organic nodules, hardware is painted metal bolted onto jelly not replacing it, restrained detail, vinyl-toy volume, low-key artisan feel, game-ready silhouette";

const LIGHTING =
  "soft diffuse studio lighting, gentle ambient occlusion, simple soft directional shadows, honest wet specular on the jelly skin, soft subsurface glow, no bloom blowout, no dramatic theatrical lighting, no volumetric fog, no rim-light fireworks";

const CAMERA =
  "elevated isometric three-quarter view, clean centered composition, character fills 70 percent of frame, orthographic-leaning game turnaround camera, tight closed silhouette";

const BACKGROUND = "flat solid black background, no ground plane, no studio floor, no environment";

const FORBIDDEN = [
  "NO tissue platform",
  "NO fleshy mound",
  "NO pink brain-like disc",
  "NO pedestal",
  "NO terrain",
  "NO chroma-key green background",
  "NO sawdust",
  "NO particle spray",
  "NO splash droplets",
  "NO floating crumbs",
  "NO leaking fluid",
  "NO motion-blur debris trails",
  "NO second unrelated body",
  "NO humanoid adult anatomy",
  "NO photoreal skin pores",
  "NO matte clay",
  "NO dry painted wood",
  "NO hard plastic toy",
  "NO PBR chrome",
  "NO bloom",
  "NO text",
  "NO watermark",
  "NO letters or numbers"
].join(", ");

const RIG =
  "one spherical-or-Y core mesh stays on screen, same cute face as the 2D portrait identity, Face and WeaponSocket never disappear, dual-form is a duty-kit swap not a second character, BaseKit is tucked turret skirt or stubby roots, LocomotionKit is bolted wheels fins or pseudopods attached to the hull";

const FAMILY = {
  T: {
    color: "saturated cytotoxic orange #ff8a3d with deep-red hardware",
    body: "chunky orange spherical cytotoxic immune cell, pitted orange-peel membrane, C-shaped red protein caps on short stalks, central ribbed red cannon barrel as the mouth-weapon"
  },
  B: {
    color: "violet-blue #8b6cff with gold Y accents",
    body: "chunky violet spherical plasma cell, gold Y-shaped antibody crest, glowing gold Y chest medallion, production pouches as painted hardware not clutter"
  },
  M: {
    color: "lavender phagocyte #c9a0ff with red pathogen-orb accents",
    body: "chunky lavender spherical macrophage, thick claw arms, organic nodules, red spiky captured-pathogen orbs only as held props if needed, never as a ground pile"
  },
  N: {
    color: "olive hunter #8fb03a with gunmetal barrels",
    body: "chunky olive spherical NK hunter, grumpy cute brows, side-bolted six-barrel gatling gun MUST be visible and attached with a circular plate"
  },
  A: {
    color: "gold antibody #f2b84b with dark-teal painted hardware",
    body: "chunky gold Y-shaped antibody construct, two upper barrels as the Y arms, cute face on the stem, relay dish as body hardware not legs, no walk skeleton"
  },
  D: {
    color: "sentinel orange #ff9b58 with warmer antler tips",
    body: "chunky orange spherical dendritic sentinel, branching antler-like dendrites, scanner pods on the branches, stubby tactile feet that can tuck"
  }
};

const FUSION_KITS = {
  TB: "T cannon plus B gold Y ledger plates on ONE sphere",
  TM: "M claw bulk plus T C-spikes and cannon on ONE sphere",
  TN: "T cannon plus N side gatling on ONE sphere",
  TA: "T cannon plus A gold Y arms and a small relay dish on ONE body",
  TD: "T cannon plus D branching dendrites on ONE sphere",
  BM: "B gold Y plus M claws and pouches on ONE sphere",
  BN: "B gold Y plus N gatling on ONE sphere",
  BA: "B production pouches plus A gold Y arms on ONE body",
  BD: "B gold Y plus D dendrites on ONE sphere",
  MN: "M claws plus N gatling on ONE sphere",
  MA: "M bulk plus A gold dish-shield on ONE body",
  MD: "M furnace belly plus D scanner dendrites on ONE sphere",
  NA: "N gatling plus A tracking Y arms on ONE body",
  ND: "N gatling plus D beacon dendrites on ONE sphere",
  AD: "A gold Y relay body plus D node branches, still one construct",
  TBA: "T cannon core with B Y plates and A dish, same face, accessory kits only",
  TND: "D dendrite core with T cannon and N gatling kits",
  MAD: "M bulk core with A dish-shield and D dendrites",
  BMD: "B Y core with M claws and D branches",
  BNA: "N hunter core with B Y pouches and A Y arms",
  TMN: "M furnace core with T cannon and N gatling",
  MEMORY: "TB memory-hunter core plus archive-plate kit, not a new body",
  STERILE: "MA barrier core plus sterile-dome hardware kit, not a new body",
  SILENT: "ND hunter-beacon core plus silence-net antenna kit, not a new body",
  PRIME: "one unified sphere wearing all six family kits as readable accessories, same cute face, not six characters glued together"
};

function familyLabel(character) {
  return character.families.join("+");
}

function kitNote(character) {
  const id = character.id;
  if (id.startsWith("CHAR-BASE-")) return FAMILY[character.families[0]].body;
  if (id.startsWith("CHAR-PAIR-")) return FUSION_KITS[id.replace("CHAR-PAIR-", "")];
  if (id.startsWith("CHAR-TRIPLE-")) return FUSION_KITS[id.replace("CHAR-TRIPLE-", "")];
  if (id === "CHAR-PRIME") return FUSION_KITS.PRIME;
  if (id === "CHAR-APEX-MEMORY") return FUSION_KITS.MEMORY;
  if (id === "CHAR-APEX-STERILE") return FUSION_KITS.STERILE;
  if (id === "CHAR-APEX-SILENT") return FUSION_KITS.SILENT;
  return "one core immune-cell body with bolted accessory kits";
}

function colorNote(character) {
  const colors = character.families.map((f) => FAMILY[f].color);
  if (colors.length === 1) return colors[0];
  return `split or accessory mix of ${colors.join(" and ")}, still ONE body`;
}

function dutyBlock(character, formKey, form) {
  if (formKey === "fixed") {
    return "FIXED DUTY: planted turret posture, BaseKit visible as tucked stubby roots or turret skirt under the hull, weapon deployed, cannot walk, LocomotionKit hidden";
  }
  if (form.kind === "relay" || character.id === "CHAR-BASE-A") {
    return "RELAY DUTY: hovering fixed relay beacon, RelayDish unfolded from the gold Y body, support beams are part of the mesh, no walk cycle, no wheels, no legs";
  }
  return "MOBILE DUTY: LocomotionKit visible as bolted wheels, fins, or thick pseudopods firmly attached to the hull, BaseKit tucked away, dynamic but planted-weight pose, no shedding";
}

function priority(character) {
  return character.id.startsWith("CHAR-BASE-") ? "lock-first" : "after-six-base-kits";
}

function subject(character, formKey, form) {
  return [
    `IMMUNE Godot 4 combat character ${character.name} (${familyLabel(character)}, ${character.id})`,
    kitNote(character),
    colorNote(character),
    dutyBlock(character, formKey, form),
    RIG,
    `keep the same cute face and honest 濕果凍 wet-jelly material as the 2D portrait ${character.id}-${form.assetSuffix}.png, glossy gelatinous not matte clay, not hard plastic`
  ].join(", ");
}

function conceptPrompt(character, formKey, form) {
  return `3D render of [${subject(character, formKey, form)}], ${STYLE}, ${LIGHTING}, ${BACKGROUND}, ${CAMERA}, ${FORBIDDEN}.`;
}

function meshPrompt(character, formKey, form) {
  return [
    `game-ready stylized 3D character mesh of ${character.name}`,
    kitNote(character),
    dutyBlock(character, formKey, form),
    "chunky beveled geometry, watertight single mesh or clean kit pieces",
    "honest wet gelatinous shader, subsurface scatter, wet specular, not matte clay, not hard plastic",
    "T-pose or duty pose, closed silhouette, no base platform",
    colorNote(character),
    FORBIDDEN
  ].join(", ");
}

function turnaroundPrompt(character, formKey, form) {
  return `character turnaround sheet of [${subject(character, formKey, form)}], four orthographic panels front three-quarter side back, identical proportions, ${STYLE}, ${LIGHTING}, ${BACKGROUND}, no bloom, ${FORBIDDEN}.`;
}

const prompts = [];
for (const character of Object.values(characters)) {
  if (!character.forms) continue;
  for (const [formKey, form] of Object.entries(character.forms)) {
    prompts.push({
      fileStem: `${character.id}-${form.assetSuffix}`,
      characterId: character.id,
      name: character.name,
      families: character.families,
      formKey,
      kind: form.kind || (formKey === "fixed" ? "fixed" : "mobile"),
      priority: priority(character),
      conceptPrompt: conceptPrompt(character, formKey, form),
      meshPrompt: meshPrompt(character, formKey, form),
      turnaroundPrompt: turnaroundPrompt(character, formKey, form)
    });
  }
}

function sectionFor(list) {
  return list
    .map((p) => {
      return [
        `### ${p.name} · ${p.characterId} · ${p.formKey}`,
        "",
        `**Concept / image model**`,
        "",
        "```",
        p.conceptPrompt,
        "```",
        "",
        `**Text-to-3D mesh (Meshy / Rodin / Tripo)**`,
        "",
        "```",
        p.meshPrompt,
        "```",
        "",
        `**Turnaround sheet**`,
        "",
        "```",
        p.turnaroundPrompt,
        "```",
        ""
      ].join("\n");
    })
    .join("\n");
}

const lockFirst = prompts.filter((p) => p.priority === "lock-first");
const later = prompts.filter((p) => p.priority !== "lock-first");

const md = `# IMMUNE 3D 角色 Prompt（與 2D 立繪分開相機，不分開材質）

2D 立繪：果凍高光、綠幕、正面圖鑑。
3D 戰鬥模型：同一套 **誠實濕果凍** 材質，相機與造型工法改用 Dogan 那套生產語法。
不抄背包的梅紫／青綠／木頭。材質 **不要** 壓成霧面黏土。

## 從參考學到、為 IMMUNE 改過的部分

| 參考（背包／煉金師） | IMMUNE 3D 採用 | 不採用 |
|---|---|---|
| chunky simplified geometry | 大塊可讀形狀 | 碎細節、微結構 |
| softly beveled edges | 軟倒角，玩具體積 | 刀鋒硬邊、寫實皺褶 |
| matte painted wood/metal | 只有配件金屬可手繪 | 身體改霧面＝說謊 |
| soft diffuse, no bloom | 平光、輕 AO；果凍仍有濕高光與皮下透光 | 戲劇光、體積霧、bloom 爆光 |
| elevated isometric 3/4 | 戰鬥模型相機 | 圖鑑正面特寫 |
| flat black background | 3D 概念圖黑底 | 綠幕（綠幕留給 2D 圖示） |
| tight game-ready silhouette | 剪影先於雜訊 | 粒子、鋸屑、組織台、漏液 |
| plum / teal wood-metal | — | 對方道具色，不是家族色 |

材質鎖：身體是 **濕果凍**（glossy gelatinous、wet specular、subsurface glow、organic nodules）。加特林、Y 標、中繼碟可以是畫上去的金屬，但要 **鎖在果凍殼上**，不能把整隻變成硬塑膠。

家族色仍鎖：T 橘、B 紫藍金 Y、M 薰衣草、N 橄欖＋加特林、A 金 Y 中繼碟、D 橘樹突。

## 綁定規則（3D 必守）

- 先鎖 **六個基礎套件**，通過 1.0–1.5 秒駐守／拔起後才做融合。
- 雙形態是 **DutyKit 切換**：同一顆 CoreMesh + Face + Weapon。
- 抗體 A 是 **中繼碟**，沒有走路骨骼。
- 移動肢體必須 **鎖在殼上**（輪、鰭、偽足），禁止鋸屑粒子。
- 禁止組織台／粉紅肉盤。
- 融合是 **同一顆球加配件**，不是兩隻站一起。
- 濕是材質，不是漏液：有高光、有透光，沒有噴濺、沒有水灘。

## 使用方式

1. 概念圖：貼 \`conceptPrompt\`（黑底 3/4）。
2. 出模：拿概念圖做 image-to-3D，或貼 \`meshPrompt\`。
3. 拓撲：\`turnaroundPrompt\` 出四面，再進 Godot \`base_{t,b,m,n,a,d}\`。
4. 2D 立繪提供 **臉、剪影、濕果凍材質**；3D 只換相機與套件結構。

重跑：\`node ui/immune-research-network/scripts/generate-3d-character-prompts.mjs\`

共 ${prompts.length} 條（基礎 ${lockFirst.length}、融合以後 ${later.length}）。

## 第一批：六基礎 × 雙職責

${sectionFor(lockFirst)}

## 第二批：融合／Apex（六套件過關後才出模）

${sectionFor(later)}
`;

await mkdir(dirname(JSON_OUT), { recursive: true });
await mkdir(dirname(MD_OUT), { recursive: true });
await writeFile(
  JSON_OUT,
  JSON.stringify(
    {
      version: "1.0.0",
      generatedAt: new Date().toISOString(),
      note: "3D combat-mesh prompts. Same honest wet-jelly material as 2D portraits; different camera and kit structure.",
      shared: { STYLE, LIGHTING, CAMERA, BACKGROUND, FORBIDDEN, RIG },
      count: prompts.length,
      prompts
    },
    null,
    2
  ),
  "utf8"
);
await writeFile(MD_OUT, md, "utf8");
console.log(`wrote ${prompts.length} 3D prompts -> ${JSON_OUT}`);
console.log(`wrote markdown -> ${MD_OUT}`);
