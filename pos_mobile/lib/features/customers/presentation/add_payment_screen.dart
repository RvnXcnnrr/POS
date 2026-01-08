import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money.dart';
import '../../dashboard/application/dashboard_notifier.dart';
import '../../reports/application/reports_notifier.dart';
import '../application/customers_notifier.dart';
import '../data/customers_repository.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  const AddPaymentScreen({super.key, required this.customerId});

  final int customerId;

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerId = widget.customerId;
    final customerAsync = ref.watch(customerByIdProvider(customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Add Payment')),
      body: SafeArea(
        child: customerAsync.when(
          data: (customer) {
            if (customer == null) return const Center(child: Text('Customer not found'));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Text('Current balance', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          Money.format(customer.balanceCents),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: customer.balanceCents > 0
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Payment amount',
                      prefixText: '₱',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final cents = Money.tryParseToCents(v ?? '');
                      if (cents == null) return 'Enter a valid amount';
                      if (cents <= 0) return 'Must be > 0';
                      if (cents > customer.balanceCents) return 'Cannot pay more than balance';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final ok = _formKey.currentState?.validate() ?? false;
                            if (!ok) return;

                            final cents = Money.tryParseToCents(_amountCtrl.text)!;
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm payment'),
                                content: Text('Record payment of ${Money.format(cents)}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;

                            setState(() => _saving = true);
                            try {
                              await ref.read(customersRepositoryProvider).addPayment(
                                    customerId: customerId,
                                    amountCents: cents,
                                  );
                              await ref.read(customersNotifierProvider.notifier).load();
                              ref.invalidate(customerByIdProvider(customerId));
                              ref.invalidate(paymentsByCustomerProvider(customerId));
                              ref.invalidate(reportsNotifierProvider);
                              ref.invalidate(dashboardNotifierProvider);
                              if (!mounted) return;
                              navigator.pop();
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                    child: const Text('CONFIRM PAYMENT'),
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
