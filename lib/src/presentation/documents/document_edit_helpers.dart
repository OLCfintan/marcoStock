import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/database/app_database.dart';
import '../sales/pos_screen.dart';
import '../purchases/purchases_screen.dart';
import '../../application/sales/sales_service.dart';
import '../../application/purchases/purchase_service.dart';

extension DocumentEditHelper on ConsumerState {
  Future<void> onEditInvoice(InvoiceEntity invoice, ClientEntity? client, AppDatabase db) async {
    final lines = await (db.select(db.invoiceLines)..where((t) => t.invoiceId.equals(invoice.id))).get();
    
    final session = PosSession(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Edit ${invoice.invoiceNumber}');
    session.editingId = invoice.id;
    if (client != null) {
      session.selectedClientId = client.id;
      session.selectedClientName = client.name;
      session.selectedClientTier = client.tier;
    }
    session.selectedDocumentType = invoice.documentType;
    
    session.cart = lines.map((l) => SaleLineRequest(
      productId: l.productId,
      quantity: l.quantity,
      unitPrice: l.unitPrice,
      discount: l.discount,
    )).toList();
    
    session.payments.clear();
    
    if (invoice.invoiceNumber != null) session.invoiceCounterController.text = invoice.invoiceNumber;;
    if (invoice.clientNameOverride != null) session.customNameController.text = invoice.clientNameOverride!;
    if (invoice.clientIceOverride != null) session.customIceController.text = invoice.clientIceOverride!;

    globalPosSessions.add(session);
    globalPosActiveSessionIndex = globalPosSessions.length - 1;
    
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen()));
    }
  }

  Future<void> onEditPurchase(PurchaseEntity purchase, SupplierEntity? supplier, AppDatabase db) async {
    final lines = await (db.select(db.purchaseLines)..where((t) => t.purchaseId.equals(purchase.id))).get();
    
    final session = PurchaseSession(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Edit ${purchase.purchaseNumber}');
    session.editingId = purchase.id;
    if (supplier != null) {
      session.selectedSupplierId = supplier.id;
      session.selectedSupplierName = supplier.name;
    }
    
    session.cart = lines.map((l) => PurchaseLineRequest(
      productId: l.productId,
      quantity: l.quantity,
      unitPrice: l.unitPrice,
    )).toList();
    
    session.payments.clear();
    
    globalPurchaseSessions.add(session);
    globalPurchaseActiveSessionIndex = globalPurchaseSessions.length - 1;
    
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesScreen()));
    }
  }
}
