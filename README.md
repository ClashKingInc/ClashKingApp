# ClashKing Mobile App

[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue)](https://github.com/ClashKingInc)
[![Flutter](https://img.shields.io/badge/Flutter-3.44-blue)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-Open%20Source-green)](https://github.com/ClashKingInc)

The ultimate Clash of Clans companion app for tracking stats, managing clans, and analyzing performance. Built with Flutter for a beautiful, fast mobile experience.

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
- Flutter-composited Liquid Glass on every platform

## 🚀 Getting Started

### Prerequisites
- Flutter 3.44.0 (see `.flutter-version`)
- Dart 3.12.0
- Android Studio / Xcode for device deployment

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ClashKingInc/clashkingapp.git
   cd clashkingapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Development Commands

- `flutter pub get` - Install dependencies
- `flutter run` - Run the app in development mode
- `flutter analyze` - Run static analysis
- `flutter test` - Run the full test suite
- `flutter build apk --release` - Build the Android APK
- `flutter build ios --release --no-codesign` - Compile iOS and its widget extension

## 🌐 ClashKing Ecosystem

ClashKing is a comprehensive platform with multiple tools:

- **📱 Mobile App** (this repository) - Beautiful, fast access to your stats
- **🤖 Discord Bot** - Clan management and server integration
- **🔗 Free API** - Open-source data access for developers

All tools work together seamlessly, sharing data to provide the ultimate Clash of Clans experience.

## 🏗️ Architecture

### Project Structure
```
lib/
├── core/           # Core app functionality and utilities
├── features/       # Feature-based modules
│   ├── auth/       # Authentication and user management
│   ├── clan/       # Clan-related features
│   ├── player/     # Player statistics and profiles
│   ├── war_cwl/    # War and CWL analytics
│   └── settings/   # App settings and preferences
├── common/         # Shared widgets and utilities
└── l10n/          # Internationalization files
```

Startup and post-login account hydration share `AccountBootstrapService`.
Reusable API and token transports live in `ApiService.shared` and
`TokenService.shared`; non-secret settings live in `AppPreferences`.

### Key Technologies
- **Flutter** - Cross-platform mobile framework
- **Provider** - State management
- **HTTP** - API communication
- **Cached Network Image** - Image caching and optimization
- **Shared Preferences** - Local data persistence

## 🌍 Internationalization

The app supports 20+ languages with community-driven translations:

- English (reference language)
- French (developer-maintained)
- Spanish, German, Italian, Portuguese, and more

### Contributing Translations
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
- Follow Flutter best practices
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
