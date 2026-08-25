(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  const MAX_TRACKED = 3;

  function getNode(catalog, nodeId) {
    return catalog.nodes.find((node) => node.id === nodeId) || null;
  }

  function clonePlayer(player) {
    return structuredClone(player);
  }

  function eligibilityError(eligibility) {
    switch (eligibility) {
      case "completed":
        return "already_completed";
      case "hidden":
        return "hidden";
      case "missing_prerequisite":
        return "missing_prerequisite";
      case "missing_condition":
        return "missing_condition";
      case "missing_resource":
        return "missing_resource";
      default:
        return "not_ready";
    }
  }

  function deductCosts(player, costs) {
    const normalized = IMMUNE.normalizeCosts(costs);
    for (const [key, amount] of Object.entries(normalized)) {
      player.resources[key] = Number(player.resources[key] || 0) - Number(amount || 0);
    }
  }

  function applyCompletionReveals(catalog, player, completedNodeId) {
    const revealed = new Set(player.revealedNodeIds || []);
    revealed.add(completedNodeId);

    const node = getNode(catalog, completedNodeId);
    if (node?.reveals) {
      for (const id of node.reveals) revealed.add(id);
    }

    for (const candidate of catalog.nodes) {
      if (revealed.has(candidate.id)) continue;
      const runtime = IMMUNE.deriveNodeState(catalog, { ...player, revealedNodeIds: [...revealed] }, candidate.id);
      if (runtime.visibility === "revealed") revealed.add(candidate.id);
    }

    player.revealedNodeIds = [...revealed];
  }

  /**
   * Atomically purchase a research node when eligible.
   */
  function researchNode(catalog, player, nodeId) {
    const node = getNode(catalog, nodeId);
    if (!node) {
      return { ok: false, error: "unknown_node", state: player };
    }

    const runtime = IMMUNE.deriveNodeState(catalog, player, nodeId);
    if (runtime.eligibility !== "ready") {
      return { ok: false, error: eligibilityError(runtime.eligibility), state: player };
    }

    const next = clonePlayer(player);
    deductCosts(next, node.costs);
    next.completedNodeIds = [...next.completedNodeIds, nodeId];
    applyCompletionReveals(catalog, next, nodeId);

    return { ok: true, state: next };
  }

  function trackNode(catalog, player, nodeId, tracked = true) {
    const runtime = IMMUNE.deriveNodeState(catalog, player, nodeId);
    if (runtime.visibility !== "revealed") {
      return { ok: false, error: "hidden", state: player };
    }

    const next = clonePlayer(player);
    const current = new Set(next.trackedNodeIds || []);

    if (tracked) {
      if (current.has(nodeId)) return { ok: true, state: next };
      if (current.size >= MAX_TRACKED) {
        return { ok: false, error: "track_limit", state: player };
      }
      current.add(nodeId);
    } else {
      current.delete(nodeId);
    }

    next.trackedNodeIds = [...current];
    return { ok: true, state: next };
  }

  IMMUNE.MAX_TRACKED = MAX_TRACKED;
  IMMUNE.researchNode = researchNode;
  IMMUNE.trackNode = trackNode;
})(globalThis);
