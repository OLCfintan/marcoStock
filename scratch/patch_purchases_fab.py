import re

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

scaffold_old = """  return Scaffold(
      appBar: AppBar(title: Text(l10n?.purchases ?? AppLocalizations.of(context)!.recordInboundPurchase)),
      body: LayoutBuilder("""
scaffold_new = """  return Scaffold(
      appBar: AppBar(title: Text(l10n?.purchases ?? AppLocalizations.of(context)!.recordInboundPurchase)),
      floatingActionButton: _multiSelectedProductIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                final allProducts = productsAsync.valueOrNull ?? [];
                _addMultiSelectedToCart(allProducts);
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('Add ${_multiSelectedProductIds.length}'),
            )
          : null,
      body: LayoutBuilder("""
content = content.replace(scaffold_old, scaffold_new)

# Also fix the AppLocalizations.of(context)?.add in _addMultiSelectedToCart
content = content.replace("AppLocalizations.of(context)?.add ?? 'Add'", "'Add'")

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
