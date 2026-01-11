import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';
import 'app_accent_colors.dart';

class AppTheme {
  static const int defaultBrandColorValue = 0xFF005F5C;

  static const _bgLight = Color(0xFFF5FAF9); // near-white w/ subtle tint
  static const _bgDark = Color(0xFF0B0F10); // near-black (true dark)

  // Light surface/text
  static const _surfaceLight = Color(0xFFFBFDFC);
  static const _onSurfaceLight = Color(0xFF0B1F1E);
  static const _onSurfaceMutedLight = Color(0xFF3A5150);

  // Dark surface/text
  static const _surfaceDark = Color(0xFF0E1415);
  static const _surfaceContainerLowDark = Color(0xFF101819);
  static const _surfaceContainerDark = Color(0xFF121C1D);
  static const _surfaceContainerHighDark = Color(0xFF162022);
  static const _surfaceContainerHighestDark = Color(0xFF1A2628);
  static const _onSurfaceDark = Color(0xFFF1F7F6);
  static const _onSurfaceMutedDark = Color(0xFFB9C7C6);
  static const _outlineDark = Color(0xFF2C3A3C);
  static const _outlineVariantDark = Color(0xFF223031);

  // Light semantic
  static const _dangerLight = Color(0xFFB42318);
  static const _onDangerLight = Color(0xFFFFFFFF);
  static const _dangerContainerLight = Color(0xFFFFE4E2);
  static const _onDangerContainerLight = Color(0xFF5A0B08);

  static const _successLight = Color(0xFF067647);
  static const _onSuccessLight = Color(0xFFFFFFFF);
  static const _successContainerLight = Color(0xFFD2F9E5);
  static const _onSuccessContainerLight = Color(0xFF04452A);

  static const _warningLight = Color(0xFFE07A00);
  static const _onWarningLight = Color(0xFF1F1300);
  static const _warningContainerLight = Color(0xFFFFE9C7);
  static const _onWarningContainerLight = Color(0xFF4A2C00);

  static const _infoLight = Color(0xFF0B7EA2);
  static const _onInfoLight = Color(0xFFFFFFFF);
  static const _infoContainerLight = Color(0xFFD2F2FF);
  static const _onInfoContainerLight = Color(0xFF084155);

  static const _disabledLight = Color(0xFF9AA8A7);
  static const _onDisabledLight = Color(0xFF1C2B2A);

  // Dark semantic (tuned for low-light comfort)
  static const _dangerDark = Color(0xFFFF6B5E);
  static const _onDangerDark = Color(0xFF1B0907);
  static const _dangerContainerDark = Color(0xFF3A1210);
  static const _onDangerContainerDark = Color(0xFFFFDAD6);

  static const _successDark = Color(0xFF22C55E);
  static const _onSuccessDark = Color(0xFF071A0E);
  static const _successContainerDark = Color(0xFF0F271A);
  static const _onSuccessContainerDark = Color(0xFFBFF0D1);

  static const _warningDark = Color(0xFFFFB020);
  static const _onWarningDark = Color(0xFF1B1204);
  static const _warningContainerDark = Color(0xFF2C1E08);
  static const _onWarningContainerDark = Color(0xFFFFE6C2);

  static const _infoDark = Color(0xFF4FD1FF);
  static const _onInfoDark = Color(0xFF04151B);
  static const _infoContainerDark = Color(0xFF082733);
  static const _onInfoContainerDark = Color(0xFFC6F0FF);

  static const _disabledDark = Color(0xFF465354);
  static const _onDisabledDark = Color(0xFF101718);

  static const double _cardElevation = 2.5;
  static const BorderRadius _radiusLg = BorderRadius.all(Radius.circular(18));
  static const BorderRadius _radiusMd = BorderRadius.all(Radius.circular(16));
  static const BorderRadius _radiusSm = BorderRadius.all(Radius.circular(14));

  static ThemeData light({required Color brandColor}) {
    return _build(brandColor: brandColor, brightness: Brightness.light);
  }

  static ThemeData dark({required Color brandColor}) {
    return _build(brandColor: brandColor, brightness: Brightness.dark);
  }

  static Color _onBrand(Color brandColor) {
    final b = ThemeData.estimateBrightnessForColor(brandColor);
    // Avoid Colors.* in widgets; keep hard values local to theme.
    return b == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
  }

  static ThemeData _build({
    required Color brandColor,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final onBrand = _onBrand(brandColor);

    final accents = _buildAccents(brandColor: brandColor, brightness: brightness);

    final base = ColorScheme.fromSeed(
      seedColor: brandColor,
      brightness: brightness,
    );

    final scheme = isDark
        ? base.copyWith(
            primary: brandColor,
            onPrimary: onBrand,
            secondary: accents.cyan,
            onSecondary: accents.onCyan,
            tertiary: accents.indigo,
            onTertiary: accents.onIndigo,
            error: _dangerDark,
            onError: _onDangerDark,
            errorContainer: _dangerContainerDark,
            onErrorContainer: _onDangerContainerDark,
            surface: _surfaceDark,
            onSurface: _onSurfaceDark,
            onSurfaceVariant: _onSurfaceMutedDark,
            outline: _outlineDark,
            outlineVariant: _outlineVariantDark,
            surfaceContainerLow: _surfaceContainerLowDark,
            surfaceContainer: _surfaceContainerDark,
            surfaceContainerHigh: _surfaceContainerHighDark,
            surfaceContainerHighest: _surfaceContainerHighestDark,
            surfaceTint: brandColor,
          )
        : base.copyWith(
            primary: brandColor,
            onPrimary: onBrand,
            secondary: accents.cyan,
            onSecondary: accents.onCyan,
            tertiary: accents.indigo,
            onTertiary: accents.onIndigo,
            error: _dangerLight,
            onError: _onDangerLight,
            errorContainer: _dangerContainerLight,
            onErrorContainer: _onDangerContainerLight,
            surface: _surfaceLight,
            onSurface: _onSurfaceLight,
            onSurfaceVariant: _onSurfaceMutedLight,
            surfaceTint: brandColor,
          );

    final sem = isDark
        ? const AppSemanticColors(
            success: _successDark,
            onSuccess: _onSuccessDark,
            successContainer: _successContainerDark,
            onSuccessContainer: _onSuccessContainerDark,
            warning: _warningDark,
            onWarning: _onWarningDark,
            warningContainer: _warningContainerDark,
            onWarningContainer: _onWarningContainerDark,
            danger: _dangerDark,
            onDanger: _onDangerDark,
            dangerContainer: _dangerContainerDark,
            onDangerContainer: _onDangerContainerDark,
            info: _infoDark,
            onInfo: _onInfoDark,
            infoContainer: _infoContainerDark,
            onInfoContainer: _onInfoContainerDark,
            disabled: _disabledDark,
            onDisabled: _onDisabledDark,
          )
        : const AppSemanticColors(
            success: _successLight,
            onSuccess: _onSuccessLight,
            successContainer: _successContainerLight,
            onSuccessContainer: _onSuccessContainerLight,
            warning: _warningLight,
            onWarning: _onWarningLight,
            warningContainer: _warningContainerLight,
            onWarningContainer: _onWarningContainerLight,
            danger: _dangerLight,
            onDanger: _onDangerLight,
            dangerContainer: _dangerContainerLight,
            onDangerContainer: _onDangerContainerLight,
            info: _infoLight,
            onInfo: _onInfoLight,
            infoContainer: _infoContainerLight,
            onInfoContainer: _onInfoContainerLight,
            disabled: _disabledLight,
            onDisabled: _onDisabledLight,
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
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? _bgDark : _bgLight,
      extensions: [sem, accents],
      dividerColor: scheme.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? _bgDark : _bgLight,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: const Color(0x00000000),
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
        backgroundColor: scheme.surfaceContainerHigh,
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
              return BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              );
            }
            return BorderSide(color: scheme.outlineVariant);
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
        fillColor: scheme.surfaceContainerHigh,
        border: const OutlineInputBorder(borderRadius: _radiusMd),
        enabledBorder: OutlineInputBorder(
          borderRadius: _radiusMd,
          borderSide: BorderSide(color: scheme.outlineVariant),
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
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: const Color(0x00000000),
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
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }

  static AppAccentColors _buildAccents({
    required Color brandColor,
    required Brightness brightness,
  }) {
    // Derived accents (no hard-coded palette). We rotate hue toward
    // teal/cyan and purple/indigo while keeping the brand's general feel.
    final cyan = _accentFromBrand(
      brandColor: brandColor,
      targetHueDeg: 190,
      brightness: brightness,
    );
    final indigo = _accentFromBrand(
      brandColor: brandColor,
      targetHueDeg: 275,
      brightness: brightness,
    );

    return AppAccentColors(
      cyan: cyan,
      onCyan: _onBrand(cyan),
      indigo: indigo,
      onIndigo: _onBrand(indigo),
    );
  }

  static Color _accentFromBrand({
    required Color brandColor,
    required double targetHueDeg,
    required Brightness brightness,
  }) {
    final hsl = HSLColor.fromColor(brandColor);
    final hue = _lerpAngle(hsl.hue, targetHueDeg, 0.70);

    final saturation = (hsl.saturation * 1.08).clamp(0.0, 1.0);

    // Keep accents vivid enough to feel premium, but ensure they remain
    // readable in both light and dark schemes.
    final baseLightness = hsl.lightness;
    final lightness = (brightness == Brightness.dark
            ? (baseLightness + 0.14)
            : (baseLightness + 0.06))
        .clamp(0.0, 1.0);

    return hsl
        .withHue(hue)
        .withSaturation(saturation)
        .withLightness(lightness)
        .toColor();
  }

  static double _lerpAngle(double a, double b, double t) {
    // Shortest-path interpolation in degrees.
    final delta = ((b - a + 540) % 360) - 180;
    final v = (a + delta * t) % 360;
    return v < 0 ? v + 360 : v;
  }
}
