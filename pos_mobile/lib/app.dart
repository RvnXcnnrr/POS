import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

class PosApp extends ConsumerWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ).copyWith(
      // App semantics:
      // - Cash / Paid: primary (green)
      // - Credit (Utang): tertiary (amber/orange)
      // - Debt / Warnings: error (red)
      primary: Colors.green,
      tertiary: Colors.orange,
      error: Colors.red,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: colorScheme,
      ),
    );
  }
}
