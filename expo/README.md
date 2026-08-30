# ClashKing Expo app

This directory contains the Expo/React Native replacement for the frozen Flutter app. It targets iOS, Android, and static web from one TypeScript application while retaining the shipping bundle identities, shared Keychain/Keystore session, Firebase messaging, alternate icons, and war/upgrade widgets through the local `@clashking/native` module.

Expo Go is not supported because ClashKing depends on custom native code and React Native Firebase. Use an Expo development build or a generated native project.

## Local setup

```bash
npm ci
npx expo prebuild --clean
npx expo run:ios
# or
npx expo run:android
```

The API defaults to production. Local and staging builds can set:

```bash
EXPO_PUBLIC_CK_API_ENV=staging
EXPO_PUBLIC_CK_API_BASE_URL=https://dev-api.clashk.ing
EXPO_PUBLIC_CK_API_V2_BASE_URL=https://dev-api.clashk.ing/v2
EXPO_PUBLIC_CK_PROXY_BASE_URL=https://dev-api.clashk.ing/proxy/v1
EXPO_PUBLIC_CK_PUSH_API_V2_BASE_URL=https://dev-api.clashk.ing/v2
EXPO_PUBLIC_CK_WEB_DISCORD_REDIRECT_URI=https://staging-app.clashk.ing/auth/discord_callback.html
EXPO_PUBLIC_CK_DISCORD_SIGN_IN_ENABLED=true
```

## Verification

```bash
npm run l10n:check
npm run parity:check
npm run lint
npm run typecheck
npm test
npm run test:native-plugin
npm run web:export
```

`app.config.ts` and `plugins/with-clashking-native.js` generate the native projects from Expo-owned inputs under `native/`. Generated `ios/` and `android/` folders are disposable and intentionally ignored; do not copy implementation files from the Flutter native folders during prebuild.

The web export is a static PWA. Files in `public/` preserve the Discord callback paths, installation manifest, offline worker, Cloudflare Pages redirects, and cache headers.

## Parity ledger

`docs/parity-manifest.json` inventories every Flutter, native, asset, localization, web, test, and delivery input. `docs/parity-overrides.json` records reviewed dispositions and evidence; run `npm run parity:generate` only after reviewing an entry against the frozen Flutter source. The known raid-reminder persistence gap remains blocked on coordinated API/schema work and must not be hidden with client-only state.
