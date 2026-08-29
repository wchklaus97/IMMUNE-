import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

import { aggregateHumanPlaytests } from "./aggregate_human_playtests.mjs";

const FAMILIES = ["T", "B", "M", "N", "A", "D"];
const BUILD = { version: "0.4.0", commit: "5021665c73862f9aa8a2e7adf514c86841f4c4e5" };
const execFileAsync = promisify(execFile);

function completeReport(participantCode, rating, overrides = {}) {
  return {
    schema_version: 1,
    status: "complete",
    privacy: "anonymous-local-only",
    build: { ...BUILD },
    tester: {
      participant_code: participantCode,
      age_18_or_over: true,
      platform: "Windows 11",
      device: "Anonymous test machine",
      gpu: "Integrated GPU",
      input: "keyboard-mouse",
      locale: "en",
    },
    sessions: FAMILIES.map((family, index) => ({
      family,
      mission: "MISSION-01",
      completion: index === 5 ? "defeat" : "victory",
      minutes: 6 + index,
      duty_switch_used: index % 2 === 0,
      ratings: {
        controls: rating,
        combat_readability: rating,
        family_role_clarity: rating,
        jelly_visual_clarity: rating,
        game_feel: rating,
      },
      strongest_moment: `${family} role became clear during the cleanse phase.`,
      biggest_confusion: "The first duty prompt took a moment to notice.",
      visual_notes: "The jelly silhouette stayed readable against the arena.",
      control_notes: "Movement and duty switching responded consistently.",
      bugs: index === 0 ? ["Prompt focus was faint after returning from pause."] : [],
    })),
    summary: {
      most_distinct_family: "A",
      least_distinct_family: "B",
      replay_intent_1_to_5: rating,
      top_priority_change: "Make the opening duty prompt more prominent.",
    },
    ...overrides,
  };
}

test("aggregates three anonymous same-build reports without leaking participant codes", () => {
  const result = aggregateHumanPlaytests([
    completeReport("tester-01", 3),
    completeReport("tester-02", 4),
    completeReport("tester-03", 5),
  ], { minimumParticipants: 3 });

  assert.equal(result.status, "minimum-sample-reached");
  assert.equal(result.sample.participants, 3);
  assert.equal(result.sample.contract_met, true);
  assert.equal(result.families.length, 6);
  assert.equal(result.families[0].ratings.controls.mean, 4);
  assert.equal(result.families[0].outcomes.victory, 3);
  assert.equal(result.families[5].outcomes.defeat, 3);
  assert.equal(result.cross_family.replay_intent.mean, 4);
  assert.equal(result.cross_family.most_distinct_votes.A, 3);
  assert.doesNotMatch(JSON.stringify(result), /tester-0[123]/u);
  assert.doesNotMatch(JSON.stringify(result), /top_priority_change|strongest_moment/u);
});

test("marks a valid but too-small collection as provisional", () => {
  const result = aggregateHumanPlaytests([completeReport("tester-01", 4)], { minimumParticipants: 3 });
  assert.equal(result.status, "insufficient-sample");
  assert.equal(result.sample.contract_met, false);
  assert.equal(result.sample.remaining, 2);
});

test("rejects duplicate participants and mixed build provenance", () => {
  assert.throws(() => aggregateHumanPlaytests([
    completeReport("tester-01", 4),
    completeReport("tester-01", 5),
  ]), /duplicate participant/u);

  const mixed = completeReport("tester-02", 4);
  mixed.build.commit = "228a947000000000000000000000000000000000";
  assert.throws(() => aggregateHumanPlaytests([
    completeReport("tester-01", 4),
    mixed,
  ]), /mixed build/u);
});

test("keeps the checked-in campaign plan aligned with the runtime contract", async () => {
  const plan = JSON.parse(await readFile(new URL("../docs/playtesting/campaign-plan.json", import.meta.url), "utf8"));
  assert.equal(plan.schema_version, 1);
  assert.equal(plan.mission, "MISSION-01");
  assert.deepEqual(plan.families, FAMILIES);
  assert.equal(plan.minimum_participants, 3);
  assert.ok(plan.recommended_participants >= plan.minimum_participants);
  assert.equal(plan.session_design.family_order, "deterministic-cyclic-rotation");
  assert.ok(plan.required_report_contracts.includes("same-build-version-and-commit"));
  assert.ok(plan.required_report_contracts.includes("no-identifying-fields-or-email-values"));
  assert.ok(plan.distribution_contracts.includes("complete-four-platform-artifact-allowlist"));
  assert.ok(plan.distribution_contracts.includes("no-unchecksummed-distribution-files"));
});

test("CLI accepts a positional completed report and writes a provisional aggregate", async (context) => {
  const directory = await mkdtemp(join(tmpdir(), "immune-human-aggregate-"));
  context.after(() => rm(directory, { recursive: true, force: true }));
  const input = join(directory, "tester-01.json");
  const output = join(directory, "aggregate.json");
  await writeFile(input, `${JSON.stringify(completeReport("tester-01", 4), null, 2)}\n`);

  const script = fileURLToPath(new URL("./aggregate_human_playtests.mjs", import.meta.url));
  const result = await execFileAsync(process.execPath, [script, input, `--out=${output}`, "--minimum-participants=3"]);
  assert.match(result.stdout, /HUMAN_PLAYTEST_AGGREGATE_OK status=insufficient-sample/u);
  const aggregate = JSON.parse(await readFile(output, "utf8"));
  assert.equal(aggregate.sample.participants, 1);
  assert.equal(aggregate.sample.remaining, 2);
  assert.doesNotMatch(JSON.stringify(aggregate), /tester-01/u);

  const requiredOutput = join(directory, "aggregate-required.json");
  await assert.rejects(
    execFileAsync(process.execPath, [script, input, `--out=${requiredOutput}`, "--minimum-participants=3", "--require-minimum"]),
    (error) => error.code === 2,
  );
  const requiredAggregate = JSON.parse(await readFile(requiredOutput, "utf8"));
  assert.equal(requiredAggregate.status, "insufficient-sample");
});
