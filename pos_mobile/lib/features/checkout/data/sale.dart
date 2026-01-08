enum PaymentType {
  cash,
  credit,
}

extension PaymentTypeDb on PaymentType {
  String get dbValue => switch (this) {
        PaymentType.cash => 'cash',
        PaymentType.credit => 'credit',
      };

  static PaymentType fromDb(String value) {
    return switch (value) {
      'cash' => PaymentType.cash,
      'credit' => PaymentType.credit,
      _ => throw ArgumentError('Unknown payment_type: $value'),
    };
  }
}
