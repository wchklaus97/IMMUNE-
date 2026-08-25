(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  function angleBetween(a, b) {
    return Math.atan2(b.y - a.y, b.x - a.x);
  }

  function dist(a, b) {
    return Math.hypot(a.x - b.x, a.y - b.y);
  }

  /**
   * Wire keyboard navigation for research tree.
   */
  function createKeyboardGamepad(options) {
    const {
      viewport,
      catalog,
      layout,
      getPlayer,
      onSelectNode,
      onResearch,
      onTrack,
      onHome,
      onRestoreCamera,
      onPushCameraBookmark,
      onZoomIn,
      onZoomOut
    } = options;

    function nearestNode(currentId, direction) {
      const current = layout.get(currentId);
      if (!current) return null;
      const player = getPlayer();
      let best = null;
      let bestScore = Infinity;
      const targetAngle = {
        ArrowUp: -Math.PI / 2,
        ArrowDown: Math.PI / 2,
        ArrowLeft: Math.PI,
        ArrowRight: 0
      }[direction];

      for (const node of catalog.nodes) {
        if (node.id === currentId) continue;
        const point = layout.get(node.id);
        if (!point) continue;
        const state = IMMUNE.deriveNodeState(catalog, player, node.id);
        if (state.visibility === "hidden") continue;
        const d = dist(current, point);
        const ang = angleBetween(current, point);
        let delta = Math.abs(ang - targetAngle);
        if (delta > Math.PI) delta = Math.PI * 2 - delta;
        const score = d + delta * 400;
        if (score < bestScore) {
          bestScore = score;
          best = node.id;
        }
      }
      return best;
    }

    function onKeyDown(event) {
      const player = getPlayer();
      const selected = player.selectedNodeId || "CORE-IMMUNE";

      if (event.key === "Tab") return;

      if (event.key === "Home") {
        event.preventDefault();
        onHome?.();
        return;
      }

      if (event.key === "+" || event.key === "=") {
        event.preventDefault();
        onZoomIn?.();
        return;
      }

      if (event.key === "-" || event.key === "_") {
        event.preventDefault();
        onZoomOut?.();
        return;
      }

      if (event.key === "Escape") {
        event.preventDefault();
        onRestoreCamera?.();
        return;
      }

      if (["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(event.key)) {
        event.preventDefault();
        const next = nearestNode(selected, event.key);
        if (next) onSelectNode?.(next);
        return;
      }

      if (event.key === "Enter") {
        event.preventDefault();
        onSelectNode?.(selected);
        return;
      }

      if (event.key === "f" || event.key === "F") {
        event.preventDefault();
        const runtime = IMMUNE.deriveNodeState(catalog, player, selected);
        onTrack?.(selected, !runtime.tracked);
        return;
      }

      if (event.key === "r" || event.key === "R") {
        event.preventDefault();
        onResearch?.(selected);
        return;
      }

      if (event.key === "b" || event.key === "B") {
        onPushCameraBookmark?.();
      }
    }

    document.addEventListener("keydown", onKeyDown);

    return {
      destroy() {
        document.removeEventListener("keydown", onKeyDown);
      }
    };
  }

  IMMUNE.createKeyboardGamepad = createKeyboardGamepad;
})(globalThis);
