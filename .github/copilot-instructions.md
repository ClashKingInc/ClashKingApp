# Copilot instructions for ClashKing App

## Build, test, and lint commands

Run commands from the repository root with the Flutter version in `.flutter-version`.

- `flutter pub get` installs the locked dependencies.
- `flutter analyze` runs the Dart and Flutter analyzer.
- `flutter test` runs the full test suite.
- `flutter test test/path_to_test.dart` runs one test file.
- `flutter build apk --release` builds Android.
- `flutter build ios --release --no-codesign` compiles the complete iOS app and widget extension.

Tests live under `test/` and cover services, models, utilities, request coalescing, preferences, image sizing, and native/fallback Liquid Glass selection. Add focused tests for changed behavior.

## Architecture

- `lib/main.dart` initializes Sentry and platform background support, then registers app-wide providers. Do not add blocking network calls before `runApp`.
- `StartupWidget` restores auth while game data loads cache-first. `AccountBootstrapService` owns the shared post-session account, bookmark, player, clan, war, and widget hydration sequence used by startup and login.
- `ApiService.shared` owns the reusable HTTP transport. `TokenService.shared` owns secure auth tokens, refresh single-flight, and device identity. Do not create a second transport/token stack.
- `AppPreferences` stores non-secret preferences in `SharedPreferences` and migrates legacy values from secure storage. Access and refresh tokens plus the stable device ID remain in secure storage.
- Feature state uses the existing Provider and `ChangeNotifier` modules: `CocAccountService`, `BookmarkService`, `PlayerService`, `ClanService`, and `WarCwlService`.
- Every platform uses `liquid_glass_widgets` through `lib/common/widgets/liquid_glass.dart`; do not add UIKit platform-view glass because it tears during iOS route gestures.
- Android/iOS home-widget coordination is owned by `WarWidgetService` and `WarWidgetSyncService`; avoid duplicate startup refreshes.

## Conventions

- The authoritative backend is `/Users/matthewanderson/PycharmProjects/clashking_api`. Inspect its current contract before changing app-facing routes or payloads.
- Keep network failures from clearing a valid authenticated session. Startup failures should route to `ErrorPage` with retry behavior.
- Use `DebugUtils` for local diagnostic logging and `ErrorReporter` for deduplicated Sentry errors.
- Add localization keys to `lib/l10n/app_en.arb` and use generated `AppLocalizations` in UI code.
- Preserve the tracked `pubspec.lock`, Gradle wrapper, and iOS package resolution files. Dependency upgrades must pass analysis, tests, and platform builds.
- Update `update-news/whatsnew-en-US` for user-facing release changes.
