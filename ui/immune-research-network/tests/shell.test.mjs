import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

test("development shell exposes every stable application region", async () => {
  const html = await readFile(new URL("../index.html", import.meta.url), "utf8");
  for (const id of [
    "resource-bar",
    "research-toolbar",
    "tree-viewport",
    "tree-svg",
    "detail-panel",
    "protocol-dock",
    "minimap",
    "research-list",
    "toast-region"
  ]) {
    assert.match(html, new RegExp(`id=["']${id}["']`));
  }
});
