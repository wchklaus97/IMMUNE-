# IMMUNE all-family campaign soak and Metal GPU evidence

Status: implemented and passed locally on 2026-08-29 with Godot 4.6.1. The
project and CI target remain Godot 4.7.2 stable.

## Purpose

Close two release-readiness gaps without overstating the evidence:

1. exercise every family across every authored mission for substantially longer
   than the bounded CI sentinels; and
2. obtain a real non-zero GPU timing result when Godot's viewport GPU timer
   returns zero on Apple Metal.

This is automated deterministic playtest evidence. It proves runtime stability,
balance contracts, and measured rendering cost; it does not replace human
fun/readability/accessibility feedback.

## Telemetry v2

`CombatPlaytestTelemetry` remains opt-in, memory-only, and never uploads data.
Schema v2 adds:

- display server and rendering driver;
- one-second performance sampling after a 120-physics-frame warm-up;
- mean/min/5th-percentile FPS, process and physics monitor observations;
- maximum draw calls, rendered objects, static memory, and object count; and
- a separate cold-start bucket so shader/pipeline startup is not silently mixed
  into steady-state values.

Godot documents that some built-in monitors may update as slowly as once per
second. The harness therefore samples once per simulated second. `TIME_PROCESS`
is retained as a diagnostic observation but is not a hard gate in this
SceneTree harness because it did not agree with measured FPS and wall/game time.

## All-family soak contract

Run headed on the shipping Compatibility renderer at real `1.0` time scale:

```bash
godot --path godot/immune --rendering-method gl_compatibility \
  --script res://tools/balance_matrix.gd -- \
  --soak \
  --out=/absolute/path/all-family-campaign-soak-20260829.json
```

Soak mode selects all six missions and T/B/M/N/A/D, uses one deterministic seed
per pair, checkpoints JSON after every run, and stops after the first run-level
contract failure. Final gates are:

- exactly 36 completed runs;
- every run reaches victory and defeats one boss;
- real shots and hits, valid accuracy, surviving Core, and both applicable
  duties in every run;
- a strictly increasing M1 < M2 < M3 < M4 < M5 < M6 duration ladder for every
  family;
- at least 1,800 aggregate simulated seconds;
- maximum wall/game ratio at most 1.25; and
- steady-state 5th-percentile FPS at least 30 whenever the renderer exposes it.

### Result

Local report (ignored generated evidence):
`outputs/playtests/all-family-campaign-soak-20260829.json`.

| Metric | Result |
|---|---:|
| Runs / victories | 36 / 36 |
| Aggregate game time | 2,048.902 s (34.15 min) |
| Aggregate wall time | 2,043.823 s (34.06 min) |
| Maximum wall/game ratio | 1.007 |
| Minimum Core | 6 / 12 |
| Mean projectile accuracy | 99.1% |
| Minimum steady p05 FPS | 111 |
| Maximum draw calls | 348 |
| Maximum rendered objects | 431 |
| Peak static memory | 56.145 MB |
| Maximum object count | 2,263 |
| Timeouts / failures | 0 / 0 |

The cold-start bucket saw a one-frame monitor value of 1 FPS and process spikes
while pipelines were being created. That value is preserved in the report, but
is not presented as steady gameplay performance.

## Metal GPU timing

### Built-in timer boundary and fixed stall

Godot's `viewport_get_measured_render_time_gpu()` returned `0.000 ms` for all
samples on this Apple M4 Pro under Compatibility/OpenGL-on-Metal, Forward
Mobile/Metal, and Forward+/Metal. `gel_perf.gd` now reports this explicitly with
`gpu_timer_available=false` and writes a machine-readable JSON report.

An attempted Forward+ run with `force_sync()` inside every `frame_post_draw`
continuation stalled. The harness now performs at most one pre-measure drain,
before awaiting render signals. The same Forward+ command then completed in
under two seconds for a 60-frame probe.

### Instruments method

Use Xcode Instruments to capture complete Metal GPU events:

```bash
xcrun xctrace record \
  --template 'Metal System Trace' --time-limit 12s --no-prompt \
  --output /absolute/path/gel-forward-plus.trace \
  --launch -- /opt/homebrew/bin/godot \
  --path /absolute/path/godot/immune --rendering-method forward_plus \
  res://tools/gel_perf.tscn -- \
  --family=B --count=10 --frames=1200 --material=gel --sync=false

xcrun xctrace export --input /absolute/path/gel-forward-plus.trace \
  --xpath '/trace-toc/run[@number="1"]/data/table[@schema="metal-gpu-intervals"]' \
  --output /absolute/path/gel-gpu-intervals.xml

node tools/analyze_metal_gpu_trace.mjs \
  --input=/absolute/path/gel-gpu-intervals.xml \
  --process=godot --pid=<PID_FROM_TRACE_TOC> \
  --drop-frames=60 --max-frames=370 \
  --baseline=/absolute/path/standard-gpu-report.json \
  --out=/absolute/path/gel-vs-standard-gpu-report.json
```

The analyzer streams the exported XML, resolves Instruments `id`/`ref`
references, filters one exact process/PID, and groups top-level events by Metal
frame. Per-frame GPU span is `max(event end) - min(event start)`, so overlapping
Vertex/Fragment/Compute events are not double-counted. Its synthetic overlap and
reference-resolution test runs in CI.

### Matched 370-frame result

Hardware: Apple M4 Pro. Renderer: Forward+/Metal. Scene: ten B bodies at the
project's 1920×1080 viewport. Both reports drop 60 warm-up frames and analyze
370 frames.

| Material | Mean | p50 | p95 | Max |
|---|---:|---:|---:|---:|
| StandardMaterial3D | 4.805 ms | 4.225 ms | 7.632 ms | 12.039 ms |
| Wet gel | 5.645 ms | 5.289 ms | 7.986 ms | 8.249 ms |
| Wet-gel delta | +0.840 ms (+17.5%) | +1.064 ms (+25.2%) | +0.354 ms (+4.6%) | -3.790 ms |

The longer gel-only sample contains 1,164 analyzed frames: 6.464 ms mean,
8.093 ms p95, and 13.087 ms max. All observed values remain below the 16.6 ms
60-FPS whole-frame budget, but GPU span is only one part of that budget.

The Standard trace reached the fixed 12-second Instruments limit and the target
was terminated after 430 observed frames; 370 completed post-warm-up frames were
still available. The comparison therefore deliberately matches the first 370
post-warm-up gel frames. It is evidence for this Mac and Forward+ workload only,
not a universal claim for Compatibility, Web, or other GPUs.

Raw `.trace` and exported XML files are large ignored local artifacts and are not
committed.
