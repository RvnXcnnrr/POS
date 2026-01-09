import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';

class AppTheme {
  static const _brandPrimary = Color(0xFF005F5C); // deep teal/emerald
  static const _brandSecondary = Color(0xFF00B8C4); // electric mint/cyan
  static const _brandTertiary = Color(0xFFFFB100); // amber (warnings)

  static const _bg = Color(0xFFF5FAF9); // near-white w/ subtle tint
  static const _surface = Color(0xFFFBFDFC);
  static const _surfaceHigh = Color(0xFFF0F6F5);
  static const _surfaceHighest = Color(0xFFE7EFEE);

  static const _onSurface = Color(0xFF0B1F1E);
  static const _onSurfaceMuted = Color(0xFF3A5150);

  static const _danger = Color(0xFFB42318);
  static const _onDanger = Color(0xFFFFFFFF);
  static const _dangerContainer = Color(0xFFFFE4E2);
  static const _onDangerContainer = Color(0xFF5A0B08);

  static const _success = Color(0xFF067647);
  static const _onSuccess = Color(0xFFFFFFFF);
  static const _successContainer = Color(0xFFD2F9E5);
  static const _onSuccessContainer = Color(0xFF04452A);

  static const _warning = Color(0xFFE07A00);
  static const _onWarning = Color(0xFF1F1300);
  static const _warningContainer = Color(0xFFFFE9C7);
  static const _onWarningContainer = Color(0xFF4A2C00);

  static const _info = Color(0xFF0B7EA2);
  static const _onInfo = Color(0xFFFFFFFF);
  static const _infoContainer = Color(0xFFD2F2FF);
  static const _onInfoContainer = Color(0xFF084155);

  static const _disabled = Color(0xFF9AA8A7);
  static const _onDisabled = Color(0xFF1C2B2A);

  static const _border = Color(0xFFCED8D7);

  static const double _cardElevation = 2.5;
  static const BorderRadius _radiusLg = BorderRadius.all(Radius.circular(18));
  static const BorderRadius _radiusMd = BorderRadius.all(Radius.circular(16));
  static const BorderRadius _radiusSm = BorderRadius.all(Radius.circular(14));

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _brandPrimary,
          brightness: Brightness.light,
        ).copyWith(
          primary: _brandPrimary,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFBFEDEA),
          onPrimaryContainer: _onSurface,
          secondary: _brandSecondary,
          onSecondary: _onSurface,
          secondaryContainer: const Color(0xFFCFF7FA),
          onSecondaryContainer: _onSurface,
          tertiary: _brandTertiary,
          onTertiary: _onSurface,
          tertiaryContainer: _warningContainer,
          onTertiaryContainer: _onWarningContainer,
          error: _danger,
          onError: _onDanger,
          errorContainer: _dangerContainer,
          onErrorContainer: _onDangerContainer,
          surface: _surface,
          onSurface: _onSurface,
          onSurfaceVariant: _onSurfaceMuted,
          outline: _border,
          surfaceTint: _brandPrimary,
        );

    final sem = const AppSemanticColors(
      success: _success,
      onSuccess: _onSuccess,
      successContainer: _successContainer,
      onSuccessContainer: _onSuccessContainer,
      warning: _warning,
      onWarning: _onWarning,
      warningContainer: _warningContainer,
      onWarningContainer: _onWarningContainer,
      danger: _danger,
      onDanger: _onDanger,
      dangerContainer: _dangerContainer,
      onDangerContainer: _onDangerContainer,
      info: _info,
      onInfo: _onInfo,
      infoContainer: _infoContainer,
      onInfoContainer: _onInfoContainer,
      disabled: _disabled,
      onDisabled: _onDisabled,
      surfaceLow: _surface,
      surfaceHigh: _surfaceHigh,
      surfaceHighest: _surfaceHighest,
      border: _border,
    );

    WidgetStateProperty<Color?> buttonBg(Color color, Color disabledColor) {
      return WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabledColor;
        return color;
      });
    }

    WidgetStateProperty<Color?> buttonFg(Color color, Color disabledColor) {
      return WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabledColor;
        return color;
      });
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: _bg,
      extensions: [sem],
      dividerColor: sem.border,
      appBarTheme: AppBarTheme(
        backgroundColor: _bg,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: sem.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: _cardElevation,
        shape: const RoundedRectangleBorder(borderRadius: _radiusLg),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurface,
        textColor: scheme.onSurface,
        shape: const RoundedRectangleBorder(borderRadius: _radiusMd),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: sem.surfaceHigh,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const RoundedRectangleBorder(borderRadius: _radiusMd),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: _radiusMd),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: buttonBg(scheme.primary, sem.disabled),
          foregroundColor: buttonFg(scheme.onPrimary, sem.onDisabled),
          overlayColor: WidgetStatePropertyAll(
            scheme.onPrimary.withValues(alpha: 0.08),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: _radiusMd),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: sem.border.withValues(alpha: 0.45));
            }
            return BorderSide(color: sem.border);
          }),
          foregroundColor: buttonFg(scheme.primary, sem.onDisabled),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: _radiusSm),
          ),
          foregroundColor: buttonFg(scheme.primary, sem.onDisabled),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sem.surfaceHigh,
        border: const OutlineInputBorder(borderRadius: _radiusMd),
        enabledBorder: OutlineInputBorder(
          borderRadius: _radiusMd,
          borderSide: BorderSide(color: sem.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _radiusMd,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _radiusMd,
          borderSide: BorderSide(color: sem.danger, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _radiusMd,
          borderSide: BorderSide(color: sem.danger, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: const RoundedRectangleBorder(borderRadius: _radiusMd),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: sem.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: _radiusLg),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        contentTextStyle: TextStyle(color: scheme.onSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: sem.surfaceHighest,
        circularTrackColor: sem.surfaceHighest,
      ),
    );
  }
}
