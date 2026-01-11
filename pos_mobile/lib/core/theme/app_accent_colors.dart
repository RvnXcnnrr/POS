import 'package:flutter/material.dart';

@immutable
class AppAccentColors extends ThemeExtension<AppAccentColors> {
  const AppAccentColors({
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
  AppAccentColors copyWith({
    Color? cyan,
    Color? onCyan,
    Color? indigo,
    Color? onIndigo,
  }) {
    return AppAccentColors(
      cyan: cyan ?? this.cyan,
      onCyan: onCyan ?? this.onCyan,
      indigo: indigo ?? this.indigo,
      onIndigo: onIndigo ?? this.onIndigo,
    );
  }

  @override
  AppAccentColors lerp(ThemeExtension<AppAccentColors>? other, double t) {
    if (other is! AppAccentColors) return this;

    return AppAccentColors(
      cyan: Color.lerp(cyan, other.cyan, t)!,
      onCyan: Color.lerp(onCyan, other.onCyan, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      onIndigo: Color.lerp(onIndigo, other.onIndigo, t)!,
    );
  }
}

extension AppAccentColorsX on BuildContext {
  AppAccentColors get accentColors {
    final accents = Theme.of(this).extension<AppAccentColors>();
    assert(accents != null, 'AppAccentColors not found in ThemeData.extensions');
    return accents!;
  }
}
