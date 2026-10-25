# Original hero models for ClashKing

Exported on 2026-10-18 from official game assets using the existing ClashKing SC3D viewer's decoder, texture converter, skeletal-animation exporter, and standard GLTFLoader validation.

Source fingerprint: `7839fe492f55e0c5cb096b788649cd82f2a99f01`, game version `18.600.6`.

This historical fingerprint was downloaded successfully during this task. It is not asserted to be the newest game version.

Source root: `https://game-assets.clashofclans.com/7839fe492f55e0c5cb096b788649cd82f2a99f01/sc3d/`.

| File | Bytes | Original geometry | Animation clip | Duration |
| --- | ---: | --- | --- | ---: |
| barbarian-king.glb | 2,217,000 | barbking_default_geo.glb | barbking_default_idle1 | 1.633 s |
| archer-queen.glb | 2,251,948 | archerqueen_default_geo.glb | archerqueen_default_menuidle1 | 1.967 s |
| grand-warden.glb | 1,823,584 | grandwarden_default_geo.glb | grandwarden_anim_idle1 | 1.300 s |
| royal-champion.glb | 1,943,192 | royalchampion_default_geo.glb | royalchampion_default_idle1 | 1.300 s |
| minion-prince.glb | 2,424,412 | princeminion_default_geo.glb | princeminion_default_idle1 | 0.967 s |
| dragon-duke.glb | 2,636,872 | dragonduke_default_geo.glb | dragonduke_default_idle1 | 1.633 s |

Each output is a standard GLB v2 with embedded geometry, one embedded PNG texture, skeletons, and one looping-ready animation. No external image or buffer URL is required. Per-file JSON contains source texture paths and the existing converter's loader validation counts.

The original game resources contain a custom FLA2 chunk. These outputs instead contain standard JSON and BIN chunks, confirmed by an independent local header/manifest read. The converter's standard GLTFLoader successfully found all exported skinned meshes, textures, bones, and animation tracks.

For model-viewer: set `autoplay`, select the clip named above with `animation-name`, use a neutral environment, and frame the whole model. Do not apply the achievement viewer's locked/grayscale style. The outer hero carousel should own horizontal swipes; disable model pointer handling during carousel navigation and pause animation for inactive cards and reduced motion. Geometry/runtime validation does not substitute for visual verification on iOS and Android.

No asset-pipeline or published-CDN change was made.

## Local rig repair — 2026-10-18

The app now consumes the `-rigged.glb` variants. Their animation tracks are rebuilt
from the same official source clips, including constant animation-node transforms
instead of geometry bind-pose transforms. This prevents wrists and weapons from
using different poses. All matched joint world positions equal the source clip
at every sampled frame (30–60 samples including the loop seam).

The source converter fix is in `clashking_assets/internal/sc3d/static/viewer.js`.
The King and Queen variants also embed their original normal textures, unpacked
from alpha/green into tangent-space RGB with reconstructed Z at strength 0.65.
Source names: `barbking_default2_01_normal.sctx` and `archerqueen_default_n.sctx`.
Specular maps were inspected but not repurposed without a verified channel contract.
Animated hero scenes use neutral tone mapping and exposure 1.2; badges are unchanged.
New filenames prevent the runtime's module-keyed asset cache from retaining old rigs.
This is a local app asset repair, not a CDN release. Physical-device verification
is still required.
