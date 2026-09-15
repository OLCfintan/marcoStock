import re

filepath = "lib/src/presentation/hr/employees_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_trailing = r"""                  trailing: Column\(
                    mainAxisAlignment: MainAxisAlignment\.center,
                    crossAxisAlignment: CrossAxisAlignment\.end,
                    children: \[
                      const Text\('Salary Owed', style: TextStyle\(fontSize: 10, color: Colors\.grey\)\),
                      Text\(
                        '\$\{emp\.remainingSalary\.toStringAsFixed\(2\)\} Dhs',
                        style: TextStyle\(
                          color: emp\.remainingSalary >= Decimal\.zero \? Colors\.red\.shade700 : Colors\.green\.shade700,
                          fontWeight: FontWeight\.bold,
                        \),
                      \),
                    \],
                  \),
                  onTap: \(\) \{
                    Navigator\.push\(
                      context,
                      MaterialPageRoute\(
                        builder: \(\_\) => HumanProfileDialog\(
                          type: HumanType\.employee,
                          id: emp\.id,
                          name: emp\.name,
                          roleOrType: emp\.role,
                          phone: emp\.phone,
                          email: emp\.email,
                          imagePath: emp\.imagePath,
                          balance: emp\.remainingSalary,
                        \),
                      \),
                    \);
                  \},
                  onLongPress: \(\) \{
                    showModalBottomSheet\(
                      context: context,
                      builder: \(context\) \{
                        return SafeArea\(
                          child: Wrap\(
                            children: \[
                              ListTile\(
                                leading: const Icon\(Icons\.edit, color: Colors\.blue\),
                                title: const Text\('Edit'\),
                                onTap: \(\) \{
                                  Navigator\.pop\(context\);
                                  Navigator\.push\(context, MaterialPageRoute\(builder: \(\_\) => AddEmployeeScreen\(employeeToEdit: emp\)\)\);
                                \},
                              \),
                              ListTile\(
                                leading: const Icon\(Icons\.delete, color: Colors\.red\),
                                title: const Text\('Delete', style: TextStyle\(color: Colors\.red\)\),
                                onTap: \(\) \{
                                  Navigator\.pop\(context\);
                                  if \(ref\.read\(currentUserProvider\)\?\.role == 'ADMIN'\) \{
                                    ref\.read\(employeeRepositoryProvider\)\.deleteEmployee\(emp\.id\);
                                  \} else \{
                                    ScaffoldMessenger\.of\(context\)\.showSnackBar\(const SnackBar\(content: Text\('Admin access required to delete\.'\)\)\);
                                  \}
                                \},
                              \),
                            \],
                          \),
                        \);
                      \}
                    \);
                  \},"""

new_trailing = r"""                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
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
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AddEmployeeScreen(employeeToEdit: emp)));
                          } else if (value == 'delete') {
                            if (ref.read(currentUserProvider)?.role == 'ADMIN') {
                              ref.read(employeeRepositoryProvider).deleteEmployee(emp.id);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin access required to delete.')));
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
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
                          roleOrType: emp.role,
                          phone: emp.phone,
                          email: emp.email,
                          imagePath: emp.imagePath,
                          balance: emp.remainingSalary,
                        ),
                      ),
                    );
                  },"""

content = re.sub(old_trailing, new_trailing, content, flags=re.MULTILINE | re.DOTALL)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
