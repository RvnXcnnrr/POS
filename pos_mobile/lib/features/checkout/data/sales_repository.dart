import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/db/app_database.dart';
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
}
