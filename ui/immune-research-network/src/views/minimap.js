(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  const WORLD = 3000;

  function clear(el) {
    while (el.firstChild) el.removeChild(el.firstChild);
  }

  function applyMinimapViewport(rect, player) {
    const zoom = player.view?.zoom ?? 0.55;
    const vx = player.view?.x ?? 1500;
    const vy = player.view?.y ?? 1500;
    const vpSize = (WORLD / zoom) * 0.35;
    rect.setAttribute("x", String(vx - vpSize / 2));
    rect.setAttribute("y", String(vy - vpSize / 2));
    rect.setAttribute("width", String(vpSize));
    rect.setAttribute("height", String(vpSize));
  }

  /**
   * Render minimap with 3000×3000 viewport rectangle.
   */
  function renderMinimap(container, viewModel, handlers = {}, options = {}) {
    const { player, layout, catalog } = viewModel;
    if (options.cameraOnly) {
      const rect = container.querySelector(".minimap-viewport");
      if (rect) {
        applyMinimapViewport(rect, player);
        return;
      }
    }
    clear(container);
    const size = container.clientWidth || 160;
    const scale = size / WORLD;

    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.setAttribute("class", "minimap-svg");
    svg.setAttribute("viewBox", `0 0 ${WORLD} ${WORLD}`);
    svg.setAttribute("width", String(size));
    svg.setAttribute("height", String(size));

    for (const node of catalog.nodes) {
      const point = layout.get(node.id);
      if (!point) continue;
      const runtime = IMMUNE.deriveNodeState(catalog, player, node.id);
      if (runtime.visibility === "hidden" && !point.anchor) continue;
      const dot = document.createElementNS("http://www.w3.org/2000/svg", "circle");
      dot.setAttribute("cx", String(point.x));
      dot.setAttribute("cy", String(point.y));
      dot.setAttribute("r", point.anchor ? "8" : "4");
      dot.setAttribute("class", runtime.completion === "complete" ? "minimap-dot done" : "minimap-dot");
      svg.appendChild(dot);
    }

    const viewport = document.createElementNS("http://www.w3.org/2000/svg", "rect");
    viewport.setAttribute("class", "minimap-viewport");
    applyMinimapViewport(viewport, player);
    svg.appendChild(viewport);

    svg.addEventListener("click", (event) => {
      const rect = svg.getBoundingClientRect();
      const x = ((event.clientX - rect.left) / rect.width) * WORLD;
      const y = ((event.clientY - rect.top) / rect.height) * WORLD;
      handlers.onPanTo?.({ x, y });
    });

    container.appendChild(svg);
  }

  IMMUNE.renderMinimap = renderMinimap;
})(globalThis);
