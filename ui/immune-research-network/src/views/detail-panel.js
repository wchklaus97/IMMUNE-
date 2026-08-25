(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  const RESOURCE_LABELS = {
    antigen: "抗原樣本",
    protomass: "一度原質",
    fusionCore: "融合核心",
    biomass: "生物質"
  };

  const STAT_LABELS = {
    attackSpeed: "全體攻速",
    moveSpeed: "全體移速",
    cooldown: "技能冷卻縮短",
    coreRegen: "核心修復",
    coreShield: "核心護盾",
    towerSlots: "固定塔位",
    towerLink: "塔間支援",
    pathSlow: "路線減速",
    wavePrep: "波次預備",
    scoutRange: "偵察範圍",
    fogPreview: "迷霧預覽",
    expeditionNodes: "遠征節點",
    frontierBuild: "邊疆建造",
    expeditionYield: "遠征補給",
    retreatWindow: "撤退窗口",
    armyCap: "軍團容量",
    deploySpeed: "部署速度",
    relocateSpeed: "跨區轉移",
    formationBonus: "機動編隊",
    mobileHp: "移動耐久",
    retreatCover: "撤退掩護",
    pairCost: "相性消耗",
    fusionYield: "融合效率",
    tripleReady: "三融合預備",
    legacyKeep: "傳承保留",
    fusionRefund: "核心回收",
    apexPreview: "Apex 預覽",
    biomassYield: "生物質回收",
    unitRegen: "單位再生",
    regenBank: "再生儲備",
    corePulseHeal: "波次急救",
    backupDeploy: "陣亡後備",
    resourceFloor: "資源保底",
    markStacks: "標記疊層",
    weaknessAmp: "弱點放大",
    armorShred: "腐蝕破甲",
    enemySlow: "敵人緩速",
    statusSpread: "感染擴散",
    chainJumps: "鏈鎖跳躍",
    critChance: "暴擊率"
  };

  function formatEffect(op) {
    if (!op || typeof op !== "object") return "";
    if (op.op === "grant_global_stat") {
      const label = STAT_LABELS[op.stat] || op.stat;
      const amount = Number(op.amount || 0);
      const abs = Math.abs(amount);
      const shown = abs >= 1 && Number.isInteger(amount) ? String(amount) : `${Math.round(abs * 100)}%`;
      const sign = amount < 0 ? "−" : "+";
      const duty = op.duty === "fixed" ? "（固定）" : op.duty === "mobile" ? "（移動）" : "";
      return `${label}${duty} ${sign}${shown}`;
    }
    if (op.op === "grant_universal") {
      return `解鎖核心亞層：${op.layer || op.domain || ""}`;
    }
    if (op.op === "grant_status_chemistry") {
      return `強化狀態化學：${op.status || ""}`;
    }
    return op.op || JSON.stringify(op);
  }

  function formatCondition(condition) {
    if (!condition || typeof condition !== "object") return "缺少額外條件";
    if (condition.type === "campaign_level") {
      const name = IMMUNE.campaignLevelName
        ? IMMUNE.campaignLevelName(condition.min)
        : "";
      return `需先進入關卡 ${condition.min || ""}${name ? ` ${name}` : ""}`;
    }
    if (condition.type === "discovery_flag" || condition.type === "discoveryFlag") {
      return "需遠征發現此身份";
    }
    return "缺少額外條件";
  }

  function campaignConditionStatus(missing) {
    const list = missing || [];
    if (list.length && list.every((condition) => condition.type === "campaign_level")) {
      return "關卡未解鎖";
    }
    return "缺少條件";
  }

  function clear(el) {
    while (el.firstChild) el.removeChild(el.firstChild);
  }

  function text(parent, tag, value, className) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    node.textContent = value;
    parent.appendChild(node);
    return node;
  }

  function getNode(catalog, id) {
    return catalog.nodes.find((node) => node.id === id) || null;
  }

  function formatCosts(node) {
    const costs = IMMUNE.normalizeCosts(node.costs);
    return Object.entries(costs)
      .filter(([, amount]) => amount > 0)
      .map(([key, amount]) => `${RESOURCE_LABELS[key] || key} ×${amount}`)
      .join("、");
  }

  /**
   * Render detail panel for selected node.
   */
  function renderDetailPanel(panel, viewModel, handlers = {}) {
    const { catalog, player } = viewModel;
    const nodeId = player.selectedNodeId;
    const runtime = nodeId ? IMMUNE.deriveNodeState(catalog, player, nodeId) : null;
    const sig = [
      nodeId || "",
      runtime?.completion || "",
      runtime?.eligibility || "",
      runtime?.tracked ? "1" : "0",
      (player.completedNodeIds || []).length,
      (player.trackedNodeIds || []).join(",")
    ].join("|");
    if (panel.dataset.renderSig === sig) return;
    panel.dataset.renderSig = sig;
    clear(panel);
    if (!nodeId) {
      text(panel, "p", "選擇一個研究節點以查看詳情。", "detail-empty");
      return;
    }

    const node = getNode(catalog, nodeId);
    if (!node) {
      text(panel, "p", "節點不存在。", "detail-empty");
      return;
    }

    const hidden = runtime.visibility === "hidden";

    const title = document.createElement("h2");
    title.className = "detail-title";
    title.textContent = hidden ? "未知研究" : node.name;
    panel.appendChild(title);

    if (!hidden) {
      text(panel, "p", node.description || "", "detail-description");
    } else {
      text(panel, "p", "此研究尚未被發現。", "detail-description");
    }

    const character = IMMUNE.gameAssets?.characterForNode?.(node);
    const defenseList = IMMUNE.gameAssets?.defenseTargetsForNode?.(node) || [];

    if (!hidden && character) {
      const formsSection = document.createElement("section");
      formsSection.className = "detail-section detail-forms";
      text(formsSection, "h3", "角色立繪");
      const dual = document.createElement("div");
      dual.className = "form-dual form-triple";

      for (const formKey of ["catalog", "fixed", "mobile"]) {
        const form =
          formKey === "catalog"
            ? { label: "目錄臉", kind: "catalog" }
            : character.forms?.[formKey];
        if (!form) continue;
        const unlocked =
          formKey === "catalog" || IMMUNE.gameAssets.isFormUnlocked(player, character, formKey);
        const card = document.createElement("div");
        card.className = `form-card${unlocked ? " unlocked" : " locked"}`;

        const img = document.createElement("img");
        img.className = "form-portrait";
        img.alt = `${character.name} ${form.label}`;
        img.width = 132;
        img.height = 132;
        img.loading = "lazy";
        img.decoding = "async";

        const caption = document.createElement("div");
        caption.className = "form-caption";
        text(caption, "strong", form.label, "form-label");
        const hint = document.createElement("span");
        hint.className = "form-status";
        hint.textContent =
          formKey === "catalog"
            ? "圖鑑立繪"
            : IMMUNE.gameAssets.formUnlockHint(player, character, formKey);
        caption.appendChild(hint);

        card.appendChild(img);
        card.appendChild(caption);
        dual.appendChild(card);

        IMMUNE.assets?.getCharacterFormPortraitUrl(character.id, formKey).then((url) => {
          if (url) img.src = url;
        });
      }

      const meta = document.createElement("p");
      meta.className = "detail-muted form-note";
      meta.textContent = `${character.name} · ${character.role || ""}`;
      formsSection.appendChild(dual);
      formsSection.appendChild(meta);
      panel.appendChild(formsSection);

      const skillSection = document.createElement("section");
      skillSection.className = "detail-section";
      text(skillSection, "h3", "角色技能");
      const skillGrid = document.createElement("div");
      skillGrid.className = "asset-grid";
      for (const skill of character.skills || []) {
        const card = document.createElement("div");
        card.className = "asset-card";
        const img = document.createElement("img");
        img.className = "asset-icon";
        img.alt = skill.name;
        img.width = 48;
        img.height = 48;
        const label = document.createElement("span");
        label.className = "asset-label";
        const routeBits = [skill.route, skill.levelLink ? `關卡 ${skill.levelLink}` : "", skill.tier != null ? `層級 ${skill.tier}` : ""]
          .filter(Boolean)
          .join(" · ");
        label.textContent = routeBits ? `${skill.name}（${routeBits}）` : skill.name;
        card.appendChild(img);
        card.appendChild(label);
        skillGrid.appendChild(card);
        IMMUNE.assets?.getSkillIconUrl(skill.id).then((url) => {
          if (url) img.src = url;
        });
      }
      skillSection.appendChild(skillGrid);
      panel.appendChild(skillSection);
    }

    if (!hidden && defenseList.length) {
      const defSection = document.createElement("section");
      defSection.className = "detail-section";
      text(defSection, "h3", "相關防守目標");
      const defGrid = document.createElement("div");
      defGrid.className = "asset-grid";
      for (const target of defenseList) {
        const card = document.createElement("div");
        card.className = "asset-card";
        const img = document.createElement("img");
        img.className = "asset-icon";
        img.alt = target.name;
        img.width = 48;
        img.height = 48;
        const label = document.createElement("span");
        label.className = "asset-label";
        label.textContent = target.name;
        card.appendChild(img);
        card.appendChild(label);
        defGrid.appendChild(card);
        IMMUNE.assets?.getDefenseIconUrl(target.id).then((url) => {
          if (url) img.src = url;
        });
      }
      defSection.appendChild(defGrid);
      panel.appendChild(defSection);
    }

    const nodeIconSection = document.createElement("section");
    nodeIconSection.className = "detail-section detail-node-icon";
    text(nodeIconSection, "h3", "研究節點圖示");
    const nodeIconWrap = document.createElement("div");
    nodeIconWrap.className = "detail-node-icon-wrap";
    const nodeIcon = document.createElement("img");
    nodeIcon.className = "detail-node-icon-img";
    nodeIcon.alt = hidden ? "未知研究圖示" : `${node.name} 圖示`;
    nodeIcon.width = 64;
    nodeIcon.height = 64;
    nodeIconWrap.appendChild(nodeIcon);
    nodeIconSection.appendChild(nodeIconWrap);
    panel.appendChild(nodeIconSection);
    IMMUNE.assets?.getNodeIconUrl(node.id).then((url) => {
      if (url) nodeIcon.src = url;
    });

    const status = document.createElement("div");
    status.className = "detail-status";
    const statusLabel =
      runtime.completion === "complete"
        ? "已完成"
        : runtime.eligibility === "ready"
          ? "可研究"
          : runtime.eligibility === "missing_resource"
            ? "資源不足"
            : runtime.eligibility === "missing_prerequisite"
              ? "缺少前置"
              : runtime.eligibility === "missing_condition"
                ? campaignConditionStatus(runtime.missingConditions)
                : "鎖定";
    text(status, "span", statusLabel, "status-chip");
    if (runtime.tracked) text(status, "span", "追蹤中", "status-chip tracked");
    panel.appendChild(status);

    if (!hidden) {
      const routeLine = document.createElement("p");
      routeLine.className = "detail-muted";
      const bits = [];
      if (node.route) bits.push(`研究樹 ${node.route}`);
      if (node.tier != null) bits.push(`層級 ${node.tier}`);
      if (node.levelLink) bits.push(`關卡 ${node.levelLink}`);
      routeLine.textContent = bits.length ? bits.join(" · ") : "";
      if (bits.length) panel.appendChild(routeLine);
    }

    if (!hidden && node.effectOps?.length) {
      const effects = document.createElement("section");
      effects.className = "detail-section";
      text(effects, "h3", "永久效果");
      const list = document.createElement("ul");
      list.className = "detail-list";
      for (const op of node.effectOps) {
        const li = document.createElement("li");
        li.textContent = formatEffect(op);
        list.appendChild(li);
      }
      effects.appendChild(list);
      panel.appendChild(effects);
    }

    if (!hidden) {
      const prereqSection = document.createElement("section");
      prereqSection.className = "detail-section";
      text(prereqSection, "h3", "前置研究");
      const list = document.createElement("ul");
      list.className = "detail-list prereq-list";
      const groups = node.prerequisiteGroups || [];
      if (!groups.length) {
        text(list, "li", "無前置需求", "detail-muted");
      } else {
        for (const group of groups) {
          for (const pid of group.nodeIds || []) {
            const prereq = getNode(catalog, pid);
            const pState = IMMUNE.deriveNodeState(catalog, player, pid);
            const li = document.createElement("li");
            const btn = document.createElement("button");
            btn.type = "button";
            btn.className = `prereq-link${pState.completion === "complete" ? " done" : ""}`;
            btn.textContent =
              pState.visibility === "hidden"
                ? "未知前置"
                : prereq
                  ? prereq.name
                  : pid;
            btn.addEventListener("click", () => handlers.onSelectNode?.(pid));
            li.appendChild(btn);
            if (pState.completion !== "complete") {
              const gap = document.createElement("span");
              gap.className = "prereq-gap";
              gap.textContent = "未完成";
              li.appendChild(gap);
            }
            list.appendChild(li);
          }
        }
      }
      prereqSection.appendChild(list);
      panel.appendChild(prereqSection);
    }

    if (!hidden && runtime.eligibility === "missing_condition" && runtime.missingConditions?.length) {
      const gapSection = document.createElement("section");
      gapSection.className = "detail-section";
      gapSection.id = "detail-conditions";
      text(gapSection, "h3", "關卡條件");
      const list = document.createElement("ul");
      list.className = "detail-list";
      for (const condition of runtime.missingConditions) {
        const li = document.createElement("li");
        li.textContent = formatCondition(condition);
        list.appendChild(li);
      }
      gapSection.appendChild(list);
      panel.appendChild(gapSection);
    }

    if (!hidden && runtime.eligibility === "missing_resource" && runtime.missingResources) {
      const gapSection = document.createElement("section");
      gapSection.className = "detail-section";
      gapSection.id = "detail-gaps";
      text(gapSection, "h3", "資源缺口");
      const list = document.createElement("ul");
      list.className = "detail-list";
      for (const [key, amount] of Object.entries(runtime.missingResources)) {
        const li = document.createElement("li");
        li.textContent = `缺少 ${RESOURCE_LABELS[key] || key} ×${amount}`;
        list.appendChild(li);
      }
      gapSection.appendChild(list);
      panel.appendChild(gapSection);
    }

    if (!hidden && node.acquisitionHints?.length) {
      const acq = document.createElement("section");
      acq.className = "detail-section";
      text(acq, "h3", "取得方式");
      const list = document.createElement("ul");
      list.className = "detail-list";
      for (const hint of node.acquisitionHints) {
        const li = document.createElement("li");
        li.textContent = typeof hint === "string" ? hint : hint.text || "";
        list.appendChild(li);
      }
      acq.appendChild(list);
      panel.appendChild(acq);
    }

    if (!hidden) {
      const costLine = document.createElement("p");
      costLine.className = "detail-cost";
      costLine.textContent = `成本：${formatCosts(node) || "免費"}`;
      panel.appendChild(costLine);
    }

    const actions = document.createElement("div");
    actions.className = "detail-actions";

    const trackBtn = document.createElement("button");
    trackBtn.type = "button";
    trackBtn.className = "detail-btn secondary";
    trackBtn.textContent = runtime.tracked ? "取消追蹤" : "追蹤";
    trackBtn.addEventListener("click", () => handlers.onTrack?.(nodeId, !runtime.tracked));
    actions.appendChild(trackBtn);

    const researchBtn = document.createElement("button");
    researchBtn.type = "button";
    researchBtn.id = "research-button";
    researchBtn.className = "detail-btn primary";
    researchBtn.textContent = runtime.completion === "complete" ? "已完成" : "研究";
    researchBtn.disabled = runtime.eligibility !== "ready";
    researchBtn.setAttribute("aria-describedby", runtime.eligibility === "missing_resource" ? "detail-gaps" : "");
    researchBtn.addEventListener("click", () => handlers.onResearch?.(nodeId));
    actions.appendChild(researchBtn);

    panel.appendChild(actions);
  }

  IMMUNE.renderDetailPanel = renderDetailPanel;
})(globalThis);
