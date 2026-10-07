import re

with open('lib/src/presentation/settings/garbage_screen.dart', 'r') as f:
    content = f.read()

helper = """
  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.confirmDeleteTitle ?? 'Confirm Delete'),
        content: Text(l10n?.confirmDeleteMessage ?? 'Are you sure you want to permanently delete? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n?.cancel ?? 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n?.deleteStr ?? 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }
"""

content = content.replace("class _GarbageScreenState extends ConsumerState<GarbageScreen> {", "class _GarbageScreenState extends ConsumerState<GarbageScreen> {" + helper)

content = content.replace("onPressed: () async {\n                final db = ref.read(databaseProvider);", 
"""onPressed: () async {
                if (!await _confirmDelete(context)) return;
                final db = ref.read(databaseProvider);""")

content = content.replace("onPressed: () => onPermanentDelete(item),", 
"""onPressed: () async {
                              if (!await _confirmDelete(context)) return;
                              onPermanentDelete(item);
                            },""")

with open('lib/src/presentation/settings/garbage_screen.dart', 'w') as f:
    f.write(content)
