(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  const STORAGE_KEY = "immune.research-network.v1";
  const CURRENT_SCHEMA_VERSION = 1;

  function defaultPlayer(defaults = {}) {
    return {
      schemaVersion: CURRENT_SCHEMA_VERSION,
      catalogVersion: defaults.catalogVersion || "1.0.0",
      completedNodeIds: defaults.completedNodeIds ? [...defaults.completedNodeIds] : [],
      revealedNodeIds: defaults.revealedNodeIds ? [...defaults.revealedNodeIds] : [],
      trackedNodeIds: defaults.trackedNodeIds ? [...defaults.trackedNodeIds] : [],
      equippedProtocolIds: defaults.equippedProtocolIds ? [...defaults.equippedProtocolIds] : [],
      protocolBandwidth: defaults.protocolBandwidth ?? 6,
      resources: {
        antigen: 0,
        biomass: 0,
        protomass: 0,
        fusionCore: 0,
        ...(defaults.resources || {})
      },
      characterCards: { ...(defaults.characterCards || {}) },
      items: { ...(defaults.items || {}) },
      discoveryFlags: [...(defaults.discoveryFlags || [])],
      unlockedCampaignLevel: IMMUNE.normalizeCampaignLevel
        ? IMMUNE.normalizeCampaignLevel(defaults.unlockedCampaignLevel || "L01")
        : defaults.unlockedCampaignLevel || "L01",
      inBattle: Boolean(defaults.inBattle),
      view: {
        x: 1500,
        y: 1500,
        zoom: 0.55,
        ...(defaults.view || {})
      },
      selectedNodeId: defaults.selectedNodeId ?? null
    };
  }

  function validNodeIds(catalog) {
    return new Set(catalog.nodes.map((node) => node.id));
  }

  function filterIds(ids, allowed) {
    return [...new Set((ids || []).filter((id) => allowed.has(id)))];
  }

  /**
   * Serialize player progress for localStorage.
   */
  function serializePlayer(player) {
    return JSON.stringify({
      schemaVersion: player.schemaVersion ?? CURRENT_SCHEMA_VERSION,
      catalogVersion: player.catalogVersion,
      completedNodeIds: player.completedNodeIds || [],
      revealedNodeIds: player.revealedNodeIds || [],
      trackedNodeIds: player.trackedNodeIds || [],
      equippedProtocolIds: player.equippedProtocolIds || [],
      protocolBandwidth: player.protocolBandwidth ?? 6,
      resources: player.resources || {},
      characterCards: player.characterCards || {},
      items: player.items || {},
      discoveryFlags: player.discoveryFlags || [],
      unlockedCampaignLevel: player.unlockedCampaignLevel || "L01",
      view: player.view || { x: 1500, y: 1500, zoom: 0.55 },
      selectedNodeId: player.selectedNodeId ?? null
    });
  }

  /**
   * Restore player from persisted JSON, keeping only IDs that still exist in catalog.
   */
  function restorePlayer(raw, catalog, defaults = {}) {
    const parsed = typeof raw === "string" ? JSON.parse(raw) : raw;
    const allowed = validNodeIds(catalog);
    const base = defaultPlayer(defaults);

    const restored = {
      ...base,
      schemaVersion: parsed.schemaVersion ?? CURRENT_SCHEMA_VERSION,
      catalogVersion: catalog.version || parsed.catalogVersion || base.catalogVersion,
      completedNodeIds: filterIds(parsed.completedNodeIds, allowed),
      revealedNodeIds: filterIds(parsed.revealedNodeIds, allowed),
      trackedNodeIds: filterIds(parsed.trackedNodeIds, allowed).slice(0, IMMUNE.MAX_TRACKED || 3),
      equippedProtocolIds: filterIds(parsed.equippedProtocolIds, allowed),
      protocolBandwidth: parsed.protocolBandwidth ?? base.protocolBandwidth,
      resources: { ...base.resources, ...(parsed.resources || {}) },
      characterCards: { ...(parsed.characterCards || {}) },
      items: { ...(parsed.items || {}) },
      discoveryFlags: [...(parsed.discoveryFlags || [])],
      unlockedCampaignLevel: IMMUNE.normalizeCampaignLevel
        ? IMMUNE.normalizeCampaignLevel(
            parsed.unlockedCampaignLevel || parsed.campaignLevel || base.unlockedCampaignLevel
          )
        : parsed.unlockedCampaignLevel || base.unlockedCampaignLevel,
      inBattle: false,
      view: { ...base.view, ...(parsed.view || {}) },
      selectedNodeId: parsed.selectedNodeId && allowed.has(parsed.selectedNodeId)
        ? parsed.selectedNodeId
        : null
    };

    if (!restored.revealedNodeIds.includes("CORE-IMMUNE") && allowed.has("CORE-IMMUNE")) {
      restored.revealedNodeIds.unshift("CORE-IMMUNE");
    }

    for (const id of restored.completedNodeIds) {
      if (!restored.revealedNodeIds.includes(id)) restored.revealedNodeIds.push(id);
    }

    return restored;
  }

  function savePlayer(player) {
    if (typeof localStorage !== "undefined") {
      localStorage.setItem(STORAGE_KEY, serializePlayer(player));
    }
  }

  function loadPlayer(catalog, defaults = {}) {
    if (typeof localStorage === "undefined") return defaultPlayer(defaults);
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return defaultPlayer(defaults);
    return restorePlayer(raw, catalog, defaults);
  }

  IMMUNE.STORAGE_KEY = STORAGE_KEY;
  IMMUNE.defaultPlayer = defaultPlayer;
  IMMUNE.serializePlayer = serializePlayer;
  IMMUNE.restorePlayer = restorePlayer;
  IMMUNE.savePlayer = savePlayer;
  IMMUNE.loadPlayer = loadPlayer;
})(globalThis);
