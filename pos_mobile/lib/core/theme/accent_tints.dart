import 'package:flutter/material.dart';

/// Accent-tinted surfaces for subtle hierarchy.
///
/// Rules:
/// - Light mode: 0.06–0.08 opacity (default 0.07)
/// - Dark mode:  0.10–0.12 opacity (default 0.11)
///
/// Uses alpha blending (accent over surface) to keep the result in the
/// surface family ("tinted surface"), not a direct accent background.
Color accentTintedSurface({
  required BuildContext context,
  required Color surface,
  required Color accent,
  double lightOpacity = 0.07,
  double darkOpacity = 0.11,
}) {
  final brightness = Theme.of(context).brightness;
  final opacity = (brightness == Brightness.dark ? darkOpacity : lightOpacity)
      .clamp(0.0, 1.0);

  return Color.alphaBlend(accent.withValues(alpha: opacity), surface);
}
