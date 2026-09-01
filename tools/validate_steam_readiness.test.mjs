import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
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
  const paths = [
    ".godot/uid_cache.bin",
    ".godot/imported/CHAR-BASE-T-tripo-5k.glb-example.scn",
  ];
  for (const version of [2, 3, 4]) {
    const pck = makePck(paths, "CHAR-BASE-M-meshy-t2 CHAR-BASE-T-fix.glb", version);
    assert.deepEqual(parsePckResourcePaths(pck), paths);
    assert.deepEqual(validatePckResourcePolicyBuffer(pck), { files: 2 });
  }
});

test("PCK policy rejects an excluded directory entry and a missing shipping entry", () => {
  const leaked = makePck([
    ".godot/imported/CHAR-BASE-T-tripo-5k.glb-example.scn",
    ".godot/imported/CHAR-BASE-M-meshy-t2.glb-example.scn",
  ]);
  assert.throws(() => validatePckResourcePolicyBuffer(leaked), /Excluded source resource leaked/u);
  assert.throws(
    () => validatePckResourcePolicyBuffer(makePck(["project.binary"])),
    /Shipping T resource is missing/u,
  );
});

test("PCK parser fails closed on encrypted, truncated, and out-of-bounds packs", () => {
  const encrypted = makePck([".godot/imported/CHAR-BASE-T-tripo-5k.glb-example.scn"]);
  encrypted.writeUInt32LE(3, 20);
  assert.throws(() => parsePckResourcePaths(encrypted), /encrypted directories/u);

  const truncated = makePck([".godot/imported/CHAR-BASE-T-tripo-5k.glb-example.scn"]);
  assert.throws(() => parsePckResourcePaths(truncated.subarray(0, 12)), /file bounds/u);

  const invalidPayload = makePck([".godot/imported/CHAR-BASE-T-tripo-5k.glb-example.scn"]);
  const directoryOffset = Number(invalidPayload.readBigUInt64LE(32));
  const pathLength = invalidPayload.readUInt32LE(directoryOffset + 4);
  const sizeOffset = directoryOffset + 4 + 4 + pathLength + 8;
  invalidPayload.writeBigUInt64LE(BigInt(invalidPayload.length), sizeOffset);
  assert.throws(() => parsePckResourcePaths(invalidPayload), /file payload 0 exceeds file bounds/u);
});

test("passes the repository-controlled Steam readiness preflight", async () => {
  const report = await validateSteamReadiness({ root: path.resolve(".") });
  assert.equal(report.status, "repository-ready-publisher-gates-open");
  assert.equal(report.version, "0.4.0");
  assert.equal(report.screenshots, 6);
  assert.equal(report.rights_hashes_verified, 13);
  assert.ok(report.external_gates.length >= 6);
});

test("fails closed on the intentionally incomplete publisher example", async () => {
  const input = JSON.parse(await readFile("steam/publisher-inputs.example.json", "utf8"));
  assert.throws(() => validatePublisherInputs(input), /PUBLISHER_INPUTS_INCOMPLETE/u);
});

test("distinguishes complete release evidence from the final owner authorization", async () => {
  const input = {
    schema_version: 1,
    release_track: "steam_demo",
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
      tripo_task_and_terms_attached: true,
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
      tripo_receipt_and_terms: "records/tripo.pdf",
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
  };
  const missingAttestation = structuredClone(input);
  delete missingAttestation.owner_attestations.steamworks_configuration_verified;
  assert.throws(() => validatePublisherInputs(missingAttestation), /steamworks_configuration_verified/u);
  const invalidEmail = structuredClone(input);
  invalidEmail.publisher.support_email = "not-an-email";
  assert.throws(() => validatePublisherInputs(invalidEmail), /support_email/u);
  const result = validatePublisherInputs(input);
  assert.equal(result.releaseTrack, "steam_demo");
  assert.equal(result.publicReleaseAuthorized, false);
  assert.equal(input.owner_attestations.public_release_authorized, false);
  const pending = await validateSteamReadiness({ root: path.resolve("."), publisherInputs: input });
  assert.equal(pending.status, "release-evidence-complete-owner-authorization-pending");
  assert.deepEqual(pending.external_gates, ["owner public release authorization"]);
  input.owner_attestations.public_release_authorized = true;
  const authorized = await validateSteamReadiness({ root: path.resolve("."), publisherInputs: input });
  assert.equal(authorized.status, "release-evidence-complete-owner-authorized");
  assert.deepEqual(authorized.external_gates, []);
});
