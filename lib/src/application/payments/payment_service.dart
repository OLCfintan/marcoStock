import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.watch(databaseProvider));
});

class PaymentService {
  final AppDatabase _db;

  PaymentService(this._db);

  /// Algebraically allocates a payment to the oldest unpaid invoices/purchases (FIFO).
  Future<void> allocatePayment({
    String? clientId,
    String? supplierId,
    String? employeeId,
    required Decimal amount,
    required String method,
    String? checkImagePath,
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


  /// Algebraically deletes a payment, reversing its effect on invoices/purchases and entity balances.
  Future<void> deletePayment(String paymentId) async {
    await _db.transaction(() async {
      final payment = await (_db.select(_db.payments)..where((t) => t.id.equals(paymentId))).getSingleOrNull();
      if (payment == null || !payment.isActive) return;

      // 1. Reverse Invoice Logic
      if (payment.invoiceId != null) {
        final invoice = await (_db.select(_db.invoices)..where((t) => t.id.equals(payment.invoiceId!))).getSingleOrNull();
        if (invoice != null) {
          final newPaid = invoice.paidAmount - payment.amount;
          String newStatus = 'UNPAID';
          if (newPaid >= invoice.total) {
            newStatus = 'PAID';
          } else if (newPaid > Decimal.zero) {
            newStatus = 'PARTIAL';
          }
          await (_db.update(_db.invoices)..where((t) => t.id.equals(invoice.id))).write(
            InvoicesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
          );
        }
      }

      // 2. Reverse Purchase Logic
      if (payment.purchaseId != null) {
        final purchase = await (_db.select(_db.purchases)..where((t) => t.id.equals(payment.purchaseId!))).getSingleOrNull();
        if (purchase != null) {
          final newPaid = purchase.paidAmount - payment.amount;
          String newStatus = 'UNPAID';
          if (newPaid >= purchase.total) {
            newStatus = 'PAID';
          } else if (newPaid > Decimal.zero) {
            newStatus = 'PARTIAL';
          }
          await (_db.update(_db.purchases)..where((t) => t.id.equals(purchase.id))).write(
            PurchasesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
          );
        }
      }

      // 3. Reverse Client Balance (Add debt back) & LIFO De-allocation
      if (payment.clientId != null) {
        final client = await (_db.select(_db.clients)..where((t) => t.id.equals(payment.clientId!))).getSingleOrNull();
        if (client != null && client.type != 'TEMP') {
          await _db.update(_db.clients).replace(client.copyWith(balance: client.balance + payment.amount));
          
          if (payment.invoiceId == null) {
            // LIFO De-allocation: We take away paid amount from the NEWEST paid invoices
            Decimal remainingToReverse = payment.amount;
            final paidInvoices = await (_db.select(_db.invoices)
              ..where((t) => t.clientId.equals(payment.clientId!) & t.isActive.equals(true))
              ..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])
            ).get();

            for (final inv in paidInvoices) {
              if (inv.paidAmount <= Decimal.zero) continue;
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
      }

      // 4. Reverse Supplier Balance (Add debt back) & LIFO De-allocation
      if (payment.supplierId != null) {
        final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(payment.supplierId!))).getSingleOrNull();
        if (supplier != null) {
          await _db.update(_db.suppliers).replace(supplier.copyWith(balance: supplier.balance + payment.amount));
          
          if (payment.purchaseId == null) {
            Decimal remainingToReverse = payment.amount;
            final paidPurchases = await (_db.select(_db.purchases)
              ..where((t) => t.supplierId.equals(payment.supplierId!) & t.isActive.equals(true))
              ..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])
            ).get();

            for (final pur in paidPurchases) {
              if (pur.paidAmount <= Decimal.zero) continue;
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
      }

      // 5. Reverse Employee Balance
      if (payment.employeeId != null) {
        final emp = await (_db.select(_db.employees)..where((t) => t.id.equals(payment.employeeId!))).getSingleOrNull();
        if (emp != null) {
          await _db.update(_db.employees).replace(emp.copyWith(remainingSalary: emp.remainingSalary + payment.amount));
        }
      }

      // 6. Mark as deleted
      await (_db.update(_db.payments)..where((t) => t.id.equals(paymentId))).write(
        const PaymentsCompanion(isActive: drift.Value(false))
      );
    });
  }

  /// Algebraically restores a payment from the trash, reapplying its effects.
  Future<void> restorePayment(String paymentId) async {
    await _db.transaction(() async {
      final payment = await (_db.select(_db.payments)..where((t) => t.id.equals(paymentId))).getSingleOrNull();
      if (payment == null || payment.isActive) return;

      // 1. Re-apply Invoice Logic
      if (payment.invoiceId != null) {
        final invoice = await (_db.select(_db.invoices)..where((t) => t.id.equals(payment.invoiceId!))).getSingleOrNull();
        if (invoice != null) {
          final newPaid = invoice.paidAmount + payment.amount;
          String newStatus = 'UNPAID';
          if (newPaid >= invoice.total) {
            newStatus = 'PAID';
          } else if (newPaid > Decimal.zero) {
            newStatus = 'PARTIAL';
          }
          await (_db.update(_db.invoices)..where((t) => t.id.equals(invoice.id))).write(
            InvoicesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
          );
        }
      }

      // 2. Re-apply Purchase Logic
      if (payment.purchaseId != null) {
        final purchase = await (_db.select(_db.purchases)..where((t) => t.id.equals(payment.purchaseId!))).getSingleOrNull();
        if (purchase != null) {
          final newPaid = purchase.paidAmount + payment.amount;
          String newStatus = 'UNPAID';
          if (newPaid >= purchase.total) {
            newStatus = 'PAID';
          } else if (newPaid > Decimal.zero) {
            newStatus = 'PARTIAL';
          }
          await (_db.update(_db.purchases)..where((t) => t.id.equals(purchase.id))).write(
            PurchasesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
          );
        }
      }

      // 3. Re-apply Client Balance (Deduct debt) & FIFO Re-allocation
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
      }

      // 4. Re-apply Supplier Balance (Deduct debt) & FIFO Re-allocation
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
      }

      // 5. Re-apply Employee Balance
      if (payment.employeeId != null) {
        final emp = await (_db.select(_db.employees)..where((t) => t.id.equals(payment.employeeId!))).getSingleOrNull();
        if (emp != null) {
          await _db.update(_db.employees).replace(emp.copyWith(remainingSalary: emp.remainingSalary - payment.amount));
        }
      }

      // 6. Mark as active
      await (_db.update(_db.payments)..where((t) => t.id.equals(paymentId))).write(
        const PaymentsCompanion(isActive: drift.Value(true))
      );
    });
  }
}
