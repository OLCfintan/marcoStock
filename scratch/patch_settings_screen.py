import re

with open('lib/src/presentation/settings/settings_screen.dart', 'r') as f:
    content = f.read()

old_block = """          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context)!.language),
            trailing: DropdownButton<Locale>("""

new_block = """          ListTile(
            leading: const Icon(Icons.zoom_in),
            title: const Text('Magnifier Zoom Factor'),
            subtitle: Slider(
              value: ref.watch(magnifierZoomProvider),
              min: 1.0,
              max: 3.0,
              divisions: 20,
              label: '${ref.watch(magnifierZoomProvider).toStringAsFixed(1)}x',
              onChanged: (val) {
                 ref.read(magnifierZoomProvider.notifier).setZoom(val);
              },
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
