# Calculator header animation sources

These clips were exported locally with ClashKing Assets' existing Go SC exporter
from the user's Clash of Clans 18.600.1 asset bundle. They are not generated art.

| Bundled file | SC source | Export name | Exported frames | Duration |
| --- | --- | --- | --- | --- |
| fireball-impact.webp | vfx_character.sc | vfx_chr_GW_Explosion | 14 deduplicated | 1250 ms |
| builder-walk.webp | chr_worker.sc | worker_walk1_2 | 8 deduplicated | 667 ms |
| builder-build.webp | chr_worker.sc | worker_build1_2 | 9 deduplicated | 750 ms |
| fireball-flame-loop.webp | vfx_character.sc | vfx_chr_GW_Flames01 | 40 | 1667 ms |
| fireball-smoke.webp | vfx_character.sc | vfx_chr_GW_SmokeA | 16 deduplicated | 1250 ms |
| fireball-glow.webp | vfx_character.sc | vfx_chr_GW_Glow | static | — |

Exporter: `clashking_assets/main.go` and `internal/render`; WebP composition.
The impact uses render-scale 3; Builder clips use render-scale 2. This increases
the render canvas, not the underlying source texture detail. The original game
timelines use 24 fps; duplicate composed frames are coalesced by the exporter.

The Fireball inventory artwork and Hammer of Building remain existing official
assets delivered through ImageAssets. `lightning-bottle.png` is a generated
standalone reconstruction from the Lightning Spell bottle reference, not an
extracted official model. It is retained on disk but no longer displayed.

The flame uses original frames, centered by alpha bounds for attachment to
the UI orb. Original particle travel is not retained. The helper is
`clashking_assets/work/calculator-export-probe/center_flame.py`.

Verified against the bundled `logic/projectiles.csv`: `vfx_chr_gw_Fireball_lvl1`
uses `vfx_chr_GW_Flames01`, `e_chr_gw_fireball_Smoke`, ballistic travel, and
`FixedTravelTime=1500`. The level 2/3 entries reference Flames02/03. Earlier
FireballProjectile entries reference the older buildings.sc/fireball asset.

Tapping the calculator title captures it locally, sends the game flame clip from
the right screen edge (450 ms), splits the title into fragments, and has the
Builder repair it. The first two hits restore the title by 2700 ms. The third hit
has no Builder repair; fragments fade and the title remains absent until the
page is reopened. There is no draggable control, highlight, or idle animation.
The timing is intentionally faster than the game's 1500 ms battle projectile.
Flight, capture fragments and Builder placement are app-authored choreography.
Backgrounding and navigation cancel timers. The third-hit state survives
backgrounding, while leaving the calculator page resets the interaction.
Reduce Motion hides the decorative interaction.

`header-skeleton-spell.png` is an unused earlier user-supplied header image, copied from
`codex-clipboard-cf7f1fa6-e657-4429-946d-c817488f9e58.png`. No pixel edits were made.
