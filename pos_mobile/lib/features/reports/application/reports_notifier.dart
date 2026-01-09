import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reports_repository.dart';
import '../../../core/utils/business_day.dart';

final reportsNotifierProvider =
    StateNotifierProvider<ReportsNotifier, AsyncValue<ReportsState>>((ref) {
      return ReportsNotifier(ref.watch(reportsRepositoryProvider))..load();
    });

class ReportsState {
  const ReportsState({
    required this.summary,
    required this.sales,
    required this.hasMore,
    required this.loadingMore,
    required this.businessDate,
  });

  final DailySalesSummary summary;
  final List<SaleListEntry> sales;
  final bool hasMore;
  final bool loadingMore;
  final String businessDate;
}

class ReportsNotifier extends StateNotifier<AsyncValue<ReportsState>> {
  ReportsNotifier(this._repo) : super(const AsyncValue.loading());

  final ReportsRepository _repo;

  static const int _pageSize = 50;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final summary = await _repo.todaySummary();
      final businessDate = BusinessDay.businessDateFor(DateTime.now());
      final page = await _repo.salesListByBusinessDate(
        businessDate: businessDate,
        limit: _pageSize + 1,
        offset: 0,
      );

      final hasMore = page.length > _pageSize;
      final sales = hasMore ? page.take(_pageSize).toList() : page;
      return ReportsState(
        summary: summary,
        sales: sales,
        hasMore: hasMore,
        loadingMore: false,
        businessDate: businessDate,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! AsyncData<ReportsState>) return;

    final s = current.value;
    if (!s.hasMore || s.loadingMore) return;

    state = AsyncData(
      ReportsState(
        summary: s.summary,
        sales: s.sales,
        hasMore: s.hasMore,
        loadingMore: true,
        businessDate: s.businessDate,
      ),
    );

    try {
      final page = await _repo.salesListByBusinessDate(
        businessDate: s.businessDate,
        limit: _pageSize + 1,
        offset: s.sales.length,
      );

      final hasMore = page.length > _pageSize;
      final nextSales = <SaleListEntry>[...s.sales, ...page.take(_pageSize)];

      state = AsyncData(
        ReportsState(
          summary: s.summary,
          sales: nextSales,
          hasMore: hasMore,
          loadingMore: false,
          businessDate: s.businessDate,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
