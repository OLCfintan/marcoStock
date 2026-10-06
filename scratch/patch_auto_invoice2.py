with open('lib/src/presentation/sales/pos_screen.dart', 'rb') as f:
    data = f.read()

start_marker = b'void _generateAutoInvoice(double targetAmount, int numFamilies, List<Product> allProducts) {'
end_marker = b'\n  @override\n  Widget build(BuildContext context) {'

start_idx = data.find(start_marker)
# Go back to include the leading spaces
start_idx = data.rfind(b'\n', 0, start_idx) + 1

end_idx = data.find(end_marker, start_idx)

print(f"Start: {start_idx}, End: {end_idx}")
print(f"Replacing {end_idx - start_idx} bytes")

new_method = b'''  void _generateAutoInvoice(double targetAmount, int numFamilies, List<Product> allProducts) {
    // TIER LOGIC:
    // Under 2500 -> allocate ~500 per product
    // Under 5000 -> allocate ~1000 per product, then cascade to 500, then remainder
    // Under 7500 -> allocate ~1500 per product, then cascade to 1000, 500, remainder
    // General: bucket scales with target amount
    
    final double primaryBucket;
    if (targetAmount <= 2500) {
      primaryBucket = 500;
    } else if (targetAmount <= 5000) {
      primaryBucket = 1000;
    } else if (targetAmount <= 7500) {
      primaryBucket = 1500;
    } else if (targetAmount <= 10000) {
      primaryBucket = 2000;
    } else {
      primaryBucket = (targetAmount / 5).ceilToDouble();
    }
    
    // Collect active products by category
    final Map<String, List<Product>> byCategory = {};
    for (var p in allProducts) {
      if (!p.isActive) continue;
      final cat = p.category ?? 'Uncategorized';
      byCategory.putIfAbsent(cat, () => []).add(p);
    }
    
    final categories = byCategory.keys.toList();
    categories.shuffle();
    final selectedCategories = categories.take(numFamilies).toList();
    
    final pool = <Product>[];
    for (var c in selectedCategories) {
      pool.addAll(byCategory[c]!);
    }
    if (pool.isEmpty) return;
    pool.shuffle();
    
    List<SaleLineRequest> generatedCart = [];
    double remaining = targetAmount;
    int productIndex = 0;
    
    // CASCADE through tiers: primaryBucket -> half -> half -> ...
    List<double> tiers = [];
    double tier = primaryBucket;
    while (tier >= 250) {
      tiers.add(tier);
      tier = (tier / 2).floorToDouble();
    }
    if (tiers.isEmpty) tiers.add(500);
    
    for (double currentTier in tiers) {
      // Keep allocating products at this tier level while remaining >= currentTier * 0.88
      while (remaining >= currentTier * 0.88 && productIndex < pool.length * 3) {
        final p = pool[productIndex % pool.length];
        productIndex++;
        
        final price = p.sellingPrice.toDouble();
        if (price <= 0) continue;
        
        // Calculate quantity to reach ~currentTier DH from this product
        int qty = (currentTier / price).round();
        if (qty < 1) qty = 1;
        
        double lineTotal = qty * price;
        
        // Adjust price slightly (+-12%) so lineTotal hits the tier naturally
        // e.g., 500 could become 440-560 for a perfect number
        if (lineTotal > 0 && remaining > 0) {
          double idealTotal = (currentTier < remaining) ? currentTier : remaining;
          double ratio = idealTotal / lineTotal;
          
          // Clamp ratio to +-12% of base price
          if (ratio > 1.12) ratio = 1.12;
          if (ratio < 0.88) ratio = 0.88;
          
          double adjustedPrice = price * ratio;
          lineTotal = qty * adjustedPrice;
          
          if (lineTotal <= remaining * 1.02) {
            generatedCart.add(SaleLineRequest(
              productId: p.id,
              quantity: Decimal.fromInt(qty),
              unitPrice: Decimal.parse(adjustedPrice.toStringAsFixed(2)),
              discount: Decimal.zero,
            ));
            remaining -= lineTotal;
          }
        }
        
        if (remaining.abs() < 1.0) break;
      }
      
      if (remaining.abs() < 1.0) break;
    }
    
    // ABSORB any final remainder into 1-2 products
    if (remaining.abs() > 1.0 && pool.isNotEmpty) {
      final p = pool[productIndex % pool.length];
      final price = p.sellingPrice.toDouble();
      if (price > 0) {
        int qty = (remaining / price).round();
        if (qty < 1) qty = 1;
        double adjustedPrice = remaining / qty;
        
        // Only use adjusted price if within +-12% of base
        if (adjustedPrice >= price * 0.88 && adjustedPrice <= price * 1.12) {
          generatedCart.add(SaleLineRequest(
            productId: p.id,
            quantity: Decimal.fromInt(qty),
            unitPrice: Decimal.parse(adjustedPrice.toStringAsFixed(2)),
            discount: Decimal.zero,
          ));
          remaining = 0;
        } else {
          generatedCart.add(SaleLineRequest(
            productId: p.id,
            quantity: Decimal.fromInt(qty),
            unitPrice: Decimal.parse(price.toStringAsFixed(2)),
            discount: Decimal.zero,
          ));
          remaining -= qty * price;
        }
      }
    }
    
    // FINAL MICRO-ADJUSTMENT: spread remaining pennies across all lines
    if (generatedCart.isNotEmpty && remaining.abs() > 0.01) {
      double perLine = remaining / generatedCart.length;
      List<SaleLineRequest> adjusted = [];
      for (var line in generatedCart) {
        double oldPrice = line.unitPrice.toDouble();
        double newPrice = oldPrice + (perLine / line.quantity.toDouble());
        adjusted.add(SaleLineRequest(
          productId: line.productId,
          quantity: line.quantity,
          unitPrice: Decimal.parse(newPrice.toStringAsFixed(2)),
          discount: Decimal.zero,
        ));
      }
      generatedCart = adjusted;
    }
    
    setState(() {
      _activeSession.cart = generatedCart;
    });
  }
'''

data = data[:start_idx] + new_method + data[end_idx:]

with open('lib/src/presentation/sales/pos_screen.dart', 'wb') as f:
    f.write(data)
print("Auto invoice algorithm replaced successfully")
