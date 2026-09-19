import re

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

# 1. Add _multiSelectedProductIds
state_start = """class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final String _selectedDocumentType = 'FACTURE';"""
new_state_start = """class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  Set<String> _multiSelectedProductIds = {};
  final String _selectedDocumentType = 'FACTURE';"""
content = content.replace(state_start, new_state_start)


# 2. Add _addMultiSelectedToCart
add_cart_method = """  void _addToPurchase(Product product) {"""
new_multi_cart_method = """  Future<void> _addMultiSelectedToCart(List<Product> allProducts) async {
    final qtyController = TextEditingController(text: '1');
    final Decimal? qty = await showDialog<Decimal>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${AppLocalizations.of(context)?.add ?? 'Add'} ${_multiSelectedProductIds.length} items'),
        content: TextField(
          controller: qtyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.quantity ?? 'Quantity',
          ),
          autofocus: true,
          onSubmitted: (val) {
            Navigator.pop(context, Decimal.tryParse(val) ?? Decimal.one);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, Decimal.tryParse(qtyController.text) ?? Decimal.one);
            },
            child: Text(AppLocalizations.of(context)?.add ?? 'Add'),
          ),
        ],
      ),
    );

    if (qty != null && qty > Decimal.zero) {
      setState(() {
        for (final pid in _multiSelectedProductIds) {
          final p = allProducts.firstWhere((prod) => prod.id == pid);
          final existingIndex = _activeSession.cart.indexWhere((l) => l.productId == p.id);
          if (existingIndex >= 0) {
            final existing = _activeSession.cart[existingIndex];
            _activeSession.cart[existingIndex] = PurchaseLineRequest(
              productId: existing.productId,
              quantity: qty,
              unitPrice: existing.unitPrice,
            );
          } else {
            _activeSession.cart.add(PurchaseLineRequest(
              productId: p.id,
              quantity: qty,
              unitPrice: p.purchasePrice,
            ));
          }
        }
        _multiSelectedProductIds.clear();
      });
    }
  }

  void _addToPurchase(Product product) {"""
content = content.replace(add_cart_method, new_multi_cart_method)


# 3. Update InkWell
inkwell_old = """            return InkWell(
              onTap: () => _addToPurchase(p),
              onDoubleTap: () => ItemNavigator.openProduct(context, p),
              child: Card(
                color: Colors.teal.shade50,"""
inkwell_new = """            final isSelected = _multiSelectedProductIds.contains(p.id);
            return InkWell(
              onTap: () {
                if (_multiSelectedProductIds.isNotEmpty) {
                  setState(() {
                    if (isSelected) _multiSelectedProductIds.remove(p.id);
                    else _multiSelectedProductIds.add(p.id);
                  });
                } else {
                  _addToPurchase(p);
                }
              },
              onLongPress: () {
                setState(() {
                  if (isSelected) _multiSelectedProductIds.remove(p.id);
                  else _multiSelectedProductIds.add(p.id);
                });
              },
              onDoubleTap: () => ItemNavigator.openProduct(context, p),
              child: Card(
                color: Colors.teal.shade50,
                elevation: isSelected ? 8 : 2,
                shape: isSelected 
                    ? RoundedRectangleBorder(
                        side: BorderSide(color: Colors.teal, width: 3),
                        borderRadius: BorderRadius.circular(12))
                    : null,"""
content = content.replace(inkwell_old, inkwell_new)

# 4. Add FloatingActionButton to Scaffold
scaffold_old = """    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.recordInboundPurchase ?? 'Record Inbound Purchase (ACH)')),
      body: LayoutBuilder("""
scaffold_new = """    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.recordInboundPurchase ?? 'Record Inbound Purchase (ACH)')),
      floatingActionButton: _multiSelectedProductIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                final allProducts = productsAsync.valueOrNull ?? [];
                _addMultiSelectedToCart(allProducts);
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('${AppLocalizations.of(context)?.add ?? 'Add'} ${_multiSelectedProductIds.length}'),
            )
          : null,
      body: LayoutBuilder("""
content = content.replace(scaffold_old, scaffold_new)

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
