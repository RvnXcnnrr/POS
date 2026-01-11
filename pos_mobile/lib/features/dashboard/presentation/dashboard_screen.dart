import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/utils/responsive.dart';
import '../application/dashboard_notifier.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(dashboardNotifierProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: dashAsync.when(
        data: (d) {
            final statCards = <Widget>[
              _StatCard(
                title: 'Today sales',
                value: Money.format(d.todayTotalSalesCents),
                tone: _CardTone.primary,
              ),
              _StatCard(
                title: 'Today profit',
                value: Money.format(d.todayProfitCents),
                tone: _CardTone.success,
              ),
              _StatCard(
                title: 'Transactions',
                value: d.todayTransactionCount.toString(),
                tone: _CardTone.neutral,
              ),
              _StatCard(
                title: 'Outstanding credit',
                value: Money.format(d.outstandingCreditCents),
                tone: _CardTone.warning,
              ),
              _StatCard(
                title: 'Inventory value',
                value: Money.format(d.inventoryValueCents),
                tone: _CardTone.info,
              ),
              _StatCard(
                title: 'Total assets (est.)',
                value: Money.format(d.totalAssetsCents),
                tone: _CardTone.primary,
              ),
            ];

            Widget lowStockBody() {
              if (d.lowStockProducts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No low stock items.')),
                );
              }

              return Column(
                children: [
                  for (final p in d.lowStockProducts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        color: context.sem.warningContainer,
                        child: ListTile(
                          leading: Icon(
                            Icons.warning_amber_rounded,
                            color: context.sem.onWarningContainer,
                          ),
                          title: Text(
                            p.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: context.sem.onWarningContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          trailing: Text(
                            'Stock: ${p.stock}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: context.sem.onWarningContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }

            Widget statsSection(ScreenBreakpoint bp) {
              if (bp == ScreenBreakpoint.compact) {
                // Two-up grid on phones to reduce scrolling.
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: statCards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.65,
                  ),
                  itemBuilder: (context, index) => statCards[index],
                );
              }

              final maxExtent = bp == ScreenBreakpoint.medium ? 420.0 : 360.0;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: statCards.length,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxExtent,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (context, index) => statCards[index],
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final bp = breakpointForWidth(constraints.maxWidth);
                final padding = context.pagePadding;

                Widget header() {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppGradients.dashboardHeader(context),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                Money.format(d.todayTotalSalesCents),
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 16,
                              runSpacing: 6,
                              children: [
                                Text(
                                  'Profit: ${Money.format(d.todayProfitCents)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Text(
                                  'Tx: ${d.todayTransactionCount}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (bp == ScreenBreakpoint.expanded) {
                  return Padding(
                    padding: padding,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              header(),
                              const SizedBox(height: 12),
                              statsSection(bp),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Low stock alerts',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: lowStockBody(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: padding,
                  children: [
                    header(),
                    const SizedBox(height: 12),
                    statsSection(bp),
                    const SizedBox(height: 20),
                    Text(
                      'Low stock alerts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    lowStockBody(),
                  ],
                );
              },
            );
          },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

enum _CardTone { primary, success, info, neutral, warning }

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.tone,
  });

  final String title;
  final String value;
  final _CardTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sem = context.sem;

    final (bg, onBg) = switch (tone) {
      _CardTone.primary => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _CardTone.success => (sem.successContainer, sem.onSuccessContainer),
      _CardTone.info => (sem.infoContainer, sem.onInfoContainer),
      _CardTone.warning => (sem.warningContainer, sem.onWarningContainer),
      _CardTone.neutral => (scheme.surfaceContainerHigh, scheme.onSurface),
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
              style: (context.isExpanded
                      ? Theme.of(context).textTheme.headlineMedium
                      : Theme.of(context).textTheme.headlineSmall)
                  ?.copyWith(
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
