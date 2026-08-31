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

> Pre-generated AI tools assisted with limited visual and text content. The
> shipping B-cell base mesh was created from a project-owned reference image
> using Meshy Image-to-3D Smart Topology (`meshy-t2`) and then locally processed
> to restore smooth normals. Meshy texturing was disabled; the visible jelly
> material is authored in Godot. Steam marketing key art was generated for this
> project with OpenAI image generation and then cropped/composited into the
> required capsule and library formats; the transparent wordmark and icons are
> code-native/project-authored. English and Traditional Chinese UI/store copy
> received AI-assisted drafting and human review. The released product performs
> no generative AI inference and sends no player input to an AI service.

Evidence:

- `godot/immune/characters/base_b/ASSET_PROVENANCE.md`
- `godot/immune/characters/base_b/CHAR-BASE-B-meshy-t2.glb`
- `steam/assets/source/immune-key-art-landscape-v1.png`
- `steam/assets/source/immune-key-art-portrait-v1.png`
- `steam/assets/source/immune-wordmark.svg`
- `steam/assets/README.md`

## Owner confirmations still required

- Confirm the rights to every source/reference image used in the B-cell Meshy
  task and in all other shipping art.
- Confirm whether any final audio, narrative, localization, or replacement art
  adds further AI-assisted player-consumed content.
- Confirm that the store page and final build show consistent assets.
- Complete every current Steamworks survey field before review. Steam states
  that the survey is checked against both the submitted build and store page.

Official reference:
<https://partner.steamgames.com/doc/gettingstarted/contentsurvey?language=english>
