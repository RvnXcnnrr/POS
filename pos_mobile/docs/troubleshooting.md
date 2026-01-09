# Troubleshooting

## Flutter/Android toolchain issues

- Run `flutter doctor -v` and fix any missing Android licenses/SDK components.
- Ensure an emulator/device is available: `flutter devices`.

If you have multiple devices:

- `flutter run -d <device_id>`

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

## iOS build issues (macOS only)

Windows/Linux cannot build iOS.

On a Mac, if iOS dependencies fail:

- `flutter doctor -v`
- `cd ios && pod install && cd ..`

If you use `image_picker`, ensure privacy keys exist in `ios/Runner/Info.plist`:

- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
