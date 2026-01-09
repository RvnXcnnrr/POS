import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/utils/business_day.dart';
import '../../checkout/data/sale.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(appDatabaseProvider));
});

class DailySalesSummary {
  const DailySalesSummary({
    required this.totalSalesCents,
    required this.cashSalesCents,
    required this.creditSalesCents,
    required this.transactionCount,
    required this.paymentsCollectedCents,
    required this.outstandingCreditCents,
  });

  final int totalSalesCents;
  final int cashSalesCents;
  final int creditSalesCents;
  final int transactionCount;
  final int paymentsCollectedCents;
  final int outstandingCreditCents;
}

class SaleListEntry {
  const SaleListEntry({
    required this.id,
    required this.totalCents,
    required this.paymentType,
    required this.createdAtMs,
    required this.customerName,
  });

  final int id;
  final int totalCents;
  final PaymentType paymentType;
  final int createdAtMs;
  final String? customerName;
}

class ReportsRepository {
  ReportsRepository(this._db);

  final AppDatabase _db;

  Future<DailySalesSummary> todaySummary() async {
    final now = DateTime.now();
    final businessDate = BusinessDay.businessDateFor(now);
    final range = BusinessDay.businessDayRange(now);
    final db = await _db.db;

    final salesTotals = await db.rawQuery(
      '''
SELECT
  COALESCE(SUM(total_amount_cents), 0) AS total,
  COALESCE(SUM(CASE WHEN payment_type = 'cash' THEN total_amount_cents ELSE 0 END), 0) AS cash_total,
  COALESCE(SUM(CASE WHEN payment_type = 'credit' THEN total_amount_cents ELSE 0 END), 0) AS credit_total,
  COUNT(1) AS txn_count
FROM sales
WHERE business_date = ? AND is_voided = 0
''',
      [businessDate],
    );

    final paymentsTotals = await db.rawQuery(
      '''
SELECT COALESCE(SUM(amount_cents), 0) AS t
FROM payments
WHERE created_at >= ? AND created_at < ?
''',
      [range.startMs, range.endExclusiveMs],
    );

    final outstanding = await db.rawQuery(
      'SELECT COALESCE(SUM(balance_cents), 0) AS t FROM customers',
    );

    final row = salesTotals.first;
    return DailySalesSummary(
      totalSalesCents: (row['total'] as int?) ?? 0,
      cashSalesCents: (row['cash_total'] as int?) ?? 0,
      creditSalesCents: (row['credit_total'] as int?) ?? 0,
      transactionCount: (row['txn_count'] as int?) ?? 0,
      paymentsCollectedCents: (paymentsTotals.first['t'] as int?) ?? 0,
      outstandingCreditCents: (outstanding.first['t'] as int?) ?? 0,
    );
  }

  Future<List<SaleListEntry>> salesListByBusinessDate({
    required String businessDate,
    required int limit,
    required int offset,
  }) async {
    final db = await _db.db;

    final rows = await db.rawQuery(
      '''
SELECT
  s.id,
  s.total_amount_cents,
  s.payment_type,
  s.created_at,
  c.name AS customer_name
FROM sales s
LEFT JOIN customers c ON c.id = s.customer_id
WHERE s.business_date = ? AND s.is_voided = 0
ORDER BY s.created_at DESC
LIMIT ? OFFSET ?
''',
      [businessDate, limit, offset],
    );

    return rows
        .map(
          (r) => SaleListEntry(
            id: r['id'] as int,
            totalCents: r['total_amount_cents'] as int,
            paymentType: PaymentTypeDb.fromDb(r['payment_type'] as String),
            createdAtMs: r['created_at'] as int,
            customerName: r['customer_name'] as String?,
          ),
        )
        .toList();
  }

  Future<List<SaleListEntry>> todaySalesList() async {
    final businessDate = BusinessDay.businessDateFor(DateTime.now());
    return salesListByBusinessDate(
      businessDate: businessDate,
      limit: 2000,
      offset: 0,
    );
  }
}
