# V8.5 GPU material-inventory fix

Date: 2026-09-03  
Branch: `feature/v8-5-reference-sculpt`  
Baseline: `c559823`  
Status: local candidate verified; V8.3 remains the shipping default

## Outcome

The V8.5 T character now owns one visible wet core material and one explicit
membrane material at runtime. The legacy `CoreMesh` sphere is removed when the
authored GLB is realized, but `KitBlockout` had already attached wet-core and
membrane materials to that node. The meshless node did not draw another
character; however, the liquid-flow collector still discovered and updated its
two invisible materials every frame.

`character_root.gd` now clears the meshless legacy material bindings only for
the opt-in V8.5 T profile. The smoke contract requires exactly one wet material
and one shell material for that profile. V8.3 and V8.4 paths are unchanged.

## Red/green evidence

The first focused test correctly failed with:

```text
CHAR-BASE-T V8.5 single mass must bind exactly one wet core and one explicit
membrane; got wet=2 shell=2
```

Evidence:

- red: `outputs/v8-5-candidate-gpu-visual-lock-c559823-r4/tests/red-material-inventory.log`
- green: `outputs/v8-5-candidate-gpu-visual-lock-c559823-r4/tests/green-material-inventory.log`
- final V8.3/V8.4/V8.5 smokes: `outputs/v8-5-candidate-gpu-visual-lock-c559823-r4/tests/final-smoke-v8_3.log`, `final-smoke-v8_4.log`, and `final-smoke-v8_5.log`
- Godot 4.7.2 editor import: `outputs/v8-5-candidate-gpu-visual-lock-c559823-r4/tests/final-import.log`

The 20-character profiler inventory changed from 40 wet plus 40 shell
materials to the intended 20 wet plus 20 shell materials. Visible mesh count
remained 140; this confirms the defect was duplicate runtime material state,
not a second rendered character.

## Real-GPU result

The formal Forward+/Metal run used Godot 4.7.2, 1920x1080, 20 production T
characters, 60 discarded warm-up frames, and an exact-PID Instruments attach.
Runtime self-report, Instruments PID, and the trace process path all agree on
the explicit Godot 4.7.2 binary.

| Sample | Mean GPU | P95 GPU | Max GPU |
|---|---:|---:|---:|
| V8.5 after fix, first 370 measured frames | 6.993 ms | 8.006 ms | 12.757 ms |
| V8.5 after fix, first 1000 measured frames | 7.228 ms | 7.979 ms | 12.757 ms |
| Standard-material control, 1000 frames | 6.329 ms | 8.025 ms | 13.145 ms |

All 1000 observed post-fix V8.5 frames remained under the 16.67 ms 60-FPS
budget on the measured Apple M4 Pro host. Relative to the control, mean GPU
time was 0.899 ms higher while P95 was 0.046 ms lower. These are host-specific
measurements, not a minimum-spec guarantee. Godot's built-in GPU timer returned
zero on this configuration, so no claim is derived from that timer.

Formal evidence is under
`outputs/v8-5-candidate-gpu-visual-lock-c559823-r4/metal/`. Regenerable
Instruments `.ktrace` working files were removed only after the retained trace,
TOC, exported interval XML, reports, and hashes had been verified.

## Workflow failures retained and corrected

1. The first Compatibility QA output used `/tmp`; Godot accepted only the
   macOS per-user temporary root. The failed R1 log was retained and later runs
   used `getconf DARWIN_USER_TEMP_DIR`.
2. `xctrace --launch` resolved the requested Godot 4.7.2 bundle by basename to
   `/Applications/Godot.app` (4.6.1). That trace is retained as invalid R2
   evidence. Formal runs now launch the exact binary directly, capture its PID,
   attach Instruments to that PID, and cross-check the TOC path and runtime
   version.
3. A first duplicate-membrane hypothesis was disproved: the visible body's
   `next_pass` was already null. That passing experiment is retained. Runtime
   material inventory then isolated the actual meshless-material leak.

No failed evidence or earlier character version was overwritten.

## Visual lock

Thirty fresh V8.5 images cover six angles plus eight idle-flow, eight
move-flow, and eight attack frames. The reviewed sheets show one coherent
character with no collapse, detached cells, satellite particles, or extra
character. Idle, walking, and attack states retain liquid-flow and viscous
deformation.

Formal sheets:

- `reference-five-groups-r4-r3.png` — SHA-256 `6f27a776762e6f4a52ac64e2be44c6fccc3aaca3c73055700b28922209c9599a`
- `idle-flow-contact-sheet-r4-r3.png` — SHA-256 `bf9ee137073c1a01c25890b6a6f37cedaf59d659857451abfe0bcf81003c29ff`
- `move-flow-contact-sheet-r4-r3.png` — SHA-256 `26a8e871ffc4f59a078a5fb1d321999c11457be5e30a8953db8fb5787bf1c2e1`
- `combat-contact-sheet-r4-r3.png` — SHA-256 `90dd5a1452f193353eec33e3baea69a51121169a13b6231e229802c9654454f6`

This is a technical visual-regression pass, not final art-direction approval.
Compared with the target reference, the current lower silhouette is narrower,
the body-to-feet transition is harder, the frontal eyes are smaller, and edge
transmission plus broad wet highlights remain weaker.

## Fresh exported candidate

The post-fix `Web V8.5 Candidate` PCK was rebuilt rather than reusing the
baseline artifact:

- path: `outputs/v8-5-candidate-gpu-visual-lock-c559823-r4/export/v8-5-candidate.pck`
- size: 59,312,300 bytes
- SHA-256: `90da8ab7c7ab7373f3773352f266c29dcc22d92263bcf5b8adce4dfc97a9dda0`
- inventory contract: 546 packed resources, verified
- runtime probe: feature active, source default `v8_3`, body 1, shell 1,
  fallback false, loose burst hidden, 14/14 animations

Repository validation also passed 72/72 tool tests, 17 Steam image assets, nine
release-audio assets, the V8.5 export contract, and Steam repository readiness.

## Promotion boundary

The measured-host GPU gate and technical regression gate pass. Promotion is
still intentionally blocked on owner visual approval, reference/asset-rights
signature, minimum-spec or agreed target-hardware testing, and the external
Steam publisher/signing/notarization gates. This work does not change the V8.3
shipping default, push a branch, create a release, or publish a store build.
