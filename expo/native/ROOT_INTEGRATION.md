# Root integration complete

The retained native foundation is self-contained under `expo/native` and is
enabled by the root-owned Expo configuration.

## App config

- `stageIosWidgetInputs: true` stages and embeds the exact
  `WarWidgetExtension` target with its shipping bundle identifier, App Group,
  Keychain entitlement, deployment target, sources, and privacy manifest.
- `stageAndroidWidgetInputs: true` stages both providers, the
  configuration activity, Kotlin sources, resources, and widget-action
  receiver.
- Keep `stageAlternateIcons: true` and
  `contractPath: './native/parity-contract.json'`.
- Keep the Firebase files at `./config/firebase/GoogleService-Info.plist` and
  `./config/firebase/google-services.json`.
- Keep `@clashking/native` as a local dependency and keep iOS 17.0, Android min
  SDK 24, and compile/target SDK 36 in `expo-build-properties`.

The resulting plugin entry should be:

```json
[
  "./plugins/with-clashking-native",
  {
    "contractPath": "./native/parity-contract.json",
    "stageAlternateIcons": true,
    "stageIosWidgetInputs": true,
    "stageAndroidWidgetInputs": true
  }
]
```

## Application calls

The widget services write the same string keys consumed by the retained widgets
(`warInfo` and the upgrade payload/selection keys) with `setWidgetValue`, then
call `reloadWidgets()` after committing a batch. Application startup/resume
consumes `consumePendingWidgetAction()` so an Android widget refresh click
triggers the same application refresh flow.

Auth bootstrap calls `readSharedAuthSession()` before falling back to
interactive sign-in. Refresh/session replacement is wrapped in
`acquireSharedAuthRefreshLock()` and releases the lock in a `finally` block.
Android uses the vendored, exact `flutter_secure_storage` 10.3.1 implementation
and iOS uses the shipping shared Keychain access group.

Preference migration uses `readAllLegacyFlutterSecureValues()` so dynamic keys
such as `player_*_clan_tag` are included, filters the result to the existing
AppPreferences allowlist/pattern, persists each value, and only then deletes it
through the destination storage API. `readAllLegacyFlutterPreferences()` is the
equivalent enumerator for the old non-secure Flutter preferences file. The
native enumeration calls never delete source values.
