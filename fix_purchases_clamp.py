import re

filepath = "lib/src/application/purchases/purchase_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_logic = r"""        // Clamp to zero: stock may have been manually deleted, transferred, or sold
        final actualDeduction = currentQty < totalBaseUnits \? currentQty : totalBaseUnits;
        final newQty = currentQty - actualDeduction;

        if \(balance != null\) \{
          await _db.update\(_db.stockBalances\).replace\(balance.copyWith\(quantity: newQty, updatedAt: DateTime.now\(\)\)\);
        \} else if \(newQty > Decimal.zero\) \{
          await _db.into\(_db.stockBalances\).insert\(StockBalancesCompanion.insert\(productId: targetProductId, locationId: locationId, quantity: newQty\)\);
        \}"""

new_logic = r"""        // Mathematically preserve exact balances even if they go negative
        final newQty = currentQty - totalBaseUnits;

        if (balance != null) {
          await _db.update(_db.stockBalances).replace(balance.copyWith(quantity: newQty, updatedAt: DateTime.now()));
        } else {
          await _db.into(_db.stockBalances).insert(StockBalancesCompanion.insert(productId: targetProductId, locationId: locationId, quantity: newQty));
        }"""

content = re.sub(old_logic, new_logic, content)
with open(filepath, 'w') as f:
    f.write(content)
print("Removed clamp from purchase_service.dart")
