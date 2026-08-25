#!/usr/bin/env bash
# Source .agents/project.env (worked example: Emoji Cube Match 3D).
# shellcheck disable=SC1091
if [[ -f .agents/project.env ]]; then
  set -a
  # shellcheck source=/dev/null
  source .agents/project.env
  set +a
fi

GAME_TITLE="${GAME_TITLE:-Game}"
DOC_SLUG="${DOC_SLUG:-Game}"
SERVE_PORT="${SERVE_PORT:-5180}"
ENTRY="${ENTRY:-index.html}"
COVER_HERO="${COVER_HERO:-assets/cover.png}"
COVER_3X4="${COVER_3X4:-assets/cover-3x4.webp}"
COVER_16X9="${COVER_16X9:-assets/cover-16x9.webp}"
UX_HTML="${UX_HTML:-docs/ux-wireframe.html}"
UX_HTML_ZH="${UX_HTML_ZH:-docs/ux-wireframe-zh.html}"
MANAGER_HTML="${MANAGER_HTML:-docs/manager-overview.html}"
MANAGER_HTML_ZH="${MANAGER_HTML_ZH:-docs/manager-overview-zh.html}"
POSTER_JPG="${POSTER_JPG:-docs/${DOC_SLUG}-Manager-Overview-poster.jpg}"
POSTER_JPG_ZH="${POSTER_JPG_ZH:-docs/${DOC_SLUG}-Manager-Overview-zh-poster.jpg}"
UX_PNG="${UX_PNG:-docs/${DOC_SLUG}-UX-Wireframe-21x9.png}"
UX_PNG_ZH="${UX_PNG_ZH:-docs/${DOC_SLUG}-UX-Wireframe-21x9-zh.png}"
SHOT_IDS="${SHOT_IDS:-hero,summary,loop,ux,mechanics,shapes,difficulty,covers,footer}"
UX_MARKERS="${UX_MARKERS:-}"
