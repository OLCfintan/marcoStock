import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/constants/locations.dart';

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';
import '../stock/stock_helpers.dart';

final salesServiceProvider = Provider<SalesService>((ref) {
  return SalesService(ref.watch(databaseProvider));
});

class SalePaymentRequest {
  final Decimal amount;
  final String method;
  final String? checkImagePath;

  SalePaymentRequest({
    required this.amount,
    required this.method,
    this.checkImagePath,
  });
}

class SaleRequest {
  final String documentType;
  final String clientId;
  final String currentUserId;
  final List<SaleLineRequest> lines;
  final List<SalePaymentRequest> payments;
  
  SaleRequest({
    this.documentType = 'FACTURE',
    required this.clientId,
    required this.currentUserId,
    required this.lines,
    this.payments = const [],
  });
}

class ReturnRequest {
  final String clientId;
  final String currentUserId;
  final List<SaleLineRequest> lines;
  final List<SalePaymentRequest> payments;
  
  ReturnRequest({
    required this.clientId,
    required this.currentUserId,
    required this.lines,
    this.payments = const [],
  });
}

class SaleLineRequest {
  final String productId;
  final Decimal quantity;
  final Decimal unitPrice;
  final Decimal discount;
  
  SaleLineRequest({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
  });
}

class SalesService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  SalesService(this._db);

  /// Executes a sale atomically.
  /// Handles: Invoices, Lines, Stock, Consumables, Payments, Audit, Sync, and Client Balances.
  Future<void> executeSale(SaleRequest request) async {
    await _db.transaction(() async {
      final client = await (_db.select(_db.clients)..where((t) => t.id.equals(request.clientId))).getSingleOrNull();
      final locationId = client?.type == 'SPECIAL' ? AppLocations.baseWarehouse : AppLocations.magazin;

      final invoiceId = _uuid.v4();
      final date = DateTime.now();
      
      // 1. Generate Formal Invoice Number (e.g., FAC-YYYY-MM-XXXX)
      final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final prefix = request.documentType == 'BON' ? 'BON-$yearMonth' : 'FAC-$yearMonth';
      
      final seqQuery = _db.select(_db.documentSequences)
        ..where((t) => t.documentType.equals('INVOICE') & t.prefix.equals(prefix));
      final seq = await seqQuery.getSingleOrNull();
      
      int nextNum = 1;
      if (seq != null) {
        nextNum = seq.lastNumber + 1;
        await _db.update(_db.documentSequences).replace(
          seq.copyWith(lastNumber: nextNum)
        );
      } else {
        await _db.into(_db.documentSequences).insert(DocumentSequencesCompanion.insert(
          documentType: 'INVOICE',
          prefix: prefix,
          lastNumber: const drift.Value(1),
        ));
      }
      
      final invoiceNumber = '$prefix-${nextNum.toString().padLeft(4, '0')}';
      
      Decimal subtotal = Decimal.zero;
      
      // 2. Create Invoice Lines & Compute Totals
      for (final line in request.lines) {
        final lineId = _uuid.v4();
        final lineTotal = (line.quantity * line.unitPrice) - line.discount;
        subtotal += lineTotal;
        
        await _db.into(_db.invoiceLines).insert(InvoiceLinesCompanion.insert(
          id: lineId,
          invoiceId: invoiceId,
          productId: line.productId,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          discount: line.discount,
          lineTotal: lineTotal,
        ));
        
        // 3. Handle Stock Deduction (Allows deduction regardless of payment status)
        await _deductStock(
          productId: line.productId, 
          quantity: line.quantity, 
          reason: 'SALE',
          referenceOperationId: invoiceId,
          userId: request.currentUserId,
          locationId: locationId,
        );
        
        // If selling to a Special Client (Magazin), this is a transfer. We must add the stock to MAGAZIN_01.
        if (client?.type == 'SPECIAL') {
          await _restoreStock(
            productId: line.productId,
            quantity: line.quantity,
            reason: 'TRANSFER_IN',
            referenceOperationId: invoiceId,
            userId: request.currentUserId,
            locationId: AppLocations.magazin,
          );
        }
        
        // 4. Handle Consumables Deduction
        await _deductConsumables(
          productId: line.productId,
          quantity: line.quantity,
          referenceOperationId: invoiceId,
          userId: request.currentUserId,
          locationId: locationId,
        );
      }
      
      final taxes = Decimal.zero;
      final total = subtotal + taxes;
            Decimal paidAmount = Decimal.zero;
      for (final p in request.payments) {
        if (p.method != 'CREDIT') {
          paidAmount += p.amount;
        }
      }
      
      final status = paidAmount >= total ? 'PAID' : (paidAmount > Decimal.zero ? 'PARTIAL' : 'UNPAID');
      
      // 5. Update Client Balance (Debt) — skip for walk-in (TEMP) clients
      final debt = total - paidAmount;
      if (debt > Decimal.zero && client != null && client.type != 'TEMP') {
        final newBalance = client.balance + debt;
        await _db.update(_db.clients).replace(client.copyWith(
          balance: newBalance,
          updatedAt: DateTime.now(),
        ));
      }
      
      // 6. Create Invoice
      await _db.into(_db.invoices).insert(InvoicesCompanion.insert(
        id: invoiceId,
        documentType: drift.Value(request.documentType),
        invoiceNumber: invoiceNumber,
        clientId: drift.Value(request.clientId),
        date: date,
        subtotal: subtotal,
        taxes: taxes,
        total: total,
        paidAmount: paidAmount,
        status: status,
      ));
      
      // 7. Create Payments
      for (final p in request.payments) {
        if (p.amount > Decimal.zero || p.method == 'CREDIT') {
          await _db.into(_db.payments).insert(PaymentsCompanion.insert(
            id: _uuid.v4(),
            clientId: drift.Value(request.clientId),
            invoiceId: drift.Value(invoiceId),
            amount: p.amount,
            method: p.method,
            checkImagePath: drift.Value(p.checkImagePath),
            date: date,
            status: 'CLEARED',
          ));
        }
      }
      
      // 8. Audit Log
      await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
        id: _uuid.v4(),
        userId: request.currentUserId,
        action: 'CREATE_SALE',
        entityType: 'INVOICE',
        entityId: invoiceId,
        details: jsonEncode({'total': total.toString(), 'clientId': request.clientId, 'invoiceNumber': invoiceNumber}),
      ));
      
      // 9. Sync Outbox
      await _db.into(_db.syncOutbox).insert(SyncOutboxCompanion.insert(
        id: _uuid.v4(),
        entityType: 'INVOICE',
        entityId: invoiceId,
        operation: 'INSERT',
        payload: jsonEncode({'id': invoiceId, 'status': status}), 
      ));
    });
  }

  Future<void> deleteInvoice(String invoiceId, String userId) async {
    await _db.transaction(() async {
      final invoice = await (_db.select(_db.invoices)..where((t) => t.id.equals(invoiceId))).getSingleOrNull();
      if (invoice == null || !invoice.isActive) return;

      final lines = await (_db.select(_db.invoiceLines)..where((t) => t.invoiceId.equals(invoiceId))).get();
      ClientEntity? client;
      if (invoice.clientId != null) {
        client = await (_db.select(_db.clients)..where((t) => t.id.equals(invoice.clientId!))).getSingleOrNull();
      }
      final locationId = client?.type == 'SPECIAL' ? AppLocations.baseWarehouse : AppLocations.magazin;

      for (final line in lines) {
        // Reverse Stock Deduction
        await _restoreStock(
          productId: line.productId,
          quantity: line.quantity,
          reason: 'SALE_DELETED',
          referenceOperationId: invoiceId,
          userId: userId,
          locationId: locationId,
        );

        // If it was a special client (transfer), reverse the inbound to Magazin
        if (client?.type == 'SPECIAL') {
          await _deductStock(
            productId: line.productId,
            quantity: line.quantity,
            reason: 'TRANSFER_REVERSED',
            referenceOperationId: invoiceId,
            userId: userId,
            locationId: AppLocations.magazin,
          );
        }

        // Reverse Consumables Deduction
        await _restoreConsumables(
          productId: line.productId,
          quantity: line.quantity,
          referenceOperationId: invoiceId,
          userId: userId,
          locationId: locationId,
        );
      }

      // Reverse Client Debt — skip for walk-in (TEMP) clients
      final debtAdded = invoice.total - invoice.paidAmount;
      if (debtAdded > Decimal.zero && client != null && client.type != 'TEMP') {
        final newBalance = client.balance - debtAdded;
        await _db.update(_db.clients).replace(client.copyWith(balance: newBalance));
      }

      // Mark Invoice as Deleted
      await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId))).write(
        const InvoicesCompanion(isActive: drift.Value(false))
      );
    });
  }

  Future<void> restoreInvoice(String invoiceId, String userId) async {
    await _db.transaction(() async {
      final invoice = await (_db.select(_db.invoices)..where((t) => t.id.equals(invoiceId))).getSingleOrNull();
      if (invoice == null || invoice.isActive) return;

      final lines = await (_db.select(_db.invoiceLines)..where((t) => t.invoiceId.equals(invoiceId))).get();
      ClientEntity? client;
      if (invoice.clientId != null) {
        client = await (_db.select(_db.clients)..where((t) => t.id.equals(invoice.clientId!))).getSingleOrNull();
      }
      final locationId = client?.type == 'SPECIAL' ? AppLocations.baseWarehouse : AppLocations.magazin;

      for (final line in lines) {
        // Re-apply Stock Deduction
        await _deductStock(
          productId: line.productId,
          quantity: line.quantity,
          reason: 'SALE_RESTORED',
          referenceOperationId: invoiceId,
          userId: userId,
          locationId: locationId,
        );



        // Re-apply Consumables Deduction
        await _deductConsumables(
          productId: line.productId,
          quantity: line.quantity,
          referenceOperationId: invoiceId,
          userId: userId,
          locationId: locationId,
        );
      }

      // Re-apply Client Debt — skip for walk-in (TEMP) clients
      final debtAdded = invoice.total - invoice.paidAmount;
      if (debtAdded > Decimal.zero && client != null && client.type != 'TEMP') {
        final newBalance = client.balance + debtAdded;
        await _db.update(_db.clients).replace(client.copyWith(balance: newBalance));
      }

      // Mark Invoice as Active
      await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId))).write(
        const InvoicesCompanion(isActive: drift.Value(true))
      );
    });
  }

  /// Converts a BON to a FACTURE (Invoice). Generates a new invoice number.
  Future<void> convertBonToInvoice(String invoiceId) async {
    await _db.transaction(() async {
      final invoice = await (_db.select(_db.invoices)..where((t) => t.id.equals(invoiceId))).getSingleOrNull();
      if (invoice == null || invoice.documentType != 'BON') return;

      final date = DateTime.now();
      final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final prefix = 'FAC-$yearMonth';
      
      final seqQuery = _db.select(_db.documentSequences)
        ..where((t) => t.documentType.equals('INVOICE') & t.prefix.equals(prefix));
      final seq = await seqQuery.getSingleOrNull();
      
      int nextNum = 1;
      if (seq != null) {
        nextNum = seq.lastNumber + 1;
        await _db.update(_db.documentSequences).replace(
          seq.copyWith(lastNumber: nextNum)
        );
      } else {
        await _db.into(_db.documentSequences).insert(DocumentSequencesCompanion.insert(
          documentType: 'INVOICE',
          prefix: prefix,
          lastNumber: const drift.Value(1),
        ));
      }
      
      final invoiceNumber = '$prefix-${nextNum.toString().padLeft(4, '0')}';

      await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId))).write(
        InvoicesCompanion(
          documentType: const drift.Value('FACTURE'),
          invoiceNumber: drift.Value(invoiceNumber),
        )
      );

      await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
        id: _uuid.v4(),
        userId: 'SYSTEM',
        action: 'CONVERT_BON',
        entityType: 'INVOICE',
        entityId: invoiceId,
        details: jsonEncode({'oldNumber': invoice.invoiceNumber, 'newNumber': invoiceNumber}),
      ));
    });
  }

  Future<void> _deductStock({
    required String productId, 
    required Decimal quantity,
    required String reason,
    required String referenceOperationId,
    required String userId,
    required String locationId,
  }) async {
    final product = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (product == null) return;
    
    final baseProduct = await getDeterministicBaseProduct(_db, product);
    String targetProductId = baseProduct.id;
    Decimal actualQuantityToDeduct = convertQuantityToBase(quantity, product, baseProduct);
    
    final balanceQuery = _db.select(_db.stockBalances)..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(locationId));
    final balance = await balanceQuery.getSingleOrNull();
    final currentQty = balance?.quantity ?? Decimal.zero;
    
    // Clamp to zero: stock may have been manually deleted, transferred, or consumed
    final actualDeduction = currentQty < actualQuantityToDeduct ? currentQty : actualQuantityToDeduct;
    final newQty = currentQty - actualDeduction;
    
    if (balance == null) {
      await _db.into(_db.stockBalances).insert(StockBalancesCompanion.insert(productId: targetProductId, locationId: locationId, quantity: newQty));
    } else {
      await _db.update(_db.stockBalances).replace(balance.copyWith(quantity: newQty, updatedAt: DateTime.now()));
    }
    
    await _db.into(_db.stockMovements).insert(StockMovementsCompanion.insert(
      id: _uuid.v4(),
      productId: targetProductId,
      sourceLocationId: drift.Value(locationId),
      targetLocationId: const drift.Value.absent(),
      quantity: -actualQuantityToDeduct,
      reason: reason,
      referenceOperationId: drift.Value(referenceOperationId),
      createdBy: userId,
    ));
  }
  Future<void> processReturn(ReturnRequest request) async {
    await _db.transaction(() async {
      final client = await (_db.select(_db.clients)..where((t) => t.id.equals(request.clientId))).getSingleOrNull();
      final locationId = client?.type == 'SPECIAL' ? AppLocations.baseWarehouse : AppLocations.magazin;

      final invoiceId = _uuid.v4();
      final date = DateTime.now();
      
      // 1. Generate Formal Invoice Number (e.g., REF-YYYY-MM-XXXX)
      final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final prefix = 'REF-$yearMonth';
      
      final seqQuery = _db.select(_db.documentSequences)
        ..where((t) => t.documentType.equals('REFUND') & t.prefix.equals(prefix));
      final seq = await seqQuery.getSingleOrNull();
      
      int nextNum = 1;
      if (seq != null) {
        nextNum = seq.lastNumber + 1;
        await _db.update(_db.documentSequences).replace(
          seq.copyWith(lastNumber: nextNum)
        );
      } else {
        await _db.into(_db.documentSequences).insert(DocumentSequencesCompanion.insert(
          documentType: 'REFUND',
          prefix: prefix,
          lastNumber: const drift.Value(1),
        ));
      }
      
      final invoiceNumber = '$prefix-${nextNum.toString().padLeft(4, '0')}';
      
      Decimal subtotal = Decimal.zero;
      
      // 2. Create Invoice Lines & Compute Totals
      for (final line in request.lines) {
        final lineId = _uuid.v4();
        // Negative for return
        final lineTotal = -((line.quantity * line.unitPrice) - line.discount);
        subtotal += lineTotal;
        
        await _db.into(_db.invoiceLines).insert(InvoiceLinesCompanion.insert(
          id: lineId,
          invoiceId: invoiceId,
          productId: line.productId,
          quantity: -line.quantity,
          unitPrice: line.unitPrice,
          discount: -line.discount,
          lineTotal: lineTotal,
        ));
        
        // 3. Handle Stock Restore
        await _restoreStock(
          productId: line.productId, 
          quantity: line.quantity, 
          reason: 'RETURN',
          referenceOperationId: invoiceId,
          userId: request.currentUserId,
          locationId: locationId,
        );
        

        
        // 4. Handle Consumables Restore
        await _restoreConsumables(
          productId: line.productId,
          quantity: line.quantity,
          referenceOperationId: invoiceId,
          userId: request.currentUserId,
          locationId: locationId,
        );
      }
      
      final taxes = Decimal.zero;
      final total = subtotal + taxes; // Total is negative
      
      Decimal paidAmount = Decimal.zero;
      for (final p in request.payments) {
        if (p.method != 'CREDIT') {
          paidAmount += p.amount; // Should we treat this as negative?
        }
      }
      final negativePaidAmount = -paidAmount; // Paid back to customer
      
      final status = 'REFUNDED';
      
      // 5. Update Client Balance (Debt) — skip for walk-in (TEMP) clients
      final debt = total - negativePaidAmount; 
      if (debt.compareTo(Decimal.zero) != 0 && client != null && client.type != 'TEMP') {
        final newBalance = client.balance + debt;
        await _db.update(_db.clients).replace(client.copyWith(
          balance: newBalance,
          updatedAt: DateTime.now(),
        ));
      }
      
      // 6. Create Invoice (Refund type)
      await _db.into(_db.invoices).insert(InvoicesCompanion.insert(
        id: invoiceId,
        documentType: const drift.Value('REFUND'),
        invoiceNumber: invoiceNumber,
        clientId: drift.Value(request.clientId),
        date: date,
        subtotal: subtotal,
        taxes: taxes,
        total: total,
        paidAmount: negativePaidAmount,
        status: status,
      ));
      
      // 7. Create Payments (Refunds)
      for (final p in request.payments) {
        if (p.amount > Decimal.zero || p.method == 'CREDIT') {
          await _db.into(_db.payments).insert(PaymentsCompanion.insert(
            id: _uuid.v4(),
            clientId: drift.Value(request.clientId),
            invoiceId: drift.Value(invoiceId),
            amount: -p.amount, // negative payment out
            method: p.method,
            checkImagePath: drift.Value(p.checkImagePath),
            date: date,
            status: 'CLEARED',
          ));
        }
      }
      
      // 8. Audit Log
      await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
        id: _uuid.v4(),
        userId: request.currentUserId,
        action: 'PROCESS_RETURN',
        entityType: 'INVOICE',
        entityId: invoiceId,
        details: jsonEncode({'total': total.toString(), 'clientId': request.clientId, 'invoiceNumber': invoiceNumber}),
      ));
      
      // 9. Sync Outbox
      await _db.into(_db.syncOutbox).insert(SyncOutboxCompanion.insert(
        id: _uuid.v4(),
        entityType: 'INVOICE',
        entityId: invoiceId,
        operation: 'INSERT',
        payload: jsonEncode({'id': invoiceId, 'status': status}), 
      ));
    });
  }

  Future<void> _restoreStock({
    required String productId, 
    required Decimal quantity,
    required String reason,
    required String referenceOperationId,
    required String userId,
    required String locationId,
  }) async {
    final product = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (product == null) return;
    
    final baseProduct = await getDeterministicBaseProduct(_db, product);
    String targetProductId = baseProduct.id;
    Decimal actualQtyToAdd = convertQuantityToBase(quantity, product, baseProduct);
    
    final balanceQuery = _db.select(_db.stockBalances)..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(locationId));
    final balance = await balanceQuery.getSingleOrNull();
    final currentQty = balance?.quantity ?? Decimal.zero;
    final newQty = currentQty + actualQtyToAdd;
    
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
      quantity: actualQtyToAdd,
      reason: reason,
      referenceOperationId: drift.Value(referenceOperationId),
      createdBy: userId,
    ));
  }

  Future<void> _deductConsumables({
    required String productId,
    required Decimal quantity,
    required String referenceOperationId,
    required String userId,
    required String locationId,
  }) async {
    final reqsQuery = _db.select(_db.productConsumables)
      ..where((t) => t.productId.equals(productId));
    final requirements = await reqsQuery.get();
    
    for (final req in requirements) {
      final totalNeeded = req.quantityRequired * quantity;
      await _deductStock(
        productId: req.consumableId,
        quantity: totalNeeded,
        reason: 'CONSUMPTION',
        referenceOperationId: referenceOperationId,
        userId: userId,
        locationId: locationId,
      );
    }
  }

  Future<void> _restoreConsumables({
    required String productId,
    required Decimal quantity,
    required String referenceOperationId,
    required String userId,
    required String locationId,
  }) async {
    final reqsQuery = _db.select(_db.productConsumables)
      ..where((t) => t.productId.equals(productId));
    final requirements = await reqsQuery.get();
    
    for (final req in requirements) {
      final totalRestored = req.quantityRequired * quantity;
      await _restoreStock(
        productId: req.consumableId,
        quantity: totalRestored,
        reason: 'RETURN_CONSUMPTION',
        referenceOperationId: referenceOperationId,
        userId: userId,
        locationId: locationId,
      );
    }
  }

}