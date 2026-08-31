import assert from "node:assert/strict";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  createNativeSmokeEvidence,
  nativeEvidenceArguments,
} from "./create_native_smoke_evidence.mjs";

const COMMIT = "81a3cbe1a5ba60227bbe0d8c873c55d07871b729";

test("native-evidence CLI rejects unknown, empty, and duplicate inputs", () => {
  assert.throws(() => nativeEvidenceArguments(["--token=secret"]), /Unknown/u);
  assert.throws(() => nativeEvidenceArguments(["--out="]), /requires a value/u);
  assert.throws(
    () => nativeEvidenceArguments(["--platform=Linux", "--platform=Windows"]),
    /Duplicate/u,
  );
});

test("creates hash-bound Linux native smoke evidence", async () => {
  const root = await mkdtemp(join(tmpdir(), "immune-native-evidence-"));
  const log = join(root, "smoke.log");
  const artifact = join(root, "IMMUNE-linux.x86_64");
  const pck = join(root, "IMMUNE-linux.pck");
  const out = join(root, "evidence/linux.json");
  await Promise.all([
    writeFile(log, "Godot Engine\nRELEASE_SMOKE_OK platform=Linux nodes=200\n"),
    writeFile(artifact, "elf-fixture"),
    writeFile(pck, "pck-fixture"),
  ]);
  const report = await createNativeSmokeEvidence({
    platform: "Linux",
    log,
    artifact,
    pck,
    out,
    commit: COMMIT,
    version: "0.4.0",
    generatedAt: "2026-09-01T00:00:00.000Z",
  });
  assert.equal(report.status, "pass");
  assert.equal(report.artifacts.length, 2);
  assert.ok(report.artifacts.every((entry) => /^[0-9a-f]{64}$/u.test(entry.sha256)));
  assert.deepEqual(JSON.parse(await readFile(out, "utf8")), report);
});

test("rejects a missing marker, engine error, short SHA, and missing PCK", async () => {
  const root = await mkdtemp(join(tmpdir(), "immune-native-evidence-bad-"));
  const log = join(root, "smoke.log");
  const artifact = join(root, "artifact");
  const pck = join(root, "sidecar");
  await Promise.all([writeFile(log, "no marker"), writeFile(artifact, "bin"), writeFile(pck, "pck")]);
  const base = { platform: "Linux", log, artifact, pck, commit: COMMIT, version: "0.4.0" };
  await assert.rejects(createNativeSmokeEvidence({ ...base, out: join(root, "a.json") }), /missing RELEASE_SMOKE_OK/u);
  await writeFile(log, "RELEASE_SMOKE_OK platform=Linux nodes=200\nERROR: broken\n");
  await assert.rejects(createNativeSmokeEvidence({ ...base, out: join(root, "b.json") }), /engine error/u);
  await assert.rejects(createNativeSmokeEvidence({ ...base, out: join(root, "c.json"), commit: "abc" }), /40-character/u);
  await assert.rejects(createNativeSmokeEvidence({ ...base, out: join(root, "d.json"), pck: "" }), /requires a PCK/u);
});
