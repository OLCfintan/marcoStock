import re

filepath = "lib/src/presentation/settings/garbage_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_trailing = r"""            trailing: Row\(
              mainAxisSize: MainAxisSize\.min,
              children: \[
                IconButton\(icon: const Icon\(Icons\.restore, color: Colors\.green\), onPressed: \(\) => onRestore\(item\)\),
                IconButton\(icon: const Icon\(Icons\.delete_forever, color: Colors\.red\), onPressed: \(\) => onPermanentDelete\(item\)\),
              \],
            \),"""

new_trailing = r"""            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'restore') onRestore(item);
                if (value == 'delete_forever') onPermanentDelete(item);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'restore', child: Text('Restore', style: TextStyle(color: Colors.green))),
                const PopupMenuItem(value: 'delete_forever', child: Text('Delete Permanently', style: TextStyle(color: Colors.red))),
              ],
            ),"""

content = re.sub(old_trailing, new_trailing, content, flags=re.MULTILINE | re.DOTALL)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
