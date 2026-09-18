import os
import re

def remove_credit_from_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Remove DropdownMenuItem with CREDIT
    content = re.sub(r"DropdownMenuItem\(value:\s*'CREDIT'.*?\),?\n?", "", content)

    # Remove enabled: p.method != 'CREDIT'
    content = re.sub(r"enabled:\s*p\.method\s*!=\s*'CREDIT',\n?", "", content)

    # Remove logic if (val == 'CREDIT')
    # This might be tricky. Let's just manually replace in the specific files we know.

    with open(filepath, 'w') as f:
        f.write(content)

import glob

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            remove_credit_from_file(os.path.join(root, file))

print("Removed credit from all files")
