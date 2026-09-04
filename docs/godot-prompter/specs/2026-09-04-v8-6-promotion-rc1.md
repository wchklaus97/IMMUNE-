# V8.6 promotion RC1

Date: 2026-09-04
Status: implementation authorized; publication blocked on owner-controlled gates

## Outcome

Promote the accepted V8.6 R7.2 T-cell presentation from an isolated technical
candidate to the default four-platform release package without deleting or
overwriting any earlier look, model, capture, or build record.

The source release identity is `0.5.0-rc.1`. Platform metadata uses formats
accepted by the native exporters:

- Windows file version: `0.5.0.1`
- Windows product version: `0.5.0-rc.1`
- macOS short version: `0.5.0`
- macOS build version: `1`

The release remains an unpublished RC. This work does not authorize a tag,
GitHub Release, merge, Developer ID signing, notarization, SteamPipe upload,
store mutation, or public distribution.

## Shipping contract

- `immune/visual/gel_look` defaults to exact `v8_6`.
- The four ordinary release presets carry the `v8_6_shipping` feature.
- The SHA-256-bound raw export plugin injects only
  `CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb`.
- R5, R6, R7, and R7.1 remain tracked development evidence and are excluded
  from every shipping PCK.
- V8.5 and V8.6 candidate presets remain available and isolated.
- The exported shipping PCK must pass the same one-body, one-shell, one wet
  material, one shell material, zero fallback, zero loose-particle, and
  fourteen-animation probe as the V8.6 candidate.

## Rollback contract

V8.3 remains selectable through the existing exact
`IMMUNE_GEL_LOOK=v8_3` override. CI mounts the new shipping PCK, selects V8.3,
instantiates the T character, and rejects any V8.6 authored-body or shell
marker. The complete selector smoke matrix also remains in CI. The prior V8.3
source history and artifacts are not rewritten.

## Acceptance

1. Release/version, V8.5 preservation, and V8.6 shipping contracts pass.
2. Official Godot 4.7.2 clean import and default/rollback selector smokes pass.
3. Shipping and candidate PCK inventories contain only their exact active raw
   body revision.
4. All fourteen V8.6 animations and the R7.2 source/runtime mesh hashes pass.
5. Four release exports, Web QA, and Linux/Windows/macOS native smoke pass in
   GitHub Actions for the exact PR head.
6. Owner asset-rights attestation stays fail-closed and unsigned until the
   owner supplies evidence and signs it outside the public repository.

## Producer boundary

The promotion PR may be committed, pushed, and opened for review. It must not
be merged or published automatically. External owner-controlled gates remain
visible blockers rather than being represented as completed technical work.
