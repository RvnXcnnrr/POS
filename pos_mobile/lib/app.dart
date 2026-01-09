import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/settings/data/app_settings_repository.dart';

class PosApp extends ConsumerWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    final brandColorValueAsync = ref.watch(brandColorValueProvider);
    final brandColorValue = brandColorValueAsync.maybeWhen(
      data: (v) => v,
      orElse: () => AppSettingsRepository.defaultBrandColorValue,
    );
    final brandColor = Color(brandColorValue);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: themeMode,
      theme: AppTheme.light(brandColor: brandColor),
      darkTheme: AppTheme.dark(brandColor: brandColor),
    );
  }
}
