class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.balanceCents,
    required this.createdAtMs,
  });

  final int id;
  final String name;
  final String? phone;
  final int balanceCents;
  final int createdAtMs;

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      balanceCents: map['balance_cents'] as int,
      createdAtMs: map['created_at'] as int,
    );
  }
}

class CustomerDraft {
  const CustomerDraft({
    required this.name,
    required this.phone,
  });

  final String name;
  final String? phone;

  Map<String, Object?> toInsertMap() {
    return {
      'name': name,
      'phone': phone,
      'balance_cents': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, Object?> toUpdateMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}
