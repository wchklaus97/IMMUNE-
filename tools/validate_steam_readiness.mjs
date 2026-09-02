#!/usr/bin/env node

import { createHash } from "node:crypto";
import { lstat, readFile, readdir } from "node:fs/promises";
import { dirname, isAbsolute, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { validateReleaseContract } from "./validate_release_contract.mjs";
import { validateSteamAssets } from "./validate_steam_assets.mjs";
import { validateSteamConfig } from "./prepare_steam_build.mjs";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const REQUIRED_REPOSITORY_FILES = [
  ["steam/THIRD_PARTY_NOTICES.txt", 1_000, "Permission is hereby granted"],
  ["steam/GODOT_COPYRIGHT.txt", 90_000, "Upstream-Name: Godot Engine"],
  ["godot/immune/fonts/OFL.txt", 4_000, "SIL OPEN FONT LICENSE"],
  ["godot/immune/audio/AUDIO_PROVENANCE.md", 1_000, "deterministic integer noise"],
  ["steam/asset-rights-register.md", 2_000, "Commercial readiness remains fail-closed"],
  ["steam/content-survey-draft.md", 1_000, "Pre-generated content"],
  ["steam/privacy-notice-draft.md", 500, "offline single-player demo"],
  ["steam/steamworks-setup.md", 1_000, "separate Steam Demo App"],
  ["steam/publisher-inputs.example.json", 500, "owner_attestations"],
];
const RUNTIME_EXTENSIONS = new Set([".gd", ".gdshader", ".godot", ".tres", ".tscn"]);
const NETWORK_TOKENS = [
  /\bHTTPRequest\b/u,
  /\bHTTPClient\b/u,
  /\bWebSocketPeer\b/u,
  /\bWebSocketMultiplayerPeer\b/u,
  /\bENetMultiplayerPeer\b/u,
  /\bTCPServer\b/u,
  /\bStreamPeerTCP\b/u,
  /\bPacketPeerUDP\b/u,
];
const EXCLUDED_PCK_MARKERS = [
  "CHAR-BASE-B-meshy-t2",
  "CHAR-BASE-M-meshy-t2",
  "CHAR-BASE-T-tripo-5k",
  "CHAR-BASE-T-fix.glb",
  "CHAR-BASE-T-v8-4-single-mass-r1",
  "CHAR-BASE-T-v8-5-authored-sculpt-r4",
];
const REQUIRED_PCK_MARKERS = [
  "characters/authored_jelly_body.gdc",
  "characters/base_b/reference_body.tscn.remap",
  "characters/base_t/reference_body.tscn.remap",
];
const REQUIRED_COMPILED_REFERENCE_BODIES = 6;
const PCK_DIRECTORY_ENCRYPTED = 1;
const PCK_SPARSE_BUNDLE = 4;
const MAX_PCK_RESOURCE_COUNT = 100_000;
const RIGHTS_BOUND_FILES = {
  "tools/meshy/build_t_v8_5_authored_sculpt.py": "7f9ae79363244d0cf30ecf3d6f207ec777f189cf4c31bf00ad1496a8014ec8e5",
  "godot/immune/characters/base_b/CHAR-BASE-B-meshy-t2.glb": "c57cbf701c6ec66dfca69715e82ffe9339bc5ebf121fa05251f54157bab3100e",
  "godot/immune/characters/base_t/CHAR-BASE-T-tripo-5k.glb": "4b969a424da09aad9dfb80b810e7ec6b7ce08db61cb54da7febc482b259dd105",
  "godot/immune/characters/base_t/CHAR-BASE-T-v8-4-single-mass-r1.glb": "169394df640604f6d5e1302f5ff82b444b088e924125b971441e713185b6f7bb",
  "godot/immune/characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb": "8f14cfe59a508df413e4d53218f30bbf316e7e5d31e42154b2916a0bd5669294",
  "godot/immune/characters/gel/jelly_micro_height.png": "25ba40fcb8a6d800fc1ffe4747a4dadad95593fc8d8f3299aed5eef7888fc9a6",
  "godot/immune/fonts/NotoSansHK-VF.ttf": "70172afd2cf0e045182787219b949e7798253982a36e364114757c09efd55477",
  "godot/immune/audio/music/immune_pulse.ogg": "1daba74fd27ac64db650cda112689ac5b5a9ea4776a5d56b0f71b6d5474de3a4",
  "godot/immune/audio/sfx/core_hit.wav": "41ae39ffb58e7fe3e1117cccb9d6e3c99afc790e0335b8d1e98e4f36cc81c5fe",
  "godot/immune/audio/sfx/defeat.wav": "ed52b15f1e95df443c13a02ca183d8d83d6b046b0ffd86bfcbc9ade2b01bf06a",
  "godot/immune/audio/sfx/duty.wav": "b17e5aedf0a2629b4b90fbc3f1e22111983fce75f8bf276f69e88a9b968acbbe",
  "godot/immune/audio/sfx/hit.wav": "fc53b90d36baf9fb1a16c4f9695a025fd54c4670e6cd0fbeacbde9d24949405a",
  "godot/immune/audio/sfx/phase.wav": "881510d74cb039475d0fcd0e943201eb11c4d597f2b0a3f08b62969f1d631d66",
  "godot/immune/audio/sfx/shot.wav": "1c653efcd6c960650ed7332f33aabfe83baf02f76401287ac67ac70b04c6237c",
  "godot/immune/audio/sfx/ui.wav": "2a0c5878e276e1f8be32e3ae3991913ceefce8787e9e0fd02bd767ceedd427e5",
  "godot/immune/audio/sfx/victory.wav": "d62dc33fa149114e75052ef6c11f77356a783510ee17c08d68bcc91b3340e963",
};
const REQUIRED_OWNER_ATTESTATIONS = [
  "all_shipping_asset_rights_verified",
  "audio_provenance_attached",
  "generative_ai_disclosure_approved",
  "content_survey_completed",
  "macos_developer_id_signed",
  "macos_notarization_accepted",
  "native_windows_smoke_exact_candidate",
  "native_linux_smoke_exact_candidate",
  "native_macos_smoke_exact_candidate",
  "steamworks_configuration_verified",
  "private_steam_branch_install_tested",
  "minimum_spec_platforms_tested",
  "steam_deck_session_tested",
  "human_playtest_gate_accepted",
  "store_page_preview_approved",
  "valve_store_review_approved",
  "valve_build_review_approved",
];
const REQUIRED_EXTERNAL_EVIDENCE = [
  "asset_rights_attestation",
  "audio_provenance",
  "content_survey_record",
  "native_windows_smoke",
  "native_linux_smoke",
  "native_macos_smoke",
  "macos_signing_identity_record",
  "macos_notarization",
  "steamworks_configuration_record",
  "steamcmd_preview_log",
  "private_branch_install_report",
  "minimum_spec_platform_report",
  "steam_deck_session_report",
  "human_playtest_aggregate",
  "store_page_preview_record",
  "valve_store_review_approval",
  "valve_build_review_approval",
];
const NATIVE_EVIDENCE_PLATFORMS = {
  native_windows_smoke: "Windows",
  native_linux_smoke: "Linux",
  native_macos_smoke: "macOS",
};
const NATIVE_ARTIFACT_FILES = {
  Windows: ["IMMUNE-windows.exe", "IMMUNE-windows.pck"],
  Linux: ["IMMUNE-linux.x86_64", "IMMUNE-linux.pck"],
  macOS: ["IMMUNE-macOS.zip"],
};

function extension(path) {
  const match = /\.[^.\/]+$/u.exec(path);
  return match?.[0]?.toLowerCase() ?? "";
}

async function runtimeSourceFiles(root, directory = join(root, "godot/immune")) {
  const files = [];
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    if (entry.isDirectory() && [".godot", "build", "tools"].includes(entry.name)) continue;
    const target = join(directory, entry.name);
    if (entry.isDirectory()) files.push(...await runtimeSourceFiles(root, target));
    else if (entry.isFile() && RUNTIME_EXTENSIONS.has(extension(entry.name))) files.push(target);
  }
  return files;
}

async function validateOfflineRuntime(root) {
  const violations = [];
  const files = await runtimeSourceFiles(root);
  for (const path of files) {
    const source = await readFile(path, "utf8");
    for (const token of NETWORK_TOKENS) {
      if (token.test(source)) violations.push(`${relative(root, path)}: ${token.source}`);
    }
  }
  if (violations.length) throw new Error(`RUNTIME_NETWORK_SURFACE_FOUND\n- ${violations.join("\n- ")}`);
  return files.length;
}

async function validateRepositoryFiles(root) {
  for (const [path, minimumBytes, requiredText] of REQUIRED_REPOSITORY_FILES) {
    const absolute = join(root, path);
    const info = await lstat(absolute);
    if (!info.isFile() || info.isSymbolicLink() || info.size < minimumBytes) {
      throw new Error(`Release handoff file is invalid: ${path}`);
    }
    const source = await readFile(absolute, "utf8");
    if (!source.includes(requiredText)) throw new Error(`Release handoff file is incomplete: ${path}`);
  }
}

async function validateRightsBoundFiles(root) {
  const register = await readFile(join(root, "steam/asset-rights-register.md"), "utf8");
  for (const [path, expected] of Object.entries(RIGHTS_BOUND_FILES)) {
    const absolute = join(root, path);
    const info = await lstat(absolute);
    if (!info.isFile() || info.isSymbolicLink() || info.size < 1) {
      throw new Error(`Rights-bound asset is invalid: ${path}`);
    }
    const actual = createHash("sha256").update(await readFile(absolute)).digest("hex");
    if (actual !== expected) throw new Error(`Rights-bound asset changed without review: ${path}`);
    if (!register.includes(expected)) throw new Error(`Rights register is missing the exact bound hash: ${path}`);
  }
  return Object.keys(RIGHTS_BOUND_FILES).length;
}

export function parsePckResourcePaths(input) {
  const buffer = Buffer.isBuffer(input) ? input : Buffer.from(input);
  let cursor = 0;
  const fail = (message) => {
    throw new Error(`Invalid Godot PCK: ${message}`);
  };
  const requireBytes = (count, label) => {
    if (!Number.isSafeInteger(count) || count < 0 || cursor + count > buffer.length) {
      fail(`${label} exceeds file bounds`);
    }
  };
  const readU32 = (label) => {
    requireBytes(4, label);
    const value = buffer.readUInt32LE(cursor);
    cursor += 4;
    return value;
  };
  const readU64 = (label) => {
    requireBytes(8, label);
    const value = buffer.readBigUInt64LE(cursor);
    cursor += 8;
    if (value > BigInt(Number.MAX_SAFE_INTEGER)) fail(`${label} is too large`);
    return Number(value);
  };

  requireBytes(4, "magic");
  const magic = buffer.subarray(cursor, cursor + 4).toString("ascii");
  cursor += 4;
  if (magic !== "GDPC") fail(`expected GDPC magic, got ${JSON.stringify(magic)}`);
  const version = readU32("pack version");
  if (![2, 3, 4].includes(version)) fail(`unsupported pack version ${version}`);
  readU32("engine major version");
  readU32("engine minor version");
  readU32("engine patch version");
  const flags = readU32("pack flags");
  const fileBase = readU64("file base");
  if ((flags & PCK_DIRECTORY_ENCRYPTED) !== 0) {
    fail("encrypted directories cannot be audited without the release key");
  }

  if (version === 3 || version === 4) {
    const directoryOffset = readU64("directory offset");
    if (directoryOffset >= buffer.length) fail("directory offset exceeds file bounds");
    cursor = directoryOffset;
  } else {
    requireBytes(16 * 4, "version 2 reserved header");
    cursor += 16 * 4;
  }

  const fileCount = readU32("file count");
  if (fileCount > MAX_PCK_RESOURCE_COUNT) fail(`implausible file count ${fileCount}`);
  const paths = [];
  for (let index = 0; index < fileCount; index += 1) {
    const pathLength = readU32(`path length ${index}`);
    requireBytes(pathLength, `path ${index}`);
    const path = buffer.subarray(cursor, cursor + pathLength).toString("utf8").replace(/\0+$/u, "");
    cursor += pathLength;
    if (!path) fail(`path ${index} is empty`);
    const fileOffset = readU64(`file offset ${index}`);
    const fileSize = readU64(`file size ${index}`);
    if ((flags & PCK_SPARSE_BUNDLE) === 0) {
      const payloadStart = fileBase + fileOffset;
      if (!Number.isSafeInteger(payloadStart) || payloadStart > buffer.length) {
        fail(`file payload ${index} starts outside file bounds`);
      }
      if (fileSize > buffer.length - payloadStart) {
        fail(`file payload ${index} exceeds file bounds`);
      }
    }
    requireBytes(16, `file digest ${index}`);
    cursor += 16;
    readU32(`file flags ${index}`);
    paths.push(path);
  }
  return paths;
}

export function validatePckResourcePolicyBuffer(buffer) {
  const paths = parsePckResourcePaths(buffer);
  for (const marker of EXCLUDED_PCK_MARKERS) {
    if (paths.some((path) => path.includes(marker))) {
      throw new Error(`Excluded source resource leaked into PCK: ${marker}`);
    }
  }
  for (const marker of REQUIRED_PCK_MARKERS) {
    if (!paths.some((path) => path.includes(marker))) {
      throw new Error(`Required authored character resource is missing from PCK: ${marker}`);
    }
  }
  const compiledReferenceBodies = paths.filter((path) => (
    /^\.godot\/exported\/[^/]+\/export-[0-9a-f]+-reference_body\.scn$/u.test(path)
  ));
  if (compiledReferenceBodies.length < REQUIRED_COMPILED_REFERENCE_BODIES) {
    throw new Error(
      `Required compiled reference bodies are missing from PCK: expected ${REQUIRED_COMPILED_REFERENCE_BODIES}, got ${compiledReferenceBodies.length}`,
    );
  }
  return { files: paths.length };
}

async function validatePckResourcePolicy(artifacts) {
  const pckPath = join(artifacts, "IMMUNE-linux.pck");
  validatePckResourcePolicyBuffer(await readFile(pckPath));
}

function presentText(value) {
  return typeof value === "string" && value.trim().length > 0 && !/^(?:TBD|TODO|placeholder)$/iu.test(value.trim());
}

export function validatePublisherInputs(input) {
  const errors = [];
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw new Error("PUBLISHER_INPUTS_INCOMPLETE\n- root: expected an object");
  }
  if (input.schema_version !== 2) errors.push("schema_version: expected 2");
  if (input.release_track !== "steam_demo") errors.push("release_track: expected steam_demo");
  if (!/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/u.test(input.candidate?.version ?? "")) {
    errors.push("candidate.version: expected a semantic version");
  }
  if (!/^[0-9a-f]{40}$/u.test(input.candidate?.commit ?? "")) {
    errors.push("candidate.commit: expected a full 40-character Git SHA");
  }
  try {
    const normalized = validateSteamConfig({ appId: input.demo_app_id, depots: input.depots });
    const baseId = String(input.base_game_app_id ?? "");
    if (!/^[1-9]\d{3,11}$/u.test(baseId)) errors.push("base_game_app_id: expected a real numeric Steam App ID");
    if ([normalized.appId, ...Object.values(normalized.depots)].includes(baseId)) {
      errors.push("base_game_app_id: must differ from the Demo App and depot IDs");
    }
  } catch (error) {
    errors.push(error instanceof Error ? error.message : String(error));
  }
  for (const key of ["legal_name", "developer_name", "support_email", "support_url", "privacy_policy_url"]) {
    if (!presentText(input.publisher?.[key])) errors.push(`publisher.${key}: required`);
  }
  for (const key of ["support_url", "privacy_policy_url"]) {
    const value = input.publisher?.[key];
    if (presentText(value) && !/^https:\/\//u.test(value)) errors.push(`publisher.${key}: expected HTTPS URL`);
  }
  if (presentText(input.publisher?.support_email) && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/u.test(input.publisher.support_email)) {
    errors.push("publisher.support_email: expected an email address");
  }
  const attestations = input.owner_attestations;
  if (!attestations || typeof attestations !== "object" || Array.isArray(attestations)) {
    errors.push("owner_attestations: expected an object");
  } else {
    for (const key of REQUIRED_OWNER_ATTESTATIONS) {
      if (attestations[key] !== true) errors.push(`owner_attestations.${key}: owner must set true with evidence`);
    }
    if (typeof attestations.public_release_authorized !== "boolean") {
      errors.push("owner_attestations.public_release_authorized: expected a boolean owner decision");
    }
  }
  const evidence = input.evidence;
  if (!evidence || typeof evidence !== "object" || Array.isArray(evidence)) {
    errors.push("evidence: expected an object");
  } else {
    for (const key of REQUIRED_EXTERNAL_EVIDENCE) {
      if (!presentText(evidence[key]) || !isAbsolute(evidence[key])) {
        errors.push(`evidence.${key}: required absolute archived-file path`);
      }
    }
  }
  const evidenceHashes = input.evidence_sha256;
  if (!evidenceHashes || typeof evidenceHashes !== "object" || Array.isArray(evidenceHashes)) {
    errors.push("evidence_sha256: expected an object");
  } else {
    for (const key of REQUIRED_EXTERNAL_EVIDENCE) {
      if (!/^[0-9a-f]{64}$/u.test(evidenceHashes[key] ?? "")) {
        errors.push(`evidence_sha256.${key}: expected a lowercase SHA-256 digest`);
      }
    }
  }
  if (errors.length) throw new Error(`PUBLISHER_INPUTS_INCOMPLETE\n- ${errors.join("\n- ")}`);
  return {
    releaseTrack: "steam_demo",
    externalEvidence: REQUIRED_EXTERNAL_EVIDENCE.length,
    publicReleaseAuthorized: input.owner_attestations.public_release_authorized === true,
    candidate: { ...input.candidate },
  };
}

async function validatePublisherEvidenceFiles(input, artifactRoot, releaseVersion) {
  const errors = [];
  const nativeReports = {};
  for (const key of REQUIRED_EXTERNAL_EVIDENCE) {
    const path = input.evidence[key];
    try {
      const info = await lstat(path);
      if (!info.isFile() || info.isSymbolicLink() || info.size < 1) {
        errors.push(`evidence.${key}: must be a non-empty regular file, not a symlink`);
        continue;
      }
      const buffer = await readFile(path);
      const digest = createHash("sha256").update(buffer).digest("hex");
      if (digest !== input.evidence_sha256[key]) {
        errors.push(`evidence.${key}: SHA-256 does not match evidence_sha256.${key}`);
        continue;
      }
      const platform = NATIVE_EVIDENCE_PLATFORMS[key];
      if (platform) {
        let report;
        try {
          report = JSON.parse(buffer.toString("utf8"));
        } catch {
          errors.push(`evidence.${key}: expected valid native-smoke JSON`);
          continue;
        }
        if (report.schema_version !== 1 || report.status !== "pass" || report.platform !== platform) {
          errors.push(`evidence.${key}: native-smoke identity/status mismatch`);
        }
        if (report.build?.commit !== input.candidate.commit || report.build?.version !== input.candidate.version) {
          errors.push(`evidence.${key}: native-smoke candidate does not match publisher candidate`);
        }
        if (report.source_repository?.head_verified !== true || report.source_repository?.tracked_tree_clean !== true) {
          errors.push(`evidence.${key}: native-smoke source repository was not verified clean`);
        }
        nativeReports[platform] = report;
      }
    } catch (error) {
      errors.push(`evidence.${key}: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  if (input.candidate.version !== releaseVersion) {
    errors.push(`candidate.version: expected release version ${releaseVersion}`);
  }
  if (artifactRoot) {
    for (const [platform, files] of Object.entries(NATIVE_ARTIFACT_FILES)) {
      const report = nativeReports[platform];
      if (!report) continue;
      for (const file of files) {
        const record = report.artifacts?.find((entry) => entry.name === file);
        if (!record) {
          errors.push(`evidence native ${platform}: missing artifact record ${file}`);
          continue;
        }
        const buffer = await readFile(join(artifactRoot, file));
        const digest = createHash("sha256").update(buffer).digest("hex");
        if (record.bytes !== buffer.length || record.sha256 !== digest) {
          errors.push(`evidence native ${platform}: artifact identity mismatch for ${file}`);
        }
      }
    }
  }
  if (errors.length) throw new Error(`PUBLISHER_EVIDENCE_INVALID\n- ${errors.join("\n- ")}`);
  return REQUIRED_EXTERNAL_EVIDENCE.length;
}

export async function validateSteamReadiness({ root = ROOT, artifacts = "", publisherInputs = null } = {}) {
  const absoluteRoot = resolve(root);
  const artifactRoot = artifacts ? (isAbsolute(artifacts) ? artifacts : resolve(absoluteRoot, artifacts)) : "";
  const [release, assets, runtimeFiles, , rightsHashes] = await Promise.all([
    validateReleaseContract({ root: absoluteRoot, artifacts: artifactRoot }),
    validateSteamAssets(join(absoluteRoot, "steam/assets")),
    validateOfflineRuntime(absoluteRoot),
    validateRepositoryFiles(absoluteRoot),
    validateRightsBoundFiles(absoluteRoot),
  ]);
  if (artifactRoot) await validatePckResourcePolicy(artifactRoot);
  const publisher = publisherInputs ? validatePublisherInputs(publisherInputs) : null;
  const publisherEvidence = publisher
    ? await validatePublisherEvidenceFiles(publisherInputs, artifactRoot, release.version)
    : 0;
  return {
    schema_version: 1,
    status: publisher
      ? publisher.publicReleaseAuthorized
        ? "release-evidence-verified-owner-authorized"
        : "release-evidence-verified-owner-authorization-pending"
      : "repository-ready-publisher-gates-open",
    version: release.version,
    release_artifacts: artifactRoot ? "verified" : "not-requested",
    steam_assets: assets.files.length,
    screenshots: assets.screenshot_count,
    runtime_source_files_scanned: runtimeFiles,
    rights_hashes_verified: rightsHashes,
    publisher_inputs: publisher ? "complete" : "not-supplied",
    publisher_evidence_files_verified: publisherEvidence,
    external_gates: publisher
      ? publisher.publicReleaseAuthorized ? [] : ["owner public release authorization"]
      : [
        "owner asset and marketing-rights attestation",
        "real Steam App and depot IDs",
        "native Windows and Linux exact-candidate smoke",
        "Developer ID signing and Apple notarization",
        "SteamCMD preview and private-branch client installs",
        "minimum-spec/Steam Deck and human playtests",
        "Valve review and owner release authorization",
      ],
  };
}

export function readinessArguments(argv) {
  const allowed = new Set(["artifacts", "publisher-inputs"]);
  const result = {};
  for (const raw of argv) {
    const match = /^--([^=]+)=(.*)$/u.exec(raw);
    if (!match || !allowed.has(match[1])) throw new Error(`Unknown Steam readiness argument: ${raw}`);
    if (Object.hasOwn(result, match[1])) throw new Error(`Duplicate Steam readiness argument: --${match[1]}`);
    if (!match[2]) throw new Error(`Steam readiness argument requires a value: --${match[1]}`);
    result[match[1]] = match[2];
  }
  return result;
}

async function main() {
  const args = readinessArguments(process.argv.slice(2));
  const inputsPath = args["publisher-inputs"] ?? "";
  const publisherInputs = inputsPath ? JSON.parse(await readFile(resolve(inputsPath), "utf8")) : null;
  const report = await validateSteamReadiness({ artifacts: args.artifacts ?? "", publisherInputs });
  console.log(`STEAM_READINESS_OK status=${report.status} version=${report.version} artifacts=${report.release_artifacts} assets=${report.steam_assets} screenshots=${report.screenshots} rights_hashes=${report.rights_hashes_verified} external_gates=${report.external_gates.length}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
