import re

filepath = "lib/src/presentation/clients/clients_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_trailing = r"""                  trailing: Row\(
                    mainAxisSize: MainAxisSize\.min,
                    children: \[
                      Text\('\$\{client\.balance\.toStringAsFixed\(2\)\} Dhs', style: TextStyle\(
                        color: client\.balance > Decimal\.zero \? Colors\.red : Colors\.green, fontWeight: FontWeight\.bold
                      \)\),
                      const SizedBox\(width: 8\),
                      IconButton\(
                        icon: const Icon\(Icons\.edit, color: Colors\.blue\),
                        onPressed: \(\) \{
                          Navigator\.push\(context, MaterialPageRoute\(builder: \(\_\) => AddClientScreen\(clientToEdit: client\)\)\);
                        \},
                      \),
                      IconButton\(
                        icon: const Icon\(Icons\.delete, color: Colors\.red\),
                        onPressed: \(\) \{
                          if \(ref\.read\(currentUserProvider\)\?\.role == 'ADMIN'\) \{
                            ref\.read\(clientRepositoryProvider\)\.deleteClient\(client\.id\);
                          \} else \{
                            ScaffoldMessenger\.of\(context\)\.showSnackBar\(const SnackBar\(content: Text\('Admin access required to delete\.'\)\)\);
                          \}
                        \},
                      \),
                    \],
                  \),"""

new_trailing = r"""                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${client.balance.toStringAsFixed(2)} Dhs', style: TextStyle(
                        color: client.balance > Decimal.zero ? Colors.red : Colors.green, fontWeight: FontWeight.bold
                      )),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'ledger') {
                            showDialog(
                              context: context,
                              builder: (_) => PaymentLedgerDialog(
                                clientId: client.id,
                                initialBalance: client.balance,
                                entityName: client.name,
                              ),
                            );
                          } else if (value == 'edit') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AddClientScreen(clientToEdit: client)));
                          } else if (value == 'delete') {
                            if (ref.read(currentUserProvider)?.role == 'ADMIN') {
                              ref.read(clientRepositoryProvider).deleteClient(client.id);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin access required to delete.')));
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'ledger', child: Text('Ledger / Payments')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),"""

content = re.sub(old_trailing, new_trailing, content, flags=re.MULTILINE | re.DOTALL)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
