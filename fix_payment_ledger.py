import re

filepath = "lib/src/presentation/widgets/payment_ledger_dialog.dart"
with open(filepath, 'r') as f:
    content = f.read()

if "import '../../application/clients/client_providers.dart';" not in content:
    content = "import '../../application/clients/client_providers.dart';\n" + content
if "import '../../application/suppliers/supplier_providers.dart';" not in content:
    content = "import '../../application/suppliers/supplier_providers.dart';\n" + content
if "import '../../application/hr/employee_providers.dart';" not in content:
    content = "import '../../application/hr/employee_providers.dart';\n" + content

old_build = r"""  @override
  Widget build\(BuildContext context\) \{
    final remainingBalance = widget.initialBalance - _totalPaid;"""

new_build = r"""  @override
  Widget build(BuildContext context) {
    Decimal currentBalance = widget.initialBalance;
    if (widget.clientId != null) {
      final clientsAsync = ref.watch(clientsStreamProvider);
      final c = clientsAsync.value?.where((e) => e.id == widget.clientId).firstOrNull;
      if (c != null) currentBalance = c.balance;
    } else if (widget.supplierId != null) {
      final suppliersAsync = ref.watch(suppliersStreamProvider);
      final s = suppliersAsync.value?.where((e) => e.id == widget.supplierId).firstOrNull;
      if (s != null) currentBalance = s.balance;
    } else if (widget.employeeId != null) {
      final employeesAsync = ref.watch(employeesStreamProvider);
      final e = employeesAsync.value?.where((e) => e.id == widget.employeeId).firstOrNull;
      if (e != null) currentBalance = e.salaryOwed;
    }
    
    final remainingBalance = currentBalance - _totalPaid;"""

content = re.sub(old_build, new_build, content)

old_ui = r"""                const Text\('Current Balance:', style: TextStyle\(fontSize: 16\)\),
                Text\('\$\{widget.initialBalance.toStringAsFixed\(2\)\} Dhs', style: const TextStyle\(fontSize: 16, fontWeight: FontWeight.bold\)\),"""

new_ui = r"""                const Text('Current Balance:', style: TextStyle(fontSize: 16)),
                Text('${currentBalance.toStringAsFixed(2)} Dhs', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),"""

content = re.sub(old_ui, new_ui, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated payment_ledger_dialog.dart")
