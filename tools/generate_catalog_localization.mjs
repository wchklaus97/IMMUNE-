#!/usr/bin/env node

import { readFile, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const CATALOG_PATH = join(ROOT, "godot/immune/resources/catalog/immune_catalog.json");
const OUTPUT_PATH = join(ROOT, "godot/immune/translations/research_catalog.csv");

const FAMILY_NAMES = {
  T: "T Cell",
  B: "B Cell",
  M: "Macrophage",
  N: "NK Cell",
  A: "Antibody Construct",
  D: "Dendritic Cell"
};

const CHARACTER_NAMES = {
  "CHAR-BASE-T": "T Cell",
  "CHAR-BASE-B": "B Cell",
  "CHAR-BASE-M": "Macrophage",
  "CHAR-BASE-N": "NK Cell",
  "CHAR-BASE-A": "Antibody Construct",
  "CHAR-BASE-D": "Dendritic Cell",
  "CHAR-PAIR-TB": "Memory Hunter",
  "CHAR-PAIR-TM": "Phagocyte Assault",
  "CHAR-PAIR-TN": "Cytotoxic Blade",
  "CHAR-PAIR-TA": "Precision Antibody",
  "CHAR-PAIR-TD": "Immune Command",
  "CHAR-PAIR-BM": "Antigen Processing",
  "CHAR-PAIR-BN": "Marked Execution",
  "CHAR-PAIR-BA": "Antibody Storm",
  "CHAR-PAIR-BD": "Antigen Presentation",
  "CHAR-PAIR-MN": "Infection Clearance",
  "CHAR-PAIR-MA": "Immune Bulwark",
  "CHAR-PAIR-MD": "Antigen Nexus",
  "CHAR-PAIR-NA": "Antibody Pursuit",
  "CHAR-PAIR-ND": "Hunter Beacon",
  "CHAR-PAIR-AD": "Immune Network",
  "CHAR-TRIPLE-TBA": "Adaptive Immune Core",
  "CHAR-TRIPLE-TND": "Global Interception Nexus",
  "CHAR-TRIPLE-MAD": "Tissue Defense Sanctuary",
  "CHAR-TRIPLE-BMD": "Tissue Regeneration Foundry",
  "CHAR-TRIPLE-BNA": "Antibody Hunter Swarm",
  "CHAR-TRIPLE-TMN": "Apoptosis Reactor",
  "CHAR-APEX-MEMORY": "Long-term Immune Archive",
  "CHAR-APEX-STERILE": "Sterile Sanctuary",
  "CHAR-APEX-SILENT": "Silent Hunter Network",
  "CHAR-PRIME": "IMMUNE PRIME"
};

const BASE_RESEARCH_NAMES = {
  T: [
    "T Cell Deployment Clearance",
    "Cytotoxic Core",
    "T Cell Fixed Turret Specialization",
    "T Cell Mobility Clearance",
    "Antigen-specific Pursuit",
    "T Cell Formation Resonance",
    "Cytotoxic Awakening",
    "T Cell Ultimate Immunity"
  ],
  B: [
    "B Cell Deployment Clearance",
    "Antibody Secretion Core",
    "B Cell Fixed Turret Specialization",
    "B Cell Mobility Clearance",
    "Long-range Mark Lock",
    "B Cell Formation Resonance",
    "Plasma Cell Awakening",
    "B Cell Ultimate Immunity"
  ],
  M: [
    "Macrophage Deployment Clearance",
    "Phagocytic Recovery Core",
    "Macrophage Fixed Turret Specialization",
    "Macrophage Mobility Clearance",
    "Infection Residue Pursuit",
    "Macrophage Formation Resonance",
    "Tissue Repair Awakening",
    "Macrophage Ultimate Immunity"
  ],
  N: [
    "NK Cell Deployment Clearance",
    "Natural Cytotoxic Core",
    "NK Cell Fixed Turret Specialization",
    "NK Cell Mobility Clearance",
    "Abnormal Cell Hunt",
    "NK Cell Formation Resonance",
    "Antibody-free Awakening",
    "NK Cell Ultimate Immunity"
  ],
  A: [
    "Antibody Construct Deployment Clearance",
    "Neutralizing Antibody Core",
    "Antibody Fixed Turret Specialization",
    "Antibody Fixed Relay Clearance",
    "Antigen Neutralization Lock",
    "Antibody Formation Resonance",
    "Multivalent Antibody Awakening",
    "Antibody Ultimate Immunity"
  ],
  D: [
    "Dendritic Cell Deployment Clearance",
    "Antigen Presentation Core",
    "Dendritic Fixed Turret Specialization",
    "Dendritic Cell Mobility Clearance",
    "Immune Signal Guidance",
    "Dendritic Formation Resonance",
    "Co-stimulation Awakening",
    "Dendritic Ultimate Immunity"
  ]
};

const EXACT = {
  "UNI-DEF-01": ["Core Repair Efficiency", "Global defense: accelerates continuous Immune Core repair. This percentage is supplied only by the Defense ring."],
  "UNI-DEF-02": ["Fixed Turret Expansion", "Global defense: increases simultaneous fixed-turret capacity by 1. Capacity is not a damage percentage."],
  "UNI-DEF-03": ["Turret Support Chain", "2-1 convergence: links repair and turret slots into a support chain. Unlocks a rule without stacking more repair percentage."],
  "UNI-DEF-04": ["Route Disruption Barrier", "Slightly slows enemies moving along invasion routes. This is separate from status-chemistry slow and has a smaller value."],
  "UNI-DEF-05": ["Core Emergency Shield", "Deploys a one-use shield when Core health falls below its threshold."],
  "UNI-DEF-06": ["Defense Wave Preparation", "Restores some durability to the Core and fixed turrets before each wave begins."],
  "UNI-DEF-07": ["Ultimate Core Defense", "3-1 convergence: strengthens the shield without stacking another repair percentage."],
  "UNI-EXP-01": ["Extended Recon Range", "Global expedition: increases reveal distance by 6%."],
  "UNI-EXP-02": ["Enhanced Fog Preview", "Allows a preview of enemy populations in infection zones before entry. Unlocks a rule."],
  "UNI-EXP-03": ["Expedition Node Access", "2-1 convergence: opens the next layer of expedition nodes. This is not a vision percentage."],
  "UNI-EXP-04": ["Frontier Construction Clearance", "Allows temporary fixed positions to be placed on expedition tiles."],
  "UNI-EXP-05": ["Expedition Supply Efficiency", "Increases resources returned from expeditions by 6%."],
  "UNI-EXP-06": ["Extended Retreat Window", "Extends the safe window before a forced retreat. Unlocks a rule."],
  "UNI-EXP-07": ["Ultimate Territorial Expansion", "3-1 convergence: adds 4% expedition supply yield without stacking more vision."],
  "UNI-WAR-01": ["Global Attack Tempo", "Global warfare: increases all attack speed by 5%. Attack speed comes from the War ring, not the Mobility ring."],
  "UNI-WAR-02": ["Army Line Capacity", "Global warfare: increases lateral army capacity by 1. Capacity is not a percentage and does not double-stack with attack speed."],
  "UNI-WAR-03": ["Global Fire Synchronization", "2-1 convergence: adds 4% attack speed. The merge bonus is smaller than the first branch."],
  "UNI-WAR-04": ["Fixed Turret Fire Rate", "Increases fire rate by 4% only while on fixed duty. Calculated separately from global attack speed."],
  "UNI-WAR-05": ["Mobile Pursuit Tempo", "Increases attack speed by 4% only while on mobile duty. Mutually exclusive with the fixed-duty bonus."],
  "UNI-WAR-06": ["Skill Cooldown Compression", "Reduces all skill cooldowns by 6%. This follows the cooldown axis instead of stacking attack speed."],
  "UNI-WAR-07": ["Ultimate Total War Tactics", "3-1 convergence: adds 4% attack speed. Cooldown is handled by the prior branch and is not stacked here."],
  "UNI-MOB-01": ["Global Movement Tempo", "Global mobility: increases movement speed by 6%. Movement speed comes only from the Mobility ring."],
  "UNI-MOB-02": ["Rapid Deployment Channel", "Reduces deployment wind-up by 8%. This is not attack speed."],
  "UNI-MOB-03": ["Cross-region Transfer", "2-1 convergence: unlocks cross-region transfer without stacking more movement speed."],
  "UNI-MOB-04": ["Mobile Unit Durability", "Increases mobile-duty health by 6%. This is survivability, not damage output."],
  "UNI-MOB-05": ["Mobile Synergy Amplifier", "Nearby mobile units grant each other a formation bonus. Unlocks a rule without attack speed."],
  "UNI-MOB-06": ["Retreat Cover Formation", "Mobile units provide brief covering fire for the Core during retreat."],
  "UNI-MOB-07": ["Ultimate Mobile Formation", "3-1 convergence: adds 4% movement speed without placing attack speed in the Mobility capstone."],
  "UNI-FUS-01": ["Dual-family Affinity Foundation", "Global fusion: slightly lowers dual-family affinity research costs without directly increasing damage."],
  "UNI-FUS-02": ["Fusion Efficiency Amplifier", "Increases Fusion Core conversion efficiency by 6%."],
  "UNI-FUS-03": ["Triple-fusion Readiness", "2-1 convergence: opens triple-fusion qualification checks. This is not an output percentage."],
  "UNI-FUS-04": ["Legacy Trait Retention", "Preserves more passive traits from source families after fusion. Unlocks a rule."],
  "UNI-FUS-05": ["Fusion Core Recovery", "Refunds 20% of Fusion Cores when replacing a fusion."],
  "UNI-FUS-06": ["Apex Route Readiness", "Reveals missing expedition flags required by hidden Apex routes."],
  "UNI-FUS-07": ["Ultimate Fusion Engineering", "3-1 convergence: adds 4% fusion efficiency without stacking another affinity discount."],
  "UNI-SUR-01": ["Biomass Recovery Efficiency", "Global survival: increases biomass recovery by 6%. Recovery comes only from the Survival ring."],
  "UNI-SUR-02": ["Accelerated Injury Repair", "Increases unit regeneration by 6%. It does not repair the Core, which belongs to the Defense ring."],
  "UNI-SUR-03": ["Core Emergency Repair", "2-1 convergence: performs one emergency Core repair between waves without stacking continuous Core repair."],
  "UNI-SUR-04": ["Cell Regeneration Reserve", "Stores regeneration charges on kills. Unlocks a rule."],
  "UNI-SUR-05": ["Post-casualty Backup", "Allows one brief redeployment after a unit is defeated. Unlocks a rule."],
  "UNI-SUR-06": ["Resource Shortage Relief", "Guarantees a minimum drop in the next wave when resources are depleted."],
  "UNI-SUR-07": ["Ultimate Survival Repair", "3-1 convergence: adds 4% unit regeneration without stacking biomass or Core repair."],
  "STATUS-MARK": ["Mark Stack Chemistry", "Global chemistry: increases maximum Mark stacks by 1 and gives marked targets extra focus-fire priority during the effect."],
  "STATUS-AB": ["Antibody Weakness Chemistry", "Global chemistry: increases weakness amplification by 8%. The Status ring owns vulnerability while the War ring owns attack speed."],
  "STATUS-COR": ["Corrosive Armor-break Chemistry", "2-1 convergence: adds 8% armor shred through a rule conversion without applying weakness twice."],
  "STATUS-SLOW": ["Slow Control Chemistry", "Reduces controlled enemy movement speed by 8%. Separate from the Defense route barrier."],
  "STATUS-INF": ["Infection Spread Chemistry", "Allows a status to jump to a nearby enemy on a kill or at maximum stacks."],
  "STATUS-CHAIN": ["Chain-jump Chemistry", "Allows chained damage and Marks to jump one additional time."],
  "STATUS-CRIT": ["Critical Trigger Chemistry", "3-1 convergence: adds 5% global critical chance without stacking more weakness or armor shred."]
};

const CAMPAIGN_NAMES = {
  L01: "Mucosal Entry",
  L02: "Bloodstream Corridor",
  L03: "Lymphatic Filter",
  L04: "Inflammatory Lesion",
  L05: "Tumor Tissue",
  L06: "Source of Infection"
};

function researchKey(id, field) {
  return `RESEARCH_${id.replace(/[^A-Za-z0-9]+/g, "_")}_${field.toUpperCase()}`;
}

function baseDescription(family, slot) {
  const name = FAMILY_NAMES[family];
  const descriptions = [
    `Unlocks deployment and formation access for the ${name}.`,
    `Strengthens the ${name}'s core passive and biological role.`,
    `Improves the ${name}'s efficiency and range as a fixed turret.`,
    family === "A"
      ? "Grants the Antibody Construct fixed-relay clearance, strengthening formation relays instead of creating a mobile unit."
      : `Grants the ${name} mobile deployment clearance for Total War.`,
    `Optimizes the ${name}'s target selection and combat AI behavior.`,
    `Amplifies formation links between the ${name} and adjacent characters.`,
    `Awakens the ${name}'s special passive and talent abilities.`,
    `The ${name} family's ultimate permanent research, unlocking advanced fusion and Apex eligibility.`
  ];
  return descriptions[slot - 1];
}

function characterTranslation(node) {
  const name = CHARACTER_NAMES[node.id];
  if (!name) throw new Error(`Missing character name for ${node.id}`);
  if (node.id.startsWith("CHAR-BASE-")) {
    return [name, `${name} identity anchor marking the start of this family's research sector.`];
  }
  if (node.id.startsWith("CHAR-PAIR-")) {
    return [name, `${name}, a dual-family fusion character anchor combining the ${node.familyIds[0]} and ${node.familyIds[1]} lineages.`];
  }
  if (node.id.startsWith("CHAR-TRIPLE-")) {
    return [name, `${name}, a three-family fusion character anchor integrating the ultimate capabilities of the ${node.familyIds.join(", ")} lineages.`];
  }
  if (node.id === "CHAR-PRIME") {
    return [name, "The endgame identity formed from all six family ultimates and any three named triple fusions. It does not require completion of the other 199 nodes."];
  }
  return [name, `${name}, a hidden Apex identity anchor requiring its matching dual-family Rank 4 protocol and an expedition discovery.`];
}

function generatedTranslation(node) {
  if (EXACT[node.id]) return EXACT[node.id];
  if (node.id === "CORE-IMMUNE") {
    return ["Immune Core", "The origin of the permanent research network. Six global infrastructure rings—Defense, Expedition, War, Mobility, Fusion, and Survival—plus Status Chemistry surround the Core without belonging to one family."];
  }
  if (node.kind === "character_anchor") return characterTranslation(node);
  if (node.kind === "base_character_research") {
    const match = /^BASE-([TBMNAD])-(\d{2})$/.exec(node.id);
    if (!match) throw new Error(`Invalid base research id ${node.id}`);
    const family = match[1];
    const slot = Number(match[2]);
    return [BASE_RESEARCH_NAMES[family][slot - 1], baseDescription(family, slot)];
  }
  if (node.kind === "pair_research") {
    const match = /^PAIR-([TBMNAD]{2})-(S[124])$/.exec(node.id);
    if (!match) throw new Error(`Invalid pair research id ${node.id}`);
    const code = match[1];
    const stage = match[2];
    const characterName = CHARACTER_NAMES[`CHAR-PAIR-${code}`];
    const stageNames = { S1: "Base Affinity", S2: "Enhanced Synergy", S4: "Legacy Trait Protocol" };
    const descriptions = {
      S1: `Establishes a base battlefield affinity link between the ${node.familyIds[0]} and ${node.familyIds[1]} lineages.`,
      S2: `Strengthens the ${characterName} route's synergy resonance and prepares it for physical fusion.`,
      S4: `Unlocks the ${characterName} legacy-trait research protocol for pre-mission equipment.`
    };
    return [`${characterName} | ${stageNames[stage]}`, descriptions[stage]];
  }
  if (node.kind === "triple_research") {
    const match = /^TRIPLE-([TBMNAD]{3})-(ROLE|RULE|APEX)$/.exec(node.id);
    if (!match) throw new Error(`Invalid triple research id ${node.id}`);
    const code = match[1];
    const stage = match[2];
    const characterName = CHARACTER_NAMES[`CHAR-TRIPLE-${code}`];
    const stageNames = { ROLE: "Battlefield Role", RULE: "Exclusive Rule", APEX: "Apex Link" };
    const descriptions = {
      ROLE: `Defines the ${characterName}'s core battlefield position and formation role.`,
      RULE: `Grants the ${characterName} an exclusive combat rule and a formation-interaction exception.`,
      APEX: `Links the ${characterName} to an Apex endgame-route qualification node.`
    };
    return [`${characterName} | ${stageNames[stage]}`, descriptions[stage]];
  }
  if (node.kind === "apex_research") {
    const match = /^APEX-(MEMORY|STERILE|SILENT|PRIME)-(GATE|PROTOCOL)$/.exec(node.id);
    if (!match) throw new Error(`Invalid Apex research id ${node.id}`);
    const code = match[1];
    const stage = match[2];
    const characterName = code === "PRIME" ? CHARACTER_NAMES["CHAR-PRIME"] : CHARACTER_NAMES[`CHAR-APEX-${code}`];
    const stageName = stage === "GATE" ? "Endgame Gate" : "Endgame Protocol";
    const description = stage === "PROTOCOL"
      ? `${characterName}'s endgame research protocol, equipped before a mission and consuming Apex bandwidth.`
      : code === "PRIME"
        ? "The IMMUNE PRIME endgame gate, confirming that the six lineages and triple-fusion achievements are ready."
        : `${characterName}'s endgame gate, requiring its Apex identity and triple-fusion link.`;
    return [`${characterName} | ${stageName}`, description];
  }
  throw new Error(`No English translation rule for ${node.id} (${node.kind})`);
}

function csvCell(value) {
  const text = String(value).replaceAll("\r\n", "\n").replaceAll("\r", "\n");
  return /[",\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

export function buildCatalogLocalization(catalog) {
  if (!Array.isArray(catalog.nodes) || catalog.nodes.length !== 200) {
    throw new Error(`Expected exactly 200 catalog nodes, got ${catalog.nodes?.length ?? 0}`);
  }
  const rows = [];
  const seen = new Set();
  for (const node of catalog.nodes) {
    const [englishName, englishDescription] = generatedTranslation(node);
    for (const [field, zh, en] of [
      ["name", node.name, englishName],
      ["description", node.description, englishDescription]
    ]) {
      const key = researchKey(node.id, field);
      if (seen.has(key)) throw new Error(`Duplicate translation key ${key}`);
      if (!String(zh).trim() || !String(en).trim()) throw new Error(`Blank ${field} translation for ${node.id}`);
      if (/[\u3400-\u9fff]/u.test(en)) throw new Error(`English ${field} still contains Han text for ${node.id}: ${en}`);
      seen.add(key);
      rows.push([key, zh, en]);
    }
  }
  for (const row of catalog.campaignLevels ?? []) {
    const [id, zh] = row;
    const key = `RESEARCH_CAMPAIGN_${id}_NAME`;
    const en = CAMPAIGN_NAMES[id];
    if (!en) throw new Error(`Missing campaign translation for ${id}`);
    if (seen.has(key)) throw new Error(`Duplicate translation key ${key}`);
    seen.add(key);
    rows.push([key, zh, en]);
  }
  if (rows.length !== 406) throw new Error(`Expected 406 localization rows, got ${rows.length}`);
  return `keys,zh_HK,en\n${rows.map((row) => row.map(csvCell).join(",")).join("\n")}\n`;
}

async function main() {
  const catalog = JSON.parse(await readFile(CATALOG_PATH, "utf8"));
  const generated = buildCatalogLocalization(catalog);
  const check = process.argv.includes("--check");
  if (check) {
    let current = "";
    try {
      current = await readFile(OUTPUT_PATH, "utf8");
    } catch {
      throw new Error(`Generated localization is missing: ${OUTPUT_PATH}`);
    }
    if (current !== generated) {
      throw new Error("research_catalog.csv is stale; run node tools/generate_catalog_localization.mjs");
    }
  } else {
    await writeFile(OUTPUT_PATH, generated, "utf8");
  }
  console.log(`CATALOG_LOCALIZATION_OK nodes=${catalog.nodes.length} rows=406 mode=${check ? "check" : "write"}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
