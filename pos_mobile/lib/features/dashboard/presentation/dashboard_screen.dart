import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money.dart';
import '../../../core/theme/app_semantic_colors.dart';
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
      body: SafeArea(
        child: dashAsync.when(
          data: (d) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Today sales',
                        value: Money.format(d.todayTotalSalesCents),
                        tone: _CardTone.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Transactions',
                        value: d.todayTransactionCount.toString(),
                        tone: _CardTone.neutral,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: 'Outstanding credit',
                  value: Money.format(d.outstandingCreditCents),
                  tone: _CardTone.warning,
                ),
                const SizedBox(height: 20),
                Text(
                  'Low stock alerts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (d.lowStockProducts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No low stock items.')),
                  )
                else
                  ...d.lowStockProducts.map(
                    (p) => Padding(
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
}

enum _CardTone { primary, neutral, warning }

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
