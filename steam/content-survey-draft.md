# Steam content survey — owner-review draft

This is a truthful drafting aid, not a completed Steamworks submission. The
account owner must inspect the exact final build and marketing files, answer all
regional/adult-content questions in Steamworks, confirm rights, and update this
draft if any asset changes.

## General content summary

- Stylized microscopic combat between cartoon immune cells and fictional
  pathogens.
- Combat uses health bars, projectiles, flashes, and defeat effects; there is no
  realistic blood, gore, sexual content, gambling, drug use, or user-generated
  online interaction in the current build.
- The game has no spoken dialogue and does not connect players to one another.

## Generative AI disclosure draft

Category: **Pre-generated content**. Runtime generation: **None**.

Suggested detailed description for owner review:

> Pre-generated AI tools assisted with development references, marketing
> visuals, and text drafting. All six shipping character bodies and their
> visible wet-jelly lighting, internal flow, micro-height, coat, and membrane
> response are authored procedurally in Godot. Earlier Meshy and Tripo hero
> experiments remain in source history but are explicitly excluded from every
> release package and are not used in the final screenshots. A later V8.5
> project-authored sculpt candidate uses only deterministic numeric geometry
> parameters and no provider mesh or concept-image pixels; it also remains
> excluded pending owner concept/reference-rights approval. Steam marketing
> key art was generated for this project
> with OpenAI image generation and then cropped/composited into the required
> capsule and library formats; the transparent wordmark and icons are
> code-native/project-authored. A subset of research/character concept imagery,
> plus English and Traditional Chinese UI/store copy, received AI-assisted
> generation or drafting and human review. The released product performs no
> generative AI inference and sends no player input to an AI service.

Evidence:

- `godot/immune/characters/base_b/ASSET_PROVENANCE.md`
- `godot/immune/characters/base_b/CHAR-BASE-B-meshy-t2.glb`
- `godot/immune/characters/base_t/ASSET_PROVENANCE.md`
- `godot/immune/characters/base_t/CHAR-BASE-T-tripo-5k.glb`
- `godot/immune/characters/base_t/CHAR-BASE-T-v8-4-single-mass-r1.glb`
- `godot/immune/characters/base_t/CHAR-BASE-T-v8-5-authored-sculpt-r4.glb`
- `tools/meshy/build_t_v8_5_authored_sculpt.py`
- `steam/assets/source/immune-key-art-landscape-v1.png`
- `steam/assets/source/immune-key-art-portrait-v1.png`
- `steam/assets/source/immune-wordmark.svg`
- `steam/assets/README.md`

## Owner confirmations still required

- Resolve every conditional row in `asset-rights-register.md`, especially the
  generated Steam key art and final bilingual text review.
- Confirm the rights to every source/reference image used by OpenAI image
  generation and any other shipping or marketing art. Meshy/Tripo development
  assets must remain excluded unless their separate rights chains are resolved.
- Confirm whether any final audio, narrative, localization, replacement art, or
  store material adds further AI-assisted player-consumed content.
- Confirm that the store page and final build show consistent assets.
- Complete every current Steamworks survey field before review. Steam states
  that the survey is checked against both the submitted build and store page.

Official reference:
<https://partner.steamgames.com/doc/gettingstarted/contentsurvey?language=english>
