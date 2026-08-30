# Copilot instructions for ClashKing App

## Build, test, and lint commands

The shipping app is the Expo SDK 57 project under `expo/`. Run application commands from that directory with Node.js 22.

- `npm ci` installs locked Expo dependencies.
- `npm run lint` and `npm run typecheck` run static checks.
- `npm test` runs the full Jest suite; pass a test path for a focused run.
- `npm run test:native-plugin` verifies the CNG/native parity contract.
- `npx expo-doctor` verifies Expo SDK dependency/config health.
- `npx expo prebuild --clean` generates ignored native projects.
- `npx expo export --platform web --output-dir dist` builds Cloudflare Pages output.

Tests live beside Expo source and under `expo/plugins/__tests__`. Add focused tests for changed behavior and do not edit generated `expo/ios` or `expo/android` projects directly.

## Architecture

- `expo/src/core/app` owns runtime creation, startup coordination, and the app-level provider/context boundary. Do not add blocking network work before startup coordination.
- `AccountBootstrapService` owns shared post-session account, bookmark, player, clan, war, upgrade, and widget hydration.
- `ApiClient` and the auth/session services own transport, token refresh single-flight, and device identity. Do not create a second transport or token stack.
- Feature services own accounts, bookmarks, players, clans, wars, and widgets through their feature modules.
- Native continuity lives in `expo/native/parity-contract.json`, `expo/plugins`, and `expo/modules/clashking-native`. Preserve the app/widget bundle IDs, Apple team, App Group, Keychain group, Android package, Firebase files, widgets, and legacy-storage migration contracts.
- Localization source files live under `expo/src/i18n/arb`; regenerate runtime catalogs with `npm run l10n:generate`.

## Conventions

- The authoritative backend is `/Users/matthewanderson/PycharmProjects/clashking_api`. Inspect its current contract before changing app-facing routes or payloads.
- Keep network failures from clearing a valid authenticated session. Startup failures should route to `ErrorPage` with retry behavior.
- Use `DebugUtils` for local diagnostic logging and `ErrorReporter` for deduplicated Sentry errors.
- Add localization keys to every supported `expo/src/i18n/arb/*.arb` file, regenerate catalogs, and pass `npm run l10n:check`.
- Preserve `expo/package-lock.json`. Dependency upgrades must pass lint, typecheck, tests, Expo Doctor, clean prebuild, and relevant platform builds.
- Treat `expo/ios` and `expo/android` as disposable CNG output; durable native changes must be expressed through app config, config plugins, retained native inputs, or the local Expo module.
- Update `update-news/whatsnew-en-US` for user-facing release changes.
