# Architecture

This project is a Flutter POS mobile app.

## Tech stack

- UI: Flutter `MaterialApp.router` (Material 3)
- State management: Riverpod
- Routing: `go_router` using a `StatefulShellRoute` (bottom navigation)
- Local persistence: `sqflite` (SQLite)

## App composition

- `lib/main.dart` wraps the app in a Riverpod `ProviderScope`.
- `lib/app.dart` provides the root widget `PosApp` and app theme.
- `lib/router.dart` defines routes and the bottom navigation scaffold.

## Feature folders

Most user-facing screens live under `lib/features/<feature>/presentation`.

Current top-level routes are defined in `lib/router.dart`:

- Dashboard
- Checkout
- Reports
- Settings
  - Products (new/edit)
  - Customers (new/detail/edit/payment)

## Data & services

- `lib/core/providers.dart` exposes app-wide providers.
- `lib/core/db/app_database.dart` creates/opens the SQLite database.
- `lib/core/db/schema.dart` contains schema statements (v1).
