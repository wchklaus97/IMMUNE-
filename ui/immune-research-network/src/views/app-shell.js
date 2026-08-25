(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  /**
   * Bind the research app shell to existing semantic regions.
   */
  function mountResearchApp(root, dependencies = {}) {
    const { onAction } = dependencies;
    root.classList.add("immune-app");

    return {
      root,
      resourceBar: root.querySelector("#resource-bar"),
      toolbar: root.querySelector("#research-toolbar"),
      viewport: root.querySelector("#tree-viewport"),
      svg: root.querySelector("#tree-svg"),
      worldTransform: root.querySelector("#world-transform"),
      detailPanel: root.querySelector("#detail-panel"),
      minimap: root.querySelector("#minimap"),
      protocolDock: root.querySelector("#protocol-dock"),
      researchList: root.querySelector("#research-list"),
      toastRegion: root.querySelector("#toast-region"),
      emit(action) {
        if (typeof onAction === "function") onAction(action);
      }
    };
  }

  const RESOURCE_LABELS = {
    antigen: "抗原樣本",
    protomass: "一度原質",
    fusionCore: "融合核心",
    biomass: "生物質"
  };

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

  function button(parent, label, className, attrs = {}) {
    const node = document.createElement("button");
    node.type = "button";
    node.className = className;
    node.textContent = label;
    for (const [key, val] of Object.entries(attrs)) node.setAttribute(key, String(val));
    parent.appendChild(node);
    return node;
  }

  /**
   * Render resource bar and toolbar chrome.
   */
  function renderAppChrome(chrome, viewModel) {
    const { catalog, player, filters, searchQuery, viewMode } = viewModel;
    clear(chrome.resourceBar);
    clear(chrome.toolbar);

    const brand = text(chrome.resourceBar, "div", "", "brand-block");
    text(brand, "strong", "IMMUNE", "brand-title");
    text(
      brand,
      "span",
      `${player.completedNodeIds.length}/200`,
      "brand-progress"
    );

    const resources = document.createElement("div");
    resources.className = "resource-group";
    const selected = catalog.nodes.find((node) => node.id === player.selectedNodeId);
    const costs = selected && IMMUNE.normalizeCosts ? IMMUNE.normalizeCosts(selected.costs) : {};
    for (const key of ["antigen", "protomass", "fusionCore", "biomass"]) {
      const chip = document.createElement("div");
      const need = Number(costs[key] || 0);
      const have = Number(player.resources[key] ?? 0);
      chip.className = "resource-chip";
      if (need > 0) chip.classList.add("is-cost");
      if (need > 0 && have < need) chip.classList.add("is-short");
      text(chip, "span", RESOURCE_LABELS[key], "resource-label");
      text(chip, "strong", String(have), "resource-value");
      resources.appendChild(chip);
    }
    chrome.resourceBar.appendChild(resources);

    const campaign = document.createElement("div");
    campaign.className = "campaign-chip";
    const level = player.unlockedCampaignLevel || "L01";
    const chapter = IMMUNE.campaignLevelName ? IMMUNE.campaignLevelName(level) : "";
    text(campaign, "span", "關卡", "resource-label");
    text(campaign, "strong", `${level}${chapter ? ` ${chapter}` : ""}`, "resource-value");
    chrome.resourceBar.appendChild(campaign);

    const bandwidth = document.createElement("div");
    bandwidth.className = "bandwidth-chip";
    const used = IMMUNE.usedBandwidth?.(catalog, player) ?? 0;
    text(bandwidth, "span", "協議帶寬", "resource-label");
    text(
      bandwidth,
      "strong",
      `${used}/${player.protocolBandwidth}`,
      "resource-value"
    );
    chrome.resourceBar.appendChild(bandwidth);

    const review = document.createElement("nav");
    review.className = "review-links";
    review.setAttribute("aria-label", "圖鑑");
    for (const [href, label] of [
      ["datasheet.html", "角色資料表"],
      ["enemy-review.html", "敵人圖鑑"],
      ["3d-review.html", "3D 評審"]
    ]) {
      const a = document.createElement("a");
      a.href = href;
      a.textContent = label;
      a.className = "review-link";
      review.appendChild(a);
    }
    chrome.resourceBar.appendChild(review);

    const searchWrap = document.createElement("div");
    searchWrap.className = "toolbar-search";
    const searchInput = document.createElement("input");
    searchInput.type = "search";
    searchInput.className = "toolbar-search-input";
    searchInput.placeholder = "搜尋研究…";
    searchInput.value = searchQuery || "";
    searchInput.setAttribute("aria-label", "搜尋研究");
    searchInput.addEventListener("input", () => {
      chrome.emit({ type: "SET_SEARCH", query: searchInput.value });
    });
    searchWrap.appendChild(searchInput);
    chrome.toolbar.appendChild(searchWrap);

    const filtersRow = document.createElement("div");
    filtersRow.className = "toolbar-filters";
    for (const [id, , color] of catalog.families || []) {
      const active = (filters.familyIds || []).includes(id);
      const chip = button(
        filtersRow,
        id,
        `family-filter${active ? " active" : ""}`,
        { "data-family": id, "aria-pressed": active ? "true" : "false" }
      );
      chip.style.setProperty("--family-color", color);
      chip.addEventListener("click", () => {
        const current = new Set(filters.familyIds || []);
        if (current.has(id)) current.delete(id);
        else current.add(id);
        chrome.emit({
          type: "SET_FILTERS",
          filters: { ...filters, familyIds: [...current] }
        });
      });
    }
    chrome.toolbar.appendChild(filtersRow);

    const actions = document.createElement("div");
    actions.className = "toolbar-actions";
    button(actions, "顯示全圖", "toolbar-btn", { "data-action": "fit-all" }).addEventListener(
      "click",
      () => chrome.emit({ type: "CAMERA_FIT_ALL" })
    );
    button(actions, "返回核心", "toolbar-btn", { "data-action": "home" }).addEventListener(
      "click",
      () => chrome.emit({ type: "CAMERA_HOME" })
    );
    button(actions, "聚焦路線", "toolbar-btn", { "data-action": "focus-route" }).addEventListener(
      "click",
      () => chrome.emit({ type: "CAMERA_FOCUS_ROUTE" })
    );

    const mapBtn = button(
      actions,
      "地圖",
      `view-toggle${viewMode === "map" ? " active" : ""}`,
      { "data-view": "map", "aria-pressed": viewMode === "map" ? "true" : "false" }
    );
    mapBtn.addEventListener("click", () => chrome.emit({ type: "SET_VIEW_MODE", mode: "map" }));

    const listBtn = button(
      actions,
      "列表",
      `view-toggle${viewMode === "list" ? " active" : ""}`,
      { "data-view": "list", "aria-pressed": viewMode === "list" ? "true" : "false" }
    );
    listBtn.addEventListener("click", () => chrome.emit({ type: "SET_VIEW_MODE", mode: "list" }));

    chrome.toolbar.appendChild(actions);
  }

  IMMUNE.mountResearchApp = mountResearchApp;
  IMMUNE.renderAppChrome = renderAppChrome;
})(globalThis);
