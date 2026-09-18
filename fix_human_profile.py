import re

filepath = "lib/src/presentation/widgets/human_profile_dialog.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Add imports for providers
if "import '../../application/clients/client_providers.dart';" not in content:
    content = "import '../../application/clients/client_providers.dart';\n" + content
if "import '../../application/suppliers/supplier_providers.dart';" not in content:
    content = "import '../../application/suppliers/supplier_providers.dart';\n" + content
if "import '../../application/hr/employee_providers.dart';" not in content:
    content = "import '../../application/hr/employee_providers.dart';\n" + content

# Modify build method
old_build = r"""  @override
  Widget build\(BuildContext context\) \{
    final db = ref.watch\(databaseProvider\);
    
    final balanceColor = widget.balance > Decimal.zero \? Colors.red : Colors.green;
    final String balanceLabel = widget.type == HumanType.employee \? 'Salary Owed' : 'Balance';

    return Scaffold\("""

new_build = r"""  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    
    Decimal currentBalance = widget.balance;
    if (widget.type == HumanType.client) {
      final clientsAsync = ref.watch(clientsStreamProvider);
      final c = clientsAsync.value?.where((e) => e.id == widget.id).firstOrNull;
      if (c != null) currentBalance = c.balance;
    } else if (widget.type == HumanType.supplier) {
      final suppliersAsync = ref.watch(suppliersStreamProvider);
      final s = suppliersAsync.value?.where((e) => e.id == widget.id).firstOrNull;
      if (s != null) currentBalance = s.balance;
    } else if (widget.type == HumanType.employee) {
      final employeesAsync = ref.watch(employeesStreamProvider);
      final e = employeesAsync.value?.where((e) => e.id == widget.id).firstOrNull;
      if (e != null) currentBalance = e.salaryOwed;
    }
    
    final balanceColor = currentBalance > Decimal.zero ? Colors.red : Colors.green;
    final String balanceLabel = widget.type == HumanType.employee ? 'Salary Owed' : 'Balance';

    return Scaffold("""

content = re.sub(old_build, new_build, content)

# Replace widget.balance with currentBalance in the UI
old_ui = r"""                    Text\(balanceLabel, style: const TextStyle\(fontSize: 14, color: Colors.grey\)\),
                    Text\('\$\{widget.balance.toStringAsFixed\(2\)\} Dhs', style: TextStyle\(fontSize: 24, fontWeight: FontWeight.bold, color: balanceColor\)\),"""

new_ui = r"""                    Text(balanceLabel, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('${currentBalance.toStringAsFixed(2)} Dhs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: balanceColor)),"""

content = re.sub(old_ui, new_ui, content)


# Also fix PaymentLedgerDialog to use the live balance!
# Wait, PaymentLedgerDialog is a separate file.

with open(filepath, 'w') as f:
    f.write(content)
print("Updated human_profile_dialog.dart")
