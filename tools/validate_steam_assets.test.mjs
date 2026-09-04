import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import test from "node:test";

import {
  readIcnsInfo,
  readJpegInfo,
  readPngInfo,
  STEAM_ASSET_SPECS,
  validateSteamAssets,
} from "./validate_steam_assets.mjs";

const ASSET_ROOT = resolve("steam/assets");

test("validates the checked-in Steam graphical asset set", async () => {
  const report = await validateSteamAssets(ASSET_ROOT);
  assert.equal(report.schema_version, 1);
  assert.equal(report.screenshot_count, 6);
  assert.equal(report.library_logo_transparent, true);
  assert.equal(report.files.length, STEAM_ASSET_SPECS.length + 1 + 6);
});

test("reads PNG and JPEG dimensions without image-editor dependencies", async () => {
  const header = await readPngInfo(resolve(ASSET_ROOT, "store/header_capsule.png"));
  const appIcon = await readJpegInfo(resolve(ASSET_ROOT, "icons/app_icon.jpg"));
  assert.deepEqual([header.width, header.height], [920, 430]);
  assert.deepEqual([appIcon.width, appIcon.height], [184, 184]);
});

test("proves the library logo contains real transparency", async () => {
  const logo = await readPngInfo(resolve(ASSET_ROOT, "library/library_logo.png"), true);
  assert.equal(logo.hasAlphaChannel, true);
  assert.equal(logo.hasTransparentPixel, true);
});

test("validates the macOS icon container instead of trusting its extension", async () => {
  const path = resolve(ASSET_ROOT, "icons/mac_icon.icns");
  const icon = await readIcnsInfo(path);
  assert.equal(icon.bytes, (await readFile(path)).length);
  assert.ok(icon.bytes > 100_000);
});
