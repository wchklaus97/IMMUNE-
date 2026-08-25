(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  const WORLD_CENTER = { x: 1500, y: 1500 };

  function getNode(catalog, nodeId) {
    return catalog.nodes.find((node) => node.id === nodeId) || null;
  }

  function normalizeCosts(costs) {
    if (!costs) return {};
    if (Array.isArray(costs)) {
      return costs.reduce((acc, entry) => {
        if (entry?.resource) acc[entry.resource] = Number(entry.amount || 0);
        return acc;
      }, {});
    }
    return { ...costs };
  }

  function isCompleted(player, nodeId) {
    return player.completedNodeIds.includes(nodeId);
  }

  function isExplicitlyRevealed(player, nodeId) {
    return player.revealedNodeIds.includes(nodeId);
  }

  function evaluatePrerequisiteGroup(player, group) {
    if (!group || !Array.isArray(group.nodeIds)) return true;
    const completed = group.nodeIds.filter((id) => isCompleted(player, id));
    if (group.mode === "atLeast") {
      const min = typeof group.min === "number" ? group.min : 1;
      return completed.length >= min;
    }
    return completed.length === group.nodeIds.length;
  }

  function prerequisitesMet(node, player) {
    const groups = node.prerequisiteGroups || [];
    return groups.every((group) => evaluatePrerequisiteGroup(player, group));
  }

  function normalizeCampaignLevel(id) {
    const match = String(id || "L01").toUpperCase().match(/^L0?([1-6])$/);
    return match ? `L0${match[1]}` : "L01";
  }

  function campaignRank(id) {
    return Number(normalizeCampaignLevel(id).slice(2));
  }

  function playerCampaignLevel(player) {
    return normalizeCampaignLevel(player?.unlockedCampaignLevel || player?.campaignLevel || "L01");
  }

  function campaignLevelName(id) {
    const normalized = normalizeCampaignLevel(id);
    const row = (IMMUNE.definitions?.campaignLevels || []).find((entry) => entry[0] === normalized);
    return row ? row[1] : "";
  }

  function evaluateCondition(condition, player) {
    if (!condition || typeof condition !== "object") return true;
    switch (condition.type) {
      case "characterCard":
        return Boolean(player.characterCards?.[condition.characterId]?.[condition.tier || 1]);
      case "item":
        return Number(player.items?.[condition.itemId] || 0) >= Number(condition.count || 1);
      case "discovery_flag":
      case "discoveryFlag":
        return (player.discoveryFlags || []).includes(condition.flag);
      case "campaign_level":
        return campaignRank(playerCampaignLevel(player)) >= campaignRank(condition.min || "L01");
      default:
        return true;
    }
  }

  function conditionsMet(node, player) {
    return (node.conditions || []).every((condition) => evaluateCondition(condition, player));
  }

  function missingConditions(node, player) {
    return (node.conditions || []).filter((condition) => !evaluateCondition(condition, player));
  }

  function resourcesMet(node, player) {
    const costs = normalizeCosts(node.costs);
    const resources = player.resources || {};
    for (const [key, amount] of Object.entries(costs)) {
      if (Number(resources[key] || 0) < Number(amount || 0)) return false;
    }
    return true;
  }

  function missingResources(node, player) {
    const missing = {};
    const costs = normalizeCosts(node.costs);
    const resources = player.resources || {};
    for (const [key, amount] of Object.entries(costs)) {
      const have = Number(resources[key] || 0);
      const need = Number(amount || 0);
      if (have < need) missing[key] = need - have;
    }
    return missing;
  }

  function prereqsVisible(node, player, catalog, memo = new Map()) {
    const groups = node.prerequisiteGroups || [];
    if (!groups.length) return true;
    return groups.every((group) =>
      (group.nodeIds || []).every((id) => {
        if (isCompleted(player, id) || isExplicitlyRevealed(player, id)) return true;
        const prereqNode = getNode(catalog, id);
        if (!prereqNode) return false;
        if (memo.has(id)) return memo.get(id);
        const visible = deriveVisibility(prereqNode, player, catalog, memo);
        memo.set(id, visible === "revealed");
        return visible === "revealed";
      })
    );
  }

  function revealRuleMet(node, player, catalog, memo) {
    const rule = node.revealRule || { type: "on_prerequisite_visible" };
    if (rule.type === "always") return true;
    if (rule.type === "on_flag") {
      return (player.discoveryFlags || []).includes(rule.flag);
    }
    if (rule.type === "on_prerequisite_visible") {
      return prereqsVisible(node, player, catalog, memo);
    }
    if (rule.type === "completed") {
      return (rule.nodeIds || []).some((id) => isCompleted(player, id));
    }
    if (rule.type === "revealed" || rule.type === "anyRevealed") {
      return (rule.nodeIds || []).some((id) => isExplicitlyRevealed(player, id) || isCompleted(player, id));
    }
    if (rule.type === "anyCompleted") {
      return (rule.nodeIds || []).some((id) => isCompleted(player, id));
    }
    return isExplicitlyRevealed(player, node.id);
  }

  function deriveVisibility(node, player, catalog, memo = new Map()) {
    if (memo.has(node.id)) return memo.get(node.id);
    if (isExplicitlyRevealed(player, node.id) || isCompleted(player, node.id)) {
      memo.set(node.id, "revealed");
      return "revealed";
    }
    const visible = revealRuleMet(node, player, catalog, memo) ? "revealed" : "hidden";
    memo.set(node.id, visible);
    return visible;
  }

  function deriveEligibility(node, player, visibility, completion) {
    if (completion === "complete") return "completed";
    if (visibility === "hidden") return "hidden";
    if (!prerequisitesMet(node, player)) return "missing_prerequisite";
    if (!conditionsMet(node, player)) return "missing_condition";
    if (!resourcesMet(node, player)) return "missing_resource";
    return "ready";
  }

  /**
   * Derive runtime presentation state for a catalog node.
   */
  function deriveNodeState(catalog, player, nodeId, options = {}) {
    const node = getNode(catalog, nodeId);
    if (!node) {
      return {
        visibility: "hidden",
        completion: "incomplete",
        eligibility: "hidden",
        selected: false,
        tracked: false
      };
    }

    const selectedId = options.selectedNodeId ?? player.selectedNodeId ?? null;
    const visibility = deriveVisibility(node, player, catalog);
    const completion = isCompleted(player, nodeId) ? "complete" : "incomplete";
    const tracked = (player.trackedNodeIds || []).includes(nodeId);
    const selected = selectedId === nodeId;
    const eligibility = deriveEligibility(node, player, visibility, completion);
    const state = { visibility, completion, eligibility, selected, tracked };

    if (eligibility === "missing_resource") {
      state.missingResources = missingResources(node, player);
    }
    if (eligibility === "missing_condition") {
      state.missingConditions = missingConditions(node, player);
    }

    return state;
  }

  IMMUNE.WORLD_CENTER = WORLD_CENTER;
  IMMUNE.deriveNodeState = deriveNodeState;
  IMMUNE.normalizeCosts = normalizeCosts;
  IMMUNE.normalizeCampaignLevel = normalizeCampaignLevel;
  IMMUNE.campaignRank = campaignRank;
  IMMUNE.playerCampaignLevel = playerCampaignLevel;
  IMMUNE.campaignLevelName = campaignLevelName;
  IMMUNE._unlockInternals = {
    prerequisitesMet,
    conditionsMet,
    missingConditions,
    resourcesMet,
    revealRuleMet,
    evaluatePrerequisiteGroup,
    evaluateCondition,
    normalizeCosts
  };
})(globalThis);
