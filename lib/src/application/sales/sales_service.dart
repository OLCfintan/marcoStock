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
  final String? customInvoiceNumber;
  final DateTime? customDate;
  final String? customClientName;
  final String? customClientIce;
  final String companyBranch;
  
  SaleRequest({
    this.documentType = 'FACTURE',
    required this.clientId,
    required this.currentUserId,
    required this.lines,
    this.payments = const [],
    this.customInvoiceNumber,
    this.customDate,
    this.customClientName,
    this.customClientIce,
    this.companyBranch = 'MARKO_GROUP',
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

class InsufficientStockException implements Exception {
  final String productName;
  final String available;
  final String requested;

  InsufficientStockException({
    required this.productName,
    required this.available,
    required this.requested,
  });

  @override
  String toString() {
    return 'Insufficient stock for "$productName".\nAvailable: $available\nRequested: $requested';
  }
}

class SalesService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  SalesService(this._db);
  
    Future<String> getNextCustomInvoiceNumber(String prefix) async {
    final result = await _db.customSelect(
      "SELECT invoice_number FROM invoices WHERE invoice_number LIKE '$prefix%'",
    ).get();

    int maxNum = 0;
    for (final row in result) {
      final str = row.read<String>('invoice_number');
      if (str.length > prefix.length) {
        final numPart = str.substring(prefix.length);
        final cleanNum = numPart.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanNum.isNotEmpty) {
          final num = int.tryParse(cleanNum) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
    }
    
    if (maxNum > 0) {
      return '$prefix${maxNum + 1}';
    }
    return '${prefix}1';
  }

  /// Executes a sale atomically.
  /// Handles: Invoices, Lines, Stock, Consumables, Payments, Audit, Sync, and Client Balances.
  Future<void> executeSale(SaleRequest request) async {
    await _db.transaction(() async {
      final client = await (_db.select(_db.clients)..where((t) => t.id.equals(request.clientId))).getSingleOrNull();
      final locationId = (client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01') ? AppLocations.baseWarehouse : AppLocations.magazin;

      final invoiceId = _uuid.v4();
      final date = request.customDate ?? DateTime.now();
      
      // 1. Generate Formal Invoice Number
      String invoiceNumber = '';
      if (request.documentType == 'FACTURE' && request.customInvoiceNumber != null && request.customInvoiceNumber!.isNotEmpty) {
        invoiceNumber = request.customInvoiceNumber!;
      } else if (request.documentType == 'FACTURE' || request.documentType == 'FACTURE_DUMMY') {
        final settings = await _db.customSelect('SELECT value FROM settings WHERE key = ?', variables: [drift.Variable.withString('invoiceCounterPrefix')]).getSingleOrNull();
        final prefixSetting = settings?.read<String>('value') ?? 'MG';
        invoiceNumber = await getNextCustomInvoiceNumber(prefixSetting);
      } else {
        final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        String prefix = '';
        if (request.documentType == 'BON') prefix = 'BON-$yearMonth';
        else if (request.documentType == 'COMMANDE') prefix = 'CMD-$yearMonth';
        else prefix = 'FAC-$yearMonth';
        
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
        invoiceNumber = '$prefix-${nextNum.toString().padLeft(4, '0')}';
      }
      
      Decimal subtotal = Decimal.zero;

      // 2. Create Invoice Lines & Compute Totals
      bool isDummyDoc = request.documentType == 'COMMANDE' || request.documentType == 'FACTURE' || request.documentType == 'FACTURE_DUMMY';

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
        
        if (!isDummyDoc) {
          // 3. Handle Stock Deduction
          await _deductStock(
            productId: line.productId, 
            quantity: line.quantity, 
            reason: 'SALE',
            referenceOperationId: invoiceId,
            userId: request.currentUserId,
            locationId: locationId,
          );
          
          if (client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01') {
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
      }
      
      final taxes = Decimal.zero;
      final total = subtotal + taxes;
      Decimal paidAmount = Decimal.zero;
      
      if (!isDummyDoc) {
        for (final p in request.payments) {
          if (p.method != 'CREDIT') {
            paidAmount += p.amount;
          }
        }
      }
      
      final status = isDummyDoc
          ? 'PENDING' 
          : (paidAmount >= total ? 'PAID' : (paidAmount > Decimal.zero ? 'PARTIAL' : 'UNPAID'));
      
      // 5. Update Client Balance (Debt)
      if (!isDummyDoc) {
        final debt = total - paidAmount;
        if (debt > Decimal.zero && client != null && client.type != 'TEMP') {
          final newBalance = client.balance + debt;
          await _db.update(_db.clients).replace(client.copyWith(
            balance: newBalance,
            updatedAt: DateTime.now(),
          ));
        }
      }
      
      // 6. Create Invoice
      await _db.into(_db.invoices).insert(InvoicesCompanion.insert(
        id: invoiceId,
        documentType: drift.Value(request.documentType),
        invoiceNumber: invoiceNumber,
        clientId: drift.Value(request.clientId),
        clientNameOverride: drift.Value(request.customClientName),
        clientIceOverride: drift.Value(request.customClientIce),
        date: date,
        subtotal: subtotal,
        taxes: taxes,
        total: total,
        paidAmount: paidAmount,
        status: status,
        companyBranch: drift.Value(request.companyBranch),
        paymentMethod: drift.Value(request.payments.isNotEmpty ? request.payments.first.method : null),
      ));
      
      // 7. Create Payments
      if (!isDummyDoc) {
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
      final locationId = (client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01') ? AppLocations.baseWarehouse : AppLocations.magazin;

      if (invoice.documentType != 'COMMANDE' && invoice.documentType != 'FACTURE_DUMMY' && invoice.documentType != 'FACTURE') {
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

          // If it was a Magazin or Special client (transfer), reverse the inbound to Magazin
          if (client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01') {
            await _deductStock(
              productId: line.productId,
              quantity: line.quantity,
              reason: 'TRANSFER_REVERSED',
              allowNegative: true,
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
        if (debtAdded.compareTo(Decimal.zero) != 0 && client != null && client.type != 'TEMP') {
          final newBalance = client.balance - debtAdded;
          await _db.update(_db.clients).replace(client.copyWith(balance: newBalance));
        }
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
      final locationId = (client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01') ? AppLocations.baseWarehouse : AppLocations.magazin;

      if (invoice.documentType != 'COMMANDE' && invoice.documentType != 'FACTURE_DUMMY' && invoice.documentType != 'FACTURE') {
        for (final line in lines) {
          // Re-apply Stock Deduction
          await _deductStock(
            productId: line.productId,
            quantity: line.quantity,
            reason: 'SALE_RESTORED',
            allowNegative: true,
            referenceOperationId: invoiceId,
            userId: userId,
            locationId: locationId,
          );

          // Re-apply Magazin transfer if Magazin or Special client
          if (client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01') {
            await _restoreStock(
              productId: line.productId,
              quantity: line.quantity,
              reason: 'TRANSFER_IN_RESTORED',
              referenceOperationId: invoiceId,
              userId: userId,
              locationId: AppLocations.magazin,
            );
          }

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
        if (debtAdded.compareTo(Decimal.zero) != 0 && client != null && client.type != 'TEMP') {
          final newBalance = client.balance + debtAdded;
          await _db.update(_db.clients).replace(client.copyWith(balance: newBalance));
        }
      }

      // Mark Invoice as Active
      await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId))).write(
        const InvoicesCompanion(isActive: drift.Value(true))
      );
    });
  }

  /// Converts a BON to a FACTURE (Invoice). Generates a new dummy invoice.
  Future<void> convertBonToInvoice(String invoiceId, {String? customInvoiceNumber, DateTime? customDate, String? customName, String? customIce}) async {
    await _db.transaction(() async {
      final bon = await (_db.select(_db.invoices)..where((t) => t.id.equals(invoiceId))).getSingleOrNull();
      if (bon == null || bon.documentType != 'BON') return;

      final date = customDate ?? DateTime.now();
      String invoiceNumber = '';
      
            if (customInvoiceNumber != null && customInvoiceNumber.isNotEmpty) {
        invoiceNumber = customInvoiceNumber;
      } else {
        final settings = await _db.customSelect('SELECT value FROM settings WHERE key = ?', variables: [drift.Variable.withString('invoiceCounterPrefix')]).getSingleOrNull();
        final prefixSetting = settings?.read<String>('value') ?? 'MG';
        invoiceNumber = await getNextCustomInvoiceNumber(prefixSetting);
      }

      final newInvoiceId = _uuid.v4();
      
      await _db.into(_db.invoices).insert(InvoicesCompanion.insert(
        id: newInvoiceId,
        documentType: const drift.Value('FACTURE_DUMMY'),
        invoiceNumber: invoiceNumber,
        clientId: drift.Value(bon.clientId),
        clientNameOverride: drift.Value(customName),
        clientIceOverride: drift.Value(customIce),
        date: date,
        subtotal: bon.subtotal,
        taxes: bon.taxes,
        total: bon.total,
        paidAmount: Decimal.zero,
        status: 'UNPAID',
        notes: drift.Value('Converted from BON: ${bon.invoiceNumber}'),
      ));

      final lines = await (_db.select(_db.invoiceLines)..where((t) => t.invoiceId.equals(bon.id))).get();
      for (final line in lines) {
        await _db.into(_db.invoiceLines).insert(InvoiceLinesCompanion.insert(
          id: _uuid.v4(),
          invoiceId: newInvoiceId,
          productId: line.productId,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          discount: line.discount,
          lineTotal: line.lineTotal,
        ));
      }

      await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
        id: _uuid.v4(),
        userId: 'SYSTEM',
        action: 'CONVERT_BON',
        entityType: 'INVOICE',
        entityId: newInvoiceId,
        details: jsonEncode({'sourceBonId': bon.id, 'newNumber': invoiceNumber}),
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
    bool allowNegative = false,
  }) async {
    final settingsResult = await _db.customSelect("SELECT value FROM settings WHERE key = 'stockEngineEnabled'").getSingleOrNull();
    final stockEngineEnabled = settingsResult == null || settingsResult.read<String>('value') == 'true';
    if (!stockEngineEnabled) return;

    final product = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (product == null) return;
    
    final trackingInfo = await getStockTrackingInfo(_db, product, quantity, locationId);
    String targetProductId = trackingInfo.productId;
    Decimal actualQuantityToDeduct = trackingInfo.quantity;
    
    final balanceQuery = _db.select(_db.stockBalances)..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(locationId));
    final balance = await balanceQuery.getSingleOrNull();
    final currentQty = balance?.quantity ?? Decimal.zero;
    
    // Prevent selling stock we don't have, unless we are reversing an operation
    if (!allowNegative && currentQty < actualQuantityToDeduct) {
        final productQuery = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingleOrNull();
        final productName = productQuery?.name ?? 'Unknown Product';
        throw InsufficientStockException(
          productName: productName,
          available: currentQty.toStringAsFixed(2),
          requested: actualQuantityToDeduct.toStringAsFixed(2),
        );
    }
    
    // Mathematically preserve exact balances
    final newQty = currentQty - actualQuantityToDeduct;
    
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
      final locationId = (client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01') ? AppLocations.baseWarehouse : AppLocations.magazin;

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
        

        // If Magazin or Special client is returning goods to base, deduct from Magazin
        if (client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01') {
          await _deductStock(
            productId: line.productId,
            quantity: line.quantity,
            reason: 'RETURN_TRANSFER_OUT',
            allowNegative: true,
            referenceOperationId: invoiceId,
            userId: request.currentUserId,
            locationId: AppLocations.magazin,
          );
        }
        
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

      // 6.5 Cross-cancel return credit with older unpaid invoices
      if (debt < Decimal.zero && request.clientId != null && client?.type != 'TEMP') {
        Decimal creditToApply = -debt;
        final unpaidInvoices = await (_db.select(_db.invoices)
          ..where((t) => t.clientId.equals(request.clientId!) & t.isActive.equals(true) & t.status.isNotIn(['PAID', 'CANCELLED']) & t.id.isNotValue(invoiceId))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.asc)])
        ).get();

        for (final inv in unpaidInvoices) {
          if (creditToApply <= Decimal.zero) break;
          if (inv.total <= Decimal.zero) continue;
          
          final invoiceDebt = inv.total - inv.paidAmount;
          if (invoiceDebt <= Decimal.zero) continue;
          
          final allocation = creditToApply > invoiceDebt ? invoiceDebt : creditToApply;
          final newPaid = inv.paidAmount + allocation;
          final newStatus = newPaid >= inv.total ? 'PAID' : 'PARTIAL';
          
          await (_db.update(_db.invoices)..where((t) => t.id.equals(inv.id))).write(
            InvoicesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
          );
          creditToApply -= allocation;
        }

        final appliedCredit = (-debt) - creditToApply;
        if (appliedCredit > Decimal.zero) {
          final returnInvoicePaidAmount = negativePaidAmount - appliedCredit;
          await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId))).write(
            InvoicesCompanion(paidAmount: drift.Value(returnInvoicePaidAmount))
          );
        }
      }
      
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
    final settingsResult = await _db.customSelect("SELECT value FROM settings WHERE key = 'stockEngineEnabled'").getSingleOrNull();
    final stockEngineEnabled = settingsResult == null || settingsResult.read<String>('value') == 'true';
    if (!stockEngineEnabled) return;

    final product = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (product == null) return;
    
    final trackingInfo = await getStockTrackingInfo(_db, product, quantity, locationId);
    String targetProductId = trackingInfo.productId;
    Decimal actualQtyToAdd = trackingInfo.quantity;
    
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
        allowNegative: true,
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



  Future<void> updateSale(SaleRequest request, String existingInvoiceId) async {
    await _db.transaction(() async {
      final invoice = await (_db.select(_db.invoices)..where((t) => t.id.equals(existingInvoiceId))).getSingleOrNull();
      if (invoice == null) return;
      
      final oldLines = await (_db.select(_db.invoiceLines)..where((t) => t.invoiceId.equals(existingInvoiceId))).get();
      ClientEntity? client;
      if (invoice.clientId != null) {
        client = await (_db.select(_db.clients)..where((t) => t.id.equals(invoice.clientId!))).getSingleOrNull();
      }
      final locationId = (client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01') ? AppLocations.baseWarehouse : AppLocations.magazin;

      // Reverse old lines
      if (invoice.documentType != 'COMMANDE' && invoice.documentType != 'FACTURE_DUMMY' && invoice.documentType != 'FACTURE') {
        for (final line in oldLines) {
          await _restoreStock(
            productId: line.productId,
            quantity: line.quantity,
            reason: 'SALE_UPDATED_REVERSE',
            referenceOperationId: existingInvoiceId,
            userId: request.currentUserId,
            locationId: locationId,
          );

          if (client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01') {
            await _deductStock(
              productId: line.productId,
              quantity: line.quantity,
              reason: 'TRANSFER_REVERSED_UPDATE',
              allowNegative: true,
              referenceOperationId: existingInvoiceId,
              userId: request.currentUserId,
              locationId: AppLocations.magazin,
            );
          }

          await _restoreConsumables(
            productId: line.productId,
            quantity: line.quantity,
            referenceOperationId: existingInvoiceId,
            userId: request.currentUserId,
            locationId: locationId,
          );
        }

        final oldDebtAdded = invoice.total - invoice.paidAmount;
        if (oldDebtAdded > Decimal.zero && client != null && client.type != 'TEMP') {
          final newBalance = client.balance - oldDebtAdded;
          await _db.update(_db.clients).replace(client.copyWith(balance: newBalance));
        }
      }

      // Delete old lines
      await (_db.delete(_db.invoiceLines)..where((t) => t.invoiceId.equals(existingInvoiceId))).go();

      // Apply new lines
      Decimal subtotal = Decimal.zero;
      bool isDummyDoc = invoice.documentType == 'COMMANDE' || invoice.documentType == 'FACTURE' || invoice.documentType == 'FACTURE_DUMMY';

      for (final line in request.lines) {
        final lineId = _uuid.v4();
        final lineTotal = (line.quantity * line.unitPrice) - line.discount;
        subtotal += lineTotal;
        
        await _db.into(_db.invoiceLines).insert(InvoiceLinesCompanion.insert(
          id: lineId,
          invoiceId: existingInvoiceId,
          productId: line.productId,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          discount: line.discount,
          lineTotal: lineTotal,
        ));
        
        if (!isDummyDoc) {
          await _deductStock(
            productId: line.productId, 
            quantity: line.quantity, 
            reason: 'SALE_UPDATED',
            referenceOperationId: existingInvoiceId,
            userId: request.currentUserId,
            locationId: locationId,
          );
          
          if (client?.type == 'MAGAZIN' || client?.type == 'SPECIAL' || client?.id == 'MAGAZIN_01') {
            await _restoreStock(
              productId: line.productId,
              quantity: line.quantity,
              reason: 'TRANSFER_IN_UPDATED',
              referenceOperationId: existingInvoiceId,
              userId: request.currentUserId,
              locationId: AppLocations.magazin,
            );
          }
          
          await _deductConsumables(
            productId: line.productId,
            quantity: line.quantity,
            referenceOperationId: existingInvoiceId,
            userId: request.currentUserId,
            locationId: locationId,
          );
        }
      }

      final taxes = Decimal.zero;
      final total = subtotal + taxes;
      
      final status = isDummyDoc
          ? 'PENDING' 
          : (invoice.paidAmount >= total ? 'PAID' : (invoice.paidAmount > Decimal.zero ? 'PARTIAL' : 'UNPAID'));
          
      if (!isDummyDoc) {
        final newDebt = total - invoice.paidAmount;
        if (newDebt > Decimal.zero && client != null && client.type != 'TEMP') {
          // get the updated client object if we changed it above
          final updatedClient = await (_db.select(_db.clients)..where((t) => t.id.equals(client!.id))).getSingle();
          final newBalance = updatedClient.balance + newDebt;
          await _db.update(_db.clients).replace(updatedClient.copyWith(
            balance: newBalance,
            updatedAt: DateTime.now(),
          ));
        }
      }
      
      await _db.update(_db.invoices).replace(invoice.copyWith(
        subtotal: subtotal,
        total: total,
        status: status,
      ));
      
      await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
        id: _uuid.v4(),
        userId: request.currentUserId,
        action: 'UPDATE_SALE',
        entityType: 'INVOICE',
        entityId: existingInvoiceId,
        details: jsonEncode({'total': total.toString(), 'clientId': request.clientId}),
      ));
    });
  }
}
