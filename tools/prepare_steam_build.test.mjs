import assert from "node:assert/strict";
import { mkdtemp, mkdir, readFile, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  requiredSteamAssets,
  renderSteamVdfs,
  stagingArguments,
  stageSteamBuild,
  validateSteamConfig,
} from "./prepare_steam_build.mjs";

const VALID_CONFIG = {
  appId: "4800000",
  depots: {
    windows: "4800001",
    linux: "4800002",
    macos: "4800003",
  },
};

test("staging CLI rejects unknown, empty, and duplicate inputs", () => {
  assert.throws(() => stagingArguments(["--password=secret"]), /Unknown/u);
  assert.throws(() => stagingArguments(["--out="]), /requires a value/u);
  assert.throws(() => stagingArguments(["--app-id=4800000", "--app-id=4800001"]), /Duplicate/u);
});

test("rejects placeholder or ambiguous Steam identifiers before staging", () => {
  assert.throws(
    () => validateSteamConfig({ ...VALID_CONFIG, appId: "YOUR_APP_ID" }),
    /App ID|placeholder/u,
  );
  assert.throws(
    () => validateSteamConfig({ ...VALID_CONFIG, depots: { ...VALID_CONFIG.depots, linux: "4800001" } }),
    /unique/u,
  );
});

test("renders explicit app/depot VDFs without credentials or source-tree paths", () => {
  const rendered = renderSteamVdfs(VALID_CONFIG);
  assert.match(rendered.appBuild, /"appid"\s+"4800000"/u);
  assert.match(rendered.appBuild, /depot_build_4800001\.vdf/u);
  assert.match(rendered.depots.windows, /"DepotID"\s+"4800001"/u);
  assert.doesNotMatch(JSON.stringify(rendered), /password|YOUR_|\/Users\//iu);
});

test("stages deterministic Windows and Linux depots with a checksummed manifest", async () => {
  const fixture = await mkdtemp(join(tmpdir(), "immune-steam-fixture-"));
  const artifacts = join(fixture, "artifacts");
  const output = join(fixture, "stage");
  await mkdir(artifacts, { recursive: true });
  await Promise.all([
    writeFile(join(artifacts, "IMMUNE-windows.exe"), "windows-binary"),
    writeFile(join(artifacts, "IMMUNE-windows.pck"), "windows-pack"),
    writeFile(join(artifacts, "IMMUNE-linux.x86_64"), "linux-binary"),
    writeFile(join(artifacts, "IMMUNE-linux.pck"), "linux-pack"),
  ]);

  const report = await stageSteamBuild({
    artifacts,
    output,
    config: VALID_CONFIG,
    platforms: ["windows", "linux"],
  });
  assert.equal(report.schema_version, 2);
  assert.deepEqual(report.platforms, ["linux", "windows"]);
  assert.deepEqual(report.license_files, [
    "THIRD_PARTY_NOTICES.txt",
    "GODOT_COPYRIGHT.txt",
    "NotoSansHK-OFL.txt",
  ]);
  assert.equal(report.files.length, 10);
  assert.ok(report.files.every((entry) => /^[a-f0-9]{64}$/u.test(entry.sha256)));
  assert.equal((await stat(join(output, "content/windows/IMMUNE-windows.exe"))).isFile(), true);
  assert.equal((await stat(join(output, "content/linux/IMMUNE-linux.x86_64"))).isFile(), true);
  assert.equal((await stat(join(output, "content/windows/THIRD_PARTY_NOTICES.txt"))).isFile(), true);
  assert.equal((await stat(join(output, "content/linux/GODOT_COPYRIGHT.txt"))).isFile(), true);
  assert.match(await readFile(join(output, "scripts/app_build_4800000.vdf"), "utf8"), /4800002/u);
  assert.deepEqual(JSON.parse(await readFile(join(output, "steam-stage-manifest.json"), "utf8")), report);
});

test("fails closed when a required platform sidecar is missing", async () => {
  const fixture = await mkdtemp(join(tmpdir(), "immune-steam-missing-"));
  const artifacts = join(fixture, "artifacts");
  const output = join(fixture, "stage");
  await mkdir(artifacts, { recursive: true });
  await writeFile(join(artifacts, "IMMUNE-windows.exe"), "windows-binary");
  await assert.rejects(
    stageSteamBuild({ artifacts, output, config: VALID_CONFIG, platforms: ["windows"] }),
    /IMMUNE-windows\.pck/u,
  );
  await assert.rejects(stat(output), { code: "ENOENT" });
});

test("locks the current required Steam graphical-asset inventory", () => {
  const assets = requiredSteamAssets();
  assert.deepEqual(assets.store.filter(({ id }) => id !== "screenshots").map(({ width, height }) => [width, height]), [
    [920, 430],
    [462, 174],
    [1232, 706],
    [748, 896],
  ]);
  assert.ok(assets.store.some((asset) => asset.id === "screenshots" && asset.minimum === 5));
  assert.ok(assets.library.some((asset) => asset.id === "library_hero" && asset.width === 3840 && asset.height === 1240));
  assert.ok(assets.icons.some((asset) => asset.id === "mac_icon" && asset.format === "icns"));
});
