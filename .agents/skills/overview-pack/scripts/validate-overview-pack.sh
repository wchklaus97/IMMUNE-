#!/usr/bin/env bash
# Validation for overview-pack. Paths come from .agents/project.env
# (example host: Emoji Cube Match 3D). Does not start a server.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
# shellcheck source=load-project.sh
source .agents/skills/overview-pack/scripts/load-project.sh

fail=0
need() {
  local f="$1"
  if [[ ! -s "$f" ]]; then
    echo "MISSING  $f"
    fail=1
  else
    echo "ok       $f"
  fi
}

has() {
  local file="$1" needle="$2"
  if ! grep -q "$needle" "$file"; then
    echo "MISSING  $needle  in $file"
    fail=1
  fi
}

echo "== overview-pack: covers ($GAME_TITLE) =="
bash .agents/skills/overview-pack/scripts/check-covers.sh

echo "== overview-pack: HTML structure =="
IFS=',' read -r -a shots <<< "$SHOT_IDS"
for html in "$MANAGER_HTML" "$MANAGER_HTML_ZH"; do
  [[ -n "$html" ]] || continue
  need "$html"
  for id in "${shots[@]}"; do
    id="${id// /}"
    [[ -n "$id" ]] || continue
    has "$html" "data-shot=\"$id\""
  done
  has "$html" "$(basename "$COVER_3X4")"
  has "$html" "$(basename "$COVER_16X9")"
done

IFS=',' read -r -a markers <<< "$UX_MARKERS"
for html in "$UX_HTML" "$UX_HTML_ZH"; do
  [[ -n "$html" ]] || continue
  need "$html"
  for m in "${markers[@]}"; do
    m="${m// /}"
    [[ -n "$m" ]] || continue
    has "$html" "$m"
  done
  has "$html" "$(basename "$COVER_3X4")"
  has "$html" "$(basename "$COVER_16X9")"
done

echo "== overview-pack: baked outputs =="
need "$POSTER_JPG"
need "$POSTER_JPG_ZH"
need "$UX_PNG"
need "$UX_PNG_ZH"

if [[ "$fail" -ne 0 ]]; then
  echo "FAIL  overview-pack validation"
  echo "Next: PORT=${SERVE_PORT} npm run serve && PORT=${SERVE_PORT} npm run docs"
  exit 1
fi

echo "OK  overview-pack validation passed"
echo "If HTML just changed: PORT=${SERVE_PORT} npm run docs   (or docs:posters if phones are current)"
