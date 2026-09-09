import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../widgets/universal_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_service.dart';
import 'package:decimal/decimal.dart';

import '../../application/hr/hr_providers.dart';
import '../../infrastructure/repositories/employee_repository.dart';
import 'add_employee_screen.dart';
import '../widgets/human_profile_dialog.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees & Payroll'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: () async {
              final code = await UniversalScanner.scan(context);
              if (code != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scanned: $code')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printing selected items')),
              );
            },
          ),
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                for (final id in _selectedIds) {
                  await ref.read(employeeRepositoryProvider).deleteEmployee(id);
                }
                setState(() {
                  _selectedIds.clear();
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEmployeeScreen())),
          ),
        ],
      ),
      body: employeesAsync.when(
        data: (employees) {
          if (employees.isEmpty) {
            return const Center(child: Text('No employees found.'));
          }
          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              final isSelected = _selectedIds.contains(emp.id);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(emp.id);
                            } else {
                              _selectedIds.remove(emp.id);
                            }
                          });
                        },
                      ),
                      const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.badge, color: Colors.white),
                      ),
                    ],
                  ),
                  title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${emp.position} | Base: ${emp.baseSalary.toStringAsFixed(2)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Salary Owed', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(
                        '${emp.remainingSalary.toStringAsFixed(2)} Dhs',
                        style: TextStyle(
                          color: emp.remainingSalary >= Decimal.zero ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HumanProfileDialog(
                          type: HumanType.employee,
                          id: emp.id,
                          name: emp.name,
                          roleOrType: emp.position,
                          phone: emp.phone,
                          email: emp.email,
                          imagePath: emp.imagePath,
                          balance: emp.remainingSalary,
                          baseSalary: emp.baseSalary,
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit, color: Colors.blue),
                                title: const Text('Edit'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddEmployeeScreen(employeeToEdit: emp)));
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (ref.read(currentUserProvider)?.role == 'ADMIN') {
                                    ref.read(employeeRepositoryProvider).deleteEmployee(emp.id);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin access required to delete.')));
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${(AppLocalizations.of(context)?.errorStr ?? 'Error: ')}$err')),
      ),
    );
  }
}
