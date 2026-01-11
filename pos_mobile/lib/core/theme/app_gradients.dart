import 'package:flutter/material.dart';

import 'app_accent_colors.dart';
import 'app_semantic_colors.dart';

class AppGradients {
  static LinearGradient dashboardHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = context.accentColors;

    // Subtle, premium: mostly container tones with a hint of indigo.
    final c1 = Color.lerp(scheme.primaryContainer, scheme.primary, 0.18)!;
    final c2 = Color.lerp(scheme.primaryContainer, a.indigo, 0.22)!;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c1, c2],
    );
  }

  static LinearGradient checkoutTotal(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = context.accentColors;

    final c1 = Color.lerp(scheme.primaryContainer, scheme.primary, 0.20)!;
    final c2 = Color.lerp(scheme.primaryContainer, a.cyan, 0.18)!;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c1, c2],
    );
  }

  static LinearGradient paymentCash(BuildContext context) {
    final sem = context.sem;
    final a = context.accentColors;

    final c1 = Color.lerp(sem.success, a.cyan, 0.18)!;
    final c2 = Color.lerp(sem.success, sem.onSuccess, 0.10)!;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c1, c2],
    );
  }

  static LinearGradient paymentCredit(BuildContext context) {
    final sem = context.sem;

    // Keep this in the amber family for semantic clarity.
    final c1 = Color.lerp(sem.warning, sem.warningContainer, 0.12)!;
    final c2 = Color.lerp(sem.warning, sem.onWarning, 0.10)!;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c1, c2],
    );
  }
}
