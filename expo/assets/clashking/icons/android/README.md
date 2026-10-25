# Android adaptive launchers

All five launcher aliases use `mipmap` adaptive-icon resources on
Android 8+ instead of whole square PNGs. Full-icon PNGs remain the legacy
fallback. The Halloween fallback and iOS icon now use a flat purple background
without the original orange halo; see `../app_icon_halloween.source.md`.

- Default foreground: original paths from
  `clashking_assets/assets/logos/crown-arrow-white-bg/ClashKing-2.svg`, scaled to
  66 dp tall in a 108 dp viewport and centered. The background is system white.
- Halloween foreground: transparent extraction from `app_icon_halloween.png`
  using the built-in image editor. It is inset 18 dp in the adaptive layer,
  with a separate solid `#16051E` background. This avoids a square image inside
  the launcher mask.
- Native generation: `copyAndroidLauncherAssets` in
  `plugins/with-clashking-native.js` stages this resource tree and legacy PNGs.
  `configureAndroidLauncherAliases` points every option and the application icon
  at the mipmaps.

- Black & White and Dark Mode use the original vector logo geometry from
  `crown-black-arrow-white-bg/ClashKing-icon-black.svg` and
  `crown-arrow-dark-bg/ClashKing-1.svg`. Both are centered at 66 dp tall.
- Christmas uses a transparent extraction of `app_icon_christmas.png`, inset
  21 dp with a separate white background. The original iOS image is retained.
- All five adaptive icons provide `app_icon_monochrome.xml`. Its arrow shaft
  cuts through the crown as negative space; there is no opaque square backing.
  Android's launcher applies the user's theme colors when Themed icons is
  enabled. This is not a full-color white/black icon switch, and does not require
  the app to run or change the selected alias when the theme changes.

Christmas extraction used the built-in image editor with this prompt:
"Extract the existing Christmas ClashKing logo onto actual transparent
background. Preserve the red crown, white arrow shaft, black feather fletching
and arrowhead, white snow dots, and red Santa hat with white trim and pompom.
Only remove the off-white square background; retain white details within the
logo. Keep proportions, make crisp higher-resolution edges, and add no tile,
border, shadow, or new elements."
Generated source: `exec-e69a05ab-0b7c-43c6-819b-ed5f2b0f7601.png`.

Extraction prompt: Extract only the existing orange crown, ivory shaft, black
feather fletching and black arrowhead, including the cobweb details, onto a fully
transparent square canvas. Remove the purple background and orange halo.
Preserve shape, colors, texture, proportions and centered placement. No square
backplate, shadows, new objects or rounded corners; keep black arrow ends opaque.

Generated source: `exec-7a450af6-1e97-4543-a16d-279ad12e4e27.png`.
The original raster icon and its iOS use are retained.
