#!/usr/bin/env node

import { inflateSync } from "node:zlib";
import { readFile, readdir, stat } from "node:fs/promises";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const PNG_SIGNATURE = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
const SCREENSHOT_MINIMUM = 5;
const SCREENSHOT_MIN_WIDTH = 1920;
const SCREENSHOT_MIN_HEIGHT = 1080;
const TARGET_ASPECT = 16 / 9;

export const STEAM_ASSET_SPECS = [
  ["store/header_capsule.png", 920, 430],
  ["store/small_capsule.png", 462, 174],
  ["store/main_capsule.png", 1232, 706],
  ["store/vertical_capsule.png", 748, 896],
  ["library/library_capsule.png", 600, 900],
  ["library/library_hero.png", 3840, 1240],
  ["library/library_logo.png", 1280, 720, "transparent"],
  ["library/library_header.png", 920, 430],
  ["icons/shortcut_icon.png", 256, 256],
  ["icons/app_icon.jpg", 184, 184],
];

function expect(condition, message) {
  if (!condition) throw new Error(message);
}

function paeth(left, up, upperLeft) {
  const estimate = left + up - upperLeft;
  const leftDistance = Math.abs(estimate - left);
  const upDistance = Math.abs(estimate - up);
  const upperLeftDistance = Math.abs(estimate - upperLeft);
  if (leftDistance <= upDistance && leftDistance <= upperLeftDistance) return left;
  if (upDistance <= upperLeftDistance) return up;
  return upperLeft;
}

function decodePngAlpha(buffer, width, height, bitDepth, colorType, interlace) {
  if (bitDepth !== 8 || interlace !== 0 || ![4, 6].includes(colorType)) return null;
  const channels = colorType === 6 ? 4 : 2;
  const rowBytes = width * channels;
  const chunks = [];
  let offset = 8;
  while (offset + 12 <= buffer.length) {
    const length = buffer.readUInt32BE(offset);
    const type = buffer.toString("ascii", offset + 4, offset + 8);
    const dataStart = offset + 8;
    const dataEnd = dataStart + length;
    expect(dataEnd + 4 <= buffer.length, "PNG chunk extends beyond file bounds");
    if (type === "IDAT") chunks.push(buffer.subarray(dataStart, dataEnd));
    offset = dataEnd + 4;
    if (type === "IEND") break;
  }
  expect(chunks.length > 0, "PNG has no IDAT data");
  const inflated = inflateSync(Buffer.concat(chunks));
  expect(inflated.length >= (rowBytes + 1) * height, "PNG pixel payload is truncated");
  let previous = Buffer.alloc(rowBytes);
  let transparent = false;
  let cursor = 0;
  for (let y = 0; y < height; y += 1) {
    const filter = inflated[cursor];
    cursor += 1;
    const raw = inflated.subarray(cursor, cursor + rowBytes);
    cursor += rowBytes;
    const row = Buffer.allocUnsafe(rowBytes);
    for (let x = 0; x < rowBytes; x += 1) {
      const left = x >= channels ? row[x - channels] : 0;
      const up = previous[x] ?? 0;
      const upperLeft = x >= channels ? previous[x - channels] : 0;
      let value;
      if (filter === 0) value = raw[x];
      else if (filter === 1) value = raw[x] + left;
      else if (filter === 2) value = raw[x] + up;
      else if (filter === 3) value = raw[x] + Math.floor((left + up) / 2);
      else if (filter === 4) value = raw[x] + paeth(left, up, upperLeft);
      else throw new Error(`Unsupported PNG filter ${filter}`);
      row[x] = value & 0xff;
    }
    for (let alpha = channels - 1; alpha < rowBytes; alpha += channels) {
      if (row[alpha] < 255) {
        transparent = true;
        break;
      }
    }
    previous = row;
  }
  return transparent;
}

export async function readPngInfo(path, inspectTransparency = false) {
  const buffer = await readFile(path);
  expect(buffer.length >= 33, `PNG is truncated: ${path}`);
  expect(buffer.subarray(0, 8).equals(PNG_SIGNATURE), `Invalid PNG signature: ${path}`);
  expect(buffer.toString("ascii", 12, 16) === "IHDR", `PNG IHDR is missing: ${path}`);
  const width = buffer.readUInt32BE(16);
  const height = buffer.readUInt32BE(20);
  const bitDepth = buffer[24];
  const colorType = buffer[25];
  const interlace = buffer[28];
  const hasAlphaChannel = colorType === 4 || colorType === 6;
  const hasTransparentPixel = inspectTransparency
    ? decodePngAlpha(buffer, width, height, bitDepth, colorType, interlace)
    : null;
  return { width, height, bitDepth, colorType, hasAlphaChannel, hasTransparentPixel };
}

const JPEG_START_OF_FRAME = new Set([
  0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf,
]);

export async function readJpegInfo(path) {
  const buffer = await readFile(path);
  expect(buffer.length >= 4 && buffer[0] === 0xff && buffer[1] === 0xd8, `Invalid JPEG signature: ${path}`);
  let offset = 2;
  while (offset + 3 < buffer.length) {
    while (offset < buffer.length && buffer[offset] === 0xff) offset += 1;
    const marker = buffer[offset];
    offset += 1;
    if (marker === 0xd8 || marker === 0xd9) continue;
    expect(offset + 2 <= buffer.length, `JPEG marker is truncated: ${path}`);
    const length = buffer.readUInt16BE(offset);
    expect(length >= 2 && offset + length <= buffer.length, `JPEG segment is truncated: ${path}`);
    if (JPEG_START_OF_FRAME.has(marker)) {
      expect(length >= 7, `JPEG frame header is truncated: ${path}`);
      return {
        width: buffer.readUInt16BE(offset + 5),
        height: buffer.readUInt16BE(offset + 3),
      };
    }
    offset += length;
  }
  throw new Error(`JPEG dimensions were not found: ${path}`);
}

export async function readIcnsInfo(path) {
  const buffer = await readFile(path);
  expect(buffer.length >= 8 && buffer.toString("ascii", 0, 4) === "icns", `Invalid ICNS signature: ${path}`);
  expect(buffer.readUInt32BE(4) === buffer.length, `ICNS declared size does not match file size: ${path}`);
  return { bytes: buffer.length };
}

async function requireRegularFile(path) {
  const info = await stat(path);
  expect(info.isFile() && info.size > 0, `Steam asset must be a non-empty regular file: ${path}`);
  return info;
}

async function validateSizedAsset(root, spec) {
  const [relativePath, expectedWidth, expectedHeight, requirement] = spec;
  const path = join(root, relativePath);
  await requireRegularFile(path);
  const image = relativePath.endsWith(".jpg")
    ? await readJpegInfo(path)
    : await readPngInfo(path, requirement === "transparent");
  expect(
    image.width === expectedWidth && image.height === expectedHeight,
    `${relativePath} must be ${expectedWidth}x${expectedHeight}; got ${image.width}x${image.height}`,
  );
  if (requirement === "transparent") {
    expect(image.hasAlphaChannel, `${relativePath} must contain an alpha channel`);
    expect(image.hasTransparentPixel === true, `${relativePath} must contain transparent pixels`);
  }
  return { path: relativePath, width: image.width, height: image.height };
}

export async function validateSteamAssets(root = resolve("steam/assets")) {
  const assetRoot = resolve(root);
  const files = [];
  for (const spec of STEAM_ASSET_SPECS) files.push(await validateSizedAsset(assetRoot, spec));
  const iconPath = join(assetRoot, "icons/mac_icon.icns");
  await requireRegularFile(iconPath);
  const icon = await readIcnsInfo(iconPath);
  files.push({ path: "icons/mac_icon.icns", bytes: icon.bytes });

  const screenshotRoot = join(assetRoot, "screenshots");
  const screenshots = (await readdir(screenshotRoot, { withFileTypes: true }))
    .filter((entry) => entry.isFile() && entry.name.toLowerCase().endsWith(".png"))
    .map((entry) => entry.name)
    .sort((a, b) => a.localeCompare(b, "en"));
  expect(
    screenshots.length >= SCREENSHOT_MINIMUM,
    `Steam requires at least ${SCREENSHOT_MINIMUM} gameplay screenshots; found ${screenshots.length}`,
  );
  for (const name of screenshots) {
    const relativePath = `screenshots/${name}`;
    const path = join(screenshotRoot, name);
    await requireRegularFile(path);
    const image = await readPngInfo(path);
    expect(
      image.width >= SCREENSHOT_MIN_WIDTH && image.height >= SCREENSHOT_MIN_HEIGHT,
      `${relativePath} must be at least ${SCREENSHOT_MIN_WIDTH}x${SCREENSHOT_MIN_HEIGHT}; got ${image.width}x${image.height}`,
    );
    expect(
      Math.abs(image.width / image.height - TARGET_ASPECT) < 0.001,
      `${relativePath} must use a 16:9 aspect ratio`,
    );
    files.push({ path: relativePath, width: image.width, height: image.height });
  }
  return {
    schema_version: 1,
    root: assetRoot,
    files,
    screenshot_count: screenshots.length,
    library_logo_transparent: true,
  };
}

function cliRoot(argv) {
  if (argv.length === 0) return resolve("steam/assets");
  if (argv.length === 1 && argv[0].startsWith("--root=")) return resolve(argv[0].slice(7));
  throw new Error("Usage: node tools/validate_steam_assets.mjs [--root=steam/assets]");
}

async function main() {
  const report = await validateSteamAssets(cliRoot(process.argv.slice(2)));
  console.log(
    `STEAM_ASSETS_OK files=${report.files.length} screenshots=${report.screenshot_count} logo_alpha=transparent`,
  );
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
