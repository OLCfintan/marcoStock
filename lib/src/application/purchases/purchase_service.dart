import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/constants/locations.dart';

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  return PurchaseService(ref.watch(databaseProvider));
});

class PurchasePaymentRequest {
  final Decimal amount;
  final String method;
  final String? checkImagePath;

  PurchasePaymentRequest({
    required this.amount,
    required this.method,
    this.checkImagePath,
  });
}

class PurchaseRequest {
  final String documentType;
  final String supplierId;
  final String currentUserId;
  final List<PurchaseLineRequest> lines;
  final List<PurchasePaymentRequest> payments;
  
  PurchaseRequest({
    required this.documentType,
    required this.supplierId,
    required this.currentUserId,
    required this.lines,
    this.payments = const [],
  });
}

class PurchaseLineRequest {
  final String productId;
  final Decimal quantity;
  final Decimal unitPrice;
  
  PurchaseLineRequest({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });
}

class PurchaseService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  PurchaseService(this._db);

  /// Executes a purchase atomically.
  Future<void> executePurchase(PurchaseRequest request) async {
    await _db.transaction(() async {
      final purchaseId = _uuid.v4();
      final date = DateTime.now();
      
      // 1. Generate Purchase Number
      final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final prefix = request.documentType == 'BON' ? 'BON-ACH-$yearMonth' : 'FAC-ACH-$yearMonth';
      
      final seqQuery = _db.select(_db.documentSequences)
        ..where((t) => t.documentType.equals('PURCHASE') & t.prefix.equals(prefix));
      final seq = await seqQuery.getSingleOrNull();
      
      int nextNum = 1;
      if (seq != null) {
        nextNum = seq.lastNumber + 1;
        await _db.update(_db.documentSequences).replace(
          seq.copyWith(lastNumber: nextNum)
        );
      } else {
        await _db.into(_db.documentSequences).insert(DocumentSequencesCompanion.insert(
          documentType: 'PURCHASE',
          prefix: prefix,
          lastNumber: const drift.Value(1),
        ));
      }
      
      final purchaseNumber = '$prefix-${nextNum.toString().padLeft(4, '0')}';
      
      Decimal total = Decimal.zero;
      
      // 2. Process Lines & Stock
      for (final line in request.lines) {
        final lineId = _uuid.v4();
        final lineTotal = line.quantity * line.unitPrice;
        total += lineTotal;
        
        await _db.into(_db.purchaseLines).insert(PurchaseLinesCompanion.insert(
          id: lineId,
          purchaseId: purchaseId,
          productId: line.productId,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          lineTotal: lineTotal,
        ));
        
        // WAC (Moving Average Price) Calculation
        final product = await (_db.select(_db.products)..where((t) => t.id.equals(line.productId))).getSingle();
        final familyProducts = await (_db.select(_db.products)..where((t) => t.name.equals(product.name))).get();
        
        Decimal totalOldBaseQty = Decimal.zero;
        Decimal totalOldValue = Decimal.zero;
        
        for (final p in familyProducts) {
          final bals = await (_db.select(_db.stockBalances)..where((t) => t.productId.equals(p.id))).get();
          final pQty = bals.fold(Decimal.zero, (sum, b) => sum + (b.quantity > Decimal.zero ? b.quantity : Decimal.zero));
          totalOldBaseQty += pQty * p.unitSize;
          totalOldValue += pQty * p.purchasePrice;
        }
        
        final addedBaseQty = line.quantity * product.unitSize;
        final addedValue = line.quantity * line.unitPrice;
        
        final newTotalBaseQty = totalOldBaseQty + addedBaseQty;
        Decimal newBaseUnitCost = Decimal.zero;
        if (newTotalBaseQty > Decimal.zero) {
          final newValue = totalOldValue + addedValue;
          final rationalCost = newValue / newTotalBaseQty;
          newBaseUnitCost = rationalCost.toDecimal(scaleOnInfinitePrecision: 2);
        } else {
           // fallback if somehow dividing by zero
           newBaseUnitCost = (line.unitPrice / product.unitSize).toDecimal(scaleOnInfinitePrecision: 4);
        }
        
        for (final p in familyProducts) {
          final newPurchasePrice = newBaseUnitCost * p.unitSize;
          
          // Only update the purchase price. Selling prices remain manual via tier settings.
          await _db.update(_db.products).replace(p.copyWith(
             purchasePrice: newPurchasePrice, 
             updatedAt: DateTime.now()
          ));
        }

        await _addStock(
          productId: line.productId, 
          quantity: line.quantity, 
          reason: 'PURCHASE',
          referenceOperationId: purchaseId,
          userId: request.currentUserId,
        );
      }
      
      Decimal paidAmount = Decimal.zero;
      for (final p in request.payments) {
        if (p.method != 'CREDIT') {
          paidAmount += p.amount;
        }
      }
      final status = paidAmount >= total ? 'PAID' : (paidAmount > Decimal.zero ? 'PARTIAL' : 'UNPAID');
      
      // 3. Update Supplier Balance (We owe them)
      final debt = total - paidAmount;
      if (debt > Decimal.zero) {
        final supplierQuery = _db.select(_db.suppliers)..where((t) => t.id.equals(request.supplierId));
        final supplier = await supplierQuery.getSingleOrNull();
        if (supplier != null) {
          final newBalance = supplier.balance + debt;
          await _db.update(_db.suppliers).replace(supplier.copyWith(
            balance: newBalance,
            updatedAt: DateTime.now(),
          ));
        }
      }
      
      // 4. Create Purchase Record
      await _db.into(_db.purchases).insert(PurchasesCompanion.insert(
        id: purchaseId,
        documentType: drift.Value(request.documentType),
        purchaseNumber: purchaseNumber,
        supplierId: request.supplierId,
        date: date,
        total: total,
        paidAmount: paidAmount,
        status: status,
      ));
      
      // 4.5 Insert Payments
      for (final p in request.payments) {
        if (p.amount > Decimal.zero || p.method == 'CREDIT') {
          await _db.into(_db.payments).insert(PaymentsCompanion.insert(
            id: _uuid.v4(),
            supplierId: drift.Value(request.supplierId),
            purchaseId: drift.Value(purchaseId),
            amount: p.amount,
            method: p.method,
            checkImagePath: drift.Value(p.checkImagePath),
            date: date,
            status: 'CLEARED',
          ));
        }
      }
      
      // 5. Audit Log
      await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
        id: _uuid.v4(),
        userId: request.currentUserId,
        action: 'CREATE_PURCHASE',
        entityType: 'PURCHASE',
        entityId: purchaseId,
        details: jsonEncode({'total': total.toString(), 'supplierId': request.supplierId, 'purchaseNumber': purchaseNumber}),
      ));
      
      // 6. Sync Outbox
      await _db.into(_db.syncOutbox).insert(SyncOutboxCompanion.insert(
        id: _uuid.v4(),
        entityType: 'PURCHASE',
        entityId: purchaseId,
        operation: 'INSERT',
        payload: jsonEncode({'id': purchaseId, 'status': status}), 
      ));
    });
  }

    
  Future<void> deletePurchase(String purchaseId, String userId) async {
    await _db.transaction(() async {
      final purchase = await (_db.select(_db.purchases)..where((t) => t.id.equals(purchaseId))).getSingleOrNull();
      if (purchase == null || !purchase.isActive) return;

      final lines = await (_db.select(_db.purchaseLines)..where((t) => t.purchaseId.equals(purchaseId))).get();

      // Reverse Stock
      for (final line in lines) {
        final product = await (_db.select(_db.products)..where((t) => t.id.equals(line.productId))).getSingleOrNull();
        if (product == null) continue;

        final baseProducts = await (_db.select(_db.products)..where((t) => t.name.equals(product.name) & t.packagingType.equals('Unit'))).get();
        final baseProduct = baseProducts.isNotEmpty ? baseProducts.first : product;
        final totalBaseUnits = line.quantity * product.unitSize;
        final targetProductId = baseProduct.id;
        final locationId = AppLocations.baseWarehouse;

        final balanceQuery = _db.select(_db.stockBalances)..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(locationId));
        final balance = await balanceQuery.getSingleOrNull();
        final currentQty = balance?.quantity ?? Decimal.zero;
        final newQty = currentQty - totalBaseUnits;
        if (newQty < Decimal.zero) {
          throw Exception('Cannot delete purchase: ${product.name} has insufficient stock to reverse ($currentQty available, trying to remove $totalBaseUnits).');
        }

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
          reason: 'PURCHASE_DELETED',
          referenceOperationId: drift.Value(purchaseId),
          createdBy: userId,
        ));
      }

      // Reverse Supplier Debt
      final debtAdded = purchase.total - purchase.paidAmount;
      if (debtAdded > Decimal.zero && purchase.supplierId != null) {
        final supplierQuery = _db.select(_db.suppliers)..where((t) => t.id.equals(purchase.supplierId!));
        final supplier = await supplierQuery.getSingleOrNull();
        if (supplier != null) {
          final newBalance = supplier.balance - debtAdded;
          await _db.update(_db.suppliers).replace(supplier.copyWith(balance: newBalance));
        }
      }

      // Mark Purchase as Deleted
      await (_db.update(_db.purchases)..where((t) => t.id.equals(purchaseId))).write(
        const PurchasesCompanion(isActive: drift.Value(false))
      );
    });
  }

  Future<void> restorePurchase(String purchaseId, String userId) async {
    await _db.transaction(() async {
      final purchase = await (_db.select(_db.purchases)..where((t) => t.id.equals(purchaseId))).getSingleOrNull();
      if (purchase == null || purchase.isActive) return;

      final lines = await (_db.select(_db.purchaseLines)..where((t) => t.purchaseId.equals(purchaseId))).get();

      // Re-apply Stock
      for (final line in lines) {
        final product = await (_db.select(_db.products)..where((t) => t.id.equals(line.productId))).getSingleOrNull();
        if (product == null) continue;

        final baseProducts = await (_db.select(_db.products)..where((t) => t.name.equals(product.name) & t.packagingType.equals('Unit'))).get();
        final baseProduct = baseProducts.isNotEmpty ? baseProducts.first : product;
        final totalBaseUnits = line.quantity * product.unitSize;
        final targetProductId = baseProduct.id;
        final locationId = AppLocations.baseWarehouse;

        final balanceQuery = _db.select(_db.stockBalances)..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(locationId));
        final balance = await balanceQuery.getSingleOrNull();
        final currentQty = balance?.quantity ?? Decimal.zero;
        final newQty = currentQty + totalBaseUnits;

        if (balance != null) {
          await _db.update(_db.stockBalances).replace(balance.copyWith(quantity: newQty, updatedAt: DateTime.now()));
        } else {
          await _db.into(_db.stockBalances).insert(StockBalancesCompanion.insert(productId: targetProductId, locationId: locationId, quantity: newQty));
        }

        await _db.into(_db.stockMovements).insert(StockMovementsCompanion.insert(
          id: _uuid.v4(),
          productId: targetProductId,
          sourceLocationId: const drift.Value.absent(),
          targetLocationId: drift.Value(locationId),
          quantity: totalBaseUnits,
          reason: 'PURCHASE_RESTORED',
          referenceOperationId: drift.Value(purchaseId),
          createdBy: userId,
        ));
      }

      // Re-apply Supplier Debt
      final debtAdded = purchase.total - purchase.paidAmount;
      if (debtAdded > Decimal.zero && purchase.supplierId != null) {
        final supplierQuery = _db.select(_db.suppliers)..where((t) => t.id.equals(purchase.supplierId!));
        final supplier = await supplierQuery.getSingleOrNull();
        if (supplier != null) {
          final newBalance = supplier.balance + debtAdded;
          await _db.update(_db.suppliers).replace(supplier.copyWith(balance: newBalance));
        }
      }

      // Mark Purchase as Active
      await (_db.update(_db.purchases)..where((t) => t.id.equals(purchaseId))).write(
        const PurchasesCompanion(isActive: drift.Value(true))
      );
    });
  }

  Future<void> _addStock({
    required String productId, 
    required Decimal quantity,
    required String reason,
    required String referenceOperationId,
    required String userId,
  }) async {
    final locationId = AppLocations.baseWarehouse;
    final product = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (product == null) return;
    
    final familyProducts = await (_db.select(_db.products)..where((t) => t.name.equals(product.name))).get();
    final baseProduct = familyProducts.firstWhere(
      (p) => p.unitSize == Decimal.one,
      orElse: () => familyProducts.firstWhere(
        (p) => p.packagingType == 'Unit' || p.packagingType == null || p.packagingType == '',
        orElse: () => product,
      ),
    );
    final totalBaseUnits = quantity * product.unitSize;
    final targetProductId = baseProduct.id;
    
    final balanceQuery = _db.select(_db.stockBalances)..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(locationId));
    final balance = await balanceQuery.getSingleOrNull();
    final currentQty = balance?.quantity ?? Decimal.zero;
    final newQty = currentQty + totalBaseUnits;
    
    if (balance == null) {
      await _db.into(_db.stockBalances).insert(StockBalancesCompanion.insert(productId: targetProductId, locationId: locationId, quantity: newQty));
    } else {
      await _db.update(_db.stockBalances).replace(balance.copyWith(quantity: newQty, updatedAt: DateTime.now()));
    }
    
    await _db.into(_db.stockMovements).insert(StockMovementsCompanion.insert(
      id: _uuid.v4(),
      productId: targetProductId,
      sourceLocationId: const drift.Value.absent(),
      targetLocationId: drift.Value(locationId),
      quantity: totalBaseUnits,
      reason: reason,
      referenceOperationId: drift.Value(referenceOperationId),
      createdBy: userId,
    ));
  }
}