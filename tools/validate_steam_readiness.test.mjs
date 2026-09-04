import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import {
  parsePckResourcePaths,
  readinessArguments,
  validatePckResourcePolicyBuffer,
  validatePublisherInputs,
  validateSteamReadiness,
} from "./validate_steam_readiness.mjs";

function makePck(paths, payload = "", version = 3) {
  const payloadBuffer = Buffer.from(payload);
  const entries = paths.map((path) => {
    const encodedPath = Buffer.from(path);
    const entry = Buffer.alloc(40 + encodedPath.length);
    entry.writeUInt32LE(encodedPath.length, 0);
    encodedPath.copy(entry, 4);
    return entry;
  });
  const fileCount = Buffer.alloc(4);
  fileCount.writeUInt32LE(paths.length, 0);
  const directory = Buffer.concat([fileCount, ...entries]);
  const headerSize = version === 2 ? 96 : 40;
  const header = Buffer.alloc(headerSize);
  header.write("GDPC", 0, "ascii");
  header.writeUInt32LE(version, 4);
  header.writeUInt32LE(4, 8);
  header.writeUInt32LE(6, 12);
  header.writeUInt32LE(1, 16);
  header.writeUInt32LE(2, 20);
  if (version === 2) {
    header.writeBigUInt64LE(BigInt(headerSize + directory.length), 24);
    return Buffer.concat([header, directory, payloadBuffer]);
  }
  header.writeBigUInt64LE(BigInt(headerSize), 24);
  header.writeBigUInt64LE(BigInt(headerSize + payloadBuffer.length), 32);
  return Buffer.concat([header, payloadBuffer, directory]);
}

function authoredPckPaths() {
  return [
    ".godot/uid_cache.bin",
    "characters/authored_jelly_body.gdc",
    "characters/base_b/reference_body.tscn.remap",
    "characters/base_t/reference_body.tscn.remap",
    "characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb",
    ...Array.from({ length: 6 }, (_, index) => (
      `.godot/exported/fixture/export-${String(index + 1).padStart(2, "0")}-reference_body.scn`
    )),
  ];
}

test("readiness CLI rejects unknown, empty, and duplicate inputs", () => {
  assert.deepEqual(readinessArguments(["--artifacts=build/releases"]), { artifacts: "build/releases" });
  assert.throws(() => readinessArguments(["--wat=yes"]), /Unknown/u);
  assert.throws(() => readinessArguments(["--artifacts="]), /requires a value/u);
  assert.throws(
    () => readinessArguments(["--artifacts=one", "--artifacts=two"]),
    /Duplicate/u,
  );
});

test("PCK policy audits resource entries instead of matching UID-cache payload text", () => {
  const paths = authoredPckPaths();
  for (const version of [2, 3, 4]) {
    const pck = makePck(paths, "CHAR-BASE-M-meshy-t2 CHAR-BASE-T-fix.glb", version);
    assert.deepEqual(parsePckResourcePaths(pck), paths);
    assert.deepEqual(validatePckResourcePolicyBuffer(pck), { files: 11 });
  }
});

test("PCK policy rejects an excluded directory entry and a missing shipping entry", () => {
  const leaked = makePck([
    ...authoredPckPaths(),
    ".godot/imported/CHAR-BASE-M-meshy-t2.glb-example.scn",
  ]);
  assert.throws(() => validatePckResourcePolicyBuffer(leaked), /Excluded source resource leaked/u);
  const leakedV84Derivative = makePck([
    ...authoredPckPaths(),
    ".godot/imported/CHAR-BASE-T-v8-4-single-mass-r1.glb-example.scn",
  ]);
  assert.throws(
    () => validatePckResourcePolicyBuffer(leakedV84Derivative),
    /Excluded source resource leaked/u,
  );
  const leakedV85Candidate = makePck([
    ...authoredPckPaths(),
    ".godot/imported/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb-example.scn",
  ]);
  assert.throws(
    () => validatePckResourcePolicyBuffer(leakedV85Candidate),
    /Excluded source resource leaked/u,
  );
  const leakedV86Intermediate = makePck([
    ...authoredPckPaths(),
    "characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-1.glb",
  ]);
  assert.throws(
    () => validatePckResourcePolicyBuffer(leakedV86Intermediate),
    /Excluded source resource leaked/u,
  );
  assert.throws(
    () => validatePckResourcePolicyBuffer(makePck(["project.binary"])),
    /Required authored character resource is missing/u,
  );
  assert.throws(
    () => validatePckResourcePolicyBuffer(makePck([
      "characters/authored_jelly_body.gdc",
      "characters/base_b/reference_body.tscn.remap",
      "characters/base_t/reference_body.tscn.remap",
      "characters/base_t/CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb",
    ])),
    /Required compiled reference bodies are missing/u,
  );
});

test("PCK parser fails closed on encrypted, truncated, and out-of-bounds packs", () => {
  const encrypted = makePck(["characters/authored_jelly_body.gdc"]);
  encrypted.writeUInt32LE(3, 20);
  assert.throws(() => parsePckResourcePaths(encrypted), /encrypted directories/u);

  const truncated = makePck(["characters/authored_jelly_body.gdc"]);
  assert.throws(() => parsePckResourcePaths(truncated.subarray(0, 12)), /file bounds/u);

  const invalidPayload = makePck(["characters/authored_jelly_body.gdc"]);
  const directoryOffset = Number(invalidPayload.readBigUInt64LE(32));
  const pathLength = invalidPayload.readUInt32LE(directoryOffset + 4);
  const sizeOffset = directoryOffset + 4 + 4 + pathLength + 8;
  invalidPayload.writeBigUInt64LE(BigInt(invalidPayload.length), sizeOffset);
  assert.throws(() => parsePckResourcePaths(invalidPayload), /file payload 0 exceeds file bounds/u);
});

test("passes the repository-controlled Steam readiness preflight", async () => {
  const report = await validateSteamReadiness({ root: path.resolve(".") });
  assert.equal(report.status, "repository-ready-publisher-gates-open");
  assert.equal(report.version, "0.5.0-rc.1");
  assert.equal(report.screenshots, 6);
  assert.equal(report.rights_hashes_verified, 22);
  assert.ok(report.external_gates.length >= 6);
});

test("fails closed on the intentionally incomplete publisher example", async () => {
  const input = JSON.parse(await readFile("steam/publisher-inputs.example.json", "utf8"));
  assert.throws(() => validatePublisherInputs(input), /PUBLISHER_INPUTS_INCOMPLETE/u);
});

test("distinguishes complete release evidence from the final owner authorization", async () => {
  const candidateCommit = "81a3cbe1a5ba60227bbe0d8c873c55d07871b729";
  const input = {
    schema_version: 2,
    release_track: "steam_demo",
    candidate: { version: "0.5.0-rc.1", commit: candidateCommit },
    base_game_app_id: "5800000",
    demo_app_id: "5800010",
    depots: { windows: "5800011", linux: "5800012", macos: "5800013" },
    publisher: {
      legal_name: "Example Studio Ltd",
      developer_name: "Example Studio",
      support_email: "support@example.invalid",
      support_url: "https://example.invalid/support",
      privacy_policy_url: "https://example.invalid/privacy",
    },
    owner_attestations: {
      all_shipping_asset_rights_verified: true,
      audio_provenance_attached: true,
      generative_ai_disclosure_approved: true,
      content_survey_completed: true,
      macos_developer_id_signed: true,
      macos_notarization_accepted: true,
      native_windows_smoke_exact_candidate: true,
      native_linux_smoke_exact_candidate: true,
      native_macos_smoke_exact_candidate: true,
      steamworks_configuration_verified: true,
      private_steam_branch_install_tested: true,
      minimum_spec_platforms_tested: true,
      steam_deck_session_tested: true,
      human_playtest_gate_accepted: true,
      store_page_preview_approved: true,
      valve_store_review_approved: true,
      valve_build_review_approved: true,
      public_release_authorized: false,
    },
    evidence: {
      asset_rights_attestation: "records/rights.pdf",
      audio_provenance: "records/audio.zip",
      content_survey_record: "records/content-survey.pdf",
      native_windows_smoke: "records/windows.json",
      native_linux_smoke: "records/linux.json",
      native_macos_smoke: "records/macos.json",
      macos_signing_identity_record: "records/developer-id.txt",
      macos_notarization: "records/notarization.txt",
      steamworks_configuration_record: "records/steamworks-config.pdf",
      steamcmd_preview_log: "records/steamcmd-preview.log",
      private_branch_install_report: "records/private-install.json",
      minimum_spec_platform_report: "records/minimum-spec.json",
      steam_deck_session_report: "records/steam-deck.json",
      human_playtest_aggregate: "records/playtests.json",
      store_page_preview_record: "records/store-preview.pdf",
      valve_store_review_approval: "records/valve-store-approval.txt",
      valve_build_review_approval: "records/valve-build-approval.txt",
    },
    evidence_sha256: {},
  };
  const evidenceRoot = await mkdtemp(path.join(tmpdir(), "immune-publisher-evidence-"));
  const nativePlatforms = {
    native_windows_smoke: "Windows",
    native_linux_smoke: "Linux",
    native_macos_smoke: "macOS",
  };
  for (const key of Object.keys(input.evidence)) {
    const platform = nativePlatforms[key];
    const content = platform
      ? `${JSON.stringify({
        schema_version: 1,
        status: "pass",
        platform,
        build: { version: "0.5.0-rc.1", commit: candidateCommit },
        source_repository: { head_verified: true, tracked_tree_clean: true },
        artifacts: [],
      }, null, 2)}\n`
      : `archived evidence fixture: ${key}\n`;
    const evidencePath = path.join(evidenceRoot, `${key}${platform ? ".json" : ".txt"}`);
    await writeFile(evidencePath, content);
    input.evidence[key] = evidencePath;
    input.evidence_sha256[key] = createHash("sha256").update(content).digest("hex");
  }
  const missingAttestation = structuredClone(input);
  delete missingAttestation.owner_attestations.steamworks_configuration_verified;
  assert.throws(() => validatePublisherInputs(missingAttestation), /steamworks_configuration_verified/u);
  const invalidEmail = structuredClone(input);
  invalidEmail.publisher.support_email = "not-an-email";
  assert.throws(() => validatePublisherInputs(invalidEmail), /support_email/u);
  const relativeEvidence = structuredClone(input);
  relativeEvidence.evidence.asset_rights_attestation = "records/rights.pdf";
  assert.throws(() => validatePublisherInputs(relativeEvidence), /absolute archived-file path/u);
  const result = validatePublisherInputs(input);
  assert.equal(result.releaseTrack, "steam_demo");
  assert.equal(result.publicReleaseAuthorized, false);
  assert.equal(input.owner_attestations.public_release_authorized, false);
  const pending = await validateSteamReadiness({ root: path.resolve("."), publisherInputs: input });
  assert.equal(pending.status, "release-evidence-verified-owner-authorization-pending");
  assert.equal(pending.publisher_evidence_files_verified, 17);
  assert.deepEqual(pending.external_gates, ["owner public release authorization"]);
  input.owner_attestations.public_release_authorized = true;
  const authorized = await validateSteamReadiness({ root: path.resolve("."), publisherInputs: input });
  assert.equal(authorized.status, "release-evidence-verified-owner-authorized");
  assert.deepEqual(authorized.external_gates, []);

  await writeFile(input.evidence.asset_rights_attestation, "tampered\n");
  await assert.rejects(
    validateSteamReadiness({ root: path.resolve("."), publisherInputs: input }),
    /SHA-256 does not match/u,
  );
});
