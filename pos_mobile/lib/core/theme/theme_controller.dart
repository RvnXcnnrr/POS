import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/app_settings_repository.dart';

/// Default is system theme; UI can override later.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Persisted brand color used to generate both light/dark schemes.
final brandColorValueProvider = FutureProvider<int>((ref) async {
  return ref.watch(appSettingsRepositoryProvider).getBrandColorValue();
});
