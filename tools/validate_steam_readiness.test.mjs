import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";

import {
  readinessArguments,
  validatePublisherInputs,
  validateSteamReadiness,
} from "./validate_steam_readiness.mjs";

test("readiness CLI rejects unknown, empty, and duplicate inputs", () => {
  assert.deepEqual(readinessArguments(["--artifacts=build/releases"]), { artifacts: "build/releases" });
  assert.throws(() => readinessArguments(["--wat=yes"]), /Unknown/u);
  assert.throws(() => readinessArguments(["--artifacts="]), /requires a value/u);
  assert.throws(
    () => readinessArguments(["--artifacts=one", "--artifacts=two"]),
    /Duplicate/u,
  );
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
