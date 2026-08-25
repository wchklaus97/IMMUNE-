# IMMUNE 200 節點研究網絡 UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立一個可直接在瀏覽器開啟、具有 200 個真實研究節點、31 個角色錨點、完整依賴關係與可操作垂直切片的 `IMMUNE` 放射式永久研究網絡。

**Architecture:** 使用無外部執行期依賴的原生 HTML、CSS、SVG 與 JavaScript。來源碼按內容資料、規則引擎、放射佈局、狀態、輸入及畫面元件拆分，瀏覽器開發版依次載入模組，建置腳本再把它們內嵌成單一 H5 成品。所有節點狀態均由同一份 200 節點 catalog 與玩家存檔推導，畫面不得使用硬編碼完成數或裝飾性假連線。

**Tech Stack:** HTML5、CSS3、SVG、原生 JavaScript、Node.js 20 `node:test`、Codex in-app Browser、Image Gen。

## Global Constraints

- 權威規格為 `docs/superpowers/specs/2026-08-12-immune-permanent-research-network-design.md`。
- 節點總數必須為 200，分類數量必須為 `1/31/48/45/18/8/42/7`。
- 角色身份必須為 31：6 基礎、15 雙融合、6 三融合、3 隱藏 Apex 與 `IMMUNE PRIME`。
- 初始揭示 18–24 個節點；主線約完成 45–60，完整內容約完成 130–160，200/200 是精通目標。
- 縮放必須限制在 0.35×–2.4×；可視節點雖可為 18–24px，但操作命中區不得小於 44px。
- 初始研究協議帶寬為 6，最高 10；普通／核心／Apex 協議分別消耗 1／2／3；同時最多一個 Apex 協議。
- 目標畫面包括 1280×720、Steam Deck 1280×800 與 1920×1080。
- 全部 UI 文字由 HTML/SVG 程式渲染，不得烘焙進背景圖。
- 篩選只可改變亮度或可讀層級，不得改變節點座標。
- 未發現節點不得透過搜尋或詳情面板洩漏名稱、效果及取得條件。
- 執行期不可依賴 CDN、網絡 API、React、Vite 或其他套件；最終產物必須是一個可直接開啟的單一 HTML。
- 現有 workspace 不是 Git repository；執行過程不得自行 `git init`，每項任務以測試通過及檔案清單作檢查點。

## File Structure

```text
ui/immune-research-network/
├─ package.json                         # 本機建置、測試及靜態伺服器命令
├─ index.html                           # 開發版語義骨架及外部資源載入順序
├─ src/
│  ├─ catalog/
│  │  ├─ definitions.js                # 家族、角色、融合、狀態、資源及穩定 ID
│  │  ├─ build-catalog.js              # 由定義生成正好 200 個命名節點
│  │  └─ validate-catalog.js           # 數量、引用、依賴圖及內容完整性驗證
│  ├─ domain/
│  │  ├─ unlock-engine.js              # 揭示、前置、卡片、材料、資源資格推導
│  │  ├─ research-transaction.js       # 原子研究購買及後續揭示
│  │  ├─ protocols.js                  # 協議裝備、帶寬及 Apex 限制
│  │  └─ search-filter.js               # 搜尋、篩選及防劇透
│  ├─ state/
│  │  ├─ store.js                       # 單一狀態容器與畫面訂閱
│  │  └─ persistence.js                 # localStorage schema、版本恢復及清除示範進度
│  ├─ layout/
│  │  ├─ pair-slots.js                  # 15 個雙家族群組的人工批准固定槽位
│  │  ├─ radial-layout.js               # 3000×3000 世界座標及六扇區／六環層位置
│  │  ├─ edge-routing.js                # required、dual_source、optional、affinity 線路
│  │  └─ lod.js                         # 四級資訊密度規則
│  ├─ views/
│  │  ├─ app-shell.js                   # 頂部資源列、工具列、畫布、側欄及協議托盤
│  │  ├─ tree-map.js                    # SVG 節點層與連線層
│  │  ├─ detail-panel.js                # 效果、缺口、取得方式、追蹤及研究按鈕
│  │  ├─ minimap.js                     # 世界縮圖及目前視窗框
│  │  ├─ protocol-dock.js               # 關卡前研究協議配置
│  │  ├─ research-list.js               # 共用 catalog 的列表／無障礙替代視圖
│  │  └─ feedback.js                    # 解鎖能量、資源扣除、節點成熟及提示
│  ├─ input/
│  │  ├─ pan-zoom.js                    # 滑鼠、觸控板、觸控平移縮放
│  │  └─ keyboard-gamepad.js            # 鍵盤及 Steam Deck 導覽語義
│  ├─ styles/
│  │  ├─ tokens.css                     # 已批准概念的顏色、字體、間距與動態 token
│  │  ├─ shell.css                      # 主版面及 UI chrome
│  │  ├─ tree-map.css                   # 星盤、節點、連線及狀態
│  │  └─ responsive.css                 # 三個目標解像度與 reduced-motion
│  ├─ demo-scenario.js                  # 固定 22 節點垂直切片初始狀態
│  └─ main.js                           # 組裝 catalog、store、layout 及 views
├─ scripts/
│  ├─ build-single-file.mjs             # 把 CSS/JS 內嵌成單一 H5
│  └─ serve.mjs                         # 零依賴本機 HTTP server
└─ tests/
   ├─ catalog-integrity.test.mjs
   ├─ unlock-engine.test.mjs
   ├─ research-transaction.test.mjs
   ├─ protocols-persistence.test.mjs
   ├─ radial-layout.test.mjs
   └─ search-filter.test.mjs

outputs/
├─ concepts/
│  ├─ immune_research_network_concept_a.png
│  └─ immune_research_network_concept_b.png
└─ immune_research_network_v1.html       # 最終可直接開啟的互動成品
```

---

### Task 1: 鎖定完整畫面概念與建立零依賴工程骨架

**Files:**
- Inspect: `C:/Users/wchkl/AppData/Local/Temp/codex-clipboard-c138b9c4-b5ed-4654-8fbc-28f79925c8b8.png`
- Create: `outputs/concepts/immune_research_network_concept_a.png`
- Create: `outputs/concepts/immune_research_network_concept_b.png`
- Create: `docs/IMMUNE_research_network_visual_inventory_v1.md`
- Create: `ui/immune-research-network/package.json`
- Create: `ui/immune-research-network/index.html`
- Create: `ui/immune-research-network/src/styles/tokens.css`
- Create: `ui/immune-research-network/src/styles/shell.css`
- Create: `ui/immune-research-network/src/styles/tree-map.css`
- Create: `ui/immune-research-network/src/styles/responsive.css`
- Create: `ui/immune-research-network/tests/shell.test.mjs`

**Interfaces:**
- Consumes: 已批准研究規格、使用者提供的圓形節點樹參考圖，以及既有深色人體內部／可愛免疫細胞視覺語言。
- Produces: 兩張使用相同 1920×1080 畫面狀態的正式視覺方向概念，讓使用者公平比較 A 清晰免疫科技星盤與 B 有機器官神經網絡；選定方向後另產生 Steam Deck／聚焦狀態概念。任務亦產生固定設計 token、穩定 DOM 區域 ID，以及後續所有任務共用的 `globalThis.IMMUNE` namespace。

- [ ] **Step 1: 檢視參考圖並生成兩個完整畫面概念**

先以 `view_image` 檢視參考圖，再使用 `imagegen`。概念 A 的完整提示為：

```text
IMMUNE 遊戲的永久研究網絡完整 UI 概念圖，16:9 1920×1080。可愛但具生物質感的免疫細胞，置於危險寫實的人體微觀世界；中央為發光免疫核心，六個 60 度角色家族扇區形成巨大圓形星盤，200 個節點以不同大小和形狀分佈，31 個角色錨點明顯大於普通節點。十五組雙家族融合置於外環交界，六個三融合在更外環，三個隱藏 Apex 與 IMMUNE PRIME 在最外環。左上顯示 IMMUNE 與 18/200，頂部是抗原樣本、一度原質、融合核心及協議帶寬；左側有搜尋和六家族篩選；右側是 T 細胞移動資格的詳情面板，清楚顯示前置、缺少材料、取得方式、追蹤與研究按鈕；右下角有迷你地圖。深藍黑人體組織背景、青藍紫橙六色能量、細胞膜光圈、清晰繁體中文、專業 Steam 遊戲 UI、資訊密集但不雜亂、不是網頁卡片 dashboard、所有控制都可由 HTML/CSS/SVG 實作。
```

概念 B 使用與 A 完全相同的 1920×1080 解像度、節點揭示狀態、T 細胞選中路線、面板內容與控制區域，只把視覺方向改為更接近使用者參考圖的「分層免疫器官切片」：深色圓形器官盤、較少玻璃面板、節點群像神經網絡自然延伸，詳情面板以半透明組織切片承載。兩張圖均不得把遊戲文字烘焙成實作資產；它們只作視覺規格。使用者選定 A 或 B 後，才以選定方向另產生 1280×800 Steam Deck 聚焦狀態稿。

- [ ] **Step 2: 建立視覺 inventory 並記錄選定方案**

`docs/IMMUNE_research_network_visual_inventory_v1.md` 必須逐項寫下：背景、六家族色、字體層級、節點四種大小、八種狀態符號、四種連線、面板尺寸、工具列高度、迷你地圖尺寸、解鎖動畫、reduced-motion 替代效果，以及概念 A／B 的取捨。使用者批准的方案必須標記為唯一實作參考。

- [ ] **Step 3: 寫入工程 manifest**

```json
{
  "name": "immune-research-network",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "test": "node --test",
    "build": "node scripts/build-single-file.mjs",
    "serve": "node scripts/serve.mjs"
  }
}
```

- [ ] **Step 4: 寫入語義骨架與穩定區域 ID**

`index.html` 必須包含 `#resource-bar`、`#research-toolbar`、`#tree-viewport`、`#tree-svg`、`#detail-panel`、`#protocol-dock`、`#minimap`、`#research-list`、`#toast-region`，並依 File Structure 順序載入 CSS 和 JavaScript。每個 `<script>` 使用 `defer`，每個來源檔都以 IIFE 掛載到 `globalThis.IMMUNE`，避免全域名稱碰撞。

- [ ] **Step 5: 先寫並執行骨架測試**

```js
import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

test("development shell exposes every stable application region", async () => {
  const html = await readFile(new URL("../index.html", import.meta.url), "utf8");
  for (const id of [
    "resource-bar", "research-toolbar", "tree-viewport", "tree-svg",
    "detail-panel", "protocol-dock", "minimap", "research-list", "toast-region"
  ]) assert.match(html, new RegExp(`id=["']${id}["']`));
});
```

Run: `cd ui/immune-research-network; node --test tests/shell.test.mjs`

Expected: PASS，且概念圖經使用者批准後才進入 Task 2。

### Task 2: 建立 31 個身份與正好 200 個具語義節點的 catalog

**Files:**
- Create: `ui/immune-research-network/src/catalog/definitions.js`
- Create: `ui/immune-research-network/src/catalog/build-catalog.js`
- Create: `ui/immune-research-network/src/catalog/validate-catalog.js`
- Create: `ui/immune-research-network/tests/catalog-integrity.test.mjs`

**Interfaces:**
- Consumes: `globalThis.IMMUNE`、規格中的角色名稱與節點分配。
- Produces: `IMMUNE.definitions`、`IMMUNE.buildCatalog(): ResearchCatalog`、`IMMUNE.validateCatalog(catalog): { valid: boolean, errors: string[] }`。

- [ ] **Step 1: 定義穩定身份、家族、資源及內容語彙**

`definitions.js` 必須完整保存以下陣列，不使用「研究 01」等佔位名稱：

```js
const families = [
  ["T", "T 細胞", "#45bdf2"], ["B", "B 細胞", "#a878ff"],
  ["M", "巨噬細胞", "#d28cff"], ["N", "NK 細胞", "#a6c94a"],
  ["A", "抗體構造體", "#f2b84b"], ["D", "樹突細胞", "#ff9b58"]
];
const pairCharacters = [
  ["TB", "記憶獵手"], ["TM", "吞噬突擊"], ["TN", "細胞毒刃"],
  ["TA", "精準抗體"], ["TD", "免疫指揮"], ["BM", "抗原處理"],
  ["BN", "標記處決"], ["BA", "抗體風暴"], ["BD", "抗原呈現"],
  ["MN", "感染清除"], ["MA", "免疫壁壘"], ["MD", "抗原中樞"],
  ["NA", "抗體追獵"], ["ND", "獵殺信標"], ["AD", "免疫網絡"]
];
const tripleCharacters = [
  ["TBA", "適應免疫核心"], ["TND", "全域截擊中樞"],
  ["MAD", "組織防衛聖域"], ["BMD", "組織再生工廠"],
  ["BNA", "抗體獵殺蜂群"], ["TMN", "凋亡反應爐"]
];
const apexCharacters = [
  ["MEMORY", "長期免疫記憶庫"], ["STERILE", "無菌聖域"],
  ["SILENT", "靜默獵殺網"], ["PRIME", "IMMUNE PRIME"]
];
const statuses = ["標記", "抗體", "腐蝕", "緩速", "感染", "鏈鎖", "暴擊"];
const universalDomains = ["防守工程", "遠征探索", "全面戰爭", "細胞機動", "融合工程", "生存修復"];
```

基礎角色各自再定義 `corePassiveName`、`mobilityQualificationName`、`targetingName`、`awakeningName` 及 `ultimateName`，讓八個研究反映其生物定位。抗體構造體的第 4 節點固定為「抗體固定中繼資格」，不得誤寫成可移動角色。

- [ ] **Step 2: 先寫精確數量與身份測試並確認失敗**

```js
import test from "node:test";
import assert from "node:assert/strict";
await import("../src/catalog/definitions.js");
await import("../src/catalog/build-catalog.js");
await import("../src/catalog/validate-catalog.js");

test("catalog contains the approved 200-node allocation", () => {
  const catalog = globalThis.IMMUNE.buildCatalog();
  const counts = Object.groupBy(catalog.nodes, node => node.kind);
  const size = key => (counts[key] || []).length;
  assert.equal(catalog.nodes.length, 200);
  assert.deepEqual([
    size("core"), size("character_anchor"), size("base_character_research"),
    size("pair_research"), size("triple_research"), size("apex_research"),
    size("universal"), size("status")
  ], [1, 31, 48, 45, 18, 8, 42, 7]);
});

test("all stable ids and references are valid", () => {
  const result = globalThis.IMMUNE.validateCatalog(globalThis.IMMUNE.buildCatalog());
  assert.deepEqual(result.errors, []);
  assert.equal(result.valid, true);
});
```

Run: `cd ui/immune-research-network; node --test tests/catalog-integrity.test.mjs`

Expected: FAIL because the three catalog modules do not yet export their APIs.

- [ ] **Step 3: 實作生成規則與穩定 ID**

`buildCatalog()` 必須以以下順序生成：

```js
return {
  version: "1.0.0",
  nodes: [
    buildCore(),
    ...buildCharacterAnchors(),
    ...baseCharacters.flatMap(buildEightBaseNodes),
    ...pairCharacters.flatMap(buildThreePairNodes),
    ...tripleCharacters.flatMap(buildThreeTripleNodes),
    ...apexCharacters.flatMap(buildTwoApexNodes),
    ...universalDomains.flatMap(buildSevenUniversalNodes),
    ...statuses.map(buildStatusNode)
  ],
  families, pairCharacters, tripleCharacters, apexCharacters, statuses, universalDomains
};
```

每個節點必須包含 `id`、`kind`、`name`、`description`、`familyIds`、`categoryIds`、`tags`、`effectOps`、`prerequisiteGroups`、`conditions`、`costs`、`revealRule`、`layoutHint`、`acquisitionHints`，協議節點另有 `{ bandwidth, apex, exclusiveGroup }`。

穩定 ID 格式固定為 `CORE-IMMUNE`、`CHAR-BASE-T`、`CHAR-PAIR-TB`、`CHAR-TRIPLE-TBA`、`CHAR-APEX-MEMORY`、`CHAR-PRIME`、`BASE-T-01`、`PAIR-TB-S1`、`TRIPLE-TBA-ROLE`、`APEX-MEMORY-GATE`、`UNI-DEF-01`、`STATUS-MARK`。

- [ ] **Step 4: 實作 catalog 驗證器**

驗證器必須檢查：總數與分類數、ID 唯一、所有前置／角色／資源引用存在、成本非負、沒有自我依賴、可完成拓撲排序、除核心外每個節點都能追溯至核心、普通節點最多一組必要前置、角色／融合／Apex 最多兩組必要前置，以及 15 個無序家族 pair 沒有正反重複。

- [ ] **Step 5: 執行完整 catalog 測試**

Run: `cd ui/immune-research-network; node --test tests/catalog-integrity.test.mjs`

Expected: PASS；輸出證明實際節點為 200、角色錨點為 31、無錯誤引用或依賴循環。

### Task 3: 實作解鎖、原子研究、協議與存檔規則

**Files:**
- Create: `ui/immune-research-network/src/domain/unlock-engine.js`
- Create: `ui/immune-research-network/src/domain/research-transaction.js`
- Create: `ui/immune-research-network/src/domain/protocols.js`
- Create: `ui/immune-research-network/src/state/persistence.js`
- Create: `ui/immune-research-network/tests/unlock-engine.test.mjs`
- Create: `ui/immune-research-network/tests/research-transaction.test.mjs`
- Create: `ui/immune-research-network/tests/protocols-persistence.test.mjs`

**Interfaces:**
- Consumes: `ResearchCatalog` from Task 2。
- Produces: `deriveNodeState(catalog, player, nodeId)`、`researchNode(catalog, player, nodeId)`、`equipProtocol(catalog, player, nodeId)`、`unequipProtocol(player, nodeId)`、`serializePlayer(player)`、`restorePlayer(raw, catalog, defaults)`。

- [ ] **Step 1: 建立明確玩家狀態與資格狀態測試**

```js
const player = {
  schemaVersion: 1,
  catalogVersion: "1.0.0",
  completedNodeIds: ["CORE-IMMUNE"],
  revealedNodeIds: ["CORE-IMMUNE", "CHAR-BASE-T"],
  trackedNodeIds: [], equippedProtocolIds: [], protocolBandwidth: 6,
  resources: { antigen: 0, biomass: 0, protomass: 0, fusionCore: 0 },
  characterCards: {}, items: {}, discoveryFlags: [], inBattle: false,
  view: { x: 1500, y: 1500, zoom: 0.55 }
};

test("a revealed node distinguishes missing prerequisite from missing resource", () => {
  const state = globalThis.IMMUNE.deriveNodeState(catalog, player, "BASE-T-01");
  assert.equal(state.visibility, "revealed");
  assert.equal(state.completion, "incomplete");
  assert.equal(state.eligibility, "missing_prerequisite");
});
```

`ResearchRuntimeState` 不可壓成單一字串；必須分開保存 `visibility`、`completion`、`eligibility`、`selected` 與 `tracked`。

- [ ] **Step 2: 先寫原子交易測試並確認失敗**

```js
test("research purchase deducts once and cannot be double-purchased", () => {
  const funded = structuredClone(readyPlayer);
  const first = globalThis.IMMUNE.researchNode(catalog, funded, "BASE-T-01");
  const second = globalThis.IMMUNE.researchNode(catalog, first.state, "BASE-T-01");
  assert.equal(first.ok, true);
  assert.equal(second.ok, false);
  assert.equal(second.error, "already_completed");
  assert.equal(first.state.resources.antigen, readyPlayer.resources.antigen - 20);
  assert.equal(second.state.resources.antigen, first.state.resources.antigen);
});

test("failed purchase never mutates player resources", () => {
  const before = structuredClone(player);
  const result = globalThis.IMMUNE.researchNode(catalog, player, "BASE-T-01");
  assert.equal(result.ok, false);
  assert.deepEqual(player, before);
});
```

Run: `cd ui/immune-research-network; node --test tests/research-transaction.test.mjs`

Expected: FAIL because `researchNode` is not implemented.

- [ ] **Step 3: 實作前置組與外部條件**

`prerequisiteGroups` 支援 `{ mode: "all", nodeIds }` 與 `{ mode: "atLeast", min, nodeIds }`。三融合使用兩組：三個來源身份全部完成，以及三組 ★2 相性中至少兩組完成。角色卡、物品及 Boss／遠征發現旗標放在 `conditions`，不得偽裝成依賴線。

- [ ] **Step 4: 實作協議帶寬與 Apex 限制**

```js
test("protocol loadout enforces bandwidth and one Apex", () => {
  let state = { ...protocolPlayer, protocolBandwidth: 6, equippedProtocolIds: [] };
  state = globalThis.IMMUNE.equipProtocol(catalog, state, "APEX-MEMORY-PROTOCOL").state;
  const secondApex = globalThis.IMMUNE.equipProtocol(catalog, state, "APEX-STERILE-PROTOCOL");
  assert.equal(secondApex.ok, false);
  assert.equal(secondApex.error, "apex_limit");
});
```

戰鬥中 `equipProtocol` 與 `unequipProtocol` 必須返回 `loadout_locked_in_battle`；關卡外更換不扣任何資源。

- [ ] **Step 5: 實作版本化存檔恢復**

`restorePlayer` 只保留新 catalog 仍存在的完成、追蹤及裝備 ID，丟棄移除的 ID，重新計算所有衍生狀態，不信任存檔中的 `ready` 或 `locked`。存檔 key 固定為 `immune.research-network.v1`。

- [ ] **Step 6: 執行規則層全測試**

Run: `cd ui/immune-research-network; node --test tests/unlock-engine.test.mjs tests/research-transaction.test.mjs tests/protocols-persistence.test.mjs`

Expected: PASS；資源不會為負、已完成節點不可重買、追蹤最多三個、協議不超帶寬、最多一個 Apex、版本恢復保留有效進度。

### Task 4: 建立可重現的放射佈局、真實連線與 LOD

**Files:**
- Create: `ui/immune-research-network/src/layout/pair-slots.js`
- Create: `ui/immune-research-network/src/layout/radial-layout.js`
- Create: `ui/immune-research-network/src/layout/edge-routing.js`
- Create: `ui/immune-research-network/src/layout/lod.js`
- Create: `ui/immune-research-network/tests/radial-layout.test.mjs`

**Interfaces:**
- Consumes: `ResearchCatalog` and derived node states。
- Produces: `layoutCatalog(catalog): Map<string, LayoutPoint>`、`buildEdges(catalog): ResearchEdge[]`、`getLod(zoom): "overview"|"structure"|"detail"|"inspect"`。

- [ ] **Step 1: 固定六扇區、六環與十五個 pair 槽位**

世界固定為 3000×3000，中心 `(1500,1500)`。半徑固定為：核心 0；通用科技 180–420；狀態 460；基礎家族 560–850；雙家族 900–1150；三融合 1250–1400；Apex 1500–1650。

`pair-slots.js` 必須使用這張固定表，避免以數學中點造成重疊：

```js
const pairLayoutSlots = {
  TB:[300,980], BM:[0,980], MN:[60,980], NA:[120,980], AD:[180,980], TD:[240,980],
  TM:[330,1060], BN:[30,1060], MA:[90,1060], ND:[150,1060], TA:[210,1060], BD:[270,1060],
  TN:[0,1150], BA:[60,1150], MD:[120,1150]
};
```

- [ ] **Step 2: 先寫座標與 LOD 測試並確認失敗**

```js
test("layout is finite, stable and within the approved world", () => {
  const a = globalThis.IMMUNE.layoutCatalog(catalog);
  const b = globalThis.IMMUNE.layoutCatalog(catalog);
  assert.equal(a.size, 200);
  for (const [id, point] of a) {
    assert.deepEqual(point, b.get(id));
    assert.ok(Number.isFinite(point.x) && Number.isFinite(point.y));
    assert.ok(point.x >= 0 && point.x <= 3000 && point.y >= 0 && point.y <= 3000);
  }
});

test("LOD uses all four approved zoom bands", () => {
  assert.equal(globalThis.IMMUNE.getLod(0.35), "overview");
  assert.equal(globalThis.IMMUNE.getLod(0.8), "structure");
  assert.equal(globalThis.IMMUNE.getLod(1.2), "detail");
  assert.equal(globalThis.IMMUNE.getLod(1.8), "inspect");
});
```

Run: `cd ui/immune-research-network; node --test tests/radial-layout.test.mjs`

Expected: FAIL because layout APIs do not exist.

- [ ] **Step 3: 實作節點位置和四種 edge**

`ResearchEdge.kind` 只可為 `required`、`dual_source`、`optional`、`affinity`。只有前兩種參與解鎖；`affinity` 必須是點線資訊。SVG path 使用二次曲線或三次曲線繞開核心，不得把所有 pair 直接拉成穿越中心的直線。

- [ ] **Step 4: 執行布局測試**

Run: `cd ui/immune-research-network; node --test tests/radial-layout.test.mjs`

Expected: PASS；200 個座標固定、31 個 anchor 帶 `anchor: true`、所有 edge 端點存在、篩選不會觸發布局重算。

### Task 5: 渲染真正的 SVG 研究星盤與詳情骨架

**Files:**
- Create: `ui/immune-research-network/src/state/store.js`
- Create: `ui/immune-research-network/src/views/app-shell.js`
- Create: `ui/immune-research-network/src/views/tree-map.js`
- Create: `ui/immune-research-network/src/views/detail-panel.js`
- Create: `ui/immune-research-network/src/views/minimap.js`
- Create: `ui/immune-research-network/src/main.js`
- Modify: `ui/immune-research-network/src/styles/tokens.css`
- Modify: `ui/immune-research-network/src/styles/shell.css`
- Modify: `ui/immune-research-network/src/styles/tree-map.css`

**Interfaces:**
- Consumes: catalog、player state、layout map、ResearchEdge[]。
- Produces: `createStore(initialState)`、`mountResearchApp(root, dependencies)`、`renderTreeMap(svg, viewModel)`、`renderDetailPanel(panel, viewModel)`、`renderMinimap(container, viewModel)`。

- [ ] **Step 1: 實作單向 store**

```js
const store = IMMUNE.createStore(initialState);
const unsubscribe = store.subscribe(nextState => render(nextState));
store.dispatch({ type: "SELECT_NODE", nodeId: "BASE-T-04" });
```

`getState()` 返回目前 immutable snapshot；`dispatch()` 是唯一修改入口。畫面不得直接改寫 `completedNodeIds`、資源或協議陣列。

- [ ] **Step 2: 建立 SVG 層級並一次產生 200 節點**

`#tree-svg` 內固定包含 `#world-transform`，其下依序是 `#sector-layer`、`#edge-layer`、`#node-layer`、`#label-layer`、`#feedback-layer`。節點及連線共享同一個 transform；拖曳期間只更新 `#world-transform` 的 `transform`，不可重建 200 個 DOM 節點。

所有資料文字使用 `textContent`；不可將 catalog 內容拼入 `innerHTML`。每個節點設 `data-node-id`、`data-kind`、`data-state`、`tabindex`、`role="button"` 與可讀 `aria-label`。

- [ ] **Step 3: 實作四級視覺密度**

overview 只顯示六扇區、31 anchor 及總進度；structure 加普通節點和主幹；detail 加名稱、類型及狀態；inspect 加成本、短效果和前置提示。未發現節點只顯示匿名輪廓，不建立帶真名的 `aria-label`。

- [ ] **Step 4: 實作右側詳情與迷你地圖**

鎖定節點必須列出可點擊前置、精確缺口及取得方式。迷你地圖固定映射 3000×3000 世界，顯示目前 viewport rectangle；點擊迷你地圖會平移至對應位置但保留 zoom。

- [ ] **Step 5: 啟動開發頁並手動煙霧檢查**

Run: `cd ui/immune-research-network; node scripts/serve.mjs`

Expected: `http://127.0.0.1:4173/` 顯示中央核心、六個家族扇區、真實完成數與右側詳情；控制台沒有 error；DOM 中正好 200 個 `[data-node-id]`。

### Task 6: 完成縮放、聚焦、搜尋、篩選、路線高亮與輸入

**Files:**
- Create: `ui/immune-research-network/src/domain/search-filter.js`
- Create: `ui/immune-research-network/src/input/pan-zoom.js`
- Create: `ui/immune-research-network/src/input/keyboard-gamepad.js`
- Modify: `ui/immune-research-network/src/views/tree-map.js`
- Modify: `ui/immune-research-network/src/views/app-shell.js`
- Modify: `ui/immune-research-network/src/views/detail-panel.js`
- Create: `ui/immune-research-network/tests/search-filter.test.mjs`

**Interfaces:**
- Consumes: catalog、runtime state、layout map 及 store。
- Produces: `searchCatalog(catalog, player, query)`、`applyFilters(catalog, player, filters)`、`createPanZoom({ viewport, world, minZoom, maxZoom, onChange })`、`focusRoute(nodeId)`。

- [ ] **Step 1: 先寫搜尋防劇透和座標不變測試**

```js
test("search returns T mobility uniquely and hides undiscovered names", () => {
  const visible = globalThis.IMMUNE.searchCatalog(catalog, demoPlayer, "T 細胞移動資格");
  assert.deepEqual(visible.map(node => node.id), ["BASE-T-04"]);
  const hiddenName = catalog.nodes.find(node => node.id === "CHAR-APEX-MEMORY").name;
  assert.deepEqual(globalThis.IMMUNE.searchCatalog(catalog, demoPlayer, hiddenName), []);
});

test("filtering changes emphasis but not layout", () => {
  const before = globalThis.IMMUNE.layoutCatalog(catalog);
  globalThis.IMMUNE.applyFilters(catalog, demoPlayer, { familyIds:["T"] });
  const after = globalThis.IMMUNE.layoutCatalog(catalog);
  assert.deepEqual([...after], [...before]);
});
```

Run: `cd ui/immune-research-network; node --test tests/search-filter.test.mjs`

Expected: FAIL before implementation, then PASS after `search-filter.js` is complete.

- [ ] **Step 2: 實作以游標為中心的 zoom 和受限 pan**

wheel／雙指縮放夾在 0.35–2.4；世界不可完全離開 viewport。提供「顯示全圖」、「返回核心」、「聚焦目前路線」。雙擊角色 anchor 把群組置中至約 1.05×，Escape 回到上一個 camera bookmark。

- [ ] **Step 3: 實作搜尋、篩選與聚焦線路**

搜尋支援名稱、角色、狀態、敵人 tag、效果關鍵字與三種模式。選擇角色時亮起祖先、八項專屬研究、五個 pair 方向與可達後續；選擇 pair 時只亮兩個來源和後續。無關內容維持 DOM 但降至 10%–20% opacity。

- [ ] **Step 4: 實作鍵盤與 gamepad 語義**

Tab 進入工具列／畫布／詳情／協議托盤；方向鍵在畫布選擇角度最接近的相鄰節點；Enter 開啟詳情；F 追蹤；R 研究；Home 返回核心；肩鍵切換家族扇區。若瀏覽器沒有 Gamepad API，鍵盤路徑仍須完整。

- [ ] **Step 5: Browser 互動檢查**

Target flow: `載入全圖 → 搜尋「T 細胞移動資格」→ 唯一結果聚焦 → 選擇節點 → 顯示精確前置與缺口 → 顯示全圖`。

Expected: 搜尋流程在 10 秒內完成；zoom 永遠在 0.35–2.4；過濾前後同一節點的世界座標不變；雙家族節點同時亮起兩條來源路線。

### Task 7: 完成固定垂直切片、研究協議配置與持久化回饋

**Files:**
- Create: `ui/immune-research-network/src/demo-scenario.js`
- Create: `ui/immune-research-network/src/views/protocol-dock.js`
- Create: `ui/immune-research-network/src/views/feedback.js`
- Modify: `ui/immune-research-network/src/state/store.js`
- Modify: `ui/immune-research-network/src/state/persistence.js`
- Modify: `ui/immune-research-network/src/views/detail-panel.js`
- Modify: `ui/immune-research-network/src/main.js`

**Interfaces:**
- Consumes: Task 3 domain actions and Task 5/6 views。
- Produces: `createDemoPlayer(catalog)`、`renderProtocolDock(container, viewModel)`、`playUnlockFeedback(result)`，以及每次成功 action 後自動保存。

- [ ] **Step 1: 建立固定 22 節點初始劇本**

初始清單固定包括：核心、T／B 角色錨點、六個通用分支入口、T 前五項、B 前三項、T+B 的 ★1／★2／★3 輪廓，以及標記／抗體狀態。初始完成數和資源由該清單推導；不得用隨機數決定揭示內容。

- [ ] **Step 2: 接通研究交易與後續揭示**

指定普通研究成功後固定揭示 `BASE-T-04`「T 細胞移動資格」及 `PAIR-TB-S1`「記憶獵手｜基礎相性」。快速雙擊研究按鈕只可成功一次；失敗不得播放成功動畫或扣資源。

- [ ] **Step 3: 實作協議托盤**

托盤顯示 `已用／總帶寬`、每個協議成本、Apex 標誌、裝備／卸下操作及衝突原因。垂直切片至少有一項已解鎖普通協議可裝備；將它裝入後帶寬由 `0/6` 變成 `1/6`，重新整理後仍維持。

- [ ] **Step 4: 實作可降低動態的解鎖回饋**

正常模式依序執行：能量沿必要線流動、節點細胞膜成熟、資源平滑扣除、兩個後續節點亮起、詳情顯示永久玩法改變。`prefers-reduced-motion: reduce` 時以 150ms opacity／outline 變化取代路徑流動。

- [ ] **Step 5: Browser 完整垂直切片檢查**

Target flow: `全圖 → T 細胞 → 查看並追蹤前置 → 完成普通研究 → 兩個新節點亮起 → T+B 融合 → 看見雙來源與缺少融合核心 → 裝備一項協議 → reload`。

Expected: 完成數和資源精確更新一次；追蹤最多三項；刷新後完成、追蹤、資源、協議及 camera 全部恢復。

### Task 8: 補齊列表視圖、響應式與無障礙體驗

**Files:**
- Create: `ui/immune-research-network/src/views/research-list.js`
- Modify: `ui/immune-research-network/src/input/keyboard-gamepad.js`
- Modify: `ui/immune-research-network/src/styles/shell.css`
- Modify: `ui/immune-research-network/src/styles/tree-map.css`
- Modify: `ui/immune-research-network/src/styles/responsive.css`
- Modify: `ui/immune-research-network/index.html`

**Interfaces:**
- Consumes: 同一個 catalog、runtime states、filters 和 selection。
- Produces: 地圖／列表切換、可見 focus ring、非色彩狀態符號、三個目標解像度版面。

- [ ] **Step 1: 建立共用資料的列表視圖**

列表依家族／環層分組，顯示與地圖相同的完成、鎖定、缺資源、追蹤和未發現狀態。從列表選擇已揭示節點會切回地圖並聚焦；未發現項目只顯示「未知研究」和輪廓，不顯示真名。

- [ ] **Step 2: 完成 1280×720 與 1280×800 版面**

1280×720：右側詳情固定 320px，頂部資源列不超過 72px，協議托盤為底部可收合抽屜。1280×800：詳情 340px，托盤可同時顯示三個協議。1920×1080：詳情 380px，迷你地圖 180×180。任何目標解像度都不可遮住搜尋、研究按鈕或畫布主操作。

- [ ] **Step 3: 完成無障礙與 reduced-motion**

所有互動目標至少 44px；狀態同時使用符號和文字；焦點圈與背景對比清晰；toast 使用 `aria-live="polite"`；資源不足訊息與 research button 以 `aria-describedby` 關聯；動態偏好生效。

- [ ] **Step 4: Browser 三解像度檢查**

逐一以 1280×720、1280×800、1920×1080 檢查：無橫向溢出、右側面板不遮主工具、協議托盤可操作、列表與地圖 selection 同步、鍵盤能完成 Task 7 流程。

### Task 9: 建置單一 H5、完整自動測試與視覺驗收

**Files:**
- Create: `ui/immune-research-network/scripts/build-single-file.mjs`
- Create: `ui/immune-research-network/scripts/serve.mjs`
- Create: `outputs/immune_research_network_v1.html`
- Verify: `outputs/concepts/immune_research_network_concept_a.png` or `outputs/concepts/immune_research_network_concept_b.png`

**Interfaces:**
- Consumes: 所有已通過測試的來源檔及已批准概念。
- Produces: 一個沒有外部請求、可由 `file:///` 直接開啟的 `outputs/immune_research_network_v1.html`。

- [ ] **Step 1: 實作零依賴靜態 server**

`serve.mjs` 使用 Node `http`，固定預設 `127.0.0.1:4173`，只服務 `ui/immune-research-network` 目錄，並為 `.html`、`.css`、`.js`、`.svg` 設正確 MIME；任何解析後超出該目錄的 path 返回 403。

- [ ] **Step 2: 實作單檔建置器**

`build-single-file.mjs` 讀取 `index.html`，依 DOM 出現順序把本地 stylesheet 轉成 `<style>`，把本地 defer scripts 轉成同序 `<script>`；內嵌 JavaScript 必須將 `</script` 轉義為 `<\\/script`。輸出前刪除 source map 註解，最後檢查 HTML 不含 `src="`、`href="src/`、`fetch(` 或 `import(`。

核心替換函式需符合：

```js
async function inlineLocalAssets(html, root) {
  for (const href of [...html.matchAll(/<link[^>]+href="([^"]+\.css)"[^>]*>/g)].map(m => m[1])) {
    const css = await readFile(resolve(root, href), "utf8");
    html = html.replace(new RegExp(`<link[^>]+href="${escapeRegExp(href)}"[^>]*>`), `<style>\n${css}\n</style>`);
  }
  for (const src of [...html.matchAll(/<script[^>]+src="([^"]+\.js)"[^>]*><\\/script>/g)].map(m => m[1])) {
    const js = (await readFile(resolve(root, src), "utf8")).replace(/<\\/script/gi, "<\\\\/script");
    html = html.replace(new RegExp(`<script[^>]+src="${escapeRegExp(src)}"[^>]*><\\/script>`), `<script>\n${js}\n<\\/script>`);
  }
  return html;
}
```

- [ ] **Step 3: 執行全部測試與建置**

Run:

```powershell
cd ui/immune-research-network
node --test
node scripts/build-single-file.mjs
```

Expected: 全部測試 PASS；輸出自檢顯示 `200 nodes / 31 anchors / valid DAG / no external runtime assets`。

- [ ] **Step 4: 先用 Codex in-app Browser 驗證成品**

使用 `control-in-app-browser` skill，載入 `file:///.../outputs/immune_research_network_v1.html`。依 frontend testing 流程核對：URL 和 title、非空 DOM、沒有 error overlay、console 無相關 error/warn、主畫面 screenshot、Task 7 完整互動、重新整理存檔、三個目標 viewport，以及未發現搜尋防劇透。

- [ ] **Step 5: 視覺 fidelity 比對並修正至通過**

保存最新 browser screenshot 到 workspace 外的暫存位置。使用 `view_image` 同一次檢視已批准概念與最新 screenshot，逐項核對至少：版面比例、六扇區、節點層級、31 anchor 可辨性、色彩、字體、面板密度、連線樣式、迷你地圖、資源列及協議托盤。任何可修正差異都必須回到來源碼修正、重建並重新截圖。

- [ ] **Step 6: 最終交付檢查**

Expected:

```text
200 個真實節點；31 個角色錨點；真實完成數
搜尋 T 細胞移動資格 ≤ 10 秒
雙家族來源路線同時亮起
研究扣款一次；後續節點揭示；協議可裝備
刷新保留進度；未發現內容不劇透
1280×720、1280×800、1920×1080 無遮擋
file:/// 直接開啟；無外部請求；console 無相關錯誤
```

最終回覆必須提供：成品連結、採用概念連結、三個已測 viewport、Browser 驗證方法、完整互動路徑、至少五項視覺比對結果、已修正差異、剩餘刻意偏差；沒有剩餘重大偏差時要明確說明。

## Execution Order

```text
Task 1 視覺概念與骨架（使用者視覺批准閘門）
  ↓
Task 2 catalog
  ├── Task 3 規則／交易／協議／存檔
  └── Task 4 佈局／連線／LOD
          ↓
Task 5 SVG 星盤骨架
  ↓
Task 6 地圖互動
  ↓
Task 7 垂直切片與協議
  ↓
Task 8 響應式／列表／無障礙
  ↓
Task 9 單檔建置與 Browser 驗收
```
