# Database

The app persists data locally using SQLite via `sqflite`.

## Location

`AppDatabase` uses `path_provider` to place the DB in the app documents directory:

- File name: `pos.db`

See `lib/core/db/app_database.dart`.

## Schema

Schema statements live in `lib/core/db/schema.dart`.

Current schema version:

- `Schema.currentVersion` (currently v5)

Tables:

- `products`
- `customers`
- `sales`
- `sale_items`
- `payments`
- `app_settings`

Notes:

- Foreign keys are enabled via `PRAGMA foreign_keys = ON`.
- Some relations use `ON DELETE RESTRICT` to prevent accidental loss.
- `sale_items.price_cents` snapshots unit price at sale time.
- `app_settings` is designed as a single-row table (`id = 1`).

## Schema versioning & migrations

The database is opened in `lib/core/db/app_database.dart` using:

- `openDatabase(..., version: Schema.currentVersion, onCreate: ..., onUpgrade: ...)`

Migrations:

- Live in `AppDatabase._migrate`.
- Run inside a SQLite transaction (atomic).
- Are written as forward-only upgrades (e.g. `if (oldVersion < 4) { ... }`).
- Are primarily additive (new columns/indexes), which keeps upgrades safe for existing installs.

Fresh installs:

- Execute all `Schema.createStatements`.
- Insert the single `app_settings` row if missing.

## Backup/restore

`AppDatabase` supports copying the raw SQLite file:

- Export: `exportTo(destinationPath)` copies `pos.db` to a chosen location.
- Restore: `restoreFrom(sourcePath)` replaces the current `pos.db`.

Note: export/restore closes the database first to avoid copying an open file.
