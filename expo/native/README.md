# Native inputs and compatibility

This directory contains persistent native inputs for Expo prebuild. The generated
`expo/ios` and `expo/android` directories are disposable; make durable changes in
`app.config.ts`, `plugins/`, `native/`, or `modules/clashking-native/`.

`parity-contract.json` records bundle identities and the native inputs consumed by
`with-clashking-native`. Keep its widget and alternate-icon staging enabled. The
Firebase files are `config/firebase/GoogleService-Info.plist` and
`config/firebase/google-services.json`. Platform versions come from app config
and the installed Expo SDK; do not copy old compile/target SDK pins from handoffs.

- `ios/WarWidget` owns the WidgetKit source, privacy manifest and entitlements.
- `ios/alternate-icons` owns the alternate app icon catalogs.
- `android/app/src/main` owns widget providers, configuration activities and
  their resources.
- `android/splash` owns the shipping light/dark splash resources staged after
  Expo's defaults.

## Widget data

Write payloads with `setWidgetValue`, then call `reloadWidgets` after the batch.
Payload keys must match the native readers. Startup/resume consumes pending
Android widget actions through `consumePendingWidgetAction`.

## Installed-user auth and preference migration

Read `readSharedAuthSession` before falling back to interactive sign-in. Session
refresh uses `acquireSharedAuthRefreshLock` and releases the lock in `finally`.
iOS retains the shipping shared Keychain access group.

Android retains the vendored `flutter_secure_storage` 10.3.1 implementation,
including its preferences name, encoded key prefix, algorithm markers, Tink
compatibility path and Keystore aliases. Keep `resetOnError` false: a failed read
must not silently erase an installed user's credentials.

Enumerate legacy secure values with `readAllLegacyFlutterSecureValues` and
non-secure preferences with `readAllLegacyFlutterPreferences`. Preserve dynamic
keys such as `player_*_clan_tag`, filter through the existing preferences
allowlist, and persist each destination value before deleting its source. The
native enumeration functions themselves must never delete source values.
