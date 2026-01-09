import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'schema.dart';
import '../utils/business_day.dart';

class AppDatabase {
  AppDatabase();

  Future<Database>? _dbFuture;

  Future<Database> get db async {
    _dbFuture ??= _open();
    return _dbFuture!;
  }

  Future<String> get dbPath async {
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, 'pos.db');
  }

  Future<void> close() async {
    final future = _dbFuture;
    if (future == null) return;
    final database = await future;
    await database.close();
    _dbFuture = null;
  }

  Future<Database> _open() async {
    final path = await dbPath;

    return openDatabase(
      path,
      version: Schema.currentVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        for (final stmt in Schema.createStatements) {
          await db.execute(stmt);
        }

        // Ensure app_settings single row exists.
        await db.insert('app_settings', const {
          'id': 1,
          'store_name': 'POS',
          'pin_code': null,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrate(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    // All migrations run inside a transaction so they are atomic.
    await db.transaction((txn) async {
      if (oldVersion < 2) {
        await txn.execute(
          "ALTER TABLE products ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1",
        );
        await txn.execute(
          "ALTER TABLE customers ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1",
        );
      }

      if (oldVersion < 3) {
        await txn.execute(
          "ALTER TABLE sales ADD COLUMN is_voided INTEGER NOT NULL DEFAULT 0",
        );
        // Supporting index for undo/report filtering.
        await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id)',
        );
      }

      if (oldVersion < 4) {
        // business_date is required. Provide default then backfill.
        await txn.execute(
          "ALTER TABLE sales ADD COLUMN business_date TEXT NOT NULL DEFAULT '1970-01-01'",
        );

        // Payment metadata
        await txn.execute(
          "ALTER TABLE payments ADD COLUMN method TEXT NOT NULL DEFAULT 'cash'",
        );
        await txn.execute("ALTER TABLE payments ADD COLUMN note TEXT");

        // Indexes
        await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)',
        );
        await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_sales_business_date ON sales(business_date)',
        );
        await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at)',
        );
        await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_customers_balance ON customers(balance_cents)',
        );

        // Ensure app_settings row exists.
        await txn.insert('app_settings', const {
          'id': 1,
          'store_name': 'POS',
          'pin_code': null,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // Backfill business_date for existing sales.
        final rows = await txn.query('sales', columns: ['id', 'created_at']);
        for (final r in rows) {
          final id = r['id'] as int;
          final createdAt = r['created_at'] as int;
          final dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
          final businessDate = BusinessDay.businessDateFor(dt);
          await txn.update(
            'sales',
            {'business_date': businessDate},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    });
  }

  /// Export the SQLite database file to a chosen destination path.
  /// The destination path must be writable.
  Future<void> exportTo(String destinationPath) async {
    await close();
    final source = File(await dbPath);
    await source.copy(destinationPath);
  }

  /// Restore the SQLite database file from a selected source path.
  /// This replaces the current DB file.
  Future<void> restoreFrom(String sourcePath) async {
    await close();
    final source = File(sourcePath);
    final dest = File(await dbPath);
    await dest.parent.create(recursive: true);
    await source.copy(dest.path);
    // Re-open lazily on next access.
  }
}
