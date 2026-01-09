class Payment {
  const Payment({
    required this.id,
    required this.customerId,
    required this.amountCents,
    required this.method,
    required this.note,
    required this.createdAtMs,
  });

  final int id;
  final int customerId;
  final int amountCents;
  final String method;
  final String? note;
  final int createdAtMs;

  factory Payment.fromMap(Map<String, Object?> map) {
    return Payment(
      id: map['id'] as int,
      customerId: map['customer_id'] as int,
      amountCents: map['amount_cents'] as int,
      method: (map['method'] as String?) ?? 'cash',
      note: map['note'] as String?,
      createdAtMs: map['created_at'] as int,
    );
  }
}
