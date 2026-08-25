(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

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

  const RING_ORDER = [
    ["core", "免疫核心"],
    ["universal", "通用科技"],
    ["status", "狀態研究"],
    ["family", "基礎家族"],
    ["pair", "雙融合"],
    ["triple", "三融合"],
    ["apex", "Apex"]
  ];

  function ringForNode(node) {
    const hint = node.layoutHint || {};
    if (node.kind === "core") return "core";
    if (node.kind === "status") return "status";
    if (node.kind === "universal") return "universal";
    return hint.ring || "family";
  }

  function familyName(catalog, familyId) {
    const fam = (catalog.families || []).find((entry) => entry[0] === familyId);
    return fam ? fam[1] : familyId;
  }

  function statusLabel(runtime) {
    if (runtime.visibility === "hidden") return "未知";
    if (runtime.completion === "complete") return "已完成";
    if (runtime.eligibility === "ready") return "可研究";
    if (runtime.eligibility === "missing_resource") return "缺資源";
    if (runtime.eligibility === "missing_prerequisite") return "鎖定";
    return "未解鎖";
  }

  /**
   * Render list view grouped by family / ring layer.
   */
  function renderResearchList(container, viewModel, handlers = {}) {
    clear(container);
    const { catalog, player, filters } = viewModel;

    const groups = new Map();
    for (const node of catalog.nodes) {
      const runtime = IMMUNE.deriveNodeState(catalog, player, node.id);
      if (runtime.visibility === "hidden") continue;
      if (filters.familyIds?.length) {
        const match = (node.familyIds || []).some((id) => filters.familyIds.includes(id));
        if (!match && node.kind !== "core" && node.kind !== "universal") continue;
      }
      const ring = ringForNode(node);
      const familyKey = node.familyIds?.[0] || "ALL";
      const key = `${ring}::${familyKey}`;
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push({ node, runtime });
    }

    for (const [ringKey] of RING_ORDER) {
      const sections = [...groups.entries()].filter(([key]) => key.startsWith(`${ringKey}::`));
      if (!sections.length) continue;

      const ringTitle = RING_ORDER.find(([k]) => k === ringKey)?.[1] || ringKey;
      text(container, "h3", ringTitle, "list-ring-title");

      for (const [key, items] of sections.sort(([a], [b]) => a.localeCompare(b))) {
        const familyId = key.split("::")[1];
        if (familyId !== "ALL") {
          text(container, "h4", familyName(catalog, familyId), "list-family-title");
        }

        const list = document.createElement("ul");
        list.className = "list-group";
        for (const { node, runtime } of items.sort((a, b) => a.node.name.localeCompare(b.node.name, "zh-Hant"))) {
          const li = document.createElement("li");
          const btn = document.createElement("button");
          btn.type = "button";
          btn.className = `list-item${runtime.selected ? " selected" : ""}${runtime.tracked ? " tracked" : ""}`;
          btn.textContent = `${node.name} — ${statusLabel(runtime)}`;
          btn.addEventListener("click", () => {
            handlers.onSelectNode?.(node.id);
            handlers.onSwitchToMap?.();
          });
          li.appendChild(btn);
          list.appendChild(li);
        }
        container.appendChild(list);
      }
    }
  }

  IMMUNE.renderResearchList = renderResearchList;
})(globalThis);
