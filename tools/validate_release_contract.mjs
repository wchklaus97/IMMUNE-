#!/usr/bin/env node

import { readFile, stat } from "node:fs/promises";
import { dirname, isAbsolute, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const PROJECT_RELATIVE = "godot/immune/project.godot";
const PRESETS_RELATIVE = "godot/immune/export_presets.cfg";
const EXPECTED_EXPORTS = [
  ["IMMUNE-windows.exe", 1_000_000],
  ["IMMUNE-windows.pck", 1_000_000],
  ["IMMUNE-linux.x86_64", 1_000_000],
  ["IMMUNE-linux.pck", 1_000_000],
  ["IMMUNE-macOS.zip", 1_000_000],
  ["web/index.html", 1_000],
  ["web/index.js", 10_000],
  ["web/index.pck", 1_000_000],
  ["web/index.wasm", 1_000_000],
  ["web/index.audio.worklet.js", 1_000],
  ["web/index.audio.position.worklet.js", 1_000],
];

export function parseConfig(source, file = "config") {
  const sections = new Map();
  let section = "";
  sections.set(section, {});
  for (const [index, rawLine] of source.split(/\r?\n/u).entries()) {
    const line = rawLine.trim();
    if (!line || line.startsWith(";") || line.startsWith("#")) continue;
    if (line.startsWith("[") && line.endsWith("]")) {
      section = line.slice(1, -1);
      if (sections.has(section)) throw new Error(`${file}:${index + 1}: duplicate section [${section}]`);
      sections.set(section, {});
      continue;
    }
    const split = line.indexOf("=");
    if (split < 1) continue;
    const key = line.slice(0, split).trim();
    const rawValue = line.slice(split + 1).trim();
    let value = rawValue;
    if (rawValue.startsWith('"') && rawValue.endsWith('"')) {
      try {
        value = JSON.parse(rawValue);
      } catch {
        throw new Error(`${file}:${index + 1}: invalid quoted value for ${key}`);
      }
    } else if (rawValue === "true" || rawValue === "false") {
      value = rawValue === "true";
    } else if (/^-?\d+$/u.test(rawValue)) {
      value = Number(rawValue);
    }
    sections.get(section)[key] = value;
  }
  return sections;
}

function expect(errors, actual, expected, label) {
  if (actual !== expected) errors.push(`${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
}

function expectText(errors, value, label) {
  if (typeof value !== "string" || !value.trim()) errors.push(`${label}: expected a non-empty string`);
}

function presetByName(sections, name) {
  for (const [section, values] of sections) {
    if (/^preset\.\d+$/u.test(section) && values.name === name) {
      return { base: values, options: sections.get(`${section}.options`) ?? {} };
    }
  }
  return null;
}

function projectResourcePath(root, resourcePath) {
  if (typeof resourcePath !== "string" || !resourcePath.startsWith("res://")) return "";
  return join(root, "godot/immune", resourcePath.slice("res://".length));
}

async function validateArtifactSet(errors, artifactRoot) {
  for (const [relative, minimumBytes] of EXPECTED_EXPORTS) {
    const target = join(artifactRoot, relative);
    try {
      const info = await stat(target);
      if (!info.isFile() || info.size < minimumBytes) {
        errors.push(`artifact ${relative}: expected a file of at least ${minimumBytes} bytes`);
      }
    } catch {
      errors.push(`artifact ${relative}: missing`);
    }
  }
  try {
    const html = await readFile(join(artifactRoot, "web/index.html"), "utf8");
    if (!html.includes("index.js")) errors.push("artifact web/index.html: does not reference index.js");
  } catch {
    // The missing-file error above is more useful.
  }
}

export async function validateReleaseContract({ root = ROOT, tag = "", artifacts = "" } = {}) {
  const projectPath = join(root, PROJECT_RELATIVE);
  const presetsPath = join(root, PRESETS_RELATIVE);
  const [projectSource, presetsSource] = await Promise.all([
    readFile(projectPath, "utf8"),
    readFile(presetsPath, "utf8"),
  ]);
  const project = parseConfig(projectSource, projectPath);
  const presets = parseConfig(presetsSource, presetsPath);
  const app = project.get("application") ?? {};
  const rendering = project.get("rendering") ?? {};
  const errors = [];

  const name = app["config/name"];
  const version = app["config/version"];
  const icon = app["config/icon"];
  expectText(errors, name, "project application/config/name");
  if (typeof version !== "string" || !/^\d+\.\d+\.\d+$/u.test(version)) {
    errors.push(`project application/config/version: expected numeric SemVer, got ${JSON.stringify(version)}`);
  }
  expect(errors, rendering["renderer/rendering_method"], "gl_compatibility", "project renderer");
  expectText(errors, icon, "project application/config/icon");
  if (icon) {
    const iconPath = projectResourcePath(root, icon);
    try {
      const info = await stat(iconPath);
      if (!info.isFile() || info.size < 1_000) errors.push(`project icon: invalid file ${iconPath}`);
    } catch {
      errors.push(`project icon: missing ${iconPath}`);
    }
  }

  const windows = presetByName(presets, "Windows Desktop");
  const linux = presetByName(presets, "Linux/X11");
  const web = presetByName(presets, "Web");
  const mac = presetByName(presets, "macOS");
  for (const [label, preset] of [["Windows Desktop", windows], ["Linux/X11", linux], ["Web", web], ["macOS", mac]]) {
    if (!preset) errors.push(`export preset ${label}: missing`);
  }

  if (windows) {
    expect(errors, windows.base.platform, "Windows Desktop", "Windows platform");
    expect(errors, windows.base.export_path, "build/releases/IMMUNE-windows.exe", "Windows export path");
    expect(errors, windows.options["binary_format/architecture"], "x86_64", "Windows architecture");
    expect(errors, windows.options["application/modify_resources"], true, "Windows resource metadata");
    expect(errors, windows.options["application/product_name"], name, "Windows product name");
    expectText(errors, windows.options["application/company_name"], "Windows company name");
    expectText(errors, windows.options["application/file_description"], "Windows file description");
    expect(errors, windows.options["application/file_version"], version, "Windows file version");
    expect(errors, windows.options["application/product_version"], version, "Windows product version");
    expect(errors, windows.options["application/icon"], icon, "Windows icon");
  }
  if (linux) {
    expect(errors, linux.base.platform, "Linux", "Linux platform");
    expect(errors, linux.base.export_path, "build/releases/IMMUNE-linux.x86_64", "Linux export path");
    expect(errors, linux.options["binary_format/architecture"], "x86_64", "Linux architecture");
  }
  if (web) {
    expect(errors, web.base.platform, "Web", "Web platform");
    expect(errors, web.base.export_path, "build/releases/web/index.html", "Web export path");
    expect(errors, web.options["variant/thread_support"], false, "Web thread support");
    expect(errors, web.options["variant/extensions_support"], false, "Web extension support");
  }
  let macSigning = "unknown";
  if (mac) {
    expect(errors, mac.base.platform, "macOS", "macOS platform");
    expect(errors, mac.base.export_path, "build/releases/IMMUNE-macOS.zip", "macOS export path");
    expect(errors, mac.options["binary_format/architecture"], "universal", "macOS architecture");
    expect(errors, mac.options["application/short_version"], version, "macOS short version");
    expect(errors, mac.options["application/version"], version, "macOS build version");
    expect(errors, mac.options["application/icon"], icon, "macOS icon");
    const bundle = mac.options["application/bundle_identifier"];
    if (typeof bundle !== "string" || !/^[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$/u.test(bundle)) {
      errors.push(`macOS bundle identifier: invalid ${JSON.stringify(bundle)}`);
    }
    macSigning = mac.options["codesign/codesign"] === 1 && mac.options["codesign/identity"] === "-" ? "adhoc" : "configured";
  }

  for (const [section, values] of presets) {
    if (!/\.options$/u.test(section)) continue;
    for (const [key, value] of Object.entries(values)) {
      if (/(?:password|api_key|certificate_file|provisioning_profile)$/iu.test(key) && String(value).trim()) {
        errors.push(`${section} ${key}: release secrets and credential paths must come from environment variables`);
      }
    }
  }

  if (tag) expect(errors, tag, `v${version}`, "release tag");
  if (artifacts) {
    const artifactRoot = isAbsolute(artifacts) ? artifacts : resolve(root, artifacts);
    await validateArtifactSet(errors, artifactRoot);
  }
  if (errors.length) throw new Error(`RELEASE_CONTRACT_FAILED\n- ${errors.join("\n- ")}`);
  return {
    version,
    presetCount: [windows, linux, web, mac].filter(Boolean).length,
    icon,
    webMode: "single-threaded",
    macSigning,
    artifacts: artifacts ? "verified" : "not-requested",
    tag: tag || "unpublished",
  };
}

function argument(name) {
  const prefix = `--${name}=`;
  const match = process.argv.slice(2).find((value) => value.startsWith(prefix));
  return match ? match.slice(prefix.length) : "";
}

async function main() {
  const report = await validateReleaseContract({ tag: argument("tag"), artifacts: argument("artifacts") });
  console.log(`RELEASE_CONTRACT_OK version=${report.version} presets=${report.presetCount} icon=${report.icon} web=${report.webMode} mac_signing=${report.macSigning} artifacts=${report.artifacts} tag=${report.tag}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
