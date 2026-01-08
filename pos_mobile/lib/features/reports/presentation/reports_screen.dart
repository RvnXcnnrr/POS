import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money.dart';
import '../application/reports_notifier.dart';
import '../../checkout/data/sale.dart';
import '../data/reports_repository.dart' show SaleListEntry;

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(reportsNotifierProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: reportsAsync.when(
          data: (state) {
            final s = state.summary;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Today', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _SummaryCard(
                  title: 'Total sales',
                  value: Money.format(s.totalSalesCents),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Cash',
                        value: Money.format(s.cashSalesCents),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Credit',
                        value: Money.format(s.creditSalesCents),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Transactions',
                        value: s.transactionCount.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Payments collected',
                        value: Money.format(s.paymentsCollectedCents),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  title: 'Outstanding credit total',
                  value: Money.format(s.outstandingCreditCents),
                ),
                const SizedBox(height: 20),
                Text('Transactions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (state.sales.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No transactions today.')),
                  )
                else
                  ...state.sales.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          title: Text(Money.format(t.totalCents)),
                          subtitle: Text(_subtitle(t)),
                          trailing: Text('#${t.id}'),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  String _subtitle(SaleListEntry t) {
    final dt = DateTime.fromMillisecondsSinceEpoch(t.createdAtMs);
    final typeLabel = t.paymentType == PaymentType.cash ? 'Cash' : 'Credit';
    final customerPart = (t.paymentType == PaymentType.credit && t.customerName != null)
        ? ' • ${t.customerName}'
        : '';
    return '${dt.toString()} • $typeLabel$customerPart';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
