import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customers/data/customer.dart';
import '../../products/data/product.dart';
import '../data/sale.dart';

final cartNotifierProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

class CartLine {
  CartLine({
    required this.productId,
    required this.name,
    required this.unitPriceCents,
    required this.quantity,
  });

  final int productId;
  final String name;
  final int unitPriceCents;
  final int quantity;

  int get lineTotalCents => unitPriceCents * quantity;

  CartLine copyWith({int? quantity}) {
    return CartLine(
      productId: productId,
      name: name,
      unitPriceCents: unitPriceCents,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  const CartState({
    required this.linesByProductId,
    required this.paymentType,
    required this.selectedCustomer,
  });

  final Map<int, CartLine> linesByProductId;
  final PaymentType paymentType;
  final Customer? selectedCustomer;

  static CartState initial() {
    return const CartState(
      linesByProductId: {},
      paymentType: PaymentType.cash,
      selectedCustomer: null,
    );
  }

  List<CartLine> get lines => linesByProductId.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  int get totalCents => linesByProductId.values.fold(0, (sum, l) => sum + l.lineTotalCents);

  CartState copyWith({
    Map<int, CartLine>? linesByProductId,
    PaymentType? paymentType,
    Customer? selectedCustomer,
    bool clearCustomer = false,
  }) {
    return CartState(
      linesByProductId: linesByProductId ?? this.linesByProductId,
      paymentType: paymentType ?? this.paymentType,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState.initial());

  void setPaymentType(PaymentType type) {
    state = state.copyWith(paymentType: type, clearCustomer: type == PaymentType.cash);
  }

  void selectCustomer(Customer customer) {
    state = state.copyWith(selectedCustomer: customer);
  }

  void clearCustomer() {
    state = state.copyWith(clearCustomer: true);
  }

  void addProduct(Product product) {
    final current = Map<int, CartLine>.from(state.linesByProductId);
    final existing = current[product.id];
    if (existing == null) {
      current[product.id] = CartLine(
        productId: product.id,
        name: product.name,
        unitPriceCents: product.priceCents,
        quantity: 1,
      );
    } else {
      current[product.id] = existing.copyWith(quantity: existing.quantity + 1);
    }
    state = state.copyWith(linesByProductId: current);
  }

  void increment(int productId, {required int maxStock}) {
    final current = Map<int, CartLine>.from(state.linesByProductId);
    final existing = current[productId];
    if (existing == null) return;
    if (existing.quantity >= maxStock) return;
    current[productId] = existing.copyWith(quantity: existing.quantity + 1);
    state = state.copyWith(linesByProductId: current);
  }

  void decrement(int productId) {
    final current = Map<int, CartLine>.from(state.linesByProductId);
    final existing = current[productId];
    if (existing == null) return;
    final newQty = existing.quantity - 1;
    if (newQty <= 0) {
      current.remove(productId);
    } else {
      current[productId] = existing.copyWith(quantity: newQty);
    }
    state = state.copyWith(linesByProductId: current);
  }

  void remove(int productId) {
    final current = Map<int, CartLine>.from(state.linesByProductId);
    current.remove(productId);
    state = state.copyWith(linesByProductId: current);
  }

  void clear() {
    state = CartState.initial();
  }
}
