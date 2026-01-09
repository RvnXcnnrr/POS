# Getting Started

## Prerequisites

- Flutter SDK (stable) with Dart `>= 3.10.4` (see `pubspec.yaml`)
- Android Studio / Android SDK + an emulator or a physical Android device
- For iOS builds: macOS + Xcode (Windows/Linux cannot build iOS targets)

Useful checks:

- `flutter --version`
- `flutter doctor -v`

## Install dependencies

From the repo root:

- `flutter pub get`

## Run (Android)

- `flutter run`

If you have multiple devices connected:

- `flutter devices`
- `flutter run -d <device_id>`

## Run (other platforms)

The project can also be run on:

- Windows desktop: `flutter run -d windows`
- Web: `flutter run -d chrome` / `flutter run -d edge`

## Run (iOS)

iOS builds require macOS + Xcode.

On a Mac:

- `flutter devices`
- `flutter run -d <ios_device_id>`

If CocoaPods is needed:

- `cd ios && pod install && cd ..`

## Build APK

- Debug APK: `flutter build apk --debug`
- Release APK: `flutter build apk --release`

## Project entry points

- `lib/main.dart` boots the app.
- `lib/app.dart` defines `MaterialApp.router` and theme.
- `lib/router.dart` defines navigation.

## Quality checks

- Analyzer: `flutter analyze`
- Tests: `flutter test`
