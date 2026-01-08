import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../application/customers_notifier.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(customerId));
    final paymentsAsync = ref.watch(paymentsByCustomerProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => context.go('/settings/customers/$customerId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: customerAsync.when(
          data: (customer) {
            if (customer == null) return const Center(child: Text('Customer not found'));
            final hasUtang = customer.balanceCents > 0;
            final indicatorColor = hasUtang
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle, size: 14, color: indicatorColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(customer.name, style: Theme.of(context).textTheme.titleLarge),
                            ),
                          ],
                        ),
                        if (customer.phone != null && customer.phone!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(customer.phone!, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 16),
                        Text('Outstanding balance', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          Money.format(customer.balanceCents),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: indicatorColor,
                              ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: customer.balanceCents <= 0
                                ? null
                                : () => context.go('/settings/customers/$customerId/payment'),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Add Payment'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Payment history', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                paymentsAsync.when(
                  data: (payments) {
                    if (payments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No payments yet.')),
                      );
                    }

                    return Column(
                      children: [
                        for (final p in payments) ...[
                          Card(
                            child: ListTile(
                              title: Text(Money.format(p.amountCents)),
                              subtitle: Text(DateTime.fromMillisecondsSinceEpoch(p.createdAtMs).toString()),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
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
