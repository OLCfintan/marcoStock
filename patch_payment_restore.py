import re

with open('lib/src/application/payments/payment_service.dart', 'r') as f:
    content = f.read()

old_restore = """      // 3. Re-apply Client Balance (Deduct debt)
      if (payment.clientId != null) {
        final client = await (_db.select(_db.clients)..where((t) => t.id.equals(payment.clientId!))).getSingleOrNull();
        if (client != null && client.type != 'TEMP') {
          await _db.update(_db.clients).replace(client.copyWith(balance: client.balance - payment.amount));
        }
      }"""

new_restore = """      // 3. Re-apply Client Balance (Deduct debt) & FIFO Re-allocation
      if (payment.clientId != null) {
        final client = await (_db.select(_db.clients)..where((t) => t.id.equals(payment.clientId!))).getSingleOrNull();
        if (client != null && client.type != 'TEMP') {
          await _db.update(_db.clients).replace(client.copyWith(balance: client.balance - payment.amount));
          
          if (payment.invoiceId == null) {
            Decimal remainingToAllocate = payment.amount;
            final unpaidInvoices = await (_db.select(_db.invoices)
              ..where((t) => t.clientId.equals(payment.clientId!) & t.isActive.equals(true) & t.status.isNotIn(['PAID', 'CANCELLED']))
              ..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.asc)])
            ).get();

            for (final inv in unpaidInvoices) {
              if (remainingToAllocate <= Decimal.zero) break;
              final invoiceDebt = inv.total - inv.paidAmount;
              final allocation = remainingToAllocate > invoiceDebt ? invoiceDebt : remainingToAllocate;
              final newPaid = inv.paidAmount + allocation;
              final newStatus = newPaid >= inv.total ? 'PAID' : 'PARTIAL';
              
              await (_db.update(_db.invoices)..where((t) => t.id.equals(inv.id))).write(
                InvoicesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
              );
              remainingToAllocate -= allocation;
            }
          }
        }
      }"""

content = content.replace(old_restore, new_restore)

old_restore_sup = """      // 4. Re-apply Supplier Balance (Deduct debt)
      if (payment.supplierId != null) {
        final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(payment.supplierId!))).getSingleOrNull();
        if (supplier != null) {
          await _db.update(_db.suppliers).replace(supplier.copyWith(balance: supplier.balance - payment.amount));
        }
      }"""

new_restore_sup = """      // 4. Re-apply Supplier Balance (Deduct debt) & FIFO Re-allocation
      if (payment.supplierId != null) {
        final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(payment.supplierId!))).getSingleOrNull();
        if (supplier != null) {
          await _db.update(_db.suppliers).replace(supplier.copyWith(balance: supplier.balance - payment.amount));
          
          if (payment.purchaseId == null) {
            Decimal remainingToAllocate = payment.amount;
            final unpaidPurchases = await (_db.select(_db.purchases)
              ..where((t) => t.supplierId.equals(payment.supplierId!) & t.isActive.equals(true) & t.status.isNotIn(['PAID', 'CANCELLED']))
              ..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.asc)])
            ).get();

            for (final pur in unpaidPurchases) {
              if (remainingToAllocate <= Decimal.zero) break;
              final purchaseDebt = pur.total - pur.paidAmount;
              final allocation = remainingToAllocate > purchaseDebt ? purchaseDebt : remainingToAllocate;
              final newPaid = pur.paidAmount + allocation;
              final newStatus = newPaid >= pur.total ? 'PAID' : 'PARTIAL';
              
              await (_db.update(_db.purchases)..where((t) => t.id.equals(pur.id))).write(
                PurchasesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
              );
              remainingToAllocate -= allocation;
            }
          }
        }
      }"""

content = content.replace(old_restore_sup, new_restore_sup)

with open('lib/src/application/payments/payment_service.dart', 'w') as f:
    f.write(content)
