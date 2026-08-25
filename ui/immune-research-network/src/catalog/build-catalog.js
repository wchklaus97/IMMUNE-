(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});
  const defs = IMMUNE.definitions;

  function pad2(n) {
    return String(n).padStart(2, "0");
  }

  function makeNode(partial) {
    return {
      familyIds: [],
      categoryIds: [],
      tags: [],
      effectOps: [],
      prerequisiteGroups: [],
      conditions: [],
      costs: [],
      revealRule: { type: "on_prerequisite_visible" },
      layoutHint: { ring: "family", sector: null },
      acquisitionHints: [],
      ...partial
    };
  }

  function antigenCost(amount) {
    return [{ resource: "antigen", amount }];
  }

  function protomassCost(amount) {
    return [{ resource: "protomass", amount }];
  }

  function fusionCost(amount) {
    return [{ resource: "fusionCore", amount }];
  }

  function mixedCost(antigen, protomass, fusionCore = 0) {
    const costs = [];
    if (antigen > 0) costs.push({ resource: "antigen", amount: antigen });
    if (protomass > 0) costs.push({ resource: "protomass", amount: protomass });
    if (fusionCore > 0) costs.push({ resource: "fusionCore", amount: fusionCore });
    return costs;
  }

  function allOf(nodeIds) {
    return [{ mode: "all", nodeIds }];
  }

  function completedReveal(nodeIds) {
    return { type: "completed", nodeIds };
  }

  function levelMeta(tier, levelLink, route) {
    return { tier, levelLink, route };
  }

  function campaignConditions(min, extra = []) {
    const list = extra.map((entry) => ({ ...entry }));
    if (min) list.push({ type: "campaign_level", min });
    return list;
  }

  function campaignHint(min) {
    if (!min) return [];
    const row = (defs.campaignLevels || []).find((entry) => entry[0] === min);
    const name = row ? row[1] : "";
    return [`需解鎖關卡 ${min}${name ? ` ${name}` : ""}`];
  }

  function buildCore() {
    return makeNode({
      id: "CORE-IMMUNE",
      kind: "core",
      name: "免疫核心",
      description: "整張永久研究網絡的起點。核心外圍是六層全域基建（防線、遠征、戰爭、機動、融合、生存）與狀態化學，不綁單一家族。",
      familyIds: [],
      categoryIds: ["core"],
      tags: ["core", "permanent"],
      effectOps: [{ op: "unlock_core_network" }],
      prerequisiteGroups: [],
      revealRule: { type: "always" },
      layoutHint: { ring: "core", sector: null, tier: 0, stage: "core" },
      acquisitionHints: ["初始揭示", "層級 0", "關卡 L01"],
      ...levelMeta(0, "L01", "core")
    });
  }

  function buildCharacterAnchors() {
    const nodes = [];

    for (const [code] of defs.baseCharacters) {
      nodes.push(
        makeNode({
          id: `CHAR-BASE-${code}`,
          kind: "character_anchor",
          name: defs.baseRoleResearch[code].usageName.replace("部署資格", ""),
          description: `${defs.baseCharacters.find(([c]) => c === code)[1]} 的角色身份錨點，標示此家族的研究扇區起點。`,
          familyIds: [code],
          categoryIds: ["character", "base"],
          tags: ["character", "anchor", "base"],
          effectOps: [{ op: "reveal_character_sector", familyId: code }],
          prerequisiteGroups: [{ mode: "all", nodeIds: ["CORE-IMMUNE"] }],
          layoutHint: { ring: "family_anchor", sector: code, tier: 0, stage: "anchor" },
          acquisitionHints: ["層級 0", "關卡 L01"],
          ...levelMeta(0, "L01", "core")
        })
      );
    }

    for (const [code, name] of defs.pairCharacters) {
      const [f1, f2] = defs.pairSourceFamilies[code];
      const s1Id = `PAIR-${code}-S1`;
      const s2Id = `PAIR-${code}-S2`;
      nodes.push(
        makeNode({
          id: `CHAR-PAIR-${code}`,
          kind: "character_anchor",
          name,
          description: `${name} 雙家族融合角色錨點，匯聚 ${f1} 與 ${f2} 兩系能力。`,
          familyIds: [f1, f2],
          categoryIds: ["character", "pair"],
          tags: ["character", "anchor", "pair", "fusion"],
          effectOps: [{ op: "unlock_fusion_character", pairCode: code }],
          prerequisiteGroups: [
            { mode: "all", nodeIds: [s1Id, s2Id] },
            { mode: "all", nodeIds: [`CHAR-BASE-${f1}`, `CHAR-BASE-${f2}`] }
          ],
          costs: fusionCost(1),
          conditions: campaignConditions("L03"),
          layoutHint: { ring: "pair_anchor", sector: code, lane: 0, tier: 1, stage: "merge" },
          acquisitionHints: ["層級 1", "關卡 L03", "2-1", ...campaignHint("L03")],
          ...levelMeta(1, "L03", "2-1")
        })
      );
    }

    for (const [code, name] of defs.tripleCharacters) {
      const families = defs.tripleSourceFamilies[code];
      nodes.push(
        makeNode({
          id: `CHAR-TRIPLE-${code}`,
          kind: "character_anchor",
          name,
          description: `${name} 三家族融合角色錨點，整合 ${families.join("、")} 三系終極能力。`,
          familyIds: families,
          categoryIds: ["character", "triple"],
          tags: ["character", "anchor", "triple", "fusion"],
          effectOps: [{ op: "unlock_triple_character", tripleCode: code }],
          prerequisiteGroups: [
            {
              mode: "all",
              nodeIds: families.map((f) => `CHAR-BASE-${f}`)
            },
            {
              mode: "atLeast",
              min: 2,
              nodeIds: defs.triplePairPrerequisites[code].map((p) => `PAIR-${p}-S2`)
            }
          ],
          costs: fusionCost(2),
          conditions: campaignConditions("L04"),
          layoutHint: { ring: "triple_anchor", sector: code, lane: 0, tier: 2, stage: "merge" },
          acquisitionHints: ["層級 2", "關卡 L04", "3-1", ...campaignHint("L04")],
          ...levelMeta(2, "L04", "3-1")
        })
      );
    }

    for (const [code, name] of defs.apexCharacters) {
      if (code === "PRIME") {
        nodes.push(
          makeNode({
            id: "CHAR-PRIME",
            kind: "character_anchor",
            name,
            description:
              "六大家族終極與任意三個命名三融合成果匯聚的終局身份，不要求完成其餘 199 個節點。",
            familyIds: ["T", "B", "M", "N", "A", "D"],
            categoryIds: ["character", "prime"],
            tags: ["character", "anchor", "prime", "apex"],
            effectOps: [{ op: "unlock_immune_prime" }],
            prerequisiteGroups: [
              {
                mode: "all",
                nodeIds: defs.baseCharacters.map(([c]) => `BASE-${c}-08`)
              },
              {
                mode: "atLeast",
                min: 3,
                nodeIds: defs.tripleCharacters.map(([c]) => `CHAR-TRIPLE-${c}`)
              }
            ],
            costs: mixedCost(0, 5, 3),
            conditions: campaignConditions("L06"),
            revealRule: { type: "on_flag", flag: "prime_discovered" },
            layoutHint: { ring: "prime_anchor", sector: null, tier: 3, stage: "capstone" },
            acquisitionHints: ["完成六家族終極研究", "完成任意三個三融合角色", "層級 3", "關卡 L06", ...campaignHint("L06")],
            ...levelMeta(3, "L06", "3-1")
          })
        );
        continue;
      }

      const pairCode = code === "MEMORY" ? "TB" : code === "STERILE" ? "MA" : "ND";
      nodes.push(
        makeNode({
          id: `CHAR-APEX-${code}`,
          kind: "character_anchor",
          name,
          description: `${name} 隱藏 Apex 身份錨點，需對應雙家族 ★4 協議與遠征發現。`,
          familyIds: defs.pairSourceFamilies[pairCode],
          categoryIds: ["character", "apex"],
          tags: ["character", "anchor", "apex", "hidden"],
          effectOps: [{ op: "unlock_apex_character", apexCode: code }],
          prerequisiteGroups: [{ mode: "all", nodeIds: [`PAIR-${pairCode}-S4`] }],
          costs: fusionCost(2),
          conditions: campaignConditions("L05", [
            { type: "discovery_flag", flag: `apex_${code.toLowerCase()}_found` }
          ]),
          revealRule: { type: "on_flag", flag: `apex_${code.toLowerCase()}_found` },
          layoutHint: { ring: "apex_anchor", sector: code, tier: 3, stage: "capstone" },
          acquisitionHints: [
            `完成 ${defs.pairCharacters.find(([c]) => c === pairCode)[1]} 傳承協議`,
            "遠征 Boss 發現",
            "層級 3",
            "關卡 L05",
            ...campaignHint("L05")
          ],
          ...levelMeta(3, "L05", "3-1")
        })
      );
    }

    return nodes;
  }

  function buildEightBaseNodes([code]) {
    const research = defs.baseRoleResearch[code];
    const names = [
      research.usageName,
      research.corePassiveName,
      research.fixedTurretName,
      research.mobilityQualificationName,
      research.targetingName,
      research.formationName,
      research.awakeningName,
      research.ultimateName
    ];
    const descriptions = [
      `解鎖 ${defs.baseCharacters.find(([c]) => c === code)[1]} 的部署與陣容使用資格。`,
      `強化 ${defs.baseCharacters.find(([c]) => c === code)[1]} 的核心被動與生物學定位。`,
      `提升 ${defs.baseCharacters.find(([c]) => c === code)[1]} 作為固定炮台的效率與射程。`,
      code === "A"
        ? "授予抗體構造體固定中繼資格，強化陣線中繼而非移動單位。"
        : `授予 ${defs.baseCharacters.find(([c]) => c === code)[1]} 在全面戰爭中的移動部署資格。`,
      `優化 ${defs.baseCharacters.find(([c]) => c === code)[1]} 的目標選擇與戰鬥 AI 行為。`,
      `增幅 ${defs.baseCharacters.find(([c]) => c === code)[1]} 與相鄰角色的陣容連結效果。`,
      `覺醒 ${defs.baseCharacters.find(([c]) => c === code)[1]} 的特殊被動與天賦能力。`,
      `${defs.baseCharacters.find(([c]) => c === code)[1]} 家族終極永久研究，解鎖高階融合與 Apex 資格。`
    ];
    const effectOps = [
      [{ op: "grant_character_usage", familyId: code }],
      [{ op: "grant_core_passive", familyId: code }],
      [{ op: "grant_fixed_turret", familyId: code }],
      [{ op: code === "A" ? "grant_relay_qualification" : "grant_mobility", familyId: code }],
      [{ op: "grant_targeting", familyId: code }],
      [{ op: "grant_formation_bonus", familyId: code }],
      [{ op: "grant_awakening", familyId: code }],
      [{ op: "grant_ultimate", familyId: code }]
    ];
    const costs = [
      mixedCost(20, 1),
      mixedCost(25, 0),
      mixedCost(30, 0),
      mixedCost(35, 1),
      mixedCost(40, 0),
      mixedCost(45, 1),
      mixedCost(50, 2),
      mixedCost(60, 3)
    ];
    const routes = [
      { slot: 1, prereq: [`CHAR-BASE-${code}`], reveal: { type: "on_prerequisite_visible" }, lane: -1, tier: 1, stage: "branch", levelLink: "L01", route: "2-1" },
      { slot: 2, prereq: [`CHAR-BASE-${code}`], reveal: { type: "on_prerequisite_visible" }, lane: 1, tier: 1, stage: "branch", levelLink: "L01", route: "2-1" },
      { slot: 3, prereq: [`BASE-${code}-01`, `BASE-${code}-02`], reveal: { type: "on_prerequisite_visible" }, lane: 0, tier: 1, stage: "merge", levelLink: "L02", route: "2-1" },
      { slot: 4, prereq: [`BASE-${code}-03`], reveal: completedReveal([`BASE-${code}-03`]), lane: -1, tier: 2, stage: "branch", levelLink: "L03", route: "3-1", campaignMin: "L02" },
      { slot: 5, prereq: [`BASE-${code}-03`], reveal: completedReveal([`BASE-${code}-03`]), lane: 0, tier: 2, stage: "branch", levelLink: "L03", route: "3-1", campaignMin: "L03" },
      { slot: 6, prereq: [`BASE-${code}-03`], reveal: completedReveal([`BASE-${code}-03`]), lane: 1, tier: 2, stage: "branch", levelLink: "L03", route: "3-1", campaignMin: "L03" },
      { slot: 7, prereq: [`BASE-${code}-04`, `BASE-${code}-05`, `BASE-${code}-06`], reveal: { type: "on_prerequisite_visible" }, lane: 0, tier: 2, stage: "merge", levelLink: "L04", route: "3-1", campaignMin: "L03" },
      { slot: 8, prereq: [`BASE-${code}-07`], reveal: completedReveal([`BASE-${code}-07`]), lane: 0, tier: 3, stage: "capstone", levelLink: "L05", route: "3-1", campaignMin: "L05" }
    ];

    return names.map((name, index) => {
      const spec = routes[index];
      const id = `BASE-${code}-${pad2(spec.slot)}`;
      const meta = levelMeta(spec.tier, spec.levelLink, spec.route);
      return makeNode({
        id,
        kind: "base_character_research",
        name,
        description: descriptions[index],
        familyIds: [code],
        categoryIds: ["base_research"],
        tags: ["base", "permanent", code === "A" && spec.slot === 4 ? "relay" : spec.slot === 4 ? "mobility" : "passive"],
        effectOps: effectOps[index],
        prerequisiteGroups: allOf(spec.prereq),
        costs: costs[index],
        conditions: campaignConditions(spec.campaignMin),
        revealRule: spec.reveal,
        layoutHint: {
          ring: "family",
          sector: code,
          slot: spec.slot,
          lane: spec.lane,
          tier: spec.tier,
          stage: spec.stage
        },
        acquisitionHints: [`層級 ${spec.tier}`, `關卡 ${spec.levelLink}`, spec.route, ...campaignHint(spec.campaignMin)],
        ...meta
      });
    });
  }

  function buildThreePairNodes([code, charName]) {
    const [f1, f2] = defs.pairSourceFamilies[code];
    const s1Id = `PAIR-${code}-S1`;
    const s2Id = `PAIR-${code}-S2`;
    const s4Id = `PAIR-${code}-S4`;

    return [
      makeNode({
        id: s1Id,
        kind: "pair_research",
        name: `${charName}｜${defs.pairResearchTemplates.S1}`,
        description: `建立 ${f1} 與 ${f2} 兩系在戰場上的基礎相性連結。`,
        familyIds: [f1, f2],
        categoryIds: ["pair_research"],
        tags: ["pair", "affinity", "permanent"],
        effectOps: [{ op: "grant_pair_affinity_s1", pairCode: code }],
        prerequisiteGroups: allOf([`BASE-${f1}-01`, `BASE-${f2}-01`]),
        costs: mixedCost(30, 0),
        layoutHint: { ring: "pair", sector: code, slot: 1, lane: -1, tier: 1, stage: "branch" },
        acquisitionHints: ["層級 1", "關卡 L01", "2-1"],
        ...levelMeta(1, "L01", "2-1")
      }),
      makeNode({
        id: s2Id,
        kind: "pair_research",
        name: `${charName}｜${defs.pairResearchTemplates.S2}`,
        description: `強化 ${charName} 路線的協同共鳴，為實體融合鋪路。`,
        familyIds: [f1, f2],
        categoryIds: ["pair_research"],
        tags: ["pair", "synergy", "permanent"],
        effectOps: [{ op: "grant_pair_affinity_s2", pairCode: code }],
        prerequisiteGroups: allOf([`BASE-${f1}-02`, `BASE-${f2}-02`]),
        costs: mixedCost(40, 1),
        layoutHint: { ring: "pair", sector: code, slot: 2, lane: 1, tier: 1, stage: "branch" },
        acquisitionHints: ["層級 1", "關卡 L02", "2-1"],
        ...levelMeta(1, "L02", "2-1")
      }),
      makeNode({
        id: s4Id,
        kind: "pair_research",
        name: `${charName}｜${defs.pairResearchTemplates.S4}`,
        description: `解鎖 ${charName} 傳承特質研究協議，可在關卡前裝備。`,
        familyIds: [f1, f2],
        categoryIds: ["pair_research", "protocol"],
        tags: ["pair", "protocol", "legacy"],
        effectOps: [{ op: "unlock_pair_protocol", pairCode: code }],
        prerequisiteGroups: [{ mode: "all", nodeIds: [`CHAR-PAIR-${code}`] }],
        costs: mixedCost(50, 1, 1),
        bandwidth: 2,
        apex: false,
        exclusiveGroup: `pair-${code.toLowerCase()}-legacy`,
        layoutHint: { ring: "pair", sector: code, slot: 4, lane: 0, tier: 2, stage: "merge" },
        acquisitionHints: ["層級 2", "關卡 L04", "2-1"],
        ...levelMeta(2, "L04", "2-1")
      })
    ];
  }

  function buildThreeTripleNodes([code, charName]) {
    const families = defs.tripleSourceFamilies[code];
    const roleId = `TRIPLE-${code}-ROLE`;
    const ruleId = `TRIPLE-${code}-RULE`;
    const apexId = `TRIPLE-${code}-APEX`;

    return [
      makeNode({
        id: roleId,
        kind: "triple_research",
        name: `${charName}｜${defs.tripleResearchTemplates.ROLE}`,
        description: `定義 ${charName} 在戰場上的核心定位與編隊角色。`,
        familyIds: families,
        categoryIds: ["triple_research"],
        tags: ["triple", "role", "permanent"],
        effectOps: [{ op: "grant_triple_role", tripleCode: code }],
        prerequisiteGroups: allOf([`CHAR-TRIPLE-${code}`]),
        costs: mixedCost(45, 1),
        layoutHint: { ring: "triple", sector: code, slot: 1, lane: -1, tier: 2, stage: "branch" },
        acquisitionHints: ["層級 2", "關卡 L04", "3-1"],
        ...levelMeta(2, "L04", "3-1")
      }),
      makeNode({
        id: ruleId,
        kind: "triple_research",
        name: `${charName}｜${defs.tripleResearchTemplates.RULE}`,
        description: `授予 ${charName} 專屬戰鬥規則與陣容互動例外。`,
        familyIds: families,
        categoryIds: ["triple_research"],
        tags: ["triple", "rule", "permanent"],
        effectOps: [{ op: "grant_triple_rule", tripleCode: code }],
        prerequisiteGroups: allOf([`CHAR-TRIPLE-${code}`]),
        costs: mixedCost(50, 1),
        layoutHint: { ring: "triple", sector: code, slot: 2, lane: 1, tier: 2, stage: "branch" },
        acquisitionHints: ["層級 2", "關卡 L04", "3-1"],
        ...levelMeta(2, "L04", "3-1")
      }),
      makeNode({
        id: apexId,
        kind: "triple_research",
        name: `${charName}｜${defs.tripleResearchTemplates.APEX}`,
        description: `連結 ${charName} 與 Apex 終局路線的資格節點。`,
        familyIds: families,
        categoryIds: ["triple_research"],
        tags: ["triple", "apex_link", "permanent"],
        effectOps: [{ op: "grant_triple_apex_link", tripleCode: code }],
        prerequisiteGroups: allOf([roleId, ruleId]),
        costs: mixedCost(55, 2),
        conditions: campaignConditions("L05"),
        layoutHint: { ring: "triple", sector: code, slot: 3, lane: 0, tier: 3, stage: "merge" },
        acquisitionHints: ["層級 3", "關卡 L05", "3-1", ...campaignHint("L05")],
        ...levelMeta(3, "L05", "3-1")
      })
    ];
  }

  function buildTwoApexNodes([code, charName]) {
    const gateId = `APEX-${code}-GATE`;
    const protocolId = `APEX-${code}-PROTOCOL`;
    const isPrime = code === "PRIME";

    return [
      makeNode({
        id: gateId,
        kind: "apex_research",
        name: `${charName}｜${defs.apexResearchTemplates.GATE}`,
        description: isPrime
          ? "IMMUNE PRIME 終局門檻，確認六系與三融合成果已就緒。"
          : `${charName} 終局門檻，需完成對應 Apex 身份與三融合連結。`,
        familyIds: isPrime ? ["T", "B", "M", "N", "A", "D"] : defs.pairSourceFamilies[code === "MEMORY" ? "TB" : code === "STERILE" ? "MA" : "ND"],
        categoryIds: ["apex_research"],
        tags: ["apex", "gate", isPrime ? "prime" : "hidden"],
        effectOps: [{ op: "grant_apex_gate", apexCode: code }],
        prerequisiteGroups: isPrime
          ? [{ mode: "all", nodeIds: ["CHAR-PRIME"] }]
          : [{ mode: "all", nodeIds: [`CHAR-APEX-${code}`] }],
        costs: mixedCost(0, 3, isPrime ? 2 : 1),
        conditions: isPrime ? [] : [{ type: "discovery_flag", flag: `apex_${code.toLowerCase()}_found` }],
        revealRule: isPrime ? { type: "on_prerequisite_visible" } : { type: "on_flag", flag: `apex_${code.toLowerCase()}_found` },
        layoutHint: { ring: "apex", sector: code, slot: 1, lane: -1, tier: 3, stage: "branch" },
        acquisitionHints: ["層級 3", "關卡 L06", "3-1"],
        ...levelMeta(3, "L06", "3-1")
      }),
      makeNode({
        id: protocolId,
        kind: "apex_research",
        name: `${charName}｜${defs.apexResearchTemplates.PROTOCOL}`,
        description: `${charName} 終局研究協議，關卡前裝備並消耗 Apex 帶寬。`,
        familyIds: isPrime ? ["T", "B", "M", "N", "A", "D"] : defs.pairSourceFamilies[code === "MEMORY" ? "TB" : code === "STERILE" ? "MA" : "ND"],
        categoryIds: ["apex_research", "protocol"],
        tags: ["apex", "protocol"],
        effectOps: [{ op: "unlock_apex_protocol", apexCode: code }],
        prerequisiteGroups: [{ mode: "all", nodeIds: [gateId] }],
        costs: mixedCost(0, 2, isPrime ? 3 : 2),
        bandwidth: isPrime ? 3 : 3,
        apex: true,
        exclusiveGroup: `apex-${code.toLowerCase()}-protocol`,
        layoutHint: { ring: "apex", sector: code, slot: 2, lane: 1, tier: 3, stage: "capstone" },
        acquisitionHints: ["層級 3", "關卡 L06", "3-1"],
        ...levelMeta(3, "L06", "3-1")
      })
    ];
  }

  function buildSevenUniversalNodes([domainCode, domainName]) {
    const layers = defs.universalLayers[domainCode];
    const routes = [
      { slot: 1, prereq: ["CORE-IMMUNE"], reveal: { type: "on_prerequisite_visible" }, lane: -1, tier: 1, stage: "branch", levelLink: "L01", route: "2-1" },
      { slot: 2, prereq: ["CORE-IMMUNE"], reveal: { type: "on_prerequisite_visible" }, lane: 1, tier: 1, stage: "branch", levelLink: "L01", route: "2-1" },
      { slot: 3, prereq: [`UNI-${domainCode}-01`, `UNI-${domainCode}-02`], reveal: { type: "on_prerequisite_visible" }, lane: 0, tier: 1, stage: "merge", levelLink: "L02", route: "2-1" },
      { slot: 4, prereq: [`UNI-${domainCode}-03`], reveal: completedReveal([`UNI-${domainCode}-03`]), lane: -1, tier: 2, stage: "branch", levelLink: "L03", route: "3-1", campaignMin: "L03" },
      { slot: 5, prereq: [`UNI-${domainCode}-03`], reveal: completedReveal([`UNI-${domainCode}-03`]), lane: 0, tier: 2, stage: "branch", levelLink: "L03", route: "3-1", campaignMin: "L03" },
      { slot: 6, prereq: [`UNI-${domainCode}-03`], reveal: completedReveal([`UNI-${domainCode}-03`]), lane: 1, tier: 2, stage: "branch", levelLink: "L03", route: "3-1", campaignMin: "L03" },
      { slot: 7, prereq: [`UNI-${domainCode}-04`, `UNI-${domainCode}-05`, `UNI-${domainCode}-06`], reveal: { type: "on_prerequisite_visible" }, lane: 0, tier: 2, stage: "merge", levelLink: "L04", route: "3-1", campaignMin: "L03" }
    ];
    return layers.map((layer, index) => {
      const spec = routes[index];
      const id = `UNI-${domainCode}-${pad2(spec.slot)}`;
      return makeNode({
        id,
        kind: "universal",
        name: layer.name,
        description: layer.description,
        familyIds: [],
        categoryIds: ["universal", "core_layer", domainCode.toLowerCase()],
        tags: ["universal", "core_layer", domainCode.toLowerCase(), "permanent"],
        effectOps: [
          { op: "grant_universal", domain: domainCode, slot: spec.slot, layer: domainName },
          ...(layer.effects || [])
        ],
        prerequisiteGroups: allOf(spec.prereq),
        costs: antigenCost(15 + spec.slot * 5),
        conditions: campaignConditions(spec.campaignMin),
        revealRule: spec.reveal,
        layoutHint: { ring: "universal", domain: domainCode, slot: spec.slot, lane: spec.lane, tier: spec.tier, stage: spec.stage },
        acquisitionHints: [`核心亞層｜${domainName}`, `層級 ${spec.tier}`, `關卡 ${spec.levelLink}`, spec.route, ...campaignHint(spec.campaignMin)],
        ...levelMeta(spec.tier, spec.levelLink, spec.route)
      });
    });
  }

  function buildStatusNodes() {
    const specs = [
      { code: "MARK", prereq: ["CORE-IMMUNE"], reveal: { type: "on_prerequisite_visible" }, lane: -1, tier: 1, stage: "branch", levelLink: "L01", route: "2-1" },
      { code: "AB", prereq: ["CORE-IMMUNE"], reveal: { type: "on_prerequisite_visible" }, lane: 1, tier: 1, stage: "branch", levelLink: "L01", route: "2-1" },
      { code: "COR", prereq: ["STATUS-MARK", "STATUS-AB"], reveal: { type: "on_prerequisite_visible" }, lane: 0, tier: 1, stage: "merge", levelLink: "L02", route: "2-1" },
      { code: "SLOW", prereq: ["STATUS-COR"], reveal: completedReveal(["STATUS-COR"]), lane: -1, tier: 2, stage: "branch", levelLink: "L03", route: "3-1", campaignMin: "L03" },
      { code: "INF", prereq: ["STATUS-COR"], reveal: completedReveal(["STATUS-COR"]), lane: 0, tier: 2, stage: "branch", levelLink: "L03", route: "3-1", campaignMin: "L03" },
      { code: "CHAIN", prereq: ["STATUS-COR"], reveal: completedReveal(["STATUS-COR"]), lane: 1, tier: 2, stage: "branch", levelLink: "L03", route: "3-1", campaignMin: "L03" },
      { code: "CRIT", prereq: ["STATUS-SLOW", "STATUS-INF", "STATUS-CHAIN"], reveal: { type: "on_prerequisite_visible" }, lane: 0, tier: 2, stage: "merge", levelLink: "L04", route: "3-1", campaignMin: "L03" }
    ];
    return specs.map((spec, index) => {
      const statusName = defs.statuses[index];
      const layer = defs.statusLayers[spec.code];
      return makeNode({
        id: `STATUS-${spec.code}`,
        kind: "status",
        name: layer.name,
        description: layer.description,
        familyIds: [],
        categoryIds: ["status", "core_layer"],
        tags: ["status", statusName, "chemistry", "core_layer"],
        effectOps: [
          { op: "grant_status_chemistry", status: statusName },
          ...(layer.effects || [])
        ],
        prerequisiteGroups: allOf(spec.prereq),
        costs: antigenCost(20 + index * 5),
        conditions: campaignConditions(spec.campaignMin),
        revealRule: spec.reveal,
        layoutHint: { ring: "status", slot: index + 1, lane: spec.lane, tier: spec.tier, stage: spec.stage },
        acquisitionHints: ["核心亞層｜狀態化學", `層級 ${spec.tier}`, `關卡 ${spec.levelLink}`, spec.route, ...campaignHint(spec.campaignMin)],
        ...levelMeta(spec.tier, spec.levelLink, spec.route)
      });
    });
  }

  function buildCatalog() {
    const nodes = [
      buildCore(),
      ...buildCharacterAnchors(),
      ...defs.baseCharacters.flatMap(buildEightBaseNodes),
      ...defs.pairCharacters.flatMap(buildThreePairNodes),
      ...defs.tripleCharacters.flatMap(buildThreeTripleNodes),
      ...defs.apexCharacters.flatMap(buildTwoApexNodes),
      ...defs.universalDomainCodes.flatMap(buildSevenUniversalNodes),
      ...buildStatusNodes()
    ];

    return {
      version: defs.catalogVersion,
      nodes,
      campaignLevels: defs.campaignLevels,
      families: defs.families,
      pairCharacters: defs.pairCharacters,
      tripleCharacters: defs.tripleCharacters,
      apexCharacters: defs.apexCharacters,
      statuses: defs.statuses,
      universalDomains: defs.universalDomains
    };
  }

  IMMUNE.buildCatalog = buildCatalog;
})(globalThis);
