import os
import re

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Make circular avatars sleek
    content = re.sub(
        r'backgroundColor:\s*.*?\.shade\d+.*?,',
        r'backgroundColor: const Color(0xfff1f5f9),',
        content
    )
    content = re.sub(
        r'icon:\s*Icon\((.*?),\s*color:\s*.*?,\s*\)',
        r'icon: Icon(\1, color: const Color(0xff64748b))',
        content
    )
    # Also for direct Icon in child
    content = re.sub(
        r'child:\s*Icon\((.*?),\s*color:\s*.*?\)',
        r'child: Icon(\1, color: const Color(0xff64748b))',
        content
    )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

for root, dirs, files in os.walk('lib/src/presentation'):
    for name in files:
        if name.endswith('.dart'):
            fix_file(os.path.join(root, name))

