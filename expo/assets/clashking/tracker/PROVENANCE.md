# Tracker builder artwork

### Flat-roof correction

Current header: `builder-village-flat-roof.jpg`. Built-in image edit used `builder-village-header.jpg` plus the user's three-view Builder's Hut reference. Prompt changes only the pitched hut roof to a flat plank roof with tools resting on it and preserves the builder, scene, framing and lighting. The generated output was inspected for the flat roof before saving. Prior versions remain preserved; current app references only the corrected asset.

## Reference-guided village header, 2026-10-22

`builder-village-header.jpg` replaces the earlier workshop image. Generated with the built-in tool using four actual asset references: `stickers/Villager_HV_Builder_1.png`, `landscape/Villager_HV_Builder_19.png`, `buildings/home-village/builder's_hut/level_1.webp`, and `buildings/home-village/laboratory/level_1.webp`. The Master Builder reference was inspected but not supplied because the requested Home Village builder is clean-shaven. Prompt requires the exact home builder's orange hair, clean-shaven face, red sleeveless shirt, gold belt buckle and rounded game proportions; hut on left, scaffold on right, open center, no text or UI. Original generation is preserved under the Codex generated_images directory; app copy is 1200 by 800 JPEG. This is reference-guided generated art, not an official Supercell image.

The interactive 3D scene was removed from the tracker at the user's request. Existing source assets below remain provenance records, not current tracker UI.

## Workshop header, 2026-10-22 refinement

`builder-workshop.jpg` is a generated illustration, not extracted official game art. Created with the built-in image generation tool, then resized to 1200 by 800 JPEG. It replaces the reused landscape plus overlaid builder in the tracker header. Prompt: "Premium Clash of Clans-inspired builder workshop at dawn, timber and stone, orange-haired builder with leather apron studying construction blueprints on the left, scaffolding and a defense under construction on the right, quiet center for UI, rounded 3D game-art aesthetic, no text, logos or UI." The interactive builder below remains the authentic extracted model described below.

Generated 2026-10-22 from the locally extracted official game 18.600.1 assets.

- `builder-working.glb`: `sc3d/hvbuilder_default_geo.loda1.glb`, `hvbuilder_default_building.glb`, and `hvbuilder_default_walk.glb`. Includes the real skeletal Building and Walking clips and embedded `builder_default_a.sctx` texture, decoded by the existing ClashKing extractor. Standard glTF 2.0, 10 skinned meshes, no external textures. The tracker currently plays Building; Walking is retained for future movement choreography.
- Geometry and packed animations use `clashking_assets/internal/sc3d/static/viewer.js`, `animation-codec.mjs`, and `weight-codec.mjs`. Texture decoded using the existing `sc-export texture-root` with its ASTC fallback. Standard GLTFExporter packages the result. No game release or extractor scripts were changed.
- `builder-welcome.webp`: authentic FanKit `assets/landscape/Villager_HV_Builder_19.png` from the asset repository, transparent content trimmed and reduced from8192×4608 to720×421,40,818bytes.
- `builder-landscape.webp`: existing `assets/landscape/builder-landscape.png` converted to WebP at its original717×410,75,652bytes.

Native rendering reuses BundledModelScene. Only one worker is mounted on the active village screen; playback pauses when the app backgrounds or reduced motion is enabled. This is an actual animated3D worker beside the real upgrade building artwork, not a fully3D village reconstruction. Native visual verification remains pending.
