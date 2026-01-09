import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/db/app_database.dart';
import 'customer.dart';
import 'payment.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(ref.watch(appDatabaseProvider));
});

class CustomersRepository {
  CustomersRepository(this._db);

  final AppDatabase _db;

  Future<List<Customer>> listAllByHighestBalance() async {
    final db = await _db.db;
    final rows = await db.query(
      'customers',
      where: 'is_active = 1',
      orderBy: 'balance_cents DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getById(int id) async {
    final db = await _db.db;
    final rows = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<int> create(CustomerDraft draft) async {
    final db = await _db.db;
    return db.insert('customers', draft.toInsertMap());
  }

  Future<void> update(int id, CustomerDraft draft) async {
    final db = await _db.db;
    await db.update(
      'customers',
      draft.toUpdateMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Soft delete: mark inactive to preserve historical sales/payments.
  Future<void> deactivate(int id) async {
    final db = await _db.db;
    await db.update(
      'customers',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Payment>> listPaymentsForCustomer(int customerId) async {
    final db = await _db.db;
    final rows = await db.query(
      'payments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  /// IMPORTANT RULES:
  /// - Never edit past sales.
  /// - Customers pay via payments table.
  /// - Prevent overpayment.
  /// - Balance never becomes negative.
  /// - Use transaction.
  Future<void> addPayment({
    required int customerId,
    required int amountCents,
    String method = 'cash',
    String? note,
  }) async {
    if (amountCents <= 0) {
      throw ArgumentError('Payment amount must be > 0');
    }

    final db = await _db.db;
    await db.transaction((txn) async {
      final customerRows = await txn.query(
        'customers',
        columns: ['balance_cents'],
        where: 'id = ?',
        whereArgs: [customerId],
      );
      if (customerRows.isEmpty) {
        throw StateError('Customer not found');
      }

      final currentBalance = customerRows.first['balance_cents'] as int;
      if (amountCents > currentBalance) {
        throw StateError('Overpayment is not allowed');
      }

      await txn.insert('payments', {
        'customer_id': customerId,
        'amount_cents': amountCents,
        'method': method,
        'note': note,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      final newBalance = currentBalance - amountCents;
      if (newBalance < 0) {
        throw StateError('Customer balance cannot go below zero');
      }

      await txn.update(
        'customers',
        {'balance_cents': newBalance},
        where: 'id = ?',
        whereArgs: [customerId],
      );
    });
  }

  Future<int> outstandingCreditTotalCents() async {
    final db = await _db.db;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(balance_cents), 0) AS t FROM customers',
    );
    return (rows.first['t'] as int?) ?? 0;
  }
}
