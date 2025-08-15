#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd $CI_PRIMARY_REPOSITORY_PATH # change working directory to the root of your cloned repo.

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Force release mode configuration
echo "Configuring for release build..."
cat > ios/Flutter/Generated.xcconfig << EOF
// This is a generated file; do not edit or check into version control.
FLUTTER_ROOT=\$HOME/flutter
FLUTTER_APPLICATION_PATH=\$(SRCROOT)/..
COCOAPODS_PARALLEL_CODE_SIGN=true
FLUTTER_TARGET=lib/main.dart
FLUTTER_BUILD_DIR=build
FLUTTER_BUILD_NAME=\$(MARKETING_VERSION)
FLUTTER_BUILD_NUMBER=\$(CURRENT_PROJECT_VERSION)
EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386
EXCLUDED_ARCHS[sdk=iphoneos*]=armv7
DART_OBFUSCATION=true
TRACK_WIDGET_CREATION=false
TREE_SHAKE_ICONS=true
PACKAGE_CONFIG=.dart_tool/package_config.json
FLUTTER_BUILD_MODE=release
EOF

# Create .env file for build
cat > .env << EOF
DISCORD_CLIENT_ID=824653933347209227
DISCORD_CLIENT_SECRET=I-QO4VpQBhNS3a12zqd9UK18nwwfTsGe
DISCORD_REDIRECT_URI=clashking://com.example.clashkingapp/oauth
DISCORD_CALLBACK_URL_SCHEME=clashking
DISCORDCOC_LOGIN="magicjr"
DISCORDCOC_PASSWORD="QPsw8NMVv2"
SENTRY_DSN=https://7842054c3f4229162f88575417dee312@o4504206147977216.ingest.us.sentry.io/4507477668921344
ENCRYPTION_KEY=hABNJWCYp0KPXJcHOPwrRj/DJF/liIu5DSuVfDu+xsU=
HMAC_KEY=x1yNIPO8iSWM1NrmTiUPf8hjg3g/UG4Eo7gp8/grIEU=
EOF

echo "Release configuration and .env file created"

# Install CocoaPods using Homebrew.
HOMEBREW_NO_AUTO_UPDATE=1 # disable homebrew's automatic updates.
brew install cocoapods

# Install CocoaPods dependencies.
cd ios && pod install # run `pod install` in the `ios` directory.

exit 0