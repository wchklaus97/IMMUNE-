(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  const families = [
    ["T", "T 細胞", "#45bdf2"],
    ["B", "B 細胞", "#a878ff"],
    ["M", "巨噬細胞", "#d28cff"],
    ["N", "NK 細胞", "#a6c94a"],
    ["A", "抗體構造體", "#f2b84b"],
    ["D", "樹突細胞", "#ff9b58"]
  ];

  const pairCharacters = [
    ["TB", "記憶獵手"],
    ["TM", "吞噬突擊"],
    ["TN", "細胞毒刃"],
    ["TA", "精準抗體"],
    ["TD", "免疫指揮"],
    ["BM", "抗原處理"],
    ["BN", "標記處決"],
    ["BA", "抗體風暴"],
    ["BD", "抗原呈現"],
    ["MN", "感染清除"],
    ["MA", "免疫壁壘"],
    ["MD", "抗原中樞"],
    ["NA", "抗體追獵"],
    ["ND", "獵殺信標"],
    ["AD", "免疫網絡"]
  ];

  const tripleCharacters = [
    ["TBA", "適應免疫核心"],
    ["TND", "全域截擊中樞"],
    ["MAD", "組織防衛聖域"],
    ["BMD", "組織再生工廠"],
    ["BNA", "抗體獵殺蜂群"],
    ["TMN", "凋亡反應爐"]
  ];

  const apexCharacters = [
    ["MEMORY", "長期免疫記憶庫"],
    ["STERILE", "無菌聖域"],
    ["SILENT", "靜默獵殺網"],
    ["PRIME", "IMMUNE PRIME"]
  ];

  const statuses = ["標記", "抗體", "腐蝕", "緩速", "感染", "鏈鎖", "暴擊"];

  const statusCodes = ["MARK", "AB", "COR", "SLOW", "INF", "CHAIN", "CRIT"];

  const universalDomains = [
    "防守工程",
    "遠征探索",
    "全面戰爭",
    "細胞機動",
    "融合工程",
    "生存修復"
  ];

  const universalDomainCodes = [
    ["DEF", "防守工程"],
    ["EXP", "遠征探索"],
    ["WAR", "全面戰爭"],
    ["MOB", "細胞機動"],
    ["FUS", "融合工程"],
    ["SUR", "生存修復"]
  ];

  const baseCharacters = [
    ["T", "T 細胞"],
    ["B", "B 細胞"],
    ["M", "巨噬細胞"],
    ["N", "NK 細胞"],
    ["A", "抗體構造體"],
    ["D", "樹突細胞"]
  ];

  const baseRoleResearch = {
    T: {
      usageName: "T 細胞部署資格",
      corePassiveName: "細胞毒殺核心",
      fixedTurretName: "T 細胞固定炮台專精",
      mobilityQualificationName: "T 細胞移動資格",
      targetingName: "抗原特異追獵",
      formationName: "T 細胞陣容共鳴",
      awakeningName: "細胞毒覺醒",
      ultimateName: "T 細胞終極免疫"
    },
    B: {
      usageName: "B 細胞部署資格",
      corePassiveName: "抗體分泌核心",
      fixedTurretName: "B 細胞固定炮台專精",
      mobilityQualificationName: "B 細胞移動資格",
      targetingName: "遠距標記鎖定",
      formationName: "B 細胞陣容共鳴",
      awakeningName: "漿細胞覺醒",
      ultimateName: "B 細胞終極免疫"
    },
    M: {
      usageName: "巨噬細胞部署資格",
      corePassiveName: "吞噬回收核心",
      fixedTurretName: "巨噬固定炮台專精",
      mobilityQualificationName: "巨噬細胞移動資格",
      targetingName: "感染殘留追獵",
      formationName: "巨噬陣容共鳴",
      awakeningName: "組織修復覺醒",
      ultimateName: "巨噬終極免疫"
    },
    N: {
      usageName: "NK 細胞部署資格",
      corePassiveName: "天然細胞毒核心",
      fixedTurretName: "NK 固定炮台專精",
      mobilityQualificationName: "NK 細胞移動資格",
      targetingName: "異常細胞獵殺",
      formationName: "NK 陣容共鳴",
      awakeningName: "無抗體覺醒",
      ultimateName: "NK 終極免疫"
    },
    A: {
      usageName: "抗體構造體部署資格",
      corePassiveName: "中和抗體核心",
      fixedTurretName: "抗體固定炮台專精",
      mobilityQualificationName: "抗體固定中繼資格",
      targetingName: "抗原中和鎖定",
      formationName: "抗體陣容共鳴",
      awakeningName: "多價抗體覺醒",
      ultimateName: "抗體終極免疫"
    },
    D: {
      usageName: "樹突細胞部署資格",
      corePassiveName: "抗原呈現核心",
      fixedTurretName: "樹突固定炮台專精",
      mobilityQualificationName: "樹突細胞移動資格",
      targetingName: "免疫信號引導",
      formationName: "樹突陣容共鳴",
      awakeningName: "共刺激覺醒",
      ultimateName: "樹突終極免疫"
    }
  };

  function globalStat(stat, amount, extra = {}) {
    return { op: "grant_global_stat", stat, amount, scope: extra.scope || "all", ...extra };
  }

  /** Six core sub-layers around CORE-IMMUNE. Same 42 IDs; names/effects are global, not family kits. */
  const universalLayers = {
    DEF: [
      { name: "核心修復效率", description: "全域防線：免疫核心持續修復加快。同名百分比只由防線環提供。", effects: [globalStat("coreRegen", 0.06, { scope: "core" })] },
      { name: "固定塔位擴充", description: "全域防線：可同時展開的固定炮台席次 +1，不是傷害百分比。", effects: [globalStat("towerSlots", 1, { scope: "core" })] },
      { name: "塔間支援鏈", description: "2-1 匯合：修復與塔位連成支援鏈。規則解鎖，不再疊修復%。", effects: [globalStat("towerLink", 1, { scope: "core" })] },
      { name: "路線干擾障壁", description: "敵人沿入侵路線被輕微減速。與狀態化學緩速分開，數值較小。", effects: [globalStat("pathSlow", 0.05, { scope: "enemy" })] },
      { name: "核心緊急護盾", description: "核心生命低於閾值時展開一次護盾。一次性規則。", effects: [globalStat("coreShield", 0.15, { scope: "core" })] },
      { name: "防守波次預備", description: "每波開始前為核心與固定炮台預補一次耐久。", effects: [globalStat("wavePrep", 1, { scope: "core" })] },
      { name: "核心終極防線", description: "3-1 匯合：護盾強化。不再疊加修復百分比。", effects: [globalStat("coreShield", 0.1, { scope: "core" })] }
    ],
    EXP: [
      { name: "偵察範圍延伸", description: "全域遠征：揭示距離 +6%。", effects: [globalStat("scoutRange", 0.06)] },
      { name: "迷霧預覽強化", description: "未進入的感染區可預覽敵人族群。規則解鎖。", effects: [globalStat("fogPreview", 1)] },
      { name: "遠征節點解鎖", description: "2-1 匯合：開放下一層遠征節點。不是視野%。", effects: [globalStat("expeditionNodes", 1)] },
      { name: "邊疆建造資格", description: "可在遠征格放置臨時固定席。", effects: [globalStat("frontierBuild", 1)] },
      { name: "遠征補給效率", description: "遠征帶回資源 +6%。", effects: [globalStat("expeditionYield", 0.06)] },
      { name: "撤退窗口延長", description: "強制撤退前的安全窗口延長。規則。", effects: [globalStat("retreatWindow", 0.12)] },
      { name: "疆域終極擴張", description: "3-1 匯合：再 +4% 遠征補給。不再疊視野。", effects: [globalStat("expeditionYield", 0.04)] }
    ],
    WAR: [
      { name: "全體攻擊節奏", description: "全域戰爭：全體攻速 +5%。攻速只從戰爭環來，機動環不再給攻速。", effects: [globalStat("attackSpeed", 0.05)] },
      { name: "軍團橫向容量", description: "全域戰爭：橫向軍團席次 +1。容量不是百分比，避免和攻速雙疊。", effects: [globalStat("armyCap", 1)] },
      { name: "全域火力同步", description: "2-1 匯合：再 +4% 攻速。合併點小於第一枝，避免越合越大。", effects: [globalStat("attackSpeed", 0.04)] },
      { name: "固定炮台射速", description: "僅固定勤務 +4% 射速。與全體攻速分開計算。", effects: [globalStat("attackSpeed", 0.04, { duty: "fixed" })] },
      { name: "移動追擊節奏", description: "僅移動勤務 +4% 攻速。與固定射速互斥加成。", effects: [globalStat("attackSpeed", 0.04, { duty: "mobile" })] },
      { name: "技能冷卻壓縮", description: "全體冷卻 −6%。走冷卻軸，不再疊攻速。", effects: [globalStat("cooldown", 0.06)] },
      { name: "全面戰爭終極戰術", description: "3-1 匯合：再 +4% 攻速。冷卻已在上一枝，終局不雙疊。", effects: [globalStat("attackSpeed", 0.04)] }
    ],
    MOB: [
      { name: "全體移動節奏", description: "全域機動：移速 +6%。移速只從機動環來。", effects: [globalStat("moveSpeed", 0.06)] },
      { name: "快速部署通道", description: "部署前搖縮短 8%。不是攻速。", effects: [globalStat("deploySpeed", 0.08)] },
      { name: "跨區域轉移", description: "2-1 匯合：解鎖跨區轉移規則，不再疊移速%。", effects: [globalStat("relocateSpeed", 0.08)] },
      { name: "移動單位耐久", description: "移動勤務生命 +6%。生存軸，不是輸出。", effects: [globalStat("mobileHp", 0.06, { duty: "mobile" })] },
      { name: "機動協同增幅", description: "近距離移動單位互相獲得編隊加成。規則解鎖，不含攻速。", effects: [globalStat("formationBonus", 1, { duty: "mobile" })] },
      { name: "撤退掩護編隊", description: "撤退時移動單位為核心提供短暫掩護射擊。", effects: [globalStat("retreatCover", 1, { duty: "mobile" })] },
      { name: "機動終極編隊", description: "3-1 匯合：再 +4% 移速。不把攻速塞進機動終局。", effects: [globalStat("moveSpeed", 0.04)] }
    ],
    FUS: [
      { name: "雙家族相性基礎", description: "全域融合：雙家族相性研究消耗略降。不直接加傷害。", effects: [globalStat("pairCost", -0.05, { scope: "fusion" })] },
      { name: "融合效率增幅", description: "融合核心轉換效率 +6%。", effects: [globalStat("fusionYield", 0.06, { scope: "fusion" })] },
      { name: "三融合資格預備", description: "2-1 匯合：開放三融合資格檢查，不是輸出%。", effects: [globalStat("tripleReady", 1, { scope: "fusion" })] },
      { name: "傳承特質保留", description: "融合後保留更多來源家族被動。規則解鎖。", effects: [globalStat("legacyKeep", 1, { scope: "fusion" })] },
      { name: "融合核心回收", description: "替換融合時退回 20% 融合核心。", effects: [globalStat("fusionRefund", 0.2, { scope: "fusion" })] },
      { name: "Apex 路線預備", description: "顯示隱藏 Apex 所需的遠征旗標缺口。", effects: [globalStat("apexPreview", 1, { scope: "fusion" })] },
      { name: "融合終極工程", description: "3-1 匯合：再 +4% 融合效率。不再疊相性折抵。", effects: [globalStat("fusionYield", 0.04, { scope: "fusion" })] }
    ],
    SUR: [
      { name: "生物質回收效率", description: "全域生存：生物質回收 +6%。回收只從生存環來。", effects: [globalStat("biomassYield", 0.06)] },
      { name: "受傷修復加速", description: "單位再生 +6%。不修核心（核心修復在防線環）。", effects: [globalStat("unitRegen", 0.06)] },
      { name: "核心緊急修復", description: "2-1 匯合：波次間核心一次急救。規則，不再疊核心修復%。", effects: [globalStat("corePulseHeal", 1, { scope: "core" })] },
      { name: "細胞再生儲備", description: "擊殺儲存再生電荷。規則解鎖。", effects: [globalStat("regenBank", 1)] },
      { name: "陣亡後備援", description: "陣亡後短暫再部署一次。規則解鎖。", effects: [globalStat("backupDeploy", 1)] },
      { name: "資源短缺緩解", description: "資源見底時下一波掉落保底。", effects: [globalStat("resourceFloor", 1)] },
      { name: "生存終極修復", description: "3-1 匯合：再 +4% 單位再生。不疊生物質與核心修復。", effects: [globalStat("unitRegen", 0.04)] }
    ]
  };

  const universalResearchNames = Object.fromEntries(
    Object.entries(universalLayers).map(([code, rows]) => [code, rows.map((row) => row.name)])
  );

  const statusLayers = {
    MARK: {
      name: "標記疊層化學",
      description: "全域化學：標記最高疊層 +1，持續期間被標記目標受到額外集火權重。",
      effects: [globalStat("markStacks", 1, { scope: "status" })]
    },
    AB: {
      name: "抗體弱點化學",
      description: "全域化學：弱點放大 +8%。狀態環負責易傷，戰爭環負責攻速。",
      effects: [globalStat("weaknessAmp", 0.08, { scope: "status" })]
    },
    COR: {
      name: "腐蝕破防化學",
      description: "2-1 匯合：破甲 +8%。規則轉化，不把弱點再加一次。",
      effects: [globalStat("armorShred", 0.08, { scope: "status" })]
    },
    SLOW: {
      name: "緩速控制化學",
      description: "受控敵人移速 −8%。與防線路線障壁分開。",
      effects: [globalStat("enemySlow", 0.08, { scope: "enemy" })]
    },
    INF: {
      name: "感染擴散化學",
      description: "擊殺或疊滿時，狀態可跳到鄰近敵人。",
      effects: [globalStat("statusSpread", 1, { scope: "status" })]
    },
    CHAIN: {
      name: "鏈鎖跳躍化學",
      description: "連鎖傷害與標記可額外跳一次。",
      effects: [globalStat("chainJumps", 1, { scope: "status" })]
    },
    CRIT: {
      name: "暴擊觸發化學",
      description: "3-1 匯合：全域暴擊 +5%。終局給觸發率，不再疊弱點與破甲。",
      effects: [globalStat("critChance", 0.05, { scope: "status" })]
    }
  };

  const statusResearchNames = Object.fromEntries(
    Object.entries(statusLayers).map(([code, row]) => [code, row.name])
  );

  const pairResearchTemplates = {
    S1: "基礎相性",
    S2: "強化協同",
    S4: "傳承特質協議"
  };

  const tripleResearchTemplates = {
    ROLE: "戰場定位",
    RULE: "專屬規則",
    APEX: "Apex 連結"
  };

  const apexResearchTemplates = {
    GATE: "終局門檻",
    PROTOCOL: "終局協議"
  };

  const tripleSourceFamilies = {
    TBA: ["T", "B", "A"],
    TND: ["T", "N", "D"],
    MAD: ["M", "A", "D"],
    BMD: ["B", "M", "D"],
    BNA: ["B", "N", "A"],
    TMN: ["T", "M", "N"]
  };

  const pairSourceFamilies = {
    TB: ["T", "B"],
    TM: ["T", "M"],
    TN: ["T", "N"],
    TA: ["T", "A"],
    TD: ["T", "D"],
    BM: ["B", "M"],
    BN: ["B", "N"],
    BA: ["B", "A"],
    BD: ["B", "D"],
    MN: ["M", "N"],
    MA: ["M", "A"],
    MD: ["M", "D"],
    NA: ["N", "A"],
    ND: ["N", "D"],
    AD: ["A", "D"]
  };

  const triplePairPrerequisites = {
    TBA: ["TB", "TA", "BA"],
    TND: ["TN", "TD", "ND"],
    MAD: ["MA", "MD", "AD"],
    BMD: ["BM", "BD", "MD"],
    BNA: ["BN", "BA", "NA"],
    TMN: ["TM", "MN", "TN"]
  };

  const campaignLevels = [
    ["L01", "黏膜入口"],
    ["L02", "血流回廊"],
    ["L03", "淋巴濾站"],
    ["L04", "發炎病灶"],
    ["L05", "腫瘤組織"],
    ["L06", "感染本源"]
  ];

  IMMUNE.definitions = {
    families,
    pairCharacters,
    tripleCharacters,
    apexCharacters,
    statuses,
    statusCodes,
    universalDomains,
    universalDomainCodes,
    baseCharacters,
    baseRoleResearch,
    universalLayers,
    universalResearchNames,
    statusLayers,
    statusResearchNames,
    pairResearchTemplates,
    tripleResearchTemplates,
    apexResearchTemplates,
    tripleSourceFamilies,
    pairSourceFamilies,
    triplePairPrerequisites,
    campaignLevels,
    catalogVersion: "1.0.0"
  };
})(globalThis);
