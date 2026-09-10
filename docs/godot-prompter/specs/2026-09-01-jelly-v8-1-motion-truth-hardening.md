# Jelly V8.1 motion-truth hardening

Date: 2026-09-01
Base checkpoint: `5d9a3663b28f75b2875281702805657b30785d06`
Status: local additive development version; not pushed, tagged, signed,
notarized, or published

## Outcome

V8.1 keeps the reviewed V8 gummy-glass look and living internal flow, then
hardens how that presentation follows real gameplay. The stable
`CollisionShape3D` still owns control and collision. The visible mass, shell,
eyes, mouth cavity, duty attachments, and effect-release point now respond as
one viscous body.

The key change is authority: locomotion presentation follows post-physics
resolved displacement. Requested velocity is retained only to describe pressure
against a wall. A blocked character therefore compresses against contact without
playing a walk loop in place.

V8.1 is selected by either:

```text
immune/visual/gel_look="v8_1"
IMMUNE_GEL_LOOK=v8_1
```

The exact V8 rollback selector remains `IMMUNE_GEL_LOOK=v8`.

## Animation inventory

V8.1 has 12 generated clips per character. The eight historical clips remain:

```text
idle, plant, uproot, move, hit, attack, relay_open, relay_close
```

Four clips are additive and exist only under V8.1:

| Clip | Length | Role |
|---|---:|---|
| `move_start` | 0.28 s | Two-frame-debounced viscous acceleration edge |
| `move_stop` | 0.52 s | Three-frame-debounced braking and settle edge |
| `relay_glide` | 1.60 s | Family A's low-frequency hover translation loop |
| `skill_cast` | 0.96 s | Readable active-skill gather and release |

The basic `attack` clip releases at 0.345 seconds. `skill_cast` releases at 0.48
seconds. Both use one AnimationPlayer method key, and gameplay commits only when
the matching request token reaches that key. Visual cancellation before the key
does not apply damage or consume an auto-fire shot. V8.1 processes method keys
immediately so a low-render-FPS advance that crosses both release and clip end
still releases exactly once before `animation_finished`; explicit V8 restores
the scene's deferred callback mode.

Explicit V8 still has exactly the original eight clips, a method-track-free
`attack`, the legacy WeaponSocket hierarchy, and no V8.1 attachment or contact
controller state.

## Runtime contracts

### Resolved motion and reversal

Combat submits requested velocity, resolved velocity, contact normal, and the
physics delta after `move_and_slide()` and arena clamps. The character uses
resolved velocity for locomotion blend, direction, and start/stop state. A
bounded planar angular controller handles exact 180-degree reversals without
lerping through a zero vector. Equal-duration 30, 60, and 120 Hz simulations
must converge within the smoke tolerance. Motion-truth freshness is measured in
missed physics ticks rather than render delta, so an 80–100 ms rendered frame
cannot erase the newest normal-rate physics sample.

### Contact and settling

Requested velocity into an opposing contact normal produces a short
compression/rebound envelope while resolved zero velocity keeps locomotion
idle. The response must return to zero, with no residual lag or squash, and the
collision transform and shape must remain identical throughout.

### Coherent visual rig

The wet core, clear shell, eye surfaces, and V8.1 mouth cavity share inert-by-
default body-space deformation uniforms. V8.1 enables and updates those values
per instance. Duty props move through `LiquidAttachmentAnchor`; gameplay VFX
emit from `WeaponSocket/LiquidReleaseAnchor`. This prevents the eyes, mouth,
weapon effect, and kit from appearing to float away from the deforming slime.
Internal circulation, slime volume, fibres, and inclusion fields also sample one
shared body-space coordinate across overlapping primitives; locally attached
membrane relief, dimples, and bubbles retain the legacy object coordinate.

### Animation ownership

One priority arbiter owns one-shot presentation. Terminal state outranks active
skill, hit, basic attack, duty transform, locomotion edges, and rest loops. An
active skill may pre-empt an unreleased basic attack, while a visible duty
transformation receives one bounded active-skill buffer. Rest and movement loops
cannot overwrite a higher-priority one-shot.

## Automated coverage

`tools/smoke.gd` now checks:

- exact V8.1 and V8 clip sets, lengths, loop modes, and method-marker times;
- no basic or active gameplay release before the authored pose, and exactly one
  release after it;
- one low-render-FPS advance crossing both the release marker and clip end,
  requiring exactly one release and no `missing_release` cancellation;
- normal 60 Hz physics truth surviving a deliberately slow 100 ms render frame;
- two-frame start debounce, `move_start` hand-off, three-frame stop debounce,
  and `move_stop` settling;
- Family A hand-off from `move_start` to `relay_glide`;
- non-collapsing, frame-rate-consistent 180-degree direction reversal at
  30/60/120 Hz;
- wall pressure driven by requested velocity while locomotion stays bound to
  resolved zero velocity;
- complete contact/lag/squash settling with unchanged collision;
- coherent body-space values across wet core, shell, eyes, and mouth cavity;
- a deformation-following release anchor and VFX emission binding;
- explicit V8 rejection of V8.1 tokenized actions, clips, anchors, attachment
  materials, turn shear, and contact response;
- combat-lane active damage occurring after the live `skill_cast` release key.

## Local verification

Verified with official Godot `4.6.1.stable.official.14d19694e`:

```sh
godot --headless --path godot/immune --editor --quit --audio-driver Dummy

godot --headless --path godot/immune --script res://tools/smoke.gd -- \
  --save-path=<absolute-file-below-OS-temporary-root>

IMMUNE_GEL_LOOK=v8 godot --headless --path godot/immune \
  --script res://tools/smoke.gd -- \
  --save-path=<absolute-file-below-OS-temporary-root>
```

The default V8.1 smoke and every explicit V5–V8 rollback smoke report
`SMOKE_OK`.
This is automated implementation evidence, not a substitute for motion-quality
review, exported Web/native soak, minimum-spec hardware testing, platform SDK
integration, signing, or owner-authorized publication.
