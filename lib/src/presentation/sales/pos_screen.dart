import '../../application/products/product_providers.dart';
import '../../domain/extensions/invoice_line_extensions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../widgets/product_image.dart';
import '../widgets/item_navigator.dart';

import '../../application/sales/sales_service.dart';
import '../../infrastructure/repositories/client_repository.dart';
import '../../domain/products/product.dart';
import '../widgets/image_picker_field.dart';
import "../widgets/quantity_selector_dialog.dart";
import '../widgets/autocomplete_search_field.dart';



class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});
  @override ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final List<PosSession> _sessions = [];
  int _activeSessionIndex = 0;

  PosSession get _activeSession => _sessions[_activeSessionIndex];

  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _sessions.add(PosSession(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Cart 1'));
  }

  Decimal get _cartTotal {
    return _activeSession.cart.fold(Decimal.zero, (total, line) => total + line.calculatedTotal);
  }

  Decimal get _totalPaid {
    Decimal total = Decimal.zero;
    for (final p in _activeSession.payments) {
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
    for (var s in _sessions) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _addToCart(Product p) async {
    final existingIndex = _activeSession.cart.indexWhere((l) => l.productId == p.id);
    final Decimal initialQty = existingIndex >= 0 ? _activeSession.cart[existingIndex].quantity : Decimal.one;

    final Decimal? newQty = await showDialog<Decimal>(
      context: context,
      builder: (context) => QuantitySelectorDialog(
        product: p,
        initialQuantity: initialQty,
      ),
    );

    if (newQty != null) {
      if (newQty <= Decimal.zero) {
        setState(() {
          if (existingIndex >= 0) {
            _activeSession.cart.removeAt(existingIndex);
          }
        });
        return;
      }

      setState(() {
        if (existingIndex >= 0) {
          final existing = _activeSession.cart[existingIndex];
          _activeSession.cart[existingIndex] = SaleLineRequest(
            productId: existing.productId,
            quantity: newQty,
            unitPrice: existing.unitPrice,
            discount: existing.discount,
          );
        } else {
          _activeSession.cart.add(SaleLineRequest(
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.productNotFound}$code')));
      }
    }
    _barcodeController.clear();
    _barcodeFocusNode.requestFocus();
  }

  Future<void> _processSale() async {
    if (_activeSession.selectedClientId == null || _activeSession.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectClientAndProducts)));
      return;
    }

    final paymentRequests = _activeSession.payments.map((p) {
      Decimal amount = Decimal.tryParse(p.amountController.text) ?? Decimal.zero;
      return SalePaymentRequest(
        amount: amount,
        method: p.method,
        checkImagePath: p.method == 'CHECK' ? p.checkImagePath : null,
      );
    }).toList();

    final total = _activeSession.cart.fold(Decimal.zero, (sum, line) => sum + ((line.quantity * line.unitPrice) - line.discount));
    final paidAmount = paymentRequests.fold(Decimal.zero, (sum, p) => sum + p.amount);
    
    if (paidAmount > total) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.paymentExceedsTotal)));
      return;
    }

    final req = SaleRequest(
      documentType: _activeSession.selectedDocumentType,
      clientId: _activeSession.selectedClientId!,
      currentUserId: 'ADMIN_01', 
      lines: _activeSession.cart,
      payments: paymentRequests,
    );

    try {
      await ref.read(salesServiceProvider).executeSale(req);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.saleCompletedSuccessfully)));
        setState(() { 
          _activeSession.dispose();
          _sessions.removeAt(_activeSessionIndex);
          if (_sessions.isEmpty) {
            _sessions.add(PosSession(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Cart 1'));
            _activeSessionIndex = 0;
          } else if (_activeSessionIndex >= _sessions.length) {
            _activeSessionIndex = _sessions.length - 1;
          }
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${(AppLocalizations.of(context)?.errorStr ?? 'Error: ')}$e')));
    }
  }

  @override
  Widget build(BuildContext context) {

    final productsAsync = ref.watch(productsStreamProvider);
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!.localeName;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.newSalePos)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final productsWidget = productsAsync.when(
            data: (allProducts) {
              final products = allProducts.where((p) => p.isActive).toList();
              return GridView.builder(
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
                      onDoubleTap: () => ItemNavigator.openProduct(context, p),
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
                            Expanded(child: ProductImage(product: p, size: double.infinity)),
                            const SizedBox(height: 8),
                            Text(p.localizedLabel(loc), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${p.sellingPrice.toStringAsFixed(2)} Dhs', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('${(AppLocalizations.of(context)?.errorStr ?? 'Error: ')}$err')),
          );

          final productMap = productsAsync.valueOrNull != null 
              ? {for (final p in productsAsync.valueOrNull!) p.id: p} 
              : <String, Product>{};

          final cartWidget = Container(
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                // Sessions Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._sessions.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final session = entry.value;
                        final isActive = idx == _activeSessionIndex;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _activeSessionIndex = idx;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isActive ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                              border: Border(bottom: BorderSide(color: isActive ? theme.colorScheme.primary : Colors.transparent, width: 2)),
                            ),
                            child: Row(
                              children: [
                                Text(session.title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      session.dispose();
                                      _sessions.removeAt(idx);
                                      if (_sessions.isEmpty) {
                                        _sessions.add(PosSession(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Cart 1'));
                                        _activeSessionIndex = 0;
                                      } else if (_activeSessionIndex >= _sessions.length) {
                                        _activeSessionIndex = _sessions.length - 1;
                                      }
                                    });
                                  },
                                  child: const Icon(Icons.close, size: 16),
                                )
                              ],
                            ),
                          ),
                        );
                      }),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _sessions.add(PosSession(
                              id: DateTime.now().millisecondsSinceEpoch.toString(), 
                              title: 'Cart ${_sessions.length + 1}'
                            ));
                            _activeSessionIndex = _sessions.length - 1;
                          });
                        },
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    value: _activeSession.selectedDocumentType,
                    decoration: InputDecoration(
                      labelText: 'Document Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.colorScheme.primaryContainer.withAlpha(128),
                    ),
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    items: [
                      DropdownMenuItem(value: 'BON', child: Text(AppLocalizations.of(context)!.bon)),
                      DropdownMenuItem(value: 'FACTURE', child: Text(AppLocalizations.of(context)!.invoice)),
                    ],
                    onChanged: (val) => setState(() => _activeSession.selectedDocumentType = val!),
                  ),
                ),
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
                        _activeSession.selectedClientId = client.id;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Cart Items & Checkout
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _activeSession.cart.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final line = _activeSession.cart[index];
                              final product = productMap[line.productId] ?? productsAsync.valueOrNull!.first;
                              final variantLabel = product.localizedLabel(loc);
                              final lineTotal = line.calculatedTotal;
                              
                              return ListTile(
                                leading: CircleAvatar(child: Text('${line.quantity}')),
                                title: Text(variantLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${line.unitPrice} each'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                      onPressed: () {
                                        final qtyCtrl = TextEditingController(text: line.quantity.toString());
                                        final priceCtrl = TextEditingController(text: line.unitPrice.toStringAsFixed(2));
                                        
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text("${AppLocalizations.of(context)!.edit} ${product.localizedName(loc)}"),
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
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
                                        TextButton(
                                          onPressed: () {
                                            final newQty = Decimal.tryParse(qtyCtrl.text) ?? line.quantity;
                                            final newPrice = Decimal.tryParse(priceCtrl.text) ?? line.unitPrice;
                                            setState(() {
                                              if (newQty <= Decimal.zero) {
                                                _activeSession.cart.removeAt(index);
                                              } else {
                                                _activeSession.cart[index] = SaleLineRequest(
                                                  productId: product.id,
                                                  quantity: newQty,
                                                  unitPrice: newPrice,
                                                  discount: line.discount,
                                                );
                                              }
                                            });
                                            Navigator.pop(ctx);
                                          },
                                          child: Text(AppLocalizations.of(context)!.save),
                                        ),
                                      ]
                                    )
                                  );
                                },
                              ),
                              Text('${lineTotal.toStringAsFixed(2)} Dhs', style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          onTap: () {
                            if (productMap.containsKey(line.productId)) {
                              _addToCart(productMap[line.productId]!);
                            }
                          },
                        );
                      },
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
                      ..._activeSession.payments.asMap().entries.map((entry) {
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
                                      items: [
                                        DropdownMenuItem(value: 'CASH', child: Text(AppLocalizations.of(context)!.cash.toUpperCase())),
                                        DropdownMenuItem(value: 'CHECK', child: Text(AppLocalizations.of(context)!.check.toUpperCase())),
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
                                        _activeSession.payments.removeAt(idx);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (p.method == 'CHECK') ...[
                                const SizedBox(height: 8),
                                ImagePickerField(
                                  label: AppLocalizations.of(context)!.checkImage,
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
                            _activeSession.payments.add(_PaymentEntry(
                              method: 'CASH',
                              initialAmount: _remainingBalance > Decimal.zero ? _remainingBalance.toStringAsFixed(2) : '',
                            ));
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: Text(AppLocalizations.of(context)!.addPaymentMethod),
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
                          child: Text(AppLocalizations.of(context)!.confirmSale, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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

          if (constraints.maxWidth < 600) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Products'),
                      Tab(text: 'Cart'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        productsWidget,
                        cartWidget,
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              Expanded(flex: 2, child: productsWidget),
              const VerticalDivider(width: 1),
              Expanded(flex: 1, child: cartWidget),
            ],
          );
        },
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
  }) {
    amountController = TextEditingController(text: initialAmount);
  }
}

class PosSession {
  final String id;
  String title;
  String? selectedClientId;
  String selectedDocumentType = 'BON';
  List<SaleLineRequest> cart = [];
  List<_PaymentEntry> payments = [];

  PosSession({required this.id, required this.title}) {
    payments.add(_PaymentEntry(method: 'CASH'));
  }

  void dispose() {
    for (var p in payments) {
      p.amountController.dispose();
    }
  }
}
