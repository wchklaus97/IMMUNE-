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

  function isProtocolNode(node) {
    return Boolean(node?.bandwidth) || /-PROTOCOL$/.test(node?.id || "");
  }

  /**
   * Render protocol dock with bandwidth display.
   */
  function renderProtocolDock(container, viewModel, handlers = {}) {
    clear(container);
    const { catalog, player } = viewModel;

    const header = document.createElement("div");
    header.className = "protocol-dock-header";
    text(header, "h3", "研究協議");
    const used = IMMUNE.usedBandwidth(catalog, player);
    text(header, "span", `${used}/${player.protocolBandwidth}`, "protocol-bandwidth");
    container.appendChild(header);

    const list = document.createElement("div");
    list.className = "protocol-list";

    const protocols = catalog.nodes.filter((node) => isProtocolNode(node));
    for (const node of protocols) {
      const unlocked = player.completedNodeIds.includes(node.id);
      const equipped = (player.equippedProtocolIds || []).includes(node.id);
      const card = document.createElement("article");
      card.className = `protocol-card${equipped ? " equipped" : ""}${unlocked ? "" : " locked"}`;

      const titleRow = document.createElement("div");
      titleRow.className = "protocol-title-row";
      text(titleRow, "strong", unlocked ? node.name : "未解鎖協議");
      if (node.apex) text(titleRow, "span", "Apex", "protocol-apex-badge");
      text(titleRow, "span", `成本 ${node.bandwidth || 1}`, "protocol-cost");
      card.appendChild(titleRow);

      if (unlocked) {
        const btn = document.createElement("button");
        btn.type = "button";
        btn.className = "protocol-toggle";
        btn.textContent = equipped ? "卸下" : "裝備";
        btn.addEventListener("click", () => {
          if (equipped) handlers.onUnequip?.(node.id);
          else handlers.onEquip?.(node.id);
        });
        card.appendChild(btn);
      }

      list.appendChild(card);
    }

    container.appendChild(list);
  }

  IMMUNE.renderProtocolDock = renderProtocolDock;
})(globalThis);
