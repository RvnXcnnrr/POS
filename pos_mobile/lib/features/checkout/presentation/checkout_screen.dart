import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/gradient_button.dart';
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

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _processing = false;

  Future<bool> _showReviewDialog({
    required BuildContext context,
    required CartState cart,
  }) async {
    final customer = cart.selectedCustomer;
    final after = customer == null
        ? null
        : customer.balanceCents + cart.totalCents;

    return (await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Review Sale'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final line in cart.lines) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${line.name}\n${line.quantity} × ${Money.format(line.unitPriceCents)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(Money.format(line.lineTotalCents)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text(Money.format(cart.totalCents)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          Money.format(cart.totalCents),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Payment: '),
                        Text(
                          cart.paymentType == PaymentType.cash
                              ? 'Cash'
                              : 'Credit (Utang)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    if (cart.paymentType == PaymentType.credit) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Customer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(customer?.name ?? 'No customer selected'),
                      const SizedBox(height: 8),
                      Text(
                        'Balance before: ${Money.format(customer?.balanceCents ?? 0)}',
                      ),
                      Text('Balance after:  ${Money.format(after ?? 0)}'),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm Sale'),
                ),
              ],
            );
          },
        )) ==
        true;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsNotifierProvider);
    final cart = ref.watch(cartNotifierProvider);

    final sem = context.sem;
    final scheme = Theme.of(context).colorScheme;

    TextStyle? totalStyleFor(ScreenBreakpoint bp) {
      final base = switch (bp) {
        ScreenBreakpoint.compact => Theme.of(context).textTheme.displayMedium,
        ScreenBreakpoint.medium => Theme.of(context).textTheme.displayLarge,
        ScreenBreakpoint.expanded => Theme.of(context).textTheme.displayLarge,
      };
      return base?.copyWith(
        fontWeight: FontWeight.w900,
        color: scheme.onPrimaryContainer,
        letterSpacing: -0.5,
      );
    }

    Widget totalCard(ScreenBreakpoint bp) {
      return Card(
        color: const Color(0x00000000),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.checkoutTotal(context),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Money.format(cart.totalCents),
                      style: totalStyleFor(bp),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget paymentAndCustomer(List<Product> products) {
      return Column(
        children: [
          _PaymentTypePicker(
            value: cart.paymentType,
            enabled: !_processing,
            onChanged: (t) =>
                ref.read(cartNotifierProvider.notifier).setPaymentType(t),
          ),
          if (cart.paymentType == PaymentType.credit) ...[
            const SizedBox(height: 12),
            _CreditCustomerSection(products: products, enabled: !_processing),
          ],
        ],
      );
    }

    Widget productsSection({
      required List<Product> products,
      required ScreenBreakpoint bp,
    }) {
      final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
      final maxExtent = switch (bp) {
        ScreenBreakpoint.compact => isLandscape ? 220.0 : 240.0,
        ScreenBreakpoint.medium => 240.0,
        ScreenBreakpoint.expanded => 260.0,
      };

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Products', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _ProductGrid(
            products: products,
            enabled: !_processing,
            maxCrossAxisExtent: maxExtent,
            scrollable: false,
            onTapProduct: (p) {
              if (_processing) return;
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
        ],
      );
    }

    Widget cartSection({required List<Product> products}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cart', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (cart.linesByProductId.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Cart is empty. Tap products to add.')),
            )
          else
            _CartLines(products: products, enabled: !_processing),
        ],
      );
    }

    Future<void> onCompletePressed() async {
      if (cart.paymentType == PaymentType.credit &&
          cart.selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a customer for credit sale.')),
        );
        return;
      }

      final confirmed = await _showReviewDialog(context: context, cart: cart);
      if (!confirmed) return;

      try {
        setState(() => _processing = true);
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      } finally {
        if (mounted) setState(() => _processing = false);
      }
    }

    Widget completeButton() {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor:
              cart.paymentType == PaymentType.cash ? sem.success : sem.warning,
          foregroundColor: cart.paymentType == PaymentType.cash
              ? sem.onSuccess
              : sem.onWarning,
        ),
        onPressed: (_processing || cart.totalCents <= 0)
            ? null
            : () => onCompletePressed(),
        child: Text(
          cart.paymentType == PaymentType.cash
              ? 'COMPLETE SALE (CASH)'
              : 'COMPLETE SALE (CREDIT)',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('Add products in Settings → Products.'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final bp = breakpointForWidth(constraints.maxWidth);
              final padding = context.pagePadding;

              final isLandscape =
                  MediaQuery.orientationOf(context) == Orientation.landscape;
              final productMaxExtent = switch (bp) {
                ScreenBreakpoint.compact => isLandscape ? 220.0 : 240.0,
                ScreenBreakpoint.medium => 240.0,
                ScreenBreakpoint.expanded => 260.0,
              };

              Widget productsPane({required bool includeSummary}) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (includeSummary) ...[
                      totalCard(bp),
                      const SizedBox(height: 12),
                      paymentAndCustomer(products),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Products',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _ProductGrid(
                        products: products,
                        enabled: !_processing,
                        maxCrossAxisExtent: productMaxExtent,
                        scrollable: true,
                        onTapProduct: (p) {
                          if (_processing) return;
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
                    ),
                  ],
                );
              }

              Widget cartPane() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cart',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          if (cart.linesByProductId.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child:
                                    Text('Cart is empty. Tap products to add.'),
                              ),
                            )
                          else
                            _CartLines(products: products, enabled: !_processing),
                        ],
                      ),
                    ),
                  ],
                );
              }

              if (bp == ScreenBreakpoint.compact) {
                return ListView(
                  padding: padding,
                  children: [
                    totalCard(bp),
                    const SizedBox(height: 12),
                    paymentAndCustomer(products),
                    const SizedBox(height: 16),
                    productsSection(products: products, bp: bp),
                    const SizedBox(height: 16),
                    cartSection(products: products),
                  ],
                );
              }

              if (bp == ScreenBreakpoint.medium) {
                return Padding(
                  padding: padding,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: productsPane(includeSummary: true),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: cartPane(),
                      ),
                    ],
                  ),
                );
              }

              // Expanded: 3 columns (Products | Cart | Summary/Actions)
              return Padding(
                padding: padding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: productsPane(includeSummary: false),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: cartPane(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  totalCard(bp),
                                  const SizedBox(height: 12),
                                  paymentAndCustomer(products),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 56),
                            child: SizedBox(
                              width: double.infinity,
                              child: completeButton(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final bp = breakpointForWidth(constraints.maxWidth);
          if (bp == ScreenBreakpoint.expanded) return const SizedBox.shrink();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: SizedBox(width: double.infinity, child: completeButton()),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PaymentTypePicker extends StatelessWidget {
  const _PaymentTypePicker({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final PaymentType value;
  final bool enabled;
  final ValueChanged<PaymentType> onChanged;

  @override
  Widget build(BuildContext context) {
    final sem = context.sem;
    final scheme = Theme.of(context).colorScheme;

    Widget buildOption({
      required bool selected,
      required String label,
      required VoidCallback? onPressed,
      required Gradient selectedGradient,
      required Color selectedFg,
    }) {
      if (selected) {
        return GradientButton(
          onPressed: onPressed,
          gradient: selectedGradient,
          foregroundColor: selectedFg,
          minHeight: 52,
          child: Text(label),
        );
      }

      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: buildOption(
            selected: value == PaymentType.cash,
            label: 'Cash',
            onPressed: enabled ? () => onChanged(PaymentType.cash) : null,
            selectedGradient: AppGradients.paymentCash(context),
            selectedFg: sem.onSuccess,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildOption(
            selected: value == PaymentType.credit,
            label: 'Credit (Utang)',
            onPressed: enabled ? () => onChanged(PaymentType.credit) : null,
            selectedGradient: AppGradients.paymentCredit(context),
            selectedFg: sem.onWarning,
          ),
        ),
      ],
    );
  }
}

class _CreditCustomerSection extends ConsumerWidget {
  const _CreditCustomerSection({required this.products, required this.enabled});

  final List<Product> products;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);
    final customer = cart.selectedCustomer;
    final after = customer == null
        ? null
        : customer.balanceCents + cart.totalCents;

    final sem = context.sem;

    return Card(
      color: sem.warningContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: sem.onWarningContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Credit sale requires a customer and confirmation.',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: sem.onWarningContainer,
                      fontWeight: FontWeight.w800,
                    ),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: sem.onWarningContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: !enabled
                      ? null
                      : () async {
                          final picked = await _pickCustomer(context, ref);
                          if (picked == null) return;
                          ref
                              .read(cartNotifierProvider.notifier)
                              .selectCustomer(picked);
                        },
                  child: const Text('Select'),
                ),
              ],
            ),
            if (customer != null) ...[
              const SizedBox(height: 8),
              Text(
                'Current balance: ${Money.format(customer.balanceCents)}',
                style: TextStyle(color: sem.onWarningContainer),
              ),
              Text(
                'Balance after sale: ${Money.format(after!)}',
                style: TextStyle(color: sem.onWarningContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<Customer?> _pickCustomer(BuildContext context, WidgetRef ref) async {
    final rootContext = context;
    final repo = ref.read(customersRepositoryProvider);
    final customers = await repo.listAllByHighestBalance();
    if (!context.mounted) return null;

    return showModalBottomSheet<Customer>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (customers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No customers yet. Add a customer to use Credit (Utang).',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    rootContext.go('/settings/customers/new');
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add customer'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Add customer'),
                subtitle: const Text('Create a new utang (credit) customer'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  rootContext.go('/settings/customers/new');
                },
              );
            }

            final customerIndex = index - 1;
            final c = customers[customerIndex];
            final hasUtang = c.balanceCents > 0;
            final sem = context.sem;
            final scheme = Theme.of(context).colorScheme;
            return ListTile(
              tileColor: scheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(c.name),
              subtitle: Text('Balance: ${Money.format(c.balanceCents)}'),
              trailing: Icon(
                hasUtang ? Icons.circle : Icons.check_circle,
                color: hasUtang ? sem.warning : sem.success,
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
  const _ProductGrid({
    required this.products,
    required this.enabled,
    required this.maxCrossAxisExtent,
    required this.scrollable,
    required this.onTapProduct,
  });

  final List<Product> products;
  final bool enabled;
  final double maxCrossAxisExtent;
  final bool scrollable;
  final ValueChanged<Product> onTapProduct;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: !scrollable,
      physics: scrollable ? null : const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final p = products[index];
        final outOfStock = p.stock <= 0;
        final lowStock = p.stock > 0 && p.stock <= 5;

        final sem = context.sem;
        final badgeColor = outOfStock
            ? sem.danger
            : (lowStock ? sem.warning : sem.success);
        final badgeTextColor = outOfStock
            ? sem.onDanger
            : (lowStock ? sem.onWarning : sem.onSuccess);

        final canTap = enabled && !outOfStock;

        return InkWell(
          onTap: canTap ? () => onTapProduct(p) : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
            child: Opacity(
              opacity: canTap ? 1.0 : 0.55,
              child: Stack(
                children: [
                  Padding(
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
                        Text(
                          Money.format(p.priceCents),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          outOfStock ? 'Out of stock' : 'Stock: ${p.stock}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${p.stock}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: badgeTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
  const _CartLines({required this.products, required this.enabled});

  final List<Product> products;
  final bool enabled;

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
                        Text(
                          line.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text('${Money.format(line.unitPriceCents)} each'),
                        Text(
                          'Line total: ${Money.format(line.lineTotalCents)}',
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: !enabled
                        ? null
                        : () => notifier.decrement(line.productId),
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Decrease',
                  ),
                  Text(
                    '${line.quantity}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: !enabled
                        ? null
                        : () {
                            final maxStock = stockById[line.productId] ?? 0;
                            if (line.quantity >= maxStock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Not enough stock'),
                                ),
                              );
                              return;
                            }
                            notifier.increment(
                              line.productId,
                              maxStock: maxStock,
                            );
                          },
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Increase',
                  ),
                  IconButton(
                    onPressed: !enabled
                        ? null
                        : () => notifier.remove(line.productId),
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
