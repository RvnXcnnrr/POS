import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money.dart';
import '../../customers/data/customer.dart';
import '../../customers/application/customers_notifier.dart';
import '../../customers/data/customers_repository.dart';
import '../../products/application/products_notifier.dart';
import '../../products/data/product.dart';
import '../../dashboard/application/dashboard_notifier.dart';
import '../../reports/application/reports_notifier.dart';
import '../application/cart_notifier.dart';
import '../data/sale.dart';
import '../data/sales_repository.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsNotifierProvider);
    final cart = ref.watch(cartNotifierProvider);

    final totalStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return const Center(child: Text('Add products in Settings → Products.'));
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                Text('TOTAL', style: Theme.of(context).textTheme.titleMedium),
                Text(Money.format(cart.totalCents), style: totalStyle),
                const SizedBox(height: 12),
                _PaymentTypePicker(
                  value: cart.paymentType,
                  onChanged: (t) => ref.read(cartNotifierProvider.notifier).setPaymentType(t),
                ),
                if (cart.paymentType == PaymentType.credit) ...[
                  const SizedBox(height: 12),
                  _CreditCustomerSection(products: products),
                ],
                const SizedBox(height: 16),
                Text('Products', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _ProductGrid(
                  products: products,
                  onTapProduct: (p) {
                    if (p.stock <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Out of stock')),
                      );
                      return;
                    }
                    final existing = cart.linesByProductId[p.id];
                    if (existing != null && existing.quantity >= p.stock) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Not enough stock')),
                      );
                      return;
                    }
                    ref.read(cartNotifierProvider.notifier).addProduct(p);
                  },
                ),
                const SizedBox(height: 16),
                Text('Cart', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (cart.linesByProductId.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Cart is empty. Tap products to add.')),
                  )
                else
                  _CartLines(products: products),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cart.paymentType == PaymentType.cash
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: cart.totalCents <= 0
                  ? null
                  : () async {
                      if (cart.paymentType == PaymentType.credit && cart.selectedCustomer == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Select a customer for credit sale.')),
                        );
                        return;
                      }

                      if (cart.paymentType == PaymentType.credit) {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            final customer = cart.selectedCustomer!;
                            final after = customer.balanceCents + cart.totalCents;
                            return AlertDialog(
                              title: const Text('Confirm credit sale'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Customer: ${customer.name}'),
                                  const SizedBox(height: 8),
                                  Text('Current balance: ${Money.format(customer.balanceCents)}'),
                                  Text('Balance after sale: ${Money.format(after)}'),
                                ],
                              ),
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
                            );
                          },
                        );
                        if (confirmed != true) return;
                      }

                      try {
                        final salesRepo = ref.read(salesRepositoryProvider);
                        final selectedCustomerId = cart.selectedCustomer?.id;
                        final lines = cart.lines
                            .map(
                              (l) => CartLineInput(
                                productId: l.productId,
                                quantity: l.quantity,
                                unitPriceCents: l.unitPriceCents,
                              ),
                            )
                            .toList();

                        await salesRepo.completeSale(
                          lines: lines,
                          paymentType: cart.paymentType,
                          customerId: cart.selectedCustomer?.id,
                        );

                        ref.read(cartNotifierProvider.notifier).clear();
                        await ref.read(productsNotifierProvider.notifier).load();

                        // Keep reports/dashboard/customer balances in sync after a transaction.
                        ref.invalidate(reportsNotifierProvider);
                        ref.invalidate(dashboardNotifierProvider);
                        await ref.read(customersNotifierProvider.notifier).load();
                        if (selectedCustomerId != null) {
                          ref.invalidate(customerByIdProvider(selectedCustomerId));
                        }

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sale completed')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      }
                    },
              child: Text(cart.paymentType == PaymentType.cash ? 'COMPLETE SALE (CASH)' : 'COMPLETE SALE (CREDIT)'),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentTypePicker extends StatelessWidget {
  const _PaymentTypePicker({required this.value, required this.onChanged});

  final PaymentType value;
  final ValueChanged<PaymentType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PaymentType>(
      segments: const [
        ButtonSegment(value: PaymentType.cash, label: Text('Cash')),
        ButtonSegment(value: PaymentType.credit, label: Text('Credit (Utang)')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _CreditCustomerSection extends ConsumerWidget {
  const _CreditCustomerSection({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);
    final customer = cart.selectedCustomer;
    final after = customer == null ? null : customer.balanceCents + cart.totalCents;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Credit sale requires a customer and confirmation.',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    customer == null ? 'No customer selected' : customer.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await _pickCustomer(context, ref);
                    if (picked == null) return;
                    ref.read(cartNotifierProvider.notifier).selectCustomer(picked);
                  },
                  child: const Text('Select'),
                ),
              ],
            ),
            if (customer != null) ...[
              const SizedBox(height: 8),
              Text('Current balance: ${Money.format(customer.balanceCents)}'),
              Text('Balance after sale: ${Money.format(after!)}'),
            ],
          ],
        ),
      ),
    );
  }

  Future<Customer?> _pickCustomer(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(customersRepositoryProvider);
    final customers = await repo.listAllByHighestBalance();
    if (!context.mounted) return null;

    return showModalBottomSheet<Customer>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (customers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No customers yet. Add customers in Settings → Customers.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final c = customers[index];
            final hasUtang = c.balanceCents > 0;
            return ListTile(
              tileColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(c.name),
              subtitle: Text('Balance: ${Money.format(c.balanceCents)}'),
              trailing: Icon(
                hasUtang ? Icons.circle : Icons.check_circle,
                color: hasUtang
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
              onTap: () => Navigator.pop(context, c),
            );
          },
        );
      },
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, required this.onTapProduct});

  final List<Product> products;
  final ValueChanged<Product> onTapProduct;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final p = products[index];
        final outOfStock = p.stock <= 0;

        return InkWell(
          onTap: outOfStock ? null : () => onTapProduct(p),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(Money.format(p.priceCents), style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    outOfStock ? 'Out of stock' : 'Stock: ${p.stock}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CartLines extends ConsumerWidget {
  const _CartLines({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);
    final notifier = ref.read(cartNotifierProvider.notifier);

    final stockById = {for (final p in products) p.id: p.stock};

    return Column(
      children: [
        for (final line in cart.lines) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(line.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('${Money.format(line.unitPriceCents)} each'),
                        Text('Line total: ${Money.format(line.lineTotalCents)}'),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => notifier.decrement(line.productId),
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Decrease',
                  ),
                  Text('${line.quantity}', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    onPressed: () {
                      final maxStock = stockById[line.productId] ?? 0;
                      if (line.quantity >= maxStock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Not enough stock')),
                        );
                        return;
                      }
                      notifier.increment(line.productId, maxStock: maxStock);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Increase',
                  ),
                  IconButton(
                    onPressed: () => notifier.remove(line.productId),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
