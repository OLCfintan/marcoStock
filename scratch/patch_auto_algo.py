import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

old_algo = """      double cost = price * addQty;
      
      if (currentTotal + cost <= targetAmount * 1.05) {
        selectedItems[p] = (selectedItems[p] ?? 0) + addQty;
        currentTotal += cost;
      }"""

new_algo = """      double cost = price * addQty;
      
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
      }"""

content = content.replace(old_algo, new_algo)

old_adjust = """      double maxAdjust = basePrice * 0.05 * qty;"""
new_adjust = """      double maxAdjust = basePrice * 0.07 * qty;"""

content = content.replace(old_adjust, new_adjust)

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
print('Auto Invoice Algo patched.')
