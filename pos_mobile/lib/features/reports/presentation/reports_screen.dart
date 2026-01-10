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
import '../../../core/utils/responsive.dart';

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
      body: reportsAsync.when(
        data: (state) {
            final s = state.summary;

            final summaryCards = <Widget>[
              _SummaryCard(
                title: 'Total revenue',
                value: Money.format(s.totalSalesCents),
                tone: _SummaryTone.primary,
              ),
              _SummaryCard(
                title: 'COGS',
                value: Money.format(s.cogsCents),
                tone: _SummaryTone.info,
              ),
              _SummaryCard(
                title: 'Gross profit',
                value: Money.format(s.grossProfitCents),
                tone: _SummaryTone.success,
              ),
              _SummaryCard(
                title: 'Cash',
                value: Money.format(s.cashSalesCents),
                tone: _SummaryTone.success,
              ),
              _SummaryCard(
                title: 'Credit',
                value: Money.format(s.creditSalesCents),
                tone: _SummaryTone.warning,
              ),
              _SummaryCard(
                title: 'Transactions',
                value: s.transactionCount.toString(),
                tone: _SummaryTone.neutral,
              ),
              _SummaryCard(
                title: 'Payments collected',
                value: Money.format(s.paymentsCollectedCents),
                tone: _SummaryTone.info,
              ),
              _SummaryCard(
                title: 'Outstanding credit total',
                value: Money.format(s.outstandingCreditCents),
                tone: _SummaryTone.warning,
              ),
            ];

            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >= (n.metrics.maxScrollExtent - 250)) {
                  ref.read(reportsNotifierProvider.notifier).loadMore();
                }
                return false;
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bp = breakpointForWidth(constraints.maxWidth);
                  final isLandscape =
                      MediaQuery.orientationOf(context) == Orientation.landscape;
                  final padding = context.pagePadding;

                  final summaryAspectRatio = switch (bp) {
                    ScreenBreakpoint.compact => isLandscape ? 2.6 : 3.2,
                    ScreenBreakpoint.medium => 2.8,
                    ScreenBreakpoint.expanded => 2.6,
                  };

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: padding,
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Today',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          padding.left,
                          12,
                          padding.right,
                          0,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: bp == ScreenBreakpoint.compact
                                ? 520
                                : 420,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: summaryAspectRatio,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => summaryCards[index],
                            childCount: summaryCards.length,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          padding.left,
                          20,
                          padding.right,
                          8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Transactions',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      if (state.sales.isEmpty)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            padding.left,
                            24,
                            padding.right,
                            24,
                          ),
                          sliver: const SliverToBoxAdapter(
                            child:
                                Center(child: Text('No transactions today.')),
                          ),
                        )
                      else ...[
                        if (bp == ScreenBreakpoint.expanded)
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              padding.left,
                              0,
                              padding.right,
                              8,
                            ),
                            sliver: const SliverToBoxAdapter(
                              child: _TransactionTableHeader(),
                            ),
                          ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            padding.left,
                            0,
                            padding.right,
                            0,
                          ),
                          sliver: SliverList.separated(
                            itemCount: state.sales.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final t = state.sales[index];
                              if (bp == ScreenBreakpoint.expanded) {
                                return _TransactionTableRow(entry: t);
                              }
                              return Card(
                                child: ListTile(
                                  leading:
                                      _PaymentIndicator(type: t.paymentType),
                                  title: Text(Money.format(t.totalCents)),
                                  subtitle: Text(
                                    bp == ScreenBreakpoint.compact
                                        ? _subtitle(t)
                                        : '${_subtitle(t)} • Profit: ${Money.format(t.profitCents)}',
                                  ),
                                  trailing: Text('#${t.id}'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          padding.left,
                          16,
                          padding.right,
                          16,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: state.loadingMore
                              ? const Center(child: CircularProgressIndicator())
                              : (state.hasMore
                                  ? const Center(
                                      child: Text('Scroll to load more…'),
                                    )
                                  : null),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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

class _TransactionTableHeader extends StatelessWidget {
  const _TransactionTableHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                fontWeight: FontWeight.w900,
              ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('ID')),
              Expanded(flex: 3, child: Text('Payment')),
              Expanded(flex: 4, child: Text('Customer')),
              Expanded(flex: 5, child: Text('Time')),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Profit'),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Total'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTableRow extends StatelessWidget {
  const _TransactionTableRow({required this.entry});

  final SaleListEntry entry;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(entry.createdAtMs);
    final typeLabel =
        entry.paymentType == PaymentType.cash ? 'Cash' : 'Credit';
    final customer = entry.paymentType == PaymentType.credit
        ? (entry.customerName ?? '—')
        : '—';

    return Card(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('#${entry.id}')),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    _PaymentIndicator(type: entry.paymentType),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        typeLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  customer,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  dt.toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    Money.format(entry.profitCents),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.sem.success,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    Money.format(entry.totalCents),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
