class Product {
  const Product({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.costCents,
    required this.stock,
    required this.imagePath,
    required this.createdAtMs,
  });

  final int id;
  final String name;
  final int priceCents;
  final int costCents;
  final int stock;
  final String? imagePath;
  final int createdAtMs;

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      priceCents: map['price_cents'] as int,
      costCents: (map['cost_cents'] as int?) ?? 0,
      stock: map['stock'] as int,
      imagePath: map['image_path'] as String?,
      createdAtMs: map['created_at'] as int,
    );
  }
}

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.priceCents,
    required this.costCents,
    required this.stock,
    required this.imagePath,
  });

  final String name;
  final int priceCents;
  final int costCents;
  final int stock;
  final String? imagePath;

  Map<String, Object?> toInsertMap() {
    return {
      'name': name,
      'price_cents': priceCents,
      'cost_cents': costCents,
      'stock': stock,
      'image_path': imagePath,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, Object?> toUpdateMap() {
    return {
      'name': name,
      'price_cents': priceCents,
      'cost_cents': costCents,
      'stock': stock,
      'image_path': imagePath,
    };
  }
}
