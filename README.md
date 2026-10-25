# ClashKing Mobile App

[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue)](https://github.com/ClashKingInc)
[![Expo](https://img.shields.io/badge/Expo-SDK%2058-000020)](https://expo.dev)
[![License](https://img.shields.io/badge/license-Open%20Source-green)](https://github.com/ClashKingInc)

The Clash of Clans companion app for tracking stats, managing clans, and analyzing performance. The shipping application is the Expo SDK 58 project under `expo/`.

## ✨ Features

### 📊 **Player Statistics**

- Comprehensive player profile tracking
- Trophy progression and league rankings
- Achievement monitoring and progress
- Legend League daily tracking with detailed analytics

### 🏰 **Clan Management**

- Real-time clan member monitoring
- Donation tracking and clan health metrics
- Join/leave event tracking
- Clan capital raid analytics

### ⚔️ **War Analytics**

- Detailed war performance tracking
- Attack strategy analysis and win rates
- War history and statistical trends
- Clan War League (CWL) performance metrics

### 🏆 **Legend League Tracking**

- Daily trophy gain/loss tracking
- End-of-season statistics
- Performance charts and trends
- Attack and defense analytics

### 🔧 **Additional Features**

- Multi-language support (20+ languages)
- Dark/light theme support
- Account verification with API tokens
- Android home screen widgets
- Offline data caching
- Native iOS and Android interfaces with shared components

## 🚀 Getting Started

### Prerequisites

- Node.js 22
- npm
- Android Studio / Xcode for device deployment

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/ClashKingInc/clashkingapp.git
   cd clashkingapp
   ```

2. **Install dependencies**

   ```bash
   cd expo
   npm ci
   ```

3. **Run the app**
   ```bash
   npm run start
   ```

Expo Go is not supported because the app includes custom native code and React Native Firebase. Use an Expo development build. From `expo/`, run `npx expo run:ios` or `npx expo run:android` to generate and launch a local native build. Android requires Android Studio; iOS requires Xcode on macOS.

### Development Commands

- `npm run device:hub` - Open the local device dashboard at `http://127.0.0.1:7358` (run from `expo/`).
  This uses Expo Device Hub's standalone mode and binds only to loopback. Its Metro
  plugin is excluded from devtools autolinking because the shared Metro server is
  publicly tunneled. Keep that exclusion: the dashboard can control devices and
  execute host commands. The standalone dashboard does not change the app UI or
  require a new phone build. Starting it does not boot a simulator or emulator.
  Device Hub 0.18 expects the semicolon-separated SDK package table emitted by
  Android command-line tools 22. Version 23 changes that output and makes the
  new-emulator image picker appear empty even with system images installed.
- `npm ci` - Install locked dependencies from `expo/`
- `npm run start` - Start Metro for a native development build
- `npm run lint` / `npm run typecheck` - Run static checks
- `npx expo prebuild --clean` - Generate native projects through CNG
- `npm run web:export` - Build the native-app handoff landing for Cloudflare Pages (not the application UI)

Browser URLs serve a static app-opening landing page, not the product UI or an installable PWA. `npm run web:export` builds that landing page and preserves app links and OAuth callback files. Native iOS and Android use the JSON access/refresh-token contract.

Set `CK_IOS_STORE_URL` and `CK_ANDROID_STORE_URL` to the HTTPS store listings when building the landing page. Missing values leave the corresponding download controls disabled. `CK_ANDROID_APP_LINKS_SHA256` supplies the Play signing certificate fingerprint for Android association files.

Set `EXPO_PUBLIC_CK_API_ENV` to `development`, `staging`, or `local` to select
the non-production environment. Optional `EXPO_PUBLIC_CK_API_BASE_URL`,
`EXPO_PUBLIC_CK_API_V2_BASE_URL`, `EXPO_PUBLIC_CK_PROXY_BASE_URL`, and
`EXPO_PUBLIC_CK_PUSH_API_V2_BASE_URL` values override canonical environment
URLs. CI alpha builds use development, beta builds use staging, and production
builds use `api.clashk.ing`.

## 🌐 ClashKing Ecosystem

ClashKing is a comprehensive platform with multiple tools:

- **📱 Mobile App** (this repository) - Beautiful, fast access to your stats
- **🤖 Discord Bot** - Clan management and server integration
- **🔗 Free API** - Open-source data access for developers

All tools work together seamlessly, sharing data to provide the ultimate Clash of Clans experience.

## 🏗️ Architecture

### Project Structure

```
expo/
├── src/
│   ├── core/       # Runtime, API, storage, and shared domain code
│   ├── features/   # Feature-based application modules
│   ├── i18n/       # Generated catalogs and source ARB files
│   └── ui/         # Shared responsive components and tokens
├── native/         # Retained widget sources and native parity contract
├── plugins/        # Expo config plugins that generate native projects
└── public/         # App-opening landing, OAuth callbacks, and association files
```

The Expo project uses CNG: `expo/ios` and `expo/android` are generated and
ignored. Make durable native changes in `expo/app.config.ts`, `expo/plugins`,
`expo/native`, or the local `@clashking/native` module.

Expo startup and post-login hydration share `AccountBootstrapService`. The
runtime context owns the reusable API client, auth/session storage, preferences,
and feature services.

### Key Technologies

- **Expo SDK 58 / React Native** - Native iOS and Android runtime
- **Expo Router** - Native routing and deep links
- **TanStack Query and Zustand** - Remote and local state
- **Expo config plugins / CNG** - Reproducible native projects and widgets
- **Cloudflare Pages** - Static app-opening landing and association files

## Release delivery

The `Release mobile app` workflow accepts a ref, an exact numeric version, and an independent `alpha`, `beta`, or `production` track. The entered version is authoritative: `x.y.0` creates a native release, while `x.y.1` and later patches create OTA releases only when both fingerprints still match that track's `x.y.0` native build. Native code changes require a new native release. Signed APKs are attached to native GitHub releases.

| Track      | API and OTA host       | Expo development server | Store destination                            |
| ---------- | ---------------------- | ----------------------- | -------------------------------------------- |
| alpha      | `local-api.clashk.ing` | `local-app.clashk.ing`  | Play closed testing (`alpha`) and TestFlight |
| beta       | `dev-api.clashk.ing`   | `dev-app.clashk.ing`    | Play beta and TestFlight                     |
| production | `api.clashk.ing`       | —                       | Play production and App Store review         |

Store builds embed their JavaScript and do not connect to Metro. The Expo server URLs are for development clients only. Both alpha and beta use numeric native versions (for example `0.5.0`) and separate GitHub/OTA suffixes (`0.5.0-alpha`, `0.5.0-beta`). TestFlight groups control access on iOS; invited external testers require Apple's TestFlight review before testing.

Pushing an alpha tag such as `v0.6.2-alpha` automatically starts both native store jobs from that exact commit. Tagged alpha builds disable OTA and build native binaries, including patch versions, without requiring API/R2 signing infrastructure. To enable OTA later, publish a new native `x.y.0` baseline with `enable_updates=true` in the manual workflow, then publish compatible patches on the same track. Beta and production require OTA infrastructure. `release.yaml` can run on a tag before it has been merged to the default branch; its manual dispatch becomes available after it reaches the default branch.

The existing Play closed track is `alpha`; set `PLAY_ALPHA_TRACK` if its identifier differs. `update-news/whatsnew-en-US` supplies the Play release notes, TestFlight What to Test, and default GitHub release notes. Alpha and beta never submit the app for public App Store release. TestFlight upload does not create tester groups or submit an external beta review.

OTA assets are content-addressed and uploaded to R2 before `releases/<track>/<version>/release.json` is written. Native markers include a signed copy of their embedded JavaScript baseline; each OTA marker includes pre-signed republishes of earlier compatible releases, allowing the Admin Panel to perform a real rollback without holding the signing key. The marker is the immutable commit record used by the API and Admin Panel. Development builds keep updates disabled and continue to run from Metro.

Repository or environment secrets required by the release workflows are:

- Android: `KEY_STORE_FILE`, `KEY_ALIAS`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `GOOGLE_PLAY_JSON_KEY`, and `PACKAGE_NAME`.
- iOS: `IOS_CERTIFICATE_BASE64`, `IOS_CERTIFICATE_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`, `IOS_WIDGET_PROVISIONING_PROFILE_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, and `APP_STORE_CONNECT_API_KEY`. The app and widget provisioning profiles must both be App Store distribution profiles and include the shared app group; the app profile must also retain its push entitlement. The workflow reuses the imported distribution certificate to provision `com.clashking.apps.notificationservice` with the App Store Connect API. The key needs access to Certificates, Identifiers & Profiles. Alternatively, supply `IOS_NOTIFICATION_SERVICE_PROVISIONING_PROFILE_BASE64` to avoid automatic provisioning.
- OTA: `EXPO_UPDATES_CODE_SIGNING_CERTIFICATE`, `EXPO_UPDATES_PRIVATE_KEY`, `R2_ACCOUNT_ID`, `R2_UPDATES_ACCESS_KEY_ID`, `R2_UPDATES_SECRET_ACCESS_KEY`, and `R2_UPDATES_BUCKET_NAME`. Set the repository variable `R2_UPDATES_PUBLIC_ORIGIN` to the HTTPS custom domain serving the bucket.
- Web: `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` for the existing `clashkingapp` Pages project.

Release jobs use GitHub Environments named `alpha`, `beta`, and `production`. Configure the release and OTA secrets separately in each environment to isolate signing access. Keep approval protection on `production`.

## 🌍 Internationalization

The app uses community-driven translations:

- English (reference language)
- French (developer-maintained)
- Spanish, German, Italian, Portuguese, and more

### Contributing Translations

The ARB catalogs under `expo/src/i18n/arb` are the localization source of
truth. `npm run l10n:generate` creates the runtime JSON and TypeScript catalogs,
and `npm run l10n:check` verifies that generated output is current.

Help us translate the app! We use Crowdin for community translations:

- Visit our [Crowdin project](https://crowdin.com/project/clashkingapp)
- Join our [Discord community](https://discord.gg/clashking) for translator support

## 🤝 Contributing

We welcome contributions from the community! This is a side project developed alongside our full-time jobs, driven by our passion for Clash of Clans.

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the existing Expo/TypeScript patterns
- Maintain existing code style and patterns
- Add translations for new strings
- Test on both Android and iOS
- Ensure no secrets or API keys are committed

## 🐛 Bug Reports & Feature Requests

- **Bug Reports**: [GitHub Issues](https://github.com/ClashKingInc/clashkingapp/issues)
- **Feature Requests**: Use our in-app feature voting system
- **General Support**: [Discord Community](https://discord.gg/clashking)
- **Email**: devs@clashk.ing

## 💖 Support the Project

ClashKing is funded entirely through user donations and Supercell Creator code usage:

- **Use Creator Code**: Enter "ClashKing" in any Supercell game shop
- **Patreon**: [Support us on Patreon](https://www.patreon.com/clashking)
- **Discord**: [Join our community](https://discord.gg/clashking)
- **Share**: Tell your clan mates about ClashKing!

## 📜 License

This project is open source. See the source code for implementation details.

**Important**: This project is not affiliated with Supercell. Clash of Clans is a trademark of Supercell Oy. This app follows the [Supercell Fan Content Policy](https://supercell.com/en/fan-content-policy/).

## 🔗 Links

- **API Repository**: [ClashKing API](https://github.com/ClashKingInc/ClashKingAPI)
- **Discord Bot**: [Invite to your server](https://discord.com/api/oauth2/authorize?client_id=824653933347209227&permissions=8&scope=bot%20applications.commands)
- **Website**: [clashk.ing](https://clashk.ing)
- **Discord Community**: [discord.gg/clashking](https://discord.gg/clashking)

---

Made with ❤️ by the ClashKing team and community contributors.
