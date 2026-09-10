import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  PREFERENCE_ORDERS,
  createVisualPreferenceCampaign,
  verifyVisualPreferenceCampaign,
} from "./create_visual_preference_campaign.mjs";

const COMMITS = {
  v5: "1111111111111111111111111111111111111111",
  v6: "2222222222222222222222222222222222222222",
  v7: "3333333333333333333333333333333333333333",
  build: "4444444444444444444444444444444444444444",
};

function fakePng(width, height, marker) {
  const buffer = Buffer.alloc(2048, marker);
  Buffer.from("89504e470d0a1a0a", "hex").copy(buffer, 0);
  buffer.writeUInt32BE(13, 8);
  Buffer.from("IHDR").copy(buffer, 12);
  buffer.writeUInt32BE(width, 16);
  buffer.writeUInt32BE(height, 20);
  return buffer;
}

async function fixture() {
  const root = await mkdtemp(join(tmpdir(), "immune-visual-preference-test-"));
  const paths = {
    reference: join(root, "reference.png"),
    v5: join(root, "v5.png"),
    v6: join(root, "v6.png"),
    v7: join(root, "v7.png"),
    output: join(root, "campaign"),
  };
  await Promise.all([
    writeFile(paths.reference, fakePng(1536, 1024, 1)),
    writeFile(paths.v5, fakePng(6144, 2048, 2)),
    writeFile(paths.v6, fakePng(6144, 2048, 3)),
    writeFile(paths.v7, fakePng(6144, 2048, 4)),
  ]);
  return { root, paths };
}

test("uses all six candidate permutations with balanced positions", () => {
  assert.equal(new Set(PREFERENCE_ORDERS.map((order) => order.join(","))).size, 6);
  for (let position = 0; position < 3; position += 1) {
    const counts = { v5: 0, v6: 0, v7: 0 };
    for (const order of PREFERENCE_ORDERS) counts[order[position]] += 1;
    assert.deepEqual(counts, { v5: 2, v6: 2, v7: 2 });
  }
});

test("creates and verifies a blinded checksum-locked six-person campaign", async () => {
  const { root, paths } = await fixture();
  try {
    const result = await createVisualPreferenceCampaign({
      referencePath: paths.reference,
      sources: {
        v5: { path: paths.v5, commit: COMMITS.v5 },
        v6: { path: paths.v6, commit: COMMITS.v6 },
        v7: { path: paths.v7, commit: COMMITS.v7 },
      },
      buildCommit: COMMITS.build,
      outputRoot: paths.output,
      generatedAt: "2026-09-01T00:00:00.000Z",
    });
    assert.equal(result.participants, 6);
    const verified = await verifyVisualPreferenceCampaign(paths.output);
    assert.equal(verified.participants, 6);
    const participantHtml = await readFile(
      join(paths.output, "participants/tester-01/index.html"),
      "utf8",
    );
    assert.doesNotMatch(participantHtml, /\bV(?:5(?:\.1)?|6|7)\b/u);
    assert.doesNotMatch(participantHtml, /[—–]/u);
    const answerKey = JSON.parse(
      await readFile(join(paths.output, "facilitator/answer-key.json"), "utf8"),
    );
    assert.equal(answerKey.sources.v5.commit, COMMITS.v5);
    assert.equal(answerKey.sources.v6.commit, COMMITS.v6);
    assert.equal(answerKey.sources.v7.commit, COMMITS.v7);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("refuses overwrite and detects checksum tampering", async () => {
  const { root, paths } = await fixture();
  try {
    const options = {
      referencePath: paths.reference,
      sources: {
        v5: { path: paths.v5, commit: COMMITS.v5 },
        v6: { path: paths.v6, commit: COMMITS.v6 },
        v7: { path: paths.v7, commit: COMMITS.v7 },
      },
      buildCommit: COMMITS.build,
      outputRoot: paths.output,
      generatedAt: "2026-09-01T00:00:00.000Z",
    };
    await createVisualPreferenceCampaign(options);
    await assert.rejects(
      () => createVisualPreferenceCampaign(options),
      /refusing to overwrite/u,
    );
    await writeFile(
      join(paths.output, "participants/tester-01/assets/candidate-01.png"),
      fakePng(6144, 2048, 9),
    );
    await assert.rejects(
      () => verifyVisualPreferenceCampaign(paths.output),
      /Checksum mismatch/u,
    );
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
