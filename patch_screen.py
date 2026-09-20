import re

with open('lib/src/presentation/hr/employees_screen.dart', 'r') as f:
    content = f.read()

# 1. Bulk delete
old_bulk = """              onPressed: () async {
                for (final id in _selectedIds) {
                  await ref.read(employeeRepositoryProvider).deleteEmployee(id);
                }
                setState(() {
                  _selectedIds.clear();
                });
              },"""

new_bulk = """              onPressed: () async {
                try {
                  for (final id in _selectedIds) {
                    await ref.read(employeeRepositoryProvider).deleteEmployee(id);
                  }
                  setState(() {
                    _selectedIds.clear();
                  });
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                  }
                }
              },"""
content = content.replace(old_bulk, new_bulk)

# 2. Single delete
old_single = """                                  if (ref.read(currentUserProvider)?.role == 'ADMIN') {
                                    ref.read(employeeRepositoryProvider).deleteEmployee(emp.id);
                                  } else {"""

new_single = """                                  if (ref.read(currentUserProvider)?.role == 'ADMIN') {
                                    ref.read(employeeRepositoryProvider).deleteEmployee(emp.id).catchError((e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                                      }
                                    });
                                  } else {"""

content = content.replace(old_single, new_single)

with open('lib/src/presentation/hr/employees_screen.dart', 'w') as f:
    f.write(content)
