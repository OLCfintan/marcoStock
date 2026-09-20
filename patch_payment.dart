import 'dart:io';

def = """
  /// Algebraically allocates a payment to the oldest unpaid invoices/purchases (FIFO).
  Future<void> allocatePayment({
    String? clientId,
    String? supplierId,
    String? employeeId,
    required Decimal amount,
    required String method,
    String? checkImagePath,
    String? userId,
  }) async {
    await _db.transaction(() async {
      final paymentId = const Uuid().v4();
      
      // 1. Employee Payment
      if (employeeId != null) {
        final emp = await (_db.select(_db.employees)..where((t) => t.id.equals(employeeId))).getSingleOrNull();
        if (emp != null) {
          await _db.update(_db.employees).replace(emp.copyWith(remainingSalary: emp.remainingSalary - amount));
          await _db.into(_db.payments).insert(PaymentsCompanion.insert(
            id: paymentId,
            employeeId: drift.Value(employeeId),
            amount: amount,
            method: method,
            checkImagePath: drift.Value(checkImagePath),
            date: DateTime.now(),
            status: 'CLEARED',
          ));
        }
        return;
      }

      // 2. Client Payment (FIFO Allocation)
      if (clientId != null) {
        final client = await (_db.select(_db.clients)..where((t) => t.id.equals(clientId))).getSingleOrNull();
        if (client != null && client.type != 'TEMP') {
          // Update client balance
          await _db.update(_db.clients).replace(client.copyWith(balance: client.balance - amount));
          
          // FIFO Allocation to Invoices
          Decimal remainingToAllocate = amount;
          
          final unpaidInvoices = await (_db.select(_db.invoices)
            ..where((t) => t.clientId.equals(clientId) & t.isActive.equals(true) & t.status.isNotIn(['PAID', 'CANCELLED']))
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
          
          // Record Payment (we don't link to a single invoiceId because it may span multiple)
          await _db.into(_db.payments).insert(PaymentsCompanion.insert(
            id: paymentId,
            clientId: drift.Value(clientId),
            amount: amount,
            method: method,
            checkImagePath: drift.Value(checkImagePath),
            date: DateTime.now(),
            status: 'CLEARED',
          ));
        }
        return;
      }

      // 3. Supplier Payment (FIFO Allocation)
      if (supplierId != null) {
        final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(supplierId))).getSingleOrNull();
        if (supplier != null) {
          // Update supplier balance
          await _db.update(_db.suppliers).replace(supplier.copyWith(balance: supplier.balance - amount));
          
          // FIFO Allocation to Purchases
          Decimal remainingToAllocate = amount;
          
          final unpaidPurchases = await (_db.select(_db.purchases)
            ..where((t) => t.supplierId.equals(supplierId) & t.isActive.equals(true) & t.status.isNotIn(['PAID', 'CANCELLED']))
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
          
          await _db.into(_db.payments).insert(PaymentsCompanion.insert(
            id: paymentId,
            supplierId: drift.Value(supplierId),
            amount: amount,
            method: method,
            checkImagePath: drift.Value(checkImagePath),
            date: DateTime.now(),
            status: 'CLEARED',
          ));
        }
        return;
      }
    });
  }
"""

with open('lib/src/application/payments/payment_service.dart', 'r') as f:
    content = f.read()

# Add Uuid import if missing
if "package:uuid/uuid.dart" not in content:
    content = "import 'package:uuid/uuid.dart';\n" + content

# Insert allocatePayment right after constructor
content = content.replace('PaymentService(this._db);', 'PaymentService(this._db);\n\n' + def)

with open('lib/src/application/payments/payment_service.dart', 'w') as f:
    f.write(content)
