import re

with open('lib/src/application/payments/payment_service.dart', 'r') as f:
    content = f.read()

old_delete = """      // 3. Reverse Client Balance (Add debt back)
      if (payment.clientId != null) {
        final client = await (_db.select(_db.clients)..where((t) => t.id.equals(payment.clientId!))).getSingleOrNull();
        if (client != null && client.type != 'TEMP') {
          await _db.update(_db.clients).replace(client.copyWith(balance: client.balance + payment.amount));
        }
      }"""

new_delete = """      // 3. Reverse Client Balance (Add debt back) & LIFO De-allocation
      if (payment.clientId != null) {
        final client = await (_db.select(_db.clients)..where((t) => t.id.equals(payment.clientId!))).getSingleOrNull();
        if (client != null && client.type != 'TEMP') {
          await _db.update(_db.clients).replace(client.copyWith(balance: client.balance + payment.amount));
          
          if (payment.invoiceId == null) {
            // LIFO De-allocation: We take away paid amount from the NEWEST paid invoices
            Decimal remainingToReverse = payment.amount;
            final paidInvoices = await (_db.select(_db.invoices)
              ..where((t) => t.clientId.equals(payment.clientId!) & t.isActive.equals(true) & t.paidAmount.isBiggerThanValue(Decimal.zero))
              ..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])
            ).get();

            for (final inv in paidInvoices) {
              if (remainingToReverse <= Decimal.zero) break;
              
              final reversal = remainingToReverse > inv.paidAmount ? inv.paidAmount : remainingToReverse;
              final newPaid = inv.paidAmount - reversal;
              final newStatus = newPaid >= inv.total ? 'PAID' : (newPaid > Decimal.zero ? 'PARTIAL' : 'UNPAID');
              
              await (_db.update(_db.invoices)..where((t) => t.id.equals(inv.id))).write(
                InvoicesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
              );
              remainingToReverse -= reversal;
            }
          }
        }
      }"""

content = content.replace(old_delete, new_delete)

old_delete_sup = """      // 4. Reverse Supplier Balance (Add debt back)
      if (payment.supplierId != null) {
        final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(payment.supplierId!))).getSingleOrNull();
        if (supplier != null) {
          await _db.update(_db.suppliers).replace(supplier.copyWith(balance: supplier.balance + payment.amount));
        }
      }"""

new_delete_sup = """      // 4. Reverse Supplier Balance (Add debt back) & LIFO De-allocation
      if (payment.supplierId != null) {
        final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(payment.supplierId!))).getSingleOrNull();
        if (supplier != null) {
          await _db.update(_db.suppliers).replace(supplier.copyWith(balance: supplier.balance + payment.amount));
          
          if (payment.purchaseId == null) {
            Decimal remainingToReverse = payment.amount;
            final paidPurchases = await (_db.select(_db.purchases)
              ..where((t) => t.supplierId.equals(payment.supplierId!) & t.isActive.equals(true) & t.paidAmount.isBiggerThanValue(Decimal.zero))
              ..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])
            ).get();

            for (final pur in paidPurchases) {
              if (remainingToReverse <= Decimal.zero) break;
              
              final reversal = remainingToReverse > pur.paidAmount ? pur.paidAmount : remainingToReverse;
              final newPaid = pur.paidAmount - reversal;
              final newStatus = newPaid >= pur.total ? 'PAID' : (newPaid > Decimal.zero ? 'PARTIAL' : 'UNPAID');
              
              await (_db.update(_db.purchases)..where((t) => t.id.equals(pur.id))).write(
                PurchasesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
              );
              remainingToReverse -= reversal;
            }
          }
        }
      }"""

content = content.replace(old_delete_sup, new_delete_sup)

with open('lib/src/application/payments/payment_service.dart', 'w') as f:
    f.write(content)
