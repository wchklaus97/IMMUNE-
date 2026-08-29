# IMMUNE v0.4.0 release identity hardening

Date: 2026-08-29
Status: implemented and verified locally plus Godot 4.7.2 CI; publishing intentionally not performed

## Goal

Make the existing four-platform demo artifacts identify themselves consistently,
fail before export when project and preset metadata drift, and prove the generated
artifact set is structurally complete. This tranche does not change gameplay or
the accepted six-family Fizzy art direction.

## Decisions

- `res://ui_icons/symbols/SYM-CORE.png` is the canonical application icon. It is
  a checked-in 1024x1024 transparent IMMUNE jelly-core asset and now feeds the
  project, Windows resources, macOS icon set, and generated Web icons.
- Version `0.4.0` remains the single release version. Windows file/product
  versions and macOS short/build versions must match it exactly.
- Web remains single-threaded with extension support disabled. The demo therefore
  does not require cross-origin isolation headers just to launch.
- The project stays on GL Compatibility. Shader baker settings were deliberately
  not added because Godot's baker applies to Forward+ and Mobile, not Compatibility.
- macOS stays universal and ad-hoc signed for local/CI validation. Developer ID
  signing and notarization are a separate credentialed publishing gate.
- No release tag or GitHub Release is created automatically. A tag must be an
  explicit publishing decision and must equal `v0.4.0`.

## Release contract

`tools/validate_release_contract.mjs` parses `project.godot` and
`export_presets.cfg` without third-party dependencies. It fails on:

- missing or non-SemVer project identity;
- a renderer other than GL Compatibility;
- a missing canonical icon;
- a missing/renamed platform preset, wrong artifact path, or wrong architecture;
- Windows name, company, description, version, resource, or icon drift;
- threaded/extension-enabled Web drift;
- macOS bundle, version, architecture, or icon drift;
- committed certificate, password, provisioning-profile, or API-key paths;
- a supplied tag that is not exactly `v<project version>`; or
- a missing/undersized four-platform artifact or Web HTML that does not load
  `index.js`.

Run the fast contract before invoking Godot:

```sh
node --test tools/validate_release_contract.test.mjs
node tools/validate_release_contract.mjs
```

For a deliberate tag preflight:

```sh
node tools/validate_release_contract.mjs --tag=v0.4.0
```

After all sequential exports:

```sh
node tools/validate_release_contract.mjs \
  --artifacts=godot/immune/build/releases
```

The generated `godot/immune/build/` tree now has a `.gdignore`. This keeps release
output out of Godot's source importer and prevents Web icon `.import` sidecars
from appearing inside generated artifacts.

## CI gates

The main CI job now runs release-contract tests before installing Godot. Tag jobs
also compare `GITHUB_REF_NAME` to the project version. After export, CI validates
the complete artifact set. Native jobs additionally prove:

| Platform | Native evidence |
| --- | --- |
| Linux | exported process launches and reports 200-node release smoke |
| Windows | exported process launches; PE ProductName, CompanyName, description, FileVersion, and ProductVersion match the contract |
| macOS | strict deep signature verification; bundle/version/icon file; arm64+x86_64; exported process release smoke |

All shell error scans use explicit conditional failure. This keeps `errexit`
behaviour unambiguous and satisfies actionlint/shellcheck after later commands
were added to the workflow.

## RED-to-GREEN evidence

The first test run intentionally failed because the project icon and Windows
metadata were absent. After updating the project and presets, all three release
contract tests passed, including the mismatched-tag rejection.

Fresh Godot 4.6.1 local exports then passed for Windows x86-64, Linux x86-64,
macOS universal, and single-threaded Web. The post-export contract passed and no
generated `.import` file remained below `build/releases`.

Binary inspection proved the configuration reached the artifacts rather than
only existing in text files:

- Windows PE contains six `ICON` resources, a `GROUP_ICON`, and `VERSIONINFO`
  with `IMMUNE`, `wchklaus97`, `IMMUNE playable demo`, and `0.4.0` values.
- macOS `Info.plist` contains `com.wchklaus97.immune`, short/build version
  `0.4.0`, and `icon.icns`; the file exists, `codesign --verify --deep --strict`
  passes, and the executable contains x86_64 and arm64.
- The exported macOS executable reports
  `RELEASE_SMOKE_OK platform=macOS nodes=200`. Custom project arguments must be
  placed after Godot's `--` separator.
- Web generated a 1024x1024 alpha icon and a 180x180 alpha Apple touch icon from
  the canonical project icon.

GitHub Actions run `33253080682` then verified commit `a7db3bd` on Godot 4.7.2.
The main validation/export job and all three downloaded-artifact native jobs
(Linux, Windows, and macOS) completed successfully. This includes the Windows
VersionInfo assertions and macOS signature, bundle, icon, universal-binary, and
release-smoke assertions introduced by this tranche.

## Remaining external gates

This is a locally and remotely testable demo release pipeline, not a notarized or
store-published product. Public macOS distribution still needs an Apple Developer
ID Application identity and notarization credentials. Store privacy, legal,
screenshots/copy, age-rating, and upload decisions remain product-owner work.
Subjective fun/readability/control feel and lower-end Windows/Web GPU behaviour
also require human/hardware validation; deterministic automation cannot honestly
close those gates.
