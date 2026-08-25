#!/usr/bin/env bash
# Fail if any required cover is missing. Paths come from .agents/project.env
# (example host: Emoji Cube Match 3D).
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
# shellcheck source=load-project.sh
source .agents/skills/overview-pack/scripts/load-project.sh

need=(
  "$COVER_HERO"
  "$COVER_3X4"
  "$COVER_16X9"
)

fail=0
for f in "${need[@]}"; do
  if [[ ! -s "$f" ]]; then
    echo "MISSING  $f"
    fail=1
  else
    echo "ok       $f  ($(wc -c < "$f" | tr -d ' ') bytes)"
  fi
done

if command -v magick >/dev/null 2>&1; then
  echo "--- identify ---"
  magick identify "$COVER_HERO" "$COVER_3X4" "$COVER_16X9" 2>/dev/null || true
fi

[[ "$fail" -eq 0 ]]
echo "OK  cover trio present"
