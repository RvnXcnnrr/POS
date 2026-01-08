class Payment {
  const Payment({
    required this.id,
    required this.customerId,
    required this.amountCents,
    required this.createdAtMs,
  });

  final int id;
  final int customerId;
  final int amountCents;
  final int createdAtMs;

  factory Payment.fromMap(Map<String, Object?> map) {
    return Payment(
      id: map['id'] as int,
      customerId: map['customer_id'] as int,
      amountCents: map['amount_cents'] as int,
      createdAtMs: map['created_at'] as int,
    );
  }
}
