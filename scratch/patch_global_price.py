with open('lib/src/presentation/products/products_screen.dart', 'r') as f:
    content = f.read()

import_str = "import 'package:decimal/decimal.dart';\n"
if 'package:decimal/decimal.dart' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_str)

appbar_btn = '''          if (_selectedProductIds.isNotEmpty && ref.watch(currentUserProvider)?.role == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.price_change),
              tooltip: 'Global Update Price',
              onPressed: () {
                _showGlobalUpdatePriceDialog();
              },
            ),
          if (_selectedProductIds.isNotEmpty && ref.watch(currentUserProvider)?.role == 'ADMIN')
'''

content = content.replace("          if (_selectedProductIds.isNotEmpty && ref.watch(currentUserProvider)?.role == 'ADMIN')\n            IconButton(\n              icon: const Icon(Icons.delete),", appbar_btn + "            IconButton(\n              icon: const Icon(Icons.delete),")


method_str = '''  Future<void> _showGlobalUpdatePriceDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Global Update Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amount in DH to add to selected products (use negative number to subtract):'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Amount (DH)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancelStr)),
          ElevatedButton(
            onPressed: () async {
              final amount = Decimal.tryParse(ctrl.text);
              if (amount != null && amount != Decimal.zero) {
                Navigator.pop(ctx);
                final repo = ref.read(productRepositoryProvider);
                final allProducts = ref.read(productsStreamProvider).valueOrNull ?? [];
                
                for (final id in _selectedProductIds) {
                  final p = allProducts.firstWhere((prod) => prod.id == id);
                  
                  final newSellingPrice = p.sellingPrice + amount;
                  final newTier2 = (p.tier2Price != null) ? (p.tier2Price! + amount) : null;
                  final newTier3 = (p.tier3Price != null) ? (p.tier3Price! + amount) : null;
                  
                  final updatedProduct = Product(
                    id: p.id,
                    name: p.name,
                    nameAr: p.nameAr,
                    nameFr: p.nameFr,
                    nameEs: p.nameEs,
                    reference: p.reference,
                    category: p.category,
                    unit: p.unit,
                    unitSize: p.unitSize,
                    unitsPerBox: p.unitsPerBox,
                    purchasePrice: p.purchasePrice,
                    sellingPrice: newSellingPrice > Decimal.zero ? newSellingPrice : Decimal.zero,
                    tier2Price: (newTier2 != null && newTier2 > Decimal.zero) ? newTier2 : ((p.tier2Price != null) ? Decimal.zero : null),
                    tier3Price: (newTier3 != null && newTier3 > Decimal.zero) ? newTier3 : ((p.tier3Price != null) ? Decimal.zero : null),
                    minimumStock: p.minimumStock,
                    baseMinimumStock: p.baseMinimumStock,
                    magazinMinimumStock: p.magazinMinimumStock,
                    description: p.description,
                    imagePath: p.imagePath,
                    packagingType: p.packagingType,
                    isActive: p.isActive,
                    displayOrder: p.displayOrder,
                    createdAt: p.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  
                  await repo.updateProduct(updatedProduct);
                }
                
                setState(() {
                  _selectedProductIds.clear();
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prices updated globally!')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
'''

content = content.replace("  @override\n  Widget build(BuildContext context) {", method_str + "  Widget build(BuildContext context) {")

with open('lib/src/presentation/products/products_screen.dart', 'w') as f:
    f.write(content)
print("Products screen patched for global update price")
