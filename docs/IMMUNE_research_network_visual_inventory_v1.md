# IMMUNE Research Network Visual Inventory v1

**Approved direction:** Hybrid A+B (art review 2026-08-12)

- **Concept A** — information architecture, interaction clarity, six-sector star map, panel density.
- **Concept B** — organ texture, cellular materials, organic signal lines, danger atmosphere.

This document is the sole implementation reference for Tasks 5–9.

## Background

- Deep navy human-tissue void (`#06111d` → `#040a12`) with subtle radial glow at immune core.
- Organic membrane rings at 420 / 560 / 900 / 1250 / 1500 world units.
- No baked UI text in raster backgrounds; all labels rendered in HTML/SVG.

## Six family colors

| ID | Name | Color |
|----|------|-------|
| T | T 細胞 | `#45bdf2` |
| B | B 細胞 | `#a878ff` |
| M | 巨噬細胞 | `#d28cff` |
| N | NK 細胞 | `#a6c94a` |
| A | 抗體構造體 | `#f2b84b` |
| D | 樹突細胞 | `#ff9b58` |

## Typography

- UI: Segoe UI / Microsoft JhengHei 14px body.
- Brand title: 22px (26px at 1920×1080).
- Detail title: 18px; section labels: 13px cyan caps.
- Map labels: 22px SVG text at detail+ LOD.

## Node sizes (visual radius, world units)

| Kind | Radius | Notes |
|------|--------|-------|
| Core | 36 | Luminous immune core |
| Character anchor | 28 | 31 anchors, +15% in layout |
| Base research | 14 | Standard progression |
| Pair research | 16 | Border fusion nodes |
| Triple research | 18 | Outer ring |
| Apex research | 20 | Hidden apex gates |
| Universal / Status | 12 | Inner rings |

**Hit target:** 44px minimum (`node-hit` r=22 in world space at 1×; scales with zoom).

## Eight runtime state symbols

| Symbol | Meaning |
|--------|---------|
| ✓ | Completed |
| ● | Ready to research |
| ◎ | Tracked |
| ! | Missing resources |
| ◌ | Missing prerequisite |
| (none) | Revealed / neutral |
| Hidden silhouette | Undiscovered |
| Gold stroke | Tracked highlight |

States use **symbol + text** in detail panel; never color alone.

## Four edge languages

| Kind | Style |
|------|-------|
| required | Solid cyan 75% |
| dual_source | Gold dashed |
| optional | Muted dashed |
| affinity | Thin violet (informational) |

## Panel & chrome dimensions

| Viewport | Detail width | Resource bar | Minimap |
|----------|--------------|--------------|---------|
| 1280×720 | 320px | ≤72px | 120px |
| 1280×800 | 340px | ≤72px | 140px |
| 1920×1080 | 380px | ≤72px | 180px |

- Toolbar height: 56px.
- Protocol dock: bottom drawer at 720p; three-card row at 800p+.

## Unlock animation

**Normal:** energy pulse along required edge → node membrane mature → resource toast → newly revealed nodes glow.

**Reduced motion (`prefers-reduced-motion: reduce`):** 150ms opacity/outline transition only; no path animation.

## Concept A vs B tradeoffs (resolved)

| Aspect | Choice |
|--------|--------|
| Layout / IA | A |
| Sector legibility at 720p | A |
| Materials / atmosphere | B |
| Edge rendering | B organic weight on A geometry |
| Panel chrome | A glass panels with B tissue tint |

## Accessibility

- Focus ring: 2px cyan + 4px glow.
- Toast: `#toast-region` with `aria-live="polite"`.
- Undiscovered nodes: anonymous in search, list, and `aria-label`.
- Research button linked to gap copy via `aria-describedby` when resources insufficient.
