import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/customer.dart';
import '../data/customers_repository.dart';
import '../data/payment.dart';

final customersNotifierProvider =
    StateNotifierProvider<CustomersNotifier, AsyncValue<List<Customer>>>((ref) {
  return CustomersNotifier(ref.watch(customersRepositoryProvider))..load();
});

final customerByIdProvider = FutureProvider.family<Customer?, int>((ref, id) {
  return ref.watch(customersRepositoryProvider).getById(id);
});

final paymentsByCustomerProvider = FutureProvider.family<List<Payment>, int>((ref, customerId) {
  return ref.watch(customersRepositoryProvider).listPaymentsForCustomer(customerId);
});

class CustomersNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  CustomersNotifier(this._repo) : super(const AsyncValue.loading());

  final CustomersRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.listAllByHighestBalance());
  }

  Future<void> create(CustomerDraft draft) async {
    await _repo.create(draft);
    await load();
  }

  Future<void> update(int id, CustomerDraft draft) async {
    await _repo.update(id, draft);
    await load();
  }
}
