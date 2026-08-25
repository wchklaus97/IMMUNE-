# SDD ledger — plan: docs/superpowers/plans/2026-08-12-immune-research-network-ui.md

Status: MVP complete with full asset pipeline (200 node icons, 124 skill icons, 31 character portraits, 12 defense targets). 30 tests pass; single-file build embeds 410 assets.
Note: workspace is not a Git repository; git-based SDD worktree/commit helpers are unavailable.

Task 1 analysis: complete.
Task 1 art-direction review: complete.
Task 1 visual inventory: complete (hybrid A+B documented; concept PNGs still pending Image Gen).
Task 1 engineering skeleton: complete.
Task 2 catalog: complete (200 nodes, 31 anchors, tests pass).
Task 3 rules/transactions/protocols/persistence: complete (tests pass).
Task 4 layout/edges/LOD: complete (tests pass).
Task 5 SVG shell: complete.
Task 6 map interaction: complete.
Task 7 vertical slice + protocols: complete.
Task 8 responsive/list/a11y: complete.
Task 9 build + tests: complete (`outputs/immune_research_network_v1.html`).

Remaining optional follow-ups:
- Generate concept PNGs A/B when Image Gen network is available.
- Browser QA at 1280×720, 1280×800, 1920×1080 via in-app browser.

Character identity redraw (2026-08-15):
- `character-identity.js` model covers all 31 anchors.
- Pilot catalog faces generated for CHAR-PAIR-TM, CHAR-PAIR-TN, CHAR-PAIR-BM (`catalogStatus: pilot_catalog`).
- `npm run prompts:catalog` writes identity-driven prompts; staging in `staging/catalog-pilot/`.
- After stakeholder approval: batch remaining 21 catalog redraws, then fixed/mobile forms per identity.
