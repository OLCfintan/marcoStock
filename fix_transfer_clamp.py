import re

filepath = "lib/src/application/stock/stock_transfer_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_logic = r"""      // Clamp to available stock
      final actualTransfer = sourceBalance.quantity < totalBaseUnits \? sourceBalance.quantity : totalBaseUnits;

      await _db.update\(_db.stockBalances\).replace\(
            sourceBalance.copyWith\(
              quantity: sourceBalance.quantity - actualTransfer,
              updatedAt: DateTime.now\(\),
            \),
          \);

      // 2. Add to destination
      final destBalance = await \(_db.select\(_db.stockBalances\)
            \.\.where\(\(t\) =>
                t.productId.equals\(targetProductId\) &
                t.locationId.equals\(destinationLocationId\)\)\)
          .getSingleOrNull\(\);

      if \(destBalance != null\) \{
        await _db.update\(_db.stockBalances\).replace\(
              destBalance.copyWith\(
                quantity: destBalance.quantity \+ actualTransfer,
                updatedAt: DateTime.now\(\),
              \),
            \);
      \} else \{
        await _db.into\(_db.stockBalances\).insert\(StockBalancesCompanion.insert\(
              productId: targetProductId,
              locationId: destinationLocationId,
              quantity: actualTransfer,
            \)\);
      \}"""

new_logic = r"""      // Mathematically preserve exact balances even if they go negative
      final actualTransfer = totalBaseUnits;

      await _db.update(_db.stockBalances).replace(
            sourceBalance.copyWith(
              quantity: sourceBalance.quantity - actualTransfer,
              updatedAt: DateTime.now(),
            ),
          );

      // 2. Add to destination
      final destBalance = await (_db.select(_db.stockBalances)
            ..where((t) =>
                t.productId.equals(targetProductId) &
                t.locationId.equals(destinationLocationId)))
          .getSingleOrNull();

      if (destBalance != null) {
        await _db.update(_db.stockBalances).replace(
              destBalance.copyWith(
                quantity: destBalance.quantity + actualTransfer,
                updatedAt: DateTime.now(),
              ),
            );
      } else {
        await _db.into(_db.stockBalances).insert(StockBalancesCompanion.insert(
              productId: targetProductId,
              locationId: destinationLocationId,
              quantity: actualTransfer,
            ));
      }"""

content = re.sub(old_logic, new_logic, content)
with open(filepath, 'w') as f:
    f.write(content)
print("Removed clamp from stock_transfer_service.dart")
