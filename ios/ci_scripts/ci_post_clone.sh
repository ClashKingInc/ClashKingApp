#!/bin/sh
set -e

echo "📥 Fetching Dart dependencies…"
flutter pub get

echo "📦 Installing iOS pods…"
cd ios
pod install --repo-update
cd ..

echo "✅ Dependencies ready"