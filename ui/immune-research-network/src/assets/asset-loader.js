(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  let manifest = null;
  let embedded = null;

  function pageUrl(relativePath) {
    if (typeof document !== "undefined" && document.baseURI) {
      return new URL(relativePath, document.baseURI).href;
    }
    return relativePath;
  }

  async function loadManifest() {
    if (manifest) return manifest;
    if (embedded?.manifest) {
      manifest = embedded.manifest;
      return manifest;
    }
    try {
      const request = global.fetch;
      const response = request ? await request(pageUrl("assets/manifest.json")) : null;
      if (response?.ok) {
        manifest = await response.json();
        return manifest;
      }
    } catch {
      /* file:// or missing fetch: keep going */
    }
    if (embedded && !embedded.dataUrls) {
      manifest = embedded;
      return manifest;
    }
    manifest = { nodes: {}, skills: {}, characters: {}, defense: {} };
    return manifest;
  }

  function setEmbeddedBundle(bundle) {
    embedded = bundle;
    if (bundle?.manifest) manifest = bundle.manifest;
  }

  function resolvePath(relativePath) {
    if (!relativePath) return "";
    if (relativePath.startsWith("data:")) return relativePath;
    if (embedded?.dataUrls?.[relativePath]) return embedded.dataUrls[relativePath];
    return pageUrl(relativePath);
  }

  function researchSymbolPath(nodeId) {
    if (nodeId === "CORE-IMMUNE") return "assets/symbols/SYM-CORE.png";
    const base = /^CHAR-BASE-([TBMNAD])$/.exec(nodeId);
    if (base) return `assets/symbols/SYM-FAMILY-${base[1]}.png`;
    const pair = /^CHAR-PAIR-([TBMNAD]{2})$/.exec(nodeId);
    if (pair) return `assets/symbols/SYM-PAIR-${pair[1]}.png`;
    const triple = /^CHAR-TRIPLE-([TBMNAD]{3})$/.exec(nodeId);
    if (triple) return `assets/symbols/SYM-TRIPLE-${triple[1]}.png`;
    const apex = /^CHAR-APEX-(MEMORY|STERILE|SILENT)$/.exec(nodeId);
    if (apex) return `assets/symbols/SYM-APEX-${apex[1]}.png`;
    if (nodeId === "CHAR-PRIME") return "assets/symbols/SYM-PRIME.png";
    const baseSlot = /^BASE-[TBMNAD]-(\d{2})$/.exec(nodeId);
    if (baseSlot) return `assets/symbols/SYM-BASE-${baseSlot[1]}.png`;
    const uni = /^UNI-(DEF|EXP|WAR|MOB|FUS|SUR)-\d{2}$/.exec(nodeId);
    if (uni) return `assets/symbols/SYM-UNI-${uni[1]}.png`;
    const status = /^STATUS-(MARK|AB|COR|SLOW|INF|CHAIN|CRIT)$/.exec(nodeId);
    if (status) return `assets/symbols/SYM-STATUS-${status[1]}.png`;
    const pairSlot = /^PAIR-[TBMNAD]{2}-(S1|S2|S4)$/.exec(nodeId);
    if (pairSlot) return `assets/symbols/SYM-PAIR-${pairSlot[1]}.png`;
    const tripleSlot = /^TRIPLE-[TBMNAD]{3}-(ROLE|RULE|APEX)$/.exec(nodeId);
    if (tripleSlot) return `assets/symbols/SYM-TRIPLE-${tripleSlot[1]}.png`;
    const apexSlot = /^APEX-(MEMORY|STERILE|SILENT|PRIME)-(GATE|PROTOCOL)$/.exec(nodeId);
    if (apexSlot) return `assets/symbols/SYM-APEX-${apexSlot[2]}.png`;
    return "";
  }

  function skillSlotFromId(skillId) {
    if (!skillId || !String(skillId).startsWith("SKILL-")) return "";
    if (/-(PASSIVE|P1|ROLE|GATE)$/.test(skillId)) return "PASSIVE";
    if (/-(ACTIVE|P2|RULE)$/.test(skillId)) return "ACTIVE";
    if (/-(FIXED|DEF)$/.test(skillId)) return "FIXED";
    if (/-PROTO$/.test(skillId)) return "PROTOCOL";
    if (/-(APEX|ULT)$/.test(skillId)) return "APEX";
    return "";
  }

  function skillSymbolPath(skillId) {
    const slot = skillSlotFromId(skillId);
    if (!slot) return "";
    return `assets/symbols/SYM-SKILL-${slot}.png`;
  }

  function scanSheetPath(nodeId) {
    if (nodeId === "CORE-IMMUNE") return "assets/symbols/sheets/SYM-CORE-scan.png";
    const base = /^CHAR-BASE-([TBMNAD])$/.exec(nodeId);
    if (base) return `assets/symbols/sheets/SYM-FAMILY-${base[1]}-scan.png`;
    const pair = /^CHAR-PAIR-([TBMNAD]{2})$/.exec(nodeId);
    if (pair) return `assets/symbols/sheets/SYM-PAIR-${pair[1]}-scan.png`;
    const triple = /^CHAR-TRIPLE-([TBMNAD]{3})$/.exec(nodeId);
    if (triple) return `assets/symbols/sheets/SYM-TRIPLE-${triple[1]}-scan.png`;
    const apex = /^CHAR-APEX-(MEMORY|STERILE|SILENT)$/.exec(nodeId);
    if (apex) return `assets/symbols/sheets/SYM-APEX-${apex[1]}-scan.png`;
    if (nodeId === "CHAR-PRIME") return "assets/symbols/sheets/SYM-PRIME-scan.png";
    const baseSlot = /^BASE-[TBMNAD]-(\d{2})$/.exec(nodeId);
    if (baseSlot) return `assets/symbols/sheets/SYM-BASE-${baseSlot[1]}-scan.png`;
    const uni = /^UNI-(DEF|EXP|WAR|MOB|FUS|SUR)-\d{2}$/.exec(nodeId);
    if (uni) return `assets/symbols/sheets/SYM-UNI-${uni[1]}-scan.png`;
    const status = /^STATUS-(MARK|AB|COR|SLOW|INF|CHAIN|CRIT)$/.exec(nodeId);
    if (status) return `assets/symbols/sheets/SYM-STATUS-${status[1]}-scan.png`;
    const pairSlot = /^PAIR-[TBMNAD]{2}-(S1|S2|S4)$/.exec(nodeId);
    if (pairSlot) return `assets/symbols/sheets/SYM-PAIR-${pairSlot[1]}-scan.png`;
    const tripleSlot = /^TRIPLE-[TBMNAD]{3}-(ROLE|RULE|APEX)$/.exec(nodeId);
    if (tripleSlot) return `assets/symbols/sheets/SYM-TRIPLE-${tripleSlot[1]}-scan.png`;
    const apexSlot = /^APEX-(MEMORY|STERILE|SILENT|PRIME)-(GATE|PROTOCOL)$/.exec(nodeId);
    if (apexSlot) return `assets/symbols/sheets/SYM-APEX-${apexSlot[2]}-scan.png`;
    return "";
  }

  const SCAN_COLS = 5;
  const SCAN_ROWS = 2;
  const SCAN_FRAMES = SCAN_COLS * SCAN_ROWS;

  function familyProgress(catalog, player, family) {
    let total = 0;
    let done = 0;
    const completed = new Set(player?.completedNodeIds || []);
    for (const node of catalog?.nodes || []) {
      if (!(node.familyIds || []).includes(family)) continue;
      total += 1;
      if (completed.has(node.id)) done += 1;
    }
    return { done, total };
  }

  function pairLadderProgress(catalog, player, code) {
    const completed = new Set(player?.completedNodeIds || []);
    const ids = [`CHAR-PAIR-${code}`, `PAIR-${code}-S1`, `PAIR-${code}-S2`, `PAIR-${code}-S4`];
    let done = 0;
    let total = 0;
    const known = new Set((catalog?.nodes || []).map((node) => node.id));
    for (const id of ids) {
      if (!known.has(id)) continue;
      total += 1;
      if (completed.has(id)) done += 1;
    }
    return { done, total };
  }

  function tripleLadderProgress(catalog, player, code) {
    const completed = new Set(player?.completedNodeIds || []);
    const ids = [`CHAR-TRIPLE-${code}`, `TRIPLE-${code}-ROLE`, `TRIPLE-${code}-RULE`, `TRIPLE-${code}-APEX`];
    let done = 0;
    let total = 0;
    const known = new Set((catalog?.nodes || []).map((node) => node.id));
    for (const id of ids) {
      if (!known.has(id)) continue;
      total += 1;
      if (completed.has(id)) done += 1;
    }
    return { done, total };
  }

  function apexLadderProgress(catalog, player, code) {
    const completed = new Set(player?.completedNodeIds || []);
    const ids = code === "PRIME"
      ? ["CHAR-PRIME", "APEX-PRIME-GATE", "APEX-PRIME-PROTOCOL"]
      : [`CHAR-APEX-${code}`, `APEX-${code}-GATE`, `APEX-${code}-PROTOCOL`];
    let done = 0;
    let total = 0;
    const known = new Set((catalog?.nodes || []).map((node) => node.id));
    for (const id of ids) {
      if (!known.has(id)) continue;
      total += 1;
      if (completed.has(id)) done += 1;
    }
    return { done, total };
  }

  function familyLadderProgress(catalog, player, family) {
    const completed = new Set(player?.completedNodeIds || []);
    const ids = [`CHAR-BASE-${family}`];
    for (let slot = 1; slot <= 8; slot += 1) {
      ids.push(`BASE-${family}-${String(slot).padStart(2, "0")}`);
    }
    let done = 0;
    let total = 0;
    const known = new Set((catalog?.nodes || []).map((node) => node.id));
    for (const id of ids) {
      if (!known.has(id)) continue;
      total += 1;
      if (completed.has(id)) done += 1;
    }
    return { done, total };
  }

  function scanLevelFromEligibility(eligibility, frames = SCAN_FRAMES) {
    switch (eligibility) {
      case "hidden":
        return 0;
      case "missing_prerequisite":
        return Math.min(1, frames - 1);
      case "missing_condition":
        return Math.min(3, frames - 1);
      case "missing_resource":
        return Math.min(5, frames - 1);
      case "ready":
        return Math.min(7, frames - 1);
      case "completed":
        return frames - 1;
      default:
        return 0;
    }
  }

  function scanLevel(done, total, frames = SCAN_FRAMES) {
    if (frames <= 1 || !total || done <= 0) return 0;
    if (done >= total) return frames - 1;
    return Math.min(frames - 1, Math.max(0, Math.round((done / total) * (frames - 1))));
  }

  function scanFrameCell(level, cols = SCAN_COLS, rows = SCAN_ROWS) {
    const frames = cols * rows;
    const frame = Math.max(0, Math.min(frames - 1, Number(level) || 0));
    return { col: frame % cols, row: Math.floor(frame / cols), cols, rows };
  }

  function scanLevelForNode(catalog, player, node) {
    if (!node) return 0;
    if (node.id === "CORE-IMMUNE" || node.kind === "core") {
      const done = (player?.completedNodeIds || []).includes(node.id);
      return done ? SCAN_FRAMES - 1 : 0;
    }
    if (/^CHAR-BASE-[TBMNAD]$/.test(node.id)) {
      const family = node.familyIds?.[0] || node.id.slice(-1);
      const { done, total } = familyLadderProgress(catalog, player, family);
      return scanLevel(done, total);
    }
    const pair = /^CHAR-PAIR-([TBMNAD]{2})$/.exec(node.id);
    if (pair) {
      const { done, total } = pairLadderProgress(catalog, player, pair[1]);
      return scanLevel(done, total);
    }
    const triple = /^CHAR-TRIPLE-([TBMNAD]{3})$/.exec(node.id);
    if (triple) {
      const { done, total } = tripleLadderProgress(catalog, player, triple[1]);
      return scanLevel(done, total);
    }
    const apex = /^CHAR-APEX-(MEMORY|STERILE|SILENT)$/.exec(node.id);
    if (apex) {
      const { done, total } = apexLadderProgress(catalog, player, apex[1]);
      return scanLevel(done, total);
    }
    if (node.id === "CHAR-PRIME") {
      const { done, total } = apexLadderProgress(catalog, player, "PRIME");
      return scanLevel(done, total);
    }
    if (
      /^BASE-[TBMNAD]-\d{2}$/.test(node.id) ||
      /^UNI-(DEF|EXP|WAR|MOB|FUS|SUR)-\d{2}$/.test(node.id) ||
      /^STATUS-(MARK|AB|COR|SLOW|INF|CHAIN|CRIT)$/.test(node.id) ||
      /^PAIR-[TBMNAD]{2}-(S1|S2|S4)$/.test(node.id) ||
      /^TRIPLE-[TBMNAD]{3}-(ROLE|RULE|APEX)$/.test(node.id) ||
      /^APEX-(MEMORY|STERILE|SILENT|PRIME)-(GATE|PROTOCOL)$/.test(node.id)
    ) {
      if (typeof IMMUNE.deriveNodeState === "function") {
        return scanLevelFromEligibility(IMMUNE.deriveNodeState(catalog, player, node.id).eligibility);
      }
      const done = (player?.completedNodeIds || []).includes(node.id);
      return done ? SCAN_FRAMES - 1 : 0;
    }
    return 0;
  }

  async function getNodeIconUrl(nodeId) {
    const symbol = researchSymbolPath(nodeId);
    if (symbol) return symbol;
    const m = await loadManifest();
    const entry = m.nodes?.[nodeId];
    if (!entry) return "";
    if (entry.png) return resolvePath(entry.png);
    return resolvePath(entry.path);
  }

  async function getCharacterPortraitUrl(characterId) {
    return getCharacterFormPortraitUrl(characterId, "catalog");
  }

  async function getCharacterFormPortraitUrl(characterId, formKey) {
    const m = await loadManifest();
    const entry = m.characters?.[characterId];
    if (formKey === "catalog" && entry?.png) return resolvePath(entry.png);
    if (entry?.forms?.[formKey]) return resolvePath(entry.forms[formKey]);
    if (entry && formKey === "fixed" && entry.png) return resolvePath(entry.png);
    if (entry?.path) return resolvePath(entry.path);
    const symbol = researchSymbolPath(characterId);
    return symbol ? pageUrl(symbol) : "";
  }

  async function getSkillIconUrl(skillId) {
    const symbol = skillSymbolPath(skillId);
    if (symbol) return symbol;
    const m = await loadManifest();
    const entry = m.skills?.[skillId];
    if (!entry) return "";
    if (entry.png) return resolvePath(entry.png);
    return resolvePath(entry.path);
  }

  async function getDefenseIconUrl(defenseId) {
    if (defenseId) {
      const processed = `assets/defense/${defenseId}.png`;
      const m = await loadManifest();
      const entry = m.defense?.[defenseId];
      if (entry?.png) return resolvePath(entry.png);
      return resolvePath(processed);
    }
    return "";
  }

  IMMUNE.assets = {
    loadManifest,
    setEmbeddedBundle,
    getNodeIconUrl,
    getCharacterPortraitUrl,
    getCharacterFormPortraitUrl,
    getSkillIconUrl,
    getDefenseIconUrl,
    resolvePath,
    researchSymbolPath,
    skillSymbolPath,
    skillSlotFromId,
    scanSheetPath,
    scanLevel,
    scanLevelFromEligibility,
    familyProgress,
    familyLadderProgress,
    pairLadderProgress,
    tripleLadderProgress,
    apexLadderProgress,
    scanFrameCell,
    scanLevelForNode,
    SCAN_COLS,
    SCAN_ROWS,
    SCAN_FRAMES
  };
  IMMUNE.researchSymbolPath = researchSymbolPath;
  IMMUNE.skillSymbolPath = skillSymbolPath;
  IMMUNE.skillSlotFromId = skillSlotFromId;
  IMMUNE.scanSheetPath = scanSheetPath;
  IMMUNE.scanLevel = scanLevel;
  IMMUNE.scanLevelFromEligibility = scanLevelFromEligibility;
  IMMUNE.familyProgress = familyProgress;
  IMMUNE.familyLadderProgress = familyLadderProgress;
  IMMUNE.pairLadderProgress = pairLadderProgress;
  IMMUNE.tripleLadderProgress = tripleLadderProgress;
  IMMUNE.apexLadderProgress = apexLadderProgress;
  IMMUNE.scanFrameCell = scanFrameCell;
  IMMUNE.scanLevelForNode = scanLevelForNode;
  IMMUNE.SCAN_COLS = SCAN_COLS;
  IMMUNE.SCAN_ROWS = SCAN_ROWS;
  IMMUNE.SCAN_FRAMES = SCAN_FRAMES;
})(globalThis);
