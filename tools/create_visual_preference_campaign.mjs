#!/usr/bin/env node

import { createHash } from "node:crypto";
import {
  lstat,
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  writeFile,
} from "node:fs/promises";
import { basename, dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const OUTPUTS_ROOT = resolve(ROOT, "outputs");
const VERSION_IDS = ["v5", "v6", "v7"];
const CANDIDATE_IDS = ["candidate-01", "candidate-02", "candidate-03"];
const PARTICIPANT_CODES = Array.from(
  { length: 6 },
  (_unused, index) => `tester-${String(index + 1).padStart(2, "0")}`,
);
const RATING_KEYS = [
  "jelly_feel",
  "softness",
  "internal_detail",
  "highlight_quality",
  "family_clarity",
  "banner_match",
];
const EXPECTED_ROOT_ENTRIES = [
  "README.md",
  "SHA256SUMS",
  "campaign-manifest.json",
  "facilitator",
  "participants",
];
const EXPECTED_PARTICIPANT_ENTRIES = [
  "README.md",
  "assets",
  "index.html",
  "manifest.json",
  "report.json",
];
const EXPECTED_ASSET_ENTRIES = [
  "candidate-01.png",
  "candidate-02.png",
  "candidate-03.png",
  "reference.png",
];

export const PREFERENCE_ORDERS = [
  ["v5", "v6", "v7"],
  ["v5", "v7", "v6"],
  ["v6", "v5", "v7"],
  ["v6", "v7", "v5"],
  ["v7", "v5", "v6"],
  ["v7", "v6", "v5"],
];

function sha256(value) {
  return createHash("sha256").update(value).digest("hex");
}

function assertCommit(value, label) {
  if (typeof value !== "string" || !/^[0-9a-f]{40}$/u.test(value)) {
    throw new Error(`${label}: expected a full 40-character lowercase Git SHA`);
  }
}

function portablePath(path) {
  return path.split(sep).join("/");
}

function sourceLabel(path) {
  const absolute = resolve(path);
  const local = portablePath(relative(ROOT, absolute));
  return local === ".." || local.startsWith("../") || isAbsolute(local)
    ? basename(absolute)
    : local;
}

async function readPng(path, label, expected = null) {
  const absolute = resolve(path);
  const info = await lstat(absolute);
  if (info.isSymbolicLink() || !info.isFile() || info.size < 24) {
    throw new Error(`${label}: expected a non-empty regular PNG file`);
  }
  const buffer = await readFile(absolute);
  const signature = buffer.subarray(0, 8).toString("hex");
  if (signature !== "89504e470d0a1a0a") throw new Error(`${label}: invalid PNG signature`);
  const width = buffer.readUInt32BE(16);
  const height = buffer.readUInt32BE(20);
  if (expected && (width !== expected.width || height !== expected.height)) {
    throw new Error(
      `${label}: expected ${expected.width}x${expected.height}, got ${width}x${height}`,
    );
  }
  if (!expected && (width < 1024 || height < 512)) {
    throw new Error(`${label}: reference artwork is too small at ${width}x${height}`);
  }
  return {
    buffer,
    bytes: buffer.length,
    width,
    height,
    sha256: sha256(buffer),
    source_path: sourceLabel(absolute),
  };
}

function blankRatings() {
  return Object.fromEntries(RATING_KEYS.map((key) => [key, 0]));
}

function renderCandidateSections() {
  const labels = [
    ["jelly_feel", "Jelly feel / 啫喱感"],
    ["softness", "Softness / 柔軟感"],
    ["internal_detail", "Internal detail / 內部細節"],
    ["highlight_quality", "Highlight quality / 反光質感"],
    ["family_clarity", "Family clarity / 家族辨識"],
    ["banner_match", "Reference match / 參考圖吻合度"],
  ];
  const options = [
    '<option value="">Choose 1 to 5 / 選擇 1 至 5</option>',
    '<option value="1">1 - weakest / 最弱</option>',
    '<option value="2">2</option>',
    '<option value="3">3</option>',
    '<option value="4">4</option>',
    '<option value="5">5 - strongest / 最強</option>',
  ].join("");
  return CANDIDATE_IDS.map((candidateId, index) => {
    const candidateNumber = String(index + 1).padStart(2, "0");
    const controls = labels.map(([key, label]) => `
            <label>
              <span>${label}</span>
              <select name="${candidateId}__${key}" required>${options}</select>
            </label>`).join("");
    return `
      <section class="candidate" aria-labelledby="${candidateId}-title">
        <header>
          <p class="candidate-index">Candidate ${candidateNumber} / 候選 ${candidateNumber}</p>
          <h2 id="${candidateId}-title">Judge the surface, not the order.</h2>
          <p class="candidate-note">The upper row shows front views. The lower row shows face close-ups.</p>
        </header>
        <figure class="lineup-scroll">
          <img
            src="assets/${candidateId}.png"
            alt="Anonymous cell lineup candidate ${candidateNumber}"
            width="6144"
            height="2048"
            ${index === 0 ? 'loading="eager"' : 'loading="lazy"'}
            decoding="async">
        </figure>
        <fieldset>
          <legend>Scores / 評分</legend>
          <div class="score-grid">${controls}
          </div>
          <label class="notes">
            <span>What feels convincing or wrong? / 邊部分自然或唔自然？</span>
            <textarea name="${candidateId}__notes" rows="4" required></textarea>
          </label>
        </fieldset>
      </section>`;
  }).join("");
}

function renderParticipantHtml({ campaignId, participantCode }) {
  const initial = JSON.stringify({
    schema_version: 1,
    campaign_id: campaignId,
    participant_code: participantCode,
    candidate_order: CANDIDATE_IDS,
    rating_keys: RATING_KEYS,
  }).replaceAll("<", "\\u003c");
  const candidateOptions = CANDIDATE_IDS.map(
    (candidateId, index) => (
      `<option value="${candidateId}">Candidate ${String(index + 1).padStart(2, "0")}</option>`
    ),
  ).join("");
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light dark">
  <link rel="icon" href="data:,">
  <title>IMMUNE visual preference study</title>
  <style>
    :root {
      color-scheme: light dark;
      --page: #eef6f7;
      --surface: #f7fbfc;
      --surface-alt: #dcebed;
      --text: #10282d;
      --muted: #486269;
      --line: #8da8ae;
      --accent: #0b626d;
      --accent-text: #f4fbfc;
      --danger: #962f38;
      --radius: 12px;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --page: #071316;
        --surface: #0d2025;
        --surface-alt: #16343a;
        --text: #e8f4f5;
        --muted: #aec4c8;
        --line: #527078;
        --accent: #79d0d8;
        --accent-text: #071316;
        --danger: #ff9ba4;
      }
    }
    * { box-sizing: border-box; }
    body {
      min-height: 100dvh;
      margin: 0;
      background: var(--page);
      color: var(--text);
      font-family: "Avenir Next", Avenir, "Segoe UI", ui-sans-serif, system-ui, sans-serif;
      line-height: 1.5;
    }
    main {
      width: min(1380px, calc(100% - 32px));
      margin: 0 auto;
      padding: 48px 0 80px;
    }
    .intro { max-width: 760px; margin-bottom: 36px; }
    h1 {
      max-width: 14ch;
      margin: 0 0 14px;
      font-size: clamp(2.35rem, 7vw, 5.8rem);
      line-height: .94;
      letter-spacing: -.055em;
    }
    h2 { margin: 0; font-size: clamp(1.3rem, 2vw, 2rem); letter-spacing: -.025em; }
    p { margin: 0; }
    .lede { max-width: 56ch; color: var(--muted); font-size: 1.08rem; }
    .privacy {
      margin-top: 22px;
      padding-left: 16px;
      border-left: 4px solid var(--accent);
      color: var(--muted);
    }
    .reference { margin: 56px 0 72px; }
    .reference header { max-width: 680px; margin-bottom: 18px; }
    .reference h2 { margin-bottom: 8px; }
    .reference p { color: var(--muted); }
    figure { margin: 0; }
    .reference-image,
    .lineup-scroll {
      overflow-x: auto;
      border: 1px solid var(--line);
      border-radius: var(--radius);
      background: var(--surface);
    }
    .reference-image img {
      display: block;
      width: 100%;
      min-width: 720px;
      height: auto;
    }
    .candidate {
      padding: 56px 0 68px;
      border-top: 1px solid var(--line);
    }
    .candidate header { margin-bottom: 18px; }
    .candidate-index {
      margin-bottom: 6px;
      color: var(--accent);
      font-weight: 750;
    }
    .candidate-note { margin-top: 8px; color: var(--muted); }
    .lineup-scroll img {
      display: block;
      width: 100%;
      min-width: 960px;
      height: auto;
    }
    fieldset {
      margin: 26px 0 0;
      padding: 24px;
      border: 1px solid var(--line);
      border-radius: var(--radius);
      background: var(--surface);
    }
    legend { padding: 0 8px; font-weight: 750; }
    .score-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 18px;
    }
    label { display: grid; gap: 7px; font-weight: 650; }
    select,
    textarea,
    button {
      width: 100%;
      min-height: 46px;
      border: 1px solid var(--line);
      border-radius: var(--radius);
      font: inherit;
    }
    select,
    textarea {
      padding: 10px 12px;
      background: var(--page);
      color: var(--text);
    }
    textarea { resize: vertical; }
    .notes { margin-top: 20px; }
    select:focus-visible,
    textarea:focus-visible,
    button:focus-visible,
    input:focus-visible {
      outline: 3px solid var(--accent);
      outline-offset: 3px;
    }
    .summary {
      max-width: 920px;
      margin-top: 30px;
      padding: 28px;
      border: 1px solid var(--line);
      border-radius: var(--radius);
      background: var(--surface);
    }
    .summary h2 { margin-bottom: 20px; }
    .summary-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; }
    .age-check {
      display: flex;
      align-items: flex-start;
      gap: 10px;
      margin-top: 22px;
    }
    .age-check input { width: 22px; height: 22px; margin: 1px 0 0; }
    .actions { display: flex; gap: 12px; margin-top: 24px; }
    button {
      width: auto;
      padding: 11px 18px;
      background: var(--surface-alt);
      color: var(--text);
      font-weight: 750;
      cursor: pointer;
    }
    button.primary { background: var(--accent); color: var(--accent-text); border-color: var(--accent); }
    button:active { transform: translateY(1px); }
    .error {
      display: none;
      margin-top: 18px;
      padding: 14px;
      border: 1px solid var(--danger);
      border-radius: var(--radius);
      color: var(--danger);
    }
    .error.visible { display: block; }
    footer { margin-top: 36px; color: var(--muted); }
    @media (max-width: 820px) {
      main { width: min(100% - 24px, 720px); padding-top: 28px; }
      .score-grid,
      .summary-grid { grid-template-columns: 1fr; }
      fieldset,
      .summary { padding: 18px; }
      .actions { flex-direction: column; }
      button { width: 100%; }
    }
  </style>
</head>
<body>
  <main>
    <header class="intro">
      <h1>Which surface feels most like jelly?</h1>
      <p class="lede">Compare three anonymous lineups, score each one, then download one local report.</p>
      <p class="privacy"><strong>No network requests.</strong> Do not enter a name, email address, account name, or contact detail.</p>
    </header>

    <section class="reference" aria-labelledby="reference-title">
      <header>
        <h2 id="reference-title">Reference artwork / 參考圖片</h2>
        <p>Use this image as the target for softness, translucency, internal detail, and character appeal.</p>
      </header>
      <figure class="reference-image">
        <img src="assets/reference.png" alt="Target base cell lineup artwork" width="1536" height="1024" decoding="async">
      </figure>
    </section>

    <form id="preference-form" novalidate>
      ${renderCandidateSections()}

      <section class="summary" aria-labelledby="summary-title">
        <h2 id="summary-title">Final choice / 最終選擇</h2>
        <div class="summary-grid">
          <label>
            <span>Best overall match / 整體最吻合</span>
            <select name="overall_pick" required>
              <option value="">Choose a candidate / 選擇候選</option>
              ${candidateOptions}
            </select>
          </label>
          <label>
            <span>Confidence / 信心</span>
            <select name="confidence" required>
              <option value="">Choose 1 to 5 / 選擇 1 至 5</option>
              <option value="1">1 - low / 低</option>
              <option value="2">2</option>
              <option value="3">3</option>
              <option value="4">4</option>
              <option value="5">5 - high / 高</option>
            </select>
          </label>
          <label>
            <span>Main reason / 主要原因</span>
            <textarea name="main_reason" rows="4" required></textarea>
          </label>
          <label>
            <span>Most important remaining issue / 最重要剩餘問題</span>
            <textarea name="remaining_issue" rows="4" required></textarea>
          </label>
        </div>
        <label class="age-check">
          <input type="checkbox" name="age_18_or_over" required>
          <span>I confirm I am 18 or older / 我確認已年滿 18 歲</span>
        </label>
        <div class="actions">
          <button type="button" id="draft-button">Save draft / 儲存草稿</button>
          <button type="button" class="primary" id="complete-button">Export report / 匯出報告</button>
        </div>
        <div id="form-error" class="error" role="alert" tabindex="-1"></div>
      </section>
    </form>
    <footer>Give the downloaded JSON only to the facilitator. The page never uploads it.</footer>
  </main>
  <script type="application/json" id="campaign-data">${initial}</script>
  <script>
    const initial = JSON.parse(document.getElementById("campaign-data").textContent);
    const form = document.getElementById("preference-form");
    const errorBox = document.getElementById("form-error");

    function value(name) {
      const field = form.elements.namedItem(name);
      return field ? String(field.value || "").trim() : "";
    }

    function collect(status) {
      const candidates = {};
      for (const candidateId of initial.candidate_order) {
        const ratings = {};
        for (const key of initial.rating_keys) {
          const raw = value(candidateId + "__" + key);
          ratings[key] = raw ? Number(raw) : 0;
        }
        candidates[candidateId] = {
          ratings,
          notes: value(candidateId + "__notes"),
        };
      }
      return {
        schema_version: 1,
        status,
        privacy: "anonymous-local-only",
        campaign_id: initial.campaign_id,
        participant_code: initial.participant_code,
        age_18_or_over: form.elements.namedItem("age_18_or_over").checked,
        candidate_order: initial.candidate_order,
        candidates,
        summary: {
          overall_pick: value("overall_pick"),
          confidence_1_to_5: Number(value("confidence") || 0),
          main_reason: value("main_reason"),
          remaining_issue: value("remaining_issue"),
        },
        exported_at: new Date().toISOString(),
      };
    }

    function completeErrors(report) {
      const errors = [];
      if (!report.age_18_or_over) errors.push("Confirm that you are 18 or older.");
      for (const candidateId of initial.candidate_order) {
        const result = report.candidates[candidateId];
        for (const key of initial.rating_keys) {
          if (result.ratings[key] < 1 || result.ratings[key] > 5) {
            errors.push("Complete every 1 to 5 score.");
            break;
          }
        }
        if (!result.notes) errors.push("Add one note for every candidate.");
      }
      if (!initial.candidate_order.includes(report.summary.overall_pick)) {
        errors.push("Choose the best overall candidate.");
      }
      if (report.summary.confidence_1_to_5 < 1 || report.summary.confidence_1_to_5 > 5) {
        errors.push("Choose a confidence score.");
      }
      if (!report.summary.main_reason) errors.push("Add the main reason for your choice.");
      if (!report.summary.remaining_issue) errors.push("Add the most important remaining issue.");
      return [...new Set(errors)];
    }

    function download(status) {
      const report = collect(status);
      if (status === "complete") {
        const errors = completeErrors(report);
        if (errors.length) {
          errorBox.textContent = errors.join(" ");
          errorBox.classList.add("visible");
          errorBox.focus();
          return;
        }
      }
      errorBox.classList.remove("visible");
      const blob = new Blob([JSON.stringify(report, null, 2) + "\\n"], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = url;
      anchor.download = initial.participant_code + "-visual-preference-" + status + ".json";
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      setTimeout(() => URL.revokeObjectURL(url), 0);
    }

    document.getElementById("draft-button").addEventListener("click", () => download("draft"));
    document.getElementById("complete-button").addEventListener("click", () => download("complete"));
  </script>
</body>
</html>
`;
}

function renderParticipantReadme({ campaignId, participantCode }) {
  return `# IMMUNE anonymous visual preference study

Participant code: \`${participantCode}\`
Campaign: \`${campaignId}\`

1. Open \`index.html\` in a current browser.
2. View the reference artwork first.
3. Score all three anonymous candidates in the supplied order.
4. Export the completed JSON report.
5. Return only that JSON file to the facilitator.

Do not open another participant folder. Do not enter names, contact details,
account names, or other identifying information. This kit performs no network
requests and does not auto-save answers.
`;
}

function renderFacilitatorReadme({ campaignId, buildCommit }) {
  return `# IMMUNE visual preference facilitator guide

Campaign: \`${campaignId}\`
Exact V7 candidate commit: \`${buildCommit}\`

Keep this folder private. It contains the answer key.

1. Give each adult participant exactly one folder from \`participants/\`.
2. Do not reveal which visual revision is assigned to a candidate number.
3. Ask participants to view the reference artwork before scoring.
4. Collect only completed JSON reports. Do not collect names or contact data.
5. Require at least three independent participants. Six is preferred because
   the package contains all six candidate-order permutations.
6. Decode choices only after the reports are collected.

An empty aggregation template is included. It records no invented participant
result.
`;
}

function renderRootReadme({ campaignId }) {
  return `# IMMUNE V5/V6/V7 visual preference campaign

Campaign: \`${campaignId}\`

This is an offline, checksum-locked, anonymous preference package.

- Distribute only one \`participants/tester-XX\` folder to each participant.
- Keep \`facilitator/answer-key.json\` private until collection is complete.
- Verify the package with:

  \`node tools/create_visual_preference_campaign.mjs --verify=/path/to/campaign\`

- Raw participant JSON belongs under an ignored local \`outputs/\` directory.
- No response is included in this package.
`;
}

function templateReport({ campaignId, participantCode }) {
  return {
    schema_version: 1,
    status: "template",
    privacy: "anonymous-local-only",
    campaign_id: campaignId,
    participant_code: participantCode,
    age_18_or_over: null,
    candidate_order: CANDIDATE_IDS,
    candidates: Object.fromEntries(
      CANDIDATE_IDS.map((candidateId) => [
        candidateId,
        { ratings: blankRatings(), notes: "" },
      ]),
    ),
    summary: {
      overall_pick: "",
      confidence_1_to_5: 0,
      main_reason: "",
      remaining_issue: "",
    },
  };
}

async function assertMissing(path) {
  try {
    await stat(path);
    throw new Error(`Output already exists; refusing to overwrite: ${path}`);
  } catch (error) {
    if (error?.code !== "ENOENT") throw error;
  }
}

async function writeJson(path, value) {
  await writeFile(path, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

async function walkFiles(root) {
  const files = [];
  async function visit(directory) {
    const entries = await readdir(directory, { withFileTypes: true });
    entries.sort((a, b) => a.name.localeCompare(b.name, "en"));
    for (const entry of entries) {
      const absolute = join(directory, entry.name);
      const info = await lstat(absolute);
      const local = portablePath(relative(root, absolute));
      if (info.isSymbolicLink()) throw new Error(`Symbolic links are forbidden: ${local}`);
      if (info.isDirectory()) await visit(absolute);
      else if (info.isFile()) files.push(local);
      else throw new Error(`Unsupported campaign entry: ${local}`);
    }
  }
  await visit(root);
  return files;
}

async function writeChecksums(root) {
  const files = (await walkFiles(root)).filter((path) => path !== "SHA256SUMS");
  const lines = [];
  for (const path of files) {
    lines.push(`${sha256(await readFile(join(root, path)))}  ${path}`);
  }
  await writeFile(join(root, "SHA256SUMS"), `${lines.join("\n")}\n`, "utf8");
}

function exactEntries(actual, expected, label) {
  const left = [...actual].sort();
  const right = [...expected].sort();
  if (JSON.stringify(left) !== JSON.stringify(right)) {
    throw new Error(`${label}: expected ${right.join(", ")}, got ${left.join(", ")}`);
  }
}

export async function verifyVisualPreferenceCampaign(rootPath) {
  const root = resolve(rootPath);
  const rootInfo = await lstat(root);
  if (rootInfo.isSymbolicLink() || !rootInfo.isDirectory()) {
    throw new Error("Campaign root must be a regular directory");
  }
  exactEntries(await readdir(root), EXPECTED_ROOT_ENTRIES, "campaign root");

  const checksumSource = await readFile(join(root, "SHA256SUMS"), "utf8");
  const checksumEntries = new Map();
  for (const line of checksumSource.trim().split(/\r?\n/u)) {
    const match = /^([0-9a-f]{64})  (.+)$/u.exec(line);
    if (!match || checksumEntries.has(match[2])) throw new Error(`Invalid checksum line: ${line}`);
    checksumEntries.set(match[2], match[1]);
  }
  const discovered = (await walkFiles(root)).filter((path) => path !== "SHA256SUMS");
  exactEntries(checksumEntries.keys(), discovered, "checksum inventory");
  for (const path of discovered) {
    const actual = sha256(await readFile(join(root, path)));
    if (actual !== checksumEntries.get(path)) throw new Error(`Checksum mismatch: ${path}`);
  }

  const manifest = JSON.parse(await readFile(join(root, "campaign-manifest.json"), "utf8"));
  const answerKey = JSON.parse(await readFile(join(root, "facilitator/answer-key.json"), "utf8"));
  if (manifest.schema_version !== 1 || manifest.status !== "awaiting-human-results") {
    throw new Error("Campaign manifest status is invalid");
  }
  if (!Array.isArray(manifest.participants) || manifest.participants.length !== 6) {
    throw new Error("Campaign must contain six participants");
  }
  if (answerKey.campaign_id !== manifest.campaign_id) throw new Error("Answer key campaign mismatch");

  const seenOrders = new Set();
  const positionCounts = Array.from(
    { length: CANDIDATE_IDS.length },
    () => Object.fromEntries(VERSION_IDS.map((versionId) => [versionId, 0])),
  );
  for (const [index, participantCode] of PARTICIPANT_CODES.entries()) {
    const kitRoot = join(root, "participants", participantCode);
    exactEntries(await readdir(kitRoot), EXPECTED_PARTICIPANT_ENTRIES, participantCode);
    exactEntries(await readdir(join(kitRoot, "assets")), EXPECTED_ASSET_ENTRIES, `${participantCode} assets`);
    const kitManifest = JSON.parse(await readFile(join(kitRoot, "manifest.json"), "utf8"));
    const report = JSON.parse(await readFile(join(kitRoot, "report.json"), "utf8"));
    if (kitManifest.participant_code !== participantCode || report.participant_code !== participantCode) {
      throw new Error(`${participantCode}: identity mismatch`);
    }
    const participantText = [
      await readFile(join(kitRoot, "README.md"), "utf8"),
      await readFile(join(kitRoot, "index.html"), "utf8"),
      JSON.stringify(kitManifest),
      JSON.stringify(report),
    ].join("\n");
    if (/\bV(?:5(?:\.1)?|6|7)\b/u.test(participantText)) {
      throw new Error(`${participantCode}: participant files reveal a visual version`);
    }
    if (/[—–]/u.test(participantText)) {
      throw new Error(`${participantCode}: participant copy contains a forbidden long dash`);
    }
    const key = answerKey.participants[index];
    if (key.participant_code !== participantCode || key.order.length !== 3) {
      throw new Error(`${participantCode}: answer-key order mismatch`);
    }
    const versionOrder = key.order.map((entry) => entry.version_id);
    seenOrders.add(versionOrder.join(","));
    for (const [position, versionId] of versionOrder.entries()) {
      if (!VERSION_IDS.includes(versionId)) throw new Error(`${participantCode}: unknown version`);
      positionCounts[position][versionId] += 1;
      const candidateId = CANDIDATE_IDS[position];
      if (key.order[position].candidate_id !== candidateId) {
        throw new Error(`${participantCode}: candidate position mismatch`);
      }
      const candidatePath = join(kitRoot, "assets", `${candidateId}.png`);
      if (sha256(await readFile(candidatePath)) !== answerKey.sources[versionId].sha256) {
        throw new Error(`${participantCode}: candidate asset mismatch`);
      }
    }
  }
  if (seenOrders.size !== 6) throw new Error("Candidate orders are not fully counterbalanced");
  for (const counts of positionCounts) {
    for (const versionId of VERSION_IDS) {
      if (counts[versionId] !== 2) throw new Error("Candidate position balance failed");
    }
  }
  return {
    campaignId: manifest.campaign_id,
    participants: manifest.participants.length,
    checksums: checksumEntries.size,
  };
}

export async function createVisualPreferenceCampaign({
  referencePath,
  sources,
  buildCommit,
  outputRoot,
  generatedAt = new Date().toISOString(),
}) {
  assertCommit(buildCommit, "build commit");
  for (const versionId of VERSION_IDS) {
    if (!sources?.[versionId]) throw new Error(`Missing source ${versionId}`);
    assertCommit(sources[versionId].commit, `${versionId} commit`);
  }
  const [reference, ...candidateAssets] = await Promise.all([
    readPng(referencePath, "reference"),
    ...VERSION_IDS.map((versionId) => (
      readPng(sources[versionId].path, versionId, { width: 6144, height: 2048 })
    )),
  ]);
  const assets = Object.fromEntries(
    VERSION_IDS.map((versionId, index) => [versionId, candidateAssets[index]]),
  );
  const campaignId = `visual-preference-${sha256(JSON.stringify({
    buildCommit,
    reference: reference.sha256,
    sources: VERSION_IDS.map((versionId) => assets[versionId].sha256),
  })).slice(0, 16)}`;
  const absoluteOutput = resolve(outputRoot);
  await assertMissing(absoluteOutput);
  const parent = dirname(absoluteOutput);
  await mkdir(parent, { recursive: true });
  const staging = await mkdtemp(join(parent, ".visual-preference-"));
  let renamed = false;
  try {
    await mkdir(join(staging, "facilitator"), { recursive: true });
    await mkdir(join(staging, "participants"), { recursive: true });
    const sourceRecords = Object.fromEntries(VERSION_IDS.map((versionId) => [
      versionId,
      {
        label: versionId === "v5" ? "V5.1" : versionId.toUpperCase(),
        commit: sources[versionId].commit,
        source_path: assets[versionId].source_path,
        bytes: assets[versionId].bytes,
        width: assets[versionId].width,
        height: assets[versionId].height,
        sha256: assets[versionId].sha256,
      },
    ]));
    const answerParticipants = [];
    const participantRecords = [];
    for (const [index, participantCode] of PARTICIPANT_CODES.entries()) {
      const kitRoot = join(staging, "participants", participantCode);
      const assetRoot = join(kitRoot, "assets");
      await mkdir(assetRoot, { recursive: true });
      await writeFile(join(assetRoot, "reference.png"), reference.buffer);
      const order = PREFERENCE_ORDERS[index];
      for (const [position, versionId] of order.entries()) {
        await writeFile(
          join(assetRoot, `${CANDIDATE_IDS[position]}.png`),
          assets[versionId].buffer,
        );
      }
      const kitManifest = {
        schema_version: 1,
        kind: "anonymous-visual-preference-kit",
        privacy: "anonymous-local-only",
        campaign_id: campaignId,
        participant_code: participantCode,
        candidate_order: CANDIDATE_IDS,
        reference_sha256: reference.sha256,
        candidate_sha256: Object.fromEntries(order.map((versionId, position) => [
          CANDIDATE_IDS[position],
          assets[versionId].sha256,
        ])),
        files: EXPECTED_PARTICIPANT_ENTRIES,
      };
      await Promise.all([
        writeFile(
          join(kitRoot, "README.md"),
          renderParticipantReadme({ campaignId, participantCode }),
          "utf8",
        ),
        writeFile(
          join(kitRoot, "index.html"),
          renderParticipantHtml({ campaignId, participantCode }),
          "utf8",
        ),
        writeJson(join(kitRoot, "manifest.json"), kitManifest),
        writeJson(join(kitRoot, "report.json"), templateReport({ campaignId, participantCode })),
      ]);
      answerParticipants.push({
        participant_code: participantCode,
        order: order.map((versionId, position) => ({
          candidate_id: CANDIDATE_IDS[position],
          version_id: versionId,
        })),
      });
      participantRecords.push({
        participant_code: participantCode,
        kit_path: `participants/${participantCode}`,
        candidate_order: CANDIDATE_IDS,
      });
    }
    const answerKey = {
      schema_version: 1,
      privacy: "facilitator-only",
      campaign_id: campaignId,
      sources: sourceRecords,
      participants: answerParticipants,
    };
    const campaignManifest = {
      schema_version: 1,
      kind: "visual-preference-campaign",
      status: "awaiting-human-results",
      privacy: "anonymous-local-only",
      generated_at: generatedAt,
      campaign_id: campaignId,
      exact_v7_candidate_commit: buildCommit,
      reference: {
        source_path: reference.source_path,
        bytes: reference.bytes,
        width: reference.width,
        height: reference.height,
        sha256: reference.sha256,
      },
      sample: {
        minimum_independent_participants: 3,
        recommended_participants: 6,
        order_permutations: 6,
      },
      participants: participantRecords,
      results_included: 0,
    };
    await Promise.all([
      writeFile(join(staging, "README.md"), renderRootReadme({ campaignId }), "utf8"),
      writeJson(join(staging, "campaign-manifest.json"), campaignManifest),
      writeFile(
        join(staging, "facilitator", "README.md"),
        renderFacilitatorReadme({ campaignId, buildCommit }),
        "utf8",
      ),
      writeJson(join(staging, "facilitator", "answer-key.json"), answerKey),
      writeJson(join(staging, "facilitator", "aggregate-template.json"), {
        schema_version: 1,
        status: "awaiting-human-results",
        campaign_id: campaignId,
        completed_reports: 0,
        candidate_picks: Object.fromEntries(VERSION_IDS.map((versionId) => [versionId, 0])),
        result: null,
      }),
    ]);
    await writeChecksums(staging);
    await verifyVisualPreferenceCampaign(staging);
    await assertMissing(absoluteOutput);
    await rename(staging, absoluteOutput);
    renamed = true;
    return {
      campaignId,
      outputRoot: absoluteOutput,
      participants: PARTICIPANT_CODES.length,
      referenceSha256: reference.sha256,
      sourceSha256: Object.fromEntries(
        VERSION_IDS.map((versionId) => [versionId, assets[versionId].sha256]),
      ),
    };
  } finally {
    if (!renamed) await rm(staging, { recursive: true, force: true });
  }
}

function parseArguments(argv) {
  const allowed = new Set([
    "reference",
    "v5",
    "v5-commit",
    "v6",
    "v6-commit",
    "v7",
    "v7-commit",
    "build-commit",
    "out",
    "generated-at",
    "verify",
  ]);
  const result = {};
  for (const raw of argv) {
    const match = /^--([^=]+)=(.*)$/u.exec(raw);
    if (!match || !allowed.has(match[1])) throw new Error(`Unknown visual-campaign argument: ${raw}`);
    if (Object.hasOwn(result, match[1])) throw new Error(`Duplicate visual-campaign argument: --${match[1]}`);
    if (!match[2]) throw new Error(`Visual-campaign argument requires a value: --${match[1]}`);
    result[match[1]] = match[2];
  }
  return result;
}

function assertCliOutput(path) {
  const absolute = resolve(path);
  const local = relative(OUTPUTS_ROOT, absolute);
  if (!local || local === ".." || local.startsWith(`..${sep}`) || isAbsolute(local)) {
    throw new Error("Visual campaign output must be a new directory inside repository outputs/");
  }
  return absolute;
}

async function main() {
  const args = parseArguments(process.argv.slice(2));
  if (args.verify) {
    if (Object.keys(args).length !== 1) throw new Error("--verify cannot be combined with creation arguments");
    const report = await verifyVisualPreferenceCampaign(args.verify);
    console.log(
      `VISUAL_PREFERENCE_CAMPAIGN_VERIFY_OK campaign=${report.campaignId} participants=${report.participants} checksums=${report.checksums}`,
    );
    return;
  }
  const required = [
    "reference",
    "v5",
    "v5-commit",
    "v6",
    "v6-commit",
    "v7",
    "v7-commit",
    "build-commit",
    "out",
  ];
  for (const key of required) {
    if (!args[key]) throw new Error(`Missing required argument --${key}=...`);
  }
  const result = await createVisualPreferenceCampaign({
    referencePath: args.reference,
    sources: {
      v5: { path: args.v5, commit: args["v5-commit"] },
      v6: { path: args.v6, commit: args["v6-commit"] },
      v7: { path: args.v7, commit: args["v7-commit"] },
    },
    buildCommit: args["build-commit"],
    outputRoot: assertCliOutput(args.out),
    generatedAt: args["generated-at"] || new Date().toISOString(),
  });
  console.log(
    `VISUAL_PREFERENCE_CAMPAIGN_OK campaign=${result.campaignId} participants=${result.participants} results=0 out=${result.outputRoot}`,
  );
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
