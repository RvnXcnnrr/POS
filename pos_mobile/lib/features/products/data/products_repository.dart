import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/providers.dart';
import '../../../core/db/app_database.dart';
import 'product.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(appDatabaseProvider));
});

class ProductsRepository {
  ProductsRepository(this._db);

  final AppDatabase _db;

  Future<List<Product>> listAll() async {
    final db = await _db.db;
    final rows = await db.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<int> inventoryValueCents() async {
    final db = await _db.db;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(stock * cost_cents), 0) AS t FROM products WHERE is_active = 1',
    );
    return (rows.first['t'] as int?) ?? 0;
  }

  Future<Product?> getById(int id) async {
    final db = await _db.db;
    final rows = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<int> create(ProductDraft draft) async {
    final db = await _db.db;
    return db.insert('products', draft.toInsertMap());
  }

  Future<void> update(int id, ProductDraft draft) async {
    final db = await _db.db;
    await db.update(
      'products',
      draft.toUpdateMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> canDelete(int productId) async {
    final db = await _db.db;
    final rows = await db.rawQuery(
      'SELECT COUNT(1) AS c FROM sale_items WHERE product_id = ?',
      [productId],
    );
    final count = (rows.first['c'] as int?) ?? 0;
    return count == 0;
  }

  /// Soft delete: mark inactive to preserve historical sales.
  Future<void> delete(int id) async {
    final db = await _db.db;
    await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String?> copyProductImageToInternalDir({
    required String sourcePath,
    int? productId,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docsDir.path, 'images', 'products'));
    await imagesDir.create(recursive: true);

    final ext = p.extension(sourcePath);
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final filename =
        'product_${productId ?? 'new'}_${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final destPath = p.join(imagesDir.path, filename);

    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<void> deleteImageIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> updateStock(
    DatabaseExecutor txn,
    int productId,
    int newStock,
  ) async {
    await txn.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }
}
