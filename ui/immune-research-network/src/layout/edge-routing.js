(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  function getNode(catalog, nodeId) {
    return catalog.nodes.find((node) => node.id === nodeId) || null;
  }

  function edgeId(from, to, kind) {
    return `${from}->${to}:${kind}`;
  }

  function addEdge(edges, seen, edge) {
    const key = edgeId(edge.from, edge.to, edge.kind);
    if (seen.has(key)) return;
    seen.add(key);
    edges.push(edge);
  }

  function curvePath(fromPoint, toPoint) {
    const cx = IMMUNE.WORLD_CENTER?.x ?? 1500;
    const cy = IMMUNE.WORLD_CENTER?.y ?? 1500;
    const mx = (fromPoint.x + toPoint.x) / 2;
    const my = (fromPoint.y + toPoint.y) / 2;
    const dx = mx - cx;
    const dy = my - cy;
    const len = Math.hypot(dx, dy) || 1;
    const offset = 80;
    const qx = mx + (dx / len) * offset;
    const qy = my + (dy / len) * offset;
    return `M ${fromPoint.x} ${fromPoint.y} Q ${qx} ${qy} ${toPoint.x} ${toPoint.y}`;
  }

  /**
   * Build routed edges for the research network.
   * @returns {Array<{id:string,from:string,to:string,kind:string,path:string}>}
   */
  function buildEdges(catalog) {
    const layout = IMMUNE.layoutCatalog(catalog);
    const edges = [];
    const seen = new Set();

    for (const node of catalog.nodes) {
      const toPoint = layout.get(node.id);
      if (!toPoint) continue;

      for (const group of node.prerequisiteGroups || []) {
        const kind = group.mode === "atLeast" ? "optional" : "required";
        for (const fromId of group.nodeIds || []) {
          const fromPoint = layout.get(fromId);
          if (!fromPoint) continue;
          addEdge(edges, seen, {
            id: edgeId(fromId, node.id, kind),
            from: fromId,
            to: node.id,
            kind,
            path: curvePath(fromPoint, toPoint)
          });
        }
      }

      if (node.kind === "character_anchor" && (node.layoutHint?.ring === "pair_anchor" || node.id.startsWith("CHAR-PAIR-"))) {
        const pairCode = node.layoutHint?.sector || node.id.replace("CHAR-PAIR-", "");
        const families = IMMUNE.definitions?.pairSourceFamilies?.[pairCode] || node.familyIds || [];
        for (const familyId of families.slice(0, 2)) {
          const fromId = `CHAR-BASE-${familyId}`;
          const fromPoint = layout.get(fromId);
          if (!fromPoint) continue;
          addEdge(edges, seen, {
            id: edgeId(fromId, node.id, "dual_source"),
            from: fromId,
            to: node.id,
            kind: "dual_source",
            path: curvePath(fromPoint, toPoint)
          });
        }
      }

      if (node.tags?.includes("pair") && node.kind === "pair_research" && node.layoutHint?.slot === 1) {
        for (const familyId of node.familyIds || []) {
          const anchorId = `CHAR-BASE-${familyId}`;
          const fromPoint = layout.get(anchorId);
          if (!fromPoint) continue;
          addEdge(edges, seen, {
            id: edgeId(anchorId, node.id, "affinity"),
            from: anchorId,
            to: node.id,
            kind: "affinity",
            path: curvePath(fromPoint, toPoint)
          });
        }
      }
    }

    return edges;
  }

  IMMUNE.buildEdges = buildEdges;
})(globalThis);
