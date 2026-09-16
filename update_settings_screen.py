import re

filepath = "lib/src/presentation/settings/settings_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

clear_all_ui = """
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text('Wipe Database (Clear All Data)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text('Deletes all products, clients, stock, and history.'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Are you absolutely sure?', style: TextStyle(color: Colors.red)),
                  content: const Text('This will permanently delete all records (Products, Clients, Stock, Invoices, etc). This cannot be undone. Are you sure you want to start fresh?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true), 
                      child: const Text('WIPE EVERYTHING', style: TextStyle(color: Colors.white))
                    ),
                  ],
                )
              );
              
              if (confirm == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wiping database...')));
                await ref.read(databaseProvider).clearAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database completely erased and reset.')));
                }
              }
            },
          ),
"""

old_end = r"""              if \(context\.mounted\) \{
                ScaffoldMessenger\.of\(context\)\.showSnackBar\(SnackBar\(content: Text\(result\)\)\);
              \}
            \},
          \),
        \],
      \),
    \);"""

new_end = r"""              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
              }
            },
          ),""" + clear_all_ui + r"""
        ],
      ),
    );"""

content = re.sub(old_end, new_end, content, flags=re.MULTILINE)

# Also need to make sure databaseProvider is imported/accessible. 
# Let's check imports.
with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
