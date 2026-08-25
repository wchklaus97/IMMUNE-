(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  IMMUNE.isCoverMode = new URLSearchParams(global.location.search).has("cover");

  IMMUNE.COVER_SHEETS = {
    "CORE-IMMUNE": "assets/symbols/sheets/SYM-CORE-scan.png",
    "CHAR-BASE-T": "assets/symbols/sheets/SYM-FAMILY-T-scan.png",
    "CHAR-BASE-B": "assets/symbols/sheets/SYM-FAMILY-B-scan.png",
    "CHAR-BASE-M": "assets/symbols/sheets/SYM-FAMILY-M-scan.png",
    "CHAR-BASE-N": "assets/symbols/sheets/SYM-FAMILY-N-scan.png",
    "CHAR-BASE-A": "assets/symbols/sheets/SYM-FAMILY-A-scan.png",
    "CHAR-BASE-D": "assets/symbols/sheets/SYM-FAMILY-D-scan.png"
  };

  IMMUNE.COVER_PORTRAITS = IMMUNE.COVER_SHEETS;

  const CARD_SIDE = {
    T: "left",
    M: "left",
    N: "left",
    B: "right",
    A: "right",
    D: "right"
  };

  function fillCards(viewModel) {
    const left = document.getElementById("cover-cards-left");
    const right = document.getElementById("cover-cards-right");
    if (!left || !right) return;
    left.replaceChildren();
    right.replaceChildren();
    const characters = IMMUNE.gameAssets?.characters || {};
    const catalog = viewModel?.catalog;
    const player = viewModel?.player;
    for (const id of Object.keys(IMMUNE.COVER_SHEETS)) {
      const character = characters[id];
      if (!character) continue;
      const family = character.families?.[0] || "";
      const card = document.createElement("div");
      card.className = "cover-card";
      card.style.borderColor = `var(--family-${family.toLowerCase()}, #5de4ff)`;
      const symbol = document.createElement("div");
      symbol.className = "cover-card-symbol";
      const { done, total } = IMMUNE.familyLadderProgress
        ? IMMUNE.familyLadderProgress(catalog, player, family)
        : { done: 0, total: 1 };
      const level = IMMUNE.scanLevel ? IMMUNE.scanLevel(done, total) : 0;
      const cell = IMMUNE.scanFrameCell
        ? IMMUNE.scanFrameCell(level)
        : { col: 0, row: 0, cols: 5, rows: 2 };
      const x = cell.cols > 1 ? (cell.col / (cell.cols - 1)) * 100 : 0;
      const y = cell.rows > 1 ? (cell.row / (cell.rows - 1)) * 100 : 0;
      symbol.style.backgroundImage = `url("${IMMUNE.COVER_SHEETS[id]}")`;
      symbol.style.backgroundPosition = `${x}% ${y}%`;
      const copy = document.createElement("div");
      copy.className = "cover-card-copy";
      const title = document.createElement("strong");
      title.textContent = character.name;
      title.style.color = `var(--family-${family.toLowerCase()}, #5de4ff)`;
      const role = document.createElement("span");
      role.textContent = character.role || "";
      copy.append(title, role);
      card.append(symbol, copy);
      (CARD_SIDE[family] === "right" ? right : left).appendChild(card);
    }
  }

  /**
   * Cinematic 16:9 poster using the live star map + family symbols.
   * Cover anchors show organs/weapons, not character likeness.
   */
  function applyCoverMode(app) {
    if (!IMMUNE.isCoverMode || !app) return;
    document.documentElement.classList.add("is-cover");
    fillCards(app.store?.getState?.());
    app.store.dispatch({ type: "SET_VIEW_MODE", mode: "map" });
    app.panZoom.setView({ x: 1500, y: 1500, zoom: 0.42 });
  }

  IMMUNE.applyCoverMode = applyCoverMode;
})(globalThis);
