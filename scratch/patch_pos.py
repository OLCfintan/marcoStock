import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# 1. Add selectedClientTier to PosSession
content = content.replace(
    '  String? selectedClientId;',
    '  String? selectedClientId;\n  String? selectedClientTier;'
)

# 2. Add _getPriceForTier and _recalculateCartPrices
func_code = """
  Decimal _getPriceForTier(Product p, String? tier) {
    if (tier == 'Tier 2') return p.tier2Price ?? p.sellingPrice;
    if (tier == 'Tier 3') return p.tier3Price ?? p.sellingPrice;
    return p.sellingPrice;
  }

  void _recalculateCartPrices() {
    final products = ref.read(productsStreamProvider).valueOrNull ?? [];
    final productMap = {for (final p in products) p.id: p};
    
    for (int i = 0; i < _activeSession.cart.length; i++) {
      final line = _activeSession.cart[i];
      final product = productMap[line.productId];
      if (product != null) {
        _activeSession.cart[i] = SaleLineRequest(
          productId: line.productId,
          quantity: line.quantity,
          unitPrice: _getPriceForTier(product, _activeSession.selectedClientTier),
          discount: line.discount,
        );
      }
    }
  }

  Future<void> _addToCart(Product p) async {
"""
content = content.replace('  Future<void> _addToCart(Product p) async {', func_code)

# 3. Change _addToCart to use _getPriceForTier
add_cart_old = """
        } else {
          _activeSession.cart.add(SaleLineRequest(
            productId: p.id,
            quantity: newQty,
            unitPrice: p.sellingPrice,
            discount: Decimal.zero,
          ));
        }
"""
add_cart_new = """
        } else {
          _activeSession.cart.add(SaleLineRequest(
            productId: p.id,
            quantity: newQty,
            unitPrice: _getPriceForTier(p, _activeSession.selectedClientTier),
            discount: Decimal.zero,
          ));
        }
"""
content = content.replace(add_cart_old, add_cart_new)

# 4. Update AutocompleteSearchField onSelected
on_selected_old = """
                    onSelected: (client) {
                      setState(() {
                        _activeSession.selectedClientId = client.id;
                      });
                    },
"""
on_selected_new = """
                    onSelected: (client) {
                      setState(() {
                        _activeSession.selectedClientId = client.id;
                        _activeSession.selectedClientTier = client.tier;
                        _recalculateCartPrices();
                      });
                    },
"""
content = content.replace(on_selected_old, on_selected_new)

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
