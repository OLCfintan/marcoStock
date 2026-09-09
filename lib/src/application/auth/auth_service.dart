import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(databaseProvider));
});

// A simple session state provider
final currentUserProvider = StateProvider<EmployeeEntity?>((ref) => null);

class AuthService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  AuthService(this._db);

  Future<void> initializeAdmin() async {
    final existingAdmins = await (_db.select(_db.employees)..where((t) => t.role.equals('ADMIN'))).get();
    if (existingAdmins.isEmpty) {
      await _db.into(_db.employees).insert(EmployeesCompanion.insert(
        id: _uuid.v4(),
        name: 'Admin User',
        position: 'Administrator',
        role: const Value('ADMIN'),
        pinCode: const Value('1234'),
      ));
    }
  }

  Future<EmployeeEntity?> login(String pin) async {
    final query = _db.select(_db.employees)
      ..where((t) => t.pinCode.equals(pin) & t.isActive.equals(true));
      
    final user = await query.getSingleOrNull();
    if (user != null && user.role == 'MAGAZINIER') return null; // Magazinier cannot login
    return user;
  }
}
