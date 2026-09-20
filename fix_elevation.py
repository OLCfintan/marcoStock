import os
import re

def process_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove hardcoded elevation that typically ruins flat UI
    content = re.sub(r'elevation:\s*\d+\.?[0-9]*\s*,', '', content)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

for root, dirs, files in os.walk('lib/src/presentation'):
    for name in files:
        if name.endswith('.dart'):
            process_file(os.path.join(root, name))

