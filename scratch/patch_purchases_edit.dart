import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/database/app_database.dart';
import '../purchases/purchases_screen.dart';
import '../../application/purchases/purchase_service.dart';

extension PurchaseEditHelper on ConsumerState {
  Future<void> onEditPurchase(PurchaseData purchase, SupplierData? supplier, AppDatabase db) async {
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
