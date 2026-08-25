(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  function getNode(catalog, nodeId) {
    return catalog.nodes.find((node) => node.id === nodeId) || null;
  }

  function clonePlayer(player) {
    return structuredClone(player);
  }

  function isProtocolNode(node) {
    return Boolean(node?.bandwidth) || node?.kind === "protocol" || /-PROTOCOL$/.test(node?.id || "");
  }

  function usedBandwidth(catalog, player) {
    let total = 0;
    for (const id of player.equippedProtocolIds || []) {
      const node = getNode(catalog, id);
      if (node) total += Number(node.bandwidth || 1);
    }
    return total;
  }

  function equippedApexCount(catalog, player) {
    let count = 0;
    for (const id of player.equippedProtocolIds || []) {
      const node = getNode(catalog, id);
      if (node?.apex) count += 1;
    }
    return count;
  }

  function isProtocolUnlocked(catalog, player, nodeId) {
    return player.completedNodeIds.includes(nodeId);
  }

  /**
   * Equip a completed protocol node within bandwidth and Apex limits.
   * @returns {{ ok: boolean, error?: string, state: object }}
   */
  function equipProtocol(catalog, player, nodeId) {
    if (player.inBattle) {
      return { ok: false, error: "loadout_locked_in_battle", state: player };
    }

    const node = getNode(catalog, nodeId);
    if (!node || !isProtocolNode(node)) {
      return { ok: false, error: "not_protocol", state: player };
    }

    if (!isProtocolUnlocked(catalog, player, nodeId)) {
      return { ok: false, error: "not_unlocked", state: player };
    }

    const equipped = player.equippedProtocolIds || [];
    if (equipped.includes(nodeId)) {
      return { ok: false, error: "already_equipped", state: player };
    }

    const cost = Number(node.bandwidth || 1);
    const limit = Number(player.protocolBandwidth || 0);
    if (usedBandwidth(catalog, player) + cost > limit) {
      return { ok: false, error: "bandwidth_exceeded", state: player };
    }

    if (node.apex && equippedApexCount(catalog, player) >= 1) {
      return { ok: false, error: "apex_limit", state: player };
    }

    if (node.exclusiveGroup) {
      for (const id of equipped) {
        const other = getNode(catalog, id);
        if (other?.exclusiveGroup === node.exclusiveGroup) {
          return { ok: false, error: "exclusive_group_conflict", state: player };
        }
      }
    }

    const next = clonePlayer(player);
    next.equippedProtocolIds = [...(next.equippedProtocolIds || []), nodeId];
    return { ok: true, state: next };
  }

  /**
   * Remove an equipped protocol (free outside battle).
   * @returns {{ ok: boolean, error?: string, state: object }}
   */
  function unequipProtocol(player, nodeId) {
    if (player.inBattle) {
      return { ok: false, error: "loadout_locked_in_battle", state: player };
    }

    const equipped = player.equippedProtocolIds || [];
    if (!equipped.includes(nodeId)) {
      return { ok: false, error: "not_equipped", state: player };
    }

    const next = clonePlayer(player);
    next.equippedProtocolIds = next.equippedProtocolIds.filter((id) => id !== nodeId);
    return { ok: true, state: next };
  }

  IMMUNE.equipProtocol = equipProtocol;
  IMMUNE.unequipProtocol = unequipProtocol;
  IMMUNE.usedBandwidth = usedBandwidth;
})(globalThis);
