(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  const WORLD_SIZE = 3000;
  const CENTER = IMMUNE.WORLD_CENTER || { x: 1500, y: 1500 };

  const RINGS = {
    core: 0,
    universal: [180, 420],
    status: 460,
    family_anchor: 560,
    family: [560, 850],
    pair: [900, 1150],
    triple: [1250, 1400],
    apex: [1500, 1650],
    pair_anchor: 1050,
    triple_anchor: 1320,
    apex_anchor: 1580,
    prime_anchor: 1650
  };

  const FAMILY_ORDER = ["T", "B", "M", "N", "A", "D"];

  function familyAngle(familyId) {
    const index = FAMILY_ORDER.indexOf(familyId);
    if (index < 0) return 0;
    return index * 60 - 90;
  }

  const MAX_RADIUS = 1490;

  function clampRadius(radius) {
    return Math.min(Math.max(radius, 0), MAX_RADIUS);
  }

  function polarToXY(angleDeg, radius) {
    const rad = (angleDeg * Math.PI) / 180;
    const r = clampRadius(radius);
    const x = CENTER.x + r * Math.cos(rad);
    const y = CENTER.y + r * Math.sin(rad);
    return {
      x: Math.min(Math.max(x, 0), WORLD_SIZE),
      y: Math.min(Math.max(y, 0), WORLD_SIZE)
    };
  }

  function ringRadius(ring, slot = 1, slots = 1) {
    const spec = RINGS[ring];
    if (typeof spec === "number") return spec;
    if (Array.isArray(spec)) {
      const t = slots <= 1 ? 0.5 : (slot - 1) / (slots - 1);
      return spec[0] + (spec[1] - spec[0]) * t;
    }
    return 700;
  }

  function layoutPairNode(node) {
    const sector = node.layoutHint?.sector;
    const slot = IMMUNE.pairLayoutSlots?.[sector];
    if (slot) {
      const point = polarToXY(slot[0], slot[1]);
      return { ...point, ring: "pair" };
    }
    return { ...polarToXY(0, ringRadius("pair", node.layoutHint?.slot || 1, 3)), ring: "pair" };
  }

  function layoutUniversalNode(node) {
    const domains = ["DEF", "EXP", "WAR", "MOB", "FUS", "SUR"];
    const hint = node.layoutHint || {};
    const domain = hint.domain || "DEF";
    const domainIndex = domains.indexOf(domain);
    const lane = Number.isFinite(hint.lane) ? hint.lane : 0;
    const angle = domainIndex * 60 - 90 + lane * 8;
    const radius = branchRadius("universal", hint.tier, hint.stage, hint.slot || 1, 7);
    return { ...polarToXY(angle, radius), ring: "universal" };
  }

  function layoutStatusNode(node) {
    const hint = node.layoutHint || {};
    const lane = Number.isFinite(hint.lane) ? hint.lane : ((hint.slot || 1) - 4);
    const angle = 90 + lane * 14;
    const radius = branchRadius("status", hint.tier, hint.stage, hint.slot || 1, 1);
    return { ...polarToXY(angle, radius), ring: "status" };
  }

  function layoutFamilyNode(node) {
    const hint = node.layoutHint || {};
    const sector = hint.sector || node.familyIds?.[0] || "T";
    const lane = Number.isFinite(hint.lane) ? hint.lane : 0;
    const angle = familyAngle(sector) + lane * 9;
    const radius = branchRadius("family", hint.tier, hint.stage, hint.slot || 1, 8);
    return { ...polarToXY(angle, radius), ring: "family" };
  }

  function branchRadius(ring, tier, stage, slot, slots) {
    const bands = {
      universal: { 1: { branch: 210, merge: 300 }, 2: { branch: 360, merge: 410 } },
      family: { 1: { branch: 600, merge: 680 }, 2: { branch: 760, merge: 820 }, 3: { capstone: 850 } },
      status: { 1: { branch: 430, merge: 470 }, 2: { branch: 510, merge: 540 } }
    };
    const byTier = bands[ring]?.[tier];
    if (byTier && stage && byTier[stage] != null) return byTier[stage];
    if (ring === "status") return RINGS.status;
    return ringRadius(ring, slot, slots);
  }

  function layoutNode(node) {
    const hint = node.layoutHint || {};
    const ring = hint.ring || "family";

    if (ring === "core") {
      return { x: CENTER.x, y: CENTER.y, ring: "core", anchor: false };
    }

    if (node.kind === "character_anchor") {
      const anchorRing = ring.endsWith("_anchor") ? ring : `${ring}_anchor`;
      if (ring === "pair" || hint.sector?.length === 2) {
        const point = layoutPairNode({ ...node, layoutHint: { ...hint, ring: "pair_anchor" } });
        return { ...point, anchor: true, ring: hint.ring || "pair_anchor" };
      }
      if (ring === "prime_anchor") {
        return { ...polarToXY(-90, RINGS.prime_anchor), anchor: true, ring: "prime_anchor" };
      }
      if (ring === "apex_anchor") {
        const pairCode = hint.sector === "MEMORY" ? "TB" : hint.sector === "STERILE" ? "MA" : "ND";
        const slot = IMMUNE.pairLayoutSlots?.[pairCode];
        const base = slot ? polarToXY(slot[0], RINGS.apex_anchor) : polarToXY(180, RINGS.apex_anchor);
        return { ...base, anchor: true, ring: "apex_anchor" };
      }
      if (ring === "triple_anchor") {
        const families = node.familyIds || [];
        const angle = familyAngle(families[0] || "T") + 20;
        return { ...polarToXY(angle, RINGS.triple_anchor), anchor: true, ring: "triple_anchor" };
      }
      const sector = hint.sector || node.familyIds?.[0] || "T";
      return {
        ...polarToXY(familyAngle(sector), RINGS.family_anchor),
        anchor: true,
        ring: "family_anchor"
      };
    }

    switch (ring) {
      case "universal":
        return layoutUniversalNode(node);
      case "status":
        return layoutStatusNode(node);
      case "pair":
        return layoutPairNode(node);
      case "triple":
        return layoutTripleNode(node);
      case "apex":
        return layoutApexNode(node);
      case "family":
      default:
        return layoutFamilyNode(node);
    }
  }

  function layoutTripleNode(node) {
    const sector = node.layoutHint?.sector || "TBA";
    const families = node.familyIds || [];
    const angle = familyAngle(families[0] || "T") + (node.layoutHint?.slot || 1) * 4;
    const radius = ringRadius("triple", node.layoutHint?.slot || 1, 3);
    return { ...polarToXY(angle, radius), ring: "triple" };
  }

  function layoutApexNode(node) {
    const sector = node.layoutHint?.sector || "MEMORY";
    const pairCode = sector === "MEMORY" ? "TB" : sector === "STERILE" ? "MA" : sector === "PRIME" ? null : "ND";
    const slot = node.layoutHint?.slot || 1;
    if (sector === "PRIME") {
      return { ...polarToXY(-90, RINGS.apex[1]), ring: "apex" };
    }
    const pairSlot = pairCode ? IMMUNE.pairLayoutSlots?.[pairCode] : null;
    const angle = pairSlot ? pairSlot[0] : 0;
    const radius = ringRadius("apex", slot, 2);
    return { ...polarToXY(angle, radius), ring: "apex" };
  }

  /** @returns {Map<string, {x:number,y:number,anchor?:boolean,ring?:string}>} */
  function layoutCatalog(catalog) {
    const map = new Map();
    for (const node of catalog.nodes) {
      map.set(node.id, layoutNode(node));
    }
    return map;
  }

  IMMUNE.WORLD_SIZE = WORLD_SIZE;
  IMMUNE.layoutCatalog = layoutCatalog;
})(globalThis);
