import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/providers.dart';
import '../../../core/security/pin_auth.dart';
import '../../customers/application/customers_notifier.dart';
import '../../dashboard/application/dashboard_notifier.dart';
import '../../products/application/products_notifier.dart';
import '../../reports/application/reports_notifier.dart';
import '../data/app_settings_repository.dart';
import '../../../core/theme/app_semantic_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showPinManager(BuildContext context, WidgetRef ref) async {
    final existingPin = await ref.read(pinCodeProvider.future);

    if (!context.mounted) return;

    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    Future<void> cleanup() async {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    }

    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('App PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (existingPin != null) ...[
                    TextField(
                      controller: currentCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Current PIN',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: newCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'New PIN (leave empty to remove)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Confirm new PIN',
                      border: const OutlineInputBorder(),
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final current = currentCtrl.text.trim();
                    final next = newCtrl.text.trim();
                    final confirm = confirmCtrl.text.trim();

                    if (existingPin != null && current != existingPin) {
                      setState(() => error = 'Incorrect current PIN');
                      return;
                    }

                    if (next.isEmpty) {
                      // Remove PIN
                      Navigator.pop(context, '');
                      return;
                    }

                    if (next.length < 4) {
                      setState(() => error = 'PIN must be at least 4 digits');
                      return;
                    }
                    if (next != confirm) {
                      setState(() => error = 'PINs do not match');
                      return;
                    }

                    Navigator.pop(context, next);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      if (result == null) return;
      final repo = ref.read(appSettingsRepositoryProvider);
      if (result.isEmpty) {
        await repo.setPinCode(null);
        ref.read(pinUnlockedProvider.notifier).state = false;
      } else {
        await repo.setPinCode(result);
        ref.read(pinUnlockedProvider.notifier).state = true;
      }
      ref.invalidate(pinCodeProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.isEmpty ? 'PIN removed' : 'PIN updated'),
          ),
        );
      }
    } finally {
      await cleanup();
    }
  }

  Future<void> _exportDb(BuildContext context, WidgetRef ref) async {
    final ok = await PinAuth.requirePin(context, ref, reason: 'Export Backup');
    if (!ok) return;

    final filename = 'pos_backup_${DateTime.now().millisecondsSinceEpoch}.db';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export database backup',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: const ['db'],
    );
    if (path == null) return;

    try {
      await ref.read(appDatabaseProvider).exportTo(path);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Backup exported')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _restoreDb(BuildContext context, WidgetRef ref) async {
    final ok = await PinAuth.requirePin(context, ref, reason: 'Restore Backup');
    if (!ok) return;

    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select database backup to restore',
      type: FileType.custom,
      allowedExtensions: const ['db'],
      withData: false,
    );
    final filePath = picked?.files.single.path;
    if (filePath == null) return;

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text('This will replace all local data on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(appDatabaseProvider).restoreFrom(filePath);

      // Refresh app state from restored DB.
      await ref.read(productsNotifierProvider.notifier).load();
      await ref.read(customersNotifierProvider.notifier).load();
      ref.invalidate(reportsNotifierProvider);
      ref.invalidate(dashboardNotifierProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Backup restored')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sem = context.sem;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(
              title: 'Security',
              background: sem.infoContainer,
              foreground: sem.onInfoContainer,
              icon: Icons.security_rounded,
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('App PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPinManager(context, ref),
            ),

            const SizedBox(height: 16),
            _SectionHeader(
              title: 'Backup',
              background: sem.surfaceHighest,
              foreground: Theme.of(context).colorScheme.onSurface,
              icon: Icons.cloud_upload_rounded,
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Export backup'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exportDb(context, ref),
            ),
            ListTile(
              leading: Icon(Icons.restore_outlined, color: sem.danger),
              title: const Text('Restore backup'),
              trailing: const Icon(Icons.chevron_right),
              textColor: Theme.of(context).colorScheme.onSurface,
              onTap: () => _restoreDb(context, ref),
            ),

            const SizedBox(height: 16),
            _SectionHeader(
              title: 'Data',
              background: sem.surfaceHighest,
              foreground: Theme.of(context).colorScheme.onSurface,
              icon: Icons.storage_rounded,
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Products'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/products'),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Customers (Utang)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/customers'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String title;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.sem.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
