# ClashKing Expo app

This directory contains the ClashKing Expo/React Native app. It targets iOS, Android, and static web from one TypeScript application while retaining the shipping bundle identities, shared Keychain/Keystore session, Firebase messaging, alternate icons, and war/upgrade widgets through the local `@clashking/native` module.

Expo Go is not supported because ClashKing depends on custom native code and React Native Firebase. Use an Expo development build or a generated native project.

## Local setup

```bash
npm ci
npx expo prebuild --clean
npx expo run:ios
# or
npx expo run:android
```

The API defaults to production. Development builds can use the remote development API:

```bash
EXPO_PUBLIC_CK_API_ENV=development
EXPO_PUBLIC_CK_API_BASE_URL=https://dev-api.clashk.ing
EXPO_PUBLIC_CK_API_V2_BASE_URL=https://dev-api.clashk.ing/v2
EXPO_PUBLIC_CK_PROXY_BASE_URL=https://dev-api.clashk.ing/proxy/v1
EXPO_PUBLIC_CK_PUSH_API_V2_BASE_URL=https://dev-api.clashk.ing/v2
EXPO_PUBLIC_CK_DISCORD_SIGN_IN_ENABLED=true
```

Local API development can instead set `EXPO_PUBLIC_CK_API_ENV=local` and the
corresponding URL overrides. Store releases select all API, proxy, push, and OTA
endpoints together: alpha uses `https://local-api.clashk.ing`, beta uses
`https://dev-api.clashk.ing`, and production uses `https://api.clashk.ing`.
Store builds embed JavaScript; `local-app.clashk.ing` and `dev-app.clashk.ing`
are Expo development server URLs. See the root README for tagged alpha releases
and OTA setup.

## Verification

```bash
npm run l10n:check
npm run lint
npm run typecheck
npm run release:check
npm run web:export
```

`app.config.ts` and `plugins/with-clashking-native.js` generate the native projects from Expo-owned inputs under `native/`. Generated `ios/` and `android/` folders are disposable and intentionally ignored.

The web export is a static PWA. Files in `public/` preserve the Discord callback paths, installation manifest, offline worker, Cloudflare Pages redirects, and cache headers.

## Localization

ARB files under `src/i18n/arb` are the source of truth. Run
`npm run l10n:generate` after editing them and commit the generated catalogs;
`npm run l10n:check` verifies that the catalogs are current. The known
raid-reminder persistence gap remains blocked on coordinated API/schema work
and must not be hidden with client-only state.
