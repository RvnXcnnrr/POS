import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/customers_notifier.dart';
import '../data/customer.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});

  final int? customerId;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _saving = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.customerId;

    return Scaffold(
      appBar: AppBar(title: Text(id == null ? 'Add Customer' : 'Edit Customer')),
      body: SafeArea(
        child: id == null
            ? _buildForm(context, null)
            : ref.watch(customerByIdProvider(id)).when(
                  data: (c) {
                    if (c == null) return const Center(child: Text('Customer not found'));
                    if (!_hydrated && !_saving) {
                      _nameCtrl.text = c.name;
                      _phoneCtrl.text = c.phone ?? '';
                      _hydrated = true;
                    }
                    return _buildForm(context, c);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, Customer? existing) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Customer name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = _formKey.currentState?.validate() ?? false;
                        if (!ok) return;
                        setState(() => _saving = true);
                        try {
                          final draft = CustomerDraft(
                            name: _nameCtrl.text.trim(),
                            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
                          );
                          final notifier = ref.read(customersNotifierProvider.notifier);
                          if (existing == null) {
                            await notifier.create(draft);
                          } else {
                            await notifier.update(existing.id, draft);
                          }
                          if (!mounted) return;
                          navigator.pop();
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: SizedBox(
                  height: 48,
                  child: Center(child: Text(existing == null ? 'Add Customer' : 'Save Changes')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
