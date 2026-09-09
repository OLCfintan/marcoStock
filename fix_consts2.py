import os
import re

lib_path = "/home/limbo/Desktop/marcoStock/lib"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # 1. Remove const from Padding if it wraps AppLocalizations
    # This is a bit tricky with regex, so we'll just replace specific known ones
    content = re.sub(r'const\s+Padding\(\s*padding:\s*(.*?),\s*child:\s*Text\(AppLocalizations\.of\(context\)', r'Padding(\n            padding: \1,\n            child: Text(AppLocalizations.of(context)', content)
    
    # 2. Remove const from lists if it contains AppLocalizations
    content = re.sub(r'items:\s*const\s*\[(.*?)AppLocalizations', r'items: [\1AppLocalizations', content, flags=re.DOTALL)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")

for root, _, files in os.walk(lib_path):
    for f in files:
        if f.endswith('.dart'):
            process_file(os.path.join(root, f))

print("Done")
