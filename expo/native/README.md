# Native parity inputs

This directory owns the retained native inputs for the Expo development build.
`parity-contract.json` contains the identities and local inputs that must not
drift during prebuild; it has no Flutter-tree source dependency.

- `ios/WarWidget` is the retained WidgetKit extension source and entitlements.
- `ios/alternate-icons` contains the three alternate app icon catalogs.
- `android/app/src/main` contains both widget providers, the configuration
  activity, and every referenced layout, drawable, value, XML, and mipmap.
- `android/splash` contains the shipping light/dark density resources. The finalized config-plugin stage
  overwrites Expo's generated Android splash PNGs so pre-Android-12 and Android
  12 launches keep their distinct shipping artwork.

Android installed-user auth continuity uses an exact vendored copy of
`flutter_secure_storage` 10.3.1 in the local Expo module. Its default
`FlutterSecureStorage` preferences name, encoded key prefix, algorithm markers,
Tink compatibility path, and Android Keystore aliases are preserved. Standard
upstream cipher migration can update those storage files during initialization,
but `resetOnError` remains false and the bridge never guesses or deletes a value
after a failed read.
