#!/usr/bin/env node

import { mkdir, readFile, stat, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { HUMAN_PLAYTEST_FAMILIES, HUMAN_PLAYTEST_RATING_KEYS } from "./validate_human_playtest.mjs";

const ROOT = resolve(fileURLToPath(new URL(".", import.meta.url)), "..");
const DEFAULT_OUTPUT_ROOT = resolve(ROOT, "outputs/human-playtest-kits");

function assertKitOptions({ participantCode, buildVersion, buildCommit }) {
  if (typeof participantCode !== "string" || !/^tester-[a-z0-9]{2,16}$/u.test(participantCode)) {
    throw new Error("participant: expected an anonymous tester- code");
  }
  if (typeof buildVersion !== "string" || !/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/u.test(buildVersion)) {
    throw new Error("build version: expected SemVer");
  }
  if (typeof buildCommit !== "string" || !/^[0-9a-f]{7,40}$/u.test(buildCommit)) {
    throw new Error("build commit: expected the exact 7..40 character lowercase Git commit used to build the artifact");
  }
}

function stableHash(value) {
  let hash = 2166136261;
  for (const character of value) {
    hash ^= character.codePointAt(0);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

export function familyOrderForParticipant(participantCode) {
  const suffix = participantCode.replace(/^tester-/u, "");
  const numeric = /^\d+$/u.test(suffix) ? Number.parseInt(suffix, 10) - 1 : Number.NaN;
  const offset = Number.isSafeInteger(numeric)
    ? ((numeric % HUMAN_PLAYTEST_FAMILIES.length) + HUMAN_PLAYTEST_FAMILIES.length) % HUMAN_PLAYTEST_FAMILIES.length
    : stableHash(participantCode) % HUMAN_PLAYTEST_FAMILIES.length;
  return [
    ...HUMAN_PLAYTEST_FAMILIES.slice(offset),
    ...HUMAN_PLAYTEST_FAMILIES.slice(0, offset),
  ];
}

function blankRatings() {
  return Object.fromEntries(HUMAN_PLAYTEST_RATING_KEYS.map((key) => [key, 0]));
}

function blankSession(family) {
  return {
    family,
    mission: "MISSION-01",
    completion: "not_started",
    minutes: 0,
    duty_switch_used: false,
    ratings: blankRatings(),
    strongest_moment: "",
    biggest_confusion: "",
    visual_notes: "",
    control_notes: "",
    bugs: [],
  };
}

function buildReport({ participantCode, buildVersion, buildCommit }) {
  return {
    schema_version: 1,
    status: "template",
    privacy: "anonymous-local-only",
    build: { version: buildVersion, commit: buildCommit },
    tester: {
      participant_code: participantCode,
      age_18_or_over: null,
      platform: "",
      device: "",
      gpu: "",
      input: "",
      locale: "",
    },
    sessions: familyOrderForParticipant(participantCode).map(blankSession),
    summary: {
      most_distinct_family: "",
      least_distinct_family: "",
      replay_intent_1_to_5: 0,
      top_priority_change: "",
    },
  };
}

function jsonForHtml(value) {
  return JSON.stringify(value).replaceAll("<", "\\u003c");
}

function renderOfflineForm(report) {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" href="data:,">
  <title>IMMUNE six-family playtest</title>
  <style>
    :root {
      color-scheme: light dark;
      --page: #eef5f6;
      --surface: #f8fbfc;
      --surface-alt: #e3eff1;
      --text: #14282d;
      --muted: #465f65;
      --border: #9ab0b5;
      --accent: #0b6670;
      --accent-text: #f5fbfc;
      --danger: #a63232;
      --focus: #0b6670;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --page: #081418;
        --surface: #102328;
        --surface-alt: #173239;
        --text: #e8f3f5;
        --muted: #acc1c5;
        --border: #4d6970;
        --accent: #67c8d2;
        --accent-text: #082126;
        --danger: #ff9b94;
        --focus: #8ddbe3;
      }
    }
    * { box-sizing: border-box; }
    body {
      min-height: 100dvh;
      margin: 0;
      background: var(--page);
      color: var(--text);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.5;
    }
    main { width: min(1080px, calc(100% - 32px)); margin: 0 auto; padding: 40px 0 72px; }
    header { max-width: 760px; margin-bottom: 28px; }
    h1 { margin: 0 0 10px; font-size: clamp(2rem, 5vw, 3.4rem); line-height: 1.02; letter-spacing: -0.04em; }
    h2 { margin: 0 0 8px; font-size: 1.35rem; }
    h3 { margin: 0; font-size: 1.1rem; }
    p { margin: 0 0 10px; max-width: 68ch; }
    .quiet { color: var(--muted); }
    .notice, .panel, fieldset {
      border: 1px solid var(--border);
      border-radius: 10px;
      background: var(--surface);
    }
    .notice { padding: 16px 18px; margin: 20px 0; }
    .panel { padding: 22px; margin: 18px 0; }
    .facts, .grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
    .facts { grid-template-columns: repeat(3, minmax(0, 1fr)); margin-top: 18px; }
    .fact { padding: 14px; background: var(--surface-alt); border-radius: 10px; overflow-wrap: anywhere; }
    .fact strong { display: block; font-size: .8rem; color: var(--muted); margin-bottom: 4px; }
    label { display: grid; gap: 7px; font-weight: 650; }
    label small { color: var(--muted); font-weight: 450; }
    input, select, textarea, button {
      min-height: 44px;
      border: 1px solid var(--border);
      border-radius: 10px;
      font: inherit;
    }
    input, select, textarea { width: 100%; padding: 10px 12px; background: var(--page); color: var(--text); }
    textarea { min-height: 96px; resize: vertical; }
    input:focus-visible, select:focus-visible, textarea:focus-visible, button:focus-visible, summary:focus-visible {
      outline: 3px solid var(--focus);
      outline-offset: 2px;
    }
    .check { display: flex; align-items: flex-start; gap: 10px; font-weight: 600; }
    .check input { width: 20px; min-height: 20px; margin-top: 2px; }
    .sessions { display: grid; gap: 14px; }
    details { border: 1px solid var(--border); border-radius: 10px; background: var(--surface); }
    summary { cursor: pointer; padding: 17px 20px; font-weight: 750; }
    details[open] summary { border-bottom: 1px solid var(--border); }
    fieldset { margin: 0; padding: 20px; border: 0; background: transparent; }
    legend { padding: 0; font-weight: 750; }
    .rating-grid { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 10px; margin: 16px 0; }
    .actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 22px; }
    button { padding: 10px 18px; background: var(--surface-alt); color: var(--text); font-weight: 750; cursor: pointer; }
    button.primary { background: var(--accent); color: var(--accent-text); border-color: var(--accent); }
    button:active { transform: translateY(1px); }
    .error { display: none; margin-top: 16px; padding: 14px; border: 1px solid var(--danger); border-radius: 10px; color: var(--danger); }
    .error.visible { display: block; }
    footer { margin-top: 30px; color: var(--muted); }
    @media (max-width: 760px) {
      main { width: min(100% - 24px, 680px); padding-top: 24px; }
      .grid, .facts, .rating-grid { grid-template-columns: 1fr; }
      .panel, fieldset { padding: 16px; }
      .actions button { width: 100%; }
    }
  </style>
</head>
<body>
  <main>
    <header>
      <h1>IMMUNE six-family playtest</h1>
      <p>Play MISSION-01 with every family in the assigned order, then export one anonymous local report.</p>
      <p class="quiet">依照指定次序用六個家族完成 MISSION-01，然後匯出一份匿名本機報告。</p>
    </header>

    <section class="notice" aria-labelledby="privacy-title">
      <h2 id="privacy-title">Private by design / 私隱優先</h2>
      <p><strong>No network requests / 不會傳送網絡請求。</strong> This page does not upload, track, or auto-save any answer.</p>
      <p class="quiet">Do not enter names, email addresses, phone numbers, account names, or contact details.</p>
    </section>

    <section class="panel" aria-labelledby="build-title">
      <h2 id="build-title">Assigned build / 指定版本</h2>
      <div class="facts">
        <div class="fact"><strong>Participant code</strong><span id="participant-fact"></span></div>
        <div class="fact"><strong>Version</strong><span id="version-fact"></span></div>
        <div class="fact"><strong>Build commit</strong><span id="commit-fact"></span></div>
      </div>
    </section>

    <form id="playtest-form" novalidate>
      <section class="panel" aria-labelledby="setup-title">
        <h2 id="setup-title">Anonymous setup / 匿名裝置資料</h2>
        <div class="grid">
          <label>Platform / 平台<input name="platform" required autocomplete="off" placeholder="Windows 11"></label>
          <label>Device class / 裝置類型<input name="device" required autocomplete="off" placeholder="Desktop with integrated graphics"></label>
          <label>GPU class / 顯示晶片<input name="gpu" required autocomplete="off" placeholder="Integrated GPU"></label>
          <label>Input / 輸入方式<select name="input" required><option value="">Select / 選擇</option><option value="keyboard-mouse">Keyboard and mouse</option><option value="controller">Controller</option><option value="touch">Touch</option></select></label>
          <label>Game locale / 遊戲語言<select name="locale" required><option value="">Select / 選擇</option><option value="zh_HK">繁體中文</option><option value="en">English</option></select></label>
        </div>
        <p style="margin-top:16px"><label class="check"><input type="checkbox" name="age_18_or_over" required> I confirm I am 18 or older / 我確認已年滿 18 歲</label></p>
      </section>

      <section aria-labelledby="sessions-title">
        <h2 id="sessions-title">Family sessions / 家族測試</h2>
        <p class="quiet">Use the order below. Try both duty forms where available. Save a draft whenever you need a break.</p>
        <div id="sessions" class="sessions"></div>
      </section>

      <section class="panel" aria-labelledby="summary-title">
        <h2 id="summary-title">Cross-family summary / 跨家族總結</h2>
        <div class="grid">
          <label>Most distinct family / 最鮮明家族<select name="most_distinct_family" required data-family-options></select></label>
          <label>Least distinct family / 最不鮮明家族<select name="least_distinct_family" required data-family-options></select></label>
          <label>Replay intent, 1 to 5 / 重玩意欲<select name="replay_intent" required data-rating-options></select></label>
          <label>Top priority change / 最優先改善<textarea name="top_priority_change" required></textarea></label>
        </div>
      </section>

      <div class="actions">
        <button type="button" id="draft-button">Download draft / 下載草稿</button>
        <button type="button" class="primary" id="complete-button">Export completed report / 匯出完整報告</button>
      </div>
      <div id="form-error" class="error" role="alert" tabindex="-1"></div>
    </form>

    <footer>Keep the downloaded JSON local and give it only to the playtest facilitator.</footer>
  </main>
  <script type="application/json" id="initial-report">${jsonForHtml(report)}</script>
  <script>
    const initial = JSON.parse(document.getElementById("initial-report").textContent);
    const form = document.getElementById("playtest-form");
    const errorBox = document.getElementById("form-error");
    const ratingKeys = ${jsonForHtml(HUMAN_PLAYTEST_RATING_KEYS)};
    const ratingLabels = {
      controls: "Controls / 操作",
      combat_readability: "Combat readability / 戰鬥可讀性",
      family_role_clarity: "Family role clarity / 家族定位",
      jelly_visual_clarity: "Jelly visual clarity / 啫喱視覺",
      game_feel: "Game feel / 操作手感"
    };
    const familyOptionHtml = '<option value="">Select / 選擇</option>' + initial.sessions.map((session) => '<option value="' + session.family + '">' + session.family + ' family</option>').join("");
    const ratingOptionHtml = '<option value="">Select / 選擇</option>' + [1, 2, 3, 4, 5].map((value) => '<option value="' + value + '">' + value + '</option>').join("");

    document.getElementById("participant-fact").textContent = initial.tester.participant_code;
    document.getElementById("version-fact").textContent = initial.build.version;
    document.getElementById("commit-fact").textContent = initial.build.commit;
    document.querySelectorAll("[data-family-options]").forEach((select) => { select.innerHTML = familyOptionHtml; });
    document.querySelectorAll("[data-rating-options]").forEach((select) => { select.innerHTML = ratingOptionHtml; });

    document.getElementById("sessions").innerHTML = initial.sessions.map((session, index) => {
      const ratings = ratingKeys.map((key) => '<label>' + ratingLabels[key] + '<select required name="session_' + index + '_rating_' + key + '">' + ratingOptionHtml + '</select></label>').join("");
      return '<details' + (index === 0 ? ' open' : '') + '><summary>' + (index + 1) + '. ' + session.family + ' family, MISSION-01</summary><fieldset><legend>' + session.family + ' family notes / 家族記錄</legend><div class="grid"><label>Completion / 結果<select required name="session_' + index + '_completion"><option value="">Select / 選擇</option><option value="victory">Victory</option><option value="defeat">Defeat</option><option value="abandoned">Abandoned</option></select></label><label>Minutes / 分鐘<input required type="number" min="0.1" step="0.1" name="session_' + index + '_minutes"></label></div><p><label class="check"><input type="checkbox" name="session_' + index + '_duty"> I used the duty switch / 我有切換職責</label></p><div class="rating-grid">' + ratings + '</div><div class="grid"><label>Strongest moment / 最好時刻<textarea required name="session_' + index + '_strongest"></textarea></label><label>Biggest confusion / 最大疑惑<textarea required name="session_' + index + '_confusion"></textarea></label><label>Visual notes / 視覺意見<textarea required name="session_' + index + '_visual"></textarea></label><label>Control notes / 操作意見<textarea required name="session_' + index + '_control"></textarea></label></div><label style="margin-top:16px">Bugs, one per line / 問題每行一項<textarea name="session_' + index + '_bugs"></textarea><small>No names or contact details / 不要填寫姓名或聯絡資料</small></label></fieldset></details>';
    }).join("");

    function field(name) { return form.elements.namedItem(name); }
    function value(name) { return String(field(name)?.value ?? "").trim(); }
    function checked(name) { return Boolean(field(name)?.checked); }
    function buildReport(complete) {
      const report = structuredClone(initial);
      report.status = complete ? "complete" : "template";
      report.tester = {
        ...report.tester,
        age_18_or_over: complete ? checked("age_18_or_over") : (checked("age_18_or_over") ? true : null),
        platform: value("platform"),
        device: value("device"),
        gpu: value("gpu"),
        input: value("input"),
        locale: value("locale")
      };
      report.sessions = initial.sessions.map((session, index) => ({
        ...session,
        completion: value("session_" + index + "_completion") || "not_started",
        minutes: Number(value("session_" + index + "_minutes")) || 0,
        duty_switch_used: checked("session_" + index + "_duty"),
        ratings: Object.fromEntries(ratingKeys.map((key) => [key, Number(value("session_" + index + "_rating_" + key)) || 0])),
        strongest_moment: value("session_" + index + "_strongest"),
        biggest_confusion: value("session_" + index + "_confusion"),
        visual_notes: value("session_" + index + "_visual"),
        control_notes: value("session_" + index + "_control"),
        bugs: value("session_" + index + "_bugs").split(/\\r?\\n/u).map((entry) => entry.trim()).filter(Boolean)
      }));
      report.summary = {
        most_distinct_family: value("most_distinct_family"),
        least_distinct_family: value("least_distinct_family"),
        replay_intent_1_to_5: Number(value("replay_intent")) || 0,
        top_priority_change: value("top_priority_change")
      };
      return report;
    }
    function containsEmail(report) {
      return /\\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\b/iu.test(JSON.stringify(report));
    }
    function download(report, suffix) {
      const blob = new Blob([JSON.stringify(report, null, 2) + "\\n"], { type: "application/json" });
      const anchor = document.createElement("a");
      anchor.href = URL.createObjectURL(blob);
      anchor.download = initial.tester.participant_code + "-six-family-playtest-" + suffix + ".json";
      anchor.click();
      URL.revokeObjectURL(anchor.href);
    }
    function showError(message) {
      errorBox.textContent = message;
      errorBox.classList.add("visible");
      errorBox.focus();
    }
    document.getElementById("draft-button").addEventListener("click", () => {
      errorBox.classList.remove("visible");
      download(buildReport(false), "draft");
    });
    document.getElementById("complete-button").addEventListener("click", () => {
      errorBox.classList.remove("visible");
      if (!form.reportValidity()) {
        showError("Complete every required field before export / 請先完成所有必填欄位");
        return;
      }
      const report = buildReport(true);
      if (containsEmail(report)) {
        showError("Remove email addresses and other contact details before export / 匯出前請移除電郵及聯絡資料");
        return;
      }
      download(report, "complete");
    });
  </script>
</body>
</html>
`;
}

function renderReadme({ participantCode, buildVersion, buildCommit, familyOrder }) {
  return `# IMMUNE six-family playtest kit

This kit is assigned to anonymous code \`${participantCode}\`.

## Exact build

- Version: \`${buildVersion}\`
- Commit: \`${buildCommit}\`
- Mission: \`MISSION-01\`
- Family order: ${familyOrder.join(", ")}

Use only an artifact built from the exact commit above. Do not replace it with a newer checkout.

## Tester flow

1. Open the game artifact and \`index.html\` from this kit.
2. Play MISSION-01 once per family in the assigned order.
3. Try the duty switch where available.
4. Complete each family section after playing it.
5. Use Download draft before a break.
6. Use Export completed report after all six sessions.

Do not enter names, email addresses, phone numbers, account names, or contact details. The form makes no network requests and does not auto-save.

## Facilitator validation

From the repository root:

\`\`\`sh
node tools/validate_human_playtest.mjs /path/to/${participantCode}-six-family-playtest-complete.json
\`\`\`

Keep raw participant JSON under an ignored local \`outputs/\` directory. Do not commit it.
`;
}

export function createHumanPlaytestKit({ participantCode, buildVersion, buildCommit, generatedAt = new Date().toISOString() }) {
  assertKitOptions({ participantCode, buildVersion, buildCommit });
  const report = buildReport({ participantCode, buildVersion, buildCommit });
  const familyOrder = report.sessions.map((session) => session.family);
  const manifest = {
    schema_version: 1,
    kind: "human-playtest-session-kit",
    privacy: "anonymous-local-only",
    generated_at: generatedAt,
    participant_code: participantCode,
    build: { version: buildVersion, commit: buildCommit },
    mission: "MISSION-01",
    family_order: familyOrder,
    files: ["README.md", "index.html", "manifest.json", "report.json"],
  };
  return {
    report,
    manifest,
    html: renderOfflineForm(report),
    readme: renderReadme({ participantCode, buildVersion, buildCommit, familyOrder }),
  };
}

function argument(name, fallback = "") {
  const prefix = `--${name}=`;
  const match = process.argv.slice(2).find((entry) => entry.startsWith(prefix));
  return match ? match.slice(prefix.length) : fallback;
}

async function projectVersion() {
  const source = await readFile(resolve(ROOT, "godot/immune/project.godot"), "utf8");
  const match = source.match(/^config\/version="([^"]+)"$/mu);
  if (!match) throw new Error("project.godot config/version is missing");
  return match[1];
}

async function writeKit(outputRoot, kit) {
  try {
    await stat(outputRoot);
    throw new Error(`Output already exists; refusing to overwrite participant data: ${outputRoot}`);
  } catch (error) {
    if (error?.code !== "ENOENT") throw error;
  }
  await mkdir(outputRoot, { recursive: true });
  await Promise.all([
    writeFile(resolve(outputRoot, "README.md"), kit.readme),
    writeFile(resolve(outputRoot, "index.html"), kit.html),
    writeFile(resolve(outputRoot, "manifest.json"), `${JSON.stringify(kit.manifest, null, 2)}\n`),
    writeFile(resolve(outputRoot, "report.json"), `${JSON.stringify(kit.report, null, 2)}\n`),
  ]);
}

async function main() {
  const participantCode = argument("participant");
  const buildCommit = argument("build-commit");
  const buildVersion = argument("build-version", await projectVersion());
  const outputRoot = resolve(argument("out", resolve(DEFAULT_OUTPUT_ROOT, participantCode || "missing-participant")));
  const kit = createHumanPlaytestKit({ participantCode, buildVersion, buildCommit });
  await writeKit(outputRoot, kit);
  console.log(`HUMAN_PLAYTEST_KIT_OK participant=${participantCode} order=${kit.manifest.family_order.join(",")} out=${outputRoot}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
