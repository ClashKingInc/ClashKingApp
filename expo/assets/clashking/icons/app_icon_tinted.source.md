# iOS tinted icon

The tinted icon uses the existing white ClashKing crown-and-arrow vector from
`clashking_assets/assets/logos/crown-white-arrow-dark-bg/ClashKing-icon-white.svg`.
The paths remain unchanged. A square black background and matching view box were
added in `app_icon_tinted.svg`; this keeps the light mark in the foreground when
iOS applies its tinted treatment. The manually selected Black & White icon stays
black-on-white and is not changed by this asset.

`app_icon_tinted.png` is a 1024×1024 raster export of that SVG. No generative image
editing was used. Reproduce with Sharp's SVG-to-PNG conversion, then run Expo's
`setIconsAsync` from `@expo/prebuild-config/build/plugins/icons/withIosIcons` to
update the native catalog. Do not run a full prebuild just to update these icons.

The generated tinted image has a black corner and equal RGB channels throughout.
The native catalog assigns it to luminosity `tinted`; light and dark variants
keep their existing source assets. A native build is required to install it.
