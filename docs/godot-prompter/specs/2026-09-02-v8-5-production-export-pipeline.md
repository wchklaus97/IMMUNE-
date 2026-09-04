# V8.5 production export pipeline

Date: 2026-09-02
Status: implemented and locally verified; V8.3 remains the shipping default

## Outcome

V8.5 can now be built as an isolated four-platform candidate without changing the checked-in `immune/visual/gel_look="v8_3"` release default. The candidate presets carry the `v8_5_candidate` feature, which selects the V8.5 runtime profile and activates a SHA-bound export plugin that injects the required raw GLB into the pack.

The four existing shipping presets remain separate, have no candidate feature, continue to exclude the V8.5 source, and now explicitly exclude editor addons from runtime packs.

## Fail-closed controls

- `tools/godot_checked_command.mjs` rejects non-zero exits, signals, Godot `ERROR:`/script/parse/compile diagnostics even when Godot exits zero, missing success markers, and attempts to overwrite an existing evidence log.
- `tools/validate_v8_5_export.mjs` locks the V8.3 source default, four shipping presets, four V8.5 candidate presets, addon registration, asset SHA-256, candidate PCK inventory, and editor/concept/older-candidate exclusions.
- `tools/godot/v8_5_candidate_probe.gd` mounts the exported PCK and verifies the candidate feature, preserved source default, raw asset digest, one body, one shell, no build fallback, hidden loose-particle burst, and all 14 animations.
- CI builds and probes the isolated candidate PCK before producing the unchanged shipping release artifacts. All four shipping exports now run through the checked command wrapper.

## Local verification

Godot: `4.7.2.stable.official.ed1daf0bf`

- Fresh import: passed with no engine diagnostics.
- V8.5 candidate Web PCK: 546 resources; contract passed; post-review R2 SHA-256 `22af125e7c61a11b4eaa10ec18f934dc087457f98afc42fd7df4d17c403d26cd`.
- Candidate runtime probe: `body=1`, `shell=1`, `build_failed=false`, `loose_burst_hidden=true`, `animations=14`, `animations_ok=true`.
- V8.3 shipping-control Web PCK: 543 resources; existing Steam PCK policy passed and V8.5 remained excluded.
- Source smokes: V8.3 default and explicit V8.5 selector both passed.

Local evidence is preserved under `outputs/v8-5-production-export-pipeline-d14d98a/`. The first smoke attempt was intentionally retained after the QA save-path guard rejected a repository-local state path; the corrected rerun uses an OS temporary directory and is recorded with `-r2` logs. The post-review export also has an R2 artifact and log; its PCK is byte-identical to the pre-review candidate, while the plugin now hashes the exact in-memory bytes passed to `add_file()`.

## Operator commands

Validate the tracked contract:

```sh
npm run validate:v8-5-export
```

Build a candidate pack with a unique log:

```sh
candidate_dir="$(mktemp -d)"
node tools/godot_checked_command.mjs \
  --log="$candidate_dir/export.log" \
  --expect=V8_5_RAW_EXPORT_ADDED \
  -- godot --headless --path godot/immune \
  --export-pack "Web V8.5 Candidate" "$candidate_dir/v8-5-candidate.pck"
npm run validate:v8-5-export -- --pck="$candidate_dir/v8-5-candidate.pck"
node tools/godot_checked_command.mjs \
  --log="$candidate_dir/probe.log" \
  --expect=V8_5_CANDIDATE_PROBE_OK \
  -- godot --headless --main-pack "$candidate_dir/v8-5-candidate.pck" \
  --script "$PWD/tools/godot/v8_5_candidate_probe.gd"
```

## Promotion boundary

This pipeline makes V8.5 reproducible and testable; it does not promote it to the shipping default, upload artifacts, sign/notarize builds, or publish to Steam. Promotion remains a separate owner decision after reference-match visual approval, real-GPU performance evidence, and asset-rights sign-off.
