import 'package:flutter/material.dart';

@immutable
class AppAccents extends ThemeExtension<AppAccents> {
  const AppAccents({
    required this.cyan,
    required this.onCyan,
    required this.indigo,
    required this.onIndigo,
  });

  /// Secondary accent (teal/cyan family), derived from brand seed.
  final Color cyan;
  final Color onCyan;

  /// Tertiary accent (purple/indigo family), derived from brand seed.
  final Color indigo;
  final Color onIndigo;

  @override
  AppAccents copyWith({
    Color? cyan,
    Color? onCyan,
    Color? indigo,
    Color? onIndigo,
  }) {
    return AppAccents(
      cyan: cyan ?? this.cyan,
      onCyan: onCyan ?? this.onCyan,
      indigo: indigo ?? this.indigo,
      onIndigo: onIndigo ?? this.onIndigo,
    );
  }

  @override
  AppAccents lerp(ThemeExtension<AppAccents>? other, double t) {
    if (other is! AppAccents) return this;

    return AppAccents(
      cyan: Color.lerp(cyan, other.cyan, t)!,
      onCyan: Color.lerp(onCyan, other.onCyan, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      onIndigo: Color.lerp(onIndigo, other.onIndigo, t)!,
    );
  }
}

extension AppAccentsX on BuildContext {
  AppAccents get accents {
    final accents = Theme.of(this).extension<AppAccents>();
    assert(accents != null, 'AppAccents not found in ThemeData.extensions');
    return accents!;
  }
}
