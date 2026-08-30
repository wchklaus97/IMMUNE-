# Jelly micro-height source

`jelly_micro_height.png` is derived from the height channel in ProcTexture's
**Orange Peel Seamless PBR Texture** 1K pack.

- Source page: <https://proctexture.com/textures/plaster/textured/orange-peel>
- Pack URL: <https://proctexture.com/pbr-packs/plaster/orange-peel.zip>
- Source license: CC0 (commercial and personal use; attribution not required)
- Source page version observed: 2026-06-16
- Pack SHA-256: `a95fa0d0acfe71054d8f2ea8993887e39ce4be7190fb9bf1d354088cac6815c0`
- Height member: `plaster-orange-peel-1k/height.png`
- Height SHA-256: `c1b1a860dec8e404588d9aaba1417140148218553b8af9a90fb09293f5f4ae87`

The build script verifies both checksums, resamples the height channel to
512x512, applies a bounded data-level transform, and packs three decorrelated
tileable projections into RGB. No source colour, normal, roughness, or AO data
is shipped or used at runtime.
