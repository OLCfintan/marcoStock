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
    String? invoiceId,
    String? purchaseId,
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

      // 2. Client Payment
      if (clientId != null) {
        final client = await (_db.select(_db.clients)..where((t) => t.id.equals(clientId))).getSingleOrNull();
        if (client != null && client.type != 'TEMP') {
          // Update client balance
          await _db.update(_db.clients).replace(client.copyWith(balance: client.balance - amount));
          
          Decimal remainingAmountToAllocate = amount;
          
          if (invoiceId != null) {
            // Explicitly pay a specific invoice
            final inv = await (_db.select(_db.invoices)..where((t) => t.id.equals(invoiceId))).getSingleOrNull();
            if (inv != null) {
              final remainingDebt = inv.total - inv.paidAmount;
              final amountToApply = remainingAmountToAllocate <= remainingDebt ? remainingAmountToAllocate : remainingDebt;
              
              if (amountToApply > Decimal.zero) {
                final newPaid = inv.paidAmount + amountToApply;
                final newStatus = newPaid >= inv.total ? 'PAID' : (newPaid > Decimal.zero ? 'PARTIAL' : 'UNPAID');
                await (_db.update(_db.invoices)..where((t) => t.id.equals(inv.id))).write(
                  InvoicesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
                );
                remainingAmountToAllocate -= amountToApply;
              }
            }
          }
          
          // Allocate excess/all to other UNPAID/PARTIAL BON invoices
          if (remainingAmountToAllocate > Decimal.zero) {
            final query = _db.select(_db.invoices)
              ..where((t) => t.clientId.equals(clientId))
              ..where((t) => t.documentType.equals('BON'))
              ..where((t) => t.status.isIn(['UNPAID', 'PARTIAL']))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.date)]);
            
            final unpaidInvoices = await query.get();
            
            for (final inv in unpaidInvoices) {
              if (remainingAmountToAllocate <= Decimal.zero) break;
              
              final remainingDebt = inv.total - inv.paidAmount;
              if (remainingDebt <= Decimal.zero) continue;
              
              final amountToApply = remainingAmountToAllocate <= remainingDebt ? remainingAmountToAllocate : remainingDebt;
              final newPaid = inv.paidAmount + amountToApply;
              final newStatus = newPaid >= inv.total ? 'PAID' : (newPaid > Decimal.zero ? 'PARTIAL' : 'UNPAID');
              
              await (_db.update(_db.invoices)..where((t) => t.id.equals(inv.id))).write(
                InvoicesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
              );
              
              remainingAmountToAllocate -= amountToApply;
            }
          }
          
          // Record Payment
          await _db.into(_db.payments).insert(PaymentsCompanion.insert(
            id: paymentId,
            clientId: drift.Value(clientId),
            invoiceId: drift.Value(invoiceId),
            amount: amount,
            method: method,
            checkImagePath: drift.Value(checkImagePath),
            date: DateTime.now(),
            status: 'CLEARED',
          ));
        }
        return;
      }

      // 3. Supplier Payment
      if (supplierId != null) {
        final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(supplierId))).getSingleOrNull();
        if (supplier != null) {
          // Update supplier balance
          await _db.update(_db.suppliers).replace(supplier.copyWith(balance: supplier.balance - amount));
          
          Decimal remainingAmountToAllocate = amount;
          
          if (purchaseId != null) {
            // Explicitly pay a specific purchase
            final pur = await (_db.select(_db.purchases)..where((t) => t.id.equals(purchaseId))).getSingleOrNull();
            if (pur != null) {
              final remainingDebt = pur.total - pur.paidAmount;
              final amountToApply = remainingAmountToAllocate <= remainingDebt ? remainingAmountToAllocate : remainingDebt;
              
              if (amountToApply > Decimal.zero) {
                final newPaid = pur.paidAmount + amountToApply;
                final newStatus = newPaid >= pur.total ? 'PAID' : (newPaid > Decimal.zero ? 'PARTIAL' : 'UNPAID');
                await (_db.update(_db.purchases)..where((t) => t.id.equals(pur.id))).write(
                  PurchasesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
                );
                remainingAmountToAllocate -= amountToApply;
              }
            }
          }
          
          // Allocate excess/all to other UNPAID/PARTIAL BON purchases
          if (remainingAmountToAllocate > Decimal.zero) {
            final query = _db.select(_db.purchases)
              ..where((t) => t.supplierId.equals(supplierId))
              ..where((t) => t.documentType.equals('BON'))
              ..where((t) => t.status.isIn(['UNPAID', 'PARTIAL']))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.date)]);
            
            final unpaidPurchases = await query.get();
            
            for (final pur in unpaidPurchases) {
              if (remainingAmountToAllocate <= Decimal.zero) break;
              
              final remainingDebt = pur.total - pur.paidAmount;
              if (remainingDebt <= Decimal.zero) continue;
              
              final amountToApply = remainingAmountToAllocate <= remainingDebt ? remainingAmountToAllocate : remainingDebt;
              final newPaid = pur.paidAmount + amountToApply;
              final newStatus = newPaid >= pur.total ? 'PAID' : (newPaid > Decimal.zero ? 'PARTIAL' : 'UNPAID');
              
              await (_db.update(_db.purchases)..where((t) => t.id.equals(pur.id))).write(
                PurchasesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
              );
              
              remainingAmountToAllocate -= amountToApply;
            }
          }
          
          await _db.into(_db.payments).insert(PaymentsCompanion.insert(
            id: paymentId,
            supplierId: drift.Value(supplierId),
            purchaseId: drift.Value(purchaseId),
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
          

        }
      }

      // 4. Reverse Supplier Balance (Add debt back) & LIFO De-allocation
      if (payment.supplierId != null) {
        final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(payment.supplierId!))).getSingleOrNull();
        if (supplier != null) {
          await _db.update(_db.suppliers).replace(supplier.copyWith(balance: supplier.balance + payment.amount));
          

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
          

        }
      }

      // 4. Re-apply Supplier Balance (Deduct debt) & FIFO Re-allocation
      if (payment.supplierId != null) {
        final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(payment.supplierId!))).getSingleOrNull();
        if (supplier != null) {
          await _db.update(_db.suppliers).replace(supplier.copyWith(balance: supplier.balance - payment.amount));
          

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
