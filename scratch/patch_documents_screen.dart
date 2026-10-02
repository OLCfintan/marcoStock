import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../../infrastructure/database/app_database.dart';
import '../../application/sales/sales_service.dart';
import '../../application/purchases/purchase_service.dart';
import '../sales/pos_screen.dart';
import '../purchases/purchases_screen.dart';

extension EditDocumentExtension on ConsumerState {
  Future<void> editInvoice(InvoicesCompanion invoice, String clientId, String? clientName, String? clientTier, AppDatabase db) async {
    final invoiceId = invoice.id.value;
    final lines = await (db.select(db.invoiceLines)..where((t) => t.invoiceId.equals(invoiceId))).get();
    
    final session = PosSession(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Edit ${invoice.invoiceNumber.value}');
    session.editingId = invoiceId;
    session.selectedClientId = clientId;
    session.selectedClientName = clientName;
    session.selectedClientTier = clientTier;
    session.selectedDocumentType = invoice.documentType.value;
    
    session.cart = lines.map((l) => SaleLineRequest(
      productId: l.productId,
      quantity: l.quantity,
      unitPrice: l.unitPrice,
      discount: l.discount,
    )).toList();
    
    // clear default payment
    session.payments.clear();
    
    if (invoice.customInvoiceNumber.present) session.invoiceCounterController.text = invoice.customInvoiceNumber.value ?? '';
    if (invoice.clientNameOverride.present) session.customNameController.text = invoice.clientNameOverride.value ?? '';
    if (invoice.clientIceOverride.present) session.customIceController.text = invoice.clientIceOverride.value ?? '';

    globalPosSessions.add(session);
    globalPosActiveSessionIndex = globalPosSessions.length - 1;
    
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen()));
    }
  }

  Future<void> editPurchase(PurchasesCompanion purchase, String supplierId, String? supplierName, AppDatabase db) async {
    final purchaseId = purchase.id.value;
    final lines = await (db.select(db.purchaseLines)..where((t) => t.purchaseId.equals(purchaseId))).get();
    
    final session = PurchaseSession(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Edit ${purchase.purchaseNumber.value}');
    session.editingId = purchaseId;
    session.selectedSupplierId = supplierId;
    session.selectedSupplierName = supplierName;
    
    session.cart = lines.map((l) => PurchaseLineRequest(
      productId: l.productId,
      quantity: l.quantity,
      unitPrice: l.unitPrice,
    )).toList();
    
    // clear default payment
    session.payments.clear();
    
    globalPurchaseSessions.add(session);
    globalPurchaseActiveSessionIndex = globalPurchaseSessions.length - 1;
    
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesScreen()));
    }
  }
}
