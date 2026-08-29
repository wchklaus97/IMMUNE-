#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const FILES = [
  join(ROOT, "godot/immune/translations/game.csv"),
  join(ROOT, "godot/immune/translations/research_catalog.csv")
];
const HEADER = ["keys", "zh_HK", "en"];

export function parseCsv(source, file = "translation.csv") {
  const rows = [];
  let row = [];
  let cell = "";
  let quoted = false;
  for (let index = 0; index < source.length; index += 1) {
    const character = source[index];
    if (quoted) {
      if (character === '"' && source[index + 1] === '"') {
        cell += '"';
        index += 1;
      } else if (character === '"') {
        quoted = false;
      } else {
        cell += character;
      }
      continue;
    }
    if (character === '"') {
      if (cell.length > 0) throw new Error(`${file}: quote started inside an unquoted field`);
      quoted = true;
    } else if (character === ",") {
      row.push(cell);
      cell = "";
    } else if (character === "\n") {
      row.push(cell);
      if (row.some((value) => value.length > 0)) rows.push(row);
      row = [];
      cell = "";
    } else if (character !== "\r") {
      cell += character;
    }
  }
  if (quoted) throw new Error(`${file}: unterminated quoted field`);
  if (cell.length > 0 || row.length > 0) {
    row.push(cell);
    rows.push(row);
  }
  return rows;
}

function placeholders(value) {
  return [...String(value).matchAll(/%(?:\.\d+)?[sdf]/g)].map((match) => match[0]).sort();
}

function sameList(left, right) {
  return left.length === right.length && left.every((value, index) => value === right[index]);
}

async function validateFile(path) {
  const source = await readFile(path, "utf8");
  const rows = parseCsv(source, path);
  if (rows.length < 2 || !sameList(rows[0], HEADER)) {
    throw new Error(`${path}: expected header ${HEADER.join(",")}`);
  }
  const seen = new Set();
  for (let index = 1; index < rows.length; index += 1) {
    const row = rows[index];
    const line = index + 1;
    if (row.length !== 3) throw new Error(`${path}:${line}: expected 3 columns, got ${row.length}`);
    const [key, zh, en] = row;
    if (!key.trim() || !zh.trim() || !en.trim()) throw new Error(`${path}:${line}: blank key or translation`);
    if (seen.has(key)) throw new Error(`${path}:${line}: duplicate key ${key}`);
    seen.add(key);
    const zhPlaceholders = placeholders(zh);
    const enPlaceholders = placeholders(en);
    if (!sameList(zhPlaceholders, enPlaceholders)) {
      throw new Error(`${path}:${line}: placeholder mismatch for ${key}: ${zhPlaceholders} vs ${enPlaceholders}`);
    }
    if (/[\u3400-\u9fff]/u.test(en)) throw new Error(`${path}:${line}: English value contains Han text for ${key}`);
  }
  return rows.length - 1;
}

async function main() {
  let total = 0;
  for (const path of FILES) total += await validateFile(path);
  console.log(`TRANSLATION_CSV_OK files=${FILES.length} rows=${total}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
