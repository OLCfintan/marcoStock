import re

with open('lib/src/application/dashboard/dashboard_providers.dart', 'r') as f:
    content = f.read()

old_logic = """    for (final familyName in familyGroups.keys) {
      final family = familyGroups[familyName]!;
      
      // 1. Determine Exact Mathematical Root Product to sync with Stock Engine
      final rootProduct = await getDeterministicBaseProduct(db, family.first);
      
      // 2. Extract highest minimums for this entire family
      Decimal familyBaseMin = Decimal.zero;
      Decimal familyMagazinMin = Decimal.zero;
      
      for (final p in family) {
        final pBaseMin = p.baseMinimumStock > Decimal.zero ? p.baseMinimumStock : p.minimumStock;
        if (pBaseMin > familyBaseMin) familyBaseMin = pBaseMin;
        
        final pMagMin = p.magazinMinimumStock > Decimal.zero ? p.magazinMinimumStock : p.minimumStock;
        if (pMagMin > familyMagazinMin) familyMagazinMin = pMagMin;
      }
      
      // Since ALL stock (Base & Magazin) is routed to the rootProduct mathematically, we evaluate ONCE per family
      
      // A. Evaluate Base Stock
      if (familyBaseMin > Decimal.zero) {
        final baseQuery = db.select(db.stockBalances)..where((t) => t.productId.equals(rootProduct.id) & t.locationId.equals(AppLocations.baseWarehouse));
        final baseBalances = await baseQuery.get();
        final baseTotal = baseBalances.fold(Decimal.zero, (sum, b) => sum + b.quantity);
        
        if (baseTotal <= familyBaseMin) {
          final baseLabel = ' ${rootProduct.unitSize}${rootProduct.unit}';
          alerts.add(LowStockAlert('${rootProduct.name}$baseLabel (Base)', baseTotal, familyBaseMin));
        }
      }

      // B. Evaluate Magazin Stock
      if (familyMagazinMin > Decimal.zero) {
        final magazinQuery = db.select(db.stockBalances)..where((t) => t.productId.equals(rootProduct.id) & t.locationId.equals(AppLocations.magazin));
        final magazinBalances = await magazinQuery.get();
        final magazinTotal = magazinBalances.fold(Decimal.zero, (sum, b) => sum + b.quantity);
        
        if (magazinTotal <= familyMagazinMin) {
          final baseLabel = ' ${rootProduct.unitSize}${rootProduct.unit}';
          alerts.add(LowStockAlert('${rootProduct.name}$baseLabel (Magazin)', magazinTotal, familyMagazinMin));
        }
      }
    }"""

new_logic = """    for (final familyName in familyGroups.keys) {
      final family = familyGroups[familyName]!;
      
      // 1. Determine Exact Mathematical Root Product to sync with Stock Engine
      final rootProduct = await getDeterministicBaseProduct(db, family.first);
      
      // 2. Extract highest minimums for this entire family dynamically converted to SI Units
      Decimal familyBaseMinInSI = Decimal.zero;
      
      for (final p in family) {
        final pBaseMin = p.baseMinimumStock > Decimal.zero ? p.baseMinimumStock : p.minimumStock;
        if (pBaseMin > Decimal.zero) {
          final pBaseMinSI = convertQuantityToBase(pBaseMin, p, rootProduct);
          if (pBaseMinSI > familyBaseMinInSI) familyBaseMinInSI = pBaseMinSI;
        }

        // 3. Evaluate Magazin Stock INDIVIDUALLY for each variant (because Magazin tracks physical variants directly)
        final pMagMin = p.magazinMinimumStock > Decimal.zero ? p.magazinMinimumStock : p.minimumStock;
        if (pMagMin > Decimal.zero) {
          final magazinQuery = db.select(db.stockBalances)..where((t) => t.productId.equals(p.id) & t.locationId.equals(AppLocations.magazin));
          final magazinBalances = await magazinQuery.get();
          final magazinTotal = magazinBalances.fold(Decimal.zero, (sum, b) => sum + b.quantity);
          
          if (magazinTotal <= pMagMin) {
            final baseLabel = p.unitSize == Decimal.one ? ' ${p.unit}' : ' ${p.unitSize}${p.unit}';
            alerts.add(LowStockAlert('${p.name}$baseLabel (Mag)', magazinTotal, pMagMin));
          }
        }
      }
      
      // A. Evaluate Base Stock (Aggregated at the family root)
      if (familyBaseMinInSI > Decimal.zero) {
        final baseQuery = db.select(db.stockBalances)..where((t) => t.productId.equals(rootProduct.id) & t.locationId.equals(AppLocations.baseWarehouse));
        final baseBalances = await baseQuery.get();
        final baseTotal = baseBalances.fold(Decimal.zero, (sum, b) => sum + b.quantity);
        
        if (baseTotal <= familyBaseMinInSI) {
          final baseLabel = rootProduct.unitSize == Decimal.one ? ' ${rootProduct.unit}' : ' ${rootProduct.unitSize}${rootProduct.unit}';
          alerts.add(LowStockAlert('${rootProduct.name}$baseLabel (Base)', baseTotal, familyBaseMinInSI));
        }
      }
    }"""

if old_logic in content:
    content = content.replace(old_logic, new_logic)
    
    # We must import `convertQuantityToBase` and `AppLocations` if missing, but `AppLocations` is imported.
    # Check if convertQuantityToBase is imported.
    if 'convertQuantityToBase' not in content[:500]:
        content = "import '../stock/stock_helpers.dart';\n" + content

    with open('lib/src/application/dashboard/dashboard_providers.dart', 'w') as f:
        f.write(content)
    print("Patched successfully!")
else:
    print("Old logic not found!")

