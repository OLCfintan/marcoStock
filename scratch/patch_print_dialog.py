import re

with open('lib/src/presentation/widgets/print_dialog.dart', 'r') as f:
    content = f.read()

# Remove a4_2up from enum
content = content.replace('  a4_2up, // 2-up A5 on A4 landscape', '')

# Remove RadioListTile for a4_2up
pattern = r'          RadioListTile<PrintLayout>\(\s*title: const Text\(\'A4 Landscape \(2-up A5\)\'\),\s*subtitle: const Text\(\'Prints 2 copies side-by-side on A4\'\),\s*value: PrintLayout\.a4_2up,\s*groupValue: _selectedLayout,\s*onChanged: \(v\) \{ if\(v!=null\) setState\(\(\) => _selectedLayout = v\); \},\s*contentPadding: EdgeInsets\.zero,\s*\),'
content = re.sub(pattern, '', content)

with open('lib/src/presentation/widgets/print_dialog.dart', 'w') as f:
    f.write(content)
print("Print dialog patched")
