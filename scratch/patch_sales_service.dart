import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;

import '../../infrastructure/database/app_database.dart';
import '../../domain/constants/locations.dart';

extension UpdateSale on SalesService {
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
