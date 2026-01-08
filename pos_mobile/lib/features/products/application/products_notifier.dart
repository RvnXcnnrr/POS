import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/product.dart';
import '../data/products_repository.dart';

final productsNotifierProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductsNotifier(ref.watch(productsRepositoryProvider))..load();
});

final productByIdProvider = FutureProvider.family<Product?, int>((ref, id) {
  return ref.watch(productsRepositoryProvider).getById(id);
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  ProductsNotifier(this._repo) : super(const AsyncValue.loading());

  final ProductsRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.listAll());
  }

  Future<void> create(ProductDraft draft) async {
    await _repo.create(draft);
    await load();
  }

  Future<void> update(int id, ProductDraft draft) async {
    await _repo.update(id, draft);
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }
}
