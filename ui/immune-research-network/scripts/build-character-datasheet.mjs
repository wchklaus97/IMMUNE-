import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";
import { generateDatasheetPreviews } from "./generate-datasheet-previews.mjs";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(__dirname, "..");
const TEMPLATE = join(__dirname, "datasheet-page.html");
const MANIFEST = join(ROOT, "assets/manifest.json");
const UI_OUT = join(ROOT, "datasheet.html");
const FILE_OUT = resolve(ROOT, "../../outputs/immune_character_datasheet.html");

const base = [
  ["IMM-001", "基礎", "T細胞", "T", "精準追擊、連擊", "單體殺傷區", "適應／穿透／持續輸出", "細胞毒刃", "集中處決", "適應型"],
  ["IMM-002", "基礎", "B細胞", "B", "採集抗原、支援", "抗體生產核心", "生產／記憶／增益", "抗體生成", "記憶增幅", "生產型"],
  ["IMM-003", "基礎", "巨噬細胞", "M", "吞噬、推擠、救援", "阻擋與吞噬區", "承傷／控制／回收", "吞噬回收", "固定消化爐", "經濟／坦克型"],
  ["IMM-004", "基礎", "NK細胞", "N", "高速截擊精英", "低血量處決區", "突襲／斬殺／威脅優先", "快速截擊", "靜默獵殺", "刺殺型"],
  ["IMM-005", "基礎", "抗體構造體", "A", "浮游追蹤彈群", "遠程導引炮台", "標記／穿透／中繼", "弱點標記", "導引炮台", "遠程型"],
  ["IMM-006", "基礎", "樹突細胞", "D", "偵察感染區", "情報與增幅信標", "掃描／指揮／揭露", "抗原掃描", "免疫信標", "支援型"]
];

const pair = [
  ["IMM-007", "雙融合", "記憶獵手", "T+B", "長戰適應", "B記錄菌株；T對重複敵人累積反制傷害", "記憶標記", "學習追擊", "固定記憶陣", "長期反制", "適應型", "T←B"],
  ["IMM-008", "雙融合", "吞噬突擊", "T+M", "前線反擊", "巨噬承傷聚怪；T將吸收量轉成反擊", "吞噬反擊", "衝撞吞噬", "吞噬壁壘", "反擊爆發", "坦克型", "M←T"],
  ["IMM-009", "雙融合", "細胞毒刃", "T+N", "連續處決", "T削弱防禦；NK接續斬殺並刷新下一目標", "毒刃連鎖", "追擊斬殺", "處決陣列", "連殺重置", "攻擊型", "T←N"],
  ["IMM-010", "雙融合", "精準抗體", "T+A", "裝甲穿透", "T鎖定弱點；抗體遠距穿透部位", "弱點穿透", "精準集火", "導引炮台", "穿甲爆發", "遠程型", "A←T"],
  ["IMM-011", "雙融合", "免疫指揮", "T+D", "戰術換防", "樹突傳遞指令；T快速重新分配火力", "戰術中繼", "快速換防", "指揮信標", "全隊重定向", "支援型", "D←T"],
  ["IMM-012", "雙融合", "抗原處理", "B+M", "資源處理", "巨噬回收殘骸；B轉換成抗原樣本", "抗原回收", "吞噬採樣", "處理中樞", "資源增幅", "經濟型", "M←B"],
  ["IMM-013", "雙融合", "標記處決", "B+N", "延遲爆破", "B植入標記；NK擊殺時引發連鎖爆破", "爆破標記", "標記突進", "處決信標", "多重爆破", "攻擊型", "B←N"],
  ["IMM-014", "雙融合", "抗體風暴", "B+A", "飽和清場", "B大量生產；抗體形成追蹤彈幕", "抗體生產", "移動播種", "風暴炮台", "全域彈幕", "攻擊型", "B←A"],
  ["IMM-015", "雙融合", "抗原呈現", "B+D", "情報反制", "分析敵方突變並把反制資料分享全隊", "弱點共享", "採集呈現", "呈現信標", "反制循環", "支援型", "D←B"],
  ["IMM-016", "雙融合", "感染清除", "M+N", "區域淨化", "NK殺敵；巨噬清理殘骸並阻止再感染", "殘骸清除", "突襲清理", "淨化壁壘", "感染重置", "控制型", "N←M"],
  ["IMM-017", "雙融合", "免疫壁壘", "M+A", "投射物防禦", "巨噬阻擋；抗體攔截遠程攻擊並生成護盾", "吞噬護盾", "推進護衛", "護盾壁壘", "無菌領域", "防禦型", "M←A"],
  ["IMM-018", "雙融合", "抗原中樞", "M+D", "生物質轉化", "生物質轉換成治療、助手及淨化進度", "生物質轉化", "吞噬供料", "中樞反應爐", "再生脈衝", "經濟型", "D←M"],
  ["IMM-019", "雙融合", "抗體追獵", "N+A", "全圖防漏", "抗體追蹤逃敵；NK跨區截擊", "追蹤鎖定", "獵殺逃敵", "追獵炮台", "全圖處決", "刺殺型", "N←A"],
  ["IMM-020", "雙融合", "獵殺信標", "N+D", "Boss打斷", "樹突標記弱點；NK在信標間突進", "信標鎖殺", "信標突進", "鎖殺陣列", "沉默打斷", "控制型", "N←D"],
  ["IMM-021", "雙融合", "免疫網絡", "A+D", "跨區中繼", "樹突建立節點；抗體跨區傳遞攻擊和增益", "節點連線", "節點穿梭", "網絡炮台", "全域中繼", "支援型", "A←D"]
];

const triple = [
  ["IMM-022", "三融合", "適應免疫核心", "T+B+A", "突變反制", "分析主導菌株，動態改變抗體傷害特性", "適應彈幕", "採集學習", "固定適應核心", "抗性重編程", "攻擊／適應", "T←A+B"],
  ["IMM-023", "三融合", "全域截擊中樞", "T+N+D", "多戰區救火", "偵測前線缺口並投射T／NK快速截擊", "截擊中繼", "跨區截擊", "全域信標", "戰區同步", "支援／控制", "D←N+T"],
  ["IMM-024", "三融合", "組織防衛聖域", "M+A+D", "永久陣地", "建立健康安全區，阻止感染重新擴張", "聖域建立", "護送建點", "聖域炮台", "無菌穹頂", "防禦／控制", "A←M+D"],
  ["IMM-025", "三融合", "組織再生巢", "B+M+D", "戰場修復", "將抗原與生物質轉化成修復地形與部署點", "再生合成", "採集修復", "再生中樞", "器官修復", "支援／經濟", "B←M+D"],
  ["IMM-026", "三融合", "抗體獵殺蜂群", "B+N+A", "多精英追獵", "分出多支自主獵殺隊同時鎖定精英", "蜂群鎖定", "蜂群追獵", "獵殺蜂巢", "多重處決", "攻擊／刺殺", "N←A+B"],
  ["IMM-027", "三融合", "凋亡反應爐", "T+M+N", "高風險爆發", "儲存吞噬能量後釋放Boss破防爆發", "凋亡蓄能", "近線蓄能", "反應爐壁壘", "爆發凋亡", "攻擊／坦克", "M←N+T"]
];

const apex = [
  ["IMM-028", "全六融合", "全域免疫核心・IMMUNE PRIME", "T+B+M+N+A+D", "終局戰場狀態", "連接健康區、揭露最終感染核心並投射直控化身", "全域覺醒", "六家族同步", "統合核心", "終局淨化", "終局型", "Unified Rig"],
  ["IMM-029", "隱藏Apex", "長期免疫記憶庫", "T+B", "永久反制", "保留一種菌株的反制資料至後續波次", "記憶庫寫入", "標記保留", "記憶中樞", "跨波次反制", "適應型", "記憶獵手分支"],
  ["IMM-030", "隱藏Apex", "無菌聖域", "M+A", "永久防線", "放棄部分攻擊，建立近乎不可突破的淨化領域", "聖域展開", "護盾推進", "無菌穹頂", "區域重置", "防禦型", "免疫壁壘分支"],
  ["IMM-031", "隱藏Apex", "靜默獵殺網", "N+D", "全圖控制", "中斷Boss技能、突變傳播及敵方增援訊號", "靜默協議", "信標突進", "沉默網絡", "全域封鎖", "控制型", "獵殺信標分支"]
];

const APEX_IDS = {
  "T+B": "CHAR-APEX-MEMORY",
  "M+A": "CHAR-APEX-STERILE",
  "N+D": "CHAR-APEX-SILENT"
};

function characterId(type, recipe) {
  if (type === "基礎") return `CHAR-BASE-${recipe}`;
  if (type === "雙融合") return `CHAR-PAIR-${recipe.replaceAll("+", "")}`;
  if (type === "三融合") return `CHAR-TRIPLE-${recipe.replaceAll("+", "")}`;
  if (type === "全六融合") return "CHAR-PRIME";
  if (type === "隱藏Apex") return APEX_IDS[recipe];
  throw new Error(`unknown type ${type}`);
}

function formMeta(type, recipe) {
  if (type === "基礎" && recipe === "A") {
    return {
      fixed: { label: "固定炮台", kind: "fixed" },
      mobile: { label: "固定中繼", kind: "relay" }
    };
  }
  if (type === "基礎") {
    return {
      fixed: { label: "固定炮台", kind: "fixed" },
      mobile: { label: "移動單位", kind: "mobile" }
    };
  }
  if (type === "雙融合") {
    return {
      fixed: { label: "固定融合", kind: "fixed" },
      mobile: { label: "移動融合", kind: "mobile" }
    };
  }
  if (type === "三融合") {
    return {
      fixed: { label: "固定形態", kind: "fixed" },
      mobile: { label: "移動形態", kind: "mobile" }
    };
  }
  if (type === "全六融合") {
    return {
      fixed: { label: "固定終局", kind: "fixed" },
      mobile: { label: "移動終局", kind: "mobile" }
    };
  }
  return {
    fixed: { label: "固定 Apex", kind: "fixed" },
    mobile: { label: "移動 Apex", kind: "mobile" }
  };
}

function relativeFormPath(absPath) {
  return String(absPath || "").replace(/^assets\//, "");
}

function previewPath(relPng) {
  const fileName = String(relPng).split("/").pop() || "";
  return `characters/previews/${fileName.replace(/\.png$/i, ".jpg")}`;
}

export function buildSheetPayload(manifest) {
  const rows = [...base, ...pair, ...triple, ...apex];
  const characters = rows.map((r) => {
    const type = r[1];
    const id = characterId(type, r[3]);
    const entry = manifest.characters[id];
    if (!entry) throw new Error(`manifest missing ${id}`);
    const labels = formMeta(type, r[3]);
    const isBase = type === "基礎";
    return {
      immId: r[0],
      id,
      type,
      name: r[2],
      recipe: r[3],
      families: r[3].split("+"),
      body: isBase ? r[3] : r[11],
      role: r[4],
      zone: isBase ? r[5] : r[5],
      attrs: isBase ? r[6] : r[5],
      active: isBase ? r[7] : r[6],
      mobileSkill: isBase ? r[4] : r[7],
      fixedSkill: isBase ? r[5] : r[8],
      fixedBehavior: isBase ? r[5] : r[8],
      apex: isBase ? `家族Apex：${r[8]}` : r[9],
      tree: isBase ? r[9] : r[10],
      status: isBase ? "可養成" : type === "隱藏Apex" ? "共用資產分支" : type === "全六融合" ? "終局身份" : "固定融合身份",
      forms: {
        catalog: {
          label: "目錄臉",
          kind: "catalog",
          src: relativeFormPath(entry.png),
          preview: previewPath(relativeFormPath(entry.png))
        },
        fixed: {
          ...labels.fixed,
          src: relativeFormPath(entry.forms.fixed),
          preview: previewPath(relativeFormPath(entry.forms.fixed))
        },
        mobile: {
          ...labels.mobile,
          src: relativeFormPath(entry.forms.mobile),
          preview: previewPath(relativeFormPath(entry.forms.mobile))
        }
      }
    };
  });

  const fam = ["T", "B", "M", "N", "A", "D"];
  const cn = { T: "T細胞", B: "B細胞", M: "巨噬細胞", N: "NK細胞", A: "抗體構造體", D: "樹突細胞" };
  const named = new Map();
  for (const r of [...pair, ...triple, ...apex]) named.set(r[3], r[2]);
  const relations = [];
  function choose(start, k, acc = []) {
    if (acc.length === k) {
      relations.push(acc.join("+"));
      return;
    }
    for (let i = start; i <= fam.length - (k - acc.length); i += 1) choose(i + 1, k, [...acc, fam[i]]);
  }
  for (let k = 2; k <= 6; k += 1) choose(0, k);
  const relationRows = relations.map((x, i) => {
    const n = x.split("+").length;
    const name = named.get(x) || "";
    const physical = name && (n === 2 || n === 3 || n === 6) ? "是" : "否";
    const status = name
      ? n === 2
        ? "★1被動／★3固定融合"
        : n === 3
          ? "★5指定融合"
          : n === 6
            ? "★5終局融合"
            : "Apex分支"
      : "只疊加雙家族被動";
    return ["R-" + String(i + 1).padStart(2, "0"), n, x, x.split("+").map((y) => cn[y]).join("＋"), name, name ? "是" : "否", physical, status];
  });
  relationRows.push(["A-01", "Apex", "T+B", "T細胞＋B細胞", "長期免疫記憶庫", "是", "共用模型", "★5隱藏分支"]);
  relationRows.push(["A-02", "Apex", "M+A", "巨噬細胞＋抗體構造體", "無菌聖域", "是", "共用模型", "★5隱藏分支"]);
  relationRows.push(["A-03", "Apex", "N+D", "NK細胞＋樹突細胞", "靜默獵殺網", "是", "共用模型", "★5隱藏分支"]);

  const balance = [
    ["吞噬技能", "普通敵人生命線", 25, "%", "低於此生命值可吞噬"],
    ["吞噬技能", "大型／精英生命線", 15, "%", "低血並先破防或失衡"],
    ["吞噬技能", "吞噬冷卻", 7, "秒", "移動形態主動技能"],
    ["吞噬技能", "初始胃袋容量", 10, "生物質", "容量滿後需固定消化"],
    ["吞噬經濟", "每批升級點需求", 10, "生物質→1共享升級點", ""],
    ["永久材料", "普通敵人一度概率", 5, "%", "只計合資格敵人"],
    ["永久材料", "大型敵人一度概率", 15, "%", "只計合資格敵人"],
    ["永久材料", "精英敵人一度概率", 30, "%", "只計合資格敵人"],
    ["永久材料", "一度保底次數", 10, "次合資格消化", ""],
    ["永久材料", "每局吞噬一度上限", 3, "個", "其他來源另計"],
    ["永久材料", "目標平均產出", "1–2", "個／局", ""],
    ["反濫用", "吞噬來源總供應比例", "25–30%", "永久材料總供應", ""],
    ["星級", "雙融合最低星級", "★3", "", "雙方均需固定"],
    ["星級", "三融合最低星級", "★5", "", "只限指定配方"],
    ["星級", "全六融合最低星級", "★5", "", "特殊終局條件"]
  ];

  const enemies = [
    ["E-001", "病毒族", "基本病毒", "普通", 1, "L01–L06", "漂浮", "接觸感染", "感染脈衝", "T細胞集火／抗體標記", 60, 1.0, 1, "生命低於25%可吞噬"],
    ["E-002", "病毒族", "裂變病毒", "普通", 2, "L01–L06", "彈跳", "死亡分裂", "裂變芽體", "優先擊殺分裂源", 75, 0.9, 1, "裂變後代不重複產材料"],
    ["E-003", "病毒族", "感染病毒", "特殊", 3, "L01–L06", "漂浮", "感染範圍", "感染雲霧", "樹突揭露／遠程清除", 110, 0.8, 1, "低血量可吞噬"],
    ["E-004", "病毒族", "群體病毒", "特殊", 4, "L01–L05", "群聚", "數量壓制", "群體增殖", "範圍傷害／抗體風暴", 45, 1.2, 1, "群體共享生物質額度"],
    ["E-005", "病毒族", "飛行病毒", "特殊", 5, "L01–L06", "飛行", "俯衝感染", "空中突襲", "抗體追獵／NK截擊", 90, 1.5, 1, "需標記或空中攻擊"],
    ["E-006", "病毒族", "突變病毒", "精英", 25, "L04–L06", "漂浮", "適應攻擊", "定期變異", "樹突掃描後再集火", 220, 0.9, 8, "需破防及低於10%"],
    ["E-007", "細菌族", "裝甲細菌", "重型", 3, "L01–L04", "爬行", "高防撞擊", "裝甲外殼", "T穿透／抗體弱點", 300, 0.55, 3, "先破防才可吞噬"],
    ["E-008", "細菌族", "再生細菌", "特殊", 9, "L02–L06", "爬行", "近距咬擊", "生命再生", "NK處決／感染清除", 180, 0.65, 3, "再生時不可吞噬"],
    ["E-009", "細菌族", "細菌群落", "精英", 11, "L02–L06", "群聚", "包圍感染", "群落增殖", "巨噬吞噬核心", 420, 0.45, 8, "核心死亡後群落停止"],
    ["E-010", "細菌族", "生物膜細菌", "精英", 13, "L02–L06", "黏附", "減速黏液", "生物膜護盾", "抗體穿透／樹突標記", 360, 0.35, 8, "護盾破裂後可吞噬"],
    ["E-011", "寄生體族", "吸血寄生體", "特殊", 10, "L02–L06", "跳躍", "吸血附著", "生命偷取", "NK優先斬殺", 160, 1.1, 3, "附著中不可吞噬"],
    ["E-012", "寄生體族", "鑽地寄生體", "特殊", 17, "L03–L06", "鑽地", "地下突襲", "短暫隱形", "樹突揭露／範圍控制", 200, 0.8, 3, "現身或失衡後可吞噬"],
    ["E-013", "寄生體族", "快速寄生體", "特殊", 18, "L03–L06", "高速", "突進撕咬", "連續突進", "T減速／抗體追蹤", 140, 1.8, 3, "先造成硬直"],
    ["E-014", "寄生體族", "模仿寄生體", "精英", 20, "L03–L06", "模仿", "複製炮塔效果", "錯誤模仿", "樹突辨識真偽", 380, 0.7, 8, "解除模仿後才可吞噬"],
    ["E-015", "變異細胞族", "變異細胞 I", "精英", 19, "L03–L06", "爬行", "突變攻擊", "初階進化", "T／NK快速處決", 260, 0.75, 8, "破壞核心可中止進化"],
    ["E-016", "變異細胞族", "變異細胞 II", "精英", 25, "L04–L06", "爬行", "強化攻擊", "高生命與護甲", "抗體穿透／巨噬阻擋", 460, 0.65, 8, "需先拆除護甲"],
    ["E-017", "變異細胞族", "變異細胞 III", "精英", 29, "L04–L06", "爬行", "特殊技能", "核心爆裂", "樹突預警／NK打斷", 620, 0.6, 8, "技能準備時可打斷"],
    ["E-018", "變異細胞族", "自適應細胞", "精英", 33, "L05–L06", "多形態", "反制玩家傷害", "根據傷害類型變化", "切換攻擊類型", 800, 0.55, 8, "同一類傷害不可連續使用"],
    ["E-019", "Boss", "流感核心", "Boss", 8, "L01", "漂浮", "召喚病毒群", "感染肺泡區域", "全家族協同／分區淨化", 3000, 0.4, 0, "不可吞噬本體；殘核可處理"],
    ["E-020", "Boss", "腫瘤巨塊", "Boss", 16, "L02", "膨脹", "生成阻塞塊", "吞噬周圍空間", "巨噬控場／T穿透", 5200, 0.25, 0, "階段殘塊可吞噬"],
    ["E-021", "Boss", "細菌母巢", "Boss", 24, "L03", "固定巢穴", "大量生產細菌", "菌膜擴張", "抗體風暴／樹突斷鏈", 4600, 0.15, 0, "母巢核心不可直接吞噬"],
    ["E-022", "Boss", "寄生女王", "Boss", 32, "L04", "移動", "產卵與附著", "召喚寄生卵", "NK處決／全圖追獵", 6000, 0.45, 0, "卵囊可作吞噬殘骸"],
    ["E-023", "Boss", "變異融合體", "Boss", 40, "L05", "多形態", "混合技能", "階段形態變換", "三家族融合／弱點切換", 8500, 0.5, 0, "只可吞噬階段殘核"],
    ["E-024", "Boss", "感染本源", "Boss", 48, "L06", "核心固定", "扭曲戰場規則", "全域感染", "IMMUNE PRIME終局工具", 12000, 0.2, 0, "不可吞噬；完成終局淨化"],
    ["E-025", "病毒族", "潛伏病毒", "特殊", 6, "L02–L06", "潛行", "現身感染", "短暫隱形", "樹突揭露", 95, 1.1, 1, "現身後可吞噬"],
    ["E-026", "病毒族", "載體病毒", "特殊", 8, "L02–L06", "漂浮", "增益附近病毒", "感染載體", "優先擊殺載體", 130, 0.85, 2, "載體死亡後可吞噬"],
    ["E-027", "細菌族", "基本細菌", "普通", 1, "L01–L06", "爬行", "接觸撞擊", "無", "任意基礎火力", 80, 0.7, 1, "生命低於25%可吞噬"],
    ["E-028", "細菌族", "衝刺細菌", "普通", 4, "L01–L06", "衝刺", "高速撞擊", "短衝刺", "減速／阻擋", 70, 1.4, 1, "硬直後可吞噬"],
    ["E-029", "細菌族", "產毒細菌", "特殊", 10, "L02–L06", "爬行", "遠程毒液", "毒池", "抗體中和／遠程清除", 150, 0.6, 2, "毒池消散後可吞噬"],
    ["E-030", "細菌族", "芽孢細菌", "特殊", 12, "L02–L06", "漂浮", "孢子散布", "死亡爆孢", "範圍淨化", 120, 0.9, 2, "爆孢前擊殺可吞噬"],
    ["E-031", "寄生體族", "幼體寄生", "普通", 9, "L02–L06", "蠕行", "輕咬", "無", "NK／T 清雜", 70, 1.0, 1, "生命低於25%可吞噬"],
    ["E-032", "寄生體族", "卵囊寄生", "特殊", 14, "L03–L06", "固定", "孵化幼體", "產卵", "優先拆卵囊", 200, 0.2, 3, "孵化完成前可吞噬"],
    ["E-033", "寄生體族", "群聚水蛭", "特殊", 16, "L03–L06", "群聚", "圍咬", "吸附疊層", "範圍傷害", 55, 1.3, 1, "群體共享生物質"],
    ["E-034", "寄生體族", "巢穴寄生", "精英", 22, "L03–L06", "固定", "召喚寄生", "巢穴連結", "拆巢再清兵", 480, 0.2, 8, "巢毀後殘核可吞噬"],
    ["E-035", "變異細胞族", "變異幼體", "普通", 17, "L03–L06", "爬行", "接觸攻擊", "慢速進化", "盡快清掉", 140, 0.8, 2, "進化前可吞噬"],
    ["E-036", "變異細胞族", "奔走變異", "特殊", 21, "L03–L06", "奔跑", "衝撞", "短加速", "減速／阻擋", 180, 1.5, 2, "硬直後可吞噬"],
    ["E-037", "變異細胞族", "遠程變異", "特殊", 23, "L04–L06", "爬行", "遠程突變彈", "風箏", "突進近身", 210, 0.7, 3, "低血量可吞噬"],
    ["E-038", "變異細胞族", "壞死變異", "精英", 27, "L04–L06", "爬行", "佔格壞死", "死亡留斑", "巨噬清斑", 400, 0.5, 8, "壞死斑清除後可吞噬"],
    ["E-039", "真菌族", "基本真菌", "普通", 9, "L02–L06", "慢爬", "接觸腐蝕", "無", "巨噬優先", 90, 0.45, 1, "生命低於25%可吞噬"],
    ["E-040", "真菌族", "菌絲網", "特殊", 13, "L02–L06", "蔓延", "減速佔格", "菌絲連結", "範圍燒網", 160, 0.3, 2, "斷網後可吞噬"],
    ["E-041", "真菌族", "孢子囊", "特殊", 15, "L03–L06", "固定", "噴孢子", "死亡爆孢", "遠程拆囊", 220, 0.15, 3, "爆孢前可吞噬"],
    ["E-042", "真菌族", "真菌塔", "精英", 21, "L03–L06", "固定", "占塔繁殖", "菌塔光環", "集火拆塔", 520, 0.1, 8, "塔毀殘核可吞噬"],
    ["E-043", "毒素族", "毒素滴", "普通", 25, "L04–L06", "滑行", "接觸中毒", "無", "抗體中和", 75, 0.9, 1, "生命低於25%可吞噬"],
    ["E-044", "毒素族", "超抗原雲", "特殊", 28, "L04–L06", "漂浮", "範圍壓制", "技能封鎖", "樹突驅散", 180, 0.7, 2, "雲散後可吞噬"],
    ["E-045", "毒素族", "壞死斑", "特殊", 30, "L04–L06", "佔格", "持續傷害格", "留下毒地", "巨噬清地", 200, 0.25, 2, "毒地清除後可吞噬"],
    ["E-046", "毒素族", "毒素核心", "精英", 34, "L05–L06", "慢移", "脈衝毒爆", "抗治療", "A+D 聯手", 560, 0.4, 8, "破核後可吞噬"],
    ["E-047", "突襲隊", "核心突襲兵", "特殊", 33, "L05–L06", "直衝", "無視支路", "鎖定核心", "攔截／中繼", 160, 1.6, 2, "攔截硬直後可吞噬"],
    ["E-048", "突襲隊", "突襲精英", "精英", 41, "L06", "直衝", "破塔衝核", "短暫無敵", "全圖集火", 640, 1.2, 8, "無敵結束後可吞噬"],
    ["E-049", "真菌族", "真菌王", "Boss", 23, "L03", "固定巢穴", "孢子風暴", "菌塔領域", "巨噬燒網／集火拆塔", 7000, 0.12, 0, "不可吞噬本體；殘核可處理"],
    ["E-050", "毒素族", "毒素君主", "Boss", 39, "L05", "慢移", "全域毒脈", "抗治療領域", "A+D 聯手破核", 9000, 0.3, 0, "破核殘渣可處理"],
    ["E-051", "突襲隊", "突襲統帥", "Boss", 47, "L06", "直衝", "破塔衝核", "無敵衝鋒", "全圖攔截／中繼", 8000, 0.9, 0, "無敵結束後殘核可處理"]
  ];

  const levels = [
    ["L01", "第一區", "黏膜入口", "初次感染的紅色黏膜通道", 1, 8, "病毒族／細菌族", "學習吞噬、標記及基本固定防守", "E-019", "初始區域"],
    ["L02", "第二區", "血流回廊", "高速血流與裝甲細菌通道", 9, 16, "病毒族／細菌族／寄生體族／真菌族", "移動壓力、再生、生物膜與菌絲", "E-020", "完成L01"],
    ["L03", "第三區", "淋巴濾站", "免疫訊號匯聚的濾站", 17, 24, "細菌族／寄生體族／變異細胞族／真菌族", "偵察、鑽地、模仿、群落與孢子；第7波真菌王，第8波細菌母巢", "E-021", "完成L02"],
    ["L04", "第四區", "發炎病灶", "腫脹、狹窄及高感染區", 25, 32, "病毒族／寄生體族／變異細胞族／毒素族", "持續失守、技能打斷、區域淨化與毒素", "E-022", "完成L03"],
    ["L05", "第五區", "腫瘤組織", "高密度變異組織與多形態敵人", 33, 40, "全敵人族群／變異細胞族／毒素族／突襲隊", "反制玩家Build及三家族融合；第7波毒素君主，第8波變異融合體", "E-023", "完成L04"],
    ["L06", "終局區", "感染本源", "人體深層感染核心", 41, 48, "全敵人族群／Boss", "全域感染、終局條件及IMMUNE PRIME；第7波突襲統帥，第8波感染本源", "E-024", "完成L05"]
  ];

  const levelPools = {
    L01: ["E-001", "E-002", "E-003", "E-004", "E-005", "E-027", "E-028", "E-007"],
    L02: ["E-001", "E-025", "E-027", "E-008", "E-029", "E-039", "E-040", "E-011", "E-031", "E-010"],
    L03: ["E-026", "E-030", "E-009", "E-032", "E-033", "E-042", "E-012", "E-035", "E-041", "E-015"],
    L04: ["E-006", "E-013", "E-034", "E-036", "E-037", "E-038", "E-043", "E-044", "E-016"],
    L05: ["E-018", "E-038", "E-042", "E-045", "E-046", "E-047", "E-014", "E-017"],
    L06: ["E-018", "E-046", "E-047", "E-048", "E-006", "E-042", "E-014"]
  };
  const levelBoss = { L01: "E-019", L02: "E-020", L03: "E-021", L04: "E-022", L05: "E-023", L06: "E-024" };
  const familyBoss = { L03: "E-049", L05: "E-050", L06: "E-051" };
  const waves = [];
  let waveId = 1;
  for (const l of levels) {
    const pool = levelPools[l[0]];
    for (let local = 1; local <= 8; local += 1) {
      const wave = l[4] + local - 1;
      const herald = familyBoss[l[0]];
      const phase = local === 1 ? "教學波" : local === 8 ? "Boss波" : local === 7 && herald ? "族長波" : local === 7 ? "Boss前壓力波" : local === 5 ? "精英波" : local === 6 ? "高密度波" : local === 4 ? "特殊機制波" : "混合波";
      const take = local === 1 ? 2 : local === 2 ? 3 : local === 3 ? 4 : local === 4 ? 5 : local === 5 ? Math.min(6, pool.length) : local === 6 || local === 7 ? pool.length : Math.min(pool.length, Math.max(3, pool.length - 1));
      const spawn = pool.slice(0, take).join(", ");
      const count = local === 1 ? "6–8" : local === 2 ? "8–12" : local === 3 ? "10–14" : local === 4 ? "12–16" : local === 5 ? "2精英＋12–18" : local === 6 ? "16–24" : local === 7 && herald ? "族長＋14–20" : local === 7 ? "2精英＋18–26" : "Boss＋12–20";
      const boss = local === 8 ? levelBoss[l[0]] : local === 7 && herald ? herald : "";
      const rule = local === 1 ? "首次介紹本區敵人" : local === 2 ? "增加出生點或移動壓力" : local === 3 ? "加入第二敵人家族" : local === 4 ? "啟用本區特殊機制" : local === 5 ? "至少1個精英或重型" : local === 6 ? "感染速度提高20%" : local === 7 && herald ? "族長預告；關卡 Boss 下一波" : local === 7 ? "Boss機制預告" : "關卡 Boss＋可吞噬殘核";
      waves.push(["W-" + String(waveId).padStart(3, "0"), l[0], wave, phase, spawn, count, boss, rule, local === 8 ? "Boss獎勵＋一度來源" : local === 7 && herald ? "族長獎勵＋一度來源" : "一般波次獎勵"]);
      waveId += 1;
    }
  }

  return { characters, relations: relationRows, balance, enemies, levels, waves };
}

export function renderDatasheet(template, payload, assetPrefix) {
  return template
    .replace("%%DATA%%", JSON.stringify(payload))
    .replace("%%ASSET_PREFIX%%", JSON.stringify(assetPrefix));
}

export async function writeDatasheets() {
  try {
    await generateDatasheetPreviews();
  } catch (error) {
    console.warn("datasheet previews skipped:", error.message);
  }
  const template = await readFile(TEMPLATE, "utf8");
  const manifest = JSON.parse(await readFile(MANIFEST, "utf8"));
  const payload = buildSheetPayload(manifest);
  for (const character of payload.characters) {
    for (const form of Object.values(character.forms)) {
      const abs = resolve(ROOT, "assets", form.src);
      if (!existsSync(abs)) throw new Error(`missing portrait ${form.src}`);
    }
  }
  await writeFile(UI_OUT, renderDatasheet(template, payload, "assets/"), "utf8");
  await mkdir(dirname(FILE_OUT), { recursive: true });
  await writeFile(FILE_OUT, renderDatasheet(template, payload, "../ui/immune-research-network/assets/"), "utf8");
  return { characters: payload.characters.length, ui: UI_OUT, file: FILE_OUT };
}

const invoked = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invoked) {
  const result = await writeDatasheets();
  console.log(`datasheet ${result.characters} characters -> ${result.ui}`);
  console.log(`datasheet copy -> ${result.file}`);
}
