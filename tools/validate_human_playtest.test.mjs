import assert from "node:assert/strict";
import test from "node:test";

import { validateHumanPlaytest } from "./validate_human_playtest.mjs";

const FAMILIES = ["T", "B", "M", "N", "A", "D"];
const RATINGS = {
  controls: 4,
  combat_readability: 4,
  family_role_clarity: 4,
  jelly_visual_clarity: 4,
  game_feel: 4,
};

function report(status = "complete") {
  const complete = status === "complete";
  return {
    schema_version: 1,
    status,
    privacy: "anonymous-local-only",
    build: {
      version: "0.4.0",
      commit: complete ? "a7db3bdda42db26cb4ce74a3bb94debe6311dee0" : "TO_FILL",
    },
    tester: {
      participant_code: complete ? "tester-01" : "",
      age_18_or_over: complete ? true : null,
      platform: complete ? "Windows 11" : "",
      device: complete ? "Example desktop" : "",
      gpu: complete ? "Example GPU" : "",
      input: complete ? "keyboard-mouse" : "",
      locale: complete ? "en" : "",
    },
    sessions: FAMILIES.map((family) => ({
      family,
      mission: "MISSION-01",
      completion: complete ? "victory" : "not_started",
      minutes: complete ? 8 : 0,
      duty_switch_used: complete,
      ratings: complete ? { ...RATINGS } : Object.fromEntries(Object.keys(RATINGS).map((key) => [key, 0])),
      strongest_moment: complete ? `${family} role became clear during the cleanse phase.` : "",
      biggest_confusion: complete ? "The first duty prompt took a moment to notice." : "",
      visual_notes: complete ? "Jelly silhouette and face stayed readable against the arena." : "",
      control_notes: complete ? "Movement and duty switching responded consistently." : "",
      bugs: [],
    })),
    summary: {
      most_distinct_family: complete ? "A" : "",
      least_distinct_family: complete ? "B" : "",
      replay_intent_1_to_5: complete ? 4 : 0,
      top_priority_change: complete ? "Make the opening duty prompt more prominent." : "",
    },
  };
}

test("accepts the checked-in six-family template shape", () => {
  assert.doesNotThrow(() => validateHumanPlaytest(report("template"), { allowIncomplete: true }));
});

test("accepts a complete anonymous six-family report", () => {
  assert.doesNotThrow(() => validateHumanPlaytest(report("complete")));
});

test("rejects missing families, placeholders, and PII fields", () => {
  const invalid = report("complete");
  invalid.sessions.pop();
  invalid.build.commit = "TO_FILL";
  invalid.tester.emailAddress = "do-not-store@example.com";
  invalid.summary.top_priority_change = "TBD";
  assert.throws(() => validateHumanPlaytest(invalid), /family D|commit|emailAddress|top_priority_change/u);
});

test("requires anonymous participant codes and the shared MISSION-01 comparison", () => {
  const invalid = report("complete");
  invalid.tester.participant_code = "Klaus Example";
  invalid.sessions[0].mission = "MISSION-02";
  assert.throws(() => validateHumanPlaytest(invalid), /participant_code|MISSION-01/u);
});

test("rejects identifying values hidden inside free-text notes", () => {
  const invalid = report("complete");
  invalid.sessions[0].bugs.push("Contact me at tester@example.com for a recording.");
  assert.throws(() => validateHumanPlaytest(invalid), /personally identifying value|bugs\[0\]/u);
});

test("rejects account and contact identity fields even when their names are reformatted", () => {
  const invalid = report("complete");
  invalid.tester.account_name = "sample-account";
  invalid.tester.contactDetails = "private contact details";
  assert.throws(() => validateHumanPlaytest(invalid), /account_name|contactDetails/u);
});
