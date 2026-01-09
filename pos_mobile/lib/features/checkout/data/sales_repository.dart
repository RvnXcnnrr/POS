import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/utils/business_day.dart';
import 'sale.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(ref.watch(appDatabaseProvider));
});

class CartLineInput {
  CartLineInput({
    required this.productId,
    required this.quantity,
    required this.unitPriceCents,
  });

  final int productId;
  final int quantity;
  final int unitPriceCents;
}

class SalesRepository {
  SalesRepository(this._db);

  final AppDatabase _db;

  /// REQUIRED transaction scope:
  /// - Save sale
  /// - Save sale items
  /// - Deduct stock
  /// - Update customer balance (credit)
  /// - Write business_date
  Future<int> completeSale({
    required List<CartLineInput> lines,
    required PaymentType paymentType,
    int? customerId,
  }) async {
    if (lines.isEmpty) {
      throw StateError('Cart is empty');
    }
    if (paymentType == PaymentType.credit && customerId == null) {
      throw StateError('Customer is required for credit sales');
    }

    final totalCents = lines.fold<int>(
      0,
      (sum, line) => sum + (line.unitPriceCents * line.quantity),
    );

    final db = await _db.db;
    final now = DateTime.now();
    final businessDate = BusinessDay.businessDateFor(now);
    return db.transaction<int>((txn) async {
      // Validate stock and product existence
      for (final line in lines) {
        final productRows = await txn.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [line.productId],
        );
        if (productRows.isEmpty) {
          throw StateError('Product not found');
        }
        final currentStock = productRows.first['stock'] as int;
        if (line.quantity <= 0) {
          throw StateError('Invalid quantity');
        }
        if (currentStock < line.quantity) {
          throw StateError('Not enough stock');
        }
      }

      final saleId = await txn.insert('sales', {
        'total_amount_cents': totalCents,
        'payment_type': paymentType.dbValue,
        'customer_id': customerId,
        'business_date': businessDate,
        'is_voided': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      for (final line in lines) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': line.productId,
          'quantity': line.quantity,
          'price_cents': line.unitPriceCents,
        });

        final productRows = await txn.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [line.productId],
        );
        final currentStock = productRows.first['stock'] as int;
        await txn.update(
          'products',
          {'stock': currentStock - line.quantity},
          where: 'id = ?',
          whereArgs: [line.productId],
        );
      }

      if (paymentType == PaymentType.credit) {
        final rows = await txn.query(
          'customers',
          columns: ['balance_cents'],
          where: 'id = ?',
          whereArgs: [customerId],
        );
        if (rows.isEmpty) {
          throw StateError('Customer not found');
        }
        final currentBalance = rows.first['balance_cents'] as int;
        final newBalance = currentBalance + totalCents;

        await txn.update(
          'customers',
          {'balance_cents': newBalance},
          where: 'id = ?',
          whereArgs: [customerId],
        );
      }

      return saleId;
    });
  }

  /// Undo the most recent non-voided sale if it is within [within].
  ///
  /// Rules:
  /// - Marks the sale as voided (is_voided = 1)
  /// - Restores product stock
  /// - Reverses customer balance if credit
  /// - Atomic transaction; rolls back on any failure
  Future<int> undoLastSale({
    Duration within = const Duration(minutes: 5),
  }) async {
    final db = await _db.db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    return db.transaction<int>((txn) async {
      final saleRows = await txn.rawQuery('''
SELECT id, total_amount_cents, payment_type, customer_id, created_at
FROM sales
WHERE is_voided = 0
ORDER BY created_at DESC
LIMIT 1
''');

      if (saleRows.isEmpty) {
        throw StateError('No sale to undo');
      }

      final sale = saleRows.first;
      final saleId = sale['id'] as int;
      final createdAt = sale['created_at'] as int;
      final ageMs = nowMs - createdAt;
      if (ageMs > within.inMilliseconds) {
        throw StateError('Undo window expired');
      }

      final items = await txn.query(
        'sale_items',
        columns: ['product_id', 'quantity'],
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );

      for (final item in items) {
        final productId = item['product_id'] as int;
        final qty = item['quantity'] as int;
        if (qty <= 0) continue;

        final productRows = await txn.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [productId],
        );
        if (productRows.isEmpty) {
          throw StateError('Product not found for undo');
        }
        final currentStock = productRows.first['stock'] as int;
        await txn.update(
          'products',
          {'stock': currentStock + qty},
          where: 'id = ?',
          whereArgs: [productId],
        );
      }

      final paymentType = PaymentTypeDb.fromDb(sale['payment_type'] as String);
      if (paymentType == PaymentType.credit) {
        final customerId = sale['customer_id'] as int?;
        if (customerId == null) {
          throw StateError('Credit sale missing customer');
        }

        final customerRows = await txn.query(
          'customers',
          columns: ['balance_cents'],
          where: 'id = ?',
          whereArgs: [customerId],
        );
        if (customerRows.isEmpty) {
          throw StateError('Customer not found for undo');
        }

        final totalCents = sale['total_amount_cents'] as int;
        final currentBalance = customerRows.first['balance_cents'] as int;
        final newBalance = currentBalance - totalCents;
        if (newBalance < 0) {
          throw StateError('Undo would make customer balance negative');
        }

        await txn.update(
          'customers',
          {'balance_cents': newBalance},
          where: 'id = ?',
          whereArgs: [customerId],
        );
      }

      await txn.update(
        'sales',
        {'is_voided': 1},
        where: 'id = ?',
        whereArgs: [saleId],
      );

      return saleId;
    });
  }
}
