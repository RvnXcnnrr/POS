import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/providers.dart';
import '../../../core/security/pin_auth.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/theme/app_accent_colors.dart';
import '../../../core/theme/accent_tints.dart';
import '../../customers/application/customers_notifier.dart';
import '../../dashboard/application/dashboard_notifier.dart';
import '../../products/application/products_notifier.dart';
import '../../reports/application/reports_notifier.dart';
import '../data/app_settings_repository.dart';
import '../../../core/theme/app_semantic_colors.dart';

enum _SettingsItem { pin, exportDb, restoreDb, products, customers }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _SettingsItem? _selected;

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
    String? destinationPath;

    if (Platform.isAndroid) {
      // Android SAF may return content:// URIs for saveFile which aren't
      // writable via dart:io. Directory selection is more reliable.
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder for backup',
      );
      if (dir == null) return;
      destinationPath = p.join(dir, filename);
    } else {
      destinationPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export database backup',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: const ['db'],
      );
      if (destinationPath == null) return;
    }

    try {
      await ref.read(appDatabaseProvider).exportTo(destinationPath);
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
      withReadStream: true,
    );

    final file = picked?.files.single;
    if (file == null) return;

    String? filePath = file.path;
    String? tempPath;

    if (filePath == null) {
      final stream = file.readStream;
      if (stream == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read selected backup file')),
        );
        return;
      }

      final tmpDir = await getTemporaryDirectory();
      tempPath = p.join(
        tmpDir.path,
        'pos_restore_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      final out = File(tempPath).openWrite();
      await stream.pipe(out);
      await out.flush();
      await out.close();
      filePath = tempPath;
    }

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

      // PIN may change after restore; clear any in-memory session.
      ref.read(pinUnlockedProvider.notifier).state = false;
      ref.invalidate(pinCodeProvider);

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

    if (tempPath != null) {
      try {
        await File(tempPath).delete();
      } catch (_) {
        // Ignore cleanup failures.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sem = context.sem;
    final scheme = Theme.of(context).colorScheme;

    Future<void> handleTap(_SettingsItem item) async {
      setState(() => _selected = item);
      switch (item) {
        case _SettingsItem.pin:
          await _showPinManager(context, ref);
          break;
        case _SettingsItem.exportDb:
          await _exportDb(context, ref);
          break;
        case _SettingsItem.restoreDb:
          await _restoreDb(context, ref);
          break;
        case _SettingsItem.products:
          context.go('/settings/products');
          break;
        case _SettingsItem.customers:
          context.go('/settings/customers');
          break;
      }
    }

    Widget masterList({required bool isExpanded}) {
      final padding = context.pagePadding;
      final listPadding = isExpanded
          ? EdgeInsets.zero
          : padding;

      final headerBg = accentTintedSurface(
        context: context,
        surface: scheme.surfaceContainerHigh,
        accent: context.accentColors.indigo,
      );
      final headerFg = scheme.onSurface;

      return ListView(
        padding: listPadding,
        children: [
          _SectionHeader(
            title: 'Security',
            background: headerBg,
            foreground: headerFg,
            icon: Icons.security_rounded,
          ),
          ListTile(
            selected: isExpanded && _selected == _SettingsItem.pin,
            leading: const Icon(Icons.lock_outline),
            title: const Text('App PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => handleTap(_SettingsItem.pin),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Backup',
            background: headerBg,
            foreground: headerFg,
            icon: Icons.cloud_upload_rounded,
          ),
          ListTile(
            selected: isExpanded && _selected == _SettingsItem.exportDb,
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Export backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => handleTap(_SettingsItem.exportDb),
          ),
          ListTile(
            selected: isExpanded && _selected == _SettingsItem.restoreDb,
            leading: Icon(Icons.restore_outlined, color: sem.danger),
            title: const Text('Restore backup'),
            trailing: const Icon(Icons.chevron_right),
            textColor: Theme.of(context).colorScheme.onSurface,
            onTap: () => handleTap(_SettingsItem.restoreDb),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Data',
            background: headerBg,
            foreground: headerFg,
            icon: Icons.storage_rounded,
          ),
          ListTile(
            selected: isExpanded && _selected == _SettingsItem.products,
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Products'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => handleTap(_SettingsItem.products),
          ),
          ListTile(
            selected: isExpanded && _selected == _SettingsItem.customers,
            leading: const Icon(Icons.people_outline),
            title: const Text('Customers (Utang)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => handleTap(_SettingsItem.customers),
          ),
        ],
      );
    }

    Widget detailPanel() {
      final item = _selected;

      String title;
      String description;
      String actionLabel;
      VoidCallback? action;
      ButtonStyle? style;

      switch (item) {
        case _SettingsItem.pin:
          title = 'App PIN';
          description =
              'Protect Settings access with a PIN. Use this on shared devices.';
          actionLabel = 'Manage PIN';
          action = () => _showPinManager(context, ref);
        case _SettingsItem.exportDb:
          title = 'Export backup';
          description =
              'Save a local database backup file that can be restored later.';
          actionLabel = 'Export backup';
          action = () => _exportDb(context, ref);
        case _SettingsItem.restoreDb:
          title = 'Restore backup';
          description =
              'Restore from a backup file. This will replace all local data.';
          actionLabel = 'Restore backup';
          style = FilledButton.styleFrom(
            backgroundColor: sem.danger,
            foregroundColor: sem.onDanger,
          );
          action = () => _restoreDb(context, ref);
        case _SettingsItem.products:
          title = 'Products';
          description = 'Manage product catalog and inventory.';
          actionLabel = 'Open Products';
          action = () => context.go('/settings/products');
        case _SettingsItem.customers:
          title = 'Customers (Utang)';
          description = 'Manage credit customers and balances.';
          actionLabel = 'Open Customers';
          action = () => context.go('/settings/customers');
        case null:
          title = 'Settings';
          description = 'Select an item on the left to view details.';
          actionLabel = '';
          action = null;
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(description),
              const Spacer(),
              if (action != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: style,
                      onPressed: action,
                      child: Text(actionLabel),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bp = breakpointForWidth(constraints.maxWidth);
          if (bp != ScreenBreakpoint.expanded) {
            return masterList(isExpanded: false);
          }

          final padding = context.pagePadding;
          return Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: masterList(isExpanded: true)),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: detailPanel()),
              ],
            ),
          );
        },
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
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
