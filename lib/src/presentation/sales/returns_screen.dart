import '../../application/products/product_providers.dart';
import '../../domain/extensions/invoice_line_extensions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';

import '../../application/sales/sales_service.dart';
import '../../infrastructure/repositories/client_repository.dart';
import '../../infrastructure/repositories/product_repository.dart';
import '../../domain/products/product.dart';
import '../widgets/image_picker_field.dart';
import '../widgets/autocomplete_search_field.dart';
import '../widgets/quantity_selector_dialog.dart';



class ReturnsScreen extends ConsumerStatefulWidget {
  const ReturnsScreen({super.key});
  @override ConsumerState<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends ConsumerState<ReturnsScreen> {
  String? _selectedClientId;
  final List<SaleLineRequest> _cart = [];
  final List<_PaymentEntry> _payments = [_PaymentEntry(method: 'CASH')];
  
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  Decimal get _cartTotal {
    return _cart.fold(Decimal.zero, (total, line) => total + line.calculatedTotal);
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

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    for (var p in _payments) {
      p.amountController.dispose();
    }
    super.dispose();
  }

  Future<void> _addToCart(Product p) async {
    final existingIndex = _cart.indexWhere((l) => l.productId == p.id);
    final Decimal initialQty = existingIndex >= 0 ? _cart[existingIndex].quantity : Decimal.one;

    final Decimal? newQty = await showDialog<Decimal>(
      context: context,
      builder: (context) => QuantitySelectorDialog(
        product: p,
        initialQuantity: initialQty,
      ),
    );

    if (newQty != null) {
      if (newQty <= Decimal.zero) {
        if (existingIndex >= 0) {
          setState(() {
            _cart.removeAt(existingIndex);
          });
        }
        return;
      }

      setState(() {
        if (existingIndex >= 0) {
          final existing = _cart[existingIndex];
          _cart[existingIndex] = SaleLineRequest(
            productId: existing.productId,
            quantity: newQty,
            unitPrice: existing.unitPrice,
            discount: existing.discount,
          );
        } else {
          _cart.add(SaleLineRequest(
            productId: p.id,
            quantity: newQty,
            unitPrice: p.sellingPrice,
            discount: Decimal.zero,
          ));
        }
      });
    }
  }

  void _handleBarcodeScan(String code, List<Product>? products) {
    if (code.isEmpty || products == null) return;
    final codeLower = code.trim().toLowerCase();
    
    final productIndex = products.indexWhere(
      (p) => p.id.toLowerCase() == codeLower || p.reference.toLowerCase() == codeLower
    );
    
    if (productIndex >= 0) {
      _addToCart(products[productIndex]);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product not found: $code')));
      }
    }
    _barcodeController.clear();
    _barcodeFocusNode.requestFocus();
  }

  Future<void> _processSale() async {
    if (_selectedClientId == null || _cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a client and add products.')));
      return;
    }

    final paymentRequests = _payments.map((p) {
      Decimal amount = Decimal.tryParse(p.amountController.text) ?? Decimal.zero;
      return SalePaymentRequest(
        amount: amount,
        method: p.method,
        checkImagePath: p.method == 'CHECK' ? p.checkImagePath : null,
      );
    }).toList();

    final req = ReturnRequest(
      clientId: _selectedClientId!,
      currentUserId: 'ADMIN_01', 
      lines: _cart,
      payments: paymentRequests,
    );

    try {
      await ref.read(salesServiceProvider).processReturn(req);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return completed successfully!')));
        setState(() { 
          _cart.clear(); 
          for (var p in _payments) {
            p.amountController.dispose();
          }
          _payments.clear();
          _payments.add(_PaymentEntry(method: 'CASH'));
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {

    final productsAsync = ref.watch(productsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Process Return')),
      body: Row(
        children: [
          // Left side: Products catalog
          Expanded(
            flex: 2,
            child: productsAsync.when(
              data: (products) => GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _addToCart(p),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.primaryContainer, theme.colorScheme.surface],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.category, size: 32, color: Colors.indigo),
                            const SizedBox(height: 8),
                            Text(p.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${p.sellingPrice.toStringAsFixed(2)} Dhs', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          
          const VerticalDivider(width: 1),
          
          // Right side: Cart & Checkout
          Expanded(
            flex: 1,
            child: Container(
              color: theme.colorScheme.surface,
              child: Column(
                children: [
                  // Document type not needed for return
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _barcodeController,
                      focusNode: _barcodeFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Scan Barcode',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.qr_code_scanner),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      onSubmitted: (code) => _handleBarcodeScan(code, productsAsync.valueOrNull),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: AutocompleteSearchField<Client>(
                      labelText: 'Select Client',
                      prefixIcon: const Icon(Icons.person_search),
                      displayStringForOption: (client) => client.name,
                      getSuggestions: (query) async {
                        return ref.read(clientRepositoryProvider).searchClients(query);
                      },
                      onSelected: (client) {
                        setState(() {
                          _selectedClientId = client.id;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Cart Items
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        itemCount: _cart.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final line = _cart[index];
                          // Find name via products
                          final products = productsAsync.valueOrNull ?? [];
                          final productName = products.firstWhere((p) => p.id == line.productId, orElse: () => products.first).name;
                          final lineTotal = line.calculatedTotal;
                          
                          return ListTile(
                            leading: CircleAvatar(child: Text('${line.quantity}')),
                            title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${line.unitPrice} each'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                  onPressed: () {
                                    final pIndex = products.indexWhere((p) => p.id == line.productId);
                                    if (pIndex < 0) return;
                                    final p = products[pIndex];
                                    
                                    final qtyCtrl = TextEditingController(text: line.quantity.toString());
                                    final priceCtrl = TextEditingController(text: line.unitPrice.toStringAsFixed(2));
                                    
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('Edit ${p.name}'),
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
                                              decoration: const InputDecoration(labelText: 'Unit Price'),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () {
                                              final newQty = Decimal.tryParse(qtyCtrl.text) ?? line.quantity;
                                              final newPrice = Decimal.tryParse(priceCtrl.text) ?? line.unitPrice;
                                              setState(() {
                                                if (newQty <= Decimal.zero) {
                                                  _cart.removeAt(index);
                                                } else {
                                                  _cart[index] = SaleLineRequest(
                                                    productId: p.id,
                                                    quantity: newQty,
                                                    unitPrice: newPrice,
                                                    discount: line.discount,
                                                  );
                                                }
                                              });
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _cart.removeAt(index);
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text('${lineTotal.toStringAsFixed(2)} Dhs', style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Totals & Checkout
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text((AppLocalizations.of(context)?.totalDue ?? 'Total Due'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('${_cartTotal.toStringAsFixed(2)} Dhs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text((AppLocalizations.of(context)?.totalPaid ?? 'Total Paid'), style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text('${_totalPaid.toStringAsFixed(2)} Dhs', style: const TextStyle(fontSize: 16, color: Colors.green)),
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
                              color: theme.colorScheme.surface,
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
                                        items: const [
                                          DropdownMenuItem(value: 'CASH', child: Text('CASH')),
                                          DropdownMenuItem(value: 'CHECK', child: Text('CHECK')),
                                          DropdownMenuItem(value: 'CREDIT', child: Text('CREDIT')),
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
                                    label: 'Check Image',
                                    initialValue: p.checkImagePath,
                                    onChanged: (path) => setState(() => p.checkImagePath = path),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _payments.add(_PaymentEntry(
                                method: 'CASH',
                                initialAmount: _remainingBalance > Decimal.zero ? _remainingBalance.toStringAsFixed(2) : '',
                              ));
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Payment Method'),
                        ),
                        
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _processSale,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('CONFIRM RETURN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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

