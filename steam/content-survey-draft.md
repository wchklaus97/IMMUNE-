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

> Pre-generated AI tools assisted with visual and text content. The shipping
> B-cell base mesh was created from a project reference image using Meshy
> Image-to-3D Smart Topology (`meshy-t2`) and then locally processed to restore
> smooth normals. The shipping T-cell uses a Tripo remesh and its baked colour
> as a feature mask. The visible wet-jelly lighting, micro-height, coat, and
> membrane response are authored in Godot; the M/N/A/D bodies are project-coded
> procedural models. Steam marketing key art was generated for this project
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
- `steam/assets/source/immune-key-art-landscape-v1.png`
- `steam/assets/source/immune-key-art-portrait-v1.png`
- `steam/assets/source/immune-wordmark.svg`
- `steam/assets/README.md`

## Owner confirmations still required

- Resolve every conditional/blocked row in `asset-rights-register.md`, including
  the missing Tripo task receipt and the undocumented audio source sessions.
- Confirm the rights to every source/reference image used by Meshy, Tripo,
  OpenAI image generation, and all other shipping art.
- Confirm whether any final audio, narrative, localization, replacement art, or
  store material adds further AI-assisted player-consumed content.
- Confirm that the store page and final build show consistent assets.
- Complete every current Steamworks survey field before review. Steam states
  that the survey is checked against both the submitted build and store page.

Official reference:
<https://partner.steamgames.com/doc/gettingstarted/contentsurvey?language=english>
