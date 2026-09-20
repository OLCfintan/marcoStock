import os
import re

pattern = re.compile(r'([=!]=\s*\.[a-zA-Z_][a-zA-Z0-9_]*)')

for root, _, files in os.walk('lib/'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
                matches = pattern.findall(content)
                if matches:
                    print(f'{filepath}: {matches}')

