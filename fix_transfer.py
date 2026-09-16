import re

filepath = "lib/src/application/stock/stock_transfer_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_logic = r"""      if \(sourceBalance == null \|\| sourceBalance.quantity <= Decimal.zero\) \{
        throw Exception\('Insufficient stock at source location for base unit'\);
      \}

      // Clamp to available stock
      final actualTransfer = sourceBalance.quantity < totalBaseUnits \? sourceBalance.quantity : totalBaseUnits;

      await _db.update\(_db.stockBalances\).replace\(
            sourceBalance.copyWith\(
              quantity: sourceBalance.quantity - actualTransfer,
              updatedAt: DateTime.now\(\),
            \),
          \);"""

new_logic = r"""      // Mathematically preserve balances
      final actualTransfer = totalBaseUnits;

      if (sourceBalance == null) {
        await _db.into(_db.stockBalances).insert(StockBalancesCompanion.insert(
              productId: targetProductId,
              locationId: fromLocationId,
              quantity: -actualTransfer,
            ));
      } else {
        await _db.update(_db.stockBalances).replace(
              sourceBalance.copyWith(
                quantity: sourceBalance.quantity - actualTransfer,
                updatedAt: DateTime.now(),
              ),
            );
      }"""

content = re.sub(old_logic, new_logic, content)
with open(filepath, 'w') as f:
    f.write(content)
print("Updated stock_transfer_service.dart")
