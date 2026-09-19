import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# 1. Add _multiSelectedProductIds to _PosScreenState
state_start = """class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();"""
new_state_start = """class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();
  Set<String> _multiSelectedProductIds = {};"""
content = content.replace(state_start, new_state_start)


# 2. Add _addMultiSelectedToCart method
add_cart_method = """  Future<void> _addToCart(Product p) async {"""
new_multi_cart_method = """  Future<void> _addMultiSelectedToCart(List<Product> allProducts) async {
    final qtyController = TextEditingController(text: '1');
    final Decimal? qty = await showDialog<Decimal>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${_multiSelectedProductIds.length} items'),
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
            _activeSession.cart[existingIndex] = SaleLineRequest(
              productId: existing.productId,
              quantity: qty,
              unitPrice: existing.unitPrice,
              discount: existing.discount,
            );
          } else {
            _activeSession.cart.add(SaleLineRequest(
              productId: p.id,
              quantity: qty,
              unitPrice: _getPriceForTier(p, _activeSession.selectedClientTier),
              discount: Decimal.zero,
            ));
          }
        }
        _multiSelectedProductIds.clear();
      });
    }
  }

  Future<void> _addToCart(Product p) async {"""
content = content.replace(add_cart_method, new_multi_cart_method)

# 3. Update InkWell inside GridView.builder
inkwell_old = """                  return Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _addToCart(p),
                      onDoubleTap: () => ItemNavigator.openProduct(context, p),
                      child: Container("""
inkwell_new = """                  final isSelected = _multiSelectedProductIds.contains(p.id);
                  return Card(
                    elevation: isSelected ? 8 : 2,
                    clipBehavior: Clip.antiAlias,
                    shape: isSelected 
                        ? RoundedRectangleBorder(
                            side: BorderSide(color: theme.colorScheme.primary, width: 3),
                            borderRadius: BorderRadius.circular(12))
                        : null,
                    child: InkWell(
                      onTap: () {
                        if (_multiSelectedProductIds.isNotEmpty) {
                          setState(() {
                            if (isSelected) _multiSelectedProductIds.remove(p.id);
                            else _multiSelectedProductIds.add(p.id);
                          });
                        } else {
                          _addToCart(p);
                        }
                      },
                      onLongPress: () {
                        setState(() {
                          if (isSelected) _multiSelectedProductIds.remove(p.id);
                          else _multiSelectedProductIds.add(p.id);
                        });
                      },
                      onDoubleTap: () => ItemNavigator.openProduct(context, p),
                      child: Container("""
content = content.replace(inkwell_old, inkwell_new)


# 4. Add FloatingActionButton to Scaffold
scaffold_old = """    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.newSalePos)),
      body: LayoutBuilder("""
scaffold_new = """    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.newSalePos)),
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

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
