import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:decimal/decimal.dart';

import '../database/app_database.dart';
import '../database/providers.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(ref.watch(databaseProvider));
});

class Employee {
  final String id;
  final String name;
  final String position;
  final Decimal baseSalary;
  final Decimal remainingSalary; // Positive = MarkoGroup owes Employee
  final bool isActive;
  final String? phone;
  final String? email;
  final String? imagePath;
  final String role;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.baseSalary,
    required this.remainingSalary,
    required this.isActive,
    this.phone,
    this.email,
    this.imagePath,
    this.role = 'CAISSIER',
  });
}

class EmployeeRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  EmployeeRepository(this._db);

  drift.Value<T> driftValue<T>(T? value) => value == null ? const drift.Value.absent() : drift.Value(value);

  Stream<List<Employee>> watchAllEmployees() {
    return (_db.select(_db.employees)..where((t) => t.isActive.equals(true))).watch().map((entities) {
      return entities.map((e) => Employee(
        id: e.id,
        name: e.name,
        position: e.position,
        baseSalary: e.baseSalary,
        remainingSalary: e.remainingSalary,
        isActive: e.isActive,
        phone: e.phone,
        email: e.email,
        imagePath: e.imagePath,
        role: e.role,
      )).toList();
    });
  }

  Future<void> createEmployee(String name, String position, {
    String? phone,
    String? email,
    String? imagePath,
    String? idScanPath,
    String? baseSalary,
    String role = 'CASHIER',
    String? pinCode,
  }) async {
    await _db.into(_db.employees).insert(EmployeesCompanion.insert(
      id: _uuid.v4(),
      name: name,
      position: position,
      baseSalary: baseSalary != null && baseSalary.isNotEmpty 
          ? drift.Value(Decimal.parse(baseSalary)) 
          : const drift.Value.absent(),
      remainingSalary: const drift.Value.absent(),
      phone: drift.Value(phone),
      email: drift.Value(email),
      imagePath: drift.Value(imagePath),
      idScanPath: drift.Value(idScanPath),
      role: drift.Value(role),
      pinCode: drift.Value(pinCode),
    ));
  }

  
  Future<void> updateEmployee(
    String id, {
    required String name,
    required String position,
    String? phone,
    String? email,
    String? imagePath,
    String role = 'CAISSIER',
    String? baseSalary,
    String? pinCode,
  }) async {
    await (_db.update(_db.employees)..where((t) => t.id.equals(id))).write(
      EmployeesCompanion(
        name: drift.Value(name),
        position: drift.Value(position),
        phone: driftValue(phone),
        email: driftValue(email),
        imagePath: driftValue(imagePath),
        role: drift.Value(role),
        baseSalary: baseSalary != null ? drift.Value(Decimal.parse(baseSalary)) : const drift.Value.absent(),
        pinCode: driftValue(pinCode),
        updatedAt: drift.Value(DateTime.now()),
      )
    );
  }

  Future<void> deleteEmployee(String id) async {
    await (_db.update(_db.employees)..where((t) => t.id.equals(id))).write(const EmployeesCompanion(isActive: drift.Value(false)));
  }
  Future<void> restoreEmployee(String id) async {
    await (_db.update(_db.employees)..where((t) => t.id.equals(id))).write(const EmployeesCompanion(isActive: drift.Value(true)));
  }
  Future<void> permanentDeleteEmployee(String id) async {
    await (_db.delete(_db.employees)..where((t) => t.id.equals(id))).go();
  }
}
