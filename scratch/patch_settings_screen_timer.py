import re

with open('lib/src/presentation/settings/settings_screen.dart', 'r') as f:
    content = f.read()

old_block = """          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context)!.language),
            trailing: DropdownButton<Locale>("""

new_block = """          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Auto-Lock Sleep Delay'),
            trailing: DropdownButton<int>(
              value: ref.watch(sleepDelayProvider),
              onChanged: (val) {
                 if (val != null) ref.read(sleepDelayProvider.notifier).setDelay(val);
              },
              items: const [
                DropdownMenuItem(value: 1, child: Text('< 1 min')),
                DropdownMenuItem(value: 5, child: Text('5 min')),
                DropdownMenuItem(value: 10, child: Text('10 min')),
                DropdownMenuItem(value: 15, child: Text('15 min')),
                DropdownMenuItem(value: 30, child: Text('30 min')),
                DropdownMenuItem(value: 60, child: Text('1 h')),
                DropdownMenuItem(value: 75, child: Text('1 h 15 min')),
                DropdownMenuItem(value: 90, child: Text('1 h 30 min')),
                DropdownMenuItem(value: 0, child: Text('Never')),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context)!.language),
            trailing: DropdownButton<Locale>("""

if old_block in content:
    content = content.replace(old_block, new_block)
    print('Settings Screen patched.')
else:
    print('Settings Screen NOT patched.')

with open('lib/src/presentation/settings/settings_screen.dart', 'w') as f:
    f.write(content)
