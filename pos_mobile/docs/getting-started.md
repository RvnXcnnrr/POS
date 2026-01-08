# Getting Started

## Prerequisites

- Flutter SDK (stable) with Dart `>= 3.10.4` (see `pubspec.yaml`)
- Android Studio / Android SDK + an emulator or a physical Android device

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

## Build APK

- Debug APK: `flutter build apk --debug`
- Release APK: `flutter build apk --release`

## Project entry points

- `lib/main.dart` boots the app.
- `lib/app.dart` defines `MaterialApp.router` and theme.
- `lib/router.dart` defines navigation.
