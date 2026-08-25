(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  const EXPECTED_COUNTS = {
    core: 1,
    character_anchor: 31,
    base_character_research: 48,
    pair_research: 45,
    triple_research: 18,
    apex_research: 8,
    universal: 42,
    status: 7
  };

  const REQUIRED_FIELDS = [
    "id",
    "kind",
    "name",
    "description",
    "familyIds",
    "categoryIds",
    "tags",
    "effectOps",
    "prerequisiteGroups",
    "conditions",
    "costs",
    "revealRule",
    "layoutHint",
    "acquisitionHints"
  ];

  const LIMITED_PREREQ_KINDS = new Set([
    "base_character_research",
    "pair_research",
    "triple_research",
    "universal",
    "status",
    "apex_research"
  ]);

  const EXTENDED_PREREQ_KINDS = new Set(["core", "character_anchor"]);

  const VALID_RESOURCES = new Set(["antigen", "biomass", "protomass", "fusionCore"]);

  function pushError(errors, message) {
    errors.push(message);
  }

  function normalizePairKey(a, b) {
    return [a, b].sort().join("");
  }

  function collectPrerequisiteNodeIds(node) {
    const ids = new Set();
    for (const group of node.prerequisiteGroups || []) {
      for (const nodeId of group.nodeIds || []) {
        ids.add(nodeId);
      }
    }
    return ids;
  }

  function groupBy(items, keyFn) {
    return items.reduce((acc, item) => {
      const key = keyFn(item);
      if (!acc[key]) acc[key] = [];
      acc[key].push(item);
      return acc;
    }, {});
  }

  function validateCounts(catalog, errors) {
    const counts = groupBy(catalog.nodes, (node) => node.kind);
    const total = catalog.nodes.length;
    if (total !== 200) {
      pushError(errors, `expected 200 nodes, got ${total}`);
    }
    for (const [kind, expected] of Object.entries(EXPECTED_COUNTS)) {
      const actual = (counts[kind] || []).length;
      if (actual !== expected) {
        pushError(errors, `expected ${expected} nodes of kind ${kind}, got ${actual}`);
      }
    }
  }

  function validateNodeShape(nodesById, errors) {
    for (const node of Object.values(nodesById)) {
      for (const field of REQUIRED_FIELDS) {
        if (!(field in node)) {
          pushError(errors, `node ${node.id} missing field ${field}`);
        }
      }

      if (node.id === node.id && collectPrerequisiteNodeIds(node).has(node.id)) {
        pushError(errors, `node ${node.id} depends on itself`);
      }

      for (const cost of node.costs || []) {
        if (!VALID_RESOURCES.has(cost.resource)) {
          pushError(errors, `node ${node.id} has invalid cost resource ${cost.resource}`);
        }
        if (typeof cost.amount !== "number" || cost.amount < 0) {
          pushError(errors, `node ${node.id} has negative or invalid cost amount`);
        }
      }

      const isProtocol =
        node.categoryIds?.includes("protocol") ||
        typeof node.bandwidth === "number" ||
        node.apex === true;

      if (isProtocol) {
        if (typeof node.bandwidth !== "number" || node.bandwidth <= 0) {
          pushError(errors, `protocol node ${node.id} must define positive bandwidth`);
        }
        if (typeof node.apex !== "boolean") {
          pushError(errors, `protocol node ${node.id} must define apex boolean`);
        }
        if (!("exclusiveGroup" in node) || typeof node.exclusiveGroup !== "string") {
          pushError(errors, `protocol node ${node.id} must define exclusiveGroup`);
        }
      }

      const requiredGroups = (node.prerequisiteGroups || []).filter((group) => group.mode === "all" || group.mode === "atLeast");
      if (LIMITED_PREREQ_KINDS.has(node.kind) && requiredGroups.length > 1) {
        pushError(errors, `node ${node.id} has ${requiredGroups.length} prerequisite groups, max 1 allowed for kind ${node.kind}`);
      }
      if (EXTENDED_PREREQ_KINDS.has(node.kind) && node.kind !== "core" && requiredGroups.length > 2) {
        pushError(errors, `node ${node.id} has ${requiredGroups.length} prerequisite groups, max 2 allowed for kind ${node.kind}`);
      }

      for (const group of node.prerequisiteGroups || []) {
        if (group.mode !== "all" && group.mode !== "atLeast") {
          pushError(errors, `node ${node.id} has invalid prerequisite mode ${group.mode}`);
          continue;
        }
        if (!Array.isArray(group.nodeIds) || group.nodeIds.length === 0) {
          pushError(errors, `node ${node.id} has empty prerequisite group`);
          continue;
        }
        if (group.mode === "atLeast" && (typeof group.min !== "number" || group.min < 1 || group.min > group.nodeIds.length)) {
          pushError(errors, `node ${node.id} has invalid atLeast.min`);
        }
        for (const nodeId of group.nodeIds) {
          if (!nodesById[nodeId]) {
            pushError(errors, `node ${node.id} references missing prerequisite ${nodeId}`);
          }
          if (nodeId === node.id) {
            pushError(errors, `node ${node.id} references itself as prerequisite`);
          }
        }
      }

      for (const condition of node.conditions || []) {
        if (condition.type === "discovery_flag" && !condition.flag) {
          pushError(errors, `node ${node.id} has discovery condition without flag`);
        }
        if (condition.type === "character_card" && !condition.familyId) {
          pushError(errors, `node ${node.id} has character_card condition without familyId`);
        }
        if (condition.type === "campaign_level" && !/^L0[1-6]$/.test(condition.min || "")) {
          pushError(errors, `node ${node.id} has campaign_level condition without min L01–L06`);
        }
      }
    }
  }

  function validateUniqueIds(nodes, errors) {
    const seen = new Set();
    for (const node of nodes) {
      if (seen.has(node.id)) {
        pushError(errors, `duplicate node id ${node.id}`);
      }
      seen.add(node.id);
    }
  }

  function validatePairUniqueness(definitions, errors) {
    const seen = new Set();
    for (const [code] of definitions.pairCharacters || []) {
      const [a, b] = code.length === 2 ? [code[0], code[1]] : [code.slice(0, 1), code.slice(1)];
      const key = normalizePairKey(a, b);
      if (seen.has(key)) {
        pushError(errors, `duplicate unordered pair ${key}`);
      }
      seen.add(key);
      const reversed = `${b}${a}`;
      if (reversed !== code && definitions.pairSourceFamilies?.[reversed]) {
        pushError(errors, `pair ${code} conflicts with reversed pair ${reversed}`);
      }
    }
  }

  function validateTopology(nodesById, errors) {
    const indegree = new Map(Object.keys(nodesById).map((id) => [id, 0]));
    const edges = new Map(Object.keys(nodesById).map((id) => [id, []]));

    for (const node of Object.values(nodesById)) {
      for (const prereqId of collectPrerequisiteNodeIds(node)) {
        if (!nodesById[prereqId]) continue;
        edges.get(prereqId).push(node.id);
        indegree.set(node.id, indegree.get(node.id) + 1);
      }
    }

    const queue = [];
    for (const [id, degree] of indegree.entries()) {
      if (degree === 0) queue.push(id);
    }

    let visited = 0;
    while (queue.length > 0) {
      const current = queue.shift();
      visited += 1;
      for (const next of edges.get(current) || []) {
        indegree.set(next, indegree.get(next) - 1);
        if (indegree.get(next) === 0) queue.push(next);
      }
    }

    if (visited !== Object.keys(nodesById).length) {
      pushError(errors, "catalog prerequisite graph contains a cycle");
    }
  }

  function validateTraceToCore(nodesById, errors) {
    const memo = new Map();

    function canReachCore(nodeId, stack) {
      if (nodeId === "CORE-IMMUNE") return true;
      if (memo.has(nodeId)) return memo.get(nodeId);
      if (stack.has(nodeId)) return false;

      const node = nodesById[nodeId];
      if (!node) return false;

      const prereqs = collectPrerequisiteNodeIds(node);
      if (prereqs.size === 0) {
        memo.set(nodeId, nodeId === "CORE-IMMUNE");
        return memo.get(nodeId);
      }

      stack.add(nodeId);
      let ok = true;
      for (const prereqId of prereqs) {
        if (!canReachCore(prereqId, stack)) {
          ok = false;
          break;
        }
      }
      stack.delete(nodeId);
      memo.set(nodeId, ok);
      return ok;
    }

    for (const node of Object.values(nodesById)) {
      if (node.id === "CORE-IMMUNE") continue;
      if (!canReachCore(node.id, new Set())) {
        pushError(errors, `node ${node.id} cannot trace prerequisites back to CORE-IMMUNE`);
      }
    }
  }

  function validateCatalog(catalog) {
    const errors = [];
    if (!catalog || !Array.isArray(catalog.nodes)) {
      return { valid: false, errors: ["catalog.nodes must be an array"] };
    }

    validateUniqueIds(catalog.nodes, errors);
    const nodesById = Object.fromEntries(catalog.nodes.map((node) => [node.id, node]));
    validateCounts(catalog, errors);
    validateNodeShape(nodesById, errors);
    validatePairUniqueness(IMMUNE.definitions || {}, errors);
    validateTopology(nodesById, errors);
    validateTraceToCore(nodesById, errors);

    return { valid: errors.length === 0, errors };
  }

  IMMUNE.validateCatalog = validateCatalog;
})(globalThis);
