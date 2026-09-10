# V8.5 promotion sprint evidence

- Date: 2026-09-02
- Branch: `feature/v8-5-reference-sculpt`
- Starting commit: `29d28d3`
- Candidate selector: `IMMUNE_GEL_LOOK=v8_5`, family T only
- Release/default selector: `v8_3` (unchanged)

## Outcome

| Gate | Result | Boundary |
| --- | --- | --- |
| Working disk headroom | PASS | Approximately 19 GiB available at final check; no project/source/history versions removed |
| Five-group reference review | PASS as an opt-in technical visual lock | Human aesthetic preference is still required; this is not a claim of pixel-identical concept reproduction |
| Single-mass/no-satellite integrity | PASS | One connected authored mesh; zero bubble/microbubble/inclusion cues; 86 final visual frames inspected |
| Fourteen-animation acceptance | PASS | 14/14 clips, 56/56 sampled frames |
| Exact-final real-GPU profile | PASS on measured host | Apple M4 Pro, 1920x1080, Forward+/Metal; not generalized to other hardware |
| Repository regression | PASS | Godot import, nine selector smokes, 64 tool tests, Steam art/audio/readiness gates |
| Rights package preparation | PASS | Exact hashes and owner-signable template prepared |
| Owner rights signature | **OPEN** | `steam/asset-rights-attestation-v8.5-template.md` remains awaiting the authorized owner |
| Commercial/default promotion | **BLOCKED** | V8.5 stays opt-in and excluded until rights, owner, platform, publisher, and release gates close |

The technical result is a promoted **development candidate**, not a public or
Steam-ready release. No build was uploaded, no Steamworks state was changed,
and no automation asserted an owner's signature.

## Disk recovery

The sprint began with approximately 743 MiB free, which was below the safe
threshold for Godot import/export and Instruments. Cleanup was restricted to
regenerable products and caches:

- Xcode DerivedData: approximately 5.5 GiB;
- XcodeBuildMCP test products: approximately 5.4 GiB;
- XcodeBuildMCP DerivedData: approximately 5.0 GiB;
- inactive Playwright/updater/SwiftPM caches;
- one exact 2.39 GB Instruments temporary `.ktrace` after the formal trace,
  exported XML, and JSON report were verified;
- `uv cache prune`: 413,345 unused cache files, 10.9 GiB.

The official `uv cache prune` command preserved installed environments and
project files. The codebase knowledge graph, repository, Git history, all prior
V8.5 review directories, and formal GPU evidence remain present. Final `df`
reported approximately 19 GiB available.

## Exact candidate identity

The candidate geometry remains the immutable project-authored r4 asset:

- GLB:
  `godot/immune/characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb`
- SHA-256:
  `8f14cfe59a508df413e4d53218f30bbf316e7e5d31e42154b2916a0bd5669294`
- deterministic builder:
  `tools/meshy/build_t_v8_5_authored_sculpt.py`
- builder SHA-256:
  `7f9ae79363244d0cf30ecf3d6f207ec777f189cf4c31bf00ad1496a8014ec8e5`

The mesh contract remains one node, one mesh, one indexed primitive, 6,002
vertices, 12,000 triangles, one closed connected component, zero boundary or
non-manifold edges, zero degenerate faces, and finite positive signed volume.
No new GLB replaced r4 during this sprint because fair subject-normalized
comparison showed that the dominant remaining difference was the optical
surface, not a broken silhouette.

## Reference lock and surface result

Primary reference:

- `godot/immune/characters/concepts/CHAR-BASE-T-3d-alt.png`
- 1024x1024
- SHA-256:
  `3164ea9567836f98f1fcc96fb2ff0058495b91268f2f1e3ead298a24eab9a65c`

The final `r12-soft-gloss` profile is isolated to exact V8.5. It keeps V8.4
and all older selectors unchanged while adding:

- warm amber body/deep/transmission/rim colours instead of red or magenta
  screen-shaped cards;
- broader, softer wet reflection cards with lower roughness and a stronger
  coat;
- continuous mip-filtered authored height plus restrained analytic orange-peel
  relief;
- time-driven internal core and laminar flow visible during idle and movement;
- a low-alpha edge membrane for transparent thickness without introducing a
  duplicate shell character;
- broader eyes seated at the immutable socket centre;
- an aperture-axis camera gate for the forehead pore, preventing an edge-on
  torus from reading as a detached cell.

All bubble, microbubble, inclusion, fleck, and particle-like cues remain zero.
The pore, eyes, and mouth remain attached presentation marks on the one authored
body; no secondary character mesh is introduced.

### Five review groups

Fresh final-source renders were captured for:

1. front;
2. side;
3. idle with eight elapsed-flow samples;
4. move with eight elapsed-flow samples and velocity `(3, 0, 0)`;
5. combat with eight attack samples.

The fair comparison trims each source around its subject with a 20% background
tolerance and normalizes occupied size before arranging the reference and five
current groups. This prevents the reference's tighter original crop from being
mistaken for a silhouette/scale mismatch.

Evidence:

- root:
  `outputs/v8.5-promotion-sprint/visual-lock-r12-soft-gloss/`
- normalized six-panel comparison:
  `reference-match-five-groups-normalized-r12-r2.png`
- comparison SHA-256:
  `f57ca5c959eb9cd6763b9936cde0157ae97a9f6b9d3800a38b25b2dd1f73637b`
- idle strip SHA-256:
  `607c03780cfc16fcb7ebd1ad4eccf78aaf3b6808bff24ab73a18f5e408fb08a4`
- move strip SHA-256:
  `bbb19f44112d4ca7dee2bc76236cc953df91eca59f7cea7d5f697fa499a138a2`
- combat strip SHA-256:
  `3378c60b7235a36ff203bf92aec4c1b005bbd0bb2a13157a111fd8bbb31e4786`

Each of the 6 angle images and 24 final motion images passed the harness's
nonblank/colour/luminance content contract. Manual contact-sheet review found
one coherent character in every sample, with no collapse, detached cell,
satellite particle, or extra character.

### Honest remaining visual difference

R12 is closer to the primary image in amber colour, eye scale, broad highlight
shape, surface softness, and cohesive single-body presentation. The reference
still has a broader/softer lower silhouette, more glass-like edge transmission,
and larger painted-looking highlight cards. The current real-time result is
therefore a defensible promotion candidate, not a pixel-level replica. A human
owner/art-direction decision remains necessary before changing the default.

All older evidence was preserved, including `baseline-r1`, look-development
r2–r6, visual-lock r7–r10, r11 A/B/C, animation r9, and GPU r1.

## Fourteen-animation acceptance

The exact clip set remains:

`idle`, `plant`, `uproot`, `move`, `hit`, `attack`, `relay_open`,
`relay_close`, `move_start`, `move_stop`, `relay_glide`, `skill_cast`,
`victory`, and `defeat`.

Four samples per clip produced 56/56 content-valid images. Manual review of all
56 frames confirmed that extreme attack, hit, skill, victory, and defeat poses
stay coherent; none splits the body or creates a secondary cell.

Evidence:

- root: `outputs/v8.5-promotion-sprint/animation-acceptance-r12/`
- 56-frame sheet: `all-14-four-frame-contact-sheet.png`
- 56-frame sheet SHA-256:
  `c9afed939962bcb3e6cf951e57070f9142a4096d1963fee493525ac6c837339a`
- 14-keyframe sheet: `all-14-keyframe-contact-sheet-r2.png`
- keyframe sheet SHA-256:
  `cb880bd218e2430d688b11f3eee6589dac980b9dc0639279d58ed4547595ffa0`

## Real-GPU evidence

Measured host boundary:

- MacBook Pro with Apple M4 Pro;
- 20-core integrated GPU, 24 GB unified memory;
- Godot `4.6.1.stable.official.14d19694e`;
- production T `CharacterBody3D`, exact V8.5 selector;
- 1920x1080 viewport;
- 20 character instances in the multi-character run.

### Compatibility/OpenGL-on-Metal

Three exact-final trials sampled 360 post-warm-up frames each. Godot's
Compatibility viewport GPU timer returned zero for every sample, so no GPU
claim is made from these runs.

| Metric | Three-trial aggregate |
| --- | ---: |
| Samples | 1,080 |
| CPU mean (average of trial means) | 1.128 ms |
| CPU p95 (average of trial p95s) | 1.303 ms |
| Wall mean (average of trial means) | 4.256 ms |
| Wall p95 (average of trial p95s) | 5.458 ms |
| Highest observed wall sample | 8.477 ms |

Evidence root:
`outputs/v8.5-promotion-sprint/gpu-profile-r2-final/compatibility/`.

### Forward+/Metal System Trace

Xcode Instruments captured Metal GPU events around an exact-final 1,200-frame
run. The analyzer dropped 60 warm-up frames and analyzed the next 370 complete
target-process Metal frames:

| Metric | Final V8.5, 20 characters |
| --- | ---: |
| Mean GPU frame span | 6.282 ms |
| p50 GPU frame span | 7.398 ms |
| p95 GPU frame span | 8.125 ms |
| Maximum GPU frame span | 13.350 ms |

All analyzed spans remained below 16.67 ms on this host. The earlier matched
standard-material r1 baseline remains preserved; because the captures were not
interleaved and background load can change, the comparison is not used to
claim that the gel shader is faster or slower. This result proves only that the
measured final V8.5 multi-character scene stayed within the whole-frame 60 fps
budget on this Apple M4 Pro workload.

Evidence:

- root: `outputs/v8.5-promotion-sprint/gpu-profile-r2-final/metal/`
- formal trace: `gel-count20-forward-plus-final.trace`
- exported intervals: `gel-count20-gpu-intervals-final.xml`
- analyzer report: `gel-count20-gpu-report-final.json`
- report SHA-256:
  `132b63dfeca40a06dce7bb055d9042d31c751adaacc9acfb6ea0e18d00ab5476`

## Regression and release-preflight results

Final source state passed:

- complete Godot import;
- `SMOKE_OK` for exact selectors V5, V6, V7, V8, V8.1, V8.2, V8.3,
  V8.4, and V8.5 (9/9);
- `npm run test:tools`: 64/64;
- `npm run validate:steam-assets`: 17 assets and 6 gameplay screenshots;
- `npm run validate:release-audio`: 9 assets;
- `npm run validate:steam-readiness`:
  `repository-ready-publisher-gates-open`, 16 rights hashes and 7 external
  gate classes;
- `git diff --check`.

The readiness wording is significant: repository-controlled checks pass, but
publisher/owner/platform gates are still open. The current V8.1 exact native
release artifacts remain historical release evidence; this sprint did not
pretend they were rebuilt from or equivalent to the V8.5 source state.

## Failure-driven workflow corrections

The sprint stopped and corrected its workflow whenever generation failed:

1. A cold Godot scan was initially cut short with `--quit-after 2`, leaving
   imports incomplete. The workflow was changed to an unbounded
   `godot --headless --path godot/immune --import`, which completed.
2. An eye-centre/scale experiment moved the eye beyond the authored socket.
   V8.5 smoke rejected it. The socket centre was restored to `x=0.218`; only a
   conservative lens-scale increase was retained. The contract was not weakened.
3. The first r12 motion command passed a repository `--save-path`; the QA
   isolation contract rejected it because QA state must live below the system
   temporary root. The command was changed to automatic isolated QA state.
4. The second command passed `--ground` to `gel_preview`; the scene-specific
   argument contract rejected it. Unsupported cross-rig options were removed.
   Both failed commands produced zero images.
5. ImageMagick's first contact-sheet command inherited an empty font attribute.
   The six source panels remained valid; the corrected command explicitly set
   Helvetica and cleared label metadata before montage.
6. Instruments created one 2.39 GB temporary `.ktrace`. The formal trace,
   exported XML, runtime JSON, and analyzer JSON were verified first; then that
   exact temporary file alone was removed.

These corrections preserve fail-closed tests and prevent an aborted import,
unsupported preview option, invalid image, or partial GPU capture from being
reported as success.

## Rights/signature state

The complete hash-bound owner package is:
`steam/asset-rights-attestation-v8.5-template.md`.

It inventories five exact T reference images, the V8.5 GLB and builder, the CC0
height source, both OpenAI-generated key-art sources, and the code-native
wordmark. `godot/immune/characters/base_t/ASSET_PROVENANCE.md`,
`steam/asset-rights-register.md`, `steam/assets/README.md`, and
`steam/release-checklist.md` point to the same evidence.

Status remains **AWAITING OWNER SIGNATURE**. The authorized owner must identify
the reference creator/provider/account, attach commercial/input-rights records,
select explicit V8.5 and key-art decisions, sign/date the document, archive the
signed file outside the public repository, and bind its SHA-256 in the private
publisher input. Automation cannot complete that legal act.

## Promotion decision and next gates

V8.5 is technically suitable for continued opt-in playtesting and owner visual
review. It must not replace `v8_3` or enter a commercial depot yet.

Remaining gates include:

- owner visual approval and signed reference/key-art/contributor rights;
- a newly built exact release candidate after any promotion decision;
- native Windows and Linux exact-candidate smoke;
- lower-end/minimum-spec and physical Steam Deck testing;
- human six-family readability, control, difficulty, photosensitivity, and
  appearance sessions;
- real Steam App/depot IDs and reviewed configuration;
- Windows signing if adopted, macOS Developer ID signing and notarization;
- private-branch Steam client install/update/offline/uninstall rehearsal;
- completed content survey, store preview, Valve review, and explicit owner
  authorization to release.

Until those close, the accurate state is: **V8.5 technical promotion candidate
complete; commercial/public promotion blocked**.
