import re

filepath = "lib/src/presentation/settings/settings_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Replace the old backup/import list tiles
import_export_tiles = r"""          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text('Export & Import System', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
          ListTile(
            leading: const Icon(Icons.outbox, color: Colors.blue),
            title: const Text('Export Marko-Save'),
            subtitle: const Text('Export full system structure (DB, PDFs, Images, TXTs) to a folder.'),
            onTap: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting Export... This may take a moment to generate all PDFs.')));
                await ref.read(backupServiceProvider).exportData();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export completed successfully!')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.move_to_inbox, color: Colors.green),
            title: const Text('Import Marko-Save'),
            subtitle: const Text('Restore database and images from a Marko-Save folder.'),
            onTap: () async {
              try {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirm Import'),
                    content: const Text('This will OVERWRITE your current database with the Marko-Save backup. Are you sure?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Overwrite')),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await ref.read(backupServiceProvider).importData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import completed! Please restart the app.')));
                  }
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
          const Divider(),"""

# We'll replace the existing 'Backup Database' tile up to 'const Divider()'
old_backup = r"""          ListTile\(
            leading: const Icon\(Icons.save\),
            title: Text\(AppLocalizations.of\(context\)!.backupDatabase\),
            subtitle: Text\(AppLocalizations.of\(context\)!.selectBackupLocation\),
            onTap: \(\) async \{
              try \{
                final path = await ref.read\(syncServiceProvider\).backupDatabase\(\);
                if \(context.mounted\) \{
                  if \(path != null\) \{
                    ScaffoldMessenger.of\(context\).showSnackBar\(SnackBar\(content: Text\('\$\{AppLocalizations.of\(context\)!.backupSavedTo\}\$path'\)\)\);
                  \} else \{
                    ScaffoldMessenger.of\(context\).showSnackBar\(SnackBar\(content: Text\(AppLocalizations.of\(context\)!.backupCancelled\)\)\);
                  \}
                \}
              \} catch \(e\) \{
                if \(context.mounted\) \{
                  ScaffoldMessenger.of\(context\).showSnackBar\(SnackBar\(content: Text\('\$\{\(AppLocalizations.of\(context\)\?.errorStr \?\? 'Error: '\)\}\$e'\)\)\);
                \}
              \}
            \},
          \),

          const Divider\(\),"""

content = re.sub(old_backup, import_export_tiles, content)

# Add import at the top
import_str = "import '../../application/backup/backup_service.dart';\n"
content = content.replace("import 'company_profile_screen.dart';", "import 'company_profile_screen.dart';\n" + import_str)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated settings screen")
