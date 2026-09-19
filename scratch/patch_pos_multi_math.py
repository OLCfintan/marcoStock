import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

old_logic = """    if (qty != null && qty > Decimal.zero) {
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
    }"""

new_logic = """    if (qty != null && qty > Decimal.zero) {
      setState(() {
        // Algebraically extract the exact number of boxes the user wanted based on the first product's ratio
        final decimalBoxes = firstProduct.unitsPerBox > 0 
            ? (qty / Decimal.fromInt(firstProduct.unitsPerBox)).toDecimal(scaleOnInfinitePrecision: 4)
            : qty;

        for (final pid in _multiSelectedProductIds) {
          final p = allProducts.firstWhere((prod) => prod.id == pid);
          
          // Apply the box ratio to this specific product's unique packaging size
          final finalUnits = p.unitsPerBox > 0 
              ? (decimalBoxes * Decimal.fromInt(p.unitsPerBox)).toDecimal(scaleOnInfinitePrecision: 4)
              : decimalBoxes;
              
          final existingIndex = _activeSession.cart.indexWhere((l) => l.productId == p.id);
          if (existingIndex >= 0) {
            final existing = _activeSession.cart[existingIndex];
            _activeSession.cart[existingIndex] = SaleLineRequest(
              productId: existing.productId,
              quantity: finalUnits,
              unitPrice: existing.unitPrice,
              discount: existing.discount,
            );
          } else {
            _activeSession.cart.add(SaleLineRequest(
              productId: p.id,
              quantity: finalUnits,
              unitPrice: _getPriceForTier(p, _activeSession.selectedClientTier),
              discount: Decimal.zero,
            ));
          }
        }
        _multiSelectedProductIds.clear();
      });
    }"""

content = content.replace(old_logic, new_logic)

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)

