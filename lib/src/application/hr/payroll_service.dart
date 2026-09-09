import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';

final payrollServiceProvider = Provider<PayrollService>((ref) {
  return PayrollService(ref.watch(databaseProvider));
});

class PayrollService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  PayrollService(this._db);

  /// Executes a payroll transaction (Advance, Bonus, Deduction, or Salary Payment)
  /// Atomically updates the employee's remaining salary.
  Future<void> executePayrollTransaction({
    required String employeeId,
    required String type, // 'SALARY', 'ADVANCE', 'BONUS', 'DEDUCTION', 'PAYMENT'
    required Decimal amount,
    required String currentUserId,
    String? notes,
  }) async {
    await _db.transaction(() async {
      // 1. Record the payroll action
      final recordId = _uuid.v4();
      await _db.into(_db.payrollRecords).insert(PayrollRecordsCompanion.insert(
        id: recordId,
        employeeId: employeeId,
        type: type,
        amount: amount,
        notes: notes != null ? drift.Value(notes) : const drift.Value.absent(),
      ));

      // 2. Fetch Employee
      final empQuery = _db.select(_db.employees)..where((t) => t.id.equals(employeeId));
      final employee = await empQuery.getSingle();

      // 3. Compute New Balance
      // Positive balance = Owed to employee
      Decimal newBalance = employee.remainingSalary;
      
      switch (type) {
        case 'SALARY':
        case 'BONUS':
          newBalance = newBalance + amount;
          break;
        case 'ADVANCE':
        case 'DEDUCTION':
        case 'PAYMENT':
          newBalance = newBalance - amount;
          break;
        default:
          throw Exception('Unknown payroll type: $type');
      }

      // 4. Update Employee
      await _db.update(_db.employees).replace(employee.copyWith(
        remainingSalary: newBalance,
        updatedAt: DateTime.now(),
      ));

      // 5. Audit Log
      await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
        id: _uuid.v4(),
        userId: currentUserId,
        action: 'PAYROLL_TRANSACTION_$type',
        entityType: 'EMPLOYEE',
        entityId: employeeId,
        details: jsonEncode({'amount': amount.toString(), 'newBalance': newBalance.toString()}),
      ));
    });
  }
}
