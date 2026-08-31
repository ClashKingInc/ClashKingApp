# ClashKing Mobile App

[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue)](https://github.com/ClashKingInc)
[![Expo](https://img.shields.io/badge/Expo-SDK%2057-000020)](https://expo.dev)
[![License](https://img.shields.io/badge/license-Open%20Source-green)](https://github.com/ClashKingInc)

The Clash of Clans companion app for tracking stats, managing clans, and analyzing performance. The shipping application is the Expo SDK 57 project under `expo/`.

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
- Native and cross-platform glass surfaces with responsive iOS, Android, and web behavior

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

### Development Commands

- `npm ci` - Install locked dependencies from `expo/`
- `npm run start` - Start Expo for native or web development
- `npm run lint` / `npm run typecheck` - Run static checks
- `npm test` - Run the Expo test suite
- `npm run test:native-plugin` - Verify the retained native/widget contract
- `npx expo prebuild --clean` - Generate native projects through CNG
- `npm run web:export` - Build the Cloudflare Pages artifact and stamp its release cache

The shared web process is managed from the repository root with
`tooling/dev-app start`. It serves Expo web at `https://dev-app.clashk.ing`
through the existing tunnel and owns port `7357`; use `reload`, `restart`,
`logs`, and `status` instead of starting a second process.

The deployed production web build uses
`EXPO_PUBLIC_CK_API_V2_BASE_URL=https://api.clashk.ing/v2`.
Browser authentication uses the `/v2/auth/web/*` cookie endpoints; native iOS
and Android builds keep the JSON access/refresh-token contract.

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
└── public/         # PWA, OAuth callback, and Cloudflare static assets
```

The Expo project uses CNG: `expo/ios` and `expo/android` are generated and
ignored. Make durable native changes in `expo/app.config.ts`, `expo/plugins`,
`expo/native`, or the local `@clashking/native` module.

Expo startup and post-login hydration share `AccountBootstrapService`. The
runtime context owns the reusable API client, auth/session storage, preferences,
and feature services.

### Key Technologies

- **Expo SDK 57 / React Native** - iOS, Android, and static web runtime
- **Expo Router** - Cross-platform routing and static web export
- **TanStack Query and Zustand** - Remote and local state
- **Expo config plugins / CNG** - Reproducible native projects and widgets
- **Cloudflare Pages** - Production static web hosting

## Release delivery

GitHub Actions regenerates native projects from `expo/app.config.ts`, the native parity contract, config plugins, and local native sources. Android releases produce a signed AAB and APK before uploading the AAB to the selected Play track; iOS releases archive the `ClashKing` app and `WarWidgetExtension` together before uploading the IPA to TestFlight; web releases export static Expo Router output to Cloudflare Pages. These workflows preserve `com.clashking.clashkingapp`, `com.clashking.apps`, `com.clashking.apps.warwidget`, Apple team `MZYXD43RX5`, and app group `group.com.clashking.apps`.

Repository or environment secrets required by the release workflows are:

- Android: `KEY_STORE_FILE`, `KEY_ALIAS`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `GOOGLE_PLAY_JSON_KEY`, and `PACKAGE_NAME`.
- iOS: `IOS_CERTIFICATE_BASE64`, `IOS_CERTIFICATE_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`, `IOS_WIDGET_PROVISIONING_PROFILE_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, and `APP_STORE_CONNECT_API_KEY`. The app and widget provisioning profiles must both be App Store distribution profiles and include the shared app group; the app profile must also retain its push entitlement.
- Web: `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` for the existing `clashkingapp` Pages project.

The TestFlight workflow uploads the build but leaves external TestFlight review and group assignment in App Store Connect. Local validation can verify generated targets, compilation, and plist contracts, but production signing and store acceptance require the real credentials above.

## 🌍 Internationalization

The app supports 20+ languages with community-driven translations:

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
