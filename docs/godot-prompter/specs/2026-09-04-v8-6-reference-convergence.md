# V8.6 T-cell reference convergence

Date: 2026-09-04
Status: local technical candidate in validation; not a public-release claim

> Promotion note (2026-09-04): this document preserves the evidence and
> decisions from the opt-in convergence phase. V8.6 R7.2 was subsequently
> promoted to the unpublished `0.5.0-rc.1` four-platform shipping default under
> `2026-09-04-v8-6-promotion-rc1.md`. V8.3 remains the explicit runtime rollback;
> no historical candidate, model, capture, or evidence root was removed.

## Outcome

V8.6 is an additive, opt-in T-cell presentation revision over the frozen V8.5
reference-sculpt implementation. It replaces neither the release-safe V8.3
default nor any historical asset. Its purpose is to close the remaining gap to
`characters/concepts/CHAR-BASE-T-3d-alt.png`: a broad single slime mass,
shoulder-connected hook arms, separated soft feet, embedded face marks, a wet
transparent edge, continuous internal flow, and viscous rather than rigid-ball
locomotion.

The revision is deliberately split into independently testable layers:

1. exact selector and rollback isolation;
2. provider-independent, one-component authored geometry;
3. V8.6-T-only optical and facial tuning;
4. the existing fourteen-clip viscous animation system;
5. exact Godot 4.7.2 import, GPU, and isolated four-platform candidate
   evidence.

No Meshy generation task or paid generation credit is used. No previous model,
capture, build, or selector is overwritten. No push, tag, signing, notarization,
SteamPipe upload, store mutation, or public release is authorized by this work.

## Frozen foundations

- The project default remains `v8_3`.
- V8.5 T continues to load
  `CHAR-BASE-T-v8-5-authored-sculpt-r4.glb` with its original SHA-256.
- V8.6 is selected only by exact `IMMUNE_GEL_LOOK=v8_6` or the equivalent
  project setting.
- V8.6 geometry and optical overrides apply only to family T. Other families
  retain their V8.5 identity when the V8.6 selector is used.
- Gameplay collision, attack timing, duty behavior, save format, and input are
  unchanged.

Godot 4.7.2 rollback smoke passes for unset/default, `v8_3`, `v8_4`, and
`v8_5`; unset still resolves to V8.3. Exact V8.6 smoke also passes.

## R7.2 authored geometry lock

R5 and R6 remain immutable evidence. R5 exposed a perspective-width defect;
R6 corrected the production-camera silhouette but its shallow eye subtraction
and narrow implicit joins created fixed cheek, arm, foot, and back creases.
The rejected global R7 and selective R7.1 experiments are also preserved; they
are never runtime fallbacks and are excluded from the candidate PCK.

The bounded geometry lock is
`CHAR-BASE-T-v8-6-authored-sculpt-r7-2.glb`:

- SHA-256
  `3fc0b00e7ee8bdf2696fbf7ef97a8044abf8dc60d49c3b917a5471c60945f6a3`;
- one node, one mesh, one indexed primitive, 6,002 vertices/normals, 36,000
  indices, and 12,000 triangles;
- one closed genus-zero component, zero boundary/non-manifold/winding/
  degenerate errors, Euler characteristic 2, and signed volume `1.006122`;
- AABB position `(-0.82, 0.0, -0.50)`, size `(1.64, 1.46, 1.00)`;
- perspective ratio `1.053333` and calibrated gel-trim ratio `1.013131`, versus
  the primary reference ratio `1.012277`;
- foot notch `0.140127`, foot-arch opening `0.194318`, and minimum readable arm
  gap `0.050233`;
- socket centres `x=+/-0.238000, y=0.855065` with balanced radii
  `(0.285, 0.190, 0.060)` and eye-only subtraction softness `0.014`.

The R7.2 gate now samples each hard socket against the pre-subtraction front
skin instead of inferring fit from radii alone. Both sides cross their local
axes and measure outboard extent `0.030300`, minor span `0.251684`, and inboard
overhang `0.028576`. The preserved R7.1 depth-`0.045` fixture is rejected by
this gate because its opening no longer crosses the eye centre and clips the
minor axis. Two independent R7.2 builds are byte-identical.

All R7.x builders use numeric project-authored implicit parameters only; they
read no provider mesh/API response, texture, or reference pixels. The final
six-angle Compatibility/Metal lock is under
`outputs/v8.6-reference-convergence/lookdev-r7-2-r4-1-face-lock/`.

## R4.1 optical and face lock

R4.1 is the V8.6-T-only material baseline. It preserves R4's improved orange
saturation, thickness separation, internal laminar/core flow, eye reflections,
and pore response while softening only the hard reflection-card cutoff and
over-amplified authored normal relief. It changes uniforms only and adds no
shader instruction, texture sample, material, draw call, or transparent layer.

The final face lock keeps the measured eye position/scale/38-degree tilt but
seats each lens at z `0.436`. The pore cavity remains at z `0.438`; its attached
rim is also seated at z `0.438`, uses a thinner `(0.042, 0.060)` torus, and
blends 86% toward the body colour. It is one body-bound facial mark, not a cell,
particle, or independently animated mass.

The six-angle review shows a single coherent character, no collapse, no loose
cell/satellite body, softer cheek/limb/back transitions than R6, a continuous
wet silhouette, and a materially cleaner eye/pore seat. R4.1/R7.2 is accepted
as a gameplay-scale technical baseline, not a claim of pixel-identical
marketing-closeup parity. Any future full retopology is a new revision rather
than an unbounded V8.6 micro-tune. All R1-R4, R5-R7.1, and failed captures remain
preserved.

The project intentionally ships with `gl_compatibility`; this is the visual
acceptance renderer and Web path. A separate Forward+/Metal capture is retained
as renderer-parity and performance-stress evidence. Forward+ currently shifts
the fitted orange material toward red and makes the synthetic light cards much
more visible, so it must not be represented as the configured shipping look.

## Fourteen-animation contract

The exact inventory remains:

`idle`, `plant`, `uproot`, `move`, `hit`, `attack`, `relay_open`,
`relay_close`, `move_start`, `move_stop`, `relay_glide`, `skill_cast`,
`victory`, and `defeat`.

The official Godot 4.7.2 V8.6 animation gate passes:

- 14/14 exact animation names and 154 sampled poses;
- sampled visual scale range `0.860000..1.161781`, with no collapse;
- move scale span `0.076713`;
- idle flow speed `0.28` and slime strength `0.82`;
- moving flow mix `0.817316`, lag `0.004219`, squash `0.024486`;
- one-frame stop lag `0.005436`, proving viscous persistence instead of an
  instant rigid stop;
- settled mix `0.029328`, lag `0.000141`, squash `0.000095`;
- exactly one wet core material, one membrane material, zero detached meshes;
- collision transform and shape unchanged.

This is a structural/runtime gate, not a subjective animation-quality claim.
Idle, move, reversal, combat, and stop strips remain part of final visual review.

## GPU campaign contract

Historical single-run V8.5 data is not accepted as the new baseline. The formal
campaign must be captured from one frozen checkout with the exact official
Godot 4.7.2 executable in this order:

`A1=v8_5 -> B1=v8_6 -> B2=v8_6 -> A2=v8_5`.

Every run must bind its runtime JSON and Instruments report by run ID, sequence,
and exact PID. The workload is T, the production character scene, gel material,
20 characters, 1920x1080, 4,000 runtime samples, Forward+/Metal, no frame sync,
and an exact-PID Metal System Trace requested with an exact 8-second time limit.
Pinned xctrace may include bounded stopping latency in its authoritative TOC
envelope, so the accepted envelope is 7.95-12.0 seconds with the exact
`Time limit reached` reason. Exactly 300 contiguous GPU frames are analyzed
after dropping 60, for 1,200 analyzed frames across the four-run campaign; any
extra recorded tail is neither analyzed nor claimed. The runtime workload
itself remains 4,000 samples per run.

Every target interval must also be classified exhaustively. The first six Metal
columns are validated positionally; references, scalar cardinality, duplicate
attributes/IDs, row boundaries, and every process identity fail closed. A
legal nullable Frame sentinel is counted as unframed, never silently dropped.
Acceptance requires zero malformed target rows, zero unframed rows overlapping
the selected 300-frame window, and exact accounting:
`target = channel top-level + nested + unframed + malformed`.

`npm run run:gpu-abba` is the sole formal V8.6 capture path. The harness keeps
the measured scene rendering for at least 35 seconds after publishing a
capture-ready runtime report, so the entire bounded recording envelope must fit
inside the same exact-PID hold. Containment comes from the trace TOC's authoritative
timezone-qualified `start-date` and `end-date`, not the Node child-spawn time.
The runner resolves the selected Xcode developer directory and invokes the
exact hashed `xctrace` binary directly, rechecking Xcode build, xctrace version,
GPU/host identity, source state, and artifact hashes throughout the campaign.
Formal roots must be new leaves below the OS-reported temporary directory,
outside both the repository and Godot project. The runner verifies the trusted
macOS `/var` spelling against its `/private/var` canonical target and rejects
any additional symlink or alias traversal. Existing destinations and unbound
or caller-assembled report JSON are rejected. Disk gates require 24 GiB before
reservation, 14 GiB immediately before every capture, and 6 GiB after capture
staging cleanup before trace export and analysis.

Raw GLB SHA alone is not accepted as runtime geometry identity. Godot hashes
the actual imported body surface metadata plus vertex, normal, and index arrays
before measurement. The locked Godot-4.7.2 digests are
`ce95be01d9b0b1272c74760f8c8e1d997baa0428e308a8cf50afb78cd77fbc4d`
for V8.5 R4 and
`d5efe6491bdc51aadafe4aaccb5c1c3321376e29f6949e123a458780bf57f1de`
for V8.6 R7.2; both expose one surface, 6,002 vertices/normals, and 36,000
indices. This prevents a stale or substituted `.godot/imported` scene with the
same superficial topology/bounds from passing.

Acceptance requires:

- aggregate V8.6 mean regression at most 10% and 0.75 ms;
- aggregate V8.6 p95 regression at most 10% and 0.80 ms;
- every observed GPU frame span in each selected 300-frame A1/B1/B2/A2 window
  below 16.67 ms; this is not a long-duration rare-hitch claim;
- selector mean and p95 repeat spreads must each be within at least one of the
  two repeatability allowances: 5% relative spread or 0.40 ms absolute spread.
  Exceeding both allowances for either statistic makes the campaign
  inconclusive and requires a repeat;
- actual V8.5-R4/V8.6-R7.2 body identity, raw source SHA, imported runtime-mesh
  SHA, shell identity, animation count, renderer, GPU/OS, Godot/Xcode/xctrace
  executable hashes, trace/hash, commit/dirty state, and UTC timestamp recorded
  rather than inferred from a requested selector string.

## R7 formal GPU result

The fresh `v86-r7-2-r4-1-final-r7-20260904T-current` campaign completed on an
Apple M4 Pro under macOS 26.6.2, official Godot 4.7.2, and xctrace 17F113. All
four exact-PID runs completed their 4,000 samples and at least 35,000 ms render
hold. Each trace retained the exact requested 8-second limit and `Time limit
reached` reason, its 9.772-9.997-second authoritative envelope fit fully inside
the hold, and each report selected contiguous frames 61-360 with zero malformed
rows and zero unframed overlap.

| Run | Look | Mean (ms) | p95 (ms) | Max (ms) |
| --- | --- | ---: | ---: | ---: |
| A1 | V8.5 | 7.881 | 8.186 | 12.012 |
| B1 | V8.6 | 7.744 | 8.076 | 8.148 |
| B2 | V8.6 | 7.698 | 8.056 | 10.204 |
| A2 | V8.5 | 7.717 | 8.084 | 8.179 |

The aggregate V8.5 baseline is 7.799 ms mean / 8.135 ms p95. V8.6 is
7.721/8.066 ms, a -0.078 ms (-1.00%) mean delta and -0.069 ms (-0.85%) p95
delta. Baseline repeat spread is 0.164 ms (2.10%) mean and 0.102 ms (1.25%)
p95; candidate spread is 0.046 ms (0.60%) mean and 0.020 ms (0.25%) p95. All
repeatability, relative/absolute regression, and 16.67 ms maximum gates pass.
An independent post-run validator regenerated a byte-identical gate JSON. A
separate read-only audit re-hashed all 42 retained run/gate/log artifacts,
including the four trace bundles, with zero mismatches and no P0/P1 findings.

The immutable evidence root is local-sensitive and remains outside the
repository at
`/var/folders/s3/8ntnh5c12bv7njyr38rvftcw0000gn/T/v86-r7-2-r4-1-final-r7-20260904T-current`.
The raw provenance file SHA-256 is
`8bbde87e7f1d1d42158bc0d64e1f402ea43235305d42a376222ba3cd44346c53`;
the raw aggregate-gate SHA-256 is
`469e41dd340f3e02935501b209dfbf58b8d6fa09bc2797567718ce4fb50d01d7`.
The manifest records unchanged source/Git, host, official Godot, and Xcode
toolchain identities and confirms all runner-owned raw/export staging was
removed. These results close the local formal GPU gate; they do not substitute
for native target, minimum-spec, rights, signing, storefront, or human QA gates.

## Export contract

Windows, Linux, macOS, and Web V8.6 candidates are separate non-runnable
technical presets. Their shared export plugin injects only the exact
source-SHA-bound V8.6 asset and never changes the four release-safe presets or
the V8.3 default selector. A mounted-PCK probe must prove the candidate contains
the exact V8.6 asset and can instantiate it without a source fallback. V8.5
export inventories remain hash-locked.

The final paired local candidates under
`outputs/v8.6-reference-convergence/export-runtime-mesh-lock-20260904T0400Z/`
pass that contract. The 59,318,780-byte V8.5 PCK has SHA-256
`d84a2e07c71bcfd08683647945cae28d9a76f52a8732879ff98e4c5893e9c87b`.
The 59,317,556-byte V8.6 PCK has SHA-256
`825df57307a15801cea0eb4a7a289889988f8b3ddeaf05cf26b278bd673801ea`,
contains 546 validated files, retains V8.3 as the default selector, and mounts
with one R7.2 body, one shell, one wet material, all fourteen animations, zero
fallbacks, and zero build failures. Export and mounted-probe logs are preserved
beside both PCKs. The earlier isolated V8.6 export remains preserved rather than
being overwritten.

After clearing the disk gate, a new additive four-platform preflight was built
under
`outputs/v8.6-reference-convergence/export-four-platform-r7-2-preflight-r1/`.
All four exporters used official Godot 4.7.2 and emitted the SHA-bound
`V8_6_RAW_EXPORT_ADDED` marker. Windows, Linux, and Web PCKs are byte-identical:
59,317,556 bytes, 546 validated resources, SHA-256
`e81ca5510553cd04669aea4910e27c921ecdd4f36762bea25c59109ec313c9f4`.
The mounted PCK again resolves feature `v8_6_candidate`, source default `v8_3`,
selected look `v8_6`, one body, one shell, one wet and one shell material, zero
fallback/build-failure nodes, hidden loose burst, and all fourteen animations.

The new macOS ZIP is a universal x86_64/arm64 ad-hoc-signed development build.
Strict local code-sign verification and native release smoke pass with
`RELEASE_SMOKE_OK platform=macOS nodes=200`; Gatekeeper assessment correctly
rejects it because no owner Developer ID signature or notarization has been
applied. Web QA passes both the real Apple M4 Pro/Metal baseline at 60.002 mean
FPS and the explicitly non-hardware SwiftShader compatibility stress path at
13.720 mean FPS. Windows and Linux binaries are structurally valid x86-64 PE
and ELF artifacts. The Linux ELF additionally passes an offline, read-only,
unprivileged Ubuntu 24.04 amd64-container release smoke under Apple-Silicon
emulation; this is Linux-userspace compatibility evidence, not native x86-64
hardware or minimum-spec evidence. The Windows executable has not been
executed on Windows.
Exact hashes, sizes, logs, smoke output, and Web report are retained in the
preflight directory.

The checked-in CI workflow now rebuilds these four isolated candidates,
validates the PCK, exercises the Web candidate, and fans the exact commit-bound
artifacts out to Linux, Windows, and macOS native-smoke jobs that seal their
logs and artifact hashes. The owner has authorized committing and pushing the
candidate branch, but the workflow remains prepared evidence infrastructure
until the resulting GitHub run itself completes; this specification does not
pre-claim target-OS evidence.

The candidate export is not a Steam release artifact. Windows/Linux target
execution, owner signing, Developer ID notarization, SteamPipe/client-install
evidence, minimum-spec hardware, and owner approval remain separate gates.

## Failure discipline

- R5 attempt 1 stopped when arm-gap tunnels produced Euler characteristic `-2`;
  the topology was redesigned as open silhouette space.
- R5 attempt 4 stopped when an intermediate polygon collapsed into a line cell;
  polygon-to-line conversion was disabled and the promoted mesh still requires
  zero degenerate faces.
- The first V8.6 smoke after eye assertions stopped on an indentation/scope
  parse error. The facial assertion block was repaired before any further
  capture, and exact Godot 4.7.2 smoke passed.
- The first unprivileged Linux-container smoke used the `nobody` account's
  `/nonexistent` home. The game reached its release-smoke marker but Godot and
  ResearchState correctly emitted `user://` directory errors, so the checked
  wrapper rejected the run. R2 assigned writable HOME/XDG data only inside a
  64 MiB tmpfs while retaining a read-only root, read-only artifact mount,
  disabled network, and no-new-privileges; it passed with no diagnostics. Both
  logs are retained, and neither run is labeled native/minimum-spec evidence.
- A sandboxed smoke first failed while opening the normal macOS `user://` log
  location. It was rerun with explicit authorized user-directory access and an
  isolated QA save path; no game defect was claimed.
- The R2/R3 Forward+ comparison exposed a renderer-dependent red/card shift.
  It remains evidence and is not hidden or relabeled as Compatibility output.
- The first R7.1 headed capture stopped because its new GLB had not completed
  editor import. The exact loader correctly refused to fall back. An official
  `--editor --import` run completed all three preserved R7 imports before any
  visual verdict was taken.
- R4 was rejected after its reflection-card cutoff amplified fixed geometry
  into hard highlight islands. R4.1 changed only the bounded card/normal
  uniforms, passed exact smoke, and froze before R7.2 geometry review.
- The first formal V8.6 GPU attempt completed 4,000 frames in about 17.5 seconds,
  before a 30-second Instruments capture could finish. Its report is diagnostic
  only. The harness was changed to publish a capture-ready state and continue
  rendering for a verified 35-second hold before the campaign was attempted
  again.
- Inspecting that aborted trace showed that Instruments can serialize the full
  target launch environment. The task-created raw trace and extracted TOC were
  deleted; their sensitive values were never copied into repository evidence.
  Historical traces remain local-sensitive and must not be uploaded. The new
  runner launches Godot with an explicit minimal allowlist and fails closed on
  credential-like TOC keys. See `docs/metal-trace-security.md`.
- A later formal attempt correctly stopped before capture because a durable
  sibling evidence root was outside `gel_perf.gd`'s write allowlist. The runner
  now requires the safe intersection: a fresh OS-temporary leaf whose canonical
  target is verified. A second pre-capture attempt exposed the macOS
  `/var` -> `/private/var` alias at reservation; a real reservation regression
  test now locks that policy.
- The first complete 30-second A1 recording then exposed an empirical storage
  defect in the capture specification: the incomplete retained trace reached
  8,825,608 KiB while Instruments also held large staging files, reducing free
  space to 4,611,304 KiB. The operator interrupted before A1 publication and
  before any B run, recorded the failure hashes, verified that no Godot or
  xctrace process remained, and removed only the incomplete task-owned trace
  and same-birth-time Instruments staging. This is storage-inconclusive, not a
  V8.5/V8.6 performance verdict. The corrected contract requests an exact
  8-second limit and analyzes 300 contiguous post-warmup frames with stronger
  staged disk gates. No failed
  evidence root may be reused.
- Independent review found that a command-log `appendFileSync` failure could
  previously escape from a stdout/stderr callback before normal campaign
  cleanup. The tracked-command wrapper now captures the first log-write error,
  terminates only the exact owned child through TERM/KILL escalation, returns
  the error in the child result, and lets the outer failure path settle the
  remaining children. A real long-lived Node child with an injected `ENOSPC`
  verifies that it exits and leaves no survivor. The bounded TOC-envelope and
  cleanup regressions remain locked.
- The first fresh plan-only run of the corrected contract then stopped before
  evidence-root reservation with 24,995,209,216 bytes available against the
  25,769,803,776-byte (24 GiB) minimum. The proposed root remained absent. This
  is an operational storage blocker, not a GPU result, and the disk floor must
  not be weakened to force a campaign.
- After macOS automatically reclaimed purgeable space, a fresh plan passed with
  36,229,648,384 bytes free and A1 completed its exact V8.5 workload, 35,006 ms
  hold, and requested 8-second trace. The first TOC contract rejected it before
  B1 because pinned xctrace 17F113 authoritatively recorded 9.745658 seconds
  while still reporting `8 seconds` and `Time limit reached`. Sanitized review
  proved the exact Godot PID appears twice, `metal-gpu-intervals` is present,
  no forbidden environment key exists, and the whole envelope fits the hold.
  Historical time-limit-complete traces consistently include 1.4-1.86 seconds
  of the same recorder overhead. This is a harness-validation failure, not GPU
  evidence. The failed root and manifest remain immutable; the split
  exact-request/bounded-envelope contract must start again in a fresh root.
- A later plan-only preflight stopped before root reservation because the dirty
  worktree's 2,657,667-byte binary diff exceeded Node's old 1 MiB synchronous
  subprocess buffer. Git's staged/unstaged binary fingerprints now have a
  separate bounded 16 MiB ceiling, with a real greater-than-1-MiB Git regression;
  ordinary subprocesses retain the smaller default bound.
- R6 A1 then completed its exact V8.5 4,000-sample workload, 35,005 ms hold,
  requested 8-second trace, and 300-frame window. The old analyzer reported
  seven malformed target rows and stopped before B1. Forensic inspection proved
  that all seven were valid nullable Frame-column sentinels near 8.52 seconds,
  outside selected frames 61-360. The immutable R6 root and failed manifest were
  preserved. Read-only reanalysis to a separate temporary output yields 22,860
  target rows = 18,670 channel top-level + 4,183 nested + 7 unframed + 0
  malformed, with zero analyzed-window overlap and unchanged mean/p95/max of
  7.127/7.488/9.540 ms. Positional row parsing, ref-form exclusivity, resolved
  and consistent process identities, duplicate-ID rejection, and exact
  immediate/final accounting now have adversarial regressions. This is parser
  diagnosis, not an A/B verdict; at that point the next campaign still needed a
  new root, which the successful R7 campaign above subsequently fulfilled.

## Honest promotion state

R7.2, final multi-angle/motion review, Web export/mounted probe, the 138/138
regression suite, independent code review, and the fresh R7 formal GPU campaign
now pass. The review reports zero critical and zero important findings; its two
stale-comment notes were also corrected. All repository-controlled technical
promotion gates defined by this specification are closed. Commercial/public
promotion additionally requires a human rights-holder signature for the
concept/reference and store assets, native target and minimum-spec evidence,
publisher IDs, signing and notarization identities, Steamworks/Valve processing,
human QA, and explicit owner authorization. Codex cannot manufacture those
external approvals.
