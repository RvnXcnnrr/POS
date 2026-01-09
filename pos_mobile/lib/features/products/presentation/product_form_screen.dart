import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/money.dart';
import '../application/products_notifier.dart';
import '../data/product.dart';
import '../data/products_repository.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final int? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');

  String? _existingImagePath;
  String? _pickedImagePath;
  bool _saving = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _pickedImagePath = file.path;
    });
  }

  void _hydrate(Product p) {
    _nameCtrl.text = p.name;
    _priceCtrl.text = (p.priceCents / 100).toStringAsFixed(2);
    _stockCtrl.text = p.stock.toString();
    _existingImagePath = p.imagePath;
    _hydrated = true;
  }

  @override
  Widget build(BuildContext context) {
    final productId = widget.productId;

    return Scaffold(
      appBar: AppBar(
        title: Text(productId == null ? 'Add Product' : 'Edit Product'),
      ),
      body: SafeArea(
        child: productId == null
            ? _buildForm(context, null)
            : ref
                  .watch(productByIdProvider(productId))
                  .when(
                    data: (p) {
                      if (p == null) {
                        return const Center(child: Text('Product not found'));
                      }
                      if (!_hydrated && !_saving) {
                        _hydrate(p);
                      }
                      return _buildForm(context, p);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, Product? existing) {
    final repo = ref.read(productsRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Product name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '₱',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final cents = Money.tryParseToCents(v ?? '');
                  if (cents == null) return 'Enter a valid amount';
                  if (cents <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final value = int.tryParse((v ?? '').trim());
                  if (value == null) return 'Enter a number';
                  if (value < 0) return 'Cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Image (optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _ImagePreview(path: _pickedImagePath ?? _existingImagePath),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
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

                        final priceCents = Money.tryParseToCents(
                          _priceCtrl.text,
                        )!;
                        final stock = int.parse(_stockCtrl.text.trim());
                        final name = _nameCtrl.text.trim();

                        setState(() => _saving = true);
                        try {
                          String? imagePath = _existingImagePath;
                          if (_pickedImagePath != null) {
                            final copied = await repo
                                .copyProductImageToInternalDir(
                                  sourcePath: _pickedImagePath!,
                                  productId: widget.productId,
                                );
                            imagePath = copied;
                            if (_existingImagePath != null &&
                                _existingImagePath != copied) {
                              await repo.deleteImageIfExists(
                                _existingImagePath,
                              );
                            }
                          }

                          final draft = ProductDraft(
                            name: name,
                            priceCents: priceCents,
                            stock: stock,
                            imagePath: imagePath,
                          );

                          final notifier = ref.read(
                            productsNotifierProvider.notifier,
                          );
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
                  child: Center(
                    child: Text(
                      existing == null ? 'Add Product' : 'Save Changes',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final p = path;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: (p == null || p.isEmpty)
          ? Icon(Icons.image_outlined, size: 48, color: scheme.onSurfaceVariant)
          : Image.file(
              File(p),
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: scheme.onSurfaceVariant,
              ),
            ),
    );
  }
}
