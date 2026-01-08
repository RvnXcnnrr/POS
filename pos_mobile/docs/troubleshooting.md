# Troubleshooting

## Flutter/Android toolchain issues

- Run `flutter doctor -v` and fix any missing Android licenses/SDK components.
- Ensure an emulator/device is available: `flutter devices`.

## Clean rebuild

If builds get into a bad state:

- `flutter clean`
- `flutter pub get`
- `flutter run`

## Gradle issues (Android)

If Android builds fail with Gradle errors, try:

- `cd android`
- `./gradlew --version` (Windows: `gradlew.bat --version`)

Then retry from repo root:

- `flutter build apk --debug`
