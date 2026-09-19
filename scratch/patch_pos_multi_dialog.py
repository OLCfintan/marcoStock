import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

old_code = """  Future<void> _addMultiSelectedToCart(List<Product> allProducts) async {
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
            child: Text('Add'),
          ),
        ],
      ),
    );"""

new_code = """  Future<void> _addMultiSelectedToCart(List<Product> allProducts) async {
    if (_multiSelectedProductIds.isEmpty) return;
    
    final firstProductId = _multiSelectedProductIds.first;
    final firstProduct = allProducts.firstWhere((p) => p.id == firstProductId);

    final Decimal? qty = await showDialog<Decimal>(
      context: context,
      builder: (context) => QuantitySelectorDialog(
        product: firstProduct,
        initialQuantity: Decimal.one,
      ),
    );"""

content = content.replace(old_code, new_code)
with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
