class Money {
  static String format(int cents) {
    final value = cents / 100.0;
    return '₱${value.toStringAsFixed(2)}';
  }

  /// Accepts inputs like "12", "12.5", "12.50".
  static int? tryParseToCents(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return null;

    final normalized = raw.replaceAll(',', '');
    final value = double.tryParse(normalized);
    if (value == null) return null;

    final cents = (value * 100).round();
    if (cents < 0) return null;
    return cents;
  }
}
