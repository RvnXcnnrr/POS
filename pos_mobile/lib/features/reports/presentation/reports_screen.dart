import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../application/reports_notifier.dart';
import '../../checkout/data/sale.dart';
import '../../checkout/data/sales_repository.dart';
import '../../products/application/products_notifier.dart';
import '../../customers/application/customers_notifier.dart';
import '../../dashboard/application/dashboard_notifier.dart';
import '../../../core/security/pin_auth.dart';
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
            tooltip: 'Undo last sale',
            onPressed: () async {
              final pinOk = await PinAuth.requirePin(
                context,
                ref,
                reason: 'Undo Last Sale',
              );
              if (!pinOk) return;

              if (!context.mounted) return;

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Undo last sale?'),
                  content: const Text(
                    'This can only undo the most recent sale within 5 minutes.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Undo'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;

              try {
                await ref.read(salesRepositoryProvider).undoLastSale();

                // Refresh all dependent UI.
                ref.invalidate(reportsNotifierProvider);
                ref.invalidate(dashboardNotifierProvider);
                await ref.read(productsNotifierProvider.notifier).load();
                await ref.read(customersNotifierProvider.notifier).load();

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Last sale undone')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            icon: const Icon(Icons.undo),
          ),
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

            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >= (n.metrics.maxScrollExtent - 250)) {
                  ref.read(reportsNotifierProvider.notifier).loadMore();
                }
                return false;
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Today', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    title: 'Total sales',
                    value: Money.format(s.totalSalesCents),
                    tone: _SummaryTone.primary,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Cash',
                          value: Money.format(s.cashSalesCents),
                          tone: _SummaryTone.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Credit',
                          value: Money.format(s.creditSalesCents),
                          tone: _SummaryTone.warning,
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
                          tone: _SummaryTone.neutral,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Payments collected',
                          value: Money.format(s.paymentsCollectedCents),
                          tone: _SummaryTone.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    title: 'Outstanding credit total',
                    value: Money.format(s.outstandingCreditCents),
                    tone: _SummaryTone.warning,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
                            leading: _PaymentIndicator(type: t.paymentType),
                            title: Text(Money.format(t.totalCents)),
                            subtitle: Text(_subtitle(t)),
                            trailing: Text('#${t.id}'),
                          ),
                        ),
                      ),
                    ),
                  if (state.loadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.hasMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('Scroll to load more…')),
                    ),
                ],
              ),
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
    final customerPart =
        (t.paymentType == PaymentType.credit && t.customerName != null)
        ? ' • ${t.customerName}'
        : '';
    return '${dt.toString()} • $typeLabel$customerPart';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.tone,
  });

  final String title;
  final String value;
  final _SummaryTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sem = context.sem;

    final (bg, onBg) = switch (tone) {
      _SummaryTone.primary => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      _SummaryTone.success => (sem.successContainer, sem.onSuccessContainer),
      _SummaryTone.warning => (sem.warningContainer, sem.onWarningContainer),
      _SummaryTone.info => (sem.infoContainer, sem.onInfoContainer),
      _SummaryTone.neutral => (scheme.surfaceContainerHigh, scheme.onSurface),
    };

    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: onBg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: onBg,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SummaryTone { primary, success, warning, info, neutral }

class _PaymentIndicator extends StatelessWidget {
  const _PaymentIndicator({required this.type});

  final PaymentType type;

  @override
  Widget build(BuildContext context) {
    final sem = context.sem;
    final (color, label) = type == PaymentType.cash
        ? (sem.success, 'Cash')
        : (sem.warning, 'Credit');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
