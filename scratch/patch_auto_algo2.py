import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

old_loop = """    Map<Product, int> selectedItems = {};
    double currentTotal = 0.0;
    
    final rand = Random();
    int attempts = 0;
    while (attempts < 5000) {
      if (pool.isEmpty) break;
      final p = pool[rand.nextInt(pool.length)];
      final price = p.sellingPrice.toDouble();
      
      // Box Logic: if remaining >= 500, buy by unitSize (box). Else by unit (1).
      double remaining = targetAmount - currentTotal;
      int addQty = 1;
      if (remaining >= 500.0) {
          addQty = p.unitSize.toDouble().toInt();
          if (addQty < 1) addQty = 1;
          // If a box is extremely expensive (e.g. box of 1000 items), revert to 1 if it would overshoot drastically.
          if (price * addQty > remaining * 1.5) addQty = 1;
      }
      
      double cost = price * addQty;
      
      if (currentTotal + cost <= targetAmount * 1.05) {
        int currentQty = selectedItems[p] ?? 0;
        int newQty = currentQty + addQty;
        
        bool allowed = true;
        if (addQty == 1) {
            int uSize = (p.unitSize ?? Decimal.zero).toDouble().toInt();
            int looseUnits = (uSize > 0) ? (newQty % uSize) : newQty;
            if (looseUnits > 5) allowed = false;
        }
        
        if (allowed) {
            selectedItems[p] = newQty;
            currentTotal += cost;
        }
      }
      
      if (currentTotal >= targetAmount * 0.95 && currentTotal <= targetAmount * 1.05) {
        break;
      }
      attempts++;
    }"""

new_loop = """    Map<Product, int> selectedItems = {};
    double currentTotal = 0.0;
    int totalLooseUnitsGlobally = 0;
    
    final rand = Random();
    int attempts = 0;
    while (attempts < 5000) {
      if (pool.isEmpty) break;
      final p = pool[rand.nextInt(pool.length)];
      final price = p.sellingPrice.toDouble();
      
      int uSize = p.unitSize.toDouble().toInt();
      if (uSize < 1) uSize = 1;
      
      double remaining = targetAmount - currentTotal;
      
      int addQty = uSize; 
      
      if (price * addQty > remaining * 1.05 || (remaining < 500.0 && rand.nextDouble() < 0.8)) {
         addQty = 1; 
      }
      
      if (addQty == 1 && uSize > 1) {
         if (totalLooseUnitsGlobally >= 5) {
             attempts++;
             continue; // Exceeded global limit for loose units!
         }
      }
      
      double cost = price * addQty;
      
      if (currentTotal + cost <= targetAmount * 1.05) {
        selectedItems[p] = (selectedItems[p] ?? 0) + addQty;
        currentTotal += cost;
        
        if (addQty == 1 && uSize > 1) {
            totalLooseUnitsGlobally++;
        }
      }
      
      if (currentTotal >= targetAmount * 0.95 && currentTotal <= targetAmount * 1.05) {
        break;
      }
      attempts++;
    }"""

if old_loop in content:
    content = content.replace(old_loop, new_loop)
    print('Loop patched.')
else:
    print('Loop NOT patched.')

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
