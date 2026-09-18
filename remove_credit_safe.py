import os

def remove_credit(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Just remove the exact line for DropdownMenuItem
    if "DropdownMenuItem(value: 'CREDIT'" in content:
        lines = content.split('\n')
        new_lines = []
        for line in lines:
            if "DropdownMenuItem(value: 'CREDIT'" in line:
                continue
            if "enabled: p.method != 'CREDIT'" in line:
                continue
            new_lines.append(line)
        content = '\n'.join(new_lines)
        
        with open(filepath, 'w') as f:
            f.write(content)

import glob

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            remove_credit(os.path.join(root, file))

print("Safely removed credit")
