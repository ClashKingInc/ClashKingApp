# clashkingapp

ClashKing App

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Run

### Terminal

```sh
flutter run --dart-define-from-file=config.json
```

### IDE

Example VS Code Setup, `.vsocode/launch.json`

```json
{
  // Use IntelliSense to learn about possible attributes.
  // Hover to view descriptions of existing attributes.
  // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
  "version": "0.2.0",
  "configurations": [
    {
      "name": "clashking",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "toolArgs": ["--dart-define-from-file=config.json"]
    }
  ]
}
```
