import '../../domain/extensions/invoice_line_extensions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../widgets/autocomplete_search_field.dart';
import "../widgets/image_picker_field.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_service.dart';
import 'package:decimal/decimal.dart';

import '../../application/suppliers/supplier_providers.dart';
import '../../application/products/product_providers.dart';
import '../../application/purchases/purchase_service.dart';
import '../../domain/products/product.dart';
import '../../infrastructure/repositories/supplier_repository.dart';
import '../widgets/quantity_selector_dialog.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PaymentEntry {
  late final TextEditingController amountController;
  String method;
  String? checkImagePath;

  _PaymentEntry({
    String initialAmount = '',
    this.method = 'CASH',
    this.checkImagePath,
  }) {
    amountController = TextEditingController(text: initialAmount);
  }
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  String? _selectedSupplierId;
  String _selectedDocumentType = 'FACTURE';
  final List<PurchaseLineRequest> _cart = [];
  final List<_PaymentEntry> _payments = [_PaymentEntry(method: 'CASH')];

  Decimal get _cartTotal {
    return _cart.fold(
      Decimal.zero,
      (sum, line) => sum + line.calculatedTotal,
    );
  }

  Decimal get _totalPaid {
    Decimal total = Decimal.zero;
    for (final p in _payments) {
      if (p.method != 'CREDIT') {
        final val = Decimal.tryParse(p.amountController.text) ?? Decimal.zero;
        total += val;
      }
    }
    return total;
  }

  Decimal get _remainingBalance {
    final rem = _cartTotal - _totalPaid;
    return rem < Decimal.zero ? Decimal.zero : rem;
  }

  Future<void> _editQuantity(Product product, Decimal initialQty) async {
    final index = _cart.indexWhere((item) => item.productId == product.id);
    if (index < 0) return;
    final old = _cart[index];
    
    final qtyCtrl = TextEditingController(text: initialQty.toString());
    final priceCtrl = TextEditingController(text: old.unitPrice.toStringAsFixed(2));
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${(() {
          String pName = product.name;
          final loc = AppLocalizations.of(context)!.localeName;
          if (loc == 'ar' && product.nameAr != null) pName = product.nameAr!;
          if (loc == 'fr' && product.nameFr != null) pName = product.nameFr!;
          if (loc == 'es' && product.nameEs != null) pName = product.nameEs!;
          return pName;
        })()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            TextFormField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Unit Cost'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final newQty = Decimal.tryParse(qtyCtrl.text) ?? initialQty;
              final newPrice = Decimal.tryParse(priceCtrl.text) ?? old.unitPrice;
              setState(() {
                if (newQty <= Decimal.zero) {
                  _cart.removeWhere((item) => item.productId == product.id);
                } else {
                  _cart[index] = PurchaseLineRequest(
                    productId: old.productId,
                    quantity: newQty,
                    unitPrice: newPrice,
                  );
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ]
      )
    );
  }

  void _addToPurchase(Product product) {
    final index = _cart.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      _editQuantity(product, _cart[index].quantity);
    } else {
      setState(() {
        _cart.add(PurchaseLineRequest(
          productId: product.id,
          quantity: Decimal.parse('1'),
          unitPrice: product.purchasePrice,
        ));
      });
      _editQuantity(product, Decimal.parse('1'));
    }
  }

  Future<void> _processPurchase() async {
    if (_selectedSupplierId == null || _cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.pleaseSelectClientAndProducts ?? 'Please select a supplier and add products.')),
      );
      return;
    }

    if (_totalPaid > _cartTotal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment amount cannot exceed the total.')));
      return;
    }

    final paymentReqs = _payments.map((p) => PurchasePaymentRequest(
      amount: Decimal.tryParse(p.amountController.text) ?? Decimal.zero,
      method: p.method,
      checkImagePath: p.checkImagePath,
    )).toList();

    final req = PurchaseRequest(
      documentType: _selectedDocumentType,
      supplierId: _selectedSupplierId!,
      currentUserId: 'ADMIN_01', 
      lines: _cart,
      payments: paymentReqs,
    );

    try {
      await ref.read(purchaseServiceProvider).executePurchase(req);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.savedSuccessfully ?? 'Purchase recorded successfully!')),
        );
        setState(() {
          _cart.clear();
          for (var p in _payments) { p.amountController.dispose(); }
          _payments.clear();
          _payments.add(_PaymentEntry(method: 'CASH'));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)?.errorStr ?? "Error:"} $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersStreamProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.purchases ?? 'Record Inbound Purchase (ACH)')),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: productsAsync.when(
              data: (allProducts) {
                final baseProductsMap = <String, Product>{};
                for (final p in allProducts) {
                  // Only consider active products
                  if (!p.isActive) continue;
                  
                  // If we haven't seen this family (name), or if the current one is exactly the base 'Unit' with unitSize 1, prioritize it.
                  if (!baseProductsMap.containsKey(p.name)) {
                    baseProductsMap[p.name] = p;
                  } else {
                    final existing = baseProductsMap[p.name]!;
                    // Prefer products that explicitly have unitSize == 1 as the true root base
                    if (p.unitSize == Decimal.parse('1')) {
                      baseProductsMap[p.name] = p;
                    }
                  }
                }
                final products = baseProductsMap.values.toList();
                products.sort((a, b) => a.name.compareTo(b.name));
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                  return InkWell(
                    onTap: () => _addToPurchase(p),
                    child: Card(
                      color: Colors.teal.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.category, size: 24, color: Colors.teal),
                            Expanded(
                              child: Center(
                                child: Text(p.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Cost: ${p.purchasePrice.toStringAsFixed(2)} Dhs', style: const TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('${l10n?.errorStr ?? "Error:"} $err')),
            ),
          ),
          
          const VerticalDivider(width: 1),
          
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: suppliersAsync.when(
                    data: (suppliers) => AutocompleteSearchField<Supplier>(
                      displayStringForOption: (s) => '${s.name} (${s.type})',
                      getSuggestions: (pattern) async {
                        if (pattern.isEmpty) return suppliers;
                        return suppliers.where((s) => s.name.toLowerCase().contains(pattern.toLowerCase())).toList();
                      },
                      onSelected: (s) => setState(() => _selectedSupplierId = s.id),
                      labelText: l10n?.suppliers ?? 'Search Supplier...',
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => Text('Err: $err'),
                  ),
                ),
                
                Expanded(
                  child: productsAsync.when(
                    data: (productsList) => ListView.builder(
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final line = _cart[index];
                        final lineTotal = line.calculatedTotal;
                        
                        final product = productsList.firstWhere(
                          (p) => p.id == line.productId, 
                          orElse: () => Product(id: line.productId, name: 'Unknown', reference: '', purchasePrice: Decimal.zero, sellingPrice: Decimal.zero, minimumStock: Decimal.zero, baseMinimumStock: Decimal.zero, magazinMinimumStock: Decimal.zero, packagingType: 'Unit', unitsPerBox: 1, unitSize: Decimal.one, unit: 'Unit', isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now())
                        );
                        
                        String pName = product.name;
                        final loc = AppLocalizations.of(context)!.localeName;
                        if (loc == 'ar' && product.nameAr != null) pName = product.nameAr!;
                        if (loc == 'fr' && product.nameFr != null) pName = product.nameFr!;
                        if (loc == 'es' && product.nameEs != null) pName = product.nameEs!;
                        final variantLabel = product.unitSize == Decimal.one ? '$pName ${product.unit}' : '$pName ${product.unitSize}${product.unit}';
                        return ListTile(
                          onTap: () => _editQuantity(product, line.quantity),
                          leading: const Icon(Icons.download, color: Colors.teal),
                          title: Text(variantLabel),
                          subtitle: Text('${line.quantity} x ${line.unitPrice} Dhs'),
                          trailing: Text('${lineTotal.toStringAsFixed(2)} Dhs'),
                        );
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e,s) => const SizedBox(),
                  )
                ),
                
                Container(
                  color: Colors.teal.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text((AppLocalizations.of(context)?.totalOwed ?? 'Total Owed'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text('${_cartTotal.toStringAsFixed(2)} Dhs', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text((AppLocalizations.of(context)?.remainingBalance ?? 'Remaining Balance'), style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text('${_remainingBalance.toStringAsFixed(2)} Dhs', style: const TextStyle(fontSize: 16, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                      const Divider(height: 24),
                      
                      // Payments List
                      ..._payments.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final p = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: p.method,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Method',
                                        border: InputBorder.none,
                                      ),
                                      items: [
                                        DropdownMenuItem(value: 'CASH', child: Text(AppLocalizations.of(context)?.cash.toUpperCase() ?? 'CASH')),
                                        DropdownMenuItem(value: 'CHECK', child: Text(AppLocalizations.of(context)?.check.toUpperCase() ?? 'CHECK')),
                                        DropdownMenuItem(value: 'CREDIT', child: Text(AppLocalizations.of(context)?.credit.toUpperCase() ?? 'CREDIT')),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          p.method = val!;
                                          if (val == 'CREDIT') {
                                            p.amountController.text = '0';
                                          } else if (p.amountController.text.isEmpty || p.amountController.text == '0') {
                                            p.amountController.text = _remainingBalance.toStringAsFixed(2);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: p.amountController,
                                      enabled: p.method != 'CREDIT',
                                      decoration: const InputDecoration(
                                        labelText: 'Amount',
                                        prefixIcon: Icon(Icons.attach_money, size: 16),
                                        border: InputBorder.none,
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (val) => setState(() {}),
                                    ),
                                  ),
                                  if (_payments.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          p.amountController.dispose();
                                          _payments.removeAt(idx);
                                        });
                                      },
                                    ),
                                ],
                              ),
                              if (p.method == 'CHECK') ...[
                                const SizedBox(height: 8),
                                ImagePickerField(
                                  label: AppLocalizations.of(context)?.checkImage ?? 'Check Image',
                                  initialValue: p.checkImagePath,
                                  onChanged: (path) => setState(() => p.checkImagePath = path),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _payments.add(_PaymentEntry(method: 'CASH'));
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Payment Method'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _processPurchase,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                          child: Text(l10n?.confirm ?? 'RECORD PURCHASE', style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
