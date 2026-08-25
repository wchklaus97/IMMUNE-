(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  let activeFilters = null;

  function normalizeQuery(query) {
    return String(query || "").trim().toLowerCase();
  }

  function isRevealed(catalog, player, nodeId) {
    return IMMUNE.deriveNodeState(catalog, player, nodeId).visibility === "revealed";
  }

  function searchableText(node) {
    return [
      node.name,
      node.description,
      ...(node.tags || []),
      ...(node.familyIds || []),
      ...(node.categoryIds || []),
      ...(node.effectOps || [])
    ]
      .filter(Boolean)
      .join(" ")
      .toLowerCase();
  }

  /**
   * Search catalog for revealed nodes matching query (no spoilers).
   * @returns {object[]}
   */
  function searchCatalog(catalog, player, query) {
    const needle = normalizeQuery(query);
    if (!needle) return [];

    return catalog.nodes.filter((node) => {
      if (!isRevealed(catalog, player, node.id)) return false;
      return searchableText(node).includes(needle);
    });
  }

  function matchesFamily(node, familyIds) {
    if (!familyIds?.length) return true;
    return (node.familyIds || []).some((id) => familyIds.includes(id));
  }

  function matchesCategory(node, categoryIds) {
    if (!categoryIds?.length) return true;
    return (node.categoryIds || []).some((id) => categoryIds.includes(id));
  }

  function matchesEligibility(catalog, player, node, eligibilityFilter) {
    if (!eligibilityFilter?.length) return true;
    const state = IMMUNE.deriveNodeState(catalog, player, node.id);
    return eligibilityFilter.includes(state.eligibility);
  }

  /**
   * Apply emphasis filters without mutating layout coordinates.
   * @returns {{ filters: object, emphasis: Map<string, number> }}
   */
  function applyFilters(catalog, player, filters = {}) {
    activeFilters = { ...filters };
    const emphasis = new Map();

    for (const node of catalog.nodes) {
      const visible = isRevealed(catalog, player, node.id);
      let weight = visible ? 1 : 0.15;

      if (visible && filters.familyIds?.length && !matchesFamily(node, filters.familyIds)) {
        weight = 0.15;
      }
      if (visible && filters.categoryIds?.length && !matchesCategory(node, filters.categoryIds)) {
        weight = 0.15;
      }
      if (visible && filters.eligibility?.length && !matchesEligibility(catalog, player, node, filters.eligibility)) {
        weight = 0.15;
      }
      if (visible && filters.affordable && IMMUNE.deriveNodeState(catalog, player, node.id).eligibility === "missing_resource") {
        weight = 0.15;
      }

      emphasis.set(node.id, weight);
    }

    return { filters: activeFilters, emphasis };
  }

  function getActiveFilters() {
    return activeFilters;
  }

  IMMUNE.searchCatalog = searchCatalog;
  IMMUNE.applyFilters = applyFilters;
  IMMUNE.getActiveFilters = getActiveFilters;
})(globalThis);
