import re

filepath = "lib/src/application/stock/stock_transfer_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_transfer = r"""      // Resolve product Family Base Unit and scale quantity
      final product = await \(_db.select\(_db.products\)\.\.where\(\(t\) => t.id.equals\(productId\)\)\).getSingle\(\);
      
      final baseProduct = await getDeterministicBaseProduct\(_db, product\);
      String targetProductId = baseProduct.id;
      
      final totalBaseUnits = convertQuantityToBase\(quantity, product, baseProduct\);

      // 1. Deduct from source
      final sourceBalance = await \(_db.select\(_db.stockBalances\)
            \.\.where\(\(t\) => t.productId.equals\(targetProductId\) & t.locationId.equals\(fromLocationId\)\)\)
          .getSingleOrNull\(\);

      final currentQty = sourceBalance\?.quantity \?\? Decimal.zero;
      if \(currentQty < totalBaseUnits\) \{
        throw Exception\('Insufficient stock at source location for transfer. Available: \$\{currentQty.toStringAsFixed\(2\)\}, Requested: \$\{totalBaseUnits.toStringAsFixed\(2\)\}'\);
      \}

      // Mathematically preserve balances
      final actualTransfer = totalBaseUnits;

      if \(sourceBalance == null\) \{
        await _db.into\(_db.stockBalances\).insert\(StockBalancesCompanion.insert\(
              productId: targetProductId,
              locationId: fromLocationId,
              quantity: -actualTransfer,
            \)\);
      \} else \{
        await _db.update\(_db.stockBalances\).replace\(
              sourceBalance.copyWith\(
                quantity: sourceBalance.quantity - actualTransfer,
                updatedAt: DateTime.now\(\),
              \),
            \);
      \}

      // 2. Add to destination
      final destBalance = await \(_db.select\(_db.stockBalances\)
            \.\.where\(\(t\) => t.productId.equals\(targetProductId\) & t.locationId.equals\(toLocationId\)\)\)
          .getSingleOrNull\(\);

      if \(destBalance == null\) \{
        await _db.into\(_db.stockBalances\).insert\(
              StockBalancesCompanion.insert\(
                productId: targetProductId,
                locationId: toLocationId,
                quantity: actualTransfer,
              \),
            \);
      \} else \{
        await _db.update\(_db.stockBalances\).replace\(
              destBalance.copyWith\(
                quantity: destBalance.quantity \+ actualTransfer,
                updatedAt: DateTime.now\(\),
              \),
            \);
      \}

      // 3. Create StockMovement record
      await _db.into\(_db.stockMovements\).insert\(
            StockMovementsCompanion.insert\(
              id: _uuid.v4\(\),
              productId: targetProductId,
              sourceLocationId: Value\(fromLocationId\),
              targetLocationId: Value\(toLocationId\),
              quantity: actualTransfer,
              reason: 'TRANSFER',
              createdBy: _currentUserId,
            \),
          \);"""

new_transfer = r"""      final product = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingle();
      
      // Determine tracking parameters based on source/dest rules
      final sourceInfo = await getStockTrackingInfo(_db, product, quantity, fromLocationId);
      final destInfo = await getStockTrackingInfo(_db, product, quantity, toLocationId);

      // 1. Deduct from source
      final sourceBalance = await (_db.select(_db.stockBalances)
            ..where((t) => t.productId.equals(sourceInfo.productId) & t.locationId.equals(fromLocationId)))
          .getSingleOrNull();

      final currentQty = sourceBalance?.quantity ?? Decimal.zero;
      if (currentQty < sourceInfo.quantity) {
        throw Exception('Insufficient stock at source location for transfer. Available: ${currentQty.toStringAsFixed(2)}, Requested: ${sourceInfo.quantity.toStringAsFixed(2)}');
      }

      if (sourceBalance == null) {
        await _db.into(_db.stockBalances).insert(StockBalancesCompanion.insert(
              productId: sourceInfo.productId,
              locationId: fromLocationId,
              quantity: -sourceInfo.quantity,
            ));
      } else {
        await _db.update(_db.stockBalances).replace(
              sourceBalance.copyWith(
                quantity: sourceBalance.quantity - sourceInfo.quantity,
                updatedAt: DateTime.now(),
              ),
            );
      }

      // 2. Add to destination
      final destBalance = await (_db.select(_db.stockBalances)
            ..where((t) => t.productId.equals(destInfo.productId) & t.locationId.equals(toLocationId)))
          .getSingleOrNull();

      if (destBalance == null) {
        await _db.into(_db.stockBalances).insert(
              StockBalancesCompanion.insert(
                productId: destInfo.productId,
                locationId: toLocationId,
                quantity: destInfo.quantity,
              ),
            );
      } else {
        await _db.update(_db.stockBalances).replace(
              destBalance.copyWith(
                quantity: destBalance.quantity + destInfo.quantity,
                updatedAt: DateTime.now(),
              ),
            );
      }

      // 3. Create StockMovement record (record the physical unit movement)
      await _db.into(_db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: _uuid.v4(),
              productId: product.id, // Record the exact physical product moved
              sourceLocationId: Value(fromLocationId),
              targetLocationId: Value(toLocationId),
              quantity: quantity, // Record the raw physical quantity
              reason: 'TRANSFER',
              createdBy: _currentUserId,
            ),
          );"""

content = re.sub(old_transfer, new_transfer, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated stock_transfer_service.dart")
