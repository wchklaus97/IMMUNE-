# IMMUNE narrow-phone and safe-area contract

Status: implemented and locally verified, 2026-08-31; remote CI pending.

## Problem

The 720x1280 combat capture has a tall-HUD scale, but a real 390x844 capture
still maps the 1920-wide canvas to roughly 20.3% physical scale. The mission
desk remains a fixed 1268px two-column layout, the research screen retains its
desktop side cards and horizontal bottom bar, and the pause panel remains
560x660 logical pixels. Existing screenshot harnesses prove nonblank output and
identity, but do not prove readable type, 44px touch targets, stacked layout, or
notch avoidance.

## Supported targets

- Existing desktop landscape targets remain unchanged: 1920x1080, 1600x900,
  and 1280x720.
- Existing 720x1280 combat behavior remains supported.
- New locked low-resolution phone targets: 390x844 and 360x800.
- Debug QA simulates physical safe-area insets `24,47,24,34`; production reads
  the platform display safe area on Android/iOS. Godot's default Web shell does
  not opt into `viewport-fit=cover`, so its browser viewport is already the
  unobscured interactive area.

## Layout contract

At a portrait physical window width of 430px or less:

1. Mission selection uses one stacked main column, a two-column family grid,
   no horizontal scrolling, readable copy, and start/back controls at least
   44 physical pixels high.
2. Research hides the redundant desktop side-card columns, keeps the map as the
   visual field, and stacks resource/detail/navigation sections above the safe
   bottom edge. Research and mission buttons remain at least 44 physical pixels
   high.
3. Combat stacks briefing above vitals and stacks its three action buttons.
   Critical copy remains at least 14 physical pixels and every action is at
   least 44 physical pixels high.
4. Pause/settings scales inside a safe-area MarginContainer; sliders, locale,
   resume, restart, and return controls remain usable without clipping.
5. Physical safe insets are converted to the expanded canvas's logical units.
   Decorative 3D/map content may render behind a notch, but interactive HUD
   content may not.

## Evidence contract

- Capture the existing implementation at 390x844 as RED evidence.
- Extend mission, gameplay, and research QA so a narrow capture fails unless
  the runtime returns an `all_pass` responsive contract.
- Run zh_HK and English at 390x844 and 360x800 with simulated safe-area insets.
- Retain 1280x720, 720x1280, 1600x900/1920x1080 regressions.
- Verify Godot import, release smoke, research overflow, Web UI tests/build, and
  exported-Web browser flow before calling the tranche complete.

This work does not claim real iOS/Android device support, touch gameplay input,
or notch correctness on hardware until device testing is performed.

## Implementation result

- `ImmuneResponsiveLayout` is the single physical/logical conversion contract.
  It detects portrait windows at 430 physical pixels or narrower, converts safe
  insets into the expanded canvas, and keeps the existing desktop and 720x1280
  scaling paths intact.
- Mission selection changes from 2 desktop columns to one stacked column and
  from a 3-column to 2-column family grid. Horizontal scrolling is disabled;
  vertical scrolling remains usable with its bar hidden.
- Research keeps its map as the decorative field, hides the redundant side
  cards, and stacks resources, detail, and navigation in one bottom column.
- Combat stacks briefing/vitals and all three actions. Pause/settings is centered
  inside its own safe-area margin and validates both hidden minimum geometry and
  the visible production rectangle.
- The final review gate includes locale, sliders, screen-shake/reduced-motion
  toggles, resume, restart, and return controls. It also keeps desktop margins
  exactly at zero instead of introducing a one-pixel responsive residue.
- Mission, gameplay, pause, and research QA now fail closed if their responsive
  contract is missing or false. `check_overflow.gd --out=<dir>` preserves PNG
  and report evidence in a validated temp/repository-outputs location; source
  paths, symlink crossings, malformed, duplicate, and unknown arguments fail.

## Accepted evidence

- 390x844 and 360x800 pass in `zh_HK` and English for mission, combat, pause,
  and research. Final 390 values are 44.688 physical pixels for the smallest
  action and 14.422 for critical copy; final 360 values are 44.820 and 14.440.
- 390 mission evidence verifies six family-bound PNGs. Gameplay verifies fixed,
  mobile, boss, and pause PNGs plus three identity/lifecycle samples. Research
  verifies both locales, core plus six base labels, no clipped resource text,
  and the one-column bottom HUD.
- Desktop regressions pass at 1600x900 mission, 1280x720 gameplay with portrait,
  720x1280 gameplay without portrait, and 1920x1080 research in both locales.
- Root tools pass 36/36; research UI passes 53/53 and builds. Translation tables
  pass 595 rows, catalog localization passes 200 nodes/406 rows, playtest template
  and release identity pass, and Godot 4.7.2 import has no script/parse/compile
  error.
- Isolated project smoke reports six missions/six families. Four final release
  exports pass the artifact contract; the rebuilt macOS binary reports
  `RELEASE_SMOKE_OK platform=macOS nodes=200`.
- Final exported-Web QA completes research -> mission -> B -> combat -> mobile
  duty -> pause in baseline and SwiftShader profiles. Baseline is 120.002 mean /
  100 p05 FPS; compatibility stress is 14.608 / 13.089 and is not presented as
  a hardware benchmark.

Evidence roots are ignored generated artifacts:

- `outputs/v5.2-narrow-phone-green/`
- `outputs/v5.2-responsive-regression/`
- `outputs/v5.2-web-release-qa-final/`

## Failure handling and residual risk

The first native export attempt used `Linux` instead of the configured
`Linux/X11` preset. The workflow stopped, read `export_presets.cfg`, and then
used only its exact names. A first smoke path under `/private/tmp` was rejected
by the QA save guard; the rerun used macOS's actual `OS.get_temp_dir()`. A first
post-process copy of research evidence raced automatic QA cleanup; the harness
now owns a durable, validated `--out` path.

Godot 4.7.2 still prints non-fatal Unicode/NUL parser warnings while loading the
ASCII/valid-UTF-8 catalog and research scripts. Source scans contain no NUL,
all import/error scans and release launches pass, and the same message family
is tracked in upstream Godot parser issues. Keep monitoring the engine rather
than weakening compiled-script release settings.

Real Android/iOS safe-area geometry, touch gameplay, human readability, and a
real lower-end machine remain external gates. The default Web shell does not use
`viewport-fit=cover`, so the browser viewport itself is the unobscured area;
custom full-bleed shells must be retested before making notch claims.
