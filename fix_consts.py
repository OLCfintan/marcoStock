import os
import re

lib_path = "/home/limbo/Desktop/marcoStock/lib"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Replace 'const Text(AppLocalizations' with 'Text(AppLocalizations'
    content = re.sub(r'const\s+Text\s*\(\s*AppLocalizations', r'Text(AppLocalizations', content)
    
    # Replace 'const SnackBar(content: Text(AppLocalizations' with 'SnackBar(content: Text(AppLocalizations'
    content = re.sub(r'const\s+SnackBar\s*\(\s*content:\s*Text\s*\(\s*AppLocalizations', r'SnackBar(content: Text(AppLocalizations', content)
    
    # Also replace anything like `const Text('${AppLocalizations`
    content = re.sub(r'const\s+Text\s*\(\s*\'\$\{AppLocalizations', r'Text(\'${AppLocalizations', content)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")

for root, _, files in os.walk(lib_path):
    for f in files:
        if f.endswith('.dart'):
            process_file(os.path.join(root, f))

print("Done")
