import re

filepath = "lib/src/application/stock/stock_transfer_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_logic = r"""      // 1. Deduct from source
      final sourceBalance = await \(_db.select\(_db.stockBalances\)
            \.\.where\(\(t\) => t.productId.equals\(targetProductId\) & t.locationId.equals\(fromLocationId\)\)\)
          .getSingleOrNull\(\);

      // Mathematically preserve balances
      final actualTransfer = totalBaseUnits;"""

new_logic = r"""      // 1. Deduct from source
      final sourceBalance = await (_db.select(_db.stockBalances)
            ..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(fromLocationId)))
          .getSingleOrNull();

      final currentQty = sourceBalance?.quantity ?? Decimal.zero;
      if (currentQty < totalBaseUnits) {
        throw Exception('Insufficient stock at source location for transfer. Available: ${currentQty.toStringAsFixed(2)}, Requested: ${totalBaseUnits.toStringAsFixed(2)}');
      }

      // Mathematically preserve balances
      final actualTransfer = totalBaseUnits;"""

content = re.sub(old_logic, new_logic, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Added stock validation to stock_transfer_service.dart")
