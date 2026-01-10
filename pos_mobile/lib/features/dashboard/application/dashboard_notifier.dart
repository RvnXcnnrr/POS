import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/data/product.dart';
import '../../products/data/products_repository.dart';
import '../../reports/data/reports_repository.dart';

final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardState>>((ref) {
  return DashboardNotifier(
    productsRepository: ref.watch(productsRepositoryProvider),
    reportsRepository: ref.watch(reportsRepositoryProvider),
  )..load();
});

class DashboardState {
  const DashboardState({
    required this.todayTotalSalesCents,
    required this.todayProfitCents,
    required this.todayTransactionCount,
    required this.outstandingCreditCents,
    required this.inventoryValueCents,
    required this.totalAssetsCents,
    required this.lowStockProducts,
  });

  final int todayTotalSalesCents;
  final int todayProfitCents;
  final int todayTransactionCount;
  final int outstandingCreditCents;
  final int inventoryValueCents;
  final int totalAssetsCents;
  final List<Product> lowStockProducts;
}

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardState>> {
  DashboardNotifier({required ProductsRepository productsRepository, required ReportsRepository reportsRepository})
      : _productsRepository = productsRepository,
        _reportsRepository = reportsRepository,
        super(const AsyncValue.loading());

  final ProductsRepository _productsRepository;
  final ReportsRepository _reportsRepository;

  static const int lowStockThreshold = 5;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final summary = await _reportsRepository.todaySummary();
        final inventoryValueCents = await _productsRepository.inventoryValueCents();
        final cashCollectedTotalCents =
          await _reportsRepository.cashCollectedTotalCents();
        final totalAssetsCents =
          cashCollectedTotalCents + summary.outstandingCreditCents + inventoryValueCents;
      final products = await _productsRepository.listAll();
      final lowStock = products.where((p) => p.stock <= lowStockThreshold).toList()
        ..sort((a, b) => a.stock.compareTo(b.stock));

      return DashboardState(
        todayTotalSalesCents: summary.totalSalesCents,
        todayProfitCents: summary.grossProfitCents,
        todayTransactionCount: summary.transactionCount,
        outstandingCreditCents: summary.outstandingCreditCents,
        inventoryValueCents: inventoryValueCents,
        totalAssetsCents: totalAssetsCents,
        lowStockProducts: lowStock,
      );
    });
  }
}
