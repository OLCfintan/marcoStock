extension UpdatePurchase on PurchaseService {
  Future<void> updatePurchase(PurchaseRequest request, String existingPurchaseId) async {
    await _db.transaction(() async {
      final purchase = await (_db.select(_db.purchases)..where((t) => t.id.equals(existingPurchaseId))).getSingleOrNull();
      if (purchase == null) return;

      final oldLines = await (_db.select(_db.purchaseLines)..where((t) => t.purchaseId.equals(existingPurchaseId))).get();

      // Reverse Stock
      for (final line in oldLines) {
        final product = await (_db.select(_db.products)..where((t) => t.id.equals(line.productId))).getSingleOrNull();
        if (product == null) continue;

        final baseProduct = await getDeterministicBaseProduct(_db, product);
        final totalBaseUnits = convertQuantityToBase(line.quantity, product, baseProduct);
        final targetProductId = baseProduct.id;
        final locationId = AppLocations.baseWarehouse;

        final balanceQuery = _db.select(_db.stockBalances)..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(locationId));
        final balance = await balanceQuery.getSingleOrNull();
        final currentQty = balance?.quantity ?? Decimal.zero;
        final newQty = currentQty - totalBaseUnits;

        if (balance != null) {
          await _db.update(_db.stockBalances).replace(balance.copyWith(quantity: newQty, updatedAt: DateTime.now()));
        } else {
          await _db.into(_db.stockBalances).insert(StockBalancesCompanion.insert(productId: targetProductId, locationId: locationId, quantity: newQty));
        }

        await _db.into(_db.stockMovements).insert(StockMovementsCompanion.insert(
          id: _uuid.v4(),
          productId: targetProductId,
          sourceLocationId: drift.Value(locationId),
          targetLocationId: const drift.Value.absent(),
          quantity: -totalBaseUnits,
          reason: 'PURCHASE_UPDATED_REVERSE',
          referenceOperationId: drift.Value(existingPurchaseId),
          createdBy: request.currentUserId,
        ));
      }

      // Reverse Supplier Debt
      final oldDebtAdded = purchase.total - purchase.paidAmount;
      if (oldDebtAdded > Decimal.zero) {
        final supplierQuery = _db.select(_db.suppliers)..where((t) => t.id.equals(purchase.supplierId));
        final supplier = await supplierQuery.getSingleOrNull();
        if (supplier != null) {
          final newBalance = supplier.balance - oldDebtAdded;
          await _db.update(_db.suppliers).replace(supplier.copyWith(balance: newBalance));
        }
      }

      // Delete old lines
      await (_db.delete(_db.purchaseLines)..where((t) => t.purchaseId.equals(existingPurchaseId))).go();

      // Apply new lines
      Decimal total = Decimal.zero;

      for (final line in request.lines) {
        final lineId = _uuid.v4();
        final lineTotal = line.quantity * line.unitPrice;
        total += lineTotal;
        
        await _db.into(_db.purchaseLines).insert(PurchaseLinesCompanion.insert(
          id: lineId,
          purchaseId: existingPurchaseId,
          productId: line.productId,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          lineTotal: lineTotal,
        ));
        
        // Don't re-calculate WAC here for simplicity, or we could. Let's skip WAC update on edit to avoid complexity, or just add stock.
        await _addStock(
          productId: line.productId, 
          quantity: line.quantity, 
          reason: 'PURCHASE_UPDATED',
          referenceOperationId: existingPurchaseId,
          userId: request.currentUserId,
        );
      }

      final status = purchase.paidAmount >= total ? 'PAID' : (purchase.paidAmount > Decimal.zero ? 'PARTIAL' : 'UNPAID');

      // Re-apply Supplier Debt
      final newDebt = total - purchase.paidAmount;
      if (newDebt > Decimal.zero) {
        final supplierQuery = _db.select(_db.suppliers)..where((t) => t.id.equals(purchase.supplierId));
        final supplier = await supplierQuery.getSingleOrNull();
        if (supplier != null) {
          final newBalance = supplier.balance + newDebt;
          await _db.update(_db.suppliers).replace(supplier.copyWith(
            balance: newBalance,
            updatedAt: DateTime.now(),
          ));
        }
      }

      await _db.update(_db.purchases).replace(purchase.copyWith(
        total: total,
        status: status,
      ));

      await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
        id: _uuid.v4(),
        userId: request.currentUserId,
        action: 'UPDATE_PURCHASE',
        entityType: 'PURCHASE',
        entityId: existingPurchaseId,
        details: jsonEncode({'total': total.toString(), 'supplierId': request.supplierId}),
      ));
    });
  }
}
