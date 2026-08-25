(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  /** Branched initial reveal: 2-1 family/universal/status, not a linear drip. */
  const DEMO_REVEALED_IDS = [
    "CORE-IMMUNE",
    "CHAR-BASE-T",
    "CHAR-BASE-B",
    "UNI-DEF-01",
    "UNI-EXP-01",
    "UNI-WAR-01",
    "UNI-MOB-01",
    "UNI-FUS-01",
    "UNI-SUR-01",
    "UNI-DEF-02",
    "UNI-EXP-02",
    "UNI-WAR-02",
    "UNI-MOB-02",
    "UNI-FUS-02",
    "UNI-SUR-02",
    "BASE-T-01",
    "BASE-T-02",
    "BASE-T-03",
    "BASE-B-01",
    "BASE-B-02",
    "BASE-B-03",
    "PAIR-TB-S1",
    "PAIR-TB-S2",
    "CHAR-PAIR-TB",
    "STATUS-MARK",
    "STATUS-AB"
  ];

  /** Completed nodes derived from reveal progression (not random). */
  const DEMO_COMPLETED_IDS = [
    "CORE-IMMUNE",
    "CHAR-BASE-T",
    "CHAR-BASE-B",
    "BASE-T-01",
    "BASE-T-02"
  ];

  /**
   * Create the fixed demo player for the vertical slice.
   * @param {object} catalog
   */
  function createDemoPlayer(catalog) {
    return IMMUNE.defaultPlayer({
      catalogVersion: catalog.version,
      completedNodeIds: [...DEMO_COMPLETED_IDS],
      revealedNodeIds: [...DEMO_REVEALED_IDS],
      trackedNodeIds: [],
      equippedProtocolIds: [],
      protocolBandwidth: 6,
      resources: {
        antigen: 120,
        biomass: 40,
        protomass: 15,
        fusionCore: 2
      },
      unlockedCampaignLevel: "L02",
      view: { x: 1500, y: 1500, zoom: 0.55 },
      selectedNodeId: "BASE-T-03"
    });
  }

  IMMUNE.DEMO_REVEALED_IDS = DEMO_REVEALED_IDS;
  IMMUNE.createDemoPlayer = createDemoPlayer;
})(globalThis);
