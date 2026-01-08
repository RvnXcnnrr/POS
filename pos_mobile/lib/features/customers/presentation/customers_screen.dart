import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../application/customers_notifier.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers (Utang)')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/settings/customers/new'),
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: SafeArea(
        child: customersAsync.when(
          data: (customers) {
            if (customers.isEmpty) {
              return const Center(child: Text('No customers yet.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = customers[index];
                final hasUtang = c.balanceCents > 0;
                final indicatorColor = hasUtang
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary;

                return InkWell(
                  onTap: () => context.go('/settings/customers/${c.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 14, color: indicatorColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: Theme.of(context).textTheme.titleMedium),
                                if (c.phone != null && c.phone!.trim().isNotEmpty)
                                  Text(c.phone!, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Money.format(c.balanceCents),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: indicatorColor,
                                    ),
                              ),
                              Text(hasUtang ? 'Has utang' : 'Paid', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
