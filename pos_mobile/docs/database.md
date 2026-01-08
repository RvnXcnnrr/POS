# Database

The app persists data locally using SQLite via `sqflite`.

## Location

`AppDatabase` uses `path_provider` to place the DB in the app documents directory:

- File name: `pos.db`

See `lib/core/db/app_database.dart`.

## Schema

Schema statements live in `lib/core/db/schema.dart`.

Version 1 tables:

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
