(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  const HIT_RADIUS = 28;
  const WORLD_SIZE = 3000;

  const NODE_VISUAL = {
    core: { r: 36, anchor: true },
    character_anchor: { r: 28, anchor: true },
    base_character_research: { r: 14 },
    pair_research: { r: 16 },
    triple_research: { r: 18 },
    apex_research: { r: 20 },
    universal: { r: 12 },
    status: { r: 12 }
  };

  const EDGE_CLASS = {
    required: "edge-required",
    dual_source: "edge-dual",
    optional: "edge-optional",
    affinity: "edge-affinity"
  };

  function ns(tag) {
    return document.createElementNS("http://www.w3.org/2000/svg", tag);
  }

  function familyColor(catalog, node) {
    const id = node.familyIds?.[0];
    const fam = (catalog.families || []).find((entry) => entry[0] === id);
    return fam ? fam[2] : "#7ec8ff";
  }

  function stateClass(state) {
    if (state.visibility === "hidden") return "node-hidden";
    if (state.completion === "complete") return "node-complete";
    if (state.eligibility === "ready") return "node-ready";
    if (state.eligibility === "missing_resource") return "node-resource";
    if (state.eligibility === "missing_prerequisite") return "node-locked";
    return "node-revealed";
  }

  function ariaForNode(node, runtime, lod) {
    if (runtime.visibility === "hidden") return "未知研究";
    const parts = [node.name];
    if (runtime.completion === "complete") parts.push("已完成");
    else if (runtime.eligibility === "ready") parts.push("可研究");
    else if (runtime.eligibility === "missing_resource") parts.push("資源不足");
    else if (runtime.eligibility === "missing_prerequisite") parts.push("缺少前置");
    if (runtime.tracked) parts.push("追蹤中");
    if (lod === "inspect" && node.description) parts.push(node.description.slice(0, 40));
    return parts.join("，");
  }

  function shouldRenderNode(node, layoutPoint, lod, runtime) {
    if (runtime.visibility === "hidden" && lod === "overview") return layoutPoint?.anchor;
    if (lod === "overview") return layoutPoint?.anchor || node.kind === "core";
    if (lod === "structure") {
      return (
        layoutPoint?.anchor ||
        node.kind === "core" ||
        node.kind !== "universal" ||
        node.id.endsWith("-01")
      );
    }
    return true;
  }

  function shouldShowLabel(node, layoutPoint, lod, runtime) {
    if (runtime.visibility === "hidden") return false;
    if (lod === "overview") return layoutPoint?.anchor;
    if (lod === "structure") return layoutPoint?.anchor || node.kind === "core";
    return lod === "detail" || lod === "inspect";
  }

  function routeHighlight(viewModel, nodeId) {
    const { routeFocusId, catalog, player, layout } = viewModel;
    if (!routeFocusId) return 1;
    if (nodeId === routeFocusId) return 1;
    const focusNode = catalog.nodes.find((n) => n.id === routeFocusId);
    if (!focusNode) return 0.15;

    const related = new Set([routeFocusId]);
    for (const group of focusNode.prerequisiteGroups || []) {
      for (const id of group.nodeIds || []) related.add(id);
    }
    for (const edge of viewModel.edges || []) {
      if (edge.to === routeFocusId) related.add(edge.from);
      if (edge.from === routeFocusId) related.add(edge.to);
    }
    if (focusNode.familyIds?.length === 2) {
      for (const edge of viewModel.edges || []) {
        if (edge.kind === "dual_source" && edge.to === routeFocusId) {
          related.add(edge.from);
        }
      }
    }
    return related.has(nodeId) ? 1 : 0.15;
  }

  function ensureLayer(svg, layerId) {
    let layer = svg.querySelector(`#${layerId}`);
    if (!layer) {
      const world = svg.querySelector("#world-transform") || svg;
      layer = ns("g");
      layer.id = layerId;
      world.appendChild(layer);
    }
    return layer;
  }

  function applyCameraTransform(svg, view) {
    const world = svg.querySelector("#world-transform") || svg;
    const zoom = view?.zoom ?? 0.55;
    const vx = view?.x ?? 1500;
    const vy = view?.y ?? 1500;
    world.setAttribute("transform", `translate(${1500 - vx * zoom},${1500 - vy * zoom}) scale(${zoom})`);
  }

  /**
   * Render or update the SVG tree map (200 nodes).
   */
  function renderTreeMap(svg, viewModel) {
    const { catalog, player, layout, edges, emphasis, lod } = viewModel;
    const zoom = player.view?.zoom ?? 0.55;
    applyCameraTransform(svg, player.view);

    const sectorLayer = ensureLayer(svg, "sector-layer");
    const edgeLayer = ensureLayer(svg, "edge-layer");
    const nodeLayer = ensureLayer(svg, "node-layer");
    const labelLayer = ensureLayer(svg, "label-layer");

    if (!sectorLayer.childElementCount) {
      for (let i = 0; i < 6; i += 1) {
        const wedge = ns("path");
        wedge.setAttribute("class", "sector-wedge");
        wedge.setAttribute("data-sector", String(i));
        sectorLayer.appendChild(wedge);
      }
      const ringRadii = [420, 560, 900, 1250, 1500];
      for (const r of ringRadii) {
        const ring = ns("circle");
        ring.setAttribute("class", "layout-ring");
        ring.setAttribute("cx", "1500");
        ring.setAttribute("cy", "1500");
        ring.setAttribute("r", String(r));
        ring.setAttribute("fill", "none");
        sectorLayer.appendChild(ring);
      }
    }

    const existingEdges = new Map();
    for (const el of edgeLayer.querySelectorAll("[data-edge-key]")) {
      existingEdges.set(el.getAttribute("data-edge-key"), el);
    }
    for (const edge of edges || []) {
      const key = `${edge.from}->${edge.to}:${edge.kind}`;
      let pathEl = existingEdges.get(key);
      if (!pathEl) {
        pathEl = ns("path");
        pathEl.setAttribute("class", `research-edge ${EDGE_CLASS[edge.kind] || ""}`);
        pathEl.dataset.edgeKey = key;
        edgeLayer.appendChild(pathEl);
      }
      const from = layout.get(edge.from);
      const to = layout.get(edge.to);
      if (!from || !to) continue;
      const fromState = IMMUNE.deriveNodeState(catalog, player, edge.from);
      const toState = IMMUNE.deriveNodeState(catalog, player, edge.to);
      const visible = fromState.visibility === "revealed" || toState.visibility === "revealed";
      const route = routeHighlight(viewModel, edge.to);
      const weight = Math.min(emphasis?.get(edge.from) ?? 1, emphasis?.get(edge.to) ?? 1) * route;
      pathEl.setAttribute("d", edge.path);
      pathEl.style.opacity = visible ? String(Math.max(0.1, weight)) : "0.05";
      pathEl.style.display =
        lod === "overview" && edge.kind === "affinity" ? "none" : "";
    }

    const existingNodes = new Map();
    for (const el of nodeLayer.querySelectorAll("[data-node-id]")) {
      existingNodes.set(el.getAttribute("data-node-id"), el);
    }

    for (const node of catalog.nodes) {
      const point = layout.get(node.id);
      if (!point) continue;
      const runtime = IMMUNE.deriveNodeState(catalog, player, node.id);
      const currentLod = lod || IMMUNE.getLod(zoom);
      if (!shouldRenderNode(node, point, currentLod, runtime)) {
        const existing = existingNodes.get(node.id);
        if (existing) existing.style.display = "none";
        continue;
      }

      let group = existingNodes.get(node.id);
      if (!group) {
        group = ns("g");
        group.setAttribute("role", "button");
        group.setAttribute("tabindex", "0");
        group.dataset.nodeId = node.id;
        group.dataset.kind = node.kind;

        const hit = ns("circle");
        hit.setAttribute("class", "node-hit");
        hit.setAttribute("r", String(HIT_RADIUS));
        group.appendChild(hit);

        const body = ns("circle");
        body.setAttribute("class", "node-body");
        group.appendChild(body);

        const icon = ns("image");
        icon.setAttribute("class", "node-icon");
        icon.setAttribute("width", "0");
        icon.setAttribute("height", "0");
        icon.setAttribute("preserveAspectRatio", "xMidYMid meet");
        group.appendChild(icon);

        const badge = ns("text");
        badge.setAttribute("class", "node-state-badge");
        badge.setAttribute("text-anchor", "middle");
        badge.setAttribute("dy", "0.35em");
        group.appendChild(badge);

        nodeLayer.appendChild(group);
        existingNodes.set(node.id, group);
      }

      group.style.display = "";
      group.dataset.state = stateClass(runtime);
      group.setAttribute("aria-label", ariaForNode(node, runtime, currentLod));

      const visual = NODE_VISUAL[node.kind] || { r: 12 };
      const scanSheet = IMMUNE.scanSheetPath?.(node.id) || "";
      const coverAnchor = IMMUNE.isCoverMode ? IMMUNE.COVER_PORTRAITS?.[node.id] || "" : "";
      const catalogFace =
        !IMMUNE.isCoverMode && node.kind === "character_anchor"
          ? `assets/characters/${node.id}.png`
          : "";
      const portrait = coverAnchor || catalogFace;
      const radius = portrait
        ? IMMUNE.isCoverMode
          ? 86
          : currentLod === "inspect"
            ? 46
            : currentLod === "detail"
              ? 38
              : 32
        : point.anchor
          ? visual.r * 1.15
          : visual.r;
      const useScan = Boolean(scanSheet) && !portrait && (currentLod === "detail" || currentLod === "inspect");
      group.setAttribute("transform", `translate(${point.x},${point.y})`);

      const body = group.querySelector(".node-body");
      body.setAttribute("r", String(radius));
      body.setAttribute("fill", runtime.visibility === "hidden" && !portrait ? "#1a2430" : familyColor(catalog, node));

      const iconEl = group.querySelector(".node-icon");
      const iconUrl = portrait || viewModel.iconUrls?.[node.id];
      const iconSize = portrait ? radius * 2.35 : radius * 2.1;
      const crop = group.querySelector("svg.scan-crop");
      if (useScan) {
        const level = IMMUNE.scanLevelForNode(catalog, player, node);
        let scan = crop;
        if (!scan) {
          scan = ns("svg");
          scan.setAttribute("class", "scan-crop");
          const img = ns("image");
          img.setAttribute("class", "scan-crop-img");
          scan.appendChild(img);
          group.appendChild(scan);
        }
        const img = scan.querySelector("image");
        scan.style.display = "";
        scan.setAttribute("x", String(-iconSize / 2));
        scan.setAttribute("y", String(-iconSize / 2));
        scan.setAttribute("width", String(iconSize));
        scan.setAttribute("height", String(iconSize));
        const cell = IMMUNE.scanFrameCell
          ? IMMUNE.scanFrameCell(level)
          : { col: Number(level) || 0, row: 0, cols: 5, rows: 2 };
        scan.setAttribute("viewBox", `${cell.col} ${cell.row} 1 1`);
        if (img.getAttribute("href") !== scanSheet) img.setAttribute("href", scanSheet);
        img.setAttribute("width", String(cell.cols));
        img.setAttribute("height", String(cell.rows));
        iconEl.removeAttribute("href");
        iconEl.setAttribute("width", "0");
        iconEl.setAttribute("height", "0");
        body.setAttribute("fill", familyColor(catalog, node));
        body.setAttribute("fill-opacity", portrait ? "0.22" : "0.35");
      } else {
        if (crop) crop.style.display = "none";
        if (portrait) {
          iconEl.setAttribute("class", "node-icon cover-symbol");
          iconEl.setAttribute("href", portrait);
          iconEl.setAttribute("x", String(-iconSize / 2));
          iconEl.setAttribute("y", String(-iconSize / 2));
          iconEl.setAttribute("width", String(iconSize));
          iconEl.setAttribute("height", String(iconSize));
          iconEl.style.opacity = "1";
          body.setAttribute("fill", familyColor(catalog, node));
          body.setAttribute("fill-opacity", "0.22");
        } else if (iconUrl && runtime.visibility !== "hidden") {
          iconEl.setAttribute("href", iconUrl);
          iconEl.setAttribute("x", String(-iconSize / 2));
          iconEl.setAttribute("y", String(-iconSize / 2));
          iconEl.setAttribute("width", String(iconSize));
          iconEl.setAttribute("height", String(iconSize));
          iconEl.style.opacity = "1";
          body.setAttribute("fill", "#0b1520");
          body.setAttribute("fill-opacity", "0.55");
        } else if (iconUrl && runtime.visibility === "hidden") {
          iconEl.setAttribute("href", iconUrl);
          iconEl.setAttribute("x", String(-iconSize / 2));
          iconEl.setAttribute("y", String(-iconSize / 2));
          iconEl.setAttribute("width", String(iconSize));
          iconEl.setAttribute("height", String(iconSize));
          iconEl.style.opacity = "0.25";
        } else {
          iconEl.removeAttribute("href");
          iconEl.setAttribute("width", "0");
          iconEl.setAttribute("height", "0");
        }
      }

      const route = routeHighlight(viewModel, node.id);
      const weight = (emphasis?.get(node.id) ?? 1) * route;
      group.style.opacity = portrait ? "1" : String(Math.max(0.12, weight));
      group.classList.toggle("is-selected", runtime.selected);
      group.classList.toggle("is-tracked", runtime.tracked);
      group.classList.toggle("is-anchor", Boolean(point.anchor));

      const badge = group.querySelector(".node-state-badge");
      badge.textContent = "";
      if (runtime.visibility !== "hidden" && currentLod !== "overview") {
        if (runtime.completion === "complete") badge.textContent = "✓";
        else if (runtime.tracked) badge.textContent = "◎";
        else if (runtime.eligibility === "ready") badge.textContent = "●";
        else if (runtime.eligibility === "missing_resource") badge.textContent = "!";
        else if (runtime.eligibility === "missing_prerequisite") badge.textContent = "◌";
      }

      let label = labelLayer.querySelector(`[data-label-for="${node.id}"]`);
      const forceLabel = Boolean(portrait);
      if (forceLabel || shouldShowLabel(node, point, currentLod, runtime)) {
        if (!label) {
          label = ns("text");
          label.setAttribute("class", "node-label");
          label.dataset.labelFor = node.id;
          labelLayer.appendChild(label);
        }
        label.style.display = "";
        label.setAttribute("x", String(point.x));
        label.setAttribute("y", String(point.y + radius + (currentLod === "inspect" ? 22 : 16)));
        label.setAttribute("font-size", currentLod === "inspect" ? "28" : "22");
        label.textContent = portrait || runtime.visibility !== "hidden" ? node.name : "未知";
        label.style.opacity = portrait ? "1" : String(Math.max(0.2, weight));
      } else if (label) {
        label.style.display = "none";
      }
    }
  }

  IMMUNE.renderTreeMap = renderTreeMap;
  IMMUNE.applyCameraTransform = applyCameraTransform;
  IMMUNE.WORLD_SIZE = WORLD_SIZE;
  IMMUNE.HIT_RADIUS = HIT_RADIUS;
})(globalThis);
