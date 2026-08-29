#!/usr/bin/env node

import { mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import { dirname, extname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import {
  HUMAN_PLAYTEST_FAMILIES,
  HUMAN_PLAYTEST_RATING_KEYS,
  validateHumanPlaytest,
} from "./validate_human_playtest.mjs";

const ROOT = resolve(fileURLToPath(new URL(".", import.meta.url)), "..");
const DEFAULT_OUTPUT = resolve(ROOT, "outputs/playtests/human-playtest-aggregate.json");

function rounded(value, digits = 3) {
  const scale = 10 ** digits;
  return Math.round(value * scale) / scale;
}

function mean(values) {
  return values.length ? rounded(values.reduce((sum, value) => sum + value, 0) / values.length) : 0;
}

function median(values) {
  if (!values.length) return 0;
  const sorted = [...values].sort((left, right) => left - right);
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[middle] : rounded((sorted[middle - 1] + sorted[middle]) / 2);
}

function counts(values, keys) {
  return Object.fromEntries(keys.map((key) => [key, values.filter((value) => value === key).length]));
}

function ratingSummary(sessions, key) {
  const values = sessions.map((session) => session.ratings[key]);
  return { mean: mean(values), median: median(values), minimum: Math.min(...values), maximum: Math.max(...values) };
}

export function aggregateHumanPlaytests(reports, { minimumParticipants = 3, generatedAt = new Date().toISOString() } = {}) {
  if (!Array.isArray(reports) || reports.length === 0) throw new Error("HUMAN_PLAYTEST_AGGREGATE_FAILED\n- reports: expected at least one report");
  if (!Number.isInteger(minimumParticipants) || minimumParticipants < 1) throw new Error("HUMAN_PLAYTEST_AGGREGATE_FAILED\n- minimumParticipants: expected a positive integer");

  reports.forEach((report, index) => {
    try {
      validateHumanPlaytest(report);
    } catch (error) {
      throw new Error(`HUMAN_PLAYTEST_AGGREGATE_FAILED\n- reports[${index}]: ${error instanceof Error ? error.message : String(error)}`);
    }
  });

  const participantCodes = reports.map((report) => report.tester.participant_code);
  if (new Set(participantCodes).size !== participantCodes.length) {
    throw new Error("HUMAN_PLAYTEST_AGGREGATE_FAILED\n- duplicate participant code");
  }
  const buildIdentities = new Set(reports.map((report) => `${report.build.version}@${report.build.commit}`));
  if (buildIdentities.size !== 1) throw new Error("HUMAN_PLAYTEST_AGGREGATE_FAILED\n- mixed build provenance");

  const contractMet = reports.length >= minimumParticipants;
  const familySummaries = HUMAN_PLAYTEST_FAMILIES.map((family) => {
    const sessions = reports.map((report) => report.sessions.find((session) => session.family === family));
    return {
      family,
      sessions: sessions.length,
      outcomes: counts(sessions.map((session) => session.completion), ["victory", "defeat", "abandoned"]),
      minutes: {
        mean: mean(sessions.map((session) => session.minutes)),
        median: median(sessions.map((session) => session.minutes)),
      },
      duty_switch_usage_rate: mean(sessions.map((session) => session.duty_switch_used ? 1 : 0)),
      ratings: Object.fromEntries(HUMAN_PLAYTEST_RATING_KEYS.map((key) => [key, ratingSummary(sessions, key)])),
      bug_reports: sessions.reduce((sum, session) => sum + session.bugs.length, 0),
    };
  });
  const build = reports[0].build;

  return {
    schema_version: 1,
    status: contractMet ? "minimum-sample-reached" : "insufficient-sample",
    evidence_class: "human-self-report-not-automated-telemetry",
    privacy: "anonymous-aggregate-no-participant-codes-or-free-text",
    generated_at: generatedAt,
    build: { ...build },
    mission: "MISSION-01",
    sample: {
      participants: reports.length,
      minimum_participants: minimumParticipants,
      remaining: Math.max(0, minimumParticipants - reports.length),
      contract_met: contractMet,
      input: counts(reports.map((report) => report.tester.input), ["keyboard-mouse", "controller", "touch"]),
      locale: counts(reports.map((report) => report.tester.locale), ["zh_HK", "en"]),
    },
    families: familySummaries,
    cross_family: {
      replay_intent: {
        mean: mean(reports.map((report) => report.summary.replay_intent_1_to_5)),
        median: median(reports.map((report) => report.summary.replay_intent_1_to_5)),
      },
      most_distinct_votes: counts(reports.map((report) => report.summary.most_distinct_family), HUMAN_PLAYTEST_FAMILIES),
      least_distinct_votes: counts(reports.map((report) => report.summary.least_distinct_family), HUMAN_PLAYTEST_FAMILIES),
      bug_reports: familySummaries.reduce((sum, family) => sum + family.bug_reports, 0),
    },
    claim_boundary: "Numeric anonymous aggregate only. It does not prove accessibility, fun, or hardware performance without facilitator review of the local raw reports.",
  };
}

function argument(name, fallback = "") {
  const prefix = `--${name}=`;
  const match = process.argv.slice(2).find((entry) => entry.startsWith(prefix));
  return match ? match.slice(prefix.length) : fallback;
}

async function inputPaths(outputPath) {
  const positional = process.argv.slice(2).filter((entry) => !entry.startsWith("--"));
  const directory = argument("dir");
  if (!directory) return positional.map((entry) => resolve(entry));
  const absoluteDirectory = resolve(directory);
  const entries = await readdir(absoluteDirectory, { withFileTypes: true });
  const directoryFiles = entries
    .filter((entry) => entry.isFile() && extname(entry.name).toLowerCase() === ".json")
    .map((entry) => resolve(absoluteDirectory, entry.name))
    .filter((entry) => entry !== outputPath);
  return [...positional.map((entry) => resolve(entry)), ...directoryFiles].sort();
}

async function main() {
  const outputPath = resolve(argument("out", DEFAULT_OUTPUT));
  const minimumParticipants = Number.parseInt(argument("minimum-participants", "3"), 10);
  const paths = await inputPaths(outputPath);
  if (!paths.length) throw new Error("Usage: node tools/aggregate_human_playtests.mjs <report.json...> [--dir=reports] [--out=aggregate.json] [--minimum-participants=3] [--require-minimum]");
  const reports = await Promise.all(paths.map(async (path) => JSON.parse(await readFile(path, "utf8"))));
  const aggregate = aggregateHumanPlaytests(reports, { minimumParticipants });
  await mkdir(dirname(outputPath), { recursive: true });
  await writeFile(outputPath, `${JSON.stringify(aggregate, null, 2)}\n`);
  console.log(`HUMAN_PLAYTEST_AGGREGATE_OK status=${aggregate.status} participants=${aggregate.sample.participants} remaining=${aggregate.sample.remaining} out=${outputPath}`);
  if (process.argv.includes("--require-minimum") && !aggregate.sample.contract_met) process.exitCode = 2;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
