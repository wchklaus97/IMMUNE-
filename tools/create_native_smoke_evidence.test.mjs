import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  createNativeSmokeEvidence,
  nativeEvidenceArguments,
} from "./create_native_smoke_evidence.mjs";

const COMMIT = "81a3cbe1a5ba60227bbe0d8c873c55d07871b729";

function git(root, ...args) {
  const result = spawnSync("git", ["-C", root, ...args], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout.trim();
}

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
    verifyRepository: false,
  });
  assert.equal(report.status, "pass");
  assert.equal(report.source_repository.head_verified, false);
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
  const base = {
    platform: "Linux",
    log,
    artifact,
    pck,
    commit: COMMIT,
    version: "0.4.0",
    verifyRepository: false,
  };
  await assert.rejects(createNativeSmokeEvidence({ ...base, out: join(root, "a.json") }), /missing RELEASE_SMOKE_OK/u);
  await writeFile(log, "RELEASE_SMOKE_OK platform=Linux nodes=200\nERROR: broken\n");
  await assert.rejects(createNativeSmokeEvidence({ ...base, out: join(root, "b.json") }), /engine error/u);
  await assert.rejects(createNativeSmokeEvidence({ ...base, out: join(root, "c.json"), commit: "abc" }), /40-character/u);
  await assert.rejects(createNativeSmokeEvidence({ ...base, out: join(root, "d.json"), pck: "" }), /requires a PCK/u);
});

test("binds evidence to the real clean repository HEAD", async () => {
  const root = await mkdtemp(join(tmpdir(), "immune-native-evidence-repo-"));
  git(root, "init", "--quiet");
  git(root, "config", "user.name", "IMMUNE Test");
  git(root, "config", "user.email", "test@example.invalid");
  const tracked = join(root, "tracked.txt");
  const log = join(root, "smoke.log");
  const artifact = join(root, "IMMUNE-macOS.zip");
  await Promise.all([
    writeFile(tracked, "clean\n"),
    writeFile(log, "Godot Engine\nRELEASE_SMOKE_OK platform=macOS nodes=200\n"),
    writeFile(artifact, "zip-fixture"),
  ]);
  git(root, "add", "tracked.txt");
  git(root, "commit", "--quiet", "-m", "fixture");
  const head = git(root, "rev-parse", "HEAD");
  const report = await createNativeSmokeEvidence({
    platform: "macOS",
    log,
    artifact,
    out: join(root, "pass.json"),
    commit: head,
    version: "0.4.0",
    repositoryRoot: root,
  });
  assert.deepEqual(report.source_repository, { head_verified: true, tracked_tree_clean: true });

  await assert.rejects(createNativeSmokeEvidence({
    platform: "macOS",
    log,
    artifact,
    out: join(root, "wrong-head.json"),
    commit: COMMIT,
    version: "0.4.0",
    repositoryRoot: root,
  }), /does not match repository HEAD/u);

  await writeFile(tracked, "dirty\n");
  await assert.rejects(createNativeSmokeEvidence({
    platform: "macOS",
    log,
    artifact,
    out: join(root, "dirty.json"),
    commit: head,
    version: "0.4.0",
    repositoryRoot: root,
  }), /tracked tree must be clean/u);
});
