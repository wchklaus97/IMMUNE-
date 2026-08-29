import assert from "node:assert/strict";
import test from "node:test";

import { createHumanPlaytestKit, familyOrderForParticipant } from "./create_human_playtest_kit.mjs";
import { validateHumanPlaytest } from "./validate_human_playtest.mjs";

test("creates a deterministic counterbalanced offline kit", () => {
  const options = {
    participantCode: "tester-03",
    buildVersion: "0.4.0",
    buildCommit: "5021665c73862f9aa8a2e7adf514c86841f4c4e5",
    generatedAt: "2026-08-29T14:00:00.000Z",
  };
  const first = createHumanPlaytestKit(options);
  const second = createHumanPlaytestKit(options);

  assert.deepEqual(first, second);
  assert.deepEqual(first.manifest.family_order, familyOrderForParticipant("tester-03"));
  assert.deepEqual(first.report.sessions.map((session) => session.family), first.manifest.family_order);
  assert.doesNotThrow(() => validateHumanPlaytest(first.report, { allowIncomplete: true }));
  assert.match(first.html, /No network requests \/ 不會傳送網絡請求/u);
  assert.match(first.html, /Download draft/u);
  assert.match(first.html, /Export completed report/u);
  assert.match(first.html, /rel="icon" href="data:,"/u);
  assert.doesNotMatch(first.html, /https?:\/\//u);
  assert.doesNotMatch(first.html, /[—–]/u);
  const executableScript = [...first.html.matchAll(/<script>([\s\S]*?)<\/script>/gu)].at(-1)?.[1];
  assert.ok(executableScript);
  assert.doesNotThrow(() => new Function(executableScript));
});

test("changes the starting family across participant codes", () => {
  const starts = new Set(Array.from({ length: 12 }, (_, index) => (
    familyOrderForParticipant(`tester-${String(index + 1).padStart(2, "0")}`)[0]
  )));
  assert.equal(starts.size, 6);
});

test("requires an anonymous participant and exact build provenance", () => {
  assert.throws(() => createHumanPlaytestKit({
    participantCode: "Klaus",
    buildVersion: "0.4.0",
    buildCommit: "5021665",
  }), /participant/u);
  assert.throws(() => createHumanPlaytestKit({
    participantCode: "tester-01",
    buildVersion: "0.4.0",
    buildCommit: "TO_FILL",
  }), /commit/u);
});
