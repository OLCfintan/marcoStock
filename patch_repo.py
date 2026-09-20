import re

with open('lib/src/infrastructure/repositories/employee_repository.dart', 'r') as f:
    content = f.read()

old_delete = """  Future<void> deleteEmployee(String id) async {
    await (_db.update(_db.employees)..where((t) => t.id.equals(id))).write(const EmployeesCompanion(isActive: drift.Value(false)));
  }"""

new_delete = """  Future<void> deleteEmployee(String id) async {
    final emp = await (_db.select(_db.employees)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (emp == null) return;
    
    if (emp.role == 'ADMIN') {
      final activeAdmins = await (_db.select(_db.employees)..where((t) => t.isActive.equals(true) & t.role.equals('ADMIN'))).get();
      if (activeAdmins.length <= 1) {
        throw Exception('Cannot delete the last active admin.');
      }
    }
    
    await (_db.update(_db.employees)..where((t) => t.id.equals(id))).write(const EmployeesCompanion(isActive: drift.Value(false)));
  }"""

content = content.replace(old_delete, new_delete)

with open('lib/src/infrastructure/repositories/employee_repository.dart', 'w') as f:
    f.write(content)
