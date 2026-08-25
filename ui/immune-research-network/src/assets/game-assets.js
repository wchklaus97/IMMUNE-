(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  function skillRow(id, name, slot, unlockNodeId, requires, tier, levelLink, route) {
    return { id, name, slot, unlockNodeId, requires, tier, levelLink, route };
  }

  function baseSkills(code, names) {
    return [
      skillRow(`SKILL-${code}-PASSIVE`, names.passive, "passive", `BASE-${code}-02`, [], 1, "L01", "2-1"),
      skillRow(`SKILL-${code}-ACTIVE`, names.active, "active", `BASE-${code}-01`, [], 1, "L01", "2-1"),
      skillRow(`SKILL-${code}-FIXED`, names.fixed, "fixed", `BASE-${code}-03`, [`SKILL-${code}-PASSIVE`, `SKILL-${code}-ACTIVE`], 1, "L02", "2-1"),
      skillRow(`SKILL-${code}-APEX`, names.apex, "apex", `BASE-${code}-08`, [`SKILL-${code}-FIXED`], 3, "L05", "3-1")
    ];
  }

  /** @type {Record<string, { id: string, name: string, families: string[], role: string, skills: Array<{ id: string, name: string, slot: string, unlockNodeId?: string, requires?: string[], tier?: number, levelLink?: string, route?: string }> }>} */
  const characters = {
    "CHAR-BASE-T": {
      id: "CHAR-BASE-T",
      name: "T 細胞",
      families: ["T"],
      role: "精準追擊、連擊",
      skills: baseSkills("T", { passive: "細胞毒刃", active: "集中處決", fixed: "適應型炮台", apex: "T 細胞終極免疫" })
    },
    "CHAR-BASE-B": {
      id: "CHAR-BASE-B",
      name: "B 細胞",
      families: ["B"],
      role: "抗體生產核心",
      skills: baseSkills("B", { passive: "抗體生成", active: "記憶增幅", fixed: "生產型炮台", apex: "B 細胞終極免疫" })
    },
    "CHAR-BASE-M": {
      id: "CHAR-BASE-M",
      name: "巨噬細胞",
      families: ["M"],
      role: "吞噬、推擠、救援",
      skills: baseSkills("M", { passive: "吞噬回收", active: "固定消化爐", fixed: "經濟坦克炮台", apex: "巨噬終極免疫" })
    },
    "CHAR-BASE-N": {
      id: "CHAR-BASE-N",
      name: "NK 細胞",
      families: ["N"],
      role: "高速截擊精英",
      skills: baseSkills("N", { passive: "快速截擊", active: "靜默獵殺", fixed: "刺殺型炮台", apex: "NK 終極免疫" })
    },
    "CHAR-BASE-A": {
      id: "CHAR-BASE-A",
      name: "抗體構造體",
      families: ["A"],
      role: "浮游追蹤彈群",
      skills: baseSkills("A", { passive: "弱點標記", active: "導引炮台", fixed: "遠程中繼炮台", apex: "抗體終極免疫" })
    },
    "CHAR-BASE-D": {
      id: "CHAR-BASE-D",
      name: "樹突細胞",
      families: ["D"],
      role: "偵察感染區",
      skills: baseSkills("D", { passive: "抗原掃描", active: "免疫信標", fixed: "支援型炮台", apex: "樹突終極免疫" })
    }
  };

  const pairDefs = [
    ["TB", "記憶獵手", "T+B", "長戰適應"],
    ["TM", "吞噬突擊", "T+M", "前線反擊"],
    ["TN", "細胞毒刃", "T+N", "連續處決"],
    ["TA", "精準抗體", "T+A", "裝甲穿透"],
    ["TD", "免疫指揮", "T+D", "戰術換防"],
    ["BM", "抗原處理", "B+M", "資源處理"],
    ["BN", "標記處決", "B+N", "延遲爆破"],
    ["BA", "抗體風暴", "B+A", "飽和清場"],
    ["BD", "抗原呈現", "B+D", "情報反制"],
    ["MN", "感染清除", "M+N", "區域淨化"],
    ["MA", "免疫壁壘", "M+A", "投射物防禦"],
    ["MD", "抗原中樞", "M+D", "生物質轉化"],
    ["NA", "抗體追獵", "N+A", "全圖防漏"],
    ["ND", "獵殺信標", "N+D", "Boss 打斷"],
    ["AD", "免疫網絡", "A+D", "跨區中繼"]
  ];

  for (const [code, name, famKey, role] of pairDefs) {
    const fams = famKey.split("+");
    characters[`CHAR-PAIR-${code}`] = {
      id: `CHAR-PAIR-${code}`,
      name,
      families: fams,
      role,
      skills: [
        skillRow(`SKILL-${code}-P1`, `${name}｜基礎相性`, "passive", `PAIR-${code}-S1`, [], 1, "L01", "2-1"),
        skillRow(`SKILL-${code}-P2`, `${name}｜強化協同`, "active", `PAIR-${code}-S2`, [], 1, "L02", "2-1"),
        skillRow(`SKILL-${code}-FIXED`, `${name}｜固定融合`, "fixed", `CHAR-PAIR-${code}`, [`SKILL-${code}-P1`, `SKILL-${code}-P2`], 1, "L03", "2-1"),
        skillRow(`SKILL-${code}-PROTO`, `${name}｜傳承協議`, "protocol", `PAIR-${code}-S4`, [`SKILL-${code}-FIXED`], 2, "L04", "2-1")
      ]
    };
  }

  const tripleDefs = [
    ["TBA", "適應免疫核心", "T+B+A"],
    ["TND", "全域截擊中樞", "T+N+D"],
    ["MAD", "組織防衛聖域", "M+A+D"],
    ["BMD", "組織再生工廠", "B+M+D"],
    ["BNA", "抗體獵殺蜂群", "B+N+A"],
    ["TMN", "凋亡反應爐", "T+M+N"]
  ];

  for (const [code, name, famKey] of tripleDefs) {
    characters[`CHAR-TRIPLE-${code}`] = {
      id: `CHAR-TRIPLE-${code}`,
      name,
      families: famKey.split("+"),
      role: "三家族融合",
      skills: [
        skillRow(`SKILL-${code}-ROLE`, `${name}｜戰場定位`, "passive", `TRIPLE-${code}-ROLE`, [], 2, "L04", "3-1"),
        skillRow(`SKILL-${code}-RULE`, `${name}｜專屬規則`, "active", `TRIPLE-${code}-RULE`, [], 2, "L04", "3-1"),
        skillRow(`SKILL-${code}-FIXED`, `${name}｜固定形態`, "fixed", `CHAR-TRIPLE-${code}`, [`SKILL-${code}-ROLE`, `SKILL-${code}-RULE`], 2, "L04", "3-1"),
        skillRow(`SKILL-${code}-APEX`, `${name}｜Apex 連結`, "apex", `TRIPLE-${code}-APEX`, [`SKILL-${code}-FIXED`], 3, "L05", "3-1")
      ]
    };
  }

  const apexDefs = [
    ["MEMORY", "長期免疫記憶庫", ["T", "B"]],
    ["STERILE", "無菌聖域", ["M", "A"]],
    ["SILENT", "靜默獵殺網", ["N", "D"]],
    ["PRIME", "IMMUNE PRIME", ["T", "B", "M", "N", "A", "D"]]
  ];

  for (const [code, name, fams] of apexDefs) {
    const id = code === "PRIME" ? "CHAR-PRIME" : `CHAR-APEX-${code}`;
    const gateId = `APEX-${code}-GATE`;
    const protocolId = `APEX-${code}-PROTOCOL`;
    characters[id] = {
      id,
      name,
      families: fams,
      role: code === "PRIME" ? "終局淨化" : "隱藏 Apex",
      skills: [
        skillRow(`SKILL-${code}-GATE`, `${name}｜門檻`, "passive", gateId, [], 3, "L06", "3-1"),
        skillRow(`SKILL-${code}-PROTO`, `${name}｜協議`, "protocol", protocolId, [`SKILL-${code}-GATE`], 3, "L06", "3-1"),
        skillRow(`SKILL-${code}-DEF`, `${name}｜防線`, "fixed", gateId, [`SKILL-${code}-GATE`], 3, "L06", "3-1"),
        skillRow(`SKILL-${code}-ULT`, `${name}｜終局`, "apex", protocolId, [`SKILL-${code}-PROTO`], 3, "L06", "3-1")
      ]
    };
  }

  function setForms(charId, forms) {
    if (characters[charId]) characters[charId].forms = forms;
  }

  for (const code of ["T", "B", "M", "N", "D"]) {
    setForms(`CHAR-BASE-${code}`, {
      fixed: {
        label: "固定炮台",
        assetSuffix: "fixed",
        unlockNodeId: `BASE-${code}-03`,
        unlockMode: "completed"
      },
      mobile: {
        label: "移動單位",
        assetSuffix: "mobile",
        unlockNodeId: `BASE-${code}-04`,
        unlockMode: "completed",
        kind: "mobile"
      }
    });
  }

  setForms("CHAR-BASE-A", {
    fixed: {
      label: "固定炮台",
      assetSuffix: "fixed",
      unlockNodeId: "BASE-A-03",
      unlockMode: "completed"
    },
    mobile: {
      label: "固定中繼",
      assetSuffix: "relay",
      unlockNodeId: "BASE-A-04",
      unlockMode: "completed",
      kind: "relay",
      note: "抗體構造體不提供自由移動，僅強化固定中繼。"
    }
  });

  for (const [code] of pairDefs) {
    const [f1, f2] = famKeyToFamilies(code);
    setForms(`CHAR-PAIR-${code}`, {
      fixed: {
        label: "固定融合",
        assetSuffix: "fixed",
        unlockNodeId: `CHAR-PAIR-${code}`,
        unlockMode: "revealed"
      },
      mobile: {
        label: "移動融合",
        assetSuffix: "mobile",
        unlockNodeIds: [`BASE-${f1}-04`, `BASE-${f2}-04`],
        unlockMode: "all_completed",
        kind: "mobile"
      }
    });
  }

  for (const [code] of tripleDefs) {
    setForms(`CHAR-TRIPLE-${code}`, {
      fixed: {
        label: "固定形態",
        assetSuffix: "fixed",
        unlockNodeId: `CHAR-TRIPLE-${code}`,
        unlockMode: "revealed"
      },
      mobile: {
        label: "移動形態",
        assetSuffix: "mobile",
        unlockNodeId: `TRIPLE-${code}-ROLE`,
        unlockMode: "completed",
        kind: "mobile"
      }
    });
  }

  setForms("CHAR-APEX-MEMORY", {
    fixed: { label: "固定 Apex", assetSuffix: "fixed", unlockNodeId: "CHAR-APEX-MEMORY", unlockMode: "revealed" },
    mobile: { label: "移動 Apex", assetSuffix: "mobile", unlockNodeId: "APEX-MEMORY-GATE", unlockMode: "completed", kind: "mobile" }
  });
  setForms("CHAR-APEX-STERILE", {
    fixed: { label: "固定 Apex", assetSuffix: "fixed", unlockNodeId: "CHAR-APEX-STERILE", unlockMode: "revealed" },
    mobile: { label: "移動 Apex", assetSuffix: "mobile", unlockNodeId: "APEX-STERILE-GATE", unlockMode: "completed", kind: "mobile" }
  });
  setForms("CHAR-APEX-SILENT", {
    fixed: { label: "固定 Apex", assetSuffix: "fixed", unlockNodeId: "CHAR-APEX-SILENT", unlockMode: "revealed" },
    mobile: { label: "移動 Apex", assetSuffix: "mobile", unlockNodeId: "APEX-SILENT-GATE", unlockMode: "completed", kind: "mobile" }
  });
  setForms("CHAR-PRIME", {
    fixed: { label: "固定終局", assetSuffix: "fixed", unlockNodeId: "CHAR-PRIME", unlockMode: "revealed" },
    mobile: { label: "移動終局", assetSuffix: "mobile", unlockNodeId: "APEX-PRIME-GATE", unlockMode: "completed", kind: "mobile" }
  });

  function famKeyToFamilies(code) {
    return globalThis.IMMUNE.definitions.pairSourceFamilies[code];
  }

  function isFormUnlocked(player, character, formKey) {
    const form = character.forms?.[formKey];
    if (!form) return false;
    const completed = new Set(player.completedNodeIds || []);
    const revealed = new Set(player.revealedNodeIds || []);

    if (form.unlockMode === "completed") {
      return form.unlockNodeId ? completed.has(form.unlockNodeId) : false;
    }
    if (form.unlockMode === "revealed") {
      return form.unlockNodeId ? revealed.has(form.unlockNodeId) : false;
    }
    if (form.unlockMode === "all_completed") {
      return (form.unlockNodeIds || []).every((id) => completed.has(id));
    }
    return false;
  }

  function formUnlockHint(player, character, formKey) {
    const form = character.forms?.[formKey];
    if (!form) return "";
    if (isFormUnlocked(player, character, formKey)) return "已解鎖";
    if (form.note) return form.note;
    if (form.unlockMode === "all_completed" && form.unlockNodeIds?.length) {
      return `需完成：${form.unlockNodeIds.join("、")}`;
    }
    if (form.unlockNodeId) return `需完成研究：${form.unlockNodeId}`;
    return "尚未解鎖";
  }

  /** @type {Array<{ id: string, name: string, category: string, description: string }>} */
  const defenseTargets = [
    { id: "DEF-CORE", name: "免疫核心", category: "core", description: "必須守住的 5×5 核心防守區" },
    { id: "DEF-TOWER-SLOT", name: "固定塔位", category: "structure", description: "可放置固定免疫炮台的位置" },
    { id: "DEF-ROUTE", name: "敵人入侵路線", category: "structure", description: "受塔位影響的敵人路徑" },
    { id: "ENEMY-BACTERIA", name: "普通細菌", category: "pathogen", description: "基礎入侵單位，可被吞噬" },
    { id: "ENEMY-VIRUS", name: "病毒群", category: "pathogen", description: "高擴散威脅，偏狀態疊加" },
    { id: "ENEMY-PARASITE", name: "寄生體", category: "pathogen", description: "附著型敵人，需標記處決" },
    { id: "ENEMY-ELITE", name: "精英突變菌株", category: "pathogen", description: "高血量精英，需破防後處決" },
    { id: "ENEMY-INFECTION", name: "感染節點", category: "hazard", description: "遠征需清除的感染據點" },
    { id: "BOSS-ASSAULT", name: "進攻型 Boss", category: "boss", description: "主動突襲核心的高風險敵人" },
    { id: "BOSS-FORTRESS", name: "防守型 Boss", category: "boss", description: "據點型 Boss，需突破防線" },
    { id: "BOSS-HYBRID", name: "隨機攻守 Boss", category: "boss", description: "攻守模式切換的 Boss" },
    { id: "ENEMY-RAID", name: "核心突襲隊", category: "pathogen", description: "全面戰爭中直撲核心的部隊" },
    { id: "ENEMY-FUNGUS", name: "真菌群落", category: "pathogen", description: "慢速佔領格，孢子擴散" },
    { id: "ENEMY-TOXIN", name: "毒素殘渣", category: "hazard", description: "佔格傷害與超抗原壓力" }
  ];

  const defenseByCategory = {
    core: ["DEF-CORE"],
    universal_defense: ["DEF-CORE", "DEF-TOWER-SLOT", "DEF-ROUTE"],
    universal_expedition: ["ENEMY-INFECTION", "ENEMY-FUNGUS"],
    universal_war: ["ENEMY-RAID", "ENEMY-TOXIN", "BOSS-ASSAULT", "BOSS-FORTRESS", "BOSS-HYBRID"],
    status: ["ENEMY-VIRUS", "ENEMY-PARASITE"],
    character: ["ENEMY-BACTERIA", "ENEMY-ELITE"],
    default: ["ENEMY-BACTERIA"]
  };

  function characterForNode(node) {
    if (!node) return null;
    if (node.kind === "character_anchor") return characters[node.id] || null;
    if (node.id.startsWith("CHAR-")) return characters[node.id] || null;
    if (node.familyIds?.length === 2 && node.kind === "pair_research") {
      const code = node.familyIds.slice().sort().join("");
      return characters[`CHAR-PAIR-${code}`] || null;
    }
    if (node.familyIds?.length === 3) {
      const match = Object.keys(characters).find((key) => {
        const c = characters[key];
        return (
          key.startsWith("CHAR-TRIPLE-") &&
          c.families.length === 3 &&
          c.families.every((f) => node.familyIds.includes(f))
        );
      });
      return match ? characters[match] : null;
    }
    if (node.familyIds?.length === 1 && node.kind === "base_character_research") {
      return characters[`CHAR-BASE-${node.familyIds[0]}`] || null;
    }
    return null;
  }

  function defenseTargetsForNode(node) {
    if (!node) return [];
    const ids = new Set();
    if (node.categoryIds?.includes("core")) ids.add("DEF-CORE");
    if (node.categoryIds?.some((c) => c.includes("def") || c === "universal_defense")) {
      for (const id of defenseByCategory.universal_defense) ids.add(id);
    }
    if (node.tags?.includes("expedition") || node.categoryIds?.includes("expedition")) {
      for (const id of defenseByCategory.universal_expedition) ids.add(id);
    }
    if (node.tags?.includes("war") || node.categoryIds?.includes("war")) {
      for (const id of defenseByCategory.universal_war) ids.add(id);
    }
    if (node.kind === "status") {
      for (const id of defenseByCategory.status) ids.add(id);
    }
    if (node.kind === "base_character_research" || node.kind === "character_anchor") {
      for (const id of defenseByCategory.character) ids.add(id);
    }
    if (!ids.size) {
      for (const id of defenseByCategory.default) ids.add(id);
    }
    return defenseTargets.filter((t) => ids.has(t.id));
  }

  IMMUNE.gameAssets = {
    characters,
    defenseTargets,
    characterForNode,
    defenseTargetsForNode,
    isFormUnlocked,
    formUnlockHint
  };
})(globalThis);
