import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reports_repository.dart';

final reportsNotifierProvider =
    StateNotifierProvider<ReportsNotifier, AsyncValue<ReportsState>>((ref) {
  return ReportsNotifier(ref.watch(reportsRepositoryProvider))..load();
});

class ReportsState {
  const ReportsState({required this.summary, required this.sales});

  final DailySalesSummary summary;
  final List<SaleListEntry> sales;
}

class ReportsNotifier extends StateNotifier<AsyncValue<ReportsState>> {
  ReportsNotifier(this._repo) : super(const AsyncValue.loading());

  final ReportsRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final summary = await _repo.todaySummary();
      final sales = await _repo.todaySalesList();
      return ReportsState(summary: summary, sales: sales);
    });
  }
}
