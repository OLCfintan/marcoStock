import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';
import '../../application/products/product_providers.dart';

class ClientDetailsScreen extends ConsumerWidget {
  final String clientId;
  
  const ClientDetailsScreen({super.key, required this.clientId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This wrapper can be used as a standalone screen later,
    // or just the section can be used inside HumanProfileDialog.
    return Scaffold(
      appBar: AppBar(title: const Text('Client Details')),
      body: RemainingProductsSection(clientId: clientId),
    );
  }
}

class RemainingProductsSection extends ConsumerStatefulWidget {
  final String clientId;

  const RemainingProductsSection({super.key, required this.clientId});

  @override
  ConsumerState<RemainingProductsSection> createState() => _RemainingProductsSectionState();
}

class _RemainingProductsSectionState extends ConsumerState<RemainingProductsSection> {
  void _addRemainingProduct() {
    showDialog(
      context: context,
      builder: (context) => _AddBackorderDialog(clientId: widget.clientId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    
    // Join backorders with products
    final query = db.select(db.clientBackorders).join([
      drift.innerJoin(db.products, db.products.id.equalsExp(db.clientBackorders.productId)),
    ])..where(db.clientBackorders.clientId.equals(widget.clientId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: _addRemainingProduct,
            icon: const Icon(Icons.add),
            label: const Text('Add Remaining Product'),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<drift.TypedResult>>(
            stream: query.watch(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final rows = snapshot.data!;
              if (rows.isEmpty) {
                return const Center(child: Text('No remaining products (backorders) for this client.'));
              }
              
              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final backorder = row.readTable(db.clientBackorders);
                  final product = row.readTable(db.products);
                  
                  return ListTile(
                    title: Text('${product.name} (${product.unitSize} ${product.unit})'),
                    subtitle: Text('Quantity: ${backorder.quantity}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _EditBackorderDialog(
                            backorder: backorder, 
                            productName: '${product.name} (${product.unitSize} ${product.unit})',
                          ),
                        );
                      },
                      child: const Text('Fulfill/Edit'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddBackorderDialog extends ConsumerStatefulWidget {
  final String clientId;
  const _AddBackorderDialog({required this.clientId});

  @override
  ConsumerState<_AddBackorderDialog> createState() => _AddBackorderDialogState();
}

class _AddBackorderDialogState extends ConsumerState<_AddBackorderDialog> {
  String? _selectedProductId;
  final _qtyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    
    return AlertDialog(
      title: const Text('Add Remaining Product'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          productsAsync.when(
            data: (products) => DropdownButtonFormField<String>(
              value: _selectedProductId,
              items: products.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.unitSize} ${p.unit})'))).toList(),
              onChanged: (val) => setState(() => _selectedProductId = val),
              decoration: const InputDecoration(labelText: 'Product'),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, st) => Text('Error loading products: $e'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_selectedProductId == null || _qtyController.text.isEmpty) return;
            final qty = double.tryParse(_qtyController.text) ?? 0.0;
            if (qty <= 0) return;
            
            final db = ref.read(databaseProvider);
            await db.into(db.clientBackorders).insert(ClientBackorder(
              id: const Uuid().v4(),
              clientId: widget.clientId,
              productId: _selectedProductId!,
              quantity: qty,
              createdAt: DateTime.now(),
            ));
            
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _EditBackorderDialog extends ConsumerStatefulWidget {
  final ClientBackorder backorder;
  final String productName;

  const _EditBackorderDialog({required this.backorder, required this.productName});

  @override
  ConsumerState<_EditBackorderDialog> createState() => _EditBackorderDialogState();
}

class _EditBackorderDialogState extends ConsumerState<_EditBackorderDialog> {
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.backorder.quantity.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Fulfill/Edit: ${widget.productName}'),
      content: TextField(
        controller: _qtyController,
        decoration: const InputDecoration(labelText: 'New Quantity (0 to fulfill/delete)'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final qty = double.tryParse(_qtyController.text) ?? 0.0;
            final db = ref.read(databaseProvider);
            
            if (qty <= 0) {
              await (db.delete(db.clientBackorders)..where((t) => t.id.equals(widget.backorder.id))).go();
            } else {
              await (db.update(db.clientBackorders)..where((t) => t.id.equals(widget.backorder.id)))
                  .write(ClientBackordersCompanion(quantity: drift.Value(qty)));
            }
            
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
