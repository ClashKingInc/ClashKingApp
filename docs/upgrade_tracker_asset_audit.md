# Upgrade Tracker Asset Audit

Audit date: 2026-07-11. Source snapshot: `Magic Jr. (#2J8V28GV0)`. Source of truth: the current local `clashking_assets/assets` tree.

The tracker resolved every parsed upgrade, collection, and resource URL against the asset repository. Builder Base Battle Machine and Battle Copter were initially routed through building paths; the parser now correctly uses their hero icons.

## Missing source assets

These five expected files do not currently exist in the assets repository, so the app's existing image fallback is used:

- `buildings/home-village/blacksmith/level_10.webp`
- `buildings/home-village/bob's_hut/level_1.webp`
- `buildings/home-village/helper_hut/level_1.webp`
- `buildings/builder-base/army_camp/level_1.webp`
- `buildings/builder-base/reinforcement_camp/level_1.webp`

No tracker-side alias or substitute image was invented. The correct fix is to add/export those assets from `clashking_assets`, after which the existing URLs will begin working without an app change.
