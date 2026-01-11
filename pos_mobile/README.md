# pos_mobile

Flutter POS mobile app.

## Quick start

Prereqs:

- Flutter (stable) with Dart `>= 3.10.4` (see `pubspec.yaml`)
- Android SDK / Android Studio (for Android builds)
- macOS + Xcode (only required to build/run for iOS)

Commands:

- Install deps: `flutter pub get`
- Analyze: `flutter analyze`
- Test: `flutter test`
- Run: `flutter run` (use `flutter devices` then `flutter run -d <id>` if needed)
- Debug APK: `flutter build apk --debug`
- Release APK: `flutter build apk --release`

## Responsive/adaptive UI

The app uses a single codebase with adaptive layouts across:

- Phones/tablets
- Portrait/landscape

Breakpoints are defined in `lib/core/utils/responsive.dart`:

- Compact: < 600dp
- Medium: 600–1024dp
- Expanded: > 1024dp

Navigation adapts by breakpoint:

- Compact: bottom `NavigationBar`
- Medium/Expanded: side `NavigationRail`

## Docs

- [Project docs](docs/README.md)
- [User Manual](docs/user-manual.md)
- [UI/UX Design Overview](docs/ui-ux.md)
- [Getting Started](docs/getting-started.md)
- [Architecture](docs/architecture.md)
- [Database](docs/database.md)
- [MVP Specification](docs/mvp.md)
- [Troubleshooting](docs/troubleshooting.md)

## Tech stack

- Riverpod (state management)
- go_router (navigation)
- sqflite (local SQLite)
