import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
