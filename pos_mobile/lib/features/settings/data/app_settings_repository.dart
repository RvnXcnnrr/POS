import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/providers.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return AppSettingsRepository(ref.watch(appDatabaseProvider));
});

final pinCodeProvider = FutureProvider<String?>((ref) async {
  return ref.watch(appSettingsRepositoryProvider).getPinCode();
});

/// In-memory unlock session.
final pinUnlockedProvider = StateProvider<bool>((ref) => false);

class AppSettingsRepository {
  AppSettingsRepository(this._db);

  final AppDatabase _db;

  Future<void> _ensureRow() async {
    final db = await _db.db;
    await db.insert('app_settings', const {
      'id': 1,
      'store_name': 'POS',
      'pin_code': null,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<String?> getPinCode() async {
    await _ensureRow();
    final db = await _db.db;
    final rows = await db.query(
      'app_settings',
      columns: ['pin_code'],
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final pin = rows.first['pin_code'] as String?;
    if (pin == null || pin.trim().isEmpty) return null;
    return pin;
  }

  Future<void> setPinCode(String? pin) async {
    await _ensureRow();
    final db = await _db.db;
    await db.update('app_settings', {
      'pin_code': (pin == null || pin.trim().isEmpty) ? null : pin.trim(),
    }, where: 'id = 1');
  }
}
