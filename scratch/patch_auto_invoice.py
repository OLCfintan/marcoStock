with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# Find the method boundaries
start_marker = '  void _generateAutoInvoice(double targetAmount, int numFamilies, List<Product> allProducts) {\r\n'
end_marker = '\r\n  @override\r\n  Widget build(BuildContext context) {'

start_idx = content.index(start_marker)
end_idx = content.index(end_marker, start_idx)

new_method = '''  void _generateAutoInvoice(double targetAmount, int numFamilies, List<Product> allProducts) {\r
    // ─── TIER LOGIC ───\r
    // Under 2500 → allocate ~500 per product\r
    // Under 5000 → allocate ~1000 per product, then cascade to 500, then remainder\r
    // Under 7500 → allocate ~1500 per product, then cascade to 1000, 500, remainder\r
    // General: bucket scales with target amount\r
    \r
    final double primaryBucket;\r
    if (targetAmount <= 2500) {\r
      primaryBucket = 500;\r
    } else if (targetAmount <= 5000) {\r
      primaryBucket = 1000;\r
    } else if (targetAmount <= 7500) {\r
      primaryBucket = 1500;\r
    } else if (targetAmount <= 10000) {\r
      primaryBucket = 2000;\r
    } else {\r
      primaryBucket = (targetAmount / 5).ceilToDouble();\r
    }\r
    \r
    // Collect active products by category\r
    final Map<String, List<Product>> byCategory = {};\r
    for (var p in allProducts) {\r
      if (!p.isActive) continue;\r
      final cat = p.category ?? 'Uncategorized';\r
      byCategory.putIfAbsent(cat, () => []).add(p);\r
    }\r
    \r
    final categories = byCategory.keys.toList();\r
    categories.shuffle();\r
    final selectedCategories = categories.take(numFamilies).toList();\r
    \r
    final pool = <Product>[];\r
    for (var c in selectedCategories) {\r
      pool.addAll(byCategory[c]!);\r
    }\r
    if (pool.isEmpty) return;\r
    pool.shuffle();\r
    \r
    List<SaleLineRequest> generatedCart = [];\r
    double remaining = targetAmount;\r
    int productIndex = 0;\r
    \r
    // ─── CASCADE through tiers: primaryBucket -> half -> half -> ... ───\r
    List<double> tiers = [];\r
    double tier = primaryBucket;\r
    while (tier >= 250) {\r
      tiers.add(tier);\r
      tier = (tier / 2).floorToDouble();\r
    }\r
    if (tiers.isEmpty) tiers.add(500);\r
    \r
    for (double currentTier in tiers) {\r
      // Keep allocating products at this tier level while remaining >= currentTier * 0.88\r
      while (remaining >= currentTier * 0.88 && productIndex < pool.length * 3) {\r
        final p = pool[productIndex % pool.length];\r
        productIndex++;\r
        \r
        final price = p.sellingPrice.toDouble();\r
        if (price <= 0) continue;\r
        \r
        // Calculate quantity to reach ~currentTier DH from this product\r
        int qty = (currentTier / price).round();\r
        if (qty < 1) qty = 1;\r
        \r
        double lineTotal = qty * price;\r
        \r
        // Adjust price slightly (±12%) so lineTotal hits the tier naturally\r
        // e.g., 500 could become 440-560 for a perfect number\r
        if (lineTotal > 0 && remaining > 0) {\r
          double idealTotal = (currentTier < remaining) ? currentTier : remaining;\r
          double ratio = idealTotal / lineTotal;\r
          \r
          // Clamp ratio to ±12% of base price\r
          if (ratio > 1.12) ratio = 1.12;\r
          if (ratio < 0.88) ratio = 0.88;\r
          \r
          double adjustedPrice = price * ratio;\r
          lineTotal = qty * adjustedPrice;\r
          \r
          if (lineTotal <= remaining * 1.02) {\r
            generatedCart.add(SaleLineRequest(\r
              productId: p.id,\r
              quantity: Decimal.fromInt(qty),\r
              unitPrice: Decimal.parse(adjustedPrice.toStringAsFixed(2)),\r
              discount: Decimal.zero,\r
            ));\r
            remaining -= lineTotal;\r
          }\r
        }\r
        \r
        if (remaining.abs() < 1.0) break;\r
      }\r
      \r
      if (remaining.abs() < 1.0) break;\r
    }\r
    \r
    // ─── ABSORB any final remainder into 1-2 products ───\r
    if (remaining.abs() > 1.0 && pool.isNotEmpty) {\r
      final p = pool[productIndex % pool.length];\r
      final price = p.sellingPrice.toDouble();\r
      if (price > 0) {\r
        int qty = (remaining / price).round();\r
        if (qty < 1) qty = 1;\r
        double adjustedPrice = remaining / qty;\r
        \r
        // Only use adjusted price if within ±12% of base\r
        if (adjustedPrice >= price * 0.88 && adjustedPrice <= price * 1.12) {\r
          generatedCart.add(SaleLineRequest(\r
            productId: p.id,\r
            quantity: Decimal.fromInt(qty),\r
            unitPrice: Decimal.parse(adjustedPrice.toStringAsFixed(2)),\r
            discount: Decimal.zero,\r
          ));\r
          remaining = 0;\r
        } else {\r
          generatedCart.add(SaleLineRequest(\r
            productId: p.id,\r
            quantity: Decimal.fromInt(qty),\r
            unitPrice: Decimal.parse(price.toStringAsFixed(2)),\r
            discount: Decimal.zero,\r
          ));\r
          remaining -= qty * price;\r
        }\r
      }\r
    }\r
    \r
    // ─── FINAL MICRO-ADJUSTMENT: spread remaining pennies across all lines ───\r
    if (generatedCart.isNotEmpty && remaining.abs() > 0.01) {\r
      double perLine = remaining / generatedCart.length;\r
      List<SaleLineRequest> adjusted = [];\r
      for (var line in generatedCart) {\r
        double oldPrice = line.unitPrice.toDouble();\r
        double newPrice = oldPrice + (perLine / line.quantity.toDouble());\r
        adjusted.add(SaleLineRequest(\r
          productId: line.productId,\r
          quantity: line.quantity,\r
          unitPrice: Decimal.parse(newPrice.toStringAsFixed(2)),\r
          discount: Decimal.zero,\r
        ));\r
      }\r
      generatedCart = adjusted;\r
    }\r
    \r
    setState(() {\r
      _activeSession.cart = generatedCart;\r
    });\r
  }\r
'''

content = content[:start_idx] + new_method + content[end_idx:]

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
print("Auto invoice algorithm replaced")
