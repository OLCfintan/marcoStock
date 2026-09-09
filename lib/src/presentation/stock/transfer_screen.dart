import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';

import '../../application/stock/stock_providers.dart';
import '../../application/products/product_providers.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  
  String? _selectedProductId;
  String? _fromLocationId;
  String? _toLocationId;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null || _fromLocationId == null || _toLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select product and locations')),
      );
      return;
    }

    if (_fromLocationId == _toLocationId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and destination cannot be the same')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantity = Decimal.parse(_quantityController.text);
      final service = ref.read(stockTransferServiceProvider);
      
      if (service == null) {
        throw Exception('Not authenticated (User not found).');
      }

      await service.executeTransfer(
        _selectedProductId!,
        _fromLocationId!,
        _toLocationId!,
        quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer successful')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfer failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final locationsAsync = ref.watch(stockLocationsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Transfer')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${(AppLocalizations.of(context)?.errorStr ?? 'Error: ')}$e')),
        data: (products) => locationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('${(AppLocalizations.of(context)?.errorStr ?? 'Error: ')}$e')),
          data: (locations) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedProductId,
                      decoration: const InputDecoration(labelText: 'Product'),
                      items: products.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedProductId = val),
                      validator: (val) => val == null ? AppLocalizations.of(context)!.requiredField : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _fromLocationId,
                      decoration: const InputDecoration(labelText: 'Source Location'),
                      items: locations.map((loc) {
                        return DropdownMenuItem(
                          value: loc.id,
                          child: Text(loc.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _fromLocationId = val),
                      validator: (val) => val == null ? AppLocalizations.of(context)!.requiredField : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _toLocationId,
                      decoration: const InputDecoration(labelText: 'Destination Location'),
                      items: locations.map((loc) {
                        return DropdownMenuItem(
                          value: loc.id,
                          child: Text(loc.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _toLocationId = val),
                      validator: (val) => val == null ? AppLocalizations.of(context)!.requiredField : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.isEmpty) return AppLocalizations.of(context)!.requiredField;
                        try {
                          final parsed = Decimal.parse(val);
                          if (parsed <= Decimal.zero) return 'Must be greater than 0';
                        } catch (e) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading 
                        ? const CircularProgressIndicator()
                        : const Text('Transfer'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
