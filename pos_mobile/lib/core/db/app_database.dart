import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

class AppDatabase {
  AppDatabase();

  Future<Database>? _dbFuture;

  Future<Database> get db async {
    _dbFuture ??= _open();
    return _dbFuture!;
  }

  Future<Database> _open() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'pos.db');

    return openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        for (final stmt in Schema.v1CreateStatements) {
          await db.execute(stmt);
        }
      },
    );
  }
}
