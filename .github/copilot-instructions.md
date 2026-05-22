# Copilot instructions for ClashKing App

## Build, test, and lint commands

Use the Flutter CLI from the repository root.

- `flutter pub get` - install dependencies
- `flutter analyze` - run the Dart/Flutter analyzer
- `flutter test` - run the full test suite
- `flutter test test\path_to_test.dart` - run a single test file
- `flutter test --plain-name "test case name"` - run one named test
- `flutter build apk --release` - build the Android APK
- `flutter build appbundle --release` - build the Android Play Store bundle
- `flutter build web --release` - build the web app
- `flutter build ios --release --no-codesign` - build the iOS app artifact used before archive/signing in CI

The repo currently includes `flutter_test` and `integration_test` in `pubspec.yaml`, but there are no committed `test\` or `integration_test\` files yet.

## High-level architecture

- `lib\main.dart` is the real app bootstrap. It loads backend public config first, initializes Sentry, Android Workmanager/home-widget support, deep-link handling, and then registers the app-wide providers with `MultiProvider`.
- `lib\core\app\my_app.dart` builds `MaterialApp`, applies the custom light/dark themes, wires generated localization delegates, and starts at `StartupWidget`.
- `lib\features\auth\presentation\startup_widget.dart` is the app gate. It initializes auth, loads the saved selected account, hydrates feature data, and then routes to login, add-account, or the main app shell. Network failures here should surface `ErrorPage` instead of logging the user out.
- `lib\core\app\my_home_page.dart` is a 3-tab `PageView` shell: Dashboard, Clan, and War/CWL. These tabs are thin; they mostly read provider state and use `CocAccountService.refreshPageData(...)` for pull-to-refresh.
- `lib\features\coc_accounts\data\coc_account_service.dart` is the orchestration hub for app data. It fetches linked CoC accounts, restores/persists the selected player tag, calls the bulk `/app/initialization` endpoint, fans the response out to `PlayerService`, `ClanService`, and `WarCwlService`, then links relationships across those models. If the bulk endpoint fails, it falls back to the older per-service API calls.
- `lib\features\player\data\player_service.dart` owns player profiles plus player-specific war stats. `lib\features\clan\data\clan_service.dart` owns clan details, join/leave data, capital history, war logs, and clan war stats. `lib\features\war_cwl\data\war_cwl_service.dart` owns current war/CWL summaries keyed by clan tag.
- `lib\core\app\my_app_state.dart` is separate from the feature services. It handles locale selection and Android home widget background refresh behavior.

## Key conventions

- This app depends on a sibling backend repo at `..\clashkingAPI`. When a change touches API contracts or app initialization payloads, inspect both repositories.
- Keep the provider/`ChangeNotifier` architecture. Most screens use `context.watch<T>()`, `context.read<T>()`, or `Consumer<T>` against the services registered in `main.dart`; avoid introducing a parallel state-management pattern for feature work unless the existing structure truly cannot support it.
- Prefer the bulk initialization flow over ad hoc per-page fetches. Refreshes in Dashboard, Clan, and War/CWL are expected to go through `CocAccountService.refreshPageData(...)` so the shared provider state stays consistent across tabs.
- Add new localization keys to `lib\l10n\app_en.arb`. `l10n.yaml` sets `app_en.arb` as the template file; do not treat `app_en_US.arb` as the source of truth. UI strings should use generated `AppLocalizations`.
- Shared persisted app data uses the helpers in `lib\core\functions\functions.dart`, which wrap `FlutterSecureStorage`. The selected player tag and widget-related clan-tag cache are stored there.
- Switching the selected account has widget side effects on mobile. `CocAccountService` persists `selectedTag`, compares cached `player_<tag>_clan_tag` values, and refreshes the Android war widget if the clan changed.
- For startup and refresh error handling, preserve the authenticated state on network failures and route the user to `lib\common\widgets\error\error_page.dart` with retry behavior instead of surfacing raw socket/hostname errors.
- Use `lib\core\utils\debug_utils.dart` for debug logging patterns already used across services (`debugInfo`, `debugApi`, `debugWarning`, etc.) instead of adding unscoped prints.
- For user-facing changes and bug fixes, also update `update-news\whatsnew-en-US`. The Play Store deployment workflow publishes release notes from the `update-news` directory.
