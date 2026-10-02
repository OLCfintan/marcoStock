import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/database/app_database.dart';
import '../sales/pos_screen.dart';
import '../../application/sales/sales_service.dart';

extension InvoiceEditHelper on ConsumerState {
  Future<void> onEditInvoice(InvoiceData invoice, ClientEntity? client, AppDatabase db) async {
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
    
    if (invoice.customInvoiceNumber != null) session.invoiceCounterController.text = invoice.customInvoiceNumber!;
    if (invoice.clientNameOverride != null) session.customNameController.text = invoice.clientNameOverride!;
    if (invoice.clientIceOverride != null) session.customIceController.text = invoice.clientIceOverride!;

    globalPosSessions.add(session);
    globalPosActiveSessionIndex = globalPosSessions.length - 1;
    
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen()));
    }
  }
}
