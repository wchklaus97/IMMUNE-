# Metal trace security and retention

Updated: 2026-09-04

Xcode Instruments trace bundles and exported trace tables are local-sensitive
diagnostic artifacts. Instruments can serialize the captured process launch
environment into trace metadata. A trace must therefore be treated as capable
of containing credentials even when the game itself never reads or transmits
them.

## Repository policy

- Never commit, upload, share, or attach a `.trace`, `.ktrace`, trace TOC, or
  unreviewed trace export to an issue, pull request, CI artifact, Steamworks, or
  another service.
- Do not print environment values while inspecting a trace. Review key names
  only, and stop if an unexpected or credential-like key is present.
- Historical trace bundles and their TOC exports under `outputs/` predate the
  hardened runner. They are preserved as local history, but they are not safe
  publication artifacts and must not be used as V8.6 formal evidence.
- Rotate long-lived credentials that were present in the interactive shell
  during historical captures. This is a precaution against local artifact
  retention; it is not evidence that a credential was uploaded or used.
- A task-created V8.6 diagnostic trace that was found to contain the inherited
  shell environment was deleted locally and is not recoverable. Only its
  redacted failure summary and non-sensitive numeric diagnostic report remain.

## Hardened V8.6 capture boundary

`npm run run:gpu-abba` is the only accepted formal V8.6 GPU campaign path. It:

1. launches the captured Godot process with a small explicit environment
   allowlist instead of inheriting the caller's full shell environment;
2. rejects credential-like environment key names in the trace TOC without
   emitting their values;
3. binds each A1/B1/B2/A2 report to one run ID, sequence, exact Godot PID,
   runtime report, source artifact path, byte size, SHA-256, and a deterministic
   digest of the actual imported runtime mesh arrays;
4. reads the authoritative recording `start-date` and `end-date` from each
   trace TOC, requires an exact requested 8-second time limit and exact
   `Time limit reached` reason, accepts only a bounded 7.95-12.0-second TOC
   envelope for pinned-xctrace stop latency, and requires that whole envelope
   to fit inside the process's 35-second post-measurement render hold; the tail
   never expands the exact 300-frame analysis window;
5. keeps trace working files in marked task-owned temporary directories and
   removes them after the safe exports and hashes are complete;
6. resolves and freezes the selected developer directory, Xcode build, and
   exact `xctrace` binary/version/SHA, then rechecks them and the concrete GPU
   identity throughout the campaign;
7. requires the fresh formal evidence root to be a new child of the OS-reported
   temporary directory and outside both the source repository and measured
   Godot project; the macOS system `/var` alias is accepted only when it resolves
   to the expected canonical `/private/var` target;
8. re-hashes retained trace/runtime/export artifacts before publishing the
   final manifest and never overwrites an existing campaign;
9. requires 24 GiB free before reservation, 14 GiB before each capture, and
   6 GiB after capture staging cleanup before any export or analysis.
10. catches command-log write failures (including `ENOSPC`) inside stream
    callbacks, records the first error in the tracked child result, and
    terminates that exact owned process through the same TERM/KILL cleanup path
    before the campaign failure manifest is published.
11. parses each exported Metal interval as exactly one row per line and validates
    the first six schema columns positionally. Scalar fields must have exactly
    one value, a field cannot mix inline and `ref` forms, every reference must
    resolve, duplicate attributes and relevant element IDs are rejected, and
    all process identities in a target row must resolve and agree
    with the exact captured Godot PID. A legal nullable Frame-column
    `<sentinel/>` is classified as an unframed target row, not as malformed.
    The report must still contain zero malformed target rows, zero unframed rows
    overlapping the selected analysis window, and exact row accounting:
    `target = channel top-level + nested + unframed + malformed`.

Do not force-interrupt xctrace while it is finalizing unless disk safety
requires it. Xcode may leave `instruments*.ktrace` and `xrgpu_aps_*` staging in
the OS temporary directory after an external interruption. Such paths must
never be removed by name pattern alone: first prove that no capture process is
running and that each exact path's birth time matches the failed capture, then
record the cleanup in its failure manifest. The 2026-09-04 storage-inconclusive
A1 followed this procedure; only the incomplete trace and its verified staging
were removed, while runtime/log/failure evidence was retained.

## R6 A1 parser forensics

The original R6 A1 analyzer classified seven legal nullable Frame-column
sentinels as malformed target rows. The immediate report contract therefore
stopped the campaign before B1; it did not produce an A/B performance verdict.
The complete `v86-r7-2-r4-1-final-r6-20260904T-current` evidence root remains
immutable and must not be rewritten or promoted as a completed campaign.

A read-only reanalysis of its retained A1 interval export with the corrected
parser produced the following exact result:

- target rows: 22,860;
- channel top-level rows: 18,670;
- nested rows: 4,183;
- legal unframed rows: 7;
- malformed rows: 0;
- unframed rows overlapping the selected analysis window: 0;
- selected frames: 61-360, exactly 300 contiguous frames;
- GPU frame-span metrics: mean 7.127 ms, p95 7.488 ms, max 9.540 ms.

These counts reconcile exactly (`22,860 = 18,670 + 4,183 + 7 + 0`). The
reanalysis establishes the parser diagnosis only. It does not change R6's
failed status, replace its preserved report, or authorize reuse of that root.
A complete formal result still requires a fresh immutable A1/B1/B2/A2
campaign produced by the corrected parser.

## R7 formal campaign

The corrected-parser campaign completed with status `PASS`. Its immutable
evidence root is named
`v86-r7-2-r4-1-final-r7-20260904T-current` and is retained at:

`/var/folders/s3/8ntnh5c12bv7njyr38rvftcw0000gn/T/v86-r7-2-r4-1-final-r7-20260904T-current`

The system alias resolves to the corresponding canonical `/private/var` path.
All four runs were bound to their exact spawned Godot PID:

| Sequence | Look | Exact PID | TOC envelope | Inside 35-second hold |
| --- | --- | ---: | ---: | --- |
| A1 | V8.5 | 75044 | 9.771801 s | Yes |
| B1 | V8.6 | 75961 | 9.908435 s | Yes |
| B2 | V8.6 | 76928 | 9.996564 s | Yes |
| A2 | V8.5 | 77967 | 9.801604 s | Yes |

Every authoritative TOC envelope was within the required 7.95-12.0-second
range and fitted completely inside its corresponding 35-second render hold.
Each TOC passed the key-name-only security allowlist check with 22 allowed
environment keys. The verification evidence records key names only and does
not emit environment values.

All four task-owned raw trace temporary directories and all four export
temporary directories were removed after the retained artifacts were safely
published and hashed; the recorded removal flags are true and the eight paths
are absent. The final raw document digests are:

- provenance raw SHA-256:
  `8bbde87e7f1d1d42158bc0d64e1f402ea43235305d42a376222ba3cd44346c53`;
- GPU regression gate raw SHA-256:
  `469e41dd340f3e02935501b209dfbf58b8d6fa09bc2797567718ce4fb50d01d7`.

The retained trace-derived artifacts remain local-sensitive even though the
formal gate passed. Raw traces, TOCs, and unreviewed interval exports must not
be committed, uploaded, attached to review systems, or otherwise published.

The retained formal evidence is still local development evidence. Before any
future publication, inspect the manifest and TOC key-name inventory, confirm
that no forbidden key was recorded, and distribute only the minimal redacted
reports required for review.
