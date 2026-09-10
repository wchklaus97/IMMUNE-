#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const HUMAN_PLAYTEST_FAMILIES = ["T", "B", "M", "N", "A", "D"];
export const HUMAN_PLAYTEST_RATING_KEYS = [
  "controls",
  "combat_readability",
  "family_role_clarity",
  "jelly_visual_clarity",
  "game_feel",
];
const FORBIDDEN_PII_KEYS = new Set([
  "accountname",
  "address",
  "contact",
  "contactdetails",
  "dateofbirth",
  "dob",
  "email",
  "emailaddress",
  "fullname",
  "firstname",
  "ipaddress",
  "lastname",
  "legalname",
  "name",
  "phone",
  "phonenumber",
  "postaladdress",
  "socialhandle",
  "username",
]);
const INPUTS = new Set(["keyboard-mouse", "controller", "touch"]);
const LOCALES = new Set(["zh_HK", "en"]);
const COMPLETIONS = new Set(["victory", "defeat", "abandoned", "not_started"]);

function isRecord(value) {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
}

function textPresent(value) {
  if (typeof value !== "string" || value.trim().length === 0) return false;
  return !/^(?:placeholder|tbd|todo|to[_ -]?fill)$/iu.test(value.trim());
}

function scanPiiKeys(value, path, errors) {
  if (typeof value === "string") {
    if (/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/iu.test(value)) {
      errors.push(`${path}: personally identifying value is forbidden`);
    }
    return;
  }
  if (Array.isArray(value)) {
    value.forEach((entry, index) => scanPiiKeys(entry, `${path}[${index}]`, errors));
    return;
  }
  if (!isRecord(value)) return;
  for (const [key, entry] of Object.entries(value)) {
    const normalizedKey = key.toLowerCase().replace(/[^a-z0-9]/gu, "");
    if (FORBIDDEN_PII_KEYS.has(normalizedKey)) errors.push(`${path}.${key}: personally identifying fields are forbidden`);
    scanPiiKeys(entry, `${path}.${key}`, errors);
  }
}

function requireText(errors, value, label, allowIncomplete) {
  if (!allowIncomplete && !textPresent(value)) errors.push(`${label}: expected non-empty text`);
  if (allowIncomplete && typeof value !== "string") errors.push(`${label}: expected text`);
}

function validateRatings(errors, ratings, label, allowIncomplete) {
  if (!isRecord(ratings)) {
    errors.push(`${label}: expected an object`);
    return;
  }
  for (const key of HUMAN_PLAYTEST_RATING_KEYS) {
    const value = ratings[key];
    const minimum = allowIncomplete ? 0 : 1;
    if (!Number.isInteger(value) || value < minimum || value > 5) {
      errors.push(`${label}.${key}: expected integer ${minimum}..5`);
    }
  }
}

export function validateHumanPlaytest(report, { allowIncomplete = false } = {}) {
  const errors = [];
  if (!isRecord(report)) throw new Error("HUMAN_PLAYTEST_FAILED\n- report: expected an object");
  scanPiiKeys(report, "report", errors);
  if (report.schema_version !== 1) errors.push("schema_version: expected 1");
  if (report.privacy !== "anonymous-local-only") errors.push("privacy: expected anonymous-local-only");
  if (allowIncomplete) {
    if (report.status !== "template") errors.push("status: incomplete records must be template");
  } else if (report.status !== "complete") {
    errors.push("status: completed records must be complete");
  }

  if (!isRecord(report.build)) {
    errors.push("build: expected an object");
  } else {
    if (typeof report.build.version !== "string" || !/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/u.test(report.build.version)) {
      errors.push("build.version: expected SemVer");
    }
    if (!allowIncomplete && (typeof report.build.commit !== "string" || !/^[0-9a-f]{7,40}$/u.test(report.build.commit))) {
      errors.push("build.commit: expected a 7..40 character lowercase Git commit, not a placeholder");
    }
    if (allowIncomplete && typeof report.build.commit !== "string") errors.push("build.commit: expected text");
  }

  const tester = report.tester;
  if (!isRecord(tester)) {
    errors.push("tester: expected an object");
  } else {
    for (const key of ["platform", "device", "gpu"]) {
      requireText(errors, tester[key], `tester.${key}`, allowIncomplete);
    }
    if (allowIncomplete) {
      if (typeof tester.participant_code !== "string") errors.push("tester.participant_code: expected text");
    } else if (typeof tester.participant_code !== "string" || !/^tester-[a-z0-9]{2,16}$/u.test(tester.participant_code)) {
      errors.push("tester.participant_code: expected anonymous tester- code");
    }
    if (!allowIncomplete && tester.age_18_or_over !== true) errors.push("tester.age_18_or_over: explicit true is required");
    if (allowIncomplete && ![true, false, null].includes(tester.age_18_or_over)) errors.push("tester.age_18_or_over: expected boolean or null");
    if (!allowIncomplete && !INPUTS.has(tester.input)) errors.push("tester.input: expected keyboard-mouse, controller, or touch");
    if (allowIncomplete && typeof tester.input !== "string") errors.push("tester.input: expected text");
    if (!allowIncomplete && !LOCALES.has(tester.locale)) errors.push("tester.locale: expected zh_HK or en");
    if (allowIncomplete && typeof tester.locale !== "string") errors.push("tester.locale: expected text");
  }

  if (!Array.isArray(report.sessions)) {
    errors.push("sessions: expected an array");
  } else {
    const seen = new Set();
    for (const [index, session] of report.sessions.entries()) {
      const label = `sessions[${index}]`;
      if (!isRecord(session)) {
        errors.push(`${label}: expected an object`);
        continue;
      }
      if (!HUMAN_PLAYTEST_FAMILIES.includes(session.family)) errors.push(`${label}.family: unknown ${JSON.stringify(session.family)}`);
      if (seen.has(session.family)) errors.push(`${label}.family: duplicate ${session.family}`);
      seen.add(session.family);
      if (session.mission !== "MISSION-01") {
        errors.push(`${label}.mission: expected shared MISSION-01 comparison`);
      }
      if (!COMPLETIONS.has(session.completion)) errors.push(`${label}.completion: invalid value`);
      if (!allowIncomplete && session.completion === "not_started") errors.push(`${label}.completion: session was not played`);
      if (typeof session.minutes !== "number" || session.minutes < (allowIncomplete ? 0 : 0.1)) {
        errors.push(`${label}.minutes: expected ${allowIncomplete ? "a non-negative" : "a positive"} number`);
      }
      if (typeof session.duty_switch_used !== "boolean") errors.push(`${label}.duty_switch_used: expected boolean`);
      validateRatings(errors, session.ratings, `${label}.ratings`, allowIncomplete);
      for (const key of ["strongest_moment", "biggest_confusion", "visual_notes", "control_notes"]) {
        requireText(errors, session[key], `${label}.${key}`, allowIncomplete);
      }
      if (!Array.isArray(session.bugs)) {
        errors.push(`${label}.bugs: expected an array`);
      } else {
        for (const [bugIndex, bug] of session.bugs.entries()) {
          if (allowIncomplete ? typeof bug !== "string" : !textPresent(bug)) {
            errors.push(`${label}.bugs[${bugIndex}]: expected a concise non-placeholder string`);
          }
        }
      }
    }
    for (const family of HUMAN_PLAYTEST_FAMILIES) {
      if (!seen.has(family)) errors.push(`sessions: missing family ${family}`);
    }
    if (report.sessions.length !== HUMAN_PLAYTEST_FAMILIES.length) errors.push(`sessions: expected exactly ${HUMAN_PLAYTEST_FAMILIES.length} family sessions`);
  }

  const summary = report.summary;
  if (!isRecord(summary)) {
    errors.push("summary: expected an object");
  } else {
    for (const key of ["most_distinct_family", "least_distinct_family"]) {
      if (!allowIncomplete && !HUMAN_PLAYTEST_FAMILIES.includes(summary[key])) errors.push(`summary.${key}: expected a family ID`);
      if (allowIncomplete && typeof summary[key] !== "string") errors.push(`summary.${key}: expected text`);
    }
    const replayMinimum = allowIncomplete ? 0 : 1;
    if (!Number.isInteger(summary.replay_intent_1_to_5) || summary.replay_intent_1_to_5 < replayMinimum || summary.replay_intent_1_to_5 > 5) {
      errors.push(`summary.replay_intent_1_to_5: expected integer ${replayMinimum}..5`);
    }
    requireText(errors, summary.top_priority_change, "summary.top_priority_change", allowIncomplete);
  }

  if (errors.length) throw new Error(`HUMAN_PLAYTEST_FAILED\n- ${errors.join("\n- ")}`);
  return { status: report.status, families: HUMAN_PLAYTEST_FAMILIES.length, complete: !allowIncomplete };
}

async function main() {
  const args = process.argv.slice(2);
  const allowIncomplete = args.includes("--allow-incomplete");
  const file = args.find((value) => !value.startsWith("--"));
  if (!file) throw new Error("Usage: node tools/validate_human_playtest.mjs <report.json> [--allow-incomplete]");
  const report = JSON.parse(await readFile(resolve(file), "utf8"));
  const result = validateHumanPlaytest(report, { allowIncomplete });
  console.log(`HUMAN_PLAYTEST_OK status=${result.status} families=${result.families} complete=${result.complete}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
